# Conclusion for run wikidata-ch7-format-ab (queue seq 4335)

## Scope

This run compares `qlever-server-ch7-integration` at `84b943e4e` with the format tip tip `b0a5ac708`.
Both arms serve the upgraded Wikidata truthy index `index-for-upgrade-new-format`.
Each arm runs one warm and two cold repetitions of `large-de` and `scatter200k-de`.
The page cache is cleared before each cold repetition.
Queue seq 4335 exited 0.
The variant commit contains compressed routing 54134bb35.
The tip is 84b943e4e plus a one-line export edit that the next commit reverts. The measured delta is that revert.

## Validity checks

All measured requests in the means returned HTTP 200.
Sequential bodies share SHA-256 `dcd2b1bc77fce98409640e9a234aa92688de7ba54eeff9c0556752e814f8c5e1`.
Scattered bodies share SHA-256 `497dacfdffcc71ac2acc3f748140e9d6b27586f7d7b743ccdb98289101fb4ad9`.
The arms agree on every measured workload.
The run directory carries the COMPLETE marker.

## Result

Cold sequential means are 23.174 s for the baseline and 23.461 s for the variant.
Cold scattered means are 10.765 s and 10.803 s.
