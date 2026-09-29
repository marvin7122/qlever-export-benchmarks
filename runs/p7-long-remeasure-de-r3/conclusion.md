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
| H-vocab-label-large-de | cold | part6-3525 | 3 | 62.5958 | 62.5885 | 62.6438 |  |  |  |
| H-vocab-label-large-de | cold | part7-3526 | 3 | 27.4080 | 27.0454 | 27.4985 | -56.21% | variant faster | identical bytes |
| H-vocab-label-large-de | warm | part6-3525 | 3 | 17.1914 | 17.0361 | 17.3792 |  |  |  |
| H-vocab-label-large-de | warm | part7-3526 | 3 | 19.3371 | 19.2046 | 19.4285 | +12.48% | variant slower | identical bytes |
| H-vocab-random-label-de-200k | cold | part6-3525 | 3 | 27.4323 | 27.3660 | 27.4831 |  |  |  |
| H-vocab-random-label-de-200k | cold | part7-3526 | 3 | 10.8906 | 10.8130 | 11.0199 | -60.30% | variant faster | identical bytes |
| H-vocab-random-label-de-200k | warm | part6-3525 | 3 | 4.5510 | 4.5287 | 4.6477 |  |  |  |
| H-vocab-random-label-de-200k | warm | part7-3526 | 3 | 4.7204 | 4.6383 | 4.7347 | +3.72% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de cold: variant faster (-56.21%); correctness: identical bytes
- H-vocab-label-large-de warm: variant slower (+12.48%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: variant faster (-60.30%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (+3.72%); correctness: identical bytes

## Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: PASS ==
- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
