# Three-arm run: one base run, two comparisons

## base vs variant (p15-controller-off)
## PR #3476 A/B on wikidata (turtle_export)

- Base: `f9fc54f69d7492a907383e244e291d29de6d8d83` base f9fc54f6; server args: `(none)`
- Variant: `95f657ab9548758a2bbe9c81df147d11f1278aa9` p15-controller-off; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

### Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | base f9fc54f6 | 3 | 23.7973 | 23.7621 | 23.8369 |  |  |  |
| H-vocab-label-large-de | cold | p15-controller-off | 3 | 23.7254 | 23.7212 | 23.8390 | -0.30% | within noise | identical bytes |
| H-vocab-label-large-de | warm | base f9fc54f6 | 3 | 15.7106 | 15.5004 | 15.8758 |  |  |  |
| H-vocab-label-large-de | warm | p15-controller-off | 3 | 15.9212 | 15.8619 | 16.0054 | +1.34% | within noise | identical bytes |
| H-vocab-random-label-de-200k | cold | base f9fc54f6 | 3 | 10.8887 | 10.8703 | 10.9779 |  |  |  |
| H-vocab-random-label-de-200k | cold | p15-controller-off | 3 | 10.7456 | 10.7291 | 10.9872 | -1.31% | within noise | identical bytes |
| H-vocab-random-label-de-200k | warm | base f9fc54f6 | 3 | 4.6338 | 4.5923 | 4.6708 |  |  |  |
| H-vocab-random-label-de-200k | warm | p15-controller-off | 3 | 4.6108 | 4.5508 | 4.6586 | -0.50% | within noise | identical bytes |

### Verdict

- H-vocab-label-large-de cold: within noise (-0.30%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (+1.34%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: within noise (-1.31%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (-0.50%); correctness: identical bytes

### Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: PASS ==
- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

### Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.

## base vs variant2 (p15-controller-on)
## PR #3476 A/B on wikidata (turtle_export)

- Base: `f9fc54f69d7492a907383e244e291d29de6d8d83` base f9fc54f6; server args: `(none)`
- Variant: `95f657ab9548758a2bbe9c81df147d11f1278aa9` p15-controller-on; server args: `--set-runtime-parameter iouring-adaptive-batch-enabled=true`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

### Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | base f9fc54f6 | 3 | 23.7973 | 23.7621 | 23.8369 |  |  |  |
| H-vocab-label-large-de | cold | p15-controller-on | 3 | 23.9791 | 23.7360 | 24.0088 | +0.76% | within noise | identical bytes |
| H-vocab-label-large-de | warm | base f9fc54f6 | 3 | 15.7106 | 15.5004 | 15.8758 |  |  |  |
| H-vocab-label-large-de | warm | p15-controller-on | 3 | 15.6983 | 15.6249 | 15.8995 | -0.08% | within noise | identical bytes |
| H-vocab-random-label-de-200k | cold | base f9fc54f6 | 3 | 10.8887 | 10.8703 | 10.9779 |  |  |  |
| H-vocab-random-label-de-200k | cold | p15-controller-on | 3 | 10.8128 | 10.7359 | 10.8719 | -0.70% | within noise | identical bytes |
| H-vocab-random-label-de-200k | warm | base f9fc54f6 | 3 | 4.6338 | 4.5923 | 4.6708 |  |  |  |
| H-vocab-random-label-de-200k | warm | p15-controller-on | 3 | 4.5770 | 4.5475 | 4.6593 | -1.23% | within noise | identical bytes |

### Verdict

- H-vocab-label-large-de cold: within noise (+0.76%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (-0.08%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: within noise (-0.70%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (-1.23%); correctness: identical bytes

### Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: PASS ==
- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

### Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.

## Concern per row

| query | scenario | arm | concern |
|---|---|---|---|
| H-vocab-label-large-de | cold | p15-controller-off | main claim: wave reap (controller off), cold |
| H-vocab-label-large-de | cold | p15-controller-on | main claim: adaptive controller on, cold |
| H-vocab-label-large-de | warm | p15-controller-off | regression guard: wave reap on page-cache hits |
| H-vocab-label-large-de | warm | p15-controller-on | regression guard: adaptive controller on, page-cache hits |
| H-vocab-random-label-de-200k | cold | p15-controller-off | scattered access: wave reap, cold random lookups |
| H-vocab-random-label-de-200k | cold | p15-controller-on | scattered access: adaptive controller on, cold |
| H-vocab-random-label-de-200k | warm | p15-controller-off | regression guard: scattered page-cache hits |
| H-vocab-random-label-de-200k | warm | p15-controller-on | regression guard: adaptive controller on, scattered hits |
