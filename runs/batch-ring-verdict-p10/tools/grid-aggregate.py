#!/usr/bin/env python3
"""Aggregate a pr-ab-grid.sh run: one table per scenario and query.

Usage: grid-aggregate.py <run-dir>   (prints Markdown)

Per arm: n, wall median [min-max], delta of the median vs the first arm,
verdict (faster/slower only if the min-max ranges are disjoint and
|delta| >= 2 %), process CPU (utime+stime, all threads), wall - CPU, the
hottest thread's CPU (export thread) and wall - that ("export-thread
stall"), mean device queue depth (aqu-sz, summed over GRID_DEVS), max
device utilisation, process read_bytes. Correctness: number of distinct
body digests per query over all arms and reps (1 = identical output).
"""
import csv, json, os, statistics as st, sys
from collections import defaultdict

run = sys.argv[1]
meta = {}
for line in open(os.path.join(run, "meta.env")):
    if "=" in line:
        k, v = line.rstrip("\n").split("=", 1)
        meta[k] = v.strip("'")
arms = [a.split("=", 1)[0] for a in meta["GRID_ARMS"].split(";") if a]
qids = meta["QUERY_IDS"].split(",")
scens = meta["SCENARIOS"].split(",")

dig = defaultdict(set)
cpath = os.path.join(run, "correctness.tsv")
if os.path.exists(cpath):
    for row in csv.reader(open(cpath), delimiter="\t"):
        scen, qid, arm, rep, ordered, d = row[:6]
        try:
            j = json.loads(d)
            dig[qid].add((j["bytes"], j["lines"], j["multiset"]))
        except ValueError:
            dig[qid].add(("bad", d))

def med(v):
    v = [x for x in v if x is not None]
    return (st.median(v), min(v), max(v)) if v else None

def fmt(m, p=2, scale=1.0):
    if m is None:
        return "n/a"
    return f"{m[0]*scale:.{p}f} [{m[1]*scale:.{p}f}–{m[2]*scale:.{p}f}]"

for scen in scens:
    for qid in qids:
        print(f"### {scen} / {qid}\n")
        print("| # | arm | n | wall s | Δ wall vs " + arms[0] + " | verdict | CPU s | wall−CPU s | export-thread CPU s | wall−export-thread s | aqu-sz | util max | read GiB |")
        print("|---|---|---|---|---|---|---|---|---|---|---|---|---|")
        base = None
        for i, arm in enumerate(arms):
            d = os.path.join(run, scen, qid, arm, "raw")
            f = os.path.join(d, "results.csv")
            if not os.path.exists(f):
                print(f"| {i+1} | {arm} | 0 | missing |"); continue
            rows = [r for r in csv.DictReader(open(f)) if r["status"] == "complete"]
            wall, cpu, stall, top, tstall, aqu, util, rb = ([] for _ in range(8))
            for r in rows:
                w = float(r["elapsed_s"]); c = float(r["cpu_s"])
                n = int(r.get("loop_n") or 1) or 1
                wall.append(w); cpu.append(c / n); stall.append(w - c / n)
                rb.append(int(r["read_bytes"]) / n / 2**30)
                rep = r["run_id"].rsplit("-r", 1)[1]
                mf = os.path.join(d, f"r{rep}-{scen}", "grid-metrics.json")
                m = json.load(open(mf)) if os.path.exists(mf) else {}
                if "aqu_sz" in m:
                    aqu.append(m["aqu_sz"]); util.append(m["util_max"])
                    tc = m["top_thread_cpu_s"] / n
                    top.append(tc); tstall.append(w - tc)
            W = med(wall)
            if i == 0:
                base = wall
            delta = verdict = ""
            if i > 0 and base and wall:
                dlt = (st.median(wall) - st.median(base)) / st.median(base) * 100
                disjoint = max(wall) < min(base) or min(wall) > max(base)
                delta = f"{dlt:+.1f} %"
                verdict = ("faster" if dlt < 0 else "slower") if disjoint and abs(dlt) >= 2 else "no change"
            print(f"| {i+1} | {arm} | {len(rows)} | {fmt(W)} | {delta} | {verdict} | {fmt(med(cpu))} | {fmt(med(stall))} | {fmt(med(top))} | {fmt(med(tstall))} | {fmt(med(aqu),1)} | {fmt(med(util))} | {fmt(med(rb))} |")
        print(f"\nDistinct output digests for {qid} over all arms/reps/scenarios: {len(dig[qid])} (1 = identical)\n")
