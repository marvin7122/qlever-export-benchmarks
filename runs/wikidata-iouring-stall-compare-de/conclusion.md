# CPU load during disk I/O on German-label exports (conclusion)

Run `wikidata-iouring-stall-compare-de`, Ural seq 3945, 2026-09-19, exit 0.
Binary: `/local/data-ssd/stoetzem/wt/bench/iouring-pre-baseline/build/qlever-server`
(`v0.5.48-36-gfdbfd14f5`, no liburing linkage).
Index: old-format Wikidata truthy backup, build 2026-08-13 (see 7.5).
Queries: `H-vocab-label-large-de.rq` (sequential class scan, German labels)
against `H-vocab-random-label-de-200k.rq` (200,000 scattered subjects,
German labels). German is not in `languages-internal` (only `en`), so
`Vocabulary::shouldLiteralBeExternalized` places every de literal in the
external tier (`src/index/vocabulary/Vocabulary.cpp`).
Driver: `scripts/profile-stall-compare-de.sh` with `scripts/sample_cpu_stat.py`.

## Method

One warm plus two cold reps per workload (caches cleared before each
cold rep). Each rep records wall time, body bytes, storage bytes reread
(`/proc/PID/io`), and 2 Hz samples of machine CPU, server CPU time, and
server read rate. All 200 reps returned HTTP 200 with byte-stable bodies
per workload.

Seq 3944 ran the same driver first and failed: the scattered query had a
PREFIX typo, so its three scattered reps returned HTTP 400. Its three
sequential reps are valid and agree with seq 3945 to 0.4 s, but every
number below cites seq 3945. The `request.tsv` files hold rows from both
seqs; the HTTP code column tells them apart.

## Numbers

| Window | Wall (s) | Body | Storage reread | proc_cpu_pct | iowait | peak MB/s |
|---|---|---|---|---|---|---|
| large-de warm | 15.53 | 505 MB | 0 | 105.9 | 0.0 | 0 |
| large-de cold | 60.60 / 60.58 | same | 9615 MB | 40.6 / 40.7 | 3.6 | 306 |
| scatter200k warm | 4.84 | 19.3 MB | 0 | 87.9 | 0.0 | 0 |
| scatter200k cold | 27.15 / 27.16 | same | 3103 MB | 28.1 / 27.9 | 4.2 | 538 / 547 |

Machine `usr` matches the server's own contribution in every window, so
no other load polluted the run. Cold reps agree with each other.

## Interpretation

External words make the miss path dominate. On the sequential export
the cold-minus-warm wall gap is 45 s (a factor of 3.9) while mean busy
cores fall from 1.06 to 0.41. On the scattered export the gap is 22.3 s
(a factor of 5.6) with cores falling from 0.88 to 0.28. Both warm reps
exceed 3 s (15.5 s and 4.8 s), so warm sampling is stable too. This is
the workload pair Section 7.6 rebuilds on: every cold lookup is a
guaranteed external miss, and the stall is large enough to attribute.
