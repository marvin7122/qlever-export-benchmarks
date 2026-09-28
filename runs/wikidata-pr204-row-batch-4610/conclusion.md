# Conclusion for run pr204-row-batch-1024-vs-4096 (queue seq 4610) — NO DATA

## Scope

Row-batch-size A/B on the same binary (4b74f3ef): base
`construct-export-row-batch-size=1024` vs variant `=4096`, Wikidata
H-vocab-label-large turtle export, cold + warm, 5 reps. Ural bench
seq 4610, 2026-09-25, exit 2.

## What happened

All 20 reps completed (cold and warm, both arms), but the driver
`pr-ab.sh` died with a shell syntax error at line 403 in its
result-comparison step, so no verdict and no timing table were
produced. No numbers are recoverable from the log.

## Implication

Superseded by the owner requeue with the fixed driver
(`pr-ab-287bad775a.sh`, queue seq 4615). Await that verdict; no
prose change.
