# Conclusion for run pr200-alloc-count (queue seq 4592) — REFUSED, no data

## Scope

Allocation-count profile on the borrowed-terms binary
(`perf/export-borrowed-vocab-terms-pr57-fresh` build). Ural bench seq
4592, 2026-09-25, exit 2.

## Validity checks

None ran. Same gate refusal as seqs 4576 and 4591: no
`--branch`/`--qlever-branch` verification on the entry.

## Result

No data. No verdict follows.

## Implication

Requeue with `--qlever-branch
perf/export-borrowed-vocab-terms-pr57-fresh` once queue placement is
resolved. Same block as the other four pending requeues.
