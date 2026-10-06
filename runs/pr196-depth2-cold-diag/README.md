# pr196-depth2-cold-diag: where the CONSTRUCT export thread spends a cold run

Fork PR marvin7122/qlever#196, research loop step 1 (why does the depth-2 pipeline not help?).
Driver: `depth2-cold-diag.py` (thesis repo `scripts/`), Wikidata truthy, server on CPUs 0-2.

Per arm and query: one cold execution (serving files evicted, fresh server) and one warm execution, with
a 1 kHz `/proc` sampler (thread state, current syscall, wchan) and `schedstat` per thread; rep 2 also ran
`perf record -F 999 -g` (`perf-flat.txt`, `perf-callers.txt`).

Arms: `p12` = stack part 12 `f8cca285e`; `p13-depth2` = part 13 `f9fc54f69`; `p13-pipe3` = part 13 with a
three-stage read pipeline on one thread `785c408e6`; `p8-presented` = part 8 `51269ab4`; `thread-d2` = fork
#196 `37530faf` with `construct-export-pipeline-depth=2` (evaluation on a second thread, formatting on the first).

Finding: the export thread of `H-vocab-label-large-de` is runnable in 97-98 % of the samples in every arm,
cold and warm; it waits in `io_uring_enter` in at most 0.6 % of the samples.
The time is CPU in the vocabulary lookup (perf: `positionOfIndex` 11-17 %, the `preadv2` page-cache path
about 35 %, FSST decoding 3 %); formatting is about 1 %.
In `thread-d2` the formatting thread is busy about 5 % of the time.
Note: in this run the per-request export thread ended before the after-snapshot, so `summary.md` lists its
sampler histogram in `probe.json` only (fixed in later runs).
The wall times of this run are diagnostic (one execution each, sampler on), not a timing result.
