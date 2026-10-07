# PR #3528 A/B on wikidata (turtle_export)

- Base: `a752a45716c20e19467508f62801d64f36c0a60a` p6-before-pread; server args: `(none)`
- Variant: `77a41c663a28ebfd6453fba1e23902fd94630ff8` p10-wave-final; server args: `(none)`
- Binaries: three binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | p6-before-pread | 3 | 93.3857 | 91.8467 | 93.5867 |  |  |  |
| H-vocab-label-large-de | cold | p10-wave-final | 3 | 33.7509 | 33.4245 | 34.0693 | -63.86% | variant faster | identical bytes |
| H-vocab-label-large-de | warm | p6-before-pread | 3 | 21.1959 | 19.7352 | 24.4715 |  |  |  |
| H-vocab-label-large-de | warm | p10-wave-final | 3 | 21.2406 | 18.6324 | 23.8979 | +0.21% | within noise | identical bytes |
| A-scatter-disambig-label-de | cold | p6-before-pread | 3 | 63.4190 | 62.1701 | 83.7195 |  |  |  |
| A-scatter-disambig-label-de | cold | p10-wave-final | 3 | 13.6300 | 11.2871 | 13.6589 | -78.51% | variant faster | identical bytes |
| A-scatter-disambig-label-de | warm | p6-before-pread | 3 | 3.6759 | 3.1033 | 3.7511 |  |  |  |
| A-scatter-disambig-label-de | warm | p10-wave-final | 3 | 3.0698 | 3.0621 | 3.1442 | -16.49% | within noise | identical bytes |
| H-vocab-label-large | cold | p6-before-pread | 3 | 26.5599 | 23.9214 | 34.4406 |  |  |  |
| H-vocab-label-large | cold | p10-wave-final | 3 | 30.3416 | 24.2422 | 37.4194 | +14.24% | within noise | identical bytes |
| H-vocab-label-large | warm | p6-before-pread | 3 | 42.2086 | 26.0201 | 44.5347 |  |  |  |
| H-vocab-label-large | warm | p10-wave-final | 3 | 45.6765 | 42.2786 | 45.7855 | +8.22% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de cold: variant faster (-63.86%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (+0.21%); correctness: identical bytes
- A-scatter-disambig-label-de cold: variant faster (-78.51%); correctness: identical bytes
- A-scatter-disambig-label-de warm: within noise (-16.49%); correctness: identical bytes
- H-vocab-label-large cold: within noise (+14.24%); correctness: identical bytes
- H-vocab-label-large warm: within noise (+8.22%); correctness: identical bytes

## Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: PASS ==
- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant2.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant2.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
