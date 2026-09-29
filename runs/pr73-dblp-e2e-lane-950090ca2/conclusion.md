# PR #3522 A/B on dblp (turtle_export)

- Base: `2d5c48a8df1e37ab1a48382a16565e64bdc0500d` part2-upstream-stack-03; server args: `(none)`
- Variant: `950090ca21a6979b3b617f4b5af148e0af9e8da2` part3-upstream-stack-04; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- **Simulated out-of-memory regime**: every arm's qlever-server ran under a cgroup v2 cap `MemoryMax=2G`, `MemorySwapMax=0` (user `systemd-run --scope`); the cap charges the page cache, so the index cannot stay fully cached. Samples: 186; scope memory.max 2147483648 B; peak memory.current 1.23 GiB; max oom_kill 0.
- io_uring use: not recorded (no perf stat output).
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-title-3m | warm | part2-upstream-stack-03 | 3 | 13.5560 | 13.2404 | 21.0401 |  |  |  |
| H-vocab-title-3m | warm | part3-upstream-stack-04 | 3 | 13.1216 | 12.8123 | 16.1126 | -3.20% | within noise | identical bytes |

## Verdict

- H-vocab-title-3m warm: within noise (-3.20%); correctness: identical bytes

## Gates

- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
