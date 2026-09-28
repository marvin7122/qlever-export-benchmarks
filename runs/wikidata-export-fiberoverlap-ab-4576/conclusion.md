# Conclusion for run wikidata-export-fiberoverlap-ab (queue seq 4576) — REFUSED, no data

## Scope

Export fiber-overlap A/B: master binary against
`feat/export-fiber-overlap` binary on the Wikidata truthy index. Ural
bench seq 4576, 2026-09-25, exit 2.

## Validity checks

None ran. The queue gate refuses benches without `--branch` or
`--qlever-branch` verification (`FATAL: bench without
--branch/--qlever-branch is refused`). The entry carries only binary
paths, so the run never starts.

## Result

No data. No verdict on fiber overlap follows. The depth-2
construct-path prose stays the only filed fiber measurement.

## Implication

Requeue with `--qlever-branch feat/export-fiber-overlap` (plus master
baseline verification) once queue placement (fleet vs Ural paths) is
resolved. Both binaries were verified present and fresh on 2026-09-24.
