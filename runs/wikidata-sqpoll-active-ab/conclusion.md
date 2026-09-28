# Conclusion for run wikidata-sqpoll-active-ab (queue seq 4183)

## Scope

This run was meant to compare the compressed-routing branch
against `feat/iouring-sqpoll-routed` with the poller engaged via
`--set-runtime-parameter=iouring-sqpoll=true`. It is recorded as
INVALID: the variant arm never produced comparable numbers.

## What happened

The queue retried the run three times into the same directory.
Attempts 1 and 2 used the pre-fix variant binary and died on the
`sqe != nullptr` abort in `IoUringManager.cpp` (warmup 500s, no
samples). Attempt 3 used the drain-and-retry build, which replaced
the abort with worse failure modes on the sequential workload: a
30-minute hang on cold1 (server idle, no completions flowing), a
4-second truncated body on cold2, and wrong hashes throughout. The
scattered workload completed with correct hashes but ran twice as
slow as the baseline (21.7 s vs 11.1 s).

## Interpretation

The retry treated the symptom while the ring accounting stayed
broken, and its unbounded drain blocked forever once completions
stalled. The branch has since moved to ring headroom instead (the
in-flight cap stays, the ring is doubled under SQPoll), and the
regression test `SqPollSetup.sqPollBatchLargerThanRing` guards the
path. This run's numbers are not measurements; the rerun on the
headroom build supersedes them.

## Update: headroom fix verified at unit level (2026-09-20)

The ring-headroom rework (`cc308dd1b`) passes the regression test
`SqPollSetup.sqPollBatchLargerThanRing` on Ural (queue run 4185,
1 test passed in 12 ms). The full-server A/B rerun is requeued
against this build; its numbers will supersede this file's invalid
run once they land.
