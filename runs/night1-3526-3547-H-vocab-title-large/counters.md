| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| p6-3525 | warm | - | 199229 | 0 (0/0) | 0 | 0 | 3055616 | 2 | 0.89 | - | 15532320 |
| p7-3526 | warm | - | 123 | 0 (0/0) | 0 | 296812 | 3059712 | 2 | 3.84 | - | 15532320 |
| p8-3547-on | warm | vocabulary-iouring-page-cache-fast-path=true | 167 | 194665 (194665/0) | 0 | 0 | 3067904 | 2 | 0.75 | - | 15532320 |
| p8-3547-off | warm | vocabulary-iouring-page-cache-fast-path=false | 167 | 0 (0/0) | 0 | 296812 | 0 | 0 | 3.67 | - | 15532320 |
| p6-3525 | cold | - | 199229 | 0 (0/0) | 0 | 0 | 743403520 | 2 | 1.89 | - | 15532320 |
| p7-3526 | cold | - | 123 | 0 (0/0) | 0 | 296812 | 713068544 | 1 | 5.44 | - | 15532320 |
| p8-3547-on | cold | vocabulary-iouring-page-cache-fast-path=true | 167 | 194665 (194665/53827) | 0 | 27429 | 699731968 | 1 | 2.5 | - | 15532320 |
| p8-3547-off | cold | vocabulary-iouring-page-cache-fast-path=false | 167 | 0 (0/0) | 0 | 296812 | 714428416 | 1 | 5.4 | - | 15532320 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
