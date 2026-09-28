#!/usr/bin/env bash
# Stack part 10/16 (fork #79, upstream #3528, new chain with #3547): research loop for the synthetic slowdown
# of `lookupBatch` vs per-word `operator[]` in the PolymorphicVocabLookupBatch
# micro and end-to-end benchmarks (upstream-stack/07d @ 390a8de69 vs #3527), body rows 1-3.
#
# Arms, all in one binary:
#   A  per-word `operator[]` through PolymorphicVocabulary      ("sequential operator[]")
#   B  batch through the polymorphic dispatch                  ("batched lookupBatch")
#   C  batch + builder overload of this part, polymorphic      ("batched lookupBatch with builder")
#   D  batch on the concrete vocabulary type, no std::visit    ("concrete lookupBatch (no dispatch)")
# each in two I/O modes of the same binary:
#   iouring  default (VocabularyOnDisk::lookupBatch uses the io_uring BatchManager)
#   sync     io_uring_setup fails with ENOSYS (strace --seccomp-bpf fault injection, only that
#            syscall is traced), so makeBatchManager falls back to the synchronous pread policy.
# B-D separates this part's dispatch/builder cost; iouring vs sync separates the io_uring
# page-cache cost (#3525/#3526); what remains in sync-D vs A is the fixed per-batch cost.
#
# Length rule v2: every timed measurement >= 10 s (inner repetitions calibrated to ~12 s for the fastest
# arm), N=3 trials (benchmark length v3), arms interleaved per trial (variant/iouring, variant/sync, base/iouring),
# after one untimed warm-up trial; taskset-pinned to one core; median + min..max, ns per word.
# Base = #3527 binary (bench/p9-base-07c: upstream-stack/07c @ 87557be42 + the same benchmarks without the builder arm).
# Within a process the order is A, B, (C), D.
set -u
# VERDICT run (jobq --kind micro --verdict) for the two screening "slower" rows of lane job 90008:
# builder overload on the uncompressed copy path (same binary) and batch vs #3527 (uncompressed).
# Only the micro-uncompressed group, io_uring mode, arms variant/base interleaved, N=3, >= 10 s each.
SHA=3c9b75e971c3c73fc89ad04d38ab7b7a016a4017        # upstream-stack/07d (#3528) incl. 07c @ a1d6c06e3
BASESHA=4f42bf82e23e4eef25a15c8ec6665b67b28574bd    # bench/p9-base-07c = upstream-stack/07c @ a1d6c06e3 (#3527) + same benchmarks minus builder arm
BC=/local/data-ssd/stoetzem/bin-cache/$SHA
BB=/local/data-ssd/stoetzem/bin-cache/$BASESHA
OUT=/local/data-ssd/stoetzem/thesis/experiments/runs/p3528-polyvocab-verdict-${SHA:0:9}
N=3
CPU=3
TARGET_S=12   # every timed measurement >= 10 s: inner repetitions calibrated to ~12 s for the fastest arm
if [ "${JOBQ_DRY:-0}" = 1 ]; then
  for f in /local/data-ssd/stoetzem/bin-cache/$SHA/PolymorphicVocabLookupBatchMicroBenchmark /local/data-ssd/stoetzem/bin-cache/$BASESHA/PolymorphicVocabLookupBatchMicroBenchmark; do test -x "$f" || { echo "missing $f"; exit 1; }; done
  echo "plan: micro-uncompressed, arms variant/iouring base/iouring, N=3 + warm-up, target 12 s, out p3528-polyvocab-verdict-${SHA:0:9}"; exit 0
fi
export LD_LIBRARY_PATH=/local/data-ssd/stoetzem/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export TMPDIR=/local/data-ssd/stoetzem/bench-tmp/p9-polyvocab
mkdir -p "$OUT/raw" "$OUT/perf" "$TMPDIR"
exec > >(tee "$OUT/driver.log") 2>&1
MICRO=PolymorphicVocabLookupBatchMicroBenchmark
E2E=PolymorphicVocabLookupBatchEndToEndBenchmark
echo "variant commit $SHA (upstream-stack/07d, #3528), base commit $BASESHA (bench/p9-base-07c on upstream-stack/07c @ 87557be42, #3527), flavor u24"
for d in $BC $BB; do for b in $MICRO; do echo "binary $d/$b sha256 $(sha256sum "$d/$b" | cut -d' ' -f1)"; done; done
{ echo "host $(hostname)"; date -u +%FT%TZ; uname -r; cat /proc/loadavg; lscpu | grep -E 'Model name|^CPU\(s\)|MHz'; cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null; free -g; df -h "$TMPDIR"; echo "pinned cpu $CPU; N=$N; target $TARGET_S s per measurement"; } > "$OUT/env.txt"
cp "$0" "$OUT/run.sh" 2>/dev/null || true

INJECT=(strace -f --seccomp-bpf -e trace=io_uring_setup -e inject=io_uring_setup:error=ENOSYS -o /dev/null)
run_mode() {  # $1 = mode (iouring|sync), rest = command; pinned
  local mode=$1; shift
  if [ "$mode" = sync ]; then taskset -c $CPU "${INJECT[@]}" "$@"; else taskset -c $CPU "$@"; fi
}
repvar() { case $1 in *Micro*) echo POLY_VOCAB_MICRO_REPETITIONS;; *) echo POLY_VOCAB_E2E_REPETITIONS;; esac; }
parse() {  # $1 file -> "measurement seconds" lines
  awk '/Single measurement/{s=$0; sub(/.*measurement \047/,"",s); sub(/\047.*/,"",s)} /time:/{t=$2; sub(/s$/,"",t); print s "\t" t}' "$1"
}

# Specs: tag binary group-env
SPECS=("micro-uncompressed $MICRO POLY_VOCAB_ONLY_GROUP=uncompressed")
declare -A REPS
# Calibration (untimed for the results): fastest arm of the variant binary, io_uring mode.
for spec in "${SPECS[@]}"; do
  set -- $spec; tag=$1; b=$2; g=$3
  cal=$(case $b in *Micro*) echo 500;; *) echo 20;; esac)
  run_mode iouring env $g $(repvar $b)=$cal "$BC/$b" -p > "$OUT/raw/$tag-calibration.txt" 2>&1
  fastest=$(parse "$OUT/raw/$tag-calibration.txt" | sort -t$'\t' -k2 -g | head -1 | cut -f2)
  REPS[$tag]=$(python3 -c "import math;print(max(1,math.ceil($TARGET_S*$cal/$fastest)))")
  echo "calibration $tag: $cal reps, fastest arm $fastest s -> ${REPS[$tag]} reps"
done
printf '%s\n' "${!REPS[@]}" | while read t; do echo "$t ${REPS[$t]}"; done > "$OUT/reps.txt"

# Arms per trial, interleaved: variant/iouring, variant/sync, base/iouring.
ARMS=("variant iouring $BC" "base iouring $BB")
touch "$OUT/COMPLETE.pending"; echo "trial,tag,binary,mode,measurement,seconds,reps" > "$OUT/results.csv"
for trial in $(seq 0 $N); do   # trial 0 = untimed warm-up
  for spec in "${SPECS[@]}"; do
    set -- $spec; tag=$1; b=$2; g=$3; R=${REPS[$tag]}
    for arm in "${ARMS[@]}"; do
      set -- $arm; bin=$1; mode=$2; dir=$3
      f="$OUT/raw/$tag-$bin-$mode-trial$trial.txt"
      run_mode $mode env $g $(repvar $b)=$R "$dir/$b" -p > "$f" 2>&1 || { echo "$tag $bin $mode trial $trial FAILED"; cat "$f"; exit 1; }
      [ $trial -eq 0 ] && continue
      parse "$f" | while IFS=$'\t' read m t; do echo "$trial,$tag,$bin,$mode,$m,$t,$R"; done >> "$OUT/results.csv"
    done
  done
  echo "trial $trial done $(date -u +%T) load $(cut -d' ' -f1-3 /proc/loadavg)"
done
rm -rf "$TMPDIR"

python3 - "$OUT" <<'PY'
import csv,sys,statistics as st,collections
out=sys.argv[1]; d=collections.OrderedDict(); reps={}
for r in csv.DictReader(open(out+"/results.csv")):
    k=(r["tag"],r["binary"],r["mode"],r["measurement"]); d.setdefault(k,[]).append(float(r["seconds"])); reps[r["tag"]]=int(r["reps"])
lookups={"micro-compressed":2048,"micro-uncompressed":2048,"e2e":100000}
def ns(tag,x): return x*1e9/(lookups[tag]*reps[tag])
with open(out+"/aggregate.txt","w") as f:
    f.write("tag | binary | mode | measurement | n | median s | min..max s | median ns/word | min..max ns/word | vs per-word (same binary, mode) | verdict\n")
    for k,v in sorted(d.items()):
        tag,b,mode,m=k
        base=d[(tag,b,mode,"sequential operator[]")]
        med=st.median(v); delta=100*(med-st.median(base))/st.median(base)
        overlap=not (min(v)>max(base) or max(v)<min(base))
        verdict="parity" if (overlap or abs(delta)<2) else ("slower" if delta>0 else "faster")
        f.write(f"{tag} | {b} | {mode} | {m} | {len(v)} | {med:.2f} | {min(v):.2f}..{max(v):.2f} | {ns(tag,med):.1f} | {ns(tag,min(v)):.1f}..{ns(tag,max(v)):.1f} | {delta:+.1f} % | {verdict}\n")
    f.write("\n#3528 (variant) vs #3527 (base), same arm and mode:\n")
    for k,v in sorted(d.items()):
        tag,b,mode,m=k
        if b!="variant" or (tag,"base",mode,m) not in d: continue
        bv=d[(tag,"base",mode,m)]; delta=100*(st.median(v)-st.median(bv))/st.median(bv)
        overlap=not (min(v)>max(bv) or max(v)<min(bv))
        verdict="parity" if (overlap or abs(delta)<2) else ("slower" if delta>0 else "faster")
        f.write(f"{tag} | {mode} | {m} | base {st.median(bv):.2f} ({min(bv):.2f}..{max(bv):.2f}) s | variant {st.median(v):.2f} ({min(v):.2f}..{max(v):.2f}) s | {delta:+.1f} % | {verdict}\n")
print(open(out+"/aggregate.txt").read())
PY
rm -f "$OUT/COMPLETE.pending"; touch "$OUT/COMPLETE"
echo BENCH_EXIT=0
