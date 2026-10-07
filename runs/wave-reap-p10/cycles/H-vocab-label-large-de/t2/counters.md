| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | cycles | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| base | warm | - | 2633 | 8878901 (8878901/0) | 0 | 0 | 3162112 | 2 | 26.92 | 104694420795 | 77796162525 | 504927346 |
| wave | warm | - | 2633 | 8878901 (8878901/0) | 0 | 0 | 3158016 | 2 | 23.04 | 89509182552 | 77791429125 | 504927346 |
| base-fpoff | warm | vocabulary-iouring-page-cache-fast-path=false | 2633 | 0 (0/0) | 0 | 6625868 | 0 | 0 | 22.12 | 89313355238 | 78708166192 | 504927346 |
| wave-fpoff | warm | vocabulary-iouring-page-cache-fast-path=false | 2633 | 0 (0/0) | 0 | 35302 | 0 | 0 | 23.6 | 92246934236 | 66204572709 | 504927346 |
| base | cold | - | 2633 | 8878901 (8878901/584883) | 0 | 167839 | 9446850560 | 5 | 29.87 | 122959063625 | 86611765931 | 504927346 |
| wave | cold | - | 2633 | 8878901 (8878901/584729) | 0 | 9571 | 9446846464 | 5 | 27.77 | 113681652269 | 86430808061 | 504927346 |
| base-fpoff | cold | vocabulary-iouring-page-cache-fast-path=false | 2633 | 0 (0/0) | 0 | 6625868 | 9456922624 | 5 | 37.44 | 152125055893 | 82735264923 | 504927346 |
| wave-fpoff | cold | vocabulary-iouring-page-cache-fast-path=false | 2633 | 0 (0/0) | 0 | 40909 | 9441243136 | 5 | 29.05 | 117002710858 | 74492577233 | 504927346 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
