# Conclusion for run pr30-transform-recollapse (queue seq 4595) — FAILED, no data

## Scope

Transform-recollapse profiled export on master at `9932d19dd9`
(branch verification passes). Ural bench seq 4595, 2026-09-25, exit 2.

## Validity checks

The export runs, but the profiler gate fails: `total_samples=520
too low (fold broken?)` against a 1000-sample threshold. The export
produced too few profiler samples (too fast or window too short).

## Result

No data. No verdict follows.

## Implication

Owner decision: lower the sample threshold or lengthen the profiling
window, then requeue with the branch flag. Nothing in the thesis
cites this run.
