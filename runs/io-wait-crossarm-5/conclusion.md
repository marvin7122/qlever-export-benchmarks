# Export run diagnosis

Medians over complete reps. Counters are process-wide over the request.

| query | role | elapsed s | cpu s | MiB/s | syscr | pread64 | io_uring_enter | read_bytes | major_faults | bytes | verdict |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| I-iouring-label-nonen |  | 176.431→144.579 | 157.260→169.880 | 18.84→22.99 | 60932548→30882 | 60921326→21718 | 0→45395436 | 12810182656→12661383168 | 6→1 | 3485348857 | Faster, but io_uring_enter did not drop. |
| H-vocab-label-large | serialize-bound | 23.021→22.493 | 32.770→32.350 | 53.97→55.24 | 11298→11265 | 9836→9836 | 0→0 | 509702144→509599744 | 6→1 | 1302749672 | Enter count unchanged. This query does not stress ring refill. |

## I-iouring-label-nonen

Role: .
Measured verdict: Faster, but io_uring_enter did not drop.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 176.430855 | 144.579062 |
| export_time_s |  |  |
| plan_time_ms | 7 | 6 |
| total_server_ms |  |  |
| response_bytes | 3485348857 | 3485348857 |
| mib_per_s | 18.839605 | 22.990104 |
| cpu_s | 157.260000 | 169.880000 |
| cpu_ratio | 0.890500 | 1.175000 |
| major_faults | 6 | 1 |
| minor_faults | 174415 | 134298 |
| rchar | 1638400950 | 840960347 |
| wchar | 136964 | 126331 |
| read_bytes | 12810182656 | 12661383168 |
| write_bytes | 2949120 | 2416640 |
| syscr | 60932548 | 30882 |
| syscw | 803 | 660 |
| pread64 | 60921326 | 21718 |
| io_uring_enter | 0 | 45395436 |
| utime_ticks | 9881 | 9422 |
| stime_ticks | 5823 | 7600 |
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
| elapsed_s | 23.020878 | 22.492765 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms |  |  |
| response_bytes | 1302749672 | 1302749672 |
| mib_per_s | 53.968354 | 55.235489 |
| cpu_s | 32.770000 | 32.350000 |
| cpu_ratio | 1.423700 | 1.438700 |
| major_faults | 6 | 1 |
| minor_faults | 31437 | 30743 |
| rchar | 481078050 | 481077498 |
| wchar | 19441 | 19065 |
| read_bytes | 509702144 | 509599744 |
| write_bytes | 393216 | 385024 |
| syscr | 11298 | 11265 |
| syscw | 113 | 111 |
| pread64 | 9836 | 9836 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 3245 | 3204 |
| stime_ticks | 32 | 31 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

