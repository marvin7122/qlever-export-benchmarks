#!/usr/bin/env bash
# One-off TTFB measurement for PR #225 (AdaptiveChunkSizer wiring), outside
# the timed pr-ab.sh reps: pr-ab.sh / benchmark_export.py have no ttfb field
# (confirmed: no "time_starttransfer"/"ttfb" string anywhere in pr-ab.sh).
# One curl -w '%{time_starttransfer}' request per arm (flag off / flag on),
# same binary, DBLP H-size-select (tsv), warm (index pages already touched
# by the earlier pr-ab.sh runs on this box), 1 query thread.
set -u
BIN=/local/data-ssd/stoetzem/wt/wire/pr94/build/qlever-server
INDEX_BASENAME=/local/data-ssd/stoetzem/dblp/dblp
QUERY_FILE=/local/data-ssd/stoetzem/thesis/representative-queries/H-size-select.rq
PORT=7351
OUT=/tmp/pr94-ttfb-results.txt
: > "$OUT"

run_one() {
  local label="$1" flag="$2"
  local log=/tmp/pr94-ttfb-server-$label.log
  rm -f "$log"
  "$BIN" --index-basename "$INDEX_BASENAME" --port "$PORT" --no-access-check \
    --cache-max-size 0B --cache-max-size-single-entry 0B --cache-max-size-lazy-result 0B \
    --cache-max-num-entries 0 --default-query-timeout 60s --num-simultaneous-queries 1 \
    --construct-deduplication none \
    --set-runtime-parameter "export-v2-adaptive-chunk-sizing=$flag" \
    > "$log" 2>&1 &
  local pid=$!
  local ready=0
  for _ in $(seq 1 300); do
    if grep -q "The server is ready, listening for requests on port" "$log" 2>/dev/null; then
      ready=1; break
    fi
    sleep 0.1
  done
  if [ "$ready" != 1 ]; then
    echo "$label: SERVER DID NOT START" | tee -a "$OUT"
    kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
    return 1
  fi
  local query
  query=$(cat "$QUERY_FILE")
  # One warm-up request (not timed) so the arm's own caches/allocator are
  # warm, matching the "warm" scenario the pr-ab.sh reps already used.
  curl -s -o /dev/null -X POST "http://127.0.0.1:$PORT" \
    -H "Accept: text/tab-separated-values" \
    -H "Content-Type: application/sparql-query" --data-binary "$query"
  # The timed request: one curl per arm, outside the pr-ab.sh timed reps.
  local timing
  timing=$(curl -s -o /dev/null -X POST "http://127.0.0.1:$PORT" \
    -H "Accept: text/tab-separated-values" \
    -H "Content-Type: application/sparql-query" --data-binary "$query" \
    -w 'time_starttransfer=%{time_starttransfer} time_total=%{time_total} size_download=%{size_download}\n')
  echo "$label (export-v2-adaptive-chunk-sizing=$flag): $timing" | tee -a "$OUT"
  kill "$pid" 2>/dev/null
  wait "$pid" 2>/dev/null
  sleep 1
}

run_one flag-off false
run_one flag-on true

echo "=== $OUT ==="
cat "$OUT"
