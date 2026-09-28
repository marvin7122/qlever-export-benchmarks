#!/usr/bin/env bash
# Part 7 (#3526, fork #77) synthetic rows 6/7 (E2E only), benchmark-length rule v3:
# re-run of micro-lane 90005, whose E2E arms failed (liburing.so.2 not found:
# the micro lane does not set LD_LIBRARY_PATH). 3 interleaved trials per arm, pinned to CPU 3, each timed measurement
# >= 10 s where the benchmark's repetition cap allows it.
# Row 8 (E2E, CompressedVocabulary<VocabularyOnDisk>, 50,000 words in 13
# decoder blocks, 100,000 lookups, files in the page cache), 100 repetitions
# per measurement (the benchmark's cap). Arms per trial, order rotating:
#   ring : this part without the fast path (ed8b64020), io_uring backend
#   sync : same binary, io_uring_setup fails with ENOSYS (strace seccomp
#          fault injection) -> synchronous pread BatchManager
#   fast : with the RWF_NOWAIT fast path of the next stack part, default on (42785c8c9)
# Each process measures `sequential operator[]` and `lookupBatch` back to back.
# Row 7 (micro, CompressedVocabulary<VocabularyInMemory>, 2,048 lookups into
# 512 words): 80,000 repetitions (>= 10 s), binary = #3526 head with the raised
# repetition bound (d757ce4a5), same 10 trials. The micro arm runs only if
# that binary is installed when the entry starts (hosted build of a target
# without liburing is refused by build-binaries.yml; Wolga build pending).
set -u
C=/local/data-ssd/stoetzem/bin-cache
OLD=$C/ed8b6402088dc0545900573677456feb8cff7e3c
NEW=$C/42785c8c95fda389c06af1cfd567bacff41eaffc
MIC=$C/d757ce4a58d610e86a152c68f3e7ff18e2d2be60
OUT=/local/data-ssd/stoetzem/thesis/experiments/runs/p7-synthetic-e2e-v3
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
    fast) dir=$NEW; bin=CompressedVocabLookupBatchEndToEndBenchmark;;
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
arms=(ring sync fast)
n=${#arms[@]}
for a in "${arms[@]}"; do run $a 0; done   # warm-up, not evaluated
for t in $(seq 1 3); do
  k=$(( (t - 1) % n ))
  for i in $(seq 0 $((n - 1))); do run "${arms[$(( (k + i) % n ))]}" $t; done
done
for a in ring sync fast; do   # syscall counts (traced; timings not used)
  dir=$OLD; [ $a = fast ] && dir=$NEW; pre=(); [ $a = sync ] && pre=(-e inject=io_uring_setup:error=ENOSYS)
  LD_LIBRARY_PATH="$(libs $dir)${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" COMPRESSED_VOCAB_E2E_REPETITIONS=20 "${PIN[@]}" strace -f -c --seccomp-bpf \
    -e trace=pread64,preadv2,io_uring_enter,io_uring_setup "${pre[@]}" -o "strace-c-$a.txt" \
    "$dir/CompressedVocabLookupBatchEndToEndBenchmark" -p > "bench-strace-$a.txt" 2>&1; echo "strace rc=$? $a"
done
rm -rf "$TMPDIR"
# Summary: arm trial build seq batch (seconds)
for a in "${arms[@]}"; do for t in $(seq 1 3); do
  awk -v a=$a -v t=$t '/Single measurement/{n=$0} /time:/{v=$2; sub(/s$/,"",v); if(n~/build/)b=v; else if(n~/sequential/)s=v; else if(n~/lookupBatch/)l=v} END{print a,t,b,s,l}' bench-$a-$t.txt
done; done | tee summary.txt
