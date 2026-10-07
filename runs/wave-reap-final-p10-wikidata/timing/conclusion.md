# PR #3476 A/B on wikidata (turtle_export)

- Base: `4dd60f853612dacc4405c713638b1726c6382877` part10-4dd60f85; server args: `(none)`
- Variant: `77a41c663a28ebfd6453fba1e23902fd94630ff8` part10-wave-77a41c66; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | part10-4dd60f85 | 3 | 34.0804 | 33.9021 | 34.1473 |  |  |  |
| H-vocab-label-large-de | cold | part10-wave-77a41c66 | 3 | 33.8138 | 33.7909 | 34.2857 | -0.78% | within noise | identical bytes |
| H-vocab-label-large-de | warm | part10-4dd60f85 | 3 | 19.5499 | 16.7551 | 23.4251 |  |  |  |
| H-vocab-label-large-de | warm | part10-wave-77a41c66 | 3 | 21.1910 | 20.5115 | 23.5744 | +8.39% | within noise | identical bytes |
| A-scatter-disambig-label-de | cold | part10-4dd60f85 | 3 | 13.9317 | 13.9042 | 14.1328 |  |  |  |
| A-scatter-disambig-label-de | cold | part10-wave-77a41c66 | 3 | 13.6888 | 13.5757 | 13.7388 | -1.74% | variant faster | identical bytes |
| A-scatter-disambig-label-de | warm | part10-4dd60f85 | 3 | 3.2189 | 3.0234 | 3.2855 |  |  |  |
| A-scatter-disambig-label-de | warm | part10-wave-77a41c66 | 3 | 2.8688 | 2.8395 | 2.8792 | -10.88% | variant faster | identical bytes |

## Verdict

- H-vocab-label-large-de cold: within noise (-0.78%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (+8.39%); correctness: identical bytes
- A-scatter-disambig-label-de cold: variant faster (-1.74%); correctness: identical bytes
- A-scatter-disambig-label-de warm: variant faster (-10.88%); correctness: identical bytes

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
