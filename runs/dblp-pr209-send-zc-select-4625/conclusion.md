# Conclusion for run pr209-send-zc-select (queue seq 4625) — NULL

## Scope

Send-zerocopy flag A/B on the same binary (b64da088): base
`use-send-zc=false` vs variant `use-send-zc=true`, DBLP
H-size-select CSV export, warm, 5 reps per arm. Ural bench seq
4625, 2026-09-25, exit 0.

## Validity checks

All 10 reps complete, no zero-byte reps. Bodies identical across
arms (driver rc=0). Warm reads 0 bytes on both arms.

## Result

No measurable difference. Median elapsed: base 2.5630 s vs
variant 2.5504 s (-0.5%), with fully overlapping rep ranges
(base 2.50–2.64 s, variant 2.52–2.67 s). Syscall counts are
identical (2708170 both arms). Together with the H-size null
(seq 4624), send-zerocopy shows no observable effect on either
DBLP export query.

## Implication

Recorded here; no prose change.
