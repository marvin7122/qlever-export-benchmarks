| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| p11-3529 | warm | - | 167 | 194665 (194665/0) | 0 | 0 | 0 | 0 | 0.64 | - | 15532320 |
| p12-3539-off | warm | adaptive-export-chunk-size=false | 167 | 194665 (194665/0) | 0 | 0 | 3067904 | 2 | 0.65 | - | 15532320 |
| p12-3539-on | warm | adaptive-export-chunk-size=true | 167 | 194665 (194665/0) | 0 | 0 | 0 | 0 | 0.63 | - | 15532320 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
