# Conclusion for run wikidata-ch7-perthread-ab (queue seq 4323)

## Scope

This run compares `qlever-server-ch7-integration` at `84b943e4e` with the per-thread rings tip `d3bb0273c`.
Both arms serve the upgraded Wikidata truthy index `index-for-upgrade-new-format`.
Each arm runs one warm and two cold repetitions of `large-de` and `scatter200k-de`.
The page cache is cleared before each cold repetition.
Queue seq 4323 exited 0.
The variant commit does not contain compressed routing 54134bb35.
The baseline arm was started twice. The means use the second pass, which is the pass that the variant followed. Every request row, including the discarded first pass, has the same SHA-256. The driver still warns, because it compares the whole hash column and the first pass left an extra row.

## Validity checks

All measured requests in the means returned HTTP 200.
Sequential bodies share SHA-256 `dcd2b1bc77fce98409640e9a234aa92688de7ba54eeff9c0556752e814f8c5e1`.
Scattered bodies share SHA-256 `497dacfdffcc71ac2acc3f748140e9d6b27586f7d7b743ccdb98289101fb4ad9`.
The arms agree on every measured workload.
The run directory carries the COMPLETE marker.

## Result

Cold sequential means are 23.941 s for the baseline and 60.606 s for the variant.
Cold scattered means are 10.921 s and 27.560 s.
