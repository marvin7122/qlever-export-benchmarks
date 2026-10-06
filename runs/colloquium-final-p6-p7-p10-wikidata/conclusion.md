# Three-arm run: one base run, two comparisons

## base vs variant (p10-final-fastpath)
## PR #3528 A/B on wikidata (turtle_export)

- Base: `a752a45716c20e19467508f62801d64f36c0a60a` p6-before-pread; server args: `(none)`
- Variant: `4dd60f853612dacc4405c713638b1726c6382877` p10-final-fastpath; server args: `(none)`
- Binaries: three binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 10 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

### Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | p6-before-pread | 10 | 88.6664 | 66.0708 | 93.6780 |  |  |  |
| H-vocab-label-large-de | cold | p10-final-fastpath | 10 | 33.8301 | 24.5538 | 34.5437 | -61.85% | variant faster | identical bytes |
| H-vocab-label-large-de | warm | p6-before-pread | 10 | 24.4296 | 15.8950 | 24.8646 |  |  |  |
| H-vocab-label-large-de | warm | p10-final-fastpath | 10 | 23.4583 | 15.5763 | 24.1575 | -3.98% | within noise | identical bytes |
| H-vocab-random-label-de-200k | cold | p6-before-pread | 10 | 39.3190 | 27.5501 | 40.8224 |  |  |  |
| H-vocab-random-label-de-200k | cold | p10-final-fastpath | 10 | 14.2116 | 11.0292 | 14.6214 | -63.86% | variant faster | identical bytes |
| H-vocab-random-label-de-200k | warm | p6-before-pread | 10 | 3.9314 | 3.8471 | 5.4190 |  |  |  |
| H-vocab-random-label-de-200k | warm | p10-final-fastpath | 10 | 3.9811 | 3.9164 | 5.5213 | +1.26% | within noise | identical bytes |
| H-vocab-label-large | cold | p6-before-pread | 10 | 28.5786 | 22.3047 | 40.3129 |  |  |  |
| H-vocab-label-large | cold | p10-final-fastpath | 10 | 26.8054 | 22.3635 | 40.7911 | -6.20% | within noise | identical bytes |
| H-vocab-label-large | warm | p6-before-pread | 10 | 39.5572 | 22.5839 | 44.0820 |  |  |  |
| H-vocab-label-large | warm | p10-final-fastpath | 10 | 38.7585 | 26.1807 | 42.9332 | -2.02% | within noise | identical bytes |

### Verdict

- H-vocab-label-large-de cold: variant faster (-61.85%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (-3.98%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: variant faster (-63.86%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (+1.26%); correctness: identical bytes
- H-vocab-label-large cold: within noise (-6.20%); correctness: identical bytes
- H-vocab-label-large warm: within noise (-2.02%); correctness: identical bytes

### Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: PASS ==
- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant2.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant2.log`: VERDICT: PASS — binary is trustworthy for benchmarking

### Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.

## base vs variant2 (p7-ring-only)
## PR #3528 A/B on wikidata (turtle_export)

- Base: `a752a45716c20e19467508f62801d64f36c0a60a` p6-before-pread; server args: `(none)`
- Variant: `60f854f42e2af6984924a2b5f692e6b8b407310c` p7-ring-only; server args: `(none)`
- Binaries: three binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 10 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

### Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | p6-before-pread | 10 | 88.6664 | 66.0708 | 93.6780 |  |  |  |
| H-vocab-label-large-de | cold | p7-ring-only | 10 | 39.1691 | 35.6265 | 39.7366 | -55.82% | variant faster | identical bytes |
| H-vocab-label-large-de | warm | p6-before-pread | 10 | 24.4296 | 15.8950 | 24.8646 |  |  |  |
| H-vocab-label-large-de | warm | p7-ring-only | 10 | 27.2261 | 20.8102 | 28.8043 | +11.45% | within noise | identical bytes |
| H-vocab-random-label-de-200k | cold | p6-before-pread | 10 | 39.3190 | 27.5501 | 40.8224 |  |  |  |
| H-vocab-random-label-de-200k | cold | p7-ring-only | 10 | 14.2901 | 11.4409 | 14.5286 | -63.66% | variant faster | identical bytes |
| H-vocab-random-label-de-200k | warm | p6-before-pread | 10 | 3.9314 | 3.8471 | 5.4190 |  |  |  |
| H-vocab-random-label-de-200k | warm | p7-ring-only | 10 | 4.0826 | 4.0183 | 4.8784 | +3.85% | within noise | identical bytes |
| H-vocab-label-large | cold | p6-before-pread | 10 | 28.5786 | 22.3047 | 40.3129 |  |  |  |
| H-vocab-label-large | cold | p7-ring-only | 10 | 32.4009 | 22.3573 | 40.9697 | +13.37% | within noise | identical bytes |
| H-vocab-label-large | warm | p6-before-pread | 10 | 39.5572 | 22.5839 | 44.0820 |  |  |  |
| H-vocab-label-large | warm | p7-ring-only | 10 | 41.0203 | 22.8633 | 55.5756 | +3.70% | within noise | identical bytes |

### Verdict

- H-vocab-label-large-de cold: variant faster (-55.82%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (+11.45%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: variant faster (-63.66%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (+3.85%); correctness: identical bytes
- H-vocab-label-large cold: within noise (+13.37%); correctness: identical bytes
- H-vocab-label-large warm: within noise (+3.70%); correctness: identical bytes

### Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: PASS ==
- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant2.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant2.log`: VERDICT: PASS — binary is trustworthy for benchmarking

### Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
