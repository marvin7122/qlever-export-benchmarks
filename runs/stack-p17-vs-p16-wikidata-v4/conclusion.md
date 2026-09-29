# PR #3499 A/B on wikidata (turtle_export)

- Base: `dbaff3f862f15ba6467a26d117fb5e992f106e79` base dbaff3f8; server args: `(none)`
- Variant: `a51fb47a89a71ecf58a512e4c46a74437dafa120` variant a51fb47a; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 3 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | base dbaff3f8 | 3 | 23.9661 | 23.7718 | 24.1149 |  |  |  |
| H-vocab-label-large-de | cold | variant a51fb47a | 3 | 24.0254 | 23.5149 | 24.5806 | +0.25% | within noise | identical bytes |
| H-vocab-label-large-de | warm | base dbaff3f8 | 3 | 16.1151 | 15.9429 | 16.1741 |  |  |  |
| H-vocab-label-large-de | warm | variant a51fb47a | 3 | 16.0136 | 15.9135 | 16.0349 | -0.63% | within noise | identical bytes |
| H-vocab-random-label-de-200k | cold | base dbaff3f8 | 3 | 10.8033 | 10.7511 | 10.8575 |  |  |  |
| H-vocab-random-label-de-200k | cold | variant a51fb47a | 3 | 10.8314 | 10.7815 | 10.8635 | +0.26% | within noise | identical bytes |
| H-vocab-random-label-de-200k | warm | base dbaff3f8 | 3 | 4.6882 | 4.5684 | 4.7103 |  |  |  |
| H-vocab-random-label-de-200k | warm | variant a51fb47a | 3 | 4.6335 | 4.6244 | 4.6781 | -1.17% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de cold: within noise (+0.25%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (-0.63%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: within noise (+0.26%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (-1.17%); correctness: identical bytes

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

## Concern per row

| query | scenario | arm | concern |
|---|---|---|---|
| H-vocab-label-large-de | cold | variant a51fb47a | main claim: registered files, cold reads |
| H-vocab-label-large-de | warm | variant a51fb47a | regression guard: registered-file setup on page-cache hits |
| H-vocab-random-label-de-200k | cold | variant a51fb47a | scattered access: registered files, cold random reads |
| H-vocab-random-label-de-200k | warm | variant a51fb47a | regression guard: registered files, scattered hits |
