#!/usr/bin/env python3
"""Aggregate an internal-rank-lookup A/B run dir (pr-ab-multi-v2-3bin-loadgate
layout <run>/<scenario>/<qid>/<arm>/raw/results.csv, harness from the
pr-ab-tools-rank copy with per-trial perf stat columns).

Prints one markdown row per (scenario, query, arm != base): wall median
[min-max], delta vs base, verdict (faster/slower only if ranges do not overlap
and |delta| >= 2 %), cycles per query median [min-max] and delta, and the
number of distinct checksums over all arms of the cell.

Usage: internal-rank-lookup-aggregate.py <run-dir>
"""
import csv
import statistics
import sys
from pathlib import Path


def rows(path):
    try:
        return [r for r in csv.DictReader(open(path))
                if r.get("status") == "complete"]
    except OSError:
        return []


def fmt_s(v):
    return f"{v:.3f}" if v < 10 else f"{v:.2f}"


def summary(values, unit):
    if not values:
        return "n/a", None
    med = statistics.median(values)
    lo, hi = min(values), max(values)
    if unit == "s":
        return f"{fmt_s(med)} [{fmt_s(lo)}–{fmt_s(hi)}]", (med, lo, hi)
    return f"{med / 1e9:.2f} [{lo / 1e9:.2f}–{hi / 1e9:.2f}]", (med, lo, hi)


def verdict(base, var):
    if base is None or var is None:
        return "n/a", ""
    delta = (var[0] - base[0]) / base[0] * 100
    overlap = max(base[1], var[1]) <= min(base[2], var[2])
    if not overlap and abs(delta) >= 2:
        v = "faster" if delta < 0 else "slower"
    else:
        v = "no difference"
    return v, f"{delta:+.1f} %"


def main():
    run = Path(sys.argv[1])
    print("| scenario | query | arm | n | wall s median [min–max] | Δ wall | verdict "
          "| Gcycles/query median [min–max] | Δ cycles | checksums |")
    print("|---|---|---|---|---|---|---|---|---|---|")
    for scen_dir in sorted(p for p in run.iterdir() if p.is_dir() and p.name in ("cold", "warm")):
        for qdir in sorted(p for p in scen_dir.iterdir() if p.is_dir()):
            data = {}
            for arm in ("base", "variant", "variant2"):
                rs = rows(qdir / arm / "raw" / "results.csv")
                if rs:
                    data[arm] = rs
            if "base" not in data:
                continue
            checksums = {r["checksum"] for rs in data.values() for r in rs}
            base_wall = summary([float(r["elapsed_s"]) for r in data["base"]], "s")[1]
            base_cyc = summary([float(r["cycles_per_query"]) for r in data["base"]
                                if r.get("cycles_per_query")], "c")[1]
            for arm, rs in data.items():
                wall_txt, wall = summary([float(r["elapsed_s"]) for r in rs], "s")
                cyc_txt, cyc = summary([float(r["cycles_per_query"]) for r in rs
                                        if r.get("cycles_per_query")], "c")
                v, d = ("base", "") if arm == "base" else verdict(base_wall, wall)
                _, dc = ("", "") if arm == "base" else verdict(base_cyc, cyc)
                print(f"| {scen_dir.name} | {qdir.name} | {arm} | {len(rs)} | {wall_txt} | {d} "
                      f"| {v} | {cyc_txt} | {dc} | {len(checksums)} |")


if __name__ == "__main__":
    main()
