#!/usr/bin/env bash
# Night screening batch 1 (Wolga DBLP lane, 2026-09-28 night; supervisor request).
# Counter/direction screening only (counter-screen: 1 counted execution per arm and scenario,
# byte-identity checked). Sets in review order; each set = one counter-screen call per query.
# wolga-wq appends '--index dblp --server-mem-max 2G'.
set -u
L=/local/data-ssd/stoetzem/wolga-dblp-lane; B=$L/bin; CS=$L/counter-screen/counter-screen.sh
MEM=""; while [ $# -gt 0 ]; do case "$1" in --server-mem-max) MEM="$2"; shift 2;; *) shift;; esac; done
[ -n "$MEM" ] || { echo "need --server-mem-max"; exit 2; }
P6=533f800b87ffd1857291e27bc1ce63dacc1ca003; P7=6b71e1e5511344222a7691b1cfa3d3e3fcccf48f; P8=33572f35e64e58e7f0b4d180dde429c8b9ca38fd
P10=3c9b75e971c3c73fc89ad04d38ab7b7a016a4017; P11=67cf2ee3a7640acb2eac4438ba40b883f691f99f; P12=3a19a966f3023c91f345aa59b6ad85ab89655bcf
P13=f9fc54f69d7492a907383e244e291d29de6d8d83; P14=95f657ab9548758a2bbe9c81df147d11f1278aa9; P15=dbaff3f862f15ba6467a26d117fb5e992f106e79; P16=a51fb47a89a71ecf58a512e4c46a74437dafa120
FP=vocabulary-iouring-page-cache-fast-path; CTL=iouring-adaptive-batch-enabled; FMT=use-fast-export-stream-formatter; ACS=adaptive-export-chunk-size
rc=0
run() { # name scen-flags arms...
  local name=$1 sc=$2; shift 2
  for q in H-vocab-title-large H-size; do
    "$CS" --index dblp --server-mem-max "$MEM" --query "$L/tools/queries/$q.rq" --action turtle_export $sc "$@" \
      --out "$L/runs/night1-$name-$q" || rc=1
  done
}
# #3526 / #3547: warm ring cost and fast path (I/O: warm + cold)
run 3526-3547 "--cold" --arm p6-3525=$B/$P6/qlever-server --arm p7-3526=$B/$P7/qlever-server \
  --arm p8-3547-on=$B/$P8/qlever-server,$FP=true --arm p8-3547-off=$B/$P8/qlever-server,$FP=false
# #3529 formatter off/on vs #3528 (CPU: warm only)
run 3529-fmt "" --arm p10-3528=$B/$P10/qlever-server --arm p11-3529-off=$B/$P11/qlever-server,$FMT=false --arm p11-3529-on=$B/$P11/qlever-server,$FMT=true
# #3539 adaptive chunk off/on vs #3529 (CPU: warm only)
run 3539-acs "" --arm p11-3529=$B/$P11/qlever-server --arm p12-3539-off=$B/$P12/qlever-server,$ACS=false --arm p12-3539-on=$B/$P12/qlever-server,$ACS=true
# #3506 / #3476 controller (I/O: warm + cold, traced cold for batch sizes)
run 3506-3476 "--cold --trace-io" --arm p12-3539=$B/$P12/qlever-server --arm p13-3506=$B/$P13/qlever-server \
  --arm p14-3476-off=$B/$P14/qlever-server,$CTL=false --arm p14-3476-on=$B/$P14/qlever-server,$CTL=true
# #3477 / #3499 (I/O: warm + cold)
run 3477-3499 "--cold" --arm p14-3476=$B/$P14/qlever-server --arm p15-3477=$B/$P15/qlever-server --arm p16-3499=$B/$P16/qlever-server
for f in $L/runs/night1-*/*/cold/io-trace.txt; do [ -f "$f" ] && zstd -q -10 --rm "$f"; done
exit $rc
