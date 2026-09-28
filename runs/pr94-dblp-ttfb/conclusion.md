# PR #225 (wiring #94) — TTFB, DBLP H-size-select (tsv), 1 thread

Method: pr-ab.sh / benchmark_export.py have no TTFB field (confirmed: no
`time_starttransfer`/`ttfb` string anywhere in `scripts/pr-ab.sh`). Measured
separately, outside the timed pr-ab.sh reps in
`experiments/runs/pr94-dblp-hsizeselect-t1-ab/`: one server start per arm
(same binary `3e247beb`, `--set-runtime-parameter export-v2-adaptive-chunk-sizing=false|true`),
one untimed warm-up request, then one `curl -s -o /dev/null -w
'time_starttransfer=%{time_starttransfer} time_total=%{time_total}
size_download=%{size_download}'` request per arm. n=1 per arm (not an A/B
gate run; no correctness/noise-rule claim beyond "measured once").
Driver: `pr94-ttfb.sh` (queued via `ural-wq bench ... --qlever-branch
wire/pr94`, seq 4834; log below).

## Result

| arm | time_starttransfer (s) | time_total (s) | bytes |
|---|---|---|---|
| flag-off (export-v2-adaptive-chunk-sizing=false) | 0.136549 | 2.443081 | 59424342 |
| flag-on  (export-v2-adaptive-chunk-sizing=true)  | 0.136278 | 2.432580 | 59424342 |

Delta: -0.20 ms TTFB (flag-on faster), -0.0003% — no measurable difference,
well inside single-sample noise (n=1, no repeats).

## Interpretation

No TTFB effect from adaptive chunk sizing is visible for this query. This is
consistent with the limitation #94's own PR description already flagged:
"the dominant cost may be query evaluation / triple materialization from the
index rather than string formatting" — `H-size-select` is a SELECT with a
non-trivial WHERE clause, so the ~136 ms before any bytes reach the client is
almost entirely time to produce the first result rows from the query engine,
not time to format/flush the first HTTP chunk. AdaptiveChunkSizer's first
64 KiB target vs. the fixed 8192-row morsel are both dwarfed by that
evaluation cost here. A TTFB win from this component (if any) would need a
query where the first-morsel formatting time is a non-negligible fraction of
time-to-first-byte, e.g. a large unfiltered scan.

## Raw log

```
flag-off (export-v2-adaptive-chunk-sizing=false): time_starttransfer=0.136549 time_total=2.443081 size_download=59424342
flag-on (export-v2-adaptive-chunk-sizing=true): time_starttransfer=0.136278 time_total=2.432580 size_download=59424342
```
