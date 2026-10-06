# Export stack on Wikidata: before (part 6), ring only (part 7), final (part 10), 10 trials

## Question

The upstream export stack ("export stack k/10") changes how a Turtle export reads vocabulary words from disk.
Part 6 (#3525) still reads the on-disk-compressed words with one blocking `pread` per word.
Part 7 (#3526) routes these reads through an io_uring ring ("ring only").
Part 10 (#3528, head of the stack) adds a page-cache fast path on top of the ring, on by default.
This run measures all three versions in one interleaved run, cold and warm, with identical output.
These three commits are the code versions of the colloquium talk.

## Setup

1. Machine: `ural`, AMD Ryzen 7 3700X (8 cores, 16 threads), 125 GiB RAM, index on a software RAID of two Samsung 990 PRO NVMe SSDs, Linux 7.0.0-28 (`env-before.txt`).
   CPU governor `powersave` (no root on the box; recorded by the gates).
2. Index: Wikidata truthy, 8.2 billion triples, vocabulary type `on-disk-compressed` (`/local/data-ssd/stoetzem/wikidata/wikidata`).
3. Queries (Turtle CONSTRUCT export):
   - German sequential: [`H-vocab-label-large-de.rq`](queries/H-vocab-label-large-de.rq), every human with a German label, 504,927,346 response bytes;
   - German scattered: [`H-vocab-random-label-de-200k.rq`](queries/H-vocab-random-label-de-200k.rq), German labels of 200,000 entities in a `VALUES` list, 19,297,737 response bytes;
   - English control: [`H-vocab-label-large.rq`](queries/H-vocab-label-large.rq), every human with an English label (English labels are not in the on-disk part), 1,302,749,672 response bytes.
4. Arms (three binaries, no runtime parameters set, every flag at its default; built on Wolga with Ural's toolchain, gate-verified with `verify-qlever-binary.sh --require-iouring`):
   - before = `base`: part 6/10, #3525, `a752a45716c20e19467508f62801d64f36c0a60a` (`CIKM-2732-ga752a4571`);
   - ring only = `variant2`: part 7/10, #3526, `60f854f42e2af6984924a2b5f692e6b8b407310c` (`CIKM-2753-g60f854f42`);
   - final = `variant`: part 10/10, #3528, `4dd60f853612dacc4405c713638b1726c6382877` (`CIKM-2801-g4dd60f853`), page-cache fast path on (default).
5. Scenarios:
   - cold: the OS page cache is dropped before each repetition, then the query runs once;
   - warm: the files are in the OS page cache; queries shorter than 10 s are looped back-to-back until at least 10 s and the per-query time is reported.
6. Repetitions: 10 interleaved trials per arm, query and scenario; order alternates (odd trials before, final, ring only; even trials reversed).
7. Run: Ural queue entry 5303, 2026-10-06 10:29–14:36 UTC.
   Driver: `run.sh` (a copy of `pr-ab-multi-v2.sh` with a third binary, `--variant2-bin`, and load logging).

## Result

Cells: mean, median, [min–max] of elapsed seconds over 10 trials.
Speedup = median(before) / median(version).

| query | scenario | before (p6) | ring only (p7) | final (p10) | ring only vs before | final vs before |
|---|---|---|---|---|---:|---:|
| German sequential | cold | 82.38, 88.67 [66.07–93.68] | 38.79, 39.17 [35.63–39.74] | 31.93, 33.83 [24.55–34.54] | 2.26x | 2.62x |
| German scattered | cold | 35.75, 39.32 [27.55–40.82] | 13.77, 14.29 [11.44–14.53] | 13.37, 14.21 [11.03–14.62] | 2.75x | 2.77x |
| English control | cold | 30.54, 28.58 [22.30–40.31] | 31.75, 32.40 [22.36–40.97] | 30.86, 26.81 [22.36–40.79] | 0.88x, noise | 1.07x, noise |
| German sequential | warm | 22.10, 24.43 [15.90–24.86] | 26.10, 27.23 [20.81–28.80] | 21.51, 23.46 [15.58–24.16] | 0.90x | 1.04x, noise |
| German scattered | warm | 4.07, 3.93 [3.85–5.42] | 4.17, 4.08 [4.02–4.88] | 4.14, 3.98 [3.92–5.52] | 0.96x | 0.99x, noise |
| English control | warm | 35.34, 39.56 [22.58–44.08] | 40.42, 41.02 [22.86–55.58] | 36.81, 38.76 [26.18–42.93] | 0.96x, noise | 1.02x, noise |

Per-trial paired ratios (same trial index, arms run minutes apart) give the same picture:
final vs before, cold German sequential 2.65x [1.93–2.78], cold German scattered 2.75x [2.19–2.84];
ring only vs before, warm German sequential 0.87x [0.67–0.95] (ring only is slower warm in every trial).

1. Cold German exports: final is 2.6x (sequential) and 2.8x (scattered) faster than before; the ranges do not overlap.
   Ring only already gives 2.3x and 2.75x; on the sequential export the fast path adds the rest (39.17 → 33.83 s median).
2. Warm German sequential: ring only is slower than before (27.23 vs 24.43 s, all paired ratios < 1).
   Final removes this slowdown (23.46 s); final vs before is within noise.
3. English control and warm scattered: no change beyond noise, as expected (English labels are not read from the on-disk vocabulary).
4. Correctness: every response of a query has the same checksum across all 30 trials of both scenarios (`aggregate.txt`, `correctness.tsv`); no mismatch.
   Gates: preflight and verify PASS for all three binaries; postflight PASS cold and warm.

## Noise: this run is disturbed

Another user's niced multi-process jobs ran on Ural during the whole run.
They come in bursts: load1 around 18–20 (up to 32) for 15–60 minutes, then a few minutes near 1–5 (`loadavg.tsv`, one sample per minute, with the number of other users' running processes).
Only 31 of 247 one-minute samples had load1 < 3; the one long quiet stretch, 12:58–13:27 UTC, covered warm scattered trials 8–10 and English-control cold trials 1–8 only, no German cold trial.
Most cells therefore have ranges wider than ±10 % around the median, and the fastest trial of a cell is almost always one in a quiet minute (`rep-load.tsv` holds load1 before and after each trial).
Absolute times are higher than in the earlier, quieter colloquium run (`colloquium-final-ab-wikidata-len10`, before cold German sequential 67.7 s median there vs 88.7 s here).

What still holds: the cold German speedups (2.6x, 2.8x), because the ranges are far apart and every paired trial shows them.
What does not: the warm and English-control comparisons, where the spread is larger than the effect.
A repeat in a quiet window is needed before quoting warm numbers or absolute seconds.

## Binaries on Ural (for follow-up runs)

- before (p6): `/local/data-ssd/stoetzem/bin-cache/a752a45716c20e19467508f62801d64f36c0a60a/qlever-server` (md5 `afdbdd0442b527e1ca7c8fa3e54638fa`)
- ring only (p7): `/local/data-ssd/stoetzem/bin-cache/60f854f42e2af6984924a2b5f692e6b8b407310c/qlever-server` (md5 `86bd25239b54ebed4577dd42fb646aa1`)
- final (p10): `/local/data-ssd/stoetzem/bin-cache/4dd60f853612dacc4405c713638b1726c6382877/qlever-server` (md5 `b549c44cabe5aea7d1986f506522add1`)

## Files

- `README.md`: this file.
- `run.sh`: the driver script (three binaries, per-trial and per-minute load logging).
- `meta.env`: the run definition: commits, binaries, labels, queries, scenarios, repetitions, minimum measure time.
- `build-env.txt`: per binary: version string, md5, io_uring symbols, compiler, liburing; harness md5.
- `driver.log`: the driver's console log, one line per finished trial.
- `results.csv`: one row per trial and arm (`base` = before, `variant2` = ring only, `variant` = final): elapsed time, response bytes, CPU seconds, bytes read from disk, read syscalls, checksum.
- `aggregate.txt`: per scenario, query and arm: medians of elapsed time, bytes read, read syscalls, number of distinct checksums.
- `conclusion.md`: the two pairwise comparisons (before vs final, before vs ring only) with median, min, max, delta and verdict.
- `correctness.tsv`: byte count, line count and checksums of every response.
- `loadavg.tsv`: load average and other users' running processes, once per minute.
- `rep-load.tsv`: load average before and after each trial.
- `env-before.txt`, `env-after.txt`: host snapshot before and after the run.
- `gate-preflight-*.log`, `gate-verify-*.log`: binary and host checks before the run (PASS; load and powersave recorded as warnings).
- `gate-postflight-cold.log`, `gate-postflight-warm.log`: completeness and cold-cache checks after the run (PASS).
- `queries/`: the three SPARQL queries.
- `cold/<query>/<arm>/`, `warm/<query>/<arm>/`: harness output per trial (`raw/r<N>-<scenario>/`).
- `vs-variant/`, `vs-variant2/`: the two pairwise comparisons with their own `conclusion.md`.
