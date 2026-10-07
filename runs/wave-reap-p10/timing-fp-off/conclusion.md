# PR #161 A/B on wikidata (turtle_export)

- Base: `4dd60f853612dacc4405c713638b1726c6382877` part10-4dd60f85-fpoff; server args: `--set-runtime-parameter vocabulary-iouring-page-cache-fast-path=false`
- Variant: `77a41c663a28ebfd6453fba1e23902fd94630ff8` wave-reap-77a41c66-fpoff; server args: `--set-runtime-parameter vocabulary-iouring-page-cache-fast-path=false`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 10 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-random-label-de-200k | cold | part10-4dd60f85-fpoff | 10 | 11.4257 | 10.2938 | 14.3829 |  |  |  |
| H-vocab-random-label-de-200k | cold | wave-reap-77a41c66-fpoff | 10 | 10.5246 | 10.1212 | 13.9159 | -7.89% | within noise | identical bytes |
| H-vocab-random-label-de-200k | warm | part10-4dd60f85-fpoff | 10 | 5.4891 | 5.3949 | 5.5713 |  |  |  |
| H-vocab-random-label-de-200k | warm | wave-reap-77a41c66-fpoff | 10 | 5.3273 | 5.2326 | 5.3859 | -2.95% | variant faster | identical bytes |
| H-vocab-label-large-de | cold | part10-4dd60f85-fpoff | 10 | 32.2365 | 30.3263 | 37.8995 |  |  |  |
| H-vocab-label-large-de | cold | wave-reap-77a41c66-fpoff | 10 | 28.1291 | 27.1744 | 33.4313 | -12.74% | within noise | identical bytes |
| H-vocab-label-large-de | warm | part10-4dd60f85-fpoff | 10 | 27.4619 | 19.7804 | 28.6077 |  |  |  |
| H-vocab-label-large-de | warm | wave-reap-77a41c66-fpoff | 10 | 24.0235 | 16.4004 | 24.7778 | -12.52% | within noise | identical bytes |

## Verdict

- H-vocab-random-label-de-200k cold: within noise (-7.89%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: variant faster (-2.95%); correctness: identical bytes
- H-vocab-label-large-de cold: within noise (-12.74%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (-12.52%); correctness: identical bytes

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
