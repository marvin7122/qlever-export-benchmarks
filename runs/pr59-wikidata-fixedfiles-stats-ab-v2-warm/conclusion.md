# PR #59 A/B on wikidata (turtle_export)

- Base: `3aaff2de` routing-stats; server args: `(none)`
- Variant: `27e4cb88` fixedfiles-routing-stats; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 10 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | warm | routing-stats | 10 | 18.7812 | 18.5287 | 19.0946 |  |  |  |
| H-vocab-label-large-de | warm | fixedfiles-routing-stats | 10 | 18.1739 | 18.0733 | 18.7196 | -3.23% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de warm: within noise (-3.23%); correctness: identical bytes

## Gates

- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.

## Concern per row

| query | scenario | concern |
|---|---|---|
| H-vocab-label-large-de | warm | regression guard / CPU side: per-read fd lookup removed on page-cache hits (each execution >= 18 s) |
