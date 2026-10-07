# Wave reaping of io_uring completions vs stack part 10 (verdict, uncompressed)

## Question

Does reaping `io_uring` completions in waves change the German-label exports in the configuration presented in the colloquium (stack part 10, page-cache fast path on)?
Upstream PR: ad-freiburg/qlever#3476. Fork PR: marvin7122/qlever#270.

## Setup

1. Machine: Ural (shared; loadavg during the run in `loadavg.log` and `timing/rep-load.tsv`), Wikidata truthy, `on-disk-compressed` vocabulary.
2. Arms: `base` = part 10 `4dd60f85` (md5 `b549c44c`), `wave` = part 10 + wave reaping `77a41c66` (md5 `ad66397f`), both built on Wolga (`md5.txt`, `gate-verify-*.log`).
   Page-cache fast path ON on both arms (default).
3. Queries: `H-vocab-label-large-de` (German labels, sequential IDs) and `A-scatter-disambig-label-de` (German labels of disambiguation pages, scattered IDs).
4. Timing (`timing/`): 3 interleaved trials per arm, order alternating; cold = `drop_caches` before every run; warm = warm-up, then the query looped >= 10 s, per-query mean.
   Responses are uncompressed (`Accept-Encoding: identity`).
5. Counters (`counters/<query>/t<1..3>/`): 3 trials, arm order alternating; one cold and one warm execution per arm under `strace -T` (counts only, never timing).
   `uring-wait.tsv` sums the `io_uring_enter` calls and their in-kernel time; "wait" calls are those with `min_complete > 0` (`uring_wait.py`).
6. Driver: `driver.sh`, run 2026-10-07 15:51–18:33 UTC (Ural seq 5356), timing driver `pr-ab-multi-v2-3bin-nowait` (no load gate; load logged per trial).

## Result: timing (median [min–max] s, `timing/conclusion.md`)

| # | concern | query | scenario | part 10 | + wave | Δ | verdict |
|---|---|---|---|---|---|---|---|
| 1 | sequential reads, cold | label-large-de | cold | 34.08 [33.90–34.15] | 33.81 [33.79–34.29] | −0.8 % | no change |
| 2 | sequential reads, warm | label-large-de | warm | 19.55 [16.76–23.43] | 21.19 [20.51–23.57] | +8.4 % | ranges overlap (noise) |
| 3 | scattered reads, cold | scatter-disambig-de | cold | 13.93 [13.90–14.13] | 13.69 [13.58–13.74] | −1.7 % | disjoint, but < 2 %: no change |
| 4 | scattered reads, warm | scatter-disambig-de | warm | 3.22 [3.02–3.29] | 2.87 [2.84–2.88] | −10.9 % | faster, but load-confounded (see Noise) |

All bodies are byte-identical across arms (`timing/correctness.tsv`).

## Result: io_uring counters (cold, per trial t1 / t2 / t3)

| # | concern | query | arm | `io_uring_enter` calls | in-kernel time of the calls (s) | server CPU (s) |
|---|---|---|---|---|---|---|
| 5 | syscalls, sequential | label-large-de | part 10 | 154 995 / 154 659 / 155 818 | 5.08 / 5.02 / 4.28 | 174.7 / 190.3 / 169.3 |
| 6 | syscalls, sequential | label-large-de | + wave | 9 549 / 9 543 / 9 550 | 0.99 / 0.91 / 1.00 | 190.6 / 168.5 / 185.4 |
| 7 | syscalls, scattered | scatter-disambig-de | part 10 | 468 899 / 469 386 / 468 663 | 6.68 / 6.50 / 6.98 | 38.1 / 38.8 / 40.4 |
| 8 | syscalls, scattered | scatter-disambig-de | + wave | 3 871 / 3 869 / 3 878 | 0.79 / 0.79 / 0.79 | 32.6 / 30.6 / 30.3 |

1. Almost all calls are submissions (`min_complete = 0`); calls that block for completions are rare (0–26 per execution, at most 0.01 s), so the saved time is submission and syscall overhead, not waiting.
2. Warm executions make 0–29 k calls, depending on how much of the vocabulary another tenant had evicted (`uring-wait.tsv`); they are not comparable across trials.
3. The CPU column comes from traced runs; for the sequential query the second arm of each trial was the slower one (order effect), so it shows no difference.

## Tests

1. `IoUringManagerTest` (77a41c66): 45/45 passed (`gtest-IoUringManagerTest.txt`).
2. `VocabularyOnDiskTest` (77a41c66, Wolga u24 build): the binary was not on Ural when the run reached its test step, so `gtest-VocabularyOnDiskTest.txt` only records "DEFERRED".
   It was run separately on a btrfs disk: 19/19 passed (`gtest-VocabularyOnDiskTest-separate.txt`).

## Noise

1. Every trial except the last one ran with load1 > 5 (`timing/rep-load.tsv`, verdict `kept-noisy`); the cold sequential trials ran at load1 17–20.
2. Row 4: the base trials ran at max load1 18.6 / 7.0 / 6.8, the wave trials at 12.6 / 7.2 / 4.7, and two base counter runs show 10 k ring reads in a "warm" run, so part of the warm vocabulary had been evicted.
   Treat −10.9 % as an upper bound, not as the effect of wave reaping.
