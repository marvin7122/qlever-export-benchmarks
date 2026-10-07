#!/usr/bin/env bash
# export-cpu-profile-categories.sh — post-process the perf.data files of a
# finished export-cpu-profile run (e.g. export-cpu-profile-p12) into a CPU
# category breakdown (export-cpu-categories.py), for the whole server process
# and for its busiest thread (the export thread). Read-only on perf.data;
# writes <run>/categories/<query>-<cell>-{process,thread}.md and
# <run>/categories/summary.md. Runs via ural-wq bench (perf script is
# CPU-heavy; the queue keeps it off concurrent measurements).
#
# Usage: export-cpu-profile-categories.sh <run-dir> <categories.py>
set -u
RUN="$1"; CATS="$2"
URAL=/local/data-ssd/stoetzem
FG="$URAL/FlameGraph"
PY="$URAL/venv/bin/python3"
OUT="$RUN/categories"
mkdir -p "$OUT"
cp "$CATS" "$OUT/export-cpu-categories.py"
cp "$0" "$OUT/export-cpu-profile-categories.sh"
{
  echo "# CPU categories of $(basename "$RUN")"
  echo
  echo "perf record -g of the whole server during the measured request (see driver.log);"
  echo "classified by export-cpu-categories.py (leaf-first rules, copied here)."
  echo "process = all threads of the server; thread = the thread with the most samples."
  echo
} > "$OUT/summary.md"
for d in "$RUN"/*/*/*-rec; do
  [ -f "$d/perf.data" ] || continue
  q=$(basename "$(dirname "$d")"); cell=$(basename "$d")
  tag="$q-$cell"
  echo "== $tag"
  perf script -i "$d/perf.data" -F comm,tid,time,event,ip,sym,dso > "$OUT/$tag.process.script" 2> "$OUT/$tag.perf-script.err"
  "$FG/stackcollapse-perf.pl" "$OUT/$tag.process.script" > "$OUT/$tag.process.collapsed"
  tid=$(perf report -i "$d/perf.data" --no-children --sort tid --stdio 2>/dev/null \
        | grep -E '^ +[0-9.]+%' | head -1 | grep -oE '[0-9]+:' | head -1 | tr -d ':' || true)
  if [ -n "$tid" ]; then
    echo "$tid" > "$OUT/$tag.export-tid.txt"
    perf script -i "$d/perf.data" --tid "$tid" -F comm,tid,time,event,ip,sym,dso 2>/dev/null \
      | "$FG/stackcollapse-perf.pl" > "$OUT/$tag.thread.collapsed.tmp"
    mv "$OUT/$tag.thread.collapsed.tmp" "$OUT/$tag.thread.collapsed"
  fi
  rm -f "$OUT/$tag.process.script"
  for scope in process thread; do
    f="$OUT/$tag.$scope.collapsed"
    [ -s "$f" ] || continue
    "$PY" "$OUT/export-cpu-categories.py" "$f" --top 20 > "$OUT/$tag-$scope.md"
    "$FG/flamegraph.pl" --title "$(basename "$RUN") $tag ($scope)" --width 1600 "$f" > "$OUT/$tag.$scope.svg" 2>/dev/null || true
    gzip -f "$f"
    { echo "## $tag ($scope${tid:+, tid $tid})"; echo; sed -n '1,/^| # |/p' "$OUT/$tag-$scope.md" | sed '$d'; echo; } >> "$OUT/summary.md"
  done
done
echo "DONE $(date -u +%FT%TZ)" > "$OUT/COMPLETE"
