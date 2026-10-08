# Export V2: fewer copies (fork PR #268), allocation counts and perf stat, 1 query thread, Ural

## Question

Does fork PR marvin7122/qlever#268 remove the per-cell heap allocations of the V2 SELECT CSV/TSV serializer when a single thread does all the work, so no saturation effect can hide the per-row CPU saving?
Timing is not the point of this run (see the Wolga A/B runs); allocation claims need direct counts.

## Setup

1. Machine: `ural`, AMD Ryzen 7 3700X, governor `powersave`.
   The box was busy (load1 20.5 at the start, `meta.txt`), so the wall and CPU seconds below are not a verdict.
2. Index: Wikidata truthy; query `query.rq` (English labels of all humans, SELECT CSV, 674,222,797 bytes, 11,643,064 rows).
3. Arms (`driver.log`, `*/version.txt`), V2 (`fast-export=1`), `--num-simultaneous-queries 1`, warm:
   1. `base`: `87f57674` (`work/pr120-postsub`);
   2. `variant`: `719615ab` (`perf/export-v2-fewer-copies`).
4. Driver `driver.sh` (thesis `scripts/v2-fewer-copies/v2-fewer-copies-profile.sh`), per arm:
   1. warm-up query, then `perf stat` over back-to-back queries for ≥ 10 s (here 1 query);
   2. one query under `perf record -e cycles -F 499 --call-graph dwarf,16384`;
   3. a fresh server under the LD_PRELOAD shim `alloc_count.cpp`, warm-up query, counters zeroed (SIGUSR1), one query, counters dumped (SIGUSR2).
      The shim counts `malloc`/`calloc`/`realloc`/aligned allocations and every C++ `operator new` (QLever's jemalloc exports its own `operator new`, which a malloc-only shim misses).
5. Correctness: every body has the same byte count and sorted-line md5 as the first base body (`correctness.tsv`: all OK).

## Results

| # | concern | metric | base | variant | Δ |
|---|---|---|---|---|---|
| 1 | allocation claim | heap allocation calls per query | 17,867,132 (1.535 / row) | 1,869,735 (0.161 / row) | −89.5 % |
| 2 | allocation claim | allocations ≤ 64 bytes (per-cell strings) | 16,948,768 | 786,294 | −95.4 % |
| 3 | allocation claim | bytes allocated per query | 27.17 GB | 23.18 GB | −3.98 GB (−14.7 %) |
| 4 | CPU work | instructions per query (`perf stat`) | 85.5 G | 77.7 G | −9.2 % |
| 5 | CPU work | cycles per query (busy box) | 142.5 G | 138.9 G | −2.6 % |
| 6 | CPU work | cache misses per query | 1.60 G | 1.57 G | −2.2 % |

The single-thread numbers match the 8-thread profile run: the per-cell strings are gone in both.
The loop wall seconds (`loop.tsv`: 16.44 s base vs 16.08 s variant, one trial each on a busy box) are not a verdict.

## Leaf attribution (source → share before/after)

Leaf shares of one warm query, base → variant, from `perf report` (`*/report-top.txt`); the folded call graphs carry no user frames (same cause as in `v2-fewer-copies-profile-j8-dwarf`).

| source | base % | variant % |
|---|---|---|
| per-cell strings: `escapeCell` | 1.60 | 0 (below 0.1) |
| per-cell strings: `idsToStringAndType` | 1.18 | 0 |
| per-cell strings: `literalOrIriToStringAndType` | 0.43 | 0 |
| `std::string` construction, `operator new`/`delete` | 0.85 | 0.13 |
| row assembly in place: `appendSerializedRows` | 0.47 | 1.20 |
| row assembly in place: `setWordCell` (new) | 0 | 1.36 |
| escape scanner: `scanChunkAvx2` | 0 (below 0.1) | 0.25 |
| lookup-result buffers: `makePmrVocabBatchLookupResult` (untouched, sibling work) | 4.96 | 4.99 |
| runtime checks: `adCorrectnessCheckImpl` | 3.19 | 3.64 |
