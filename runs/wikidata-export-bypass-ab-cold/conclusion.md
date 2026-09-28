# Conclusion for run wikidata-export-bypass-ab-cold (queue seq 4574)

## Scope

Cold SELECT CSV export A/B on the Wikidata truthy index: one binary
(branch `perf/export-result-cache-bypass` at `dd70ddca0d`), two arms
differing only in the runtime flag. Off arm:
`bypass-result-cache-for-export=false` (default). On arm: `=true`.
Five queries (`H-vocab-label-large-select`, `H-size-select`,
`D1-select`, `R1-select`, `R2-select`), five cold reps each with
page-cache eviction. Ural bench seq 4574, 2026-09-25, exit 0.

## Validity checks

All 50 reps return HTTP 200. Bodies are byte-identical per query
across arms (674222797, 5679642, 994101, 5261652, 21089304 bytes).
The on arm shows exactly zero estimate-probe misses on every rep
(dMisses=0 vs 15/47/33 off), confirming the branch skips the probes
when caching is disabled.

## Result

Cold medians, off vs on: H-vocab-label-large-select 20.113 s vs
19.616 s (-2.5%, non-overlapping ranges). H-size-select 0.189 s vs
0.181 s (-3.7%, non-overlapping). D1-select 0.265 s vs 0.265 s
(flat). R1-select 1.156 s vs 1.154 s (flat). R2-select 2.927 s vs
2.919 s (flat).

## Implication

Bypassing the result cache for export removes a small real cost on
the vocab-heavy SELECT exports (2-4%) and changes nothing elsewhere.
Belongs in the SELECT export path section as a measured micro-win.
