| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| p14-3476 | warm | - | 167 | 195266 (195266/0) | 0 | 0 | 0 | 0 | 0.71 | - | 15532320 |
| p15-3477 | warm | - | 167 | 195264 (195264/0) | 0 | 0 | 3072000 | 2 | 0.67 | - | 15532320 |
| p16-3499 | warm | - | 167 | 195264 (195264/0) | 0 | 0 | 1863680 | 2 | 0.86 | - | 15532320 |
| p14-3476 | cold | - | 167 | 195266 (195266/53941) | 0 | 744 | 688611328 | 1 | 2.51 | - | 15532320 |
| p15-3477 | cold | - | 167 | 195264 (195264/54061) | 0 | 746 | 704454656 | 1 | 2.6 | - | 15532320 |
| p16-3499 | cold | - | 167 | 195264 (195264/54166) | 0 | 747 | 699604992 | 1 | 3.03 | - | 15532320 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
