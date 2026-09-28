# Conclusion for run 117

## Scope

Run 117 establishes a focused baseline for three existing CONSTRUCT workloads.
It uses the `none` deduplication mode, cold and warm cache scenarios, and five
measured repetitions per condition. The run is not a general QLever
benchmark. It uses the instrumented Release binary that was already built on
Ural from the official QLever master commit plus the archived measurement
instrumentation.

## Validity checks

All 30 measured requests completed with HTTP status 200. Every repetition
contains the required stage metrics and process memory marker. The response
size, candidate result triple count, and emitted result triple count remain
stable within each condition. The measured repetitions contain no major page
fault or swap activity.

## Client observed time

| Workload | Cache state | Median | Minimum | Maximum |
| --- | --- | ---: | ---: | ---: |
| `H-size` | cold | 3.643 s | 3.632 s | 3.680 s |
| `H-size` | warm | 0.595 s | 0.593 s | 0.608 s |
| `H-dedup` | cold | 1.787 s | 1.783 s | 1.814 s |
| `H-dedup` | warm | 0.294 s | 0.291 s | 0.296 s |
| `H-dedup-values` | cold | 1.832 s | 1.824 s | 1.866 s |
| `H-dedup-values` | warm | 0.338 s | 0.338 s | 0.348 s |

The large difference between cold and warm conditions shows that these
workloads are sensitive to the page cache state. The internal stage metrics
attribute most of the cold cache client observed time to non root response
production. Within that interval, batch evaluation and the associated RDF
term resolution account for most of the measured time. Root operation
execution accounts for only a small part of each cold cache request.

The warm cache measurements reduce the batch evaluation contribution
substantially. Formatting, response stream processing, and HTTP delivery then
represent a larger fraction of the client observed time. The residual timer
still combines several activities and must not be described as pure
serialization time.

## Interpretation and limits

The result provides a concrete baseline for locating later export path
improvements. It supports investigating batched vocabulary lookup before
optimizing root query execution for these workloads. It does not establish
that the same component dominates other queries, other datasets, or another
machine configuration.

The server retained the host's existing powersave policy. The run changed no
processor governor setting. The baseline used the instrumentation build and
the `none` deduplication mode. A controlled before and after experiment is
still required for every proposed optimization.

## Artefacts

The complete raw run and full stage analysis remain on Ural at
`/local/data-ssd/stoetzem/thesis/experiments/runs/117-construct-baseline-powersave`.
The local directory contains the exact driver, analyzer, client observed
summary, and this conclusion. The driver records the binary, index, queries,
cache protocol, repetition count, load gate, and server port.
