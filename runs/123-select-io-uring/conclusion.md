# Conclusion for run 123 (SELECT io_uring transfer, #45) — BLOCKED, no benchmark executed

## TL;DR

The experiment as specified **cannot produce meaningful measurements on Ural**, for
two independent, verified reasons. **No benchmark reps were run**, because the result
would be a guaranteed null that is an *artifact* (not evidence about io_uring):

1. **io_uring is not compiled into any Ural binary.** `liburing` is not installed,
   so CMake reports *"USE_IO_URING is ON but liburing was not found, building without
   io_uring support"* and `QLEVER_HAS_IO_URING` is never defined. Every `IoUringPolicy`
   variant (registered buffers / SQPOLL / DEFER_TASKRUN) is inside `#ifdef
   QLEVER_HAS_IO_URING` and is compiled **out**; every binary falls back to
   `SyncIoPolicy` (blocking `pread`).
2. **The SELECT CSV/TSV export path does not use the io_uring batch machinery at all.**
   `ExportQueryExecutionTrees.cpp` resolves each Id-table cell with a per-cell
   `idToStringAndType` call (one `pread` per vocabulary-backed Id). io_uring is only
   reachable through `VocabularyOnDisk::lookupBatch` → the *batched*
   `idsToStringAndType` variant, which the SELECT export does **not** call.

## Binary inventory (as delivered — mislabeled)

| File in `/local/data-ssd/stoetzem/binaries/` | `--version` | MD5 | io_uring symbols | sync-pread symbols |
| --- | --- | --- | ---: | ---: |
| qlever-server-baseline | CIKM-2494-**gb39e320a** | 9fe14c8b… | 0 | 14 |
| qlever-server-sqpoll | CIKM-2494-**gb39e320a** | **9fe14c8b…** | 0 | 14 |
| qlever-server-defer-tr | CIKM-2494-**gb39e320a** | **9fe14c8b…** | 0 | 14 |
| qlever-server-registered-buffers | CIKM-2494-**gb39e320a** | 5e5af984… | 0 | 14 |
| qlever-server-master (extra) | CIKM-2493-**g65f84b43** | 2e295ef1… | 0 | 14 |

Findings:

- `baseline`, `sqpoll`, `defer-tr` are **byte-identical** (same MD5). Running
  `sqpoll`/`defer-tr` against `baseline` would reproduce identical timings by
  construction — a fake "no difference".
- **None of the four reports master.** All four report commit `b39e320a` ("io_uring:
  register pre-allocated buffer pool"), i.e. the *registered-buffers* commit, not
  `65f84b43` (upstream/master, the fork point of the io_uring branches).
- `qlever-server-master` correctly reports `65f84b43` but is *also* sync-pread
  (io_uring compiled out).

### Branch ground truth (in `/local/data-ssd/stoetzem/qlever-src`)

| Branch | HEAD | parent | change vs `65f84b43` |
| --- | --- | --- | --- |
| master (local) | b53c7646 | — | — |
| upstream/master (fork point) | 65f84b43 | — | baseline |
| marvin-io-uring-registered-buffers | b39e320a | 65f84b43 | IoUringManager.cpp/h (+155) |
| marvin-io-uring-defer-tr | 4e2bc82b | 65f84b43 | IoUringManager.cpp (DEFER_TASKRUN\|SINGLE_ISSUER) |
| marvin-io-uring-sqpoll | 487e2936 | 65f84b43 | IoUringManager.cpp (SQPOLL\|SINGLE_ISSUER) |

The four variants are independent (each forks directly off `65f84b43`), so the
correct binaries to benchmark are builds of `65f84b43`, `b39e320a`, `4e2bc82b`,
`487e2936` — none of which currently exists under its name.

## Evidence (verbatim checks)

- `pkg-config --exists liburing` → **not found**; `find / -name liburing.h` → nothing;
  `ldconfig -p | grep uring` → nothing.
- `cmake -L .` (Ural, build dir): `-- USE_IO_URING is ON but liburing was not found,
  building without io_uring support`.
- `nm` on **all seven** binaries under `/binaries/`:
  `io_uring_queue_init|io_uring_setup|IoUringPolicy|io_uring_prep_read|io_uring_register_buffers` → **0**
  hits each; `SyncIoPolicy|readFullyOrThrow` → **14** hits each, plus `pread@GLIBC_2.2.5`.
- `CMakeLists.txt:364-377` gates io_uring on `pkg_check_modules(URING QUIET liburing)`
  → `add_compile_definitions(QLEVER_HAS_IO_URING)` only when found.

## Code-path analysis (why even a compiled-in io_uring would not reach SELECT)

- `src/engine/ExportQueryExecutionTrees.cpp:334,527,554,704` — SELECT CSV/TSV export
  resolves every cell via `ql::exportIds::idToStringAndType` (per-cell, unbatched).
- `src/util/IoUringManager.{h,cpp}` (`IoUringPolicy`, registered buffers / SQPOLL /
  DEFER_TASKRUN) is only instantiated by `ad_utility::makeBatchManager`, which is only
  called from `VocabularyOnDisk.cpp:296` inside the `lookupBatch` pool init.
- `lookupBatch` is reached only by the *batched* `idsToStringAndType`
  (`src/index/ExportIds.h:264`), which the SELECT export does not call.

So even after installing liburing and rebuilding, the three io_uring variants would
modify a code path the SELECT export never exercises. The optimizations cannot
"transfer" to SELECT unless the SELECT export is first switched from per-cell
`idToStringAndType` to the batched `idsToStringAndType`/`lookupBatch` path.

## Answer to the experiment question

**No io_uring optimization can be measured (let alone shown to help) on the SELECT
export path on Ural as-is.** This is a *negative infrastructure result*, not a "no
measurable improvement" result: with liburing absent, all four binaries are
synchronous-`pread` builds, and the SELECT export does not traverse the io_uring batch
path regardless.

## What is needed to actually run #45 (flag for Marvin)

1. **Install `liburing` on Ural** (e.g. `apt install liburing-dev`, or build from
   source into `/local/data-ssd/stoetzem/liburing` and set `PKG_CONFIG_PATH`), then
   rebuild `qlever-server` from each of `65f84b43`, `b39e320a`, `4e2bc82b`, `487e2936`
   and verify `nm` shows `io_uring_*` symbols before benchmarking.
2. **Decide the intended code path for #45.** If #45 is "does the *vocab-batch*
   io_uring optimization transfer to SELECT", the SELECT export must first call the
   batched `idsToStringAndType`/`lookupBatch` path (a code change), otherwise the
   benchmark is structurally a no-op even with io_uring compiled in.
3. **Rebuild/re-label the `/binaries/` files** — currently `baseline`/`sqpoll`/
   `defer-tr` are the same binary and none is master (same mislabeling flagged for
   run 119-dedup-ab).

## Artefacts

- Local: `experiments/runs/123-select-io-uring/conclusion.md`
- Ural mirror: `/local/data-ssd/stoetzem/thesis/experiments/runs/123-select-io-uring/`
- No benchmark CSVs were produced (run aborted at pre-flight verification).
