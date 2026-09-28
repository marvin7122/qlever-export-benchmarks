#!/usr/bin/env bash
# Part 6 (#3525, fork #76) synthetic rows 1-5 under "Benchmark length v2":
# every measurement >= 10 s (VOCAB_LOOKUP_MIN_SECONDS), 1 untimed warm-up per
# binary and group, 10 interleaved trials per arm (base/variant order and the
# single/batch order alternate per trial), pinned to one core, median and
# min..max of ns per word.
#   base    = part 5 (#3524): bench/part6-base = upstream-stack/06a + the two
#             benchmark sources (benchmark-only commit)
#   variant = part 6 (#3525): part6/bench-long = upstream-stack/07a + the same
#             benchmark sources
# Same-binary comparison: single-word operator[] vs lookupBatch.
# Usage: part6-micro-long.sh <base sha> <variant sha> <run-dir> [core] [trials]
set -u
C=/local/data-ssd/stoetzem/bin-cache
BS=$1; VS=$2; OUT=$3; CORE=${4:-7}; TRIALS=${5:-10}
export LD_LIBRARY_PATH=/local/data-ssd/stoetzem/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export TMPDIR=/local/data-ssd/stoetzem/bench-tmp/part6-micro-long
mkdir -p "$OUT/raw" "$TMPDIR"
exec > >(tee "$OUT/driver.log") 2>&1
for s in $BS $VS; do for t in VocabularyBatchLookupMicroBenchmark VocabularyBatchLookupEndToEndBenchmark; do
  b=$C/$s/$t; test -x "$b" || { echo "MISSING $b"; exit 1; }; echo "binary $b sha256 $(sha256sum "$b" | cut -d' ' -f1)"; done; done
{ echo "host $(hostname)"; date -u +%FT%TZ; uname -r; cat /proc/loadavg; lscpu | grep -E 'Model name|^CPU\(s\)'; cat /sys/devices/system/cpu/cpu$CORE/cpufreq/scaling_governor 2>/dev/null; echo "core $CORE trials $TRIALS min-seconds 10"; echo "base $BS variant $VS"; } > "$OUT/env.txt"
cp "$0" "$OUT/run.sh" 2>/dev/null || true
echo "trial,arm,group,measurement,ns_per_word,batches,seconds" > "$OUT/results.csv"
run() { # arm group trial minsec order
  local arm=$1 g=$2 t=$3 ms=$4 ord=$5 sha bin
  sha=$BS; [ "$arm" = variant ] && sha=$VS
  if [ "$g" = e2e-200k-50k ]; then bin=$C/$sha/VocabularyBatchLookupEndToEndBenchmark; else bin=$C/$sha/VocabularyBatchLookupMicroBenchmark; fi
  local f="$OUT/raw/t$t-$arm-$g.txt"
  VOCAB_LOOKUP_MIN_SECONDS=$ms VOCAB_LOOKUP_ONLY=$g VOCAB_LOOKUP_ORDER=$ord taskset -c "$CORE" "$bin" -p > "$f" 2>&1 || { echo "FAILED $f"; return 1; }
  [ "$t" = warmup ] || awk -F'\t' -v t="$t" -v a="$arm" '$1=="VOCAB_LOOKUP"{print t","a","$2","$3","$4","$5","$6}' "$f" >> "$OUT/results.csv"
}
rc=0
for g in ondisk-128 hybrid-128 ondisk-2048 hybrid-2048 e2e-200k-50k; do
  echo "== $g $(date -u +%T)"
  run base $g warmup 1 single-first || rc=1; run variant $g warmup 1 single-first || rc=1
  for i in $(seq 1 "$TRIALS"); do
    if [ $((i % 2)) = 1 ]; then arms="base variant"; ord=single-first; else arms="variant base"; ord=batch-first; fi
    for a in $arms; do run $a $g $i 10 $ord || rc=1; done
  done
done
echo "after $(cat /proc/loadavg)" >> "$OUT/env.txt"
python3 - "$OUT" <<'PY'
import csv,sys,statistics as st,collections
out=sys.argv[1]; d=collections.defaultdict(list)
for r in csv.DictReader(open(out+"/results.csv")): d[(r["group"],r["arm"],r["measurement"])].append(float(r["ns_per_word"]))
def cmp(b,v):
  bm,vm=st.median(b),st.median(v); delta=100*(vm-bm)/bm
  disj=max(v)<min(b) or min(v)>max(b)
  return f"{delta:+.1f} %", (("faster" if delta<0 else "slower") if disj and abs(delta)>=2 else "parity")
fmt=lambda v: f"{st.median(v):.1f} [{min(v):.1f}-{max(v):.1f}] n={len(v)}"
L=["# part 6 synthetic rows, ns per word, median [min-max], each measurement >= 10 s",""]
groups=sorted({k[0] for k in d},key=lambda g:["ondisk-128","hybrid-128","ondisk-2048","hybrid-2048","e2e-200k-50k"].index(g))
for g in groups:
  ms=sorted({k[2] for k in d if k[0]==g}); single=[m for m in ms if m!="lookupBatch"][0]
  L.append(f"## {g}")
  for a in ("base","variant"):
    for m in ms: L.append(f"{a} | {m} | {fmt(d[(g,a,m)])}")
  for a in ("base","variant"):
    L.append(f"same binary ({a}): lookupBatch vs {single}: "+" ".join(cmp(d[(g,a,single)],d[(g,a,'lookupBatch')])))
  for m in ms:
    L.append(f"cross binary: {m} variant vs base: "+" ".join(cmp(d[(g,'base',m)],d[(g,'variant',m)])))
  L.append("")
open(out+"/aggregate.md","w").write("\n".join(L)); print("\n".join(L))
PY
echo "WQ_DONE part6-micro-long rc=$rc"
exit $rc
