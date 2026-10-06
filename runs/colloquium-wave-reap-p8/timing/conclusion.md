# PR #161 A/B on wikidata (turtle_export)

- Base: `51269ab4bf895211983287d1086c0a700ea43c86` part8-51269ab4; server args: `(none)`
- Variant: `49487dc53051e2aa3657beeafdce58d1f275434b` wave-reap-49487dc5; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 10 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-random-label-de-400k | cold | part8-51269ab4 | 10 | 23.0707 | 20.0223 | 23.1947 |  |  |  |
| H-vocab-random-label-de-400k | cold | wave-reap-49487dc5 | 10 | 22.9511 | 21.6995 | 24.1372 | -0.52% | within noise | identical bytes |
| H-vocab-random-label-de-400k | warm | part8-51269ab4 | 10 | 9.7808 | 8.7248 | 12.2700 |  |  |  |
| H-vocab-random-label-de-400k | warm | wave-reap-49487dc5 | 10 | 9.7952 | 8.8050 | 12.2465 | +0.15% | within noise | identical bytes |
| H-vocab-random-label-de-200k | cold | part8-51269ab4 | 10 | 14.9745 | 14.8802 | 15.1373 |  |  |  |
| H-vocab-random-label-de-200k | cold | wave-reap-49487dc5 | 10 | 14.9631 | 14.8665 | 15.1266 | -0.08% | within noise | identical bytes |
| H-vocab-random-label-de-200k | warm | part8-51269ab4 | 10 | 5.0891 | 4.5967 | 6.2968 |  |  |  |
| H-vocab-random-label-de-200k | warm | wave-reap-49487dc5 | 10 | 5.1778 | 4.6643 | 6.1178 | +1.74% | within noise | identical bytes |
| H-vocab-label-large-de | cold | part8-51269ab4 | 10 | 33.8799 | 31.8788 | 34.4023 |  |  |  |
| H-vocab-label-large-de | cold | wave-reap-49487dc5 | 10 | 33.5809 | 32.7118 | 34.6872 | -0.88% | within noise | identical bytes |
| H-vocab-label-large-de | warm | part8-51269ab4 | 10 | 19.2504 | 17.1017 | 21.1120 |  |  |  |
| H-vocab-label-large-de | warm | wave-reap-49487dc5 | 10 | 18.2205 | 15.7218 | 20.0280 | -5.35% | within noise | identical bytes |

## Verdict

- H-vocab-random-label-de-400k cold: within noise (-0.52%); correctness: identical bytes
- H-vocab-random-label-de-400k warm: within noise (+0.15%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: within noise (-0.08%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (+1.74%); correctness: identical bytes
- H-vocab-label-large-de cold: within noise (-0.88%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (-5.35%); correctness: identical bytes

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
