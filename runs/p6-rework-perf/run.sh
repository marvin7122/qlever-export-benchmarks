#!/usr/bin/env bash
# Part 6 rework diagnostics (not timing verdict): where does one page-cache
# read cost more through io_uring than through pread? perf record -g of the
# ondisk-128 group (5 s single lookups + 5 s lookupBatch) for one arm.
# Usage: p6-rework-perf.sh <run-dir> <sha>
set -u
C=/local/data-ssd/stoetzem/bin-cache; OUT=$1; S=$2
export LD_LIBRARY_PATH=/local/data-ssd/stoetzem/liburing-install/lib
export TMPDIR=/local/data-ssd/stoetzem/bench-tmp/p6-rework-perf
mkdir -p "$OUT" "$TMPDIR"; cp "$0" "$OUT/run.sh"
for g in ondisk-128; do
  VOCAB_LOOKUP_MIN_SECONDS=5 VOCAB_LOOKUP_ONLY=$g VOCAB_LOOKUP_ORDER=single-first taskset -c 7 perf record -F 2999 -g -o "$TMPDIR/perf.data" $C/$S/VocabularyBatchLookupMicroBenchmark -p > "$OUT/out-$g.txt" 2>&1
  perf report -i "$TMPDIR/perf.data" --children --sort sym --stdio -g none --percent-limit 0.7 2>/dev/null | head -150 > "$OUT/perf-children-$g.txt"
  perf report -i "$TMPDIR/perf.data" --no-children --sort sym --stdio -g none --percent-limit 0.4 2>/dev/null | head -150 > "$OUT/perf-self-$g.txt"
  perf report -i "$TMPDIR/perf.data" --children --sort sym --stdio -G --percent-limit 3 --symbol-filter=io_uring_enter 2>/dev/null | head -300 > "$OUT/perf-uring-callgraph-$g.txt"
  rm -f "$TMPDIR/perf.data"
done
echo "WQ_DONE p6-rework-perf"
