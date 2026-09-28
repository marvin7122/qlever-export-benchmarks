# Conclusion for run wikidata-wired-ring-ab2 (queue seq 4122)

## Scope

This run compares the pre-io_uring baseline against a wired master on the
same old-format Wikidata truthy index. The baseline binary is
`7bd97790e` plus two compatibility commits and links no liburing. The
variant binary is master at `d717bd615` (2026-08-31), which contains the
PR #3057 export-path wiring and predates the PR #3159 index format
change, so both arms serve
`index-in-old-format.2026-08-13T19:10:06Z`. Each arm runs one warm plus
two cold repetitions of the sequential (`large-de`) and scattered
(`scatter200k-de`) German-label CONSTRUCT exports. The Page Cache is
cleared before each cold repetition.

## Validity checks

All 12 measured requests completed with HTTP status 200. Response bodies
are byte-identical between arms per workload and repetition
(SHA-256 `dcd2b1bc...` for sequential, `497dacfd...` for scattered), so
the comparison measures speed, not output. The run directory carries the
driver COMPLETE marker and the queue recorded exit 0.

## Cold wall time (means of two repetitions)

| Workload | Baseline | Wired master | Ratio |
| --- | ---: | ---: | ---: |
| Sequential | 61.00 s | 60.55 s | 1.01x |
| Scattered | 27.37 s | 27.62 s | 0.99x |

Storage reread matches to within one 8 KiB block (9.6 GB sequential,
3.1 GB scattered). Machine I/O wait is 3.6 percent of machine CPU time in both arms on the
sequential export and 4.2 versus 4.1 percent of machine CPU time on the scattered export.
Server CPU is 40.8 versus 40.3 percent of one core (sequential) and
28.3 versus 27.8 percent (scattered).

## Interpretation

The wiring changes nothing measurable on this index. Both ratios sit
within run-to-run noise, and I/O wait plus reread volume are identical.
This matches the routing analysis: on the on-disk-compressed vocabulary
both outer tiers delegate to `sequentialLookupBatch`, so the wired arm
serves these exports through per-index lookups exactly like the
baseline. The first measurement that can show a batching effect is the
compressed-routing branch, which connects the ring to this index type.
