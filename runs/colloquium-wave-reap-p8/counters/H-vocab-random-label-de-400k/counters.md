| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| base | warm | - | 2401735 | 677443 (677443/0) | 0 | 0 | 3067904 | 2 | 9.42 | 55933143098 | 37499770 |
| wave | warm | - | 2401735 | 677443 (677443/0) | 0 | 0 | 3063808 | 2 | 11.19 | 55971783188 | 37499770 |
| base | cold | - | 2401735 | 677443 (677443/450800) | 0 | 279231 | 4162146304 | 1 | 55.48 | 56188368089 | 37499770 |
| wave | cold | - | 2401735 | 677443 (677443/450376) | 0 | 2100 | 4162723840 | 1 | 54.35 | 56240376360 | 37499770 |

I/O pattern base (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=279231 batch_med=1 batch_sum=451757

I/O pattern wave (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=2101 batch_med=256 batch_sum=451333

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
