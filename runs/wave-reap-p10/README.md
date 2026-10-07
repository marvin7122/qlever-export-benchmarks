# Wave reaping of io_uring completions vs stack part 10 (screening, compressed harness)

## Question

Does reaping `io_uring` completions in waves (`77a41c66`) change the German-label exports against stack part 10 (`4dd60f85`)?
Upstream PR: ad-freiburg/qlever#3476. Fork PR: marvin7122/qlever#270.

## Setup

1. Machine: Ural (shared), Wikidata truthy index, `on-disk-compressed` vocabulary.
2. Arms: `base` = part 10 `4dd60f85`, `wave` = part 10 + wave reaping `77a41c66`.
   Both with the page-cache fast path ON (default) and OFF (`vocabulary-iouring-page-cache-fast-path=false`, every read goes through the ring).
3. Queries: `H-vocab-label-large-de` (sequential label IDs), `H-vocab-random-label-de-200k` (scattered).
4. Timing: 10 interleaved reps per arm, cold (`drop_caches` before every run) and warm (query looped >= 10 s).
5. Counters: one traced cold and one traced warm execution per arm (`counters/`), LD_PRELOAD call counts and strace I/O pattern.
6. Driver: `driver-wave-reap-p10.sh`, run 2026-10-06 17:21–22:17 UTC, loadavg 3–19 (`loadavg.log`).

**Caveat:** this run predates the harness fix of 2026-10-07 13:25 UTC.
The harness sent httpx's default `Accept-Encoding`, so QLever deflate-compressed every response on one thread.
The I/O counters are not affected; the timings include compression.
The uncompressed re-measure is `../wave-reap-final-p10-wikidata`.

## Result

Timing (median [min–max] s, `timing-fp-*/conclusion.md`):

| # | concern | query | scenario | fast path | part 10 | + wave | Δ |
|---|---|---|---|---|---|---|---|
| 1 | presented config | label-large-de | cold | on | 35.10 [26.62–35.43] | 35.06 [25.13–35.43] | −0.1 % (noise) |
| 2 | presented config | label-large-de | warm | on | 20.23 [16.79–24.52] | 22.27 [16.38–24.94] | +10.1 % (noise) |
| 3 | presented config | random-200k | cold | on | 11.39 [10.24–14.26] | 11.87 [10.65–14.15] | +4.2 % (noise) |
| 4 | presented config | random-200k | warm | on | 4.02 [3.95–4.78] | 4.09 [3.96–4.71] | +1.6 % (noise) |
| 5 | ring-only reads | label-large-de | cold | off | 32.24 [30.33–37.90] | 28.13 [27.17–33.43] | −12.7 % (overlap) |
| 6 | ring-only reads | label-large-de | warm | off | 27.46 [19.78–28.61] | 24.02 [16.40–24.78] | −12.5 % (overlap) |
| 7 | ring-only reads | random-200k | cold | off | 11.43 [10.29–14.38] | 10.52 [10.12–13.92] | −7.9 % (overlap) |
| 8 | ring-only reads | random-200k | warm | off | 5.49 [5.39–5.57] | 5.33 [5.23–5.39] | −3.0 % (faster) |

`io_uring_enter` calls per execution (`counters/*/counters.md`, strace):

| # | concern | query | scenario | fast path | part 10 | + wave |
|---|---|---|---|---|---|---|
| 1 | presented config | label-large-de | cold | on | 156 233 | 9 534 |
| 2 | ring-only reads | label-large-de | warm | off | 6 625 868 | 35 302 |
| 3 | ring-only reads | label-large-de | cold | off | 6 626 928 | 46 220 |

All bodies are byte-identical across arms. `IoUringManagerTest`: 45/45 passed (`gtest-IoUringManagerTest.txt`).
