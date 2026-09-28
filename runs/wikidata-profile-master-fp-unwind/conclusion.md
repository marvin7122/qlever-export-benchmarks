# Conclusion for run wikidata-profile-master-fp-unwind (queue seq 4248)

## Scope

Flamegraph profile of one scattered German-label CONSTRUCT export
(`I-iouring-label-de.rq`, turtle_export) on the upgraded new-format
Wikidata truthy index, recorded with frame-pointer unwinding
(`perf record -F 99 --call-graph fp`). The server binary is the
scratch frame-pointer build `scratch/fp-profile-master` at
`e6f950830` (origin/master `eeb6cf9e8` plus `-fno-omit-frame-pointer`,
queue build 4241). The driver is `scripts/wikidata-profile-fp-unwind.sh`
at `c1ab4a3`, executed from a worktree staging copy (identical sha256).
The question is whether the fp capture path recovers the master-arm
worker user frames for the Figure 7.14 tower. Stacks collapsed to
`flame.svg` (821 stacks).

## Validity checks

The export completed with HTTP status 200 and a 505 MB body, hash
`dcd2b1bc...`. That hash differs from the `497dacfd...` shared by the
master dwarf, routing dwarf, fp-dwarf, and routing fp-unwind arms, and
the wall time is 53.17 s against the master dwarf arm's 27.87 s, so the
master binary at `eeb6cf9e8` behaves differently from the `2f24c39c9`
master the dwarf arm profiled. Query and index are identical; the drift
comes from the 17 master commits between the two binaries. The run
directory carries the COMPLETE marker and the queue recorded exit 0.
Only 11 collapsed stacks carry `[unknown]` frames, all in thread-spawn
trampolines (`ret_from_fork`, `pthread_create`) at 0.002 percent of the
total, so symbolization is effectively complete.
Cache caveat: the executing checkout predates the truthy serving
manifest, so advisory eviction named stale DBLP paths and the truthy
files' page-cache state is uncontrolled. The 53 s wall shows no
warm-cache shortcut, and the figure normalizes each arm to 100 percent.

## Result

The full worker user tower is recovered on the master arm: 660 of 821
stacks pass export or vocabulary frames, from the Asio scheduler down
through `ExportQueryExecutionTrees` into `PolymorphicVocabulary` and
`VocabularyOnDisk`, ending at the pread path. The kernel towers are
present in the same capture (`entry_SYSCALL_64`, `do_syscall_64`,
ext4 read path), so one capture supplies both the user tower and the
kernel context for the Figure 7.14 tower pair.
