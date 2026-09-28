# Conclusion for run wikidata-profile-fibers-fp (queue seq 4246)

## Scope

This run profiles the fibers-plus-routing arm during one cold
scattered German-label CONSTRUCT export on the upgraded new-format
Wikidata truthy index. The binary is `scratch/fp-profile-fibers` at
`2a6701ef9` (fibers-plus-routing plus the scratch-only frame-pointer
flag). Capture is `perf record -F 99 --call-graph fp` on the server
PID for the measured window only. The profile holds 772 samples
across 524 stacks. Shares below carry about 4 points of sampling
noise.

## Validity checks

The profiled request completed with HTTP status 200 in 11.29 s. Its
body hash `497dacfd...` matches the fibers A/B runs exactly, so the
profile covers the measured code path. The collapse yields far more
than 10 stacks, so the frame-pointer build worked. Kernel frames
resolve by name; no `[unknown]` gap affects the user tower.

## User-space breakdown (leaf-frame shares of all samples)

| Component | Share | Top frames |
| --- | ---: | --- |
| Kernel read and irq path | 19.9% | `filemap_get_read_batch`, `xas_load`, `filemap_read` |
| Kernel mm and page handling | 12.9% | `kernel_init_pages`, `rmqueue_bulk`, `__rcu_read_lock` |
| ICU collation inside search | 7.4% | `RuleBasedCollator::doCompare`, `UnicodeSet::contains` |
| FSST word decode | 6.6% | `fsst_decompress` |
| zstd block decode (evaluation side) | 5.2% | `libzstd`, called from `CompressedRelationReader::decompressBlock` |
| libc and stdlib | 3.9% | `libc`, `rep_movs_alternative`, `srso_safe_ret` |
| Allocation and strings | 3.7% | `operator new`, `libjemalloc`, `string::_M_replace` |
| Vocabulary search proper | 2.2% | `lower_bound`, `positionOfIndex` |
| Formatting and emit | 1.6% | turtle and export frames |
| memcpy and memset | 1.3% | `rep_movs_alternative` |
| Ring, fiber, and wait | 0.3% | reap and yield frames |
| Long user tail | ~25% | no single frame above 0.5% |

Stacks passing through vocabulary dispatch hold 81.6% of samples,
so the export lookup path dominates this profile. The zstd share
belongs to query evaluation (`CompressedRelationReader`), not to
the lookup path.

## Interpretation

The thread almost never parks: ring, fiber, and wait leaves total
0.3%. This confirms the CPU-bound diagnosis with independent
evidence. The lookup path costs split into three optimizable
slices. Search comparisons run through ICU locale-aware collation
at 7.4%, which exceeds the 2.2% search proper by a factor of three.
Word decode costs 6.6% in FSST plus 5.2% in zstd on the evaluation
side. Allocation and string growth total about 5%, matching the
older 10 to 14% range after the batch-API work.

The ordered candidate list before any threading work is therefore:
first, the comparator inside vocabulary search (byte compare where
ordering permits, planned against the collation contract); second,
decode (SIMD FSST, fewer zstd block revisits); third, exact-size
buffer reservation from offset pairs (sizes are known before words
arrive). Kernel work near 38% moves with read volume and is not a
code target.
