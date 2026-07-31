# gfx1151 BF16 attention-output wide-load decode — 2026-07-31

All results in this note are for AMD Ryzen AI Max+ PRO 395, `gfx1151`.
GPU claims are measured with HIP events or rocprofv3. Serving claims are measured
with streaming host wall time. Derived values are labeled explicitly.

## Decision

Accept `bf16_attn_oproj_decode_wave1_wide128_gfx1151.s` for the exact
Qwen3.6 full-attention M=1 BF16 output projection, N=2048 and K=4096. It
replaces the old raw wave1 implementation while preserving the 24-byte,
8-byte-aligned three-pointer kernarg ABI, grid `(256,1,1)`, workgroup 256,
caller HIP stream, graph-pool pointers, and checkpoint weights.

The raw gfx1151 AMDGCN candidate replaces scalar `global_load_b32` activation
and weight traffic with `global_load_b128`. Each wave32 retains one output row,
but executes 16 K-loop iterations and four BF16 dot2 operations per iteration
instead of 64 scalar-load iterations. HIP C++ remains launch, graph, validation,
and timing glue only.

| gfx1151 code object | SHA-256 | status |
|---|---|---|
| baseline wave1 | `9bc3a951ebefff8e403c79e84c6ddaa6731bbf09375aed4107efb5ae1dc0da19` | measured |
| candidate wide128 | `0988ba3eb7bb00b4eebe74577f8286538a9036400406d0692217cab9e670ff4e` | measured |

Both have zero LDS and zero scratch. The source metadata uses 22 VGPR and 16
SGPR for the candidate; rocprofv3 reports identical 24-VGPR and 128-SGPR
allocation granules for old and new code objects.

A detached build of pre-change commit `dcccd15072769aeac101d5347aeb7434bd78b30a`
and the accepted build exported identical 30-symbol `netra_*` C ABI tables. The
retained old attention-output HSACO also remained byte-identical.

## Correctness

The real-checkpoint production validator covered all ten full-attention layers
at exact M1/N2048/K4096. Candidate versus model-native rocBLAS BF16 GEMM had
maximum absolute difference 0.015625 and at most nine BF16 elements differing
per layer. Candidate versus old raw wave1 had the same 0.015625 maximum and at
most two differing elements per layer in the matched dual A/B.

FP64 spot checks on real layers 3, 27, and 39 found the candidate closer than
rocBLAS at six elements per layer and rocBLAS closer at zero, with unchanged
maximum error. Full graph replay reproduced eager layer outputs at the existing
tolerance.

In matched exact-210/+128 greedy serving, four of five candidate output hashes
matched old wave1. The fifth diverged because the legal BF16 accumulation order
changed. This is explicitly not bit-exact serving equivalence; the real-layer,
model-native, and FP64 gates establish numerical correctness.

## HIP-event timing

A single process loaded both HSACOs before timing and interleaved old/new runs
on the same current HIP stream over all ten real checkpoint layers.

| gfx1151 measured ten-layer pass | old wave1 median / p90 | wide128 median / p90 | speedup |
|---|---:|---:|---:|
| eager HIP events | 1.774983 / 1.802510 ms | 1.503371 / 1.538922 ms | 1.18067x |
| graph replay HIP events | 1.770494 / 1.797758 ms | 1.496859 / 1.532234 ms | 1.18281x |

## rocprofv3 counters

Each metric was collected in a fresh process with rocprofv3 signal handlers
disabled. Every pass completed without signal 6.

| gfx1151 measured counter | old wave1 | wide128 |
|---|---:|---:|
| fetched KiB | 8200.406 | 8200.313 |
| written KiB | 1.500 | 1.672 |
| L2 hit | 1.879% | 1.817% |
| mean occupancy / active CU | 59.101 | 60.174 |
| occupancy | 73.170% | 73.563% |
| memory-unit busy | 86.857% | 83.066% |
| waves | 2048 | 2048 |
| wave cycles | 102,609,548 | 88,604,462 |
| VALU instructions | 221 | 125 |

The candidate reduces measured wave cycles by 13.649% and VALU instructions by
43.439% with effectively unchanged fetch volume and wave count. The available
gfx1151 metric set does not expose a direct dependency-stall percentage; none
is estimated.

## Complete-request trace

Matched production traces used exact 1 input + 32 output, cached tokens 0,
eager execution, and dFlash disabled.

| gfx1151 measured attention-output metric | old wave1 | wide128 | change |
|---|---:|---:|---:|
| invocations | 321 | 321 | 0 |
| total GPU time | 56.725 ms | 47.363 ms | -16.504% |
| mean GPU time | 176.713 us | 147.547 us | -16.504% |
| median GPU time | 176.330 us | 147.438 us | -16.383% |

The request saves 9.362 ms of measured attention-output GPU time with no launch
count change. The post-change trace measured 860.873 ms host wall, 767.885 ms
summed GPU kernels (89.198% of wall), 95.742 ms positive launch gaps (11.121%),
31,444 launches, and 72 unique kernels. Profiler status 137 is the bounded
collector intentionally terminating the server after request status 0; signal
handlers were disabled and there was no signal-6 loop.

## Serving A/B

Five matched exact-210/+128 requests were uncached, eager, graph disabled, and
dFlash disabled. Decode wall covers 127 timed output intervals.

| gfx1151 measured median | old attention output | wide128 attention output | change |
|---|---:|---:|---:|
| TTFT | 414.486 ms | 414.669 ms | +0.044% |
| input throughput | 506.651 tok/s | 506.428 tok/s | -0.044% |
| decode wall | 3230.117 ms | 3191.732 ms | -1.188% |
| output throughput | 39.317 tok/s | 39.790 tok/s | +1.203% |
| E2E wall | 3645.461 ms | 3609.018 ms | -1.000% |
| peak VRAM | 78,026,743,808 B | 78,026,899,456 B | +155,648 B |

The matched exact-1/+128 decode gate also improves from the previously accepted
39.579 tok/s to 40.068 tok/s, or +1.236% (derived from measured medians). This
is the newest accepted non-speculative batch-1 rate on gfx1151; 50 tok/s is not
yet achieved.

## Full graph gate

Native SGLang full decode graph captured batch 1 in 1.37 s and reported 0.07 GB
incremental graph memory. Candidate eager and graph output hashes matched 5/5.

| gfx1151 measured exact-1/+128 median | candidate eager | candidate full graph |
|---|---:|---:|
| decode wall | 3169.604 ms | 3172.565 ms |
| output throughput | 40.068 tok/s | 40.031 tok/s |
| E2E wall | 3227.876 ms | 3220.827 ms |

Full graph changes decode throughput by -0.093%, within run noise. Eager remains
the default batch-1 performance choice; graph remains correctness-safe.

## Updated bottleneck order

The post-change exact-1/+32 trace ranks LM head (159.903 ms), QKV (96.488 ms),
routed gate chunk4 (83.774 ms), MXFP4 N12800 compute (67.602 ms), shared gate
(65.828 ms), routed down (61.690 ms), then attention output (47.363 ms). The
next work remains GPU compute plus launch fragmentation, not scheduler-only
optimization.

## Evidence

- Dual A/B: `gfx1151-bf16-attention-output-wide128-dual-ab-2026-07-31.json`
- Production validation: `gfx1151-bf16-attention-output-wide128-production-validation-2026-07-31.json`
- Counters: `results/profiles/gfx1151/bf16-attention-output-wave1-counters-20260731`
  and `results/profiles/gfx1151/bf16-attention-output-wide128-counters-20260731`
- Complete trace: `results/profiles/gfx1151/attn-oproj-wide128-qkv-wide128-shared-wide128-complete-eager-b1-1-plus32-20260731`
- Serving: `results/serving/gfx1151/attn-oproj-wave1-qkv-wide128-shared-wide128-eager-210-plus128-20260731`,
  `results/serving/gfx1151/attn-oproj-wide128-qkv-wide128-shared-wide128-eager-210-plus128-20260731`,
  `results/serving/gfx1151/attn-oproj-wide128-qkv-wide128-shared-wide128-eager-1-plus128-20260731`,
  and `results/serving/gfx1151/attn-oproj-wide128-qkv-wide128-shared-wide128-fullgraph-1-plus128-20260731`
- Before/after disassembly: `gfx1151-bf16-attention-output-wide128-disassembly-2026-07-31/`
