# PR #109 A/B on dblp (csv_export)

- Base: `766c0cb5` hashmap; server args: `--set-runtime-parameter group-by-hash-map-enabled=true`
- Variant: `766c0cb5` hashmap+prefetch; server args: `--set-runtime-parameter group-by-hash-map-enabled=true --set-runtime-parameter group-by-hash-map-prefetch=true`
- Binaries: same binary, runtime-flag A/B; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps (adaptive): 3 per arm and cell first; reps 4-3 only when the two arms' min..max ranges overlapped after 3 (`adaptive.tsv`); column n gives the reps per cell. Arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| G-hash-count-per-author | warm | hashmap | 3 | 6.3221 | 6.2473 | 6.3665 |  |  |  |
| G-hash-count-per-author | warm | hashmap+prefetch | 3 | 6.1389 | 6.1334 | 6.1558 | -2.90% | variant faster | identical bytes |
| G-hash-minmax-per-author | warm | hashmap | 3 | 13.0813 | 13.0549 | 13.1162 |  |  |  |
| G-hash-minmax-per-author | warm | hashmap+prefetch | 3 | 11.3829 | 11.1227 | 11.4048 | -12.98% | variant faster | identical bytes |

## Verdict

- G-hash-count-per-author warm: variant faster (-2.90%); correctness: identical bytes
- G-hash-minmax-per-author warm: variant faster (-12.98%); correctness: identical bytes

## Gates

- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
