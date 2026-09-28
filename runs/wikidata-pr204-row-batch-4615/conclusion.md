# Conclusion for run pr204-row-batch-1024-vs-4096 (queue seq 4615) — NULL

## Scope

Row-batch-size A/B on the same binary (4b74f3ef): base
`construct-export-row-batch-size=1024` vs variant `=4096`, Wikidata
H-vocab-label-large turtle export (1.30 GB body, 11643064 lines),
cold + warm, 5 reps each. Ural bench seq 4615 (fixed-driver rerun
of seq 4610), 2026-09-25, exit 0.

## Validity checks

All 20 reps complete, no zero-byte reps. Bodies byte-identical
across arms (checksums match, correctness `identical`). Cold reads
511 MB from disk on both arms; warm reads 0 bytes (page cache).

## Result

No measurable difference. Median elapsed:

| scenario | base (1024) | variant (4096) |
|---|---|---|
| cold | 23.01 s | 23.28 s (+1.2%) |
| warm | 23.80 s | 23.05 s (-3.1%) |

Warm base reps spread 22.5 to 25.4 s across reps, so both deltas
sit inside run-to-run noise. Batch sizes 1024 and 4096 are
indistinguishable on this query.

## Implication

A null on Wikidata for the 1024-vs-4096 step. It does not overturn
the DBLP row-batch record, which compares against a different
baseline. No prose change.
