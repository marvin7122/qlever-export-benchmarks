# Conclusion for run wikidata-profile-routing-dwarf (queue seq 4208)

## Scope

Flamegraph profile of one cold scattered German-label CONSTRUCT
export on the upgraded new-format Wikidata truthy index, recorded
with dwarf unwinding (`perf record -F 99 --call-graph
dwarf,8192`). The server binary is
`feat/iouring-compressed-routing` at `54134bb35`, the same build
as the frame-pointer profile. Stacks collapsed to `flame.svg`;
the differential against the master dwarf arm is `flame-diff.svg`
(`stacks.diff.folded`, 668 stacks).

## Validity checks

The export completed with HTTP status 200 and body hash
`497dacfd...`, identical to the master dwarf arm and to every
A/B arm, so the profiled work is the same. The driver log
confirms the dwarf options. The run directory carries the
COMPLETE marker and the queue recorded exit 0.

## Result

Wall time 11.42 s (frame-pointer run: 11.32 s). All 385
collapsed stacks resolve without a single `[unknown]` frame.
The differential shows the syscall tower shrinking in blue:
`do_syscall_64` holds 55.58 percent total at minus 0.63. The
ext4 read path grows in red: `ext4_mpage_readpages` at plus
0.99 and `vfs_read` at 20.52 percent total, plus 0.82. QLever
worker-thread user frames are absent, as in the master dwarf
arm, so the per-index lookup tower is not visible in this
figure. Its shrink stays evidenced by the frame-pointer
differential.
