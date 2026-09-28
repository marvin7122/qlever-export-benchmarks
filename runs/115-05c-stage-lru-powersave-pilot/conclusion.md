# Conclusion for run 115

## Scope

Run 115 is a targeted evaluation of CONSTRUCT result deduplication. It is not
a general QLever benchmark. The comparison changes only the
`construct-deduplication` mode among `none`, `lru:30`, `lru:50`, and `full`.
The instrumented binary, DBLP index, queries, server settings, and measurement
protocol remain fixed. Each of the 24 query, mode, and cache conditions has
five measured repetitions.

## Validity checks

All 120 repetitions completed with HTTP status 200. Each repetition contains
the required stage summary and memory marker. Checksums, response sizes,
candidate result triple counts, and emitted result triple counts are stable
within each condition. No measured repetition contains a major page fault or
swap operation.

A separate verifier requested N Triples and compared each response as a set of
RDF triples. For each query, every mode produced the same RDF graph. The
different emitted result triple counts therefore reflect repeated result
triples, not different graph content.

## Correctness result

`H-size` contains no duplicate result triples. Every mode emits all 490,650
candidate result triples.

`H-dedup` contains 390,854 candidate result triples and 143,415 distinct
result triples. The `none` mode emits 390,854 result triples. The `lru:30`
mode emits 348,230 result triples. The `lru:50` mode emits 148,108 result
triples. The `full` mode emits the 143,415 distinct result triples.

`H-dedup-values` contains 573,752 candidate result triples and 143,438
distinct result triples. Both bounded modes and the `full` mode emit exactly
143,438 result triples. The repeated result triples are consecutive, so both
evaluated LRU capacities retain the required keys until the repetitions occur.

These results confirm the evaluated mode contracts. The `none` mode performs
no duplicate suppression. The `full` mode suppresses every repeated result
triple covered by the mechanism. A bounded LRU mode suppresses a repeated
result triple only while its full triple key remains in the configured cache.

## Runtime result

On `H-size`, deduplication cannot avoid output work. Relative to `none`, the
warm cache median end to end runtime increases by 5.77 percent for `lru:30`,
9.77 percent for `lru:50`, and 30.58 percent for `full`. The corresponding
cold cache increases are 1.13 percent, 1.55 percent, and 5.38 percent.

On `H-dedup`, `lru:50` suppresses 62.11 percent of the candidate result
triples and reduces the warm cache median end to end runtime by 7.59 percent.
The `full` mode suppresses 63.31 percent and reduces that median by only 0.95
percent. Its additional duplicate tracking work offsets most of the reduced
formatting and transfer work.

On `H-dedup-values`, every deduplicating mode suppresses 75 percent of the
candidate result triples. The warm cache median end to end runtime falls by
17.10 percent for `lru:30`, 14.46 percent for `lru:50`, and 8.60 percent for
`full`. The corresponding cold cache reductions are 3.35 percent, 0.88
percent, and 1.26 percent.

The internal timers explain why fewer emitted result triples do not imply a
proportional end to end reduction. On warm `H-dedup-values`, `full` reduces
the median formatting, stream processing, and HTTP delivery residual from
111.490 milliseconds to 53.586 milliseconds. At the same time, median
instantiation and deduplication time increases from 27.858 milliseconds to
57.853 milliseconds. Root operation execution and batch evaluation also
remain part of the request.

## Memory result

Without deduplication, the median QLever process peak ranges from 139.8 MiB to
163.2 MiB across the evaluated workloads and cache scenarios. Full
deduplication adds between 4.8 MiB and 27.0 MiB. This equals between 3.4
percent and 16.6 percent of the corresponding process peak without
deduplication.

The largest relative overhead occurs on `H-size`, where `full` must retain one
key for each of 490,650 distinct candidate result triples. The process memory
measurement does not resolve the much smaller incremental footprint of the
LRU structures at capacities 30 and 50.

## Interpretation and limits

The feature works according to its specified contracts in the evaluated
workloads. Its memory cost is acceptable for these workloads. The appropriate
tradeoff remains an operational choice because more complete duplicate
suppression requires more retained state. A future per query override could
allow the query submitter to request this tradeoff within limits chosen by the
operator.

This conclusion applies only to the three fixed DBLP queries, two cache
scenarios, and the instrumented run 115 binary. The server used the host's
existing powersave policy. The result does not establish general QLever
performance, allocator level structure sizes, or LRU memory costs below the
resolution of the process resident set size measurement.

## Artefacts

The complete run remains on Ural at
`/local/data-ssd/stoetzem/thesis/experiments/runs/115-05c-stage-lru-powersave-pilot`.
The measured source is the official QLever commit
`65f84b43d86b6ceb887d7a15dd5d387b2fc18a7a` plus the archived instrumentation
patch. The corresponding source artefacts are in
`experiments/artifacts/05c-construct-dedup-run-115/`.
