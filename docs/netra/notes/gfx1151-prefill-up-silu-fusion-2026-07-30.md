# gfx1151 M64 prefill up + SiLU-times-up fusion — 2026-07-30

Status: **accepted**. Timings are measured on gfx1151 (AMD Ryzen AI Max+ PRO 395). MXFP4 checkpoint weights remain MXFP4; the fused gate activation/output is model-native FP32/BF16.

## Raw AMDGCN change

`mxfp4_prefill_up_silu_wmma_gfx1151.s` specializes the real Qwen3.6 MoE shape E256, M64, N512, K2048. It performs the raw MXFP4 up projection, reads the already-computed FP32 gate tile, evaluates the same `exp2(-x*log2(e))` SiLU sequence, multiplies by up, rounds to BF16, and stores the final intermediate directly.

This removes one separate raw SiLU kernel launch and the full FP32 up-output write/read. HIP C++ only loads modules, launches, captures/replays graphs, manages memory, compares outputs, and records HIP events.

## Correctness and graph gate

The production-build harness poisons the candidate output on every pass and compares it bit-for-bit with the existing raw up projection plus raw SiLU kernel:

- 20/20 eager repeats exact;
- 20/20 actual HIP-graph replays exact;
- zero mismatched BF16 elements;
- no capture-time allocation and stable device pointers.

Two real-checkpoint, uncached exact 32,768/+1 runs with the rejected raw GDN kernel disabled produced the same token 82 and identical output hashes. A corrected-stack rocprofv3 request also completed with exact requested/observed counts and zero cached tokens.

## HIP-event performance

The final production build, 11 alternating samples at 1,276 real padded expert groups:

| Path | Median | Result |
|---|---:|---|
| gate + up + separate SiLU | 16.123194 ms | measured gfx1151 |
| gate + fused up epilogue | 14.354801 ms | measured gfx1151 |
| speedup | 1.123192x | measured gfx1151 |

## rocprofv3 and full-request evidence

A process trace with signal handlers disabled measured the fused kernel at 7.252 ms mean over 49 calls in the standalone mixed-path harness. Resources are 112 VGPRs, 128 SGPRs, 4 KiB LDS, and zero scratch.

The corrected uncached exact 32,768/+1 full-stack trace (graph disabled, dFlash disabled) recorded:

| Metric | Measured gfx1151 value |
|---|---:|
| host request E2E under profiler | 22,778.396 ms |
| GPU kernel launches | 37,503 |
| aggregate GPU kernel time | 22,965.811 ms |
| positive launch gaps | 14,982.091 ms |
| fused up+SiLU calls | 160 |
| fused up+SiLU GPU total | 1,177.132 ms |
| fused up+SiLU mean | 7.357 ms |
| fused up+SiLU share | 5.126% |

A full-request speedup is deliberately not claimed: the only preceding full-stack baseline used the raw GDN kernel that the repeated correctness gate later rejected. The standalone identical-shape HIP-event comparison is the valid speedup evidence; the corrected full trace establishes integration and request cost.

The full corrected ranking still puts attention first (5,360.349 ms, 23.341%), MXFP4 linear second (2,440.505 ms, 10.627%), tuned GDN chunk-o third (1,897.557 ms, 8.263%), gate fourth (1,260.710 ms), down fifth (1,221.003 ms), recompute sixth (1,201.288 ms), and fused up+SiLU seventh (1,177.132 ms).

## Disassembly

The baseline up projection, separate SiLU, fused candidate, and unified projection-versus-fused diff are under `docs/netra/notes/gfx1151-prefill-up-silu-fusion-disassembly-2026-07-30/`. WMMA count remains eight in the up projection. The fused disassembly contains the 32 scalarized epilogue exponent/store paths while eliminating the separate global FP32 up tensor round trip.

## Reproduction

Run only inside Netra:

```bash
cd /root/netra-mxfp4-gfx1151
scripts/rocm/tools/build/build_netra_sglang_gfx1151.sh
build/sglang/benchmark_prefill_up_silu_fusion \
  build/sglang/mxfp4_prefill_gate_wmma_gfx1151.hsaco \
  build/sglang/silu_mul_bf16_gfx1151.hsaco \
  build/sglang/mxfp4_prefill_up_silu_wmma_gfx1151.hsaco 1276 11
```

The adjacent JSON contains exact samples, resources, serving hashes, and corrected full-trace metrics.
