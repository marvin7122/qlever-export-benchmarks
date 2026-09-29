# PR #109 A/B on wikidata (csv_export)

- Base: `766c0cb5` hashmap; server args: `--memory-max-size=16GB --set-runtime-parameter group-by-hash-map-enabled=true`
- Variant: `766c0cb5` hashmap+prefetch; server args: `--memory-max-size=16GB --set-runtime-parameter group-by-hash-map-enabled=true --set-runtime-parameter group-by-hash-map-prefetch=true`
- Binaries: same binary, runtime-flag A/B; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps (adaptive): 3 per arm and cell first; reps 4-3 only when the two arms' min..max ranges overlapped after 3 (`adaptive.tsv`); column n gives the reps per cell. Arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| G-hash-count-per-author-wd | warm | hashmap | 3 | 5.5909 | 5.4925 | 5.6247 |  |  |  |
| G-hash-count-per-author-wd | warm | hashmap+prefetch | 3 | 5.2930 | 5.2870 | 5.3922 | -5.33% | variant faster | identical bytes |

## Verdict

- G-hash-count-per-author-wd warm: variant faster (-5.33%); correctness: identical bytes

## Gates

- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
