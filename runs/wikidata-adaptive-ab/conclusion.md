# Conclusion for run wikidata-adaptive-ab (queue seq 4130)

## Scope

This run compares current master against the adaptive-batching branch
on the upgraded new-format Wikidata truthy index. The baseline binary
is master at `2f24c39c9`. The variant binary is
`feat/iouring-adaptive-batching` at `80d0707a6`. Both arms serve
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

| Workload | Master | Adaptive | Ratio |
| --- | ---: | ---: | ---: |
| Sequential | 60.41 s | 60.33 s | 1.00x |
| Scattered | 27.64 s | 27.44 s | 1.01x |

Machine I/O wait is 3.6 percent of machine CPU time in both arms (sequential) and
4.1 percent of machine CPU time in both arms (scattered). Server CPU is 40.2 percent of
one core in both arms (sequential) and 27.9 versus 27.8 percent
(scattered).

## Interpretation

The adaptive-batching branch changes nothing measurable on these
exports. Its ratio controller only engages around ring submissions,
and the ring path never engages for the compressed vocabulary on this
branch, so both arms serve per-index sequential lookups exactly like
master. The measurement isolates the adaptive scaffolding at zero
overhead on this workload.
