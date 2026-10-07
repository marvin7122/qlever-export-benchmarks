# Prefetch distance sweep (rank lookup on), English labels warm

Part of the prefetch / huge-page experiment for fork PR marvin7122/qlever#264; setup, binaries, counters and the full story are in [`internal-rank-best-en-p12`](../internal-rank-best-en-p12/README.md).
Ural queue entry #5362, 2026-10-07, uncompressed responses, variant binary `6770bbf2c7e4a06793c31eff504b9526ac530c96`, 3 interleaved trials per arm, no load wait (pr-ab-grid.sh records no per-trial load).
All bodies of a cell are identical (`correctness.tsv`); postflight gates PASS (`gate-postflight-*.log`).
Table: `aggregate-counters.md` (from `internal-rank-lookup-aggregate2.py`; counters are per query, deltas vs the reference arm).
Binaries are not included.

## Result

| # | concern | arm | wall s median [min–max] | Δ vs d0 | Δ cycles | Δ DRAM refills |
|---|---|---|---|---|---|---|
| 1 | reference: no prefetch | d0 | 24.81 [13.68–25.69] | | | |
| 2 | distance 4 | d4 | 22.56 [15.78–22.59] | −9.1 % | −8.3 % | −13.8 % |
| 3 | distance 8 (chosen) | d8 | 21.91 [12.53–22.29] | −11.7 % | −10.1 % | −15.9 % |
| 4 | distance 16 | d16 | 22.12 [11.65–22.14] | −10.8 % | −9.9 % | −13.7 % |
| 5 | distance 32 | d32 | 22.38 [16.15–22.68] | −9.8 % | −8.8 % | −12.8 % |

All ranges overlap with d0 (one fast outlier per arm, 11.7–16.2 s), so no arm is "faster" by the rule; the medians and the DRAM refill counts agree on a 9–12 % gain for every distance ≥ 4.
