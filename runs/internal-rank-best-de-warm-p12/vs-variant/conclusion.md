# PR #264 A/B on wikidata (turtle_export)

- Base: `d20a4c74ab76e844364eea53a8ac144ea54729c0` stack12-22-d20a4c74; server args: `(none)`
- Variant: `6770bbf2c7e4a06793c31eff504b9526ac530c96` pf8-6770bbf2; server args: `--set-runtime-parameter vocabulary-internal-rank-lookup=true --set-runtime-parameter vocabulary-internal-rank-prefetch-distance=8 --set-runtime-parameter vocabulary-internal-rank-hugepages=false`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | warm | stack12-22-d20a4c74 | 3 | 23.7708 | 19.9421 | 23.7939 |  |  |  |
| H-vocab-label-large-de | warm | pf8-6770bbf2 | 3 | 18.0704 | 11.9146 | 18.1250 | -23.98% | variant faster | identical bytes |

## Verdict

- H-vocab-label-large-de warm: variant faster (-23.98%); correctness: identical bytes

## Gates

- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
