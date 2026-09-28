# PR #172 A/B on wikidata (turtle_export)

- Base: `c75e1927` master-c75e1927; server args: `(none)`
- Variant: `07d06bc5` routing-07d06bc5-fastpath-on; server args: `--set-runtime-parameter vocabulary-iouring-page-cache-fast-path=true`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 1 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | master-c75e1927 | 1 | 63.0106 | 63.0106 | 63.0106 |  |  |  |
| H-vocab-label-large-de | cold | routing-07d06bc5-fastpath-on | 1 | 23.3209 | 23.3209 | 23.3209 | -62.99% | variant faster | identical bytes |
| H-vocab-label-large-de | warm | master-c75e1927 | 1 | 16.1406 | 16.1406 | 16.1406 |  |  |  |
| H-vocab-label-large-de | warm | routing-07d06bc5-fastpath-on | 1 | 15.7804 | 15.7804 | 15.7804 | -2.23% | variant faster | identical bytes |
| H-vocab-random-label-de-200k | cold | master-c75e1927 | 1 | 27.1423 | 27.1423 | 27.1423 |  |  |  |
| H-vocab-random-label-de-200k | cold | routing-07d06bc5-fastpath-on | 1 | 10.5779 | 10.5779 | 10.5779 | -61.03% | variant faster | identical bytes |
| H-vocab-random-label-de-200k | warm | master-c75e1927 | 1 | 4.4028 | 4.4028 | 4.4028 |  |  |  |
| H-vocab-random-label-de-200k | warm | routing-07d06bc5-fastpath-on | 1 | 4.4210 | 4.4210 | 4.4210 | +0.41% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de cold: variant faster (-62.99%); correctness: identical bytes
- H-vocab-label-large-de warm: variant faster (-2.23%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: variant faster (-61.03%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (+0.41%); correctness: identical bytes

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
