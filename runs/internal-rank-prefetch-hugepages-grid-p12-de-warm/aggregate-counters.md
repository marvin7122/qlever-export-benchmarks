| scenario | query | arm | n | wall s median [min–max] | Δ wall | verdict | Gcyc/query | Δ | M DRAM refills/query | Δ | M dTLB misses/query | Δ | M cache misses/query | Δ | checksums |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| warm | H-vocab-label-large-de | rank | 3 | 13.00 [12.96–14.98] |  | reference | 56.5 |  | 65.5 |  | 84.4 |  | 366.1 |  | 1 |
| warm | H-vocab-label-large-de | hp | 3 | 12.05 [11.59–12.12] | -7.3 % | faster | 53.1 | -6.0 % | 55.4 | -15.5 % | 69.6 | -17.5 % | 350.8 | -4.2 % | 1 |
| warm | H-vocab-label-large-de | pf8 | 3 | 12.91 [11.85–13.83] | -0.7 % | no difference | 55.8 | -1.2 % | 65.5 | -0.0 % | 83.9 | -0.6 % | 362.9 | -0.9 % | 1 |
| warm | H-vocab-label-large-de | pf8-hp | 3 | 14.98 [11.14–15.47] | +15.2 % | no difference | 64.6 | +14.4 % | 73.5 | +12.3 % | 161.9 | +91.8 % | 421.8 | +15.2 % | 1 |
