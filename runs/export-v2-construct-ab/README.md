# V2 CONSTRUCT vs Legacy (fork PR #273): first A/B, German cold+warm, English warm

## Question

Fork PR marvin7122/qlever#273 lets export engine V2 serve CONSTRUCT as Turtle/N-Triples.
Is the colloquium running example (German labels of all humans, 4,515,802 triples, 505 MB Turtle) faster on V2 than on Legacy, and is the output the same triple multiset?
English labels (11,643,064 triples, 1.30 GB) as the second query.

## Setup

1. Machine: `ural`, governor `powersave`; no load wait, load logged per trial (`load-gate.txt`, `rep-load.tsv`).
2. Index: Wikidata truthy, vocabulary type `on-disk-compressed`.
3. Arms (`meta.env`, gate `gate-verify.log`: PASS, io_uring compiled in): ONE binary `60efca19a` (V2 CONSTRUCT @ branch `feat/export-v2-construct`), arms differ only in the request field: legacy `fast-export=0` vs v2 `fast-export=1`.
4. Queries (`queries/`), all CONSTRUCT to Turtle, 8 query threads: `H-vocab-label-large-de.rq` (cold + warm), `H-vocab-label-large.rq` (warm).
5. Procedure (driver `/local/data-ssd/stoetzem/incoming/export-v2-construct-ab.sh`): 3 interleaved trials per arm, alternating order.
   Cold: fresh server after `drop_caches`, one execution.
   Warm: page cache warm, result cache cleared before each execution, harness loops the query until >= 10 s (wall_s below is per execution).
6. Run: 2026-10-08 00:29-00:51 UTC, Ural queue entry #5371 (re-enqueue of #5369, which aborted in its unit-test step; #5367 aborted earlier the same way).
   Unit tests on the Wolga-built test binaries (@`e3ff30da`) run first inside the job (`unit-tests.txt`): ExportEngineV2LiveTest 6/6, ExportMorselPlannerTest 9/9, ExportPipelineRouterTest 16/16, all PASS.

## Result

"faster/slower" requires disjoint min-max ranges and |delta| >= 2 % (medians of 3 trials, per-execution wall seconds).

| # | concern | query | scenario | legacy wall s median [min-max] | v2 wall s median [min-max] | delta | verdict |
|---|---|---|---|---|---|---|---|
| 1 | running example | H-vocab-label-large-de | cold | 27.32 [27.08-29.58] | 4.81 [4.78-5.57] | -82.4 % | faster |
| 2 | running example, page cache warm | H-vocab-label-large-de | warm | 17.34 [16.07-23.75] | 3.04 [2.06-5.89] | -82.5 % | faster |
| 3 | guard: English labels | H-vocab-label-large | warm | 39.70 [39.14-41.08] | 8.97 [7.52-10.10] | -77.4 % | faster |

Correctness (`correctness.tsv`): the triple-multiset hash is identical across all arms and trials (de `75eb7a67...`, en `f5e829f8...`), same bytes (504,927,346) and line counts (4,515,802 / 11,643,064).
V2 emits morsels in completion order, so byte order differs from Legacy except by coincidence; LIMIT/OFFSET sessions are byte-identical by construction (covered in `ExportEngineV2LiveTest`).

Parallelism: busy cores cold 1.02 (legacy) vs ~8.2 (v2); warm de ~1.05 vs 4.0-9.2; warm en ~1.07 vs 3.5-4.5.
Cold disk: ~9.4 GB read on both arms; `io_uring_enter` ~5.69 M (legacy) vs ~5.80 M (v2).

Caveat: the box was shared during the warm cells (max load1 per trial 2.9-22.3, highest during English warm).
Trials are interleaved, so both arms face the same load, and all three cells have wide disjoint ranges; a quiet-box re-run would tighten the warm-de ranges but not change the verdicts.
