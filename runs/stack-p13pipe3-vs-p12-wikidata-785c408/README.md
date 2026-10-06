# stack-p13pipe3-vs-p12-wikidata-785c408: one-thread three-stage read pipeline (null result)

Fork PR marvin7122/qlever#196 / upstream #3506 research loop, 2026-09-29.
Base = stack part 12 `f8cca285e`; variant = `bench/p13-pipeline3` @ `785c408e6`: on the export thread, the word
reads of sub-batch k+1 and the offset reads of k+2 are in flight while sub-batch k is finished.
3 interleaved trials per arm, warm looped to >= 10 s, byte-identical output.
Every cell is within noise (`conclusion.md`): deeper read overlap on one thread does not shorten the export,
because the export thread does not wait for reads (see `pr196-depth2-cold-diag`).
