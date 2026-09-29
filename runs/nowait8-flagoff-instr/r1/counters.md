| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| p7-3526 | warm | - | 601720 | 0 (0/0) | 0 | 263576 | 0 | 0 | 4.85 | 29318941734 | 19297737 |
| p8-off | warm | vocabulary-iouring-page-cache-fast-path=false | 1201735 | 0 (0/0) | 0 | 263576 | 3067904 | 2 | 5.06 | 30418954836 | 19297737 |
| p8-on | warm | vocabulary-iouring-page-cache-fast-path=true | 1201735 | 348919 (348919/0) | 0 | 0 | 0 | 0 | 5.04 | 30325420733 | 19297737 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
