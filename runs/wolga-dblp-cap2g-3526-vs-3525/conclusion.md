# PR #3526 A/B on dblp (turtle_export)

- Base: `533f800b87ffd1857291e27bc1ce63dacc1ca003` p6-3525; server args: `(none)`
- Variant: `0ed8f9223497196d8979accb24ac737becc42f2b` p7-3526-routing; server args: `(none)`
- Binaries: two binaries; host `wolga` (fleet layout)
- Server query threads (`--num-simultaneous-queries`): 1
- **Simulated out-of-memory regime**: every arm's qlever-server ran under a cgroup v2 cap `MemoryMax=2G`, `MemorySwapMax=0` (user `systemd-run --scope`); the cap charges the page cache, so the index cannot stay fully cached. Samples: 198; scope memory.max 2147483648 B; peak memory.current 0.87 GiB; max oom_kill 0.
- io_uring use: not recorded (no perf stat output).
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-title-large | cold | p6-3525 | 3 | 4.7951 | 4.7189 | 4.8201 |  |  |  |
| H-vocab-title-large | cold | p7-3526-routing | 3 | 1.2548 | 1.2352 | 1.7160 | -73.83% | variant faster | identical bytes |
| H-vocab-title-large | warm | p6-3525 | 3 | 0.5388 | 0.5309 | 0.5428 |  |  |  |
| H-vocab-title-large | warm | p7-3526-routing | 3 | 1.1503 | 1.1484 | 1.1592 | +113.48% | variant slower | identical bytes |
| H-size | cold | p6-3525 | 3 | 3.9196 | 3.9170 | 3.9232 |  |  |  |
| H-size | cold | p7-3526-routing | 3 | 1.2917 | 1.2772 | 1.3192 | -67.05% | variant faster | identical bytes |
| H-size | warm | p6-3525 | 3 | 0.7546 | 0.7497 | 0.7570 |  |  |  |
| H-size | warm | p7-3526-routing | 3 | 1.0750 | 1.0624 | 1.0851 | +42.46% | variant slower | identical bytes |

## Verdict

- H-vocab-title-large cold: variant faster (-73.83%); correctness: identical bytes
- H-vocab-title-large warm: variant slower (+113.48%); correctness: identical bytes
- H-size cold: variant faster (-67.05%); correctness: identical bytes
- H-size warm: variant slower (+42.46%); correctness: identical bytes

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
