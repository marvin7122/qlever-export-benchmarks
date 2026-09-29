# PR #3526 A/B on wikidata (turtle_export)

- Base: `c6b2f8d3bde40696b47cba44390144a936705a8d` part6-3525; server args: `(none)`
- Variant: `d91a22f484a90282dd6a84feaa161f94ebcc3c07` part7-3526; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| I-iouring-label-nonen | cold | part6-3525 | 3 | 175.0540 | 174.6092 | 175.2077 |  |  |  |
| I-iouring-label-nonen | cold | part7-3526 | 3 | 143.5653 | 142.9862 | 143.7766 | -17.99% | variant faster | equal as multiset (order differs) |

## Verdict

- I-iouring-label-nonen cold: variant faster (-17.99%); correctness: equal as multiset (order differs)

## Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
