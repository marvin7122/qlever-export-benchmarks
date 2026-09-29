# PR #83 A/B on wikidata (turtle_export)

- Base: `9eb57fad` registered-buffers; server args: `--set-runtime-parameter vocabulary-iouring-registered-buffers=true`
- Variant: `9eb57fad` registered-buffers+O_DIRECT-coalesced; server args: `--set-runtime-parameter vocabulary-iouring-registered-buffers=true --set-runtime-parameter vocabulary-iouring-direct-io=true`
- Binaries: same binary, runtime-flag A/B; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps: 2 per arm, query and scenario; arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| H-vocab-label-large-de | cold | registered-buffers | 2 | 27.0338 | 26.8371 | 27.2305 |  |  |  |
| H-vocab-label-large-de | cold | registered-buffers+O_DIRECT-coalesced | 2 | 50.9675 | 50.8752 | 51.0597 | +88.53% | variant slower | identical bytes |
| H-vocab-random-label-de-200k | cold | registered-buffers | 2 | 10.5808 | 10.5687 | 10.5930 |  |  |  |
| H-vocab-random-label-de-200k | cold | registered-buffers+O_DIRECT-coalesced | 2 | 9.9803 | 9.9768 | 9.9838 | -5.68% | variant faster | identical bytes |

## Verdict

- H-vocab-label-large-de cold: variant slower (+88.53%); correctness: identical bytes
- H-vocab-random-label-de-200k cold: variant faster (-5.68%); correctness: identical bytes

## Gates

- `gate-postflight-cold.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.

## Notes (agent)

- Branch `wire/pr83-registered-buffers` @ 9eb57fad (marvin7122/qlever#223): consecutive requests of a batch whose blocks lie in the same 4 KiB slot share one O_DIRECT read.
- Mechanism engaged: two `Opened ... with O_DIRECT` lines per variant server log.
- read_bytes label-large: 32.64 GB (was 36.58 GB before coalescing; buffered base 9.43 GB). Coalescing within a batch removes only ~11 % of the amplification: the requests of a batch are in result order, not file order, and most block reuse on the buffered path is across batches (page cache) and from readahead. O_DIRECT has neither.
- random-200k: -5.68 %, ranges disjoint (base 10.569..10.593 s, variant 9.977..9.984 s), read_bytes 2.99 -> 2.96 GB, cpu_s 7.7 -> 7.15 s: scattered single-word reads avoid readahead and page-cache insertion.
- Verdict: O_DIRECT is workload dependent (+88.5 % on the dense label query, -5.7 % on scattered lookups). Keep `vocabulary-iouring-direct-io` default off.
- `bin/` not committed.
