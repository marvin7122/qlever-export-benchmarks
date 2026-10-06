# Three-arm run: one base run, two comparisons

## base vs variant (3-stage-depth-2)
## PR #196 A/B on wikidata (turtle_export)

- Base: `f8cca285e3d0d3400dd51be97b5ebf078cd454de` p12-f8cca285; server args: `(none)`
- Variant: `4c4e9ddfe651c8d1e2308aeb3e014e15b73525f1` 3-stage-depth-2; server args: `--set-runtime-parameter construct-export-pipeline-depth=2 --set-runtime-parameter construct-export-pipeline-split-lookup=true`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 10 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

### Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | p12-f8cca285 | 10 | 33.7551 | 28.6183 | 37.8918 |  |  |  |
| H-vocab-label-large-de | cold | 3-stage-depth-2 | 10 | 18.3013 | 15.0603 | 20.8647 | -45.78% | variant faster | identical bytes |
| H-vocab-label-large-de | warm | p12-f8cca285 | 10 | 22.1945 | 15.9123 | 22.8488 |  |  |  |
| H-vocab-label-large-de | warm | 3-stage-depth-2 | 10 | 12.3781 | 8.9942 | 12.7221 | -44.23% | variant faster | identical bytes |
| H-vocab-random-label-de-200k | cold | p12-f8cca285 | 10 | 11.0720 | 10.5902 | 14.2861 |  |  |  |
| H-vocab-random-label-de-200k | cold | 3-stage-depth-2 | 10 | 9.8228 | 9.4565 | 12.4744 | -11.28% | within noise | identical bytes |
| H-vocab-random-label-de-200k | warm | p12-f8cca285 | 10 | 5.3094 | 4.0309 | 5.4332 |  |  |  |
| H-vocab-random-label-de-200k | warm | 3-stage-depth-2 | 10 | 4.8881 | 3.6695 | 5.0010 | -7.94% | within noise | identical bytes |
| H-vocab-label-large | cold | p12-f8cca285 | 10 | 32.4231 | 26.7756 | 39.3096 |  |  |  |
| H-vocab-label-large | cold | 3-stage-depth-2 | 10 | 18.6975 | 12.9430 | 29.6740 | -42.33% | within noise | identical bytes |
| H-vocab-label-large | warm | p12-f8cca285 | 10 | 35.7733 | 22.1504 | 39.2563 |  |  |  |
| H-vocab-label-large | warm | 3-stage-depth-2 | 10 | 18.3278 | 12.9119 | 22.0078 | -48.77% | variant faster | identical bytes |

### Verdict

- H-vocab-label-large-de cold: variant faster (-45.78%); correctness: identical bytes
- H-vocab-label-large-de warm: variant faster (-44.23%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: within noise (-11.28%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (-7.94%); correctness: identical bytes
- H-vocab-label-large cold: within noise (-42.33%); correctness: identical bytes
- H-vocab-label-large warm: variant faster (-48.77%); correctness: identical bytes

### Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: PASS ==
- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

### Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.

## base vs variant2 (depth-0-single-thread)
## PR #196 A/B on wikidata (turtle_export)

- Base: `f8cca285e3d0d3400dd51be97b5ebf078cd454de` p12-f8cca285; server args: `(none)`
- Variant: `4c4e9ddfe651c8d1e2308aeb3e014e15b73525f1` depth-0-single-thread; server args: `--set-runtime-parameter construct-export-pipeline-depth=0 --set-runtime-parameter construct-export-pipeline-split-lookup=true`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 10 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

### Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | p12-f8cca285 | 10 | 33.7551 | 28.6183 | 37.8918 |  |  |  |
| H-vocab-label-large-de | cold | depth-0-single-thread | 10 | 38.0295 | 27.2346 | 40.1629 | +12.66% | within noise | identical bytes |
| H-vocab-label-large-de | warm | p12-f8cca285 | 10 | 22.1945 | 15.9123 | 22.8488 |  |  |  |
| H-vocab-label-large-de | warm | depth-0-single-thread | 10 | 22.6609 | 16.7132 | 23.4524 | +2.10% | within noise | identical bytes |
| H-vocab-random-label-de-200k | cold | p12-f8cca285 | 10 | 11.0720 | 10.5902 | 14.2861 |  |  |  |
| H-vocab-random-label-de-200k | cold | depth-0-single-thread | 10 | 11.0002 | 10.6483 | 14.0520 | -0.65% | within noise | identical bytes |
| H-vocab-random-label-de-200k | warm | p12-f8cca285 | 10 | 5.3094 | 4.0309 | 5.4332 |  |  |  |
| H-vocab-random-label-de-200k | warm | depth-0-single-thread | 10 | 5.2819 | 3.9583 | 5.4560 | -0.52% | within noise | identical bytes |
| H-vocab-label-large | cold | p12-f8cca285 | 10 | 32.4231 | 26.7756 | 39.3096 |  |  |  |
| H-vocab-label-large | cold | depth-0-single-thread | 10 | 34.1842 | 24.7343 | 40.1144 | +5.43% | within noise | identical bytes |
| H-vocab-label-large | warm | p12-f8cca285 | 10 | 35.7733 | 22.1504 | 39.2563 |  |  |  |
| H-vocab-label-large | warm | depth-0-single-thread | 10 | 32.0381 | 24.8636 | 39.5347 | -10.44% | within noise | identical bytes |

### Verdict

- H-vocab-label-large-de cold: within noise (+12.66%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (+2.10%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: within noise (-0.65%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (-0.52%); correctness: identical bytes
- H-vocab-label-large cold: within noise (+5.43%); correctness: identical bytes
- H-vocab-label-large warm: within noise (-10.44%); correctness: identical bytes

### Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: PASS ==
- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

### Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
