| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | cycles | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| base | warm | - | 2633 | 8878901 (8878901/0) | 0 | 0 | 0 | 0 | 184.0 | 536342864163 | 52608275718 | 504927346 |
| wave | warm | - | 2633 | 8878901 (8878901/0) | 0 | 0 | 3158016 | 2 | 183.1 | 535086459143 | 52607851865 | 504927346 |
| base | cold | - | 2633 | 8878901 (8878901/568326) | 0 | 155819 | 9456046080 | 5 | 169.32 | 478749577486 | 61518178129 | 504927346 |
| wave | cold | - | 2633 | 8878901 (8878901/569896) | 0 | 9527 | 9449254912 | 7 | 185.39 | 543130059381 | 61312982562 | 504927346 |

I/O pattern base (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=0 batch_med=0 batch_sum=0

I/O pattern wave (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=0 batch_med=0 batch_sum=0

I/O pattern base (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=155834 batch_med=1 batch_sum=568857

I/O pattern wave (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=9553 batch_med=24 batch_sum=570428

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
