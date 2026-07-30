# Post-group4-A gate gfx1151 exact-32K ranked trace (2026-07-30)

This is a measured gfx1151 rocprofv3 process-start trace for exact 32,768 input
+1 output, uncached, graphs disabled, and dFlash disabled. The target gate kernel
has 320 calls. Server JIT/startup launch counts differ from the matched control,
so trace wall/gaps are inventory values, not A/B performance claims.

| Rank | Kernel/family | Calls | Total GPU ms | Mean GPU ms | Kernel-time % |
|---:|---|---:|---:|---:|---:|
| 1 | `extend_attention_wmma_n64_gfx1151` / triton_attention | 40 | 5351.046 | 133.776 | 23.779% |
| 2 | `mxfp4_prefill_gate_wmma_gfx1151` / netra_mxfp4_moe | 320 | 2410.063 | 7.531 | 10.710% |
| 3 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` / netra_mxfp4_linear | 360 | 2398.025 | 6.661 | 10.656% |
| 4 | `gdn_chunk_o_bv32_gfx1151` / gdn_linear_attn | 120 | 1372.819 | 11.440 | 6.101% |
| 5 | `recompute_w_u_reuse_a_ordered_gfx1151` / other | 120 | 1211.034 | 10.092 | 5.382% |
| 6 | `mxfp4_prefill_down_wmma_gfx1151` / netra_mxfp4_moe | 160 | 1200.927 | 7.506 | 5.337% |
| 7 | `chunk_gated_delta_rule_fwd_kernel_h_blockdim64` / gdn_linear_attn | 150 | 1048.374 | 6.989 | 4.659% |
| 8 | `chunk_gated_delta_rule_fwd_kkt_solve_kernel` / gdn_linear_attn | 150 | 974.278 | 6.495 | 4.329% |
| 9 | `void at::native::elementwise_kernel_manual_unroll<128, 8, at:...` / other | 640 | 803.620 | 1.256 | 3.571% |
| 10 | `Cijk_Alik_Bljk_BBS_BH_MT128x128x32_MI16x16x16x1_SN_1LDSB0_AMA...` / hip_blas_gemm | 40 | 573.124 | 14.328 | 2.547% |
| 11 | `void at::native::vectorized_elementwise_kernel<4, at::native:...` / other | 930 | 523.308 | 0.563 | 2.325% |
| 12 | `expert_weighted_reduce_top8_fp64_gfx1151` / reduce_misc | 160 | 463.066 | 2.894 | 2.058% |

Total measured GPU kernel time: 22503.266 ms. Measured trace wall: 37605.937 ms. Positive launch gaps: 15109.017 ms.

The next measured compute target is `mxfp4_sgl_linear_prefill_wmma_gfx1151`:
it is effectively tied with the improved gate kernel at about 2.40 s total GPU time.
