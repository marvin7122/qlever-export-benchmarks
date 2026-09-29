# PR #3526 A/B on wikidata (turtle_export)

- Base: `6b71e1e5511344222a7691b1cfa3d3e3fcccf48f` part7-3526; server args: `(none)`
- Variant: `15f447df54b915a02659f3a156c876299cad25dc` p7-wave-reap; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | part7-3526 | 3 | 27.4920 | 27.3904 | 27.5371 |  |  |  |
| H-vocab-label-large-de | cold | p7-wave-reap | 3 | 24.3213 | 24.2647 | 24.4256 | -11.53% | variant faster | identical bytes |
| H-vocab-label-large-de | warm | part7-3526 | 3 | 19.5914 | 19.5878 | 19.7265 |  |  |  |
| H-vocab-label-large-de | warm | p7-wave-reap | 3 | 16.4852 | 16.2054 | 16.5667 | -15.86% | variant faster | identical bytes |

## Verdict

- H-vocab-label-large-de cold: variant faster (-11.53%); correctness: identical bytes
- H-vocab-label-large-de warm: variant faster (-15.86%); correctness: identical bytes

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
