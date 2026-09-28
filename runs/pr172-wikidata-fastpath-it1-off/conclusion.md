# PR #172 A/B on wikidata (turtle_export)

- Base: `c75e1927` master-c75e1927; server args: `(none)`
- Variant: `07d06bc5` routing-07d06bc5-fastpath-off; server args: `--set-runtime-parameter vocabulary-iouring-page-cache-fast-path=false`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 1 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | master-c75e1927 | 1 | 62.3912 | 62.3912 | 62.3912 |  |  |  |
| H-vocab-label-large-de | cold | routing-07d06bc5-fastpath-off | 1 | 26.6543 | 26.6543 | 26.6543 | -57.28% | variant faster | identical bytes |
| H-vocab-label-large-de | warm | master-c75e1927 | 1 | 16.6289 | 16.6289 | 16.6289 |  |  |  |
| H-vocab-label-large-de | warm | routing-07d06bc5-fastpath-off | 1 | 19.0646 | 19.0646 | 19.0646 | +14.65% | variant slower | identical bytes |
| H-vocab-random-label-de-200k | cold | master-c75e1927 | 1 | 27.1411 | 27.1411 | 27.1411 |  |  |  |
| H-vocab-random-label-de-200k | cold | routing-07d06bc5-fastpath-off | 1 | 10.9360 | 10.9360 | 10.9360 | -59.71% | variant faster | identical bytes |
| H-vocab-random-label-de-200k | warm | master-c75e1927 | 1 | 4.3745 | 4.3745 | 4.3745 |  |  |  |
| H-vocab-random-label-de-200k | warm | routing-07d06bc5-fastpath-off | 1 | 4.5244 | 4.5244 | 4.5244 | +3.43% | variant slower | identical bytes |

## Verdict

- H-vocab-label-large-de cold: variant faster (-57.28%); correctness: identical bytes
- H-vocab-label-large-de warm: variant slower (+14.65%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: variant faster (-59.71%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: variant slower (+3.43%); correctness: identical bytes

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
