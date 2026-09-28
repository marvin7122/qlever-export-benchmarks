# Conclusion for run pr200-alloc-count (queue seq 4608) — INSTRUMENT NULL

## Scope

Allocation-count comparison on the borrowed-terms binary vs master,
57 MB CONSTRUCT export, one timed query per arm. Ural bench seq 4608
(retry of seq 4594 with the `label` driver bug fixed), 2026-09-25,
exit 0.

## Validity checks

Both servers answer HTTP 200 with identical bodies (57139614 bytes).
Timed reps tie: branch 0.87 s vs master 0.89 s.

## Result

No allocation verdict. The malloc-count instrumentation reports zero
bytes on both arms (`total allocated bytes: {'BRANCH': 0, 'MASTER':
0}`), so the counters captured nothing and the script's own
`VERDICT FAIL` reflects the instrument, not the code. The times
corroborate the seq 4593 cold tie.

## Implication

Needs a working allocation counter before any claim. No prose
change.
