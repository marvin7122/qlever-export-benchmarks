# Export run diagnosis

Medians over complete reps. Counters are process-wide over the request.

| query | role | elapsed s | cpu s | cpu_ratio | wait s | blkio s | syscr | pread64 | io_uring_enter | bytes | verdict |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| I-iouring-label-de | io_uring-proof | 26.589→23.704 | 29.850→26.625 | 1.123→1.123 | 0→0 | 0→0 | 2687→2681 | 2612→2612 | 6636818→60668 | 504927346 | Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters. |
| I-iouring-label-nonen | wait-utilization-treatment | 138.847→122.001 | 164.160→145.970 | 1.182→1.196 | 0→0 | 0→0 | 21996→21962 | 21637→21637 | 45397868→289191 | 3485348857 | Sliding window: fewer io_uring_enter on the same pread path. Elapsed did not fall with fewer enters. |

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
| elapsed_s | 26.589282 | 23.703679 |
| first_byte_s | 0.480386 | 0.426071 |
| export_time_s |  |  |
| plan_time_ms | 4 | 3.500000 |
| total_server_ms |  |  |
| response_bytes | 504927346 | 504927346 |
| mib_per_s | 18.110254 | 20.315334 |
| cpu_s | 29.850000 | 26.625000 |
| cpu_ratio | 1.122650 | 1.123250 |
| blkio_s | 0 | 0 |
| wait_s | 0 | 0 |
| delayacct_blkio_ticks | 0 | 0 |
| major_faults | 0 | 0 |
| minor_faults | 26206 | 22202 |
| rchar | 97586932 | 97586519 |
| wchar | 3276 | 3186 |
| read_bytes | 9435840512 | 9438412800 |
| write_bytes | 20480 | 18432 |
| syscr | 2687 | 2681 |
| syscw | 23.500000 | 22 |
| pread64 | 2612 | 2612 |
| io_uring_enter | 6636818 | 60668 |
| utime_ticks | 1323 | 1230 |
| stime_ticks | 1662 | 1432 |
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
| elapsed_s | 138.846903 | 122.000711 |
| first_byte_s | 0.397947 | 0.349353 |
| export_time_s |  |  |
| plan_time_ms | 6 | 6.500000 |
| total_server_ms |  |  |
| response_bytes | 3485348857 | 3485348857 |
| mib_per_s | 23.939881 | 27.244834 |
| cpu_s | 164.160000 | 145.970000 |
| cpu_ratio | 1.182300 | 1.196500 |
| blkio_s | 0 | 0 |
| wait_s | 0 | 0 |
| delayacct_blkio_ticks | 0 | 0 |
| major_faults | 0 | 0 |
| minor_faults | 117559 | 128595 |
| rchar | 840831153 | 840828802 |
| wchar | 6200 | 5712 |
| read_bytes | 12671602688 | 12656439296 |
| write_bytes | 53248 | 51200 |
| syscr | 21996 | 21962 |
| syscw | 79.500000 | 71 |
| pread64 | 21637 | 21637 |
| io_uring_enter | 45397868 | 289191 |
| utime_ticks | 9022 | 8419 |
| stime_ticks | 7394 | 6178 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

