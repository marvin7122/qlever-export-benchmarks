# PR #3506 A/B on wikidata (turtle_export)

- Base: `3a19a966f3023c91f345aa59b6ad85ab89655bcf` part12-upstream-stack-22; server args: `(none)`
- Variant: `f9fc54f69d7492a907383e244e291d29de6d8d83` part13-depth2-construct; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | part12-upstream-stack-22 | 3 | 23.4663 | 23.4525 | 23.6899 |  |  |  |
| H-vocab-label-large-de | cold | part13-depth2-construct | 3 | 23.7405 | 23.5099 | 24.2007 | +1.17% | within noise | identical bytes |
| H-vocab-label-large-de | warm | part12-upstream-stack-22 | 3 | 15.6611 | 15.6501 | 15.8543 |  |  |  |
| H-vocab-label-large-de | warm | part13-depth2-construct | 3 | 15.9665 | 15.5463 | 16.0131 | +1.95% | within noise | identical bytes |
| H-vocab-random-label-de-200k | cold | part12-upstream-stack-22 | 3 | 10.8057 | 10.7814 | 11.0228 |  |  |  |
| H-vocab-random-label-de-200k | cold | part13-depth2-construct | 3 | 10.9311 | 10.8589 | 10.9619 | +1.16% | within noise | identical bytes |
| H-vocab-random-label-de-200k | warm | part12-upstream-stack-22 | 3 | 4.5339 | 4.4893 | 4.5771 |  |  |  |
| H-vocab-random-label-de-200k | warm | part13-depth2-construct | 3 | 4.6634 | 4.6205 | 4.6737 | +2.85% | variant slower | identical bytes |
| H-vocab-label-large | cold | part12-upstream-stack-22 | 3 | 23.8003 | 23.4147 | 24.0018 |  |  |  |
| H-vocab-label-large | cold | part13-depth2-construct | 3 | 23.9933 | 23.9674 | 24.0314 | +0.81% | within noise | identical bytes |
| H-vocab-label-large | warm | part12-upstream-stack-22 | 3 | 23.4022 | 23.3722 | 23.6210 |  |  |  |
| H-vocab-label-large | warm | part13-depth2-construct | 3 | 23.5909 | 23.4514 | 23.6968 | +0.81% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de cold: within noise (+1.17%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (+1.95%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: within noise (+1.16%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: variant slower (+2.85%); correctness: identical bytes
- H-vocab-label-large cold: within noise (+0.81%); correctness: identical bytes
- H-vocab-label-large warm: within noise (+0.81%); correctness: identical bytes

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
