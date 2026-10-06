# PR #3525 A/B on wikidata (turtle_export)

- Base: `f08433901cc002c41350dd9c665c0647c726602d` part5-3524; server args: `(none)`
- Variant: `e508af5dcd7ff44c07b1da47cd5c0d60340db221` part6-reap-slots; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 10 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | part5-3524 | 10 | 72.5910 | 65.2800 | 92.8913 |  |  |  |
| H-vocab-label-large-de | cold | part6-reap-slots | 10 | 90.8391 | 62.5489 | 93.6392 | +25.14% | within noise | identical bytes |
| H-vocab-label-large-de | warm | part5-3524 | 10 | 18.5757 | 15.6761 | 21.9004 |  |  |  |
| H-vocab-label-large-de | warm | part6-reap-slots | 10 | 17.2811 | 16.7029 | 23.7032 | -6.97% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de cold: within noise (+25.14%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (-6.97%); correctness: identical bytes

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
