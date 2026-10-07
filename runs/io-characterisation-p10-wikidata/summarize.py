#!/usr/bin/env python3
"""Summarise io_screen.py rows.json into summary.md (median [min-max] per configuration)."""

from __future__ import annotations

import json
import statistics
import sys
from pathlib import Path

GATE = 0.10  # export-thread off-CPU share in io_uring_enter (audit §3)


def fmt(vals: list[float], nd: int = 2, pct: bool = False) -> str:
    vals = [v for v in vals if v is not None]
    if not vals:
        return "-"
    k = 100.0 if pct else 1.0
    med = statistics.median(vals) * k
    if len(vals) == 1:
        return f"{med:.{nd}f}"
    return f"{med:.{nd}f} [{min(vals) * k:.{nd}f}–{max(vals) * k:.{nd}f}]"


def main() -> int:
    run = Path(sys.argv[1])
    rows = json.loads((run / "rows.json").read_text())
    labels: list[str] = []
    for r in rows:
        if r["label"] not in labels:
            labels.append(r["label"])
    md = [f"# I/O characterisation screen: `{run.name}`", "",
          "Cold (page cache dropped before every server start); one fresh server per execution.",
          "Median [min–max] over trials. Gate: export-thread off-CPU share in `io_uring_enter` >= 10 % of wall.", "",
          "| config | query | cap GiB | n | lines | MB out | wall s | TTFB s | export phase s | server CPU s | "
          "export on-CPU s | io_uring wait s | io_uring share of wall % | of export phase % | fast-path hit % | "
          "disk read GB | aqu-sz (whole) | aqu-sz (export) | read MB/s (whole) | read MB/s (export) | peak 1 s MB/s | "
          "avg read KiB | gate |",
          "|" + "---|" * 23]
    for lab in labels:
        rs = [r for r in rows if r["label"] == lab and "error" not in r and r.get("status") == 200]
        errs = [r for r in rows if r["label"] == lab and ("error" in r or r.get("status") != 200)]
        if not rs:
            md.append(f"| {lab} | - | - | 0 | errors: {[e.get('error') for e in errs]} |" + " |" * 18)
            continue
        cap = rs[0].get("mem_max_bytes")
        share = [r.get("export_uring_share_wall") for r in rs]
        gate = "PASS" if statistics.median([s or 0 for s in share]) >= GATE else "fail"
        md.append("| " + " | ".join([
            lab, rs[0]["query"], f"{cap / 2**30:.2f}" if cap else "none", str(len(rs)) + (f" ({len(errs)} err)" if errs else ""),
            fmt([r["lines"] for r in rs], 0), fmt([r["bytes"] / 1e6 for r in rs], 1),
            fmt([r["elapsed_s"] for r in rs]), fmt([r["ttfb_s"] for r in rs]), fmt([r["export_phase_s"] for r in rs]),
            fmt([r["server_cpu_s"] for r in rs]), fmt([r["export_run_s"] for r in rs]),
            fmt([r["export_uring_wait_s"] for r in rs]), fmt(share, 1, True),
            fmt([r.get("export_uring_share_export_phase") for r in rs], 1, True),
            fmt([r.get("fastpath_hit_share") for r in rs], 1, True),
            fmt([r["disk_whole"].get("read_bytes", 0) / 1e9 for r in rs]),
            fmt([r["disk_whole"].get("aqu_sz") for r in rs]), fmt([r["disk_export"].get("aqu_sz") for r in rs]),
            fmt([r["disk_whole"].get("read_mb_s") for r in rs], 0), fmt([r["disk_export"].get("read_mb_s") for r in rs], 0),
            fmt([r.get("disk_peak_1s_mb_s") for r in rs], 0), fmt([r["disk_whole"].get("avg_read_kib") for r in rs], 1),
            gate]) + " |")
    md += ["", "## Byte identity per configuration", ""]
    for lab in labels:
        ds = {r.get("xxh3_128") for r in rows if r["label"] == lab and "error" not in r}
        md.append(f"- {lab}: {'identical' if len(ds) == 1 else 'DIFFERENT ' + str(ds)}")
    md += ["", "## Export-thread off-CPU by syscall (median trial by wall time)", ""]
    for lab in labels:
        rs = sorted([r for r in rows if r["label"] == lab and "error" not in r], key=lambda r: r["elapsed_s"])
        if rs:
            r = rs[len(rs) // 2]
            by = ", ".join(f"{k}={v}" for k, v in list(r["export_offcpu_by_syscall_s"].items())[:6])
            md.append(f"- {lab} (t{r['trial']}, export thread `{r['export_comm']}`, on-CPU {r['export_run_s']} s, "
                      f"off-CPU {r['export_offcpu_s']} s): {by}; counts {r.get('counts')}; "
                      f"top io_uring threads {r.get('uring_threads')}; cgroup {{max: {r['cg_after'].get('memory.max')}, "
                      f"peak: {r['cg_after'].get('memory.peak')}, oom_kill: {r['cg_after'].get('memory.events.oom_kill')}, "
                      f"refault_file: {r['cg_after'].get('memory.stat.workingset_refault_file', 0) - r['cg_before'].get('memory.stat.workingset_refault_file', 0)}}}")
    (run / "summary.md").write_text("\n".join(md) + "\n")
    print("\n".join(md))
    return 0


if __name__ == "__main__":
    sys.exit(main())
