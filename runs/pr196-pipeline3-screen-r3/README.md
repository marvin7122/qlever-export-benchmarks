# pr196-pipeline3-screen-r3: three-stage CONSTRUCT pipeline, screening A/B

Fork PR marvin7122/qlever#196. `pr-ab-multi-v2.sh`, Wikidata truthy, 3 interleaved trials per arm,
cold = fresh server after evicting the serving files, warm = query looped to >= 10 s.
Base = stack part 12 `f8cca285e`. Variant = `6d2f7faa` with `construct-export-pipeline-depth=2` and
`construct-export-pipeline-split-lookup=true` (three stages); variant2 = same binary, depth 2, no split (two stages).
Results: `conclusion.md` (variant) and `vs-variant2/conclusion.md`. All bodies are byte-identical.
This queue entry (5296) was enqueued for the two-stage binary `37530faf` and redirected to this A/B before it started.
