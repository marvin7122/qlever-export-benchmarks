# Conclusion for run exportids-test (queue seq 4570) — PASS, no measurement

## Scope

`ExportIdsTest` regression (focused new test plus full suite) on
branch `feat/select-term-result-cache` at `bb071431b6` (= origin).
Ural bench seq 4570, 2026-09-25, exit 0
(`WQ_DONE_FOCUSED_AND_FULL_OK`).

## Validity checks

Focused test
`ExportIds.cachedIdToStringAndTypeMatchesDirectAndHits` passes
(584 ms). Full suite passes with no failures.

## Result

Correctness gate only; no performance numbers. The cached
`idToStringAndType` path matches the direct path and records hits.

## Implication

The term-result-cache feature keeps a green test gate. No prose
change: no measured effect.
