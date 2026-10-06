| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| base | warm | - | 2633 | 8878901 (8878901/0) | 0 | 0 | 3067904 | 2 | 22.17 | 79640445730 | 504927346 |
| wave | warm | - | 2633 | 8878901 (8878901/0) | 0 | 0 | 0 | 0 | 20.92 | 79638324514 | 504927346 |
| base | cold | - | 2633 | 8878901 (8878901/571217) | 0 | 157386 | 9452675072 | 3 | 139.48 | 88560644855 | 504927346 |
| wave | cold | - | 2633 | 8878901 (8878901/571635) | 0 | 9533 | 9459834880 | 5 | 134.93 | 88355064201 | 504927346 |

I/O pattern base (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=157424 batch_med=1 batch_sum=571744

I/O pattern wave (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=9570 batch_med=24 batch_sum=572167

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
