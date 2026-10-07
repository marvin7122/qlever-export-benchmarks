# Cold I/O characterisation of Wikidata exports on the final export stack (part 10)

## Question

Which cold Turtle exports on Wikidata make the export thread wait for the disk?
The screen asks whether the export thread spends at least 10 % of the wall time waiting in `io_uring_enter`.
Only then could further latency-hiding work (wave reaping, fibers, a depth-2 read pipeline) pay off.
It also characterises each workload's disk traffic (bytes, queue depth, bandwidth) and page-cache hit share.

## Setup

1. Machine: `ural`, AMD Ryzen 7 3700X (8 cores, 16 threads), 125 GiB RAM, index on a software RAID of two Samsung 990 PRO NVMe SSDs, Linux 7.0.0-28 (`env-before.txt`).
   CPU governor `powersave` (no root on the box).
2. Index: Wikidata truthy, 8.2 billion triples, vocabulary type `on-disk-compressed`.
3. Binary (one arm): export stack part 10 (#3528) head `4dd60f853612dacc4405c713638b1726c6382877` (`CIKM-2801-g4dd60f853`), every flag at its default (page-cache fast path on).
   It is the same binary as "final" in [`colloquium-final-p6-p7-p10-wikidata`](../colloquium-final-p6-p7-p10-wikidata/).
   `binary-label.txt`: the later tag `stack12/07d` (`b05dc9d4`) differs from it only in comments and a backport refactor.
   Gate: `gate-verify-p10.log` (PASS, io_uring compiled in).
4. Queries (Turtle CONSTRUCT export, all in `queries/` except the two references):
   - references: `ref-humans-de` = German labels of all humans ([`H-vocab-label-large-de.rq`](../colloquium-final-p6-p7-p10-wikidata/queries/H-vocab-label-large-de.rq)), `ref-values-200k` = German labels of 200,000 entities in a `VALUES` list ([`H-vocab-random-label-de-200k.rq`](../colloquium-final-p6-p7-p10-wikidata/queries/H-vocab-random-label-de-200k.rq));
   - A (scattered): German labels of one sparse class each (taxa, disambiguation pages, articles, female humans, a mix);
   - B (several literals per entity): humans with labels, descriptions and aliases in one or more languages.
5. Memory caps: `capN-*` runs the server in a user systemd scope with `MemoryMax` = calibrated peak anonymous memory (22.46 GiB, `calibration.json`) + N GiB and no swap.
   The page cache then cannot hold the index, so pages are read again (`refault_file` in the off-CPU section of `summary.md`).
6. Procedure: cold only; the page cache is dropped and a fresh server started before every execution; 3 trials per configuration, run in sequence (`io-screen.log`).
   Per execution: wall time, time to first byte (TTFB), per-thread on-CPU and off-CPU time split by syscall (1 ms `/proc` sampler), `LD_PRELOAD` call counts (`io_counts_preload.c`), disk statistics every 0.25 s.
   Fast-path hit share = 1 − (EAGAIN misses / `preadv2(RWF_NOWAIT)` calls).
7. Run: Ural queue entry 5308, 2026-10-06 22:17–23:20 UTC.
   Load: load1 2.47 at the start, 19.9 at the end (another user's niced jobs, `env-after.txt`); there is no per-trial load log in this run.

## Result

Cells: median [min–max] over 3 trials (`summary.md` has all columns).

| configuration | lines | wall s | TTFB s | io_uring wait, % of wall | fast-path hit % | disk read GB | aqu-sz (export) |
|---|---:|---|---|---|---:|---:|---:|
| ref-humans-de | 4,515,802 | 34.33 [24.89–34.56] | 0.55 | 0.3 [0.2–0.7] | 93.4 | 9.45 | 2.02 |
| ref-values-200k | 177,845 | 10.38 [10.35–13.74] | 7.82 | 0.0 | 24.8 | 2.99 | 6.45 |
| A-taxon | 3,711,626 | 19.07 [17.06–24.12] | 0.34 | 0.6 | 87.9 | 9.81 | 2.55 |
| A-disambig | 701,285 | 11.28 [10.13–13.93] | 0.51 | 0.0 | 40.4 | 6.83 | 7.01 |
| A-article | 258,159 | 3.17 [3.09–3.86] | 0.46 | 0.4 | 62.0 | 1.34 | 4.99 |
| A-female | 986,247 | 7.92 [7.48–9.80] | 0.48 | 0.2 | 87.3 | 4.16 | 3.42 |
| A-mixed | 1,508,805 | 17.24 [14.84–18.91] | 0.57 | 0.2 | 66.4 | 10.84 | 5.65 |
| B-label-desc-alias-de | 2,058,636 | 14.42 [12.46–15.66] | 0.54 | 0.4 | 79.8 | 6.81 | 4.39 |
| B-label-5lang | 11,589,085 | 59.96 [43.92–64.11] | 0.64 | 0.3 | 97.7 | 9.39 | 1.11 |
| B-desc-4lang | 4,433,704 | 10.41 [9.82–13.10] | 0.73 | 1.8 | 98.1 | 1.16 | 0.48 |
| B-label-desc-de | 4,055,790 | 23.54 [19.95–26.98] | 0.46 | 0.5 | 91.5 | 8.31 | 2.62 |
| cap1-humans-de | 4,515,802 | 78.13 [59.06–79.33] | 0.44 | 0.1 | 54.2 | 27.76 | 4.47 |
| cap3-humans-de | 4,515,802 | 52.21 [51.77–52.45] | 0.52 | 0.1 | 83.3 | 17.85 | 3.34 |

1. No configuration reaches the 10 % gate: the export thread waits in `io_uring_enter` for at most 1.8 % of the wall time (median), usually below 1 %.
   On the final stack the cold export thread is on-CPU almost all the time (e.g. `ref-humans-de`: 33.3 s on-CPU of 34.3 s wall).
2. The scattered disambiguation-page export (`A-disambig`, 701,285 lines, 74.4 MB) has the lowest fast-path hit share of the uncapped workloads without `VALUES` (40 %) and the deepest disk queue (aqu-sz 7.0): its reads are scattered.
   Unlike the `VALUES` query it streams from the start (TTFB 0.51 s vs 7.82 s), so its wall time is export time.
   This is why the repeated colloquium run uses it as the "German scattered" query.
3. With a memory cap below the index size the same export reads about 2–3x more bytes and gets slower (humans-de: 34.3 s → 52.2 s with +3 GiB, 78.1 s with +1 GiB), but the wait in `io_uring_enter` stays below 0.2 %.
4. Every configuration returned byte-identical responses across its trials (`summary.md`, xxh3_128 per execution in `rows.json`).

## Used in the colloquium talk

1. On the final stack the cold export thread almost never waits for I/O: median `io_uring_enter` wait ≤ 1.8 % of wall in all 19 configurations (max single trial 2.2 %).
2. The German scattered query (`A-scatter-disambig-label-de.rq`): 701,285 lines, about 11 s cold on part 10, 40 % page-cache fast-path hits.

## Files

- `README.md`: this file.
- `summary.md`: full table (all columns), byte identity per configuration, export-thread off-CPU time by syscall, preload counts, cgroup memory.
- `rows.json`: one record per execution with every measured value; `calibration.json`: the calibration execution (peak anonymous memory for the caps).
- `io-screen.log`: one line per execution.
- `<configuration>/t<N>/`: per execution `row.json`, `disk-samples.json`, `io-counts.bin`, `qlever-server.log`, `server-cmd.txt`.
- `plan.json`: the configurations (query, cap headroom).
- `io-screen.sh`: the queue entry (binary gate, preload build, scope probe, run, summary); `io_screen.py`: the measurement; `summarize.py`: builds `summary.md`; `io_counts_preload.c`: the `LD_PRELOAD` counter (the built `.so` is not included).
- `queries/`: the A and B queries.
- `env-before.txt`, `env-after.txt`: host snapshot (load, governor, memory, other users' running processes).
- `gate-verify-p10.log`: binary check (commit in version string, io_uring symbols).
- `binary-label.txt`: which commit the binary is.
