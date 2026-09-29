# PR #3526 A/B on wikidata (turtle_export)

- Base: `533f800b87ffd1857291e27bc1ce63dacc1ca003` part6-3525; server args: `(none)`
- Variant: `15f447df54b915a02659f3a156c876299cad25dc` p7-wave-reap; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | part6-3525 | 3 | 62.6361 | 62.6210 | 62.6441 |  |  |  |
| H-vocab-label-large-de | cold | p7-wave-reap | 3 | 24.2346 | 23.9153 | 24.3607 | -61.31% | variant faster | identical bytes |
| H-vocab-label-large-de | warm | part6-3525 | 3 | 17.0388 | 17.0262 | 17.3002 |  |  |  |
| H-vocab-label-large-de | warm | p7-wave-reap | 3 | 16.3212 | 16.2612 | 16.5356 | -4.21% | variant faster | identical bytes |

## Verdict

- H-vocab-label-large-de cold: variant faster (-61.31%); correctness: identical bytes
- H-vocab-label-large-de warm: variant faster (-4.21%); correctness: identical bytes

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
