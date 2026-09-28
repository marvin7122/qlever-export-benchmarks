# Conclusion for run wikidata-profile-sqpoll

## Scope

Flamegraph profile of one cold scattered German-label CONSTRUCT
export on the upgraded new-format Wikidata truthy index. The server
binary is `feat/iouring-sqpoll` at `901b3b9a1`, default parameters. `perf record -F 99 -g` sampled the server process
for the whole export, and the stacks collapsed to `flame.svg`
(period-weighted cycles).

## Validity checks

The export completed with HTTP status 200 and body hash
`497dacfd...`, identical to every A/B arm, so the profiled work is
the same. The run directory carries the COMPLETE marker.

## Result

Wall time 27.85 s. Vocabulary frames hold 68 percent of sampled
cycles. Only the routing arm differs from master; all other arms
match it within profile noise.
