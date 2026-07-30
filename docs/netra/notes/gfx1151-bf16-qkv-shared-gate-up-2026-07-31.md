# gfx1151 combined BF16 QKV and shared-expert gate/up decode result

Status: **accepted** for the exact Qwen3.6 M=1 shapes. Every timing and counter in this note is measured on gfx1151 (AMD Ryzen AI Max+ PRO 395); no value is estimated. The checkpoint remains MXFP4. These two model-native BF16 projection families were optimized together because either family alone has a small end-to-end ceiling.

## Accepted raw kernels

- `bf16_qkv_decode_wave4_gfx1151`: M1, N9216, K2048, grid 288, block 256, four adjacent rows per wave32.
- `bf16_shared_gate_up_silu_decode_wave2_gfx1151`: M1, gate/up N512+512, K2048, grid 32, block 256, two gate/up pairs per wave32.

The shared-expert kernel reads the common activation once per two gate/up pairs, computes both BF16 projections, restores the model-native BF16 projection boundary, evaluates SiLU and multiplication in registers, and writes the 512-element BF16 down-projection input directly. It removes the 1024-element gate/up temporary and the separate SiLU-and-multiply launch. Both kernels have 24-byte, eight-byte-aligned kernargs containing only weight, activation, and output pointers. The production launchers preserve the caller's current HIP stream.

Production HSACO SHA-256:

- QKV: `f5671248ce64bac53aba95e4c47d976aae0c3446bc98b4149e5687b59ab3006f`.
- shared gate/up+SiLU: `13424b1036af90fe8cfe991f030c244363ee2ce33e19652054f47d00987fb859`.

`SGLANG_NETRA_ENABLE_BF16_QKV=0` and `SGLANG_NETRA_ENABLE_BF16_SHARED_GATE_UP_SILU=0` independently restore the prior rocBLAS paths. M greater than one and all prefill shapes remain unchanged.

## Real-checkpoint numerical gate

The shared-expert validator uses all 40 independent real layer weights, a 160 MiB weight working set, PyTorch rocBLAS BF16 projection plus the SGL kernel SiLU-and-multiply as the model-native reference, and three FP64 spot checks.

| gfx1151 measured result | value |
|---|---:|
| maximum absolute difference | 0.0078125 |
| maximum differing BF16 elements per 512 output | 156 |
| baseline HIP-event median, 40 layers | 4.414198 ms |
| raw HIP-event median, 40 layers | 3.061415 ms |
| isolated speedup | 1.441881x |
| raw graph replay median / p90 | 3.086603 / 3.108135 ms |
| graph maximum absolute difference | 0.0078125 |

For FP64 spot layers 0, 20 and 39, raw has lower mean absolute error in all three cases. Raw is closer in 83, 89 and 85 differing elements; baseline is closer in 47, 45 and 48. Candidate maximum error is equal on layers 0 and 20 and lower on layer 39.

The QKV kernel's separate validation has maximum absolute difference 0.015625 and a 1.114846x real-ten-weight HIP-event speedup. Its detailed evidence is in `gfx1151-bf16-qkv-decode-2026-07-31.md`.

## rocprofv3 evidence

Each counter was collected with one counter per fresh process and `--disable-signal-handlers true`; all 18 raw/baseline passes completed without the prior signal-6 loop.

| gfx1151 measured counter | rocBLAS gate/up projection | raw fused gate/up+SiLU |
|---|---:|---:|
| profiler VGPR allocation | 256 | 24 |
| profiler SGPR allocation | 128 | 128 |
| LDS | 50 KiB | 0 |
| scratch | 0 | 0 |
| occupancy percent | 2.318% | 12.720% |
| mean occupancy per active CU | 4.000 | 12.764 |
| fetched bytes | 2060.25 KiB | 2050.59 KiB |
| L2 hit | 3.612% | 2.209% |
| waves | 32 | 256 |
| VALU instructions | 3730 | 411 |

The raw counter pass includes its register-resident SiLU epilogue; the rocBLAS counter is the projection kernel only. Direct dependency-stall percentage is not exposed by the gfx1151 metric set and is not estimated.

## Combined serving result

The serving comparison disables both new kernels for the baseline and enables both for the candidate. Each cell is the median of five exact uncached requests. Host wall time is used only for labeled serving end-to-end results. dFlash is disabled.

| gfx1151 measured serving mode | exact tokens | baseline median | both raw kernels median | latency reduction | speedup |
|---|---:|---:|---:|---:|---:|
| eager | 1 + 32 | 1722.716 ms | 1659.497 ms | 3.670% | 1.03810x |
| eager | 210 + 128 | 7172.358 ms | 6925.436 ms | 3.443% | 1.03565x |
| full graph | 1 + 32 | 1733.643 ms | 1668.263 ms | 3.771% | 1.03919x |
| full graph | 210 + 128 | 7221.120 ms | 6970.224 ms | 3.474% | 1.03600x |

Every request reports zero cached tokens. Candidate effective output rates derived from measured host E2E are 19.283 and 18.483 output tokens/s in eager mode and 19.182 and 18.364 output tokens/s in full-graph mode. The non-streaming harness did not measure TTFT or separate input throughput, so those fields are explicitly marked not measured in JSON.

Candidate eager and full-graph output sequences match 5/5 at both shapes. Pre-both baseline and candidate match 3/5 at both shapes because the raw and rocBLAS FP32 accumulation trees are not bit-exact. This is accepted as model-native BF16 numerical equivalence, backed by the FP64 results, not claimed as bit-exact equivalence.

Full decode graph capture succeeded with modules preloaded and stable per-layer 512-element outputs. Baseline capture was 2.57 s and candidate capture 2.44 s; both reported 0.16 GiB graph memory. No capture-time allocation, module load, tensor-value query, or stream substitution is introduced.

## Rejected variant

A one-pair-per-wave variant doubled the raw wave count from 256 to 512. It was bit-exact to the accepted two-pair kernel across all 40 real layers, but its interleaved HIP-event median was 3.122388 ms versus 3.076401 ms, a measured 1.495% regression on gfx1151. The extra activation reads and scheduling overhead outweighed its additional latency hiding. The rejected source is retained recoverably at `/tmp/bf16_shared_gate_up_silu_decode_wave1_gfx1151.s` for this run and is not shipped.

## Artifacts

- `gfx1151-bf16-qkv-validation-2026-07-31.json`
- `gfx1151-bf16-qkv-rocprof-candidate-2026-07-31.json`
- `gfx1151-bf16-qkv-rocprof-baseline-2026-07-31.json`
- `gfx1151-bf16-shared-gate-up-validation-2026-07-31.json`
- `gfx1151-bf16-shared-gate-up-rocprof-candidate-2026-07-31.json`
- `gfx1151-bf16-shared-gate-up-rocprof-baseline-2026-07-31.json`
- `gfx1151-bf16-qkv-shared-gate-up-serving-2026-07-31.json`
- `gfx1151-bf16-qkv-shared-gate-up-disassembly-2026-07-31/`
- `gfx1151-bf16-qkv-shared-abi-hsaco-2026-07-31.txt`

The next ranked BF16 decode families remain router N256 K2048, attention output N2048 K4096, and shared-expert down N2048 K512. Their gains must be accumulated under the same real-weight, graph and serving gates.
