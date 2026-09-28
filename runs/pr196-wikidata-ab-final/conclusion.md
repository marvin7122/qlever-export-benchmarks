# PR #196 A/B on wikidata (turtle_export)

- Base: `09f0132a` base 09f0132a; server args: `(none)`
- Variant: `c200532c` variant c200532c; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps (adaptive): 3 per arm and cell first; reps 4-5 only when the two arms' min..max ranges overlapped after 3 (`adaptive.tsv`); column n gives the reps per cell. Arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large | cold | base 09f0132a | 5 | 33.8390 | 33.0332 | 38.3661 |  |  |  |
| H-vocab-label-large | cold | variant c200532c | 5 | 33.1569 | 30.5456 | 34.0468 | -2.02% | within noise | identical bytes |
| H-vocab-label-large | warm | base 09f0132a | 5 | 32.5689 | 30.0498 | 41.6202 |  |  |  |
| H-vocab-label-large | warm | variant c200532c | 5 | 31.1167 | 28.2393 | 36.7492 | -4.46% | within noise | identical bytes |

## Verdict

- H-vocab-label-large cold: within noise (-2.02%); correctness: identical bytes
- H-vocab-label-large warm: within noise (-4.46%); correctness: identical bytes

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
