# Idea 1 prototype: read known-resident vocabulary pages from a memory mapping (vs part 12)

## Question

Does copying vocabulary words and offsets from a read-only memory mapping, for pages that this process has read before, make the German label export faster than one `preadv2(RWF_NOWAIT)` system call per word?

## Setup

1. Machine: `ural`, AMD Ryzen 7 3700X (8 cores, 16 threads), 125 GiB RAM, Linux 7.0.0-28, CPU governor `powersave` (no root on the box) (`env-before.txt`).
2. Index: Wikidata truthy, vocabulary type `on-disk-compressed`.
3. Arms (`meta.env`, `build-env.txt`, gates `gate-verify-*.log`: PASS, io_uring compiled in):
   - base `p12`: export stack part 12 `fc954b6300d518ce25131169731e45f9d4f867a2`;
   - variant `mmap-resident`: `ca7132433d9da6cd54f04c68088d2888edd6190a` (part 12 + `ResidentFileMapping`, runtime parameter `vocabulary-mmap-resident-reads=true`);
   - variant2 `mmap-resident-off`: the same binary with `vocabulary-mmap-resident-reads=false` (control: the code change alone must not cost time).
4. Query: [`queries/H-vocab-label-large-de.rq`](queries/H-vocab-label-large-de.rq), German labels of all humans (4.5 M triples, 505 MB of Turtle); all German words are in the on-disk vocabulary.
5. Procedure (harness `pr-ab-multi-v3`, version v5): 5 interleaved trials per arm and scenario, order alternating; server on CPUs 0–2, client on CPU 3.
   Cold: fresh server after evicting the serving files from the page cache, one execution.
   Warm: one long-running server per binary, result cache cleared before each execution, each measurement loops the query until ≥ 10 s (per-query mean).
   Cycles: `perf stat` on the server process tree per query.
6. Run: 2026-10-07 00:27–02:03 UTC on Ural.
   Load: the box was shared; `load-gate.tsv` shows 6 busy foreign CPUs before most cold trials (the gate waited 320 s and then proceeded).
   The arms are interleaved, so the load affects all arms alike, but the ranges are wider than on a quiet box.

## Result (`conclusion.md`)

| # | concern | scenario | base p12 median [min–max] s | mmap-resident median [min–max] s | delta | verdict |
|---|---|---|---|---|---|---|
| 1 | idea 1 on sequential German labels | cold | 32.52 [29.78–33.97] | 26.14 [19.79–26.45] | −19.6 % | faster (ranges disjoint) |
| 2 | same, page cache warm | warm | 18.74 [15.49–23.31] | 11.40 [8.97–13.40] | −39.2 % | faster (ranges disjoint; cycles −31.7 %) |
| 3 | control: same binary, flag off | cold / warm | 32.52 / 18.74 | 33.62 / 20.33 | +3.4 % / +8.5 % | within noise |

Cycles per query (perf stat): cold 146.5 → 118.7 Gcycles (−19.0 %), warm 89.5 → 61.1 Gcycles (−31.7 %).
All bodies are byte-identical to base (`correctness.tsv`); postflight gates PASS (`gate-postflight-*.log`).

## Files

`results.csv` (all trials), `<scenario>/<query>/<arm>/raw/` (harness output per trial), `vs-variant/`, `vs-variant2/` (two-arm views), `correctness.tsv`, `phase-times.tsv`, `startup.tsv`, `residency-at-ready.tsv`, `load-gate.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.
Binaries are not included.

The cumulative chain measurement of all three ideas is in [`chain-ideas-wikidata`](../chain-ideas-wikidata/) (when published).
