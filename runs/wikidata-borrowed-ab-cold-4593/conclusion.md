# Conclusion for run pr57-borrowed-ab-cold (queue seq 4593)

## Scope

Cold borrowed-terms A/B on the Wikidata truthy index: branch
`perf/export-borrowed-vocab-terms-pr57-fresh` at `f47d174dee` against
master at `9932d19dd9`. Binaries are the only difference. One warmup
plus one timed rep per arm in ABBA order. Ural bench seq 4593,
2026-09-25, exit 0.

## Validity checks

Both timed reps return HTTP 200 with byte-identical bodies (57139614
bytes, SHA `32af3541b477186c` both arms). Output agreement PASS.
Caveat: the stats summarizer crashes on the log format, so the
numbers below come from the raw rep lines; and the evidence is a
single timed rep per arm.

## Result

Timed rep: branch 0.878 s vs master 0.879 s (-0.1%, tie). The
branch warmup rep is slower (5.930 s vs 0.888 s), but warmups are
discarded by design and both timed reps agree.

## Implication

Borrowed terms change nothing on the cold path either. Closes the
cold-path gap: warm null plus cold null. Belongs in the 5A inventory
as a double null.
