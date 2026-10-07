| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | cycles | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| base | warm | - | 2633 | 8878901 (8878901/0) | 0 | 0 | 1945600 | 1 | 31.01 | 125046994745 | 86395871217 | 504927346 |
| wave | warm | - | 2633 | 8878901 (8878901/0) | 0 | 0 | 3158016 | 2 | 30.96 | 120502774753 | 77795919577 | 504927346 |
| base-fpoff | warm | vocabulary-iouring-page-cache-fast-path=false | 2633 | 0 (0/0) | 0 | 6625868 | 0 | 0 | 30.09 | 117772071227 | 74455213870 | 504927346 |
| wave-fpoff | warm | vocabulary-iouring-page-cache-fast-path=false | 2633 | 0 (0/0) | 0 | 35302 | 0 | 0 | 25.68 | 101834350708 | 68916640040 | 504927346 |
| base | cold | - | 2633 | 8878901 (8878901/583634) | 0 | 166746 | 9446985728 | 7 | 35.74 | 143582430592 | 86361974216 | 504927346 |
| wave | cold | - | 2633 | 8878901 (8878901/584236) | 0 | 9570 | 9446846464 | 5 | 34.38 | 138822248335 | 86412778314 | 504927346 |
| base-fpoff | cold | vocabulary-iouring-page-cache-fast-path=false | 2633 | 0 (0/0) | 0 | 6625868 | 9447989248 | 5 | 35.09 | 141436432747 | 82635746806 | 504927346 |
| wave-fpoff | cold | vocabulary-iouring-page-cache-fast-path=false | 2633 | 0 (0/0) | 0 | 40939 | 9440641024 | 5 | 28.51 | 116112238811 | 74486032367 | 504927346 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
