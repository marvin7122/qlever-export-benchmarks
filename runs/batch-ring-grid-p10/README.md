# CONSTRUCT row batch size x io_uring ring size, cold German export (grid, stack part 10)

## Question

How much of the cold German Wikidata export is still waiting on vocabulary I/O on top of stack part 10?
Does a larger CONSTRUCT row batch, a larger io_uring ring, or both together make the cold export faster?

Hypothesis before the run (inferred, not measured): with the page-cache fast path only misses reach the ring.
The sequential export has ~92 % page-cache hits, so a 1024-row batch puts only ~80 misses into the ring and the batch size limits the reads in flight.
The scattered export has ~21 % hits (~800 misses per batch), so the 256-slot ring limits.

## Setup

1. Machine: `ural`, AMD Ryzen 7 3700X (8 cores, 16 threads), 125 GiB RAM, index on a software RAID 0 (`/dev/md1`) of two NVMe SSDs (`nvme0n1`, `nvme1n1`), Linux 7.0.0-28 (`env-before.txt`).
2. Index: Wikidata truthy, on-disk compressed vocabulary.
3. Binary: one binary, fork branch `perf/batch-ring-size-on-p10` at `52ca007a` (stack part 10, old `upstream-stack/07d` head `4dd60f85` = tag `stack12/07d` up to comment-only changes, plus two runtime parameters).
   Gate: `gate-verify-*.log` (version carries `52ca007a`, io_uring compiled in).
4. Arms (same binary, runtime parameters, server restarted per measurement): `b<construct-export-row-batch-size>-r<vocabulary-iouring-ring-size>`, batch {1024, 4096, 16384} x ring {256, 1024}.
   `b1024-r256` is the current default.
5. Queries (Turtle CONSTRUCT, `queries/`):
   - sequential: `H-vocab-label-large-de` (every human with a German label, 504,927,346 response bytes);
   - scattered: `H-vocab-random-label-de-200k` (German labels of 200,000 entities in a `VALUES` list, 19,297,737 response bytes).
6. Cold only: `drop_caches` before every measurement, one execution each.
   5 interleaved reps; the arm order rotates per rep.
7. Per measurement, `tools/grid-sampler.py` sampled `/sys/block/nvme{0,1}n1/stat` and the server's per-thread CPU every 0.2 s.
   `tools/grid-rep-metrics.py` reduces the samples to the query window (`grid-metrics.json` per rep):
   aqu-sz = summed d(time_in_queue)/dt over both NVMe devices (as `iostat -x`), util = d(io_ticks)/dt, export-thread CPU = CPU of the hottest server thread in the window.
8. Driver: `tools/pr-ab-grid.sh`, a copy of `pr-ab-multi-v2.sh` extended to N runtime-parameter arms.

## Result (median [min–max] of 5 cold reps)

Sequential (`H-vocab-label-large-de`):

| # | concern | arm | wall s | paired Δ vs default (median [min–max]) | export-thread CPU s | wall − export-thread s | aqu-sz | util |
|---|---|---|---|---|---|---|---|---|
| 1 | default | b1024-r256 | 30.66 [25.91–34.40] | – | 29.42 | 1.24 | 2.3 | 0.35 |
| 2 | ring only | b1024-r1024 | 33.52 [24.71–34.30] | −0.3 % [−12.8, +20.9] | 31.80 | 1.18 | 2.1 | 0.34 |
| 3 | batch 4x | b4096-r256 | 26.80 [22.81–30.78] | −10.0 % [−23.6, +3.4] | 25.84 | 1.19 | 2.6 | 0.37 |
| 4 | batch 4x + ring | b4096-r1024 | 30.46 [26.09–31.06] | −7.9 % [−9.7, +1.4] | 29.36 | 1.10 | 2.3 | 0.35 |
| 5 | batch 16x | b16384-r256 | 29.13 [22.05–29.80] | −13.1 % [−22.2, −4.5] | 27.70 | 1.36 | 2.4 | 0.33 |
| 6 | batch 16x + ring | b16384-r1024 | 28.13 [21.41–29.73] | −13.2 % [−24.4, −8.1] | 26.61 | 1.52 | 2.5 | 0.34 |

Scattered (`H-vocab-random-label-de-200k`):

| # | concern | arm | wall s | paired Δ vs default | first byte s | export-thread CPU s | aqu-sz | util |
|---|---|---|---|---|---|---|---|---|
| 1 | default | b1024-r256 | 14.38 [10.69–15.11] | – | 11.04 | 5.59 | 1.8 | 0.33 |
| 2 | ring only | b1024-r1024 | 14.07 [10.52–14.44] | −0.7 % [−26.1, +0.3] | 10.83 | 5.60 | 1.8 | 0.32 |
| 3 | batch 4x | b4096-r256 | 14.03 [10.21–14.28] | −2.6 % [−5.5, −2.0] | 10.84 | 5.64 | 1.7 | 0.30 |
| 4 | batch 4x + ring | b4096-r1024 | 14.01 [11.69–14.15] | −1.7 % [−7.2, +9.3] | 10.84 | 5.52 | 1.7 | 0.31 |
| 5 | batch 16x | b16384-r256 | 14.05 [10.90–14.14] | −1.8 % [−6.5, +2.0] | 11.28 | 5.72 | 1.8 | 0.31 |
| 6 | batch 16x + ring | b16384-r1024 | 13.97 [10.33–14.85] | −2.8 % [−3.4, −1.7] | 11.17 | 5.68 | 1.8 | 0.30 |

Full table with CPU, wall − CPU and read bytes: `grid.md`.
"Paired Δ" compares each arm with the default arm of the same rep (the arms of one rep ran back to back).
Unpaired, every min–max range overlaps the default's range, so by the author's rule no cell is "faster" from this screening alone.
Output is identical in all 60 measurements (one body digest per query, `correctness.tsv`); postflight gate PASS (`gate-postflight-cold.log`).

## Interpretation

1. Little cold I/O headroom is left in the sequential export.
   The export thread is on CPU for ~96 % of the wall time (29.4 of 30.7 s); only ~1.2 s (~4 %) of the wall time is not covered by export-thread CPU.
   The NVMe RAID sees an average queue depth of ~2.3 and is busy ~35 % of the time.
2. The ring size does not matter: with ~2 requests in flight on average, neither 256 nor 1024 slots is ever close to full.
3. A larger batch helps the sequential export through CPU, not through I/O depth: export-thread CPU drops from 29.4 s to 26.6–27.7 s at 16384 rows, and the wall time follows (paired −13 %).
   The process spends about half of its CPU in the kernel (`stime` 17.8 s of 34.4 s, ~8.9 M read syscalls per export), so the export is bounded by per-read CPU cost, not by device latency.
   Cost: time to first byte rises from ~0.5 s to ~0.85 s.
4. The scattered export spends ~11 s of its ~14 s before the first byte (query evaluation, ~1.2 M blocking `pread`s outside the export).
   Only ~3 s is export, so neither knob moves it beyond −3 %.
5. The hypothesis does not hold: neither query is limited by the ring, and the batch size acts on CPU per batch, not on reads in flight.

## Noise

The machine was shared: loadavg ~19 before and after the run (`env-before.txt`, `env-after.txt`).
Rep-to-rep spread is large (the default ranges 25.9–34.4 s); reps 3 and 5 were 10–25 % faster in most arms, which the rotation and the paired comparison partly cancel.
The per-rep metrics were recomputed after the run with the final `tools/grid-rep-metrics.py` (the first version missed the CPU of threads that exited before the end of the window); the raw samples are in `dev-samples.jsonl.gz` per rep.

## Files

- `grid.md`: per-arm table (wall, CPU, wall − CPU, export-thread CPU, aqu-sz, util, read GiB).
- `cold/<query>/<arm>/raw/results.csv`: one row per measurement (harness columns, incl. `cpu_s`, `utime_ticks`, `stime_ticks`, `read_bytes`, `syscr`, `first_byte_s`).
- `cold/<query>/<arm>/raw/r<rep>-cold/`: per-measurement artefacts, `grid-metrics.json`, `dev-samples.jsonl.gz`, server log.
- `correctness.tsv`: body digest per measurement.
- `build-env.txt`, `gate-*.log`, `env-*.txt`, `meta.env`, `driver.log`.
- `tools/`: the driver and the sampling/aggregation scripts.
