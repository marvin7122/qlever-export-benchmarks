| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| p8-off | warm | vocabulary-iouring-page-cache-fast-path=false | 1201735 | 0 (0/0) | 0 | 263576 | 0 | 0 | 5.28 | 30216779181 | 19297737 |
| p8-on | warm | vocabulary-iouring-page-cache-fast-path=true | 1201735 | 348919 (348919/0) | 0 | 0 | 0 | 0 | 4.87 | 30363709650 | 19297737 |
| p7-3526 | warm | - | 601720 | 0 (0/0) | 0 | 263576 | 0 | 0 | 4.78 | 29500049597 | 19297737 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
