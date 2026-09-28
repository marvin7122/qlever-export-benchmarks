| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| p10-3528 | warm | - | 1438 | 246926 (246926/0) | 0 | 0 | 0 | 0 | 1.53 | - | 61418523 |
| p11-3529-off | warm | use-fast-export-stream-formatter=false | 1438 | 246926 (246926/0) | 0 | 0 | 0 | 0 | 1.6 | - | 61418523 |
| p11-3529-on | warm | use-fast-export-stream-formatter=true | 1438 | 246926 (246926/0) | 0 | 0 | 0 | 0 | 1.31 | - | 61418523 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
