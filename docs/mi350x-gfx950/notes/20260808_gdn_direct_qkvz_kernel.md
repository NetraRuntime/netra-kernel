# gfx950 direct-QKVZ GDN M=12 kernel

The raw assembly kernel consumes `[B*12,12288]` BF16 QKVZ rows, applies the
width-four BF16 causal convolution and SiLU to the first 8192 features, updates
the live convolution state and all twelve speculative intermediate windows,
and emits packed `[B*12,8192]` QKV.

At graph batch 64, comparison against the production split plus convolution
path was bit-exact for all 6,291,456 QKV values, 1,572,864 state values, and
18,874,368 intermediate-window values in eager and graph replay.  Median graph
time improved from 38.201 us to 26.001 us (1.469x).  The companion direct-Z
RMSNorm test was bit-exact at 12, 96, 384, and 768 tokens in eager and graph
execution.

An earlier fused copy-plus-convolution variant was also exact but reached only
30.24 us (1.262x).  It remains in the tree with its harness as negative design
evidence; production integration selects the direct-QKVZ kernel.

Raw targeted gfx950 assembly lives here in netra-kernel.  The server repository
contains only graph-safe loading, dispatch, and model integration.

Evidence: `/data/netra/benchmarks/gfx950_qwen36_optimization/20260808T213000Z-qwen36-fused-split-conv-gpu0/`.
