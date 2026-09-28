# NVMe passthrough optimization arc (Hetzner AX41, exact 7.7 workloads)

Follow-up to `../wikidata-nvme-engaged-ab/conclusion.md`. This arc uses
the same machine (Hetzner AX41), the same index paths (baseline on
regular files, passthrough with the external words file on `/dev/ng1n1`),
and the same binary series on `bench/ch7-nvmept`. All wall clock times
are cold-cache end-to-end times per request, and hashes pin every body
below.

## Baseline exact-workload A/B (gap-32 binary, `1:512`)

| Workload | Baseline cold | Passthrough cold | Delta |
|---|---|---|---|
| `H-vocab-label-large-de` sequential | 24.28 / 24.27 s, `dcd2b1bc` | 27.94 / 27.94 s, `dcd2b1bc` | +15.1% |
| `H-vocab-random-label-de-200k` scattered | 4.78 / 4.84 s, `497dacfd` | 4.50 / 4.09 s, `497dacfd` | -10.6% |

Cross-arm hashes match, so both arms compute identical result sets. The
split verdict from the engaged run reproduces on the byte-exact 7.7 files.

## Granularity counters (new instrumentation)

One cold sequential export issues 4,065,326 native reads totaling
2,211,796,480 bytes (average 544 bytes per read) across 8,704 waits, with
zero capable-fd fallbacks. The result holds about 4.2 million label
triples, so the path issues nearly one NVMe command per word. The G0
allowance reproduces these counters bit-for-bit, so the workload is
deterministic and the A/B comparisons are trustworthy.

## Gap sweep (batch size 1024 rows)

| Allowance | Wall clock | Commands | Bytes |
|---|---|---|---|
| 0 blocks | 29.15 s | 4.07M | 2.21 GB |
| 1 block | 28.85 s | 3.95M | 2.27 GB |
| 4 blocks | 28.58 s | 3.77M | 2.53 GB |
| 32 blocks | 28.52 s | 3.36M | 5.58 GB |

Merging helps monotonically but with diminishing returns. All bodies
carry `dcd2b1bc`.

## Failed interventions (kept as negative results)

- 8192-row batches cut waits 7x (8,704 to about 1,200) but slowed the
  export to 29.53 s, because bigger batches drain more work per wait and
  merge more gap bytes (6.6 GB). Reverted.
- Synchronous range preads for offsets produced deterministically wrong
  output (121,635,066 bytes, `0c7e0545`, twice byte-identical) while a
  5-word unit test passed, so the trigger is scale-dependent. Reverted in
  `967c8cfaa`; the root cause is still open and blocks any retry.

## Fiber overlap (kept)

Paired (depth 2) and quadrupled (depth 4) consecutive row blocks run as
cooperating fibers on one thread. They share the idCache and the manager
pool and interleave only at I/O waits, with this outcome:

| Depth | Wall clock | Waits | Hash |
|---|---|---|---|
| 1 (serial) | 28.74 s | 8,704 | `dcd2b1bc` |
| 2 | 27.18 s | 8,704 | `dcd2b1bc` |
| 4 | 27.12 s | 8,704 | `dcd2b1bc` |

Waits are identical, so the 1.56 s gain comes purely from hiding stalls
behind concurrent waves. Depth 4 adds nothing further, so overlap
saturates at depth 2 and the remainder is device service time. Scatter on
the depth-4 binary runs 4.47 s cold (`497dacfd`), so the scattered win
survives overlap.

## Anomaly (open, validity unaffected)

The first scattered query on a fresh passthrough server returns HTTP 200
with a truncated body three times (1 MB, then 8 MB twice, same hash for
both 8 MB bodies), while baseline first-scattered queries return full
bodies and all cold repetitions agree byte-for-byte. Warm repetitions are
discarded by protocol, and every cold number above is hash-verified, so
no filed result depends on the anomaly. It needs a separate streaming
investigation.

## Verdict

Passthrough with gap-32 merging and depth-2 fiber overlap closes the
sequential gap from +19% to +12% (27.18 s against 24.27 s) with identical
bytes, while scattered keeps a 10% win. The remaining gap is per-command
cost plus gap bytes on a workload with no exploitable locality. The
offsets wait (half the 8,704 waits) is the largest known unaddressed
item, pending root-cause analysis of the reverted attempt.
