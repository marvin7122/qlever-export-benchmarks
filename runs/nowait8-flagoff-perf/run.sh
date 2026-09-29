#!/usr/bin/env bash
# #3547 research loop, row 10 step 2: jobq 60014 showed +3.5 % instructions:u
# for this PR's binary (flag off and on) vs #3526 on the warm scattered query.
# perf profiles (harness --perf) of #3526 vs this PR's binary with the flag
# off, warm, 3 interleaved reps (>= 10 s loops), to locate the extra work.
set -u
S=/local/data-ssd/stoetzem/incoming/pr-ab-multi-v2.sh
TOOLS=/local/data-ssd/stoetzem/incoming/pr-ab-tools-stack10s
RUNS=/local/data-ssd/stoetzem/thesis/experiments/runs
C=/local/data-ssd/stoetzem/bin-cache
P7=0ed8f9223497196d8979accb24ac737becc42f2b
P8=51269ab4bf895211983287d1086c0a700ea43c86
exec taskset -c 0-7 "$S" --pr 3547 --index wikidata --action turtle_export \
  --queries H-vocab-random-label-de-200k.rq --tools-dir "$TOOLS" \
  --scenarios warm --reps 3 --no-adaptive --require-iouring --min-measure-s 10 --perf \
  --base-bin "$C/$P7/qlever-server" --variant-bin "$C/$P8/qlever-server" \
  --base-commit "$P7" --variant-commit "$P8" \
  --label-base p7-3526 --label-variant nowait-fastpath-off \
  --variant-rp vocabulary-iouring-page-cache-fast-path=false \
  --run-dir "$RUNS/nowait8-flagoff-perf"
