#!/usr/bin/env bash
# Export stack 10/16 (fork marvin7122/qlever#79, stack/07d-vocab-polymorphic-dispatch): rework of the
# +13.1 % slowdown of lookupBatch(indices, builder) on the uncompressed (copy) path.
# Binaries (PolymorphicVocabLookupBatchMicroBenchmark), all u24 Release builds from Wolga:
#   base  b093e6997  bench/p10-base-07c  = stack/07c (fork PR 9/16, #3527) @ b8504b389 + same benchmark minus builder arms
#   v0    e274aadfb  07d merged with current 07c + tracked-builder arm, BEFORE the fix (per-word copy)
#   v1    bdb5da6bf  + appendWords: one arena allocation per copied result
#   v2    9f48877c8  + appendResult: untracked builder retains the result (no copy); tracked builder bulk-copies (PR head)
# Arms within a process: sequential operator[], batched lookupBatch, with builder (untracked), with tracked builder
# (AllocatorWithLimit), concrete lookupBatch. Both groups (compressed, uncompressed).
# Rules: every timed measurement >= 10 s (reps calibrated to ~12 s for the fastest arm of each group),
# 1 untimed warm-up + N=10 trials, binaries interleaved per trial, pinned to one core; median, min..max, mean.
# Then perf stat (instructions:u, page-faults, cycles) of each builder arm, uncompressed group, full length.
set -u
BIN=/local/data-ssd/stoetzem/bin-cache
declare -A SHA=([base]=b093e69972ee5a8166f561618cbe4cf59fc655bd [v0]=e274aadfb5bf328538e73ecbbfa09dd0d4857e9a [v1]=bdb5da6bf174fdc3a37262d902dbe1f5cf892d24 [v2]=9f48877c80a72b84c299728d718f18a92f63bc3d)
ORDER=(base v0 v1 v2)
B=PolymorphicVocabLookupBatchMicroBenchmark
OUT=/local/data-ssd/stoetzem/thesis/experiments/runs/p10-polyvocab-rework-9f48877c8
N=${N:-10}; CPU=3; TARGET_S=12
for a in "${ORDER[@]}"; do test -x "$BIN/${SHA[$a]}/$B" || { echo "missing $BIN/${SHA[$a]}/$B"; exit 1; }; done
[ "${JOBQ_DRY:-0}" = 1 ] && { echo "dry ok"; exit 0; }
export LD_LIBRARY_PATH=/local/data-ssd/stoetzem/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export TMPDIR=/local/data-ssd/stoetzem/bench-tmp/p10-polyvocab
mkdir -p "$OUT/raw" "$OUT/perf" "$TMPDIR"
exec > >(tee "$OUT/driver.log") 2>&1
cp "$0" "$OUT/run.sh" 2>/dev/null || true
for a in "${ORDER[@]}"; do echo "$a ${SHA[$a]} sha256 $(sha256sum "$BIN/${SHA[$a]}/$B" | cut -d' ' -f1)"; done
{ echo "host $(hostname)"; date -u +%FT%TZ; uname -r; cat /proc/loadavg; lscpu | grep -E 'Model name|^CPU\(s\)|MHz'; cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null; free -g; ldd --version | head -1; echo "pinned cpu $CPU; N=$N; target $TARGET_S s"; } > "$OUT/env.txt"
parse() { awk '/Single measurement/{s=$0; sub(/.*measurement \047/,"",s); sub(/\047.*/,"",s)} /time:/{t=$2; sub(/s$/,"",t); print s "\t" t}' "$1"; }
declare -A REPS
for g in compressed uncompressed; do
  cal=500
  taskset -c $CPU env POLY_VOCAB_ONLY_GROUP=$g POLY_VOCAB_MICRO_REPETITIONS=$cal "$BIN/${SHA[v2]}/$B" -p > "$OUT/raw/$g-calibration.txt" 2>&1
  fastest=$(parse "$OUT/raw/$g-calibration.txt" | sort -t$'\t' -k2 -g | head -1 | cut -f2)
  REPS[$g]=$(python3 -c "import math;print(max(1,math.ceil($TARGET_S*$cal/$fastest)))")
  echo "calibration $g: fastest $fastest s at $cal reps -> ${REPS[$g]} reps"; echo "$g ${REPS[$g]}" >> "$OUT/reps.txt"
done
echo "trial,group,binary,measurement,seconds,reps" > "$OUT/results.csv"
for trial in $(seq 0 $N); do
  for g in compressed uncompressed; do
    # rotate binary order per trial
    for k in 0 1 2 3; do a=${ORDER[$(( (k+trial) % 4 ))]}
      f="$OUT/raw/$g-$a-trial$trial.txt"
      taskset -c $CPU env POLY_VOCAB_ONLY_GROUP=$g POLY_VOCAB_MICRO_REPETITIONS=${REPS[$g]} "$BIN/${SHA[$a]}/$B" -p > "$f" 2>&1 || { echo "$g $a trial $trial FAILED"; tail -20 "$f"; exit 1; }
      [ $trial -eq 0 ] && continue
      parse "$f" | while IFS=$'\t' read m t; do echo "$trial,$g,$a,$m,$t,${REPS[$g]}"; done >> "$OUT/results.csv"
    done
  done
  echo "trial $trial done $(date -u +%T) load $(cut -d' ' -f1-3 /proc/loadavg)"
done
# Counters: each builder arm and the plain batch arm, uncompressed group, full length.
for a in "${ORDER[@]}"; do
  for m in "batched lookupBatch with builder" "batched lookupBatch with tracked builder" "batched lookupBatch"; do
    # The measurement filter is a substring match: "batched lookupBatch" isolates the plain arm only in base.
    if [ $a = base ]; then [ "$m" != "batched lookupBatch" ] && continue; else [ "$m" = "batched lookupBatch" ] && continue; fi
    tag=$(echo "$m" | tr ' ' '-')
    POLY_VOCAB_ONLY_MEASUREMENT="$m" taskset -c $CPU env POLY_VOCAB_ONLY_GROUP=uncompressed POLY_VOCAB_MICRO_REPETITIONS=${REPS[uncompressed]} \
      perf stat -x, -e instructions:u,cycles:u,cycles:k,page-faults -o "$OUT/perf/$a-$tag.csv" "$BIN/${SHA[$a]}/$B" -p > "$OUT/perf/$a-$tag.log" 2>&1 || echo "perf $a $m failed"
  done
done
rm -rf "$TMPDIR"
python3 - "$OUT" <<'PY'
import csv,sys,statistics as st,collections
out=sys.argv[1]; d=collections.OrderedDict(); reps={}
for r in csv.DictReader(open(out+"/results.csv")):
    d.setdefault((r["group"],r["binary"],r["measurement"]),[]).append(float(r["seconds"])); reps[r["group"]]=int(r["reps"])
ns=lambda g,x: x*1e9/(2048*reps[g])
def verdict(v,b):
    delta=100*(st.median(v)-st.median(b))/st.median(b); ov=not(min(v)>max(b) or max(v)<min(b))
    return delta,("parity" if ov or abs(delta)<2 else ("slower" if delta>0 else "faster"))
with open(out+"/aggregate.txt","w") as f:
    f.write("group | binary | measurement | n | median s | min..max s | mean s | median ns/word\n")
    for (g,a,m),v in sorted(d.items()):
        f.write(f"{g} | {a} | {m} | {len(v)} | {st.median(v):.2f} | {min(v):.2f}..{max(v):.2f} | {st.mean(v):.2f} | {ns(g,st.median(v)):.1f}\n")
    f.write("\nbuilder arms vs plain 'batched lookupBatch' of the same binary:\n")
    for (g,a,m),v in sorted(d.items()):
        if "builder" not in m: continue
        dl,vd=verdict(v,d[(g,a,"batched lookupBatch")]); f.write(f"{g} | {a} | {m} | {dl:+.1f} % | {vd}\n")
    f.write("\nsame arm vs base (stack/07c) and vs v0 (before fix):\n")
    for (g,a,m),v in sorted(d.items()):
        for ref in ("base","v0"):
            if a==ref or (g,ref,m) not in d: continue
            dl,vd=verdict(v,d[(g,ref,m)]); f.write(f"{g} | {a} vs {ref} | {m} | {dl:+.1f} % | {vd}\n")
print(open(out+"/aggregate.txt").read())
PY
touch "$OUT/COMPLETE"; echo BENCH_EXIT=0
