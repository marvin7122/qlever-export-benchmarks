# Export V2: fewer copies (fork PR #268), DWARF attribution profile, 8 query threads, Ural

## Question

Which code owns the allocation and copy samples of a warm V2 SELECT CSV export, before and after fork PR marvin7122/qlever#268?
Timing is not the point of this run (see the Wolga A/B runs); allocation claims need direct counts.

## Setup

1. Machine: `ural`, AMD Ryzen 7 3700X, governor `powersave`.
   The box was busy (load1 18.0 at the start, `meta.txt`), so the wall and CPU seconds below are not a verdict.
2. Index: Wikidata truthy; query `query.rq` (English labels of all humans, SELECT CSV, 674,222,797 bytes, 11,643,064 rows).
3. Arms (`driver.log`, `*/version.txt`), V2 (`fast-export=1`), `--num-simultaneous-queries 8`, warm:
   1. `base`: `87f57674` (`work/pr120-postsub`);
   2. `variant`: `719615ab` (`perf/export-v2-fewer-copies`).
4. Driver `driver.sh` (thesis `scripts/v2-fewer-copies/v2-fewer-copies-profile.sh`), per arm:
   1. warm-up query, then `perf stat` over back-to-back queries for ≥ 10 s (here 2 queries);
   2. one query under `perf record -e cycles -F 499 --call-graph dwarf,16384` (explicit `-e cycles`: the default event on this AMD host is `cycles:P` (IBS), whose samples carry no user stack);
   3. a fresh server under the LD_PRELOAD shim `alloc_count.cpp`, warm-up query, counters zeroed (SIGUSR1), one query, counters dumped (SIGUSR2).
      The shim counts `malloc`/`calloc`/`realloc`/aligned allocations and every C++ `operator new` (QLever's jemalloc exports its own `operator new`, which a malloc-only shim misses).
5. Correctness: every body has the same byte count and sorted-line md5 as the first base body (`correctness.tsv`: all OK).

## Results

| # | concern | metric | base | variant | Δ |
|---|---|---|---|---|---|
| 1 | allocation claim | heap allocation calls per query | 17,870,373 (1.535 / row) | 1,872,933 (0.161 / row) | −89.5 % |
| 2 | allocation claim | allocations ≤ 64 bytes (per-cell strings) | 16,950,163 | 787,774 | −95.4 % |
| 3 | allocation claim | bytes allocated per query | 27.17 GB | 23.18 GB | −3.98 GB (−14.7 %) |
| 4 | CPU work | instructions per query (`perf stat`) | 171.8 G | 155.8 G | −9.3 % |
| 5 | CPU work | cycles per query (busy box) | 282.8 G | 276.6 G | −2.2 % |
| 6 | CPU work | cache misses per query | 2.97 G | 2.91 G | −2.1 % |

The bytes allocated are dominated by query evaluation (join and scan blocks of all labels of all humans), which this PR does not touch; the 3.98 GB difference is the serializer's per-cell strings and window strings.

## Leaf attribution (source → share before/after)

The folded call graphs (`*/stacks.folded`) carry no user frames (see below), so this table is leaf-level, from `perf report` (`*/report-top.txt`).
Leaf shares of one warm query, base → variant:

| source | base % | variant % |
|---|---|---|
| per-cell strings: `escapeCell` | 1.79 | 0 (below 0.1) |
| per-cell strings: `idsToStringAndType` | 1.25 | 0 |
| per-cell strings: `literalOrIriToStringAndType` | 0.48 | 0 |
| `std::string` construction/move, `operator new`/`delete` | 1.50 | 0.13 |
| row assembly in place: `appendSerializedRows` | 0.48 | 1.49 |
| row assembly in place: `setWordCell` (new) | 0 | 1.43 |
| escape scanner: `scanChunkAvx2` | 0.24 | 0.42 |
| lookup-result buffers: `makePmrVocabBatchLookupResult` (untouched, sibling work) | 5.20 | 5.20 |
| runtime checks: `adCorrectnessCheckImpl` | 3.67 | 4.62 |
| kernel copy/clear: `rep_movs`, `kernel_init_pages` | 0.53 | 0.62 |

Suspected source 1 (one heap string per cell) is gone from the profile.
Suspected source 2 (window string plus `appendCopy`) is gone by code reading: the window string no longer exists and `finalizeToString` already moved the buffer.
Suspected source 3 (pmr lookup-result buffers) is unchanged here and belongs to sibling work.

## Not usable

The `perf record --call-graph dwarf` call graphs (`*/stacks.folded`, `flame.svg`) contain no user frames: 97 % of recorded cycles sit in the bare process name, the rest are kernel-entry stacks.
The record captured full 16 KB stack dumps (`perf.data` was 247–281 MB), the binary carries `.eh_frame` and `.symtab`, and DWARF unwinding of a locally compiled toy works on this host, so the failure is specific to unwinding this attached 8-thread server process.
`perf report` leaf resolution (above) is unaffected.
`perf.data` files were deleted by the driver after folding; only the folded stacks, the leaf tables, and the flame graphs are kept.
