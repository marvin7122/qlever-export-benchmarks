# pr196-pipeline3-diag: per-thread CPU of the #196 pipelines

Fork PR marvin7122/qlever#196. Same driver as `pr196-depth2-cold-diag`, one cold and one warm execution
of `H-vocab-label-large-de` per arm, no perf.
Arms: `p12` = stack part 12 `f8cca285e`; `two-stage-d2` and `three-stage-d2` = fork #196 `6d2f7faa` with
`construct-export-pipeline-depth=2`, without and with `construct-export-pipeline-split-lookup`.

Finding (cold): `p12` has one thread with 29.5 s on-CPU in a 30.1 s request.
`three-stage-d2` has two threads with 14.7 s and 14.5 s on-CPU in a 15.7 s request, plus 0.8 s for formatting;
the process CPU is about the same (31.1 s vs 30.7 s). Warm: 10.1 s and 8.8 s in a 10.7 s request.
