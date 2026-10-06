# Conclusion for run fiber-rework-offcpu-p15-vs-p14-v2 (Ural queue seq 5299)

## Scope

This run checks why the fibers of export stack part 15/16 (ad-freiburg/qlever#3477, fork marvin7122/qlever#165) show no gain on top of part 14/16 (#3476).
Fibers can only help when the export thread blocks in `io_uring` waits.
The run measures how long it blocks, and in which syscall.

- Base: part 14/16, #3476 `95f657ab` (no fibers; wave reap and the page-cache fast path are in).
- Variant: part 15/16, #3477 `dbaff3f8` (the binary of the stack re-measure `stack-p16-vs-p15-wikidata-v4`).
- Both binaries pass `verify-qlever-binary.sh --require-iouring`; only the variant contains `boost::fibers` and `FiberIoScheduler` symbols.
- Index: Wikidata truthy, `on-disk-compressed`, `languages-internal = ["en"]`.
- Queries: `H-vocab-label-large-de` (sequential) and `H-vocab-random-label-de-200k` (scattered), CONSTRUCT, Turtle.
- Cold only: the page cache is dropped (`clear-caches`) before every server start.
- 3 trials per arm and query, arms interleaved with alternating order.

## Method

`offcpu_screen.py` (in this directory) samples every server thread about every 1.2 ms from `/proc`.
For a sleeping thread it records the syscall the thread sleeps in (`/proc/<pid>/task/<tid>/syscall`).
Per-thread on-CPU and run-queue time come from `schedstat`, kept until a thread exits.
The export thread is the thread with the most on-CPU time (sequential query) or the thread that runs the CONSTRUCT evaluator (scattered query, see below).
Trial 3 also records a flat `perf record -F 999` profile (perf.data not published; the per-thread reports are).
Timing here is a screen: the sampler uses CPU on another core.

The first attempt (`fiber-rework-offcpu-p15-vs-p14`, seq 5290) is void.
It read `schedstat` only before and after the query and so missed the per-query export thread, which exits before the end snapshot.

## Result

Output is byte-identical across arms and trials for both queries.

| # | concern | query | base (#3476) median [min–max] | variant (#3477) median [min–max] |
|---|---|---|---|---|
| 1 | wall time (screen) | sequential | 25.30 [25.08–25.32] s | 24.99 [24.78–25.94] s |
| 2 | export thread on-CPU | sequential | 24.35 [24.11–24.38] s (96 % of wall) | 24.12 [23.92–25.04] s |
| 3 | export thread off-CPU, total (schedstat) | sequential | 0.92 [0.91–0.96] s | 0.86 [0.85–0.87] s |
| 4 | export thread asleep in `io_uring_enter` | sequential | 0.40 [0.39–0.42] s (share of off-CPU samples) / 0.27 [0.26–0.31] s (sample count × period) | 0.37 [0.35–0.37] s / 0.26 [0.24–0.27] s |
| 5 | wall time (screen) | scattered | 11.10 [10.69–11.27] s | 10.70 [10.55–11.61] s |
| 6 | any thread asleep in `io_uring_enter` | scattered | 0.001 [0.000–0.002] s | 0.001 [0.000–0.003] s |
| 7 | any thread blocked in `pread64` (D state) | scattered | 2.85 [2.83–2.94] s | 2.93 [2.77–2.94] s |

1. Sequential: the export thread is on-CPU 96 % of the wall time.
   It sleeps in `io_uring_enter` for 0.27–0.42 s per export, depending on the estimator: 1.1–1.7 % of the wall time.
   That is the upper bound of what any overlap of ring waits can save, below the 2 % threshold for "faster".
2. Scattered: the thread that runs the CONSTRUCT evaluator is on-CPU 95 % of its lifetime and almost never waits for the ring.
   The 2.9 s of blocking `pread64` are in the query-execution thread (it also sleeps in `epoll_wait`): reads of the index permutation for the 200k `VALUES` rows, before and outside the export path the fibers act on.
3. In the profile of the sequential export thread (trial 3, `perf-cpu-export-thread.txt`), no `io_uring` reap/wait or fiber symbol reaches the 0.3 % listing threshold in either arm.
   Its cycles go to the vocabulary and page-cache copy path (base): `VocabularyInMemoryBinSearch::positionOfIndex` 9.0 %, `filemap_get_read_batch` 6.3 %, `_copy_to_iter` 4.3 %, `filemap_read` 3.9 %.

## How many fibers run concurrently

From the code of `ConstructBatchEvaluator::evaluateBatch` and the index settings (not from a counter; the `FIBER_IO_STATS` counters of the fork branch are compiled out in these binaries):

1. The template `{ ?entity rdfs:label ?label }` has two variable columns, so a wave has at most 2 fibers.
2. `?entity` holds `wd:Q…` IRIs.
   `prefixes-external` lists only `entity/statement`, `value` and `reference`, so these IRIs are in the internal (in-memory) vocabulary and their lookup never enters the ring.
3. The bodies run in column order: the `?entity` fiber runs to completion without a single wait before the `?label` fiber starts.
4. So at most one fiber ever waits for the ring, and nothing else runs on the thread while it waits.
   The fibers cannot overlap anything on these queries; the remaining change is the non-blocking reap (0.03–0.04 s less in `io_uring_enter`, row 4).

## Verdict

The cold export on top of #3476 is CPU-bound in the export thread.
The ring waits that fibers could hide are at most 1.7 % of the wall time (sequential) and about 0 (scattered).
No fiber schedule (more columns per wave, reordering I/O columns first, overlapping consecutive batches) can reach a 2 % gain on these workloads.
Recommendation: drop the fibers from the export stack.
