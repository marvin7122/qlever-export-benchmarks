#!/usr/bin/env python3
"""Sum io_uring_enter calls and their in-kernel time from a counter-screen trace.

Input: io-trace.txt[.gz] written by counter_screen.py --trace-io
(`strace -f -ttt -T ... -e trace=...,io_uring_enter`).
A line looks like
  PID TS io_uring_enter(FD, TO_SUBMIT, MIN_COMPLETE, FLAGS, ...) = R <DUR>
Calls with MIN_COMPLETE > 0 block for completions ("wait" calls).
Prints one TSV row: calls, wait_calls, total_s, wait_s, mean_wait_us,
sum_to_submit, sum_min_complete. Times are strace -T times, so they are
inflated by tracing; compare arms only within the traced rows.
"""
import gzip
import re
import sys

LINE = re.compile(r"io_uring_enter\((\d+), (\d+), (\d+), [^)]*\)\s+=\s+-?\d+.*<([\d.]+)>")


def main() -> int:
    path = sys.argv[1]
    op = gzip.open if path.endswith(".gz") else open
    calls = waits = 0
    tot = wait = 0.0
    sub = minc = 0
    with op(path, "rt", errors="replace") as f:
        for line in f:
            if "io_uring_enter(" not in line:
                continue
            m = LINE.search(line)
            if not m:
                continue
            ts, mc, dur = int(m.group(2)), int(m.group(3)), float(m.group(4))
            calls += 1
            tot += dur
            sub += ts
            minc += mc
            if mc > 0:
                waits += 1
                wait += dur
    mean = (wait / waits * 1e6) if waits else 0.0
    print(f"{calls}\t{waits}\t{tot:.3f}\t{wait:.3f}\t{mean:.1f}\t{sub}\t{minc}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
