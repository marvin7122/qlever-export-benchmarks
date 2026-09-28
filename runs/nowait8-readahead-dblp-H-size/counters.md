| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| on | warm | vocabulary-iouring-page-cache-fast-path=true vocabulary-bench-fadvise-random=false | 1438 | 246926 (246926/0) | 0 | 0 | 0 | 0 | 1.38 | - | 61418523 |
| off | warm | vocabulary-iouring-page-cache-fast-path=false vocabulary-bench-fadvise-random=false | 1438 | 0 (0/0) | 0 | 8384 | 0 | 0 | 3.77 | - | 61418523 |
| on-fadvrandom | warm | vocabulary-iouring-page-cache-fast-path=true vocabulary-bench-fadvise-random=true | 1438 | 246926 (246926/0) | 0 | 0 | 0 | 0 | 1.51 | - | 61418523 |
| off-fadvrandom | warm | vocabulary-iouring-page-cache-fast-path=false vocabulary-bench-fadvise-random=true | 1438 | 0 (0/0) | 0 | 8384 | 0 | 0 | 4.1 | - | 61418523 |
| on | cold | vocabulary-iouring-page-cache-fast-path=true vocabulary-bench-fadvise-random=false | 1438 | 246926 (246926/41732) | 0 | 1344 | 463831040 | 1 | 2.53 | - | 61418523 |
| off | cold | vocabulary-iouring-page-cache-fast-path=false vocabulary-bench-fadvise-random=false | 1438 | 0 (0/0) | 0 | 8384 | 479666176 | 1 | 4.92 | - | 61418523 |
| on-fadvrandom | cold | vocabulary-iouring-page-cache-fast-path=true vocabulary-bench-fadvise-random=true | 1438 | 246926 (246926/53234) | 0 | 1729 | 281640960 | 1 | 2.71 | - | 61418523 |
| off-fadvrandom | cold | vocabulary-iouring-page-cache-fast-path=false vocabulary-bench-fadvise-random=true | 1438 | 0 (0/0) | 0 | 8384 | 281640960 | 1 | 4.58 | - | 61418523 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
