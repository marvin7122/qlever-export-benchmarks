# Conclusion for run wikidata-ch7-nvme-ab (queue seq 4317)

## Scope

This run compares `qlever-server-ch7-integration` at `84b943e4e` with `bench/ch7-nvmept` at `1d4d41b98`.
Both arms serve the upgraded Wikidata truthy index `index-for-upgrade-new-format`.
Each arm runs one warm and two cold repetitions of `large-de` and `scatter200k-de`.
The page cache is cleared before each cold repetition.
Queue seq 4317 exited 0.

## Validity checks

All 12 measured requests returned HTTP 200.
Sequential bodies share SHA-256 `dcd2b1bc77fce98409640e9a234aa92688de7ba54eeff9c0556752e814f8c5e1`.
Scattered bodies share SHA-256 `497dacfdffcc71ac2acc3f748140e9d6b27586f7d7b743ccdb98289101fb4ad9`.
The arms agree on every measured workload.
The run directory carries the COMPLETE marker.

## Result

Cold sequential means are 24.182 s for the baseline and 24.264 s for NVMe passthrough.
Cold scattered means are 10.930 s and 11.029 s.
The ratios are 1.00x and 0.99x.
Regular vocabulary files stay on the plain read path, so this null result is the expected outcome.
