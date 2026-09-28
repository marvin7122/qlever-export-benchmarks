| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| p12-3539 | warm | - | 167 | 194665 (194665/0) | 0 | 0 | 0 | 0 | 0.63 | - | 15532320 |
| p13-3506 | warm | - | 167 | 195266 (195266/0) | 0 | 0 | 3067904 | 2 | 1.06 | - | 15532320 |
| p14-3476-off | warm | iouring-adaptive-batch-enabled=false | 167 | 195266 (195266/0) | 0 | 0 | 3072000 | 2 | 0.65 | - | 15532320 |
| p14-3476-on | warm | iouring-adaptive-batch-enabled=true | 167 | 195266 (195266/0) | 0 | 0 | 0 | 0 | 0.66 | - | 15532320 |
| p12-3539 | cold | - | 167 | 194665 (194665/53959) | 0 | 27312 | 696434688 | 2 | 4.87 | - | 15532320 |
| p13-3506 | cold | - | 167 | 195266 (195266/54245) | 0 | 746 | 703512576 | 2 | 5.52 | - | 15532320 |
| p14-3476-off | cold | iouring-adaptive-batch-enabled=false | 167 | 195266 (195266/53431) | 0 | 752 | 705286144 | 2 | 4.65 | - | 15532320 |
| p14-3476-on | cold | iouring-adaptive-batch-enabled=true | 167 | 195266 (195266/54499) | 0 | 3018 | 698601472 | 3 | 4.49 | - | 15532320 |

I/O pattern p12-3539 (cold, traced): pread64=167 preadv2=194665 (nowait 194665, EAGAIN 53959) io_uring_enter=28076 batch_med=1 batch_sum=61663 [dblp.vocabulary.words.external: n=97718 seq=0.0 seek_med=251010] [dblp.vocabulary.words.external.offsets: n=97035 seq=0.0 seek_med=46716]

I/O pattern p13-3506 (cold, traced): pread64=167 preadv2=195266 (nowait 195266, EAGAIN 54245) io_uring_enter=2508 batch_med=0 batch_sum=57430 [dblp.vocabulary.words.external: n=98017 seq=0.0031 seek_med=249018] [dblp.vocabulary.words.external.offsets: n=97337 seq=0.0001 seek_med=46320]

I/O pattern p14-3476-off (cold, traced): pread64=167 preadv2=195266 (nowait 195266, EAGAIN 53431) io_uring_enter=1553 batch_med=0 batch_sum=56632 [dblp.vocabulary.words.external: n=98017 seq=0.0031 seek_med=249018] [dblp.vocabulary.words.external.offsets: n=97337 seq=0.0001 seek_med=46320]

I/O pattern p14-3476-on (cold, traced): pread64=167 preadv2=195266 (nowait 195266, EAGAIN 54499) io_uring_enter=3747 batch_med=16 batch_sum=57694 [dblp.vocabulary.words.external: n=98017 seq=0.0031 seek_med=249018] [dblp.vocabulary.words.external.offsets: n=97337 seq=0.0001 seek_med=46320]

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
