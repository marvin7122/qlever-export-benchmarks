# Export run diagnosis

Medians over complete reps. Counters are process-wide over the request.

| query | role | elapsed s | cpu s | cpu_ratio | wait s | blkio s | syscr | pread64 | io_uring_enter | bytes | verdict |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| I-iouring-label-de | io_uring-proof | 62.248→26.768 | 28.435→30 | 0.457→1.121 | 33.813→0 | 0→0 | 8886303→2685 | 4444385→2612 | 0→6636672 | 504927346 | Faster, but io_uring_enter did not drop. |
| I-iouring-label-nonen | wait-utilization-treatment | 167.711→139.876 | 148.015→164.980 | 0.883→1.179 | 19.696→0 | 0→0 | 60921662→21996 | 30471441→21637 | 0→45397290 | 3485348857 | Faster, but io_uring_enter did not drop. |

## I-iouring-label-de

Role: io_uring-proof.
CONSTRUCT writes entity IRI + rdfs:label.
WHERE: P+O class scan P31/Q5, then S+P label, LANG=de.
Same scan as H-vocab-label-large. The language is not in
languages-internal, so the label strings are on-disk compressed
words, not RAM. Fail the claim if io_uring_enter stays 0.
Measured verdict: Faster, but io_uring_enter did not drop.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 62.248087 | 26.768035 |
| first_byte_s | 2.845076 | 0.475224 |
| export_time_s |  |  |
| plan_time_ms | 4 | 4 |
| total_server_ms |  |  |
| response_bytes | 504927346 | 504927346 |
| mib_per_s | 7.736023 | 17.991353 |
| cpu_s | 28.435000 | 30 |
| cpu_ratio | 0.456800 | 1.120750 |
| blkio_s | 0 | 0 |
| wait_s | 33.813087 | 0 |
| delayacct_blkio_ticks | 0 | 0 |
| major_faults | 0 | 0 |
| minor_faults | 51298 | 24398 |
| rchar | 211757033 | 97586796 |
| wchar | 4290 | 3246 |
| read_bytes | 9615065088 | 9425473536 |
| write_bytes | 30720 | 16384 |
| syscr | 8886303 | 2685 |
| syscw | 41 | 23 |
| pread64 | 4444385 | 2612 |
| io_uring_enter | 0 | 6636672 |
| utime_ticks | 1413 | 1322 |
| stime_ticks | 1430 | 1678 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

## I-iouring-label-nonen

Role: wait-utilization-treatment.
CONSTRUCT writes entity IRI + rdfs:label.
WHERE: P+O class scan P31/Q5, S+P label, LANG in de/fr/es/it/nl/pl/pt/ru.
On-disk compressed language tags only. Cold wall time must be
at least 30 s on master. H1: blkio_s and wait fall. H2: cpu_ratio
rises. Reject if io_uring_enter stays 0.
Measured verdict: Faster, but io_uring_enter did not drop.

| counter | baseline | variant |
|---|---:|---:|
| elapsed_s | 167.711251 | 139.875776 |
| first_byte_s | 1.278459 | 0.346038 |
| export_time_s |  |  |
| plan_time_ms | 6.500000 | 6.500000 |
| total_server_ms |  |  |
| response_bytes | 3485348857 | 3485348857 |
| mib_per_s | 19.819143 | 23.764071 |
| cpu_s | 148.015000 | 164.980000 |
| cpu_ratio | 0.882550 | 1.179500 |
| blkio_s | 0 | 0 |
| wait_s | 19.696252 | 0 |
| delayacct_blkio_ticks | 0 | 0 |
| major_faults | 0 | 0 |
| minor_faults | 164888 | 126742 |
| rchar | 1638242985 | 840831158 |
| wchar | 7066 | 6198 |
| read_bytes | 12773695488 | 12645447680 |
| write_bytes | 63488 | 55296 |
| syscr | 60921662 | 21996 |
| syscw | 94 | 79.500000 |
| pread64 | 30471441 | 21637 |
| io_uring_enter | 0 | 45397290 |
| utime_ticks | 9200 | 9044 |
| stime_ticks | 5602 | 7454 |
| voluntary_ctxt_switches | 0 | 0 |
| nonvoluntary_ctxt_switches | 0 | 0 |

