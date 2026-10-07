#!/usr/bin/env python3
"""Per-thread on-CPU sampler for one process (V2 utilisation diagnosis).

Every INTERVAL ms, reads /proc/<pid>/task/*/{stat,schedstat,wchan} and
appends one CSV row per thread:

  t_ns,tid,comm,state,utime,stime,run_ns,wait_ns,slices,cpu,wchan

t_ns is CLOCK_MONOTONIC (comparable with the server's steady_clock).
run_ns / wait_ns are cumulative on-CPU / runqueue-wait nanoseconds from
schedstat. Stops when STOPFILE exists or the process is gone.

Also samples system-wide CPU jiffies (/proc/stat "cpu" line) as rows with
tid=0 and comm=__system__: utime=busy jiffies, stime=total jiffies.

Usage: v2util-sampler.py <pid> <interval_ms> <out.csv> <stopfile>
"""
import os
import sys
import time


def read(path):
    try:
        with open(path, "rb") as f:
            return f.read().decode("ascii", "replace")
    except OSError:
        return None


def main():
    pid, interval_ms, out_path, stopfile = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
    interval = interval_ms / 1000.0
    base = f"/proc/{pid}/task"
    with open(out_path, "w", buffering=1 << 20) as out:
        out.write("t_ns,tid,comm,state,utime,stime,run_ns,wait_ns,slices,cpu,wchan\n")
        nxt = time.monotonic()
        while not os.path.exists(stopfile):
            t = time.monotonic_ns()
            try:
                tids = os.listdir(base)
            except OSError:
                break
            rows = []
            for tid in tids:
                st = read(f"{base}/{tid}/stat")
                if st is None:
                    continue
                rp = st.rfind(")")
                comm = st[st.find("(") + 1:rp].replace(",", "_")
                f = st[rp + 2:].split()
                # f[0]=state (field 3); utime=field 14 -> f[11]; stime f[12];
                # processor=field 39 -> f[36]
                ss = read(f"{base}/{tid}/schedstat") or "0 0 0"
                run_ns, wait_ns, slices = ss.split()[:3]
                wchan = (read(f"{base}/{tid}/wchan") or "").strip() or "-"
                rows.append(f"{t},{tid},{comm},{f[0]},{f[11]},{f[12]},{run_ns},{wait_ns},{slices},{f[36]},{wchan}\n")
            cpu = (read("/proc/stat") or "cpu 0").split("\n", 1)[0].split()[1:]
            vals = [int(x) for x in cpu]
            total = sum(vals[:8])
            idle = vals[3] + vals[4]
            rows.append(f"{t},0,__system__,-,{total - idle},{total},0,0,0,-1,-\n")
            out.writelines(rows)
            nxt += interval
            delay = nxt - time.monotonic()
            if delay > 0:
                time.sleep(delay)
            else:
                nxt = time.monotonic()


if __name__ == "__main__":
    main()
