# Run 132: cold-cache export latency attribution (conclusion)

Ural seqs 3758 and 3759, 2026-09-17, both ALL DONE. Seq 3759 is an
identical rerun of the same script and binary; the artifacts on disk are
the second run. Both runs agree within 0.6 percentage points on every
share, so the numbers below cite the second run. Binary:
`/local/data-ssd/stoetzem/wt/master/build/qlever-server v0.6.0-89-g090c76f64`.
Index: Wikidata truthy (`/local/data-ssd/stoetzem/wikidata`). Queries:
`H-vocab-label-large.rq` (CONSTRUCT `turtle_export`) and
`H-vocab-label-large-select.rq` (SELECT `csv_export`).

## Method

Each workload ran three reps with the page cache evicted before every
rep and no warmup. Eviction used advisory `posix_fadvise` `DONTNEED` over
the serving-manifest files. One `perf record` session per workload sampled
at 999 Hz with dwarf call graphs, attached to the server PID.
Server flags: `--construct-deduplication none`,
all result caches size 0, one simultaneous query. Preflight aborts on
missing perf, symbols, index files, or queries. Zero lost samples in both
sessions; `[unknown]` symbols below 0.5%.

## Numbers

Client-observed elapsed per rep (HTTP 200, `time_total`, bytes):

| Workload | Rep 1 (s) | Rep 2 (s) | Rep 3 (s) | Body bytes |
|---|---|---|---|---|
| CONSTRUCT turtle | 22.44 | 22.59 | 22.75 | 1302749672 |
| SELECT csv | 20.02 | 20.18 | 20.27 | 674222797 |

All three reps per workload returned byte-identical bodies. Rep times are
flat: no first-rep cold penalty is visible.

Attribution shares from `perf report --no-children` (second run; first run
in parentheses):

| Workload | Lookup | Format | Other |
|---|---|---|---|
| CONSTRUCT | 46.27 (46.33) | 4.55 (4.56) | 46.05 (46.24) |
| SELECT | 53.94 (53.41) | 9.64 (9.79) | 34.40 (34.71) |

Top on-CPU symbols (share of all samples):

| Symbol | CONSTRUCT | SELECT |
|---|---|---|
| `VocabularyInMemoryBinSearch::positionOfIndex` | 23.73% | 31.08% |
| `fsst_decompress` | 8.83% | 13.65% |
| `DecoderMultiplexer::decompress` (FSST) | 5.59% | 4.71% |
| `ConstructBatchEvaluator::evaluateVariableByColumn` | 5.32% | n/a |
| `RdfEscaping::escapeForCsv` | n/a | 3.90% |
| `ValueId::compareThreeWay` | 2.80% | 1.38% |
| jemalloc `operator new` + `operator delete` | 4.12% | 2.67% |

Kernel symbols total 1.22% (CONSTRUCT) and 0.98% (SELECT). `__libc_pread`
samples at 0.00% in both profiles. No `io_uring` symbol appears.

## Verdict

The profile does not show storage-read dominance. The export path burns
about one core for the full request wall time, and the samples concentrate
in ID-to-string materialization: binary search over the in-memory
vocabulary index plus FSST decompression account for 38% (CONSTRUCT) and
49% (SELECT) of all samples. Storage reads contribute no measurable
on-CPU share.

One caveat limits the cold reading. The eviction helper uses advisory
`POSIX_FADV_DONTNEED`, which cannot drop pages that remain mapped by the
running server. Residency after eviction was not verified, and the flat
rep times point the same way: this profile may be effectively warm. A
true-cold test needs privileged `drop_caches` or a working set larger
than RAM, neither of which this run had.

## Design consequence

This evidence does not motivate asynchronous storage reads for the
export path: with the working set resident, nothing waits on storage.
It motivates batching that amortizes per-row CPU cost instead (binary
search, FSST decompress, per-row allocation and string growth). The
`io_uring` batch design must therefore target the vocab-materialization
stage, not the read stage, unless a true-cold profile shows otherwise.

## Artifacts

`driver.log` (both runs appended), `results-summary.txt`,
`qlever-server.log`, per workload: `requests.tsv`, `share.txt`,
`flat.txt`, `callgraph.txt`, `out.folded`, `flamegraph.svg`.
Excluded from this commit: `perf.data*` (1.1-1.2 GB), `perf.script`,
response bodies (0.7-1.3 GB). They remain on Ural at
`experiments/runs/132-export-cold-latency/`.
