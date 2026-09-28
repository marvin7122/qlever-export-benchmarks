# PR #225 A/B on dblp (csv_export)

- Base: `3e247beb` flag-off; server args: `--set-runtime-parameter export-v2-adaptive-chunk-sizing=false`
- Variant: `3e247beb` flag-on; server args: `--set-runtime-parameter export-v2-adaptive-chunk-sizing=true`
- Binaries: same binary, runtime-flag A/B; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 8
- Reps (adaptive): 3 per arm and cell first; reps 4-3 only when the two arms' min..max ranges overlapped after 3 (`adaptive.tsv`); column n gives the reps per cell. Arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| R2-select | warm | flag-off | 3 | 0.8028 | 0.8014 | 0.8079 |  |  |  |
| R2-select | warm | flag-on | 3 | 0.8053 | 0.7984 | 0.8060 | +0.31% | within noise | identical bytes |

## Verdict

- R2-select warm: within noise (+0.31%); correctness: identical bytes

## Gates

- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
