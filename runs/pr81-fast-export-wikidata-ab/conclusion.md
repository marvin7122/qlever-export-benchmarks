# PR81 Wikidata export A/B: result (run pr81-wikidata-export-ab-r2)

Ural bench seq 3472, 2026-09-09, 15:02 UTC COMPLETE. Sixty cells, all HTTP
200 with no errors. Arm A is `stack/08-construct-batch-evaluator` at
`c2a743e06` (binary v0.6.0-73-gc2a743e06). Arm B is the same commit plus
PR 81, built from `bench/pr81-arm-b-65955219` at `659552193`
(binary v0.6.0-75-g659552193). The binaries differ and both carry io_uring
symbols. Thesis ref is `bench/pr81-wikidata-export-ab` at `00f559b7`.
Preflight load was 0.24. The CPU governor was powersave (accepted); both
arms ran interleaved under the same condition, so the comparison stands
while absolute times carry that caveat. The postflight WARN is a driver
ordering artifact: the gate checks for COMPLETE before the driver writes
it. COMPLETE exists.

## Correctness gate: passed

Every query serializes byte-identical bodies on both arms in all ten
repetitions (xxh3_128 over the full response):

- H-vocab-label-large: cf2bbf8ee8a6414f7a14ff74cec09d1b (1302749672 bytes)
- H-size: 99570bc71db44cbba660285a638b4974 (11078871 bytes)
- D3: 1fb87fd242f63044bab37ea5efc2a7a6 (11611130 bytes)

## Medians (client-observed elapsed, five reps, min/median/max)

| Query | Scenario | Baseline (s) | Variant (s) | Speedup |
|---|---|---|---|---|
| H-vocab-label-large | cold | 27.516/27.831/28.018 | 27.898/28.314/28.551 | 0.983x |
| H-vocab-label-large | warm | 27.633/27.720/27.872 | 27.594/27.814/28.264 | 0.997x |
| H-size | cold | 0.335/0.340/0.357 | 0.327/0.338/0.355 | 1.007x |
| H-size | warm | 0.270/0.272/0.274 | 0.263/0.270/0.279 | 1.005x |
| D3 | cold | 0.640/0.679/0.696 | 0.661/0.673/0.687 | 1.009x |
| D3 | warm | 0.441/0.446/0.469 | 0.444/0.455/0.465 | 0.980x |

All six speedups sit inside plus or minus two percent, which is run noise.

## Interpretation

The null result is expected from the code: `FastExportStreamFormatter`
has no production call sites in arm B. Only its header and the synthetic
microbenchmark reference it. The live export path still formats through
per-term string construction on both arms, so the PR as merged cannot move
wall-clock time. The microbenchmark gains do not transfer to the server.
Either wire the formatter into the export path or drop the end-to-end
performance claim for PR 81.

The run also confirms the regime: H-vocab-label-large is CPU-bound
(cold 27.8 s versus warm 27.7 s at identical syscall counts), so a wired
zero-allocation formatter would show up exactly here.

## Repeat run r3 (seq 3479): replicates

The measurement was restarted clean after a mid-queue stack rebase
orphaned the first attempt's arm-B binary. Same pinned commits, same
driver and queries (executed query hashes identical), run-id
`pr81-wikidata-export-ab-r3`. All sixty cells HTTP 200, and every
checksum matches r2 exactly across arms and repetitions. Medians
(base/var speedup): H-vocab-label-large cold 1.006x, warm 0.994x; H-size
cold 0.978x, warm 1.002x; D3 cold 1.030x, warm 1.033x. The D3 warm sign
flips between r2 (0.980x) and r3 (1.033x), and label-large cold flips
from 0.983x to 1.006x, which confirms the plus-or-minus three percent
band is run noise. The null result replicates.
