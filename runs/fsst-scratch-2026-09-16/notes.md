# FSST scratch-buffer scale-up (2026-09-16)

## Motivation

The three strategies perform the same decompressions. The benchmark exists
to prove that the memory saving is free, not to find a faster decode.
`decompressInto` lets callers decode into caller-owned buffers and avoids
one `std::string` temporary per stage. The stage-aware scratch sizes the
intermediate buffer at `outputCapacity / 8` instead of a second full-size
buffer, which halves peak scratch memory of the three-stage pipeline.
Parity is the desired result because it de-risks that saving.

## Method

Release binary on Ural (`FsstScratchBufferBenchmark`, commit c5191e1).
Corpus: 40,000 synthetic Wikidata-like words with 180-char suffixes,
compressed through 3 FSST stages. Each strategy decodes all words 200
times (8M three-stage decodes). All 6 strategy orders run, 3 trials each.

## Results (seconds per 8M decodes, 18 trials per strategy)

| strategy | median | min | max |
|---|---|---|---|
| full-size `std::string` scratch | 0.334042 | 0.332267 | 0.370031 |
| full-size uninitialized scratch | 0.334253 | 0.332376 | 0.655139 |
| stage-aware uninitialized scratch | 0.336010 | 0.331410 | 0.654703 |

Raw timings: `raw/timings.csv`. Full log: Ural `~/.qlever-wq/logs/3744-bench.log`.

## Observations

- Largest median gap is 0.6%. The strategies are at parity.
- Run-to-run noise dominates. Whole process runs flip together between
  ~0.333s and ~0.369s (about 10%) regardless of strategy, and one trial
  produced two ~0.65s outliers. The order rotation shows this fluctuation
  hits all three arms equally, so it is machine noise, not a strategy
  effect.
- Allocations happen once per measurement outside the decode loop, so
  8M decodes amortize them away. This explains why buffer choice cannot
  move the needle here.

## Follow-up

Run `perf stat` (cycles, instructions, cache misses, page faults) plus one
`perf record` flamegraph per strategy on Ural. Expected outcome: identical
decode-bound profiles, with fewer page touches for the stage-aware arm.
This tells the thesis where time goes and documents the memory win
directly instead of inferring it from parity.
