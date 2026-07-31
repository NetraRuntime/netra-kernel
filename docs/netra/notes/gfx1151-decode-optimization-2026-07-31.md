# gfx1151 decode optimization update — 2026-07-31

All numbers in this note are for AMD Ryzen AI Max+ PRO 395, `gfx1151`.
GPU timings are measured with HIP events or rocprofv3. Serving timings are measured
host end-to-end HTTP wall time. Any derived token rate is explicitly estimated.

## Accepted raw-ASM replacements

| Path | Before | After | Result |
|---|---:|---:|---:|
| BF16 QKV, all 10 attention layers | 3.955923 ms wave2 | 3.059702 ms wave1 | 1.29291x, HIP-event measured, bit-exact |
| BF16 LM head | 6.502371 ms wave4 | 5.211666 ms wave1 | 1.24765x, HIP-event measured, exact versus prior raw output |
| BF16 LM head workgroup | 5.218205 ms WG256 | 5.006868 ms WG64 | 1.04221x, HIP-event measured, bit-exact |
| BF16 attention output, all 10 layers | 1.939446 ms wave2 | 1.772834 ms wave1 | 1.09398x, HIP-event measured, wave1/wave2 bit-exact |
| GDN N=2048 compute+reduce, all 30 layers | 1.888719 ms | 1.354499 ms | 1.39440x, HIP-event measured, bit-exact |
| GDN N=12800 layer-0 compute+reduce | 35.326 us | 30.497 us | 1.15834x, HIP-event measured, bit-exact |
| Router projection | about 78.3 us rocBLAS median/layer | 23.765 us raw FP32 median/layer | 3.30x approximate ratio, rocprofv3 measured |

### Accepted code-object metadata

All four accepted code objects use a 24-byte, 8-byte-aligned kernarg segment,
wave32, 16 SGPRs, 18 VGPRs, zero fixed LDS/private segment, and no spills.

| Raw gfx1151 HSACO | SHA-256 | Launch |
|---|---|---|
| `bf16_qkv_decode_wave1_gfx1151` | `0d700a1d29739041d9b0e475b7be33edf2c05a22a354a73358747b8f934cdd67` | grid 1152, block 256 |
| `bf16_attn_oproj_decode_wave1_gfx1151` | `9bc3a951ebefff8e403c79e84c6ddaa6731bbf09375aed4107efb5ae1dc0da19` | grid 256, block 256 |
| `bf16_router_decode_wave2_fp32_gfx1151` | `f1371c14dd50265ce7d2827a2a4c9e63e86f3b4d965b442b7dbd0051fcb8ccd8` | grid 16, block 256 |
| `bf16_lm_head_decode_wave1_wg64_gfx1151` | `876e17b6239f42e03e9d128250adf32b02788909a6da3def4ab6ed3ee967169e` | grid 124160, block 64 |

A clean rebuild reproduced all four hashes exactly. The shared library exports the
existing BF16 entry points plus the new `netra_bf16_attention_output_decode` and
`netra_bf16_router_decode` C ABI symbols.

The raw FP32 router was checked on all 40 real layers. In 534 actual calls where
native BF16 and FP32 routing selected differently (1,113 positions), the FP32 raw
kernel matched the FP64 reference at every changed position; native BF16 missed all
1,113. Candidate max error was 3.27e-6 versus 0.03129 for native BF16.

The attention-output raw kernel differs from rocBLAS in only 56 BF16 outputs across
10 randomized real-weight layer tests. Every differing raw value is closer to FP64;
no differing rocBLAS value is closer. Aggregate mean absolute error is
0.0011337420 raw versus 0.0011337519 rocBLAS.

## Final rocprofv3 inventory excerpt

Trace:
`results/profiles/gfx1151/decode-m1-32-final-qkv1-router-fp32-attn-oproj-lm-wg64-gdnpipe-20260731`

| Kernel | Invocations | Median GPU time | Total GPU time |
|---|---:|---:|---:|
| `bf16_lm_head_decode_wave1_wg64_gfx1151` | 35 | 5008.684 us | 175.408 ms |
| `bf16_qkv_decode_wave1_gfx1151` | 350 | 341.561 us | 120.172 ms |
| `bf16_shared_gate_up_silu_decode_wave2_gfx1151` | 1400 | 74.219 us | 105.223 ms |
| `mxfp4_decode_gate_block64_gfx1151` | 2800 | 36.469 us | 103.411 ms |
| `mxfp4_linear_decode_n12800_k2048_block64_gfx1151` | 1050 | 73.017 us | 74.282 ms |
| `mxfp4_decode_down_gfx1151` | 1400 | 48.411 us | 68.343 ms |
| `bf16_attn_oproj_decode_wave1_gfx1151` | 350 | 173.927 us | 60.966 ms |
| `bf16_shared_down_decode_wave4_gfx1151` | 1400 | 24.366 us | 34.630 ms |
| `bf16_router_decode_wave2_fp32_gfx1151` | 1400 | 23.765 us | 34.058 ms |

The trace contains model initialization as well as the request. Repeated-kernel
medians are used for ranking; the 13.461 s trace wall is not a request latency.
The exact uncached request was 1 input + 32 output, graph disabled, dFlash disabled,
and host E2E was 1234.309 ms measured.

## Serving A/B

All rows below are exact 210 input + 128 forced output, cached tokens 0, seed 731,
graph disabled, dFlash disabled, and measured host E2E on gfx1151.

| Configuration | E2E | Output hash / behavior |
|---|---:|---|
| QKV wave1 + LM wave1 + GDN pipelines, router off | 4842.202 ms | coherent Chinese response, hash `876b4575...` |
| FP32 router enabled | 4409.050 ms | coherent English response, hash `9715033b...` |
| Attention-output control, raw disabled | 4397.462 ms | hash `9715033b...` |
| Raw attention output enabled | 4355.864 ms | coherent Chinese response, hash `a86a2080...` |
| Raw attention output + LM WG64 | 4321.996 ms | identical `a86a2080...` hash |

The accepted attention-output A/B is 41.598 ms or 0.946% faster. The accepted LM
WG64 A/B is another 33.867 ms or 0.778% faster. The latest total-based rate is
`127 / 4.321996 = 29.385 output tok/s`, estimated because the non-streaming request
does not expose TTFT or decode-only time. The 50 tok/s target is not yet achieved.

## Rejected experiments

- Routed gate/up block64 fusion was bit-exact in isolation and 1.0888x faster in a
  cache-hot HIP microbenchmark, but doubled the per-layer partial workspace. Real
  exact 210+128 serving regressed from 4321.996 to 4470.582 ms (+3.44%) and peak
  VRAM rose by about 3.3 GB. Rejected and reverted.
- QKV WG64 was bit-exact but saved only about 0.041 ms across all 10 layers
  (3.074078 to 3.032962 ms, 1.01355x). Rejected as specialization noise/complexity.
- LM WG32 tied WG64 within noise; WG64 was retained to use fewer workgroups.
- LM dwordx2 produced 35 BF16 mismatches, was slower, and was rejected.
- Shared gate/up precise double buffering was exact but only 1.0103x; rejected.
- Eager dual-stream MoE overlap preserved output but improved serving by only 0.24%; rejected.
- A precise-wait routed gate experiment changed outputs and did not improve time; rejected.

## rocprofv3 signal handling

The profiling scripts pass `--disable-signal-handlers true` and terminate the
profiled server after the request. The shell can therefore print `Killed` for the
server cleanup even when trace generation succeeds. Repeated `rocprofv3 caught
signal 6` messages indicate rocprof counter/signal-handler failure, not a model
kernel result; do not loop/restart the profiler. Use the kernel/hip trace path, keep
counter collections isolated, and accept a run only when the CSV and summary are
complete.

Hazy Research's [AMD GPUs go brrr](https://hazyresearch.stanford.edu/blog/2025-11-09-amd-brr)
and [HipKittens: Fast and Furious AMD Kernels](https://hazyresearch.stanford.edu/blog/2025-11-09-hk)
support explicit register scheduling, ping-pong/interleaved pipelines, and precise
dependency waits. Their MI355X CDNA wave64 geometry is not copied directly: each
idea remains conditional on measured RDNA wave32 behavior on gfx1151.
