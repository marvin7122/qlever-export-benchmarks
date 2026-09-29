# PR #3547 A/B on wikidata (turtle_export)

- Base: `476247bc24a11b831d3898bf7886e4cbb6cad920` fastpath-off-fadv-random; server args: `--set-runtime-parameter vocabulary-iouring-page-cache-fast-path=false --set-runtime-parameter vocabulary-bench-fadvise-random=true`
- Variant: `476247bc24a11b831d3898bf7886e4cbb6cad920` fastpath-on-fadv-random; server args: `--set-runtime-parameter vocabulary-iouring-page-cache-fast-path=true --set-runtime-parameter vocabulary-bench-fadvise-random=true`
- Binaries: same binary, runtime-flag A/B; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | fastpath-off-fadv-random | 3 | 27.8494 | 27.7851 | 27.9272 |  |  |  |
| H-vocab-label-large-de | cold | fastpath-on-fadv-random | 3 | 23.8081 | 23.5292 | 23.8263 | -14.51% | variant faster | identical bytes |
| H-vocab-random-label-de-200k | cold | fastpath-off-fadv-random | 3 | 11.0120 | 10.7622 | 11.1039 |  |  |  |
| H-vocab-random-label-de-200k | cold | fastpath-on-fadv-random | 3 | 10.7803 | 10.7169 | 10.8272 | -2.10% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de cold: variant faster (-14.51%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: within noise (-2.10%); correctness: identical bytes

## Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
