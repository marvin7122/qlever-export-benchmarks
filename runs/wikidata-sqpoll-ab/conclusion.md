# Conclusion for run wikidata-sqpoll-ab (queue seq 4131)

## Scope

This run compares current master against the sqpoll branch on the
upgraded new-format Wikidata truthy index. The baseline binary is
master at `2f24c39c9`. The variant binary is `feat/iouring-sqpoll`
at `901b3b9a1` with default parameters. Both arms serve
`index-for-upgrade-new-format`. The `iouring-sqpoll` parameter defaults
to off and the driver passes no override, so the poller never engages;
this run isolates the branch scaffolding, not active polling. An
SQPoll-enabled comparison is outstanding.
Each arm runs one warm plus two cold repetitions of the sequential
(`large-de`) and scattered (`scatter200k-de`) German-label CONSTRUCT
exports. The Page Cache is cleared before each cold repetition.

## Validity checks

All 12 measured requests completed with HTTP status 200. Response bodies
are byte-identical between arms per workload and repetition
(SHA-256 `dcd2b1bc...` for sequential, `497dacfd...` for scattered), so
the comparison measures speed, not output. The run directory carries the
driver COMPLETE marker and the queue recorded exit 0.

## Cold wall time (means of two repetitions)

| Workload | Master | SQPoll | Ratio |
| --- | ---: | ---: | ---: |
| Sequential | 60.30 s | 60.32 s | 1.00x |
| Scattered | 27.49 s | 27.56 s | 1.00x |

Machine I/O wait is 3.6 percent of machine CPU time in both arms (sequential) and
4.1 percent of machine CPU time in both arms (scattered). Server CPU is 40.2 percent of
one core in both arms (sequential) and 27.6 versus 28.0 percent
(scattered).

## Interpretation

The branch changes nothing measurable on these exports at default
settings. The ring path never engages for the compressed vocabulary
on this branch, so both arms serve per-index sequential lookups
exactly like master. The measurement isolates the branch scaffolding
at zero overhead on this workload. It does not evaluate active
polling, which requires the opt-in parameter plus the compressed
routing to reach the ring at all.
