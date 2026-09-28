# PR #196 A/B on wikidata (turtle_export)

- Base: `376d92ad` base 376d92ad; server args: `(none)`
- Variant: `1273038c` variant 1273038c; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 2 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | base 376d92ad | 2 | 26.5148 | 26.2609 | 26.7686 |  |  |  |
| H-vocab-label-large-de | cold | variant 1273038c | 2 | 24.3330 | 24.2391 | 24.4269 | -8.23% | variant faster | identical bytes |
| H-vocab-label-large-de | warm | base 376d92ad | 2 | 18.6677 | 18.5472 | 18.7882 |  |  |  |
| H-vocab-label-large-de | warm | variant 1273038c | 2 | 15.9285 | 15.8475 | 16.0094 | -14.67% | variant faster | identical bytes |
| H-vocab-random-label-de-200k | cold | base 376d92ad | 2 | 10.5188 | 10.4847 | 10.5529 |  |  |  |
| H-vocab-random-label-de-200k | cold | variant 1273038c | 2 | 10.1566 | 10.1061 | 10.2070 | -3.44% | variant faster | identical bytes |
| H-vocab-random-label-de-200k | warm | base 376d92ad | 2 | 4.3719 | 4.3600 | 4.3837 |  |  |  |
| H-vocab-random-label-de-200k | warm | variant 1273038c | 2 | 4.1626 | 4.1299 | 4.1953 | -4.79% | variant faster | identical bytes |

## Verdict

- H-vocab-label-large-de cold: variant faster (-8.23%); correctness: identical bytes
- H-vocab-label-large-de warm: variant faster (-14.67%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: variant faster (-3.44%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: variant faster (-4.79%); correctness: identical bytes

## Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: PASS ==
- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Profiles

One extra warm rep per arm and query under `perf record -g` (not part of the timing): `perf/<query>/<arm>/` holds `report-top50.txt`, `stacks.folded` and `flame.svg` when FlameGraph was available; `perf/<query>/diff.svg` is the base-to-variant differential.

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
