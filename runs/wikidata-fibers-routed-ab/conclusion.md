# Conclusion for run wikidata-fibers-routed-ab (queue seq 4142)

## Scope

This run compares current master against the fibers-plus-routing
branch on the upgraded new-format Wikidata truthy index. The baseline
binary is master at `2f24c39c9`. The variant binary is
`feat/iouring-fibers-routed` at `84b943e4e`, which merges the
compressed routing (PR #172) into the fibers stack so per-column
fibers overlap real ring waits. Both arms serve
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

| Workload | Master | Fibers+routing | Ratio |
| --- | ---: | ---: | ---: |
| Sequential | 60.60 s | 23.19 s | 2.61x |
| Scattered | 27.61 s | 10.90 s | 2.53x |

Machine I/O wait is 0.1 percent of machine CPU time (sequential) and
1.7 percent (scattered) on the variant arm. Server CPU is about 101
percent of one core (sequential) and about 64 percent (scattered).

## Interpretation

Engaged fibers add a further gain on top of routing alone. The
routing-only branch measured 25.49 s sequential and 11.19 s scattered;
fibers cut that to 23.19 s (1.10x) and 10.90 s (1.03x). Overlapping
per-column fibers with ring waits converts residual stall into
progress, exactly the paper's mechanism at smaller scale. Against
master the combination reaches 2.61x sequential and 2.53x scattered
with identical output.
