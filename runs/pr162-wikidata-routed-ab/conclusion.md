# PR #162 A/B on wikidata (turtle_export)

- Base: `376d92ad` base 376d92ad; server args: `(none)`
- Variant: `6463b3ce` variant 6463b3ce; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 5 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | base 376d92ad | 5 | 26.7687 | 26.0246 | 27.2917 |  |  |  |
| H-vocab-label-large-de | cold | variant 6463b3ce | 5 | 26.7581 | 26.3434 | 26.9065 | -0.04% | within noise | identical bytes |
| H-vocab-random-label-de-200k | cold | base 376d92ad | 5 | 10.5519 | 10.4349 | 10.6863 |  |  |  |
| H-vocab-random-label-de-200k | cold | variant 6463b3ce | 5 | 10.4325 | 10.3973 | 10.6016 | -1.13% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de cold: within noise (-0.04%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: within noise (-1.13%); correctness: identical bytes

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

- H-vocab-label-large-de: 402 stacks containing io_uring
- H-vocab-random-label-de-200k: 153 stacks containing io_uring

The variant's read path reaches the ring on both queries (per-thread rings wiring confirmed).
