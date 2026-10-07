| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | cycles | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| base | warm | - | 1859 | 1399318 (1399318/0) | 0 | 0 | 3162112 | 2 | 24.56 | 64051033881 | 8942387541 | 74413425 |
| wave | warm | - | 1859 | 1399318 (1399318/0) | 0 | 0 | 0 | 0 | 23.98 | 63962107412 | 8065101241 | 74413425 |
| base | cold | - | 1859 | 1399318 (1399318/809976) | 0 | 468948 | 6863216640 | 5 | 38.14 | 113236266685 | 12840372699 | 74413425 |
| wave | cold | - | 1859 | 1399318 (1399318/809613) | 0 | 3865 | 6833537024 | 5 | 32.57 | 100177925540 | 12240465042 | 74413425 |

I/O pattern base (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=0 batch_med=0 batch_sum=0

I/O pattern wave (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=0 batch_med=0 batch_sum=0

I/O pattern base (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=468948 batch_med=1 batch_sum=811357

I/O pattern wave (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=3875 batch_med=256 batch_sum=811017

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
