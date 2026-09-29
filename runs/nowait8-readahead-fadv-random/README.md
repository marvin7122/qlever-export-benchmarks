# #3547: cold gain on Wikidata with readahead turned off (Ural 5247, 2026-09-29)

Bench-only binary `bench/nowait8-hitcount` 476247bc2 (#3547 + FASTPATH_STATS counters + `vocabulary-bench-fadvise-random`, which applies `POSIX_FADV_RANDOM` to the vocabulary files before each batched lookup). Classic harness (pr-ab-multi-v2), cold, 3 interleaved reps per arm, byte-identical output.

Arms: base = fast path off + FADV_RANDOM; variant = fast path on + FADV_RANDOM; variant2 = fast path on, normal readahead. `run.sh` is the driver as it is now; the stats parsing at its end was made layout-independent after this run (the run used the per-rep version, output `fastpath-stats.tsv`).

| query | arm | median | word hits | offset-pair hits | read from device |
|---|---|---|---|---|---|
| H-vocab-label-large-de | off + FADV_RANDOM | 27.85 s | – | – | 4.36 GB |
| H-vocab-label-large-de | on + FADV_RANDOM | 23.81 s (−14.5 %) | 86.6 % | 89.0 % | 4.36 GB |
| H-vocab-label-large-de | on, normal | 23.77 s (−14.7 %) | 92.4 % | 94.4 % | 9.44 GB |
| H-vocab-random-label-de-200k | off + FADV_RANDOM | 11.01 s | – | – | 2.69 GB |
| H-vocab-random-label-de-200k | on + FADV_RANDOM | 10.78 s (−2.1 %) | 19.0 % | 23.5 % | 2.69 GB |
| H-vocab-random-label-de-200k | on, normal | 10.99 s (−0.2 %) | 20.9 % | 27.4 % | 2.99 GB |
