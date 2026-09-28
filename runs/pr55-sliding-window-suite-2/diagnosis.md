# Export run diagnosis

Medians over complete reps. Counters are process-wide over the request.

| query | role | elapsed s | cpu s | MiB/s | syscr | pread64 | io_uring_enter | read_bytes | major_faults | bytes | verdict |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| H-vocab-label-large | serialize-bound | 21.306→20.833 | 31.040→30.640 | 58.31→59.64 | 9847→9847 | 9815→9815 | 0→0 | 509681664→509689856 | 6→6 | 1302749672 | Enter count unchanged. This query does not stress ring refill. |
| H-vocab-label-small | fixed-cost | 0.195→0.199 | 0.190→0.190 | 0.11→0.10 | 668→668 | 647→647 | 0→0 | 40022016→40030208 | 6→6 | 21636 | Enter count unchanged. This query does not stress ring refill. |
| H-vocab-description-large | serialize-bound | 0.220→0.219 | 0.230→0.220 | 49.03→49.28 | 237→237 | 216→216 | 0→0 | 10813440→10825728 | 9→9 | 11331291 | Enter count unchanged. This query does not stress ring refill. |
| H-vocab-description-small | fixed-cost | 0.186→0.193 | 0.160→0.170 | 0.13→0.12 | 674→674 | 653→653 | 0→0 | 50864128→50872320 | 6→6 | 24490 | Enter count unchanged. This query does not stress ring refill. |
| H-size | bounded-serialize | 0.301→0.294 | 0.300→0.300 | 35.11→35.90 | 234→234 | 213→213 | 0→0 | 12664832→12677120 | 9→9 | 11078871 | Enter count unchanged. This query does not stress ring refill. |
| H-vocab-random-label | where-dominated | 4.570→4.525 | 3.590→3.490 | 1.03→1.04 | 308937→308937 | 158920→158920 | 0→0 | 983769088→983773184 | 7→5 | 4949275 | Enter count unchanged. This query does not stress ring refill. |
| D1 | io_uring-proof | 0.149→0.151 | 0.070→0.070 | 6.98→6.89 | 108→108 | 78→78 | 1006→310 | 15597568→15622144 | 6→5 | 1092678 | Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters. |
| D3 | io_uring-proof | 0.629→0.662 | 0.830→0.860 | 17.61→16.73 | 2664→2664 | 2658→2658 | 901→2248 | 223580160→223596544 | 9→9 | 11611130 | No sliding-window signature in the counters. |
| I-iouring-stars | io_uring-proof | 0.285→0.267 | 0.210→0.210 | 13.07→13.97 | 308→308 | 218→218 | 5600→1201 | 54263808→54472704 | 6→5 | 3905790 | Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters. |
| I-iouring-capitals | io_uring-proof | 0.178→0.179 | 0.110→0.110 | 8.52→8.49 | 172→172 | 166→166 | 3000→558 | 27181056→27578368 | 6→6 | 1593662 | Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters. |

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
| elapsed_s | 21.305585 | 20.833237 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms |  |  |
| response_bytes | 1302749672 | 1302749672 |
| mib_per_s | 58.313296 | 59.635422 |
| cpu_s | 31.040000 | 30.640000 |
| cpu_ratio | 1.454200 | 1.470200 |
| major_faults | 6 | 6 |
| minor_faults | 29685 | 29625 |
| rchar | 481054810 | 481054810 |
| wchar | 2431 | 2432 |
| read_bytes | 509681664 | 509689856 |
| write_bytes | 16384 | 16384 |
| syscr | 9847 | 9847 |
| syscw | 21 | 21 |
| pread64 | 9815 | 9815 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 3075 | 3035 |
| stime_ticks | 29 | 29 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## H-vocab-label-small

Role: fixed-cost.
CONSTRUCT writes entity IRI + rdfs:label.
WHERE: P+O class scan P31/Q6256, S+P label, LANG=en, LIMIT 10000.
Same plan as label-large on a small class. syscr stayed 668.
Measured verdict: Enter count unchanged. This query does not stress ring refill.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.195338 | 0.198690 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms | 119 | 121 |
| response_bytes | 21636 | 21636 |
| mib_per_s | 0.105631 | 0.103849 |
| cpu_s | 0.190000 | 0.190000 |
| cpu_ratio | 0.962200 | 0.948900 |
| major_faults | 6 | 6 |
| minor_faults | 2710 | 2701 |
| rchar | 32178982 | 32178982 |
| wchar | 1840 | 1840 |
| read_bytes | 40022016 | 40030208 |
| write_bytes | 4096 | 4096 |
| syscr | 668 | 668 |
| syscw | 10 | 10 |
| pread64 | 647 | 647 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 16 | 16 |
| stime_ticks | 2 | 3 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## H-vocab-description-large

Role: serialize-bound.
CONSTRUCT writes entity IRI + schema:description.
WHERE: humans, then description, LANG=en, LIMIT 100000.
Same structure as labels. syscr stayed 237.
Measured verdict: Enter count unchanged. This query does not stress ring refill.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.220403 | 0.219294 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms | 144 | 140 |
| response_bytes | 11331291 | 11331291 |
| mib_per_s | 49.030016 | 49.277985 |
| cpu_s | 0.230000 | 0.220000 |
| cpu_ratio | 1.003300 | 1.003200 |
| major_faults | 9 | 9 |
| minor_faults | 10076 | 10049 |
| rchar | 4513049 | 4513049 |
| wchar | 1877 | 1875 |
| read_bytes | 10813440 | 10825728 |
| write_bytes | 4096 | 4096 |
| syscr | 237 | 237 |
| syscw | 10 | 10 |
| pread64 | 216 | 216 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 20 | 19 |
| stime_ticks | 2 | 3 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## H-vocab-description-small

Role: fixed-cost.
CONSTRUCT writes entity IRI + schema:description.
WHERE: countries, description, LANG=en, LIMIT 10000.
Small country description export. syscr stayed 674.
Measured verdict: Enter count unchanged. This query does not stress ring refill.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.186346 | 0.192627 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms | 100 | 106 |
| response_bytes | 24490 | 24490 |
| mib_per_s | 0.125334 | 0.121247 |
| cpu_s | 0.160000 | 0.170000 |
| cpu_ratio | 0.912100 | 0.962900 |
| major_faults | 6 | 6 |
| minor_faults | 2761 | 2826 |
| rchar | 17084191 | 17084191 |
| wchar | 1794 | 1794 |
| read_bytes | 50864128 | 50872320 |
| write_bytes | 4096 | 4096 |
| syscr | 674 | 674 |
| syscw | 10 | 10 |
| pread64 | 653 | 653 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 14 | 14 |
| stime_ticks | 3 | 3 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## H-size

Role: bounded-serialize.
CONSTRUCT writes entity IRI + rdfs:label.
WHERE: same as label-large, LIMIT 100000.
Bounded humans-label. syscr stayed 234.
Measured verdict: Enter count unchanged. This query does not stress ring refill.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.300902 | 0.294294 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms | 213 | 212 |
| response_bytes | 11078871 | 11078871 |
| mib_per_s | 35.113246 | 35.901589 |
| cpu_s | 0.300000 | 0.300000 |
| cpu_ratio | 1.019200 | 1.026800 |
| major_faults | 9 | 9 |
| minor_faults | 9950 | 9975 |
| rchar | 7384068 | 7384068 |
| wchar | 1859 | 1857 |
| read_bytes | 12664832 | 12677120 |
| write_bytes | 4096 | 4096 |
| syscr | 234 | 234 |
| syscw | 10 | 10 |
| pread64 | 213 | 213 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 27 | 28 |
| stime_ticks | 3 | 2 |
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
| elapsed_s | 4.570356 | 4.524883 |
| export_time_s |  |  |
| plan_time_ms | 168 | 171 |
| total_server_ms |  |  |
| response_bytes | 4949275 | 4949275 |
| mib_per_s | 1.032741 | 1.043120 |
| cpu_s | 3.590000 | 3.490000 |
| cpu_ratio | 0.785400 | 0.770900 |
| major_faults | 7 | 5 |
| minor_faults | 23558 | 25255 |
| rchar | 468949443 | 468949443 |
| wchar | 526729 | 526631 |
| read_bytes | 983769088 | 983773184 |
| write_bytes | 528384 | 528384 |
| syscr | 308937 | 308937 |
| syscw | 15 | 14 |
| pread64 | 158920 | 158920 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 294 | 281 |
| stime_ticks | 65 | 69 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## D1

Role: io_uring-proof.
CONSTRUCT writes s, p, and o of all outgoing triples.
WHERE: VALUES 10 seeds, S-bound SPO.
High unique VocabIndex IDs, small scan. Suite-2: 0.356s to 0.159s,
syscr 5620 to 108. That is lookupBatch plus io_uring.
Measured verdict: Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.149329 | 0.151277 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms | 70 | 68 |
| response_bytes | 1092678 | 1092678 |
| mib_per_s | 6.978294 | 6.888401 |
| cpu_s | 0.070000 | 0.070000 |
| cpu_ratio | 0.472500 | 0.462700 |
| major_faults | 6 | 5 |
| minor_faults | 4269 | 4264 |
| rchar | 1097767 | 1097767 |
| wchar | 2284 | 2282 |
| read_bytes | 15597568 | 15622144 |
| write_bytes | 4096 | 4096 |
| syscr | 108 | 108 |
| syscw | 12 | 12 |
| pread64 | 78 | 78 |
| io_uring_enter | 1006 | 310 |
| utime_ticks | 3 | 3 |
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
| elapsed_s | 0.628710 | 0.661733 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms | 548 | 571 |
| response_bytes | 11611130 | 11611130 |
| mib_per_s | 17.612636 | 16.733693 |
| cpu_s | 0.830000 | 0.860000 |
| cpu_ratio | 1.306600 | 1.305100 |
| major_faults | 9 | 9 |
| minor_faults | 25161 | 25107 |
| rchar | 48882029 | 48882029 |
| wchar | 1708 | 1710 |
| read_bytes | 223580160 | 223596544 |
| write_bytes | 4096 | 4096 |
| syscr | 2664 | 2664 |
| syscw | 10 | 10 |
| pread64 | 2658 | 2658 |
| io_uring_enter | 901 | 2248 |
| utime_ticks | 60 | 63 |
| stime_ticks | 23 | 23 |
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
| elapsed_s | 0.284938 | 0.266669 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms | 198 | 194 |
| response_bytes | 3905790 | 3905790 |
| mib_per_s | 13.072503 | 13.968047 |
| cpu_s | 0.210000 | 0.210000 |
| cpu_ratio | 0.754200 | 0.762200 |
| major_faults | 6 | 5 |
| minor_faults | 5498 | 5529 |
| rchar | 2964776 | 2964776 |
| wchar | 2554 | 2552 |
| read_bytes | 54263808 | 54472704 |
| write_bytes | 8192 | 4096 |
| syscr | 308 | 308 |
| syscw | 12 | 12 |
| pread64 | 218 | 218 |
| io_uring_enter | 5600 | 1201 |
| utime_ticks | 10 | 10 |
| stime_ticks | 12 | 11 |
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
| elapsed_s | 0.178391 | 0.178980 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms | 103 | 97 |
| response_bytes | 1593662 | 1593662 |
| mib_per_s | 8.519687 | 8.491656 |
| cpu_s | 0.110000 | 0.110000 |
| cpu_ratio | 0.619600 | 0.614600 |
| major_faults | 6 | 6 |
| minor_faults | 4894 | 4804 |
| rchar | 3436932 | 3436932 |
| wchar | 1930 | 1929 |
| read_bytes | 27181056 | 27578368 |
| write_bytes | 4096 | 4096 |
| syscr | 172 | 172 |
| syscw | 10 | 10 |
| pread64 | 166 | 166 |
| io_uring_enter | 3000 | 558 |
| utime_ticks | 6 | 6 |
| stime_ticks | 6 | 5 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

