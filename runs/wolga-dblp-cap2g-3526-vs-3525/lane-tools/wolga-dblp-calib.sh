#!/usr/bin/env bash
# Wolga DBLP lane calibration (2026-09-28, author-approved second bench machine).
# Question: does DBLP under a 2 GiB cgroup cap (MemoryMax=2G, MemorySwapMax=0,
# user systemd-run --scope) reproduce the sign and rough size of the Wikidata
# effects of #3526 (ring routing) and #3547 (RWF_NOWAIT page-cache fast path)?
#   pair A: #3526 (0ed8f9223 = src of 07b 1fc82901c without the string.h backport) vs #3525 (533f800b8)
#   pair B: #3547 (42785c8c9, fast path default on) vs #3526 (0ed8f9223); variant2 = same #3547 binary, fast path off
# Binaries: the SAME u24 qlever-server files Ural uses (gcc 13.3, liburing 2.15; 533f800b8/0ed8f9223 from
# the Wolga u24 store, 42785c8c9 = Ural's hosted build, sha256 a856d213...), copied to $L/bin/<sha>/qlever-server.real
# and started through $L/bin/<sha>/qlever-server = exec of the bundled u24 loader
# (/local/data-ssd/stoetzem/wolga-libs/ld-linux-x86-64.so.2 --library-path wolga-libs); Wolga is Ubuntu 22.04
# (glibc 2.35), host-flavor builds have no liburing (SyncIoPolicy fallback), so they cannot be used.
# --require-iouring is replaced by an nm check on the .real files (the wrapper is a shell script).
# DBLP CONSTRUCT turtle export, H-vocab-title-large + H-size, cold + warm, 3 (benchmark length v3)
# interleaved reps per arm (order alternates), no adaptive stop, driver pinned
# to CPUs 0-7. Cold = one execution after evicting ONLY the DBLP index files (evict-dblp-cache.sh, fincore-verified); warm = query looped
# back-to-back until >= 10 s (per-query mean). Byte-identical output per rep.
# wolga-wq appends '--index dblp --server-mem-max <N>G' (from --mem-limit).
set -u
L=/local/data-ssd/stoetzem/wolga-dblp-lane
C=/local/data-ssd/stoetzem/bin-cache
MEM=""
while [ $# -gt 0 ]; do
  case "$1" in
    --index) shift 2 ;;
    --server-mem-max) MEM="$2"; shift 2 ;;
    *) shift ;;
  esac
done
[ -n "$MEM" ] || { echo "FATAL: no --server-mem-max (enqueue with --mem-limit 2)" >&2; exit 2; }
export FLEET_DATA=/local/data-ssd/stoetzem/qlever-indices
export QLEVER_WORKSPACE=/local/data-ssd/stoetzem/qlever
export PR_AB_PYTHON=/local/data-ssd/stoetzem/venv-wolga/bin/python3
export WOLGA_CLEAR_CACHES=$L/evict-dblp-cache.sh   # our-files-only cold (author 21:45): no global drop_caches
export WOLGA_LOAD_MAX=${WOLGA_LOAD_MAX:-4} WOLGA_LOAD_WAIT_MAX=${WOLGA_LOAD_WAIT_MAX:-1200}   # co-tenant load gate per arm (coordinator 21:5x)
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
C=$L/bin
P6=533f800b87ffd1857291e27bc1ce63dacc1ca003
P7=0ed8f9223497196d8979accb24ac737becc42f2b
P8=42785c8c95fda389c06af1cfd567bacff41eaffc
for s in $P6 $P7 $P8; do
  [ -x "$C/$s/qlever-server" ] || { echo "FATAL: missing $C/$s/qlever-server" >&2; exit 2; }
  n=$(nm "$C/$s/qlever-server.real" | grep -c io_uring); [ "$n" -gt 0 ] || { echo "FATAL: no io_uring in $s" >&2; exit 2; }
  echo "binary $s: $("$C/$s/qlever-server" --version | head -1) io_uring_syms=$n sha256=$(sha256sum "$C/$s/qlever-server.real" | cut -c1-64)"
done
common=(--index dblp --action turtle_export --queries H-vocab-title-large,H-size
  --tools-dir "$L/tools" --scenarios cold,warm --reps 3 --no-adaptive
  --min-measure-s 10 --server-mem-max "$MEM")
rc=0
taskset -c 0-7 "$L/pr-ab-multi-v2.sh" --pr 3526 "${common[@]}" \
  --base-bin "$C/$P6/qlever-server" --variant-bin "$C/$P7/qlever-server" \
  --base-commit "$P6" --variant-commit "$P7" \
  --label-base p6-3525 --label-variant p7-3526-routing \
  --run-dir "$L/runs/wolga-dblp-cap2g-3526-vs-3525" || rc=1
taskset -c 0-7 "$L/pr-ab-multi-v2.sh" --pr 3547 "${common[@]}" \
  --base-bin "$C/$P7/qlever-server" --variant-bin "$C/$P8/qlever-server" \
  --base-commit "$P7" --variant-commit "$P8" \
  --label-base p7-3526-routing --label-variant p8-3547-fastpath-on \
  --variant-rp vocabulary-iouring-page-cache-fast-path=true \
  --variant2-rp vocabulary-iouring-page-cache-fast-path=false --label-variant2 p8-3547-fastpath-off \
  --run-dir "$L/runs/wolga-dblp-cap2g-3547-vs-3526" || rc=1
exit $rc
