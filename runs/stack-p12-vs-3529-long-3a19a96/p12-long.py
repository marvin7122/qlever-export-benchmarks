#!/usr/bin/env python3
"""Stack part 12 (#3539) long A/B: time per query and time to first byte.

Arms (DBLP, warm page cache, QLever result cache cleared before every request):
  base  = #3529 binary (upstream-stack/09 @ BASE_SHA)
  off   = #3539 binary (upstream-stack/22 @ P12_SHA), adaptive-export-chunk-size=false
  on    = part 12 binary, adaptive-export-chunk-size=true
One measurement = one query repeated back-to-back until >= MIN_S seconds of
request time; it yields the mean time per query and the median / min / max
time to first body byte over its requests. TRIALS trials per arm, arm order
rotated per trial (interleaved). Servers pinned to SERVER_CPUS, client to
CLIENT_CPU. Every response body is hashed (xxh3-128); all hashes of a query
must agree across arms.
"""
import json
import os
import statistics as st
import subprocess
import sys
import time
from pathlib import Path

import httpx
import xxhash

U = Path("/local/data-ssd/stoetzem")
BASE_SHA = os.environ["BASE_SHA"]
P12_SHA = os.environ["P12_SHA"]
RUN = Path(os.environ["RUN_DIR"])
TRIALS = int(os.environ.get("TRIALS", "10"))
MIN_S = float(os.environ.get("MIN_S", "10"))
SERVER_CPUS = os.environ.get("SERVER_CPUS", "0-7")
CLIENT_CPU = os.environ.get("CLIENT_CPU", "12")
INDEX = U / "dblp" / "dblp"
QDIR = U / "thesis" / "representative-queries"
FLAG = "adaptive-export-chunk-size"
QUERIES = [
    ("H-vocab-title-large-select", "tsv_export", "text/tab-separated-values"),
    ("H-size-select", "tsv_export", "text/tab-separated-values"),
    ("R2-select", "csv_export", "text/csv"),
]

RUN.mkdir(parents=True, exist_ok=True)
os.sched_setaffinity(0, {int(CLIENT_CPU)})


def log(msg):
    line = f"[{time.strftime('%H:%M:%S')}] {msg}"
    print(line, flush=True)
    with open(RUN / "driver.log", "a") as f:
        f.write(line + "\n")


def start_server(name, sha, port):
    binary = U / "bin-cache" / sha / "qlever-server"
    cmd = ["taskset", "-c", SERVER_CPUS, str(binary),
           "--index-basename", str(INDEX), "--port", str(port),
           "--no-access-check", "--cache-max-size", "0B",
           "--cache-max-size-single-entry", "0B",
           "--cache-max-size-lazy-result", "0B",
           "--cache-max-num-entries", "0", "--default-query-timeout", "1800s"]
    out = open(RUN / f"server-{name}.log", "wb")
    proc = subprocess.Popen(cmd, cwd=INDEX.parent, stdout=out,
                            stderr=subprocess.STDOUT, start_new_session=True)
    url = f"http://127.0.0.1:{port}/"
    for _ in range(600):
        try:
            if httpx.get(url, params={"cmd": "stats"}, timeout=2).status_code == 200:
                log(f"server {name} ({sha[:10]}) ready on {port}")
                return proc, url
        except Exception:
            pass
        if proc.poll() is not None:
            sys.exit(f"server {name} exited early")
        time.sleep(0.5)
    sys.exit(f"server {name} not ready")


def set_flag(url, value):
    r = httpx.get(url, params={FLAG: "true" if value else "false"}, timeout=10)
    r.raise_for_status()
    s = httpx.get(url, params={"cmd": "get-settings"}, timeout=10).json()
    got = s.get(FLAG)
    if str(got).lower() != ("true" if value else "false"):
        sys.exit(f"flag not applied: {FLAG}={got}")


def request(url, query, action, accept):
    httpx.get(url, params={"cmd": "clear-cache"}, timeout=30)
    h = xxhash.xxh3_128()
    nbytes = 0
    first = None
    t0 = time.perf_counter_ns()
    with httpx.stream("POST", url, data={"query": query, "action": action},
                      headers={"Accept": accept},
                      timeout=httpx.Timeout(10.0, read=None)) as resp:
        if resp.status_code != 200:
            sys.exit(f"HTTP {resp.status_code}: {resp.read()[:500]!r}")
        for chunk in resp.iter_bytes():
            if first is None and chunk:
                first = time.perf_counter_ns() - t0
            nbytes += len(chunk)
            h.update(chunk)
    return (time.perf_counter_ns() - t0) / 1e9, first / 1e9, nbytes, h.hexdigest()


def measure(url, qtext, action, accept):
    elapsed, ttfb, hashes, nbytes = [], [], set(), 0
    while sum(elapsed) < MIN_S:
        e, f, n, d = request(url, qtext, action, accept)
        elapsed.append(e)
        ttfb.append(f)
        hashes.add(d)
        nbytes = n
    return elapsed, ttfb, hashes, nbytes


def main():
    base_proc, base_url = start_server("base", BASE_SHA, 7121)
    p12_proc, p12_url = start_server("p12", P12_SHA, 7122)
    arms = [("base", base_url, None), ("off", p12_url, False), ("on", p12_url, True)]
    rows = []
    try:
        for qname, action, accept in QUERIES:
            qtext = (QDIR / f"{qname}.rq").read_text()
            # One untimed warm-up request per arm.
            for arm, url, flag in arms:
                if flag is not None:
                    set_flag(url, flag)
                request(url, qtext, action, accept)
            for t in range(TRIALS):
                order = arms[t % 3:] + arms[:t % 3]
                for arm, url, flag in order:
                    if flag is not None:
                        set_flag(url, flag)
                    el, tf, hs, nb = measure(url, qtext, action, accept)
                    row = dict(query=qname, trial=t, arm=arm, n=len(el),
                               total_s=sum(el), per_query_s=sum(el) / len(el),
                               ttfb_median_s=st.median(tf), ttfb_min_s=min(tf),
                               ttfb_max_s=max(tf), bytes=nb, hashes=sorted(hs))
                    rows.append(row)
                    with open(RUN / "measurements.jsonl", "a") as f:
                        f.write(json.dumps(row) + "\n")
                    tcsv = RUN / "trials.csv"
                    new_file = not tcsv.exists()
                    with open(tcsv, "a") as f:
                        if new_file:
                            f.write("trial,arm,query,s_per_query,first_byte_s,requests,bytes,xxh3\n")
                        f.write(f"{t},{arm},{qname},{row['per_query_s']:.6f},"
                                f"{row['ttfb_median_s']:.6f},{row['n']},{nb},"
                                f"{'+'.join(sorted(hs))}\n")
                    log(f"{qname} t{t} {arm}: n={len(el)} per_query={row['per_query_s']:.4f}s "
                        f"ttfb_med={row['ttfb_median_s']:.4f}s")
    finally:
        for p in (base_proc, p12_proc):
            p.terminate()
            try:
                p.wait(20)
            except Exception:
                p.kill()
    summarize(rows)


def summarize(rows):
    lines = ["| query | arm | trials | requests/measurement | time per query median (min–max) | TTFB median of medians (min–max) | Δ time vs base | Δ TTFB vs base | byte-identical |",
             "|---|---|---|---|---|---|---|---|---|"]
    ok_all = True
    for qname, _, _ in QUERIES:
        qrows = [r for r in rows if r["query"] == qname]
        allh = {h for r in qrows for h in r["hashes"]}
        ident = len(allh) == 1
        ok_all &= ident
        med = {}
        for arm in ("base", "off", "on"):
            ar = [r for r in qrows if r["arm"] == arm]
            pq = [r["per_query_s"] for r in ar]
            tf = [r["ttfb_median_s"] for r in ar]
            med[arm] = (st.median(pq), st.median(tf))
            dt = "" if arm == "base" else f"{(med[arm][0] / med['base'][0] - 1) * 100:+.2f} %"
            dtf = "" if arm == "base" else f"{(med[arm][1] / med['base'][1] - 1) * 100:+.2f} %"
            lines.append(f"| {qname} | {arm} | {len(ar)} | {min(r['n'] for r in ar)}–{max(r['n'] for r in ar)} | "
                         f"{st.median(pq):.4f} s ({min(pq):.4f}–{max(pq):.4f}) | "
                         f"{st.median(tf) * 1000:.2f} ms ({min(tf) * 1000:.2f}–{max(tf) * 1000:.2f}) | "
                         f"{dt} | {dtf} | {'yes' if ident else 'NO'} |")
        pq_off = [r["per_query_s"] for r in qrows if r["arm"] == "off"]
        pq_on = [r["per_query_s"] for r in qrows if r["arm"] == "on"]
        tf_off = [r["ttfb_median_s"] for r in qrows if r["arm"] == "off"]
        tf_on = [r["ttfb_median_s"] for r in qrows if r["arm"] == "on"]
        lines.append(f"| {qname} | on vs off | | | {(st.median(pq_on) / st.median(pq_off) - 1) * 100:+.2f} % "
                     f"(ranges {'overlap' if max(pq_on) >= min(pq_off) and max(pq_off) >= min(pq_on) else 'disjoint'}) | "
                     f"{(st.median(tf_on) / st.median(tf_off) - 1) * 100:+.2f} % "
                     f"(ranges {'overlap' if max(tf_on) >= min(tf_off) and max(tf_off) >= min(tf_on) else 'disjoint'}) | | | |")
    header = (f"# #3539 long A/B\n\nbase {BASE_SHA} (upstream-stack/09, #3529), "
              f"#3539 {P12_SHA} (upstream-stack/22); DBLP, warm page cache, QLever result cache "
              f"cleared before every request; {TRIALS} interleaved trials per arm; one measurement = "
              f"query repeated for >= {MIN_S:.0f} s; servers pinned to CPUs {SERVER_CPUS}, client to CPU "
              f"{CLIENT_CPU}; host {os.uname().nodename}.\n\n")
    (RUN / "summary.md").write_text(header + "\n".join(lines) + "\n")
    log("summary written; byte-identical all queries: " + str(ok_all))
    print("\n".join(lines))


if __name__ == "__main__":
    main()
