# PrefixCompressor hosted counters (ad-freiburg/qlever#3523)

counters.yml runs (marvin7122/qlever), PrefixCompressorLengthBenchmark (source in this directory), 20,000 words,
PCL_PASSES scaled 1 -> 3, per-item = per decoded word. Tools: DHAT (heap blocks/bytes), callgrind (Ir).

| run | base | variant | args |
|---|---|---|---|
| 36477756160 | #3522 + tool (9583420ae) | #3523 after fix 1 (d22b2acce) | decompress |
| 36477762917 | #3523 as reviewed + tool (4ab8162e7) | #3523 after fix 1 (d22b2acce) | decompress |
| 36477769221 | #3523 as reviewed + tool (4ab8162e7) | #3523 after fix 1 (d22b2acce) | decompress-into |
| 36485900415 | #3522 + tool (9583420ae) | #3523 final head 56f87bdf1 + tool (a5b06793b) | decompress |

Fix 1 = inline contract checks + decompress as concatenation through prefixIndex (e372acc5f);
final = fix 1 with decompress restored unchanged (56f87bdf1). decompressInto code is identical in d22b2acce and a5b06793b.
