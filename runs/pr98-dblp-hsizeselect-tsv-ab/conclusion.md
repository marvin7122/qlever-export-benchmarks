# PR #228 A/B on dblp (tsv_export)

- Base: `c8f70dff` use-swar-export-delimiters=false; server args: `--set-runtime-parameter use-swar-export-delimiters=false`
- Variant: `c8f70dff` use-swar-export-delimiters=true; server args: `--set-runtime-parameter use-swar-export-delimiters=true`
- Binaries: same binary, runtime-flag A/B; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps (adaptive): 3 per arm and cell first; reps 4-3 only when the two arms' min..max ranges overlapped after 3 (`adaptive.tsv`); column n gives the reps per cell. Arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-size-select | warm | use-swar-export-delimiters=false | 3 | 2.6187 | 2.6150 | 2.6972 |  |  |  |
| H-size-select | warm | use-swar-export-delimiters=true | 3 | 2.6573 | 2.5651 | 2.6620 | +1.47% | within noise | identical bytes |

## Verdict

- H-size-select warm: within noise (+1.47%); correctness: identical bytes

## Gates

- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
