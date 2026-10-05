# #3525 (fork #76) rework: synthetic rows, 4 arms, >= 10 s per measurement

Ural micro lane job 90024 (2026-10-05), script `run.sh`, pinned core, 10
interleaved trials per arm (arm order rotates per trial), 1 untimed warm-up,
ns per word, median [min-max]. Vocabulary files in the page cache.

| arm | fork commit | what |
|---|---|---|
| base | `f08433901` | part 5 (#75, `stack/06a` @ `6a2133d14`) + the two benchmark sources (benchmark-only) |
| orig | `c6d9de02a` | part 6 before the fix (old `stack/07a` merged with the current part 5) |
| reap | `ed96428a9` | + reap all ready completions when the ring is full |
| reapslots | `e508af5dc` | + in-flight reads in a slot array instead of a hash map (= PR head minus a test-only commit) |

Summary: `aggregate.md`. Diagnostics (not timing): `../p6-rework-diag`
(strace syscall counts), `../p6-rework-perf` (perf record, callers of
io_uring_enter vs pread64), `../p6-rework-test` (IoUringManagerTest, u24
build with io_uring).
