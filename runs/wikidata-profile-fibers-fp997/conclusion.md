# Conclusion for run wikidata-profile-fibers-fp997 (queue seq 4250)

## Scope

This run re-profiles the fibers-plus-routing arm at 997 Hz after
the 99 Hz profile (run wikidata-profile-fibers-fp, 772 samples)
left the small shares noise-limited. Same arm, binary
`scratch/fp-profile-fibers` at `2a6701ef9`, same cold scattered
German-label export on the upgraded new-format index, same
`--call-graph fp` capture. The profile holds 7310 samples across
2797 stacks. Share noise is about 0.3 points for mid-size slices
and 0.1 for the smallest.

## Validity checks

The profiled request completed with HTTP status 200 in 10.98 s.
Its body hash `497dacfd...` matches the A/B runs and the 99 Hz
profile exactly. The collapse yields far more than 10 stacks.

## User-space breakdown (leaf-frame shares of all samples)

| Component | 997 Hz | 99 Hz before |
| --- | ---: | ---: |
| Kernel (reads, faults, RAID) | 60.0% | 58.3% |
| FSST word decode | 5.4% | 6.6% |
| zstd block decode (evaluation side) | 5.7% | 5.2% |
| ICU comparison inside search | 5.0% | 7.4% |
| Allocation and strings | 4.3% | 4.7% |
| libc and stdlib | 4.1% | 3.9% |
| Vocabulary search proper | 2.4% | 2.2% |
| Formatting, copies, wait, long tail | 13.1% | 12.5% |
| Ring, fiber, and wait leaves | 0.2% | 0.3% |

Stacks passing through vocabulary dispatch hold 82% of samples,
unchanged from before.

## Interpretation

The tighter profile confirms the structure and revises two
details. Ring, fiber, and wait leaves now read 0.2% with 0.1
points of noise, so the never-parks claim is significant. Word
decode totals 11.1% and passes ICU comparison at 5.0% as the
largest user slice. The ICU revision from 7.4% exceeds old-profile
noise and likely mixes cold-state variance with the small sample
count; it stays second on the candidate list either way. The
ordered candidates are unchanged: comparator, decode,
exact-size reservation.
