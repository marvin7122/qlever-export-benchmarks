| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| base | warm | - | 1201735 | 348919 (348919/0) | 0 | 0 | 3067904 | 2 | 5.31 | 30388858550 | 19297737 |
| wave | warm | - | 1201735 | 348919 (348919/0) | 0 | 0 | 0 | 0 | 5.01 | 30335222593 | 19297737 |
| base | cold | - | 1201735 | 348919 (348919/258728) | 0 | 170570 | 3000774656 | 3 | 28.95 | 30699611557 | 19297737 |
| wave | cold | - | 1201735 | 348919 (348919/258778) | 0 | 1193 | 3002019840 | 3 | 26.59 | 30461298255 | 19297737 |

I/O pattern base (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=170570 batch_med=1 batch_sum=259310

I/O pattern wave (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=1194 batch_med=256 batch_sum=259369

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
