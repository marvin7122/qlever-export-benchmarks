| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| p10-3528 | warm | - | 167 | 194665 (194665/0) | 0 | 0 | 3063808 | 2 | 0.71 | - | 15532320 |
| p11-3529-off | warm | use-fast-export-stream-formatter=false | 167 | 194665 (194665/0) | 0 | 0 | 3067904 | 2 | 0.67 | - | 15532320 |
| p11-3529-on | warm | use-fast-export-stream-formatter=true | 167 | 194665 (194665/0) | 0 | 0 | 0 | 0 | 0.66 | - | 15532320 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
