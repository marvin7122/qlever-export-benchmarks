# Conclusion for run wikidata-kernel-ab-era2 (queue seq 4398)

## Scope

This run compares `qlever-server-bench_ch7-integration` at `84b943e4e`
with the initial-ring kernel branch tip at the same commit. Both arms
serve the upgraded Wikidata truthy index
`index-for-upgrade-new-format`. Each arm runs one warm and two cold
repetitions of `large-de` and `scatter200k-de`. The page cache is
cleared before each cold repetition. Queue seq 4398 exited 0. Mode
`uring-vs-uring` against the freshly rebuilt integration baseline.

## Validity checks

All measured requests in the means returned HTTP 200.
Sequential bodies share SHA-256
`dcd2b1bc77fce98409640e9a234aa92688de7ba54eeff9c0556752e814f8c5e1`.
Scattered bodies share SHA-256
`497dacfdffcc71ac2acc3f748140e9d6b27586f7d7b743ccdb98289101fb4ad9`.
The arms agree on every measured workload.
The run directory carries the COMPLETE marker.

## Result

Cold sequential means are 23.750 s for the baseline and 23.591 s for
the variant (-0.7%). Cold scattered means are 10.921 s and 10.837 s
(-0.8%). Warm means show the same neutral signature: 15.965 s vs
16.130 s sequential (+1.0%), 5.074 s vs 5.025 s scattered (-1.0%).
The initial-ring kernel state does not change export performance
beyond run-to-run noise on either workload.
