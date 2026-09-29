# Time blocked in pread during German-label exports (conclusion)

Run `wikidata-iouring-pread-timing`, Ural seq 3958, 2026-09-19, exit 0.
Binary: `/local/data-ssd/stoetzem/wt/bench/iouring-pre-baseline/build/qlever-server`
(`v0.5.48-36-gfdbfd14f5`, no liburing linkage).
Index: old-format Wikidata truthy backup, build 2026-08-13 (see 7.5).
Queries: `H-vocab-label-large-de.rq` against
`H-vocab-random-label-de-200k.rq`.
Driver: `scripts/profile-pread-timing.sh`. The server runs as a traced
child under `strace -T -f -e trace=pread64` (Ural refuses ptrace attach).
One discarded warmup precedes the measured warm repetition; caches are
cleared before the cold repetition.

## Method

Per repetition the driver sums the `strace -T` latencies of the trace
lines appended during the request window. ptrace stops inflate every
trapped call, so each sum is an UPPER BOUND on true blocking time.
Running everything under strace also slows the server severalfold
(sequential warm 15.5 s becomes 228 s, cold 60.6 s becomes 279 s;
compare seq 3945); ratios and call counts below are robust to that,
absolute seconds are not. The per-repetition trace
slices are gigabytes and stay on Ural; `request.tsv` holds the derived
sums and this file records their interpretation.

Seqs 3956 and 3957 failed first: 3956 attached strace to the running
server (refused), and 3957 summed zero calls (the parser read its own
heredoc) and measured warm without a warmup. Both are superseded.

## Numbers

| Window | Wall (s) | Storage reread | pread calls | pread sum (s) | Mean per call |
|---|---|---|---|---|---|
| large-de warm | 227.84 | 0 | 8,886,173 | 80.006 | 9.0 us |
| large-de cold | 279.47 | 9615 MB | 8,886,173 | 127.080 | 14.3 us |
| scatter200k warm | 41.20 | 0 | 1,554,045 | 13.015 | 8.4 us |
| scatter200k cold | 65.69 | 3103 MB | 1,554,045 | 36.268 | 23.3 us |

## Interpretation

The call counts match exactly between warm and cold: the server issues
the same 8.89 M (respectively 1.55 M) pread calls either way, so cold
does not perform different I/O, only slower I/O. Mean latency rises
from 9.0 to 14.3 us sequential and from 8.4 to 23.3 us scattered; the
scattered factor of 2.8 against the sequential factor of 1.6 shows
random disk reads where readahead cannot help. Together with the
wall-minus-CPU accounting of seq 3945 (35.9 s and 19.7 s of non-CPU
time), this proves the cold gap is time blocked inside pread.
