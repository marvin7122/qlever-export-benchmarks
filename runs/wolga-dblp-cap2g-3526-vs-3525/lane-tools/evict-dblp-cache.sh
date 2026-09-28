#!/usr/bin/env bash
# Wolga lane "our-files-only cold": evict ONLY the DBLP index files from the
# page cache (posix_fadvise DONTNEED via evict_file_cache.py; no drop_caches,
# so co-tenants' page cache is untouched), then verify residency with fincore.
# Prints resident bytes before/after; exit 1 if > 64 MiB stay resident.
set -u
IDX=${WOLGA_EVICT_DIR:-/local/data-ssd/stoetzem/qlever-indices/dblp}
PY=${PR_AB_PYTHON:-/local/data-ssd/stoetzem/venv-wolga/bin/python3}
EV=/local/data-ssd/stoetzem/wolga-dblp-lane/tools/scripts/evict_file_cache.py
res() { fincore -b -n -o RES "$IDX"/dblp.* 2>/dev/null | awk '{s+=$1} END{print s+0}'; }
before=$(res)
sync "$IDX"/dblp.* 2>/dev/null
"$PY" "$EV" "$IDX"/dblp.* || { echo "evict: evict_file_cache.py failed"; exit 1; }
after=$(res)
if [ "$after" -gt 67108864 ]; then "$PY" "$EV" "$IDX"/dblp.*; after=$(res); fi
echo "our-files-only cold: evicted $IDX/dblp.* resident_before=${before}B resident_after=${after}B (fincore)"
[ "$after" -le 67108864 ] || { echo "evict: ${after}B still resident"; exit 1; }
