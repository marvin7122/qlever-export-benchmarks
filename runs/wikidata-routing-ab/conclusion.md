# Conclusion for run wikidata-routing-ab (queue seq 4127)

## Scope

This run compares current master against the compressed-routing branch on
the upgraded new-format Wikidata truthy index. The baseline binary is
master at `2f24c39c9` and links liburing. The variant binary is
`feat/iouring-compressed-routing` at `54134bb35` (PR #172, routing
without the SQPoll stack). Both arms serve
`index-for-upgrade-new-format`. Each arm runs one warm plus two cold
repetitions of the sequential (`large-de`) and scattered
(`scatter200k-de`) German-label CONSTRUCT exports. The Page Cache is
cleared before each cold repetition.

## Validity checks

All 12 measured requests completed with HTTP status 200. Response bodies
are byte-identical between arms per workload and repetition
(SHA-256 `dcd2b1bc...` for sequential, `497dacfd...` for scattered), so
the comparison measures speed, not output. The run directory carries the
driver COMPLETE marker and the queue recorded exit 0.

## Cold wall time (means of two repetitions)

| Workload | Master | Routing | Ratio |
| --- | ---: | ---: | ---: |
| Sequential | 60.70 s | 25.49 s | 2.38x |
| Scattered | 27.56 s | 11.19 s | 2.46x |

Storage reread drops from 9.62 GB to 9.44 GB (sequential) and from
3.10 GB to 2.99 GB (scattered). Machine I/O wait collapses from 3.6 to
0.1 percent of machine CPU time (sequential) and from 4.1 to about 1.6 percent of machine CPU time (scattered).
Server CPU rises from 40.6 to about 102 percent of one core
(sequential) and from 28.0 to about 66 percent of one core (scattered).

## Interpretation

Routing the compressed tier through the ring converts I/O wait into
CPU work. Sorted miss lists arrive as one sequential run, so reread
volume falls slightly, while per-block decompression raises server CPU.
The net effect is a factor 2.4 speedup on both exports with identical
output. This is the first measurement in which the ring serves the
evaluated index type.

## Warm wall time (single repetition)

| Workload | Master | Routing | Ratio |
| --- | ---: | ---: | ---: |
| Sequential | 15.17 s | 17.64 s | 0.86x |
| Scattered | 5.01 s | 5.10 s | 0.98x |

With the page cache hot, I/O wait is 0.0 percent of machine CPU time
in both arms, so no stall remains to remove. Server CPU rises from
15.8 to 18.3 CPU seconds on the sequential export: decompression
costs CPU while saving no I/O. This matches the mechanism: the
routing wins if and only if the export waits on storage. Each submit
carries up to 256 concurrent reads, but the code enters the reaping
wait immediately with no useful work between submission and
completion. The implementation is therefore device-level asynchronous
and thread-level synchronous. The natural next step is thread-level
asynchrony: schedule other batches while completions are in flight.
