# Export run diagnosis

Medians over complete reps. Counters are process-wide over the request.

| query | role | elapsed s | cpu s | MiB/s | syscr | pread64 | io_uring_enter | read_bytes | major_faults | bytes | verdict |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| I-iouring-label-nonen |  | 181.328→150.560 | 162.010→176.330 | 18.33→22.08 | 60932844→31249 | 60921326→21718 | 0→45395519 | 12810039296→12679987200 | 6→8 | 3485348857 | Faster, but io_uring_enter did not drop. |
| H-vocab-label-large | serialize-bound | 25.764→24.442 | 35.950→34.470 | 48.22→50.83 | 11475→11394 | 9836→9836 | 0→0 | 509698048→509702144 | 6→8 | 1302749672 | Enter count unchanged. This query does not stress ring refill. |

## I-iouring-label-nonen

Role: .
Measured verdict: Faster, but io_uring_enter did not drop.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 181.328411 | 150.559959 |
| export_time_s |  |  |
| plan_time_ms | 7 | 6 |
| total_server_ms |  |  |
| response_bytes | 3485348857 | 3485348857 |
| mib_per_s | 18.330761 | 22.076837 |
| cpu_s | 162.010000 | 176.330000 |
| cpu_ratio | 0.892600 | 1.171200 |
| major_faults | 6 | 8 |
| minor_faults | 168457 | 125743 |
| rchar | 1638382904 | 840947379 |
| wchar | 114002 | 101542 |
| read_bytes | 12810039296 | 12679987200 |
| write_bytes | 3026944 | 2514944 |
| syscr | 60932844 | 31249 |
| syscw | 825 | 686 |
| pread64 | 60921326 | 21718 |
| io_uring_enter | 0 | 45395519 |
| utime_ticks | 10203 | 9845 |
| stime_ticks | 5998 | 7721 |
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
| elapsed_s | 25.763628 | 24.441716 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms |  |  |
| response_bytes | 1302749672 | 1302749672 |
| mib_per_s | 48.222979 | 50.831084 |
| cpu_s | 35.950000 | 34.470000 |
| cpu_ratio | 1.395400 | 1.409400 |
| major_faults | 6 | 8 |
| minor_faults | 31867 | 35571 |
| rchar | 481077654 | 481076494 |
| wchar | 17735 | 16949 |
| read_bytes | 509698048 | 509702144 |
| write_bytes | 438272 | 425984 |
| syscr | 11475 | 11394 |
| syscw | 126 | 120 |
| pread64 | 9836 | 9836 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 3560 | 3412 |
| stime_ticks | 35 | 34 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

