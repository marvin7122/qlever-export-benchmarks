# PR #3529 A/B on dblp (csv_export)

- Base: `3c9b75e971c3c73fc89ad04d38ab7b7a016a4017` base 3c9b75e9; server args: `(none)`
- Variant: `d95f40d446eef1b9e999aff6c4ea91302c49960c` p10-flag-off; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-size-select | warm | base 3c9b75e9 | 3 | 2.9581 | 2.8503 | 2.9588 |  |  |  |
| H-size-select | warm | p10-flag-off | 3 | 2.9496 | 2.8904 | 2.9609 | -0.29% | within noise | identical bytes |

## Verdict

- H-size-select warm: within noise (-0.29%); correctness: identical bytes

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

| query | scenario | arm | concern |
|---|---|---|---|
| H-size-select | warm | p10-flag-off | regression guard: SELECT export untouched |
