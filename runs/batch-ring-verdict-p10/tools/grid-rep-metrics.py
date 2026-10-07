#!/usr/bin/env python3
"""Reduce one rep's grid-sampler.py samples to the measured query window.

Usage: grid-rep-metrics.py <samples.jsonl[.gz]> <rep-raw-dir> <out.json>

Window: ends at the mtime of <rep-raw-dir>/cache-stats-after-measured.txt
(the harness writes it right after the measured request) and lasts
loop_total_s (or elapsed_s) from <rep-raw-dir>/result.yaml. Uses the last
sample at or before the start and the first sample at or after the end.
Output (JSON):
  window_s, aqu_sz (sum over devices of d(time_in_queue)/dt, = iostat
  aqu-sz), util_max (max over devices of d(io_ticks)/dt), dev_read_bytes,
  dev_read_ios, inflight_mean (mean sampled in_flight sum),
  proc_cpu_s (all threads), top_thread_cpu_s / top_thread_busy (the hottest
  thread, i.e. the export thread for a single-query CONSTRUCT export).
"""
import json, os, sys

samples_f, rep, out = sys.argv[1:4]
clk = os.sysconf("SC_CLK_TCK") or 100
res = {}
for line in open(os.path.join(rep, "result.yaml")):
    if ":" in line:
        k, v = line.split(":", 1)
        res[k.strip()] = v.strip().strip("'\"")
def num(k):
    try:
        return float(res.get(k, ""))
    except ValueError:
        return None
win = num("loop_total_s") or num("elapsed_s")
end = os.path.getmtime(os.path.join(rep, "cache-stats-after-measured.txt"))
start = end - win
import gzip
opener = gzip.open if samples_f.endswith(".gz") else open
S = [json.loads(l) for l in opener(samples_f, "rt") if l.strip()]
a = [s for s in S if s["t"] <= start]
b = [s for s in S if s["t"] >= end]
if not a or not b:
    json.dump({"error": "window not covered by samples", "window_s": win}, open(out, "w"))
    sys.exit(0)
a, b = a[-1], b[0]
dt = b["t"] - a["t"]
devs = list(a["dev"])
m = {"window_s": win, "sample_dt_s": dt,
     "aqu_sz": sum(b["dev"][d][4] - a["dev"][d][4] for d in devs) / (dt * 1000),
     "util_max": max((b["dev"][d][3] - a["dev"][d][3]) / (dt * 1000) for d in devs),
     "dev_read_bytes": sum(b["dev"][d][1] - a["dev"][d][1] for d in devs) * 512,
     "dev_read_ios": sum(b["dev"][d][0] - a["dev"][d][0] for d in devs)}
inw = [s for s in S if a["t"] <= s["t"] <= b["t"]]
m["inflight_mean"] = sum(sum(s["dev"][d][2] for d in devs) for s in inw) / len(inw)
# A thread may exit before the end sample (the export thread ends with the
# query), so use the last value seen for each thread inside the window.
last = {}
for smp in inw:
    for tid, v in smp["thr"].items():
        last[tid] = max(v, last.get(tid, 0))
th = {tid: v - a["thr"].get(tid, 0) for tid, v in last.items()}
m["proc_cpu_s"] = sum(th.values()) / clk
top = max(th.values()) if th else 0
m["top_thread_cpu_s"] = top / clk
m["top_thread_busy"] = (top / clk) / dt if dt > 0 else None
json.dump(m, open(out, "w"))
