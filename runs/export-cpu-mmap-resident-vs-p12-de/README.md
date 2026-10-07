# export-cpu-mmap-resident-vs-p12-de: idea 1, copy cached vocabulary words via mmap

A/B on Wikidata truthy (Ural), CONSTRUCT export of the German names of all humans (`H-vocab-label-large-de`), cold and warm, 5 interleaved trials per arm, pinned (server CPUs 0-2, client CPU 3).

- Base `p12`: export stack part 12, `fc954b63`.
- Variant `mmap-resident`: `ca713243` with `vocabulary-mmap-resident-reads=true` (words and offsets files mapped; words whose pages were already read are copied from the mapping without a system call).
- Variant2 `mmap-resident-off`: same binary, parameter off (checks that the binary alone changes nothing).

Result (median, see `conclusion.md`):
- cold: 32.5 s -> 26.1 s (-19.6 %), identical bytes.
- warm: 18.7 s -> 11.4 s (-39.2 %; cycles -31.7 %), identical bytes.

Not included: the two server binaries (`bin/`), kept on Ural.
