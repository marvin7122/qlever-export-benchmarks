#!/usr/bin/env bash
# combo-v2-rank-ab.sh -- cumulative effect of idea 2 (rank lookup, fork #264)
# and idea 3 (export engine v2, fork #137/#120) on Wikidata, fork draft PR #274,
# branch combo/v2-plus-rank-lookup. One binary, four arms (runtime flags only):
#   today    fast-export=0, vocabulary-internal-rank-lookup=false
#   v2       fast-export=1, rank lookup off                    (idea 3)
#   v2rank   fast-export=1, rank lookup on                     (ideas 2+3)
#   v2rankpf fast-export=1, rank on, prefetch distance 16, huge pages
# All arms: --num-simultaneous-queries 8, Accept-Encoding: identity (harness
# default), 3 interleaved trials per (query, scenario), arm order rotated per
# trial. No load wait: load1 is logged before/after and sampled every 5 s
# during each trial (rep-load.tsv).
# Queries: English labels SELECT (words in RAM), German labels SELECT (words
# on disk). Cold trials: clear-caches first; /proc/diskstats of nvme0n1,
# nvme1n1 and md1 sampled every 0.25 s (disk/<run-id>.tsv).
# Warm trials loop the query back-to-back to >= 10 s (harness
# --min-measure-s 10, --loop-compare bytes: the v2 output is unordered, so a
# loop iteration must only match the byte count; the first body's row
# multiset is checked against the today arm's).
# Unit tests (from the same build) run first; any failure aborts.
# Then one warm perf profile per arm v2, v2rank and v2rankpf, English labels:
# perf record -e cycles --call-graph dwarf,8192 -F 300, folded stacks kept.
# Usage: combo-v2-rank-ab.sh <commit-full-sha> [run-dir]
set -u
SHA="$1"
U=/local/data-ssd/stoetzem
I=$U/incoming
BC=$U/bin-cache/$SHA
RUN="${2:-$U/thesis/experiments/runs/combo-v2-rank-lookup-wikidata-j8}"
TOOLS=$I/pr-ab-tools-combo
H=$TOOLS/scripts
HARNESS=$H/benchmark_export.py
PY=$U/venv/bin/python3
CLEAR=$U/clear-caches
QREPO=$U/qlever-src
FLAMEDIR=$U/FlameGraph
INDEX_DIR=$U/wikidata
INDEX_BASENAME=$INDEX_DIR/wikidata
MANIFEST=$U/thesis/experiments/runs/wikidata-iouring/manifests/wikidata-serving-files.txt
EN=$U/thesis/representative-queries/wikidata/H-vocab-label-large-select.rq
DE=$I/H-vocab-label-large-de-select.rq
REPS="${REPS:-3}"
export LD_LIBRARY_PATH=$U/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export INDEX_DIR PYTHON="$PY" CLEAR_CACHES="$CLEAR"

die() { echo "combo: FATAL: $*" >&2; [ -d "$RUN" ] && echo "ABORTED: $*" > "$RUN/ABORTED"; exit 2; }
for f in "$BC/qlever-server" "$HARNESS" "$EN" "$DE" "$PY" "$CLEAR" "$MANIFEST" "$H/pr-ab-digest.py" \
         "$H/verify-qlever-binary.sh" "$H/capture-environment.sh"; do
  [ -e "$f" ] || die "missing: $f"
done
TESTS="BitVectorWithRankTest VocabularyInMemoryBinSearchTest VocabularyInternalExternalTest ExportEngineV2Test AsyncChunkPipelineTest ExportQueryExecutionTreesTest"
for t in $TESTS; do [ -x "$BC/$t" ] || die "test binary missing: $BC/$t"; done

if [ -e "$RUN" ]; then mv "$RUN" "$RUN.prev-$(date -u +%Y%m%dT%H%M%SZ)" || die "cannot move old run dir"; fi
mkdir -p "$RUN"/{bin,queries,disk,tests} || die "cannot create $RUN"
LOG="$RUN/driver.log"
log() { echo "[$(date -u +%FT%TZ)] $*" | tee -a "$LOG"; }
stop_servers() { fuser -k 7015/tcp >/dev/null 2>&1 || true; }
trap 'log "terminated"; [ -n "${DPID:-}" ] && kill "$DPID" 2>/dev/null; [ -n "${MPID:-}" ] && kill "$MPID" 2>/dev/null; stop_servers; echo "ABORTED: signal" > "$RUN/ABORTED"; exit 143' TERM INT
cp "$EN" "$DE" "$RUN/queries/"
cp "$0" "$RUN/driver.sh"

# ------------------------------------------------------------ binary + env
cp "$BC/qlever-server" "$RUN/bin/qlever-server" || die "snapshot failed"
BIN="$RUN/bin/qlever-server"
bash "$H/verify-qlever-binary.sh" "$BIN" "${SHA:0:8}" --require-iouring > "$RUN/gate-verify.log" 2>&1 \
  || die "verify-qlever-binary failed (gate-verify.log)"
{
  echo "# build environment ($(date -u +%FT%TZ)), host $(hostname)"
  echo "binary: $BC/qlever-server (Wolga u24 build, shipped)"
  echo "commit: $SHA"
  echo "--version: $("$BIN" --version 2>&1 | head -1)"
  echo "md5: $(md5sum "$BIN" | cut -d' ' -f1)"
  echo "io_uring symbols: $(nm "$BIN" 2>/dev/null | grep -c io_uring)"
  echo "compiler (.comment): $(readelf -p .comment "$BIN" 2>/dev/null | grep -m2 -oE '(GCC|clang)[^]]*' | sort -u | tr '\n' ' ')"
  echo "liburing linked: $(ldd "$BIN" 2>/dev/null | grep -o 'liburing[^ ]*' | head -1)"
  [ -f "$BC/CMakeCache.txt" ] && grep -E '^(CMAKE_BUILD_TYPE|CMAKE_CXX_COMPILER|USE_IO_URING|CMAKE_CXX_FLAGS|QLEVER_ENABLE_EXPORT_V2):' "$BC/CMakeCache.txt"
  ls "$BC"/META-* >/dev/null 2>&1 && head -20 "$BC"/META-qlever-server 2>/dev/null
  echo "perf: $(perf --version 2>/dev/null)"
  echo "THP: $(cat /sys/kernel/mm/transparent_hugepage/enabled)"
  echo "harness md5: $(md5sum "$HARNESS" | cut -d' ' -f1) ($HARNESS)"
} > "$RUN/build-env.txt" 2>&1

# ------------------------------------------------------------ unit tests
TEST_RC=0
for t in $TESTS; do
  td=$(mktemp -d "$RUN/tests/wd-$t.XXXX")
  ( cd "$td" && "$BC/$t" --gtest_brief=1 ) > "$RUN/tests/$t.log" 2>&1
  rc=$?
  log "unit test $t: rc=$rc ($(grep -E '^\[  (PASSED|FAILED)  \]' "$RUN/tests/$t.log" | tr '\n' ' '))"
  rm -rf "$td"
  [ "$rc" = 0 ] || TEST_RC=1
done
[ "$TEST_RC" = 0 ] || die "unit tests failed (tests/*.log)"

# ------------------------------------------------------------ arms
declare -A FF RP LABEL
FF[today]="fast-export=0";  RP[today]="vocabulary-internal-rank-lookup=false"
FF[v2]="fast-export=1";     RP[v2]="vocabulary-internal-rank-lookup=false"
FF[v2rank]="fast-export=1"; RP[v2rank]="vocabulary-internal-rank-lookup=true"
FF[v2rankpf]="fast-export=1"; RP[v2rankpf]="vocabulary-internal-rank-lookup=true vocabulary-internal-rank-prefetch-distance=16 vocabulary-internal-rank-hugepages=true"
LABEL[today]="today (legacy export, rank off)"
LABEL[v2]="idea 3: v2, rank off"
LABEL[v2rank]="ideas 2+3: v2, rank on"
LABEL[v2rankpf]="ideas 2+3 + prefetch 16 + huge pages"
ARMS="today v2 v2rank v2rankpf"
for a in $ARMS; do printf '%s\t%s\t%s\t%s\n' "$a" "${LABEL[$a]}" "${FF[$a]}" "${RP[$a]}"; done > "$RUN/arms.tsv"

harness() { # arm scenario query run-id run-dir [extra harness args...]
  local arm="$1" scen="$2" qf="$3" rid="$4" rdir="$5"; shift 5
  local -a sx=() t
  for t in ${RP[$arm]}; do sx+=("--server-extra-arg=--set-runtime-parameter" "--server-extra-arg=$t"); done
  stop_servers
  "$PY" "$HARNESS" --run-id "$rid" --run-dir "$rdir" --query "$qf" \
    --cache-scenario "$scen" --repetitions 1 --mode pilot \
    --qlever-server "$BIN" --qlever-repo "$QREPO" \
    --index-dir "$INDEX_DIR" --index-basename "$INDEX_BASENAME" \
    --serving-manifest "$MANIFEST" --action csv_export --accept text/csv \
    --num-simultaneous-queries 8 --min-measure-s 10 --loop-compare bytes \
    --hard-timeout-s 1800 --form-field="${FF[$arm]}" "$@" "${sx[@]}" >> "$LOG" 2>&1
}

disk_sampler() { # out-file: /proc/diskstats of the md1 members every 0.25 s
  local out="$1"
  trap 'exit 0' TERM
  echo "t_s device reads_completed reads_merged sectors_read ms_reading in_flight io_ticks_ms weighted_ms" > "$out"
  while :; do
    awk -v t="$(date +%s.%N)" '$3=="nvme0n1"||$3=="nvme1n1"||$3=="md1"{print t, $3, $4, $5, $6, $7, $12, $13, $14}' /proc/diskstats >> "$out"
    sleep 0.25
  done
}
trial_monitor() { # out-file: max load1 during the trial (5 s polls)
  local out="$1" m=0 l1
  trap 'echo "$m" > "$out"; exit 0' TERM
  while :; do
    l1=$(cut -d' ' -f1 /proc/loadavg)
    m=$(awk -v a="$m" -v b="$l1" 'BEGIN{print (b>a)?b:a}')
    echo "$m" > "$out"; sleep 5
  done
}

bash "$H/capture-environment.sh" "$RUN/env-before.txt" >/dev/null 2>&1
printf 'run_id\tstart_utc\tloadavg_before\tend_utc\tloadavg_after\tmax_load1_during\n' > "$RUN/rep-load.tsv"
printf 'query\tscenario\tarm\trep\tdigest\n' > "$RUN/correctness.tsv"
log "combo run: commit $SHA, arms $ARMS, reps $REPS, 8 threads"
BODY="$RUN/.body"
RC=0
for qf in "$EN" "$DE"; do
  qid=$(basename "$qf" .rq)
  for scen in cold warm; do
    for rep in $(seq 1 "$REPS"); do
      # Rotate the arm order per trial (today first, then last, ...).
      case $((rep % 4)) in
        1) order="today v2 v2rank v2rankpf";;
        2) order="v2rankpf v2rank v2 today";;
        3) order="v2 today v2rankpf v2rank";;
        0) order="v2rank v2rankpf today v2";;
      esac
      for arm in $order; do
        rid="combo-$qid-$scen-$arm-r$rep"
        rdir="$RUN/$scen/$qid/$arm"
        [ "$scen" = cold ] && { "$CLEAR" >> "$LOG" 2>&1 || log "clear-caches failed before $rid"; }
        rm -f "$BODY"
        l0="$(date -u +%FT%TZ)	$(cut -d' ' -f1-4 /proc/loadavg)"
        echo 0 > "$RUN/.mon"; trial_monitor "$RUN/.mon" & MPID=$!
        DPID=""; [ "$scen" = cold ] && { disk_sampler "$RUN/disk/$rid.tsv" & DPID=$!; }
        harness "$arm" "$scen" "$qf" "$rid" "$rdir" --save-body "$BODY" || { RC=1; log "harness failed: $rid"; }
        [ -n "$DPID" ] && { kill -TERM "$DPID" 2>/dev/null; wait "$DPID" 2>/dev/null; DPID=""; }
        kill -TERM "$MPID" 2>/dev/null; wait "$MPID" 2>/dev/null; MPID=""
        printf '%s\t%s\t%s\t%s\n' "$rid" "$l0" "$(date -u +%FT%TZ)	$(cut -d' ' -f1-4 /proc/loadavg)" "$(cat "$RUN/.mon")" >> "$RUN/rep-load.tsv"
        [ -d "$rdir/raw/rep-001-$scen" ] && mv "$rdir/raw/rep-001-$scen" "$rdir/raw/r$rep-$scen"
        [ -f "$rdir/metadata.yaml" ] && mv "$rdir/metadata.yaml" "$rdir/metadata-r$rep.yaml"
        if [ -f "$BODY" ]; then d=$("$PY" "$H/pr-ab-digest.py" "$BODY" 2>&1) || d="digest-failed"; else d="no-body"; fi
        printf '%s\t%s\t%s\t%s\t%s\n' "$qid" "$scen" "$arm" "$rep" "$d" >> "$RUN/correctness.tsv"
        rm -f "$BODY"
        log "$rid done"
      done
    done
  done
done
stop_servers

# ------------------------------------------------------------ perf profiles
if command -v perf >/dev/null 2>&1; then
  for arm in v2 v2rank v2rankpf; do
    pdir="$RUN/perf/$(basename "$EN" .rq)/$arm"; mkdir -p "$pdir"
    l0="$(date -u +%FT%TZ)	$(cut -d' ' -f1-4 /proc/loadavg)"
    harness "$arm" warm "$EN" "combo-perf-$arm" "$pdir/harness" \
      --perf-record "$pdir/perf.data" --perf-event cycles --perf-call-graph dwarf,8192 --perf-freq 300 \
      || log "perf trial failed: $arm"
    printf '%s\t%s\t%s\t%s\n' "combo-perf-$arm" "$l0" "$(date -u +%FT%TZ)	$(cut -d' ' -f1-4 /proc/loadavg)" "n/a" >> "$RUN/rep-load.tsv"
    [ -f "$pdir/harness/raw/results.csv" ] && mv "$pdir/harness/raw/results.csv" "$pdir/harness/raw/results-perf.csv"
    if [ -s "$pdir/perf.data" ]; then
      perf report -i "$pdir/perf.data" --stdio --no-children -g none --sort sym --percent-limit 0.1 2>/dev/null \
        | grep -E '^ +[0-9]' > "$pdir/report-self-sym.txt"
      perf report -i "$pdir/perf.data" --stdio --children -g none --sort sym --percent-limit 1 2>/dev/null \
        | grep -E '^ +[0-9]' > "$pdir/report-children-sym.txt"
      perf script -i "$pdir/perf.data" 2>/dev/null | perl "$FLAMEDIR/stackcollapse-perf.pl" > "$pdir/stacks.folded"
      perl "$FLAMEDIR/flamegraph.pl" --title "combo #274 English labels warm: ${LABEL[$arm]}" "$pdir/stacks.folded" > "$pdir/flame.svg" 2>/dev/null
      rm -f "$pdir/perf.data" "$pdir/perf.data.old"
    else
      log "empty perf.data for $arm"
    fi
  done
  stop_servers
fi

# ------------------------------------------------------------ summary
bash "$H/capture-environment.sh" "$RUN/env-after.txt" >/dev/null 2>&1
"$PY" - "$RUN" > "$RUN/summary.md" 2>>"$LOG" <<'PYEOF'
import csv, glob, json, os, statistics, sys
run = sys.argv[1]
arms = [l.split("\t") for l in open(f"{run}/arms.tsv").read().splitlines()]
corr = {}
for r in csv.DictReader(open(f"{run}/correctness.tsv"), delimiter="\t"):
    try:
        corr[(r["query"], r["scenario"], r["arm"], r["rep"])] = json.loads(r["digest"])
    except ValueError:
        corr[(r["query"], r["scenario"], r["arm"], r["rep"])] = None
def fmt(v): return f"{statistics.median(v):.2f} [{min(v):.2f}–{max(v):.2f}]" if v else "n/a"
print("| query | scenario | arm | n | wall s median [min–max] | CPU s median | busy cores median [min–max] | loop n | read MB median | io_uring_enter median | rows multiset = today |")
print("|---|---|---|---|---|---|---|---|---|---|---|")
for q in sorted({k[0] for k in corr}):
    for scen in ("cold", "warm"):
        ref = [corr[k] for k in corr if k[0] == q and k[1] == scen and k[2] == "today" and corr[k]]
        ref = ref[0] if ref else None
        for arm, label, *_ in arms:
            f = f"{run}/{scen}/{q}/{arm}/raw/results.csv"
            rows = list(csv.DictReader(open(f))) if os.path.exists(f) else []
            wall, cpu, busy, loopn, rb, ent = [], [], [], [], [], []
            for r in rows:
                # Wall time from the raw row even when the loop flagged it.
                if not r.get("elapsed_s") or int(r.get("response_bytes") or 0) == 0:
                    continue
                n = int(r.get("loop_n") or 1)
                tot = float(r.get("loop_total_s") or r["elapsed_s"])
                wall.append(tot / n); cpu.append(float(r["cpu_s"]) / n)
                busy.append(float(r["cpu_s"]) / tot if tot else 0); loopn.append(n)
                rb.append(int(r["read_bytes"]) / 1e6); ent.append(int(r.get("io_uring_enter") or 0) / n)
            ds = [corr[k] for k in corr if k[0] == q and k[1] == scen and k[2] == arm]
            same = sum(1 for d in ds if d and ref and d["multiset"] == ref["multiset"] and d["lines"] == ref["lines"])
            md = lambda v, p=2: f"{statistics.median(v):.{p}f}" if v else "n/a"
            print(f"| {q} | {scen} | {label} | {len(wall)} | {fmt(wall)} | {md(cpu)} | {fmt(busy)} | {md(loopn,0)} | {md(rb,0)} | {md(ent,0)} | {same}/{len(ds)} |")
PYEOF
echo "ALL DONE $(date -u +%FT%TZ)" > "$RUN/COMPLETE"
cat "$RUN/summary.md" >> "$LOG"
log "finished rc=$RC run=$RUN"
exit "$RC"
