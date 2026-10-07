#!/usr/bin/env bash
# Wave reaping A/B for the colloquium final (2026-10-07, uncompressed harness).
#   base = stack part 10 (4dd60f85, as presented)
#   wave = part 10 + "IoUringPolicy: reap completions in waves" (77a41c66,
#          fork branch colloquium/final-p10-wave-reap)
# Page-cache fast path ON on both arms (the presented configuration).
# Queries: H-vocab-label-large-de (German, sequential label IDs) and
#          A-scatter-disambig-label-de (German, scattered label IDs).
# Phases:
#   0. gate both binaries (verify-qlever-binary --require-iouring) and run
#      IoUringManagerTest + VocabularyOnDiskTest of the wave commit.
#   1. timing verdict: pr-ab-multi-v2 3bin nowait copy (no load gate), 3 interleaved trials per
#      arm, cold + warm, warm loops >= 10 s; per-trial load in rep-load.tsv.
#   2. counters: 3 trials (arm order alternates), one traced cold and one
#      traced warm execution per arm: io_uring_enter count, to_submit,
#      wait calls and strace -T wait time (uring_wait.py), CPU s.
# Every harness copy sends Accept-Encoding: identity (uncompressed body).
set -u
U=/local/data-ssd/stoetzem
C=$U/bin-cache
I=$U/incoming
BASE_SHA=4dd60f853612dacc4405c713638b1726c6382877
WAVE_SHA=77a41c663a28ebfd6453fba1e23902fd94630ff8
B=$C/$BASE_SHA/qlever-server
W=$C/$WAVE_SHA/qlever-server
QSEQ=$I/pr162-queries/H-vocab-label-large-de.rq
QSCAT=$I/io-queries/A-scatter-disambig-label-de.rq
D=$I/wave-reap-final
CS=$D/cs/counter-screen.sh
R=${1:-$U/thesis/experiments/runs/wave-reap-final-p10-wikidata}
export LD_LIBRARY_PATH=$U/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
mkdir -p "$R"
cp "$0" "$R/driver.sh" 2>/dev/null
cp "$D/uring_wait.py" "$R/" 2>/dev/null
la() { echo "$(date -u +%FT%TZ) $1 loadavg=$(cut -d' ' -f1-3 /proc/loadavg) users_RD=$(ps -eo user=,stat= | awk '$1!="stoetzem" && $1!="root" && $2 ~ /^[RD]/' | wc -l) governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)" >> "$R/loadavg.log"; }
la start
md5sum "$B" "$W" > "$R/md5.txt"
bash $U/thesis/scripts/verify-qlever-binary.sh "$B" "${BASE_SHA:0:8}" --require-iouring > "$R/gate-verify-base.log" 2>&1 || { echo "ABORTED: base gate" > "$R/COMPLETE"; exit 2; }
bash $U/thesis/scripts/verify-qlever-binary.sh "$W" "${WAVE_SHA:0:8}" --require-iouring > "$R/gate-verify-wave.log" 2>&1 || { echo "ABORTED: wave gate" > "$R/COMPLETE"; exit 2; }
cmp -s "$B" "$W" && { echo "ABORTED: arms byte-identical" > "$R/COMPLETE"; exit 2; }
rc=0

# 0. unit tests of the wave commit (Wolga-built, shipped to bin-cache/<sha>/host)
for t in IoUringManagerTest VocabularyOnDiskTest; do
  TB=$C/$WAVE_SHA/host/$t
  for i in $(seq 1 120); do [ -x "$TB" ] && break; sleep 60; done
  if [ -x "$TB" ]; then
    mkdir -p "$R/gtest-wd-$t"
    (cd "$R/gtest-wd-$t" && "$TB" > "$R/gtest-$t.txt" 2>&1) || { echo "gtest FAILED" >> "$R/gtest-$t.txt"; rc=1; }
    rm -rf "$R/gtest-wd-$t"
  else
    echo "test binary missing: $TB" > "$R/gtest-$t.txt"; rc=1
  fi
done

# 1. timing verdict
la timing
"$I/pr-ab-multi-v2-3bin-nowait.sh" --pr 3476 --index wikidata --action turtle_export \
  --queries "$QSEQ,$QSCAT" --tools-dir $I/pr-ab-tools-stack10s --scenarios cold,warm \
  --reps 3 --no-adaptive --require-iouring --min-measure-s 10 \
  --base-bin "$B" --base-commit $BASE_SHA --label-base part10-4dd60f85 \
  --variant-bin "$W" --variant-commit $WAVE_SHA --label-variant part10-wave-77a41c66 \
  --run-dir "$R/timing" || rc=1

# 2. counters, 3 trials
printf 'query\ttrial\tarm\tscenario\tenter_calls\twait_calls\tenter_s\twait_s\tmean_wait_us\tsum_to_submit\tsum_min_complete\n' > "$R/uring-wait.tsv"
for t in 1 2 3; do
  if [ $((t % 2)) = 1 ]; then ARMS=(--arm base=$B --arm wave=$W); else ARMS=(--arm wave=$W --arm base=$B); fi
  for qf in "$QSEQ" "$QSCAT"; do
    q=$(basename "$qf" .rq)
    o="$R/counters/$q/t$t"
    la "counters-$q-t$t"
    "$CS" --index wikidata --query "$qf" --action turtle_export "${ARMS[@]}" \
      --cold --trace-io --trace-warm --out "$o" || rc=1
    for f in $(find "$o" -name io-trace.txt); do
      arm=$(basename "$(dirname "$(dirname "$f")")"); scen=$(basename "$(dirname "$f")")
      printf '%s\t%s\t%s\t%s\t%s\n' "$q" "$t" "$arm" "$scen" "$($U/venv/bin/python3 "$D/uring_wait.py" "$f")" >> "$R/uring-wait.tsv"
      gzip -f "$f"
    done
  done
done
la end
echo "ALL DONE rc=$rc" > "$R/COMPLETE"
exit $rc
