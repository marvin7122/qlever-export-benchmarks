# PR #81 A/B on dblp (turtle_export)

- Base: `13c00768` flag-off; server args: `--set-runtime-parameter use-fast-export-stream-formatter=false`
- Variant: `13c00768` flag-on; server args: `--set-runtime-parameter use-fast-export-stream-formatter=true`
- Binaries: same binary, runtime-flag A/B; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps (adaptive): 3 per arm and cell first; reps 4-3 only when the two arms' min..max ranges overlapped after 3 (`adaptive.tsv`); column n gives the reps per cell. Arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-size | warm | flag-off | 3 | 0.6830 | 0.6529 | 0.6963 |  |  |  |
| H-size | warm | flag-on | 3 | 0.6299 | 0.6187 | 0.6385 | -7.77% | variant faster | identical bytes |
| H-vocab-title-large | warm | flag-off | 3 | 0.5647 | 0.5615 | 0.5700 |  |  |  |
| H-vocab-title-large | warm | flag-on | 3 | 0.6036 | 0.5655 | 0.6071 | +6.88% | within noise | identical bytes |

## Verdict

- H-size warm: variant faster (-7.77%); correctness: identical bytes
- H-vocab-title-large warm: within noise (+6.88%); correctness: identical bytes

## Gates

- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
