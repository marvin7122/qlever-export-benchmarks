# Wolga night screening, 2026-09-28/29 (SCREENING ONLY)

These runs are counter and direction screening on Wolga. The setup:
- DBLP index, with the server capped at MemoryMax=2G.
- counter-screen: one counted execution per arm and scenario, with byte-identical output checked across arms.
- The drivers are the scripts in this directory. Wolga seqs: 261 for `night1-*`, 263 for `night2-*`.
- Every arm uses a u24 binary started through the bundled loader.

The Wolga lane calibration is in `wolga-dblp-cap2g-3526-vs-3525/WOLGA-LANE.md`. It shows that signs transfer from this setup and sizes do not.

The CPU-second columns are single samples, with noise of about ±0.3 s. Read them as direction only. The counters (pread, preadv2 NOWAIT/EAGAIN, ring submits, bytes) are exact.

The preload `io_uring_enter` column reads 0 because liburing issues that syscall directly. Use the ring submit count or the traced `io-pattern.json` (`*/cold/io-trace.txt.zst`) instead.
