#!/usr/bin/env python3
"""Analyse a v2-utilisation-diag run directory (see v2-utilisation-diag.sh).

Prints a Markdown report (phase A scaling, phase B phase/utilisation
breakdown, phase C client check) and writes timeline CSVs + figures into
<run>/analysis/.

Usage: v2util-analyze.py <run-dir>
"""
import csv
import glob
import gzip
import os
import re
import statistics as st
import sys
from collections import Counter, defaultdict

RUN = sys.argv[1]
OUT = os.path.join(RUN, "analysis")
os.makedirs(OUT, exist_ok=True)
NS = 1e9


def med_rng(xs, fmt="{:.2f}"):
    xs = [x for x in xs if x is not None]
    if not xs:
        return "-"
    return (fmt + " ({}–{})").format(st.median(xs), fmt.format(min(xs)), fmt.format(max(xs)))


rows = list(csv.DictReader(open(os.path.join(RUN, "queries.csv"))))
for r in rows:
    for k in ("wall_s", "ttfb_s", "srv_cpu_s", "bytes"):
        r[k] = float(r[k])
    r["sys_busy_cores"] = float(r["sys_busy_cores"]) if r["sys_busy_cores"] not in ("-", "") else None

print(f"# V2 utilisation diagnosis — {os.path.basename(RUN.rstrip('/'))}\n")

# ------------------------------------------------------------------ phase A
A = [r for r in rows if r["phase"] == "A" and r["scenario"] in ("cold", "warm")]
if A:
    print("## Phase A — wall time vs query threads (original binary 87f57674)\n")
    print("Per trial: cold = mean of 2 cold queries; warm = mean of the looped warm "
          "queries (>= 10 s). Table: median over trials (min–max).\n")
    print("| config | scenario | arm | trials | wall s | TTFB s | server CPU s | avg busy cores | speedup vs 1 thr | efficiency | other CPU (cores) |")
    print("|---|---|---|---|---|---|---|---|---|---|---|")
    g = defaultdict(list)
    for r in A:
        g[(r["config"], r["scenario"], r["fast"], r["trial"])].append(r)
    agg = {}
    for (cfg, scen, fast, tr), rs in g.items():
        wall = st.mean(r["wall_s"] for r in rs)
        agg.setdefault((cfg, scen, fast), []).append(dict(
            wall=wall,
            ttfb=st.mean(r["ttfb_s"] for r in rs),
            cpu=st.mean(r["srv_cpu_s"] for r in rs),
            cores=st.mean(r["srv_cpu_s"] / r["wall_s"] for r in rs),
            other=st.mean((r["sys_busy_cores"] or 0) - r["srv_cpu_s"] / r["wall_s"] for r in rs),
            bytes=rs[0]["bytes"]))
    order = ["1", "2", "4", "8", "8pin"]
    for scen in ("cold", "warm"):
        one = agg.get(("1", scen, "1"))
        w1 = st.median(t["wall"] for t in one) if one else None
        for cfg in order:
            for fast in ("1", "0"):
                ts = agg.get((cfg, scen, fast))
                if not ts:
                    continue
                w = st.median(t["wall"] for t in ts)
                n = int(cfg.rstrip("pin"))
                sp = w1 / w if (w1 and fast == "1") else None
                eff = sp / n if sp else None
                print(f"| {cfg} | {scen} | {'v2' if fast == '1' else 'base'} | {len(ts)} | "
                      f"{med_rng([t['wall'] for t in ts])} | {med_rng([t['ttfb'] for t in ts])} | "
                      f"{med_rng([t['cpu'] for t in ts], '{:.1f}')} | {med_rng([t['cores'] for t in ts])} | "
                      f"{'%.2fx' % sp if sp else '-'} | {'%.0f%%' % (100 * eff) if eff else '-'} | "
                      f"{med_rng([t['other'] for t in ts])} |")
    print()
    # Amdahl fit T(N) = s + p/N on warm and cold medians
    for scen in ("cold", "warm"):
        pts = []
        for cfg in ("1", "2", "4", "8"):
            ts = agg.get((cfg, scen, "1"))
            if ts:
                pts.append((int(cfg), st.median(t["wall"] for t in ts)))
        if len(pts) >= 3:
            xs = [1 / n for n, _ in pts]
            ys = [w for _, w in pts]
            mx, my = st.mean(xs), st.mean(ys)
            p = sum((x - mx) * (y - my) for x, y in zip(xs, ys)) / sum((x - mx) ** 2 for x in xs)
            s = my - p * mx
            kf = []
            w1 = dict(pts)[1]
            for n, w in pts:
                if n > 1:
                    S = w1 / w
                    kf.append(f"N={n}: {(1 / S - 1 / n) / (1 - 1 / n):.2f}")
            print(f"Amdahl fit ({scen}): T(N) = {s:.2f} s serial + {p:.2f} s / N  "
                  f"→ serial fraction {s / (s + p):.0%} of the 1-thread time, "
                  f"max speedup {(s + p) / s:.1f}x; Karp–Flatt e: {', '.join(kf)}\n")

# ------------------------------------------------------------------ phase B
def load_csv(path):
    return list(csv.DictReader(open(path)))


def intervals_overlap_series(iv, t0, t1, step):
    """iv: list of (a, b). Returns list of (t, mean concurrency in bin)."""
    nb = int((t1 - t0) / step) + 1
    acc = [0.0] * nb
    for a, b in iv:
        a = max(a, t0)
        b = min(b, t1)
        if b <= a:
            continue
        i = int((a - t0) / step)
        while a < b and i < nb:
            be = t0 + (i + 1) * step
            acc[i] += (min(b, be) - a) / step
            a = be
            i += 1
    return acc


def mean_conc(iv, a, b):
    if b <= a:
        return 0.0
    tot = 0.0
    for x, y in iv:
        lo, hi = max(x, a), min(y, b)
        if hi > lo:
            tot += hi - lo
    return tot / (b - a)


Bq = {(r["config"], r["scenario"], r["iter"]): r for r in rows if r["phase"] == "B" and r["scenario"] in ("cold", "warm")}
bdirs = sorted(glob.glob(os.path.join(RUN, "B", "j*", "*")))
cells = [d for d in bdirs if os.path.isdir(d) and glob.glob(os.path.join(d, "v2diag-*-coord.csv"))]
if cells:
    print("## Phase B — phase breakdown and utilisation (diag binary)\n")
    summary = []
    for d in cells:
        n = os.path.basename(os.path.dirname(d))[1:]
        cell = os.path.basename(d)
        scen = "cold" if cell.startswith("cold") else "warm"
        coordf = glob.glob(os.path.join(d, "v2diag-*-coord.csv"))[0]
        pre = coordf[:-len("-coord.csv")]
        ev = load_csv(coordf)
        mo = load_csv(pre + "-morsels.csv")
        sl = load_csv(pre + "-slots.csv")
        E = defaultdict(list)
        for e in ev:
            E[e["kind"]].append((int(e["index"]), int(e["t_ns"]), int(e["value"])))
        coord_tid = E["enter"][0][2]
        # query start/end from queries.csv: B rows are written in order; match by
        # the time window (start_mono <= enter).
        qrow = None
        for r in rows:
            if r["phase"] == "B" and r["config"] == n and r["scenario"] == scen:
                s0 = int(r["start_mono_ns"])
                if s0 <= E["enter"][0][1] <= s0 + r["wall_s"] * NS:
                    qrow = r
        t_start = int(qrow["start_mono_ns"]) if qrow else E["enter"][0][1]
        t_end = t_start + (qrow["wall_s"] * NS if qrow else 0)
        T = lambda k, i=0: E[k][i][1] if E[k] else None
        t_enter, t_hdr, t_hdr_res = T("enter"), T("header_yield"), T("header_resumed")
        t_res, t_plan, t_subd, t_drain = T("getresult_done"), T("plan_begin"), T("submit_done"), T("drain_done")
        subs = sorted(t for _, t, _ in E["submit"])
        t_first_sub = subs[0] if subs else t_plan
        iv = [(int(m["t0_ns"]), int(m["t1_ns"])) for m in mo]
        helpers = [m for m in mo if int(m["tid"]) != coord_tid]
        inline = [m for m in mo if int(m["tid"]) == coord_tid]
        pool_tids = sorted({int(m["tid"]) for m in helpers})
        rows_tot = sum(int(m["rows"]) for m in mo)
        cpu_tot = sum(int(m["cpu_ns"]) for m in mo) / NS
        wall_tot = sum(int(m["t1_ns"]) - int(m["t0_ns"]) for m in mo) / NS
        # queue length = submitted - started (slots)
        started = sorted(int(s["started_ns"]) for s in sl if int(s["started_ns"]) > 0)
        # consume/yield timing
        cb = {i: t for i, t, _ in E["consume_begin"]}
        ce = {i: t for i, t, _ in E["consume_end"]}
        yr = {i: t for i, t, _ in E["yield_resumed"]}
        wait_consume = sum(ce[i] - cb[i] for i in ce if i in cb) / NS
        wait_yield = sum(yr[i] - ce[i] for i in yr if i in ce) / NS
        first_morsel_out = min(ce.values()) if ce else None
        # phases
        ph = [
            ("request → V2 enter (parse, plan)", t_start, t_enter),
            ("enter → lazy result handle", t_enter, t_res),
            ("submit phase (lazy join + morsel planning on coordinator)", t_res, t_subd),
            ("drain phase (consume + emit)", t_subd, t_drain),
            ("tail (last emit → client done)", t_drain, t_end),
        ]
        # sampler
        smp = load_csv(os.path.join(d, "sampler.csv"))
        by_tid = defaultdict(list)
        sysrows = []
        for s in smp:
            if s["tid"] == "0":
                sysrows.append((int(s["t_ns"]), int(s["utime"]), int(s["stime"])))
            else:
                by_tid[int(s["tid"])].append((int(s["t_ns"]), int(s["run_ns"]), int(s["wait_ns"]), s["state"], s["wchan"], s["comm"]))

        def role(tid):
            if tid == coord_tid:
                return "coordinator"
            if tid in pool_tids:
                return "pool (morsel helpers)"
            return "other"

        def oncpu_between(tid, a, b):
            ss = by_tid[tid]
            ra = rb = None
            for t, run, wt, *_ in ss:
                if t <= a:
                    ra = (run, wt)
                if t <= b:
                    rb = (run, wt)
            if ra is None and ss:
                ra = (ss[0][1], ss[0][2])
            if rb is None or ra is None:
                return 0.0, 0.0
            return (rb[0] - ra[0]) / NS, (rb[1] - ra[1]) / NS

        print(f"### {n} thread(s), {scen} ({cell})\n")
        print(f"- client: wall {qrow['wall_s']:.2f} s, TTFB {qrow['ttfb_s']:.2f} s, {qrow['bytes'] / 1e6:.0f} MB, server CPU {qrow['srv_cpu_s']:.1f} s" if qrow else "- client row not found")
        print(f"- morsels: {len(mo)} executions ({len(helpers)} on {len(pool_tids)} pool threads, {len(inline)} inline on coordinator), "
              f"{rows_tot:,} rows, morsel CPU {cpu_tot:.1f} s, morsel wall {wall_tot:.1f} s "
              f"(off-CPU inside morsels {100 * (1 - cpu_tot / wall_tot):.0f}%), {1e9 * cpu_tot / max(rows_tot, 1):.0f} ns CPU/row")
        if t_hdr is not None:
            print(f"- header chunk yielded at +{(t_hdr - t_start) / NS:.3f} s; coordinator resumed after header at +{(t_hdr_res - t_start) / NS:.3f} s; "
                  f"first morsel consumed at +{(first_morsel_out - t_start) / NS:.3f} s" if first_morsel_out else "")
        print(f"- coordinator: waited {wait_consume:.2f} s in consumeNextResult (incl. inline morsels), "
              f"{wait_yield:.2f} s suspended in co_yield (finalize + hand-off to the HTTP stream queue)")
        print()
        print("| phase | start s | dur s | busy morsels (mean) | max | queued morsels (mean) | coordinator on-CPU | pool on-CPU (cores) | other on-CPU | runqueue wait (cores) |")
        print("|---|---|---|---|---|---|---|---|---|---|")
        for name, a, b in ph:
            if a is None or b is None or b <= a:
                print(f"| {name} | - | - | | | | | | | |")
                continue
            conc = mean_conc(iv, a, b)
            ser = intervals_overlap_series(iv, a, b, 2e6)
            mx = max(ser) if ser else 0
            # queued: integrate (submitted - started) over [a,b]
            pts = sorted([(t, 1) for t in subs] + [(t, -1) for t in started])
            q = 0
            last = a
            area = 0.0
            for t, dv in pts:
                if t > b:
                    break
                if t > a:
                    area += q * (t - last)
                    last = t
                q += dv
                if t <= a:
                    last = a
            area += q * (b - max(last, a))
            dur = (b - a) / NS
            agg = defaultdict(float)
            rq = 0.0
            for tid in by_tid:
                on, wt = oncpu_between(tid, a, b)
                agg[role(tid)] += on
                rq += wt
            print(f"| {name} | {(a - t_start) / NS:.2f} | {dur:.2f} | {conc:.2f} | {mx:.1f} | {area / (b - a):.1f} | "
                  f"{agg['coordinator'] / dur:.2f} | {agg['pool (morsel helpers)'] / dur:.2f} | {agg['other'] / dur:.2f} | {rq / dur:.2f} |")
        print()
        # wchan histogram for pool + coordinator when sleeping during export window
        wc = defaultdict(Counter)
        for tid, ss in by_tid.items():
            for t, run, wt, state, wch, comm in ss:
                if t_res and t_drain and t_res <= t <= t_drain:
                    wc[role(tid)][f"{state}:{wch}"] += 1
        for r_, c in wc.items():
            tot = sum(c.values())
            top = ", ".join(f"{k} {100 * v / tot:.0f}%" for k, v in c.most_common(5))
            print(f"- {r_} thread states during submit+drain (sampled): {top}")
        print()
        # thread-counts (perf report -T): cycles / instructions / task-clock per tid
        tc = os.path.join(d, "thread-counts.txt")
        if os.path.exists(tc):
            lines = open(tc).read().splitlines()
            hdr = None
            per = defaultdict(lambda: defaultdict(float))
            for ln in lines:
                if "PID" in ln and "TID" in ln:
                    hdr = ln.replace("#", " ").split()
                    continue
                p = ln.split()
                if hdr and len(p) >= 4 and p[1].isdigit():
                    tid = int(p[1])
                    vals = p[2:]
                    names = hdr[2:]
                    for k, v in zip(names, vals):
                        try:
                            per[role(tid)][k] += float(v)
                        except ValueError:
                            pass
            for r_, v in per.items():
                cyc = v.get("cycles", 0)
                ins = v.get("instructions", 0)
                tclk = v.get("task-clock", 0)
                if tclk > 0 and cyc > 0:
                    print(f"- perf counters {r_}: task-clock {tclk / 1e9:.1f} s, {cyc / tclk:.2f} GHz effective, IPC {ins / cyc:.2f}")
            print()
        # timeline CSV
        a0, a1 = t_start, max(t_end, t_drain or t_end)
        step = 50e6
        conc_s = intervals_overlap_series(iv, a0, a1, step)
        tl = os.path.join(OUT, f"timeline-j{n}-{cell}.csv")
        with open(tl, "w") as f:
            f.write("t_s,busy_morsels,coord_cpu,pool_cpu,other_cpu,submitted,started\n")
            nb = len(conc_s)
            for i in range(nb):
                a, b = a0 + i * step, a0 + (i + 1) * step
                agg = defaultdict(float)
                for tid in by_tid:
                    on, _ = oncpu_between(tid, a, b)
                    agg[role(tid)] += on
                subm = sum(1 for t in subs if t <= b)
                stt = sum(1 for t in started if t <= b)
                f.write(f"{(a - a0) / NS:.3f},{conc_s[i]:.2f},{agg['coordinator'] / (step / NS):.2f},"
                        f"{agg['pool (morsel helpers)'] / (step / NS):.2f},{agg['other'] / (step / NS):.2f},{subm},{stt}\n")
        summary.append(dict(n=n, cell=cell, tl=tl, marks={k: (v - a0) / NS for k, v in
                                                          dict(header=t_hdr, result=t_res, submit_done=t_subd, drain_done=t_drain, end=t_end).items() if v}))
    # figures
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        plain = [s for s in summary if s["cell"] in ("cold", "warm")]
        if plain:
            fig, axes = plt.subplots(len(plain), 1, figsize=(11, 2.3 * len(plain)), sharex=True)
            if len(plain) == 1:
                axes = [axes]
            for ax, s in zip(axes, plain):
                data = list(csv.DictReader(open(s["tl"])))
                t = [float(x["t_s"]) for x in data]
                ax.stackplot(t, [float(x["coord_cpu"]) for x in data], [float(x["pool_cpu"]) for x in data],
                             [float(x["other_cpu"]) for x in data],
                             labels=["(1) coordinator on-CPU", "(2) pool threads on-CPU", "(3) other server threads"],
                             colors=["#d62728", "#1f77b4", "#7f7f7f"], alpha=0.8)
                ax.plot(t, [float(x["busy_morsels"]) for x in data], color="black", lw=1, label="morsels running")
                for k, v in s["marks"].items():
                    ax.axvline(v, color="#2ca02c", lw=0.8, ls="--")
                    ax.text(v, ax.get_ylim()[1] * 0.92 if ax.get_ylim()[1] else 1, k, fontsize=7, rotation=90, va="top")
                ax.set_ylabel(f"j{s['n']} {s['cell']}\ncores")
                ax.set_ylim(0, max(int(s["n"]) + 2, 3))
            axes[0].legend(loc="upper right", fontsize=7, ncol=4)
            axes[-1].set_xlabel("seconds since request start")
            fig.tight_layout()
            fig.savefig(os.path.join(OUT, "timelines.svg"))
            fig.savefig(os.path.join(OUT, "timelines.png"), dpi=110)
    except Exception as exc:  # noqa: BLE001
        print(f"(figure failed: {exc})")

# ------------------------------------------------------------------ phase C
C = [r for r in rows if r["phase"] == "C" and r["scenario"] == "warm"]
if C:
    print("## Phase C — client / socket check (8 threads, warm, original binary)\n")
    print("| client | trials | wall s | TTFB s | client CPU s | throughput MB/s |")
    print("|---|---|---|---|---|---|")
    g = defaultdict(list)
    for r in C:
        g[(r["client"], r["trial"])].append(r)
    byc = defaultdict(list)
    for (cl, tr), rs in g.items():
        byc[cl].append(dict(w=st.mean(r["wall_s"] for r in rs), t=st.mean(r["ttfb_s"] for r in rs),
                            c=st.mean(float(r["client_cpu_s"]) for r in rs if r["client_cpu_s"] not in ("-", "")),
                            mb=st.mean(r["bytes"] / r["wall_s"] / 1e6 for r in rs)))
    for cl, ts in byc.items():
        print(f"| {cl} | {len(ts)} | {med_rng([t['w'] for t in ts])} | {med_rng([t['t'] for t in ts])} | "
              f"{med_rng([t['c'] for t in ts])} | {med_rng([t['mb'] for t in ts], '{:.0f}')} |")
    print()
    # ss: last tcp_info sample per query
    lim = defaultdict(list)
    for f in sorted(glob.glob(os.path.join(RUN, "C", "ss-*.txt"))):
        txt = open(f).read()
        blocks = [b for b in txt.split("T ") if "busy:" in b]
        if not blocks:
            continue
        last = blocks[-1]
        cl = os.path.basename(f).split("-")[2]
        m = {k: re.search(k + r":(\d+)ms", last) for k in ("busy", "rwnd_limited", "sndbuf_limited")}
        vals = {k: int(v.group(1)) if v else 0 for k, v in m.items()}
        lim[cl].append(vals)
    for cl, vs in lim.items():
        b = st.median(v["busy"] for v in vs)
        print(f"- {cl}: socket busy {b / 1000:.2f} s, rwnd_limited {st.median(v['rwnd_limited'] for v in vs) / 1000:.2f} s, "
              f"sndbuf_limited {st.median(v['sndbuf_limited'] for v in vs) / 1000:.2f} s (median of last tcp_info samples)")
    print()
