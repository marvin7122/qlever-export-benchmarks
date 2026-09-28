| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| p2-3521 | warm | - | 199229 | 0 (0/0) | 0 | 0 | 0 | 0 | 0.91 | - | 15532320 |
| p3-3522 | warm | - | 199229 | 0 (0/0) | 0 | 0 | 0 | 0 | 0.89 | - | 15532320 |
| p4-3523 | warm | - | 199229 | 0 (0/0) | 0 | 0 | 0 | 0 | 0.9 | - | 15532320 |
| p5-3524 | warm | - | 199229 | 0 (0/0) | 0 | 0 | 0 | 0 | 0.88 | - | 15532320 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
