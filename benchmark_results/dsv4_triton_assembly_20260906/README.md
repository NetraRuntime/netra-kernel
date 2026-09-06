# DSV4 Triton-to-assembly campaign — in progress

The ledger covers 27 compiled entry-point names in the current TP4×DP2 worker,
plus the source-discovered compressed-tail helper. Cache presence does not prove
execution for every workload. Prior DP8 trace roles establish observed names,
not TP4 latency. Required model math, prefix caching and overlap ownership remain
part of the contract. No assembly from this campaign has been promoted to serving.

## First control group (r47)

Ten operations / eleven assembly bodies passed all 385 exact-output cases against
AST-extracted bodies from the deployed source. Assembly hashes are recorded in the build manifests; the final r48
manifest also covers the expanded validation harness. Cases cover one/four waves, automatic
selection, output canaries, changed-input graph replay, C1–C4-equivalent rows
8/16/24/32, large prefill batches, 1M-equivalent metadata, concurrent streams and
a scatter address above 4 GiB. This is component qualification, not a model-level
accuracy or throughput result. The follow-up r48 run passed 393 cases, including compressed page ratios
1/2/4/8, odd vector tails, non-power-of-two output-token widths, and negative
pages within a compressed tail.

The first smoke run found missing DPP dependency waits. The corrected assembly
passed the subsequent smoke/full runs. Historical failed results are retained.
Final timing uses five shuffled rounds of graph replay; raw per-round numbers
are in `r47/job-06.result.json`. The final 16-row compressed-metadata case with
8,192 compressed indices took 9.031 µs versus 23.094 µs for Triton. A 49,152×512
BF16 scatter took 15.496 µs versus 42.545 µs. These component improvements do not
establish 300 TPS/user or 14K C256 serving throughput.

**Performance is not fully qualified:** prefill lengths, prefill indices and
compressed-tail copies regress at wide 8K-page shapes. For example, 1,024-row
prefill lengths took 12.417 µs versus 7.092 µs. Several ordinary small cases are
near parity. The ledger keeps these tuning requirements open.

Production r36 was restored after the bounded test window. Native, public TLS
and Expo/history checks passed; recovery artifacts are in the server validation
branch. Eight further memory/embedding entry points passed the 246-case r48 suite.
Nine numeric/sampling entry points remain unqualified.

## Build and validate

On a gfx950 ROCm host, build with
`bash tools/benchmark/dsv4_control/build.sh BUILD_DIR`, then run
`python tools/benchmark/dsv4_control/validate.py --build BUILD_DIR --reference-root DEPLOYED_SOURCE_COPY --output result.json`.
The memory group uses the analogous `dsv4_memory` paths. Run isolated GPU checks
only in a drained, bounded window with recovery; do not overlap production work.
The bridge owns HIP modules and launches handwritten assembly; it does not use
HIP-generated compute or secretly fall back to Triton. Reference Triton runs exist
only in the benchmark harness.

## Memory group (r48)

Eight entry points share seven handwritten bodies: safe last-location lookup,
position fill, request-table read/write, causal expansion, prefix/extend table
write, paged allocation, and vocabulary embedding. Prefix sums use wave reductions.
Long outputs are partitioned into disjoint tiles without GPU readback or mutable
shared scratch. The prefix-pointer writer accepts a host `prefix_tokens` work hint;
callers must retain the pointed-to int64 GPU allocations until all eager/graph
uses finish. No prefix memory is inferred from raw pointers on the host.

The final 246 cases include int32/int64 metadata, ragged and empty requests,
partial pages, free-page pointers offset by eight bytes, zero-extension prefix-only
writes, changed-input graph replay, a request-table address above 4 GiB, 1M-token
fills, and BF16 vocabulary sharding/padding. Final source hashes match
`r48/memory-final-manifest.json`; raw timing is `r48/job-04.result.json`.
The initial serial long-fill implementation passed correctness but regressed
badly; tiling fixed that measured bottleneck. A prefix-only 1,048,570-token copy
took 4.907 µs versus 642.830 µs for the Triton reference in the final isolated run.

Performance qualification is still open. Some short prefix-write cases without
a prefix-work hint lag the reference, and some small allocator cases are near
parity or slightly slower. Do not infer model latency, throughput, or long-context
accuracy from these synthetic helper measurements.
