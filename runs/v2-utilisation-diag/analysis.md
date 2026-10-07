# V2 utilisation diagnosis — v2-utilisation-diag

## Phase A — wall time vs query threads (original binary 87f57674)

Per trial: cold = mean of 2 cold queries; warm = mean of the looped warm queries (>= 10 s). Table: median over trials (min–max).

| config | scenario | arm | trials | wall s | TTFB s | server CPU s | avg busy cores | speedup vs 1 thr | efficiency | other CPU (cores) |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | cold | v2 | 3 | 16.94 (14.59–17.23) | 0.01 (0.01–0.01) | 35.3 (31.9–36.6) | 2.12 (2.08–2.18) | 1.00x | 100% | 12.86 (10.37–13.16) |
| 2 | cold | v2 | 3 | 11.12 (9.50–11.45) | 0.01 (0.01–0.01) | 34.3 (31.1–35.6) | 3.11 (3.09–3.28) | 1.52x | 76% | 12.79 (8.92–12.80) |
| 4 | cold | v2 | 3 | 8.70 (7.88–9.59) | 0.01 (0.01–0.01) | 35.4 (34.6–35.8) | 4.07 (3.78–4.40) | 1.95x | 49% | 11.83 (11.47–12.14) |
| 8 | cold | v2 | 3 | 9.92 (9.78–12.65) | 0.01 (0.01–0.01) | 35.3 (35.3–35.6) | 3.60 (2.81–3.61) | 1.71x | 21% | 12.31 (12.20–13.15) |
| 8pin | cold | v2 | 3 | 7.81 (7.44–7.94) | 0.01 (0.01–0.01) | 35.0 (34.9–35.2) | 4.51 (4.51–4.70) | 2.17x | 27% | 11.29 (11.15–11.37) |
| 1 | warm | v2 | 3 | 16.65 (14.03–16.87) | 0.00 (0.00–0.00) | 35.1 (30.7–35.5) | 2.13 (2.08–2.19) | 1.00x | 100% | 13.16 (9.45–13.50) |
| 2 | warm | v2 | 3 | 10.78 (8.95–11.06) | 0.00 (0.00–0.00) | 33.6 (29.4–34.7) | 3.14 (3.12–3.29) | 1.54x | 77% | 12.42 (7.87–12.62) |
| 4 | warm | v2 | 3 | 8.11 (6.63–8.21) | 0.00 (0.00–0.00) | 34.5 (34.0–34.7) | 4.34 (4.22–5.14) | 2.05x | 51% | 11.57 (10.01–11.74) |
| 8 | warm | v2 | 3 | 8.67 (7.89–10.55) | 0.00 (0.00–0.00) | 35.0 (34.9–35.4) | 4.04 (3.36–4.49) | 1.92x | 24% | 11.83 (11.43–12.60) |
| 8 | warm | base | 3 | 34.08 (32.24–36.73) | 0.15 (0.14–0.15) | 36.8 (34.9–39.4) | 1.08 (1.07–1.08) | - | - | 11.60 (11.21–12.42) |
| 8pin | warm | v2 | 3 | 6.13 (5.70–6.52) | 0.00 (0.00–0.00) | 34.3 (33.4–34.4) | 5.60 (5.14–6.04) | 2.72x | 34% | 10.32 (9.88–10.72) |

Amdahl fit (cold): T(N) = 7.46 s serial + 8.98 s / N  → serial fraction 45% of the 1-thread time, max speedup 2.2x; Karp–Flatt e: N=2: 0.31, N=4: 0.35, N=8: 0.53

Amdahl fit (warm): T(N) = 6.44 s serial + 9.85 s / N  → serial fraction 40% of the 1-thread time, max speedup 2.5x; Karp–Flatt e: N=2: 0.30, N=4: 0.32, N=8: 0.45

## Phase B — phase breakdown and utilisation (diag binary)

### 1 thread(s), cold (cold)

- client: wall 13.21 s, TTFB 0.01 s, 674 MB, server CPU 29.1 s
- morsels: 1422 executions (751 on 1 pool threads, 671 inline on coordinator), 11,643,064 rows, morsel CPU 24.7 s, morsel wall 24.7 s (off-CPU inside morsels 0%), 2122 ns CPU/row
- header chunk yielded at +0.026 s; coordinator resumed after header at +0.026 s; first morsel consumed at +1.544 s
- coordinator: waited 11.58 s in consumeNextResult (incl. inline morsels), 0.08 s suspended in co_yield (finalize + hand-off to the HTTP stream queue)

| phase | start s | dur s | busy morsels (mean) | max | queued morsels (mean) | coordinator on-CPU | pool on-CPU (cores) | other on-CPU | runqueue wait (cores) |
|---|---|---|---|---|---|---|---|---|---|
| request → V2 enter (parse, plan) | 0.00 | 0.03 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.38 | 0.00 |
| enter → lazy result handle | 0.03 | 0.00 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| submit phase (lazy join + morsel planning on coordinator) | 0.03 | 1.52 | 0.98 | 1.0 | 700.2 | 0.01 | 0.99 | 2.58 | 0.14 |
| drain phase (consume + emit) | 1.54 | 11.67 | 1.99 | 2.0 | 674.2 | 1.00 | 1.00 | 0.03 | 0.01 |
| tail (last emit → client done) | 13.21 | 0.00 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |

- other thread states during submit+drain (sampled): S:futex_do_wait 72%, S:ep_poll 23%, R:0 4%, S:0 0%, R:futex_do_wait 0%
- pool (morsel helpers) thread states during submit+drain (sampled): R:0 100%, S:futex_do_wait 0%
- coordinator thread states during submit+drain (sampled): R:0 89%, S:futex_do_wait 11%, R:futex_do_wait 0%

- perf counters other: task-clock 4.0 s, 4.03 GHz effective, IPC 2.02
- perf counters coordinator: task-clock 11.7 s, 4.08 GHz effective, IPC 0.52

### 1 thread(s), warm (warm)

- client: wall 13.69 s, TTFB 0.00 s, 674 MB, server CPU 30.1 s
- morsels: 1422 executions (746 on 1 pool threads, 676 inline on coordinator), 11,643,064 rows, morsel CPU 25.7 s, morsel wall 25.8 s (off-CPU inside morsels 0%), 2211 ns CPU/row
- header chunk yielded at +0.008 s; coordinator resumed after header at +0.008 s; first morsel consumed at +1.506 s
- coordinator: waited 12.10 s in consumeNextResult (incl. inline morsels), 0.08 s suspended in co_yield (finalize + hand-off to the HTTP stream queue)

| phase | start s | dur s | busy morsels (mean) | max | queued morsels (mean) | coordinator on-CPU | pool on-CPU (cores) | other on-CPU | runqueue wait (cores) |
|---|---|---|---|---|---|---|---|---|---|
| request → V2 enter (parse, plan) | 0.00 | 0.01 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| enter → lazy result handle | 0.01 | 0.00 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| submit phase (lazy join + morsel planning on coordinator) | 0.01 | 1.50 | 0.99 | 1.0 | 723.6 | 0.01 | 0.98 | 2.53 | 0.17 |
| drain phase (consume + emit) | 1.51 | 12.19 | 1.99 | 2.0 | 683.7 | 1.00 | 1.00 | 0.03 | 0.01 |
| tail (last emit → client done) | - | - | | | | | | | |

- other thread states during submit+drain (sampled): S:futex_do_wait 73%, S:ep_poll 23%, R:0 4%, S:0 0%, R:futex_do_wait 0%
- pool (morsel helpers) thread states during submit+drain (sampled): R:0 100%, S:futex_do_wait 0%
- coordinator thread states during submit+drain (sampled): R:0 89%, S:futex_do_wait 11%, S:0 0%

- perf counters other: task-clock 3.9 s, 4.03 GHz effective, IPC 2.07
- perf counters coordinator: task-clock 12.2 s, 4.09 GHz effective, IPC 0.50

### 1 thread(s), warm (warm-cs)

- client: wall 13.55 s, TTFB 0.00 s, 674 MB, server CPU 29.7 s
- morsels: 1422 executions (757 on 1 pool threads, 665 inline on coordinator), 11,643,064 rows, morsel CPU 25.5 s, morsel wall 25.5 s (off-CPU inside morsels 0%), 2189 ns CPU/row
- header chunk yielded at +0.009 s; coordinator resumed after header at +0.009 s; first morsel consumed at +1.439 s
- coordinator: waited 12.03 s in consumeNextResult (incl. inline morsels), 0.08 s suspended in co_yield (finalize + hand-off to the HTTP stream queue)

| phase | start s | dur s | busy morsels (mean) | max | queued morsels (mean) | coordinator on-CPU | pool on-CPU (cores) | other on-CPU | runqueue wait (cores) |
|---|---|---|---|---|---|---|---|---|---|
| request → V2 enter (parse, plan) | 0.00 | 0.01 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| enter → lazy result handle | 0.01 | 0.00 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| submit phase (lazy join + morsel planning on coordinator) | 0.01 | 1.43 | 0.98 | 1.0 | 691.3 | 0.00 | 0.97 | 2.64 | 0.13 |
| drain phase (consume + emit) | 1.44 | 12.11 | 1.99 | 2.0 | 694.2 | 1.00 | 1.00 | 0.03 | 0.01 |
| tail (last emit → client done) | - | - | | | | | | | |

- other thread states during submit+drain (sampled): S:futex_do_wait 73%, S:ep_poll 23%, R:0 4%, S:0 0%, R:futex_do_wait 0%
- pool (morsel helpers) thread states during submit+drain (sampled): R:0 100%, S:futex_do_wait 0%
- coordinator thread states during submit+drain (sampled): R:0 89%, S:futex_do_wait 11%

### 2 thread(s), cold (cold)

- client: wall 8.31 s, TTFB 0.01 s, 674 MB, server CPU 27.6 s
- morsels: 1422 executions (1014 on 2 pool threads, 408 inline on coordinator), 11,643,064 rows, morsel CPU 23.2 s, morsel wall 23.2 s (off-CPU inside morsels 0%), 1990 ns CPU/row
- header chunk yielded at +0.029 s; coordinator resumed after header at +0.029 s; first morsel consumed at +1.526 s
- coordinator: waited 6.69 s in consumeNextResult (incl. inline morsels), 0.09 s suspended in co_yield (finalize + hand-off to the HTTP stream queue)

| phase | start s | dur s | busy morsels (mean) | max | queued morsels (mean) | coordinator on-CPU | pool on-CPU (cores) | other on-CPU | runqueue wait (cores) |
|---|---|---|---|---|---|---|---|---|---|
| request → V2 enter (parse, plan) | 0.00 | 0.03 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.28 | 0.00 |
| enter → lazy result handle | 0.03 | 0.00 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| submit phase (lazy join + morsel planning on coordinator) | 0.03 | 1.50 | 1.97 | 2.0 | 655.7 | 0.01 | 1.96 | 2.61 | 0.09 |
| drain phase (consume + emit) | 1.53 | 6.79 | 2.98 | 3.0 | 624.2 | 1.00 | 1.99 | 0.04 | 0.02 |
| tail (last emit → client done) | - | - | | | | | | | |

- other thread states during submit+drain (sampled): S:futex_do_wait 71%, S:ep_poll 22%, R:0 6%, S:0 0%, D:folio_wait_bit_common 0%
- pool (morsel helpers) thread states during submit+drain (sampled): R:0 100%, S:futex_do_wait 0%
- coordinator thread states during submit+drain (sampled): R:0 82%, S:futex_do_wait 18%, S:0 0%

- perf counters other: task-clock 4.0 s, 4.02 GHz effective, IPC 2.03
- perf counters coordinator: task-clock 6.8 s, 4.10 GHz effective, IPC 0.55

### 2 thread(s), warm (warm)

- client: wall 8.21 s, TTFB 0.00 s, 674 MB, server CPU 27.4 s
- morsels: 1422 executions (1006 on 2 pool threads, 416 inline on coordinator), 11,643,064 rows, morsel CPU 22.9 s, morsel wall 22.9 s (off-CPU inside morsels 0%), 1967 ns CPU/row
- header chunk yielded at +0.007 s; coordinator resumed after header at +0.007 s; first morsel consumed at +1.555 s
- coordinator: waited 6.56 s in consumeNextResult (incl. inline morsels), 0.09 s suspended in co_yield (finalize + hand-off to the HTTP stream queue)

| phase | start s | dur s | busy morsels (mean) | max | queued morsels (mean) | coordinator on-CPU | pool on-CPU (cores) | other on-CPU | runqueue wait (cores) |
|---|---|---|---|---|---|---|---|---|---|
| request → V2 enter (parse, plan) | 0.00 | 0.01 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| enter → lazy result handle | 0.01 | 0.00 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| submit phase (lazy join + morsel planning on coordinator) | 0.01 | 1.55 | 1.98 | 2.0 | 662.8 | 0.00 | 1.97 | 2.58 | 0.07 |
| drain phase (consume + emit) | 1.56 | 6.66 | 2.98 | 3.0 | 651.4 | 1.00 | 2.00 | 0.04 | 0.01 |
| tail (last emit → client done) | - | - | | | | | | | |

- other thread states during submit+drain (sampled): S:futex_do_wait 71%, S:ep_poll 22%, R:0 6%, S:0 0%, R:futex_do_wait 0%
- pool (morsel helpers) thread states during submit+drain (sampled): R:0 100%, S:futex_do_wait 0%
- coordinator thread states during submit+drain (sampled): R:0 81%, S:futex_do_wait 18%, S:0 0%

- perf counters other: task-clock 4.0 s, 3.82 GHz effective, IPC 2.10
- perf counters coordinator: task-clock 6.7 s, 4.10 GHz effective, IPC 0.57

### 4 thread(s), cold (cold)

- client: wall 5.16 s, TTFB 0.01 s, 674 MB, server CPU 28.2 s
- morsels: 1422 executions (1213 on 4 pool threads, 209 inline on coordinator), 11,643,064 rows, morsel CPU 24.0 s, morsel wall 24.0 s (off-CPU inside morsels 0%), 2060 ns CPU/row
- header chunk yielded at +0.027 s; coordinator resumed after header at +0.027 s; first morsel consumed at +1.435 s
- coordinator: waited 3.60 s in consumeNextResult (incl. inline morsels), 0.13 s suspended in co_yield (finalize + hand-off to the HTTP stream queue)

| phase | start s | dur s | busy morsels (mean) | max | queued morsels (mean) | coordinator on-CPU | pool on-CPU (cores) | other on-CPU | runqueue wait (cores) |
|---|---|---|---|---|---|---|---|---|---|
| request → V2 enter (parse, plan) | 0.00 | 0.03 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| enter → lazy result handle | 0.03 | 0.00 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| submit phase (lazy join + morsel planning on coordinator) | 0.03 | 1.41 | 3.93 | 4.0 | 577.5 | 0.01 | 3.90 | 2.63 | 0.17 |
| drain phase (consume + emit) | 1.44 | 3.73 | 4.95 | 5.0 | 569.7 | 1.00 | 3.99 | 0.08 | 0.03 |
| tail (last emit → client done) | - | - | | | | | | | |

- other thread states during submit+drain (sampled): S:futex_do_wait 74%, S:ep_poll 18%, R:0 7%, S:0 1%, R:futex_do_wait 0%
- pool (morsel helpers) thread states during submit+drain (sampled): R:0 100%, S:futex_do_wait 0%
- coordinator thread states during submit+drain (sampled): R:0 73%, S:futex_do_wait 27%

- perf counters other: task-clock 3.8 s, 3.87 GHz effective, IPC 2.23
- perf counters coordinator: task-clock 3.7 s, 4.10 GHz effective, IPC 0.52

### 4 thread(s), warm (warm)

- client: wall 5.14 s, TTFB 0.00 s, 674 MB, server CPU 28.3 s
- morsels: 1422 executions (1193 on 4 pool threads, 229 inline on coordinator), 11,643,064 rows, morsel CPU 24.0 s, morsel wall 24.0 s (off-CPU inside morsels 0%), 2062 ns CPU/row
- header chunk yielded at +0.008 s; coordinator resumed after header at +0.008 s; first morsel consumed at +1.453 s
- coordinator: waited 3.57 s in consumeNextResult (incl. inline morsels), 0.12 s suspended in co_yield (finalize + hand-off to the HTTP stream queue)

| phase | start s | dur s | busy morsels (mean) | max | queued morsels (mean) | coordinator on-CPU | pool on-CPU (cores) | other on-CPU | runqueue wait (cores) |
|---|---|---|---|---|---|---|---|---|---|
| request → V2 enter (parse, plan) | 0.00 | 0.01 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| enter → lazy result handle | 0.01 | 0.00 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| submit phase (lazy join + morsel planning on coordinator) | 0.01 | 1.45 | 3.96 | 4.0 | 598.7 | 0.01 | 3.94 | 2.61 | 0.14 |
| drain phase (consume + emit) | 1.45 | 3.69 | 4.96 | 5.0 | 559.7 | 0.99 | 3.99 | 0.08 | 0.03 |
| tail (last emit → client done) | - | - | | | | | | | |

- other thread states during submit+drain (sampled): S:futex_do_wait 74%, S:ep_poll 18%, R:0 7%, S:0 0%, R:futex_do_wait 0%
- pool (morsel helpers) thread states during submit+drain (sampled): R:0 100%, S:futex_do_wait 0%
- coordinator thread states during submit+drain (sampled): R:0 72%, S:futex_do_wait 27%, R:srso_return_thunk 0%

- perf counters other: task-clock 3.8 s, 3.85 GHz effective, IPC 2.19
- perf counters coordinator: task-clock 3.7 s, 4.10 GHz effective, IPC 0.57

### 8 thread(s), cold (cold)

- client: wall 3.51 s, TTFB 0.01 s, 674 MB, server CPU 32.8 s
- morsels: 1422 executions (1349 on 8 pool threads, 73 inline on coordinator), 11,643,064 rows, morsel CPU 28.4 s, morsel wall 29.0 s (off-CPU inside morsels 2%), 2438 ns CPU/row
- header chunk yielded at +0.027 s; coordinator resumed after header at +0.027 s; first morsel consumed at +1.871 s
- coordinator: waited 1.38 s in consumeNextResult (incl. inline morsels), 0.25 s suspended in co_yield (finalize + hand-off to the HTTP stream queue)

| phase | start s | dur s | busy morsels (mean) | max | queued morsels (mean) | coordinator on-CPU | pool on-CPU (cores) | other on-CPU | runqueue wait (cores) |
|---|---|---|---|---|---|---|---|---|---|
| request → V2 enter (parse, plan) | 0.00 | 0.03 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.43 | 0.00 |
| enter → lazy result handle | 0.03 | 0.00 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| submit phase (lazy join + morsel planning on coordinator) | 0.03 | 1.84 | 7.88 | 8.0 | 346.5 | 0.00 | 7.61 | 2.04 | 1.09 |
| drain phase (consume + emit) | 1.87 | 1.65 | 8.78 | 9.0 | 381.6 | 0.91 | 7.91 | 0.22 | 0.45 |
| tail (last emit → client done) | - | - | | | | | | | |

- other thread states during submit+drain (sampled): S:futex_do_wait 77%, S:ep_poll 12%, R:0 10%, S:0 0%, R:futex_do_wait 0%
- pool (morsel helpers) thread states during submit+drain (sampled): R:0 99%, S:futex_do_wait 1%
- coordinator thread states during submit+drain (sampled): S:futex_do_wait 53%, R:0 47%, S:0 1%

- perf counters other: task-clock 3.8 s, 4.06 GHz effective, IPC 2.09
- perf counters coordinator: task-clock 1.5 s, 4.09 GHz effective, IPC 0.47

### 8 thread(s), cold (cold-cs)

- client: wall 3.52 s, TTFB 0.00 s, 674 MB, server CPU 33.1 s
- morsels: 1422 executions (1359 on 8 pool threads, 63 inline on coordinator), 11,643,064 rows, morsel CPU 28.4 s, morsel wall 29.0 s (off-CPU inside morsels 2%), 2441 ns CPU/row
- header chunk yielded at +0.014 s; coordinator resumed after header at +0.014 s; first morsel consumed at +2.051 s
- coordinator: waited 1.15 s in consumeNextResult (incl. inline morsels), 0.30 s suspended in co_yield (finalize + hand-off to the HTTP stream queue)

| phase | start s | dur s | busy morsels (mean) | max | queued morsels (mean) | coordinator on-CPU | pool on-CPU (cores) | other on-CPU | runqueue wait (cores) |
|---|---|---|---|---|---|---|---|---|---|
| request → V2 enter (parse, plan) | 0.00 | 0.01 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| enter → lazy result handle | 0.01 | 0.00 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| submit phase (lazy join + morsel planning on coordinator) | 0.01 | 2.04 | 7.90 | 8.0 | 373.6 | 0.00 | 7.72 | 1.97 | 0.97 |
| drain phase (consume + emit) | 2.05 | 1.48 | 8.70 | 9.0 | 329.2 | 0.88 | 7.85 | 0.24 | 0.71 |
| tail (last emit → client done) | - | - | | | | | | | |

- other thread states during submit+drain (sampled): S:futex_do_wait 76%, S:ep_poll 12%, R:0 11%, S:0 1%, R:futex_do_wait 0%
- pool (morsel helpers) thread states during submit+drain (sampled): R:0 99%, S:futex_do_wait 1%
- coordinator thread states during submit+drain (sampled): S:futex_do_wait 57%, R:0 42%, S:0 1%

### 8 thread(s), warm (warm)

- client: wall 3.40 s, TTFB 0.00 s, 674 MB, server CPU 32.2 s
- morsels: 1422 executions (1353 on 8 pool threads, 69 inline on coordinator), 11,643,064 rows, morsel CPU 27.7 s, morsel wall 28.1 s (off-CPU inside morsels 1%), 2383 ns CPU/row
- header chunk yielded at +0.008 s; coordinator resumed after header at +0.008 s; first morsel consumed at +1.902 s
- coordinator: waited 1.19 s in consumeNextResult (incl. inline morsels), 0.28 s suspended in co_yield (finalize + hand-off to the HTTP stream queue)

| phase | start s | dur s | busy morsels (mean) | max | queued morsels (mean) | coordinator on-CPU | pool on-CPU (cores) | other on-CPU | runqueue wait (cores) |
|---|---|---|---|---|---|---|---|---|---|
| request → V2 enter (parse, plan) | 0.00 | 0.01 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| enter → lazy result handle | 0.01 | 0.00 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| submit phase (lazy join + morsel planning on coordinator) | 0.01 | 1.89 | 7.92 | 8.0 | 364.7 | 0.00 | 7.78 | 2.00 | 0.94 |
| drain phase (consume + emit) | 1.90 | 1.50 | 8.74 | 9.0 | 344.5 | 0.90 | 7.88 | 0.24 | 0.57 |
| tail (last emit → client done) | - | - | | | | | | | |

- other thread states during submit+drain (sampled): S:futex_do_wait 77%, S:ep_poll 12%, R:0 10%, S:0 1%, R:futex_do_wait 0%
- pool (morsel helpers) thread states during submit+drain (sampled): R:0 99%, S:futex_do_wait 1%
- coordinator thread states during submit+drain (sampled): S:futex_do_wait 58%, R:0 40%, S:0 2%

- perf counters other: task-clock 3.9 s, 3.91 GHz effective, IPC 2.14
- perf counters coordinator: task-clock 1.4 s, 4.09 GHz effective, IPC 0.49

### 8 thread(s), warm (warm-cs)

- client: wall 3.47 s, TTFB 0.00 s, 674 MB, server CPU 32.7 s
- morsels: 1422 executions (1367 on 8 pool threads, 55 inline on coordinator), 11,643,064 rows, morsel CPU 28.2 s, morsel wall 28.5 s (off-CPU inside morsels 1%), 2419 ns CPU/row
- header chunk yielded at +0.009 s; coordinator resumed after header at +0.009 s; first morsel consumed at +2.032 s
- coordinator: waited 1.11 s in consumeNextResult (incl. inline morsels), 0.31 s suspended in co_yield (finalize + hand-off to the HTTP stream queue)

| phase | start s | dur s | busy morsels (mean) | max | queued morsels (mean) | coordinator on-CPU | pool on-CPU (cores) | other on-CPU | runqueue wait (cores) |
|---|---|---|---|---|---|---|---|---|---|
| request → V2 enter (parse, plan) | 0.00 | 0.01 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| enter → lazy result handle | 0.01 | 0.00 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| submit phase (lazy join + morsel planning on coordinator) | 0.01 | 2.02 | 7.91 | 8.0 | 335.0 | 0.00 | 7.73 | 1.93 | 0.94 |
| drain phase (consume + emit) | 2.03 | 1.44 | 8.71 | 9.0 | 320.9 | 0.85 | 7.96 | 0.26 | 0.87 |
| tail (last emit → client done) | - | - | | | | | | | |

- other thread states during submit+drain (sampled): S:futex_do_wait 77%, S:ep_poll 12%, R:0 11%, S:0 0%, R:futex_do_wait 0%
- pool (morsel helpers) thread states during submit+drain (sampled): R:0 99%, S:futex_do_wait 1%
- coordinator thread states during submit+drain (sampled): S:futex_do_wait 58%, R:0 41%, S:0 1%, R:futex_do_wait 1%

### 8 thread(s), warm (warm-cyc)

- client: wall 3.48 s, TTFB 0.00 s, 674 MB, server CPU 32.8 s
- morsels: 1422 executions (1352 on 8 pool threads, 70 inline on coordinator), 11,643,064 rows, morsel CPU 28.3 s, morsel wall 28.9 s (off-CPU inside morsels 2%), 2431 ns CPU/row
- header chunk yielded at +0.008 s; coordinator resumed after header at +0.008 s; first morsel consumed at +1.776 s
- coordinator: waited 1.39 s in consumeNextResult (incl. inline morsels), 0.29 s suspended in co_yield (finalize + hand-off to the HTTP stream queue)

| phase | start s | dur s | busy morsels (mean) | max | queued morsels (mean) | coordinator on-CPU | pool on-CPU (cores) | other on-CPU | runqueue wait (cores) |
|---|---|---|---|---|---|---|---|---|---|
| request → V2 enter (parse, plan) | 0.00 | 0.01 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| enter → lazy result handle | 0.01 | 0.00 | 0.00 | 0.0 | 0.0 | 0.00 | 0.00 | 0.00 | 0.00 |
| submit phase (lazy join + morsel planning on coordinator) | 0.01 | 1.77 | 7.89 | 8.0 | 406.9 | 0.00 | 7.55 | 2.20 | 0.91 |
| drain phase (consume + emit) | 1.78 | 1.71 | 8.75 | 9.0 | 388.4 | 0.89 | 7.97 | 0.20 | 0.64 |
| tail (last emit → client done) | - | - | | | | | | | |

- other thread states during submit+drain (sampled): S:futex_do_wait 77%, S:ep_poll 12%, R:0 10%, S:0 1%, R:futex_do_wait 0%
- pool (morsel helpers) thread states during submit+drain (sampled): R:0 99%, S:futex_do_wait 1%
- coordinator thread states during submit+drain (sampled): S:futex_do_wait 51%, R:0 49%

## Phase C — client / socket check (8 threads, warm, original binary)

| client | trials | wall s | TTFB s | client CPU s | throughput MB/s |
|---|---|---|---|---|---|
| curl | 3 | 2.82 (2.82–6.47) | 0.00 (0.00–0.00) | 0.19 (0.16–0.21) | 239 (119–239) |
| py | 3 | 6.95 (6.95–8.21) | 1.50 (1.47–2.27) | 1.99 (1.98–2.06) | 97 (82–97) |
| curlpin | 3 | 2.89 (2.84–2.93) | 0.00 (0.00–0.00) | 0.21 (0.19–0.24) | 234 (230–238) |

- curl: socket busy 0.27 s, rwnd_limited 0.01 s, sndbuf_limited 0.00 s (median of last tcp_info samples)
- curlpin: socket busy 0.28 s, rwnd_limited 0.00 s, sndbuf_limited 0.00 s (median of last tcp_info samples)
- py: socket busy 0.29 s, rwnd_limited 0.00 s, sndbuf_limited 0.00 s (median of last tcp_info samples)

