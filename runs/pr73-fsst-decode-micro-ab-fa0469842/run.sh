#!/usr/bin/env bash
# Part 3/17 (fork #73, upstream #3522): microbenchmark A/B, base = part 2
# (bench/pr73-ab-base = upstream-stack/03 + bench-only files), variant = part 3
# (bench/pr73-ab-variant = upstream-stack/04 + PR benchmark + same bench files).
# Every timed measurement >= 10 s (fastest arm calibrated to ~12 s), 10 interleaved
# trials after an untimed warm-up pass, pinned with taskset. jemalloc counters
# (allocation requests, bytes) per measurement; perf stat (differenced) and
# perf record per arm.
set -u
BS=0456e6c5955576282965bd1821c2b84a093dda8a
VS=fa04698423899cd72c2d552a72eae3c466433baa
C=/local/data-ssd/stoetzem/bin-cache
OUT=${OUT:-/local/data-ssd/stoetzem/thesis/experiments/runs/pr73-fsst-decode-micro-ab-${VS:0:9}}
CORE=${CORE:-6}; TRIALS=${TRIALS:-10}
export LD_LIBRARY_PATH=/local/data-ssd/stoetzem/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
mkdir -p "$OUT"/{raw,perf}
exec > >(tee "$OUT/driver.log") 2>&1
cp "$0" "$OUT/run.sh"
PIN="taskset -c $CORE"
EV=task-clock,cycles,instructions,cache-references,cache-misses,L1-dcache-load-misses,branch-misses,page-faults
for b in $C/$BS/FsstDecodeAbBenchmark $C/$VS/FsstDecodeAbBenchmark $C/$BS/CompressedVocabularyLookupBenchmark $C/$VS/CompressedVocabularyLookupBenchmark $C/$VS/FsstScratchBufferBenchmark; do
  [ -x "$b" ] || { echo "MISSING $b"; exit 2; }; echo "binary $b sha256 $(sha256sum $b | cut -c1-16) $(ldd $b | grep -o 'libjemalloc[^ ]*')"; cat "$(dirname $b)/META-$(basename $b)" 2>/dev/null | tr '\n' ' '; echo; done
{ echo "host $(hostname) $(date -u +%FT%TZ)"; uname -r; cat /proc/loadavg; lscpu | grep -E 'Model name|^CPU\(s\)'; cat /sys/devices/system/cpu/cpu$CORE/cpufreq/scaling_governor; free -g | head -2
  echo "base $BS = bench/pr73-ab-base (upstream-stack/03 9bf5b86ea + bench-only FsstDecodeAbBenchmark, CompressedVocabularyLookupBenchmark)"
  echo "variant $VS = bench/pr73-ab-variant (upstream-stack/04 de4822b12 + PR benchmark 9b8ab0bc0 + same bench-only files)"
  echo "core $CORE trials $TRIALS"; } > "$OUT/env.txt"
TMP=$(mktemp -d); cd "$TMP"
jt() { python3 - "$1" <<'PY'
import json,sys
def walk(o):
  if isinstance(o,dict):
    if "measured-time" in o: yield o
    for v in o.values(): yield from walk(v)
  elif isinstance(o,list):
    for v in o: yield from walk(v)
e=next(walk(json.load(open(sys.argv[1])))); m=e.get("metadata",{})
items=m.get("decodes",m.get("lookups"))
print(e["measured-time"],items,m.get("allocationRequests",""),m.get("allocatedBytes",""),m.get("peakLiveHeapBytesAboveStart",""),m.get("maxPerWordBufferBytes",""),m.get("provisionedBufferBytes",""))
PY
}
echo "bench,config,arm,trial,seconds,items,ns_per_item,alloc_requests,alloc_bytes,peak_live_bytes,max_per_word_buffer_bytes,provisioned_buffer_bytes" > "$OUT/results.csv"
# run <bench> <config> <arm> <trial> <env...> -- <binary>
run1() { local bench=$1 cfg=$2 arm=$3 t=$4; shift 4; local f="$OUT/raw/$bench-$cfg-$arm-t$t.json"
  env "$@" -w "$f" > /dev/null 2> "${f%.json}.err" || { echo "FAIL $bench $cfg $arm $t"; tail -5 "${f%.json}.err"; exit 1; }
  read -r s items ar ab pk pw pb < <(jt "$f")
  echo "$bench,$cfg,$arm,$t,$s,$items,$(python3 -c "print(1e9*$s/$items)"),$ar,$ab,$pk,$pw,$pb" >> "$OUT/results.csv"; }
secs() { jt "$1" | cut -d' ' -f1; }
reps_for() { python3 -c "import math;print(max(1,int(math.ceil($1*$2/$3))))"; }  # target_s cal_reps cal_s
# ---------- (1) FsstDecodeAb: base owning vs variant owning vs variant into, stages 1 and 3
for st in 1 3; do
  env FSST_AB_STAGES=$st FSST_AB_MODE=into FSST_AB_REPETITIONS=20 $PIN $C/$VS/FsstDecodeAbBenchmark -w cal.json >/dev/null 2>&1
  R=$(reps_for 12 20 $(secs cal.json)); echo "stages $st: R=$R (fastest arm ~12 s)"; echo "FsstDecodeAb stages=$st R=$R" >> "$OUT/env.txt"
  for t in $(seq 1 $TRIALS); do
    arms=("base-owning" "variant-owning" "variant-into"); n=${#arms[@]}
    for k in $(seq 0 $((n-1))); do a=${arms[$(( (k+t) % n ))]}
      case $a in base-owning) bin=$C/$BS; m=owning;; variant-owning) bin=$C/$VS; m=owning;; variant-into) bin=$C/$VS; m=into;; esac
      run1 fsstab s$st $a $t FSST_AB_STAGES=$st FSST_AB_MODE=$m FSST_AB_REPETITIONS=$R $PIN $bin/FsstDecodeAbBenchmark
    done
    echo "fsstab s$st trial $t $(date -u +%T)"
  done
  for a in base-owning variant-owning variant-into; do
    case $a in base-owning) bin=$C/$BS; m=owning;; variant-owning) bin=$C/$VS; m=owning;; variant-into) bin=$C/$VS; m=into;; esac
    for x in 1 2; do env FSST_AB_STAGES=$st FSST_AB_MODE=$m FSST_AB_REPETITIONS=$((x*(R/4))) perf stat -x, -o "$OUT/perf/fsstab-s$st-$a.x$x.stat" -e $EV $PIN $bin/FsstDecodeAbBenchmark -w p.json >/dev/null 2>&1; done
    env FSST_AB_STAGES=$st FSST_AB_MODE=$m FSST_AB_REPETITIONS=$((R/4)) perf record -q -F 1999 -o p.data $PIN $bin/FsstDecodeAbBenchmark -w p.json >/dev/null 2>&1
    perf report -i p.data --no-children --sort dso,sym --stdio 2>/dev/null | grep -E '^ +[0-9]' | head -60 > "$OUT/perf/fsstab-s$st-$a.top.txt"
    echo "$((R/4)) 40000" > "$OUT/perf/fsstab-s$st-$a.reps"
  done
done
# ---------- (2) real path: CompressedVocabulary operator[] base vs variant
env VOCAB_BENCH_REPETITIONS=2 $PIN $C/$BS/CompressedVocabularyLookupBenchmark -w cal.json >/dev/null 2>&1
RV=$(reps_for 12 2 $(secs cal.json)); echo "vocab RV=$RV"; echo "CompressedVocabularyLookup RV=$RV" >> "$OUT/env.txt"
for t in $(seq 1 $TRIALS); do
  if [ $((t%2)) -eq 1 ]; then order="base variant"; else order="variant base"; fi
  for a in $order; do bin=$C/$BS; [ $a = variant ] && bin=$C/$VS
    run1 vocab real $a $t VOCAB_BENCH_REPETITIONS=$RV $PIN $bin/CompressedVocabularyLookupBenchmark; done
  echo "vocab trial $t"
done
for a in base variant; do bin=$C/$BS; [ $a = variant ] && bin=$C/$VS
  for x in 1 2; do env VOCAB_BENCH_REPETITIONS=$((x*RV)) perf stat -x, -o "$OUT/perf/vocab-real-$a.x$x.stat" -e $EV $PIN $bin/CompressedVocabularyLookupBenchmark -w p.json >/dev/null 2>&1; done
  env VOCAB_BENCH_REPETITIONS=$RV perf record -q -F 1999 -o p.data $PIN $bin/CompressedVocabularyLookupBenchmark -w p.json >/dev/null 2>&1
  perf report -i p.data --no-children --sort dso,sym --stdio 2>/dev/null | grep -E '^ +[0-9]' | head -60 > "$OUT/perf/vocab-real-$a.top.txt"
  echo "$RV 200000" > "$OUT/perf/vocab-real-$a.reps"
done
# ---------- (3) PR benchmark, 7 arms (variant binary), >= 1 s per arm
env FSST_BENCH_ARM=5 FSST_BENCH_REPETITIONS=200 $PIN $C/$VS/FsstScratchBufferBenchmark -w cal.json >/dev/null 2>&1
RS=$(reps_for 12 200 $(secs cal.json)); echo "scratch RS=$RS"; echo "FsstScratchBuffer RS=$RS" >> "$OUT/env.txt"
for t in $(seq 1 $TRIALS); do
  for k in 0 1 2 3 4 5 6; do a=$(( (k+t) % 7 ))
    run1 scratch arms arm$a $t FSST_BENCH_ARM=$a FSST_BENCH_REPETITIONS=$RS $PIN $C/$VS/FsstScratchBufferBenchmark; done
  echo "scratch trial $t"
done
for a in 0 1 2 3 4 5 6; do
  for x in 1 2; do env FSST_BENCH_ARM=$a FSST_BENCH_REPETITIONS=$((x*RS)) perf stat -x, -o "$OUT/perf/scratch-arms-arm$a.x$x.stat" -e $EV $PIN $C/$VS/FsstScratchBufferBenchmark -w p.json >/dev/null 2>&1; done
  env FSST_BENCH_ARM=$a FSST_BENCH_REPETITIONS=$RS perf record -q -F 1999 -o p.data $PIN $C/$VS/FsstScratchBufferBenchmark -w p.json >/dev/null 2>&1
  perf report -i p.data --no-children --sort dso,sym --stdio 2>/dev/null | grep -E '^ +[0-9]' | head -60 > "$OUT/perf/scratch-arms-arm$a.top.txt"
  echo "$RS 5000" > "$OUT/perf/scratch-arms-arm$a.reps"
done
cd /; rm -rf "$TMP"
cp /local/data-ssd/stoetzem/incoming/pr73-aggregate.py "$OUT/aggregate.py" && python3 "$OUT/aggregate.py" "$OUT"
echo MICRO_EXIT=0
