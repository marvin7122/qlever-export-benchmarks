# Conclusion for run wikidata-borrowed-terms-ab (queue seq 4563)

## Scope

Warm CONSTRUCT export A/B on the reused Wikidata truthy index: branch
binary from `perf/export-borrowed-vocab-terms-pr57-fresh` at
`885da37d02` against master at `399fa7ec00` (= origin/master).
Workload is CONSTRUCT over humans with LIMIT 500000 (57 MB bodies).
Three warmups plus six timed reps per arm in ABBA order. No cold reps.

## Validity checks

Every timed rep returns HTTP 200 on both arms. All bodies share SHA
`32af3541b477186c` at 57139614 bytes, so the comparison is
byte-identical output. The script's own stats block throws a traceback
and prints no summary, but the raw rep lines are complete and the
waiter reports exit 0 with agreement PASS.

## Result

Median of the six timed reps is 0.863 s for the branch and 0.864 s for
master (-0.1%, null). Borrowed vocabulary terms change nothing on this
warm workload.

## Implication

The borrowed-terms subsection keeps its open expected improvement for
the cold path and records this warm null. A cold A/B stays unmeasured.
