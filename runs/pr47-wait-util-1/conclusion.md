# Verdict

## control H-vocab-label-large (n=5/5 complete)

| metric | baseline | variant |
|---|---:|---:|
| elapsed_s | 22.8631 | 22.6778 |
| cpu_s | 32.5700 | 32.2800 |
| cpu_ratio | 1.4165 | 1.4305 |
| wait_s | 0.0000 | 0.0000 |
| blkio_s | 0.0000 | 0.0000 |
| pread64 | 0.0000 | 0.0000 |
| io_uring_enter | 0.0000 | 0.0000 |
| response_bytes | 1302749672.0000 | 1302749672.0000 |

reps elapsed baseline: 22.844300493, 23.084504699, 22.863058740, 23.080633563, 22.760977640
reps elapsed variant: 22.682401332, 22.367818717, 22.677761457, 22.262218368, 22.718698572

## treatment I-iouring-label-nonen (n=5/5 complete)

| metric | baseline | variant |
|---|---:|---:|
| elapsed_s | 161.0500 | 131.8551 |
| cpu_s | 141.1300 | 156.9100 |
| cpu_ratio | 0.8763 | 1.1905 |
| wait_s | 19.9621 | 0.0000 |
| blkio_s | 0.0000 | 0.0000 |
| pread64 | 0.0000 | 0.0000 |
| io_uring_enter | 0.0000 | 0.0000 |
| response_bytes | 3485348857.0000 | 3485348857.0000 |

reps elapsed baseline: 161.601026724, 161.049972472, 160.907637186, 159.965634123, 161.382089054
reps elapsed variant: 132.629596335, 131.939277397, 131.855070758, 131.394679869, 131.740820352

## Decisions

- duration ≥30 s: yes (baseline treatment median 161.0500 s)
- delayacct active: no
- H0 control (English, no wire): HOLD
- H1 less I/O wait: REJECT: variant io_uring_enter did not rise on treatment
- H2 higher cpu_ratio: REJECT: wire not used

