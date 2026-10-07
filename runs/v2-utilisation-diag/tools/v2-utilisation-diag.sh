#!/usr/bin/env bash
# v2-utilisation-diag.sh — why does export engine V2 (fork PR #120/#137,
# fast-export=1) use only ~4.6 of 8 cores on H-vocab-label-large-select
# (Wikidata truthy, SELECT CSV)? Measure first, no fix.
#
# Phase A (timing, original PR #120 binary 87f57674, unpinned like the A/B):
#   TRIALS interleaved trials; per trial the configs (query threads
#   = --num-simultaneous-queries) 1 2 4 8 and "8pin" (8 threads, server pinned
#   to the 8 physical cores 0-7) run in rotated order, each on a fresh server:
#   cold = 2 x (clear-caches + query); warm = warm-up + queries looped until
#   >= MIN_WARM_S s. At 8 threads one base (fast-export=0) warm query is added
#   as an in-session reference. Client: curl -> /dev/null.
# Phase B (diagnosis, diag binary 112f76a7 = 87f57674 + CSV instrumentation):
#   per thread count 1 2 4 8, cold and warm: per-thread /proc sampler (20 ms),
#   per-thread perf counters, ss socket sampler, V2 morsel/coordinator CSVs.
#   Off-CPU: perf record -e context-switches -c 1 with call graphs (warm 1/8,
#   cold 8). On-CPU: perf record cycles at 8 threads warm.
# Phase C (client/socket limit, original binary, 8 threads, warm):
#   curl unpinned vs curl pinned to CPU 15 vs the harness-equivalent Python
#   client (httpx iter_bytes + xxh3), interleaved, TRIALS trials, each
#   measurement = 2 back-to-back queries (>= 10 s).
#
# Runs only via ural-wq bench. Usage:
#   v2-utilisation-diag.sh <run-dir> <diag-binary> [<orig-binary>]
set -uo pipefail

RUN="${1:?run dir}"; DIAG_BIN_SRC="${2:?diag binary}"
ORIG_BIN_SRC="${3:-/local/data-ssd/stoetzem/wt/work/pr120-postsub/build/qlever-server}"
TRIALS="${TRIALS:-3}"
CONFIGS="${CONFIGS:-1 2 4 8 8pin}"
DIAG_THREADS="${DIAG_THREADS:-1 2 4 8}"
PHASES="${PHASES:-A B C}"
MIN_WARM_S="${MIN_WARM_S:-10}"

URAL=/local/data-ssd/stoetzem
export LD_LIBRARY_PATH=$URAL/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
BASENAME=$URAL/wikidata/wikidata
QSRC=$URAL/thesis/experiments/runs/pr120-wikidata-j8-ab/queries/H-vocab-label-large-select.rq
CLEAR=$URAL/clear-caches
PY=$URAL/venv/bin/python3
FG=$URAL/FlameGraph
VERIFY=$URAL/thesis/scripts/verify-qlever-binary.sh
# Helpers live next to the deployed driver; ural-workload runs a snapshot copy
# of the driver from its log dir, so $0 cannot locate them.
TOOLS="${V2UTIL_TOOLS:-/local/data-ssd/stoetzem/incoming/v2-util}"
PORT=7041
EP="http://127.0.0.1:${PORT}/"

mkdir -p "$RUN/bin" "$RUN/tools"
rm -f "$RUN/COMPLETE"
LOG="$RUN/driver.log"
log() { echo "[$(date -u +%FT%TZ)] $*" | tee -a "$LOG"; }
SRV=""
fail() {
  log "FATAL: $*"; echo "ABORTED: $*" > "$RUN/COMPLETE"
  [ -n "$SRV" ] && kill "$SRV" 2>/dev/null
  pkill -f "qlever-serve[r] .*--port $PORT" 2>/dev/null; exit 2
}
trap 'fail "terminated by signal"' TERM INT

envsnap() {
  {
    echo "date=$(date -u +%FT%TZ)"
    echo "host=$(hostname) kernel=$(uname -r)"
    echo "governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
    echo "boost=$(cat /sys/devices/system/cpu/cpufreq/boost 2>/dev/null)"
    echo "loadavg=$(cat /proc/loadavg)"
    echo "thp=$(cat /sys/kernel/mm/transparent_hugepage/enabled)"
    echo "paranoid=$(cat /proc/sys/kernel/perf_event_paranoid)"
    echo "perf=$(perf --version)"
    lscpu | grep -E 'Model name|Thread|Core|Socket|MHz' | sed 's/^/cpu: /'
    free -g | sed 's/^/mem: /'
    ps -eo user,stat,pcpu,comm --sort=-pcpu | head -10 | sed 's/^/top: /'
  } > "$1"
}

# ---------------------------------------------------------------- setup
command -v perf >/dev/null || fail "perf missing"
[ -x "$CLEAR" ] || fail "clear-caches missing"
[ -f "$QSRC" ] || fail "query missing: $QSRC"
cp "$QSRC" "$RUN/query.rq"
Q="$RUN/query.rq"
cp "$0" "$TOOLS/v2util-sampler.py" "$TOOLS/v2util-pyclient.py" "$RUN/tools/" 2>/dev/null
[ -f "$TOOLS/v2util-analyze.py" ] && cp "$TOOLS/v2util-analyze.py" "$RUN/tools/"
ORIG_BIN="$RUN/bin/qlever-server-87f57674"
DIAG_BIN="$RUN/bin/qlever-server-diag-112f76a7"
cp "$ORIG_BIN_SRC" "$ORIG_BIN" || fail "copy orig binary"
cp "$DIAG_BIN_SRC" "$DIAG_BIN" || fail "copy diag binary"
bash "$VERIFY" "$ORIG_BIN" 87f57674 > "$RUN/gate-verify-orig.log" 2>&1 || fail "verify orig"
bash "$VERIFY" "$DIAG_BIN" 112f76a7 > "$RUN/gate-verify-diag.log" 2>&1 || fail "verify diag"
{
  for b in "$ORIG_BIN" "$DIAG_BIN"; do
    echo "$(basename "$b"): $("$b" --version 2>&1 | head -1) md5=$(md5sum < "$b" | cut -d' ' -f1) io_uring_syms=$(nm "$b" 2>/dev/null | grep -c io_uring)"
  done
  echo "orig_src=$ORIG_BIN_SRC"; echo "diag_src=$DIAG_BIN_SRC"
  echo "compiler: $(gcc --version | head -1)"
  echo "liburing: $(PKG_CONFIG_PATH=$URAL/liburing-install/lib/pkgconfig pkg-config --modversion liburing 2>/dev/null)"
} > "$RUN/build-env.txt"
envsnap "$RUN/env-before.txt"
log "setup done; $(grep loadavg "$RUN/env-before.txt")"

QCSV="$RUN/queries.csv"
[ -f "$QCSV" ] || echo "phase,config,trial,scenario,iter,bin,fast,client,wall_s,ttfb_s,bytes,srv_cpu_s,sys_busy_cores,start_mono_ns,md5,client_cpu_s,loadavg1" > "$QCSV"

start_server() { # bin threads slog pin diagdir
  local bin="$1" n="$2" slog="$3" pin="${4:-}" ddir="${5:-}" pre=()
  pkill -f "qlever-serve[r] .*--port $PORT" 2>/dev/null; sleep 1
  ss -ltn | grep -q ":${PORT} " && fail "port $PORT busy"
  [ -n "$pin" ] && pre=(taskset -c "$pin")
  if [ -n "$ddir" ]; then mkdir -p "$ddir"; pre=(env "QLEVER_V2_DIAG_DIR=$ddir" "${pre[@]}"); fi
  "${pre[@]}" "$bin" --index-basename "$BASENAME" --port $PORT --no-access-check \
    --cache-max-size 0B --cache-max-size-single-entry 0B --cache-max-size-lazy-result 0B \
    --cache-max-num-entries 0 --default-query-timeout 1800s \
    --num-simultaneous-queries "$n" > "$slog" 2>&1 &
  SRV=$!
  for _ in $(seq 1 1200); do
    grep -q "The server is ready" "$slog" && return 0
    kill -0 $SRV 2>/dev/null || fail "server died at startup ($slog)"
    sleep 0.5
  done
  fail "server not ready ($slog)"
}
stop_server() { [ -n "$SRV" ] && kill "$SRV" 2>/dev/null; wait "$SRV" 2>/dev/null; SRV=""; }

proc_cpu() { awk '{print $14+$15}' "/proc/$SRV/stat"; }
sys_jiffies() { head -1 /proc/stat | awk '{b=$2+$3+$4+$7+$8+$9; print b, b+$5+$6}'; }

# run_query <phase> <config> <trial> <scenario> <iter> <binlabel> <fast> <client> <outprefix> [md5]
# client: curl | curlpin | py. Appends one row to queries.csv, sets LAST_WALL.
run_query() {
  local ph="$1" cfg="$2" tr="$3" sc="$4" it="$5" bl="$6" fast="$7" cl="$8" out="$9" want_md5="${10:-}"
  local off t0 t1 c0 c1 j0 j1 res wall ttfb bytes md5="-" ccpu="-" pin=()
  off=$($PY -c 'import time;print(time.time_ns()-time.monotonic_ns())')
  c0=$(proc_cpu); j0=$(sys_jiffies)
  if [ "$cl" = py ]; then
    t0=$(date +%s%N)
    res=$("$PY" "$TOOLS/v2util-pyclient.py" "$EP" "$Q" csv_export text/csv "fast-export=$fast") \
      || fail "pyclient failed ($out)"
    t1=$(date +%s%N)
    set -- $res; wall=$1; ttfb=$2; bytes=$3; md5="xxh3:$4"; ccpu=$5
  else
    [ "$cl" = curlpin ] && pin=(taskset -c 15)
    t0=$(date +%s%N)
    if [ -n "$want_md5" ]; then
      res=$(/usr/bin/time -f "%U %S" -o "$out.ctime" "${pin[@]}" curl -s -o >(md5sum | cut -d' ' -f1 > "$out.md5") \
        -w "%{http_code} %{time_starttransfer} %{time_total} %{size_download}" --max-time 1800 \
        --data-urlencode "query@$Q" --data-urlencode "action=csv_export" --data-urlencode "fast-export=$fast" \
        -H "Accept: text/csv" "$EP")
    else
      res=$(/usr/bin/time -f "%U %S" -o "$out.ctime" "${pin[@]}" curl -s -o /dev/null \
        -w "%{http_code} %{time_starttransfer} %{time_total} %{size_download}" --max-time 1800 \
        --data-urlencode "query@$Q" --data-urlencode "action=csv_export" --data-urlencode "fast-export=$fast" \
        -H "Accept: text/csv" "$EP")
    fi
    t1=$(date +%s%N)
    set -- $res
    [ "$1" = 200 ] || fail "http $1 ($out)"
    ttfb=$2; wall=$3; bytes=$4
    ccpu=$(awk '{print $1+$2}' "$out.ctime" 2>/dev/null || echo -)
    if [ -n "$want_md5" ]; then sleep 0.3; md5=$(cat "$out.md5" 2>/dev/null || echo -); fi
  fi
  c1=$(proc_cpu); j1=$(sys_jiffies)
  [ "${bytes%.*}" -gt 0 ] || fail "empty body ($out)"
  local srvcpu busy
  srvcpu=$(awk -v a="$c0" -v b="$c1" 'BEGIN{printf "%.2f",(b-a)/100}')
  busy=$(awk -v a="$j0" -v b="$j1" 'BEGIN{split(a,x," ");split(b,y," "); if (y[2]>x[2]) printf "%.2f",16*(y[1]-x[1])/(y[2]-x[2]); else print "-"}')
  echo "$ph,$cfg,$tr,$sc,$it,$bl,$fast,$cl,$wall,$ttfb,$bytes,$srvcpu,$busy,$((t0-off)),$md5,$ccpu,$(cut -d' ' -f1 /proc/loadavg)" >> "$QCSV"
  echo "$ph $cfg t$tr $sc#$it $bl fast=$fast $cl wall=$wall ttfb=$ttfb bytes=$bytes srvcpu=$srvcpu sysbusy=$busy" >> "$LOG"
  LAST_WALL="$wall"
}
LAST_WALL=0

rotate() { # k list... -> list rotated left by k
  local k="$1"; shift; local a=("$@") n=$# i
  for ((i = 0; i < n; i++)); do echo -n "${a[$(((i + k) % n))]} "; done
}

# ---------------------------------------------------------------- phase A
if [[ " $PHASES " == *" A "* ]]; then
  read -ra CFGS <<< "$CONFIGS"
  for t in $(seq 1 "$TRIALS"); do
    for cfg in $(rotate $((t - 1)) "${CFGS[@]}"); do
      n="${cfg%pin}"; pin=""; [ "$cfg" != "$n" ] && pin=0-7
      d="$RUN/A/t$t/$cfg"; mkdir -p "$d"
      log "A t$t cfg=$cfg: fresh server (threads=$n pin=${pin:-none})"
      start_server "$ORIG_BIN" "$n" "$d/server.log" "$pin"
      for i in 1 2; do
        "$CLEAR" >> "$LOG" 2>&1 || fail "clear-caches"
        run_query A "$cfg" "$t" cold "$i" orig 1 curl "$d/cold$i" $([ "$i" = 1 ] && echo md5) 
      done
      run_query A "$cfg" "$t" warmup 0 orig 1 curl "$d/warmup" 
      acc=0; i=0
      while :; do
        i=$((i + 1))
        run_query A "$cfg" "$t" warm "$i" orig 1 curl "$d/warm$i"
        acc=$(awk -v a="$acc" -v w="$LAST_WALL" 'BEGIN{print a+w}')
        awk -v a="$acc" -v m="$MIN_WARM_S" -v i="$i" 'BEGIN{exit !(a>=m && i>=2)}' && break
      done
      if [ "$cfg" = 8 ]; then
        run_query A "$cfg" "$t" warm 1 orig 0 curl "$d/base-warm1" 
      fi
      stop_server
    done
  done
  log "phase A done"
fi

# ---------------------------------------------------------------- phase B
diag_query() { # dir scenario mode(plain|cs|cyc|cs-cold) threads
  local d="$1" sc="$2" mode="$3" n="$4" pp="" ssp=""
  mkdir -p "$d"
  touch "$d/.stop"; rm -f "$d/.stop"
  "$PY" "$TOOLS/v2util-sampler.py" "$SRV" 20 "$d/sampler.csv" "$d/.stop" &
  local sp=$!
  ( while [ ! -e "$d/.stop" ]; do
      echo "T $(date +%s%N)"; ss -tniH state established "( sport = :$PORT )" 2>/dev/null; sleep 0.1
    done > "$d/ss.txt" ) &
  ssp=$!
  case "$mode" in
    plain) perf record -s -c 4000000000 -e cycles,instructions,task-clock -p "$SRV" -o "$d/stat.data" > "$d/perf.log" 2>&1 & pp=$! ;;
    cs)    perf record -e context-switches -c 1 --call-graph dwarf,4096 -p "$SRV" -o "$d/perf.data" > "$d/perf.log" 2>&1 & pp=$! ;;
    cyc)   perf record -F 499 -e cycles --call-graph dwarf,8192 -p "$SRV" -o "$d/perf.data" > "$d/perf.log" 2>&1 & pp=$! ;;
  esac
  sleep 1
  [ -n "$pp" ] && { kill -0 "$pp" 2>/dev/null || log "WARN perf died ($d): $(tail -2 "$d/perf.log")"; }
  run_query B "$n" 1 "$sc" 1 diag 1 curl "$d/q" 
  sleep 0.3
  [ -n "$pp" ] && { kill -INT "$pp" 2>/dev/null; wait "$pp" 2>/dev/null; }
  touch "$d/.stop"; wait "$sp" 2>/dev/null; wait "$ssp" 2>/dev/null
  mv "$DDIR"/v2diag-* "$d/" 2>/dev/null || log "WARN no v2diag csv for $d"
  if [ "$mode" = plain ] && [ -f "$d/stat.data" ]; then
    perf report -i "$d/stat.data" -T --stdio 2>/dev/null | sed -n '/PID *TID/,$p' > "$d/thread-counts.txt"
    rm -f "$d/stat.data"
  fi
  if [ "$mode" = cs ] || [ "$mode" = cyc ]; then
    perf script -i "$d/perf.data" -F comm,tid,time,event,ip,sym,dso 2> "$d/perf-script.err" \
      | "$FG/stackcollapse-perf.pl" --tid > "$d/stacks.collapsed"
    "$FG/flamegraph.pl" --title "$(basename "$(dirname "$d")")/$(basename "$d") $mode" \
      --width 1600 $([ "$mode" != cyc ] && echo "--countname switches --colors io") \
      "$d/stacks.collapsed" > "$d/flame.svg" 2>/dev/null
    perf report -i "$d/perf.data" --no-children --sort tid --stdio 2>/dev/null | grep -E '^ +[0-9.]+%' | head -40 > "$d/tids.txt"
    gzip -f "$d/stacks.collapsed"
    rm -f "$d/perf.data"
  fi
}

if [[ " $PHASES " == *" B "* ]]; then
  for n in $DIAG_THREADS; do
    base="$RUN/B/j$n"; mkdir -p "$base"
    DDIR="$base/v2diag-spool"
    log "B j$n: fresh diag server"
    start_server "$DIAG_BIN" "$n" "$base/server.log" "" "$DDIR"
    "$CLEAR" >> "$LOG" 2>&1 || fail "clear-caches"
    diag_query "$base/cold" cold plain "$n"
    run_query B "$n" 1 warmup 0 diag 1 curl "$base/warmup" 
    mv "$DDIR"/v2diag-* "$base/" 2>/dev/null
    diag_query "$base/warm" warm plain "$n"
    if [ "$n" = 8 ] || [ "$n" = 1 ]; then
      diag_query "$base/warm-cs" warm cs "$n"
    fi
    if [ "$n" = 8 ]; then
      diag_query "$base/warm-cyc" warm cyc "$n"
      "$CLEAR" >> "$LOG" 2>&1 || fail "clear-caches"
      diag_query "$base/cold-cs" cold cs "$n"
    fi
    stop_server
  done
  log "phase B done"
fi

# ---------------------------------------------------------------- phase C
if [[ " $PHASES " == *" C "* ]]; then
  d="$RUN/C"; mkdir -p "$d"
  log "C: client/socket check, 8 threads warm"
  start_server "$ORIG_BIN" 8 "$d/server.log"
  run_query C 8 0 warmup 0 orig 1 curl "$d/warmup" 
  CLIENTS=(curl py curlpin)
  for t in $(seq 1 "$TRIALS"); do
    for cl in $(rotate $((t - 1)) "${CLIENTS[@]}"); do
      for i in 1 2; do
        ( while [ ! -e "$d/.stop-$t-$cl-$i" ]; do
            echo "T $(date +%s%N)"; ss -tniH state established "( sport = :$PORT )" 2>/dev/null; sleep 0.1
          done > "$d/ss-$t-$cl-$i.txt" ) &
        ssp=$!
        run_query C 8 "$t" warm "$i" orig 1 "$cl" "$d/$t-$cl-$i" 
        touch "$d/.stop-$t-$cl-$i"; wait "$ssp" 2>/dev/null
      done
    done
  done
  stop_server
  log "phase C done"
fi

envsnap "$RUN/env-after.txt"
if [ -f "$TOOLS/v2util-analyze.py" ]; then
  "$PY" "$TOOLS/v2util-analyze.py" "$RUN" > "$RUN/analysis.md" 2> "$RUN/analysis.err" || log "WARN analysis failed"
fi
log "ALL DONE"
echo "ALL DONE" > "$RUN/COMPLETE"
