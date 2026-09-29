#!/usr/bin/env bash
# #3547 research loop, row 10: flag-off path of this PR's binary vs #3526 on the
# warm scattered query (+4.4 % / +3.1 % wall, +4.4 % / +3.0 % CPU, identical
# read syscalls in Ural 5192). Discriminates extra executed work (more
# instructions:u) from code placement (same instructions, more cycles/CPU).
# counter-screen: one warm execution per arm, 3 rounds, arm order rotated.
set -u
I=/local/data-ssd/stoetzem/incoming
C=/local/data-ssd/stoetzem/bin-cache
RUNS=/local/data-ssd/stoetzem/thesis/experiments/runs
Q=/local/data-ssd/stoetzem/thesis/representative-queries/wikidata/H-vocab-random-label-de-200k.rq
P7=$C/0ed8f9223497196d8979accb24ac737becc42f2b/qlever-server
P8=$C/51269ab4bf895211983287d1086c0a700ea43c86/qlever-server
FP=vocabulary-iouring-page-cache-fast-path
A1="p7-3526=$P7"; A2="p8-off=$P8,$FP=false"; A3="p8-on=$P8,$FP=true"
rc=0
for r in 1 2 3; do
  case $r in 1) arms=("$A1" "$A2" "$A3");; 2) arms=("$A2" "$A3" "$A1");; 3) arms=("$A3" "$A1" "$A2");; esac
  args=(); for a in "${arms[@]}"; do args+=(--arm "$a"); done
  taskset -c 0-7 "$I/counter-screen/counter-screen.sh" --index wikidata --query "$Q" \
    --action turtle_export "${args[@]}" --out "$RUNS/nowait8-flagoff-instr/r$r" || rc=1
done
exit $rc
