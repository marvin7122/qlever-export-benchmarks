| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | cycles | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| base | warm | - | 2633 | 8878901 (8878901/0) | 0 | 0 | 3162112 | 2 | 22.54 | 89003090577 | 80471104682 | 504927346 |
| wave | warm | - | 2633 | 8878901 (8878901/0) | 0 | 0 | 3158016 | 2 | 20.35 | 80405074597 | 77798035418 | 504927346 |
| base-fpoff | warm | vocabulary-iouring-page-cache-fast-path=false | 2633 | 0 (0/0) | 0 | 6625868 | 0 | 0 | 27.63 | 110197819782 | 77160293432 | 504927346 |
| wave-fpoff | warm | vocabulary-iouring-page-cache-fast-path=false | 2633 | 0 (0/0) | 0 | 35302 | 0 | 0 | 21.02 | 83104793897 | 68872974127 | 504927346 |
| base | cold | - | 2633 | 8878901 (8878901/584584) | 0 | 167542 | 9446850560 | 5 | 28.21 | 113524676926 | 86604032440 | 504927346 |
| wave | cold | - | 2633 | 8878901 (8878901/583269) | 0 | 9566 | 9446846464 | 5 | 35.04 | 142455807534 | 86421971496 | 504927346 |
| base-fpoff | cold | vocabulary-iouring-page-cache-fast-path=false | 2633 | 0 (0/0) | 0 | 6625868 | 9433010176 | 5 | 32.03 | 131599889555 | 82723390233 | 504927346 |
| wave-fpoff | cold | vocabulary-iouring-page-cache-fast-path=false | 2633 | 0 (0/0) | 0 | 40928 | 9440272384 | 5 | 26.58 | 106868492641 | 74480221224 | 504927346 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
