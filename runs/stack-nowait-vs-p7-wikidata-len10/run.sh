#!/usr/bin/env bash
# Page-cache fast path part (upstream-stack/07b-nowait, fork #236) vs its parent
# #3526 (upstream-stack/07b, ring only), benchmark length v2.
# Base = #3526 binary 0ed8f922 (src tree = 07b head 1fc82901c); variant =
# 51269ab4b (src = 07b-nowait 7eb9805b5 minus a comment), fast path at its
# default (on). Variant2 = the same binary with the fast path off (same-binary
# default-on decision: variant vs variant2; replaces the failed Ural 5188 arms). Wikidata CONSTRUCT turtle export, cold + warm, 10 interleaved
# reps per arm, byte-identical output. Cold: one execution after drop_caches.
# Warm: queries < 10 s loop back-to-back until >= 10 s (per-query mean).
set -u
S=/local/data-ssd/stoetzem/incoming/pr-ab-multi-v2.sh
TOOLS=/local/data-ssd/stoetzem/incoming/pr-ab-tools-stack10s
RUNS=/local/data-ssd/stoetzem/thesis/experiments/runs
C=/local/data-ssd/stoetzem/bin-cache
P7=0ed8f9223497196d8979accb24ac737becc42f2b
P8=51269ab4bf895211983287d1086c0a700ea43c86
exec taskset -c 0-7 "$S" --pr 236 --index wikidata --action turtle_export \
  --queries H-vocab-label-large-de.rq,H-vocab-random-label-de-200k.rq \
  --tools-dir "$TOOLS" --scenarios cold,warm --reps 10 --no-adaptive --require-iouring \
  --min-measure-s 10 \
  --base-bin "$C/$P7/qlever-server" --variant-bin "$C/$P8/qlever-server" \
  --base-commit "$P7" --variant-commit "$P8" \
  --label-base p7-3526-ring-only --label-variant nowait-fastpath-default-on \
  --variant-rp vocabulary-iouring-page-cache-fast-path=true \
  --variant2-rp vocabulary-iouring-page-cache-fast-path=false --label-variant2 nowait-fastpath-off \
  --run-dir "$RUNS/stack-nowait-vs-p7-wikidata-len10"
