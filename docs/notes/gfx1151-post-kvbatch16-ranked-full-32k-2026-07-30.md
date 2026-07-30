# Post-kvbatch16 gfx1151 exact-32K ranked trace (2026-07-30)

This is a measured gfx1151 rocprofv3 process-start trace for exact 32,768 input
+1 output, uncached, graphs disabled, and dFlash disabled. The target kernel has
40 calls. Server JIT/startup launch counts differ from the matched control, so
trace wall/gaps are inventory values, not A/B performance claims.

| Rank | Kernel/family | Calls | Total GPU ms | Mean GPU ms | Kernel-time % |
|---:|---|---:|---:|---:|---:|
| 1 | `extend_attention_wmma_n64_gfx1151` / triton_attention | 40 | 5346.822 | 133.671 | 23.190% |
| 2 | `mxfp4_prefill_gate_wmma_gfx1151` / netra_mxfp4_moe | 320 | 2856.720 | 8.927 | 12.390% |
| 3 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` / netra_mxfp4_linear | 360 | 2399.691 | 6.666 | 10.408% |
| 4 | `gdn_chunk_o_bv32_gfx1151` / gdn_linear_attn | 120 | 1371.247 | 11.427 | 5.947% |
| 5 | `recompute_w_u_reuse_a_ordered_gfx1151` / other | 120 | 1213.404 | 10.112 | 5.263% |
| 6 | `mxfp4_prefill_down_wmma_gfx1151` / netra_mxfp4_moe | 160 | 1200.696 | 7.504 | 5.208% |
| 7 | `chunk_gated_delta_rule_fwd_kernel_h_blockdim64` / gdn_linear_attn | 180 | 1051.379 | 5.841 | 4.560% |
| 8 | `chunk_gated_delta_rule_fwd_kkt_solve_kernel` / gdn_linear_attn | 180 | 968.078 | 5.378 | 4.199% |
| 9 | `void at::native::elementwise_kernel_manual_unroll<128, 8, a...` / other | 640 | 814.263 | 1.272 | 3.532% |
| 10 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_A...` / hip_blas_gemm | 40 | 569.055 | 14.226 | 2.468% |
| 11 | `void at::native::vectorized_elementwise_kernel<4, at::nativ...` / other | 1092 | 523.255 | 0.479 | 2.269% |
| 12 | `expert_weighted_reduce_top8_fp64_gfx1151` / reduce_misc | 160 | 463.143 | 2.895 | 2.009% |

Total measured GPU kernel time: 23056.319 ms. Measured trace wall: 39109.821 ms. Positive launch gaps: 16073.206 ms.
