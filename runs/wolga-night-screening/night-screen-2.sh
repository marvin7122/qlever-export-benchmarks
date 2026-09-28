#!/usr/bin/env bash
# Night screening batch 2 (Wolga DBLP lane): CPU-side parts, warm only, counter-screen
# (1 counted warm execution per arm, cpu_s + counters, byte identity). #3522 (04) vs #3521 (03);
# #3524 (06a) vs #3523 (05). Binaries: Wolga u24 builds 257-260. wolga-wq appends --index dblp --server-mem-max.
set -u
L=/local/data-ssd/stoetzem/wolga-dblp-lane; B=$L/bin; CS=$L/counter-screen/counter-screen.sh
MEM=""; while [ $# -gt 0 ]; do case "$1" in --server-mem-max) MEM="$2"; shift 2;; *) shift;; esac; done
[ -n "$MEM" ] || { echo "need --server-mem-max"; exit 2; }
P2=9bf5b86eab2c0c7c44063231e371aeb5e239eec1; P3=f73853be2b37a1e081d6ac4504914d5d16a795d0
P4=56f87bdf1b622d2c4549dc2473705b9492261e9c; P5=a7bf5f8fe139c0a320fd1ecefdd72d73228758c0
rc=0
for q in H-vocab-title-large H-size; do
  "$CS" --index dblp --server-mem-max "$MEM" --query "$L/tools/queries/$q.rq" --action turtle_export \
    --arm p2-3521=$B/$P2/qlever-server --arm p3-3522=$B/$P3/qlever-server \
    --arm p4-3523=$B/$P4/qlever-server --arm p5-3524=$B/$P5/qlever-server \
    --out "$L/runs/night2-3521-3524-$q" || rc=1
done
exit $rc
