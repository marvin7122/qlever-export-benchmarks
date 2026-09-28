# PR #120 A/B on dblp (csv_export)

- Base: `0fb1cb2c` request fast-export=0; server args: `(none)`
- Variant: `0fb1cb2c` request fast-export=1; server args: `(none)`
- Binaries: same binary, runtime-flag A/B; host `ural` (ural layout)
- Request form fields: base `fast-export=0`; variant `fast-export=1`
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 5 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| D1-select | cold | request fast-export=0 | 5 | 0.1234 | 0.0961 | 0.1507 |  |  |  |
| D1-select | cold | request fast-export=1 | 5 | 0.1086 | 0.0875 | 0.5780 | -11.97% | within noise | identical bytes |
| D1-select | warm | request fast-export=0 | 5 | 0.0312 | 0.0289 | 0.1043 |  |  |  |
| D1-select | warm | request fast-export=1 | 5 | 0.0295 | 0.0286 | 0.1566 | -5.60% | within noise | identical bytes |
| R1-select | cold | request fast-export=0 | 5 | 1.1577 | 1.1404 | 1.3174 |  |  |  |
| R1-select | cold | request fast-export=1 | 5 | 0.4262 | 0.4045 | 0.6131 | -63.18% | variant faster | identical bytes |
| R1-select | warm | request fast-export=0 | 5 | 0.3720 | 0.2992 | 0.6379 |  |  |  |
| R1-select | warm | request fast-export=1 | 5 | 0.2670 | 0.2411 | 0.3771 | -28.22% | within noise | identical bytes |
| R2-select | cold | request fast-export=0 | 5 | 2.4803 | 2.3881 | 4.1792 |  |  |  |
| R2-select | cold | request fast-export=1 | 5 | 0.6012 | 0.5980 | 1.5796 | -75.76% | variant faster | equal as multiset (order differs) |
| R2-select | warm | request fast-export=0 | 5 | 0.7977 | 0.7967 | 0.8060 |  |  |  |
| R2-select | warm | request fast-export=1 | 5 | 0.3747 | 0.3669 | 0.4102 | -53.03% | variant faster | equal as multiset (order differs) |
| H-vocab-title-large-select | cold | request fast-export=0 | 5 | 5.2000 | 5.1884 | 5.2108 |  |  |  |
| H-vocab-title-large-select | cold | request fast-export=1 | 5 | 1.1033 | 1.0744 | 1.1793 | -78.78% | variant faster | identical bytes |
| H-vocab-title-large-select | warm | request fast-export=0 | 5 | 0.4840 | 0.4820 | 0.4877 |  |  |  |
| H-vocab-title-large-select | warm | request fast-export=1 | 5 | 0.3817 | 0.3551 | 0.4001 | -21.14% | variant faster | identical bytes |

## Verdict

- D1-select cold: within noise (-11.97%); correctness: identical bytes
- D1-select warm: within noise (-5.60%); correctness: identical bytes
- R1-select cold: variant faster (-63.18%); correctness: identical bytes
- R1-select warm: within noise (-28.22%); correctness: identical bytes
- R2-select cold: variant faster (-75.76%); correctness: equal as multiset (order differs)
- R2-select warm: variant faster (-53.03%); correctness: equal as multiset (order differs)
- H-vocab-title-large-select cold: variant faster (-78.78%); correctness: identical bytes
- H-vocab-title-large-select warm: variant faster (-21.14%); correctness: identical bytes

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
