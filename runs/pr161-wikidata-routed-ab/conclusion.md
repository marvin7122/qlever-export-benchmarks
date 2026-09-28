# PR #161 A/B on wikidata (turtle_export)

- Base: `376d92ad` base 376d92ad; server args: `(none)`
- Variant: `a0c8ee82` variant a0c8ee82; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 5 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | base 376d92ad | 5 | 26.4537 | 26.3304 | 26.7803 |  |  |  |
| H-vocab-label-large-de | cold | variant a0c8ee82 | 5 | 23.3073 | 23.0519 | 23.5466 | -11.89% | variant faster | identical bytes |
| H-vocab-random-label-de-200k | cold | base 376d92ad | 5 | 10.5327 | 10.4453 | 10.5794 |  |  |  |
| H-vocab-random-label-de-200k | cold | variant a0c8ee82 | 5 | 10.0803 | 9.9922 | 10.1356 | -4.30% | variant faster | identical bytes |

## Verdict

- H-vocab-label-large-de cold: variant faster (-11.89%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: variant faster (-4.30%); correctness: identical bytes

## Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Profiles

One extra warm rep per arm and query under `perf record -g` (not part of the timing): `perf/<query>/<arm>/` holds `report-top50.txt`, `stacks.folded` and `flame.svg` when FlameGraph was available; `perf/<query>/diff.svg` is the base-to-variant differential.

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.

## io_uring reach (variant, `grep -c io_uring perf/*/variant/stacks.folded`)

- H-vocab-label-large-de: 328 stacks containing io_uring
- H-vocab-random-label-de-200k: 102 stacks containing io_uring

The variant's perf profile shows the read path actually reaching the ring on both queries, confirming the wiring (adaptive batching + batched reap) is exercised by this A/B, not bypassed.
