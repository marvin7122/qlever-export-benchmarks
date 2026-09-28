# Conclusion for run pr204-row-batchsize-dblp-ab (queue seq 4604)

## Scope

Row-batch-size A/B for PR 204 on the DBLP index: same binary
(`feat/construct-export-row-batchsize` at `4b74f3ef`), arms differ
only in `construct-export-row-batch-size` (1024 vs 4096). Query
`H-vocab-title-small` turtle export, 3 cold reps (page-cache evicted)
plus 3 warm reps, interleaved. Ural bench seq 4604, 2026-09-25, exit
0. Full driver conclusion with gate logs lives in the run directory
on Ural (`thesis/experiments/runs/pr204-dblp-ab/`).

## Validity checks

Preflight and postflight PASS on both scenarios. Bodies byte-identical
across arms. The `mv` warnings in the log concern a redundant raw-dir
move and touch no measurement.

## Result

Cold medians: 1.014 s (1024) vs 0.832 s (4096), -18.0%,
non-overlapping ranges. Warm medians: 0.0773 s vs 0.0760 s (-1.8%).

## Implication

A larger construct export row batch substantially cuts cold export
time on this workload. Belongs in the 5A inventory as the batch-size
data point.
