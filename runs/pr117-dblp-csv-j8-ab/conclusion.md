# PR #117 A/B on dblp (csv_export)

- Base: `4202342c` async-pipeline=off; server args: `--set-runtime-parameter export-v2-async-pipeline=false`
- Variant: `4202342c` async-pipeline=on; server args: `--set-runtime-parameter export-v2-async-pipeline=true`
- Binaries: same binary, runtime-flag A/B; host `ural` (ural layout)
- Request form fields: base `fast-export=1`; variant `fast-export=1`
- Server query threads (`--num-simultaneous-queries`): 8
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-size-select | warm | async-pipeline=off | 3 | 0.4935 | 0.4794 | 0.5145 |  |  |  |
| H-size-select | warm | async-pipeline=on | 3 | 0.4896 | 0.4822 | 0.4940 | -0.79% | within noise | equal as multiset (order differs) |
| R2-select | warm | async-pipeline=off | 3 | 0.1618 | 0.1582 | 0.1718 |  |  |  |
| R2-select | warm | async-pipeline=on | 3 | 0.1658 | 0.1643 | 0.1768 | +2.45% | within noise | equal as multiset (order differs) |

## Verdict

- H-size-select warm: within noise (-0.79%); correctness: equal as multiset (order differs)
- R2-select warm: within noise (+2.45%); correctness: equal as multiset (order differs)

## Gates

- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.

## Context (added by hand)

- Ural queue: bench 4807; binary wire/pr117 @ 4202342c (Ural build 4805); both arms fast-export=1 (Export V2), only `export-v2-async-pipeline` differs.
- Mechanism check: every variant rep logs `ExportEngineV2 async pipeline: N chunks, B bytes, 0 producer waits, N(+1) consumer waits` (H-size-select 61 chunks, R2-select 19 chunks); no base rep logs it. The producer never blocked on the 2-slot pipeline; the consumer waited for every chunk: serialization, not the handoff, bounds the export.
- Correctness: response_bytes equal in every rep of both arms; row multiset equal. Row order differs between reps of the same arm too (V2 emits morsels of unbounded queries in completion order, #120), so identical bytes cannot be expected for these queries in either arm.
- Verdict: no effect on elapsed time or time to first byte (all cells within noise). The HTTP layer already runs the V2 generator on a runStreamAsync thread (setBody, depth 100), so the pipeline adds a second prefetch stage in series with no new overlap.
- The binary (`bin/qlever-server-ab`) is not committed; it stays under the Ural run dir.
