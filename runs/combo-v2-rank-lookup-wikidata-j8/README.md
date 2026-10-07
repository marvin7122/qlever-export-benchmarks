# combo-v2-rank-lookup-wikidata-j8

Cumulative effect of idea 2 (rank bit vector for the in-RAM vocabulary, fork PR #264) and idea 3 (multithreaded export engine v2, fork PRs #137 / #120).
Fork draft PR: marvin7122/qlever#274, branch `combo/v2-plus-rank-lookup` @ `022c2247`.
Ural queue #5368, 2026-10-07 19:56–20:56 UTC.

## Setup

1. One binary (Wolga u24 build #396, Release, gcc 13.3, `CIKM-3084-g022c22472`), four arms that differ only in runtime flags:

| arm | request field | runtime parameters |
|---|---|---|
| today | `fast-export=0` | `vocabulary-internal-rank-lookup=false` |
| idea 3 | `fast-export=1` | `vocabulary-internal-rank-lookup=false` |
| ideas 2+3 | `fast-export=1` | `vocabulary-internal-rank-lookup=true` |
| ideas 2+3 + prefetch + huge pages | `fast-export=1` | rank on, `vocabulary-internal-rank-prefetch-distance=16`, `vocabulary-internal-rank-hugepages=true` |

2. Wikidata truthy, `--num-simultaneous-queries 8`, uncompressed responses (`Accept-Encoding: identity`).
3. Queries: English labels of all humans, SELECT CSV (`H-vocab-label-large-select`, 11.6 M rows, words in RAM); German labels of all humans, SELECT CSV (`H-vocab-label-large-de-select`, 4.5 M rows, words on disk).
4. 3 interleaved trials per query and scenario, arm order rotated per trial.
   Cold: `clear-caches` before each trial.
   Warm: one unmeasured query, then the query is looped back-to-back to at least 10 s; wall time and CPU are per-query means of the loop.
5. No load wait: load1 before, after and the maximum during each trial is in `rep-load.tsv`.
6. Correctness: every arm's first body has the same row multiset and line count as the today arm (`correctness.tsv`, 48/48).
7. Unit tests of the same build ran first: 97 tests in 6 binaries, all passed (`tests/`).

## Caveat: co-tenant load

The box was shared: load1 was 4–27 during the trials (16 cores).
At load1 above about 13, the v2 arms got about 4 cores; below about 9, about 8 cores.
Wall-time medians therefore mix quiet and busy trials.
CPU seconds per query are hardly affected by the load and are the robust comparison.

## Files

- `summary.md`: per arm and cell, wall median [min–max], CPU per query, busy cores (CPU / wall).
- `analysis/cpu-split.md`: user and system CPU per query, `io_uring_enter` calls, read syscalls.
- `analysis/disk-query-window.md`: NVMe statistics (`/proc/diskstats`, 0.25 s samples, both RAID-0 members summed) restricted to each cold query's window (server log "Processing" to "Done").
- `analysis/profile-categories.md`: warm English profiles (`perf record -e cycles`, 300 Hz, all threads) by leaf function (self time).
- `perf/H-vocab-label-large-select/<arm>/`: `report-self-sym.txt`, `report-children-sym.txt`, `flame.svg`.
  User-mode stacks did not unwind with `--call-graph dwarf` (children = self for user frames), so the flame graphs only resolve kernel frames.
- `disk/`: raw diskstats samples per cold trial; `cold/`, `warm/`: raw harness output per trial.
- `driver.sh`: the driver; harness copy `pr-ab-tools-combo` (adds `--perf-event`, `--perf-call-graph`, `--loop-compare bytes`).
