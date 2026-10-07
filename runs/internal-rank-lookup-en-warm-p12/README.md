# Constant-time rank lookup for in-RAM vocabulary words (vs part 12): English labels, warm

## Question

`VocabularyInternalExternal` checks for every looked-up index whether the word is in RAM.
Today it does this with a binary search over the sorted indices of the 778 M in-RAM words (`VocabularyInMemoryBinSearch::positionOfIndex`).
In a part-12 profile of the English-label CONSTRUCT export, this binary search costs about 40 % of the CPU.
Does a bit vector with rank counters (one cache line per lookup) make this export faster?
Does a cheaper option help: sort the batch and gallop once over the sorted indices?

## Setup

1. Machine: `ural`, AMD Ryzen 7 3700X, 125 GiB RAM, Linux 7.0.0-28, CPU governor `powersave` (no root) (`env-before.txt`).
2. Index: Wikidata truthy, vocabulary type `on-disk-compressed`.
   In-RAM vocabulary: 777,658,536 words, `endIndex()` = 1,580,300,680.
3. Arms (`meta.env`, `build-env.txt`, gates `gate-verify-*.log`: PASS, io_uring compiled in):
   - base `stack12-22-d20a4c74`: tag `stack12/22` = `d20a4c74ab76e844364eea53a8ac144ea54729c0` (export stack part 12, whole-stack head);
   - variant `rank-lookup-12c10ee7`: `12c10ee76289a92f09d310d4658984c19e4f3f3c` (fork PR marvin7122/qlever#264), `vocabulary-internal-rank-lookup=true`.
     The rank directory costs 225,757,248 bytes (3.6 % of the 6.22 GB indices array), logged by the server at index load;
   - variant2 `sorted-batch-12c10ee7`: the same binary, `vocabulary-internal-rank-lookup=false`, `vocabulary-internal-sorted-batch-lookup=true`.
4. Query: [`queries/H-vocab-label-large.rq`](queries/H-vocab-label-large.rq), English labels of all humans (11.6 M lines, 1.30 GB of Turtle); English words are in the in-RAM vocabulary.
5. Procedure (driver `pr-ab-multi-v2-3bin-nowait.sh`, harness copy `pr-ab-tools-rank` with per-trial `perf stat`): 3 interleaved trials per arm, warm only, order alternating.
   Warm: page cache warm, result cache cleared before each execution, each measurement loops the query until ≥ 10 s (one execution here, each takes about 20 s).
   Cycles: `perf stat -e cycles,instructions,task-clock -p <server>` (all threads) over the measured window, divided by the loop count.
6. Run: 2026-10-07 11:08–11:21 UTC, Ural queue entry #5331.
   Load: the box was shared, and this quick run did not wait for a quiet box (`load-gate.txt`: no wait, no repeats).
   Max load1 during each trial (`rep-load.tsv`): base 5.54 / 6.05 / 3.71, rank-lookup 5.08 / 5.56 / 5.10, sorted-batch 6.64 / 4.57 / 5.85.

## Result (`conclusion.md`, `aggregate-cycles.md`)

| # | concern | arm | wall s median [min–max] | delta | verdict | Gcycles/query median [min–max] | delta cycles |
|---|---|---|---|---|---|---|---|
| 1 | baseline | base | 24.83 [23.05–24.88] | | | 139.5 [132.7–140.6] | |
| 2 | main claim: rank lookup, all words in RAM | rank-lookup | 19.62 [19.49–19.74] | −21.0 % | faster (ranges disjoint) | 124.6 [123.4–124.7] | −10.7 % |
| 3 | cheap alternative: sorted batch, galloping | sorted-batch | 27.55 [25.57–29.17] | +11.0 % | slower (ranges disjoint) | 151.9 [142.8–157.6] | +8.9 % |

All 9 bodies are byte-identical (`correctness.tsv`: same xxh3 and triple multiset); postflight gate PASS (`gate-postflight-warm.log`).
3 trials per arm under co-tenant load: this is a screen, not the 10-trial verdict.

## Files

`results.csv` (all trials), `warm/<query>/<arm>/raw/` (harness output per trial, incl. `perf-stat.csv`), `vs-variant/`, `vs-variant2/` (two-arm views), `correctness.tsv`, `rep-load.tsv`, `loadavg.tsv`, `load-gate.txt`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`, `internal-rank-lookup-aggregate.py` (produces `aggregate-cycles.md`).
Binaries are not included.
