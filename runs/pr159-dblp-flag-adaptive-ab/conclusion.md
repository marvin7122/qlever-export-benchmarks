# PR #159 A/B on dblp (csv_export)

- Base: `6133c138` select-export-term-cache-capacity=0; server args: `--set-runtime-parameter select-export-term-cache-capacity=0`
- Variant: `6133c138` select-export-term-cache-min-hit-rate=0.25; server args: `--set-runtime-parameter select-export-term-cache-min-hit-rate=0.25`
- Binaries: same binary, runtime-flag A/B; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-size-select | warm | select-export-term-cache-capacity=0 | 3 | 2.6141 | 2.5635 | 2.6457 |  |  |  |
| H-size-select | warm | select-export-term-cache-min-hit-rate=0.25 | 3 | 0.5649 | 0.5648 | 0.5651 | -78.39% | variant faster | identical bytes |

## Verdict

- H-size-select warm: variant faster (-78.39%); correctness: identical bytes

## Gates

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

## Research loop (PR #159, step 3: fix re-measure)

Same binary `6133c138`, bench seq 4711. Base: cache off. Variant: default adaptive cache
(threshold 25 % per 8192-lookup window). The cache stays on for the whole export (log:
1,261,689 hits, 210,261 misses, 0 bypassed, same as always-on). Result: -78.39 %, ranges
disjoint (always-on arm, seq 4704: -78.83 %). The DBLP win is kept.
