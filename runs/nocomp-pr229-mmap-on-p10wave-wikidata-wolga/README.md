# nocomp-pr229-mmap-on-p10wave-wikidata-wolga: #229 mmap offsets on top of the presented io_uring version

A/B on Wikidata truthy, measured on Wolga (Ryzen 7 3700X), 2026-10-07.
Uncompressed responses (harness sends `Accept-Encoding: identity`).
CONSTRUCT Turtle export, 1 query thread, 3 interleaved trials per arm, cold trials after dropping the page cache, warm trials loop the query for at least 10 s.

- Base `p10-wave-77a41c66`: export stack part 10 + wave reaping (`77a41c66`, branch `colloquium/final-p10-wave-reap`), the version presented in the colloquium.
- Variant `p10-wave-mmap-offsets-d6f429dd`: base + fork PR #229 (`d6f429dd`, branch `perf/mmap-offsets-on-p10wave`). The `.offsets` file is memory-mapped; phase 1 of `lookupBatch` reads the offset pairs from the mapping, bypassing the ring and the `preadv2(RWF_NOWAIT)` page-cache fast path. Phase 2 (word bytes) is unchanged.
- Page-cache fast path at its default (on) in both arms.
- Binaries: Wolga u24 builds, re-linked for the Wolga runtime with patchelf (code bytes identical).

Unit tests of the variant (before timing): `ReadOnlyMmapTest` 6/6, `VocabularyOnDiskTest` 21/21, `IoUringManagerTest` 45/45.

Result (median [min–max] s, `timing/results.csv`; faster/slower only with disjoint ranges and |delta| >= 2 %):

| query | scenario | base | variant | delta | verdict |
|---|---|---|---|---|---|
| H-vocab-label-large-de (sequential) | cold | 23.38 [22.81–23.57] | 23.51 [20.78–25.00] | +0.6 % | no difference |
| H-vocab-label-large-de (sequential) | warm | 17.25 [16.68–19.17] | 12.41 [12.40–13.72] | −28.0 % | faster |
| A-scatter-disambig-label-de (scattered) | cold | 7.91 [6.55–10.08] | 9.19 [8.85–11.87] | +16.2 % | no difference (ranges overlap) |
| A-scatter-disambig-label-de (scattered) | warm | 4.40 [4.15–4.40] | 3.51 [3.46–3.52] | −20.2 % | faster |

Response bodies identical in every trial.
Gates: preflight, verify and postflight PASS.

Caveats:
- Wolga was shared: max load1 per trial 5.4–21.3, other users' running processes up to 12 (`timing/rep-load.tsv`, `timing/loadavg.tsv`); no load wait.
- Cold scattered trials last 6.5–11.9 s; cold trials cannot be looped.
- Compare these numbers only with other Wolga runs.

Not included: the server binaries (`timing/bin/`) and saved response bodies.
