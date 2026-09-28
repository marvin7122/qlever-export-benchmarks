# Conclusion for run prefetch-diverse-ural (diverse live-path prefetch A/B)

## Scope

Run prefetch-diverse-ural extends the earlier two-query end-to-end test
(`prefetch-e2e-wikidata-ural`) to a diverse set of four long-running
Wikidata queries through the live export path: `H-vocab-label-large.rq`
(humans label export, 1.3 GiB output), `H-vocab-description-large.rq`
(description export, 11.3 MiB output), `H-format.rq` (formatting-heavy
export, 21.3 MiB output), and `H-dedup.rq` (deduplicating export,
56.8 MiB output). The same `qlever-server` binary (branch
`feat/export-vocab-lookup-prefetch` at `e47b5472a`) served each query
with `vocab-lookup-prefetch-distance` 0 (control) and 8 (prefetch).
Each of the 8 conditions ran 3 warm repetitions on Ural on 2026-09-09
(benchmark job 3478, following pilot job 3474).

## Validity checks

All 24 repetitions returned HTTP 200. Checksums match across arms per
query (xxh3_128 `cf2bbf…` for label-large, `558391…` for
description-large, `c8835c…` for format, `dfb250…` for dedup), so
prefetching changes no result byte. Syscall counts match per query
(9815 `pread64` for label-large, 302812 for format, 66082 for dedup,
216 for description-large in both arms), so both arms perform identical
I/O. Three repetitions per condition is thin; medians below are
reported without confidence intervals. All repetitions show zero major
faults and zero swap activity, so the vocabulary and index pages were
resident in memory on this host; this run therefore does not cover the
out-of-memory case where vocabulary pages must be faulted in from disk.

## Measurement results

Warm client-side elapsed medians over 3 repetitions:

| Query | Flag 0 | Flag 8 | Delta |
| --- | ---: | ---: | ---: |
| H-vocab-label-large | 22.638 s | 22.705 s | +0.3% |
| H-vocab-description-large | 0.152 s | 0.153 s | +0.9% |
| H-format | 2.070 s | 2.118 s | +2.3% |
| H-dedup | 0.560 s | 0.566 s | +1.0% |

Per-rep times in seconds, flag 0 then flag 8. Label-large: 22.563,
22.638, 22.710 versus 22.666, 22.741, 22.705. Description-large:
0.152, 0.141, 0.161 versus 0.153, 0.160, 0.143. Format: 2.289, 2.060,
2.070 versus 2.118, 2.101, 2.299. Dedup: 0.558, 0.560, 0.565 versus
0.564, 0.578, 0.566.

## Interpretation

The wired prefetching shows no end-to-end gain on any of the four
queries; every delta is at or below about 2% and points slightly
against prefetching. This confirms and widens the earlier two-query
result (−0.2% on label-large, +6.1% noise on the WHERE-dominated
random-label query): software prefetching at the export-ID resolution
layer is neutral to slightly negative in the live path. The +33%
microbenchmark win does not transfer because the live path resolves
through `lookupBatch` with io_uring batching while the remaining
per-row work touches sequential batch arrays, leaving almost no random
CPU-cache access for prefetching to hide at this layer. A further step
would prefetch inside the vocabulary lookup phases themselves; it was
not pursued here. The open question that remains is the out-of-memory
case: if the vocabulary exceeds physical memory so lookups fault pages
in from disk, the latency profile changes completely and prefetching
(or io_uring batching at a different layer) might matter; measuring
that requires an index larger than host RAM or a memory-constrained
server, neither of which was available here.

## Code change

Branch `feat/export-vocab-lookup-prefetch` at `e47b5472a` (1 commit):
the `vocab-lookup-prefetch-distance` runtime parameter (default 0) and
a pipelined loop in `ql::exportIds::resolveVocabIndexIds` that
prefetches upcoming ID, position, and result slots. Default path,
callers, and the CONSTRUCT and SELECT export trees are unchanged.
`ExportIdsTest` (11 tests, including the new prefetch-equivalence test
over distances 1, 8, 1000 and empty input) passes on Ural.

## Artifact location

- Results: `/local/data-ssd/stoetzem/ai-review/prefetch-diverse-ab-20260909T155812Z`
  (`raw/results.csv` holds all 24 repetitions; pilot results in
  `/local/data-ssd/stoetzem/ai-review/prefetch-diverse-pilot-20260909T150405Z`)
- Binary: `/local/data-ssd/stoetzem/binaries/qlever-server-feat_export-vocab-lookup-prefetch`
- Branch: `marvin7122/qlever` `feat/export-vocab-lookup-prefetch`;
  worktree `~/code/qlever/.worktrees/vocab-prefetch`
- Run identifier: `prefetch-diverse-ural`
