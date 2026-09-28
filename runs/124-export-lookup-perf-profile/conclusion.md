# Conclusion for run 124 (export term-lookup CPU share, perf)

## Scope

Run 124 profiles warm Wikidata truthy export on the master binary to
measure the CPU share of term (vocabulary) lookup inside the export
path. No DBLP data is used. Ural bench seq 3726, 2026-09-16, exit 0.
Binary `/local/data-ssd/stoetzem/wt/master/build/qlever-server`,
version v0.6.0-89-g090c76f64, master commit 090c76f642. Sampling is
999 Hz with dwarf call graphs, one perf session per workload over eight
warm sequential repetitions. Unknown symbols stay below 0.5 percent, so
symbol resolution is healthy.

## Queries

- CONSTRUCT `representative-queries/wikidata/H-vocab-label-large.rq`
  (turtle_export, text/turtle). Eight reps, all HTTP 200, 22.4 to
  23.0 s each, 1,302,749,672 bytes stable. The byte count matches the
  documented humans-label body size, confirming the query identity.
  (The driver summary labels it H-vocab-title-large; that label is a
  driver echo bug, the executed file is the Wikidata query.)
- SELECT `representative-queries/wikidata/H-vocab-label-large-select.rq`
  (csv_export, text/csv). Eight reps, all HTTP 200, 20.3 to 22.2 s
  each, 674,222,797 bytes stable.

## Result (flat profile, server process)

- CONSTRUCT: total 96.91, lookup 46.32, format 4.52, other 46.07.
- SELECT: total 98.08, lookup 55.04, format 9.04, other 34.00.

## Interpretation

Term lookup takes 46.3 percent of warm server CPU on CONSTRUCT export
and 55.0 percent on SELECT export, against 4.5 and 9.0 percent in
formatting. The remainder holds the WHERE clause execution and the
stream plumbing, so both lookup shares are lower bounds on the
export-phase fraction, not exact export shares. The profile justifies a
lookup cache in principle. It does not size the 2048-entry per-variable
IdCache; that bound still rests on repetition reasoning.

## Artefacts

- Ural run directory:
  `/local/data-ssd/stoetzem/thesis/experiments/runs/124-export-lookup-perf-profile`
  (perf.data, flat.txt, callgraph.txt, requests.tsv per workload).
- Local mirror: `experiments/runs/124-export-lookup-perf-profile`
  (results-summary.txt, share and request files, driver.log).
- Driver: `scripts/profile-export-lookup-share.sh`.
- Queue: build seq 3695, bench seq 3726 (retry of seq 3696, which died
  on a transient GitHub fetch failure).
