# PR #59 A/B on wikidata (turtle_export)

- Base: `51269ab4bf895211983287d1086c0a700ea43c86` part8-51269ab4; server args: `(none)`
- Variant: `e2a1530e2e4eca44c5c423e81dbee816b8412be5` part8+fixed-files-e2a1530e; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 10 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | part8-51269ab4 | 10 | 33.3982 | 24.4255 | 34.4507 |  |  |  |
| H-vocab-label-large-de | cold | part8+fixed-files-e2a1530e | 10 | 33.6768 | 23.2654 | 34.5697 | +0.83% | within noise | identical bytes |
| H-vocab-label-large-de | warm | part8-51269ab4 | 10 | 20.2710 | 15.9479 | 23.9229 |  |  |  |
| H-vocab-label-large-de | warm | part8+fixed-files-e2a1530e | 10 | 20.6225 | 17.1680 | 23.9291 | +1.73% | within noise | identical bytes |
| H-vocab-random-label-de-200k | cold | part8-51269ab4 | 10 | 11.4230 | 10.7890 | 12.5098 |  |  |  |
| H-vocab-random-label-de-200k | cold | part8+fixed-files-e2a1530e | 10 | 11.2174 | 10.9673 | 12.8865 | -1.80% | within noise | identical bytes |
| H-vocab-random-label-de-200k | warm | part8-51269ab4 | 10 | 4.6417 | 4.5769 | 5.4737 |  |  |  |
| H-vocab-random-label-de-200k | warm | part8+fixed-files-e2a1530e | 10 | 4.7054 | 4.6044 | 5.3567 | +1.37% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de cold: within noise (+0.83%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (+1.73%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: within noise (-1.80%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (+1.37%); correctness: identical bytes

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
