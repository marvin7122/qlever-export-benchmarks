# Reading German labels through io_uring: master vs compressed-tier routing

## Question

German labels live in the on-disk, compressed part of the Wikidata vocabulary.
On master the export reads them one blocking read at a time.
The routing branch (fork PR #172; upstream it is part of #3526, stack part 7) sends these reads through an io_uring ring instead.
This run asks how much faster the German-label exports get, cold and warm, with identical output.

## Setup

1. Machine: `ural`, AMD Ryzen 7 3700X (8 cores, 16 threads), 125 GiB RAM (about 135 GB), index on a software RAID (`/dev/md1`) of two Samsung 990 PRO NVMe SSDs, Linux 7.0.0-28 (`env.txt`).
2. Index: Wikidata truthy, 8.2 billion triples, the upgraded new-format index (`index-for-upgrade-new-format`, see `env.txt`).
3. Queries (Turtle CONSTRUCT export, German labels); the `.rq` files are not in this directory, the same queries are in other run directories:
   - sequential (`large-de`): every human with a German label, [`H-vocab-label-large-de.rq`](../../queries/wikidata/H-vocab-label-large-de.rq), 504,927,346 response bytes;
   - scattered (`scatter200k-de`): German labels of 200,000 entities given in a `VALUES` list, [`H-vocab-random-label-de-200k.rq`](../nowait8-readahead-fadv-random/queries/H-vocab-random-label-de-200k.rq), 19,297,737 response bytes.
4. Arms (two binaries):
   - master: `master` at `2f24c39c9` (`v0.6.0-116-g2f24c39c9`), blocking reads;
   - routing: `feat/iouring-compressed-routing` at `54134bb35` (`v0.6.0-117-g54134bb35`), compressed-tier reads through the io_uring ring.
5. Scenarios:
   - cold: the OS page cache is dropped before each repetition;
   - warm: the index files are already in the OS page cache (0 bytes read from disk).
6. Repetitions: per arm and query 2 cold and 1 warm; cold numbers are the mean of the two cold repetitions.

## Result

| query | scenario | master | routing | speedup |
|---|---|---:|---:|---:|
| sequential | cold, mean of 2 | 60.70 s | 25.49 s | 2.38x |
| sequential | warm, 1 rep | 15.17 s | 17.64 s | 0.86x |
| scattered | cold, mean of 2 | 27.56 s | 11.19 s | 2.46x |
| scattered | warm, 1 rep | 5.01 s | 5.10 s | 0.98x |

Cold, the sequential export reads 9.62 GB from disk on master (9,615,794,176 bytes) and 9.44 GB with routing.
Responses are byte-identical between arms (SHA-256 per workload and rep).
Routing turns I/O wait into CPU work: it wins by a factor 2.4 when the export waits on storage.
Warm there is no wait to remove, and decompression costs CPU, so the sequential export gets slower.

## Used in the colloquium talk

1. German sequential export, cold: 60.70 s (master, mean of 2) vs 25.49 s (routing).
2. German sequential export, warm: 15.17 s vs 17.64 s.
3. Scattered export, cold: 27.56 s vs 11.19 s; warm: 5.01 s vs 5.10 s.
4. 9.6 GB read from disk per cold sequential export (master).
5. Arms: master `2f24c39c` vs routing `54134bb35`.

## Files

- `conclusion.md`: the result: scope, validity checks, cold and warm tables, I/O wait and CPU shares, interpretation.
- `results-summary.txt`: one line per request and arm: HTTP status, wall seconds, response bytes, SHA-256 of the body, bytes read from disk (`rbytes`).
- `env.txt`: binaries and their version strings, index path, kernel, date.
  Its `base_commit` field (`7bd97790`) matches neither arm's version string; the arms are identified by the version strings.
- `flame-diff.svg`: differential CPU flame graph, master vs routing, cold scattered export.
