# PR #3547 A/B on dblp (turtle_export)

- Base: `0ed8f9223497196d8979accb24ac737becc42f2b` p7-3526-routing; server args: `(none)`
- Variant: `42785c8c95fda389c06af1cfd567bacff41eaffc` p8-3547-fastpath-off; server args: `--set-runtime-parameter vocabulary-iouring-page-cache-fast-path=false`
- Binaries: two binaries; host `wolga` (fleet layout)
- Server query threads (`--num-simultaneous-queries`): 1
- **Simulated out-of-memory regime**: every arm's qlever-server ran under a cgroup v2 cap `MemoryMax=2G`, `MemorySwapMax=0` (user `systemd-run --scope`); the cap charges the page cache, so the index cannot stay fully cached. No memcap samples recorded.
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-title-large | cold | p7-3526-routing | 3 | 1.2324 | 1.2051 | 1.2360 |  |  |  |
| H-vocab-title-large | cold | p8-3547-fastpath-off | 3 | 1.2235 | 1.2200 | 1.2236 | -0.72% | within noise | identical bytes |
| H-vocab-title-large | warm | p7-3526-routing | 3 | 1.1527 | 1.1388 | 1.1685 |  |  |  |
| H-vocab-title-large | warm | p8-3547-fastpath-off | 3 | 1.1486 | 1.1302 | 1.1560 | -0.35% | within noise | identical bytes |
| H-size | cold | p7-3526-routing | 3 | 1.2921 | 1.2855 | 1.3611 |  |  |  |
| H-size | cold | p8-3547-fastpath-off | 3 | 1.3023 | 1.2945 | 1.3162 | +0.79% | within noise | identical bytes |
| H-size | warm | p7-3526-routing | 3 | 1.0651 | 1.0566 | 1.0767 |  |  |  |
| H-size | warm | p8-3547-fastpath-off | 3 | 1.0760 | 1.0226 | 1.0770 | +1.02% | within noise | identical bytes |

## Verdict

- H-vocab-title-large cold: within noise (-0.72%); correctness: identical bytes
- H-vocab-title-large warm: within noise (-0.35%); correctness: identical bytes
- H-size cold: within noise (+0.79%); correctness: identical bytes
- H-size warm: within noise (+1.02%); correctness: identical bytes

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
