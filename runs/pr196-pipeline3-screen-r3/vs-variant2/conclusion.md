# PR #196 A/B on wikidata (turtle_export)

- Base: `f8cca285e3d0d3400dd51be97b5ebf078cd454de` p12-f8cca285; server args: `(none)`
- Variant: `6d2f7faa07d8df4f2a7181d45741c6e0c9236d9f` 2-stage-depth-2; server args: `--set-runtime-parameter construct-export-pipeline-depth=2 --set-runtime-parameter construct-export-pipeline-split-lookup=false`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | p12-f8cca285 | 3 | 23.9273 | 22.8141 | 25.9635 |  |  |  |
| H-vocab-label-large-de | cold | 2-stage-depth-2 | 3 | 27.9485 | 22.6869 | 29.3458 | +16.81% | within noise | identical bytes |
| H-vocab-label-large-de | warm | p12-f8cca285 | 3 | 20.1317 | 16.4230 | 22.9764 |  |  |  |
| H-vocab-label-large-de | warm | 2-stage-depth-2 | 3 | 19.8210 | 15.3584 | 22.8980 | -1.54% | within noise | identical bytes |
| H-vocab-random-label-de-200k | cold | p12-f8cca285 | 3 | 14.2263 | 14.1196 | 14.2343 |  |  |  |
| H-vocab-random-label-de-200k | cold | 2-stage-depth-2 | 3 | 13.9964 | 13.9958 | 14.2095 | -1.62% | within noise | identical bytes |
| H-vocab-random-label-de-200k | warm | p12-f8cca285 | 3 | 5.3684 | 5.3577 | 5.3799 |  |  |  |
| H-vocab-random-label-de-200k | warm | 2-stage-depth-2 | 3 | 5.3590 | 5.2131 | 5.3633 | -0.17% | within noise | identical bytes |
| H-vocab-label-large | cold | p12-f8cca285 | 3 | 26.6747 | 24.5430 | 34.0581 |  |  |  |
| H-vocab-label-large | cold | 2-stage-depth-2 | 3 | 29.6401 | 24.5100 | 31.7716 | +11.12% | within noise | identical bytes |
| H-vocab-label-large | warm | p12-f8cca285 | 3 | 23.8802 | 21.1640 | 26.6594 |  |  |  |
| H-vocab-label-large | warm | 2-stage-depth-2 | 3 | 23.9036 | 23.4828 | 30.3249 | +0.10% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de cold: within noise (+16.81%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (-1.54%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: within noise (-1.62%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (-0.17%); correctness: identical bytes
- H-vocab-label-large cold: within noise (+11.12%); correctness: identical bytes
- H-vocab-label-large warm: within noise (+0.10%); correctness: identical bytes

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
