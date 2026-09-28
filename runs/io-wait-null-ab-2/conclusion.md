# Export run diagnosis

Medians over complete reps. Counters are process-wide over the request.

| query | role | elapsed s | cpu s | MiB/s | syscr | pread64 | io_uring_enter | read_bytes | major_faults | bytes | verdict |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| I-iouring-label-de |  | 62.292→62.619 | 28.700→29.060 | 7.73→7.69 | 8886210→8886210 | 8886179→8886179 | 0→0 | 9615556608→9615556608 | 6→6 | 504927346 | Enter count unchanged. This query does not stress ring refill. |
| D3 | io_uring-proof | 1.875→1.868 | 0.890→0.890 | 5.91→5.93 | 39423→39423 | 39422→39422 | 0→0 | 230895616→230895616 | 9→9 | 11611130 | Enter count unchanged. This query does not stress ring refill. |

## I-iouring-label-de

Role: .
Measured verdict: Enter count unchanged. This query does not stress ring refill.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 62.291994 | 62.619043 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms |  |  |
| response_bytes | 504927346 | 504927346 |
| mib_per_s | 7.730307 | 7.689933 |
| cpu_s | 28.700000 | 29.060000 |
| cpu_ratio | 0.460700 | 0.463900 |
| major_faults | 6 | 6 |
| minor_faults | 48132 | 42566 |
| rchar | 211749567 | 211749567 |
| wchar | 2416 | 2418 |
| read_bytes | 9615556608 | 9615556608 |
| write_bytes | 28672 | 28672 |
| syscr | 8886210 | 8886210 |
| syscw | 41 | 41 |
| pread64 | 8886179 | 8886179 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 1459 | 1495 |
| stime_ticks | 1413 | 1409 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## D3

Role: io_uring-proof.
CONSTRUCT writes s, p, and o.
WHERE: P+O films P31/Q11424, then S-bound SPO, LIMIT 100000.
Mid-scale dump. Suite-2: 1.847s to 0.630s, syscr 39423 to 2664.
Measured verdict: Enter count unchanged. This query does not stress ring refill.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 1.874551 | 1.867832 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms |  |  |
| response_bytes | 11611130 | 11611130 |
| mib_per_s | 5.907142 | 5.928390 |
| cpu_s | 0.890000 | 0.890000 |
| cpu_ratio | 0.474800 | 0.471600 |
| major_faults | 9 | 9 |
| minor_faults | 25152 | 25074 |
| rchar | 49520478 | 49520478 |
| wchar | 1746 | 1746 |
| read_bytes | 230895616 | 230895616 |
| write_bytes | 4096 | 4096 |
| syscr | 39423 | 39423 |
| syscw | 11 | 11 |
| pread64 | 39422 | 39422 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 66 | 65 |
| stime_ticks | 23 | 23 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

