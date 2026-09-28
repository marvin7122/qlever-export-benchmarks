#!/usr/bin/env python3
"""Focused validation of benchmark_export.py's export timer parser."""

from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
HARNESS = REPO_ROOT / "scripts" / "benchmark_export.py"


def load_harness():
    spec = importlib.util.spec_from_file_location("benchmark_export", HARNESS)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load {HARNESS}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def main() -> None:
    harness = load_harness()
    with tempfile.TemporaryDirectory() as temporary_directory:
        log_path = Path(temporary_directory) / "qlever-server.log"
        log_path.write_text(
            "Export finished in 19 ms\n"
            "unrelated diagnostic\n"
            "Export finished in 47 ms\n"
        )
        parsed_export_time_ms = harness.parse_export_time_ms(log_path)

    assert parsed_export_time_ms == 47
    request = harness.RequestResult(
        status_code=200,
        elapsed_ns=123_456_789,
        response_bytes=42,
        checksum_xxh3_128="test",
        content_type="text/turtle",
    )
    assert request.elapsed_ns == 123_456_789

    print(
        json.dumps(
            {
                "status": "passed",
                "parsed_last_export_marker_ms": parsed_export_time_ms,
                "independent_client_elapsed_ns": request.elapsed_ns,
                "harness": str(HARNESS),
            },
            sort_keys=True,
        )
    )


if __name__ == "__main__":
    main()
