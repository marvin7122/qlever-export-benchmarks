# Export run diagnosis

Medians over complete reps. Counters are process-wide over the request.

| query | role | elapsed s | cpu s | MiB/s | syscr | pread64 | io_uring_enter | read_bytes | major_faults | bytes | verdict |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| H-vocab-label-large | serialize-bound | 22.763→21.101 | 32.460→30.920 | 54.58→58.88 | 9847→9846 | 9815→9815 | 0→0 | 509673472→509681664 | 9→6 | 1302749672 | pread64 unchanged. This query does not exercise io_uring. |
| H-vocab-label-small | fixed-cost | 0.194→0.204 | 0.190→0.200 | 0.11→0.10 | 668→668 | 647→647 | 0→0 | 40013824→40022016 | 9→6 | 21636 | pread64 unchanged. This query does not exercise io_uring. |
| H-vocab-description-large | serialize-bound | 0.232→0.215 | 0.230→0.220 | 46.57→50.36 | 237→237 | 216→216 | 0→0 | 10801152→10813440 | 12→9 | 11331291 | pread64 unchanged. This query does not exercise io_uring. |
| H-vocab-description-small | fixed-cost | 0.197→0.191 | 0.180→0.170 | 0.12→0.12 | 674→674 | 653→653 | 0→0 | 50855936→50864128 | 9→6 | 24490 | pread64 unchanged. This query does not exercise io_uring. |
| H-size | bounded-serialize | 0.302→0.287 | 0.330→0.300 | 34.98→36.76 | 234→234 | 213→213 | 0→0 | 12652544→12664832 | 12→9 | 11078871 | pread64 unchanged. This query does not exercise io_uring. |
| H-vocab-random-label | where-dominated | 4.646→4.553 | 3.710→3.550 | 1.02→1.04 | 308937→308937 | 158920→158920 | 0→0 | 983756800→983769088 | 9→7 | 4949275 | pread64 unchanged. This query does not exercise io_uring. |
| D1 | io_uring-proof | 0.358→0.159 | 0.070→0.070 | 2.91→6.54 | 5620→108 | 2834→78 | 0→1010 | 19410944→15597568 | 9→6 | 1092678 | ID-to-string left pread for io_uring. Elapsed also fell. |
| D3 | io_uring-proof | 1.876→0.661 | 0.880→0.870 | 5.90→16.74 | 39423→2664 | 21037→2658 | 0→825 | 230858752→223580160 | 12→9 | 11611130 | ID-to-string left pread for io_uring. Elapsed also fell. |
| I-iouring-stars | io_uring-proof | 0.975→0.276 | 0.220→0.220 | 3.82→13.48 | 22270→308 | 11199→218 | 0→5603 | 64770048→54239232 | 9→6 | 3905790 | ID-to-string left pread for io_uring. Elapsed also fell. |
| I-iouring-capitals | io_uring-proof | 0.421→0.177 | 0.110→0.110 | 3.61→8.58 | 10600→172 | 5380→166 | 0→3000 | 32514048→27193344 | 9→6 | 1593662 | ID-to-string left pread for io_uring. Elapsed also fell. |

## H-vocab-label-large

Role: serialize-bound.
CONSTRUCT writes entity IRI + rdfs:label.
WHERE: P+O class scan P31/Q5, then S+P label, LANG=en.
Output is about 1.3 GiB. syscr stayed 9847 on both arms. That count
is too small for per-word label pread. The scan is mmap. A time
change here is serialize or CPU, not io_uring.
Measured verdict: pread64 unchanged. This query does not exercise io_uring.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 22.762593 | 21.100687 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms |  |  |
| response_bytes | 1302749672 | 1302749672 |
| mib_per_s | 54.580728 | 58.879548 |
| cpu_s | 32.460000 | 30.920000 |
| cpu_ratio | 1.423800 | 1.463700 |
| major_faults | 9 | 6 |
| minor_faults | 31285 | 28214 |
| rchar | 481054810 | 481054770 |
| wchar | 2431 | 2394 |
| read_bytes | 509673472 | 509681664 |
| write_bytes | 16384 | 16384 |
| syscr | 9847 | 9846 |
| syscw | 21 | 20 |
| pread64 | 9815 | 9815 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 3217 | 3062 |
| stime_ticks | 29 | 30 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## H-vocab-label-small

Role: fixed-cost.
CONSTRUCT writes entity IRI + rdfs:label.
WHERE: P+O class scan P31/Q6256, S+P label, LANG=en, LIMIT 10000.
Same plan as label-large on a small class. syscr stayed 668.
Measured verdict: pread64 unchanged. This query does not exercise io_uring.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.194439 | 0.204382 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms | 119 | 125 |
| response_bytes | 21636 | 21636 |
| mib_per_s | 0.106119 | 0.100956 |
| cpu_s | 0.190000 | 0.200000 |
| cpu_ratio | 0.997000 | 0.956700 |
| major_faults | 9 | 6 |
| minor_faults | 2704 | 2766 |
| rchar | 32178982 | 32178982 |
| wchar | 1840 | 1838 |
| read_bytes | 40013824 | 40022016 |
| write_bytes | 4096 | 4096 |
| syscr | 668 | 668 |
| syscw | 10 | 10 |
| pread64 | 647 | 647 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 16 | 17 |
| stime_ticks | 3 | 3 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## H-vocab-description-large

Role: serialize-bound.
CONSTRUCT writes entity IRI + schema:description.
WHERE: humans, then description, LANG=en, LIMIT 100000.
Same structure as labels. syscr stayed 237.
Measured verdict: pread64 unchanged. This query does not exercise io_uring.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.232032 | 0.214563 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms | 156 | 146 |
| response_bytes | 11331291 | 11331291 |
| mib_per_s | 46.572735 | 50.364502 |
| cpu_s | 0.230000 | 0.220000 |
| cpu_ratio | 0.991200 | 1.044300 |
| major_faults | 12 | 9 |
| minor_faults | 10031 | 10056 |
| rchar | 4513049 | 4513049 |
| wchar | 1875 | 1877 |
| read_bytes | 10801152 | 10813440 |
| write_bytes | 4096 | 4096 |
| syscr | 237 | 237 |
| syscw | 10 | 10 |
| pread64 | 216 | 216 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 21 | 20 |
| stime_ticks | 2 | 3 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## H-vocab-description-small

Role: fixed-cost.
CONSTRUCT writes entity IRI + schema:description.
WHERE: countries, description, LANG=en, LIMIT 10000.
Small country description export. syscr stayed 674.
Measured verdict: pread64 unchanged. This query does not exercise io_uring.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.196777 | 0.191348 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms | 108 | 105 |
| response_bytes | 24490 | 24490 |
| mib_per_s | 0.118690 | 0.122058 |
| cpu_s | 0.180000 | 0.170000 |
| cpu_ratio | 0.914700 | 0.871300 |
| major_faults | 9 | 6 |
| minor_faults | 2747 | 2831 |
| rchar | 17084191 | 17084191 |
| wchar | 1794 | 1794 |
| read_bytes | 50855936 | 50864128 |
| write_bytes | 4096 | 4096 |
| syscr | 674 | 674 |
| syscw | 10 | 10 |
| pread64 | 653 | 653 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 15 | 14 |
| stime_ticks | 3 | 2 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## H-size

Role: bounded-serialize.
CONSTRUCT writes entity IRI + rdfs:label.
WHERE: same as label-large, LIMIT 100000.
Bounded humans-label. syscr stayed 234.
Measured verdict: pread64 unchanged. This query does not exercise io_uring.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.302071 | 0.287431 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms | 225 | 211 |
| response_bytes | 11078871 | 11078871 |
| mib_per_s | 34.977369 | 36.758821 |
| cpu_s | 0.330000 | 0.300000 |
| cpu_ratio | 1.092500 | 1.043700 |
| major_faults | 12 | 9 |
| minor_faults | 9882 | 10007 |
| rchar | 7384068 | 7384068 |
| wchar | 1859 | 1859 |
| read_bytes | 12652544 | 12664832 |
| write_bytes | 4096 | 4096 |
| syscr | 234 | 234 |
| syscw | 10 | 10 |
| pread64 | 213 | 213 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 30 | 27 |
| stime_ticks | 3 | 3 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## H-vocab-random-label

Role: where-dominated.
CONSTRUCT writes entity IRI + rdfs:label.
WHERE: VALUES 50000 IRIs, S+P label, LANG=en.
syscr stayed 308937. Most of that is string-to-ID binary search
for VALUES, still pread. PR 47 does not change that path.
Measured verdict: pread64 unchanged. This query does not exercise io_uring.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 4.646223 | 4.553315 |
| export_time_s |  |  |
| plan_time_ms | 169 | 168 |
| total_server_ms |  |  |
| response_bytes | 4949275 | 4949275 |
| mib_per_s | 1.015878 | 1.036607 |
| cpu_s | 3.710000 | 3.550000 |
| cpu_ratio | 0.798100 | 0.779700 |
| major_faults | 9 | 7 |
| minor_faults | 23411 | 23613 |
| rchar | 468949443 | 468949443 |
| wchar | 526730 | 526729 |
| read_bytes | 983756800 | 983769088 |
| write_bytes | 528384 | 528384 |
| syscr | 308937 | 308937 |
| syscw | 15 | 15 |
| pread64 | 158920 | 158920 |
| io_uring_enter | 0 | 0 |
| utime_ticks | 304 | 288 |
| stime_ticks | 67 | 68 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## D1

Role: io_uring-proof.
CONSTRUCT writes s, p, and o of all outgoing triples.
WHERE: VALUES 10 seeds, S-bound SPO.
High unique VocabIndex IDs, small scan. Suite-2: 0.356s to 0.159s,
syscr 5620 to 108. That is lookupBatch plus io_uring.
Measured verdict: ID-to-string left pread for io_uring. Elapsed also fell.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.357914 | 0.159413 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms | 274 | 70 |
| response_bytes | 1092678 | 1092678 |
| mib_per_s | 2.911481 | 6.536854 |
| cpu_s | 0.070000 | 0.070000 |
| cpu_ratio | 0.198200 | 0.438800 |
| major_faults | 9 | 6 |
| minor_faults | 4231 | 4287 |
| rchar | 1196974 | 1097767 |
| wchar | 2283 | 2282 |
| read_bytes | 19410944 | 15597568 |
| write_bytes | 4096 | 4096 |
| syscr | 5620 | 108 |
| syscw | 12 | 12 |
| pread64 | 2834 | 78 |
| io_uring_enter | 0 | 1010 |
| utime_ticks | 4 | 3 |
| stime_ticks | 4 | 4 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## D3

Role: io_uring-proof.
CONSTRUCT writes s, p, and o.
WHERE: P+O films P31/Q11424, then S-bound SPO, LIMIT 100000.
Mid-scale dump. Suite-2: 1.847s to 0.630s, syscr 39423 to 2664.
Measured verdict: ID-to-string left pread for io_uring. Elapsed also fell.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 1.875631 | 0.661441 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms |  | 586 |
| response_bytes | 11611130 | 11611130 |
| mib_per_s | 5.903738 | 16.741072 |
| cpu_s | 0.880000 | 0.870000 |
| cpu_ratio | 0.472000 | 1.307800 |
| major_faults | 12 | 9 |
| minor_faults | 24965 | 25146 |
| rchar | 49520478 | 48882029 |
| wchar | 1746 | 1708 |
| read_bytes | 230858752 | 223580160 |
| write_bytes | 4096 | 4096 |
| syscr | 39423 | 2664 |
| syscw | 11 | 10 |
| pread64 | 21037 | 2658 |
| io_uring_enter | 0 | 825 |
| utime_ticks | 65 | 62 |
| stime_ticks | 23 | 24 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## I-iouring-stars

Role: io_uring-proof.
CONSTRUCT writes s, p, and o.
WHERE: VALUES 30 seeds, S-bound SPO, no LANG filter.
Same mechanism as D1 with more seeds. Fail the claim if pread64
does not fall and io_uring_enter does not rise on the variant.
Measured verdict: ID-to-string left pread for io_uring. Elapsed also fell.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.974669 | 0.276315 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms | 901 | 199 |
| response_bytes | 3905790 | 3905790 |
| mib_per_s | 3.821657 | 13.480440 |
| cpu_s | 0.220000 | 0.220000 |
| cpu_ratio | 0.225700 | 0.768300 |
| major_faults | 9 | 6 |
| minor_faults | 5437 | 5490 |
| rchar | 3353475 | 2964776 |
| wchar | 2552 | 2554 |
| read_bytes | 64770048 | 54239232 |
| write_bytes | 4096 | 4096 |
| syscr | 22270 | 308 |
| syscw | 12 | 12 |
| pread64 | 11199 | 218 |
| io_uring_enter | 0 | 5603 |
| utime_ticks | 11 | 9 |
| stime_ticks | 11 | 12 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## I-iouring-capitals

Role: io_uring-proof.
CONSTRUCT writes s, p, and o.
WHERE: P+O capitals P31/Q5119, then S-bound SPO, LIMIT 50000.
Smaller class than films. Unique objects stay high. Fail the
claim if pread64 does not fall and io_uring_enter does not rise.
Measured verdict: ID-to-string left pread for io_uring. Elapsed also fell.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 0.421341 | 0.177149 |
| export_time_s |  |  |
| plan_time_ms | 3 | 3 |
| total_server_ms | 340 | 100 |
| response_bytes | 1593662 | 1593662 |
| mib_per_s | 3.607140 | 8.579430 |
| cpu_s | 0.110000 | 0.110000 |
| cpu_ratio | 0.268400 | 0.601100 |
| major_faults | 9 | 6 |
| minor_faults | 4810 | 4894 |
| rchar | 3585859 | 3436932 |
| wchar | 1929 | 1930 |
| read_bytes | 32514048 | 27193344 |
| write_bytes | 4096 | 4096 |
| syscr | 10600 | 172 |
| syscw | 10 | 10 |
| pread64 | 5380 | 166 |
| io_uring_enter | 0 | 3000 |
| utime_ticks | 6 | 5 |
| stime_ticks | 5 | 5 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

