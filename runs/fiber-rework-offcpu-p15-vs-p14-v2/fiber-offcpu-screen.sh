#!/usr/bin/env bash
# Fiber rework (fork #165): off-CPU screen of the cold CONSTRUCT export thread on
# the stack. Base = export stack 14/16 (#3476, 95f657ab), variant = 15/16 (#3477, dbaff3f8).
# 3 interleaved cold trials per arm and query; flat perf profile on trial 3.
set -u
U=/local/data-ssd/stoetzem
export LD_LIBRARY_PATH=$U/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
C=$U/bin-cache; Q=$U/incoming/pr162-queries
P14=95f657ab9548758a2bbe9c81df147d11f1278aa9; P15=dbaff3f862f15ba6467a26d117fb5e992f106e79
OUT=${1:-$U/thesis/experiments/runs/fiber-rework-offcpu-p15-vs-p14-v2}
for c in $P14 $P15; do
  bash $U/thesis/scripts/verify-qlever-binary.sh $C/$c/qlever-server ${c:0:8} --require-iouring || exit 2
done
mkdir -p "$OUT"; cp "$0" "$(dirname "$0")/offcpu_screen.py" "$OUT/"
exec $U/venv/bin/python3 "$(dirname "$0")/offcpu_screen.py" --index-basename $U/wikidata/wikidata \
  --evict-cmd $U/clear-caches --trials 3 --perf-cpu \
  --query $Q/H-vocab-label-large-de.rq --query $Q/H-vocab-random-label-de-200k.rq \
  --arm p14-3476=$C/$P14/qlever-server --arm p15-3477=$C/$P15/qlever-server --out "$OUT"
