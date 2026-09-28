# Conclusion for run wikidata-copies-ab-era2 (queue seq 4396)

## Scope

This run compares `qlever-server-bench_ch7-integration` at `84b943e4e`
with the copies branch tip at the same commit. Both arms serve the
upgraded Wikidata truthy index `index-for-upgrade-new-format`. Each
arm runs one warm and two cold repetitions of `large-de` and
`scatter200k-de`. The page cache is cleared before each cold
repetition. Queue seq 4396 exited 0. Mode `uring-vs-uring` against
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

Cold sequential means are 23.677 s for the baseline and 23.732 s for
the variant (+0.2%). Cold scattered means are 10.988 s and 10.871 s
(-1.1%). Warm means show the same neutral signature: 16.184 s vs
16.254 s sequential (+0.4%), 4.983 s vs 5.037 s scattered (+1.1%).
The copies branch does not change export performance beyond
run-to-run noise on either workload.
