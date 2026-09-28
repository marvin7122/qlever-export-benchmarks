# Wolga DBLP lane calibration (2026-09-28)

Host `wolga`: AMD Ryzen 7 3700X (8c/16t), 125 GiB RAM shared with co-tenants
(another user's qlever-server ~53 GB RSS and a 100 % CPU process during the runs), Ubuntu 22.04,
Linux 5.15.0-187, ext4 on md RAID. The DBLP index is byte-identical to Ural's
(same meta-data.json and vocabulary.codebooks md5).

Setup: harness copy `lane-tools/pr-ab-multi-v2.sh` (Ural's pr-ab-multi-v2 with three
Wolga changes: our-files-only cold eviction, a co-tenant load gate before every arm,
no `--` token in the systemd-run prefix), 3 interleaved reps per arm, driver pinned to
CPUs 0-7, qlever-server capped by `systemd-run --user --scope -p MemoryMax=2G -p MemorySwapMax=0`.
Cold = one execution after `posix_fadvise(DONTNEED)` on every `dblp.*` index file
(fincore-verified, no global drop_caches). Warm = query looped back-to-back >= 10 s.
Binaries = the same u24 files as on Ural (gcc 13.3, liburing 2.15), started through
the bundled Ubuntu 24.04 loader (`lane-tools/bin/<sha>/qlever-server` wrapper).
Per-trial loadavg / MemAvailable: `load-per-trial.tsv`.

| # | concern | query | scenario | Wolga DBLP 2 GiB cap | Ural Wikidata |
|---|---|---|---|---|---|
| 1 | #3526 vs #3525: cold I/O wait | H-vocab-title-large | cold | 4.795 -> 1.255 s (-73.8 %) | -57 % |
| 2 | same | H-size | cold | 3.920 -> 1.292 s (-67.1 %) | -57 % |
| 3 | #3526 vs #3525: ring cost on page-cache hits | H-vocab-title-large | warm | 0.539 -> 1.150 s (+113.5 %) | +13.5 % |
| 4 | same | H-size | warm | 0.755 -> 1.075 s (+42.5 %) | +13.5 % |
| 5 | #3547 vs #3526: fast path | H-vocab-title-large | warm | 1.153 -> 0.387 s (-66.4 %) | -17.6 % |
| 6 | same | H-size | warm | 1.065 -> 0.718 s (-32.6 %) | -17.6 % |
| 7 | same | H-vocab-title-large | cold | 1.232 -> 0.724 s (-41.3 %) | -15.5 % |
| 8 | same | H-size | cold | 1.292 -> 1.141 s (-11.7 %) | -15.5 % |
| 9 | #3547 fast path off vs #3526 | both | both | -0.7 % .. +1.0 % (parity) | - |

Verdict: the proxy reproduces the sign of every Wikidata effect but not its size
(ring cost on page-cache hits is 3-8x larger on this kernel). Wolga rows are screening
only (direction + mechanism counters). Companion run dirs:
`wolga-dblp-cap2g-3547-vs-3526` (rows 5-9), `wolga-dblp-cap2g-counters-p6-p7-p8`
(counter screening), `wolga-dblp-cap2g-iopattern-heads` (per-head counters + traced
cold I/O pattern, `*/cold/io-pattern.json`, raw strace logs `io-trace.txt.zst`).
