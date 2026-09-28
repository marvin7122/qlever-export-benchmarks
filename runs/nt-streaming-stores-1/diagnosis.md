# Streaming stores microbenchmark diagnosis

Single measurement per cell (see arms.txt); medians do not apply.

| chunk | memcpy GB/s | streaming GB/s | delta | vocab probe ns (both arms) |
|---|---|---:|---:|:--:|
| 1 KB | 8.12 | 11.36 | +40% | 5-6 |
| 4 KB | 8.14 | 13.87 | +70% | 5-6 |
| 16 KB | 7.62 | 14.03 | +84% | 5-6 |
| 64 KB | 8.46 | 13.73 | +62% | 5-6 |
| 1 MB | 8.36 | 14.09 | +69% | 5-6 |
| 16 MB | 13.39 | 14.16 | +6% | 5-6 |
| 256 MB | 12.90 | 14.19 | +10% | 5-6 |

The throughput win is real and chunk-size dependent: strongest at 4-16 KB,
narrower at 1 KB (per-call overhead over 262k tiny writes), nearly gone at
16 MB and above. The vocabulary probe latency is flat in both arms, so this
run shows no evidence that hot vocabulary or index entries stay resident;
only the throughput win is supported.
