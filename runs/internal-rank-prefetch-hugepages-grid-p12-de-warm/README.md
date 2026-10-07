# Rank x prefetch x huge pages, German labels warm

Part of the prefetch / huge-page experiment for fork PR marvin7122/qlever#264; setup, binaries, counters and the full story are in [`internal-rank-best-en-p12`](../internal-rank-best-en-p12/README.md).
Ural queue entry #5362, 2026-10-07, uncompressed responses, variant binary `6770bbf2c7e4a06793c31eff504b9526ac530c96`, 3 interleaved trials per arm, no load wait (pr-ab-grid.sh records no per-trial load).
All bodies of a cell are identical (`correctness.tsv`); postflight gates PASS (`gate-postflight-*.log`).
Table: `aggregate-counters.md` (from `internal-rank-lookup-aggregate2.py`; counters are per query, deltas vs the reference arm).
Binaries are not included.

## Result

| # | concern | arm | wall s median [min–max] | Δ vs rank | verdict | Δ cycles | Δ DRAM refills | Δ dTLB misses |
|---|---|---|---|---|---|---|---|---|
| 1 | reference | rank | 13.00 [12.96–14.98] | | | | | |
| 2 | huge pages | hp | 12.05 [11.59–12.12] | −7.3 % | faster | −6.0 % | −15.5 % | −17.5 % |
| 3 | prefetch 8 | pf8 | 12.91 [11.85–13.83] | −0.7 % | no difference | −1.2 % | −0.0 % | −0.6 % |
| 4 | both | pf8-hp | 14.98 [11.14–15.47] | +15.2 % | no difference | +14.4 % | +12.3 % | +91.8 % |

German words are on disk, so a German batch has few in-RAM hits: prefetching the in-RAM words has little to do, while every probe still touches the directory, which huge pages make cheaper (dTLB misses −17.5 %).
