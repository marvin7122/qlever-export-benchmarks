# PR #3539 A/B on wikidata (turtle_export)

- Base: `fc954b6300d518ce25131169731e45f9d4f867a2` p12; server args: `(none)`
- Variant: `ca7132433d9da6cd54f04c68088d2888edd6190a` mmap-resident; server args: `--set-runtime-parameter vocabulary-mmap-resident-reads=true`
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
| H-vocab-label-large-de | cold | mmap-resident | 5 | 26.1421 | 19.7891 | 26.4496 | -19.62% | variant faster | identical bytes |
| H-vocab-label-large-de | warm | p12 | 5 | 18.7397 | 15.4945 | 23.3114 |  |  |  |
| H-vocab-label-large-de | warm | mmap-resident | 5 | 11.4012 | 8.9664 | 13.4023 | -39.16% | variant faster | identical bytes |

## Cycles (perf stat on the server process tree, user+kernel, per query)

Warm rows are CPU-bound: their verdict is stated on cycles (same noise rule); wall time is reported above. CV = coefficient of variation over the trials of one cell.

| query | scenario | arm | n | median Gcycles | min | max | delta vs base | verdict | CV cycles | CV wall |
|---|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | p12 | 5 | 146.476 | 137.365 | 151.943 |  |  | 3.97% | 5.03% |
| H-vocab-label-large-de | cold | mmap-resident | 5 | 118.704 | 91.694 | 120.759 | -18.96% | variant faster | 9.76% | 10.50% |
| H-vocab-label-large-de | warm | p12 | 5 | 89.487 | 76.425 | 110.081 |  |  | 11.79% | 13.22% |
| H-vocab-label-large-de | warm | mmap-resident | 5 | 61.111 | 48.416 | 69.806 | -31.71% | variant faster | 14.32% | 15.74% |

## Verdict

- H-vocab-label-large-de cold: variant faster (-19.62%); correctness: identical bytes
- H-vocab-label-large-de warm: variant faster (-39.16%); correctness: identical bytes
- H-vocab-label-large-de warm, on cycles (verdict basis for warm rows): variant faster (-31.71%)

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
