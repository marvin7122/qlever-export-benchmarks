# PR #120 A/B on wikidata (csv_export)

- Base: `87f57674` request fast-export=0; server args: `(none)`
- Variant: `87f57674` request fast-export=1; server args: `(none)`
- Binaries: same binary, runtime-flag A/B; host `ural` (ural layout)
- Request form fields: base `fast-export=0`; variant `fast-export=1`
- Server query threads (`--num-simultaneous-queries`): 8
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| R1-select | cold | request fast-export=0 | 3 | 1.3116 | 1.2691 | 1.3215 |  |  |  |
| R1-select | cold | request fast-export=1 | 3 | 0.3904 | 0.3815 | 0.4069 | -70.24% | variant faster | identical bytes |
| R1-select | warm | request fast-export=0 | 3 | 0.3859 | 0.3841 | 0.3860 |  |  |  |
| R1-select | warm | request fast-export=1 | 3 | 0.2958 | 0.2918 | 0.3096 | -23.33% | variant faster | identical bytes |
| H-vocab-label-large-select | cold | request fast-export=0 | 3 | 21.2854 | 21.0475 | 21.5258 |  |  |  |
| H-vocab-label-large-select | cold | request fast-export=1 | 3 | 6.9187 | 6.8818 | 7.1567 | -67.50% | variant faster | identical bytes |
| H-vocab-label-large-select | warm | request fast-export=0 | 3 | 21.0312 | 20.7793 | 21.4794 |  |  |  |
| H-vocab-label-large-select | warm | request fast-export=1 | 3 | 6.8185 | 6.5458 | 6.8766 | -67.58% | variant faster | identical bytes |

## Verdict

- R1-select cold: variant faster (-70.24%); correctness: identical bytes
- R1-select warm: variant faster (-23.33%); correctness: identical bytes
- H-vocab-label-large-select cold: variant faster (-67.50%); correctness: identical bytes
- H-vocab-label-large-select warm: variant faster (-67.58%); correctness: identical bytes

## Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: PASS ==
- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.

## Context (added by hand)

- Ural queue seqs: build 4707 (branch work/pr120-postsub @ 87f57674 = PR #120 head after the review fixes), bench 4715. Index: Wikidata truthy.
- Mechanism check: 12/12 variant reps log `Using ExportEngineV2 for text/csv export`, with V2 posting onto `queryThreadPool_ (8 threads)`; 12/12 base reps are routed to Legacy V1.
- The binary (`bin/qlever-server-ab`) is not committed; it stays under the Ural run dir.
- H-vocab-label-large-select takes about the same time cold and warm in both arms (base 21.3 vs 21.0 s), so on this index the query is CPU-bound in computation plus serialization, not in index I/O. The V2 gain (-67.5%) is from parallel serialization and batched vocabulary resolution.
- No regression: no research loop needed.
