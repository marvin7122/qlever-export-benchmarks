| scenario | query | arm | n | wall s median [min–max] | Δ wall | verdict | Gcyc/query | Δ | M DRAM refills/query | Δ | M dTLB misses/query | Δ | M cache misses/query | Δ | checksums |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| cold | H-vocab-label-large | rank | 3 | 24.99 [24.53–26.06] |  | reference | 111.8 |  | 171.0 |  | 351.9 |  | 900.2 |  | 1 |
| cold | H-vocab-label-large | hp | 3 | 24.52 [23.93–25.60] | -1.9 % | no difference | 110.0 | -1.6 % | 170.8 | -0.1 % | 348.4 | -1.0 % | 923.4 | +2.6 % | 1 |
| cold | H-vocab-label-large | pf8 | 3 | 22.21 [21.61–22.21] | -11.1 % | faster | 100.5 | -10.1 % | 143.9 | -15.8 % | 344.8 | -2.0 % | 936.5 | +4.0 % | 1 |
| cold | H-vocab-label-large | pf8-hp | 3 | 21.82 [21.56–21.84] | -12.7 % | faster | 99.0 | -11.4 % | 144.4 | -15.6 % | 349.1 | -0.8 % | 906.5 | +0.7 % | 1 |
| warm | H-vocab-label-large | rank | 3 | 22.55 [17.86–25.17] |  | reference | 103.1 |  | 158.6 |  | 290.1 |  | 863.7 |  | 1 |
| warm | H-vocab-label-large | hp | 3 | 18.99 [14.21–24.45] | -15.8 % | no difference | 88.0 | -14.6 % | 135.3 | -14.7 % | 242.3 | -16.5 % | 803.8 | -6.9 % | 1 |
| warm | H-vocab-label-large | pf8 | 3 | 14.53 [12.41–17.97] | -35.6 % | no difference | 68.8 | -33.2 % | 80.7 | -49.1 % | 223.0 | -23.1 % | 824.7 | -4.5 % | 1 |
| warm | H-vocab-label-large | pf8-hp | 3 | 21.65 [14.77–21.91] | -4.0 % | no difference | 98.2 | -4.7 % | 140.9 | -11.2 % | 384.0 | +32.4 % | 955.6 | +10.6 % | 1 |
