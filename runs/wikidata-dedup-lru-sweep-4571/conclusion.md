# Conclusion for run dedup-lru-sweep-4571 (queue seq 4571) — FAILED, no data

## Scope

Dedup-LRU capacity sweep: branch `perf/export-dedup-lru-sizing` at
`e24d2e84af` against master at `399fa7ec00` on the reused Wikidata
truthy index. Modes per arm: none, lru:1000, lru:100000, lru:1000000,
full. Five timed reps per arm per mode. Ural bench seq 4571,
2026-09-24/25, exit 1 (`sweep: FAIL`).

## Validity checks

Branch unit tests pass 15/15 (`ConstructDeduplicatorTest`, incl. the
new `lruDefaultVocabBudgetRetainsFullWindow`). Both binaries verified
against their commits. These checks pass; they do not save the run.

## Result

No data. Zero reps return HTTP 200 on any arm or mode (n=0 medians
throughout). The servers never started: the driver passes
`--set-runtime-parameter construct-export-num-threads=8`, but neither
binary provides that parameter (absent from `--set-runtime-parameter
help` on both arms). Both servers exit immediately with `Invalid
argument`, so every rep fails on baseline and branch alike. This is a
driver bug, not a code result. No verdict on the LRU sizing follows.

## Implication

The sweep must rerun after removing the invalid flag (both arms then
run the identical default threading, keeping the single-factor
design). Driver fixed on Ural
(`incoming/dedup-lru-sweep.sh`, backup `dedup-lru-sweep.sh.bak-4571`,
`bash -n` clean). Requeue blocked: `ural-wq bench` now reroutes to the
fleet, which has no `/local/data-ssd` script path, and no client flag
pins the job to Ural. Owner decision needed on where this reruns.
