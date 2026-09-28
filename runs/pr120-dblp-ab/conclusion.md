# PR #120 A/B on dblp (csv_export)

- Base: `e1993226` request fast-export=0; server args: `(none)`
- Variant: `e1993226` request fast-export=1; server args: `(none)`
- Binaries: same binary, runtime-flag A/B; host `ural` (ural layout)
- Reps: 5 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| D1-select | cold | request fast-export=0 | 5 | 0.0953 | 0.0923 | 0.0970 |  |  |  |
| D1-select | cold | request fast-export=1 | 5 | 0.0897 | 0.0850 | 0.0945 | -5.85% | within noise | identical bytes |
| D1-select | warm | request fast-export=0 | 5 | 0.0281 | 0.0280 | 0.0301 |  |  |  |
| D1-select | warm | request fast-export=1 | 5 | 0.0307 | 0.0294 | 0.0328 | +8.96% | within noise | identical bytes |
| R1-select | cold | request fast-export=0 | 5 | 1.1038 | 1.0971 | 1.1060 |  |  |  |
| R1-select | cold | request fast-export=1 | 5 | 0.4954 | 0.4885 | 0.5067 | -55.12% | variant faster | identical bytes |
| R1-select | warm | request fast-export=0 | 5 | 0.3086 | 0.3074 | 0.3115 |  |  |  |
| R1-select | warm | request fast-export=1 | 5 | 0.3507 | 0.3230 | 0.3586 | +13.62% | variant slower | identical bytes |
| R2-select | cold | request fast-export=0 | 5 | 2.3258 | 2.3108 | 2.3375 |  |  |  |
| R2-select | cold | request fast-export=1 | 5 | 0.7129 | 0.7074 | 0.7745 | -69.35% | variant faster | equal as multiset (order differs) |
| R2-select | warm | request fast-export=0 | 5 | 0.8118 | 0.7987 | 0.8136 |  |  |  |
| R2-select | warm | request fast-export=1 | 5 | 0.5756 | 0.5209 | 0.5778 | -29.10% | variant faster | equal as multiset (order differs) |
| H-vocab-title-large-select | cold | request fast-export=0 | 5 | 5.1420 | 5.1096 | 5.4026 |  |  |  |
| H-vocab-title-large-select | cold | request fast-export=1 | 5 | 1.1812 | 1.1607 | 1.2954 | -77.03% | variant faster | identical bytes |
| H-vocab-title-large-select | warm | request fast-export=0 | 5 | 0.4880 | 0.4858 | 0.4917 |  |  |  |
| H-vocab-title-large-select | warm | request fast-export=1 | 5 | 0.5291 | 0.5016 | 0.5411 | +8.41% | variant slower | identical bytes |

## Verdict

- D1-select cold: within noise (-5.85%); correctness: identical bytes
- D1-select warm: within noise (+8.96%); correctness: identical bytes
- R1-select cold: variant faster (-55.12%); correctness: identical bytes
- R1-select warm: variant slower (+13.62%); correctness: identical bytes
- R2-select cold: variant faster (-69.35%); correctness: equal as multiset (order differs)
- R2-select warm: variant faster (-29.10%); correctness: equal as multiset (order differs)
- H-vocab-title-large-select cold: variant faster (-77.03%); correctness: identical bytes
- H-vocab-title-large-select warm: variant slower (+8.41%); correctness: identical bytes

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

## Notes (dispatcher)

- Stacked PR: #120's base is `feat/export-v2-unified-pipeline` (#137), not master. This is a same-binary A/B at the PR head `e1993226`; the arms differ only in the request form field `fast-export` (0 = V1 legacy export, 1 = ExportEngineV2). The server log of every variant rep shows `ExportEngine: FastStreamingV2`.
- The harness ran the server with `--num-simultaneous-queries 1`, which also sizes `queryThreadPool_`; V2 therefore serialized morsels on ONE thread (`ExportEngineV2 serialize posts onto queryThreadPool_ (1 threads)`). The warm results measure V2 without its parallelism; the thesis expectation (speedup with idle query threads) is not tested here. A follow-up with 8 query threads is planned.
- Cold wins (R1 -55%, R2 -69%, H-vocab-title-large-select -77%) with one thread point at V2 overlapping block reads with serialization rather than at parallel serialization; the perf profiles under `perf/` are warm reps only.
- R2-select has no ORDER BY; V2 emits morsels in completion order, so its bodies equal the base as row multisets, not byte for byte.
