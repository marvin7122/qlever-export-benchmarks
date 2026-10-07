# V2 export utilisation diagnosis (fork PR #120/#137, `fast-export=1`)

Question: in run `pr120-wikidata-j8-ab`, export engine V2 at 8 query threads took 6.9 s for `H-vocab-label-large-select`.
That run used 31.7 s of server CPU, so only about 4.6 of 8 cores were busy.
Its time to first byte (TTFB) was 1.7 s, against 0.2 s for the base arm.
Why?

Setup:
- Index: Wikidata truthy on Ural.
- Query: `query.rq` (SELECT CSV, 11,643,064 rows, 674,222,797 bytes).
- Binaries:
  - `87f57674`, the PR #120 head, used for phases A and C;
  - `112f76a7` on fork branch `diag/v2-utilisation`, used for phase B. It is the same code plus CSV instrumentation of morsel intervals and coordinator phases, active only when `QLEVER_V2_DIAG_DIR` is set.
- Driver: `tools/v2-utilisation-diag.sh` (Ural queue #5337). Analysis: `tools/v2util-analyze.py` → `analysis.md` and `analysis/timelines.{svg,png}`.

## Answer in one sentence

The 6.9 s and 4.6 cores are set by HTTP response compression, not by the V2 scheduler.
The harness client (httpx) sends `Accept-Encoding: gzip, deflate` by default.
QLever then deflates the whole response as one serial stream on the HTTP send path.
That caps the output at about 97 MB/s, and V2 can deliver about 240 MB/s.

## Phase C — client / socket check (8 threads, warm, binary 87f57674)

| # | concern | client | trials | wall s, median (min–max) | TTFB s | client CPU s | MB/s |
|---|---|---|---|---|---|---|---|
| 1 | what the A/B harness sees | Python, httpx `iter_bytes` + xxh3 (same loop as `benchmark_export.stream_query`) | 3 | 6.95 (6.95–8.21) | 1.50 (1.47–2.27) | 1.99 | 97 |
| 2 | server without compression | curl → /dev/null | 3 | 2.82 (2.82–6.47) | 0.00 | 0.19 | 239 |
| 3 | client CPU placement | curl pinned to CPU 15 | 3 | 2.89 (2.84–2.93) | 0.00 | 0.21 | 234 |

Each trial is the mean of 2 back-to-back queries.
The 6.47 s curl maximum is trial 1, which ran under co-tenant load (system 15.9 of 16 cores busy).

Evidence that row 1 is compressed:
1. The `ss` samples (`C/ss-*-py-*.txt`) show about 150 MB `bytes_sent` after about 6 s for the Python client, against 440 MB in under 2 s for curl (`C/ss-1-curl-1.txt`).
2. Server CPU is 32.1–32.6 s for the Python client and 27.5–28.2 s for curl, about 4 s more per query.
3. In the code, `getCompressionMethodForRequest` prefers deflate. `HttpUtils::setBody` wraps the generator in `compressStream` (zlib `best_speed`), which runs as one stream on the send path.
4. Row 1 reproduces the A/B numbers: 6.95 s against 6.9 s, and 32.1 s / 6.95 s = 4.6 cores.
5. Its TTFB of 1.5 s matches the time V2 emits its first morsel (phase B, about 1.5–2.0 s). zlib holds back the 13-byte header line until that point.

The Python client is not the limit: it used 2.0 s of CPU in 6.95 s.
The quiet re-run `phaseA-quiet/` (queue #5339) adds curl `--compressed` and the Python client with `Accept-Encoding: identity` to separate the two directly.

## Phase B — where the time goes without compression (curl, diag binary)

Amdahl-style breakdown, 8 threads, warm (`B/j8/warm`), wall 3.40 s:

| # | phase | from s | dur s | morsels running (mean / max) | morsels queued (mean) | coordinator cores | pool cores | other server threads | run-queue wait (cores) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | parse + plan + V2 setup | 0.00 | 0.01 | 0 | 0 | 0 | 0 | 0 | 0 |
| 2 | submit: lazy join produces blocks, coordinator plans and posts morsels; nothing but the header is emitted | 0.01 | 1.89 | 7.92 / 8 | 365 | 0.00 | 7.78 | 2.00 (join / scan threads) | 0.94 |
| 3 | drain: coordinator consumes completed morsels, runs pending ones itself, emits | 1.90 | 1.50 | 8.74 / 9 | 345 | 0.90 | 7.88 | 0.24 | 0.57 |
| 4 | tail (last emit → client done) | 3.40 | ≈0 | – | – | – | – | – | – |

- The pool threads are runnable (state R) in 99% of the samples, and morsel wall ≈ morsel CPU (1% off-CPU).
- The helpers never wait for work: the queue holds 300–400 morsels throughout.
- The coordinator sleeps on a futex 58% of the time. That is `consumeNextResult` waiting for a helper to finish.
- Server CPU: 32.2 s / 3.40 s = 9.5 cores busy.

Scaling with query threads (`--num-simultaneous-queries`), diag binary, curl:

| # | concern | threads | wall cold s | wall warm s | morsels on pool / inline | serialization lanes in drain | CPU per row | coordinator in drain |
|---|---|---|---|---|---|---|---|---|
| 1 | baseline | 1 | 13.21 | 13.69 | 746 / 676 | 2.0 | 2211 ns | 1.00 core |
| 2 | +1 helper | 2 | 8.31 | 8.21 | 1006 / 416 | 3.0 | 1967 ns | 1.00 |
| 3 | +3 helpers | 4 | 5.16 | 5.14 | 1193 / 229 | 5.0 | 2062 ns | 0.99 |
| 4 | +7 helpers | 8 | 3.51 | 3.40 | 1353 / 69 | 8.7 | 2383 ns | 0.90 |

The speedup from 1 to 8 threads is 4.0x warm, and the measured parts account for it:
1. The "1 thread" point already runs 1.75 serialization lanes on average: the pool thread plus the coordinator, which runs pending morsels itself in the drain (1 lane for 1.5 s, 2 lanes for 12.2 s). The join and scan threads also run alongside (about 2.6 cores during the submit phase).
2. At 8 threads there are 8.25 lanes on average (7.9 for 1.89 s, 8.7 for 1.50 s).
3. Going from 1.75 to 8.25 lanes gives 4.7x.
4. CPU per row grows by 8% (2211 → 2383 ns) from 1 to 8 threads. At 8 threads, 8 helpers + coordinator + 2 join threads + HTTP threads exceed the 8 physical cores (SMT siblings), and the effective clock drops from 4.1 to 3.9 GHz.
5. 4.7 / 1.08 ≈ 4.35x is predicted.
6. The remaining gap to the measured 4.0x matches the co-tenant run-queue wait at 8 threads (0.6–0.9 cores of runnable-but-waiting time).
7. No idle helper time remains to recover at 8 threads.

Phase B ran with 5–9 cores of co-tenant load (`queries.csv`, `sys_busy_cores` minus server cores), so its absolute times are inflated.
For example, phase C's curl median of 2.82 s on the original binary is below phase B's 3.40 s.
The shares in the tables (utilisation, phase split) are the result.

Scheduler rules (code + measurement):
- `maxForegroundQueriesForHelperAdmission` = 1. The export query is the only registered query, so helpers are admitted for the whole run (1422 morsel executions for 1422 morsels).
- `kRevocationCheckRows` = 1024. No revocation happened: no partial morsels were resubmitted.
- Morsel size of 8192 rows: 1422 morsels. The tail is at most one morsel (≈20 ms at 2.4 µs/row), and the coordinator also helps with the remaining ones.
- The number of helpers is capped only by the pool size (`--num-simultaneous-queries`), plus the coordinator thread.
- Morsels run in parallel: 8 (pool) + 1 (coordinator). Morsels queued: 300–700 on average.

## Phase A — scaling with the original binary (contaminated, see `analysis.md`)

All Phase A queries ran while other users kept 10–13 of the 16 logical CPUs busy (system 15.9/16).
The numbers in `analysis.md` (for example 8.7 s at 8 threads, base 34 s) are therefore not clean.
The quiet re-run (`phaseA-quiet/`, queue #5339) waits for loadavg < 3.

One result does not depend on the load: server CPU is 34–35 s at every thread count (1, 2, 4, 8, 8 pinned).
More threads do not add CPU.

## Causes, ranked

1. **HTTP compression on the response path (harness side and server side).**
   - Evidence: phase C rows 1 and 2, wire bytes, +4 s CPU.
   - Explains the 6.9 s, the 4.6 cores and the 1.7 s TTFB of the A/B.
   - The base arm of the A/B was compressed too, so the A/B measured "V2 + deflate" against "legacy + deflate".
2. **Emission barrier: rows are emitted only after the whole lazy result has been submitted.**
   - `buildSerializedMorsels` runs the submit loop to completion before its consume loop.
   - The first row bytes leave at +1.5 to 2.0 s, when submission ends.
   - All completed morsel results stay buffered until then (backlog of 300–700 morsels, unbounded memory).
   - Without compression this costs little throughput, because the helpers are saturated anyway.
   - With compression the serial compressor sits idle for those 1.5–2.0 s.
3. **Serialization CPU.**
   - 2.0–2.4 µs per row, about 28 s of CPU per query, is the real parallel work.
   - It grows by 8–21% at 8 threads (SMT, frequency).
   - The on-CPU profile (`B/j8/warm-cyc`) did not resolve user symbols, so this run has no function-level split.
4. **Lazy join.** About 1.5–1.9 s on 2–2.6 cores of separate join and scan threads. It overlaps with serialization and is not limiting: the queue never drains during submit.
5. **Scheduler rules** (admission, revocation, morsel size): not limiting in this single-client run.

## Fix proposals (expected gain)

1. **Measurement fix: run benchmarks without compression.**
   - Send `Accept-Encoding: identity` from the harness, either as the default in `stream_query` or as `--header 'Accept-Encoding: identity'` in the drivers.
   - Expected: the V2 A/B goes from 6.9 s to about 2.8 s at 8 threads (phase C curl). The base arm needs a re-measurement as well.
2. **Stream while submitting.**
   - Consume completed slots between submissions (or use a bounded in-flight window) instead of after the submit loop.
   - Expected:
     - time to first row goes from about 1.5–2.0 s to about the first morsel (≈20 ms after the first block);
     - memory is bounded;
     - with compression, about −1.5 s (6.9 → ≈5.4 s), because the compressor starts 1.5–2 s earlier;
     - without compression, a small gain (≤0.3 s from overlapping finalize and hand-off).
3. **Parallel compression.**
   - Compress each morsel on its helper thread: independent deflate blocks with a full flush plus `adler32_combine` (pigz scheme), or one gzip member per morsel.
   - Expected: compressed exports take ≈3.3 s instead of 6.9 s, because the ≈4 s of compression CPU spreads over 8 helpers.
4. **Fewer copies per row.**
   - Today each cell is built as a `std::string` inside `vector<optional<pair<string,…>>>`, copied into `out`, copied again by `appendCopy`, and again by `finalizeToString`.
   - Expected: up to about 10–15% of the 28 s of CPU. Needs a symbolised profile first.
5. **Scheduler:** nothing to fix for single-client throughput.
