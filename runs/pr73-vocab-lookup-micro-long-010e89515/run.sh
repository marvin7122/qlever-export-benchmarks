#!/usr/bin/env bash
# #3522 (fork #73) research loop, iteration 3: CompressedVocabulary lookup only,
# RV=1500 so that the fastest arm also runs >= 10 s (90019 had 7 s). Was: re-measure after the fix
# 4d9d6053f (redundant per-word checks removed from FsstDecoder::decompress).
# Arms: base = #3521 (bench/pr73-ab-base 0456e6c5), variant = #3522 before the fix
# (bench/pr73-ab-variant fa046984), variant2 = #3522 with the fix
# (bench/pr73-ab-variant2 4d9d6053). Same bench-only sources in all three.
# Every timed measurement >= 10 s (repetitions from job 90004's calibration),
# 3 interleaved trials (rule v3) (arm order rotates per trial), pinned, jemalloc counts.
set -u
BS=0456e6c5955576282965bd1821c2b84a093dda8a
VS=fa04698423899cd72c2d552a72eae3c466433baa
V2=4d9d6053fe1976d4d33d619fad109cdfde079740
# Iteration 3 (design change 010e89515: stack-buffer decode) replaces the
# "variant2" arm when its binaries exist when the job starts.
V3=010e89515ac77fa4e615b7deb5a29dcb46fbd587
if [ -x /local/data-ssd/stoetzem/bin-cache/$V3/FsstDecodeAbBenchmark ] && [ -x /local/data-ssd/stoetzem/bin-cache/$V3/CompressedVocabularyLookupBenchmark ]; then V2=$V3; fi
C=/local/data-ssd/stoetzem/bin-cache
OUT=${OUT:-/local/data-ssd/stoetzem/thesis/experiments/runs/pr73-vocab-lookup-micro-long-${V2:0:9}}
CORE=${CORE:-6}; TRIALS=${TRIALS:-3}
mkdir -p "$OUT"/{raw,perf}
exec > >(tee "$OUT/driver.log") 2>&1
cp "$0" "$OUT/run.sh"
PIN="taskset -c $CORE"
for s in $BS $VS $V2; do for t in FsstDecodeAbBenchmark CompressedVocabularyLookupBenchmark; do b=$C/$s/$t
  [ -x "$b" ] || { echo "MISSING $b"; exit 2; }; echo "binary $b sha256 $(sha256sum $b | cut -c1-16) $(ldd $b | grep -o 'libjemalloc[^ ]*' | head -1)"; done; done
{ echo "host $(hostname) $(date -u +%FT%TZ)"; uname -r; cat /proc/loadavg; lscpu | grep -E 'Model name'
  echo "base $BS (#3521), variant $VS (#3522 before fix), variant2 $V2 (4d9d6053 = check removal only; 010e8951 = + stack-buffer decode)"; echo "core $CORE trials $TRIALS"; } > "$OUT/env.txt"
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
print(e["measured-time"],m.get("decodes",m.get("lookups")),m.get("allocationRequests",""),m.get("allocatedBytes",""))
PY
}
echo "bench,config,arm,trial,seconds,items,ns_per_item,alloc_requests,alloc_bytes" > "$OUT/results.csv"
run1() { local bench=$1 cfg=$2 arm=$3 t=$4; shift 4; local f="$OUT/raw/$bench-$cfg-$arm-t$t.json"
  env "$@" -w "$f" > /dev/null 2> "${f%.json}.err" || { echo "FAIL $bench $cfg $arm $t"; tail -5 "${f%.json}.err"; exit 1; }
  read -r s items ar ab < <(jt "$f")
  echo "$bench,$cfg,$arm,$t,$s,$items,$(python3 -c "print(1e9*$s/$items)"),$ar,$ab" >> "$OUT/results.csv"; }
armbin() { case $1 in base-*) echo $C/$BS;; variant-*) echo $C/$VS;; variant2-*) echo $C/$V2;; esac; }
armmode() { case $1 in *-into) echo into;; *) echo owning;; esac; }
for s in $BS $V2; do env VOCAB_BENCH_REPETITIONS=50 $PIN $C/$s/CompressedVocabularyLookupBenchmark -w w.json >/dev/null 2>&1; done
RV=1500; arms=(base-real variant2-real); n=2
for t in $(seq 1 $TRIALS); do
  for k in 0 1; do a=${arms[$(( (k+t) % n ))]}
    run1 vocab real $a $t VOCAB_BENCH_REPETITIONS=$RV $PIN $(armbin $a)/CompressedVocabularyLookupBenchmark; done
  echo "vocab trial $t $(date -u +%T)"
done
cd /; rm -rf "$TMP"
echo MICRO_EXIT=0
