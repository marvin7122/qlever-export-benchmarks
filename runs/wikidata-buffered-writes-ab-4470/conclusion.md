# Conclusion for run pr195-buffered-writes-ab (queue seq 4470) — KILLED, no data

## Scope

Buffered-writes export A/B: master against
`perf/export-buffered-writes-8mib-fresh` on the Wikidata truthy index.
Ural bench seq 4470 (CI purpose), 2026-09-25, exit 143 (SIGTERM).

## Validity checks

The run cycled normally (preflight ok, server ready, page-cache
eviction) and was killed mid-measurement. No arm completed.

## Result

No data. No verdict on buffered writes follows.

## Implication

Requeue if the buffered-writes number is still wanted; nothing in the
thesis cites this run.
