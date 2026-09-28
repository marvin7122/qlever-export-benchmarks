# Export run diagnosis

Medians over complete reps. Counters are process-wide over the request.

| query | role | elapsed s | cpu s | MiB/s | syscr | pread64 | io_uring_enter | read_bytes | major_faults | bytes | verdict |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| I-iouring-label-de |  | 61.532→26.465 | 27.940→29.710 | 7.83→18.20 | 8886210→2646 | 4444385→2612 | 0→6636712 | 9615527936→9433931776 | 9→7 | 504927346 | ID-to-string left pread for io_uring. Elapsed also fell. |
| R2 |  | 2.921→0.991 | 1.350→1.330 | 7.56→22.27 | 97031→3504 | 50261→3498 | 0→8878 | 338563072→329797632 | 12→10 | 23144633 | ID-to-string left pread for io_uring. Elapsed also fell. |

## I-iouring-label-de

Role: .
Measured verdict: ID-to-string left pread for io_uring. Elapsed also fell.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 61.532209 | 26.464817 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms |  |  |
| response_bytes | 504927346 | 504927346 |
| mib_per_s | 7.825759 | 18.195336 |
| cpu_s | 27.940000 | 29.710000 |
| cpu_ratio | 0.454300 | 1.124000 |
| major_faults | 9 | 7 |
| minor_faults | 50380 | 21414 |
| rchar | 211749567 | 97583742 |
| wchar | 2416 | 1782 |
| read_bytes | 9615527936 | 9433931776 |
| write_bytes | 32768 | 16384 |
| syscr | 8886210 | 2646 |
| syscw | 41 | 23 |
| pread64 | 4444385 | 2612 |
| io_uring_enter | 0 | 6636712 |
| utime_ticks | 1393 | 1312 |
| stime_ticks | 1403 | 1664 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## R2

Role: .
Measured verdict: ID-to-string left pread for io_uring. Elapsed also fell.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 2.920552 | 0.991282 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms |  | 909 |
| response_bytes | 23144633 | 23144633 |
| mib_per_s | 7.557628 | 22.266563 |
| cpu_s | 1.350000 | 1.330000 |
| cpu_ratio | 0.464600 | 1.340400 |
| major_faults | 12 | 10 |
| minor_faults | 25926 | 25268 |
| rchar | 72492526 | 70905128 |
| wchar | 1588 | 1552 |
| read_bytes | 338563072 | 329797632 |
| write_bytes | 4096 | 4096 |
| syscr | 97031 | 3504 |
| syscw | 11 | 10 |
| pread64 | 50261 | 3498 |
| io_uring_enter | 0 | 8878 |
| utime_ticks | 99 | 95 |
| stime_ticks | 36 | 38 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

