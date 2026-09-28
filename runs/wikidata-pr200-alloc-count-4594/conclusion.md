# Conclusion for run pr200-alloc-count (queue seq 4594) — FAILED, no data

## Scope

Allocation-count profile on the borrowed-terms binary. Ural bench seq
4594, 2026-09-25, exit 1.

## Validity checks

Branch verification passes. The driver dies at line 61: `label:
unbound variable` under `set -u` — the same driver-bug class as seq
4575.

## Result

No data. No verdict follows.

## Implication

Fix the `label` variable in `pr200-alloc-count.sh` and requeue with
the branch flag. Nothing in the thesis cites this run.
