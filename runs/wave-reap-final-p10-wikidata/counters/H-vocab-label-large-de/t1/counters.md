| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | cycles | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| base | warm | - | 2633 | 8878901 (8878901/0) | 0 | 0 | 3162112 | 2 | 181.43 | 532104438080 | 60925166280 | 504927346 |
| wave | warm | - | 2633 | 8878901 (8878901/0) | 0 | 0 | 3158016 | 2 | 184.99 | 541379546894 | 61549283115 | 504927346 |
| base | cold | - | 2633 | 8878901 (8878901/567175) | 0 | 154994 | 9460088832 | 7 | 174.72 | 497552612603 | 61511978806 | 504927346 |
| wave | cold | - | 2633 | 8878901 (8878901/569952) | 0 | 9527 | 9463726080 | 5 | 190.58 | 561139281687 | 61312144288 | 504927346 |

I/O pattern base (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=0 batch_med=0 batch_sum=0

I/O pattern wave (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=0 batch_med=0 batch_sum=0

I/O pattern base (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=155009 batch_med=1 batch_sum=567704

I/O pattern wave (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=9551 batch_med=24 batch_sum=570482

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
