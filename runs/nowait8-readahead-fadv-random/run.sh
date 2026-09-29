#!/usr/bin/env bash
# #3547 (fork #236, upstream-stack/07b-nowait) readahead question: why is the
# cold German export faster with the page-cache fast path (-14/-15 %)?
# Bench-only binary bench/nowait8-hitcount 476247bc2 = the part + process-wide
# counters (FASTPATH_STATS line on stderr: offset pairs / words served by
# preadv2(RWF_NOWAIT) vs submitted to the ring, preadv2 outcomes) + runtime
# parameter vocabulary-bench-fadvise-random (POSIX_FADV_RANDOM on the vocabulary
# files: no readahead beyond the requested ranges).
# Call 1 (cold, 3 interleaved reps, benchmark length v3): base = fast path off + FADV_RANDOM,
#   variant = fast path on + FADV_RANDOM, variant2 = fast path on, normal.
#   If readahead explains the cold gain, the on/off gain vanishes under
#   FADV_RANDOM and the cold hit share of the German export collapses.
# Call 2 (cold + warm, 3 reps): base = fast path off, variant = on (normal),
#   for the hit shares warm vs cold and same-session timings.
set -u
S=/local/data-ssd/stoetzem/incoming/pr-ab-multi-v5.sh
TOOLS=/local/data-ssd/stoetzem/incoming/pr-ab-tools-fast5
RUNS=/local/data-ssd/stoetzem/thesis/experiments/runs
C=/local/data-ssd/stoetzem/bin-cache
B=476247bc24a11b831d3898bf7886e4cbb6cad920
FP=vocabulary-iouring-page-cache-fast-path
FR=vocabulary-bench-fadvise-random
common=(--pr 3547 --index wikidata --action turtle_export --require-iouring
  --tools-dir "$TOOLS" --no-adaptive --min-measure-s 10
  --queries H-vocab-label-large-de.rq,H-vocab-random-label-de-200k.rq
  --base-bin "$C/$B/qlever-server" --variant-bin "$C/$B/qlever-server"
  --base-commit "$B" --variant-commit "$B")
rc=0
taskset -c 0-7 "$S" "${common[@]}" --scenarios cold --reps 3 \
  --base-rp $FP=false --base-rp $FR=true --label-base fastpath-off-fadv-random \
  --variant-rp $FP=true --variant-rp $FR=true --label-variant fastpath-on-fadv-random \
  --variant2-rp $FP=true --variant2-rp $FR=false --label-variant2 fastpath-on-normal \
  --run-dir "$RUNS/nowait8-readahead-fadv-random" || rc=1
# Call 2 (hit shares warm vs cold) moved to Wolga 256 (DBLP counter screen).
# Hit shares: last cumulative FASTPATH_STATS line of every server log in the
# run dir (layout-independent: path, then the counters).
for r in nowait8-readahead-fadv-random; do
  out="$RUNS/$r/fastpath-stats.tsv"
  printf 'log\tstats\n' > "$out"
  find "$RUNS/$r" -name '*.log' -type f | sort | while read -r log; do
    line=$(grep -a FASTPATH_STATS "$log" | tail -1)
    [ -n "$line" ] && printf '%s\t%s\n' "${log#"$RUNS/$r/"}" "${line#FASTPATH_STATS }" >> "$out"
  done
done
exit $rc
