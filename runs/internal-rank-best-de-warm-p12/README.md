# Base vs best arm vs rank, German labels warm

Part of the prefetch / huge-page experiment for fork PR marvin7122/qlever#264; setup, binaries, counters and the full story are in [`internal-rank-best-en-p12`](../internal-rank-best-en-p12/README.md).
Ural queue entry #5362, 2026-10-07, uncompressed responses, variant binary `6770bbf2c7e4a06793c31eff504b9526ac530c96`, 3 interleaved trials per arm, no load wait; max load1 during trials 4.0–19.7 (`rep-load.tsv`).
All bodies of a cell are identical (`correctness.tsv`); postflight gates PASS (`gate-postflight-*.log`).
Table: `aggregate-counters.md` (from `internal-rank-lookup-aggregate2.py`; counters are per query, deltas vs the reference arm).
Binaries are not included.

## Result

| # | concern | arm | wall s median [min–max] | Δ vs base | verdict | Δ cycles | Δ DRAM refills | Δ dTLB misses |
|---|---|---|---|---|---|---|---|---|
| 1 | reference | base `d20a4c74` | 23.77 [19.94–23.79] | | | | | |
| 2 | best English arm on German | rank + prefetch 8 (`variant`) | 18.07 [11.91–18.13] | −24.0 % | faster | −23.6 % | −61.7 % | −35.8 % |
| 3 | rank lookup | rank (`variant2`) | 15.36 [12.15–18.29] | −35.4 % | faster | −32.9 % | −64.7 % | −54.9 % |

Rank vs rank + prefetch overlap here (see the German factorial).
