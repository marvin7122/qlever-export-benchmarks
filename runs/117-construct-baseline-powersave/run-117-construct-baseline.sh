#!/usr/bin/env bash
set -euo pipefail

root=/local/data-ssd/stoetzem/thesis/experiments/runs/117-construct-baseline-powersave
thesis=/local/data-ssd/stoetzem/thesis
qlever=/local/data-ssd/stoetzem/qlever/construct-memory-instrumentation
harness="$thesis/scripts/benchmark_export_stage_powersave_pilot.py"
python="$thesis/.venv/bin/python"

test ! -e "$root"
mkdir -p "$root"

wait_for_initial_idle_load() {
  local waited=0
  while ! awk '($1 + 0) < 0.5 { exit 0 } { exit 1 }' /proc/loadavg; do
    if (( waited >= 900 )); then
      echo "Initial one minute load average did not fall below 0.5 within 900 seconds" >&2
      exit 1
    fi
    sleep 5
    waited=$((waited + 5))
  done
}

run_cell() {
  local query="$1"
  local cache="$2"
  local first_cell="$3"
  local run_name="${query}-none-${cache}"
  local idle_args=()

  if [[ "$first_cell" == false ]]; then
    idle_args=(--wait-for-idle-load --idle-wait-timeout-s 900 --idle-poll-s 5)
  fi

  "$python" "$harness" \
    --run-id "117-${run_name}" \
    --run-dir "$root/$run_name" \
    --query "$thesis/${query}.rq" \
    --cache-scenario "$cache" \
    --repetitions 5 \
    --load-threshold 0.5 \
    "${idle_args[@]}" \
    --mode pilot \
    --construct-deduplication none \
    --qlever-repo "$qlever" \
    --qlever-server "$qlever/build/qlever-server" \
    --index-dir /local/data-ssd/stoetzem/dblp \
    --index-basename /local/data-ssd/stoetzem/dblp/dblp \
    --serving-manifest "$thesis/experiments/manifests/dblp-serving-files.txt" \
    --port 7026 \
    --require-memory-marker \
    --require-stage-metrics
}

wait_for_initial_idle_load
first_cell=true
for query in H-size H-dedup H-dedup-values; do
  for cache in cold warm; do
    run_cell "$query" "$cache" "$first_cell"
    first_cell=false
  done
done
