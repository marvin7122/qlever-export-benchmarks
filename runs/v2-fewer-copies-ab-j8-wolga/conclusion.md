# PR #120 A/B on wikidata (csv_export)

- Base: `87f57674` v2-87f57674; server args: `(none)`
- Variant: `719615ab` v2-fewer-copies-719615ab; server args: `(none)`
- Binaries: two binaries; host `wolga` (ural layout)
- Request form fields: base `fast-export=1`; variant `fast-export=1`
- Server query threads (`--num-simultaneous-queries`): 8
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-select | cold | v2-87f57674 | 3 | 4.0584 | 3.7650 | 4.8071 |  |  |  |
| H-vocab-label-large-select | cold | v2-fewer-copies-719615ab | 3 | 4.5706 | 3.5209 | 5.1161 | +12.62% | within noise | equal as multiset (order differs) |
| H-vocab-label-large-select | warm | v2-87f57674 | 3 | 3.9875 | 3.5848 | 4.1908 |  |  |  |
| H-vocab-label-large-select | warm | v2-fewer-copies-719615ab | 3 | 3.8047 | 3.7720 | 4.1568 | -4.58% | within noise | equal as multiset (order differs) |

## Verdict

- H-vocab-label-large-select cold: within noise (+12.62%); correctness: equal as multiset (order differs)
- H-vocab-label-large-select warm: within noise (-4.58%); correctness: equal as multiset (order differs)

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
