# PR #120 A/B on dblp (csv_export)

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
| R1-select | cold | request fast-export=0 | 3 | 1.1285 | 1.1090 | 1.1337 |  |  |  |
| R1-select | cold | request fast-export=1 | 3 | 0.2047 | 0.1880 | 0.2121 | -81.86% | variant faster | identical bytes |
| R1-select | warm | request fast-export=0 | 3 | 0.3098 | 0.3090 | 0.3108 |  |  |  |
| R1-select | warm | request fast-export=1 | 3 | 0.1004 | 0.0981 | 0.1035 | -67.58% | variant faster | identical bytes |
| H-vocab-title-large-select | cold | request fast-export=0 | 3 | 5.1984 | 5.1856 | 5.2180 |  |  |  |
| H-vocab-title-large-select | cold | request fast-export=1 | 3 | 0.3564 | 0.3523 | 0.3676 | -93.14% | variant faster | identical bytes |
| H-vocab-title-large-select | warm | request fast-export=0 | 3 | 0.4854 | 0.4850 | 0.4871 |  |  |  |
| H-vocab-title-large-select | warm | request fast-export=1 | 3 | 0.1899 | 0.1862 | 0.1977 | -60.88% | variant faster | identical bytes |

## Verdict

- R1-select cold: variant faster (-81.86%); correctness: identical bytes
- R1-select warm: variant faster (-67.58%); correctness: identical bytes
- H-vocab-title-large-select cold: variant faster (-93.14%); correctness: identical bytes
- H-vocab-title-large-select warm: variant faster (-60.88%); correctness: identical bytes

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

- Ural queue seqs: build 4707 (branch work/pr120-postsub @ 87f57674 = PR #120 head after the review fixes), bench 4709.
- Mechanism check: server logs show `ExportEngineV2 serialize posts onto queryThreadPool_ (8 threads)`; every variant rep logs `Using ExportEngineV2 for text/csv export` (12/12), every base rep is routed to Legacy V1 (12/12).
- The binary (`bin/qlever-server-ab`, 54 MB) is not committed; it stays under the Ural run dir.
- Compared with the 1-query-thread A/B (run pr120-warmfix-dblp-ural, head 0fb1cb2c, Ural seq 4653), the variant medians drop further with 8 threads: R1-select cold 0.426 -> 0.205 s, warm 0.267 -> 0.100 s; H-vocab-title-large-select cold 1.103 -> 0.356 s, warm 0.382 -> 0.190 s. The base (Legacy V1, single-threaded serialization) is unchanged: 1.158/1.129 s, 0.372/0.310 s, 5.200/5.198 s, 0.484/0.485 s. The two runs used different heads (0fb1cb2c vs 87f57674; the difference is only exception handling and a contract check off the hot loop), so this is a cross-run comparison, not an A/B.
- No regression: no research loop needed.
