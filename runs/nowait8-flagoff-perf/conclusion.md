# PR #3547 A/B on wikidata (turtle_export)

- Base: `0ed8f9223497196d8979accb24ac737becc42f2b` p7-3526; server args: `(none)`
- Variant: `51269ab4bf895211983287d1086c0a700ea43c86` nowait-fastpath-off; server args: `--set-runtime-parameter vocabulary-iouring-page-cache-fast-path=false`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-random-label-de-200k | warm | p7-3526 | 3 | 4.5607 | 4.5534 | 4.6101 |  |  |  |
| H-vocab-random-label-de-200k | warm | nowait-fastpath-off | 3 | 4.7538 | 4.7248 | 4.7797 | +4.23% | variant slower | identical bytes |

## Verdict

- H-vocab-random-label-de-200k warm: variant slower (+4.23%); correctness: identical bytes

## Gates

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
