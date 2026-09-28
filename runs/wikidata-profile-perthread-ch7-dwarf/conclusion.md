# Conclusion for run wikidata-profile-perthread-ch7-dwarf (queue seq 4324)

## Scope

One cold `large-de` German-label CONSTRUCT export on `index-for-upgrade-new-format`.
The binary is the per-thread rings tip `d3bb0273c`.
`perf record -F 99 --call-graph dwarf` sampled the server for that export.
Host kernel is `7.0.0-28-generic`.
Queue seq 4324 exited 0.

## Validity checks

The export returned HTTP 200.
The body hash is `dcd2b1bc77fce98409640e9a234aa92688de7ba54eeff9c0556752e814f8c5e1`, the same hash as the A/B.
`flame.svg` and `stacks.collapsed` are in this directory.
The collapsed file has 635 stacks.

## Result

Wall time is 60.958 s.
