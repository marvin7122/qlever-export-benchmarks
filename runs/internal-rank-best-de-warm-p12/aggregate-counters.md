| scenario | query | arm | n | wall s median [min–max] | Δ wall | verdict | Gcyc/query | Δ | M DRAM refills/query | Δ | M dTLB misses/query | Δ | M cache misses/query | Δ | checksums |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| warm | H-vocab-label-large-de | base | 3 | 23.77 [19.94–23.79] |  | reference | 98.5 |  | 224.9 |  | 370.5 |  | 701.1 |  | 1 |
| warm | H-vocab-label-large-de | variant | 3 | 18.07 [11.91–18.13] | -24.0 % | faster | 75.3 | -23.6 % | 86.1 | -61.7 % | 237.9 | -35.8 % | 438.2 | -37.5 % | 1 |
| warm | H-vocab-label-large-de | variant2 | 3 | 15.36 [12.15–18.29] | -35.4 % | faster | 66.1 | -32.9 % | 79.3 | -64.7 % | 167.3 | -54.9 % | 419.2 | -40.2 % | 1 |
