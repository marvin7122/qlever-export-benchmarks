# How much of a cold German-label export is waiting for the disk? (baseline profile)

## Question

When the page cache is cold, the German-label exports read their labels from disk with blocking reads.
This run measures, for the baseline binary without io_uring, how long each export takes and how much CPU the server uses meanwhile.
The gap between wall time and CPU time is time spent waiting, which bounds what faster I/O can save.

## Setup

1. Machine: `ural`, AMD Ryzen 7 3700X (8 cores, 16 threads), 125 GiB RAM (about 135 GB), index on a software RAID (`/dev/md1`) of two Samsung 990 PRO NVMe SSDs, Linux 7.0.0-28 (`env.txt`).
2. Index: Wikidata truthy, 8.2 billion triples, the old-format index backup built 2026-08-13 (`index-in-old-format.2026-08-13T19:10:06Z`, see `env.txt`).
3. Queries (Turtle CONSTRUCT export, German labels); the `.rq` files are not in this directory, the same queries are in other run directories:
   - sequential (`large-de`): every human with a German label, [`H-vocab-label-large-de.rq`](../../queries/wikidata/H-vocab-label-large-de.rq), 504,927,346 response bytes;
   - scattered (`scatter200k-de`): German labels of 200,000 entities given in a `VALUES` list, [`H-vocab-random-label-de-200k.rq`](../nowait8-readahead-fadv-random/queries/H-vocab-random-label-de-200k.rq), 19,297,737 response bytes.
4. One arm, no A/B: the baseline binary `bench/iouring-pre-baseline` at `fdbfd14f5` (`v0.5.48-36-gfdbfd14f5`), built without liburing.
5. Scenarios:
   - cold: the OS page cache is dropped before each repetition;
   - warm: the index files are already in the OS page cache (0 bytes read from disk).
6. Repetitions: per query 1 warm and 2 cold.
   A sampler records machine CPU, server CPU time and server read rate at 2 Hz during each repetition.

## Result

| query | scenario | wall time | server CPU time | bytes read from disk | I/O wait (machine) |
|---|---|---:|---:|---:|---:|
| sequential | warm | 15.5 s | 16.4 s | 0 | 0.0 % |
| sequential | cold (rep 1 / rep 2) | 60.5 s / 60.5 s | 24.6 s / 24.6 s | 9,615,302,656 | 3.6 % |
| scattered | warm | 4.5 s | 4.0 s | 0 | 0.0 % |
| scattered | cold (rep 1 / rep 2) | 27.0 s / 27.0 s | 7.6 s / 7.5 s | 3,103,010,816 | 4.2 % |

Wall time and server CPU time are the sampler's values in `results-summary.txt`.
The request timer gives slightly longer cold wall times: 60.60 / 60.58 s sequential and 27.15 / 27.16 s scattered.
Cold, the server is busy on only 0.41 cores on average (sequential) and 0.28 cores (scattered); the rest of the wall time it waits for the disk.
Cold is a factor 3.9 slower than warm on the sequential export and a factor 5.6 slower on the scattered one.

## Used in the colloquium talk

1. Baseline cold sequential export: 60.5 s wall time with 24.6 s of server CPU time.
2. The "upper bound if all waiting disappeared", wall time divided by CPU time:
   - sequential: 60.6 s / 24.6 s = 2.46x;
   - scattered: 27.2 s / 7.6 s = 3.58x.
   The ratios are computed from this run's numbers (request wall time, sampler CPU time of cold rep 1); they are not written in the files.

## Files

- `COMPLETE`: driver completion marker with timestamp.
- `conclusion.md`: the result: method, the table of wall time, body size, disk reads, server CPU share, I/O wait and peak read rate, interpretation.
- `results-summary.txt`: per window the request lines and the sampler summary (`wall_s`, machine `usr`/`sys`/`iowait`/`idle` percent, `proc_cpu_s`, `proc_cpu_pct`, peak read rate, busy cores).
- `env.txt`: binary and version, index path and its git hash, kernel, CPU, date.
- `<query>-<scenario>/` (`large-de-cold1`, `large-de-cold2`, `large-de-warm`, `scatter200k-de-cold1`, `scatter200k-de-cold2`, `scatter200k-de-warm`):
  - `request.tsv`: HTTP status, wall seconds, response bytes, bytes read from disk.
    It also holds the rows of a failed earlier attempt (seq 3944; its scattered rows have HTTP 400, see `conclusion.md`).
  - `cpu.tsv`: the sampler summary of this window.
  - `cpu-samples.tsv`: the raw 2 Hz samples.
