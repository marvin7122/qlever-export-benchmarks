# Conclusion for run wikidata-profile-sqpoll-kptr0 (queue seq 4163)

## Scope

Flamegraph profile of one cold scattered German-label CONSTRUCT
export on the upgraded new-format Wikidata truthy index, rerun with
kernel symbols resolved (`kptr_restrict=0` on Ural). The server
binary is `feat/iouring-sqpoll` at default parameters (the poller
stays off without the opt-in flag). `perf record -F 99 -g` sampled
the server process for the whole export, and the stacks collapsed
to `flame.svg` (period-weighted cycles).

## Validity checks

The export completed with HTTP status 200 and body hash
`497dacfd...`, identical to every A/B arm and to the era-1 profile,
so the profiled work is the same. The run directory carries the
COMPLETE marker.

## Result

Wall time 27.82 s (era-1: 27.85 s). Vocabulary frames hold 66
percent of sampled cycles by the same symbol-match method that gave
68 percent on era-1. The profile matches master within noise and
supersedes era-1 SQPoll at defaults. Active polling remains
unmeasured until the flagged A/B lands.
