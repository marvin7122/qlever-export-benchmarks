| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| base | cold | - | 2401735 | 677443 (677443/458104) | 0 | 286735 | 4163108864 | 3 | 19.81 | 56180798165 | 37499770 |
| wave | cold | - | 2401735 | 677443 (677443/458203) | 0 | 2126 | 4163239936 | 5 | 19.6 | 55849542975 | 37499770 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
