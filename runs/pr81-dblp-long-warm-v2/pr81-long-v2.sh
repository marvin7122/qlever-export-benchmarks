#!/bin/bash
# pr81-long-v2.sh — upstream #3529 (fork #81) stack rows: >= 10 s per
# measurement (warm query looped), 3 interleaved trials per arm, DBLP warm,
# Turtle CONSTRUCT. Base arm = previous stack part.
#   p9        upstream-stack/07d 3c9b75e97 (#3528)
#   head-off  #3529 head d95f40d44 (loop/pr81-us09 = upstream-stack/09 67cf2ee3a +
#             flag read once per export, ~64 KiB batches, bulk-copy escaping),
#             use-fast-export-stream-formatter=false
#   head-on   same binary, flag on
# Allocation arms (loop/pr81-us09-alloc 91267256d = head + QLEVER_COUNT_ALLOCATIONS=ON,
# one request each): flag off / on.
# Calibration: requests per measurement = ceil(10 s / fastest of 3 warm base
# requests), so every measurement of the base arm takes >= 10 s.
set -u
U=/local/data-ssd/stoetzem
BC=$U/bin-cache
F=use-fast-export-stream-formatter
P9=$BC/3c9b75e971c3c73fc89ad04d38ab7b7a016a4017/qlever-server
HD=$BC/d95f40d446eef1b9e999aff6c4ea91302c49960c/qlever-server
AL=$BC/91267256da7306b1b3a1fe711d0d651046a099a1/qlever-server
export LD_LIBRARY_PATH=$U/liburing-install/lib
RQ=$U/thesis/representative-queries
Q=$U/incoming/pr81-queries
RUN=$U/thesis/experiments/runs/${1:-pr81-dblp-long-warm-v2}
mkdir -p "$RUN/queries"
for b in "$P9" "$HD" "$AL"; do [ -x "$b" ] || { echo "missing binary $b" | tee "$RUN/env-before.txt"; echo "rc=3" > "$RUN/COMPLETE"; exit 3; }; done
cp $RQ/H-vocab-title-large.rq $RQ/H-size.rq $Q/H-vocab-title-xl.rq $Q/H-size-1990.rq "$RUN/queries/"
cp "$0" $U/incoming/pr81-loop-v2.py "$RUN/"
{ date -u +%FT%TZ; uptime; free -g; cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null; } > "$RUN/env-before.txt"
$U/venv/bin/python3 $U/incoming/pr81-loop-v2.py --out "$RUN" \
  --index-basename $U/dblp/dblp --trials 3 --target-seconds 10 --perf-record \
  --arm "p9=$P9" --arm "head-off=$HD,$F=false" --arm "head-on=$HD,$F=true" \
  --alloc-arm "alloc-off=$AL,$F=false" --alloc-arm "alloc-on=$AL,$F=true" \
  --query "$RUN/queries/H-vocab-title-large.rq" --query "$RUN/queries/H-vocab-title-xl.rq" \
  --query "$RUN/queries/H-size.rq" --query "$RUN/queries/H-size-1990.rq" 2>&1 | tee "$RUN/driver.log"
rc=${PIPESTATUS[0]}
{ date -u +%FT%TZ; uptime; } > "$RUN/env-after.txt"
echo "rc=$rc" | tee "$RUN/COMPLETE"
exit $rc
