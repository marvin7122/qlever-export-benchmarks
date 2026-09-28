# Conclusion for run pr209-send-zc (queue seq 4624) — NULL

## Scope

Send-zerocopy flag A/B on the same binary (b64da088): base
`use-send-zc=false` vs variant `use-send-zc=true`, DBLP H-size
turtle export, warm, 3 reps per arm. Ural bench seq 4624,
2026-09-25, exit 0.

## Validity checks

All 6 reps complete, no zero-byte reps. Bodies identical across
arms (driver rc=0). Warm reads 0 bytes on both arms.

## Result

No measurable difference. Median elapsed: base 0.6401 s vs
variant 0.6453 s (+0.8%), with overlapping rep ranges (base
0.639–0.643 s, variant 0.644–0.657 s). Syscall counts are
identical (285473 both arms), so the flag changes nothing
observable on this query.

## Implication

A null for send-zerocopy on the DBLP H-size export. Recorded
here; no prose change.
