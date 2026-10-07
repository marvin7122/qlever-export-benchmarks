| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | cycles | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| base | warm | - | 1201735 | 348919 (348919/0) | 0 | 0 | 3162112 | 2 | 5.97 | 23216454841 | 23080843704 | 19297737 |
| wave | warm | - | 1201735 | 348919 (348919/0) | 0 | 0 | 3158016 | 2 | 5.9 | 23594776255 | 23674634236 | 19297737 |
| base-fpoff | warm | vocabulary-iouring-page-cache-fast-path=false | 1201735 | 0 (0/0) | 0 | 263576 | 0 | 0 | 6.01 | 24016176750 | 23574908909 | 19297737 |
| wave-fpoff | warm | vocabulary-iouring-page-cache-fast-path=false | 1201735 | 0 (0/0) | 0 | 1390 | 0 | 0 | 5.91 | 23623238043 | 23251310206 | 19297737 |
| base | cold | - | 1201735 | 348919 (348919/261862) | 0 | 173791 | 2993037312 | 8 | 10.51 | 41029352352 | 23435050221 | 19297737 |
| wave | cold | - | 1201735 | 348919 (348919/261750) | 0 | 1207 | 2993025024 | 8 | 10.49 | 40163689152 | 22078614046 | 19297737 |
| base-fpoff | cold | vocabulary-iouring-page-cache-fast-path=false | 1201735 | 0 (0/0) | 0 | 263576 | 2995003392 | 8 | 10.49 | 40816166284 | 22692799274 | 19297737 |
| wave-fpoff | cold | vocabulary-iouring-page-cache-fast-path=false | 1201735 | 0 (0/0) | 0 | 1401 | 2992930816 | 8 | 10.07 | 37259548204 | 19519334578 | 19297737 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
