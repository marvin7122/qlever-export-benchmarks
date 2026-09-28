# PR #236 A/B on wikidata (turtle_export)

- Base: `07d06bc5` fastpath-off; server args: `--set-runtime-parameter vocabulary-iouring-page-cache-fast-path=false`
- Variant: `07d06bc5` fastpath-on; server args: `--set-runtime-parameter vocabulary-iouring-page-cache-fast-path=true`
- Binaries: same binary, runtime-flag A/B; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 2 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | fastpath-off | 2 | 26.9779 | 26.8594 | 27.0964 |  |  |  |
| H-vocab-label-large-de | cold | fastpath-on | 2 | 23.1864 | 22.9679 | 23.4049 | -14.05% | variant faster | identical bytes |
| H-vocab-label-large-de | warm | fastpath-off | 2 | 18.8640 | 18.8295 | 18.8985 |  |  |  |
| H-vocab-label-large-de | warm | fastpath-on | 2 | 15.7494 | 15.6277 | 15.8711 | -16.51% | variant faster | identical bytes |
| H-vocab-random-label-de-200k | cold | fastpath-off | 2 | 10.7447 | 10.7264 | 10.7630 |  |  |  |
| H-vocab-random-label-de-200k | cold | fastpath-on | 2 | 10.5393 | 10.4987 | 10.5800 | -1.91% | variant faster | identical bytes |
| H-vocab-random-label-de-200k | warm | fastpath-off | 2 | 4.4916 | 4.4098 | 4.5734 |  |  |  |
| H-vocab-random-label-de-200k | warm | fastpath-on | 2 | 4.3711 | 4.3573 | 4.3848 | -2.68% | variant faster | identical bytes |

## Verdict

- H-vocab-label-large-de cold: variant faster (-14.05%); correctness: identical bytes
- H-vocab-label-large-de warm: variant faster (-16.51%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: variant faster (-1.91%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: variant faster (-2.68%); correctness: identical bytes

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
