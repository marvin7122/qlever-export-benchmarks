#!/usr/bin/env bash
# #3526 research loop: does the wave reap of #3476 remove the warm regression
# of #3526? Benchmark length v3: 3 interleaved reps per arm, no adaptive stop,
# driver pinned to CPUs 0-7. Cold = one execution after cache drop. Warm =
# query repeated back-to-back (result cache cleared) until >= 10 s, per-query
# mean (tools dir pr-ab-tools-p7loop, QLEVER_BENCH_WARM_MIN_S=10).
#   A: #3525 (533f800b8)  vs  #3526 + wave reap (bench/p7-wave-reap 15f447df5)
#   B: #3526 (6b71e1e55)  vs  #3526 + wave reap (15f447df5)
# (#3525 vs #3526 is Ural 5240.) Byte-identical output checked per rep.
set -u
S=/local/data-ssd/stoetzem/incoming/pr-ab-multi-v1.sh
C=/local/data-ssd/stoetzem/bin-cache
RUNS=/local/data-ssd/stoetzem/thesis/experiments/runs
P6=533f800b87ffd1857291e27bc1ce63dacc1ca003
P7=6b71e1e5511344222a7691b1cfa3d3e3fcccf48f
WV=15f447df54b915a02659f3a156c876299cad25dc
export QLEVER_BENCH_WARM_MIN_S=10
common=(--pr 3526 --index wikidata --action turtle_export --require-iouring
  --tools-dir /local/data-ssd/stoetzem/incoming/pr-ab-tools-p7loop
  --reps 3 --no-adaptive --queries H-vocab-label-large-de.rq --scenarios cold,warm
  --variant-bin "$C/$WV/qlever-server" --variant-commit "$WV" --label-variant p7-wave-reap)
rc=0
taskset -c 0-7 "$S" "${common[@]}" --base-bin "$C/$P6/qlever-server" --base-commit "$P6" \
  --label-base part6-3525 --run-dir "$RUNS/p7-wave-e2e-vs-3525" || rc=1
taskset -c 0-7 "$S" "${common[@]}" --base-bin "$C/$P7/qlever-server" --base-commit "$P7" \
  --label-base part7-3526 --run-dir "$RUNS/p7-wave-e2e-vs-3526" || rc=1
exit $rc
