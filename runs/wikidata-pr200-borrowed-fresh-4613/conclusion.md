# Conclusion for run pr200-borrowed-fresh (queue seq 4613) — NO DATA

## Scope

Borrowed-terms A/B on Wikidata, fresh branch
`perf/export-borrowed-vocab-terms-pr57-fresh` (f47d174d) vs master
base (9a1fc884), humans-label-en turtle export, 5 reps. Ural bench
seq 4613, 2026-09-25, exit 2.

## What happened

The driver aborted before any query: `verify-qlever-binary failed
for base`. The master worktree binary did not pass the pre-bench
gate, so no rep ran and no numbers exist.

## Implication

Likely a stale or mid-rebuild master binary (the master rebuild,
seq 4612, ran concurrently). Requeue stays with the owner. No
prose change.
