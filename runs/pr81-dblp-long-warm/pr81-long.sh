#!/bin/bash
# pr81-long.sh — PR #81 / upstream #3529: >= 10 s per measurement, 10 interleaved
# trials per arm, warm, DBLP. Base arm = previous stack part (#3528,
# upstream-stack/07d 390a8de69). Arms (flag = use-fast-export-stream-formatter):
#   p9        upstream-stack/07d 390a8de69 (#3528, no flag)
#   up-off    upstream-stack/09  13ccf0a8f (#3529 head: one string per triple,
#             flag read per triple) flag off
#   up-on     same, flag on
#   cand-off  loop/pr81-us09     cdf36d4d9 (13ccf0a8f + flag read once per export,
#             ~64 KiB batches, bulk-copy escaping) flag off
#   cand-on   same, flag on
# Allocation arms (loop/pr81-us09-alloc 69f6d6ab3 = cand + QLEVER_COUNT_ALLOCATIONS=ON):
#   flag off / on.
# An arm whose binary is missing is dropped (logged); if the candidate is
# missing, the old-chain same-binary arms esc-off/esc-on (loop/pr81-escape
# ee089e9f) are used instead.
set -u
U=/local/data-ssd/stoetzem
BC=$U/bin-cache
F=use-fast-export-stream-formatter
P9=$BC/390a8de69badf543e11620b4bbb53e7fcd0b8594/qlever-server
UP=$BC/13ccf0a8fa3c10d63661912c69d81a8ed5f9bc37/qlever-server
CA=$BC/cdf36d4d98cf38492f9b04afabad7fdc35218cb2/qlever-server
AL=$BC/69f6d6ab3785704d9d4140069b268863bb6b3c0e/qlever-server
BE=$BC/ee089e9f04242346729b1566faa9c8fa80a44ab5/qlever-server
export LD_LIBRARY_PATH=$U/liburing-install/lib
RQ=$U/thesis/representative-queries
Q=$U/incoming/pr81-queries
RUN=$U/thesis/experiments/runs/${1:-pr81-dblp-long-warm}
mkdir -p "$RUN/queries"
cp $RQ/H-vocab-title-large.rq $RQ/H-size.rq $Q/H-vocab-title-xl.rq $Q/H-size-1990.rq "$RUN/queries/"
cp "$0" $U/incoming/pr81-loop.py "$RUN/"
{ date -u +%FT%TZ; uptime; free -g; cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null; } > "$RUN/env-before.txt"
ARMS=(--arm "p9=$P9" --arm "up-off=$UP,$F=false" --arm "up-on=$UP,$F=true")
if [ -x "$CA" ]; then
  ARMS+=(--arm "cand-off=$CA,$F=false" --arm "cand-on=$CA,$F=true")
else
  echo "candidate binary missing: $CA; using esc-off/esc-on ($BE)" | tee -a "$RUN/env-before.txt"
  ARMS+=(--arm "esc-off=$BE,$F=false" --arm "esc-on=$BE,$F=true")
fi
ALLOC=()
if [ -x "$AL" ]; then
  ALLOC=(--alloc-arm "alloc-off=$AL,$F=false" --alloc-arm "alloc-on=$AL,$F=true")
else
  echo "alloc binary missing: $AL; no allocation arms" | tee -a "$RUN/env-before.txt"
fi
for b in "$P9" "$UP"; do [ -x "$b" ] || { echo "missing base binary $b"; echo "rc=3" > "$RUN/COMPLETE"; exit 3; }; done
$U/venv/bin/python3 $U/incoming/pr81-loop.py --out "$RUN" \
  --index-basename $U/dblp/dblp --trials 10 --target-seconds 10 --perf-record \
  "${ARMS[@]}" "${ALLOC[@]}" \
  --query "$RUN/queries/H-vocab-title-large.rq" --query "$RUN/queries/H-vocab-title-xl.rq" \
  --query "$RUN/queries/H-size.rq" --query "$RUN/queries/H-size-1990.rq" 2>&1 | tee "$RUN/driver.log"
rc=${PIPESTATUS[0]}
{ date -u +%FT%TZ; uptime; } > "$RUN/env-after.txt"
echo "rc=$rc" | tee "$RUN/COMPLETE"
exit $rc
