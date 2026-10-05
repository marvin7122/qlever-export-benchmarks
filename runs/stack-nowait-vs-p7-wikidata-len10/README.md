# Page-cache fast path on top of the io_uring ring: German-label exports, 10 trials

## Question

Stack part 7 (#3526) reads on-disk vocabulary words through an io_uring ring ("ring only").
PR #3547 (fork #236) adds a page-cache fast path: a non-blocking `preadv2(RWF_NOWAIT)` first tries to read each word straight from the OS page cache, and only misses go to the ring.
This run asks whether the fast path makes the German-label exports faster, cold and warm, and whether it should be on by default.

## Setup

1. Machine: `ural`, AMD Ryzen 7 3700X (8 cores, 16 threads), 125 GiB RAM (about 135 GB), index on a software RAID (`/dev/md1`) of two Samsung 990 PRO NVMe SSDs, Linux 7.0.0-28 (`env-before.txt`).
   The driver pins the benchmark to CPUs 0-7.
2. Index: Wikidata truthy, 8.2 billion triples (`/local/data-ssd/stoetzem/wikidata/wikidata`).
3. Queries (Turtle CONSTRUCT export, German labels; German labels live in the on-disk part of the vocabulary):
   - [`H-vocab-label-large-de.rq`](queries/H-vocab-label-large-de.rq): every human with a German label, a sequential scan ("sequential");
   - [`H-vocab-random-label-de-200k.rq`](queries/H-vocab-random-label-de-200k.rq): German labels of 200,000 entities given in a `VALUES` list ("scattered").
4. Arms:
   - `base` ("ring only"): the #3526 binary `0ed8f9223497`;
   - `variant` ("+ fast path"): the #3547 binary `51269ab4bf89` with `vocabulary-iouring-page-cache-fast-path=true` (the default);
   - `variant2`: the same #3547 binary with the fast path switched off.
5. Scenarios:
   - cold: the OS page cache is dropped before each repetition, then the query runs once;
   - warm: the files are already in the OS page cache; queries shorter than 10 s are looped back-to-back until at least 10 s and the per-query time is reported.
6. Repetitions: 10 interleaved trials per arm, query and scenario, order alternating; tables report medians.

## Result

| query | scenario | ring only (base), median | + fast path (variant), median | change |
|---|---|---:|---:|---:|
| sequential | warm | 19.80 s | 16.17 s | −18.3 % |
| sequential | cold | 28.67 s | 24.75 s | −13.6 % |
| scattered | warm | 4.68 s | 4.69 s | +0.2 %, within noise |
| scattered | cold | 11.16 s (9 reps) | 11.17 s | +0.1 %, within noise |

Exact medians from `aggregate.txt`: 19.7959 → 16.1653 s warm, 28.6650 → 24.7540 s cold (sequential).
The fast path cuts the sequential export by 18 % warm and 14 % cold, and leaves the scattered export unchanged.
With the flag off (`variant2`), the #3547 binary matches the ring-only binary within noise, except scattered warm (+4.4 %).
Every complete repetition returns identical bytes; one scattered cold base rep failed for an external reason (see below).

## Used in the colloquium talk

The talk takes "ring only" vs "+ fast path" (base vs variant), 10 interleaved trials, medians:

1. sequential warm: 19.80 → 16.17 s;
2. sequential cold: 28.67 → 24.75 s;
3. scattered: parity (4.68 vs 4.69 s warm, 11.16 vs 11.17 s cold).

## Original run note

### #3547 vs #3526 on Wikidata (Ural 5192, first attempt, 2026-09-28 19:16–21:09 UTC)

- Arms (interleaved, 10 reps, order alternating): base = #3526 binary `0ed8f922` (ring only); variant = this PR's binary `51269ab4`, `vocabulary-iouring-page-cache-fast-path=true` (default); variant2 = the same binary with the flag `false`. Driver: `run.sh`. Cold = one execution after dropping the page cache; warm = the query looped back-to-back until >= 10 s, per-query time.
- `vs-variant/` = base vs variant, `vs-variant2/` = base vs variant2; the same-binary comparison variant2 vs variant uses the same per-rep data (`results.csv`).
- Discounted rep: `pr236-H-vocab-random-label-de-200k-cold-base-r8` (status failed, 0 bytes). Its server was killed at 20:39:34 UTC by another job's `fuser -k 7015/tcp` port cleanup (smoke test of a different harness outside the exclusive slot). This is the only cause of the `MISMATCH` marker and of the `mismatch/` body; every complete rep has identical output bytes. All other reps are undisturbed.
- The queue retried the entry because of that rep (rc=1). The retry's run dir is NOT this one; its cold German reps between 21:15:30 and 21:18:15 UTC were disturbed by an rsync reading the index files on Ural.
- Background disk read during the cold H-vocab-random-label-de-200k cell (20:28:34 to ~21:37 UTC): another job read DBLP index files with O_DIRECT at ~4 MB/s (nice 19, ionice idle), with a 1.1 GB copy at ~25 MB/s from 20:28:34 to 20:29 UTC (overlapping base-r3 at most at its end, and variant-r3). Both reps lie inside their arm's spread (11.18 s vs 10.80–11.59 s; 11.22 s vs 11.01–11.31 s). The low-rate part covered all three interleaved arms of the cell alike. No page-cache pollution.

## Files

- `README.md`: this file.
- `COMPLETE`: driver completion marker with timestamp.
- `MISMATCH`: names the one failed rep (`pr236-H-vocab-random-label-de-200k-cold-base-r8`); `mismatch/` holds its empty body and the reference body.
- `meta.env`: the A/B definition: commits, binaries, runtime flags per arm, queries, scenarios, repetitions, threads, minimum measure time.
- `run.sh`: the driver script.
- `driver.log`: the driver's console log, one line per finished repetition with syscall and I/O counters.
- `results.csv`: one row per repetition: query, scenario, arm, rep, status, elapsed and first-byte time, response bytes, CPU seconds, bytes read from disk, read syscalls, major faults, checksums, correctness.
- `aggregate.txt`: per scenario, query and arm the medians of elapsed time, bytes read and read syscalls, and the number of distinct checksums.
- `conclusion.md`: the two comparisons (base vs variant, base vs variant2) with median/min/max, delta, verdict, gates, problems.
- `correctness.tsv`: byte count, line count and checksums of every response.
- `env-before.txt`, `env-after.txt`: host snapshot before and after the run (kernel, CPU governor, load, memory, page cache size, disk).
- `gate-preflight-*.log`, `gate-verify-*.log`: binary and host checks before the run (PASS).
- `gate-postflight-cold.log`, `gate-postflight-warm.log`: completeness and cold-cache checks after the run; cold FAILs only on the one failed rep.
- `queries/`: the two SPARQL queries.
- `cold/<query>/<arm>/`, `warm/<query>/<arm>/`: harness output per repetition (`raw/r<N>-<scenario>/`) and per-rep metadata.
- `vs-variant/`, `vs-variant2/`: the two pairwise comparisons with their own `conclusion.md`, `results.csv`, `correctness.tsv`, gates.
