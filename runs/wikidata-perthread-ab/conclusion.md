# Conclusion for run wikidata-perthread-ab (queue seq 4128)

## Scope

This run compares current master against the per-thread-rings branch on
the upgraded new-format Wikidata truthy index. The baseline binary is
master at `2f24c39c9`. The variant binary is
`feat/iouring-per-thread-rings` at `0051c6d83`. Both arms serve
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

| Workload | Master | Per-thread | Ratio |
| --- | ---: | ---: | ---: |
| Sequential | 60.41 s | 60.48 s | 1.00x |
| Scattered | 27.63 s | 27.63 s | 1.00x |

Machine I/O wait is 3.6 percent of machine CPU time in both arms (sequential) and
4.1 percent of machine CPU time in both arms (scattered). Server CPU is 40.1 versus
40.4 percent of one core (sequential) and 28.1 versus 28.2 percent
(scattered).

## Interpretation

Per-thread rings change nothing measurable on these exports. The branch
does not route the compressed tier through the ring pool, so both arms
serve per-index sequential lookups exactly like master. The measurement
isolates the per-thread ownership change at zero overhead on this
workload.
