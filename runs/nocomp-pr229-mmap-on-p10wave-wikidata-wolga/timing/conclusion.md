# PR #229 A/B on wikidata (turtle_export)

- Base: `77a41c663a28ebfd6453fba1e23902fd94630ff8` p10-wave-77a41c66; server args: `(none)`
- Variant: `d6f429dde4f82148720ab7e8fc70b5338d8911ce` p10-wave-mmap-offsets-d6f429dd; server args: `(none)`
- Binaries: two binaries; host `wolga` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | p10-wave-77a41c66 | 3 | 23.3791 | 22.8123 | 23.5722 |  |  |  |
| H-vocab-label-large-de | cold | p10-wave-mmap-offsets-d6f429dd | 3 | 23.5105 | 20.7792 | 24.9997 | +0.56% | within noise | identical bytes |
| H-vocab-label-large-de | warm | p10-wave-77a41c66 | 3 | 17.2466 | 16.6772 | 19.1739 |  |  |  |
| H-vocab-label-large-de | warm | p10-wave-mmap-offsets-d6f429dd | 3 | 12.4133 | 12.3969 | 13.7179 | -28.02% | variant faster | identical bytes |
| A-scatter-disambig-label-de | cold | p10-wave-77a41c66 | 3 | 7.9059 | 6.5517 | 10.0787 |  |  |  |
| A-scatter-disambig-label-de | cold | p10-wave-mmap-offsets-d6f429dd | 3 | 9.1898 | 8.8479 | 11.8737 | +16.24% | within noise | identical bytes |
| A-scatter-disambig-label-de | warm | p10-wave-77a41c66 | 3 | 4.3971 | 4.1459 | 4.3995 |  |  |  |
| A-scatter-disambig-label-de | warm | p10-wave-mmap-offsets-d6f429dd | 3 | 3.5078 | 3.4645 | 3.5246 | -20.22% | variant faster | identical bytes |

## Verdict

- H-vocab-label-large-de cold: within noise (+0.56%); correctness: identical bytes
- H-vocab-label-large-de warm: variant faster (-28.02%); correctness: identical bytes
- A-scatter-disambig-label-de cold: within noise (+16.24%); correctness: identical bytes
- A-scatter-disambig-label-de warm: variant faster (-20.22%); correctness: identical bytes

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
