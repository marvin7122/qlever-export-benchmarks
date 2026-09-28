# Export run diagnosis

Medians over complete reps. Counters are process-wide over the request.

| query | role | elapsed s | cpu s | MiB/s | syscr | pread64 | io_uring_enter | read_bytes | major_faults | bytes | verdict |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| I-iouring-label-nonen |  | 175.015→140.917 | 155.180→166.280 | 18.99→23.59 | 60932454→30640 | 60921326→21718 | 0→45396051 | 12810162176→12671270912 | 6→8 | 3485348857 | Faster, but io_uring_enter did not drop. |
| H-vocab-label-large | serialize-bound | 22.719→22.202 | 32.350→32 | 54.69→55.96 | 11281→11249 | 9836→9836 | 0→0 | 509698048→509702144 | 6→8 | 1302749672 | Enter count unchanged. This query does not stress ring refill. |

## I-iouring-label-nonen

Role: .
Measured verdict: Faster, but io_uring_enter did not drop.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 175.015189 | 140.917280 |
| export_time_s |  |  |
| plan_time_ms | 6 | 7 |
| total_server_ms |  |  |
| response_bytes | 3485348857 | 3485348857 |
| mib_per_s | 18.991996 | 23.587510 |
| cpu_s | 155.180000 | 166.280000 |
| cpu_ratio | 0.886700 | 1.179300 |
| major_faults | 6 | 8 |
| minor_faults | 174131 | 124882 |
| rchar | 1638377340 | 840938723 |
| wchar | 4904 | 4296 |
| read_bytes | 12810162176 | 12671270912 |
| write_bytes | 61440 | 53248 |
| syscr | 60932454 | 30640 |
| syscw | 97 | 80 |
| pread64 | 60921326 | 21718 |
| io_uring_enter | 0 | 45396051 |
| utime_ticks | 9831 | 9228 |
| stime_ticks | 5679 | 7397 |
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
| elapsed_s | 22.718973 | 22.202397 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms |  |  |
| response_bytes | 1302749672 | 1302749672 |
| mib_per_s | 54.685521 | 55.957872 |
| cpu_s | 32.350000 | 32 |
| cpu_ratio | 1.424500 | 1.440500 |
| major_faults | 6 | 8 |
| minor_faults | 32557 | 32156 |
| rchar | 481074886 | 481074438 |
| wchar | 2431 | 2431 |
| read_bytes | 509698048 | 509702144 |
| write_bytes | 16384 | 16384 |
| syscr | 11281 | 11249 |
| syscw | 21 | 21 |
| pread64 | 9836 | 9836 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 3206 | 3170 |
| stime_ticks | 30 | 30 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

