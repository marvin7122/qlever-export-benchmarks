# #3476 controller with the fibers of #3477 — counter screening (Wolga, DBLP 2 GiB cap)

Screening (counters, 1 counted execution per arm and scenario; Wolga, DBLP 2 GiB cap, kernel 5.15, cold = our-files-only eviction, traced).
Arms: #3476 head `95f657ab9` and #3477 head `e8a3af2ce` (fibers), each with `iouring-adaptive-batch-enabled=false|true`.
Queries: H-vocab-title-large, H-size (CONSTRUCT turtle export). Counters in `*/counters.md`, I/O pattern per arm in `*/<arm>/cold/io-pattern.json`.
