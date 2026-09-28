# PR #196 A/B on wikidata (turtle_export)

- Base: `b3d4f562` base b3d4f562; server args: `(none)`
- Variant: `319d2f86` variant 319d2f86; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps (adaptive): 3 per arm and cell first; reps 4-5 only when the two arms' min..max ranges overlapped after 3 (`adaptive.tsv`); column n gives the reps per cell. Arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large | cold | base b3d4f562 | 3 | 22.6684 | 22.6456 | 22.7552 |  |  |  |
| H-vocab-label-large | cold | variant 319d2f86 | 3 | 21.9892 | 21.6848 | 22.1674 | -3.00% | variant faster | identical bytes |
| H-vocab-label-large | warm | base b3d4f562 | 3 | 22.8253 | 22.7797 | 23.1214 |  |  |  |
| H-vocab-label-large | warm | variant 319d2f86 | 3 | 21.7970 | 21.7257 | 21.8543 | -4.51% | variant faster | identical bytes |

## Verdict

- H-vocab-label-large cold: variant faster (-3.00%); correctness: identical bytes
- H-vocab-label-large warm: variant faster (-4.51%); correctness: identical bytes

## Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: PASS ==
- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Profiles

One extra warm rep per arm and query under `perf record -g` (not part of the timing): `perf/<query>/<arm>/` holds `report-top50.txt`, `stacks.folded` and `flame.svg` when FlameGraph was available; `perf/<query>/diff.svg` is the base-to-variant differential.

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
