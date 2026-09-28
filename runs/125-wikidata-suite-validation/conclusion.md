# Conclusion for run 125 (Wikidata suite validation, Phase 0)

## Scope

Run 125 validates the 14-query draft Wikidata suite plus 5 SELECT
companions on Wikidata truthy (master binary v0.6.0-89-g090c76f64).
Ural bench seq 3732, 2026-09-16, exit 0. (Seqs 3698, 3728, 3729, 3731
died on an unscannable branch or a non-executable driver; no data.)
One cold and one warm repetition per query through the harness in pilot
mode. Cold uses the harness advisory vmtouch eviction, not the
clear-caches hard eviction Phase 1 uses.

## Result

All 38 repetitions return HTTP 200 with status complete. Response bytes
and checksums are stable cold versus warm for every query. No query
times out. The heaviest query is H-vocab-label-large at 23.6 s cold and
23.5 s warm for 1,302,749,672 Turtle bytes. H-format is CPU-bound
(2.21 s cold, 2.06 s warm). H-dedup completes in 3.33 s cold and
0.56 s warm with 56,843,290 bytes.

## Freeze decision

Keep all 14 CONSTRUCT queries and all 5 SELECT companions. Nothing is
cut or LIMIT-bound. The suite freezes as construct-workload-wikidata-v1
and select-workload-wikidata-v1 with the sizes below.

CONSTRUCT (bytes, cold s, warm s): D1 1092678/0.35/0.06,
D2 11147807/0.79/0.14, D3 11611130/1.86/0.42, D4 5632445/0.45/0.23,
R1 5778786/1.23/0.34, R2 23144633/2.93/0.66, R3 22468139/1.27/0.23,
H-dedup 56843290/3.33/0.56, H-format 21280840/2.21/2.06,
H-size 11078871/0.30/0.23, H-vocab-label-small 21636/0.19/0.11,
H-vocab-label-large 1302749672/23.58/23.46,
H-vocab-description-small 24490/0.18/0.09,
H-vocab-description-large 11331291/0.20/0.16.

SELECT (bytes, cold s, warm s): D1-select 994101/0.35/0.06,
R1-select 5261652/1.27/0.38, R2-select 21089304/3.12/0.81,
H-size-select 5679642/0.26/0.21,
H-vocab-label-large-select 674222797/20.69/19.90.

## Artefacts

- Ural run directory:
  `/local/data-ssd/stoetzem/thesis/experiments/runs/125-wikidata-suite-validation`.
- Local mirror: `experiments/runs/125-wikidata-suite-validation`
  (validation-summary.csv, driver.log, this file).
- Driver: `scripts/validate-wikidata-suite.sh`.
- Frozen manifests: `experiments/manifests/construct-workload-wikidata-v1.yaml`,
  `experiments/manifests/select-workload-wikidata-v1.yaml`.
