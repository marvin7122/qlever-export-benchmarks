# PR #3526 A/B on wikidata (turtle_export)

- Base: `533f800b87ffd1857291e27bc1ce63dacc1ca003` base 533f800b; server args: `(none)`
- Variant: `0ed8f9223497196d8979accb24ac737becc42f2b` variant 0ed8f922; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | base 533f800b | 3 | 64.5783 | 62.9614 | 65.1509 |  |  |  |
| H-vocab-label-large-de | cold | variant 0ed8f922 | 3 | 27.5690 | 27.5465 | 28.6476 | -57.31% | variant faster | identical bytes |
| H-vocab-label-large-de | warm | base 533f800b | 3 | 17.0387 | 16.9058 | 18.1497 |  |  |  |
| H-vocab-label-large-de | warm | variant 0ed8f922 | 3 | 19.3454 | 18.9538 | 20.5579 | +13.54% | variant slower | identical bytes |
| H-vocab-random-label-de-200k | cold | base 533f800b | 3 | 27.5107 | 27.5094 | 28.0136 |  |  |  |
| H-vocab-random-label-de-200k | cold | variant 0ed8f922 | 3 | 11.0364 | 10.9517 | 11.1261 | -59.88% | variant faster | identical bytes |
| H-vocab-random-label-de-200k | warm | base 533f800b | 3 | 4.6406 | 4.6211 | 4.8042 |  |  |  |
| H-vocab-random-label-de-200k | warm | variant 0ed8f922 | 3 | 4.6331 | 4.5821 | 4.6382 | -0.16% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de cold: variant faster (-57.31%); correctness: identical bytes
- H-vocab-label-large-de warm: variant slower (+13.54%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: variant faster (-59.88%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (-0.16%); correctness: identical bytes

## Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: PASS ==
- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
