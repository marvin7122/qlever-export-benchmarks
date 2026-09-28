# #3547 readahead question: page-cache hit shares with and without POSIX_FADV_RANDOM (Wolga 256, screening)

Wolga, DBLP, qlever-server capped at 2 GiB (MemoryMax, page cache included), kernel 5.15. Screening only: one execution per arm and scenario, cold = our-files-only eviction. Binary: bench-only branch `bench/nowait8-hitcount` 476247bc2 (#3547 + FASTPATH_STATS counters + `vocabulary-bench-fadvise-random`). Driver: `run.sh`. Counters per arm: `counters.md`; fast-path counters: `fastpath-stats.tsv` (last cumulative FASTPATH_STATS line of each server log). Companion query: `../nowait8-readahead-dblp-H-size`.

Cold, fast path on (hits = reads served by preadv2(RWF_NOWAIT)):

| query | FADV_RANDOM | word hits | offset-pair hits | device read | CPU on / off |
|---|---|---|---|---|---|
| H-vocab-title-large | no | 133,273 / 177,377 (75.1 %) | 162,340 / 177,377 (91.5 %) | 694 MB | 2.51 / 5.09 s |
| H-vocab-title-large | yes | 60,496 / 196,847 (30.7 %) | 77,875 / 196,847 (39.6 %) | 301 MB | 4.38 / 5.01 s |
| H-size | no | 113,428 / 142,017 (79.9 %) | 123,120 / 142,017 (86.7 %) | 464 MB | 2.53 / 4.92 s |
| H-size | yes | 100,717 / 134,636 (74.8 %) | 109,874 / 134,888 (81.5 %) | 282 MB | 2.71 / 4.58 s |
