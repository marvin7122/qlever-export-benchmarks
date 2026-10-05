#!/usr/bin/env bash
# Part 6 rework diagnostics (not used for the timing verdict): syscall counts
# per arm for the lookupBatch groups, 2 s per measurement, strace -c -f.
# Usage: p6-rework-diag.sh <run-dir> <label=sha> ...
set -u
C=/local/data-ssd/stoetzem/bin-cache; OUT=$1; shift
export LD_LIBRARY_PATH=/local/data-ssd/stoetzem/liburing-install/lib
export TMPDIR=/local/data-ssd/stoetzem/bench-tmp/p6-rework-diag
mkdir -p "$OUT" "$TMPDIR"; cp "$0" "$OUT/run.sh"
for a in "$@"; do l=${a%%=*}; s=${a#*=}
  for g in ondisk-128 hybrid-2048; do
    VOCAB_LOOKUP_MIN_SECONDS=2 VOCAB_LOOKUP_ONLY=$g VOCAB_LOOKUP_ORDER=batch-first taskset -c 7 strace -f -c -o "$OUT/strace-$l-$g.txt" $C/$s/VocabularyBatchLookupMicroBenchmark -p > "$OUT/out-$l-$g.txt" 2>&1
    echo "$l $g: $(grep -h VOCAB_LOOKUP "$OUT/out-$l-$g.txt" | tr '\t' ' ' | tr '\n' ';') enters=$(awk '$NF=="io_uring_enter"{print $4}' "$OUT/strace-$l-$g.txt") preads=$(awk '$NF=="pread64"{print $4}' "$OUT/strace-$l-$g.txt")" | tee -a "$OUT/summary.txt"
  done
done
echo "WQ_DONE p6-rework-diag"
