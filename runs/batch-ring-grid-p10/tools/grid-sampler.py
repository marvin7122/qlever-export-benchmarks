#!/usr/bin/env python3
"""Sample block-device and per-thread CPU counters during one harness call.

Usage: grid-sampler.py <out.jsonl> <server-binary> <dev>[,<dev>...] [interval_s]

Every interval (default 0.2 s) appends one JSON line:
  {"t": <epoch s>, "dev": {<dev>: [read_ios, sectors_read, in_flight,
   io_ticks_ms, time_in_queue_ms]}, "thr": {<tid>: <utime+stime ticks>}}
"thr" covers the threads of the process whose /proc/<pid>/exe is the given
server binary (empty before the server starts). Stops on SIGTERM.
Fields from /sys/block/<dev>/stat (Documentation/block/stat.rst).
"""
import json, os, signal, sys, time

out, binary, devs = sys.argv[1], os.path.realpath(sys.argv[2]), sys.argv[3].split(",")
interval = float(sys.argv[4]) if len(sys.argv) > 4 else 0.2
running = True
def stop(*_):
    global running
    running = False
signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)

def find_pid():
    for p in os.listdir("/proc"):
        if p.isdigit():
            try:
                if os.readlink(f"/proc/{p}/exe") == binary:
                    return p
            except OSError:
                pass
    return None

def dev_stat(d):
    f = open(f"/sys/block/{d}/stat").read().split()
    return [int(f[0]), int(f[2]), int(f[8]), int(f[9]), int(f[10])]

def thread_ticks(pid):
    res = {}
    try:
        tids = os.listdir(f"/proc/{pid}/task")
    except OSError:
        return res
    for tid in tids:
        try:
            s = open(f"/proc/{pid}/task/{tid}/stat").read()
        except OSError:
            continue
        rest = s[s.rfind(")") + 2:].split()
        res[tid] = int(rest[11]) + int(rest[12])  # utime, stime (fields 14, 15)
    return res

pid = None
with open(out, "a") as fh:
    while running:
        if pid is None or not os.path.exists(f"/proc/{pid}"):
            pid = find_pid()
        rec = {"t": time.time(), "dev": {d: dev_stat(d) for d in devs},
               "thr": thread_ticks(pid) if pid else {}}
        fh.write(json.dumps(rec, separators=(",", ":")) + "\n")
        fh.flush()
        time.sleep(interval)
