# Run 134: vocabulary batch export materialization mock (conclusion)

Ural bench seq 3786, 2026-09-17, ALL DONE. Binary:
`bench/vocab-batch-export-mock` at `15e7259aad` (mock builds the
synthetic vocabulary at startup, so the binary commit covers the arms).
Method: 200,000 synthetic words (alternating IRIs and English labels,
FSST-compressed with one codebook) in a
`CompressedVocabulary<VocabularyInMemoryBinSearch>`; 200,000 lookups from
a Zipf-skewed index multiset in batches of 4096; five reps per arm. All
three arms produce byte-identical output (checked up front inside the
binary; a mismatch aborts nonzero).

## Numbers

Seconds per rep (200k lookups each):

| Arm | Rep 1-5 (s) | Median (s) |
|---|---|---|
| sequential `operator[]` | 0.0541/0.0524/0.0528/0.0524/0.0525 | 0.0525 |
| `lookupBatch` | 0.0581/0.0582/0.0584/0.0583/0.0584 | 0.0583 |
| batch plus scratch reuse | 0.0606/0.0607/0.0608/0.0608/0.0608 | 0.0608 |

## Verdict

The batch API shape loses on the mock: `lookupBatch` is 11% slower than
the sequential loop, and scratch reuse adds another 4%. The cause is
structural. `sequentialLookupBatch` materializes one owning string per
word plus a view vector. It pays the same binary search and FSST
decompression as the sequential loop, with extra allocation and
indirection on top. Scratch reuse cannot recover that margin because the
escape function still takes and returns owning strings.

The consequence for Stage A: wiring `idsToStringAndType` into the SELECT
export loop changes the call shape but not the cost centers. A measurable
win needs fewer passes over the data (escape straight into the stream
chunk) rather than a different lookup API. The production A/B (run 133)
is decisive; this mock predicts it shows no win.

## Limits

The vocabulary is synthetic (200k words, one codebook, contiguous
indices, all `VocabIndex`), so only relative overhead transfers. The
mock multiset models repeated labels but not the production datatype
partition (a no-op here by construction).

## Artifacts

`driver.log`, `mock-output.txt`, `mock-results.json`. Binary built by
Ural seq 3773 (exit 0, first try).
