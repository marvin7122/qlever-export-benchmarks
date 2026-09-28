# PR #3476 A/B on wikidata (turtle_export)

- Base: `26427fd7` controller-off; server args: `--set-runtime-parameter iouring-adaptive-batch-enabled=false`
- Variant: `26427fd7` controller-on; server args: `--set-runtime-parameter iouring-adaptive-batch-enabled=true`
- Binaries: same binary, runtime-flag A/B; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps (adaptive): 3 per arm and cell first; reps 4-5 only when the two arms' min..max ranges overlapped after 3 (`adaptive.tsv`); column n gives the reps per cell. Arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | controller-off | 5 | 23.3066 | 23.2553 | 23.7724 |  |  |  |
| H-vocab-label-large-de | cold | controller-on | 5 | 23.9430 | 23.7643 | 24.5353 | +2.73% | within noise | identical bytes |
| H-vocab-label-large-de | warm | controller-off | 5 | 16.0146 | 15.8544 | 16.2349 |  |  |  |
| H-vocab-label-large-de | warm | controller-on | 5 | 16.2494 | 15.9394 | 16.3394 | +1.47% | within noise | identical bytes |
| H-vocab-random-label-de-200k | cold | controller-off | 3 | 10.1196 | 10.0238 | 10.1444 |  |  |  |
| H-vocab-random-label-de-200k | cold | controller-on | 3 | 10.2876 | 10.2440 | 10.3306 | +1.66% | variant slower | identical bytes |
| H-vocab-random-label-de-200k | warm | controller-off | 5 | 4.1242 | 4.0206 | 4.2584 |  |  |  |
| H-vocab-random-label-de-200k | warm | controller-on | 5 | 4.1436 | 4.1120 | 4.2358 | +0.47% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de cold: within noise (+2.73%); correctness: identical bytes
- H-vocab-label-large-de warm: within noise (+1.47%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: variant slower (+1.66%); correctness: identical bytes
- H-vocab-random-label-de-200k warm: within noise (+0.47%); correctness: identical bytes

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

## Mechanism counters (added by hand from `*/raw/*/result.yaml`)

liburing submit/wait calls (LD_PRELOAD shim) and process CPU, all reps, controller off -> on:

- H-vocab-label-large-de cold: ~141 k -> ~600 k calls; CPU 26.16-26.61 s -> 26.94-27.48 s.
- H-vocab-label-large-de warm: 105 906 -> 576 248 calls; CPU 19.44-19.70 s -> 19.58-19.85 s.
- H-vocab-random-label-de-200k cold: ~4.5 k -> ~24.9 k; CPU 7.20-7.30 s -> 7.39-7.51 s.
- H-vocab-random-label-de-200k warm: 4 170 -> 22 854; CPU 4.30-4.61 s -> 4.44-4.55 s.

Binary: upstream-iouring-adaptive-batching `26427fd71` (same controller code as fork PR #161),
same binary in both arms, `iouring-adaptive-batch-enabled=false|true` (server logs confirm).
With one batch in flight per export thread, the controller flushes early groups (from 16 reads
on) while few reads are outstanding, so it submits 4-5x more often; with no I/O wait to hide,
the extra kernel entries cost CPU and the export is not faster (+0.5 to +2.7 %).
