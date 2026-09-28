# Conclusion for run wikidata-pr57-borrowed-ab-cold (queue seq 4591) — REFUSED, no data

## Scope

Cold borrowed-terms A/B on the Wikidata truthy index (fresh
`perf/export-borrowed-vocab-terms-pr57-fresh` build from seq 4590).
Ural bench seq 4591, 2026-09-25, exit 2.

## Validity checks

None ran. Same gate refusal as seq 4576: the entry carries no
`--branch`/`--qlever-branch` verification.

## Result

No data. The cold-path gap noted in the thesis stays open.

## Implication

Requeue with `--qlever-branch
perf/export-borrowed-vocab-terms-pr57-fresh` once queue placement is
resolved. Prerequisite build (seq 4590) finished green.
