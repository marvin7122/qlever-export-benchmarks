#!/usr/bin/env python3
"""Harness-equivalent HTTP client (same loop as benchmark_export.stream_query:
httpx.stream + iter_bytes + xxh3_128 per chunk) for the client-limit check.

Prints: wall_s ttfb_s bytes xxh3 client_cpu_s t_start_ns
Usage: v2util-pyclient.py <endpoint> <query.rq> <action> <accept> [k=v ...]
"""
import sys
import time

import httpx
import xxhash


def main():
    endpoint, qfile, action, accept = sys.argv[1:5]
    data = {"query": open(qfile).read(), "action": action}
    for kv in sys.argv[5:]:
        k, v = kv.split("=", 1)
        data[k] = v
    hasher = xxhash.xxh3_128()
    nbytes = 0
    ttfb = None
    c0 = time.process_time()
    t0m = time.monotonic_ns()
    t0 = time.perf_counter_ns()
    timeout = httpx.Timeout(connect=10.0, read=None, write=10.0, pool=10.0)
    with httpx.stream("POST", endpoint, data=data, headers={"Accept": accept}, timeout=timeout) as r:
        if r.status_code != 200:
            print(f"HTTP {r.status_code}", file=sys.stderr)
            sys.exit(1)
        for chunk in r.iter_bytes():
            if ttfb is None and chunk:
                ttfb = time.perf_counter_ns() - t0
            nbytes += len(chunk)
            hasher.update(chunk)
    wall = time.perf_counter_ns() - t0
    print(f"{wall / 1e9:.4f} {(ttfb or 0) / 1e9:.4f} {nbytes} {hasher.hexdigest()} "
          f"{time.process_time() - c0:.3f} {t0m}")


if __name__ == "__main__":
    main()
