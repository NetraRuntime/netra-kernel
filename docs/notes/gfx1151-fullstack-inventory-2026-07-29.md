# gfx1151 full-stack bottleneck inventory (2026-07-29)

All numbers below are **measured on gfx1151** unless a row explicitly says unavailable or pending. The six scenario host timings include rocprofv3 tracing overhead; GPU times are rocprofv3 dispatch durations. Synchronization API time overlaps queued GPU execution and must not be added to GPU time.

## Scenario overview

| Scenario | Exact input/output | Host E2E ms | GPU kernel ms | Positive gaps ms | Launches | Blocking copy/sync ms | Alloc count / GiB | Peak VRAM GiB |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| short-prefill | 16 / 1 | 1303.816 | 222.962 | 1065.740 | 5725 | 108.298 | 6 / 0.098 | 59.964 |
| prefill-210 | 210 / 1 | 680.749 | 430.763 | 236.969 | 5904 | 315.386 | 10 / 0.383 | 60.409 |
| prefill-chunk-8192 | 8192 / 1 | 7849.574 | 7002.726 | 829.886 | 6142 | 6783.570 | 12 / 3.852 | 64.278 |
| prefill-32768 | 32768 / 1 | 34855.689 | 34695.086 | 155.545 | 19114 | 34136.430 | 8 / 0.578 | 64.856 |
| decode-m1 | 1 / 32 | 2059.831 | 1863.747 | 189.271 | 59984 | 532.019 | 0 / 0.000 | 64.856 |
| serving-210-in-128-out | 210 / 128 | 8512.340 | 7609.127 | 875.979 | 235410 | 2212.455 | 0 / 0.000 | 64.856 |

## Ranked kernels by total request cost

### short-prefill — gfx1151 measured

| Rank | Kernel | Family | Calls | Mean us | Total ms | % host E2E | VGPR / SGPR | LDS / scratch B |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1 | `mxfp4_prefill_gate_wmma_gfx1151` | netra_mxfp4_moe | 80 | 1174.459 | 93.957 | 7.21% | 112 / 128 | 0 / 0 |
| 2 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | hip_blas_gemm | 22 | 1509.590 | 33.211 | 2.55% | 256 / 128 | 51200 / 0 |
| 3 | `mxfp4_sgl_linear_decode_gfx1151` | netra_mxfp4_linear | 90 | 212.926 | 19.163 | 1.47% | 40 / 128 | 0 / 0 |
| 4 | `mxfp4_prefill_down_wmma_gfx1151` | netra_mxfp4_moe | 40 | 356.677 | 14.267 | 1.09% | 112 / 128 | 0 / 0 |
| 5 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | hip_blas_gemm | 100 | 140.792 | 14.079 | 1.08% | 256 / 128 | 51200 / 0 |
| 6 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` | netra_mxfp4_linear | 90 | 124.515 | 11.206 | 0.86% | 112 / 128 | 0 / 0 |
| 7 | `mxfp4_decode_gate_gfx1151` | netra_mxfp4_moe | 80 | 84.471 | 6.758 | 0.52% | 40 / 128 | 0 / 0 |
| 8 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | hip_blas_gemm | 80 | 78.609 | 6.289 | 0.48% | 256 / 128 | 51200 / 0 |
| 9 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA4_GLVWB4_GRVW4_GSU1_GSUASB_ISA1151_...` | hip_blas_gemm | 80 | 36.720 | 2.938 | 0.23% | 256 / 128 | 51200 / 0 |
| 10 | `chunk_gated_delta_rule_fwd_kernel_h_blockdim64` | gdn_linear_attn | 30 | 72.460 | 2.174 | 0.17% | 256 / 128 | 0 / 524 |
| 11 | `silu_mul_bf16_gfx1151` | activation | 80 | 24.249 | 1.940 | 0.15% | 8 / 128 | 0 / 0 |
| 12 | `mxfp4_decode_down_gfx1151` | netra_mxfp4_moe | 40 | 46.800 | 1.872 | 0.14% | 40 / 128 | 0 / 0 |

### prefill-210 — gfx1151 measured

| Rank | Kernel | Family | Calls | Mean us | Total ms | % host E2E | VGPR / SGPR | LDS / scratch B |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1 | `mxfp4_prefill_gate_wmma_gfx1151` | netra_mxfp4_moe | 80 | 2555.206 | 204.416 | 30.03% | 112 / 128 | 0 / 0 |
| 2 | `mxfp4_prefill_down_wmma_gfx1151` | netra_mxfp4_moe | 40 | 1067.998 | 42.720 | 6.28% | 112 / 128 | 0 / 0 |
| 3 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | hip_blas_gemm | 52 | 496.780 | 25.833 | 3.79% | 256 / 128 | 51200 / 0 |
| 4 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` | netra_mxfp4_linear | 90 | 253.433 | 22.809 | 3.35% | 112 / 128 | 0 / 0 |
| 5 | `mxfp4_sgl_linear_decode_gfx1151` | netra_mxfp4_linear | 90 | 214.982 | 19.348 | 2.84% | 40 / 128 | 0 / 0 |
| 6 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | hip_blas_gemm | 60 | 279.261 | 16.756 | 2.46% | 256 / 128 | 51200 / 0 |
| 7 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | hip_blas_gemm | 40 | 241.921 | 9.677 | 1.42% | 256 / 128 | 51200 / 0 |
| 8 | `chunk_fwd_kernel_o` | other | 30 | 301.070 | 9.032 | 1.33% | 256 / 128 | 0 / 1632 |
| 9 | `silu_mul_bf16_gfx1151` | activation | 80 | 102.133 | 8.171 | 1.20% | 8 / 128 | 0 / 0 |
| 10 | `mxfp4_decode_gate_gfx1151` | netra_mxfp4_moe | 80 | 84.470 | 6.758 | 0.99% | 40 / 128 | 0 / 0 |
| 11 | `chunk_gated_delta_rule_fwd_kernel_h_blockdim64` | gdn_linear_attn | 30 | 224.856 | 6.746 | 0.99% | 256 / 128 | 0 / 524 |
| 12 | `void at::native::vectorized_gather_kernel<16, long>(char*, char*, long*, int, long, long, long, long, bool)` | other | 81 | 78.182 | 6.333 | 0.93% | 16 / 128 | 0 / 0 |

### prefill-chunk-8192 — gfx1151 measured

| Rank | Kernel | Family | Calls | Mean us | Total ms | % host E2E | VGPR / SGPR | LDS / scratch B |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1 | `chunk_fwd_kernel_o` | other | 30 | 33143.775 | 994.313 | 12.67% | 256 / 128 | 0 / 1632 |
| 2 | `mxfp4_prefill_gate_wmma_gfx1151` | netra_mxfp4_moe | 80 | 9467.957 | 757.437 | 9.65% | 112 / 128 | 0 / 0 |
| 3 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` | netra_mxfp4_linear | 90 | 7775.282 | 699.775 | 8.91% | 112 / 128 | 0 / 0 |
| 4 | `recompute_w_u_fwd_kernel` | other | 30 | 18262.116 | 547.863 | 6.98% | 256 / 128 | 0 / 0 |
| 5 | `_fwd_kernel` | other | 10 | 48079.605 | 480.796 | 6.13% | 256 / 128 | 0 / 1184 |
| 6 | `fused_qkvzba_split_reshape_cat_contiguous_kernel` | other | 60 | 6210.256 | 372.615 | 4.75% | 16 / 128 | 0 / 0 |
| 7 | `_causal_conv1d_fwd_kernel` | conv_short | 30 | 10961.341 | 328.840 | 4.19% | 72 / 128 | 0 / 0 |
| 8 | `void at::native::vectorized_gather_kernel<16, long>(char*, char*, long*, int, long, long, long, long, bool)` | other | 81 | 3545.466 | 287.183 | 3.66% | 16 / 128 | 0 / 0 |
| 9 | `void at::native::indexFuncLargeIndex<float, long, unsigned int, 2, 2, -2, true, at::native::(anonymous namespace)::Re...` | elementwise_copy | 40 | 7076.673 | 283.067 | 3.61% | 16 / 128 | 0 / 0 |
| 10 | `mxfp4_prefill_down_wmma_gfx1151` | netra_mxfp4_moe | 40 | 6871.247 | 274.850 | 3.50% | 112 / 128 | 0 / 0 |
| 11 | `void at::native::elementwise_kernel_manual_unroll<128, 4, at::native::gpu_kernel_impl_nocast<at::native::BinaryFuncto...` | other | 283 | 967.709 | 273.862 | 3.49% | 24 / 128 | 0 / 0 |
| 12 | `chunk_gated_delta_rule_fwd_kernel_h_blockdim64` | gdn_linear_attn | 30 | 8701.864 | 261.056 | 3.33% | 256 / 128 | 0 / 524 |

### prefill-32768 — gfx1151 measured

| Rank | Kernel | Family | Calls | Mean us | Total ms | % host E2E | VGPR / SGPR | LDS / scratch B |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1 | `_fwd_kernel` | other | 40 | 220607.503 | 8824.300 | 25.32% | 256 / 128 | 0 / 1184 |
| 2 | `chunk_fwd_kernel_o` | other | 120 | 33118.248 | 3974.190 | 11.40% | 256 / 128 | 0 / 1632 |
| 3 | `mxfp4_prefill_gate_wmma_gfx1151` | netra_mxfp4_moe | 320 | 9473.422 | 3031.495 | 8.70% | 112 / 128 | 0 / 0 |
| 4 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` | netra_mxfp4_linear | 360 | 7766.617 | 2795.982 | 8.02% | 112 / 128 | 0 / 0 |
| 5 | `recompute_w_u_fwd_kernel` | other | 120 | 18236.522 | 2188.383 | 6.28% | 256 / 128 | 0 / 0 |
| 6 | `fused_qkvzba_split_reshape_cat_contiguous_kernel` | other | 150 | 9937.712 | 1490.657 | 4.28% | 16 / 128 | 0 / 0 |
| 7 | `_causal_conv1d_fwd_kernel` | conv_short | 120 | 10942.372 | 1313.085 | 3.77% | 72 / 128 | 0 / 0 |
| 8 | `void at::native::vectorized_gather_kernel<16, long>(char*, char*, long*, int, long, long, long, long, bool)` | other | 324 | 3505.171 | 1135.676 | 3.26% | 16 / 128 | 0 / 0 |
| 9 | `void at::native::indexFuncLargeIndex<float, long, unsigned int, 2, 2, -2, true, at::native::(anonymous namespace)::Re...` | elementwise_copy | 160 | 7072.116 | 1131.539 | 3.25% | 16 / 128 | 0 / 0 |
| 10 | `mxfp4_prefill_down_wmma_gfx1151` | netra_mxfp4_moe | 160 | 6863.234 | 1098.117 | 3.15% | 112 / 128 | 0 / 0 |
| 11 | `void at::native::elementwise_kernel_manual_unroll<128, 4, at::native::gpu_kernel_impl_nocast<at::native::BinaryFuncto...` | other | 889 | 1232.027 | 1095.272 | 3.14% | 24 / 128 | 0 / 0 |
| 12 | `chunk_gated_delta_rule_fwd_kernel_h_blockdim64` | gdn_linear_attn | 120 | 8669.870 | 1040.384 | 2.98% | 256 / 128 | 0 / 524 |

### decode-m1 — gfx1151 measured

| Rank | Kernel | Family | Calls | Mean us | Total ms | % host E2E | VGPR / SGPR | LDS / scratch B |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1 | `mxfp4_sgl_linear_decode_gfx1151` | netra_mxfp4_linear | 2970 | 213.648 | 634.535 | 30.81% | 40 / 128 | 0 / 0 |
| 2 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | hip_blas_gemm | 363 | 1317.351 | 478.198 | 23.22% | 256 / 128 | 51200 / 0 |
| 3 | `mxfp4_decode_gate_gfx1151` | netra_mxfp4_moe | 2640 | 84.488 | 223.047 | 10.83% | 40 / 128 | 0 / 0 |
| 4 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | hip_blas_gemm | 1650 | 127.602 | 210.543 | 10.22% | 256 / 128 | 51200 / 0 |
| 5 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | hip_blas_gemm | 1320 | 77.394 | 102.160 | 4.96% | 256 / 128 | 51200 / 0 |
| 6 | `mxfp4_decode_down_gfx1151` | netra_mxfp4_moe | 1320 | 46.970 | 62.000 | 3.01% | 40 / 128 | 0 / 0 |
| 7 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA4_GLVWB4_GRVW4_GSU1_GSUASB_ISA1151_...` | hip_blas_gemm | 1320 | 33.649 | 44.417 | 2.16% | 256 / 128 | 51200 / 0 |
| 8 | `fused_recurrent_gated_delta_rule_packed_decode_kernel` | gdn_linear_attn | 960 | 22.606 | 21.702 | 1.05% | 184 / 128 | 0 / 0 |
| 9 | `void at::native::reduce_kernel<512, 1, at::native::ReduceOp<float, at::native::MeanOps<float, float, float, float>, u...` | reduce_misc | 2673 | 3.940 | 10.532 | 0.51% | 32 / 128 | 512 / 0 |
| 10 | `void at::native::vectorized_elementwise_kernel<4, at::native::bfloat16tofloat32_copy_kernel_cuda(at::TensorIteratorBa...` | other | 5379 | 1.240 | 6.670 | 0.32% | 16 / 128 | 0 / 0 |
| 11 | `void at::native::vectorized_elementwise_kernel<4, at::native::CUDAFunctorOnSelf_add<float>, std::array<char*, 2ul> >(...` | other | 5346 | 1.128 | 6.028 | 0.29% | 16 / 128 | 0 / 0 |
| 12 | `void at::native::elementwise_kernel_manual_unroll<128, 4, at::native::gpu_kernel_impl_nocast<at::native::BinaryFuncto...` | other | 2673 | 2.119 | 5.665 | 0.28% | 24 / 128 | 0 / 0 |

### serving-210-in-128-out — gfx1151 measured

| Rank | Kernel | Family | Calls | Mean us | Total ms | % host E2E | VGPR / SGPR | LDS / scratch B |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1 | `mxfp4_sgl_linear_decode_gfx1151` | netra_mxfp4_linear | 11520 | 213.778 | 2462.724 | 28.93% | 40 / 128 | 0 / 0 |
| 2 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | hip_blas_gemm | 1449 | 1296.722 | 1878.949 | 22.07% | 256 / 128 | 51200 / 0 |
| 3 | `mxfp4_decode_gate_gfx1151` | netra_mxfp4_moe | 10240 | 84.627 | 866.580 | 10.18% | 40 / 128 | 0 / 0 |
| 4 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | hip_blas_gemm | 6410 | 128.796 | 825.583 | 9.70% | 256 / 128 | 51200 / 0 |
| 5 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | hip_blas_gemm | 5120 | 77.353 | 396.046 | 4.65% | 256 / 128 | 51200 / 0 |
| 6 | `mxfp4_decode_down_gfx1151` | netra_mxfp4_moe | 5120 | 47.103 | 241.166 | 2.83% | 40 / 128 | 0 / 0 |
| 7 | `mxfp4_prefill_gate_wmma_gfx1151` | netra_mxfp4_moe | 80 | 2520.956 | 201.676 | 2.37% | 112 / 128 | 0 / 0 |
| 8 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA4_GLVWB4_GRVW4_GSU1_GSUASB_ISA1151_...` | hip_blas_gemm | 5120 | 33.485 | 171.444 | 2.01% | 256 / 128 | 51200 / 0 |
| 9 | `fused_recurrent_gated_delta_rule_packed_decode_kernel` | gdn_linear_attn | 3840 | 22.511 | 86.442 | 1.02% | 184 / 128 | 0 / 0 |
| 10 | `mxfp4_prefill_down_wmma_gfx1151` | netra_mxfp4_moe | 40 | 1042.286 | 41.691 | 0.49% | 112 / 128 | 0 / 0 |
| 11 | `void at::native::reduce_kernel<512, 1, at::native::ReduceOp<float, at::native::MeanOps<float, float, float, float>, u...` | reduce_misc | 10449 | 3.964 | 41.417 | 0.49% | 32 / 128 | 512 / 0 |
| 12 | `_fwd_grouped_kernel_stage1` | other | 1280 | 23.228 | 29.732 | 0.35% | 256 / 128 | 0 / 1060 |

## Post-dword-layout exact 32K ranking — gfx1151 measured

A fresh ABI-matched process-start rocprofv3 trace captured exact 32,768/+1
uncached inference after the accepted attention K swizzle and prefill gate/up
dword layout. The trace finalized normally with 34,090 launches, 29,738.787 ms
of GPU kernel time, and 12,303.018 ms of positive gaps over its 42,004.145 ms
process-start window. Startup copies are included in the aggregate API/gap
figures; the ranked model kernels below use exact request call counts.

| Rank | Kernel | Calls | Mean us | Total ms | % kernel time | VGPR / SGPR | LDS / scratch B |
|---:|---|---:|---:|---:|---:|---:|---:|
| 1 | `extend_attention_wmma_n64_gfx1151` | 40 | 173257.699 | 6930.308 | 23.304% | 248 / 128 | 65536 / 0 |
| 2 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` | 360 | 8175.856 | 2943.308 | 9.897% | 112 / 128 | 0 / 0 |
| 3 | `mxfp4_prefill_gate_wmma_gfx1151` | 320 | 9083.241 | 2906.637 | 9.774% | 112 / 128 | 0 / 0 |
| 4 | `recompute_w_u_fwd_kernel` | 150 | 15848.254 | 2377.238 | 7.994% | 256 / 128 | 0 / 0 |
| 5 | `gdn_chunk_o_bv32_gfx1151` | 120 | 11352.175 | 1362.261 | 4.581% | 216 / 128 | 32768 / 0 |
| 6 | `_causal_conv1d_fwd_kernel` | 150 | 8818.668 | 1322.800 | 4.448% | 72 / 128 | 0 / 0 |
| 7 | `mxfp4_prefill_down_wmma_gfx1151` | 160 | 7577.532 | 1212.405 | 4.077% | 112 / 128 | 0 / 0 |
| 8 | `indexFuncLargeIndex` expert reduction | 160 | 7058.314 | 1129.330 | 3.797% | 16 / 128 | 0 / 0 |
| 9 | FP32 router-weight multiply | 1054 | 1046.565 | 1103.079 | 3.709% | 24 / 128 | 0 / 0 |
| 10 | `chunk_gated_delta_rule_fwd_kernel_h_blockdim64` | 150 | 7106.871 | 1066.031 | 3.585% | 256 / 128 | 0 / 524 |

The accepted gate/up change reduces its total from 3,456.036 to 2,906.637 ms
(-15.897%) and moves it from rank 2 to rank 3. Dense prefill is therefore the
next MXFP4 projection target; recompute W/U is the next non-attention GDN
target. The complete updated trace is under
`results/profiles/gfx1151/prefill-gate-dword-layout-32k-start-20260729/`.

## CPU/GPU orchestration

`hipMemcpyWithStream` is a blocking host API in every measured scenario. The 32K request issued 402 calls totaling 34094.121 ms of CPU call duration. This trace predates the piecewise integration fix: grouped prefill called `group_index[-1].item()`, a source-derived device-to-host synchronization point. That host read is now removed with a correctness-validated fixed-capacity routed-group workspace; the remaining blocking copies require a fresh trace before attribution.

| Scenario | Top HIP API | Calls | Total CPU ms | Mean us |
|---|---|---:|---:|---:|
| short-prefill | `hipLaunchKernel` | 3625 | 806.717 | 222.542 |
| prefill-210 | `hipMemcpyWithStream` | 102 | 294.999 | 2892.144 |
| prefill-chunk-8192 | `hipMemcpyWithStream` | 102 | 6711.099 | 65795.087 |
| prefill-32768 | `hipMemcpyWithStream` | 402 | 34094.121 | 84811.246 |
| decode-m1 | `hipMemcpyWithStream` | 46 | 512.208 | 11134.961 |
| serving-210-in-128-out | `hipMemcpyWithStream` | 230 | 2186.154 | 9505.019 |

## Raw-ASM decode hardware counters

These are gfx1151 **measured** rocprofv3 counters with exact Qwen3.6 decode tensor shapes and synthetic zero data. One counter was collected per process launch because combined groups exceed hardware collection capacity.

| Kernel | Waves | Occupancy % | Active-CU waves | Fetch KiB | Write KiB | L2 hit % | Mem busy % | VGPR / SGPR |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `mxfp4_decode_down_gfx1151` | 128 | 8.891 | 7.851 | 2182.500 | 0.000 | 10.597 | 90.304 | 40 / 128 |
| `mxfp4_decode_gate_gfx1151` | 64 | 4.583 | 3.968 | 2188.500 | 0.000 | 6.085 | 85.834 | 40 / 128 |
| `mxfp4_sgl_reduce_gfx1151` | 64 | 0.873 | 7.743 | 32.500 | 0.000 | 10.356 | 0.000 | 16 / 128 |
| `silu_mul_bf16_gfx1151` | 128 | 1.554 | 7.816 | 16.250 | 0.000 | 23.474 | 5.618 | 8 / 128 |

## Full serving baseline

| Target | Input/output | Cached | TTFT s | Input tok/s | Output tok/s | Total latency s | Graph | dFlash | Status |
|---|---:|---:|---:|---:|---:|---:|---|---|---|
| gfx1151 | 32768 / 16384 | 0 | 35.3761 | 926.28 | 12.90 | 1305.4599 | disabled | disabled | measured |

## Evidence-backed priorities

Post-inventory update: ranked kernel six,
`fused_qkvzba_split_reshape_cat_contiguous_kernel`, now has an accepted
bit-exact raw gfx1151 ASM replacement. It improves M8192 kernel time 7.0195x,
uncached 8,192/+1 serving 1.0462x, and matched 32,768/+1 serving 1.0376x.

1. Reprofile grouped prefill after the accepted `.item()` removal and fixed-capacity workspace. The original 32K trace measured 402 blocking copies and 34.094 s inside `hipMemcpyWithStream`; no portion is assumed eliminated until the replacement trace is captured.
2. Optimize the top 32K GDN kernels first: `_fwd_kernel`, `chunk_fwd_kernel_o`, and `recompute_w_u` collectively dominate several seconds and use 256 VGPR with scratch in the first two cases.
3. Continue raw gfx1151 ASM work on MXFP4 gate/linear/down. Decode linear alone is 34.05% of decode GPU time; the raw gate/down counter passes are 85.8–90.3% memory-unit busy with low measured L2 hit rate.
4. Reduce decode launch fragmentation: the 1+32 trace contains 59,984 launches; 210+128 contains 235,410 launches.

## Negative results and missing coverage

- A delayed launch-from-start full-decode-graph profile completed all six uncached requests, but rocprofv3 did not flush CSVs on collection end. Terminating the exact process group exposed a rocprof signal-handler recursion in the inherited Python `multiprocessing.resource_tracker` (PID 33358, repeated signal 6). The request JSONs remain valid host measurements; no GPU timing claim is made from this failed trace.
- ABI-mismatched ROCm 7.2.1 live attach emitted no trace and wedged the server; ABI-matched ROCm 7.13 live attach SIGSEGVed the scheduler. Launch-from-start delayed collection is the working method.
- ROCm 7.13 wheel counter collection fails to load the AQL profiling API. ROCm 7.2.1 native harness collection succeeds and is used above.
- Direct dependency-stall counters were not exposed for gfx1151 by the available metric set; no stall percentage is estimated.
- Speculative M=12 and actual dFlash shapes are unavailable because the supplied checkpoint has no `dflash_config` and no compatible draft checkpoint exists on the system.
- Explicit native `tc_piecewise` prefill capture now succeeds on HIP and matches eager hashes from M64 through M8,192. Its measured host-serving medians are neutral (0.9871x to 1.0073x), so it is retained as a graph-safe integration path but rejected as a default speed optimization.

The raw JSON companion contains the top 80 kernels per scenario, full family tables, HIP API tables, allocation totals, and all collected hardware counters.

## Post-ordered-recompute exact 32K ranking — gfx1151 measured

The accepted ordered raw-ASM recompute replacement changes the top request
costs in the process-start trace as follows. These are measured request-shape
GPU totals; health-only compiler calls are excluded from recompute.

| Rank | Kernel | Calls | Total GPU ms | Mean us |
|---:|---|---:|---:|---:|
| 1 | `extend_attention_wmma_n64_gfx1151` | 40 | 6960.867198 | 174021.680 |
| 2 | `mxfp4_prefill_gate_wmma_gfx1151` | 320 | 2904.613761 | 9076.918 |
| 3 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` | 360 | 2485.034979 | 6902.875 |
| 4 | `gdn_chunk_o_bv32_gfx1151` | 120 | 1368.860575 | 11407.171 |
| 5 | `_causal_conv1d_fwd_kernel` | 180 | 1303.828436 | 7243.491 |
| 6 | `mxfp4_prefill_down_wmma_gfx1151` | 160 | 1212.053803 | 7575.336 |
| 7 | `recompute_w_u_reuse_a_ordered_gfx1151` | 120 | 1189.433566 | 9911.946 |
| 8 | `indexFuncLargeIndex` | 160 | 1129.624508 | 7060.153 |
| 9 | elementwise multiply family | 1216 | 1103.710523 | 907.657 |
| 10 | `chunk_gated_delta_rule_fwd_kernel_h_blockdim64` | 180 | 1055.010362 | 5861.169 |

The recompute family moved from rank 4 at 2,383.947096 ms request-only GPU
time to rank 7 at 1,189.433566 ms. The next unaddressed high-cost model
family is causal convolution; rank 1 attention and ranks 2–4 already have
accepted raw replacements but retain measurable cache/LDS limitations.

## Post-ordered-causal-convolution exact 32K ranking — gfx1151 measured

The accepted ordered raw causal convolution replaces the 120 long-prefill Triton calls. Triton used 1303.633029 ms GPU; raw convolution plus raw state writeback uses 166.231160 ms, saving 1137.401869 ms GPU at the identical request shape (7.842290x). The 60 short/decode forward calls and 90 update calls remain compiler kernels because they are outside the exact raw shape.

| Rank | Kernel | Calls | Total GPU ms | Mean us |
|---:|---|---:|---:|---:|
| 1 | `extend_attention_wmma_n64_gfx1151` | 40 | 6954.057714 | 173851.443 |
| 2 | `mxfp4_prefill_gate_wmma_gfx1151` | 320 | 2857.311398 | 8929.098 |
| 3 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` | 360 | 2408.417340 | 6690.048 |
| 4 | `gdn_chunk_o_bv32_gfx1151` | 120 | 1334.647772 | 11122.065 |
| 5 | `recompute_w_u_reuse_a_ordered_gfx1151` | 120 | 1236.328911 | 10302.741 |
| 6 | `mxfp4_prefill_down_wmma_gfx1151` | 160 | 1202.059694 | 7512.873 |
| 7 | `indexFuncLargeIndex` | 160 | 1130.480012 | 7065.500 |
| 8 | elementwise multiply family | 1216 | 1097.929616 | 902.903 |
| 9 | `chunk_gated_delta_rule_fwd_kernel_h_blockdim64` | 180 | 1066.006455 | 5922.258 |
| 10 | `chunk_gated_delta_rule_fwd_kkt_solve_kernel` | 180 | 978.392810 | 5435.516 |

The raw causal pair is now 166.231160 ms and is no longer a top-ten request cost. The next untargeted kernel by total request cost is `indexFuncLargeIndex` expert reduction; attention, gate, dense, GDN chunk-o, recompute, and prefill down retain higher absolute totals despite earlier accepted replacements.
