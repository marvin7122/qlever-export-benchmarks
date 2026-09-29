# PR #199 A/B on dblp (csv_export)

- Base: `c75e1927` base: --memory-max-size=16GB; server args: `--memory-max-size=16GB`
- Variant: `47dda163` variant: --memory-max-size=16GB; server args: `--memory-max-size=16GB`
- Binaries: two binaries; host `ural` (ural layout)
- Server query threads (`--num-simultaneous-queries`): 1
- Reps (adaptive): 3 per arm and cell first; reps 4-5 only when the two arms' min..max ranges overlapped after 3 (`adaptive.tsv`); column n gives the reps per cell. Arms interleaved per rep, order alternating (odd reps base first, even reps variant first); cold reps run after `clear-caches`.
- Noise rule: within noise when |delta| < 1% or the min..max ranges overlap.

## Timing (elapsed_s, end to end)

| query | scenario | arm | n | median | min | max | delta vs base | verdict | correctness |
|---|---|---|---|---|---|---|---|---|---|
| E-count-star-join-2-large-large | warm | base: --memory-max-size=16GB | 5 | 0.3938 | 0.3710 | 0.4334 |  |  |  |
| E-count-star-join-2-large-large | warm | variant: --memory-max-size=16GB | 5 | 0.3331 | 0.3224 | 0.3832 | -15.41% | within noise | identical bytes |

## Verdict

- E-count-star-join-2-large-large warm: within noise (-15.41%); correctness: identical bytes

## Gates

- `gate-postflight-warm.log`: == POSTFLIGHT: PASS ==
- `gate-preflight-base.log`: == PREFLIGHT: PASS ==
- `gate-preflight-variant.log`: == PREFLIGHT: PASS ==
- `gate-verify-base.log`: VERDICT: PASS — binary is trustworthy for benchmarking
- `gate-verify-variant.log`: VERDICT: PASS — binary is trustworthy for benchmarking

## Profiles

One extra warm rep per arm and query under `perf record -g` (not part of the timing): `perf/<query>/<arm>/` holds `report-top50.txt`, `stacks.folded` and `flame.svg` when FlameGraph was available; `perf/<query>/diff.svg` is the base-to-variant differential.

## Problems

None: every rep complete, non-empty and correct.

Artifacts: `results.csv` (all reps), `<scenario>/<query>/<arm>/raw/` (harness output per rep), `correctness.tsv`, `build-env.txt`, `env-before.txt`, `env-after.txt`, `gate-*.log`, `driver.log`.

## Analysis (research loop, after the fix)

Ural seq 4714. Base master `c75e1927`, variant `47dda163` (with the fix), warm, 5 reps
(adaptive, ranges overlapped after 3), 16 GB both arms.

Median -15.41 % (0.3938 s vs 0.3331 s), identical bytes. Ranges overlap (variant rep 2
0.3832 s > base min 0.3710 s), so by the noise rule the verdict is within noise; 4 of the 5
variant reps are below every base rep. Before the fix (seq 4656, `f35642f3`): -12.02 %, ranges
disjoint.

Profile: merge 0.25e9 samples (seq 4699: 0.96e9 before the fix) vs master's join 1.30e9;
zstd 3.00e9 / 3.28e9. As on Wikidata, decompression is the floor.
