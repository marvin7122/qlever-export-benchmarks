# Conclusion for run wikidata-zstdcache-ab-era2 (queue seq 4400)

## Scope

This run compares `qlever-server-bench_ch7-integration` at `84b943e4e`
with the zstdcache branch tip at the same commit. Both arms serve the
upgraded Wikidata truthy index `index-for-upgrade-new-format`. Each
arm runs one warm and two cold repetitions of `large-de` and
`scatter200k-de`. The page cache is cleared before each cold
repetition. Queue seq 4400 exited 0. Mode `uring-vs-uring` against
the freshly rebuilt integration baseline.

## Validity checks

All measured requests in the means returned HTTP 200.
Sequential bodies share SHA-256
`dcd2b1bc77fce98409640e9a234aa92688de7ba54eeff9c0556752e814f8c5e1`.
Scattered bodies share SHA-256
`497dacfdffcc71ac2acc3f748140e9d6b27586f7d7b743ccdb98289101fb4ad9`.
The arms agree on every measured workload.
The run directory carries the COMPLETE marker.

## Result

Cold sequential means are 23.463 s for the baseline and 24.778 s for
the variant (+5.6%). Warm sequential means are 16.078 s vs 16.598 s
(+3.2%). Cold scattered means are 10.831 s and 10.898 s (+0.6%) and
warm scattered means are 5.133 s vs 5.053 s (-1.6%). The zstdcache
branch regresses the sequential workload while leaving the scattered
workload unchanged. The mechanism is open: per-lookup cache overhead
on the sequential path is the first suspect, and a profile of the
sequential arm is needed before any fix.
