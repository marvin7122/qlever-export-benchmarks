# #3525 research loop: where the synthetic `lookupBatch` slowdown comes from

Ural queue seq 5169 (2026-09-28), binary `VocabularyBatchLookupAttributionBenchmark`
from fork branch `loop/part6-07a-attribution` @ `77360f420` (= `upstream-stack/07a`
+ this research-only benchmark, source in this directory). Pinned to core 5,
11 interleaved trials per case after an untimed warm-up, each trial >= 1 s,
median and min–max of ns per word. Vocabulary files are in the page cache.

Cases (same data, same process):

| case | what it runs |
|---|---|
| `od-single` | `VocabularyOnDisk::operator[]` per word (two `pread`s, one `std::string`) |
| `od-batch` | `VocabularyOnDisk::lookupBatch` (vocabulary's own io_uring `BatchIoManager`) |
| `od-manual-sync` | the same two-phase read as `lookupBatch`, `BatchManager<SyncIoPolicy>` (one `pread` per request) |
| `od-manual-uring` | the same two-phase read, fresh `BatchManager<IoUringPolicy>` |
| `ie-probe-only` | only the internal/external membership probes of `VocabularyInternalExternal::lookupBatch` |
| `ie-single` / `ie-batch` | `VocabularyInternalExternal` per word / batched |

Result (ns per word, median; full table in `attr-summary.tsv`):

| words | batch | od-single | od-manual-sync | od-manual-uring | od-batch | ie-probe-only | ie-single | ie-batch |
|---|---|---|---|---|---|---|---|---|
| 4096 | 128 | 1,042 | 1,012 | 1,332 | 1,345 | 18 | 518 | 638 |
| 4096 | 2048 | 1,042 | 1,009 | 1,845 | 1,853 | 55 | 590 | 952 |
| 200k | 128 | 1,050 | 1,022 | 1,330 | 1,349 | 24 | 554 | 678 |
| 200k | 2048 | 1,047 | 1,015 | 1,852 | 1,855 | 92 | 646 | 991 |
| 200k | 50000 | 1,073 | 1,073 | 1,993 | 1,997 | 94 | 675 | 1,097 |

Attribution:
- The batched algorithm itself is not slower: the two-phase read with the
  synchronous backend (`od-manual-sync`) is at parity with or 1–3 % below
  single-word `operator[]` (`od-single`).
- The whole gap is the backend: the same two-phase read with io_uring
  (`od-manual-uring`) matches `od-batch` within 1 %. On page-cache hits one
  io_uring read costs more than one `pread` (strace: 751 k `io_uring_enter`
  at 6 µs/call vs 874 k `pread64` at 3 µs/call, diagnostic run).
- The `VocabularyInternalExternal` bookkeeping (membership probes, position
  scatter) is 18–94 ns per word (`ie-probe-only`), 2–10 % of the batch cost.

Fix in the stack: the page-cache fast path (`preadv2(RWF_NOWAIT)` before the
ring, ad-freiburg/qlever#3547) serves page-cache hits without the ring; cold
device reads keep the ring (ad-freiburg/qlever#3526).
