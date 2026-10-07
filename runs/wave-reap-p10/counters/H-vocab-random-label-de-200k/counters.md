| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | cycles | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| base | warm | - | 1201735 | 348919 (348919/0) | 0 | 0 | 3162112 | 2 | 30.25 | 83954847907 | 23733518369 | 19297737 |
| wave | warm | - | 1201735 | 348919 (348919/0) | 0 | 0 | 3158016 | 2 | 26.67 | 73346803329 | 23705548408 | 19297737 |
| base-fpoff | warm | vocabulary-iouring-page-cache-fast-path=false | 1201735 | 0 (0/0) | 0 | 263576 | 0 | 0 | 25.55 | 70588888494 | 23583852885 | 19297737 |
| wave-fpoff | warm | vocabulary-iouring-page-cache-fast-path=false | 1201735 | 0 (0/0) | 0 | 1390 | 0 | 0 | 23.67 | 68399449509 | 23243625411 | 19297737 |
| base | cold | - | 1201735 | 348919 (348919/258487) | 0 | 170324 | 3002245120 | 6 | 32.78 | 91108504835 | 24033614492 | 19297737 |
| wave | cold | - | 1201735 | 348919 (348919/258081) | 0 | 1191 | 3003248640 | 6 | 32.04 | 92361937979 | 23816625005 | 19297737 |
| base-fpoff | cold | vocabulary-iouring-page-cache-fast-path=false | 1201735 | 0 (0/0) | 0 | 263576 | 3000930304 | 6 | 29.29 | 83009728316 | 23568290763 | 19297737 |
| wave-fpoff | cold | vocabulary-iouring-page-cache-fast-path=false | 1201735 | 0 (0/0) | 0 | 1391 | 2992795648 | 6 | 32.62 | 102244854934 | 23221379970 | 19297737 |

I/O pattern base (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=0 batch_med=0 batch_sum=0

I/O pattern wave (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=0 batch_med=0 batch_sum=0

I/O pattern base-fpoff (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=263576 batch_med=1 batch_sum=352316

I/O pattern wave-fpoff (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=1390 batch_med=256 batch_sum=352316

I/O pattern base (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=170324 batch_med=1 batch_sum=259064

I/O pattern wave (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=1192 batch_med=256 batch_sum=258644

I/O pattern base-fpoff (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=263898 batch_med=1 batch_sum=352316

I/O pattern wave-fpoff (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=1408 batch_med=256 batch_sum=352316

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
