| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | cycles | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| wave | warm | - | 2633 | 8878901 (8878901/0) | 0 | 0 | 0 | 0 | 184.88 | 540160910756 | 55361188954 | 504927346 |
| base | warm | - | 2633 | 8878901 (8878901/0) | 0 | 0 | 3162112 | 2 | 177.82 | 510553118848 | 52608194963 | 504927346 |
| wave | cold | - | 2633 | 8878901 (8878901/569300) | 0 | 9525 | 9458913280 | 5 | 168.47 | 480697606831 | 61305595948 | 504927346 |
| base | cold | - | 2633 | 8878901 (8878901/565882) | 0 | 154652 | 9466544128 | 7 | 190.29 | 557194010164 | 61511964223 | 504927346 |

I/O pattern wave (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=0 batch_med=0 batch_sum=0

I/O pattern base (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=0 batch_med=0 batch_sum=0

I/O pattern wave (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=9543 batch_med=24 batch_sum=569829

I/O pattern base (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=154666 batch_med=1 batch_sum=566401

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
