| scenario | query | arm | n | wall s median [min–max] | Δ wall | verdict | Gcyc/query | Δ | M DRAM refills/query | Δ | M dTLB misses/query | Δ | M cache misses/query | Δ | checksums |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| cold | H-vocab-label-large | base | 3 | 38.66 [38.47–38.93] |  | reference | 166.1 |  | 555.4 |  | 682.7 |  | 1700.6 |  | 1 |
| cold | H-vocab-label-large | variant | 3 | 21.53 [20.66–22.24] | -44.3 % | faster | 97.5 | -41.3 % | 137.4 | -75.3 % | 346.0 | -49.3 % | 906.9 | -46.7 % | 1 |
| cold | H-vocab-label-large | variant2 | 3 | 24.59 [24.53–25.00] | -36.4 % | faster | 109.9 | -33.8 % | 168.9 | -69.6 % | 339.2 | -50.3 % | 890.0 | -47.7 % | 1 |
| warm | H-vocab-label-large | base | 3 | 38.68 [38.46–39.31] |  | reference | 166.4 |  | 558.4 |  | 724.4 |  | 1773.3 |  | 1 |
| warm | H-vocab-label-large | variant | 3 | 16.52 [13.65–17.80] | -57.3 % | faster | 78.9 | -52.6 % | 99.4 | -82.2 % | 257.3 | -64.5 % | 909.9 | -48.7 % | 1 |
| warm | H-vocab-label-large | variant2 | 3 | 16.80 [16.07–17.65] | -56.6 % | faster | 79.5 | -52.2 % | 104.0 | -81.4 % | 225.3 | -68.9 % | 799.2 | -54.9 % | 1 |
