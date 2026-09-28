# PR #3529 A/B on dblp (turtle_export)

- Base: `154bf7bfda2ea5292d01f92ad9dce34dd6d0224b` base 154bf7bf; server args: `(none)`
- Variant: `30699e6156104e4a8bb9e4bd077d3c61be595b65` p10-flag-on; server args: `--set-runtime-parameter use-fast-export-stream-formatter=true`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-size | warm | base 154bf7bf | 3 | 0.6516 | 0.6377 | 0.6653 |  |  |  |
| H-size | warm | p10-flag-on | 3 | 0.6448 | 0.6174 | 0.6585 | -1.04% | within noise | identical bytes |

## Verdict

- H-size warm: within noise (-1.04%); correctness: identical bytes

## Gates

- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
