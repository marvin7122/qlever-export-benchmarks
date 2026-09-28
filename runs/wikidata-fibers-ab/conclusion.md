# Conclusion for run wikidata-fibers-ab (queue seq 4129)

## Scope

This run compares current master against the fibers-cooperative branch
on the upgraded new-format Wikidata truthy index. The baseline binary
is master at `2f24c39c9`. The variant binary is
`feat/iouring-fibers-cooperative` at `d57225921`. Both arms serve
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

| Workload | Master | Fibers | Ratio |
| --- | ---: | ---: | ---: |
| Sequential | 60.48 s | 60.30 s | 1.00x |
| Scattered | 27.58 s | 27.58 s | 1.00x |

Machine I/O wait is 3.6 percent of machine CPU time in both arms (sequential) and
4.1 percent of machine CPU time in both arms (scattered). Server CPU is 40.3 versus
40.2 percent of one core (sequential) and 28.0 versus 28.2 percent
(scattered).

## Interpretation

The fibers branch changes nothing measurable on these exports. Its
cooperative scheduling only engages around ring waits, and the ring
path never engages for the compressed vocabulary on this branch, so
both arms serve per-index sequential lookups exactly like master. The
measurement isolates the fibers scaffolding at zero overhead on this
workload.
