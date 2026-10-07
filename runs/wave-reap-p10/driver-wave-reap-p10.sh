#!/usr/bin/env bash
# Wave reaping (fork perf/wave-reap-on-p10, 77a41c66) vs stack part 10 head
# (upstream-stack/07d, 4dd60f85), with the page-cache fast path ON (default)
# and OFF (vocabulary-iouring-page-cache-fast-path=false on BOTH arms; the
# ring-heavy case where every vocabulary read goes through the ring).
#   1. counters: one traced execution per arm, cold AND warm (strace window =
#      the counted execution only): io_uring_enter count, to_submit
#      distribution, preadv2 NOWAIT/EAGAIN, CPU s, byte identity.
#   2. timing fast path ON:  pr-ab-multi-v2, 10 interleaved reps, cold + warm.
#   3. timing fast path OFF: same, both arms with the fast path off.
#   4. cycles screen: 3 untraced trials per arm (perf stat cycles/instructions,
#      cold + warm), 4 arms (on/off x base/wave).
# Queries: H-vocab-random-label-de-200k (scattered), H-vocab-label-large-de
# (sequential). loadavg is logged before and after every phase.
set -u
U=/local/data-ssd/stoetzem
C=$U/bin-cache
BASE_SHA=4dd60f853612dacc4405c713638b1726c6382877
WAVE_SHA=77a41c663a28ebfd6453fba1e23902fd94630ff8
B=$C/$BASE_SHA/qlever-server
W=$C/$WAVE_SHA/qlever-server
FPOFF=vocabulary-iouring-page-cache-fast-path=false
Q200=$U/incoming/pr162-queries/H-vocab-random-label-de-200k.rq
QLD=$U/incoming/pr162-queries/H-vocab-label-large-de.rq
CS=$U/incoming/wave-reap-p10/cs/counter-screen.sh
R=$U/thesis/experiments/runs/wave-reap-p10
export LD_LIBRARY_PATH=$U/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
mkdir -p "$R"
cp "$0" "$R/driver-wave-reap-p10.sh" 2>/dev/null
la() { echo "$(date -u +%FT%TZ) $1 loadavg=$(cut -d' ' -f1-3 /proc/loadavg) users_RD=$(ps -eo user=,stat= | awk '$1!="stoetzem" && $1!="root" && $2 ~ /^[RD]/' | wc -l) governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null) MHz=$(awk '/MHz/{s+=$4;n++}END{printf "%.0f", s/n}' /proc/cpuinfo)" >> "$R/loadavg.log"; }
la start
for i in $(seq 1 240); do [ -x "$W" ] && break; sleep 60; done
[ -x "$W" ] || { echo "ABORTED: wave binary missing" > "$R/COMPLETE"; exit 2; }
bash $U/thesis/scripts/verify-qlever-binary.sh "$B" "${BASE_SHA:0:8}" --require-iouring > "$R/gate-verify-base.log" 2>&1 || { echo "ABORTED: base gate" > "$R/COMPLETE"; exit 2; }
bash $U/thesis/scripts/verify-qlever-binary.sh "$W" "${WAVE_SHA:0:8}" --require-iouring > "$R/gate-verify-wave.log" 2>&1 || { echo "ABORTED: wave gate" > "$R/COMPLETE"; exit 2; }
cmp -s "$B" "$W" && { echo "ABORTED: arms byte-identical" > "$R/COMPLETE"; exit 2; }
rc=0
TB=$C/$WAVE_SHA/IoUringManagerTest
for i in $(seq 1 60); do [ -x "$TB" ] && break; sleep 60; done
if [ -x "$TB" ]; then
  (cd "$(dirname "$TB")" && "$TB" > "$R/gtest-IoUringManagerTest.txt" 2>&1) || { echo "gtest FAILED" >> "$R/gtest-IoUringManagerTest.txt"; rc=1; }
else
  echo "test binary missing" > "$R/gtest-IoUringManagerTest.txt"
fi
ARMS=(--arm base=$B --arm wave=$W --arm base-fpoff=$B,$FPOFF --arm wave-fpoff=$W,$FPOFF)

# 1. traced counters (counts only)
for qf in "$Q200" "$QLD"; do
  q=$(basename "$qf" .rq)
  la "counters-$q"
  "$CS" --index wikidata --query "$qf" --action turtle_export "${ARMS[@]}" \
    --cold --trace-io --trace-warm --out "$R/counters/$q" || rc=1
  find "$R/counters/$q" -name io-trace.txt -exec gzip -f {} \;
done

# 2./3. timing verdict rows
AB=(--pr 161 --index wikidata --action turtle_export --queries "$Q200,$QLD"
    --tools-dir $U/incoming/pr-ab-tools-stack10s --scenarios cold,warm --reps 10 --no-adaptive
    --require-iouring --min-measure-s 10
    --base-bin "$B" --variant-bin "$W" --base-commit $BASE_SHA --variant-commit $WAVE_SHA)
la timing-fp-on
"$U/incoming/pr-ab-multi-v2.sh" "${AB[@]}" --label-base part10-4dd60f85 --label-variant wave-reap-77a41c66 \
  --run-dir "$R/timing-fp-on" || rc=1
la timing-fp-off
"$U/incoming/pr-ab-multi-v2.sh" "${AB[@]}" --base-rp $FPOFF --variant-rp $FPOFF \
  --label-base part10-4dd60f85-fpoff --label-variant wave-reap-77a41c66-fpoff \
  --run-dir "$R/timing-fp-off" || rc=1

# 4. cycles screen (untraced, 3 trials)
for t in 1 2 3; do
  for qf in "$Q200" "$QLD"; do
    q=$(basename "$qf" .rq)
    la "cycles-$q-t$t"
    "$CS" --index wikidata --query "$qf" --action turtle_export "${ARMS[@]}" \
      --cold --out "$R/cycles/$q/t$t" || rc=1
  done
done
la end
echo ALL DONE rc=$rc > "$R/COMPLETE"
exit $rc
