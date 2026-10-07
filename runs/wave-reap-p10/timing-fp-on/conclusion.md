# PR #161 A/B on wikidata (turtle_export)

- Base: `4dd60f853612dacc4405c713638b1726c6382877` part10-4dd60f85; server args: `(none)`
- Variant: `77a41c663a28ebfd6453fba1e23902fd94630ff8` wave-reap-77a41c66; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 10 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-random-label-de-200k | cold | part10-4dd60f85 | 10 | 11.3902 | 10.2435 | 14.2606 |  |  |  |
| H-vocab-random-label-de-200k | cold | wave-reap-77a41c66 | 10 | 11.8651 | 10.6545 | 14.1512 | +4.17% | within noise | identical bytes |
| H-vocab-random-label-de-200k | warm | part10-4dd60f85 | 10 | 4.0218 | 3.9530 | 4.7811 |  |  |  |
| H-vocab-random-label-de-200k | warm | wave-reap-77a41c66 | 10 | 4.0865 | 3.9616 | 4.7146 | +1.61% | within noise | identical bytes |
| H-vocab-label-large-de | cold | part10-4dd60f85 | 10 | 35.1045 | 26.6218 | 35.4339 |  |  |  |
| H-vocab-label-large-de | cold | wave-reap-77a41c66 | 10 | 35.0592 | 25.1311 | 35.4285 | -0.13% | within noise | identical bytes |
| H-vocab-label-large-de | warm | part10-4dd60f85 | 10 | 20.2256 | 16.7948 | 24.5150 |  |  |  |
| H-vocab-label-large-de | warm | wave-reap-77a41c66 | 10 | 22.2651 | 16.3825 | 24.9393 | +10.08% | within noise | identical bytes |

## Verdict

- H-vocab-random-label-de-200k cold: within noise (+4.17%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (+1.61%); correctness: identical bytes
- H-vocab-label-large-de cold: within noise (-0.13%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (+10.08%); correctness: identical bytes

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
