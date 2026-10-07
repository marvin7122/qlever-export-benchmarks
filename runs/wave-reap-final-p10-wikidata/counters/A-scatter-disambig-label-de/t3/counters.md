| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | cycles | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| base | warm | - | 1859 | 1399318 (1399318/0) | 0 | 0 | 3162112 | 2 | 28.34 | 78208423798 | 8066150909 | 74413425 |
| wave | warm | - | 1859 | 1399318 (1399318/0) | 0 | 0 | 0 | 0 | 22.6 | 60243350191 | 8065518248 | 74413425 |
| base | cold | - | 1859 | 1399318 (1399318/809600) | 0 | 468691 | 6828621824 | 5 | 40.35 | 120953666742 | 12828587807 | 74413425 |
| wave | cold | - | 1859 | 1399318 (1399318/810984) | 0 | 3868 | 6845792256 | 5 | 30.28 | 93831003846 | 12241105381 | 74413425 |

I/O pattern base (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=0 batch_med=0 batch_sum=0

I/O pattern wave (warm, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=0 batch_med=0 batch_sum=0

I/O pattern base (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=468693 batch_med=1 batch_sum=810997

I/O pattern wave (cold, traced): pread64=0 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=3878 batch_med=256 batch_sum=812379

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
