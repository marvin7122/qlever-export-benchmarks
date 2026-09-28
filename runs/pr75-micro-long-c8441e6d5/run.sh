#!/usr/bin/env bash
##QBRANCH=upstream-stack/06a
# Part 5/17 (upstream #3524, fork #75) microbenchmarks under the benchmark length
# rule: every timed measurement >= 10 s, 1 untimed warm-up + 3 interleaved trials (benchmark length v3), pinned to
# one core, median and min-max.
#  A  same binary (part 5): assemble a 20,000-word batch, owning vector<string>
#     vs ContiguousVocabBatchBuilder vs ArenaVocabBatchBuilder (the builders do
#     not exist in part 4, so there is no cross-binary arm for this group).
#  B  cross binary: VocabBatchResolveAbBenchmark (identical source) built on
#     part 4 (bench/part5-resolve-p4 = upstream-stack/05 + benchmark) and part 5
#     (bench/part5-resolve-p5 = upstream-stack/06a + benchmark); processes
#     interleaved p4, p5, p4, ...
#  C  perf stat + jemalloc counts per resolve measurement (part 5 binary).
#  D  jemalloc allocation requests per assemble variant (200 batches) + fixture-only.
set -u
C=/local/data-ssd/stoetzem/bin-cache
P4=db5fa8d1e862912b392e9768f4331451d0557cbe
P5=c8441e6d54320c3f9587c50b4ffb55d9aa30be6e
LOOKUP=$C/$P5/VocabBatchLookupBenchmark
R4=$C/$P4/VocabBatchResolveAbBenchmark
R5=$C/$P5/VocabBatchResolveAbBenchmark
OUT=/local/data-ssd/stoetzem/thesis/experiments/runs/pr75-micro-long-${P5:0:9}
CORE=${CORE:-3}
ASM_REPS=60000; RES_REPS=60000; TRIALS=3; ALLOC_REPS=200
export LD_LIBRARY_PATH=/local/data-ssd/stoetzem/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
mkdir -p "$OUT"/{assemble,resolve,perf,jemalloc}
exec > >(tee "$OUT/driver.log") 2>&1
for b in "$LOOKUP" "$R4" "$R5"; do test -x "$b" || { echo "MISSING $b"; exit 1; }; echo "binary $b sha256 $(sha256sum "$b" | cut -d' ' -f1)"; done
echo "part4 bench commit $P4 (upstream-stack/05 f566b590d + benchmark); part5 bench commit $P5 (upstream-stack/06a c83ed19c0 + benchmark)"
echo "taskset -c $CORE; ASM_REPS=$ASM_REPS RES_REPS=$RES_REPS TRIALS=$TRIALS (+1 warm-up each) ALLOC_REPS=$ALLOC_REPS"
{ echo "host $(hostname)"; date -u +%FT%TZ; uname -r; cat /proc/loadavg; lscpu | grep -E 'Model name|^CPU\(s\)|MHz'; cat /sys/devices/system/cpu/cpu$CORE/cpufreq/scaling_governor 2>/dev/null; free -g; } > "$OUT/env.txt"
cp "$0" "$OUT/run.sh" 2>/dev/null || true
cd "$(mktemp -d)"
parse() { awk -v r="$1" -v a="$2" '/Single measurement/{s=$0; sub(/.*measurement \047/,"",s); sub(/\047.*/,"",s)} /time:/{t=$2; sub(/s$/,"",t); print r "," a "," s "," t}' "$3"; }

echo "== A assemble (same binary)"
echo "trial,arm,measurement,seconds" > "$OUT/assemble/results.csv"
runA() { VOCAB_BATCH_MICRO_INNER_REPETITIONS=$ASM_REPS VOCAB_BATCH_E2E_INNER_REPETITIONS=1 taskset -c $CORE "$LOOKUP" -p; }
runA > "$OUT/assemble/warmup.txt" 2>&1 || { echo "A warm-up FAILED"; exit 1; }
for i in $(seq 1 $TRIALS); do
  runA > "$OUT/assemble/trial$i.txt" 2>&1 || { echo "A trial $i FAILED"; exit 1; }
  parse $i p5 "$OUT/assemble/trial$i.txt" | grep -v -E 'operator\[\] loop|single lookupBatch' >> "$OUT/assemble/results.csv"
done

echo "== B resolve (part 4 vs part 5, interleaved)"
echo "trial,arm,measurement,seconds" > "$OUT/resolve/results.csv"
runB() { VOCAB_RESOLVE_AB_REPETITIONS=$RES_REPS taskset -c $CORE "$1" -p; }
runB "$R4" > "$OUT/resolve/warmup-p4.txt" 2>&1 && runB "$R5" > "$OUT/resolve/warmup-p5.txt" 2>&1 || { echo "B warm-up FAILED"; exit 1; }
for i in $(seq 1 $TRIALS); do
  if [ $((i % 2)) = 1 ]; then order="p4 p5"; else order="p5 p4"; fi
  for a in $order; do
    b=$R4; [ $a = p5 ] && b=$R5
    runB "$b" > "$OUT/resolve/trial$i-$a.txt" 2>&1 || { echo "B trial $i $a FAILED"; exit 1; }
    parse $i $a "$OUT/resolve/trial$i-$a.txt" >> "$OUT/resolve/results.csv"
  done
done
echo "after A+B $(cat /proc/loadavg)" >> "$OUT/env.txt"

echo "== C perf stat + jemalloc per resolve measurement"
for a in p4 p5; do
  b=$R4; [ $a = p5 ] && b=$R5
  for m in 1 2 3; do
    VOCAB_RESOLVE_AB_ONLY=$m VOCAB_RESOLVE_AB_REPETITIONS=2000 taskset -c $CORE perf stat -x, -o "$OUT/perf/$a-m$m.csv" \
      -e task-clock,cycles,instructions,branch-misses,cache-references,cache-misses,page-faults "$b" -p > "$OUT/perf/$a-m$m.out" 2>&1 || echo "perf $a m$m rc=$?"
    VOCAB_RESOLVE_AB_ONLY=$m VOCAB_RESOLVE_AB_REPETITIONS=200 MALLOC_CONF=stats_print:true taskset -c $CORE "$b" -p > /dev/null 2> "$OUT/jemalloc/resolve-$a-m$m.err" || echo "jemalloc $a m$m rc=$?"
  done
  VOCAB_RESOLVE_AB_ONLY=9 VOCAB_RESOLVE_AB_REPETITIONS=200 MALLOC_CONF=stats_print:true taskset -c $CORE "$b" -p > /dev/null 2> "$OUT/jemalloc/resolve-$a-none.err"
done

echo "== D jemalloc per assemble variant"
for v in none baseline contiguous arena; do
  VOCAB_BATCH_MICRO_ONLY=$v VOCAB_BATCH_MICRO_INNER_REPETITIONS=$ALLOC_REPS VOCAB_BATCH_E2E_INNER_REPETITIONS=1 MALLOC_CONF=stats_print:true \
    taskset -c $CORE "$LOOKUP" -p > /dev/null 2> "$OUT/jemalloc/assemble-$v.err" || { echo "D $v FAILED"; exit 1; }
done
jem() { awk '/^small:/ && !s {s=1; sr=$7} /^large:/ && !l {l=1; lr=$7} END {print sr+lr}' "$1"; }
{ echo "file,total_nrequests"; for f in "$OUT"/jemalloc/*.err; do echo "$(basename $f .err),$(jem $f)"; done; } > "$OUT/jemalloc/counts.csv"

python3 - "$OUT" $ASM_REPS $RES_REPS $ALLOC_REPS <<'PY'
import csv,sys,statistics as st,collections,os
out,ar,rr,al=sys.argv[1],int(sys.argv[2]),int(sys.argv[3]),int(sys.argv[4])
def load(p):
  d=collections.OrderedDict()
  for r in csv.DictReader(open(p)): d.setdefault((r["arm"],r["measurement"]),[]).append(float(r["seconds"]))
  return d
def verdict(b,v):
  bm,vm=st.median(b),st.median(v); delta=100*(vm-bm)/bm
  disjoint=max(v)<min(b) or min(v)>max(b)
  return delta, (("faster" if delta<0 else "slower") if disjoint and abs(delta)>=2 else "parity")
L=[]
A=load(out+"/assemble/results.csv"); keys=list(A)
L.append(f"A assemble, same binary (part 5), {ar} batches x 20,000 words per measurement, trials={len(A[keys[0]])}")
L.append("measurement | median s | min s | max s | ns/word | delta vs owning | verdict")
for k in keys:
  v=A[k]; d,vd=verdict(A[keys[0]],v) if k!=keys[0] else (0.0,"base")
  L.append(f"{k[1]} | {st.median(v):.3f} | {min(v):.3f} | {max(v):.3f} | {st.median(v)/(ar*20000)*1e9:.2f} | {d:+.1f} % | {vd}")
B=load(out+"/resolve/results.csv")
ms=sorted({k[1] for k in B})
L.append(f"\nB resolve, {rr} batches x 4,096 lookups per measurement, trials={len(B[('p4',ms[0])])}, interleaved p4/p5")
L.append("measurement | p4 median s [min-max] | p5 median s [min-max] | p4 ns/lookup | p5 ns/lookup | delta p5 vs p4 | verdict")
for m in ms:
  b,v=B[("p4",m)],B[("p5",m)]; d,vd=verdict(b,v)
  L.append(f"{m} | {st.median(b):.3f} [{min(b):.3f}-{max(b):.3f}] | {st.median(v):.3f} [{min(v):.3f}-{max(v):.3f}] | {st.median(b)/(rr*4096)*1e9:.1f} | {st.median(v)/(rr*4096)*1e9:.1f} | {d:+.1f} % | {vd}")
L.append("\nB within binary: lookupBatch (2) vs per-word copy loop (1)")
for a in ("p4","p5"):
  b,v=B[(a,ms[0])],B[(a,ms[1])]; d,vd=verdict(b,v); L.append(f"{a}: {d:+.1f} % ({vd})")
  b,v=B[(a,ms[0])],B[(a,ms[2])]; d,vd=verdict(b,v); L.append(f"{a}: views-only (3) vs copy loop (1): {d:+.1f} % ({vd})")
L.append("\nC perf stat per resolve measurement (2000 batches, whole process incl. fixture)")
for f in sorted(os.listdir(out+"/perf")):
  if f.endswith(".csv"):
    vals={}
    for line in open(out+"/perf/"+f):
      p=line.strip().split(",")
      if len(p)>3 and p[0] and p[0][0].isdigit(): vals[p[2]]=p[0]
    L.append(f"{f[:-4]}: "+", ".join(f"{k}={v}" for k,v in vals.items()))
c={r["file"]:int(r["total_nrequests"] or 0) for r in csv.DictReader(open(out+"/jemalloc/counts.csv"))}
L.append(f"\nD jemalloc allocation requests (small+large nrequests), minus fixture-only process")
for v in ("baseline","contiguous","arena"):
  x=c["assemble-"+v]-c["assemble-none"]; L.append(f"assemble {v}: {x} over {al} batches = {x/al:.1f} per batch = {x/al/20000:.4f} per word")
for a in ("p4","p5"):
  for m in (1,2,3):
    x=c[f"resolve-{a}-m{m}"]-c[f"resolve-{a}-none"]; L.append(f"resolve {a} m{m}: {x} over 200 batches = {x/200:.1f} per batch")
open(out+"/aggregate.txt","w").write("\n".join(L)+"\n"); print("\n".join(L))
PY
echo BENCH_EXIT=0
