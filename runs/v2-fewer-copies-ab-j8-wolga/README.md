# Export V2: fewer copies (fork PR #268), A/B, 8 query threads, measured on Wolga

## Question

Fork PR marvin7122/qlever#268 removes the per-cell `std::string`s and two whole-window copies from the V2 SELECT CSV/TSV serializer.
Does the English-label export get faster or use less CPU at 8 query threads?

## Setup

1. Machine: `wolga`, AMD Ryzen 7 3700X, governor `schedutil` (`env-before.txt`).
   Numbers from this host are compared only with other Wolga runs.
2. Index: Wikidata truthy, `on-disk-compressed` vocabulary.
3. Query: `queries/H-vocab-label-large-select.rq` (English labels of all humans, SELECT, CSV), 674,222,797 bytes, 11,643,064 rows.
4. Arms (`meta.env`), both with request field `fast-export=1` (V2) and `--num-simultaneous-queries 8`:
   1. base `v2-87f57674`: `work/pr120-postsub` @ `87f57674`;
   2. variant `v2-fewer-copies-719615ab`: `perf/export-v2-fewer-copies` @ `719615ab`.
5. Binaries: the Ural (Ubuntu 24.04) build products, copied and re-linked with patchelf to bundled u24 libraries, because Wolga's glibc is 2.35.
   Code bytes and `--version` are unchanged; only the file md5 differs (`wolga-bench/u24/PROVENANCE.tsv`: base f42a099c → 2ef6fc08, variant 6c924a0b → 1e4d1dc5).
6. Protocol: 3 interleaved trials per arm and scenario, alternating order; cold after `clear-caches`; warm loops the query until ≥ 10 s and reports the mean per query.
   Uncompressed response (`Accept-Encoding: identity`).

## Results

| # | concern | scenario | base median (min–max) | variant median (min–max) | Δ |
|---|---|---|---|---|---|
| 1 | wall, main claim | cold | 4.06 s (3.77–4.81) | 4.57 s (3.52–5.12) | within noise |
| 2 | wall, main claim | warm | 3.99 s (3.58–4.19) | 3.80 s (3.77–4.16) | within noise |
| 3 | process CPU | cold | 34.91 s (34.13–35.00) | 33.34 s (32.21–33.97) | −4.5 %, ranges disjoint |
| 4 | process CPU, whole warm loop | warm | 100.31 s (100.05–102.14) | 98.91 s (97.22–99.93) | −1.4 %, ranges disjoint, below 2 % |

Every body has 674,222,797 bytes and the same row multiset as base rep 1 (`correctness.tsv`); V2 row order follows morsel completion.
Gates: preflight, verify and postflight PASS.

## Caveat: co-tenant load

`rep-load.tsv` records up to 12 R/D processes of other users during the trials, so the wall times are noisy.
The CPU rows are less sensitive to this, but not immune.
