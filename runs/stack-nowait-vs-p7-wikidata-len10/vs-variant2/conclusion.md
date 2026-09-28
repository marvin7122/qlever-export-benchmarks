# PR #236 A/B on wikidata (turtle_export)

- Base: `0ed8f9223497196d8979accb24ac737becc42f2b` p7-3526-ring-only; server args: `(none)`
- Variant: `51269ab4bf895211983287d1086c0a700ea43c86` nowait-fastpath-off; server args: `--set-runtime-parameter vocabulary-iouring-page-cache-fast-path=false`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 10 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | p7-3526-ring-only | 10 | 28.6650 | 28.5664 | 28.7620 |  |  |  |
| H-vocab-label-large-de | cold | nowait-fastpath-off | 10 | 28.5862 | 28.4799 | 28.7232 | -0.28% | within noise | identical bytes |
| H-vocab-label-large-de | warm | p7-3526-ring-only | 10 | 19.7959 | 19.4496 | 20.7932 |  |  |  |
| H-vocab-label-large-de | warm | nowait-fastpath-off | 10 | 19.7249 | 19.5521 | 20.5675 | -0.36% | within noise | identical bytes |
| H-vocab-random-label-de-200k | cold | p7-3526-ring-only | 9 | 11.1587 | 10.8012 | 11.5935 |  |  |  |
| H-vocab-random-label-de-200k | cold | nowait-fastpath-off | 10 | 11.3236 | 11.1301 | 11.5707 | +1.48% | within noise | **MISMATCH** (MISMATCH) |
| H-vocab-random-label-de-200k | warm | p7-3526-ring-only | 10 | 4.6827 | 4.6035 | 4.7320 |  |  |  |
| H-vocab-random-label-de-200k | warm | nowait-fastpath-off | 10 | 4.8907 | 4.8230 | 4.9384 | +4.44% | variant slower | identical bytes |

## Verdict

- H-vocab-label-large-de cold: within noise (-0.28%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (-0.36%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: within noise (+1.48%); correctness: **MISMATCH** (MISMATCH)
- H-vocab-random-label-de-200k warm: variant slower (+4.44%); correctness: identical bytes

## Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: FAIL ==
  - FAIL 1 failed/non-complete rows
- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

- H-vocab-random-label-de-200k/cold/base rep 8: status=failed bytes=0
- H-vocab-random-label-de-200k/cold/base rep 8: correctness MISMATCH
- H-vocab-random-label-de-200k/cold/base: 9 good reps of 10

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
