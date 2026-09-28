# Conclusion for run wikidata-nvme-routed-ab (queue seq 4260)

## Scope

First successful era-2 A/B: baseline `qlever-server-master`
(v0.6.0-132-geeb6cf9e8) against the NVMe-routed variant
(v0.6.0-119-gd585b6bb4) on the upgraded new-format Wikidata truthy
index (`index-for-upgrade-new-format`), thesis branch
`bench/routed-ab-era2` at `a0e7ca5`. Two workloads, each with one
warm and two cache-cleared cold reps: `large-de` (half-gigabyte
German-label Turtle export) and `scatter200k-de` (200k scattered
labels). Setup incidents on the three prior seqs (4256 missing CPU
sampler, 4258 stale thesis bundle, 4259 missing `-de` queries) were
fixed before this run and produced no data.

## Validity checks

Both arms return HTTP 200 on `large-de` with identical body size
(504927346 bytes) and identical sha256 `dcd2b1bc...` across all six
reps, so the comparison is byte-identical output. `COMPLETE` is
clean and the waiter reports exit 0. The `scatter200k-de` query
returns HTTP 400 on both arms in about 1.06 s, so it carries no
performance signal; the query itself is broken independently of the
export path.

## Results

Cold `large-de` wall time: baseline 61.24 s and 61.10 s against
variant 25.58 s and 26.04 s, a speedup of 2.37x. Server-side
`/proc` I/O reads drop from 9.62 GB to about 9.43 GB while process
CPU stays flat (25.0 s against 26.3 s): the win comes from system
iowait, which falls from about 908 s to about 382 s of aggregate
CPU time. The single-threaded CPU cost is unchanged, which bounds
what routing alone can do and leaves the user-space candidates
(arena decode, ICU comparator, gallop search, formatting) as the
remaining gap.

Warm `large-de` (single rep each, page cache hot, zero bytes read):
baseline 15.34 s against variant 18.22 s. The variant shows no warm
win and may carry ring-path CPU overhead when I/O is cached; this
needs replication before it becomes a claim.

## Implication

The cold 2.37x belongs in the chapter as the routed-arm data
point. The warm inversion stays out of the prose until replicated.
