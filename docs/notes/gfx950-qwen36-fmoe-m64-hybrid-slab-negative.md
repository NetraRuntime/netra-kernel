# gfx950 Qwen3.6 M64 fused gate/up hybrid-slab result

Status: **validated, retained as a negative experiment, not integrated**.

This experiment targets the highest-ranked post-K0 kernel,
`fmoe_bf16_blockscaleFp8_g1u1_vs_ps_silu_64x256`, for the real Qwen3.6
FP8 E4M3 M64 verification distribution.  The raw wave64 gfx950 kernel fuses
the paired gate/up projection, SiLU, and 128-column FP8 activation
quantization.  It keeps the second N64 half on the safe lower-LDS producer
path, while the first N64 half preloads gate and up into separate 8 KiB LDS
slabs.

The unconditional dual-slab precursor was rejected for correctness.  Its
upper slab overwrote the first N64 half's activation values while the second
half ran, corrupting the shared 128-column scale.  It produced 3,311,135 of
4,718,592 wrong FP8 bytes, a scale maximum error of `3.69395e+35`, and a
completely wrong layer output.  Adding a barrier did not repair this storage
lifetime violation.

The hybrid schedule fixes that lifetime conflict.  On the real M1024 capture
(18,624 valid sorted IDs, 291 M64 blocks, 197 active experts), the predeclared
gates passed:

- FP8 activation mismatches: 101,625 / 4,718,592
- activation-scale maximum absolute error: `3.48776e-05`
- complete-layer structural maximum absolute error: `0.000849761`
- complete-layer structural cosine: `0.999973`
- AITER maximum absolute error: `0.000976562`
- AITER cosine: `0.999965`

HIP-event medians over 100 measured iterations on MI350X/gfx950 were:

| Region | Median |
|---|---:|
| fused gate/up + SiLU + FP8 quantization | 148.900 us |
| raw down projection | 86.300 us |
| deterministic route reduction | 14.5205 us |
| complete raw pipeline | 250.061 us |

The complete hybrid pipeline is 3.13% faster than the retained 257.881 us raw
pipeline, and 5.50% faster than the correct 263.822 us unconditional-loading
prototype.  It remains 10.65% slower than the 226.0025 us packaged AITER
oracle.  It therefore does not meet the production acceptance rule and is not
wired into SGLang.

Artifacts are retained under:

`/data/netra/benchmarks/gfx950_qwen36_optimization/20260801T090000Z-raw-fmoe-m64-fused-quant-gpu4/`

The accepted hybrid run is `run-hybrid-slab100.log`; failed dual-slab runs are
retained beside it.  The corresponding code object, disassembly, metadata,
and hashes are under
`build/gfx950-qwen36-moe-gateup-m64-fused-quant-hybrid-slab/` on the MI350X
host.
