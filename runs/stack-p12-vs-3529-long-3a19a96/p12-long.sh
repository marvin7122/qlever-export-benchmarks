#!/usr/bin/env bash
# #3539 (upstream-stack/22) long A/B (benchmark length v2): base = #3529 binary
# (upstream-stack/09) vs #3539 flag off / on, DBLP warm, >= 10 s per
# measurement (query repeated back-to-back), 3 interleaved trials per arm (benchmark length v3),
# TTFB per request, byte-identical output check.
set -u
U=/local/data-ssd/stoetzem
export LD_LIBRARY_PATH=$U/liburing-install/lib
export BASE_SHA=67cf2ee3a7640acb2eac4438ba40b883f691f99f   # upstream-stack/09 (#3529)
export P12_SHA=3a19a966f3023c91f345aa59b6ad85ab89655bcf    # upstream-stack/22 (#3539)
export TRIALS=3
export RUN_DIR=$U/thesis/experiments/runs/stack-p12-vs-3529-long-3a19a96
for s in $BASE_SHA $P12_SHA; do
  [ -x $U/bin-cache/$s/qlever-server ] || { echo "missing binary $s"; exit 2; }
  $U/bin-cache/$s/qlever-server --version >/dev/null 2>&1 || { echo "binary $s does not start"; exit 2; }
done
mkdir -p "$RUN_DIR"
cp "$0" $U/incoming/p12-long.py "$RUN_DIR/"
printf "INDEX=DBLP\nBASE_COMMIT=%s\nVARIANT_COMMIT=%s\nBASE_REF=upstream-stack/09\nVARIANT_REF=upstream-stack/22\n" $BASE_SHA $P12_SHA > "$RUN_DIR/meta.env"
{ date -u +%FT%TZ; uptime; free -g; cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null; } > "$RUN_DIR/env-before.txt"
$U/venv/bin/python3 $U/incoming/p12-long.py
rc=$?
{ date -u +%FT%TZ; uptime; } > "$RUN_DIR/env-after.txt"
echo "rc=$rc" > "$RUN_DIR/COMPLETE"
echo "WQ_DONE p12-long rc=$rc"
exit $rc
