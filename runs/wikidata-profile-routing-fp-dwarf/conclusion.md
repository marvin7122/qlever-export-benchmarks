# Conclusion for run wikidata-profile-routing-fp-dwarf (queue seq 4228)

## Scope

Flamegraph profile of one cold scattered German-label CONSTRUCT
export on the upgraded new-format Wikidata truthy index, recorded
with dwarf unwinding (`perf record -F 99 --call-graph
dwarf,8192`). The server binary is
`scratch/fp-profile-routing` at `4c2e9f2ed`, which is the
routing commit `54134bb35` plus a scratch-only
`-fno-omit-frame-pointer` flag. The question is whether a
frame-pointer-preserving build recovers the QLever worker-thread
user frames that the plain dwarf arms lose. Stacks collapsed to
`flame.svg` (381 stacks).

## Validity checks

The export completed with HTTP status 200 and body hash
`497dacfd...`, identical to the plain dwarf arms and to every
A/B arm, so the profiled work is the same. The binary version
string confirms the frame-pointer build
(`v0.6.0-118-g4c2e9f2ed`). The run directory carries the
COMPLETE marker and the queue recorded exit 0.

## Result

Wall time 11.37 s (plain dwarf routing arm: 11.42 s, a wash).
All 381 collapsed stacks resolve without a single `[unknown]`
frame, as in the plain dwarf arm. The verdict is negative: the
worker-thread user frames are still absent. The only resolved
QLever user frames in either run belong to the background
resource-monitor thread (`ad_utility::ResourceMonitor::runLoop`,
6 stacks here against 3 in the plain dwarf arm, noise level).
The export worker threads show kernel-only towers in both runs
(`do_syscall_64`, the ext4 read path, the io_uring issue path),
so the per-index lookup tower stays invisible however the
binary preserves frame pointers. No master-side frame-pointer
build is needed for this question. Its shrink stays evidenced
by the frame-pointer-unwind differential filed with the plain
dwarf arms.
