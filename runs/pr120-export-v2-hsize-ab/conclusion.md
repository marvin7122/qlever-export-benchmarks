# H-size SELECT CSV export A/B: Legacy vs ExportEngineV2 (PR 120)

Ural queue seq 1839, `hsize-ab.sh 56fd618bd 8`, branch
`feat/export-v2-unified-pipeline-wired` at `56fd618bd`.
Server binary `v0.6.0-701-g56fd618bd` (version gate passed).
Five passes, 3 reps each (n=15 per arm). Every rep HTTP 200 with identical
byte counts on all three arms; every slice multisets match.

| slice | bytes | lines | legacy median s | v2str median s | v2iov median s | speedup |
|---|---|---:|---:|---:|---:|---:|
| year=1970 | 56,692,914 | 490,651 | 2.384 | 0.540 | 0.543 | 4.4x |
| year=1990 | 737,614,618 | 6,356,476 | 28.955 | 5.847 | 5.811 | 5.0x |

Means (medians in table): 1970 legacy 2.500 (first rep of pass 1 cold at
4.439), v2str 0.539, v2iov 0.542; 1990 legacy 29.143 (first rep cold at
34.141), v2str 5.853, v2iov 5.821.
Min/max ranges are tight after the cold first reps on both slices.

Verdict: V2 is 4.4x (1970) and 5.0x (1990) faster than Legacy at
byte-identical output. V2-string vs V2-iovec differ by 0.6% on both slices,
inside run noise: the win comes from the parallel push pipeline, not the
send path. Raw log: Ural `.qlever-wq/logs/1839-bench.log`.
Caveat: the harness exited 2 in finalization with all 30 measurements green
and no error text; duplicate run (same script+commit) queued as
corroboration. Later branch commits are CI-only (benchmark link,
clang-format, nodiscard), benchmark-neutral.
