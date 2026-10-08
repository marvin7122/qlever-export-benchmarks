#!/usr/bin/env bash
# v2-fewer-copies-profile.sh — per-arm evidence for the export-v2 copy work.
#
# For each arm (label=binary@commit), warm cache, one qlever-server per step:
#   1. perf stat (cycles, instructions, cache misses, task-clock) over a loop
#      of back-to-back warm queries (>= MIN_S seconds), plus wall per query
#      and process CPU (utime+stime from /proc) for the loop;
#   2. perf record --call-graph dwarf over ONE warm query -> stacks.folded,
#      report-top.txt (leaf symbols), flame.svg;
#   3. allocation counts and bytes for ONE warm query from the LD_PRELOAD
#      shim alloc_count.so (C allocator + C++ operator new/delete; QLever's
#      jemalloc exports its own operator new, so a malloc-only shim misses it).
# Every response body is checked against arm 1 as a row multiset (sorted
# md5) and must have the same byte count.
#
# Usage: v2-fewer-copies-profile.sh <run-dir> <threads> <label> <bin> <commit> [<label> <bin> <commit>]...
# (space-separated triples: the ural-gate refuses "=" and "@" in bench args)
# Env: QUERY (default H-vocab-label-large-select.rq), MIN_S (10), PERF_FREQ
#      (499), DWARF_STACK (16384), FORM (fast-export=1), STEPS (stat,record,alloc)
set -u
URAL=/local/data-ssd/stoetzem
RUN="$1"; THREADS="$2"; shift 2
[ $# -ge 3 ] && [ $(($# % 3)) = 0 ] || { echo "usage: $0 <run-dir> <threads> <label> <bin> <commit>..." >&2; exit 2; }
SPECS=(); while [ $# -gt 0 ]; do SPECS+=("$1=$2@$3"); shift 3; done
QUERY="${QUERY:-$URAL/thesis/representative-queries/wikidata/H-vocab-label-large-select.rq}"
MIN_S="${MIN_S:-10}"; PERF_FREQ="${PERF_FREQ:-499}"; DWARF_STACK="${DWARF_STACK:-16384}"
FORM="${FORM:-fast-export=1}"; STEPS="${STEPS:-stat,record,alloc}"
INDEX_BASENAME="$URAL/wikidata/wikidata"
FLAMEDIR="$URAL/FlameGraph"
PORT="${PORT:-7031}"
HERE="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="$URAL/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
mkdir -p "$RUN"
LOG="$RUN/driver.log"
log() { echo "[$(date -u +%FT%TZ)] $*" | tee -a "$LOG"; }
die() { log "FATAL: $*"; echo "ABORTED: $*" > "$RUN/ABORTED"; exit 2; }

# The shim source sits next to this script (incoming/ copy) or in the run dir.
SHIM="$RUN/alloc_count.so"
SRC="$HERE/alloc_count.cpp"
[ -f "$SRC" ] || SRC="$HERE/v2-fewer-copies/alloc_count.cpp"
[ -f "$SRC" ] || die "alloc_count.cpp not found next to $0"
cp "$SRC" "$RUN/alloc_count.cpp"
c++ -O2 -std=c++17 -shared -fPIC -o "$SHIM" "$RUN/alloc_count.cpp" -ldl || die "shim build failed"
cp "$QUERY" "$RUN/query.rq"
cp "$0" "$RUN/driver.sh"
{ echo "threads=$THREADS min_s=$MIN_S perf_freq=$PERF_FREQ dwarf_stack=$DWARF_STACK form=$FORM steps=$STEPS"
  echo "query=$QUERY"; echo "host=$(hostname) kernel=$(uname -r)"; echo "perf=$(perf --version)"
  echo "loadavg=$(cat /proc/loadavg)"; echo "governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
  echo "arms=${SPECS[*]}"; } > "$RUN/meta.txt"

SERVER_PID=""
start_server() { # bin logfile [preload]
  local bin="$1" slog="$2" pre="${3:-}"
  local -a cmd=("$bin" --index-basename "$INDEX_BASENAME" --port "$PORT" --no-access-check
    --cache-max-size 0B --cache-max-size-single-entry 0B --cache-max-size-lazy-result 0B
    --cache-max-num-entries 0 --default-query-timeout 3600s
    --num-simultaneous-queries "$THREADS")
  if [ -n "$pre" ]; then
    ALLOC_COUNT_OUT="$RUN/.alloc" LD_PRELOAD="$pre" "${cmd[@]}" > "$slog" 2>&1 &
  else
    "${cmd[@]}" > "$slog" 2>&1 &
  fi
  SERVER_PID=$!
  local t=0
  until grep -q "The server is ready" "$slog" 2>/dev/null; do
    sleep 1; t=$((t + 1))
    kill -0 "$SERVER_PID" 2>/dev/null || die "server died at startup (see $slog)"
    [ "$t" -lt 900 ] || die "server not ready after 900 s"
  done
}
stop_server() {
  [ -n "$SERVER_PID" ] || return 0
  kill "$SERVER_PID" 2>/dev/null
  for _ in $(seq 1 60); do kill -0 "$SERVER_PID" 2>/dev/null || break; sleep 1; done
  kill -9 "$SERVER_PID" 2>/dev/null; wait "$SERVER_PID" 2>/dev/null; SERVER_PID=""
}
trap 'stop_server' EXIT
query() { # out-file -> prints "http_code bytes seconds"
  local -a ff=(); local f; for f in $FORM; do ff+=(--data-urlencode "$f"); done
  curl -s -o "$1" -w '%{http_code} %{size_download} %{time_total}' \
    -H 'Accept: text/csv' -H 'Accept-Encoding: identity' \
    --data-urlencode "query@$RUN/query.rq" "${ff[@]}" "http://localhost:$PORT/"
}
cpu_ticks() { awk '{print $14 + $15}' "/proc/$1/stat"; }
REF_MD5="" REF_BYTES=""
check_body() { # body label
  local md5 bytes
  bytes=$(stat -c %s "$1")
  md5=$(LC_ALL=C sort -S 4G --parallel=4 "$1" | md5sum | cut -d' ' -f1)
  if [ -z "$REF_MD5" ]; then REF_MD5="$md5"; REF_BYTES="$bytes"; fi
  local v=OK; [ "$md5" = "$REF_MD5" ] && [ "$bytes" = "$REF_BYTES" ] || v=MISMATCH
  printf '%s\t%s\t%s\t%s\n' "$2" "$bytes" "$md5" "$v" >> "$RUN/correctness.tsv"
  [ "$v" = OK ] || log "CORRECTNESS MISMATCH: $2 bytes=$bytes md5=$md5 ref=$REF_BYTES/$REF_MD5"
}
printf 'label\tbytes\tsorted_md5\tverdict\n' > "$RUN/correctness.tsv"
printf 'arm\tcommit\tthreads\tqueries\twall_s_total\twall_s_per_query\tcpu_s_per_query\tbytes\n' > "$RUN/loop.tsv"
printf 'arm\tcommit\trows\talloc_calls\talloc_bytes\tcalls_per_row\tbytes_per_row\traw\n' > "$RUN/alloc.tsv"

BODY="$RUN/.body"
for spec in "${SPECS[@]}"; do
  label="${spec%%=*}"; rest="${spec#*=}"; bin="${rest%@*}"; commit="${rest##*@}"
  [ -x "$bin" ] || die "binary missing: $bin"
  ver=$("$bin" --version 2>&1 | head -5)
  echo "$ver" | grep -q "${commit:0:8}" || die "$label: --version does not carry $commit: $ver"
  A="$RUN/$label"; mkdir -p "$A"; echo "$ver" > "$A/version.txt"
  log "arm $label: $bin ($commit)"

  if [[ ",$STEPS," == *,stat,* ]] || [[ ",$STEPS," == *,record,* ]]; then
    start_server "$bin" "$A/server.log"
    r=$(query "$BODY"); log "$label warm-up: $r"; check_body "$BODY" "$label-warmup"
    if [[ ",$STEPS," == *,stat,* ]]; then
      perf stat -x, -e cycles,instructions,cache-references,cache-misses,task-clock \
        -p "$SERVER_PID" -o "$A/perf-stat.csv" & psp=$!
      sleep 1
      c0=$(cpu_ticks "$SERVER_PID"); t0=$(date +%s.%N); nq=0
      : > "$A/loop-queries.tsv"
      while :; do
        r=$(query "$BODY"); nq=$((nq + 1)); echo "$r" >> "$A/loop-queries.tsv"
        read -r code _ <<< "$r"; [ "$code" = 200 ] || die "$label loop query failed: $r"
        el=$(echo "$(date +%s.%N) $t0" | awk '{print $1 - $2}')
        awk -v e="$el" -v m="$MIN_S" 'BEGIN{exit !(e >= m)}' && break
      done
      t1=$(date +%s.%N); c1=$(cpu_ticks "$SERVER_PID")
      kill -INT "$psp"; wait "$psp" 2>/dev/null
      check_body "$BODY" "$label-loop"
      hz=$(getconf CLK_TCK)
      awk -v a="$label" -v c="$commit" -v j="$THREADS" -v n="$nq" -v t0="$t0" -v t1="$t1" \
        -v c0="$c0" -v c1="$c1" -v hz="$hz" -v b="$(stat -c %s "$BODY")" \
        'BEGIN{w=t1-t0; printf "%s\t%s\t%s\t%d\t%.3f\t%.4f\t%.4f\t%s\n", a, c, j, n, w, w/n, (c1-c0)/hz/n, b}' >> "$RUN/loop.tsv"
      log "$label loop: $nq queries"
    fi
    if [[ ",$STEPS," == *,record,* ]]; then
      # -e cycles: the default event on this AMD box is cycles:P (IBS), whose
      # samples carry no user registers/stack, so DWARF unwinding yields
      # empty call chains.
      perf record -e cycles -F "$PERF_FREQ" --call-graph "dwarf,$DWARF_STACK" -p "$SERVER_PID" \
        -o "$A/perf.data" > "$A/perf-record.log" 2>&1 & prp=$!
      sleep 2
      r=$(query "$BODY"); log "$label perf query: $r"
      kill -INT "$prp"; wait "$prp" 2>/dev/null
      check_body "$BODY" "$label-perf"
    fi
    stop_server
    if [ -s "$A/perf.data" ]; then
      perf report -i "$A/perf.data" --stdio --no-children -g none --percent-limit 0.1 \
        --sort dso,sym 2>/dev/null | grep -E '^ +[0-9]' | head -80 > "$A/report-top.txt"
      perf script -i "$A/perf.data" 2>/dev/null | perl "$FLAMEDIR/stackcollapse-perf.pl" --all > "$A/stacks.folded"
      perl "$FLAMEDIR/flamegraph.pl" --title "v2 export $label (dwarf, $THREADS threads)" \
        "$A/stacks.folded" > "$A/flame.svg" 2>/dev/null
      ls -la "$A/perf.data" >> "$LOG"; rm -f "$A/perf.data" "$A/perf.data.old"
      log "$label: $(wc -l < "$A/stacks.folded") folded stacks"
    fi
  fi

  if [[ ",$STEPS," == *,alloc,* ]]; then
    rm -f "$RUN/.alloc"
    start_server "$bin" "$A/server-alloc.log" "$SHIM"
    r=$(query "$BODY"); log "$label alloc warm-up: $r"
    kill -USR1 "$SERVER_PID"; sleep 1
    r=$(query "$BODY"); log "$label alloc query: $r"
    sleep 1; kill -USR2 "$SERVER_PID"; sleep 1
    stop_server
    check_body "$BODY" "$label-alloc"
    line=$(tail -1 "$RUN/.alloc" 2>/dev/null)
    [ -n "$line" ] || die "$label: no alloc-count line"
    echo "$line" > "$A/alloc-count.txt"
    rows=$(($(wc -l < "$BODY") - 1))
    calls=$(echo "$line" | sed -n 's/.*alloc_calls=\([0-9]*\).*/\1/p')
    bytes=$(echo "$line" | sed -n 's/.*alloc_bytes=\([0-9]*\).*/\1/p')
    awk -v a="$label" -v c="$commit" -v r="$rows" -v n="$calls" -v b="$bytes" -v l="$line" \
      'BEGIN{printf "%s\t%s\t%d\t%s\t%s\t%.3f\t%.1f\t%s\n", a, c, r, n, b, n/r, b/r, l}' >> "$RUN/alloc.tsv"
    log "$label alloc: rows=$rows $line"
  fi
done
rm -f "$BODY"
grep -q MISMATCH "$RUN/correctness.tsv" && { log "CORRECTNESS MISMATCH"; echo "ALL DONE (mismatch)" > "$RUN/COMPLETE"; exit 1; }
echo "ALL DONE $(date -u +%FT%TZ)" > "$RUN/COMPLETE"
log "done"
