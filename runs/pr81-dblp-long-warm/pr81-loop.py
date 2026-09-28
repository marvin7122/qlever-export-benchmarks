#!/usr/bin/env python3
"""pr81-loop.py — long, interleaved end-to-end A/B for PR #81 / upstream #3529.

One measurement = one query run back-to-back N times against one arm's
qlever-server (same N for every arm, calibrated so the base arm needs >= the
target seconds). Every arm has its own server, started once on its own port and
pinned to the same cores; only one server is busy at a time. Trials interleave
the arms (odd trials in arm order, even trials reversed). Every response is
hashed (xxh3-128) and must equal the base arm's hash (byte-identical output).
perf stat (task-clock, cycles, instructions, cache-misses) runs around every
measured loop. Optional: one perf record per arm and query (flame graphs +
diff against the base) and allocation-count arms (servers built with
QLEVER_COUNT_ALLOCATIONS log "Heap allocations during the export: N (B bytes)").

Arm spec: name=binary[,rp=value]...   e.g.  p9=/path/qlever-server
          on=/path/qlever-server,use-fast-export-stream-formatter=true
"""
import argparse, csv, json, math, os, re, statistics, subprocess, sys, time
from pathlib import Path
import httpx, xxhash

READY = "The server is ready, listening for requests on port "
ALLOC = re.compile(r"Heap allocations during the export: (\d+) \((\d+) bytes\)")
EVENTS = "task-clock,cycles,instructions,cache-misses"


def parse_arm(spec):
    name, rest = spec.split("=", 1)
    parts = rest.split(",")
    return {"name": name, "bin": parts[0], "rps": parts[1:]}


def start(arm, port, a, out):
    cmd = ["taskset", "-c", a.server_cores, arm["bin"], "--index-basename", a.index_basename,
           "--port", str(port), "--no-access-check", "--cache-max-size", "0B",
           "--cache-max-size-single-entry", "0B", "--cache-max-size-lazy-result", "0B",
           "--cache-max-num-entries", "0", "--default-query-timeout", "3600s",
           "--num-simultaneous-queries", "1"]
    for rp in arm["rps"]:
        cmd += ["--set-runtime-parameter", rp]
    log = out / f"server-{arm['name']}.log"
    arm["log"] = log
    arm["port"] = port
    arm["cmd"] = cmd
    arm["proc"] = subprocess.Popen(cmd, cwd=Path(a.index_basename).parent, stdout=log.open("wb"),
                                   stderr=subprocess.STDOUT, start_new_session=True)
    deadline = time.time() + 600
    while time.time() < deadline:
        if READY in log.read_text(errors="replace"):
            return
        if arm["proc"].poll() is not None:
            sys.exit(f"server {arm['name']} exited: see {log}")
        time.sleep(1)
    sys.exit(f"server {arm['name']} not ready")


def request(arm, query, action, accept):
    h = xxhash.xxh3_128()
    n = 0
    with httpx.stream("POST", f"http://127.0.0.1:{arm['port']}/",
                      data={"query": query, "action": action}, headers={"Accept": accept},
                      timeout=httpx.Timeout(connect=10.0, read=None, write=10.0, pool=10.0)) as r:
        if r.status_code != 200:
            raise RuntimeError(f"{arm['name']}: HTTP {r.status_code}: {r.read()[:500]!r}")
        for chunk in r.iter_bytes():
            n += len(chunk)
            h.update(chunk)
    return h.hexdigest(), n


def clear_cache(arm):
    httpx.get(f"http://127.0.0.1:{arm['port']}/", params={"cmd": "clear-cache"}, timeout=30)


def loop(arm, qtext, a, reps, ref, stat_file=None):
    perf = None
    if stat_file is not None:
        perf = subprocess.Popen(["perf", "stat", "-x,", "-e", EVENTS, "-p", str(arm["proc"].pid),
                                 "-o", str(stat_file)])
        time.sleep(0.3)
    t0 = time.perf_counter()
    for _ in range(reps):
        clear_cache(arm)
        d, n = request(arm, qtext, a.action, a.accept)
        if ref is not None and (d, n) != ref:
            raise RuntimeError(f"{arm['name']}: output differs from base ({d},{n}) != {ref}")
    el = time.perf_counter() - t0
    counters = {}
    if perf is not None:
        perf.send_signal(2)
        perf.wait()
        for line in stat_file.read_text().splitlines():
            p = line.split(",")
            if len(p) > 3 and p[0] and p[2]:
                try:
                    counters[p[2]] = float(p[0])
                except ValueError:
                    pass
    return el, counters


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--arm", action="append", required=True, help="first arm = base")
    ap.add_argument("--alloc-arm", action="append", default=[])
    ap.add_argument("--query", action="append", required=True)
    ap.add_argument("--index-basename", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--trials", type=int, default=10)
    ap.add_argument("--target-seconds", type=float, default=10.0)
    ap.add_argument("--server-cores", default="2-7")
    ap.add_argument("--client-core", default="1")
    ap.add_argument("--action", default="turtle_export")
    ap.add_argument("--accept", default="text/turtle")
    ap.add_argument("--perf-record", action="store_true")
    ap.add_argument("--flamegraph-dir", default="/local/data-ssd/stoetzem/FlameGraph")
    a = ap.parse_args()
    os.sched_setaffinity(0, {int(c) for c in a.client_core.split(",")})
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    arms = [parse_arm(s) for s in a.arm]
    allocs = [parse_arm(s) for s in a.alloc_arm]
    meta = {"argv": sys.argv, "start_utc": time.strftime("%FT%TZ", time.gmtime()),
            "uname": os.uname().release, "loadavg_start": os.getloadavg()}
    port = 7301
    for arm in arms + allocs:
        start(arm, port, a, out)
        port += 1
        ver = subprocess.run([arm["bin"], "--version"], capture_output=True, text=True).stdout.strip()
        arm["version"] = ver
    meta["arms"] = [{k: v for k, v in x.items() if k not in ("proc", "log")} | {"log": str(x["log"])}
                    for x in arms + allocs]
    queries = [(Path(q).stem, Path(q).read_text()) for q in a.query]
    rows = []
    summary = []
    try:
        for qid, qtext in queries:
            # Warm-up: one untimed request per arm; the base's bytes are the reference.
            ref = None
            base_t = None
            for arm in arms:
                clear_cache(arm)
                t = time.perf_counter()
                d, n = request(arm, qtext, a.action, a.accept)
                if ref is None:
                    ref, base_t = (d, n), time.perf_counter() - t
                elif (d, n) != ref:
                    raise RuntimeError(f"warm-up {qid} {arm['name']}: output differs from base")
            reps = max(1, math.ceil(a.target_seconds / base_t))
            print(f"{qid}: base warm-up {base_t:.3f} s, {reps} requests per measurement, "
                  f"{ref[1]} bytes, xxh3 {ref[0]}", flush=True)
            for trial in range(1, a.trials + 1):
                order = arms if trial % 2 else list(reversed(arms))
                for arm in order:
                    sf = out / "perf-stat" / qid / f"{arm['name']}-t{trial}.csv"
                    sf.parent.mkdir(parents=True, exist_ok=True)
                    el, c = loop(arm, qtext, a, reps, ref, sf)
                    rows.append({"query": qid, "arm": arm["name"], "trial": trial, "requests": reps,
                                 "seconds": round(el, 4), "s_per_query": round(el / reps, 5),
                                 "bytes_per_query": ref[1], "xxh3": ref[0],
                                 **{k: c.get(k, "") for k in EVENTS.split(",")}})
                    print(f"  t{trial} {arm['name']}: {el:.2f} s, {el / reps:.4f} s/query", flush=True)
            base_med = None
            for arm in arms:
                r = [x for x in rows if x["query"] == qid and x["arm"] == arm["name"]]
                s = sorted(x["s_per_query"] for x in r)
                med = statistics.median(s)
                ins = statistics.median(float(x["instructions"]) / x["requests"] for x in r if x["instructions"] != "")
                cyc = statistics.median(float(x["cycles"]) / x["requests"] for x in r if x["cycles"] != "")
                if base_med is None:
                    base_med, base_min, base_max = med, s[0], s[-1]
                d = 100 * (med - base_med) / base_med
                overlap = not (s[-1] < base_min or s[0] > base_max)
                verdict = "base" if arm is arms[0] else (
                    "parity" if overlap or abs(d) < 2 else ("faster" if d < 0 else "slower"))
                summary.append({"query": qid, "arm": arm["name"], "trials": len(s), "requests": reps,
                                "median_s_per_query": round(med, 5), "min": s[0], "max": s[-1],
                                "delta_vs_base_pct": round(d, 2), "verdict": verdict,
                                "instructions_per_query": round(ins), "cycles_per_query": round(cyc),
                                "bytes_per_query": ref[1]})
            if a.perf_record:
                fd = Path(a.flamegraph_dir)
                for arm in arms:
                    pd = out / "perf" / qid
                    pd.mkdir(parents=True, exist_ok=True)
                    data = pd / f"{arm['name']}.data"
                    p = subprocess.Popen(["perf", "record", "-g", "-F", "999", "-o", str(data), "-p",
                                          str(arm["proc"].pid)], stderr=subprocess.DEVNULL)
                    time.sleep(0.5)
                    loop(arm, qtext, a, max(1, reps // 2), ref)
                    p.send_signal(2)
                    p.wait()
                    folded = pd / f"{arm['name']}.folded"
                    with folded.open("w") as f:
                        s1 = subprocess.Popen(["perf", "script", "-i", str(data)], stdout=subprocess.PIPE,
                                              stderr=subprocess.DEVNULL)
                        subprocess.run(["perl", str(fd / "stackcollapse-perf.pl")], stdin=s1.stdout, stdout=f)
                        s1.wait()
                    with (pd / f"{arm['name']}.svg").open("w") as f:
                        subprocess.run(["perl", str(fd / "flamegraph.pl"), str(folded)], stdout=f)
                    data.unlink()
                base = pd / f"{arms[0]['name']}.folded"
                for arm in arms[1:]:
                    with (pd / f"diff-{arms[0]['name']}-vs-{arm['name']}.svg").open("w") as f:
                        d1 = subprocess.Popen(["perl", str(fd / "difffolded.pl"), "-n", str(base),
                                               str(pd / f"{arm['name']}.folded")], stdout=subprocess.PIPE)
                        subprocess.run(["perl", str(fd / "flamegraph.pl"), "--title",
                                        f"{qid}: {arms[0]['name']} -> {arm['name']} (red = more in {arm['name']})"],
                                       stdin=d1.stdout, stdout=f)
                        d1.wait()
            # Allocation counts: one request per alloc arm; the server logs one line per export.
            for arm in allocs:
                clear_cache(arm)
                d, n = request(arm, qtext, a.action, a.accept)
                time.sleep(1)
                m = ALLOC.findall(arm["log"].read_text(errors="replace"))
                cnt, byt = (int(m[-1][0]), int(m[-1][1])) if m else (None, None)
                summary.append({"query": qid, "arm": arm["name"], "alloc_count": cnt, "alloc_bytes": byt,
                                "bytes_per_query": n, "identical_to_base": (d, n) == ref})
                print(f"  alloc {arm['name']}: {cnt} allocations, {byt} bytes, output identical: {(d, n) == ref}",
                      flush=True)
    finally:
        for arm in arms + allocs:
            arm["proc"].terminate()
            try:
                arm["proc"].wait(30)
            except subprocess.TimeoutExpired:
                arm["proc"].kill()
        meta["end_utc"] = time.strftime("%FT%TZ", time.gmtime())
        meta["loadavg_end"] = os.getloadavg()
        (out / "meta.json").write_text(json.dumps(meta, indent=1, default=str))
        if rows:
            with (out / "trials.csv").open("w", newline="") as f:
                w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
                w.writeheader()
                w.writerows(rows)
        (out / "summary.json").write_text(json.dumps(summary, indent=1))
    for s in summary:
        print(json.dumps(s))


if __name__ == "__main__":
    main()
