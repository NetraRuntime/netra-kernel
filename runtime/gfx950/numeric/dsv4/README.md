# DSV4 numeric assembly (gfx950)

`Numeric` owns a HIP module and launches handwritten gfx950 assembly on the
caller's current stream. It does not install serving hooks or fall back to
Triton. Build with `tools/benchmark/dsv4_numeric/build.sh BUILD_DIR`.

The nine deployed Triton entry points are implemented by thirteen assembly
bodies. Temperature softmax and classic speculative sampling each use three
ordered launches with caller-owned workspaces. The other operations use one
launch. Independent-row operations have one-wave and four-wave launch variants;
RMS, partial sampling, HC, and tile reductions use cooperative four-wave blocks.

| Operation | Supported specialization |
| --- | --- |
| Flat RoPE | BF16, power-of-two heads/rotary dimension; strided rows, optional integer positions, forward/inverse |
| Hash routing | BF16/FP32 logits; integer token/map indices; FP32 weights, int32 IDs |
| Router | 256 ungrouped BF16 experts and bias; sqrt-softplus, stable smallest-ID ties, shared slots |
| RMS + FP8 | Hidden size 4096, BF16 input/weight, groups of 128, E4M3FN; optional BF16 normalized output, row/column-major scales |
| Online partial/combine | FP32 logits/temperature/noise, int32 greedy flags; 1024-token tiles, at most 128 tiles |
| HC head | BF16 input, HC factor 4, hidden size 4096, FP32 mixer/gates |
| Temperature softmax | FP32, vocabulary at most 131072, per-request temperature sharing |
| Classic speculative sampler | FP32 probabilities/draws, int64 candidates/retrieval indices, int32 acceptance outputs; vocabulary divisible by 16, at most 131072 |

Shapes, dtypes, contiguity, scalar range, and device ownership are checked on the
host without GPU readback. Semantic indices must be valid; output regions must
not collide. Keep modules, pointed-to tensors, and workspaces alive through every
eager or captured-graph use. Each overlapping operation needs independent
workspace ownership. Close a module only after all its GPU uses finish.

RMS assigns four adjacent BF16 values to each lane, keeping normalized values in
registers while it reduces group maxima. Routing holds selected IDs and weights
in registers and writes each output once. A ballot selects the first matching
lane for stable expert ties. Classic sampling deliberately preserves the
reference's distinct sum and inclusive-scan orders: changing associativity can
change a token near a sampling boundary.

Qualification is against AST-extracted bodies from the deployed source, with
output canaries, graph replay, independent streams, and paired GPU timings. The
reference imports and Triton dependency exist only in the validation harness.
See `benchmark_results/dsv4_triton_assembly_20260906` for exact manifests, supported
test shapes, numerical tolerances, and remaining performance limitations.
