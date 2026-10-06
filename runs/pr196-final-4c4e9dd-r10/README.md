# pr196-final-4c4e9dd-r10: three-stage CONSTRUCT pipeline, 10-trial verdict run

Fork PR marvin7122/qlever#196 head `4c4e9ddfe`. `pr-ab-multi-v2.sh`, Wikidata truthy, 10 interleaved trials per arm.
Base = stack part 12 `f8cca285e`. Variant = `4c4e9ddfe` at its defaults (depth 2, split lookup).
Variant2 = same binary with `construct-export-pipeline-depth=0` (previous single-thread evaluation).
All 180 bodies identical; all gates PASS.
Caveat: co-tenant load during the run (loadavg 36.7 at start, 11.3 at end, `env-*.txt`); every arm's times are
higher and wider than in `pr196-pipeline3-screen-r3`.
