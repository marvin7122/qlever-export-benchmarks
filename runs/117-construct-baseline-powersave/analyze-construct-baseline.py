#!/usr/bin/env python3
"""Aggregate the baseline-only run 117 cells."""

from __future__ import annotations

import argparse
import csv
import json
import statistics
from pathlib import Path


STAGES_US = [
    "server_planning_us",
    "server_root_execution_us",
    "server_non_root_stream_us",
    "construct_batch_evaluation_us",
    "construct_instantiation_deduplication_us",
    "construct_format_transport_residual_us",
]


def numbers(rows: list[dict[str, str]], field: str) -> list[float]:
    return [float(row[field]) for row in rows]


def distribution(values: list[float]) -> dict[str, float]:
    return {
        "median": statistics.median(values),
        "min": min(values),
        "max": max(values),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    parser.add_argument("--json-out", type=Path)
    args = parser.parse_args()

    cells: dict[str, dict[str, object]] = {}
    all_rows: list[dict[str, str]] = []
    for csv_path in sorted(args.root.glob("*-none-*/raw/results.csv")):
        rows = list(csv.DictReader(csv_path.open(newline="")))
        all_rows.extend(rows)
        e2e_s = numbers(rows, "elapsed_s")
        summary: dict[str, object] = {
            "repetitions": len(rows),
            "statuses": sorted({row["status"] for row in rows}),
            "http_statuses": sorted({row["http_status"] for row in rows}),
            "e2e_s": distribution(e2e_s),
            "response_bytes": sorted({int(row["response_bytes"]) for row in rows}),
            "candidate_result_triples": sorted(
                {int(row["construct_candidate_triples"]) for row in rows}
            ),
            "emitted_result_triples": sorted(
                {int(row["construct_emitted_triples"]) for row in rows}
            ),
            "process_peak_rss_mib": distribution(
                [float(row["server_vm_hwm_kib"]) / 1024 for row in rows]
            ),
        }
        for field in STAGES_US:
            summary[field.removesuffix("_us") + "_ms"] = distribution(
                [value / 1000 for value in numbers(rows, field)]
            )
        summary["median_per_run_share_percent"] = {
            field.removesuffix("_us"): statistics.median(
                [
                    100 * float(row[field]) / (float(row["elapsed_s"]) * 1_000_000)
                    for row in rows
                ]
            )
            for field in STAGES_US
        }
        cells[csv_path.parents[1].name] = summary

    result = {
        "root": str(args.root),
        "audit": {
            "cell_count": len(cells),
            "row_count": len(all_rows),
            "rows_per_cell": sorted({cell["repetitions"] for cell in cells.values()}),
            "statuses": sorted({row["status"] for row in all_rows}),
            "http_statuses": sorted({row["http_status"] for row in all_rows}),
            "rows_with_stage_metrics": sum(
                row["stage_metrics_seen"] == "True" for row in all_rows
            ),
            "rows_with_memory_marker": sum(
                row["dedup_memory_marker_seen"] == "True" for row in all_rows
            ),
            "major_faults": sum(int(row["major_faults"]) for row in all_rows),
            "swap_in": sum(int(row["pswpin_delta"]) for row in all_rows),
            "swap_out": sum(int(row["pswpout_delta"]) for row in all_rows),
            "errors": [row["error"] for row in all_rows if row["error"]],
        },
        "cells": cells,
    }
    rendered = json.dumps(result, indent=2, sort_keys=True)
    if args.json_out:
        args.json_out.write_text(rendered + "\n")
    print(rendered)


if __name__ == "__main__":
    main()
