# iouring-adaptive-batch-min-size sweep

Same binary. Cold medians, 5 reps, rotated arm order.

| query | min-size | elapsed s | cpu_ratio | io_uring_enter | pread64 | bytes |
|---|---:|---:|---:|---:|---:|---:|
| I-iouring-label-de | 4 | 23.321 | 1.124 | 141006 | 2612 | 504927346 |
| I-iouring-label-de | 16 | 23.096 | 1.128 | 141029 | 2612 | 504927346 |
| I-iouring-label-de | 64 | 23.405 | 1.125 | 141028 | 2612 | 504927346 |
| I-iouring-label-nonen | 4 | 120 | 1.200 | 795906 | 21637 | 3485348857 |
| I-iouring-label-nonen | 16 | 119 | 1.203 | 795876 | 21637 | 3485348857 |
| I-iouring-label-nonen | 64 | 120 | 1.199 | 796073 | 21637 | 3485348857 |
