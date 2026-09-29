| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| p14-off | warm | iouring-adaptive-batch-enabled=false | 1438 | 246946 (246946/0) | 0 | 0 | 0 | 0 | 1.42 | - | 61418523 |
| p14-on | warm | iouring-adaptive-batch-enabled=true | 1438 | 246946 (246946/0) | 0 | 0 | 0 | 0 | 1.46 | - | 61418523 |
| p15fib-off | warm | iouring-adaptive-batch-enabled=false | 1438 | 246970 (246970/0) | 0 | 0 | 0 | 0 | 1.44 | - | 61418523 |
| p15fib-on | warm | iouring-adaptive-batch-enabled=true | 1438 | 246970 (246970/0) | 0 | 0 | 0 | 0 | 1.38 | - | 61418523 |
| p14-off | cold | iouring-adaptive-batch-enabled=false | 1438 | 246946 (246946/41412) | 0 | 1329 | 462479360 | 3 | 6.62 | - | 61418523 |
| p14-on | cold | iouring-adaptive-batch-enabled=true | 1438 | 246946 (246946/41600) | 0 | 3305 | 466325504 | 4 | 6.48 | - | 61418523 |
| p15fib-off | cold | iouring-adaptive-batch-enabled=false | 1438 | 246970 (246970/41163) | 0 | 1322 | 474902528 | 7 | 6.42 | - | 61418523 |
| p15fib-on | cold | iouring-adaptive-batch-enabled=true | 1438 | 246970 (246970/41471) | 0 | 3296 | 468062208 | 3 | 6.33 | - | 61418523 |

I/O pattern p14-off (cold, traced): pread64=1438 preadv2=246946 (nowait 246946, EAGAIN 41412) io_uring_enter=3285 batch_med=0 batch_sum=47139 [dblp.vocabulary.words.external: n=125918 seq=0.0001 seek_med=33575] [dblp.vocabulary.words.external.offsets: n=121204 seq=0.0001 seek_med=47152]

I/O pattern p14-on (cold, traced): pread64=1438 preadv2=246946 (nowait 246946, EAGAIN 41600) io_uring_enter=4982 batch_med=11 batch_sum=47326 [dblp.vocabulary.words.external: n=125918 seq=0.0001 seek_med=33575] [dblp.vocabulary.words.external.offsets: n=121204 seq=0.0001 seek_med=47152]

I/O pattern p15fib-off (cold, traced): pread64=1438 preadv2=246970 (nowait 246970, EAGAIN 41163) io_uring_enter=4094 batch_med=0 batch_sum=46799 [dblp.vocabulary.words.external: n=125933 seq=0.0001 seek_med=34083] [dblp.vocabulary.words.external.offsets: n=121213 seq=0.0001 seek_med=47252]

I/O pattern p15fib-on (cold, traced): pread64=1438 preadv2=246970 (nowait 246970, EAGAIN 41471) io_uring_enter=5742 batch_med=6 batch_sum=47124 [dblp.vocabulary.words.external: n=125933 seq=0.0001 seek_med=34022] [dblp.vocabulary.words.external.offsets: n=121213 seq=0.0001 seek_med=47252]

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
