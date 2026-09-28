# Conclusion for run pr208-typed-count-warm-ab (queue seq 4575) — FAILED, no data

## Scope

Warm-cache typed-count A/B for PR 208: branch
`marvin-groupby-typed-count-fresh` at `318e03d6bd` against master, DBLP
index, warm query times with result-value agreement check. Ural bench
seq 4575, 2026-09-25, exit 1.

## Validity checks

Branch verification passes (`318e03d6bd` equals origin head). The
benchmark itself never starts.

## Result

No data. The driver dies at startup, twice identically (initial plus
retry): `pr208-typed-count-warm-ab.sh: line 39: tag: unbound variable`
under `set -u`. Line 39 is `run_arm()`'s `local bin="$1" tag="$2"`
header, so the running copy received fewer than two arguments. The
on-disk script is consistent (both call sites pass binary plus tag),
so the file was likely fixed after enqueue, or the runner passed
different args. No rep ran on either arm. No verdict follows.

## Implication

Requeue the current on-disk script once queue placement (fleet vs
Ural paths) is resolved. Nothing in the thesis cites this run.
