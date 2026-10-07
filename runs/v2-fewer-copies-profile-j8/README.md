# Export V2: fewer copies (fork PR #268), allocation counts and perf stat, 8 query threads, Ural

## Question

Does fork PR marvin7122/qlever#268 remove the per-cell heap allocations of the V2 SELECT CSV/TSV serializer, and how many instructions does that save?
Timing is not the point of this run (see the Wolga A/B runs); allocation claims need direct counts.

## Setup

1. Machine: `ural`, AMD Ryzen 7 3700X, governor `powersave`.
   The box was busy (load1 11.9 at the start, `meta.txt`), so the wall and CPU seconds below are not a verdict.
2. Index: Wikidata truthy; query `query.rq` (English labels of all humans, SELECT CSV, 674,222,797 bytes, 11,643,064 rows).
3. Arms (`driver.log`, `*/version.txt`), V2 (`fast-export=1`), `--num-simultaneous-queries 8`, warm:
   1. `base`: `87f57674` (`work/pr120-postsub`);
   2. `variant`: `719615ab` (`perf/export-v2-fewer-copies`).
4. Driver `driver.sh` (thesis `scripts/v2-fewer-copies/v2-fewer-copies-profile.sh`), per arm:
   1. warm-up query, then `perf stat` over back-to-back queries for ≥ 10 s (here 2 queries);
   2. one query under `perf record`;
   3. a fresh server under the LD_PRELOAD shim `alloc_count.cpp`, warm-up query, counters zeroed (SIGUSR1), one query, counters dumped (SIGUSR2).
      The shim counts `malloc`/`calloc`/`realloc`/aligned allocations and every C++ `operator new` (QLever's jemalloc exports its own `operator new`, which a malloc-only shim misses).
5. Correctness: every body has the same byte count and sorted-line md5 as the first base body (`correctness.tsv`: all OK).

## Results

| # | concern | metric | base | variant | Δ |
|---|---|---|---|---|---|
| 1 | allocation claim | heap allocation calls per query | 17,870,541 (1.535 / row) | 1,872,883 (0.161 / row) | −89.5 % |
| 2 | allocation claim | allocations ≤ 64 bytes | 16,950,230 | 787,670 | −95.4 % |
| 3 | allocation claim | bytes allocated per query | 27.17 GB | 23.18 GB | −3.98 GB (−14.7 %) |
| 4 | CPU work | instructions per query (`perf stat`) | 86.0 G | 78.0 G | −9.3 % |
| 5 | CPU work | cycles per query (busy box) | 143.4 G | 140.0 G | −2.4 % |
| 6 | CPU work | cache misses per query | 1.46 G | 1.43 G | −2.7 % |

The bytes allocated are dominated by query evaluation (join and scan blocks of all labels of all humans), which this PR does not touch; the 3.98 GB difference is the serializer's per-cell strings and window strings.

## Not usable

The `perf record` call graphs (`*/stacks.folded`) are empty: the default event on this AMD host is `cycles:P` (IBS), whose samples carry no user stack, so DWARF unwinding produced no user frames.
The driver now passes `-e cycles`; the attribution profile is `v2-fewer-copies-profile-j8-dwarf`.
