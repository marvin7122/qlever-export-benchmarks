# PR #3526 A/B on wikidata (turtle_export)

- Base: `51269ab4` vocabulary-iouring-page-cache-fast-path=false; server args: `--set-runtime-parameter vocabulary-iouring-page-cache-fast-path=false`
- Variant: `51269ab4` vocabulary-iouring-page-cache-fast-path=true; server args: `--set-runtime-parameter vocabulary-iouring-page-cache-fast-path=true`
- Binaries: same binary, runtime-flag A/B; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 2 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | vocabulary-iouring-page-cache-fast-path=false | 2 | 27.9032 | 27.7645 | 28.0419 |  |  |  |
| H-vocab-label-large-de | cold | vocabulary-iouring-page-cache-fast-path=true | 2 | 23.5839 | 23.1777 | 23.9901 | -15.48% | variant faster | identical bytes |
| H-vocab-label-large-de | warm | vocabulary-iouring-page-cache-fast-path=false | 2 | 19.3208 | 19.2672 | 19.3744 |  |  |  |
| H-vocab-label-large-de | warm | vocabulary-iouring-page-cache-fast-path=true | 2 | 15.9184 | 15.8353 | 16.0015 | -17.61% | variant faster | identical bytes |
| H-vocab-random-label-de-200k | cold | vocabulary-iouring-page-cache-fast-path=false | 2 | 10.9765 | 10.9193 | 11.0336 |  |  |  |
| H-vocab-random-label-de-200k | cold | vocabulary-iouring-page-cache-fast-path=true | 2 | 11.0910 | 11.0579 | 11.1242 | +1.04% | variant slower | identical bytes |
| H-vocab-random-label-de-200k | warm | vocabulary-iouring-page-cache-fast-path=false | 2 | 4.7711 | 4.7212 | 4.8210 |  |  |  |
| H-vocab-random-label-de-200k | warm | vocabulary-iouring-page-cache-fast-path=true | 2 | 4.5490 | 4.3668 | 4.7312 | -4.66% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de cold: variant faster (-15.48%); correctness: identical bytes
- H-vocab-label-large-de warm: variant faster (-17.61%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: variant slower (+1.04%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (-4.66%); correctness: identical bytes

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
