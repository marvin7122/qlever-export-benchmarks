# Validation of the legacy export timing diagnostic

## Question

Issue 62 asks whether the `Export finished in ... ms` diagnostic can serve as
an isolated export phase metric alongside client observed end to end time.

## Source result

The diagnostic does not exist on official QLever master commit
`65f84b43d86b6ceb887d7a15dd5d387b2fc18a7a`. Searching that source for the log
message and its regular expression yields no source location. Consequently,
`scripts/benchmark_export.py` leaves `export_time_ms` and `export_time_s` empty
when it runs an unmodified binary from this commit.

The diagnostic exists on the local instrumentation branch
`export-time-primary-metric`. Commit
`545b583e924c101f4c51d3c492233a696bbb91cd` adds the timer in
`src/engine/Server.cpp`, lines 1023 to 1030 at that commit. The timer starts
after QLever creates the lazy response generator, constructs the HTTP response,
and applies response middleware. It starts immediately before
`co_await send(std::move(response))`. It stops after that asynchronous send
returns.

## Exact boundary

The instrumented timer excludes request receipt, SPARQL parsing, query
planning, response generator construction, HTTP response object construction,
and response middleware work performed before the call to `send`.

The timer includes consumption of the lazy response generator, RDF term
resolution, result formatting, response stream plumbing, socket writes, and
time for which sending is delayed by client or network backpressure. QLever can
also produce result tables lazily. Root operation work that occurs while the
response generator is consumed is therefore inside this interval. Query
execution and export can interleave inside the timed call.

The diagnostic is consequently a server side response send interval. It is
not an isolated measurement of serialization or of the export path alone. Its
name overstates what it isolates.

## Client observed boundary

`scripts/benchmark_export.py` starts its client timer immediately before the
HTTP POST. It stops after `httpx` yields the final response byte. This interval
includes client request setup, server request processing, query planning,
query execution, result production, serialization, and response transfer.

The harness stores this value in `elapsed_ns` and `elapsed_s`. It parses the
last server log marker separately into `export_time_ms` and `export_time_s`.
The two values therefore have separate fields and separate clocks.

## Focused parser validation

`validate_export_time_parser.py` creates a synthetic server log containing a
warmup marker and a later measured marker. It verifies that the harness selects
the final marker and that the client elapsed value is stored independently.
The validation command is:

```text
python3 experiments/runs/116-export-time-boundary-validation/validate_export_time_parser.py
```

The command passed on 2026 08 10 and produced:

```json
{"harness": "/home/userNoPriv/thesis/scripts/benchmark_export.py", "independent_client_elapsed_ns": 123456789, "parsed_last_export_marker_ms": 47, "status": "passed"}
```

## Decision for later measurements

Later reports must retain client observed end to end time as the primary
metric. They must not label the legacy diagnostic as isolated export time. If
the diagnostic is used for an instrumented branch, it should be named server
response send time and its inclusion of lazy root execution and response
transfer must be stated.

Run 115 uses more specific diagnostic timers. Even those timers are interpreted
with their lazy interleaving caveat. The derived non root response stream time
contains export processing, formatting, stream plumbing, and HTTP delivery. It
is not pure serialization time.

## Limitations

The focused validation tests the harness parser without running a benchmark.
It does not validate a marker on official master because official master does
not emit one. The source inspection, rather than a timing subtraction,
establishes which work the instrumentation branch places inside the timer.
