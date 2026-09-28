| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| p2-3521 | warm | - | 143367 | 0 (0/0) | 0 | 0 | 0 | 0 | 1.32 | - | 61418523 |
| p3-3522 | warm | - | 143367 | 0 (0/0) | 0 | 0 | 0 | 0 | 1.53 | - | 61418523 |
| p4-3523 | warm | - | 143367 | 0 (0/0) | 0 | 0 | 0 | 0 | 1.56 | - | 61418523 |
| p5-3524 | warm | - | 143367 | 0 (0/0) | 0 | 0 | 0 | 0 | 1.33 | - | 61418523 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
