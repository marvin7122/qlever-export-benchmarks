#!/usr/bin/env bash
# ad-freiburg/qlever#3523 (fork #74): PrefixCompressor decode under the
# benchmark length rule (>= 10 s per measurement, 3 interleaved pinned trials, length rule v3).
# One benchmark source (benchmark/PrefixCompressorLengthBenchmark.cpp, bench
# commits on top of each tree) built by build-binaries.yml for every arm:
#   base    = #3522 upstream-stack/04 de4822b12         -> c85718a51
#   variant = #3523 upstream-stack/05 5fc8cef39 (as reviewed, before the fix)
#                                                       -> 0a139760b
#   final   = #3523 head 56f87bdf1 (inline checks, decompress unchanged from #3522)
#                                                       -> a5b06793b
# Arms per trial in rotating order; modes decompress and batch-vector on all
# arms (base has no decompressInto), decompress-into and batch-arena on the
# #3523 arms. Two word counts: 5,000 (shape of PrefixCompressorBenchmark) and
# 40,000. Each invocation: untimed checksum pass, 0.5 s warm-up, then whole
# passes until >= SECS seconds; prints ns/word and allocations/word.
set -u
U=/local/data-ssd/stoetzem
export LD_LIBRARY_PATH=$U/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
declare -A BIN=(
  [base]=$U/bin-cache/c85718a515e75d42791f6918e8024f021617ca9a/PrefixCompressorLengthBenchmark
  [variant]=$U/bin-cache/0a139760b83c88249b8e79de5fc92c5faa9a8f9a/PrefixCompressorLengthBenchmark
  [final]=$U/bin-cache/a5b06793b648be12a7a48aef3dc7e92f8b9ce500/PrefixCompressorLengthBenchmark
)
ARMS=(base variant final)
OUT=$U/thesis/experiments/runs/part4-prefixcompressor-length-v3d-lane
CORE=${CORE:-2}; SECS=${SECS:-10}; TRIALS=${TRIALS:-3}
mkdir -p "$OUT"
exec > >(tee "$OUT/driver.log") 2>&1
{
  for a in "${ARMS[@]}"; do
    echo "arm $a ${BIN[$a]}"; sha256sum "${BIN[$a]}"; "${BIN[$a]}" --version | head -1
    cat "$(dirname "${BIN[$a]}")/META" 2>/dev/null | sed "s/^/  $a META /"
  done
  echo "host $(hostname) $(date -u +%FT%TZ)"; uname -a
  lscpu | grep -E 'Model name|^CPU\(s\)'
  echo "governor core$CORE $(cat /sys/devices/system/cpu/cpu$CORE/cpufreq/scaling_governor 2>/dev/null)"
  echo "loadavg-before $(cat /proc/loadavg)"
  echo "core $CORE min_seconds $SECS trials $TRIALS"
} > "$OUT/env.txt" 2>&1
cat "$OUT/env.txt"
run() { # arm mode words trial
  local line
  line=$(taskset -c "$CORE" "${BIN[$1]}" "$2" "$3" "$SECS") || { echo "FAILED arm=$1 mode=$2 words=$3"; echo PART4V3_EXIT=1; exit 1; }
  echo "trial=$4 arm=$1 $line" | tee -a "$OUT/raw.txt"
}
echo "== warm-up (untimed, 1 s per arm and mode)"
for w in 5000 40000; do
  for a in "${ARMS[@]}"; do
    for m in decompress batch-vector; do taskset -c "$CORE" "${BIN[$a]}" $m $w 1 >/dev/null || { echo FAILED warm-up; exit 1; }; done
  done
done
for t in $(seq 1 "$TRIALS"); do
  # rotate the arm order every trial
  r=$(( (t - 1) % ${#ARMS[@]} ))
  order=("${ARMS[@]:$r}" "${ARMS[@]:0:$r}")
  for w in 5000 40000; do
    for m in decompress batch-vector decompress-into batch-arena; do
      for a in "${order[@]}"; do
        if [ "$a" = base ] && { [ $m = decompress-into ] || [ $m = batch-arena ]; }; then continue; fi
        run "$a" $m $w $t
      done
    done
  done
  echo "trial $t done $(date -u +%T) loadavg $(cut -d' ' -f1-3 /proc/loadavg)"
done
echo "loadavg-after $(cat /proc/loadavg)" >> "$OUT/env.txt"
echo PART4V3_EXIT=0
