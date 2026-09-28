# Export run diagnosis

Medians over complete reps. Counters are process-wide over the request.

| query | role | elapsed s | cpu s | cpu_ratio | wait s | blkio s | syscr | pread64 | io_uring_enter | bytes | verdict |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| D1 | io_uring-proof | 0.146→0.243 | 0.070→0.190 | 0.460→0.787 | 0.077→0.054 | 0→0 | 108→108 | 78→78 | 1012→1174 | 1092678 | No sliding-window signature in the counters. |
| D3 | io_uring-proof | 0.641→2.041 | 0.845→2.425 | 1.319→1.190 | 0→0 | 0→0 | 2664→2665 | 2658→2658 | 873→2126 | 11611130 | No sliding-window signature in the counters. |
| I-iouring-stars | io_uring-proof | 0.280→0.849 | 0.210→0.835 | 0.757→0.997 | 0.068→0.002 | 0→0 | 308→308 | 218→218 | 5612→6276 | 3905790 | No sliding-window signature in the counters. |
| I-iouring-capitals | io_uring-proof | 0.181→0.342 | 0.110→0.305 | 0.615→0.895 | 0.071→0.035 | 0→0 | 172→172 | 166→166 | 2989→3318 | 1593662 | No sliding-window signature in the counters. |
| H-vocab-random-label | where-dominated | 4.569→4.596 | 3.540→3.580 | 0.774→0.779 | 1.028→1.010 | 0→0 | 308937→308937 | 158920→158920 | 0→0 | 4949275 | Enter count unchanged. This query does not stress ring refill. |
| H-vocab-label-large | serialize-bound | 22.577→22.567 | 32.405→32.320 | 1.435→1.434 | 0→0 | 0→0 | 9847→9847 | 9815→9815 | 0→0 | 1302749672 | Enter count unchanged. This query does not stress ring refill. |

## D1

Role: io_uring-proof.
CONSTRUCT writes s, p, and o of all outgoing triples.
WHERE: VALUES 10 seeds, S-bound SPO.
High unique VocabIndex IDs, small scan. Suite-2: 0.356s to 0.159s,
syscr 5620 to 108. That is lookupBatch plus io_uring.
Measured verdict: No sliding-window signature in the counters.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.145900 | 0.243124 |
| first_byte_s | 0.144555 | 0.241728 |
| export_time_s |  |  |
| plan_time_ms | 2 | 2.500000 |
| total_server_ms | 66.500000 | 168.500000 |
| response_bytes | 1092678 | 1092678 |
| mib_per_s | 7.142536 | 4.286117 |
| cpu_s | 0.070000 | 0.190000 |
| cpu_ratio | 0.460300 | 0.787000 |
| blkio_s | 0 | 0 |
| wait_s | 0.077380 | 0.054054 |
| delayacct_blkio_ticks | 0 | 0 |
| major_faults | 0 | 0 |
| minor_faults | 4285 | 4280 |
| rchar | 1097687 | 1097687 |
| wchar | 2284 | 2284 |
| read_bytes | 15851520 | 15851520 |
| write_bytes | 4096 | 4096 |
| syscr | 108 | 108 |
| syscw | 12 | 12 |
| pread64 | 78 | 78 |
| io_uring_enter | 1012 | 1174 |
| utime_ticks | 3 | 3.500000 |
| stime_ticks | 3.500000 | 16 |
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
| elapsed_s | 0.640639 | 2.041361 |
| first_byte_s | 0.393928 | 0.593512 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms | 562.500000 |  |
| response_bytes | 11611130 | 11611130 |
| mib_per_s | 17.284774 | 5.424500 |
| cpu_s | 0.845000 | 2.425000 |
| cpu_ratio | 1.318650 | 1.189550 |
| blkio_s | 0 | 0 |
| wait_s | 0 | 0 |
| delayacct_blkio_ticks | 0 | 0 |
| major_faults | 3 | 3 |
| minor_faults | 25136 | 25272 |
| rchar | 48883610 | 48883650 |
| wchar | 1710 | 1747 |
| read_bytes | 224526336 | 224526336 |
| write_bytes | 4096 | 4096 |
| syscr | 2664 | 2665 |
| syscw | 10 | 11 |
| pread64 | 2658 | 2658 |
| io_uring_enter | 873 | 2126 |
| utime_ticks | 62 | 63 |
| stime_ticks | 23 | 179 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## I-iouring-stars

Role: io_uring-proof.
CONSTRUCT writes s, p, and o.
WHERE: VALUES 30 seeds, S-bound SPO, no LANG filter.
Same mechanism as D1 with more seeds. Fail the claim if pread64
does not fall and io_uring_enter does not rise on the variant.
Measured verdict: No sliding-window signature in the counters.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.279739 | 0.848794 |
| first_byte_s | 0.211252 | 0.529674 |
| export_time_s |  |  |
| plan_time_ms | 2 | 3 |
| total_server_ms | 198.500000 | 757.500000 |
| response_bytes | 3905790 | 3905790 |
| mib_per_s | 13.315511 | 4.388433 |
| cpu_s | 0.210000 | 0.835000 |
| cpu_ratio | 0.756750 | 0.997450 |
| blkio_s | 0 | 0 |
| wait_s | 0.067517 | 0.002366 |
| delayacct_blkio_ticks | 0 | 0 |
| major_faults | 0 | 0 |
| minor_faults | 5592 | 5624 |
| rchar | 2964605 | 2964605 |
| wchar | 2552 | 2552 |
| read_bytes | 57470976 | 57475072 |
| write_bytes | 6144 | 4096 |
| syscr | 308 | 308 |
| syscw | 12 | 12 |
| pread64 | 218 | 218 |
| io_uring_enter | 5612 | 6276 |
| utime_ticks | 10 | 10 |
| stime_ticks | 11.500000 | 74 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## I-iouring-capitals

Role: io_uring-proof.
CONSTRUCT writes s, p, and o.
WHERE: P+O capitals P31/Q5119, then S-bound SPO, LIMIT 50000.
Smaller class than films. Unique objects stay high. Fail the
claim if pread64 does not fall and io_uring_enter does not rise.
Measured verdict: No sliding-window signature in the counters.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.180969 | 0.342373 |
| first_byte_s | 0.178750 | 0.339952 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms | 99 | 260.500000 |
| response_bytes | 1593662 | 1593662 |
| mib_per_s | 8.398363 | 4.439175 |
| cpu_s | 0.110000 | 0.305000 |
| cpu_ratio | 0.615300 | 0.894750 |
| blkio_s | 0 | 0 |
| wait_s | 0.070831 | 0.035489 |
| delayacct_blkio_ticks | 0 | 0 |
| major_faults | 0 | 0 |
| minor_faults | 4826 | 4839 |
| rchar | 3436953 | 3436953 |
| wchar | 1930 | 1930 |
| read_bytes | 29700096 | 29609984 |
| write_bytes | 4096 | 4096 |
| syscr | 172 | 172 |
| syscw | 10 | 10 |
| pread64 | 166 | 166 |
| io_uring_enter | 2989 | 3318 |
| utime_ticks | 5 | 6 |
| stime_ticks | 5.500000 | 24.500000 |
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
| elapsed_s | 4.569140 | 4.595931 |
| first_byte_s | 4.487307 | 4.514678 |
| export_time_s |  |  |
| plan_time_ms | 169 | 168.500000 |
| total_server_ms |  |  |
| response_bytes | 4949275 | 4949275 |
| mib_per_s | 1.033017 | 1.026997 |
| cpu_s | 3.540000 | 3.580000 |
| cpu_ratio | 0.774150 | 0.779200 |
| blkio_s | 0 | 0 |
| wait_s | 1.027901 | 1.010104 |
| delayacct_blkio_ticks | 0 | 0 |
| major_faults | 0 | 0 |
| minor_faults | 25167 | 25344 |
| rchar | 468949443 | 468949443 |
| wchar | 526632 | 526632 |
| read_bytes | 983769088 | 983769088 |
| write_bytes | 528384 | 528384 |
| syscr | 308937 | 308937 |
| syscw | 14 | 14 |
| pread64 | 158920 | 158920 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 285 | 289.500000 |
| stime_ticks | 68 | 68 |
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
| elapsed_s | 22.576576 | 22.566784 |
| first_byte_s | 0.153910 | 0.155389 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms |  |  |
| response_bytes | 1302749672 | 1302749672 |
| mib_per_s | 55.030565 | 55.054317 |
| cpu_s | 32.405000 | 32.320000 |
| cpu_ratio | 1.434800 | 1.434350 |
| blkio_s | 0 | 0 |
| wait_s | 0 | 0 |
| delayacct_blkio_ticks | 0 | 0 |
| major_faults | 0 | 0 |
| minor_faults | 29344 | 33850 |
| rchar | 481054810 | 481054810 |
| wchar | 2431 | 2431 |
| read_bytes | 511410176 | 511410176 |
| write_bytes | 16384 | 16384 |
| syscr | 9847 | 9847 |
| syscw | 21 | 21 |
| pread64 | 9815 | 9815 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 3210 | 3202 |
| stime_ticks | 29.500000 | 30 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

