# Conclusion for run prefetch-wikidata-ural (prefetch on real Wikidata vocabulary)

## Scope

Run prefetch-wikidata-ural measures software prefetching during
vocabulary ID resolution against the real Wikidata external vocabulary
instead of the synthetic 1M-entry vocabulary of run prefetch-why-ural.
The benchmark memory-maps `wikidata.vocabulary.words.external`
(19.8 GiB) plus `wikidata.vocabulary.words.external.offsets`
(12.6 GiB, 1.58B entries) and resolves 1M uniform-random IDs with four
arms: plain sequential baseline, pipelined-no-prefetch restructure, and
software prefetch at K = 8 and K = 16. Arm order rotates every
repetition over 5 repetitions to balance page-cache warmth. All runs
used Ural (AMD Ryzen 7 3700X, 32 MiB L3) on 2026-09-08.

## Validity checks

The checksum over all resolved bytes is identical (1056259833) across
all 20 arm-repetitions, which proves every arm performed identical
resolution work. Baseline repetition 0 took 18.1 s because it faulted
vocabulary pages into the cache, so only the warm medians
(repetitions 1 to 4) compare the arms fairly. LLC hardware counters are
unsupported on this AMD processor, so only L1 and IPC counters apply.
Uniform-random IDs form a worst case; export queries resolve correlated
IDs and may behave better.

## Measurement results

| Arm | Warm median | Warm M/s | Cold rep0 M/s |
| --- | ---: | ---: | ---: |
| Baseline | 145.88 ms | 6.85 | 0.055 |
| Restructure only | 152.69 ms | 6.55 | 6.51 |
| Prefetch K = 8 | 109.69 ms | 9.12 | 9.06 |
| Prefetch K = 16 | 109.58 ms | 9.13 | 9.12 |

Warm deltas: restructure −4.4% versus baseline; prefetch K = 8 +33.0%
versus baseline (+39.2% versus restructure); K = 16 ties K = 8. The cold
first touch costs 18.1 s for 1M lookups (0.055 M/s, disk-bound). Whole
process under `perf stat`: 18.67B cycles, 7.31B instructions,
branch-miss rate 10.7%.

## Interpretation

On the real vocabulary, prefetching wins by one third warm and reverses
the synthetic verdict. Restructure overhead shrinks from −42% on the
synthetic vocabulary to −4% here because memory latency dominates
instruction overhead. The cold first touch is 300x slower than warm
(0.055 versus 6.85 M/s), so full-export performance depends strongly on
page-cache state, which matches the cold/warm pattern of run 120.
Prefetch distances 8 and 16 tie, so distance tuning is flat here.

## Code change

Branch `bench/prefetch-wikidata` holds 1 commit on the isolation tip
(`f0938f7db`). It adds the standalone
`benchmark/WikidataVocabPrefetchBenchmark.cpp` (mmap access, rotated
arms, checksummed resolution) with a bare CMake target and no
benchmark-infra link.

## Artifact location

- Results: `/local/data-ssd/stoetzem/ai-review/prefetch-perf-results/20260908T060338Z-wikidata`
- Binary: `/local/data-ssd/stoetzem/binaries/WikidataVocabPrefetchBenchmark-bench_prefetch-wikidata`
- Branch: `marvin7122/qlever` `bench/prefetch-wikidata` at `f0938f7db`;
  worktree `~/code/qlever/.worktrees/prefetch-wikidata`
- Run identifier: `prefetch-wikidata-ural`
