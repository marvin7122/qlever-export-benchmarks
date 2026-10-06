| arm | scenario | rp | pread | preadv2 (nowait/EAGAIN) | io_uring_enter | submit | read_bytes | majflt | cpu_s | instructions:u | bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| base | cold | - | 2633 | 8878901 (8878901/581880) | 0 | 165252 | 9446117376 | 5 | 42.61 | 89174277188 | 504927346 |
| wave | cold | - | 2633 | 8878901 (8878901/582632) | 0 | 9563 | 9446113280 | 5 | 42.12 | 88971528810 | 504927346 |

Byte-identical output across arms: yes. Screening counters (one execution per arm and scenario); timing only in the verdict row.
