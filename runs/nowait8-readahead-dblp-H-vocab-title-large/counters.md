| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| on | warm | vocabulary-iouring-page-cache-fast-path=true vocabulary-bench-fadvise-random=false | 167 | 194665 (194665/0) | 0 | 0 | 0 | 0 | 0.6 | - | 15532320 |
| off | warm | vocabulary-iouring-page-cache-fast-path=false vocabulary-bench-fadvise-random=false | 167 | 0 (0/0) | 0 | 296812 | 0 | 0 | 4.29 | - | 15532320 |
| on-fadvrandom | warm | vocabulary-iouring-page-cache-fast-path=true vocabulary-bench-fadvise-random=true | 167 | 194665 (194665/0) | 0 | 0 | 0 | 0 | 0.61 | - | 15532320 |
| off-fadvrandom | warm | vocabulary-iouring-page-cache-fast-path=false vocabulary-bench-fadvise-random=true | 167 | 0 (0/0) | 0 | 296812 | 0 | 0 | 4.01 | - | 15532320 |
| on | cold | vocabulary-iouring-page-cache-fast-path=true vocabulary-bench-fadvise-random=false | 167 | 194665 (194665/53647) | 0 | 27398 | 693587968 | 1 | 2.51 | - | 15532320 |
| off | cold | vocabulary-iouring-page-cache-fast-path=false vocabulary-bench-fadvise-random=false | 167 | 0 (0/0) | 0 | 296812 | 712167424 | 1 | 5.09 | - | 15532320 |
| on-fadvrandom | cold | vocabulary-iouring-page-cache-fast-path=true vocabulary-bench-fadvise-random=true | 167 | 194665 (194665/74244) | 0 | 165904 | 301215744 | 1 | 4.38 | - | 15532320 |
| off-fadvrandom | cold | vocabulary-iouring-page-cache-fast-path=false vocabulary-bench-fadvise-random=true | 167 | 0 (0/0) | 0 | 296812 | 301211648 | 1 | 5.01 | - | 15532320 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
