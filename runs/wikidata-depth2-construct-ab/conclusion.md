# Conclusion for run wikidata-depth2-construct-ab (queue seq 4476)

## Scope

Stage A export A/B from the run 133 plan on the Wikidata truthy index
(`/local/data-ssd/stoetzem/wikidata/wikidata`): baseline
`qlever-server-master` (v0.6.0-176-g3f1b75219) against the depth-2
construct variant (v0.6.0-144-gd5cec278b) from branch
`perf/export-depth2-construct-fresh` (PR #196). Two workloads, each with
five cache-evicted cold reps: `H-vocab-label-large` CONSTRUCT export and
its SELECT twin. Two earlier attempts the same day passed wrapper
scripts as binaries and aborted before any rep; they produced no data.

## Validity checks

All 20 reps return HTTP 200. Every CONSTRUCT body carries exactly
1302749672 bytes and every SELECT body exactly 674222797 bytes on both
arms, so the comparison is byte-identical output. The page cache is
evicted before every rep. `COMPLETE` reads `ALL DONE` and the waiter
reports exit 0.

## Results

Cold CONSTRUCT means are 22.60 s for the baseline and 21.88 s for the
depth-2 variant (-3.2%). Cold SELECT means are 20.11 s and 20.19 s
(+0.4%, flat). The depth-2 pipeline helps the CONSTRUCT export modestly
and leaves the SELECT path unchanged, which fits a construct-path-only
change.

## Implication

The CONSTRUCT -3.2% belongs in the chapter as the depth-2 data point.
The SELECT flatline stays as a scope note: the feature does not touch
that path.
