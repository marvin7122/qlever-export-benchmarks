# Conclusion for run wikidata-comparator-ab (queue seq 4275)

## Scope

This run compares `qlever-server-ch7-integration` at `84b943e4e`
with the ASCII fast-path comparator `adb35863f` (PR 189). Both arms
serve the upgraded Wikidata truthy index
`index-for-upgrade-new-format`. Each arm runs one warm and two cold
repetitions of `large-de` and `scatter200k-de`, with the page cache
cleared before each cold repetition. Queue seq 4275 exits with
warnings only.

## Validity checks

All `large-de` requests return HTTP 200 with identical body size
(504927346 bytes) and identical sha256 `dcd2b1bc...` across all six
reps, so the comparison is byte-identical output. The directory
carries a COMPLETE marker with a hash-mismatch warning that refers
exclusively to the `scatter200k-de` reps: both arms return HTTP 400
there (the query is broken independently of the export path), and
only the error-page bodies differ. No measured workload disagrees.

## Result

Cold `large-de` means are 24.10 s for the baseline and 24.33 s for
the variant: a tie within repetition noise. The comparator changes
only user CPU (about 5% of it in the fp997 profile), which cold
exports hide under I/O wait, so a tie is the predicted outcome and
doubles as a no-regression gate. Any comparator win must show on
warm cache or in profiles, not here.
