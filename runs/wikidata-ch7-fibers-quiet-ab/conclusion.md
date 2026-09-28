# Conclusion for run wikidata-ch7-fibers-quiet-ab (queue seq 4343)

## Scope

This run compares `qlever-server-ch7-integration` at `84b943e4e` with the cooperative fibers tip `f047a827d`.
Both arms serve the upgraded Wikidata truthy index `index-for-upgrade-new-format`.
Each arm runs one warm and two cold repetitions of `large-de` and `scatter200k-de`.
The page cache is cleared before each cold repetition.
Queue seq 4343 exited 0.
The variant commit does not contain compressed routing 54134bb35.
Queue 4343 is the quiet rerun. The paired baseline in that job stays near 24 s, and COMPLETE is DONE with one hash row per repetition.

## Validity checks

All measured requests in the means returned HTTP 200.
Sequential bodies share SHA-256 `dcd2b1bc77fce98409640e9a234aa92688de7ba54eeff9c0556752e814f8c5e1`.
Scattered bodies share SHA-256 `497dacfdffcc71ac2acc3f748140e9d6b27586f7d7b743ccdb98289101fb4ad9`.
The arms agree on every measured workload.
The run directory carries the COMPLETE marker.

## Result

Cold sequential means are 23.676 s for the baseline and 60.494 s for the variant.
Cold scattered means are 10.831 s and 27.413 s.
