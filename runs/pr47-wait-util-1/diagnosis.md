# Export run diagnosis

Medians over complete reps. Counters are process-wide over the request.

| query | role | elapsed s | cpu s | MiB/s | syscr | pread64 | io_uring_enter | read_bytes | major_faults | bytes | verdict |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| H-vocab-label-large |  | 22.863→22.678 | 32.570→32.280 | 54.34→54.78 | 9847→9847 | 0→0 | 0→0 | 509542400→509558784 | 9→7 | 1302749672 | pread64 unchanged. This query does not exercise io_uring. |
| I-iouring-label-nonen |  | 161.050→131.855 | 141.130→156.910 | 20.64→25.21 | 60921406→21784 | 0→0 | 0→0 | 12810006528→12674285568 | 9→7 | 3485348857 | pread64 unchanged. Time change is not io_uring. |

## H-vocab-label-large

Role: .
Measured verdict: pread64 unchanged. This query does not exercise io_uring.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 22.863059 | 22.677761 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms |  |  |
| response_bytes | 1302749672 | 1302749672 |
| mib_per_s | 54.340887 | 54.784900 |
| cpu_s | 32.570000 | 32.280000 |
| cpu_ratio | 1.416500 | 1.430500 |
| major_faults | 9 | 7 |
| minor_faults | 30378 | 31647 |
| rchar | 481054810 | 481054810 |
| wchar | 2431 | 2431 |
| read_bytes | 509542400 | 509558784 |
| write_bytes | 12288 | 12288 |
| syscr | 9847 | 9847 |
| syscw | 21 | 21 |
| pread64 | 0 | 0 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 3227 | 3198 |
| stime_ticks | 30 | 30 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## I-iouring-label-nonen

Role: .
Measured verdict: pread64 unchanged. Time change is not io_uring.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 161.049972 | 131.855071 |
| export_time_s |  |  |
| plan_time_ms | 6 | 7 |
| total_server_ms |  |  |
| response_bytes | 3485348857 | 3485348857 |
| mib_per_s | 20.638859 | 25.208645 |
| cpu_s | 141.130000 | 156.910000 |
| cpu_ratio | 0.876300 | 1.190500 |
| major_faults | 9 | 7 |
| minor_faults | 154803 | 124858 |
| rchar | 1638222486 | 840814635 |
| wchar | 4640 | 4142 |
| read_bytes | 12810006528 | 12674285568 |
| write_bytes | 36864 | 32768 |
| syscr | 60921406 | 21784 |
| syscw | 90 | 76 |
| pread64 | 0 | 0 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 8618 | 8449 |
| stime_ticks | 5492 | 7253 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

