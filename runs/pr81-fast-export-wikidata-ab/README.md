# Does a faster Turtle formatter (fork PR 81) speed up Wikidata exports?

## Question

Fork PR 81 (upstream #3529, stack part 10) adds `FastExportStreamFormatter`, a formatter that is faster in a microbenchmark.
This run asks whether it makes real Wikidata CONSTRUCT exports faster end to end.
The run is excluded as a performance claim: the formatter has no call site in the export path yet, so a null result is expected.
It is kept because its English-label numbers show that this export is CPU-bound.

## Setup

1. Machine: `ural`, AMD Ryzen 7 3700X (8 cores, 16 threads), 125 GiB RAM (about 135 GB), index on a software RAID (`/dev/md1`) of two Samsung 990 PRO NVMe SSDs.
   CPU governor `powersave`, preflight load 0.24 (from `conclusion.md`); this directory has no separate environment file.
2. Index: Wikidata truthy, 8.2 billion triples (`/local/data-ssd/stoetzem/wikidata/wikidata`).
3. Queries (Turtle CONSTRUCT export); the `.rq` files are not in this directory:
   - `H-vocab-label-large`: every human with its English label (English labels sit in the in-memory part of the vocabulary):
     ```sparql
     PREFIX wd: <http://www.wikidata.org/entity/>
     PREFIX wdt: <http://www.wikidata.org/prop/direct/>
     PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
     CONSTRUCT { ?entity rdfs:label ?label }
     WHERE {
       ?entity wdt:P31 wd:Q5 .
       ?entity rdfs:label ?label .
       FILTER(LANG(?label) = "en")
     }
     ```
   - `H-size` and `D3`: two small controls (11 MB of output each).
4. Arms (two binaries):
   - baseline (arm A): `stack/08-construct-batch-evaluator` at `c2a743e06`;
   - variant (arm B): the same commit plus PR 81, `bench/pr81-arm-b-65955219` at `659552193`.
5. Scenarios:
   - cold: the serving index files are evicted from the OS page cache before each repetition;
   - warm: the files are already in the OS page cache.
6. Repetitions: 5 cold and 5 warm per arm and query, arms interleaved; tables report min/median/max.

## Result

| query | scenario | baseline, median | variant, median | speedup |
|---|---|---:|---:|---:|
| H-vocab-label-large | cold | 27.831 s | 28.314 s | 0.983x |
| H-vocab-label-large | warm | 27.720 s | 27.814 s | 0.997x |
| H-size | cold | 0.340 s | 0.338 s | 1.007x |
| H-size | warm | 0.272 s | 0.270 s | 1.005x |
| D3 | cold | 0.679 s | 0.673 s | 1.009x |
| D3 | warm | 0.446 s | 0.455 s | 0.980x |

All responses are byte-identical between arms; `H-vocab-label-large` returns 1,302,749,672 bytes.
All speedups are within ±2 %, which is run noise; a repeat run (r3) replicates the null result.
`H-vocab-label-large` is CPU-bound: cold and warm differ by only 0.1 s (27.8 s vs 27.7 s).

## Used in the colloquium talk

The talk uses the English control `H-vocab-label-large` (baseline arm medians):

1. cold 27.83 s;
2. warm 27.72 s;
3. 1,302,749,672 response bytes.

It contrasts this with the German export, whose labels must be read from disk.

## Files

- `conclusion.md`: the result: arms, correctness checksums, min/median/max per query and scenario, interpretation, and the repeat run r3.
- `manifest.md`: the run's history: planned arms, a build failure and its one-line fix, the stack rebase that forced the arm-B rebuild, and the protocol.
