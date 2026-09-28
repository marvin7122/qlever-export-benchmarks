# Conclusion for run wikidata-nvme-engaged-ab (Hetzner AX41)

## Scope

First end-to-end measurement of the NVMe passthrough read path on real
hardware. Both arms run the same `qlever-server` binary
(`bench/ch7-nvmept` at `c76bd21ab`, with the NVM Read opcode fix, the
fail-closed single-word reads, and the EOF spin fix). The baseline arm
reads the words file from the md RAID on `nvme0n1`. The passthrough arm
reads a byte-verified copy of the same file from the spare drive
`nvme1n1` through `/dev/ng1n1` with `QLEVER_NVME_PASSTHROUGH=1:512`.
Each arm runs alone: the other server is stopped, and the page cache
is dropped before each cold repetition. One warm and two cold
repetitions of `large-de` and `scatter200k-de`, posted (the scatter
query exceeds the GET URI limit).

## Validity checks

All measured requests returned HTTP 200. Sequential bodies share
SHA-256
`dcd2b1bc77fce98409640e9a234aa92688de7ba54eeff9c0556752e814f8c5e1`
on both arms, matching the Ural era-2 reference hash. Scattered bodies
share SHA-256
`497dacfdffcc71ac2acc3f748140e9d6b27586f7d7b743ccdb98289101fb4ad9`
on both arms. The passthrough path returns byte-identical results.
The run directory carries the COMPLETE marker.

## Result

Cold sequential means are 24.348 s for the baseline and 28.490 s for
passthrough (+17.0%). Cold scattered means are 4.798 s and 4.148 s
(-13.5%). Warm means lose on both workloads: 15.302 s vs 24.269 s
sequential (+58.6%), 2.747 s vs 3.856 s scattered (+40.3%).
Passthrough helps cold scattered reads and hurts everything else in
this single run.

## Interpretation and caveats

The warm losses are expected: passthrough bypasses the page cache by
design, so warm data pays full device latency on every read. The cold
sequential loss points at read amplification from whole-block
coalescing plus the missing block-layer readahead and merging. The
arms read from different drives: buffered sequential reads measure
1409 MB/s on `nvme0n1` and 1730 MB/s on `nvme1n1`, so the faster drive
carries the slower sequential result (which strengthens that finding)
while the scattered gain carries a drive-speed confound. Single run
with no repeats; no per-CPU breakdown was collected.
