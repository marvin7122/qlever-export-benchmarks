# Export run diagnosis

Medians over complete reps. Counters are process-wide over the request.

| query | role | elapsed s | cpu s | cpu_ratio | wait s | blkio s | syscr | pread64 | io_uring_enter | bytes | verdict |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| I-iouring-label-de | io_uring-proof | 26.675→23.353 | 29.940→26.300 | 1.121→1.126 | 0→0 | 0→0 | 2685→2681 | 2612→2612 | 6636722→140923 | 504927346 | Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters. |
| I-iouring-label-nonen | wait-utilization-treatment | 139.568→119.870 | 164.810→143.850 | 1.180→1.199 | 0→0 | 0→0 | 21998→21958 | 21637→21637 | 45397459→795085 | 3485348857 | Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters. |

## I-iouring-label-de

Role: io_uring-proof.
CONSTRUCT writes entity IRI + rdfs:label.
WHERE: P+O class scan P31/Q5, then S+P label, LANG=de.
Same scan as H-vocab-label-large. The language is not in
languages-internal, so the label strings are on-disk compressed
words, not RAM. Fail the claim if io_uring_enter stays 0.
Measured verdict: Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 26.675246 | 23.352918 |
| first_byte_s | 0.480651 | 0.419283 |
| export_time_s |  |  |
| plan_time_ms | 4 | 3 |
| total_server_ms |  |  |
| response_bytes | 504927346 | 504927346 |
| mib_per_s | 18.051801 | 20.619960 |
| cpu_s | 29.940000 | 26.300000 |
| cpu_ratio | 1.121500 | 1.126200 |
| blkio_s | 0 | 0 |
| wait_s | 0 | 0 |
| delayacct_blkio_ticks | 0 | 0 |
| major_faults | 0 | 0 |
| minor_faults | 22395 | 20748 |
| rchar | 97586794 | 97586519 |
| wchar | 3246 | 3185 |
| read_bytes | 9431678976 | 9438154752 |
| write_bytes | 20480 | 16384 |
| syscr | 2685 | 2681 |
| syscw | 23 | 22 |
| pread64 | 2612 | 2612 |
| io_uring_enter | 6636722 | 140923 |
| utime_ticks | 1321 | 1185 |
| stime_ticks | 1677 | 1442 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## I-iouring-label-nonen

Role: wait-utilization-treatment.
CONSTRUCT writes entity IRI + rdfs:label.
WHERE: P+O class scan P31/Q5, S+P label, LANG in de/fr/es/it/nl/pl/pt/ru.
On-disk compressed language tags only. Cold wall time must be
at least 30 s on master. H1: blkio_s and wait fall. H2: cpu_ratio
rises. Reject if io_uring_enter stays 0.
Measured verdict: Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 139.567812 | 119.870495 |
| first_byte_s | 0.351007 | 0.390776 |
| export_time_s |  |  |
| plan_time_ms | 6 | 6 |
| total_server_ms |  |  |
| response_bytes | 3485348857 | 3485348857 |
| mib_per_s | 23.815575 | 27.728990 |
| cpu_s | 164.810000 | 143.850000 |
| cpu_ratio | 1.180000 | 1.199200 |
| blkio_s | 0 | 0 |
| wait_s | 0 | 0 |
| delayacct_blkio_ticks | 0 | 0 |
| major_faults | 0 | 0 |
| minor_faults | 117673 | 108100 |
| rchar | 840831296 | 840828530 |
| wchar | 6225 | 5655 |
| read_bytes | 12650614784 | 12672569344 |
| write_bytes | 53248 | 49152 |
| syscr | 21998 | 21958 |
| syscw | 80 | 70 |
| pread64 | 21637 | 21637 |
| io_uring_enter | 45397459 | 795085 |
| utime_ticks | 9033 | 8203 |
| stime_ticks | 7448 | 6191 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

