# PR #3522 A/B on dblp (turtle_export)

- Base: `0456e6c5955576282965bd1821c2b84a093dda8a` part2-upstream-stack-03; server args: `(none)`
- Variant: `010e89515ac77fa4e615b7deb5a29dcb46fbd587` part3-upstream-stack-04; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-title-3m | warm | part2-upstream-stack-03 | 3 | 11.7206 | 11.6341 | 11.7668 |  |  |  |
| H-vocab-title-3m | warm | part3-upstream-stack-04 | 3 | 11.5174 | 11.4788 | 11.5969 | -1.73% | variant faster | identical bytes |

## Verdict

- H-vocab-title-3m warm: variant faster (-1.73%); correctness: identical bytes

## Gates

- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
