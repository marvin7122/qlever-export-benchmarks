# Conclusion for run 122 (SELECT export baseline)

## Scope

Run 122 establishes the SELECT (CSV) export baseline for the five-query
SELECT D/R/H suite against the DBLP index on Ural. It measures the current
QLever code state, commit `c801fe1b` on branch `marvin-construct-row-batch`
(binary `CIKM-2494-gc801fe1b`). On this state the SELECT CSV/TSV export path
resolves every Id-table cell with a separate `idToStringAndType` call, which
issues one `pread64` syscall per vocabulary-backed identifier. The batched
`idsToStringAndType` path is not present in `ExportQueryExecutionTrees.cpp`.
No optimization is implemented here; that is the follow-up issue #45.

Queries (SELECT suite, Issue #39):

- `H-vocab-title-large-select.rq` (H, vocab-heavy, 100k title rows x 2 cols)
- `H-size-select.rq` (H, year-bound output-size sweep)
- `D1-select.rq` (D, broad scan over 12 publication IRIs)
- `R1-select.rq` (R, bounded venue materialization, LIMIT 50000)
- `R2-select.rq` (R, unbounded venue materialization)

## Protocol

Five measured repetitions per query per cache scenario. TRUE cold cache is
enforced with `/local/data-ssd/stoetzem/clear-caches` (writes 1 to
`/proc/sys/vm/drop_caches`) before every cold rep, in addition to the
harness's advisory `vmtouch` eviction. A fresh server is started for every
rep on port 7015 with `action=csv_export` and `Accept: text/csv`. Driver:
`scripts/run_select_baseline.sh`.

## Validity checks

All 50 measured requests returned HTTP 200 with a non-zero `text/csv`
response body. `major_faults` is greater than 0 in every cold rep (median
14 to 16) and 0 in every warm rep, confirming the index mmap was cold or
warm as intended. Response byte counts are stable within each query and
scenario. No benchmark server remained after the run.

## Measurement results (median over 5 reps, client-observed `elapsed_s`)

| Query | Cold (s) | Warm (s) | Cold/Warm | Cold read_bytes | Cold syscr | Response bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| H-vocab-title-large-select | 5.0353 | 0.4182 | 12.0x | 632,684,544 | 399,754 | 11,346,544 |
| H-size-select | 5.3257 | 2.3013 | 2.31x | 420,683,776 | 2,708,171 | 56,692,914 |
| D1-select | 0.0919 | 0.0285 | 3.22x | 4,673,536 | 740 | 9,923 |
| R1-select | 1.0457 | 0.2659 | 3.93x | 48,291,840 | 271,891 | 5,654,210 |
| R2-select | 2.1344 | 0.6805 | 3.14x | 101,068,800 | 780,477 | 16,194,131 |

## Interpretation: bottleneck class

The SELECT export path is **I/O-bound under cold cache**. Cold-cache time
exceeds warm-cache time by 2.3x to 12.0x across the suite, and the added
cold time is dominated by physical reads from the external vocabulary file.
The vocab-heavy query (`H-vocab-title-large-select`) reads 633 MB from disk
and is the clearest case: 4.6 s of its 5.04 s cold time is vocabulary disk
read on top of a 0.42 s warm baseline. `read_bytes` is 0 in every warm rep
and scales from 4.7 MB (D1) to 633 MB (H-vocab) in cold reps, so the
cold-vs-warm gap is vocabulary I/O, not CPU work.

Under warm cache the same path becomes **serialization/syscall-bound**. With
no disk reads the warm times still scale with the number of Id-table cells:
`H-size-select` issues 2.71 million read syscalls and takes 2.30 s warm to
serialize 56.7 MB of CSV, while `D1-select` issues 740 syscalls and takes
0.03 s. The syscall count is identical in cold and warm runs, which shows
the per-cell `idToStringAndType` resolution is paid on every cell regardless
of cache state. The cold measurements therefore inherit a per-cell syscall
and serialization floor that the warm numbers expose directly.

The unified root cause is the unbatched per-cell vocabulary resolution on
the SELECT CSV/TSV path. The cold H-vocab median of 5.035 s reproduces the
5.087 s "old path" measurement of run 120 within 1%, confirming that this
binary is the pre-batching baseline that #45 optimizes.

## Artefacts

- Ural run directory: `/local/data-ssd/stoetzem/thesis/experiments/runs/122-select-export-baseline`
- Local mirror: `experiments/runs/122-select-export-baseline`
- Driver: `scripts/run_select_baseline.sh`
- Per-rep CSVs: `raw/results.csv` under each `query/scenario/rep-*/` dir
- Query suite: `representative-queries/*-select.rq` (Issue #39)
- Binary: `/local/data-ssd/stoetzem/qlever-src/build/qlever-server` (`CIKM-2494-gc801fe1b`)
