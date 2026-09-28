# Conclusion for run wikidata-profile-master-dwarf (queue seq 4207)

## Scope

Flamegraph profile of one cold scattered German-label CONSTRUCT
export on the upgraded new-format Wikidata truthy index, recorded
with dwarf unwinding (`perf record -F 99 --call-graph
dwarf,8192`). The server binary is the master worktree build
`v0.6.0-116-g2f24c39c9`. Stacks collapsed to `flame.svg`.

## Validity checks

The export completed with HTTP status 200 and body hash
`497dacfd...`, identical to the routing dwarf arm and to every
A/B arm, so the profiled work is the same. The driver log
confirms the dwarf options. The run directory carries the
COMPLETE marker and the queue recorded exit 0.

## Result

Wall time 27.87 s. All 364 collapsed stacks resolve without a
single `[unknown]` frame. Kernel paths are complete from
`entry_SYSCALL_64_after_hwframe` through `do_syscall_64` to
`__x64_sys_pread64`, `vfs_read`, `ext4_file_read_iter`, and
`generic_file_read_iter`. QLever worker-thread user frames are
absent (see interpretation); only the resource-monitor thread
keeps user symbols.

## Interpretation

Dwarf unwinding resolves the kernel side completely on this
machine and binary, which frame-pointer profiles cannot do.
It loses the export worker's user frames: every worker sample
ends at `entry_SYSCALL_64_after_hwframe` with no user chain,
while the monitor thread in the same process unwinds fully.
The unwind tables are present (46k FDEs), so the cause sits in
perf or the kernel, not in missing tables. This profile serves
the kernel half of the differential figure; user-side
attribution stays on the frame-pointer method.
