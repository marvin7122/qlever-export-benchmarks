# Three-arm run: one base run, two comparisons

## base vs variant (pf8-6770bbf2)
## PR #264 A/B on wikidata (turtle_export)

- Base: `d20a4c74ab76e844364eea53a8ac144ea54729c0` stack12-22-d20a4c74; server args: `(none)`
- Variant: `6770bbf2c7e4a06793c31eff504b9526ac530c96` pf8-6770bbf2; server args: `--set-runtime-parameter vocabulary-internal-rank-lookup=true --set-runtime-parameter vocabulary-internal-rank-prefetch-distance=8 --set-runtime-parameter vocabulary-internal-rank-hugepages=false`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

### Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large | cold | stack12-22-d20a4c74 | 3 | 38.6600 | 38.4713 | 38.9308 |  |  |  |
| H-vocab-label-large | cold | pf8-6770bbf2 | 3 | 21.5349 | 20.6556 | 22.2365 | -44.30% | variant faster | identical bytes |
| H-vocab-label-large | warm | stack12-22-d20a4c74 | 3 | 38.6791 | 38.4606 | 39.3059 |  |  |  |
| H-vocab-label-large | warm | pf8-6770bbf2 | 3 | 16.5172 | 13.6457 | 17.7955 | -57.30% | variant faster | identical bytes |

### Verdict

- H-vocab-label-large cold: variant faster (-44.30%); correctness: identical bytes
- H-vocab-label-large warm: variant faster (-57.30%); correctness: identical bytes

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

## base vs variant2 (rank-6770bbf2)
## PR #264 A/B on wikidata (turtle_export)

- Base: `d20a4c74ab76e844364eea53a8ac144ea54729c0` stack12-22-d20a4c74; server args: `(none)`
- Variant: `6770bbf2c7e4a06793c31eff504b9526ac530c96` rank-6770bbf2; server args: `--set-runtime-parameter vocabulary-internal-rank-lookup=true --set-runtime-parameter vocabulary-internal-rank-prefetch-distance=0 --set-runtime-parameter vocabulary-internal-rank-hugepages=false`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

### Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large | cold | stack12-22-d20a4c74 | 3 | 38.6600 | 38.4713 | 38.9308 |  |  |  |
| H-vocab-label-large | cold | rank-6770bbf2 | 3 | 24.5884 | 24.5348 | 24.9990 | -36.40% | variant faster | identical bytes |
| H-vocab-label-large | warm | stack12-22-d20a4c74 | 3 | 38.6791 | 38.4606 | 39.3059 |  |  |  |
| H-vocab-label-large | warm | rank-6770bbf2 | 3 | 16.7961 | 16.0693 | 17.6549 | -56.58% | variant faster | identical bytes |

### Verdict

- H-vocab-label-large cold: variant faster (-36.40%); correctness: identical bytes
- H-vocab-label-large warm: variant faster (-56.58%); correctness: identical bytes

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
