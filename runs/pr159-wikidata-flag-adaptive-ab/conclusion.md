# PR #159 A/B on wikidata (csv_export)

- Base: `6133c138` select-export-term-cache-capacity=0; server args: `--set-runtime-parameter select-export-term-cache-capacity=0`
- Variant: `6133c138` select-export-term-cache-min-hit-rate=0.25; server args: `--set-runtime-parameter select-export-term-cache-min-hit-rate=0.25`
- Binaries: same binary, runtime-flag A/B; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-size-select | warm | select-export-term-cache-capacity=0 | 3 | 0.2149 | 0.2140 | 0.2171 |  |  |  |
| H-size-select | warm | select-export-term-cache-min-hit-rate=0.25 | 3 | 0.2164 | 0.2164 | 0.2174 | +0.68% | within noise | identical bytes |

## Verdict

- H-size-select warm: within noise (+0.68%); correctness: identical bytes

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

Same binary `6133c138`, bench seq 4710. Base: cache off. Variant: the fix's default,
switch the cache off when a window of 8192 cached lookups has a hit rate below 25 %
(`select-export-term-cache-min-hit-rate=0.25`, window 8192, capacity 2^16).
Log: 125 hits, 8,067 misses in the first window (1.5 %), then the cache switched off and
191,808 lookups went straight to the vocabulary. Result: +0.68 %, ranges overlap, within
noise. The +19.93 % regression (always-on arm, seq 4703) is gone.
