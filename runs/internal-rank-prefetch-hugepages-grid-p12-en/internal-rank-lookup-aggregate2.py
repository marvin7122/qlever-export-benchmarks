#!/usr/bin/env python3
"""Aggregate a run dir with layout <run>/<scenario>/<qid>/<arm>/raw/results.csv
(pr-ab-grid.sh or pr-ab-multi-v2-3bin-*), harness copy pr-ab-tools-rank2
(per-trial perf stat columns).

Per (scenario, query, arm): wall median [min-max], delta vs the reference arm
with verdict (faster/slower only if ranges are disjoint and |delta| >= 2 %),
and per-query medians of Gcycles, demand DRAM refills (M), dTLB misses (M),
cache misses (M), each with its delta vs the reference arm. Distinct
(checksum) count over all arms of the cell.

Usage: internal-rank-lookup-aggregate2.py <run-dir> <reference-arm>
"""
import csv
import statistics
import sys
from pathlib import Path

COUNTERS = [("cycles", 1e9, "Gcyc"), ("dram_refills", 1e6, "M DRAM refills"),
            ("dtlb_misses", 1e6, "M dTLB misses"), ("cache_misses", 1e6, "M cache misses")]


def rows(path):
    try:
        return [r for r in csv.DictReader(open(path)) if r.get("status") == "complete"]
    except OSError:
        return []


def per_query(r, key):
    v = r.get(key)
    if not v:
        return None
    try:
        return float(v) / max(1, int(r.get("loop_n") or 1))
    except ValueError:
        return None


def med(values):
    values = [v for v in values if v is not None]
    return (statistics.median(values), min(values), max(values)) if values else None


def verdict(ref, var):
    if ref is None or var is None:
        return "", ""
    d = (var[0] - ref[0]) / ref[0] * 100
    overlap = max(ref[1], var[1]) <= min(ref[2], var[2])
    v = ("faster" if d < 0 else "slower") if (not overlap and abs(d) >= 2) else "no difference"
    return f"{d:+.1f} %", v


def main():
    run, ref_arm = Path(sys.argv[1]), sys.argv[2]
    head = ["scenario", "query", "arm", "n", "wall s median [min–max]", "Δ wall", "verdict"]
    for _, _, name in COUNTERS:
        head += [f"{name}/query", "Δ"]
    head.append("checksums")
    print("| " + " | ".join(head) + " |")
    print("|" + "---|" * len(head))
    for scen in sorted(p for p in run.iterdir() if p.is_dir() and p.name in ("cold", "warm")):
        for qdir in sorted(p for p in scen.iterdir() if p.is_dir()):
            data = {a.name: rows(a / "raw" / "results.csv") for a in sorted(qdir.iterdir()) if a.is_dir()}
            data = {k: v for k, v in data.items() if v}
            if not data:
                continue
            sums = {r["checksum"] for rs in data.values() for r in rs}
            ref = data.get(ref_arm)
            order = ([ref_arm] if ref else []) + [a for a in data if a != ref_arm]
            for arm in order:
                rs = data[arm]
                wall = med([float(r["elapsed_s"]) for r in rs])
                dw, v = ("", "reference") if arm == ref_arm else verdict(
                    med([float(r["elapsed_s"]) for r in ref]) if ref else None, wall)
                cells = [scen.name, qdir.name, arm, str(len(rs)),
                         f"{wall[0]:.2f} [{wall[1]:.2f}–{wall[2]:.2f}]", dw, v]
                for key, scale, _ in COUNTERS:
                    m = med([per_query(r, key) for r in rs])
                    mr = med([per_query(r, key) for r in ref]) if ref else None
                    cells.append(f"{m[0] / scale:.1f}" if m else "n/a")
                    cells.append("" if arm == ref_arm or not m or not mr else f"{(m[0] - mr[0]) / mr[0] * 100:+.1f} %")
                cells.append(str(len(sums)))
                print("| " + " | ".join(cells) + " |")


if __name__ == "__main__":
    main()
