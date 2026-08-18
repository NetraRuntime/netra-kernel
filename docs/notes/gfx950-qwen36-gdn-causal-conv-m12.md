# gfx950 Qwen3.6 M=12 GDN causal convolution

Status: accepted incremental replacement, 2026-08-02.

The production target-verification shape is `B=1..64, M=12, D=8192,
width=4`, BF16 input/state/output with SiLU. Qwen weights remain FP8 E4M3
with 128x128 blocks and KV storage remains FP8 E4M3; this kernel only replaces
the model-native BF16 GDN convolution.

The raw implementation is
`kernels/gfx950/linear_attention/verify/qwen36_gdn_causal_conv_m12_gfx950.s`.
It targets gfx950 and wave64 directly. The HIP bridge only loads the code
object and launches it on the caller stream. The exact real-checkpoint harness
is `tools/benchmark/qwen36_causal_conv1d_update_m12_real.py`.

## Correctness

The retained layer-0 target-verification capture was reconstructed with the
live SGLang strides:

- input `(64,8192,12)`, stride `(98304,1,8192)`;
- state `(64,8192,3)`, stride `(24576,3,1)`;
- intermediate window `(64,12,8192,3)`, stride `(294912,24576,3,1)`.

Against the captured Triton result, the raw kernel was bit-exact for all
6,291,456 outputs, 1,572,864 final-state values, and 18,874,368 speculative
window values. The piecewise-graph server captured and launched successfully.
Candidate and current production produced the same stable token hash for six
sequential 210-input/128-output requests. GSM8K 5-shot, non-thinking, 200
questions measured 0.960 candidate versus 0.965 control; one question is well
within the 200-sample error and the retained AITER MoE path is nondeterministic.

## Performance

On one otherwise free MI350X, 100 HIP-event samples on the exact real layout:

| implementation | median | mean | p90 |
|---|---:|---:|---:|
| deployed Triton wrapper | 44.860 us | 45.232 us | 47.840 us |
| raw gfx950 | 21.700 us | 21.931 us | 22.280 us |

The raw interval is 2.067x faster. The newest-state c64 serving A/B (192
measured 1024-input/256-output requests per side) was 4,382.684 versus
4,375.158 output token/s, +0.172%. This agrees with the source region's small
~0.46% share of request wall time.

Code-object metadata reports wave64, 33 VGPR, 34 SGPR, zero LDS, and zero
scratch. rocprofv3 retained seven exact dispatches per counter pass. Median
counters were 8,192 waves, 4,268,032 VALU instructions, 434,176 VMEM
instructions, 531,808 TCC read sectors, 2,949,120 TCC write sectors, 34.04%
occupancy, and 12.90% `MemUnitStalled`. Profiler resource fields report 20 VGPR
and 48 SGPR allocation, zero AGPR/LDS/scratch, a 524,288-thread grid, and a
256-thread workgroup.

Artifacts are under:

- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T051000Z-gdn-conv-m12-liveabi-raw-gpu1/`
- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T052000Z-gdn-causal-conv-m12-serving-v3-gpu1/`

The next variant should fuse the contiguous QKVZ/BA split with convolution and
compact the speculative window. This accepted kernel intentionally preserves
the existing full-window ABI so the arithmetic and graph integration are
independently validated first.
