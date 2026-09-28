# Export run diagnosis

Medians over complete reps. Counters are process-wide over the request.

| query | role | elapsed s | cpu s | MiB/s | syscr | pread64 | io_uring_enter | read_bytes | major_faults | bytes | verdict |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| D1 | io_uring-proof | 0.153→0.147 | 0.070→0.070 | 6.83→7.10 | 108→108 | 78→78 | 125→63 | 15605760→15593472 | 5→5 | 1092678 | Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters. |
| D3 | io_uring-proof | 0.637→0.642 | 0.840→0.855 | 17.38→17.25 | 2664→2664 | 2658→2658 | 1039→977 | 223592448→223592448 | 9→9 | 11611130 | No sliding-window signature in the counters. |
| I-iouring-stars | io_uring-proof | 0.270→0.265 | 0.210→0.200 | 13.81→14.04 | 308→308 | 218→218 | 508→245 | 54272000→54259712 | 5→5 | 3905790 | Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters. |
| I-iouring-capitals | io_uring-proof | 0.179→0.172 | 0.110→0.110 | 8.49→8.81 | 172→172 | 166→166 | 286→110 | 27189248→27222016 | 6→6 | 1593662 | Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters. |
| H-vocab-random-label | where-dominated | 4.561→4.545 | 3.570→3.530 | 1.03→1.04 | 308937→308937 | 158920→158920 | 0→0 | 983773184→983773184 | 5→5 | 4949275 | Enter count unchanged. This query does not stress ring refill. |
| H-vocab-label-large | serialize-bound | 21.239→21.165 | 30.975→30.900 | 58.50→58.70 | 9846→9846 | 9815→9815 | 0→0 | 509689856→509689856 | 6→6 | 1302749672 | Enter count unchanged. This query does not stress ring refill. |

## D1

Role: io_uring-proof.
CONSTRUCT writes s, p, and o of all outgoing triples.
WHERE: VALUES 10 seeds, S-bound SPO.
High unique VocabIndex IDs, small scan. Suite-2: 0.356s to 0.159s,
syscr 5620 to 108. That is lookupBatch plus io_uring.
Measured verdict: Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.152671 | 0.146699 |
| export_time_s |  |  |
| plan_time_ms | 3 | 2.500000 |
| total_server_ms | 67 | 66 |
| response_bytes | 1092678 | 1092678 |
| mib_per_s | 6.826017 | 7.103366 |
| cpu_s | 0.070000 | 0.070000 |
| cpu_ratio | 0.465200 | 0.479050 |
| major_faults | 5 | 5 |
| minor_faults | 4274 | 4268 |
| rchar | 1097767 | 1097767 |
| wchar | 2283 | 2284 |
| read_bytes | 15605760 | 15593472 |
| write_bytes | 4096 | 4096 |
| syscr | 108 | 108 |
| syscw | 12 | 12 |
| pread64 | 78 | 78 |
| io_uring_enter | 125 | 63 |
| utime_ticks | 4 | 3 |
| stime_ticks | 4 | 4 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## D3

Role: io_uring-proof.
CONSTRUCT writes s, p, and o.
WHERE: P+O films P31/Q11424, then S-bound SPO, LIMIT 100000.
Mid-scale dump. Suite-2: 1.847s to 0.630s, syscr 39423 to 2664.
Measured verdict: No sliding-window signature in the counters.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.637158 | 0.641895 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms | 557 | 561 |
| response_bytes | 11611130 | 11611130 |
| mib_per_s | 17.380015 | 17.253479 |
| cpu_s | 0.840000 | 0.855000 |
| cpu_ratio | 1.317250 | 1.316950 |
| major_faults | 9 | 9 |
| minor_faults | 25092 | 25107 |
| rchar | 48882029 | 48882029 |
| wchar | 1709 | 1710 |
| read_bytes | 223592448 | 223592448 |
| write_bytes | 4096 | 4096 |
| syscr | 2664 | 2664 |
| syscw | 10 | 10 |
| pread64 | 2658 | 2658 |
| io_uring_enter | 1039 | 977 |
| utime_ticks | 61.500000 | 61.500000 |
| stime_ticks | 23 | 22.500000 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## I-iouring-stars

Role: io_uring-proof.
CONSTRUCT writes s, p, and o.
WHERE: VALUES 30 seeds, S-bound SPO, no LANG filter.
Same mechanism as D1 with more seeds. Fail the claim if pread64
does not fall and io_uring_enter does not rise on the variant.
Measured verdict: Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.269803 | 0.265385 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms | 192.500000 | 187.500000 |
| response_bytes | 3905790 | 3905790 |
| mib_per_s | 13.806318 | 14.035671 |
| cpu_s | 0.210000 | 0.200000 |
| cpu_ratio | 0.771550 | 0.758450 |
| major_faults | 5 | 5 |
| minor_faults | 5576 | 5514 |
| rchar | 2964776 | 2964776 |
| wchar | 2554 | 2552 |
| read_bytes | 54272000 | 54259712 |
| write_bytes | 4096 | 6144 |
| syscr | 308 | 308 |
| syscw | 12 | 12 |
| pread64 | 218 | 218 |
| io_uring_enter | 508.500000 | 245 |
| utime_ticks | 10 | 9 |
| stime_ticks | 11 | 11 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## I-iouring-capitals

Role: io_uring-proof.
CONSTRUCT writes s, p, and o.
WHERE: P+O capitals P31/Q5119, then S-bound SPO, LIMIT 50000.
Smaller class than films. Unique objects stay high. Fail the
claim if pread64 does not fall and io_uring_enter does not rise.
Measured verdict: Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.179128 | 0.172467 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms | 98.500000 | 98.500000 |
| response_bytes | 1593662 | 1593662 |
| mib_per_s | 8.491754 | 8.813835 |
| cpu_s | 0.110000 | 0.110000 |
| cpu_ratio | 0.637450 | 0.623850 |
| major_faults | 6 | 6 |
| minor_faults | 4808 | 4802 |
| rchar | 3436932 | 3436932 |
| wchar | 1929 | 1929 |
| read_bytes | 27189248 | 27222016 |
| write_bytes | 4096 | 4096 |
| syscr | 172 | 172 |
| syscw | 10 | 10 |
| pread64 | 166 | 166 |
| io_uring_enter | 285.500000 | 110 |
| utime_ticks | 6 | 5.500000 |
| stime_ticks | 5 | 5 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## H-vocab-random-label

Role: where-dominated.
CONSTRUCT writes entity IRI + rdfs:label.
WHERE: VALUES 50000 IRIs, S+P label, LANG=en.
syscr stayed 308937. Most of that is string-to-ID binary search
for VALUES, still pread. PR 47 does not change that path.
Measured verdict: Enter count unchanged. This query does not stress ring refill.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 4.561348 | 4.545221 |
| export_time_s |  |  |
| plan_time_ms | 169 | 170 |
| total_server_ms |  |  |
| response_bytes | 4949275 | 4949275 |
| mib_per_s | 1.034783 | 1.038453 |
| cpu_s | 3.570000 | 3.530000 |
| cpu_ratio | 0.782650 | 0.776900 |
| major_faults | 5 | 5 |
| minor_faults | 25290 | 25408 |
| rchar | 468949443 | 468949443 |
| wchar | 526631 | 526632 |
| read_bytes | 983773184 | 983773184 |
| write_bytes | 528384 | 528384 |
| syscr | 308937 | 308937 |
| syscw | 14 | 14 |
| pread64 | 158920 | 158920 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 289.500000 | 285 |
| stime_ticks | 68 | 68.500000 |
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
| elapsed_s | 21.238903 | 21.164894 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms |  |  |
| response_bytes | 1302749672 | 1302749672 |
| mib_per_s | 58.496511 | 58.700983 |
| cpu_s | 30.975000 | 30.900000 |
| cpu_ratio | 1.461250 | 1.460700 |
| major_faults | 6 | 6 |
| minor_faults | 28799 | 30213 |
| rchar | 481054770 | 481054770 |
| wchar | 2396 | 2396 |
| read_bytes | 509689856 | 509689856 |
| write_bytes | 16384 | 16384 |
| syscr | 9846 | 9846 |
| syscw | 20 | 20 |
| pread64 | 9815 | 9815 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 3067 | 3060 |
| stime_ticks | 30.500000 | 29 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

