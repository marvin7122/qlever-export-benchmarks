| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| p11-3529 | warm | - | 1438 | 246926 (246926/0) | 0 | 0 | 0 | 0 | 1.59 | - | 61418523 |
| p12-3539-off | warm | adaptive-export-chunk-size=false | 1438 | 246926 (246926/0) | 0 | 0 | 0 | 0 | 1.51 | - | 61418523 |
| p12-3539-on | warm | adaptive-export-chunk-size=true | 1438 | 246926 (246926/0) | 0 | 0 | 0 | 0 | 1.47 | - | 61418523 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
