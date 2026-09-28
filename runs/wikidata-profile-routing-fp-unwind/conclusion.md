# Conclusion for run wikidata-profile-routing-fp-unwind (queue seq 4232)

## Scope

Flamegraph profile of one cold scattered German-label CONSTRUCT
export on the upgraded new-format Wikidata truthy index, recorded
with frame-pointer unwinding (`perf record -F 99 --call-graph
fp`) instead of dwarf. The server binary is the scratch
frame-pointer build `scratch/fp-profile-routing` at `4c2e9f2ed`
(routing commit `54134bb35` plus `-fno-omit-frame-pointer`).
The question is whether the fp capture path recovers the worker
user frames that both dwarf arms lose. Stacks collapsed to
`flame.svg` (565 stacks).

## Validity checks

The export completed with HTTP status 200 and body hash
`497dacfd...`, identical to both dwarf arms and to every A/B
arm, so the profiled work is the same. The run directory
carries the COMPLETE marker and the queue recorded exit 0.

## Result

Wall time 11.45 s (dwarf arms: 11.37 s and 11.42 s, a wash).
The full worker user tower is recovered: the Asio scheduler
frames lead into `ExportQueryExecutionTrees::computeResult` and
`constructQueryResultToStream`, down through
`ConstructBatchEvaluator::evaluateBatch`, then the vocabulary
tower `PolymorphicVocabulary::lookupBatch` into
`CompressedVocabulary::lookupBatch` and `VocabularyOnDisk`,
ending at `BatchManager<IoUringPolicy>::addBatch`. Raw-sample
inspection explains the dwarf gap: for the I/O worker samples
the dwarf user-stack dump captured no user-space addresses at
all (the kernel tower ends at `entry_SYSCALL_64` with zero
following user lines, not even unresolved ones), so no build
flag could have recovered them. The fp capture path walks the
preserved frame chain in kernel at sample time and does not
need that dump. The plain dwarf arms stay valid for kernel-side
shares; this arm supplies the per-frame lookup tower for the
readable-flamegraph figures.
