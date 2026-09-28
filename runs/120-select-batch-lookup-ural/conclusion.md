# Conclusion for run 120 (SELECT batch vocab lookup)

## Scope

Run 120 compares the SELECT CSV/TSV export path before and after batching
`VocabIndex` ID-to-string lookups. The old path called `idToStringAndType`
once per Id-table cell, issuing one `pread64` syscall per vocabulary-backed
ID. The new path collects IDs from 1000-row batches and resolves them with a
single `idsToStringAndType` call, which performs one batched vocabulary
lookup (`lookupBatch`) per batch.

The comparison uses the query `H-vocab-title-large-select.rq` (100 000 DBLP
title literals, SELECT form) against the official DBLP index on Ural. Both
binaries were compiled from the same source commit
`8c8577bfe1423cdf573e7266110ec7284d77ac38` (branch `marvin-dedup-wire-up`),
with only `ExportQueryExecutionTrees.cpp` differing between old and new.

## Validity checks

The new binary produces byte-identical CSV output to the old binary
(11 346 544 bytes, verified with `diff`). All measured repetitions returned
HTTP 200. Server was restarted and page cache was evicted between the cold
measurements.

## Measurement results

Server: Ural, DBLP index (1.59×10⁹ triples, 4.47×10⁸ vocabulary entries).
Query: `H-vocab-title-large-select.rq` (100 000 rows, 2 columns).
Five repetitions per condition.

| Binary | Cache | Median | Min | Max |
| --- | --- | ---: | ---: | ---: |
| Old (per-ID) | warm | 0.389 s | 0.376 s | 0.395 s |
| New (batched) | warm | 0.369 s | 0.361 s | 0.381 s |
| Old (per-ID) | cold | 5.087 s | — | — |
| New (batched) | cold | 0.363 s | 0.361 s | 0.390 s |

The warm-cache improvement is modest (−5.2 % median) because the index fits
in Ural's page cache and the per-ID `pread64` syscalls operate on in-memory
pages. The cold-cache improvement is substantial (−93 %, approximately 14×)
because the batched path issues far fewer disk reads for vocabulary-backed
identifiers.

## Interpretation

The optimization eliminates the per-cell `pread64` syscall bottleneck on the
SELECT CSV/TSV export path. The benefit scales with vocabulary cache pressure:
negligible when the external vocabulary is resident in the page cache, but
dramatic when vocabulary pages must be read from disk. This pattern matches
the thesis target scenario (full Wikidata export on hardware where the
external vocabulary exceeds available page cache).

## Code change

File: `src/engine/ExportQueryExecutionTrees.cpp`, function
`selectQueryResultToStream` (CSV/TSV template), lines 516–590.
The change replaces the inner loop that called `idToStringAndType` per cell
with batch collection into a flat `std::vector<Id>` followed by a single
`idsToStringAndType` call, reusing the existing batched-resolution
infrastructure from `src/index/ExportIds.h`.

## Artifact location

- Ural build directory: `/local/data-ssd/stoetzem/qlever-src`
- Old binary: `/tmp/qlever-server-old` (55 545 688 bytes)
- New binary: `/tmp/qlever-server-new` (55 559 280 bytes)
- Run identifier: `120-select-batch-lookup-ural`
- Query: `~/thesis/representative-queries/H-vocab-title-large-select.rq`
