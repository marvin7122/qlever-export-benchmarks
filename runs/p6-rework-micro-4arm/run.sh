#!/usr/bin/env bash
# Part 6 (#3525, fork #76) rework: synthetic rows 1-5 with N arms.
# Every measurement >= 10 s (VOCAB_LOOKUP_MIN_SECONDS), 1 untimed warm-up per
# arm and group, TRIALS interleaved trials (arm order rotates per trial, the
# single/batch order alternates), pinned to one core, ns per word.
# Usage: p6-rework-micro.sh <run-dir> <trials> <label=sha> [<label=sha> ...]
# The first arm is the base of every cross-binary comparison.
set -u
C=/local/data-ssd/stoetzem/bin-cache
OUT=$1; TRIALS=$2; shift 2
CORE=7
LABELS=(); SHAS=()
for a in "$@"; do LABELS+=("${a%%=*}"); SHAS+=("${a#*=}"); done
N=${#LABELS[@]}
export LD_LIBRARY_PATH=/local/data-ssd/stoetzem/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export TMPDIR=/local/data-ssd/stoetzem/bench-tmp/p6-rework-micro
mkdir -p "$OUT/raw" "$TMPDIR"
exec > >(tee "$OUT/driver.log") 2>&1
for s in "${SHAS[@]}"; do for t in VocabularyBatchLookupMicroBenchmark VocabularyBatchLookupEndToEndBenchmark; do
  b=$C/$s/$t; test -x "$b" || { echo "MISSING $b"; exit 1; }; echo "binary $b sha256 $(sha256sum "$b" | cut -d' ' -f1)"; done; done
{ echo "host $(hostname)"; date -u +%FT%TZ; uname -r; cat /proc/loadavg; lscpu | grep -E 'Model name|^CPU\(s\)'; echo "core $CORE trials $TRIALS min-seconds 10"; for i in $(seq 0 $((N-1))); do echo "arm ${LABELS[$i]} ${SHAS[$i]}"; done; } > "$OUT/env.txt"
cp "$0" "$OUT/run.sh" 2>/dev/null || true
echo "trial,arm,group,measurement,ns_per_word,batches,seconds" > "$OUT/results.csv"
run() { # armIndex group trial minsec order
  local i=$1 g=$2 t=$3 ms=$4 ord=$5 sha=${SHAS[$1]} arm=${LABELS[$1]} bin
  if [ "$g" = e2e-200k-50k ]; then bin=$C/$sha/VocabularyBatchLookupEndToEndBenchmark; else bin=$C/$sha/VocabularyBatchLookupMicroBenchmark; fi
  local f="$OUT/raw/t$t-$arm-$g.txt"
  VOCAB_LOOKUP_MIN_SECONDS=$ms VOCAB_LOOKUP_ONLY=$g VOCAB_LOOKUP_ORDER=$ord taskset -c "$CORE" "$bin" -p > "$f" 2>&1 || { echo "FAILED $f"; return 1; }
  [ "$t" = warmup ] || awk -F'\t' -v t="$t" -v a="$arm" '$1=="VOCAB_LOOKUP"{print t","a","$2","$3","$4","$5","$6}' "$f" >> "$OUT/results.csv"
}
rc=0
for g in ondisk-128 hybrid-128 ondisk-2048 hybrid-2048 e2e-200k-50k; do
  echo "== $g $(date -u +%T)"
  for i in $(seq 0 $((N-1))); do run $i $g warmup 1 single-first || rc=1; done
  for t in $(seq 1 "$TRIALS"); do
    if [ $((t % 2)) = 1 ]; then ord=single-first; else ord=batch-first; fi
    for k in $(seq 0 $((N-1))); do run $(( (k + t) % N )) $g $t 10 $ord || rc=1; done
  done
done
echo "after $(cat /proc/loadavg)" >> "$OUT/env.txt"
python3 - "$OUT" "${LABELS[@]}" <<'PY'
import csv,sys,statistics as st,collections
out=sys.argv[1]; labels=sys.argv[2:]; d=collections.defaultdict(list)
for r in csv.DictReader(open(out+"/results.csv")): d[(r["group"],r["arm"],r["measurement"])].append(float(r["ns_per_word"]))
def cmp(b,v):
  bm,vm=st.median(b),st.median(v); delta=100*(vm-bm)/bm
  disj=max(v)<min(b) or min(v)>max(b)
  return f"{delta:+.1f} %", (("faster" if delta<0 else "slower") if disj and abs(delta)>=2 else "parity")
fmt=lambda v: f"{st.median(v):.1f} [{min(v):.1f}-{max(v):.1f}] mean {st.mean(v):.1f} n={len(v)}"
L=["# part 6 rework synthetic rows, ns per word, median [min-max], each measurement >= 10 s",""]
order=["ondisk-128","hybrid-128","ondisk-2048","hybrid-2048","e2e-200k-50k"]
for g in [g for g in order if any(k[0]==g for k in d)]:
  ms=sorted({k[2] for k in d if k[0]==g}); single=[m for m in ms if m!="lookupBatch"][0]
  L.append(f"## {g}")
  for a in labels:
    for m in ms: L.append(f"{a} | {m} | {fmt(d[(g,a,m)])}")
  for a in labels:
    L.append(f"same binary ({a}): lookupBatch vs {single}: "+" ".join(cmp(d[(g,a,single)],d[(g,a,'lookupBatch')])))
  for a in labels[1:]:
    for m in ms: L.append(f"cross binary: {m} {a} vs {labels[0]}: "+" ".join(cmp(d[(g,labels[0],m)],d[(g,a,m)])))
  L.append("")
open(out+"/aggregate.md","w").write("\n".join(L)); print("\n".join(L))
PY
echo "WQ_DONE p6-rework-micro rc=$rc"
exit $rc
