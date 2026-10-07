# export-cpu-profile-p12: where the CPU time of the CONSTRUCT export goes

Whole-server `perf record -g` (and per-thread `perf stat`) during one measured CONSTRUCT export on Wikidata truthy (Ural), binary = export stack part 12 (`p12`, see `gate-verify-p12.log`, `sha-summary.txt`).

Queries:
- `H-vocab-label-large-de`: German names of all humans (vocabulary entries on disk).
- `H-vocab-label-large`: English names of all humans (vocabulary entries in RAM).

Each query cold (page cache evicted) and warm.

Files:
- `categories/summary.md` and `categories/*-process.md`: CPU samples grouped by category and top self symbols, classified by `categories/export-cpu-categories.py`.
- `categories/*.process.svg`: flame graphs; `*.collapsed.gz`: folded stacks.
- `p12/<query>/<cold|warm>-stat/perf-stat.log`, `thread-counts.txt`: per-thread counters.
- `p12/<query>/<cold|warm>-rec/measured.time`: wall time and bytes of the profiled execution.

Not included: the raw `perf.data` files (about 1.1 GB), kept on Ural.

Key numbers used in the colloquium slides:
- German, cold: `VocabularyInMemoryBinSearch::positionOfIndex` (binary search over the in-RAM IDs) 15.6 % self; page-cache reads (`preadv2`, kernel) 58 % of all samples.
- English, warm: `positionOfIndex` 35.0 % of all server samples (cold 35.4 %), from `perf report --sort symbol` on the raw data (the English category files could not resolve symbols).
