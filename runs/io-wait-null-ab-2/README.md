# How much does per-read wait accounting cost? (one binary, accounting off vs on)

## Question

The thesis adds optional counters that time every blocking vocabulary read.
This run asks whether switching those counters on slows the export down.
As a side effect it records how many blocking `pread64` calls the German-label export makes without io_uring.

## Setup

1. Machine: `ural`, AMD Ryzen 7 3700X (8 cores, 16 threads), 125 GiB RAM (about 135 GB), index on a software RAID (`/dev/md1`) of two Samsung 990 PRO NVMe SSDs.
   The gate log records the CPU governor (`powersave`) and the load (0.30); `clocksource.txt` records the clock source (`tsc`).
2. Index: Wikidata truthy, 8.2 billion triples (`/local/data-ssd/stoetzem/wikidata/wikidata`).
3. Queries (Turtle CONSTRUCT export):
   - `I-iouring-label-de`: every human (`wdt:P31 wd:Q5`) with its German label.
     Its SPARQL is identical to [`H-vocab-label-large-de.rq`](../../queries/wikidata/H-vocab-label-large-de.rq) (only the comment header differs).
     German labels live in the on-disk part of the vocabulary, so every label is read from disk when the cache is cold.
   - `D3`: a 100,000-row star dump of films (`wdt:P31 wd:Q11424`), the small control.
4. Arms: one binary, `marvin-io-wait-accounting` at commit `ac6a5a20`, with the runtime switch `measure-io-wait`.
   - baseline: `measure-io-wait=false` (accounting off);
   - variant: `measure-io-wait=true` (accounting on).
   The two arms run byte-identical code paths except for the timing calls, so the time difference is the cost of the accounting.
5. Cold only: the OS page cache is dropped before each repetition.
6. Repetitions: 5 per arm and query, arms interleaved with alternating order (driver `scripts/io-wait-null-ab-bench.sh` in the thesis repository).
   The tables report medians.

## Result

| query | counter | baseline (off) | variant (on) |
|---|---|---:|---:|
| I-iouring-label-de | elapsed, median | 62.292 s | 62.619 s |
| I-iouring-label-de | process CPU, median | 28.70 s | 29.06 s |
| I-iouring-label-de | blocking `pread64` calls | 8,886,179 | 8,886,179 |
| I-iouring-label-de | bytes read from disk | 9,615,556,608 | 9,615,556,608 |
| I-iouring-label-de | response bytes | 504,927,346 | 504,927,346 |
| D3 | elapsed, median | 1.875 s | 1.868 s |
| D3 | blocking `pread64` calls | 39,422 | 39,422 |

Switching the accounting on adds 0.33 s (0.52 %) over 8.9 million reads on the German export, about 37 ns per read.
On `D3` the difference is within noise.
Both arms make exactly the same reads, and `io_uring_enter` stays at 0: this binary reads the vocabulary with blocking `pread64` only.

## Used in the colloquium talk

The talk takes the size of the German sequential export (`I-iouring-label-de` = `H-vocab-label-large-de`) from this run:

1. 8,886,179 blocking `pread64` calls per export ("8.9 million reads");
2. 504,927,346 response bytes ("0.5 GB").

## Files

- `arms.txt`: run id, binary path and commit, the two arms, clock source.
- `clocksource.txt`: the kernel clock source during the run (`tsc`, so `clock_gettime` is a cheap vDSO call).
- `conclusion.md`: the result: per query a summary row (baseline → variant medians of elapsed time, CPU, syscalls, `pread64`, `io_uring_enter`, bytes read, page faults) and the full counter table per arm.
- `diagnosis.md`: same content as `conclusion.md` (the driver copies the diagnosis to the conclusion).
- `gate.log`: preflight check (binary matches the commit, io_uring compiled in, idle host, cache-drop tool present) and postflight check (all reps complete, cold reps really read from disk, checksums stable): both PASS.
- `io-wait-totals.txt`: the binary paths found in the server logs; the per-request wait totals the instrumentation prints were not captured in this run.
