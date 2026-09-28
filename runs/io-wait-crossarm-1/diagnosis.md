# Export run diagnosis

Medians over complete reps. Counters are process-wide over the request.

| query | role | elapsed s | cpu s | MiB/s | syscr | pread64 | io_uring_enter | read_bytes | major_faults | bytes | verdict |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| I-iouring-label-nonen |  | 175.556→141.693 | 155.540→166.910 | 18.93→23.46 | 60921414→21789 | 60921326→21718 | 0→45395902 | 12810166272→12667404288 | 6→6 | 3485348857 | Faster, but io_uring_enter did not drop. |
| H-vocab-label-large | serialize-bound | 22.791→22.648 | 32.510→32.350 | 54.51→54.86 | 9847→9847 | 9836→9836 | 0→0 | 509702144→509698048 | 6→6 | 1302749672 | Enter count unchanged. This query does not stress ring refill. |

## I-iouring-label-nonen

Role: .
Measured verdict: Faster, but io_uring_enter did not drop.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 175.556254 | 141.693379 |
| export_time_s |  |  |
| plan_time_ms | 7 | 6 |
| total_server_ms |  |  |
| response_bytes | 3485348857 | 3485348857 |
| mib_per_s | 18.933462 | 23.458313 |
| cpu_s | 155.540000 | 166.910000 |
| cpu_ratio | 0.887200 | 1.178200 |
| major_faults | 6 | 6 |
| minor_faults | 171132 | 121868 |
| rchar | 1638222806 | 840814835 |
| wchar | 4939 | 4332 |
| read_bytes | 12810166272 | 12667404288 |
| write_bytes | 61440 | 53248 |
| syscr | 60921414 | 21789 |
| syscw | 98 | 81 |
| pread64 | 60921326 | 21718 |
| io_uring_enter | 0 | 45395902 |
| utime_ticks | 9858 | 9277 |
| stime_ticks | 5673 | 7402 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## H-vocab-label-large

Role: serialize-bound.
CONSTRUCT writes entity IRI + rdfs:label.
WHERE: P+O class scan P31/Q5, then S+P label, LANG=en.
Output is about 1.3 GiB. syscr stayed 9847 on both arms. That count
is too small for per-word label pread. The scan is mmap. A time
change here is serialize or CPU, not io_uring.
Measured verdict: Enter count unchanged. This query does not stress ring refill.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 22.791098 | 22.648087 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms |  |  |
| response_bytes | 1302749672 | 1302749672 |
| mib_per_s | 54.512464 | 54.856682 |
| cpu_s | 32.510000 | 32.350000 |
| cpu_ratio | 1.425000 | 1.429700 |
| major_faults | 6 | 6 |
| minor_faults | 29071 | 31939 |
| rchar | 481054810 | 481054810 |
| wchar | 2431 | 2433 |
| read_bytes | 509702144 | 509698048 |
| write_bytes | 16384 | 20480 |
| syscr | 9847 | 9847 |
| syscw | 21 | 21 |
| pread64 | 9836 | 9836 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 3224 | 3206 |
| stime_ticks | 30 | 29 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

