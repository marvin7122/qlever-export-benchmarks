| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | cycles | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| base | warm | - | 1201735 | 348919 (348919/0) | 0 | 0 | 3162112 | 2 | 6.1 | 24343186329 | 23701173922 | 19297737 |
| wave | warm | - | 1201735 | 348919 (348919/0) | 0 | 0 | 0 | 0 | 6.05 | 24206213213 | 23713725851 | 19297737 |
| base-fpoff | warm | vocabulary-iouring-page-cache-fast-path=false | 1201735 | 0 (0/0) | 0 | 263576 | 0 | 0 | 6.06 | 24164802968 | 23550505271 | 19297737 |
| wave-fpoff | warm | vocabulary-iouring-page-cache-fast-path=false | 1201735 | 0 (0/0) | 0 | 1390 | 0 | 0 | 6.02 | 23972754556 | 23258216794 | 19297737 |
| base | cold | - | 1201735 | 348919 (348919/261770) | 0 | 173698 | 2993025024 | 8 | 10.93 | 42483988512 | 23394303868 | 19297737 |
| wave | cold | - | 1201735 | 348919 (348919/261803) | 0 | 1207 | 2993025024 | 8 | 10.73 | 41148910524 | 22374706612 | 19297737 |
| base-fpoff | cold | vocabulary-iouring-page-cache-fast-path=false | 1201735 | 0 (0/0) | 0 | 263576 | 2984808448 | 8 | 10.8 | 42114329477 | 22839151855 | 19297737 |
| wave-fpoff | cold | vocabulary-iouring-page-cache-fast-path=false | 1201735 | 0 (0/0) | 0 | 1409 | 2992930816 | 8 | 10.15 | 39511615312 | 22450159517 | 19297737 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
