# PR #59 A/B on wikidata (turtle_export)

- Base: `3aaff2de` routing-stats; server args: `(none)`
- Variant: `27e4cb88` fixedfiles-routing-stats; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 1 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | routing-stats | 1 | 26.8401 | 26.8401 | 26.8401 |  |  |  |
| H-vocab-label-large-de | cold | fixedfiles-routing-stats | 1 | 27.6415 | 27.6415 | 27.6415 | +2.99% | variant slower | identical bytes |
| H-vocab-random-label-de-200k | cold | routing-stats | 1 | 10.5626 | 10.5626 | 10.5626 |  |  |  |
| H-vocab-random-label-de-200k | cold | fixedfiles-routing-stats | 1 | 10.3984 | 10.3984 | 10.3984 | -1.55% | variant faster | identical bytes |

## Verdict

- H-vocab-label-large-de cold: variant slower (+2.99%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: variant faster (-1.55%); correctness: identical bytes

## Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
