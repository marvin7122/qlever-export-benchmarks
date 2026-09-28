| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| p14-3476 | warm | - | 1438 | 246946 (246946/0) | 0 | 0 | 0 | 0 | 1.92 | - | 61418523 |
| p15-3477 | warm | - | 1438 | 246970 (246970/0) | 0 | 0 | 0 | 0 | 1.54 | - | 61418523 |
| p16-3499 | warm | - | 1438 | 246970 (246970/0) | 0 | 0 | 0 | 0 | 1.56 | - | 61418523 |
| p14-3476 | cold | - | 1438 | 246946 (246946/41487) | 0 | 1334 | 464060416 | 1 | 2.57 | - | 61418523 |
| p15-3477 | cold | - | 1438 | 246970 (246970/41351) | 0 | 1324 | 462856192 | 1 | 2.67 | - | 61418523 |
| p16-3499 | cold | - | 1438 | 246970 (246970/41670) | 0 | 1332 | 460492800 | 1 | 3.1 | - | 61418523 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
