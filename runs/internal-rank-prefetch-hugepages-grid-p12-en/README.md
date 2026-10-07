# Rank x prefetch x huge pages, English labels cold and warm

Part of the prefetch / huge-page experiment for fork PR marvin7122/qlever#264; setup, binaries, counters and the full story are in [`internal-rank-best-en-p12`](../internal-rank-best-en-p12/README.md).
Ural queue entry #5362, 2026-10-07, uncompressed responses, variant binary `6770bbf2c7e4a06793c31eff504b9526ac530c96`, 3 interleaved trials per arm, no load wait (pr-ab-grid.sh records no per-trial load).
All bodies of a cell are identical (`correctness.tsv`); postflight gates PASS (`gate-postflight-*.log`).
Table: `aggregate-counters.md` (from `internal-rank-lookup-aggregate2.py`; counters are per query, deltas vs the reference arm).
Binaries are not included.

## Result

| # | concern | scenario | arm | wall s median [min–max] | Δ vs rank | verdict | Δ cycles | Δ DRAM refills | Δ dTLB misses |
|---|---|---|---|---|---|---|---|---|---|
| 1 | reference | cold | rank | 24.99 [24.53–26.06] | | | | | |
| 2 | huge pages | cold | hp | 24.52 [23.93–25.60] | −1.9 % | no difference | −1.6 % | −0.1 % | −1.0 % |
| 3 | prefetch 8 | cold | pf8 | 22.21 [21.61–22.21] | −11.1 % | faster | −10.1 % | −15.8 % | −2.0 % |
| 4 | both | cold | pf8-hp | 21.82 [21.56–21.84] | −12.7 % | faster | −11.4 % | −15.6 % | −0.8 % |
| 5 | reference | warm | rank | 22.55 [17.86–25.17] | | | | | |
| 6 | huge pages | warm | hp | 18.99 [14.21–24.45] | −15.8 % | no difference | −14.6 % | −14.7 % | −16.5 % |
| 7 | prefetch 8 | warm | pf8 | 14.53 [12.41–17.97] | −35.6 % | no difference | −33.2 % | −49.1 % | −23.1 % |
| 8 | both | warm | pf8-hp | 21.65 [14.77–21.91] | −4.0 % | no difference | −4.7 % | −11.2 % | +32.4 % |

Cold, prefetching is faster with disjoint ranges; huge pages change neither time nor dTLB misses there, so the dTLB misses are not dominated by the 226 MB directory (the offsets, 6.2 GB, and words, 15 GB, are far larger).
Warm ranges are wide under co-tenant load (up to 10 s between the fastest and slowest trial of an arm), so no warm cell is decided.
