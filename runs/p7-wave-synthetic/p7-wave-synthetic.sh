#!/usr/bin/env bash
# #3526 research loop (warm regression = per-completion io_uring_enter).
# E2E synthetic (CompressedVocabulary<VocabularyOnDisk>, 50,000 words, 100,000
# lookups per measurement x 100 repetitions (benchmark cap), files in page
# cache), 3 interleaved trials per arm, pinned:
#   ring : #3526 head 6b71e1e55 (io_uring backend, one wait per completion)
#   wave : bench/p7-wave-reap 15f447df5 = 6b71e1e55 + wave reap of #3476 only
#   sync : 6b71e1e55 with io_uring_setup -> ENOSYS (synchronous pread backend)
# plus strace -c syscall counts per arm (20 repetitions).
set -u
C=/local/data-ssd/stoetzem/bin-cache
OLD=$C/6b71e1e5511344222a7691b1cfa3d3e3fcccf48f
NEW=$C/15f447df54b915a02659f3a156c876299cad25dc

OUT=/local/data-ssd/stoetzem/thesis/experiments/runs/p7-wave-synthetic
export LD_LIBRARY_PATH=/local/data-ssd/stoetzem/liburing-install/lib
rm -rf "$OUT"; mkdir -p "$OUT"; cd "$OUT" || exit 2
export TMPDIR="$OUT/tmp"; mkdir -p "$TMPDIR"
export COMPRESSED_VOCAB_E2E_REPETITIONS=100 COMPRESSED_VOCAB_MICRO_REPETITIONS=80000
PIN=(taskset -c 3)
INJ=(strace -f --seccomp-bpf -e trace=io_uring_setup -e inject=io_uring_setup:error=ENOSYS -o /dev/null)
libs() { [ -d "$1/lib" ] && echo "$1/lib" || true; }
run() { # arm trial
  local pre=() bin dir
  case $1 in
    ring) dir=$OLD; bin=CompressedVocabLookupBatchEndToEndBenchmark;;
    sync) dir=$OLD; bin=CompressedVocabLookupBatchEndToEndBenchmark; pre=("${INJ[@]}");;
    wave) dir=$NEW; bin=CompressedVocabLookupBatchEndToEndBenchmark;;
    micro) dir=$MIC; bin=CompressedVocabLookupBatchMicroBenchmark;;
  esac
  LD_LIBRARY_PATH="$(libs $dir)${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    "${pre[@]}" "${PIN[@]}" perf stat -o "perfstat-$1-$2.txt" -e task-clock,user_time,system_time \
    "$dir/$bin" -p > "bench-$1-$2.txt" 2>&1
  echo "rc=$? $1 $2"
}
{ uname -a; date -u; sha256sum "$OLD/CompressedVocabLookupBatchEndToEndBenchmark" \
  "$NEW/CompressedVocabLookupBatchEndToEndBenchmark" ; echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH";
  echo "pinned cpu 3; E2E reps/measurement 100; micro reps/measurement 80000"; } > env.txt
arms=(ring wave sync)
n=${#arms[@]}
for a in "${arms[@]}"; do run $a 0; done   # warm-up, not evaluated
for t in $(seq 1 3); do
  k=$(( (t - 1) % n ))
  for i in $(seq 0 $((n - 1))); do run "${arms[$(( (k + i) % n ))]}" $t; done
done
for a in ring wave sync; do   # syscall counts (traced; timings not used)
  dir=$OLD; [ $a = wave ] && dir=$NEW; pre=(); [ $a = sync ] && pre=(-e inject=io_uring_setup:error=ENOSYS)
  LD_LIBRARY_PATH="$(libs $dir)${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" COMPRESSED_VOCAB_E2E_REPETITIONS=20 "${PIN[@]}" strace -f -c --seccomp-bpf \
    -e trace=pread64,preadv2,io_uring_enter,io_uring_setup "${pre[@]}" -o "strace-c-$a.txt" \
    "$dir/CompressedVocabLookupBatchEndToEndBenchmark" -p > "bench-strace-$a.txt" 2>&1; echo "strace rc=$? $a"
done
rm -rf "$TMPDIR"
# Summary: arm trial build seq batch (seconds)
for a in "${arms[@]}"; do for t in $(seq 1 3); do
  awk -v a=$a -v t=$t '/Single measurement/{n=$0} /time:/{v=$2; sub(/s$/,"",v); if(n~/build/)b=v; else if(n~/sequential/)s=v; else if(n~/lookupBatch/)l=v} END{print a,t,b,s,l}' bench-$a-$t.txt
done; done | tee summary.txt
