# #3525 synthetic rows 1–5: this PR vs #3524, >= 10 s per measurement

Micro-lane job 90006 (Ural, 2026-09-28 19:45–20:19 UTC), script `run.sh`.
Base = #3524 (`upstream-stack/06a` + the two benchmark sources, benchmark-only
commit `caf11ac4c`), variant = this PR (`upstream-stack/07a` @ `13df91418`).
Each measurement repeats its batch for >= 10 s, 10 interleaved trials per arm
after an untimed warm-up, pinned to CPU 14, ns per word, median [min–max].
Files are in the page cache. Summary: `aggregate.md`; raw: `results.csv`.
Micro lane = screening (see `env.txt`); the hybrid slowdown agrees with the
exclusive-slot attribution run in `../p6-lookupbatch-attribution` (Ural 5169).
