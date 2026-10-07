# CONSTRUCT row batch size x io_uring ring size: verdict run (stack part 10)

## Question

Is the best cell of the screening grid ([`../batch-ring-grid-p10`](../batch-ring-grid-p10)) faster than the default, cold and warm, with the English label export as a guard?
Arms (same binary `52ca007a`, runtime parameters, server restarted per measurement): default `b1024-r256`, `b16384-r256` (larger batch), `b16384-r1024` (larger batch and ring).

## Setup

Same machine, index, binary and harness as the grid (see its README); driver `tools/pr-ab-grid.sh`.
Queries: German sequential `H-vocab-label-large-de`, German scattered `H-vocab-random-label-de-200k`, English `H-vocab-label-large` (guard; English labels are in the in-memory part of the vocabulary).
Cold: `drop_caches` before every measurement. Warm: a warm-up run, then the query looped until >= 10 s; `elapsed_s` is the per-execution mean.
Planned: 10 interleaved reps per arm, scenario and query, arm order rotating per rep.

## Run status (read first)

1. The run was stopped by SIGTERM at 2026-10-07T10:49:57Z (`ABORTED`, `driver.log`) during the English cold rep 8; the cause was not this agent.
2. Complete: German sequential and scattered, cold and warm, 10 reps each; English cold, 7 reps.
3. Missing: English warm (guard). A 3-trial English warm run (default vs `b16384-r256`) is queued separately.
4. One failed measurement: warm scattered, default arm, rep 9 (`MISMATCH`): the request got `Connection refused` 0.14 s after the server reported ready; the body is empty (0 bytes).
   It is a start-up failure of that one request, not differing output; it is excluded (9 reps in that cell).
   All 136 other bodies are identical per query (`correctness.tsv`).
5. No postflight gate ran (the run did not reach it); the per-row status is in each `results.csv`.

## Result (median [min–max]; paired Δ = vs the default arm of the same rep, median [min–max])

| # | concern | query | scenario | default b1024-r256 | b16384-r256 | paired Δ | b16384-r1024 | paired Δ | verdict |
|---|---|---|---|---|---|---|---|---|---|
| 1 | sequential German | label-large-de | cold (10) | 33.59 [24.94–34.10] | 29.05 [24.82–29.59] | −13.5 % [−18.1, +18.7] | 28.71 [23.23–29.62] | −14.3 % [−20.1, −6.9] | ranges overlap |
| 2 | scattered German | random-label-de-200k | cold (10) | 14.04 [10.97–15.07] | 13.68 [11.49–14.67] | −1.0 % [−10.8, +29.3] | 13.13 [10.66–13.96] | −6.3 % [−24.5, +24.3] | no change |
| 3 | English guard | label-large | cold (7) | 44.69 [43.62–50.67] | 33.99 [31.76–36.01] | −26.8 % [−28.9, −19.9] | 33.20 [25.54–36.63] | −25.0 % [−42.4, −21.5] | faster (disjoint) |
| 4 | sequential German | label-large-de | warm (10) | 23.18 [16.91–23.71] | 18.54 [14.67–20.05] | −15.6 % [−29.1, +1.7] | 19.61 [14.89–20.13] | −15.2 % [−37.2, +4.1] | ranges overlap |
| 5 | scattered German | random-label-de-200k | warm (9/10) | 5.49 [4.42–6.19] | 5.32 [3.99–12.00] | −5.5 % [−15.9, +120.4] | 5.39 [3.94–6.59] | −3.9 % [−14.1, +20.8] | no change |
| 6 | English guard | label-large | warm | – | – | – | – | – | pending (3-trial run) |

Time to first byte (median): German sequential cold 0.60 → 0.86 s, warm 0.16 → 0.19 s; English cold 0.25 → 0.24 s (`paired.txt`).
Ring 1024 vs 256 at batch 16384: no consistent difference (rows 1–5).
The single +120 % rep in row 5 read 2.3 GiB from disk in a "warm" run, i.e. the page cache was partly evicted (shared machine).

## Interpretation

1. The larger batch saves CPU in the export thread: German sequential cold 32.3 → 27.7 s export-thread CPU, English cold user CPU 55.5 → 43.9 s (`grid.md`, `results.csv`).
   The gain is largest where I/O plays no role (English labels are in memory), so it is a per-batch CPU cost, not I/O depth (inferred: fewer per-batch sort/lookup setups and longer coalesced runs).
2. The ring size does not matter (device queue depth ~2, see the grid).
3. The scattered export is dominated by work before the first byte (~10.5 s of ~14 s cold); neither knob changes it measurably.

## Noise

Shared machine, loadavg ~18 at the start (`env-before.txt`).
Rep-to-rep spread is up to ±20 % in some cells; the paired comparison is the more sensitive view.

## Files

- `grid.md`: per-arm table incl. CPU, export-thread CPU, aqu-sz, util, read GiB (metrics recomputed with the final `tools/grid-rep-metrics.py`).
- `paired.txt`: paired deltas and time to first byte.
- `<scenario>/<query>/<arm>/raw/results.csv` and per-rep directories, `correctness.tsv`, `MISMATCH`, `ABORTED`, `driver.log`, `build-env.txt`, `gate-*.log`, `env-before.txt`, `meta.env`.
- `tools/`: driver and scripts.
