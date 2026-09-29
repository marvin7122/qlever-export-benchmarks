# #3539 long A/B

base 67cf2ee3a7640acb2eac4438ba40b883f691f99f (upstream-stack/09, #3529), #3539 3a19a966f3023c91f345aa59b6ad85ab89655bcf (upstream-stack/22); DBLP, warm page cache, QLever result cache cleared before every request; 3 interleaved trials per arm; one measurement = query repeated for >= 10 s; servers pinned to CPUs 0-7, client to CPU 12; host ural.

| query | arm | trials | requests/measurement | time per query median (min–max) | TTFB median of medians (min–max) | Δ time vs base | Δ TTFB vs base | byte-identical |
|---|---|---|---|---|---|---|---|---|
| H-vocab-title-large-select | base | 3 | 24–25 | 0.4299 s (0.4008–0.4299) | 103.46 ms (100.40–103.48) |  |  | yes |
| H-vocab-title-large-select | off | 3 | 24–24 | 0.4227 s (0.4207–0.4254) | 102.44 ms (102.18–102.51) | -1.68 % | -0.99 % | yes |
| H-vocab-title-large-select | on | 3 | 24–24 | 0.4244 s (0.4236–0.4248) | 38.23 ms (38.10–38.32) | -1.28 % | -63.05 % | yes |
| H-vocab-title-large-select | on vs off | | | +0.41 % (ranges overlap) | -62.68 % (ranges disjoint) | | | |
| H-size-select | base | 3 | 5–5 | 2.4557 s (2.4240–2.4863) | 158.83 ms (157.70–158.97) |  |  | yes |
| H-size-select | off | 3 | 5–5 | 2.4078 s (2.3315–2.4536) | 159.13 ms (157.70–159.29) | -1.95 % | +0.19 % | yes |
| H-size-select | on | 3 | 5–5 | 2.4399 s (2.4140–2.4672) | 111.72 ms (111.14–112.10) | -0.64 % | -29.66 % | yes |
| H-size-select | on vs off | | | +1.33 % (ranges overlap) | -29.79 % (ranges disjoint) | | | |
| R2-select | base | 3 | 15–15 | 0.7037 s (0.6851–0.7065) | 123.76 ms (123.65–124.40) |  |  | yes |
| R2-select | off | 3 | 15–15 | 0.6805 s (0.6788–0.7041) | 123.49 ms (123.01–123.54) | -3.29 % | -0.22 % | yes |
| R2-select | on | 3 | 15–15 | 0.6892 s (0.6711–0.6983) | 74.11 ms (73.69–74.53) | -2.06 % | -40.12 % | yes |
| R2-select | on vs off | | | +1.27 % (ranges overlap) | -39.98 % (ranges disjoint) | | | |
