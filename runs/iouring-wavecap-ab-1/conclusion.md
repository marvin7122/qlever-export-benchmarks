# Export run diagnosis

Medians over complete reps. Counters are process-wide over the request.

| query | role | elapsed s | cpu s | MiB/s | syscr | pread64 | io_uring_enter | read_bytes | major_faults | bytes | verdict |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| D1 | io_uring-proof | 0.147→0.141 | 0.070→0.070 | 7.10→7.38 | 108→108 | 78→78 | 308→121 | 15622144→15605760 | 5→5 | 1092678 | Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters. |
| D3 | io_uring-proof | 0.653→0.649 | 0.855→0.870 | 16.95→17.07 | 2664→2664 | 2658→2658 | 2246→1038 | 223596544→223592448 | 9→9 | 11611130 | Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters. |
| I-iouring-stars | io_uring-proof | 0.270→0.267 | 0.210→0.200 | 13.79→13.93 | 308→308 | 218→218 | 1200→510 | 54472704→54272000 | 5→5 | 3905790 | Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters. |
| I-iouring-capitals | io_uring-proof | 0.176→0.179 | 0.110→0.110 | 8.65→8.48 | 172→172 | 166→166 | 557→284 | 27580416→27189248 | 6→6 | 1593662 | Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters. |
| H-vocab-random-label | where-dominated | 4.584→4.568 | 3.580→3.565 | 1.03→1.03 | 308937→308937 | 158920→158920 | 0→0 | 983773184→983773184 | 5→5 | 4949275 | Enter count unchanged. This query does not stress ring refill. |
| H-vocab-label-large | serialize-bound | 21.252→21.185 | 30.980→30.975 | 58.46→58.65 | 9846→9846 | 9815→9815 | 0→0 | 509689856→509689856 | 6→6 | 1302749672 | Enter count unchanged. This query does not stress ring refill. |

## D1

Role: io_uring-proof.
CONSTRUCT writes s, p, and o of all outgoing triples.
WHERE: VALUES 10 seeds, S-bound SPO.
High unique VocabIndex IDs, small scan. Suite-2: 0.356s to 0.159s,
syscr 5620 to 108. That is lookupBatch plus io_uring.
Measured verdict: Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.146699 | 0.141283 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms | 69.500000 | 67.500000 |
| response_bytes | 1092678 | 1092678 |
| mib_per_s | 7.103431 | 7.376411 |
| cpu_s | 0.070000 | 0.070000 |
| cpu_ratio | 0.490900 | 0.501950 |
| major_faults | 5 | 5 |
| minor_faults | 4264 | 4278 |
| rchar | 1097767 | 1097767 |
| wchar | 2284 | 2282 |
| read_bytes | 15622144 | 15605760 |
| write_bytes | 4096 | 4096 |
| syscr | 108 | 108 |
| syscw | 12 | 12 |
| pread64 | 78 | 78 |
| io_uring_enter | 308 | 121 |
| utime_ticks | 3 | 3 |
| stime_ticks | 4 | 4 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## D3

Role: io_uring-proof.
CONSTRUCT writes s, p, and o.
WHERE: P+O films P31/Q11424, then S-bound SPO, LIMIT 100000.
Mid-scale dump. Suite-2: 1.847s to 0.630s, syscr 39423 to 2664.
Measured verdict: Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.653458 | 0.648715 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms | 570 | 574.500000 |
| response_bytes | 11611130 | 11611130 |
| mib_per_s | 16.945683 | 17.069672 |
| cpu_s | 0.855000 | 0.870000 |
| cpu_ratio | 1.321250 | 1.348000 |
| major_faults | 9 | 9 |
| minor_faults | 25075 | 25156 |
| rchar | 48882029 | 48882029 |
| wchar | 1710 | 1710 |
| read_bytes | 223596544 | 223592448 |
| write_bytes | 4096 | 4096 |
| syscr | 2664 | 2664 |
| syscw | 10 | 10 |
| pread64 | 2658 | 2658 |
| io_uring_enter | 2246 | 1038 |
| utime_ticks | 62.500000 | 64.500000 |
| stime_ticks | 24.500000 | 23 |
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
| elapsed_s | 0.270080 | 0.267440 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms | 193.500000 | 189 |
| response_bytes | 3905790 | 3905790 |
| mib_per_s | 13.791714 | 13.927843 |
| cpu_s | 0.210000 | 0.200000 |
| cpu_ratio | 0.769700 | 0.754750 |
| major_faults | 5 | 5 |
| minor_faults | 5526 | 5525 |
| rchar | 2964776 | 2964776 |
| wchar | 2552 | 2552 |
| read_bytes | 54472704 | 54272000 |
| write_bytes | 6144 | 4096 |
| syscr | 308 | 308 |
| syscw | 12 | 12 |
| pread64 | 218 | 218 |
| io_uring_enter | 1200 | 510 |
| utime_ticks | 9.500000 | 9.500000 |
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
| elapsed_s | 0.175746 | 0.179202 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms | 99.500000 | 98 |
| response_bytes | 1593662 | 1593662 |
| mib_per_s | 8.648000 | 8.481683 |
| cpu_s | 0.110000 | 0.110000 |
| cpu_ratio | 0.628000 | 0.608600 |
| major_faults | 6 | 6 |
| minor_faults | 4810 | 4808 |
| rchar | 3436932 | 3436932 |
| wchar | 1928 | 1930 |
| read_bytes | 27580416 | 27189248 |
| write_bytes | 4096 | 4096 |
| syscr | 172 | 172 |
| syscw | 10 | 10 |
| pread64 | 166 | 166 |
| io_uring_enter | 557 | 284 |
| utime_ticks | 6 | 6 |
| stime_ticks | 5.500000 | 5 |
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
| elapsed_s | 4.583634 | 4.568238 |
| export_time_s |  |  |
| plan_time_ms | 168.500000 | 170.500000 |
| total_server_ms |  |  |
| response_bytes | 4949275 | 4949275 |
| mib_per_s | 1.029753 | 1.033221 |
| cpu_s | 3.580000 | 3.565000 |
| cpu_ratio | 0.782850 | 0.780650 |
| major_faults | 5 | 5 |
| minor_faults | 25346 | 25350 |
| rchar | 468949443 | 468949443 |
| wchar | 526631 | 526632 |
| read_bytes | 983773184 | 983773184 |
| write_bytes | 528384 | 528384 |
| syscr | 308937 | 308937 |
| syscw | 14 | 14 |
| pread64 | 158920 | 158920 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 290.500000 | 287.500000 |
| stime_ticks | 67 | 68 |
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
| elapsed_s | 21.252179 | 21.184706 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms |  |  |
| response_bytes | 1302749672 | 1302749672 |
| mib_per_s | 58.460282 | 58.646124 |
| cpu_s | 30.980000 | 30.975000 |
| cpu_ratio | 1.459500 | 1.460200 |
| major_faults | 6 | 6 |
| minor_faults | 29737 | 30288 |
| rchar | 481054790 | 481054790 |
| wchar | 2414 | 2414 |
| read_bytes | 509689856 | 509689856 |
| write_bytes | 16384 | 16384 |
| syscr | 9846 | 9846 |
| syscw | 20.500000 | 20.500000 |
| pread64 | 9815 | 9815 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 3069 | 3068 |
| stime_ticks | 29 | 30 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

