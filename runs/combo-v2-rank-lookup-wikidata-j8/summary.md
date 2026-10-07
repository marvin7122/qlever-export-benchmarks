| query | scenario | arm | n | wall s median [min–max] | CPU s median | busy cores median [min–max] | loop n | read MB median | io_uring_enter median | rows multiset = today |
|---|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de-select | cold | today (legacy export, rank off) | 3 | 102.46 [74.02–102.86] | 44.91 | 0.44 [0.44–0.45] | 1 | 9484 | 0 | 3/3 |
| H-vocab-label-large-de-select | cold | idea 3: v2, rank off | 3 | 10.58 [5.26–11.17] | 42.41 | 3.92 [3.80–8.16] | 1 | 9392 | 5788878 | 3/3 |
| H-vocab-label-large-de-select | cold | ideas 2+3: v2, rank on | 3 | 8.78 [4.59–9.40] | 36.35 | 4.00 [3.90–7.92] | 1 | 9417 | 5789258 | 3/3 |
| H-vocab-label-large-de-select | cold | ideas 2+3 + prefetch 16 + huge pages | 3 | 4.65 [4.55–8.66] | 35.86 | 7.87 [3.94–7.88] | 1 | 9376 | 5785681 | 3/3 |
| H-vocab-label-large-de-select | warm | today (legacy export, rank off) | 3 | 25.32 [24.03–25.50] | 26.01 | 1.03 [1.03–1.03] | 1 | 0 | 0 | 3/3 |
| H-vocab-label-large-de-select | warm | idea 3: v2, rank off | 3 | 5.53 [5.26–5.89] | 23.40 | 4.23 [3.93–4.50] | 2 | 0 | 0 | 3/3 |
| H-vocab-label-large-de-select | warm | ideas 2+3: v2, rank on | 3 | 4.33 [2.12–4.35] | 17.34 | 4.07 [3.92–8.19] | 3 | 0 | 0 | 3/3 |
| H-vocab-label-large-de-select | warm | ideas 2+3 + prefetch 16 + huge pages | 3 | 4.14 [2.33–4.45] | 17.25 | 4.17 [3.94–7.37] | 3 | 0 | 0 | 3/3 |
| H-vocab-label-large-select | cold | today (legacy export, rank off) | 3 | 37.67 [34.25–38.52] | 39.99 | 1.06 [1.06–1.08] | 1 | 511 | 0 | 3/3 |
| H-vocab-label-large-select | cold | idea 3: v2, rank off | 3 | 9.70 [5.57–9.82] | 36.27 | 3.76 [3.69–6.21] | 1 | 511 | 0 | 3/3 |
| H-vocab-label-large-select | cold | ideas 2+3: v2, rank on | 3 | 5.79 [3.54–7.03] | 18.55 | 3.20 [3.10–4.93] | 1 | 511 | 0 | 3/3 |
| H-vocab-label-large-select | cold | ideas 2+3 + prefetch 16 + huge pages | 3 | 5.59 [3.40–5.74] | 17.59 | 3.23 [3.06–4.89] | 1 | 511 | 0 | 3/3 |
| H-vocab-label-large-select | warm | today (legacy export, rank off) | 3 | 36.34 [27.13–36.88] | 39.00 | 1.07 [1.07–1.09] | 1 | 0 | 0 | 3/3 |
| H-vocab-label-large-select | warm | idea 3: v2, rank off | 3 | 8.30 [3.39–8.48] | 35.16 | 4.24 [4.18–9.44] | 2 | 0 | 0 | 3/3 |
| H-vocab-label-large-select | warm | ideas 2+3: v2, rank on | 3 | 2.73 [2.03–5.20] | 16.89 | 6.19 [3.49–7.45] | 4 | 0 | 0 | 3/3 |
| H-vocab-label-large-select | warm | ideas 2+3 + prefetch 16 + huge pages | 3 | 1.99 [1.96–4.10] | 13.73 | 6.85 [4.13–6.90] | 6 | 0 | 0 | 3/3 |
