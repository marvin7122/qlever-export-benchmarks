# PR #3539 A/B on dblp (turtle_export)

- Base: `67cf2ee3a7640acb2eac4438ba40b883f691f99f` part11-3529; server args: `(none)`
- Variant: `3a19a966f3023c91f345aa59b6ad85ab89655bcf` p12-flag-on; server args: `--set-runtime-parameter adaptive-export-chunk-size=true`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- **Simulated out-of-memory regime**: every arm's qlever-server ran under a cgroup v2 cap `MemoryMax=2G`, `MemorySwapMax=0` (user `systemd-run --scope`); the cap charges the page cache, so the index cannot stay fully cached. No memcap samples recorded.
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-size | warm | part11-3529 | 3 | 0.6914 | 0.6834 | 0.6977 |  |  |  |
| H-size | warm | p12-flag-on | 3 | 0.6862 | 0.6732 | 0.6911 | -0.74% | within noise | identical bytes |

## Verdict

- H-size warm: within noise (-0.74%); correctness: identical bytes

## Gates

- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
