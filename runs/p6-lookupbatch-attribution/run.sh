#!/bin/bash
# Part 6 (#3525) research loop, iteration 1: cost attribution of lookupBatch on
# warm files. Benchmark length rule: each trial >= 1 s, 11 interleaved trials
# after a warm-up, pinned to one core, median and min..max.
# Usage: part6-attr.sh <bench-binary> <run-dir> [core]
set -u
BIN=$1; RUN=$2; CORE=${3:-5}
export LD_LIBRARY_PATH=/local/data-ssd/stoetzem/liburing-install/lib
mkdir -p "$RUN"; cd "$RUN" || exit 1
export ATTR_DIR=/local/data-ssd/stoetzem/bench-tmp/part6-attr
mkdir -p "$ATTR_DIR"
{ echo "binary: $BIN"; sha256sum "$BIN"; uname -a; nproc; uptime; date -Is; echo "pinned core: $CORE"; } > env.txt
taskset -c "$CORE" "$BIN" -p > attr-main.txt 2>&1; echo "main rc=$?"
grep ATTR attr-main.txt > attr-summary.tsv
# Diagnostics (short trials; not used for the numbers).
export ATTR_TRIALS=1 ATTR_MIN_SECONDS=0.2
taskset -c "$CORE" perf stat -e task-clock,context-switches,cpu-migrations,page-faults -o perf-stat.txt "$BIN" -p > attr-perfstat.txt 2>&1
taskset -c "$CORE" strace -f -c -o strace-c.txt "$BIN" -p > attr-strace.txt 2>&1
taskset -c "$CORE" perf record -o perf.data -F 4999 -g "$BIN" -p > attr-perfrec.txt 2>&1
perf report -i perf.data --no-children --sort comm,dso,sym --stdio 2>/dev/null | head -150 > perf-report-flat.txt
perf report -i perf.data --no-children --sort sym --stdio -g caller,0.5,callee --percent-limit 1 2>/dev/null | head -400 > perf-report-callers.txt
rm -f perf.data
echo "WQ_DONE part6-attr"
