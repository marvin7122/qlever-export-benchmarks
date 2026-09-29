| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| p14-off | warm | iouring-adaptive-batch-enabled=false | 167 | 195266 (195266/0) | 0 | 0 | 3072000 | 2 | 0.69 | - | 15532320 |
| p14-on | warm | iouring-adaptive-batch-enabled=true | 167 | 195266 (195266/0) | 0 | 0 | 0 | 0 | 1.14 | - | 15532320 |
| p15fib-off | warm | iouring-adaptive-batch-enabled=false | 167 | 195264 (195264/0) | 0 | 0 | 2965504 | 2 | 0.67 | - | 15532320 |
| p15fib-on | warm | iouring-adaptive-batch-enabled=true | 167 | 195264 (195264/0) | 0 | 0 | 0 | 0 | 0.61 | - | 15532320 |
| p14-off | cold | iouring-adaptive-batch-enabled=false | 167 | 195266 (195266/53343) | 0 | 745 | 704622592 | 3 | 5.8 | - | 15532320 |
| p14-on | cold | iouring-adaptive-batch-enabled=true | 167 | 195266 (195266/53849) | 0 | 2991 | 682844160 | 5 | 5.67 | - | 15532320 |
| p15fib-off | cold | iouring-adaptive-batch-enabled=false | 167 | 195264 (195264/53961) | 0 | 743 | 697430016 | 5 | 5.71 | - | 15532320 |
| p15fib-on | cold | iouring-adaptive-batch-enabled=true | 167 | 195264 (195264/54122) | 0 | 2996 | 697753600 | 3 | 5.52 | - | 15532320 |

I/O pattern p14-off (cold, traced): pread64=167 preadv2=195266 (nowait 195266, EAGAIN 53343) io_uring_enter=1788 batch_med=0 batch_sum=56778 [dblp.vocabulary.words.external: n=98017 seq=0.0031 seek_med=249018] [dblp.vocabulary.words.external.offsets: n=97337 seq=0.0001 seek_med=46320]

I/O pattern p14-on (cold, traced): pread64=167 preadv2=195266 (nowait 195266, EAGAIN 53849) io_uring_enter=3890 batch_med=16 batch_sum=57046 [dblp.vocabulary.words.external: n=98017 seq=0.0031 seek_med=249018] [dblp.vocabulary.words.external.offsets: n=97337 seq=0.0001 seek_med=46320]

I/O pattern p15fib-off (cold, traced): pread64=167 preadv2=195264 (nowait 195264, EAGAIN 53961) io_uring_enter=4198 batch_med=0 batch_sum=57132 [dblp.vocabulary.words.external: n=98016 seq=0.0031 seek_med=249112] [dblp.vocabulary.words.external.offsets: n=97336 seq=0.0001 seek_med=46320]

I/O pattern p15fib-on (cold, traced): pread64=167 preadv2=195264 (nowait 195264, EAGAIN 54122) io_uring_enter=4592 batch_med=16 batch_sum=57317 [dblp.vocabulary.words.external: n=98016 seq=0.0031 seek_med=249033] [dblp.vocabulary.words.external.offsets: n=97336 seq=0.0001 seek_med=46320]

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
