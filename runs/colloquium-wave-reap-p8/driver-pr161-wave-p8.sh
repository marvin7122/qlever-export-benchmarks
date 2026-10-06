#!/usr/bin/env bash
# Colloquium candidate: stack part 8 (51269ab4, #3547 page-cache fast path on)
# + wave reaping (fork branch colloquium/wave-reap-on-p8 49487dc5, the wave
# reap of fork PR #161 without its opt-in controller).
#   1. counters: cold run under strace (io_uring_enter count, to_submit and
#      min_complete distributions) + LD_PRELOAD preadv2 NOWAIT/EAGAIN
#      (= page-cache misses sent to the ring); warm untraced.
#   2. cold perf profile (perf record -g, untraced), base vs wave.
#   3. timing verdict: pr-ab-multi-v2, 10 interleaved reps, cold + warm (>= 10 s).
# Queries: H-vocab-random-label-de-400k (scattered, ring-heavy, target),
# H-vocab-random-label-de-200k, H-vocab-label-large-de (regression guards).
set -u
U=/local/data-ssd/stoetzem
C=$U/bin-cache
BASE_SHA=51269ab4bf895211983287d1086c0a700ea43c86
WAVE_SHA=49487dc53051e2aa3657beeafdce58d1f275434b
B=$C/$BASE_SHA/qlever-server
W=$C/$WAVE_SHA/qlever-server
Q400=$U/incoming/pr161-queries/H-vocab-random-label-de-400k.rq
Q200=$U/incoming/pr162-queries/H-vocab-random-label-de-200k.rq
QLD=$U/incoming/pr162-queries/H-vocab-label-large-de.rq
CS=$U/incoming/pr161-counter-screen/counter-screen.sh
R=$U/thesis/experiments/runs/colloquium-wave-reap-p8
export LD_LIBRARY_PATH=$U/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
mkdir -p "$R"
for i in $(seq 1 180); do [ -x "$W" ] && break; sleep 60; done
[ -x "$W" ] || { echo "ABORTED: wave binary missing" > "$R/COMPLETE"; exit 2; }
bash $U/thesis/scripts/verify-qlever-binary.sh "$B" "${BASE_SHA:0:8}" --require-iouring > "$R/gate-verify-base.log" 2>&1 || { echo "ABORTED: base gate" > "$R/COMPLETE"; exit 2; }
bash $U/thesis/scripts/verify-qlever-binary.sh "$W" "${WAVE_SHA:0:8}" --require-iouring > "$R/gate-verify-wave.log" 2>&1 || { echo "ABORTED: wave gate" > "$R/COMPLETE"; exit 2; }
rc=0
TB=$C/$WAVE_SHA/IoUringManagerTest
for i in $(seq 1 60); do [ -x "$TB" ] && break; sleep 60; done
if [ -x "$TB" ]; then
  (cd "$(dirname "$TB")" && "$TB" > "$R/gtest-IoUringManagerTest.txt" 2>&1) || { echo "gtest FAILED" >> "$R/gtest-IoUringManagerTest.txt"; rc=1; }
else
  echo "test binary missing" > "$R/gtest-IoUringManagerTest.txt"
fi
for qf in "$Q400" "$Q200" "$QLD"; do
  q=$(basename "$qf" .rq)
  "$CS" --index wikidata --query "$qf" --action turtle_export \
    --arm base=$B --arm wave=$W --cold --trace-io --out "$R/counters/$q" || rc=1
done
for qf in "$Q400" "$QLD"; do
  q=$(basename "$qf" .rq)
  "$CS" --index wikidata --query "$qf" --action turtle_export \
    --arm base=$B --arm wave=$W --cold --no-warm --perf-record --out "$R/profile/$q" || rc=1
  for a in base wave; do
    pd="$R/profile/$q/$a/cold"
    if [ -s "$pd/perf.data" ]; then
      perf report -i "$pd/perf.data" --stdio --no-children -g none --sort dso,sym --percent-limit 0.3 2>/dev/null \
        | grep -E '^ +[0-9]' | head -60 > "$pd/report-top.txt"
      perf report -i "$pd/perf.data" --stdio --no-children -g none --sort dso 2>/dev/null \
        | grep -E '^ +[0-9]' > "$pd/report-dso.txt"
      perf report -i "$pd/perf.data" --stdio --children -g none --sort sym 2>/dev/null \
        | grep -E 'io_uring|IoUring|drain|wait_cqe|get_cqe|preadv|lookupBatch|addBatch' | head -40 > "$pd/report-children-io.txt"
      rm -f "$pd/perf.data"
    fi
  done
done
"$U/incoming/pr-ab-multi-v2.sh" --pr 161 --index wikidata --action turtle_export \
  --queries "$Q400,$Q200,$QLD" \
  --tools-dir $U/incoming/pr-ab-tools-stack10s --scenarios cold,warm --reps 10 --no-adaptive \
  --require-iouring --min-measure-s 10 \
  --base-bin "$B" --variant-bin "$W" --base-commit $BASE_SHA --variant-commit $WAVE_SHA \
  --label-base part8-51269ab4 --label-variant wave-reap-49487dc5 \
  --run-dir "$R/timing" || rc=1
echo ALL DONE rc=$rc > "$R/COMPLETE"
exit $rc
