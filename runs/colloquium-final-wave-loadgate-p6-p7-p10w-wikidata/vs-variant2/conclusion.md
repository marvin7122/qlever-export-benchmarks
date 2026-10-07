# PR #3528 A/B on wikidata (turtle_export)

- Base: `a752a45716c20e19467508f62801d64f36c0a60a` p6-before-pread; server args: `(none)`
- Variant: `60f854f42e2af6984924a2b5f692e6b8b407310c` p7-ring-only; server args: `(none)`
- Binaries: three binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | p6-before-pread | 3 | 93.3857 | 91.8467 | 93.5867 |  |  |  |
| H-vocab-label-large-de | cold | p7-ring-only | 3 | 39.4291 | 39.1317 | 39.4474 | -57.78% | variant faster | identical bytes |
| H-vocab-label-large-de | warm | p6-before-pread | 3 | 21.1959 | 19.7352 | 24.4715 |  |  |  |
| H-vocab-label-large-de | warm | p7-ring-only | 3 | 28.6569 | 28.4295 | 28.6963 | +35.20% | variant slower | identical bytes |
| A-scatter-disambig-label-de | cold | p6-before-pread | 3 | 63.4190 | 62.1701 | 83.7195 |  |  |  |
| A-scatter-disambig-label-de | cold | p7-ring-only | 3 | 14.7721 | 11.1562 | 14.7924 | -76.71% | variant faster | identical bytes |
| A-scatter-disambig-label-de | warm | p6-before-pread | 3 | 3.6759 | 3.1033 | 3.7511 |  |  |  |
| A-scatter-disambig-label-de | warm | p7-ring-only | 3 | 3.5433 | 3.4502 | 3.5517 | -3.61% | within noise | identical bytes |
| H-vocab-label-large | cold | p6-before-pread | 3 | 26.5599 | 23.9214 | 34.4406 |  |  |  |
| H-vocab-label-large | cold | p7-ring-only | 3 | 28.2348 | 26.5103 | 31.0806 | +6.31% | within noise | identical bytes |
| H-vocab-label-large | warm | p6-before-pread | 3 | 42.2086 | 26.0201 | 44.5347 |  |  |  |
| H-vocab-label-large | warm | p7-ring-only | 3 | 46.0310 | 42.7886 | 46.5102 | +9.06% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de cold: variant faster (-57.78%); correctness: identical bytes
- H-vocab-label-large-de warm: variant slower (+35.20%); correctness: identical bytes
- A-scatter-disambig-label-de cold: variant faster (-76.71%); correctness: identical bytes
- A-scatter-disambig-label-de warm: within noise (-3.61%); correctness: identical bytes
- H-vocab-label-large cold: within noise (+6.31%); correctness: identical bytes
- H-vocab-label-large warm: within noise (+9.06%); correctness: identical bytes

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
