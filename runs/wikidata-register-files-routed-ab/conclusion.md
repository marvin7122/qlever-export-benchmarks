# Conclusion for run wikidata-register-files-routed-ab (queue seq 4164)

## Scope

This run compares the compressed-routing branch against the
register-files-plus-routing branch on the upgraded new-format
Wikidata truthy index. The baseline binary is
`feat/iouring-compressed-routing` at `54134bb35`. The variant
binary is `feat/iouring-register-files-routed` at `0fa3c4a23`,
which merges the routing into the fixed-file registration so the
ring reads skip the kernel file-table lookup. Both arms serve
`index-for-upgrade-new-format`. Each arm runs one warm plus two
cold repetitions of the sequential (`large-de`) and scattered
(`scatter200k-de`) German-label CONSTRUCT exports. The Page Cache
is cleared before each cold repetition.

## Validity checks

All 12 measured requests completed with HTTP status 200. Response
bodies are byte-identical between arms per workload and repetition
(SHA-256 `dcd2b1bc...` for sequential, `497dacfd...` for
scattered), so the comparison measures speed, not output. Read
volume is unchanged (9.43 GB vs 9.44 GB sequential), as fixed files
save per-request lookup syscalls rather than bytes. The run
directory carries the driver COMPLETE marker and the queue recorded
exit 0.

## Cold wall time (means of two repetitions)

| Workload | Routing | Register-files+routing | Ratio |
| --- | ---: | ---: | ---: |
| Sequential | 25.36 s | 23.38 s | 1.08x |
| Scattered | 11.29 s | 10.82 s | 1.04x |

## Interpretation

Registering the two vocabulary files and submitting with fixed
descriptors cuts another 8 percent sequential and 4 percent
scattered off the routing arm, with identical output and
identical read volume. Against master (60.60 s sequential, 27.61 s
scattered) the combination reaches 2.59x and 2.55x. The gain is
smaller than routing itself because the file-table lookup is a
per-request constant while the batching removed the per-request
syscall.
