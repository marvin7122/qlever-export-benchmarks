# Conclusion for run wikidata-arena-ab-era2 (queue seq 4395)

## Scope

This run compares `qlever-server-bench_ch7-integration` at `84b943e4e`
with the PMR arena batch lookup tip `99836eef1` (PR 190 head, includes
the PrefixCompressor in-place decode API on top of the measured
`2cbb5e23f`). Both arms serve the upgraded Wikidata truthy index
`index-for-upgrade-new-format`. Each arm runs one warm and two cold
repetitions of `large-de` and `scatter200k-de`. The page cache is
cleared before each cold repetition. Queue seq 4395 exited 0. Mode
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

Cold sequential means are 23.912 s for the baseline and 24.154 s for
the variant (+1.0%). Cold scattered means are 10.887 s and 11.390 s
(+4.6%). Warm means show the same signature: 15.817 s vs 16.338 s
sequential (+3.3%), 5.066 s vs 5.463 s scattered (+7.8%). The newer tip
does not change the verdict of run 4332: no speedup, consistent slight
CPU-side overhead.
