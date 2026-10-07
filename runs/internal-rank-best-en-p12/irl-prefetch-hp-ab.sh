#!/usr/bin/env bash
# irl-prefetch-hp-ab.sh -- fork PR #264 (perf/internal-rank-lookup): prefetch
# distance sweep, then rank x prefetch x huge pages, then base vs best arm vs
# rank on Wikidata, uncompressed responses
# (harness copy pr-ab-tools-rank2: Accept-Encoding identity, per-trial perf stat
# with cycles, cache-misses, demand DRAM refills, L2 fill wait cycles, dTLB misses).
#   1. sweep: variant binary, rank lookup on, prefetch distance 0/4/8/16/32,
#      English labels warm, 3 interleaved trials (pr-ab-grid.sh).
#   2. best distance B = lowest median elapsed_s among 4/8/16/32.
#   3. factorial (pr-ab-grid.sh, variant binary): rank, rank+prefetch B,
#      rank+huge pages, rank+prefetch B+huge pages; English cold and warm,
#      German warm; 3 interleaved trials.
#   4. best arm = lowest English warm median of step 3.
#   5. pr-ab-multi-v2-3bin-fastgate.sh: base d20a4c74 vs best arm vs rank;
#      English cold and warm with --perf (profile pair base vs best arm,
#      English warm), then German warm; 3 interleaved trials.
# Usage: irl-prefetch-hp-ab.sh <variant-full-sha>
set -uo pipefail
VAR="$1"
I=/local/data-ssd/stoetzem/incoming
C=/local/data-ssd/stoetzem/bin-cache
RUNS=/local/data-ssd/stoetzem/thesis/experiments/runs
BASE=d20a4c74ab76e844364eea53a8ac144ea54729c0
TOOLS=$I/pr-ab-tools-rank2
EN=/local/data-ssd/stoetzem/thesis/representative-queries/wikidata/H-vocab-label-large.rq
DE=$I/pr162-queries/H-vocab-label-large-de.rq
PY=/local/data-ssd/stoetzem/venv/bin/python3
export LD_LIBRARY_PATH=/local/data-ssd/stoetzem/liburing-install/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
V=/local/data-ssd/stoetzem/thesis/scripts/verify-qlever-binary.sh
bash "$V" "$C/$BASE/qlever-server" "${BASE:0:8}" --require-iouring || exit 2
bash "$V" "$C/$VAR/qlever-server" "${VAR:0:8}" --require-iouring || exit 2

SWEEP=$RUNS/internal-rank-prefetch-sweep-p12-identity
arms=()
for d in 0 4 8 16 32; do
  arms+=(--arm "d$d:vocabulary-internal-rank-lookup=true,vocabulary-internal-rank-prefetch-distance=$d")
done
"$I/pr-ab-grid.sh" --pr 264 --index wikidata --action turtle_export --queries "$EN" \
  --tools-dir "$TOOLS" --scenarios warm --reps 3 --no-adaptive --require-iouring --min-measure-s 10 \
  --base-bin "$C/$VAR/qlever-server" --base-commit "$VAR" "${arms[@]}" --run-dir "$SWEEP"
echo "sweep rc=$?"

BEST=$("$PY" - "$SWEEP" <<'EOF'
import csv, glob, statistics, sys
best = None
for d in (4, 8, 16, 32):
    v = []
    for f in glob.glob(f"{sys.argv[1]}/warm/*/d{d}/raw/results.csv"):
        v += [float(r["elapsed_s"]) for r in csv.DictReader(open(f)) if r.get("status") == "complete"]
    if v:
        m = statistics.median(v)
        print(f"d{d} median {m:.3f} n={len(v)}", file=sys.stderr)
        if best is None or m < best[0]:
            best = (m, d)
print(best[1] if best else 16)
EOF
)
echo "best prefetch distance: $BEST" | tee "$SWEEP/best-distance.txt"

R=vocabulary-internal-rank-lookup=true
FACT=$RUNS/internal-rank-prefetch-hugepages-grid-p12
farms=(--arm "rank:$R,vocabulary-internal-rank-prefetch-distance=0,vocabulary-internal-rank-hugepages=false"
  --arm "pf$BEST:$R,vocabulary-internal-rank-prefetch-distance=$BEST,vocabulary-internal-rank-hugepages=false"
  --arm "hp:$R,vocabulary-internal-rank-prefetch-distance=0,vocabulary-internal-rank-hugepages=true"
  --arm "pf$BEST-hp:$R,vocabulary-internal-rank-prefetch-distance=$BEST,vocabulary-internal-rank-hugepages=true")
gcommon=(--pr 264 --index wikidata --action turtle_export --tools-dir "$TOOLS" --reps 3 --no-adaptive
  --require-iouring --min-measure-s 10 --base-bin "$C/$VAR/qlever-server" --base-commit "$VAR" "${farms[@]}")
"$I/pr-ab-grid.sh" "${gcommon[@]}" --queries "$EN" --scenarios cold,warm --run-dir "$FACT-en"
echo "grid en rc=$?"
"$I/pr-ab-grid.sh" "${gcommon[@]}" --queries "$DE" --scenarios warm --run-dir "$FACT-de-warm"
echo "grid de rc=$?"

BESTARM=$("$PY" - "$FACT-en" "$BEST" <<'EOF2'
import csv, glob, statistics, sys
run, d = sys.argv[1], sys.argv[2]
params = {"rank": (0, "false"), f"pf{d}": (d, "false"), "hp": (0, "true"), f"pf{d}-hp": (d, "true")}
best = None
for arm, (dist, hp) in params.items():
    v = []
    for f in glob.glob(f"{run}/warm/*/{arm}/raw/results.csv"):
        v += [float(r["elapsed_s"]) for r in csv.DictReader(open(f)) if r.get("status") == "complete"]
    if v:
        m = statistics.median(v)
        print(f"{arm} median {m:.3f} n={len(v)}", file=sys.stderr)
        if best is None or m < best[0]:
            best = (m, arm, dist, hp)
print(f"{best[1]} {best[2]} {best[3]}" if best else f"pf{d}-hp {d} true")
EOF2
)
read -r BARM BDIST BHP <<< "$BESTARM"
echo "best arm: $BARM distance=$BDIST hugepages=$BHP" | tee "$FACT-en/best-arm.txt"

common=(--pr 264 --index wikidata --action turtle_export --tools-dir "$TOOLS" --reps 3 --no-adaptive
  --require-iouring --min-measure-s 10
  --base-bin "$C/$BASE/qlever-server" --base-commit "$BASE" --label-base stack12-22-d20a4c74
  --variant-bin "$C/$VAR/qlever-server" --variant-commit "$VAR"
  --variant-rp "$R" --variant-rp "vocabulary-internal-rank-prefetch-distance=$BDIST"
  --variant-rp "vocabulary-internal-rank-hugepages=$BHP" --label-variant "$BARM-${VAR:0:8}"
  --variant2-rp "$R" --variant2-rp vocabulary-internal-rank-prefetch-distance=0
  --variant2-rp vocabulary-internal-rank-hugepages=false --label-variant2 "rank-${VAR:0:8}")
"$I/pr-ab-multi-v2-3bin-fastgate.sh" "${common[@]}" --queries "$EN" --scenarios cold,warm --perf \
  --run-dir "$RUNS/internal-rank-best-en-p12"
echo "ab en rc=$?"
"$I/pr-ab-multi-v2-3bin-fastgate.sh" "${common[@]}" --queries "$DE" --scenarios warm \
  --run-dir "$RUNS/internal-rank-best-de-warm-p12"
echo "ab de rc=$?"
