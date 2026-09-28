#!/usr/bin/env bash
# #3547 readahead question, Wolga DBLP counter screen (screening only, kernel
# 5.15, DBLP, 2 GiB cap). Bench-only binary bench/nowait8-hitcount 476247bc2:
# FASTPATH_STATS counters (offset pairs / words served by preadv2(RWF_NOWAIT)
# vs sent to the ring) + vocabulary-bench-fadvise-random (POSIX_FADV_RANDOM:
# no readahead beyond the requested ranges). Arms: fast path on/off x
# FADV_RANDOM off/on, warm + one cold execution each, per query.
set -u
L=/local/data-ssd/stoetzem/wolga-dblp-lane
B=$L/bin/476247bc24a11b831d3898bf7886e4cbb6cad920/qlever-server
FP=vocabulary-iouring-page-cache-fast-path FR=vocabulary-bench-fadvise-random
rc=0
for q in H-vocab-title-large H-size; do
  "$L/counter-screen/counter-screen.sh" --index dblp --server-mem-max 2G \
    --query "$L/tools/queries/$q.rq" --action turtle_export --cold \
    --arm on=$B,$FP=true,$FR=false --arm off=$B,$FP=false,$FR=false \
    --arm on-fadvrandom=$B,$FP=true,$FR=true --arm off-fadvrandom=$B,$FP=false,$FR=true \
    --out "$L/runs/nowait8-readahead-dblp-$q" || rc=1
  for log in "$L/runs/nowait8-readahead-dblp-$q"/*/*/qlever-server.log; do
    printf '%s\t%s\n' "${log#$L/runs/}" "$(grep -a FASTPATH_STATS "$log" | tail -1)"
  done > "$L/runs/nowait8-readahead-dblp-$q/fastpath-stats.tsv"
done
exit $rc
