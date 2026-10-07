# Rank lookup with prefetching and huge pages (vs part 12): overview and base A/B, English labels

This run is the base A/B of a three-step experiment for fork PR marvin7122/qlever#264.
All steps ran in one Ural queue entry (#5362, script [`irl-prefetch-hp-ab.sh`](irl-prefetch-hp-ab.sh)) on 2026-10-07 21:00–23:05 UTC.

## Question

PR #264 replaces the binary search in `VocabularyInMemoryBinSearch::positionOfIndex` (778 M sorted indices of the in-RAM words on Wikidata) with a rank bit vector of 226 MB: one 64-byte cache line per lookup.
The remaining cost per lookup is a cache miss in the directory (plus, with 4 KiB pages, a TLB miss), and for an in-RAM word a miss in its offsets and one in its bytes.
Do prefetching (`vocabulary-internal-rank-prefetch-distance`) and transparent huge pages for the directory (`vocabulary-internal-rank-hugepages`) remove more of this cost, and is the mechanism visible in the counters?

## Setup

1. Machine: `ural`, AMD Ryzen 7 3700X (Zen 2), 125 GiB RAM, Linux 7.0.0-28, CPU governor `powersave` (no root).
   Transparent huge pages: `madvise` (defrag `madvise`).
   The server log confirms that the directory was fully on huge pages in the huge-page arms: "226492416 of 226,492,416 allocated bytes on huge pages".
2. Index: Wikidata truthy, `on-disk-compressed`; in-RAM vocabulary 777,658,536 words, `endIndex()` 1,580,300,680.
3. Binaries (gates `gate-verify-*.log`: PASS, io_uring compiled in):
   - base: tag `stack12/22` = `d20a4c74ab76e844364eea53a8ac144ea54729c0`;
   - variant: `6770bbf2c7e4a06793c31eff504b9526ac530c96` (PR #264 with prefetching and huge pages).
4. Responses are uncompressed (`Accept-Encoding: identity`).
5. Each trial records `perf stat` on the server (all threads, measured window only): cycles, instructions, cache-misses, demand L1 refills from DRAM (`ls_refills_from_sys.ls_mabresp_lcl_dram`, the Zen 2 proxy for LLC load misses, which this PMU does not expose), L2 fill wait cycles, dTLB misses (`ls_l1_d_tlb_miss.all`).
6. 3 interleaved trials per arm and cell; warm loops to ≥ 10 s (one execution here); cold = fresh server after `drop_caches`.
   No load wait: the box was shared, and max load1 during the trials of this run was 4.1–20.6 (`rep-load.tsv`).
   The two grid runs record no per-trial load.

## Steps

1. [`internal-rank-prefetch-sweep-p12-identity`](../internal-rank-prefetch-sweep-p12-identity/): prefetch distance 0/4/8/16/32 on English warm.
   All distances 4–32 are 9–12 % faster in median than 0, with overlapping ranges; 8 was best (`best-distance.txt`).
2. Factorial on the variant binary: rank, rank + prefetch 8, rank + huge pages, rank + prefetch 8 + huge pages.
   Runs: [`internal-rank-prefetch-hugepages-grid-p12-en`](../internal-rank-prefetch-hugepages-grid-p12-en/) (English cold and warm) and [`internal-rank-prefetch-hugepages-grid-p12-de-warm`](../internal-rank-prefetch-hugepages-grid-p12-de-warm/) (German warm).
   Best arm on English warm: prefetch 8 without huge pages (`best-arm.txt`).
3. This run: base vs best arm (`variant` = prefetch 8) vs rank without prefetch (`variant2`), English cold and warm, plus a perf profile pair base vs best arm.
   German warm: [`internal-rank-best-de-warm-p12`](../internal-rank-best-de-warm-p12/).

## Result: base A/B (`aggregate-counters.md`, `conclusion.md`)

| # | concern | query | scenario | arm | wall s median [min–max] | Δ wall | verdict | Δ cycles | Δ DRAM refills | Δ dTLB misses |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | main claim, all words in RAM | English | warm | rank | 16.80 [16.07–17.65] | −56.6 % | faster | −52.2 % | −81.4 % | −68.9 % |
| 2 | prefetch on top | English | warm | rank + prefetch 8 | 16.52 [13.65–17.80] | −57.3 % | faster | −52.6 % | −82.2 % | −64.5 % |
| 3 | main claim, cold | English | cold | rank | 24.59 [24.53–25.00] | −36.4 % | faster | −33.8 % | −69.6 % | −50.3 % |
| 4 | prefetch on top, cold | English | cold | rank + prefetch 8 | 21.53 [20.66–22.24] | −44.3 % | faster | −41.3 % | −75.3 % | −49.3 % |
| 5 | sequential German, warm | German | warm | rank | 15.36 [12.15–18.29] | −35.4 % | faster | −32.9 % | −64.7 % | −54.9 % |
| 6 | prefetch on top, German | German | warm | rank + prefetch 8 | 18.07 [11.91–18.13] | −24.0 % | faster | −23.6 % | −61.7 % | −35.8 % |

The base is 38.66 s (English cold), 38.68 s (English warm) and 23.77 s (German warm).
All deltas are vs base. All bodies in each cell are identical (`correctness.tsv`, same triple multiset and bytes), and the postflight gates PASS.

Prefetch vs no prefetch within this run: English cold 21.53 vs 24.59 s (ranges disjoint, −12.4 %); English warm and German warm overlap.

## Profile pair (English warm, `perf/H-vocab-label-large/{base,variant}/report-top50.txt`)

| function | base | rank + prefetch 8 |
|---|---|---|
| `VocabularyInMemoryBinSearch::positionOfIndex` (self) | 28.1 % | 1.9 % |
| `__popcountdi2` (libgcc popcount, no `POPCNT` instruction in this build) | – | 5.4 % |
| frames matching `positionOfIndex`, popcount or rank (inclusive) | 28.1 % | 7.4 % |

The binary search was the largest single function in the base profile; with the rank lookup the probe costs 7.4 % of the samples, of which 5.4 % is the out-of-line software popcount.

## Files

`results.csv`, `<scenario>/<query>/<arm>/raw/` (per trial, including `perf-stat.csv`), `vs-variant/`, `vs-variant2/`, `conclusion.md`, `aggregate-counters.md` (from `internal-rank-lookup-aggregate2.py`), `correctness.tsv`, `rep-load.tsv`, `loadavg.tsv`, `perf/`, `build-env.txt`, `env-*.txt`, `gate-*.log`, `driver.log`, `irl-prefetch-hp-ab.sh`.
Binaries and `perf.data` are not included.
