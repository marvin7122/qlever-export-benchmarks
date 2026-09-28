# Conclusion for run pr196-depth2-fresh (queue seq 4623) — WIN

## Scope

Depth-2 fiber-overlap A/B on Wikidata: master base (b3d4f562) vs
branch `perf/export-depth2-construct-fresh` (319d2f86),
H-vocab-label-large turtle export, cold + warm with adaptive
early stopping (3 reps per arm after disjoint ranges). Ural bench
seq 4623, 2026-09-25, exit 0.

## Validity checks

All 12 reps complete, no zero-byte reps. Bodies identical across
arms (driver rc=0). Cold reads ~511 MB from disk on both arms;
warm reads 0 bytes.

## Result

The depth-2 branch wins consistently in both scenarios. Median
elapsed:

| scenario | base | variant | delta |
|---|---|---|---|
| cold | 22.67 s | 21.99 s | -3.0% |
| warm | 22.83 s | 21.80 s | -4.5% |

Rep ranges are disjoint in both scenarios (cold base 22.65–22.76
s vs variant 21.68–22.17 s; warm base 22.78–23.12 s vs variant
21.73–21.85 s), which is why the adaptive driver stopped at 3
reps. The effect reproduces across scenarios and reps.

## Implication

First measured Wikidata verdict for depth-2 fiber overlap: a
3–4.5% export win on the vocab-label query. The MVP claim set is
frozen, so this is recorded here and left out of the prose
unless the owner reopens it.
