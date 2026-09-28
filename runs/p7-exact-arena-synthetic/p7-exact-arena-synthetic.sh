#!/usr/bin/env bash
# #3526 research loop (large-batch page faults found for #3528): does storing
# exact decoded sizes in the arena (bench/p7-exact-arena bb29ed1e1) instead of
# the maxDecompressedSize bound (#3526 head 6b71e1e55) remove the page-fault
# cost of a 100,000-word batch? E2E synthetic (CompressedVocabulary<
# VocabularyOnDisk>, 50,000 words, 100,000 lookups per measurement x 100
# repetitions, page cache), 3 interleaved trials per arm, pinned. Arms:
#   head, exact           : io_uring backend
#   head-sync, exact-sync : io_uring_setup -> ENOSYS (synchronous pread)
# perf stat: task-clock, user/system time, page-faults.
set -u
C=/local/data-ssd/stoetzem/bin-cache
HEAD=$C/6b71e1e5511344222a7691b1cfa3d3e3fcccf48f
EXACT=$C/bb29ed1e10426c48548d36ff7949c87d6701a0c2
OUT=/local/data-ssd/stoetzem/thesis/experiments/runs/p7-exact-arena-synthetic
export LD_LIBRARY_PATH=/local/data-ssd/stoetzem/liburing-install/lib
rm -rf "$OUT"; mkdir -p "$OUT"; cd "$OUT" || exit 2
export TMPDIR="$OUT/tmp"; mkdir -p "$TMPDIR"
export COMPRESSED_VOCAB_E2E_REPETITIONS=100
PIN=(taskset -c 3)
INJ=(strace -f --seccomp-bpf -e trace=io_uring_setup -e inject=io_uring_setup:error=ENOSYS -o /dev/null)
run() { # arm trial
  local pre=() dir
  case $1 in
    head) dir=$HEAD;; exact) dir=$EXACT;;
    head-sync) dir=$HEAD; pre=("${INJ[@]}");; exact-sync) dir=$EXACT; pre=("${INJ[@]}");;
  esac
  "${pre[@]}" "${PIN[@]}" perf stat -o "perfstat-$1-$2.txt" -e task-clock,user_time,system_time,page-faults \
    "$dir/CompressedVocabLookupBatchEndToEndBenchmark" -p > "bench-$1-$2.txt" 2>&1
  echo "rc=$? $1 $2"
}
{ uname -a; date -u; sha256sum "$HEAD/CompressedVocabLookupBatchEndToEndBenchmark" "$EXACT/CompressedVocabLookupBatchEndToEndBenchmark";
  echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH; pinned cpu 3; E2E reps/measurement 100"; } > env.txt
arms=(head exact head-sync exact-sync)
n=${#arms[@]}
for a in "${arms[@]}"; do run $a 0; done   # warm-up, not evaluated
for t in 1 2 3; do
  k=$(( (t - 1) % n ))
  for i in $(seq 0 $((n - 1))); do run "${arms[$(( (k + i) % n ))]}" $t; done
done
rm -rf "$TMPDIR"
# Summary: arm trial build seq batch (seconds) page-faults
for a in "${arms[@]}"; do for t in 1 2 3; do
  pf=$(awk '/page-faults/{gsub(",","",$1); print $1}' perfstat-$a-$t.txt)
  awk -v a=$a -v t=$t -v pf=$pf '/Single measurement/{n=$0} /time:/{v=$2; sub(/s$/,"",v); if(n~/build/)b=v; else if(n~/sequential/)s=v; else if(n~/lookupBatch/)l=v} END{print a,t,b,s,l,pf}' bench-$a-$t.txt
done; done | tee summary.txt
