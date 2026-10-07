| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | cycles | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| base | warm | - | 2633 | 8878901 (8878901/0) | 0 | 0 | 3162112 | 2 | 188.64 | 549073385387 | 77809197248 | 504927346 |
| wave | warm | - | 2633 | 8878901 (8878901/0) | 0 | 0 | 0 | 0 | 163.23 | 452421800925 | 77800350655 | 504927346 |
| base-fpoff | warm | vocabulary-iouring-page-cache-fast-path=false | 2633 | 0 (0/0) | 0 | 6625868 | 0 | 0 | 141.92 | 425389884634 | 83398846973 | 504927346 |
| wave-fpoff | warm | vocabulary-iouring-page-cache-fast-path=false | 2633 | 0 (0/0) | 0 | 35302 | 0 | 0 | 22.28 | 87904938237 | 75142574260 | 504927346 |
| base | cold | - | 2633 | 8878901 (8878901/568045) | 0 | 156210 | 9452904448 | 7 | 205.42 | 617960883732 | 86713277729 | 504927346 |
| wave | cold | - | 2633 | 8878901 (8878901/566017) | 0 | 9511 | 9458442240 | 7 | 203.66 | 613950955750 | 86527363499 | 504927346 |
| base-fpoff | cold | vocabulary-iouring-page-cache-fast-path=false | 2633 | 0 (0/0) | 0 | 6625868 | 9428103168 | 7 | 165.25 | 524012424801 | 82807976459 | 504927346 |
| wave-fpoff | cold | vocabulary-iouring-page-cache-fast-path=false | 2633 | 0 (0/0) | 0 | 40536 | 9447055360 | 7 | 34.48 | 136532675375 | 74464252336 | 504927346 |

I/O pattern base (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=0 batch_med=0 batch_sum=0

I/O pattern wave (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=0 batch_med=0 batch_sum=0

I/O pattern base-fpoff (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=6625868 batch_med=1 batch_sum=8883546

I/O pattern wave-fpoff (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=35302 batch_med=256 batch_sum=8883546

I/O pattern base (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=156233 batch_med=1 batch_sum=568561

I/O pattern wave (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=9534 batch_med=24 batch_sum=566539

I/O pattern base-fpoff (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=6626928 batch_med=1 batch_sum=8883546

I/O pattern wave-fpoff (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=46220 batch_med=252 batch_sum=8883546

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
