# PR #196 A/B on wikidata (turtle_export)

- Base: `f8cca285e3d0d3400dd51be97b5ebf078cd454de` p12-f8cca285; server args: `(none)`
- Variant: `6d2f7faa07d8df4f2a7181d45741c6e0c9236d9f` 3-stage-depth-2; server args: `--set-runtime-parameter construct-export-pipeline-depth=2 --set-runtime-parameter construct-export-pipeline-split-lookup=true`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | p12-f8cca285 | 3 | 23.9273 | 22.8141 | 25.9635 |  |  |  |
| H-vocab-label-large-de | cold | 3-stage-depth-2 | 3 | 12.9906 | 12.3486 | 13.4830 | -45.71% | variant faster | identical bytes |
| H-vocab-label-large-de | warm | p12-f8cca285 | 3 | 20.1317 | 16.4230 | 22.9764 |  |  |  |
| H-vocab-label-large-de | warm | 3-stage-depth-2 | 3 | 9.5854 | 9.0500 | 12.8601 | -52.39% | variant faster | identical bytes |
| H-vocab-random-label-de-200k | cold | p12-f8cca285 | 3 | 14.2263 | 14.1196 | 14.2343 |  |  |  |
| H-vocab-random-label-de-200k | cold | 3-stage-depth-2 | 3 | 12.4180 | 12.3392 | 12.5988 | -12.71% | variant faster | identical bytes |
| H-vocab-random-label-de-200k | warm | p12-f8cca285 | 3 | 5.3684 | 5.3577 | 5.3799 |  |  |  |
| H-vocab-random-label-de-200k | warm | 3-stage-depth-2 | 3 | 4.9587 | 4.9435 | 5.0036 | -7.63% | variant faster | identical bytes |
| H-vocab-label-large | cold | p12-f8cca285 | 3 | 26.6747 | 24.5430 | 34.0581 |  |  |  |
| H-vocab-label-large | cold | 3-stage-depth-2 | 3 | 16.4862 | 15.5389 | 19.3031 | -38.20% | variant faster | identical bytes |
| H-vocab-label-large | warm | p12-f8cca285 | 3 | 23.8802 | 21.1640 | 26.6594 |  |  |  |
| H-vocab-label-large | warm | 3-stage-depth-2 | 3 | 13.8206 | 12.9801 | 17.4796 | -42.13% | variant faster | identical bytes |

## Verdict

- H-vocab-label-large-de cold: variant faster (-45.71%); correctness: identical bytes
- H-vocab-label-large-de warm: variant faster (-52.39%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: variant faster (-12.71%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: variant faster (-7.63%); correctness: identical bytes
- H-vocab-label-large cold: variant faster (-38.20%); correctness: identical bytes
- H-vocab-label-large warm: variant faster (-42.13%); correctness: identical bytes

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
