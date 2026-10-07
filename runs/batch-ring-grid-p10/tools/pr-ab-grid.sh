#!/usr/bin/env bash
# pr-ab-grid.sh — COPY of pr-ab-multi-v2.sh extended to N same-binary
# runtime-parameter arms (grid), with per-rep device/thread sampling.
#   --arm LABEL:name=value[,name=value...]   (repeat; >= 2 arms; one binary =
#   --base-bin/--base-commit). Arms rotate per rep (rep r starts at arm
#   (r-1) mod N), every cold call after clear-caches. Correctness: every body
#   is compared with the first body of its query. During each harness call
#   grid-sampler.py samples /sys/block/<GRID_DEVS>/stat and the server's
#   per-thread CPU; grid-rep-metrics.py reduces them to the query window
#   (<arm>/raw/r<rep>-<scen>/grid-metrics.json). grid-aggregate.py writes
#   grid.md. Adaptive reps, perf and the two-arm conclusion are not used.
# pr-ab.sh — generic interleaved A/B benchmark of one QLever PR.
# pr-ab-multi variant (stack remeasure): optional third arm "variant2" =
# the variant binary with its own runtime parameters (--variant2-rp k=v,
# --label-variant2 T). One base run serves both comparisons; the base-vs-
# variant2 conclusion is written to <run>/vs-variant2/conclusion.md from a
# view dir (symlinks to the same per-rep data).
# --min-measure-s S (benchmark length v2): each warm measurement loops the
# query back-to-back until >= S s of query time; elapsed_s = per-query mean
# (needs the tools copy whose benchmark_export.py has --min-measure-s).
#
# Usage:
#   pr-ab.sh --pr N --base-bin P --variant-bin P --base-commit C --variant-commit C \
#            --index dblp|wikidata --queries a.rq[,b.rq...] \
#            --action turtle_export|csv_export|tsv_export \
#            [--scenarios cold,warm] [--reps 5] [--perf] [--threads 1] [--no-adaptive] \
#            [--base-extra-args "..."] [--variant-extra-args "..."] \
#            [--base-rp name=value]... [--variant-rp name=value]... \
#            [--base-form-field k=v]... [--variant-form-field k=v]... \
#            [--label-base TXT] [--label-variant TXT] \
#            [--index-dir D] [--index-basename B] [--serving-manifest M] \
#            [--run-dir D] [--tools-dir D] [--require-iouring] [--dry-run]
#            [--server-mem-max SIZE]
#
# One harness call (benchmark_export.py, --repetitions 1) per arm and rep.
# Arms interleave per rep with alternating order; cold reps run after
# clear-caches; every rep has its own run-id. Each measured body is digested
# (pr-ab-digest.py) and compared with the base arm's first body: SELECT as a
# row multiset (ordered only with ORDER BY), CONSTRUCT as a triple multiset.
# Extra args are qlever-server arguments, e.g.
#   --variant-extra-args "--set-runtime-parameter construct-export-row-batch-size=4096"
# and go to the harness as --server-extra-arg=<tok>, last on its command line.
# --base-rp/--variant-rp name=value is the space-free spelling of
# "--set-runtime-parameter name=value" (queue payloads must not hold spaces).
# --base-form-field/--variant-form-field k=v add a request form field per arm
# (harness --form-field), e.g. fast-export=1 for a per-request engine switch.
#
# --server-mem-max SIZE (e.g. 17G) starts every arm's qlever-server inside
# "systemd-run --scope -p MemoryMax=SIZE -p MemorySwapMax=0" (--user scope
# when not root). MemoryMax also charges the page cache, so an index larger
# than SIZE cannot stay cached: this simulates an out-of-memory regime on a
# smaller index. Both arms get the identical cap; the scope's memory.current/
# memory.max/oom_kill are sampled each second into memcap-samples.csv.
#
# Adaptive reps (default): 3 reps per arm and cell first; reps 4..--reps run
# only when the two arms' min..max elapsed ranges overlap after rep 3.
# --no-adaptive runs all --reps reps.
#
# Output: <thesis>/experiments/runs/pr<N>-<index>-ab/ with results.csv,
# conclusion.md, build-env.txt, env-before/after.txt, gate-*.log, driver.log.
# Exit: 0 = gates pass and all reps correct; 1 = gate/rep/correctness
# failure (see conclusion.md); 2 = setup error before measuring.
set -u

die() { echo "pr-ab: FATAL: $*" >&2; [ -n "${RUN:-}" ] && [ -d "$RUN" ] && echo "ABORTED: $*" > "$RUN/ABORTED"; exit 2; }
usage() { sed -n '2,30p' "$0" >&2; exit 2; }

PR="" BASE_BIN="" VARIANT_BIN="" BASE_COMMIT="" VARIANT_COMMIT="" INDEX="" QUERIES=""
ACTION="" SCENARIOS="cold,warm" REPS=5 PERF=0 BASE_EXTRA="" VARIANT_EXTRA=""
BASE_FF="" VARIANT_FF="" THREADS=1 ADAPTIVE=1
LABEL_BASE="" LABEL_VARIANT="" INDEX_DIR="" INDEX_BASENAME="" MANIFEST="" RUN=""
TOOLS="" REQUIRE_IOURING=0 DRY=0 MEM_MAX=""
VARIANT2_EXTRA="" LABEL_VARIANT2="" MIN_MEASURE_S=0
ARM_LABELS=() ARM_EXTRAS=()
GRID_DEVS="${GRID_DEVS:-nvme0n1,nvme1n1}"
while [ $# -gt 0 ]; do
  case "$1" in
    --pr) PR="$2"; shift 2;;
    --base-bin) BASE_BIN="$2"; shift 2;;
    --variant-bin) VARIANT_BIN="$2"; shift 2;;
    --base-commit) BASE_COMMIT="$2"; shift 2;;
    --variant-commit) VARIANT_COMMIT="$2"; shift 2;;
    --index) INDEX="$2"; shift 2;;
    --queries) QUERIES="$2"; shift 2;;
    --action) ACTION="$2"; shift 2;;
    --scenarios) SCENARIOS="$2"; shift 2;;
    --reps) REPS="$2"; shift 2;;
    --perf) PERF=1; shift;;
    --threads) THREADS="$2"; shift 2;;
    --adaptive) ADAPTIVE=1; shift;;
    --no-adaptive) ADAPTIVE=0; shift;;
    --base-extra-args) BASE_EXTRA="$2"; shift 2;;
    --variant-extra-args) VARIANT_EXTRA="$2"; shift 2;;
    --base-rp) BASE_EXTRA="${BASE_EXTRA:+$BASE_EXTRA }--set-runtime-parameter $2"; shift 2;;
    --variant-rp) VARIANT_EXTRA="${VARIANT_EXTRA:+$VARIANT_EXTRA }--set-runtime-parameter $2"; shift 2;;
    --base-form-field) BASE_FF="${BASE_FF:+$BASE_FF }$2"; shift 2;;
    --variant-form-field) VARIANT_FF="${VARIANT_FF:+$VARIANT_FF }$2"; shift 2;;
    --label-base) LABEL_BASE="$2"; shift 2;;
    --label-variant) LABEL_VARIANT="$2"; shift 2;;
    --variant2-rp) VARIANT2_EXTRA="${VARIANT2_EXTRA:+$VARIANT2_EXTRA }--set-runtime-parameter $2"; shift 2;;
    --label-variant2) LABEL_VARIANT2="$2"; shift 2;;
    --arm) ARM_LABELS+=("${2%%:*}"); x=""; for kv in $(echo "${2#*:}" | tr ',' ' '); do x="${x:+$x }--set-runtime-parameter $kv"; done; ARM_EXTRAS+=("$x"); shift 2;;
    --min-measure-s) MIN_MEASURE_S="$2"; shift 2;;
    --index-dir) INDEX_DIR="$2"; shift 2;;
    --index-basename) INDEX_BASENAME="$2"; shift 2;;
    --serving-manifest) MANIFEST="$2"; shift 2;;
    --run-dir) RUN="$2"; shift 2;;
    --tools-dir) TOOLS="$2"; shift 2;;
    --require-iouring) REQUIRE_IOURING=1; shift;;
    --server-mem-max) MEM_MAX="$2"; shift 2;;
    --dry-run) DRY=1; shift;;
    -h|--help) usage;;
    *) die "unknown argument: $1";;
  esac
done
[ "${#ARM_LABELS[@]}" -ge 2 ] || die "need >= 2 --arm"
ADAPTIVE=0 PERF=0
VARIANT_BIN="$BASE_BIN"; VARIANT_COMMIT="$BASE_COMMIT"
BASE_EXTRA="${ARM_EXTRAS[0]}"; VARIANT_EXTRA="${ARM_EXTRAS[1]}"
LABEL_BASE="${ARM_LABELS[0]}"; LABEL_VARIANT="${ARM_LABELS[1]}"
for v in PR BASE_BIN VARIANT_BIN BASE_COMMIT VARIANT_COMMIT INDEX QUERIES ACTION; do
  [ -n "${!v}" ] || die "missing --$(echo "$v" | tr 'A-Z_' 'a-z-')"
done
case "$PR" in *[!0-9]*) die "--pr must be numeric";; esac
case "$REPS" in ''|*[!0-9]*|0) die "--reps must be a positive integer";; esac
case "$THREADS" in ''|*[!0-9]*|0) die "--threads must be a positive integer";; esac
case "$INDEX" in dblp|wikidata) ;; *) die "--index must be dblp|wikidata";; esac
case "$ACTION" in
  turtle_export) ACCEPT="text/turtle";;
  csv_export) ACCEPT="text/csv";;
  tsv_export) ACCEPT="text/tab-separated-values";;
  *) die "--action must be turtle_export|csv_export|tsv_export";;
esac
case "$MEM_MAX" in ''|[0-9]*[KMGT]|[0-9]*) ;; *) die "--server-mem-max must be bytes or N[KMGT]";; esac
for s in ${SCENARIOS//,/ }; do case "$s" in cold|warm) ;; *) die "bad scenario: $s";; esac; done
# Default arm labels name the tested value: the runtime parameters when the
# arms differ in flags, else the commit.
[ -n "$LABEL_BASE" ] || LABEL_BASE="${BASE_EXTRA:+${BASE_EXTRA//--set-runtime-parameter /}}"
[ -n "$LABEL_BASE" ] || LABEL_BASE="${BASE_FF:+request $BASE_FF}"
[ -n "$LABEL_BASE" ] || LABEL_BASE="base ${BASE_COMMIT:0:8}"
[ -n "$LABEL_VARIANT" ] || LABEL_VARIANT="${VARIANT_EXTRA:+${VARIANT_EXTRA//--set-runtime-parameter /}}"
[ -n "$LABEL_VARIANT" ] || LABEL_VARIANT="${VARIANT_FF:+request $VARIANT_FF}"
[ -n "$LABEL_VARIANT" ] || LABEL_VARIANT="variant ${VARIANT_COMMIT:0:8}"
[ "$LABEL_BASE" != "$LABEL_VARIANT" ] || { LABEL_BASE="base: $LABEL_BASE"; LABEL_VARIANT="variant: $LABEL_VARIANT"; }

# ---------------------------------------------------------------- layout
# Ural: everything under /local/data-ssd/stoetzem. Fleet box: indexes under
# $HOME/data/<tag>/ (fleet-wq index tags: dblp, wd), tools extracted next to
# the driver by pr-ab-enqueue.sh's bundle, Qlever checkout in QLEVER_WORKSPACE.
URAL=/local/data-ssd/stoetzem
if [ -d "$URAL/thesis/scripts" ] && [ -x "$URAL/clear-caches" ]; then
  LAYOUT=ural
  THESIS="$URAL/thesis"
  PY="$URAL/venv/bin/python3"
  CLEAR="$URAL/clear-caches"
  QREPO="$URAL/qlever-src"
  FLAMEDIR="$URAL/FlameGraph"
  export LD_LIBRARY_PATH="$URAL/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  if [ "$INDEX" = dblp ]; then
    : "${INDEX_DIR:=$URAL/dblp}"; : "${INDEX_BASENAME:=$INDEX_DIR/dblp}"
    : "${MANIFEST:=$THESIS/experiments/manifests/dblp-serving-files.txt}"
    QDIRS="$THESIS/representative-queries"
  else
    : "${INDEX_DIR:=$URAL/wikidata}"; : "${INDEX_BASENAME:=$INDEX_DIR/wikidata}"
    : "${MANIFEST:=$THESIS/experiments/runs/wikidata-iouring/manifests/wikidata-serving-files.txt}"
    QDIRS="$THESIS/experiments/runs/wikidata-iouring/queries $THESIS/representative-queries/wikidata"
  fi
  # New helper scripts reach Ural via incoming/ before the thesis tree syncs.
  if [ -z "$TOOLS" ]; then
    if [ -f "$THESIS/scripts/pr-ab-digest.py" ]; then TOOLS="$THESIS"; else TOOLS="$URAL/incoming/pr-ab-tools"; fi
  fi
else
  LAYOUT=fleet
  FLEET_DATA="${FLEET_DATA:-$HOME/data}"
  [ -n "$TOOLS" ] || TOOLS="${PR_AB_TOOLS:-$(cd "$(dirname "$0")" && pwd)/pr-ab-tools}"
  THESIS="$TOOLS"
  QREPO="${QLEVER_WORKSPACE:-$HOME/fleet-builds/qlever}"
  FLAMEDIR="${FLAMEGRAPH_DIR:-$HOME/FlameGraph}"
  if [ "$INDEX" = dblp ]; then
    : "${INDEX_DIR:=$FLEET_DATA/dblp}"; : "${INDEX_BASENAME:=$INDEX_DIR/dblp}"
  else
    : "${INDEX_DIR:=$FLEET_DATA/wd}"; : "${INDEX_BASENAME:=$INDEX_DIR/wikidata}"
  fi
  QDIRS="$TOOLS/queries"
  # Python deps: a private venv, created once per box.
  PY="${PR_AB_PYTHON:-$HOME/.cache/pr-ab-venv/bin/python3}"
  if ! "$PY" -c 'import httpx, xxhash, yaml' 2>/dev/null; then
    python3 -m venv "$HOME/.cache/pr-ab-venv" && \
      "$HOME/.cache/pr-ab-venv/bin/pip" install -q httpx xxhash pyyaml || die "cannot create the python venv"
  fi
  # True cold cache: drop_caches as root, else passwordless sudo.
  CLEAR="$TOOLS/clear-caches"
  if [ "$(id -u)" = 0 ]; then
    printf '#!/bin/sh\nsync; echo 3 > /proc/sys/vm/drop_caches\n' > "$CLEAR"
  elif sudo -n true 2>/dev/null; then
    printf '#!/bin/sh\nsync; sudo -n sh -c "echo 3 > /proc/sys/vm/drop_caches"\n' > "$CLEAR"
  else
    rm -f "$CLEAR"
  fi
  [ -f "$CLEAR" ] && chmod +x "$CLEAR"
  # Container-built binaries ship their shared libraries in <bindir>/lib
  # (pr-ab-enqueue.sh stashes them there); the host lacks jemalloc, boost, ...
  for b in "$BASE_BIN" "$VARIANT_BIN"; do
    d="$(dirname "$(readlink -f "$b")")/lib"
    [ -d "$d" ] && export LD_LIBRARY_PATH="$d${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  done
fi
H="$TOOLS/scripts"
GRID_TOOLS="${GRID_TOOLS:-$(cd "$(dirname "$0")" && pwd)/pr-ab-grid-tools}"
for f in grid-sampler.py grid-rep-metrics.py grid-aggregate.py; do [ -f "$GRID_TOOLS/$f" ] || die "grid tool missing: $GRID_TOOLS/$f"; done
HARNESS="$H/benchmark_export.py"
GATE="$H/qlever-benchmark-gate.sh"
for f in "$HARNESS" "$GATE" "$H/verify-qlever-binary.sh" "$H/pr-ab-digest.py" \
         "$H/pr-ab-conclusion.py" "$H/aggregate-ab-results.py" "$H/capture-environment.sh" \
         "$H/evict_file_cache.py"; do
  [ -f "$f" ] || die "tool missing: $f (tools dir $TOOLS)"
done
grep -q -- '--save-body' "$HARNESS" || die "harness $HARNESS lacks --save-body"
[ -f "$INDEX_BASENAME.meta-data.json" ] || die "index not found: $INDEX_BASENAME.meta-data.json (pass --index-dir/--index-basename)"
case "$SCENARIOS" in *cold*) [ -x "$CLEAR" ] || die "cold scenario needs clear-caches ($CLEAR); none usable on this box";; esac
[ -x "$PY" ] || die "python missing: $PY"
[ -d "$QREPO/.git" ] || [ -f "$QREPO/.git" ] || die "qlever repo for git metadata missing: $QREPO"

# Resolve query files: absolute path, or a name under the index's query dirs.
QFILES=() QIDS=()
for q in ${QUERIES//,/ }; do
  f=""
  if [ -f "$q" ]; then f="$q"; else
    for d in $QDIRS; do
      [ -f "$d/$q" ] && { f="$d/$q"; break; }
      [ -f "$d/$q.rq" ] && { f="$d/$q.rq"; break; }
    done
  fi
  [ -n "$f" ] || die "query not found: $q (searched: $QDIRS)"
  QFILES+=("$(readlink -f "$f")"); QIDS+=("$(basename "$f" .rq)")
done
# A CONSTRUCT query needs turtle_export, a SELECT query csv/tsv.
for f in "${QFILES[@]}"; do
  if grep -qiE '^[[:space:]]*CONSTRUCT' "$f"; then
    [ "$ACTION" = turtle_export ] || die "$f is CONSTRUCT but --action $ACTION"
  else
    [ "$ACTION" != turtle_export ] || die "$f is not CONSTRUCT but --action turtle_export"
  fi
done

: "${RUN:=$THESIS/experiments/runs/pr$PR-$INDEX-ab}"
if [ -e "$RUN" ]; then
  mv "$RUN" "$RUN.prev-$(date -u +%Y%m%dT%H%M%SZ)" || die "cannot move old run dir aside"
fi
mkdir -p "$RUN" || die "cannot create $RUN"
LOG="$RUN/driver.log"
log() { echo "[$(date -u +%FT%TZ)] $*" | tee -a "$LOG"; }
loud() { log "!!!!!!!! $* !!!!!!!!"; echo "pr-ab: $*" >&2; }
export INDEX_DIR PYTHON="$PY" CLEAR_CACHES="$CLEAR"

stop_servers() { # only servers on the harness port; never other users' servers
  fuser -k 7015/tcp >/dev/null 2>&1 || true
}
trap 'loud "terminated"; stop_servers; echo "ABORTED: signal" > "$RUN/ABORTED"; exit 143' TERM INT

# ---------------------------------------------------------------- binaries
# Snapshot binaries into the run dir: a later build of the same branch
# must not swap a file under a running suite.
mkdir -p "$RUN/bin"
if [ "$(readlink -f "$BASE_BIN")" = "$(readlink -f "$VARIANT_BIN")" ]; then
  [ "$BASE_COMMIT" = "$VARIANT_COMMIT" ] || die "same binary but different commits"
  [ "$BASE_EXTRA|$BASE_FF" != "$VARIANT_EXTRA|$VARIANT_FF" ] || die "same binary and same extra args: the arms are identical"
  BINARY_MODE="same binary, runtime-flag A/B"
  bash "$GATE" snapshot "$BASE_BIN" "$RUN/bin/qlever-server-ab" || die "snapshot failed: $BASE_BIN"
  SNAP_BASE="$RUN/bin/qlever-server-ab"; SNAP_VARIANT="$SNAP_BASE"
else
  BINARY_MODE="two binaries"
  bash "$GATE" snapshot "$BASE_BIN" "$RUN/bin/qlever-server-base" || die "snapshot failed: $BASE_BIN"
  bash "$GATE" snapshot "$VARIANT_BIN" "$RUN/bin/qlever-server-variant" || die "snapshot failed: $VARIANT_BIN"
  SNAP_BASE="$RUN/bin/qlever-server-base"; SNAP_VARIANT="$RUN/bin/qlever-server-variant"
fi

# ---------------------------------------------------------------- memory cap
MEM_PREFIX=() MEM_SCOPE_KIND=""
if [ -n "$MEM_MAX" ]; then
  command -v systemd-run >/dev/null || die "--server-mem-max needs systemd-run"
  if [ "$(id -u)" = 0 ]; then MEM_SCOPE_KIND=system; su=(); else MEM_SCOPE_KIND=user; su=(--user); fi
  MEM_PREFIX=(systemd-run "${su[@]}" --scope --quiet --collect -p "MemoryMax=$MEM_MAX" -p MemorySwapMax=0 --)
  # Preflight: the cap must be visible in the scope's own cgroup.
  want=$(numfmt --from=iec "$MEM_MAX")
  got=$("${MEM_PREFIX[@]}" sh -c 'cat "/sys/fs/cgroup$(sed -n "s/^0:://p" /proc/self/cgroup)/memory.max"' 2>&1)
  [ "$got" = "$want" ] || die "memory cap not applied: memory.max=$got, want $want ($MEM_SCOPE_KIND scope)"
  log "server memory cap: MemoryMax=$MEM_MAX ($want B), MemorySwapMax=0, $MEM_SCOPE_KIND scope; preflight memory.max=$got"
  echo "t,run_id,cgroup,memory_current,memory_max,oom_kill" > "$RUN/memcap-samples.csv"
fi
# With the cap, also count the server's io_uring_enter and pread64 syscalls
# per rep (perf stat on the server PID until it exits): a cold export that
# never enters the ring shows 0 io_uring_enter calls (iouring-stat/<rid>.txt).
memcap_sample() { # run-id: sample the capped server's cgroup once per second
  local rid="$1" pid cg d perfpid=""
  trap '[ -n "$perfpid" ] && kill -INT "$perfpid" 2>/dev/null; exit 0' TERM
  while :; do
    pid=$(fuser 7015/tcp 2>/dev/null | awk '{print $1}')
    if [ -n "$pid" ] && [ -z "$perfpid" ] && command -v perf >/dev/null; then
      mkdir -p "$RUN/iouring-stat"
      perf stat -x, -e syscalls:sys_enter_io_uring_enter,syscalls:sys_enter_pread64 \
        -p "$pid" -o "$RUN/iouring-stat/$rid.txt" >/dev/null 2>&1 & perfpid=$!
    fi
    cg=""; [ -n "$pid" ] && cg=$(sed -n 's/^0:://p' "/proc/$pid/cgroup" 2>/dev/null)
    d="/sys/fs/cgroup$cg"
    if [ -n "$cg" ] && [ -f "$d/memory.max" ]; then
      printf '%s,%s,%s,%s,%s,%s\n' "$(date +%s.%N)" "$rid" "$cg" "$(cat "$d/memory.current")" \
        "$(cat "$d/memory.max")" "$(awk '$1=="oom_kill"{print $2}' "$d/memory.events")" >> "$RUN/memcap-samples.csv"
    fi
    sleep 1
  done
}

qid_join=$(IFS=,; echo "${QIDS[*]}")
cat > "$RUN/meta.env" <<EOF
PR=$PR
INDEX=$INDEX
ACTION=$ACTION
SCENARIOS=$SCENARIOS
REPS=$REPS
QUERY_IDS=$qid_join
BASE_COMMIT=$BASE_COMMIT
VARIANT_COMMIT=$VARIANT_COMMIT
BASE_BIN=$BASE_BIN
VARIANT_BIN=$VARIANT_BIN
BASE_EXTRA_ARGS=$BASE_EXTRA
VARIANT_EXTRA_ARGS=$VARIANT_EXTRA
THREADS=$THREADS
ADAPTIVE=$ADAPTIVE
BASE_FORM_FIELDS=$BASE_FF
VARIANT_FORM_FIELDS=$VARIANT_FF
LABEL_BASE=$LABEL_BASE
LABEL_VARIANT=$LABEL_VARIANT
VARIANT2_EXTRA_ARGS=$VARIANT2_EXTRA
GRID_ARMS='$(for i in "${!ARM_LABELS[@]}"; do printf '%s=%s;' "${ARM_LABELS[$i]}" "${ARM_EXTRAS[$i]}"; done)'
GRID_DEVS=$GRID_DEVS
LABEL_VARIANT2=$LABEL_VARIANT2
MIN_MEASURE_S=$MIN_MEASURE_S
BINARY_MODE=$BINARY_MODE
HOST=$(hostname)
LAYOUT=$LAYOUT
INDEX_BASENAME=$INDEX_BASENAME
SERVER_MEM_MAX=$MEM_MAX
SERVER_MEM_SCOPE=${MEM_SCOPE_KIND:-}
EOF
mkdir -p "$RUN/queries"
for f in "${QFILES[@]}"; do cp "$f" "$RUN/queries/"; done

# Serving manifest: the recorded one, else every file of the index basename.
if [ -z "$MANIFEST" ] || [ ! -f "$MANIFEST" ]; then
  MANIFEST="$RUN/serving-manifest.txt"
  (cd "$INDEX_DIR" && ls -1 "$(basename "$INDEX_BASENAME")".* | grep -vE 'partial|tmp|unsorted') > "$MANIFEST"
fi

# ---------------------------------------------------------------- build env
{
  echo "# build environment, PR #$PR ($(date -u +%FT%TZ))"
  echo "host: $(hostname) layout: $LAYOUT"
  echo "binary mode: $BINARY_MODE"
  for arm in base variant; do
    if [ "$arm" = base ]; then b="$SNAP_BASE"; src="$BASE_BIN"; c="$BASE_COMMIT"; x="$BASE_EXTRA"
    else b="$SNAP_VARIANT"; src="$VARIANT_BIN"; c="$VARIANT_COMMIT"; x="$VARIANT_EXTRA"; fi
    echo "== $arm"
    echo "source binary: $src"
    echo "expected commit: $c"
    echo "server extra args: ${x:-(none)}"
    echo "--version: $("$b" --version 2>&1 | head -1)"
    echo "md5: $(md5sum "$b" | cut -d' ' -f1)"
    echo "io_uring symbols: $(nm "$b" 2>/dev/null | grep -c io_uring)"
    echo "compiler (.comment): $(readelf -p .comment "$b" 2>/dev/null | grep -m2 -oE '(GCC|clang)[^]]*' | sort -u | tr '\n' ' ')"
    echo "liburing linked: $(ldd "$b" 2>/dev/null | grep -o 'liburing[^ ]*' | head -1)"
    cache="$(dirname "$(readlink -f "$src")")/CMakeCache.txt"
    [ -f "$cache" ] && grep -E '^(CMAKE_BUILD_TYPE|CMAKE_CXX_COMPILER|USE_IO_URING|CMAKE_CXX_FLAGS):' "$cache"
  done
  echo "== toolchain on host"
  (c++ --version 2>/dev/null || g++ --version 2>/dev/null) | head -1
  echo "liburing (pkg-config): $(PKG_CONFIG_PATH=$URAL/liburing-install/lib/pkgconfig pkg-config --modversion liburing 2>/dev/null || echo n/a)"
  echo "perf: $(perf --version 2>/dev/null || echo n/a)"
  echo "python: $("$PY" --version 2>&1)"
  echo "harness md5: $(md5sum "$HARNESS" | cut -d' ' -f1) ($HARNESS)"
} > "$RUN/build-env.txt" 2>&1

# ---------------------------------------------------------------- preflight
IOFLAG=""; [ "$REQUIRE_IOURING" = 1 ] && IOFLAG="--require-iouring"
PSFLAG=""
gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo none)
if [ "$gov" != performance ] && [ ! -w /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
  PSFLAG="--allow-powersave"   # no governor control here; interleaving cancels drift
fi
bash "$H/verify-qlever-binary.sh" "$SNAP_BASE" "$BASE_COMMIT" $IOFLAG > "$RUN/gate-verify-base.log" 2>&1 \
  || die "verify-qlever-binary failed for base (see gate-verify-base.log)"
bash "$H/verify-qlever-binary.sh" "$SNAP_VARIANT" "$VARIANT_COMMIT" $IOFLAG > "$RUN/gate-verify-variant.log" 2>&1 \
  || die "verify-qlever-binary failed for variant (see gate-verify-variant.log)"

# Busy box: hold and retry when loadavg is the only failing gate.
preflight() { # arm binary commit [compare-to]
  local arm="$1" bin="$2" commit="$3" cmp="${4:-}" tries=0 out
  while :; do
    out="$RUN/gate-preflight-$arm.log"
    if bash "$GATE" preflight "$bin" "$commit" $IOFLAG $PSFLAG ${cmp:+--compare-to "$cmp"} > "$out" 2>&1; then
      return 0
    fi
    if grep '^  FAIL' "$out" | grep -qv 'loadavg'; then
      return 1
    fi
    [ "$DRY" = 1 ] && { log "dry run: preflight $arm fails only on loadavg; not holding"; return 0; }
    tries=$((tries + 1))
    [ "$tries" -gt "${HOLD_RETRIES:-24}" ] && return 1
    log "preflight $arm: box busy (loadavg), holding ${HOLD_SLEEP:-300}s ($tries/${HOLD_RETRIES:-24})"
    sleep "${HOLD_SLEEP:-300}"
  done
}
stop_servers
if [ "$BINARY_MODE" = "two binaries" ] && [ "$BASE_COMMIT" != "$VARIANT_COMMIT" ]; then
  preflight base "$SNAP_BASE" "$BASE_COMMIT" "$SNAP_VARIANT" || die "preflight failed (gate-preflight-base.log)"
else
  preflight base "$SNAP_BASE" "$BASE_COMMIT" || die "preflight failed (gate-preflight-base.log)"
fi
preflight variant "$SNAP_VARIANT" "$VARIANT_COMMIT" || die "preflight failed (gate-preflight-variant.log)"
bash "$H/capture-environment.sh" "$RUN/env-before.txt" >/dev/null 2>&1
log "PR #$PR $INDEX $ACTION queries=${QIDS[*]} scenarios=$SCENARIOS reps=$REPS mode=$BINARY_MODE layout=$LAYOUT"
log "base:    $SNAP_BASE ($BASE_COMMIT) args='$BASE_EXTRA' form='$BASE_FF'"
log "variant: $SNAP_VARIANT ($VARIANT_COMMIT) args='$VARIANT_EXTRA' form='$VARIANT_FF'"
[ -n "$VARIANT2_EXTRA" ] && log "variant2: $SNAP_VARIANT ($VARIANT_COMMIT) args='$VARIANT2_EXTRA' label='$LABEL_VARIANT2'"
[ "$DRY" = 1 ] && { log "dry run: setup and preflight OK"; exit 0; }

# ---------------------------------------------------------------- measure
# Only pass -j when it differs from the harness default (1), so older staged
# harness copies without the option keep working.
THREADS_ARG=(); [ "$THREADS" = 1 ] || THREADS_ARG=(--num-simultaneous-queries "$THREADS")
extra_flags() { # "a b c" -> --server-extra-arg=a --server-extra-arg=b ...
  local t; for t in $1; do printf '%s\n' "--server-extra-arg=$t"; done
}
harness() { # arm scenario query-file qid run-id run-dir [extra harness args...]
  local arm="$1" scen="$2" qf="$3" rid="$5" rdir="$6"; shift 6
  local bin extra ff t
  local i; bin="$SNAP_BASE"; ff=""; extra=""
  for i in "${!ARM_LABELS[@]}"; do [ "${ARM_LABELS[$i]}" = "$arm" ] && extra="${ARM_EXTRAS[$i]}"; done
  [ -n "$extra" ] || { loud "unknown arm $arm"; return 1; }
  local -a sx=(); mapfile -t sx < <(extra_flags "$extra")
  local -a fx=(); for t in $ff; do fx+=("--form-field=$t"); done
  local -a px=(); for t in ${MEM_PREFIX[@]+"${MEM_PREFIX[@]}"}; do px+=("--server-prefix-arg=$t"); done
  stop_servers
  local sampler="" hrc gs=""
  if [ -n "$MEM_MAX" ]; then memcap_sample "$rid" & sampler=$!; fi
  mkdir -p "$rdir/raw"; GRID_SAMPLES="$rdir/raw/.samples-$rid.jsonl"; rm -f "$GRID_SAMPLES"
  "$PY" "$GRID_TOOLS/grid-sampler.py" "$GRID_SAMPLES" "$bin" "$GRID_DEVS" 0.2 & gs=$!
  # --server-extra-arg values stay LAST on the command line.
  "$PY" "$HARNESS" --run-id "$rid" --run-dir "$rdir" --query "$qf" \
    --cache-scenario "$scen" --repetitions 1 --mode pilot \
    --qlever-server "$bin" --qlever-repo "$QREPO" \
    --index-dir "$INDEX_DIR" --index-basename "$INDEX_BASENAME" \
    --serving-manifest "$MANIFEST" --action "$ACTION" --accept "$ACCEPT" \
    ${THREADS_ARG[@]+"${THREADS_ARG[@]}"} --min-measure-s "$MIN_MEASURE_S" \
    --hard-timeout-s "${HARD_TIMEOUT_S:-1800}" ${px[@]+"${px[@]}"} "${fx[@]}" "$@" "${sx[@]}" >> "$LOG" 2>&1
  hrc=$?
  if [ -n "$sampler" ]; then kill -TERM "$sampler" 2>/dev/null; wait "$sampler" 2>/dev/null; fi
  kill -TERM "$gs" 2>/dev/null; wait "$gs" 2>/dev/null
  return $hrc
}

# 0 when the arms' min..max elapsed_s ranges overlap (or data is missing).
ranges_overlap() { # scenario qid
  "$PY" - "$RUN/$1/$2/base/raw/results.csv" "$RUN/$1/$2/variant/raw/results.csv" <<'PYEOF2'
import csv, sys
rng = []
for f in sys.argv[1:]:
    try:
        v = [float(r["elapsed_s"]) for r in csv.DictReader(open(f)) if r.get("status") == "complete" and r.get("elapsed_s")]
    except OSError:
        sys.exit(0)
    if not v:
        sys.exit(0)
    rng.append((min(v), max(v)))
(a0, a1), (b0, b1) = rng
sys.exit(0 if max(a0, b0) <= min(a1, b1) else 1)
PYEOF2
}

RC=0
BODY="$RUN/.body"
for i in "${!QFILES[@]}"; do
  qf="${QFILES[$i]}"; qid="${QIDS[$i]}"
  ordered=0; grep -qiE '\bORDER[[:space:]]+BY\b' "$qf" && ordered=1
  for scen in ${SCENARIOS//,/ }; do
    rep=0
    while [ "$rep" -lt "$REPS" ]; do
      rep=$((rep + 1))
      if [ "$ADAPTIVE" = 1 ] && [ "$rep" = 4 ]; then
        if ranges_overlap "$scen" "$qid"; then
          log "adaptive: $qid $scen ranges overlap after 3 reps, running reps 4-$REPS"
          printf '%s\t%s\t%s\n' "$scen" "$qid" "overlap after 3: reps 4-$REPS added" >> "$RUN/adaptive.tsv"
        else
          log "adaptive: $qid $scen ranges disjoint after 3 reps, stopping"
          printf '%s\t%s\t%s\n' "$scen" "$qid" "disjoint after 3: stopped at 3" >> "$RUN/adaptive.tsv"
          break
        fi
      fi
      n=${#ARM_LABELS[@]}; order=""
      for k in $(seq 0 $((n - 1))); do order="$order ${ARM_LABELS[$(( (k + rep - 1) % n ))]}"; done
      for arm in $order; do
        rdir="$RUN/$scen/$qid/$arm"
        rid="pr$PR-$qid-$scen-$arm-r$rep"
        [ "$scen" = cold ] && { "$CLEAR" >> "$LOG" 2>&1 || loud "clear-caches failed before $rid"; }
        rm -f "$BODY"
        harness "$arm" "$scen" "$qf" "$qid" "$rid" "$rdir" --save-body "$BODY" \
          || { RC=1; loud "harness failed: $rid"; }
        # The harness names its per-rep dir rep-001-<scen> on every call;
        # rename it so the next call cannot overwrite this rep's artifacts.
        [ -d "$rdir/raw/rep-001-$scen" ] && mv "$rdir/raw/rep-001-$scen" "$rdir/raw/r$rep-$scen"
        if [ -d "$rdir/raw/r$rep-$scen" ] && [ -f "$GRID_SAMPLES" ]; then
          "$PY" "$GRID_TOOLS/grid-rep-metrics.py" "$GRID_SAMPLES" "$rdir/raw/r$rep-$scen" \
            "$rdir/raw/r$rep-$scen/grid-metrics.json" >> "$LOG" 2>&1 || loud "grid metrics failed: $rid"
          gzip -c "$GRID_SAMPLES" > "$rdir/raw/r$rep-$scen/dev-samples.jsonl.gz" && rm -f "$GRID_SAMPLES"
        fi
        [ -f "$rdir/metadata.yaml" ] && mv "$rdir/metadata.yaml" "$rdir/metadata-r$rep.yaml"
        if [ -f "$BODY" ]; then
          d=$("$PY" "$H/pr-ab-digest.py" "$BODY" 2>&1) || d="digest-failed: $d"
        else
          d="no-body"
        fi
        log "$rid digest $d"
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$scen" "$qid" "$arm" "$rep" "$ordered" "$d" >> "$RUN/correctness.tsv"
        # Keep the reference body (base, first rep) until the query is done,
        # and any body that differs from it, for diagnosis.
        ref="$RUN/.ref-$qid"
        if [ ! -f "$ref.json" ] && [ -f "$BODY" ]; then
          mv "$BODY" "$ref.body"; echo "$d" > "$ref.json"
        elif [ -f "$ref.json" ] && [ -f "$BODY" ]; then
          if ! "$PY" - "$ref.json" "$ordered" "$d" <<'PYEOF'
import json, sys
r = json.load(open(sys.argv[1])); ordered = sys.argv[2] == "1"
try:
    d = json.loads(sys.argv[3])
except ValueError:
    sys.exit(1)
same = d["xxh3_128"] == r["xxh3_128"] or (not ordered and d["multiset"] == r["multiset"] and d["lines"] == r["lines"])
sys.exit(0 if same else 1)
PYEOF
          then
            RC=1
            loud "CORRECTNESS MISMATCH: $rid differs from $qid base rep 1 (bodies kept in mismatch/)"
            mkdir -p "$RUN/mismatch"
            cp -n "$ref.body" "$RUN/mismatch/$qid-reference.body"
            mv "$BODY" "$RUN/mismatch/$rid.body"
            echo "$rid" >> "$RUN/MISMATCH"
          fi
        fi
        rm -f "$BODY"
        log "$rid done"
      done
    done
  done
  rm -f "$RUN/.ref-$qid.body" "$RUN/.ref-$qid.json"
done
stop_servers

# ---------------------------------------------------------------- perf
if [ "$PERF" = 1 ]; then
  if ! command -v perf >/dev/null 2>&1; then
    loud "perf requested but not installed; skipping profiles"
  else
    for i in "${!QFILES[@]}"; do
      qf="${QFILES[$i]}"; qid="${QIDS[$i]}"
      for arm in base variant; do
        pdir="$RUN/perf/$qid/$arm"
        mkdir -p "$pdir"
        harness "$arm" warm "$qf" "$qid" "pr$PR-$qid-perf-$arm" "$pdir/harness" \
          --perf-record "$pdir/perf.data" || loud "perf rep failed: $qid $arm"
        # Not part of the timing: hide the CSV from the gates and aggregators.
        [ -f "$pdir/harness/raw/results.csv" ] && mv "$pdir/harness/raw/results.csv" "$pdir/harness/raw/results-perf.csv"
        if [ -s "$pdir/perf.data" ]; then
          perf report -i "$pdir/perf.data" --stdio --no-children -g none --percent-limit 0.2 2>/dev/null \
            | grep -E '^ +[0-9]' | head -50 > "$pdir/report-top50.txt"
          if [ -f "$FLAMEDIR/stackcollapse-perf.pl" ] && [ -f "$FLAMEDIR/flamegraph.pl" ]; then
            perf script -i "$pdir/perf.data" 2>/dev/null | perl "$FLAMEDIR/stackcollapse-perf.pl" > "$pdir/stacks.folded"
            lbl="$LABEL_BASE"; [ "$arm" = variant ] && lbl="$LABEL_VARIANT"
            perl "$FLAMEDIR/flamegraph.pl" --title "PR #$PR $qid: $lbl" \
              "$pdir/stacks.folded" > "$pdir/flame.svg" 2>/dev/null
          fi
          rm -f "$pdir/perf.data" "$pdir/perf.data.old"
        else
          loud "empty perf.data for $qid $arm (see $pdir/harness/raw/*/perf-record.log)"
        fi
      done
      b="$RUN/perf/$qid/base/stacks.folded"; v="$RUN/perf/$qid/variant/stacks.folded"
      if [ -s "$b" ] && [ -s "$v" ] && [ -f "$FLAMEDIR/difffolded.pl" ]; then
        perl "$FLAMEDIR/difffolded.pl" -n "$b" "$v" | perl "$FLAMEDIR/flamegraph.pl" \
          --title "PR #$PR $qid: base -> variant (red = more in variant)" > "$RUN/perf/$qid/diff.svg" 2>/dev/null
      fi
    done
    stop_servers
  fi
fi

# ---------------------------------------------------------------- gates + conclusion
# COMPLETE markers first: postflight's G10 requires them.
for scen in ${SCENARIOS//,/ }; do echo "ALL DONE $(date -u +%FT%TZ)" > "$RUN/$scen/COMPLETE"; done
echo "ALL DONE $(date -u +%FT%TZ)" > "$RUN/COMPLETE"
for scen in ${SCENARIOS//,/ }; do
  cf=""; [ "$scen" = cold ] && cf="--expect-cold"
  bash "$GATE" postflight "$RUN/$scen" $cf > "$RUN/gate-postflight-$scen.log" 2>&1 || { RC=1; loud "postflight $scen FAILED"; }
done
bash "$H/capture-environment.sh" "$RUN/env-after.txt" >/dev/null 2>&1
"$PY" "$GRID_TOOLS/grid-aggregate.py" "$RUN" > "$RUN/grid.md" 2>> "$LOG" || { RC=1; loud "grid-aggregate failed"; }
cat "$RUN/grid.md" >> "$LOG"
[ -f "$RUN/MISMATCH" ] && loud "CORRECTNESS MISMATCH in $(wc -l < "$RUN/MISMATCH") reps: see $RUN/MISMATCH"
log "finished rc=$RC run=$RUN"
exit "$RC"
