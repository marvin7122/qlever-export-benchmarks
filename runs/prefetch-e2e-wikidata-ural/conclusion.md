# Conclusion for run prefetch-e2e-wikidata-ural (live-path prefetch A/B)

## Scope

Run prefetch-e2e-wikidata-ural tests the live-path wiring of software
prefetching end to end. The same `qlever-server` binary (branch
`feat/export-vocab-lookup-prefetch` at `e47b5472a`) served two Wikidata
H-vocab queries with `vocab-lookup-prefetch-distance` 0 (control) and 8
(prefetch): `H-vocab-random-label.rq` (50k VALUES subjects, CONSTRUCT
labels, 4.9 MiB output) and `H-vocab-label-large.rq` (humans label
export, 1.3 GiB output). Each condition ran 3 warm repetitions with a
fresh server per repetition on Ural on 2026-09-08.

## Validity checks

All 12 repetitions returned HTTP 200. Checksums match across arms per
query (xxh3_128 `6d8a61…` for random-label, `cf2bbf…` for label-large),
so prefetching changes no result byte. Syscall counts match per query
(158920 `pread64` for random-label in both arms), so both arms perform
identical I/O. Three repetitions per condition is thin; medians below
are reported without confidence intervals.

## Measurement results

Warm client-side elapsed medians over 3 repetitions:

| Query | Flag 0 | Flag 8 | Delta |
| --- | ---: | ---: | ---: |
| H-vocab-random-label | 2.038 s | 2.162 s | +6.1% |
| H-vocab-label-large | 23.130 s | 23.075 s | −0.2% |

Per-rep times in seconds, flag 0 then flag 8. Random-label: 2.003,
2.038, 2.178 versus 2.545, 2.059, 2.162. Label-large: 23.421, 23.130,
23.130 versus 23.501, 23.075, 22.664.

## Interpretation

The wired prefetching shows no end-to-end gain. Random-label is
WHERE-dominated (first byte at about 2 s of 2.1 s total), so vocabulary
lookup is a small fraction and the +6.1% sits inside run noise plus one
slow first repetition. Label-large is export-dominated (first byte at
0.09 s, 53 to 55 MiB/s over 23 s) and the −0.2% is indistinguishable
from noise. The +33% microbenchmark win does not transfer because the
live path resolves through `lookupBatch` with io_uring batching while
the remaining per-row work touches sequential batch arrays, leaving
almost no random CPU-cache access for prefetching to hide at this
layer. A further step would prefetch inside the vocabulary lookup
phases themselves; it was not pursued here.

## Code change

Branch `feat/export-vocab-lookup-prefetch` at `e47b5472a` (1 commit):
the `vocab-lookup-prefetch-distance` runtime parameter (default 0) and
a pipelined loop in `ql::exportIds::resolveVocabIndexIds` that
prefetches upcoming ID, position, and result slots. Default path,
callers, and the CONSTRUCT and SELECT export trees are unchanged.
`ExportIdsTest` (11 tests, including the new prefetch-equivalence test
over distances 1, 8, 1000 and empty input) passes on Ural.

## Artifact location

- Results: `/local/data-ssd/stoetzem/ai-review/prefetch-e2e-20260908T064314Z`
  (`raw/results.csv` holds all 12 repetitions)
- Binary: `/local/data-ssd/stoetzem/binaries/qlever-server-feat_export-vocab-lookup-prefetch`
- Branch: `marvin7122/qlever` `feat/export-vocab-lookup-prefetch`;
  worktree `~/code/qlever/.worktrees/vocab-prefetch`
- Run identifier: `prefetch-e2e-wikidata-ural`
