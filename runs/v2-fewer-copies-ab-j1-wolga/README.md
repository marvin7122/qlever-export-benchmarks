# Export V2: fewer copies (fork PR #268), A/B, 1 query thread, measured on Wolga

## Question

Same change and query as `v2-fewer-copies-ab-j8-wolga`, with `--num-simultaneous-queries 1`, so the per-row serializer cost is not hidden by 8-way parallelism.

## Setup

As in `v2-fewer-copies-ab-j8-wolga` (Wolga, AMD Ryzen 7 3700X; same two patchelf-relinked u24 binaries; 3 interleaved trials; warm ≥ 10 s), except 1 query thread.

## Results

| # | concern | scenario | base median (min–max) | variant median (min–max) | Δ |
|---|---|---|---|---|---|
| 1 | wall, per-row cost | cold | 16.27 s (10.19–17.41) | 10.30 s (9.95–17.24) | within noise (bimodal, see caveat) |
| 2 | wall, per-row cost | warm | 16.64 s (16.58–17.25) | 16.66 s (16.11–16.77) | +0.1 %, within noise |
| 3 | process CPU | cold | 35.08 s (23.28–36.85) | 22.86 s (22.37–36.65) | within noise (bimodal) |
| 4 | process CPU | warm | 35.58 s (35.46–36.85) | 35.18 s (34.26–35.97) | −1.1 %, ranges overlap |

Every body has 674,222,797 bytes and the same row multiset as base rep 1 (`correctness.tsv`).
Gates: preflight, verify and postflight PASS.

## Caveat: co-tenant load

The cold trials are bimodal in both arms: about 10 s / 23 CPU-s with at most 5 other-user R/D processes, about 17 s / 36 CPU-s with 10–12 (`rep-load.tsv`).
All warm trials ran with 10–12 such processes.
So this run shows no measurable wall or CPU difference at 1 thread; the allocation and instruction evidence is in `v2-fewer-copies-profile-j8`.
