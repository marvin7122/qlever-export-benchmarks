# Conclusion: active SQPoll A/B on the ring-headroom build

## Setup

Both arms run the same pinned server binary from branch
`feat/iouring-sqpoll-routed` at `cc308dd1b` (sha256
`828d19d3…`, checked before and after the run). The only delta is
the `iouring-sqpoll` runtime knob: baseline arm `false`, variant
arm `true`. The workload is the Wikidata CONSTRUCT suite against
the Wikidata truthy index. The thesis driver state is
`bench/iouring-sqpoll-ab @ db8e1409b5`. Queue run 4188 exited 0
with COMPLETE ALL DONE.

## Result

The headroom build is functionally correct with SQPoll enabled.
Every query returns byte-identical responses on both arms, and all
repetitions complete with no abort, hang, or truncated body. This
closes the invalid drain-and-retry run, whose numbers stay
discarded.

Active SQPoll slows down every query that reaches the ring, while
the two H-tier queries never enter the ring on either arm
(`io_uring_enter` 0 on both) and stay unchanged. The table lists
median elapsed times for SQPoll off versus on.

| query | off (s) | on (s) | ratio |
|---|---|---:|---:|
| D1 | 0.146 | 0.243 | 1.67x slower |
| D3 | 0.641 | 2.041 | 3.18x slower |
| I-iouring-stars | 0.280 | 0.849 | 3.03x slower |
| I-iouring-capitals | 0.181 | 0.342 | 1.89x slower |
| H-vocab-random-label | 4.569 | 4.596 | 1.01x (noise) |
| H-vocab-label-large | 22.577 | 22.567 | 1.00x |

The slowdown comes with higher cost, not less I/O. On D3, CPU
time rises from 0.845 s to 2.425 s while `syscr` (2664 versus
2665) and `pread64` (2658 on both arms) stay constant.
`io_uring_enter` rises from 873 to 2126 on the same query. D1,
stars, and capitals show the same pattern: identical syscall
counts, more `io_uring_enter` calls, and more CPU time.

## Interpretation

Ring headroom fixed correctness but did not make SQPoll pay off
at these batch sizes. The poll thread adds CPU and submission
overhead without removing enough wakeup cost. Each batch still
pays one enter per refill, and the ring never stays full enough
for polling to skip wakeups. Per-query data and counters
are in `diagnosis.md`; raw repetitions are in `bench.log` and
the per-query directories.
