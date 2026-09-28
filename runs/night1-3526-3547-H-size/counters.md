| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| p6-3525 | warm | - | 143367 | 0 (0/0) | 0 | 0 | 0 | 0 | 1.64 | - | 61418523 |
| p7-3526 | warm | - | 1350 | 0 (0/0) | 0 | 8384 | 0 | 0 | 3.81 | - | 61418523 |
| p8-3547-on | warm | vocabulary-iouring-page-cache-fast-path=true | 1438 | 246926 (246926/0) | 0 | 0 | 0 | 0 | 1.53 | - | 61418523 |
| p8-3547-off | warm | vocabulary-iouring-page-cache-fast-path=false | 1438 | 0 (0/0) | 0 | 8384 | 0 | 0 | 3.68 | - | 61418523 |
| p6-3525 | cold | - | 143367 | 0 (0/0) | 0 | 0 | 487161856 | 2 | 2.42 | - | 61418523 |
| p7-3526 | cold | - | 1350 | 0 (0/0) | 0 | 8384 | 466006016 | 1 | 5.2 | - | 61418523 |
| p8-3547-on | cold | vocabulary-iouring-page-cache-fast-path=true | 1438 | 246926 (246926/41588) | 0 | 1337 | 467136512 | 1 | 2.97 | - | 61418523 |
| p8-3547-off | cold | vocabulary-iouring-page-cache-fast-path=false | 1438 | 0 (0/0) | 0 | 8384 | 475049984 | 1 | 4.94 | - | 61418523 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
