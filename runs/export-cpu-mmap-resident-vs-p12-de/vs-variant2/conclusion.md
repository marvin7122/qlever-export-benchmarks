# PR #3539 A/B on wikidata (turtle_export)

- Base: `fc954b6300d518ce25131169731e45f9d4f867a2` p12; server args: `(none)`
- Variant: `ca7132433d9da6cd54f04c68088d2888edd6190a` mmap-resident-off; server args: `--set-runtime-parameter vocabulary-mmap-resident-reads=false`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Trials: 5 per arm, query and scenario; arms interleaved per trial, order alternating (odd trials base first, even trials reversed).
- cold: per trial a fresh server after the index's serving files were evicted from the page cache (`posix_fadvise(DONTNEED)`, residency verified with `mincore`, `startup.tsv`); one execution per trial.
- Pinning: server CPUs 0-2, client/driver CPU 3; SMT siblings of both kept free of our work
- Output sink: timed executions discard the body (byte count + streamed xxh3_128 only); each arm's body is captured once per query in an untimed execution (the warm-up) and digested; a trial is correct when its xxh3 equals its arm's captured body and that body equals base's.
- warm: one long-running server per binary for all queries and trials (runtime-parameter-only arms share a server; parameters switched over HTTP before each measurement and verified in the reply); one untimed warm-up per arm and query; QLever's result cache cleared before every execution and verified empty (`cache-stats`), so every execution recomputes; each measurement loops the query until >= 10 s, elapsed = per-query mean.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | p12 | 5 | 32.5247 | 29.7755 | 33.9734 |  |  |  |
| H-vocab-label-large-de | cold | mmap-resident-off | 5 | 33.6187 | 29.9130 | 34.0019 | +3.36% | within noise | identical bytes |
| H-vocab-label-large-de | warm | p12 | 5 | 18.7397 | 15.4945 | 23.3114 |  |  |  |
| H-vocab-label-large-de | warm | mmap-resident-off | 5 | 20.3330 | 17.0651 | 23.3300 | +8.50% | within noise | identical bytes |

## Cycles (perf stat on the server process tree, user+kernel, per query)

Warm rows are CPU-bound: their verdict is stated on cycles (same noise rule); wall time is reported above. CV = coefficient of variation over the trials of one cell.

| query | scenario | arm | n | median Gcycles | min | max | delta vs base | verdict | CV cycles | CV wall |
|---|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | p12 | 5 | 146.476 | 137.365 | 151.943 |  |  | 3.97% | 5.03% |
| H-vocab-label-large-de | cold | mmap-resident-off | 5 | 150.188 | 137.480 | 151.886 | +2.53% | within noise | 4.59% | 5.85% |
| H-vocab-label-large-de | warm | p12 | 5 | 89.487 | 76.425 | 110.081 |  |  | 11.79% | 13.22% |
| H-vocab-label-large-de | warm | mmap-resident-off | 5 | 98.797 | 81.917 | 109.770 | +10.40% | within noise | 11.29% | 11.83% |

## Verdict

- H-vocab-label-large-de cold: within noise (+3.36%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (+8.50%); correctness: identical bytes
- H-vocab-label-large-de warm, on cycles (verdict basis for warm rows): within noise (+10.40%)

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
