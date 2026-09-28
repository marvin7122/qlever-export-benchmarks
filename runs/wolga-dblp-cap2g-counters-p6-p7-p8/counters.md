| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| p6-3525 | warm | - | 199229 | 0 (0/0) | 0 | 0 | 0 | 0 | 0.75 | - | 15532320 |
| p7-3526 | warm | - | 123 | 0 (0/0) | 0 | 296812 | 0 | 1 | 4.16 | - | 15532320 |
| p8-3547-on | warm | vocabulary-iouring-page-cache-fast-path=true | 167 | 194665 (194665/0) | 0 | 0 | 0 | 0 | 0.63 | - | 15532320 |
| p8-3547-off | warm | vocabulary-iouring-page-cache-fast-path=false | 167 | 0 (0/0) | 0 | 296812 | 0 | 0 | 3.98 | - | 15532320 |
| p6-3525 | cold | - | 199229 | 0 (0/0) | 0 | 0 | 743403520 | 2 | 1.25 | - | 15532320 |
| p7-3526 | cold | - | 123 | 0 (0/0) | 0 | 296812 | 722829312 | 1 | 5.15 | - | 15532320 |
| p8-3547-on | cold | vocabulary-iouring-page-cache-fast-path=true | 167 | 194665 (194665/53807) | 0 | 27547 | 699555840 | 1 | 2.53 | - | 15532320 |
| p8-3547-off | cold | vocabulary-iouring-page-cache-fast-path=false | 167 | 0 (0/0) | 0 | 296812 | 717279232 | 1 | 5.22 | - | 15532320 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
