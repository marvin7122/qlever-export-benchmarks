# PR #3477 A/B on wikidata (turtle_export)

- Base: `95f657ab9548758a2bbe9c81df147d11f1278aa9` base 95f657ab; server args: `(none)`
- Variant: `dbaff3f862f15ba6467a26d117fb5e992f106e79` variant dbaff3f8; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | base 95f657ab | 3 | 23.6763 | 23.3093 | 24.0763 |  |  |  |
| H-vocab-label-large-de | cold | variant dbaff3f8 | 3 | 23.9371 | 23.8961 | 23.9781 | +1.10% | within noise | identical bytes |
| H-vocab-label-large-de | warm | base 95f657ab | 3 | 15.9650 | 15.6645 | 16.0564 |  |  |  |
| H-vocab-label-large-de | warm | variant dbaff3f8 | 3 | 16.0346 | 15.8096 | 16.0976 | +0.44% | within noise | identical bytes |
| H-vocab-random-label-de-200k | cold | base 95f657ab | 3 | 10.8321 | 10.7853 | 10.9538 |  |  |  |
| H-vocab-random-label-de-200k | cold | variant dbaff3f8 | 3 | 10.8063 | 10.7779 | 11.0375 | -0.24% | within noise | identical bytes |
| H-vocab-random-label-de-200k | warm | base 95f657ab | 3 | 4.5704 | 4.5021 | 4.5907 |  |  |  |
| H-vocab-random-label-de-200k | warm | variant dbaff3f8 | 3 | 4.6161 | 4.5950 | 4.6571 | +1.00% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de cold: within noise (+1.10%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (+0.44%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: within noise (-0.24%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (+1.00%); correctness: identical bytes

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
