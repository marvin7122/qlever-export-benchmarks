# PR #3476 A/B on wikidata (turtle_export)

- Base: `f9fc54f69d7492a907383e244e291d29de6d8d83` base f9fc54f6; server args: `(none)`
- Variant: `95f657ab9548758a2bbe9c81df147d11f1278aa9` p15-controller-on; server args: `--set-runtime-parameter iouring-adaptive-batch-enabled=true`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | base f9fc54f6 | 3 | 23.7973 | 23.7621 | 23.8369 |  |  |  |
| H-vocab-label-large-de | cold | p15-controller-on | 3 | 23.9791 | 23.7360 | 24.0088 | +0.76% | within noise | identical bytes |
| H-vocab-label-large-de | warm | base f9fc54f6 | 3 | 15.7106 | 15.5004 | 15.8758 |  |  |  |
| H-vocab-label-large-de | warm | p15-controller-on | 3 | 15.6983 | 15.6249 | 15.8995 | -0.08% | within noise | identical bytes |
| H-vocab-random-label-de-200k | cold | base f9fc54f6 | 3 | 10.8887 | 10.8703 | 10.9779 |  |  |  |
| H-vocab-random-label-de-200k | cold | p15-controller-on | 3 | 10.8128 | 10.7359 | 10.8719 | -0.70% | within noise | identical bytes |
| H-vocab-random-label-de-200k | warm | base f9fc54f6 | 3 | 4.6338 | 4.5923 | 4.6708 |  |  |  |
| H-vocab-random-label-de-200k | warm | p15-controller-on | 3 | 4.5770 | 4.5475 | 4.6593 | -1.23% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de cold: within noise (+0.76%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (-0.08%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: within noise (-0.70%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (-1.23%); correctness: identical bytes

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
