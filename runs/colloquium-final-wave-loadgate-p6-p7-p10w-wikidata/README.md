# Colloquium result: before / ring only / final (part 10 + wave reaping), uncompressed

## Question

How do the three versions shown in the colloquium compare, now that the final version includes wave reaping and the harness no longer compresses responses?

## Setup

1. Machine: Ural (shared), Wikidata truthy, `on-disk-compressed` vocabulary.
2. Arms (`build-env.txt`, `gate-verify-*.log`):
   1. `p6-before-pread` = stack part 6, `a752a457` (md5 `afdbdd04`): vocabulary reads with `pread`.
   2. `p7-ring-only` = stack part 7, `60f854f4` (md5 `86bd2523`): every vocabulary read through the `io_uring` ring.
   3. `p10-wave-final` = stack part 10 + wave reaping, `77a41c66` (md5 `ad66397f`): ring + page-cache fast path + wave reaping (fork PR marvin7122/qlever#270, upstream ad-freiburg/qlever#3476).
3. Queries: German sequential `H-vocab-label-large-de`, German scattered `A-scatter-disambig-label-de`, English `H-vocab-label-large` (guard: English labels live in the in-memory vocabulary).
4. 3 interleaved trials per arm, order rotating; cold = `drop_caches` before every run; warm = warm-up, then the query looped >= 10 s, per-query mean.
   Responses uncompressed (`Accept-Encoding: identity`).
5. Driver `pr-ab-multi-v2-3bin-nowait` (no load gate, load logged per trial in `rep-load.tsv`), Ural seq 5357, 2026-10-07 18:33–19:56 UTC.
   It replaces the queued run `colloquium-repeat-loadgate-p6-p7-p10-wikidata` (seq 5330, final = part 10 without wave reaping), which was dropped before it started.

## Result (median [min–max] s; `conclusion.md`, `vs-variant2/conclusion.md`)

| # | concern | query | scenario | before (p6) | ring only (p7) | final (p10 + wave) | before / final |
|---|---|---|---|---|---|---|---|
| 1 | cold, sequential | label-large-de | cold | 93.39 [91.85–93.59] | 39.43 [39.13–39.45] | 33.75 [33.42–34.07] | 2.77× faster |
| 2 | cold, scattered | scatter-disambig-de | cold | 63.42 [62.17–83.72] | 14.77 [11.16–14.79] | 13.63 [11.29–13.66] | 4.65× faster |
| 3 | warm, sequential | label-large-de | warm | 21.20 [19.74–24.47] | 28.66 [28.43–28.70] | 21.24 [18.63–23.90] | parity (+0.2 %) |
| 4 | warm, scattered | scatter-disambig-de | warm | 3.68 [3.10–3.75] | 3.54 [3.45–3.55] | 3.07 [3.06–3.14] | −16.5 %, ranges overlap |
| 5 | guard, in-memory vocab | label-large (en) | cold | 26.56 [23.92–34.44] | 28.23 [26.51–31.08] | 30.34 [24.24–37.42] | noise |
| 6 | guard, in-memory vocab | label-large (en) | warm | 42.21 [26.02–44.53] | 46.03 [42.79–46.51] | 45.68 [42.28–45.79] | noise |

All bodies are byte-identical across the three arms per query (`correctness.tsv`).

1. The ring alone (p7) is what makes cold exports fast, but it makes the warm sequential export 35 % slower (row 3, disjoint ranges).
2. The page-cache fast path removes that warm cost: final = before on warm sequential.
3. Wave reaping adds no measurable time on top of part 10 here (see `../wave-reap-final-p10-wikidata`: −0.8 % cold sequential, −1.7 % cold scattered), so the final column equals part 10 within noise.
4. The cold speedup of 2.77× (sequential) is larger than the 2.5–2.6× of the earlier compressed-harness runs (`colloquium-final-ab-wikidata-len10`: 67.7 → 27.3 s; `colloquium-final-p6-p7-p10-wikidata`: 88.7 → 33.8 s); inferred cause: those runs added single-threaded deflate time to every arm, and their p6 cold medians varied (67.7 vs 88.7 s).

## Noise

1. 53 of 54 trials ran with load1 > 5 (`rep-load.tsv`, `kept-noisy`); German sequential cold trials ran at load1 16–21, German scattered cold trials at 9–20.
2. English warm (row 6): the first p6 trial ran at load1 7.5 (26.0 s), all others at load1 20–27 (42–46 s); the row says nothing about the versions.
