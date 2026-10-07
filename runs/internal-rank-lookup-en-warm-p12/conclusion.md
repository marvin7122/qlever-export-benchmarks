# Three-arm run: one base run, two comparisons

## base vs variant (rank-lookup-12c10ee7)
## PR #264 A/B on wikidata (turtle_export)

- Base: `d20a4c74ab76e844364eea53a8ac144ea54729c0` stack12-22-d20a4c74; server args: `(none)`
- Variant: `12c10ee76289a92f09d310d4658984c19e4f3f3c` rank-lookup-12c10ee7; server args: `--set-runtime-parameter vocabulary-internal-rank-lookup=true`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

### Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large | warm | stack12-22-d20a4c74 | 3 | 24.8268 | 23.0487 | 24.8773 |  |  |  |
| H-vocab-label-large | warm | rank-lookup-12c10ee7 | 3 | 19.6209 | 19.4910 | 19.7366 | -20.97% | variant faster | identical bytes |

### Verdict

- H-vocab-label-large warm: variant faster (-20.97%); correctness: identical bytes

### Gates

- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

### Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.

## base vs variant2 (sorted-batch-12c10ee7)
## PR #264 A/B on wikidata (turtle_export)

- Base: `d20a4c74ab76e844364eea53a8ac144ea54729c0` stack12-22-d20a4c74; server args: `(none)`
- Variant: `12c10ee76289a92f09d310d4658984c19e4f3f3c` sorted-batch-12c10ee7; server args: `--set-runtime-parameter vocabulary-internal-rank-lookup=false --set-runtime-parameter vocabulary-internal-sorted-batch-lookup=true`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

### Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large | warm | stack12-22-d20a4c74 | 3 | 24.8268 | 23.0487 | 24.8773 |  |  |  |
| H-vocab-label-large | warm | sorted-batch-12c10ee7 | 3 | 27.5519 | 25.5727 | 29.1726 | +10.98% | variant slower | identical bytes |

### Verdict

- H-vocab-label-large warm: variant slower (+10.98%); correctness: identical bytes

### Gates

- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

### Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
