# Current gfx1151 full-stack bottleneck inventory — 2026-07-31

All numeric results are **measured on gfx1151** unless explicitly marked unavailable. MXFP4 checkpoint weights are unchanged. Eager traces are independent, uncached, timed request-only windows. CPU API statistics below are filtered to the first-to-last request kernel window, excluding server startup and teardown.

## Eager scenario overview

| Scenario | Input/output | Host E2E ms | GPU ms | Gaps ms | Launches | Kernel occupancy | Alloc/free | Peak VRAM GiB |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| short-prefill | 16 / 1 | 363.446 | 269.751 | 52.386 | 5,026 | 83.86% | 4 / 0 | 72.741 |
| prefill-210 | 210 / 1 | 564.574 | 410.751 | 13.357 | 4,895 | 96.87% | 0 / 0 | 72.522 |
| prefill-8192 | 8192 / 1 | 5187.831 | 4355.767 | 865.735 | 5,515 | 83.42% | 16 / 0 | 75.950 |
| prefill-32768 | 32768 / 1 | 22344.359 | 21529.795 | 901.580 | 16,888 | 96.14% | 22 / 0 | 73.485 |
| decode-m1-32-output | 1 / 32 | 1804.449 | 1559.064 | 168.014 | 52,656 | 90.30% | 0 / 0 | 71.587 |
| serving-210-in-128-out | 210 / 128 | 7641.356 | 7054.498 | 486.700 | 228,068 | 93.58% | 7 / 0 | 72.640 |

## CPU/GPU orchestration in the request window

HIP API durations are measured gfx1151 host-call durations. Synchronization durations overlap GPU execution and must not be added to GPU or host E2E time. The launch columns report both compiler/HIP launches and cached raw-module launches; allocation bytes are measured in the same request-kernel window.

| Scenario | Dominant sync calls / total ms | hipLaunchKernel calls / ms | hipModuleLaunchKernel calls / ms | Blocking copies calls / ms | Allocations / KiB | Device queries |
|---|---:|---:|---:|---:|---:|---:|
| short-prefill | 2 / 170.252 | 3,131 / 49.833 | 1,276 / 12.792 | 0 / 0.000 | 4 / 135168.0 | 39,977 |
| prefill-210 | 2 / 343.372 | 2,117 / 9.337 | 896 / 9.611 | 0 / 0.000 | 0 / 0.0 | 26,532 |
| prefill-8192 | 2 / 4165.703 | 3,606 / 912.426 | 1,326 / 14.644 | 5 / 0.102 | 16 / 2031680.0 | 41,837 |
| prefill-32768 | 5 / 21043.294 | 11,561 / 937.838 | 3,705 / 38.206 | 17 / 29.383 | 22 / 2033728.0 | 130,043 |
| decode-m1-32-output | 31 / 543.255 | 29,703 / 114.344 | 15,960 / 139.417 | 0 / 0.000 | 0 / 0.0 | 377,358 |
| serving-210-in-128-out | 129 / 2115.308 | 129,010 / 545.214 | 68,840 / 645.645 | 0 / 0.000 | 7 / 290816.0 | 1,638,336 |

## Per-scenario ranked kernels

### short-prefill — gfx1151 measured

| Rank | Kernel | Family | Calls | Mean us | Total ms | % host E2E | VGPR/SGPR | LDS/scratch B |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1 | `mxfp4_prefill_gate_wmma_gfx1151` | mxfp4_moe | 40 | 1661.502 | 66.460 | 18.29% | 112/128 | 4096/0 |
| 2 | `mxfp4_prefill_up_silu_wmma_gfx1151` | mxfp4_moe | 40 | 1511.581 | 60.463 | 16.64% | 112/128 | 4096/0 |
| 3 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | blas_projection | 22 | 1560.590 | 34.333 | 9.45% | 256/128 | 51200/0 |
| 4 | `mxfp4_prefill_down_wmma_gfx1151` | mxfp4_moe | 40 | 772.126 | 30.885 | 8.50% | 112/128 | 0/0 |
| 5 | `mxfp4_sgl_linear_decode_gfx1151` | mxfp4_dense | 60 | 251.932 | 15.116 | 4.16% | 40/128 | 0/0 |
| 6 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | blas_projection | 99 | 143.427 | 14.199 | 3.91% | 256/128 | 51200/0 |
| 7 | `mxfp4_decode_gate_gfx1151` | mxfp4_moe | 80 | 85.692 | 6.855 | 1.89% | 40/128 | 0/0 |
| 8 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | blas_projection | 79 | 78.614 | 6.211 | 1.71% | 256/128 | 51200/0 |
| 9 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` | mxfp4_dense | 29 | 179.825 | 5.215 | 1.43% | 112/128 | 0/0 |
| 10 | `expert_activation_pack_gfx1151` | moe_pack_reduce | 40 | 128.362 | 5.134 | 1.41% | 8/128 | 0/0 |
| 11 | `mxfp4_sgl_linear_prefill_group4_a_gfx1151` | mxfp4_dense | 58 | 80.430 | 4.665 | 1.28% | 112/128 | 4096/0 |
| 12 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA4_GLVWB4_GRVW4_GSU1_GSUASB_ISA1151_...` | blas_projection | 79 | 39.218 | 3.098 | 0.85% | 256/128 | 51200/0 |
| 13 | `chunk_gated_delta_rule_fwd_kernel_h_blockdim64` | gdn_state_scan | 29 | 85.655 | 2.484 | 0.68% | 256/128 | 0/524 |
| 14 | `mxfp4_decode_down_gfx1151` | mxfp4_moe | 40 | 48.255 | 1.930 | 0.53% | 40/128 | 0/0 |
| 15 | `recompute_w_u_fwd_kernel` | gdn_state_scan | 29 | 56.539 | 1.640 | 0.45% | 256/128 | 0/0 |

### prefill-210 — gfx1151 measured

| Rank | Kernel | Family | Calls | Mean us | Total ms | % host E2E | VGPR/SGPR | LDS/scratch B |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1 | `mxfp4_prefill_gate_wmma_gfx1151` | mxfp4_moe | 36 | 2975.478 | 107.117 | 18.97% | 112/128 | 4096/0 |
| 2 | `mxfp4_prefill_up_silu_wmma_gfx1151` | mxfp4_moe | 36 | 2385.409 | 85.875 | 15.21% | 112/128 | 4096/0 |
| 3 | `mxfp4_prefill_down_wmma_gfx1151` | mxfp4_moe | 36 | 1728.004 | 62.208 | 11.02% | 112/128 | 0/0 |
| 4 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | blas_projection | 48 | 528.822 | 25.383 | 4.50% | 256/128 | 51200/0 |
| 5 | `mxfp4_sgl_linear_decode_gfx1151` | mxfp4_dense | 60 | 250.998 | 15.060 | 2.67% | 40/128 | 0/0 |
| 6 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | blas_projection | 59 | 253.796 | 14.974 | 2.65% | 256/128 | 51200/0 |
| 7 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` | mxfp4_dense | 27 | 469.136 | 12.667 | 2.24% | 112/128 | 0/0 |
| 8 | `expert_activation_pack_gfx1151` | moe_pack_reduce | 36 | 283.971 | 10.223 | 1.81% | 8/128 | 0/0 |
| 9 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | blas_projection | 36 | 231.647 | 8.339 | 1.48% | 256/128 | 51200/0 |
| 10 | `chunk_fwd_kernel_o` | gdn_output | 27 | 287.935 | 7.774 | 1.38% | 256/128 | 0/1632 |
| 11 | `mxfp4_decode_gate_gfx1151` | mxfp4_moe | 80 | 85.303 | 6.824 | 1.21% | 40/128 | 0/0 |
| 12 | `mxfp4_sgl_linear_prefill_group4_a_gfx1151` | mxfp4_dense | 54 | 109.292 | 5.902 | 1.05% | 112/128 | 4096/0 |
| 13 | `chunk_gated_delta_rule_fwd_kernel_h_blockdim64` | gdn_state_scan | 27 | 213.877 | 5.775 | 1.02% | 256/128 | 0/524 |
| 14 | `expert_weighted_reduce_top8_fp64_gfx1151` | moe_pack_reduce | 36 | 148.634 | 5.351 | 0.95% | 40/128 | 0/0 |
| 15 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | blas_projection | 36 | 137.781 | 4.960 | 0.88% | 256/128 | 51200/0 |

### prefill-8192 — gfx1151 measured

| Rank | Kernel | Family | Calls | Mean us | Total ms | % host E2E | VGPR/SGPR | LDS/scratch B |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` | mxfp4_dense | 30 | 13723.438 | 411.703 | 7.94% | 112/128 | 0/0 |
| 2 | `gdn_chunk_o_bv32_gfx1151` | gdn_output | 30 | 13630.043 | 408.901 | 7.88% | 216/128 | 25088/0 |
| 3 | `extend_attention_wmma_n64_gfx1151` | standard_attention | 10 | 34696.068 | 346.961 | 6.69% | 248/128 | 65536/0 |
| 4 | `mxfp4_prefill_gate_wmma_gfx1151` | mxfp4_moe | 40 | 7830.226 | 313.209 | 6.04% | 112/128 | 4096/0 |
| 5 | `recompute_w_u_reuse_a_ordered_gfx1151` | gdn_state_scan | 30 | 10095.439 | 302.863 | 5.84% | 136/128 | 16384/0 |
| 6 | `mxfp4_prefill_down_wmma_gfx1151` | mxfp4_moe | 40 | 7533.746 | 301.350 | 5.81% | 112/128 | 0/0 |
| 7 | `mxfp4_prefill_up_silu_wmma_gfx1151` | mxfp4_moe | 40 | 7289.358 | 291.574 | 5.62% | 112/128 | 4096/0 |
| 8 | `chunk_gated_delta_rule_fwd_kernel_h_blockdim64` | gdn_state_scan | 30 | 8711.375 | 261.341 | 5.04% | 256/128 | 0/524 |
| 9 | `chunk_gated_delta_rule_fwd_kkt_solve_kernel` | gdn_state_scan | 30 | 8103.019 | 243.091 | 4.69% | 256/128 | 0/128 |
| 10 | `mxfp4_sgl_linear_prefill_group4_a_gfx1151` | mxfp4_dense | 60 | 2723.000 | 163.380 | 3.15% | 112/128 | 4096/0 |
| 11 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | blas_projection | 10 | 14242.976 | 142.430 | 2.75% | 256/128 | 51200/0 |
| 12 | `void at::native::vectorized_elementwise_kernel<4, at::native::bfloat16_copy_kernel_cuda(at::TensorIteratorBase&)::{la...` | copy_elementwise | 252 | 520.403 | 131.142 | 2.53% | 24/128 | 0/0 |
| 13 | `expert_weighted_reduce_top8_fp64_gfx1151` | moe_pack_reduce | 40 | 2893.705 | 115.748 | 2.23% | 40/128 | 0/0 |
| 14 | `expert_activation_pack_gfx1151` | moe_pack_reduce | 40 | 2555.775 | 102.231 | 1.97% | 8/128 | 0/0 |
| 15 | `void at::native::elementwise_kernel_manual_unroll<128, 4, at::native::gpu_kernel_impl_nocast<at::native::BinaryFuncto...` | copy_elementwise | 243 | 370.354 | 89.996 | 1.73% | 24/128 | 0/0 |

### prefill-32768 — gfx1151 measured

| Rank | Kernel | Family | Calls | Mean us | Total ms | % host E2E | VGPR/SGPR | LDS/scratch B |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1 | `extend_attention_wmma_n64_gfx1151` | standard_attention | 40 | 133738.870 | 5349.555 | 23.94% | 248/128 | 65536/0 |
| 2 | `chunk_fwd_kernel_o` | gdn_output | 120 | 15612.700 | 1873.524 | 8.38% | 256/128 | 0/432 |
| 3 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` | mxfp4_dense | 120 | 13799.289 | 1655.915 | 7.41% | 112/128 | 0/0 |
| 4 | `mxfp4_prefill_gate_wmma_gfx1151` | mxfp4_moe | 160 | 7837.297 | 1253.968 | 5.61% | 112/128 | 4096/0 |
| 5 | `mxfp4_prefill_down_wmma_gfx1151` | mxfp4_moe | 160 | 7558.591 | 1209.375 | 5.41% | 112/128 | 0/0 |
| 6 | `recompute_w_u_reuse_a_ordered_gfx1151` | gdn_state_scan | 120 | 9920.133 | 1190.416 | 5.33% | 136/128 | 16384/0 |
| 7 | `mxfp4_prefill_up_silu_wmma_gfx1151` | mxfp4_moe | 160 | 7297.169 | 1167.547 | 5.23% | 112/128 | 4096/0 |
| 8 | `chunk_gated_delta_rule_fwd_kernel_h_blockdim64` | gdn_state_scan | 120 | 8795.266 | 1055.432 | 4.72% | 256/128 | 0/524 |
| 9 | `chunk_gated_delta_rule_fwd_kkt_solve_kernel` | gdn_state_scan | 120 | 8110.126 | 973.215 | 4.36% | 256/128 | 0/128 |
| 10 | `mxfp4_sgl_linear_prefill_group4_a_gfx1151` | mxfp4_dense | 240 | 2728.394 | 654.815 | 2.93% | 112/128 | 4096/0 |
| 11 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | blas_projection | 40 | 14283.178 | 571.327 | 2.56% | 256/128 | 51200/0 |
| 12 | `void at::native::vectorized_elementwise_kernel<4, at::native::bfloat16_copy_kernel_cuda(at::TensorIteratorBase&)::{la...` | copy_elementwise | 765 | 685.149 | 524.139 | 2.35% | 24/128 | 0/0 |
| 13 | `expert_weighted_reduce_top8_fp64_gfx1151` | moe_pack_reduce | 160 | 2892.711 | 462.834 | 2.07% | 40/128 | 0/0 |
| 14 | `expert_activation_pack_gfx1151` | moe_pack_reduce | 160 | 2535.301 | 405.648 | 1.82% | 8/128 | 0/0 |
| 15 | `void at::native::elementwise_kernel_manual_unroll<128, 4, at::native::gpu_kernel_impl_nocast<at::native::BinaryFuncto...` | copy_elementwise | 729 | 492.676 | 359.161 | 1.61% | 24/128 | 0/0 |

### decode-m1-32-output — gfx1151 measured

| Rank | Kernel | Family | Calls | Mean us | Total ms | % host E2E | VGPR/SGPR | LDS/scratch B |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1 | `mxfp4_sgl_linear_decode_gfx1151` | mxfp4_dense | 1800 | 248.438 | 447.189 | 24.78% | 40/128 | 0/0 |
| 2 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | blas_projection | 330 | 1318.872 | 435.228 | 24.12% | 256/128 | 51200/0 |
| 3 | `mxfp4_decode_gate_gfx1151` | mxfp4_moe | 2400 | 84.410 | 202.584 | 11.23% | 40/128 | 0/0 |
| 4 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | blas_projection | 1500 | 127.479 | 191.218 | 10.60% | 256/128 | 51200/0 |
| 5 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | blas_projection | 1200 | 77.693 | 93.232 | 5.17% | 256/128 | 51200/0 |
| 6 | `mxfp4_decode_down_gfx1151` | mxfp4_moe | 1200 | 47.203 | 56.644 | 3.14% | 40/128 | 0/0 |
| 7 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA4_GLVWB4_GRVW4_GSU1_GSUASB_ISA1151_...` | blas_projection | 1200 | 35.127 | 42.152 | 2.34% | 256/128 | 51200/0 |
| 8 | `fused_recurrent_gated_delta_rule_packed_decode_kernel` | gdn_state_scan | 900 | 22.004 | 19.803 | 1.10% | 184/128 | 0/0 |
| 9 | `void at::native::reduce_kernel<512, 1, at::native::ReduceOp<float, at::native::MeanOps<float, float, float, float>, u...` | normalization | 2430 | 3.747 | 9.106 | 0.50% | 32/128 | 512/0 |
| 10 | `void at::native::vectorized_elementwise_kernel<4, at::native::bfloat16tofloat32_copy_kernel_cuda(at::TensorIteratorBa...` | copy_elementwise | 4890 | 1.196 | 5.846 | 0.32% | 16/128 | 0/0 |
| 11 | `void at::native::vectorized_elementwise_kernel<4, at::native::CUDAFunctorOnSelf_add<float>, std::array<char*, 2ul> >(...` | copy_elementwise | 4860 | 1.093 | 5.312 | 0.29% | 16/128 | 0/0 |
| 12 | `_fwd_grouped_kernel_stage1` | other | 300 | 17.194 | 5.158 | 0.29% | 256/128 | 0/1060 |
| 13 | `void at::native::elementwise_kernel_manual_unroll<128, 4, at::native::gpu_kernel_impl_nocast<at::native::BinaryFuncto...` | copy_elementwise | 2430 | 2.009 | 4.883 | 0.27% | 24/128 | 0/0 |
| 14 | `__amd_rocclr_fillBufferAligned` | copy_elementwise | 2430 | 1.525 | 3.706 | 0.21% | 16/128 | 0/0 |
| 15 | `void at::native::vectorized_elementwise_kernel<4, at::native::rsqrt_kernel_cuda(at::TensorIteratorBase&)::{lambda()#2...` | normalization | 2430 | 1.346 | 3.271 | 0.18% | 32/128 | 0/0 |

### serving-210-in-128-out — gfx1151 measured

| Rank | Kernel | Family | Calls | Mean us | Total ms | % host E2E | VGPR/SGPR | LDS/scratch B |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1 | `mxfp4_sgl_linear_decode_gfx1151` | mxfp4_dense | 7680 | 248.038 | 1904.933 | 24.93% | 40/128 | 0/0 |
| 2 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | blas_projection | 1448 | 1292.231 | 1871.151 | 24.49% | 256/128 | 51200/0 |
| 3 | `mxfp4_decode_gate_gfx1151` | mxfp4_moe | 10240 | 84.289 | 863.117 | 11.30% | 40/128 | 0/0 |
| 4 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | blas_projection | 6410 | 128.460 | 823.426 | 10.78% | 256/128 | 51200/0 |
| 5 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_...` | blas_projection | 5120 | 77.621 | 397.417 | 5.20% | 256/128 | 51200/0 |
| 6 | `mxfp4_decode_down_gfx1151` | mxfp4_moe | 5120 | 47.479 | 243.093 | 3.18% | 40/128 | 0/0 |
| 7 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA4_GLVWB4_GRVW4_GSU1_GSUASB_ISA1151_...` | blas_projection | 5120 | 36.080 | 184.730 | 2.42% | 256/128 | 51200/0 |
| 8 | `mxfp4_prefill_gate_wmma_gfx1151` | mxfp4_moe | 40 | 2939.298 | 117.572 | 1.54% | 112/128 | 4096/0 |
| 9 | `mxfp4_prefill_up_silu_wmma_gfx1151` | mxfp4_moe | 40 | 2379.078 | 95.163 | 1.25% | 112/128 | 4096/0 |
| 10 | `fused_recurrent_gated_delta_rule_packed_decode_kernel` | gdn_state_scan | 3840 | 21.952 | 84.295 | 1.10% | 184/128 | 0/0 |
| 11 | `mxfp4_prefill_down_wmma_gfx1151` | mxfp4_moe | 40 | 1732.025 | 69.281 | 0.91% | 112/128 | 0/0 |
| 12 | `void at::native::reduce_kernel<512, 1, at::native::ReduceOp<float, at::native::MeanOps<float, float, float, float>, u...` | normalization | 10447 | 3.694 | 38.594 | 0.51% | 32/128 | 512/0 |
| 13 | `_fwd_grouped_kernel_stage1` | other | 1280 | 22.850 | 29.249 | 0.38% | 256/128 | 0/1060 |
| 14 | `void at::native::vectorized_elementwise_kernel<4, at::native::bfloat16tofloat32_copy_kernel_cuda(at::TensorIteratorBa...` | copy_elementwise | 21052 | 1.184 | 24.926 | 0.33% | 16/128 | 0/0 |
| 15 | `void at::native::vectorized_elementwise_kernel<4, at::native::CUDAFunctorOnSelf_add<float>, std::array<char*, 2ul> >(...` | copy_elementwise | 20894 | 1.039 | 21.716 | 0.28% | 16/128 | 0/0 |

## Suite ranking

This sum is a workload-suite prioritization, not a frequency-weighted production traffic estimate.

| Rank | Kernel | Calls | Total ms | Scenarios |
|---:|---|---:|---:|---:|
| 1 | `extend_attention_wmma_n64_gfx1151` | 50 | 5696.515 | 2 |
| 2 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_IU1` | 1875 | 2438.271 | 6 |
| 3 | `mxfp4_sgl_linear_decode_gfx1151` | 9720 | 2412.383 | 6 |
| 4 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` | 235 | 2099.101 | 5 |
| 5 | `chunk_fwd_kernel_o` | 205 | 1889.802 | 4 |
| 6 | `mxfp4_prefill_gate_wmma_gfx1151` | 316 | 1858.326 | 5 |
| 7 | `mxfp4_prefill_up_silu_wmma_gfx1151` | 316 | 1700.622 | 5 |
| 8 | `mxfp4_prefill_down_wmma_gfx1151` | 316 | 1673.099 | 5 |
| 9 | `recompute_w_u_reuse_a_ordered_gfx1151` | 150 | 1493.279 | 2 |
| 10 | `chunk_gated_delta_rule_fwd_kernel_h_blockdim64` | 235 | 1331.177 | 5 |
| 11 | `chunk_gated_delta_rule_fwd_kkt_solve_kernel` | 235 | 1221.470 | 5 |
| 12 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_IU1` | 8368 | 1178.007 | 6 |
| 13 | `mxfp4_decode_gate_gfx1151` | 12960 | 1093.049 | 6 |
| 14 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_IU1` | 6719 | 863.540 | 6 |
| 15 | `mxfp4_sgl_linear_prefill_group4_a_gfx1151` | 470 | 835.109 | 5 |
| 16 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_IU1` | 125 | 730.866 | 4 |
| 17 | `void at::native::vectorized_elementwise_kernel<4, at::native::bfloat16_copy_kernel_cuda(at::TensorIteratorBase&)::{lambd` | 14463 | 671.799 | 6 |
| 18 | `expert_weighted_reduce_top8_fp64_gfx1151` | 316 | 590.591 | 5 |
| 19 | `expert_activation_pack_gfx1151` | 316 | 534.686 | 5 |
| 20 | `void at::native::elementwise_kernel_manual_unroll<128, 4, at::native::gpu_kernel_impl_nocast<at::native::BinaryFunctor<f` | 14394 | 477.185 | 6 |
| 21 | `gdn_chunk_o_bv32_gfx1151` | 30 | 408.901 | 1 |
| 22 | `mxfp4_decode_down_gfx1151` | 6480 | 307.458 | 6 |
| 23 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA4_GLVWB4_GRVW4_GSU1_GSUASB_ISA1151_IU1` | 50 | 306.192 | 2 |
| 24 | `void at::native::reduce_kernel<512, 1, at::native::ReduceOp<float, at::native::MeanOps<float, float, float, float>, unsi` | 13757 | 282.655 | 6 |
| 25 | `qkvzba_split_copy_gfx1151` | 5095 | 272.490 | 6 |

## Full graph replay

| Graph | Batch | Graph launches | Kernels/replay | Graph CPU us | GPU span ms | Summed GPU ms | Replay alloc/free/sync |
|---|---:|---:|---:|---:|---:|---:|---:|
| full-graph-b1 | 1 | 8 | 1723 | 935.766 | 56.539 | 52.086 | 0 |

Top full-graph-b1 replay kernels:

| Rank | Kernel | Calls | Total ms | % graph GPU | VGPR/SGPR | LDS/scratch B |
|---:|---|---:|---:|---:|---:|---:|
| 1 | `mxfp4_sgl_linear_decode_gfx1151` | 480 | 120.374 | 28.89% | 40/128 | 0/0 |
| 2 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_IU1` | 88 | 116.084 | 27.86% | 256/128 | 51200/0 |
| 3 | `mxfp4_decode_gate_gfx1151` | 640 | 54.710 | 13.13% | 40/128 | 0/0 |
| 4 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_IU1` | 400 | 50.945 | 12.23% | 256/128 | 51200/0 |
| 5 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_IU1` | 320 | 24.654 | 5.92% | 256/128 | 51200/0 |
| 6 | `mxfp4_decode_down_gfx1151` | 320 | 15.261 | 3.66% | 40/128 | 0/0 |
| 7 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA4_GLVWB4_GRVW4_GSU1_GSUASB_ISA1151_IU1` | 320 | 10.832 | 2.60% | 256/128 | 51200/0 |
| 8 | `fused_recurrent_gated_delta_rule_packed_decode_kernel` | 240 | 4.991 | 1.20% | 184/128 | 0/0 |
| 9 | `void at::native::reduce_kernel<512, 1, at::native::ReduceOp<float, at::native::MeanOps<float, float, float, float>, unsi` | 648 | 2.428 | 0.58% | 32/128 | 512/0 |
| 10 | `_fwd_grouped_kernel_stage1` | 80 | 1.691 | 0.41% | 256/128 | 0/1060 |
| 11 | `void at::native::vectorized_elementwise_kernel<4, at::native::bfloat16tofloat32_copy_kernel_cuda(at::TensorIteratorBase&` | 1304 | 1.543 | 0.37% | 16/128 | 0/0 |
| 12 | `void at::native::vectorized_elementwise_kernel<4, at::native::CUDAFunctorOnSelf_add<float>, std::array<char*, 2ul> >(int` | 1296 | 1.392 | 0.33% | 16/128 | 0/0 |

| full-graph-m12 | 12 | 8 | 2983 | 1671.344 | 114.495 | 106.885 | 0 |

Top full-graph-m12 replay kernels:

| Rank | Kernel | Calls | Total ms | % graph GPU | VGPR/SGPR | LDS/scratch B |
|---:|---|---:|---:|---:|---:|---:|
| 1 | `mxfp4_m12_group_gate_up_silu_wmma_gfx1151` | 320 | 331.218 | 38.74% | 88/128 | 0/0 |
| 2 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_IU1` | 88 | 128.345 | 15.01% | 256/128 | 51200/0 |
| 3 | `mxfp4_m12_group_down_wmma_gfx1151` | 320 | 72.926 | 8.53% | 72/128 | 0/0 |
| 4 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_IU1` | 400 | 69.403 | 8.12% | 256/128 | 51200/0 |
| 5 | `fused_recurrent_gated_delta_rule_packed_decode_kernel` | 240 | 51.054 | 5.97% | 184/128 | 0/0 |
| 6 | `mxfp4_sgl_linear_prefill_group4_a_gfx1151` | 480 | 38.347 | 4.48% | 112/128 | 4096/0 |
| 7 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` | 240 | 36.810 | 4.30% | 112/128 | 0/0 |
| 8 | `expert_activation_pack_gfx1151` | 320 | 34.866 | 4.08% | 8/128 | 0/0 |
| 9 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA8_GLVWB8_GRVW8_GSU1_GSUASB_ISA1151_IU1` | 320 | 31.692 | 3.71% | 256/128 | 51200/0 |
| 10 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMAS3_BL1_BS1_EPS1_GLVWA4_GLVWB4_GRVW4_GSU1_GSUASB_ISA1151_IU1` | 320 | 15.589 | 1.82% | 256/128 | 51200/0 |
| 11 | `_fwd_grouped_kernel_stage1` | 80 | 7.929 | 0.93% | 256/128 | 0/1060 |
| 12 | `void at::native::reduce_kernel<512, 1, at::native::ReduceOp<float, at::native::MeanOps<float, float, float, float>, unsi` | 648 | 3.146 | 0.37% | 32/128 | 512/0 |

## Hardware-counter coverage

rocprofv3 counters were collected one metric per fresh process for selected hot raw kernels. The request traces do not contain counters. Direct dependency/wait-state stall percentage is unavailable in the exposed gfx1151 metric set and is not estimated. Compiler/Triton and rocBLAS kernels still need isolated counter passes.

| Counter artifact | Kernel | Fetch KiB | Write KiB | Occupancy % | Waves | L2 hit % | Mem busy % |
|---|---|---:|---:|---:|---:|---:|---:|
| `decode-synthetic-identical-counters-20260729` | `mxfp4_decode_down_gfx1151` | 2182.500 | 0.000 | 8.891 | 128.000 | 10.597 | 90.304 |
| `decode-synthetic-identical-counters-20260729` | `mxfp4_decode_gate_gfx1151` | 2188.500 | 0.000 | 4.583 | 64.000 | 6.085 | 85.834 |
| `decode-synthetic-identical-counters-20260729` | `mxfp4_sgl_reduce_gfx1151` | 32.500 | 0.000 | 0.873 | 64.000 | 10.356 | 0.000 |
| `decode-synthetic-identical-counters-20260729` | `silu_mul_bf16_gfx1151` | 16.250 | 0.000 | 1.554 | 128.000 | 23.474 | 5.618 |
| `prefill-gate-dword-layout-counters-20260729` | `mxfp4_prefill_gate_dword_layout_gfx1151` | 393866.531 | 81113.234 | 74.000 | 40832.000 | 92.013 | 99.406 |
| `causal-conv1d-ordered-counters-hip72-20260729` | `causal_conv1d_state_update_gfx1151` | 24.250 | 0.000 | 3.795 | 256.000 | 71.731 | 9.349 |
| `causal-conv1d-ordered-counters-hip72-20260729` | `causal_conv1d_stream64_ordered_gfx1151` | 69353.375 | 65103.750 | 96.089 | 32768.000 | 33.472 | 99.146 |
| `expert-reduce-fp64-counters-hip72-20260729` | `expert_weighted_reduce_top8_fp64_gfx1151` | 262401.688 | 16384.000 | 82.392 | 524288.000 | 5.797 | 96.372 |
| `recompute-w-u-ordered-counters-hip72-20260729` | `recompute_w_u_reuse_a_ordered_gfx1151` | 122920.938 | 69271.750 | 24.443 | 8192.000 | 49.050 | 95.046 |
| `gdn-chunk-o-two-wave-counters-20260731` | `gdn_chunk_o_bv32_gfx1151` | 180400.438 | 32768.000 | 12.465 | unavailable | 63.665 | 92.294 |
| `qkvzba-split-copy-counters-repro` | `qkvzba_split_copy_gfx1151` | 98817.938 | 98340.125 | 0.000 | 458752.000 | 33.335 | 0.000 |
| `candidate` | `extend_attention_wmma_n64_group4_qpipe_kvbatch16_gfx1151` | 18885545.583 | unavailable | unavailable | 8192.000 | 9.719 | unavailable |

## Long serving and coverage status

The existing exact 32,768-input/16,384-output result is **gfx1151 measured** but predates the current accepted stack: 1305.4599 s total, 35.3761 s TTFT, 926.28 input tok/s, and 12.90 output tok/s. A current-stack rerun is required and is not estimated.

- Native full graph tiers M1 and M12 are measured above; M2/4/8/16 correctness exists, but per-tier profiler inventories remain pending.
- Native `tc_piecewise` M64 correctness and construction are measured; piecewise profiler coverage for all requested tiers remains pending.
- Actual speculative verify/dFlash remains unavailable because no compatible draft checkpoint or checkpoint `dflash_config` is installed. Non-speculative M12 is not labeled as verify.
- LM-head/sampling and CPU routing are present in the complete JSON tables, but need focused counter and host-stack instrumentation where they do not rank in the top 15.
- Every kernel row records unavailable counter fields as null rather than estimating bytes, occupancy, cache, waves, or dependency stalls.

## Evidence-backed next targets

1. Continue from the updated ranking after accepting the correctness-stable raw two-wave GDN chunk-output kernel; attention and MXFP4 dense remain ahead in the 8K request window.
2. Specialize short/210-token MoE gate/up/down: they consume most GPU time at those tiers.
3. Continue attention only with a materially different transaction/accumulator schedule; eighteen incremental ideas already have measured accept/reject evidence.
4. Reduce M=1 graph/eager dense projection and launch cost; attention preparation is not a decode bottleneck.
