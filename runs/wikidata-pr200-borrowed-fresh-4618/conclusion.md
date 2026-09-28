# Conclusion for run pr200-borrowed-fresh (queue seq 4618) — SMALL WIN

## Scope

Borrowed-terms A/B on Wikidata: master base (b3d4f562) vs fresh
branch `perf/export-borrowed-vocab-terms-pr57-fresh` (f47d174d),
humans-label-en turtle export, cold + warm, 5 reps each. Ural
bench seq 4618 (owner requeue after the seq 4613 verify failure),
2026-09-25, exit 0.

## Validity checks

All 20 reps complete, no zero-byte reps. Bodies identical across
arms (driver rc=0, checksums consistent). Cold reads 511 MB from
disk on both arms; warm reads 0 bytes.

## Result

The branch is consistently about 2% faster in both scenarios.
Median elapsed:

| scenario | base | variant | delta |
|---|---|---|---|
| cold | 22.80 s | 22.43 s | -1.6% |
| warm | 22.64 s | 22.20 s | -1.9% |

Rep ranges do not overlap in warm (base 22.55–23.03 s, variant
22.06–22.43 s) and touch at one point in cold (base 22.58–22.88
s, variant 22.05–22.58 s). All 10 variant reps beat their base
counterparts directionally. The effect is small but consistent,
not noise.

## Implication

First positive Wikidata signal for borrowed terms: a small,
consistent export win rather than a null. The MVP claim set is
frozen, so this is recorded here and left out of the prose.
