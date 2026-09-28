#!/usr/bin/env bash
# Stack part 9/16 (upstream #3527, fork #78): SplitVocabulary::lookupBatch
# synthetic benchmarks under benchmark length v2. Two binaries of the same
# benchmark source: BASE = partitioned lookupBatch as first submitted (repro),
# VARIANT = final head of upstream-stack/07c (in-memory / single-marker fast
# paths). Each process measures three arms on the same vocabulary: sequential
# operator[] (lower bound), fallback sequentialLookupBatch (= the lookupBatch of
# #3547, the previous part) and batched lookupBatch (this part).
# Per binary and benchmark: 3 interleaved (benchmark length v3)
# trials (odd: base first, even: variant first), pinned to core 3. Every timed
# measurement runs >= 10 s (SPLIT_VOCAB_MIN_SECONDS); each process does one
# untimed warm-up pass per arm itself. Then perf stat and perf record (dwarf
# call graphs) of one shorter run (1 s per measurement) per binary.
# usage: p9-split-microbench.sh <base-sha> <variant-sha> <run-dir-name>
set -u
BASE_SHA=$1 VAR_SHA=$2 NAME=$3
U=/local/data-ssd/stoetzem
OUT=$U/thesis/experiments/runs/$NAME
CORE=3 TRIALS=3
MIN_SECONDS=10 PERF_MIN_SECONDS=1
export LD_LIBRARY_PATH=$U/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
mkdir -p "$OUT/raw" "$OUT/perf"
exec > >(tee "$OUT/driver.log") 2>&1
cp "$0" "$OUT/run.sh" 2>/dev/null || true
declare -A BIN
for arm in base variant; do
  sha=$BASE_SHA; [ $arm = variant ] && sha=$VAR_SHA
  for t in SplitVocabLookupBatchMicroBenchmark SplitVocabLookupBatchEndToEndBenchmark; do
    b=$U/bin-cache/$sha/$t
    [ -x "$b" ] || { echo "missing $b"; exit 2; }
    BIN[$arm-$t]=$b
    echo "$arm $t $b sha256 $(sha256sum "$b" | cut -d' ' -f1)"
  done
done
{ echo "host $(hostname)"; date -u +%FT%TZ; uname -r; cat /proc/loadavg; lscpu | grep -E 'Model name|^CPU\(s\)|MHz'; cat /sys/devices/system/cpu/cpu$CORE/cpufreq/scaling_governor 2>/dev/null; free -g;
  echo "base_sha=$BASE_SHA variant_sha=$VAR_SHA core=$CORE trials=$TRIALS min_seconds=$MIN_SECONDS"; } > "$OUT/env.txt"

run() { # arm target trial
  local arm=$1 t=$2 trial=$3 f="$OUT/raw/$t-$arm-$3"
  SPLIT_VOCAB_MIN_SECONDS=$MIN_SECONDS \
    taskset -c $CORE "${BIN[$arm-$t]}" -p -w "$f.json" > "$f.txt" 2>&1 || { echo "FAILED $f"; tail -5 "$f.txt"; exit 1; }
}
for t in SplitVocabLookupBatchMicroBenchmark SplitVocabLookupBatchEndToEndBenchmark; do
  for i in $(seq 1 $TRIALS); do
    if [ $((i % 2)) = 1 ]; then order="base variant"; else order="variant base"; fi
    for arm in $order; do run $arm $t $i; done
    echo "[$(date -u +%T)] $t trial $i done (load $(cut -d' ' -f1 /proc/loadavg))"
  done
done

python3 - "$OUT" <<'PY'
import json, glob, os, sys, csv, statistics as st, collections
out = sys.argv[1]
rows = []
for f in sorted(glob.glob(out + "/raw/*.json")):
    t, arm, trial = os.path.basename(f)[:-5].rsplit("-", 2)
    data = json.load(open(f))
    for cls in data:
        for g in cls["measurements"]["result-groups"]:
            for e in g["result-entries"]:
                md = e["metadata"]
                rows.append(dict(arm=arm, benchmark=t, trial=trial, group=g["descriptor"].split(":")[0],
                                 measurement=e["descriptor"], seconds=e["measured-time"], words=md["words"],
                                 bytes_per_call=md["bytes-per-call"], ns_per_word=1e9 * e["measured-time"] / md["words"]))
with open(out + "/results.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
d = collections.OrderedDict()
for r in rows:
    d.setdefault((r["benchmark"], r["group"], r["measurement"]), {}).setdefault(r["arm"], []).append(r)
def cmp(f, label, B, V):
    mb, mv = st.median(B), st.median(V); dl = 100 * (mv - mb) / mb
    overlap = not (max(V) < min(B) or max(B) < min(V))
    verdict = "parity" if overlap or abs(dl) < 2 else ("faster" if dl < 0 else "slower")
    f.write(f"{label} | {len(B)}/{len(V)} | {mb:.2f} [{min(B):.2f}..{max(B):.2f}] | {mv:.2f} [{min(V):.2f}..{max(V):.2f}] | {dl:+.1f} % | {verdict}\n")
ns = collections.defaultdict(list); secs = []; bpc = collections.defaultdict(set)
for r in rows:
    batch = r["measurement"].split(", ")[-1] if ", " in r["measurement"] else "100k lookups"
    kind = r["measurement"].split(",")[0]
    ns[(r["benchmark"], r["group"], batch, r["arm"], kind)].append(r["ns_per_word"])
    bpc[(r["benchmark"], r["group"], batch)].add(r["bytes_per_call"]); secs.append(r["seconds"])
keys = sorted({k[:3] for k in ns})
with open(out + "/aggregate.txt", "w") as f:
    f.write(f"ns/word, median [min..max] over trials; shortest measurement {min(secs):.1f} s; delta = right vs left;\n")
    f.write("verdict: faster/slower only if ranges do not overlap and |delta| >= 2 %, else parity\n\n")
    for title, a, b in [("A. this part vs previous part's code (same final binary): fallback sequentialLookupBatch -> batched lookupBatch", ("variant","fallback sequentialLookupBatch"), ("variant","batched lookupBatch")),
                        ("B. research loop: batched lookupBatch, as submitted (repro binary) -> final", ("base","batched lookupBatch"), ("variant","batched lookupBatch")),
                        ("C. same code in both binaries (noise check): fallback sequentialLookupBatch repro -> final", ("base","fallback sequentialLookupBatch"), ("variant","fallback sequentialLookupBatch")),
                        ("D. lower bound (final binary): sequential operator[] -> batched lookupBatch", ("variant","sequential operator[]"), ("variant","batched lookupBatch"))]:
        f.write(title + "\nbenchmark | underlying | batch | trials | left ns/word | right ns/word | delta | verdict\n")
        for (bm, g, batch) in keys:
            L = ns.get((bm, g, batch) + a); R = ns.get((bm, g, batch) + b)
            if L and R:
                cmp(f, f"{bm.replace('SplitVocabLookupBatch','').replace('Benchmark','')} | {g} | {batch}", L, R)
        f.write("\n")
    f.write("bytes per call identical across arms and binaries: " + str(all(len(v) == 1 for v in bpc.values())) + "\n")
print(open(out + "/aggregate.txt").read())
PY

# Profiles: one shorter run per binary, pinned; perf stat counters and a dwarf
# call-graph profile.
for arm in base variant; do for t in SplitVocabLookupBatchMicroBenchmark SplitVocabLookupBatchEndToEndBenchmark; do
  p="$OUT/perf/$t-$arm"
  SPLIT_VOCAB_MIN_SECONDS=$PERF_MIN_SECONDS \
    perf stat -e task-clock,cycles,instructions,cache-misses,page-faults,minor-faults -o "$p.stat.txt" \
    taskset -c $CORE "${BIN[$arm-$t]}" -p > "$p.stat-run.txt" 2>&1
  SPLIT_VOCAB_MIN_SECONDS=$PERF_MIN_SECONDS \
    perf record -F 999 --call-graph dwarf,16384 -o "$p.data" \
    taskset -c $CORE "${BIN[$arm-$t]}" -p > "$p.record-run.txt" 2>&1
  perf report -i "$p.data" --no-children --sort symbol --stdio 2>/dev/null | grep -v "^$" | head -80 > "$p.self-top.txt"
  perf report -i "$p.data" --children --sort symbol --stdio -g none 2>/dev/null | grep -v "^$" | head -80 > "$p.children-top.txt"
  rm -f "$p.data"
done; done
echo BENCH_EXIT=0
