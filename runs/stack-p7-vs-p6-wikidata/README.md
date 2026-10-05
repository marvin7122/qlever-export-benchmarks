# Blocking reads vs the io_uring ring for German-label exports (stack part 7 vs part 6)

## Question

Stack part 6 (#3525) still reads on-disk vocabulary words with blocking `pread` calls.
Stack part 7 (#3526) sends those reads through an io_uring ring.
This run measures part 7 against its parent, part 6, on the German-label exports, cold and warm.

## Setup

1. Machine: `ural`, AMD Ryzen 7 3700X (8 cores, 16 threads), 125 GiB RAM (about 135 GB), index on a software RAID (`/dev/md1`) of two Samsung 990 PRO NVMe SSDs, Linux 7.0.0-28 (`env-before.txt`).
2. Index: Wikidata truthy, 8.2 billion triples (`/local/data-ssd/stoetzem/wikidata/wikidata`).
3. Queries (Turtle CONSTRUCT export, German labels; German labels live in the on-disk part of the vocabulary):
   - [`H-vocab-label-large-de.rq`](queries/H-vocab-label-large-de.rq): every human with a German label, a sequential scan ("sequential");
   - [`H-vocab-random-label-de-200k.rq`](queries/H-vocab-random-label-de-200k.rq): German labels of 200,000 entities given in a `VALUES` list ("scattered").
4. Arms (two binaries):
   - `base` ("before", pread): the #3525 binary `533f800b87ff`;
   - `variant` (io_uring ring): the #3526 binary `0ed8f9223497`.
5. Scenarios:
   - cold: the OS page cache is dropped before each repetition, then the query runs once;
   - warm: the files are already in the OS page cache; one warm-up run, then QLever's result cache is cleared and the query runs once more.
6. Repetitions: 3 interleaved trials per arm, query and scenario, order alternating; tables report medians.

## Result

| query | scenario | #3525 pread (base), median | #3526 ring (variant), median | change |
|---|---|---:|---:|---:|
| sequential | cold | 64.58 s | 27.57 s | −57.3 % |
| sequential | warm | 17.04 s | 19.35 s | +13.5 % |
| scattered | cold | 27.51 s | 11.04 s | −59.9 % |
| scattered | warm | 4.64 s | 4.63 s | within noise |

Exact medians from `aggregate.txt`: sequential cold 64.5783 → 27.5690 s, warm 17.0387 → 19.3454 s.
The ring makes both cold exports more than twice as fast.
Warm, the sequential export is 13.5 % slower with the ring; the scattered export is unchanged.
All reps are complete and return identical bytes in both arms; all gates PASS.

## Used in the colloquium talk

The talk's "before (pread)" bars come from the base arm (#3525 binary `533f800b`), 3 trials, medians:

1. sequential warm: 17.04 s;
2. sequential cold: 64.58 s.

## Files

- `COMPLETE`: driver completion marker with timestamp.
- `meta.env`: the A/B definition: commits, binaries, queries, scenarios, repetitions, threads.
- `driver.log`: the driver's console log, one line per finished repetition with syscall and I/O counters (`pread64`, `io_uring_enter`, bytes read, CPU seconds).
- `results.csv`: one row per repetition: query, scenario, arm, rep, status, elapsed and first-byte time, response bytes, CPU seconds, bytes read from disk, read syscalls, major faults, checksums, correctness.
- `aggregate.txt`: per scenario, query and arm the medians of elapsed time, bytes read and read syscalls, and the number of distinct checksums.
- `conclusion.md`: the comparison with median/min/max, delta, verdict, gates.
- `correctness.tsv`: byte count, line count and checksums of every response.
- `env-before.txt`, `env-after.txt`: host snapshot before and after the run (kernel, CPU governor, load, memory, page cache size, disk).
- `gate-preflight-*.log`, `gate-verify-*.log`: binary and host checks before the run; `gate-postflight-cold.log`, `gate-postflight-warm.log`: completeness and cold-cache checks after it. All PASS.
- `queries/`: the two SPARQL queries.
- `cold/<query>/<arm>/`, `warm/<query>/<arm>/`: harness output per repetition (`raw/r<N>-<scenario>/`: result, page-cache snapshots, syscall counts) and per-rep metadata.
