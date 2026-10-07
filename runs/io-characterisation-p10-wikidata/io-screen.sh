#!/usr/bin/env bash
# I/O characterisation screen (2026-10-06): which cold Wikidata exports make the
# export thread wait in io_uring_enter (gate >= 10 % of wall, closed-PR audit §3)?
# One binary, labelled stack12/07d: the old export-stack part-10 head 4dd60f85
# (#3528 before the 2026-10-06 restructure). Tag stack12/07d = b05dc9d4 is a
# descendant whose src diff is only comments + a resize_and_overwrite backport
# refactor (src/backports/string.h, src/util/FsstCompressor.h comment).
# Usage (ural-wq bench entry): io-screen.sh <run-dir> [trials] [plan.json]
set -u
U=/local/data-ssd/stoetzem
D=$U/incoming/io-screen
Q=$U/incoming/io-queries
P10=4dd60f853612dacc4405c713638b1726c6382877
BIN=$U/bin-cache/$P10/qlever-server
OUT=${1:?run dir}
TRIALS=${2:-3}
PLAN=${3:-$D/plan.json}
export LD_LIBRARY_PATH=$U/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
mkdir -p "$OUT"
echo "stack12/07d (binary built from old part-10 head ${P10}; tag stack12/07d=b05dc9d4 differs only in comments and a string.h backport refactor)" > "$OUT/binary-label.txt"
cp "$0" "$D/io_screen.py" "$D/io_counts_preload.c" "$D/summarize.py" "$PLAN" "$OUT/"
mkdir -p "$OUT/queries"; cp "$Q"/*.rq "$OUT/queries/"
env_snap() {
  { date -u +%FT%TZ; uname -r; echo "loadavg: $(cat /proc/loadavg)"
    echo "governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
    echo "cpu0 MHz: $(grep -m1 MHz /proc/cpuinfo)"; free -g
    echo "other users R/D:"; ps -eo user:20,stat,pid,comm --no-headers | awk '$1!="stoetzem" && $1!="root" && $2 ~ /^[RD]/'
  } > "$1" 2>&1
}
env_snap "$OUT/env-before.txt"
bash $U/thesis/scripts/verify-qlever-binary.sh "$BIN" "${P10:0:8}" --require-iouring > "$OUT/gate-verify-p10.log" 2>&1 \
  || { echo "binary gate failed"; cat "$OUT/gate-verify-p10.log"; exit 2; }
cc -shared -fPIC -O2 -o "$OUT/libio_counts.so" "$D/io_counts_preload.c" -ldl > "$OUT/preload-build.log" 2>&1 \
  || { echo "preload build failed"; exit 2; }
SCOPE=()
if ! systemd-run --user --scope --quiet --collect -p MemoryMax=1G true > "$OUT/scope-probe.log" 2>&1; then
  echo "systemd-run --user --scope unavailable; running without scopes (caps skipped)" | tee -a "$OUT/scope-probe.log"
  SCOPE=(--no-scope)
  $U/venv/bin/python3 -c "import json,sys; p=json.load(open('$PLAN')); json.dump([c for c in p if not c.get('cap_headroom_gib')], open('$OUT/plan-noscope.json','w'))"
  PLAN=$OUT/plan-noscope.json
fi
$U/venv/bin/python3 "$D/io_screen.py" --index-basename $U/wikidata/wikidata --binary "$BIN" \
  --plan "$PLAN" --trials "$TRIALS" --evict-cmd $U/clear-caches --preload-so "$OUT/libio_counts.so" \
  --calibrate-query $Q/B-humans-label-5lang.rq "${SCOPE[@]}" --out "$OUT"
rc=$?
env_snap "$OUT/env-after.txt"
$U/venv/bin/python3 "$D/summarize.py" "$OUT" > /dev/null 2>&1 || echo "summarize failed"
exit $rc
