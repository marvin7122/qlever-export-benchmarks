| query | scenario | arm | user s/query | sys s/query | io_uring_enter/query | read syscalls/query |
|---|---|---|---|---|---|---|
| H-vocab-label-large-select | cold | today (legacy export, rank off) | 39.4 | 0.6 | 0 | 9848 |
| H-vocab-label-large-select | cold | idea 3: v2, rank off | 35.5 | 0.9 | 0 | 9835 |
| H-vocab-label-large-select | cold | ideas 2+3: v2, rank on | 17.6 | 0.9 | 0 | 9833 |
| H-vocab-label-large-select | cold | ideas 2+3 + prefetch 16 + huge pages | 16.6 | 0.9 | 0 | 9833 |
| H-vocab-label-large-select | warm | today (legacy export, rank off) | 38.4 | 0.5 | 0 | 9848 |
| H-vocab-label-large-select | warm | idea 3: v2, rank off | 34.2 | 1.0 | 0 | 9834 |
| H-vocab-label-large-select | warm | ideas 2+3: v2, rank on | 16.2 | 0.7 | 0 | 9832 |
| H-vocab-label-large-select | warm | ideas 2+3 + prefetch 16 + huge pages | 13.2 | 0.6 | 0 | 9831 |
| H-vocab-label-large-de-select | cold | today (legacy export, rank off) | 21.2 | 23.8 | 0 | 9034282 |
| H-vocab-label-large-de-select | cold | idea 3: v2, rank off | 15.1 | 27.0 | 5788878 | 1049380 |
| H-vocab-label-large-de-select | cold | ideas 2+3: v2, rank on | 8.9 | 27.3 | 5789258 | 1046672 |
| H-vocab-label-large-de-select | cold | ideas 2+3 + prefetch 16 + huge pages | 8.2 | 27.6 | 5785681 | 1054112 |
| H-vocab-label-large-de-select | warm | today (legacy export, rank off) | 16.3 | 9.7 | 0 | 9034243 |
| H-vocab-label-large-de-select | warm | idea 3: v2, rank off | 12.1 | 11.3 | 0 | 9034234 |
| H-vocab-label-large-de-select | warm | ideas 2+3: v2, rank on | 6.0 | 11.4 | 0 | 9034233 |
| H-vocab-label-large-de-select | warm | ideas 2+3 + prefetch 16 + huge pages | 6.0 | 11.4 | 0 | 9034233 |
