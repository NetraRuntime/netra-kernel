// SPDX-License-Identifier: MIT
//
// Native-CDNA4 Qwen3.6 decode residual add + Gemma RMSNorm + group FP8:
//   M=1, N=2048, BF16 input/residual/weight
//   -> BF16 output/residual + FP8 E4M3 output + 16 FP32 scales.
//
// The quantizer consumes the BF16-rounded norm output exactly as the deployed
// two-kernel path does. Each 16-lane wave row owns one 128-value quant group.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_gemma_add_rmsnorm_quant_m1_n2048_gfx950
	.globl qwen36_gemma_add_rmsnorm_quant_m1_n2048_gfx950
	.p2align 8
	.type qwen36_gemma_add_rmsnorm_quant_m1_n2048_gfx950,@function
qwen36_gemma_add_rmsnorm_quant_m1_n2048_gfx950:
	// Kernargs: BF16 output/input/residual/residual_out/weight,
	//           FP8 output, FP32 scales, epsilon.
	s_load_dwordx2 s[2:3], s[0:1], 0
	s_load_dwordx2 s[4:5], s[0:1], 8
	s_load_dwordx2 s[6:7], s[0:1], 16
	s_load_dwordx2 s[8:9], s[0:1], 24
	s_load_dwordx2 s[10:11], s[0:1], 32
	s_load_dwordx2 s[12:13], s[0:1], 40
	s_load_dwordx2 s[14:15], s[0:1], 48
	s_load_dwordx2 s[16:17], s[0:1], 56
	s_waitcnt lgkmcnt(0)
	s_mov_b32 s20, 0x2edbe6ff	// 1.0e-10f
	s_mov_b32 s21, 0x43600000	// 224.0f
	s_mov_b32 s22, 0x05040100	// pack low FP8 pairs as [lo, hi]

	v_mov_b32_e32 v27, v0
	v_lshlrev_b32_e32 v1, 4, v0
	global_load_dwordx4 v[6:9], v1, s[4:5]
	global_load_dwordx4 v[10:13], v1, s[6:7]
	global_load_dwordx4 v[2:5], v1, s[10:11]
	v_and_b32_e32 v26, 63, v0
	s_waitcnt vmcnt(0)

	// Unpack eight BF16 input and residual values to packed FP32 pairs.
	v_and_b32_e32 v15, 0xffff0000, v6
	v_lshlrev_b32_e32 v14, 16, v6
	v_and_b32_e32 v17, 0xffff0000, v7
	v_lshlrev_b32_e32 v16, 16, v7
	v_and_b32_e32 v7, 0xffff0000, v8
	v_lshlrev_b32_e32 v6, 16, v8
	v_and_b32_e32 v19, 0xffff0000, v9
	v_lshlrev_b32_e32 v18, 16, v9

	v_and_b32_e32 v9, 0xffff0000, v10
	v_lshlrev_b32_e32 v8, 16, v10
	v_and_b32_e32 v21, 0xffff0000, v11
	v_lshlrev_b32_e32 v20, 16, v11
	v_and_b32_e32 v23, 0xffff0000, v12
	v_lshlrev_b32_e32 v22, 16, v12
	v_and_b32_e32 v25, 0xffff0000, v13
	v_lshlrev_b32_e32 v24, 16, v13

	v_pk_add_f32 v[12:13], v[8:9], v[14:15]
	v_pk_add_f32 v[10:11], v[20:21], v[16:17]
	v_pk_add_f32 v[8:9], v[22:23], v[6:7]
	v_pk_add_f32 v[6:7], v[24:25], v[18:19]

	// Store the BF16 residual while retaining unrounded sums for RMSNorm.
	v_cvt_pk_bf16_f32 v14, v12, v13
	v_cvt_pk_bf16_f32 v15, v10, v11
	v_cvt_pk_bf16_f32 v16, v8, v9
	v_cvt_pk_bf16_f32 v17, v6, v7
	global_store_dwordx4 v1, v[14:17], s[8:9]

	// Per-thread sum of eight squares.
	v_pk_mul_f32 v[18:19], v[12:13], v[12:13]
	v_pk_mul_f32 v[20:21], v[10:11], v[10:11]
	v_pk_mul_f32 v[22:23], v[8:9], v[8:9]
	v_pk_mul_f32 v[24:25], v[6:7], v[6:7]
	v_add_f32_e32 v14, v19, v18
	v_add_f32_e32 v14, v14, v20
	v_add_f32_e32 v14, v14, v21
	v_add_f32_e32 v14, v14, v22
	v_add_f32_e32 v14, v14, v23
	v_add_f32_e32 v14, v14, v24
	v_add_f32_e32 v14, v14, v25

	// Wave64 sum; weight unpack fills four mandatory DPP dependency windows.
	v_lshlrev_b32_e32 v18, 16, v2
	v_and_b32_e32 v19, 0xffff0000, v2
	v_mov_b32_dpp v15, v14 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_e32 v14, v14, v15
	v_lshlrev_b32_e32 v20, 16, v3
	v_and_b32_e32 v21, 0xffff0000, v3
	v_mov_b32_dpp v15, v14 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_e32 v14, v14, v15
	v_lshlrev_b32_e32 v22, 16, v4
	v_and_b32_e32 v23, 0xffff0000, v4
	v_mov_b32_dpp v15, v14 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_e32 v14, v14, v15
	v_lshlrev_b32_e32 v24, 16, v5
	v_and_b32_e32 v25, 0xffff0000, v5
	v_mov_b32_dpp v15, v14 row_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_e32 v14, v14, v15
	s_nop 1
	v_mov_b32_dpp v15, v14 row_bcast:15 row_mask:0xf bank_mask:0xf
	v_add_f32_e32 v14, v14, v15
	s_nop 1
	v_mov_b32_dpp v15, v14 row_bcast:31 row_mask:0xf bank_mask:0xf

	// One completed partial per wave.
	v_cmp_eq_u32_e32 vcc, 63, v26
	s_and_saveexec_b64 s[18:19], vcc
	v_lshrrev_b32_e32 v16, 4, v0
	v_and_b32_e32 v16, 60, v16
	v_add_f32_e32 v14, v14, v15
	ds_write_b32 v16, v14
	s_or_b64 exec, exec, s[18:19]
	s_waitcnt lgkmcnt(0)
	s_barrier

	// Final (wave0+wave1)+(wave2+wave3) reduction in every quad.
	v_and_b32_e32 v0, 3, v0
	v_lshlrev_b32_e32 v0, 2, v0
	ds_read_b32 v0, v0
	s_waitcnt lgkmcnt(0)
	v_mov_b32_dpp v15, v0 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_e32 v0, v0, v15
	s_nop 1
	v_mov_b32_dpp v15, v0 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_e32 v0, v0, v15

	// inverse_rms = rsqrt(float(double(sum/2048) + epsilon)).
	v_mov_b32_e32 v14, 0x3a000000
	v_mul_f32_e32 v0, v14, v0
	v_cvt_f64_f32_e32 v[14:15], v0
	v_add_f64 v[14:15], s[16:17], v[14:15]
	v_cvt_f32_f64_e32 v0, v[14:15]
	v_rsq_f32_e32 v14, v0
	s_nop 3
	v_mov_b32_e32 v15, v14
	v_pk_mul_f32 v[12:13], v[12:13], v[14:15]
	v_pk_mul_f32 v[10:11], v[10:11], v[14:15]
	v_pk_mul_f32 v[8:9], v[8:9], v[14:15]
	v_pk_mul_f32 v[6:7], v[6:7], v[14:15]

	v_pk_mul_f32 v[12:13], v[12:13], v[18:19]
	v_pk_mul_f32 v[10:11], v[10:11], v[20:21]
	v_pk_mul_f32 v[8:9], v[8:9], v[22:23]
	v_pk_mul_f32 v[6:7], v[6:7], v[24:25]

	// BF16 output is retained for exact fallback and downstream state parity.
	v_cvt_pk_bf16_f32 v2, v12, v13
	v_cvt_pk_bf16_f32 v3, v10, v11
	v_cvt_pk_bf16_f32 v4, v8, v9
	v_cvt_pk_bf16_f32 v5, v6, v7
	global_store_dwordx4 v1, v[2:5], s[2:3]

	// Re-expand the BF16-rounded norm output before calculating group scales.
	v_lshlrev_b32_e32 v18, 16, v2
	v_and_b32_e32 v19, 0xffff0000, v2
	v_lshlrev_b32_e32 v20, 16, v3
	v_and_b32_e32 v21, 0xffff0000, v3
	v_lshlrev_b32_e32 v22, 16, v4
	v_and_b32_e32 v23, 0xffff0000, v4
	v_lshlrev_b32_e32 v24, 16, v5
	v_and_b32_e32 v25, 0xffff0000, v5

	// One 128-value maximum per 16-lane row.
	v_max3_f32 v28, |v18|, |v19|, s20
	v_max3_f32 v28, v28, |v20|, |v21|
	v_max3_f32 v28, v28, |v22|, |v23|
	v_max3_f32 v28, v28, |v24|, |v25|
	s_nop 1
	v_mov_b32_dpp v29, v28 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 v28, v28, v29
	s_nop 1
	v_mov_b32_dpp v29, v28 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 v28, v28, v29
	s_nop 1
	v_mov_b32_dpp v29, v28 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 v28, v28, v29
	s_nop 1
	v_mov_b32_dpp v29, v28 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 v28, v28, v29
	// IEEE-rounded group scale = maximum / 224. Multiplication by a rounded
	// reciprocal misses the deployed quantizer by one ULP for several groups.
	s_nop 1
	v_mov_b32_e32 v30, v28
	v_rcp_f32_e32 v31, s21
	s_nop 1
	v_fma_f32 v32, -s21, v31, 1.0
	s_nop 1
	v_fma_f32 v31, v32, v31, v31
	s_nop 1
	v_mul_f32_e32 v28, v30, v31
	s_nop 1
	v_fma_f32 v32, -s21, v28, v30
	s_nop 1
	v_fma_f32 v28, v32, v31, v28

	// Store one FP32 scale from the high lane of each row.
	v_and_b32_e32 v30, 15, v27
	v_cmp_eq_u32_e32 vcc, 15, v30
	s_and_saveexec_b64 s[18:19], vcc
	v_lshrrev_b32_e32 v31, 4, v27
	v_lshlrev_b32_e32 v31, 2, v31
	global_store_dword v31, v28, s[14:15]
	s_or_b64 exec, exec, s[18:19]

	// Broadcast the scale from row lane 15.
	v_and_b32_e32 v30, 0x30, v27
	v_lshlrev_b32_e32 v30, 2, v30
	v_add_u32_e32 v30, 60, v30
	ds_bpermute_b32 v31, v30, v28
	s_waitcnt lgkmcnt(0)

	// Match the deployed divide using one reciprocal refinement.
	v_rcp_f32_e32 v32, v31
	s_nop 1
	v_fma_f32 v33, -v31, v32, 1.0
	s_nop 1
	v_fma_f32 v34, v33, v32, v32
	s_nop 1
	v_mov_b32_e32 v32, v34
	s_nop 0
	v_mul_f32_e32 v18, v32, v18
	v_mul_f32_e32 v19, v32, v19
	v_mul_f32_e32 v20, v32, v20
	v_mul_f32_e32 v21, v32, v21
	v_mul_f32_e32 v22, v32, v22
	v_mul_f32_e32 v23, v32, v23
	v_mul_f32_e32 v24, v32, v24
	v_mul_f32_e32 v25, v32, v25
	v_cvt_pk_fp8_f32 v2, v18, v19
	v_cvt_pk_fp8_f32 v3, v20, v21
	v_cvt_pk_fp8_f32 v4, v22, v23
	v_cvt_pk_fp8_f32 v5, v24, v25
	s_nop 1
	v_perm_b32 v2, v3, v2, s22
	v_perm_b32 v3, v5, v4, s22
	v_lshlrev_b32_e32 v34, 3, v27
	global_store_dwordx2 v34, v[2:3], s[12:13]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_gemma_add_rmsnorm_quant_m1_n2048_gfx950
		.amdhsa_group_segment_fixed_size 16
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 64
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 35
		.amdhsa_accum_offset 36
		.amdhsa_next_free_sgpr 23
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_gemma_add_rmsnorm_quant_m1_n2048_gfx950, .Lfunc_end0-qwen36_gemma_add_rmsnorm_quant_m1_n2048_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: output_bf16, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: input_bf16, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: residual_bf16, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: residual_out_bf16, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: gemma_weight_bf16, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: output_fp8, .offset: 40, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: output_scale_f32, .offset: 48, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: epsilon, .offset: 56, .size: 8, .value_kind: by_value }
    .group_segment_fixed_size: 16
    .kernarg_segment_align: 8
    .kernarg_segment_size: 64
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_gemma_add_rmsnorm_quant_m1_n2048_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 23
    .sgpr_spill_count: 0
    .symbol: qwen36_gemma_add_rmsnorm_quant_m1_n2048_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 35
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
