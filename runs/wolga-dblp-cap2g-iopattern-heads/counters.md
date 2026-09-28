| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| p6-3525 | warm | - | 199229 | 0 (0/0) | 0 | 0 | 0 | 0 | 0.76 | - | 15532320 |
| p7-3526 | warm | - | 123 | 0 (0/0) | 0 | 296812 | 0 | 0 | 4.14 | - | 15532320 |
| p8-3547 | warm | - | 167 | 194665 (194665/0) | 0 | 0 | 0 | 0 | 0.59 | - | 15532320 |
| p9-3527 | warm | - | 167 | 194665 (194665/0) | 0 | 0 | 0 | 0 | 0.64 | - | 15532320 |
| p10-3528 | warm | - | 167 | 194665 (194665/0) | 0 | 0 | 0 | 0 | 0.63 | - | 15532320 |
| p11-3529 | warm | - | 167 | 194665 (194665/0) | 0 | 0 | 0 | 0 | 0.55 | - | 15532320 |
| p12-3539 | warm | - | 167 | 194665 (194665/0) | 0 | 0 | 0 | 0 | 0.61 | - | 15532320 |
| p13-3506 | warm | - | 167 | 195266 (195266/0) | 0 | 0 | 0 | 0 | 0.59 | - | 15532320 |
| p14-3476 | warm | - | 167 | 195266 (195266/0) | 0 | 0 | 0 | 0 | 0.61 | - | 15532320 |
| p14-3476-ctl-on | warm | iouring-adaptive-batch-enabled=true | 167 | 195266 (195266/0) | 0 | 0 | 0 | 0 | 0.58 | - | 15532320 |
| p15-3477 | warm | - | 167 | 195264 (195264/0) | 0 | 0 | 0 | 0 | 0.61 | - | 15532320 |
| p16-3499 | warm | - | 167 | 195264 (195264/0) | 0 | 0 | 0 | 0 | 0.61 | - | 15532320 |
| p6-3525 | cold | - | 199229 | 0 (0/0) | 0 | 0 | 743403520 | 4 | 3.8 | - | 15532320 |
| p7-3526 | cold | - | 123 | 0 (0/0) | 0 | 296812 | 704909312 | 3 | 7.18 | - | 15532320 |
| p8-3547 | cold | - | 167 | 194665 (194665/54220) | 0 | 27763 | 694960128 | 2 | 4.93 | - | 15532320 |
| p9-3527 | cold | - | 167 | 194665 (194665/54457) | 0 | 27888 | 696365056 | 2 | 4.7 | - | 15532320 |
| p10-3528 | cold | - | 167 | 194665 (194665/54104) | 0 | 27638 | 695189504 | 2 | 4.57 | - | 15532320 |
| p11-3529 | cold | - | 167 | 194665 (194665/53949) | 0 | 27639 | 706506752 | 2 | 4.51 | - | 15532320 |
| p12-3539 | cold | - | 167 | 194665 (194665/53781) | 0 | 27525 | 695664640 | 2 | 4.82 | - | 15532320 |
| p13-3506 | cold | - | 167 | 195266 (195266/53825) | 0 | 742 | 700669952 | 2 | 5.42 | - | 15532320 |
| p14-3476 | cold | - | 167 | 195266 (195266/54070) | 0 | 749 | 704163840 | 2 | 5.61 | - | 15532320 |
| p14-3476-ctl-on | cold | iouring-adaptive-batch-enabled=true | 167 | 195266 (195266/54197) | 0 | 2998 | 704086016 | 2 | 5.17 | - | 15532320 |
| p15-3477 | cold | - | 167 | 195264 (195264/54290) | 0 | 750 | 702332928 | 2 | 5.66 | - | 15532320 |
| p16-3499 | cold | - | 167 | 195264 (195264/53755) | 0 | 743 | 694071296 | 2 | 5.42 | - | 15532320 |

I/O pattern p6-3525 (cold, traced): pread64=398379 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=0 batch_med=0 batch_sum=0 [dblp.vocabulary.words.external.offsets: n=199150 seq=0.0034 seek_med=8] [dblp.vocabulary.words.external: n=199150 seq=0.5093 seek_med=0]

I/O pattern p7-3526 (cold, traced): pread64=167 preadv2=0 (nowait 0, EAGAIN 0) io_uring_enter=297007 batch_med=1 batch_sum=398212 [dblp.index.pso: n=79 seq=0.3333 seek_med=31763] [dblp.vocabulary.words.external.offsets: n=44 seq=0.093 seek_med=112]

I/O pattern p8-3547 (cold, traced): pread64=167 preadv2=194665 (nowait 194665, EAGAIN 54220) io_uring_enter=28543 batch_med=1 batch_sum=61927 [dblp.vocabulary.words.external: n=97718 seq=0.0 seek_med=251010] [dblp.vocabulary.words.external.offsets: n=97035 seq=0.0 seek_med=46716]

I/O pattern p9-3527 (cold, traced): pread64=167 preadv2=194665 (nowait 194665, EAGAIN 54457) io_uring_enter=28741 batch_med=1 batch_sum=62137 [dblp.vocabulary.words.external: n=97718 seq=0.0 seek_med=251010] [dblp.vocabulary.words.external.offsets: n=97035 seq=0.0 seek_med=46716]

I/O pattern p10-3528 (cold, traced): pread64=167 preadv2=194665 (nowait 194665, EAGAIN 54104) io_uring_enter=28532 batch_med=1 batch_sum=61811 [dblp.vocabulary.words.external: n=97718 seq=0.0 seek_med=251010] [dblp.vocabulary.words.external.offsets: n=97035 seq=0.0 seek_med=46716]

I/O pattern p11-3529 (cold, traced): pread64=167 preadv2=194665 (nowait 194665, EAGAIN 53949) io_uring_enter=28471 batch_med=1 batch_sum=61628 [dblp.vocabulary.words.external: n=97718 seq=0.0 seek_med=251010] [dblp.vocabulary.words.external.offsets: n=97035 seq=0.0 seek_med=46716]

I/O pattern p12-3539 (cold, traced): pread64=167 preadv2=194665 (nowait 194665, EAGAIN 53781) io_uring_enter=28331 batch_med=1 batch_sum=61484 [dblp.vocabulary.words.external: n=97718 seq=0.0 seek_med=251010] [dblp.vocabulary.words.external.offsets: n=97035 seq=0.0 seek_med=46716]

I/O pattern p13-3506 (cold, traced): pread64=167 preadv2=195266 (nowait 195266, EAGAIN 53825) io_uring_enter=2470 batch_med=0 batch_sum=56991 [dblp.vocabulary.words.external: n=98017 seq=0.0031 seek_med=249018] [dblp.vocabulary.words.external.offsets: n=97337 seq=0.0001 seek_med=46320]

I/O pattern p14-3476 (cold, traced): pread64=167 preadv2=195266 (nowait 195266, EAGAIN 54070) io_uring_enter=1686 batch_med=0 batch_sum=57277 [dblp.vocabulary.words.external: n=98017 seq=0.0031 seek_med=249018] [dblp.vocabulary.words.external.offsets: n=97337 seq=0.0001 seek_med=46320]

I/O pattern p14-3476-ctl-on (cold, traced): pread64=167 preadv2=195266 (nowait 195266, EAGAIN 54197) io_uring_enter=3836 batch_med=16 batch_sum=57368 [dblp.vocabulary.words.external: n=98017 seq=0.0031 seek_med=249018] [dblp.vocabulary.words.external.offsets: n=97337 seq=0.0001 seek_med=46320]

I/O pattern p15-3477 (cold, traced): pread64=167 preadv2=195264 (nowait 195264, EAGAIN 54290) io_uring_enter=2386 batch_med=0 batch_sum=57467 [dblp.vocabulary.words.external: n=98016 seq=0.0031 seek_med=249094] [dblp.vocabulary.words.external.offsets: n=97336 seq=0.0001 seek_med=46320]

I/O pattern p16-3499 (cold, traced): pread64=167 preadv2=195264 (nowait 195264, EAGAIN 53755) io_uring_enter=2425 batch_med=0 batch_sum=56935 [dblp.vocabulary.words.external: n=98016 seq=0.0031 seek_med=249112] [dblp.vocabulary.words.external.offsets: n=97336 seq=0.0001 seek_med=46320]

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
