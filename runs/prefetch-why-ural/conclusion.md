# Conclusion for run prefetch-why-ural (software prefetch during vocab lookup)

## Scope

Run prefetch-why-ural explains the PR87 regression report for software
cache prefetching during vocabulary ID resolution. It compares a plain
sequential baseline against pipelined prefetch resolution at distances
K = 4, 8, 16, 32, plus a new pipelined-no-prefetch arm that isolates the
loop-restructure cost. All measurements ran on Ural (AMD Ryzen 7 3700X,
32 MiB L3) on 2026-09-07. The synthetic workload resolves 500,000
uniform-random IDs against a 1M-entry in-memory vocabulary.

Three binaries were measured. The PR87-era PrefetchingBenchmark was built
2026-09-03 and predates its branch head, so it serves reproduction only.
The refreshed SoftwarePipelinedPrefetcherBenchmark was built from
`feat/engine-v2-software-prefetching` at `96503b81d`. The new three-arm
PrefetchingBenchmark was built from `bench/prefetch-why-isolation` at
`02fa522dc`.

## Validity checks

PR87-style arms ran once each with no repetitions, while the
large-working-set benchmark reports medians over 5 repetitions. LLC
hardware counters are unsupported on this AMD processor (`perf` reports
`<not supported>`), so every llc-miss-rate value reads 0.0 and is void;
the L1 and IPC counters are real. Two earlier queue benches produced no
data because of a driver-script path bug, so only `20260907T213757Z`
carries valid PR87-style numbers and only `20260907T213006Z` carries
valid large-set numbers.

## Measurement results

Machine: Ural, AMD Ryzen 7 3700X, L1d 256 KiB, L2 4 MiB, L3 32 MiB.
Wikidata index for context: external vocabulary 19.8 GiB, offsets file
12.6 GiB (each exceeds the L3 by orders of magnitude).

PR87 reproduction (old binary):

| Arm | M res/s | L1 miss | IPC |
| --- | ---: | ---: | ---: |
| Baseline | 160.65 | 44.3% | 0.51 |
| K = 4 | 51.54 | 27.4% | 0.76 |
| K = 8 | 56.16 | 27.8% | 0.79 |
| K = 16 | 62.51 | 31.5% | 0.94 |
| K = 32 | 67.08 | 25.8% | 0.88 |

Isolation run (new binary):

| Arm | M res/s | L1 miss | IPC |
| --- | ---: | ---: | ---: |
| Baseline | 164.99 | 32.5% | 0.43 |
| Restructure only | 94.82 | 39.9% | 0.62 |
| K = 4 | 38.38 | 7.2% | 0.92 |
| K = 8 | 46.33 | 7.2% | 1.04 |
| K = 16 | 52.67 | 7.8% | 1.16 |
| K = 32 | 57.94 | 6.9% | 1.57 |

Large working sets of 160 to 256 MiB (refreshed binary, median of 5):
random lookups +11% (133.57 to 148.21 M/s), hash-join probes +6.5%
(147.55 to 157.17 M/s), vocab string resolution +7.8% (129.80 to
139.95 M/s), overall IPC 0.447.

## Interpretation

The loop restructure alone costs 42% of baseline throughput (164.99 to
94.82 M/s) through the extra index pass, the per-row callback, and the
per-row check, while the L1 miss rate rises from 32.5% to 39.9%. The
prefetch intrinsics cost a further 51% at K = 8 (94.82 to 46.33 M/s)
although the cache mechanism works: the L1 miss rate falls from 39.9%
to 7.2% and IPC rises from 0.62 to above 1.5 at K = 32. Wall time
follows instructions per lookup divided by IPC, and the added
instructions per row outweigh the reduced stall time because the 1M-entry
vocabulary is LLC-resident (8 MiB offsets against 32 MiB L3) with no
DRAM latency left to hide. On working sets that exceed the L3 by 5x to
8x, the same technique gains 6% to 11%, so the negative verdict is
specific to cache-resident vocabularies. The real Wikidata vocabulary
(19.8 GiB words, 12.6 GiB offsets) exceeds the L3 by three orders of
magnitude, so a Wikidata-backed resolution measurement remains open and
the synthetic verdict must not be generalized to it.

## Code change

Branch `bench/prefetch-why-isolation` holds 2 commits on PR87 head
`99a352117`. The first backports two stack compile fixes (the
`LiteralOrIriView` qualification and the public
`CompactVectorOfStrings` spans, since PR87 never compiled as a target).
The second adds the `Pipelined No-Prefetch (restructure only)` arm to
`benchmark/PrefetchingBenchmark.cpp` with identical measurement shape
minus the prefetch intrinsics, plus the CMake target registration.

## Artifact location

- Results: `/local/data-ssd/stoetzem/ai-review/prefetch-perf-results/20260907T213757Z`
  (valid full set), `.../20260907T213006Z` (valid large-set numbers only)
- Binaries: `/local/data-ssd/stoetzem/binaries/SoftwarePipelinedPrefetcherBenchmark-feat_engine-v2-software-prefetching`,
  `.../PrefetchingBenchmark-stack_21-io-uring-send-zc-zerocopy`,
  `.../PrefetchingBenchmark-bench_prefetch-why-isolation`
- Branch: `marvin7122/qlever` `bench/prefetch-why-isolation` at `02fa522dc`;
  worktree `~/code/qlever/.worktrees/prefetch-why`
- Run identifier: `prefetch-why-ural`
