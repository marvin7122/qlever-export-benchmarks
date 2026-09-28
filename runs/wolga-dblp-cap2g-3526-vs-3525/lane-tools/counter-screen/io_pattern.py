#!/usr/bin/env python3
"""Offline I/O-pattern analysis of one traced cold run (lever D8, 2026-09-28).

Input: an `strace -f -ttt -T -qq -s0 -e abbrev=none -e trace=openat,pread64,preadv2,io_uring_enter`
log of qlever-server (started under strace: ptrace_scope=1 forbids attaching).
Only syscalls inside [--from, --to] (epoch s, the counted query) are analysed;
openat lines from the whole log map fds to index files.

Per run it derives: syscall counts and bytes per kind, request-size histogram
(log2 buckets), per index file: request count, bytes, sequential fraction
(offset == previous end), median/p90 absolute seek distance, and for
io_uring_enter the to_submit (batch size) and min_complete distributions.
Reads submitted through the io_uring SQ ring carry no offsets in a syscall
trace (blktrace/bpf need root); for them only batch sizes and counts exist.
Writes <out>.json and prints a one-line summary.
"""

from __future__ import annotations

import argparse
import json
import re
import statistics
from collections import Counter, defaultdict
from pathlib import Path

LINE = re.compile(r"^(?P<pid>\d+)\s+(?P<ts>\d+\.\d+)\s+(?P<rest>.*)$")
CALL = re.compile(r"^(?P<name>\w+)\((?P<args>.*)\)\s+=\s+(?P<ret>-?\d+|\?)(?:\s+(?P<err>E[A-Z]+))?.*?(?:<(?P<dur>[\d.]+)>)?$")
UNFIN = re.compile(r"^(?P<name>\w+)\((?P<args>.*)\s+<unfinished \.\.\.>$")
RESUMED = re.compile(r"^<\.\.\. (?P<name>\w+) resumed>(?P<args>.*)\)\s+=\s+(?P<ret>-?\d+|\?)(?:\s+(?P<err>E[A-Z]+))?.*?(?:<(?P<dur>[\d.]+)>)?$")
OPENAT = re.compile(r'openat\([^,]+,\s*"(?P<path>[^"]*)"')


def split_args(s: str) -> list[str]:
    out, depth, cur, q = [], 0, "", False
    for ch in s:
        if ch == '"':
            q = not q
        if not q and ch in "[{(":
            depth += 1
        if not q and ch in "]})":
            depth -= 1
        if ch == "," and depth == 0 and not q:
            out.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def bucket(n: int) -> str:
    if n <= 0:
        return "0"
    b = 1 << (n - 1).bit_length()
    return f"<={b}"


def pct(v: list[int], p: float) -> int:
    if not v:
        return 0
    v = sorted(v)
    return v[min(len(v) - 1, int(p * (len(v) - 1)))]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("trace")
    ap.add_argument("--from", dest="t0", type=float, default=0.0)
    ap.add_argument("--to", dest="t1", type=float, default=1e30)
    ap.add_argument("--index-prefix", default="", help="only fds whose path starts with this")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    fdpath: dict[int, str] = {}
    pending: dict[str, tuple[str, str, float]] = {}
    calls = []
    for raw in Path(a.trace).read_text(errors="replace").splitlines():
        m = LINE.match(raw)
        if not m:
            continue
        pid, ts, rest = m["pid"], float(m["ts"]), m["rest"]
        u = UNFIN.match(rest)
        if u:
            pending[pid] = (u["name"], u["args"], ts)
            continue
        r = RESUMED.match(rest)
        if r and pid in pending:
            name, args0, ts0 = pending.pop(pid)
            calls.append((ts0, name, args0 + r["args"], r["ret"], r["err"]))
            continue
        c = CALL.match(rest)
        if c:
            calls.append((ts, c["name"], c["args"], c["ret"], c["err"]))

    counts, byts, errs = Counter(), Counter(), Counter()
    sizes = Counter()
    per_file = defaultdict(list)  # path -> [(offset, len)]
    batch, minc = [], []
    calls.sort(key=lambda c: c[0])
    for ts, name, args, ret, err in calls:
        if name == "openat":  # fd -> path in time order (fds get reused)
            if ret != "?" and int(ret) >= 0:
                o = OPENAT.search(f"openat({args})")
                if o:
                    fdpath[int(ret)] = o["path"]
            continue
        if not (a.t0 <= ts <= a.t1):
            continue
        p = split_args(args)
        if name in ("pread64", "preadv2"):
            try:
                fd = int(p[0])
            except (ValueError, IndexError):
                continue
            path = fdpath.get(fd, f"fd{fd}")
            if a.index_prefix and not path.startswith(a.index_prefix):
                continue
            if name == "pread64":
                length, off = int(p[2]), int(p[3])
            else:
                lens = [int(x) for x in re.findall(r"iov_len=(\d+)", p[1])]
                length, off = sum(lens), int(p[3])
                if "RWF_NOWAIT" in (p[4] if len(p) > 4 else ""):
                    counts["preadv2_nowait"] += 1
            counts[name] += 1
            if err:
                errs[f"{name}:{err}"] += 1
            got = int(ret) if ret != "?" and int(ret) > 0 else 0
            byts[name] += got
            sizes[bucket(length)] += 1
            per_file[path].append((off, length))
        elif name == "io_uring_enter":
            counts[name] += 1
            try:
                batch.append(int(p[1]))
                minc.append(int(p[2]))
            except (ValueError, IndexError):
                pass

    files = {}
    for path, reqs in per_file.items():
        seq, seeks, prev_end = 0, [], None
        for off, ln in reqs:
            if prev_end is not None:
                if off == prev_end:
                    seq += 1
                seeks.append(abs(off - prev_end))
            prev_end = off + ln
        files[path] = {
            "requests": len(reqs),
            "bytes_requested": sum(ln for _, ln in reqs),
            "sequential_fraction": round(seq / max(1, len(reqs) - 1), 4),
            "seek_median_B": int(statistics.median(seeks)) if seeks else 0,
            "seek_p90_B": pct(seeks, 0.9),
            "distinct_4k_pages": len({o // 4096 for o, _ in reqs}),
        }
    res = {
        "window_s": [a.t0, a.t1],
        "syscalls": dict(counts),
        "bytes_returned": dict(byts),
        "errors": dict(errs),
        "request_size_hist": dict(sorted(sizes.items(), key=lambda kv: int(kv[0][2:]) if kv[0] != "0" else 0)),
        "io_uring_enter_to_submit": {"n": len(batch), "median": pct(batch, 0.5), "p90": pct(batch, 0.9),
                                      "max": max(batch) if batch else 0, "sum": sum(batch)},
        "io_uring_enter_min_complete": {"median": pct(minc, 0.5), "max": max(minc) if minc else 0},
        "files": files,
    }
    Path(a.out).write_text(json.dumps(res, indent=1))
    top = sorted(files.items(), key=lambda kv: -kv[1]["requests"])[:2]
    print(f"pread64={counts['pread64']} preadv2={counts['preadv2']} (nowait {counts['preadv2_nowait']}, "
          f"EAGAIN {errs.get('preadv2:EAGAIN', 0)}) io_uring_enter={counts['io_uring_enter']} "
          f"batch_med={res['io_uring_enter_to_submit']['median']} batch_sum={res['io_uring_enter_to_submit']['sum']} "
          + " ".join(f"[{Path(k).name}: n={v['requests']} seq={v['sequential_fraction']} seek_med={v['seek_median_B']}]" for k, v in top))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
