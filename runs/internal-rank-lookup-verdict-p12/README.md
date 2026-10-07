# Constant-time rank lookup for in-RAM vocabulary words (vs part 12): verdict run, 3 queries, cold and warm

## Question

`VocabularyInternalExternal` checks for every looked-up index whether the word is in RAM.
Today it does this with a binary search over the sorted indices of the 778 M in-RAM words (`VocabularyInMemoryBinSearch::positionOfIndex`).
A part-12 profile puts this binary search at 16 % (cold) and 23 % (warm) of the CPU for the German-label export, and 40 % for the English one.
Fork PR marvin7122/qlever#264 replaces it with a bit vector plus rank counters (one 64-byte cache line per lookup).
Is the export faster, and does any cell regress?

## Setup

1. Machine: `ural`, AMD Ryzen 7 3700X, 125 GiB RAM, Linux 7.0.0-28, CPU governor `powersave` (no root) (`env-before.txt`).
2. Index: Wikidata truthy, vocabulary type `on-disk-compressed`.
   In-RAM vocabulary: 777,658,536 words, `endIndex()` = 1,580,300,680.
3. Arms (`meta.env`, `build-env.txt`, gates `gate-verify-*.log`: PASS, io_uring compiled in):
   - base `stack12-22-d20a4c74`: tag `stack12/22` = `d20a4c74ab76e844364eea53a8ac144ea54729c0` (export stack part 12, whole-stack head);
   - variant `rank-lookup-12c10ee7`: `12c10ee76289a92f09d310d4658984c19e4f3f3c`, `vocabulary-internal-rank-lookup=true`.
     The rank directory costs 225,757,248 bytes (3.6 % of the 6.22 GB indices array), logged by the server at index load.
4. Queries (`queries/`), all CONSTRUCT to Turtle:
   - `H-vocab-label-large-de.rq`: German labels of all humans, sequential (505 MB); German words are on disk;
   - `A-scatter-disambig-label-de.rq`: German labels, scattered vocabulary access (74 MB);
   - `H-vocab-label-large.rq`: English labels of all humans (1.30 GB); English words are in RAM.
5. Procedure (driver `pr-ab-multi-v2-3bin-fastgate.sh` with 2 arms, harness copy `pr-ab-tools-rank` with per-trial `perf stat`): 3 interleaved trials per arm, query and scenario, order alternating.
   Cold: fresh server after `drop_caches`, one execution.
   Warm: page cache warm, result cache cleared before each execution, each measurement loops the query until ≥ 10 s (per-query mean).
   Cycles: `perf stat -e cycles,instructions,task-clock -p <server>` (all threads) over the measured window, divided by the loop count.
6. Run: 2026-10-07 12:06–13:25 UTC, Ural queue entry #5340.
   Load: the box was heavily shared. The gate waited at most 60 s and repeated nothing (`load-gate.txt`), and max load1 during the trials was 5.7–22.8 (`rep-load.tsv`).
   The run was stopped by a signal before its last trial (English, warm, variant, trial 3; `ABORTED`), so that cell has 2 variant trials.
   The driver therefore wrote no `conclusion.md` or postflight gate. The table below comes from `aggregate-cycles.md` (`internal-rank-lookup-aggregate.py`), and correctness from `correctness.tsv`.

## Result

"faster/slower" requires disjoint min–max ranges and |delta| ≥ 2 %.

| # | concern | query | scenario | base wall s median [min–max] | rank-lookup wall s median [min–max] | delta | verdict | Δ cycles/query |
|---|---|---|---|---|---|---|---|---|
| 1 | main claim: all words in RAM | H-vocab-label-large (en) | warm | 38.11 [36.10–39.19] | 24.51 [24.20–24.83] (n=2) | −35.7 % | faster | −27.6 % |
| 2 | main claim, cold page cache | H-vocab-label-large (en) | cold | 38.56 [27.74–39.10] | 24.41 [23.93–25.19] | −36.7 % | faster | −28.8 % |
| 3 | sequential German, page cache warm | H-vocab-label-large-de | warm | 23.93 [23.77–24.23] | 18.97 [18.66–19.25] | −20.7 % | faster | −17.4 % |
| 4 | regression guard: German words on disk, cold | H-vocab-label-large-de | cold | 26.56 [24.28–34.71] | 29.10 [27.53–29.87] | +9.5 % | no difference (ranges overlap) | +8.9 % |
| 5 | scattered German access, warm | A-scatter-disambig-label-de | warm | 3.455 [3.101–3.899] | 3.055 [2.131–3.111] | −11.6 % | no difference (ranges overlap) | −8.9 % |
| 6 | scattered German access, cold | A-scatter-disambig-label-de | cold | 13.07 [12.10–13.80] | 13.04 [11.16–13.04] | −0.3 % | no difference | −1.0 % |

Correctness: in every cell, all trials of both arms return the same triple multiset and byte count (`correctness.tsv`).

Row 4: the variant's cold trials ran under higher load (max load1 19.6 / 19.5 / 13.5) than base trials 2 and 3 (8.9 / 7.2), while base trial 1 (load 17.9) took 34.7 s.
The earlier English warm screen ([`internal-rank-lookup-en-warm-p12`](../internal-rank-lookup-en-warm-p12/)) measured −21.0 % at lower load.

## Files

`results.csv` is missing because the driver was stopped before aggregation.
Per-trial data is in `<scenario>/<query>/<arm>/raw/results.csv` and in the harness output per trial, including `perf-stat.csv`.
Other files: `correctness.tsv`, `rep-load.tsv`, `loadavg.tsv`, `load-gate.txt`, `build-env.txt`, `env-before.txt`, `gate-*.log`, `driver.log`, `ABORTED`, `aggregate-cycles.md`, `internal-rank-lookup-aggregate.py`.
Binaries are not included.
