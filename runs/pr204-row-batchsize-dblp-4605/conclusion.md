# Conclusion for run pr204-row-batchsize-dblp-ab repeat (queue seq 4605)

## Scope

Repeat of seq 4604 with identical arguments: same binary
(`4b74f3ef`), 1024 vs 4096, DBLP `H-vocab-title-small` turtle
export, 3 cold plus 3 warm reps. Ural bench seq 4605, 2026-09-25,
exit 0.

## Validity checks

Preflight and postflight PASS. Bodies byte-identical.

## Result

Cold medians: 1.0155 s vs 0.8419 s (-17.1%, non-overlapping).
Warm medians: 0.0764 s vs 0.0767 s (+0.4%, within noise).

## Implication

Replicates seq 4604 on cold (-18.0% then, -17.1% now). The warm
-1.8% from seq 4604 does not replicate; warm is within noise.
Prose updated to claim the cold win only.
