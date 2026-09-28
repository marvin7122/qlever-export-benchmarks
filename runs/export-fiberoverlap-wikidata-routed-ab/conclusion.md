# PR #196 A/B on wikidata (turtle_export)

- Base: `6e6e8029` export-fiber-overlap=false; server args: `--set-runtime-parameter export-fiber-overlap=false`
- Variant: `6e6e8029` export-fiber-overlap=true; server args: `--set-runtime-parameter export-fiber-overlap=true`
- Binaries: same binary, runtime-flag A/B; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 2 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | export-fiber-overlap=false | 2 | 23.5718 | 23.2805 | 23.8631 |  |  |  |
| H-vocab-label-large-de | cold | export-fiber-overlap=true | 2 | 23.7599 | 23.7025 | 23.8172 | +0.80% | within noise | identical bytes |
| H-vocab-label-large-de | warm | export-fiber-overlap=false | 2 | 16.1905 | 16.1122 | 16.2687 |  |  |  |
| H-vocab-label-large-de | warm | export-fiber-overlap=true | 2 | 16.4340 | 16.3479 | 16.5201 | +1.50% | variant slower | identical bytes |

## Verdict

- H-vocab-label-large-de cold: within noise (+0.80%); correctness: identical bytes
- H-vocab-label-large-de warm: variant slower (+1.50%); correctness: identical bytes

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
