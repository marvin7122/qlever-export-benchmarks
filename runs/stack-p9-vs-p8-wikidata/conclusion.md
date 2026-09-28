# PR #3528 A/B on wikidata (turtle_export)

- Base: `c35325d021382ef194837f70d770d4f07e717c4e` base c35325d0; server args: `(none)`
- Variant: `154bf7bfda2ea5292d01f92ad9dce34dd6d0224b` variant 154bf7bf; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | warm | base c35325d0 | 3 | 19.5960 | 18.8995 | 19.7605 |  |  |  |
| H-vocab-label-large-de | warm | variant 154bf7bf | 3 | 19.2450 | 19.0412 | 20.4943 | -1.79% | within noise | identical bytes |
| H-vocab-random-label-de-200k | warm | base c35325d0 | 3 | 4.7516 | 4.5784 | 4.7635 |  |  |  |
| H-vocab-random-label-de-200k | warm | variant 154bf7bf | 3 | 4.7221 | 4.6491 | 4.8415 | -0.62% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de warm: within noise (-1.79%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (-0.62%); correctness: identical bytes

## Gates

- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
