#!/usr/bin/env bash
# Counter screening entry point (Ural ural-wq entry or Wolga wolga-wq bench).
# Usage (Ural, inside a ural-wq bench entry; the literal '##QBRANCH=<branch>' token goes on the ural-wq line):
#   counter-screen.sh --index dblp|wikidata --query <file.rq> [--action turtle_export] \
#     --arm base=<bin>[,rp=v] --arm variant=<bin>[,rp=v] [--cold] [--strace] --out <run-dir>
# Wolga: add --index dblp (wolga-wq requires it) and pass the u24 loader wrappers as binaries.
set -u
D=$(cd "$(dirname "$0")" && pwd)
U=/local/data-ssd/stoetzem
IDX="" ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --index) IDX="$2"; shift 2 ;;
    --server-mem-max) for t in systemd-run --user --scope --quiet --collect -p "MemoryMax=$2" -p MemorySwapMax=0; do ARGS+=("--server-prefix-arg=$t"); done; shift 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done
if [ -x "$U/clear-caches" ] && [ -d "$U/wikidata" ]; then            # Ural
  export LD_LIBRARY_PATH="$U/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  PY=$U/venv/bin/python3; BASE=$U/$IDX/$IDX; EV=(--evict-cmd "$U/clear-caches")
  [ "$IDX" = wikidata ] && BASE=$U/wikidata/wikidata
else                                                                  # Wolga (our-files-only cold)
  PY=$U/venv-wolga/bin/python3; BASE=$U/qlever-indices/$IDX/$IDX; EV=()
fi
[ -n "$IDX" ] || { echo "need --index dblp|wikidata" >&2; exit 2; }
exec "$PY" "$D/counter_screen.py" --index-basename "$BASE" "${EV[@]}" "${ARGS[@]}"
