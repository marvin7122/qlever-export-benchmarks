| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | cycles | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| base | warm | - | 1201735 | 348919 (348919/0) | 0 | 0 | 3162112 | 2 | 4.49 | 18217839557 | 23714103622 | 19297737 |
| wave | warm | - | 1201735 | 348919 (348919/0) | 0 | 0 | 0 | 0 | 4.34 | 17718853039 | 23691188363 | 19297737 |
| base-fpoff | warm | vocabulary-iouring-page-cache-fast-path=false | 1201735 | 0 (0/0) | 0 | 263576 | 0 | 0 | 5.25 | 21342895244 | 23593799708 | 19297737 |
| wave-fpoff | warm | vocabulary-iouring-page-cache-fast-path=false | 1201735 | 0 (0/0) | 0 | 1390 | 0 | 0 | 4.91 | 19974951782 | 23222033312 | 19297737 |
| base | cold | - | 1201735 | 348919 (348919/262173) | 0 | 174122 | 2992889856 | 6 | 7.89 | 30287901591 | 23069168495 | 19297737 |
| wave | cold | - | 1201735 | 348919 (348919/262274) | 0 | 1206 | 2993025024 | 8 | 8.01 | 30095170314 | 23095794631 | 19297737 |
| base-fpoff | cold | vocabulary-iouring-page-cache-fast-path=false | 1201735 | 0 (0/0) | 0 | 263576 | 2991325184 | 6 | 7.72 | 29523636389 | 22756831656 | 19297737 |
| wave-fpoff | cold | vocabulary-iouring-page-cache-fast-path=false | 1201735 | 0 (0/0) | 0 | 1418 | 2992820224 | 6 | 8.69 | 34067222800 | 22576010283 | 19297737 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
