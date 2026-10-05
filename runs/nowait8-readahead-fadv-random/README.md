# How often does a cold German-label export find its words already in the page cache?

## Question

PR #3547 adds a page-cache fast path: before a vocabulary word goes to the io_uring ring, a non-blocking `preadv2(RWF_NOWAIT)` tries to read it straight from the OS page cache.
This run asks why that fast path also helps on a cold cache.
The suspect is kernel readahead: reading one word pulls its neighbours into the page cache, so later words are already there.
To test that, one arm switches readahead off for the vocabulary files (`POSIX_FADV_RANDOM`), and a bench-only binary counts how many words the fast path serves.

## Setup

1. Machine: `ural`, AMD Ryzen 7 3700X (8 cores, 16 threads), 125 GiB RAM (about 135 GB), index on a software RAID (`/dev/md1`) of two Samsung 990 PRO NVMe SSDs, Linux 7.0.0-28 (`env-before.txt`).
2. Index: Wikidata truthy, 8.2 billion triples (`/local/data-ssd/stoetzem/wikidata/wikidata`).
3. Queries (Turtle CONSTRUCT export, German labels; German labels live in the on-disk part of the vocabulary):
   - [`H-vocab-label-large-de.rq`](queries/H-vocab-label-large-de.rq): every human with a German label, a sequential scan ("sequential").
   - [`H-vocab-random-label-de-200k.rq`](queries/H-vocab-random-label-de-200k.rq): German labels of 200,000 entities given in a `VALUES` list, scattered over the vocabulary ("scattered").
4. Arms: one bench-only binary, `bench/nowait8-hitcount` at `476247bc2` (#3547 plus `FASTPATH_STATS` counters plus the `vocabulary-bench-fadvise-random` switch), three runtime settings:
   - `base`: fast path off, readahead off (`FADV_RANDOM`);
   - `variant`: fast path on, readahead off (`FADV_RANDOM`);
   - `variant2`: fast path on, normal readahead.
5. Cold only: the OS page cache is dropped before each repetition.
6. Repetitions: 3 per arm and query, arms interleaved with alternating order; tables report medians.

## Result

| query | arm | elapsed, median | name lookups served from the page cache (rep 1) |
|---|---|---:|---:|
| sequential | fast path off, `FADV_RANDOM` | 27.85 s | – |
| sequential | fast path on, `FADV_RANDOM` | 23.81 s | 3,845,045 / 4,438,827 = 86.6 % |
| sequential | fast path on, normal readahead | 23.77 s | 4,101,685 / 4,437,805 = 92.4 % |
| scattered | fast path off, `FADV_RANDOM` | 11.01 s | – |
| scattered | fast path on, `FADV_RANDOM` | 10.78 s | 33,548 / 176,158 = 19.0 % |
| scattered | fast path on, normal readahead | 10.99 s | 35,255 / 169,085 = 20.9 % |

The share is `wordHits / words` from `fastpath-stats.tsv`; the other two reps of each arm agree to within 1.5 percentage points.
With readahead off, the fast path still serves 86.6 % of the sequential export's words, and its cold gain stays (−14.5 % with `FADV_RANDOM`, −14.7 % with normal readahead).
So kernel readahead explains little of the cold gain.
On the scattered export the fast path serves only about one word in five, and the time change is within noise.

## Used in the colloquium talk

The talk takes the page-cache hit share of the name reads from `fastpath-stats.tsv`, cold, fast path on with normal readahead (arm `variant2`), rep 1:

1. sequential: 4,101,685 of 4,437,805 name lookups = 92.4 %;
2. scattered: 35,255 of 169,085 name lookups = 20.9 %;
3. about 4.43 million name lookups per sequential export (`words` = 4,417,412 to 4,441,773 across all reps).

## Original run note

### #3547: cold gain on Wikidata with readahead turned off (Ural 5247, 2026-09-29)

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

## Files

- `README.md`: this file.
- `COMPLETE`: driver completion marker with timestamp.
- `meta.env`: the A/B definition: commit, binary, runtime flags per arm, queries, scenario, repetitions, threads.
- `run.sh`: the driver script (its stats parsing at the end was made layout-independent after this run).
- `driver.log`: the driver's console log, one line per finished repetition with syscall and I/O counters.
- `results.csv`: one row per repetition: query, scenario, arm, rep, status, elapsed and first-byte time, response bytes, CPU seconds, bytes read from disk, read syscalls, major faults, checksums, correctness.
- `aggregate.txt`: per query and arm the medians of elapsed time, bytes read and read syscalls, and the number of distinct checksums.
- `conclusion.md`: the two comparisons (base vs variant, base vs variant2) with median/min/max, delta, verdict, gates.
- `correctness.tsv`: byte count, line count and checksums of every response; all arms produce identical output.
- `fastpath-stats.tsv`: the `FASTPATH_STATS` counters per rep: `words` (name lookups), `wordHits` (served by the fast path from the page cache), `wordsRing` (sent to the io_uring ring), offset-pair counters, `preadv2` outcomes, `fadvise` calls.
- `env-before.txt`, `env-after.txt`: host snapshot before and after the run (kernel, CPU governor, load, memory, page cache size, disk).
- `gate-preflight-*.log`, `gate-verify-*.log`: binary and host checks before the run; `gate-postflight-cold.log`: completeness and cold-cache checks after it. All PASS.
- `queries/`: the two SPARQL queries.
- `cold/<query>/<arm>/`: harness output per repetition (`raw/r<N>-cold/`: result, server log, page-cache snapshots) and per-rep metadata.
- `vs-variant/`, `vs-variant2/`: the two pairwise comparisons, with their own `conclusion.md`, `results.csv`, gates; arm directories are links into `cold/`.
