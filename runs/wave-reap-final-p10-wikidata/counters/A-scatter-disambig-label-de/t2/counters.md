| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | cycles | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| wave | warm | - | 1859 | 1399318 (1399318/0) | 0 | 0 | 3158016 | 2 | 22.84 | 60821385444 | 8934920481 | 74413425 |
| base | warm | - | 1859 | 1399318 (1399318/0) | 0 | 0 | 0 | 0 | 24.87 | 66773429847 | 8066401988 | 74413425 |
| wave | cold | - | 1859 | 1399318 (1399318/810588) | 0 | 3864 | 6840836096 | 5 | 30.6 | 94709484652 | 12242607429 | 74413425 |
| base | cold | - | 1859 | 1399318 (1399318/810267) | 0 | 469407 | 6835445760 | 5 | 38.81 | 114503843794 | 12830427305 | 74413425 |

I/O pattern wave (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=0 batch_med=0 batch_sum=0

I/O pattern base (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=0 batch_med=0 batch_sum=0

I/O pattern wave (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=3871 batch_med=256 batch_sum=811967

I/O pattern base (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=469408 batch_med=1 batch_sum=811681

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
