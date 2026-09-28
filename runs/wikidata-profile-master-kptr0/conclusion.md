# Conclusion for run wikidata-profile-master-kptr0 (queue seq 4158)

## Scope

Flamegraph profile of one cold scattered German-label CONSTRUCT
export on the upgraded new-format Wikidata truthy index, rerun with
kernel symbols resolved (`kptr_restrict=0` on Ural). The server
binary is master at `2f24c39c9`. `perf record -F 99 -g` sampled the
server process for the whole export, and the stacks collapsed to
`flame.svg` (period-weighted cycles).

## Validity checks

The export completed with HTTP status 200 and body hash
`497dacfd...`, identical to every A/B arm and to the era-1 profile,
so the profiled work is the same. The run directory carries the
COMPLETE marker.

## Result

Wall time 27.96 s (era-1: 27.94 s). Vocabulary frames hold 67
percent of sampled cycles by the same symbol-match method that gave
63 percent on era-1. The `[unknown]` share fell from 75.5 percent
to 21.5 percent, and scheduler and context-switch frames now
resolve by name. The 4-point vocabulary shift against era-1 is
within cold-run variation; the profile supersedes era-1 master as
the baseline for the differential flamegraph.
