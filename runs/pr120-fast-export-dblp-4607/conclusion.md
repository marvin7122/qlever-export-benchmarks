# Conclusion for run pr120-fast-export-dblp-ab (queue seq 4607)

## Scope

Fast-export flag A/B for PR 120 on the DBLP index: same binary
(`feat/export-v2-unified-pipeline-wired` at `e1993226`), arms differ
only in the request form field (`fast-export=0` vs `1`). Four SELECT
CSV queries, 5 cold reps (evicted) plus 5 warm reps. Ural bench seq
4607, 2026-09-25, exit 0. Full driver conclusion with gate logs on
Ural (`thesis/experiments/runs/pr120-dblp-ab/`).

## Validity checks

Preflight and postflight PASS. D1, R1, H-vocab bodies byte-identical
across arms. R2 bodies are equal as multisets with differing row
order — the fast path does not preserve output order there.

## Result

Cold medians, base vs fast: D1 0.095 s vs 0.090 s (-5.9%, noise).
R1 1.104 s vs 0.495 s (-55.1%). R2 2.326 s vs 0.713 s (-69.3%).
H-vocab-title-large 5.142 s vs 1.181 s (-77.0%). Warm: R2 -29.1%
faster; R1 +13.6% and H-vocab +8.4% slower; D1 noise.

## Implication

Fast export massively cuts cold SELECT export time (55-77% on three
workloads) at the cost of output row order on R2. Warm effects are
mixed. Belongs in the SELECT chapter with the order caveat stated.
