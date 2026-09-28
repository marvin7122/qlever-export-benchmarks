# Conclusion for run wikidata-profile-routing-kptr0 (queue seq 4159)

## Scope

Flamegraph profile of one cold scattered German-label CONSTRUCT
export on the upgraded new-format Wikidata truthy index, rerun with
kernel symbols resolved (`kptr_restrict=0` on Ural). The server
binary is `feat/iouring-compressed-routing` at `54134bb35`.
`perf record -F 99 -g` sampled the server process for the whole
export, and the stacks collapsed to `flame.svg`
(period-weighted cycles).

## Validity checks

The export completed with HTTP status 200 and body hash
`497dacfd...`, identical to every A/B arm and to the era-1 profile,
so the profiled work is the same. The run directory carries the
COMPLETE marker.

## Result

Wall time 11.32 s (era-1: 11.20 s). Vocabulary frames hold 34
percent of sampled cycles by the same symbol-match method that gave
33 percent on era-1. The `io_uring_enter` to `ext4_file_read_iter`
kernel path now resolves by name, which is the frame range section
7.8 reasons about. The remaining 57 percent `[unknown]` sits on the
userspace side (the stripped liburing submit wrapper and LTO-folded
callers), not in the kernel. The profile supersedes era-1 routing
as the red side of the differential flamegraph.
