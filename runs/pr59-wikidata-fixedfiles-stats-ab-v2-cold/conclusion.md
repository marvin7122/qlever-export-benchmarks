# PR #59 A/B on wikidata (turtle_export)

- Base: `3aaff2de` routing-stats; server args: `(none)`
- Variant: `27e4cb88` fixedfiles-routing-stats; server args: `(none)`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 10 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | routing-stats | 9 | 26.9426 | 26.5395 | 27.3356 |  |  |  |
| H-vocab-label-large-de | cold | fixedfiles-routing-stats | 9 | 26.2605 | 25.9754 | 26.7461 | -2.53% | within noise | **MISMATCH** (MISMATCH) |
| H-vocab-random-label-de-200k | cold | routing-stats | 10 | 10.6159 | 10.4915 | 10.7462 |  |  |  |
| H-vocab-random-label-de-200k | cold | fixedfiles-routing-stats | 10 | 10.5695 | 10.4336 | 10.7197 | -0.44% | within noise | identical bytes |

## Verdict

- H-vocab-label-large-de cold: within noise (-2.53%); correctness: **MISMATCH** (MISMATCH)
- H-vocab-random-label-de-200k cold: within noise (-0.44%); correctness: identical bytes

## Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: FAIL ==
  - FAIL 2 failed/non-complete rows
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

- H-vocab-label-large-de/cold/base rep 5: status=failed bytes=409890946
- H-vocab-label-large-de/cold/base rep 5: correctness MISMATCH
- H-vocab-label-large-de/cold/variant rep 5: status=failed bytes=18752176
- H-vocab-label-large-de/cold/variant rep 5: correctness MISMATCH
- H-vocab-label-large-de/cold/base: 9 good reps of 10
- H-vocab-label-large-de/cold/variant: 9 good reps of 10

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.

## Note on rep 5 of H-vocab-label-large-de (added after the run)

Rep 5 failed in both arms with `RemoteProtocolError('peer closed connection')`:
the server was killed mid-stream (its log ends without an error). Cause: while
this entry ran (17:45–17:47 UTC), a `--dry-run` of the same pr-ab driver was
started on Ural for another entry, and the driver's setup runs
`fuser -k 7015/tcp`, which killed the running benchmark server. Not related to
either binary. The rep is excluded in both arms (9 good interleaved reps each);
the truncated bodies were deleted from mismatch/ (> 20 MB).

## Concern per row

| query | scenario | concern |
|---|---|---|
| H-vocab-label-large-de | cold | main claim: fixed files on the sequential cold export, same base, engagement counted |
| H-vocab-random-label-de-200k | cold | scattered access, same base |
