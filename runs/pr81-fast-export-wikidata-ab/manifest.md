# PR 81 Wikidata E2E A/B — run manifest (config only, no build queued)

Status: configured, awaiting builds on Ural.
Dataset: wikidata-truthy.
Index on Ural: /local/data-ssd/stoetzem/wikidata/wikidata (from construct-workload-wikidata-v0.yaml, not re-verified this session).

## Arms

- Arm A (base): origin/stack/08-construct-batch-evaluator @ 1128daa47d6789df89f67d4db0e7e7d317ecc6fb — Ural build seq 3347 (was running at queue check)
- Arm B (head): origin/stack/09-fast-export-stream-formatter @ 3a40b6c8b8d52b803394b7987b7433bbf485fd55 — Ural build seq 3351 (queued detached)

## Queries (wikidata, CONSTRUCT Turtle only)

Primary: H-vocab-label-large.rq, H-size.rq, D3.rq.
Extension: H-vocab-description-large.rq, D1.rq, R2.rq.

Frozen SHA256 (this workstation, 2026-09-07):

- H-vocab-label-large.rq: 51908e8f247e570aa80c6e938f05621ba6efbaaecee0e1df5b870bc87674a706
- H-size.rq: 83780b9cda75707591d9a3bf731fb32bf677c2dbc753681443eb6d0ba21a7d92
- D3.rq: 64a8a18bdeef67871c27da2da4fe9a373b68571d9a46df3fe386eed69eba5ac8
- H-vocab-description-large.rq: 9ba3fa8633ee8b740b9d5b596eee9b66a6530224bcb0b5ff70ec4784930abfd2
- D1.rq: 0da334221db35ac062a281629051d61ef65adb4fbf058ff1cca5bf1702b2a2ef
- R2.rq: 4de7ae84bc337c57263ece6f72845e6b30cfebd3d6f1a5746d77fccba803e92e

Note: manifest construct-workload-wikidata-v0.yaml lists different SHA values.
The values above are the current working-tree files. The executed set must be
frozen at bench time. H-format.rq is excluded from the primary claim
(synthetic literals).

## Build outcomes (Ural, 2026-09-07)

- Seq 3347 (arm A, stack/08 @ 1128daa47): FAILED. `qlever-server` link never
  ran. `ConstructBatchEvaluator.cpp` does not compile: `ExportIds.h:298`
  applies `operator*` to `vocabStrings`, but `lookupBatch` returns
  `VocabBatchLookupResult`, which has no `operator*`.
  Verbatim error: `no match for 'operator*' (operand type is
  'VocabBatchLookupResult')`. Terminal state: `WQ_DONE seq=3347 type=build
  exit=4`.
- Seq 3351 (arm B, stack/09 @ 3a40b6c8b): FAILED with the identical error
  (`ExportIds.h:298`, no match for `operator*` on `VocabBatchLookupResult`).
  Terminal state: `WQ_DONE seq=3351 type=build exit=4`. This confirms the
  failure comes from PR 80 code, not from PR 81: PR 81 touches only
  `FastExportStreamFormatter.h`, the microbenchmark, and the benchmark CMake
  entry.

## Fix (2026-09-08)

- One-line fix in `src/index/ExportIds.h:298` (`resolveVocabIndexIds`):
  zip `vocabStrings` directly instead of `*vocabStrings`.
  `lookupBatch` returns `VocabBatchLookupResult` by value with a
  container/range interface and no `operator*`.
- Worktree: `~/code/qlever/stack-08-construct-batch-evaluator`.
- Commit `c2a743e06` on `stack/08-construct-batch-evaluator`, pushed to origin.
- Verification build seq 3417: BUILD OK @ c2a743e06, `WQ_DONE type=build
  exit=0`.

Benchmark status: bench QUEUED as Ural seq 3453 (2026-09-08).
Thesis branch `bench/pr81-wikidata-export-ab` @ 00f559b7 (pushed to GitHub
origin and packed into Ural bundle). Driver
`thesis/scripts/pr81-wikidata-export-ab.sh`, arms A `stack/08` @ c2a743e06
and B `stack/09` @ 659552193, pinned via branch marker with
`--wait-for` on both server binaries.

Recovery after seq 3453 failed in setup (`no qlever-server for stack/09
@ 65955219`): the stack was rebased mid-queue (`stack/08` now 83cbd9232,
`stack/09` now a7bf3092a, 31 files changed including `VocabularyTypes.h`
and other vocab-path sources). The rebuild at the new head overwrote the
pinned arm-B binary. The rebased heads are NOT substitute arms (they mix
unrelated vocab changes into the contrast). The arm A binary for c2a743e06
is still present. Arm B is re-materialized via temp branch
`bench/pr81-arm-b-65955219` at 6595521932 (pushed to origin; delete after
the benchmark). Build seq 3471, bench seq 3472 (run-id
`pr81-wikidata-export-ab-r2`, `--wait-for` on both binaries so the bench
holds until the build lands, `##BRANCH` marker).

Repeat after incidents (seq 3479, run-id `pr81-wikidata-export-ab-r3`):
same pinned commits (arm A `stack/08` @ c2a743e06, arm B temp branch
`bench/pr81-arm-b-65955219` @ 6595521932, both binaries verified present
so no rebuild), thesis bundle refreshed to tip b7e84cc, same driver and
queries. The r2 result stands unless r3 disagrees.

## Protocol

Five cold and five warm repetitions per query per arm, interleaved A/B.
Cold evicts serving files before each repetition. Warm leaves cache resident.
Accept header: text/turtle. Primary metric: client-observed elapsed time.
Correctness gate: byte-identical bodies per query across arms.

## Gap

No Wikidata SELECT twins exist, so CSV and TSV paths are untested in this run.
The existing pilot script scripts/export-v2-e2e-ab-pilot.sh is DBLP-hardcoded
(index, queries, REPS=3, one cold sample). It needs a Wikidata adaptation
before queueing the bench.
