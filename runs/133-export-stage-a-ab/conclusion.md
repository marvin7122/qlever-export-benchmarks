# Run 133: Stage A export A/B (conclusion)

Ural bench seq 3788, 2026-09-17, ALL DONE with zero WARN lines.
Baseline: master `090c76f64`. Variant: `bench/export-select-batch`, which
resolves the SELECT csv/tsv export loop in 4096-row windows with one
`idsToStringAndType` call per column instead of one `idToStringAndType`
call per cell. Emission stays row-major. The CONSTRUCT path is untouched
(it already uses the batch API). Five reps per workload per arm, cache
evicted before every rep. Every response body is byte-identical to its
workload reference (the run reports DONE WITH WARNINGS otherwise).

## Numbers

Client-observed elapsed per rep (HTTP 200 throughout):

| Workload | Baseline median (s) | Variant median (s) | Ratio |
|---|---|---|---|
| CONSTRUCT turtle (1,302,749,672 bytes) | 22.62 | 22.81 | 0.992x |
| SELECT csv (674,222,797 bytes) | 19.96 | 19.26 | 1.036x |

SELECT reps: baseline 19.83/19.85/19.96/20.11/20.25,
variant 18.82/19.18/19.26/19.44/19.46. The ranges do not overlap.
CONSTRUCT reps overlap fully (baseline 22.21-22.81,
variant 22.64-23.00).

## Verdict

Stage A speeds the SELECT export by 3.5% with byte-identical output.
CONSTRUCT is unchanged, as the variant does not touch that path; the
0.8% gap there is noise inside overlapping ranges. Against the run-132
attribution the win sits in the expected 10-14% allocation and dispatch
headroom, of which batching the lookup shape captures about a third.

The run-134 mock predicted no win, and the A/B overrules it. The mock
called the concrete vocabulary class directly, so it missed the
per-cell polymorphic dispatch through the `Index` interface that the
production loop pays and the batch call avoids. The mock remains valid
for its narrow claim (the batch container itself adds overhead); it is
not a model of the production call path.

## Artifacts

`driver.log`, `results-summary.txt`, per-arm `requests.tsv` and
server logs. Response bodies stay on Ural (0.7-1.3 GB each).
