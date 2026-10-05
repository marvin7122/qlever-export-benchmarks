# QLever export benchmarks: run artifacts

Benchmark run directories for the QLever query-result export PR stack
(upstream [ad-freiburg/qlever](https://github.com/ad-freiburg/qlever) PRs
#3476, #3477, #3499, #3506, #3520–#3530, #3539 and the preadv2 fast-path part;
fork counterparts in [marvin7122/qlever](https://github.com/marvin7122/qlever)).

This repository contains only measurement artifacts, copied from the author's
private thesis repository with their original directory names
(`experiments/runs/<dir>` there, `runs/<dir>` here). The PR descriptions link
to directories in this repository.

## Runs used in the colloquium talk (2026-10-26)

Each of these directories has a `README.md` that says what the run measures and which numbers the slides take from it.

1. [`io-wait-null-ab-2`](runs/io-wait-null-ab-2/): size of the German sequential export: 8.9 million blocking reads, 0.5 GB of output.
2. [`nowait8-readahead-fadv-random`](runs/nowait8-readahead-fadv-random/): share of name reads served from the page cache, cold: 92.4 % sequential, 20.9 % scattered.
3. [`pr81-fast-export-wikidata-ab`](runs/pr81-fast-export-wikidata-ab/): English-label control export: 27.83 s cold, 27.72 s warm, CPU-bound.
4. [`wikidata-routing-ab`](runs/wikidata-routing-ab/): master vs io_uring routing on German-label exports, cold and warm.
5. [`wikidata-iouring-stall-compare-de`](runs/wikidata-iouring-stall-compare-de/): baseline wall time vs CPU time, the upper bound if all waiting disappeared.
6. [`stack-nowait-vs-p7-wikidata-len10`](runs/stack-nowait-vs-p7-wikidata-len10/): ring only vs ring + page-cache fast path, 10 trials.
7. [`stack-p7-vs-p6-wikidata`](runs/stack-p7-vs-p6-wikidata/): the "before (pread)" bars: stack part 6 (#3525) vs part 7 (#3526).

## Machine

All A/B runs ran on the benchmark host `ural` unless a run's env file says otherwise:

- CPU: AMD Ryzen 7 3700X, 8 cores / 16 threads, one NUMA node,
  governor `powersave` (recorded per run in `env*.txt`)
- RAM: 125 GiB
- Storage: indexes on an ext4 file system on an md RAID over NVMe devices
  (`/dev/md1`, mounted at `/local/data-ssd`)
- OS: Ubuntu 24.04, Linux 7.0.0-28-generic; liburing 2.15
- Datasets: Wikidata truthy and DBLP indexes under `/local/data-ssd/stoetzem/{wikidata,dblp}`

Each run directory records its own environment (`env.txt`, `env-before.txt` /
`env-after.txt`, `meta.env`, `metadata.yaml`), so check there for the exact
state of a given run (load average, page-cache size, commits, binaries, flags).

## Harness

- `pr-ab.sh` (thesis repository, `scripts/`): interleaved A/B of two binaries
  or of one binary with a runtime flag off vs on. Arms alternate per repetition
  (odd reps base first, even reps variant first). Cold repetitions drop the
  page cache (`clear-caches`) before every rep; warm repetitions do not.
  Adaptive repetitions: 3 per arm and cell, reps 4–5 only when the min..max
  ranges of the two arms overlap after 3 (`adaptive.tsv`).
- Each rep is timed end to end by `benchmark_export.py`, which also checks the
  result bytes (checksums in `correctness.tsv`) and records syscall and I/O
  counters (`pread64`, `io_uring_enter`, `read_bytes`, CPU seconds).
- Pre-/post-flight gates (`gate-*.log`) check that the binary is the intended
  build and the host was idle and cache-cold where required.
- Some directories come from older one-off scripts (`wikidata-iouring-bench.sh`,
  `wikidata-pr161-adaptive-batch-ab.sh`, ...); their `bench.log` / `arms.txt`
  list the arms and the per-rep counters.

## How to read a run directory

- `conclusion.md`: the result. Table of median / min / max elapsed seconds per
  query, scenario (cold/warm) and arm, the delta vs base, the verdict and the
  correctness check. Noise rule: within noise when |delta| < 1 % or the two
  arms' min..max ranges overlap.
- `results.csv` / `aggregate.txt` / `*.tsv`: raw per-repetition numbers.
- `meta.env`: the A/B definition (base/variant commit, binary, extra server
  args, threads, repetitions, index).
- `diagnosis.md`: counter-level analysis where present.
- `perf/<query>/<arm>/`: `report-top50.txt`, `stacks.folded`, `flame.svg`;
  `perf/<query>/diff.svg` is the base-to-variant differential flame graph.
- `queries/`: the SPARQL queries used.

## Not included

- Server binaries (`bin/`), the `LD_PRELOAD` syscall-counter library
  (`libexport_syscall_count.so`), raw `perf.data` files.
- Files over 20 MB (raw `strace` logs of `121-access-sequentiality`).
- The IP address of a private Git server in `git remote -v` dumps inside
  `metadata.yaml` files is replaced by `<private-gitea-host>`.

## Run directory → PR

Parts refer to the 17-part upstream export stack.

| run dir | upstream PR (stack part) | fork PR |
|---|---|---|
| `fsst-scratch-2026-09-16` | #3522 (part 3) | #73 |
| `wikidata-routing-ab` | #3526 (7), #3528 (9), fast path (14), #3477 (16) | #77, #172, #236, #165 |
| `wikidata-upstream172-compressed-routing-ab` | #3526 (7), #3528 (9) | #77, #79, #172 |
| `pr120-dblp-ab` | #3526 (7), fast path (14) | #120 (indirect evidence) |
| `pr120-warmfix-dblp-ural` | #3526 (7), fast path (14) | #120 (indirect evidence) |
| `pr81-dblp-turtle-fastexport-ab` | #3529 (10) | #81 |
| `pr81-fast-export-wikidata-ab` | #3529 (10), excluded void run | #81 |
| `pr117-dblp-csv-j1-ab`, `pr117-dblp-tsv-j1-ab`, `pr117-dblp-csv-j8-ab` | #3530 (11) | #82, #224 |
| `pr94-dblp-hsizeselect-t1-ab`, `pr94-dblp-hsizeselect-t8-ab`, `pr94-dblp-r2select-t1-ab`, `pr94-dblp-r2select-t8-ab`, `pr94-dblp-ttfb` | #3539 (12) | #94, #225 |
| `pr196-wikidata-routed-ab`, `pr196-wikidata-ab`, `pr196-wikidata-ab-final` | #3506 (13) | #196 |
| `pr161-wikidata-routed-ab`, `wikidata-upstream161-adaptive-ab`, `wikidata-minbatch-sweep3`, `pr3476-controller-onoff-wikidata-ab` | #3476 (15) | #161 |
| `wikidata-upstream165-fibers-routed-ab3`, `wikidata-fibers-routed-ab`, `export-fiberoverlap-wikidata-routed-ab` | #3477 (16) | #165 |
| `wikidata-register-files-routed-ab`, `wikidata-ch7-register-ab` | #3499 (17) | #59 |

The other directories are further runs of the same thesis work (profiles,
pilots, earlier A/Bs) and are kept for context.

## Follow-up

The stack re-measure (each part against part k−1, directories with a
`stack-` prefix) was still running when this repository was created. Its
directories will be added under `runs/stack-*` and the PR descriptions'
pending rows linked to them.
