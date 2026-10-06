# PR #3506 A/B on wikidata (turtle_export)

- Base: `f8cca285e3d0d3400dd51be97b5ebf078cd454de` p12-upstream-stack-22; server args: `(none)`
- Variant: `785c408e604183b5c18e233026703d64b5b09e9c` p13-pipeline3; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Trials: up to 3 per arm, query and scenario; a cell stops after 2 trials when every variant's min..max range is disjoint from base's by more than 10% of the base median, or (warm) when every arm's cycles CV is below 1 % (`adaptive.tsv`); column n gives the trials per cell. Arms interleaved per trial, order alternating (odd trials base first, even trials reversed).
- cold: per trial a fresh server after the index's serving files were evicted from the page cache (`posix_fadvise(DONTNEED)`, residency verified with `mincore`, `startup.tsv`); one execution per trial.
- Pinning: server CPUs 0-2, client/driver CPU 3; SMT siblings of both kept free of our work
- Output sink: timed executions discard the body (byte count + streamed xxh3_128 only); each arm's body is captured once per query in an untimed execution (the warm-up) and digested; a trial is correct when its xxh3 equals its arm's captured body and that body equals base's.
- warm: one long-running server per binary for all queries and trials (runtime-parameter-only arms share a server; parameters switched over HTTP before each measurement and verified in the reply); one untimed warm-up per arm and query; QLever's result cache cleared before every execution and verified empty (`cache-stats`), so every execution recomputes; each measurement loops the query until >= 10 s, elapsed = per-query mean.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | p12-upstream-stack-22 | 3 | 23.6568 | 22.9872 | 25.8882 |  |  |  |
| H-vocab-label-large-de | cold | p13-pipeline3 | 3 | 23.4628 | 23.0625 | 23.9904 | -0.82% | within noise | identical bytes |
| H-vocab-label-large-de | warm | p12-upstream-stack-22 | 2 | 15.3248 | 15.2503 | 15.3992 |  |  |  |
| H-vocab-label-large-de | warm | p13-pipeline3 | 2 | 15.3291 | 15.2695 | 15.3887 | +0.03% | within noise | identical bytes |
| H-vocab-random-label-de-200k | cold | p12-upstream-stack-22 | 3 | 10.4129 | 10.3019 | 12.9627 |  |  |  |
| H-vocab-random-label-de-200k | cold | p13-pipeline3 | 3 | 10.2943 | 10.2741 | 10.3231 | -1.14% | within noise | identical bytes |
| H-vocab-random-label-de-200k | warm | p12-upstream-stack-22 | 2 | 3.9895 | 3.9745 | 4.0045 |  |  |  |
| H-vocab-random-label-de-200k | warm | p13-pipeline3 | 2 | 3.9625 | 3.9431 | 3.9820 | -0.68% | within noise | identical bytes |
| H-vocab-label-large | cold | p12-upstream-stack-22 | 3 | 21.4352 | 21.3760 | 21.7082 |  |  |  |
| H-vocab-label-large | cold | p13-pipeline3 | 3 | 22.1900 | 21.6725 | 34.9647 | +3.52% | within noise | identical bytes |
| H-vocab-label-large | warm | p12-upstream-stack-22 | 2 | 21.4984 | 21.3969 | 21.6000 |  |  |  |
| H-vocab-label-large | warm | p13-pipeline3 | 2 | 21.4315 | 21.2680 | 21.5949 | -0.31% | within noise | identical bytes |

## Cycles (perf stat on the server process tree, user+kernel, per query)

Warm rows are CPU-bound: their verdict is stated on cycles (same noise rule); wall time is reported above. CV = coefficient of variation over the trials of one cell.

| query | scenario | arm | n | median Gcycles | min | max | delta vs base | verdict | CV cycles | CV wall |
|---|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | p12-upstream-stack-22 | 3 | 107.808 | 106.405 | 120.157 |  |  | 5.54% | 5.13% |
| H-vocab-label-large-de | cold | p13-pipeline3 | 3 | 107.892 | 107.258 | 111.204 | +0.08% | within noise | 1.59% | 1.62% |
| H-vocab-label-large-de | warm | p12-upstream-stack-22 | 2 | 75.545 | 75.289 | 75.802 |  |  | 0.34% | 0.49% |
| H-vocab-label-large-de | warm | p13-pipeline3 | 2 | 75.272 | 74.955 | 75.589 | -0.36% | within noise | 0.42% | 0.39% |
| H-vocab-random-label-de-200k | cold | p12-upstream-stack-22 | 3 | 29.664 | 29.337 | 40.802 |  |  | 16.02% | 10.95% |
| H-vocab-random-label-de-200k | cold | p13-pipeline3 | 3 | 29.208 | 29.025 | 29.369 | -1.54% | within noise | 0.48% | 0.20% |
| H-vocab-random-label-de-200k | warm | p12-upstream-stack-22 | 2 | 17.490 | 17.438 | 17.543 |  |  | 0.30% | 0.38% |
| H-vocab-random-label-de-200k | warm | p13-pipeline3 | 2 | 17.377 | 17.376 | 17.379 | -0.65% | within noise | 0.01% | 0.49% |
| H-vocab-label-large | cold | p12-upstream-stack-22 | 3 | 121.542 | 121.155 | 122.039 |  |  | 0.30% | 0.67% |
| H-vocab-label-large | cold | p13-pipeline3 | 3 | 122.712 | 120.993 | 192.685 | +0.96% | within noise | 22.96% | 23.40% |
| H-vocab-label-large | warm | p12-upstream-stack-22 | 2 | 121.295 | 121.271 | 121.318 |  |  | 0.02% | 0.47% |
| H-vocab-label-large | warm | p13-pipeline3 | 2 | 120.761 | 120.557 | 120.966 | -0.44% | within noise | 0.17% | 0.76% |

## Verdict

- H-vocab-label-large-de cold: within noise (-0.82%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (+0.03%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: within noise (-1.14%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (-0.68%); correctness: identical bytes
- H-vocab-label-large cold: within noise (+3.52%); correctness: identical bytes
- H-vocab-label-large warm: within noise (-0.31%); correctness: identical bytes
- H-vocab-label-large-de warm, on cycles (verdict basis for warm rows): within noise (-0.36%)
- H-vocab-random-label-de-200k warm, on cycles (verdict basis for warm rows): within noise (-0.65%)
- H-vocab-label-large warm, on cycles (verdict basis for warm rows): within noise (-0.44%)

## Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: PASS ==
- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Profiles

One extra warm rep per arm and query under `perf record -g` (not part of the timing): `perf/<query>/<arm>/` holds `report-top50.txt`, `stacks.folded` and `flame.svg` when FlameGraph was available; `perf/<query>/diff.svg` is the base-to-variant differential.

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
