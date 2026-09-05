// SPDX-License-Identifier: MIT
//
// Native-CDNA4 Qwen3.6 decode residual add + Gemma RMSNorm:
//   M=1, N=2048, BF16 input/residual/weight -> BF16 output/residual.
//
// One 256-thread workgroup handles eight elements per workitem. Four wave64
// partial sums are reduced through 16 bytes of LDS. RMS statistics use the
// unrounded FP32 input+residual sum; residual_out stores its BF16 rounding.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_gemma_add_rmsnorm_m1_n2048_gfx950
	.globl qwen36_gemma_add_rmsnorm_m1_n2048_gfx950
	.p2align 8
	.type qwen36_gemma_add_rmsnorm_m1_n2048_gfx950,@function
qwen36_gemma_add_rmsnorm_m1_n2048_gfx950:
	// Kernargs: output, input, residual, residual_out, Gemma weight, epsilon.
	s_load_dwordx2 s[2:3], s[0:1], 0
	s_load_dwordx2 s[4:5], s[0:1], 8
	s_load_dwordx2 s[6:7], s[0:1], 16
	s_load_dwordx2 s[8:9], s[0:1], 24
	s_load_dwordx2 s[10:11], s[0:1], 32
	s_load_dwordx2 s[12:13], s[0:1], 40
	s_waitcnt lgkmcnt(0)

	v_lshlrev_b32_e32 v1, 4, v0
	global_load_dwordx4 v[6:9], v1, s[4:5]
	global_load_dwordx4 v[10:13], v1, s[6:7]
	global_load_dwordx4 v[2:5], v1, s[10:11]
	v_and_b32_e32 v26, 63, v0
	s_waitcnt vmcnt(0)

	// Unpack eight BF16 input values and eight BF16 residual values to
	// packed FP32 pairs, then add in the same pair order as deployed AITER.
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

	// Exact wave64 reduction order used by the deployed AITER kernel.
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

	// Lane 63 of each wave stores its completed partial at offsets 0,4,8,12.
	v_cmp_eq_u32_e32 vcc, 63, v26
	s_and_saveexec_b64 s[14:15], vcc
	v_lshrrev_b32_e32 v16, 4, v0
	v_and_b32_e32 v16, 60, v16
	v_add_f32_e32 v14, v14, v15
	ds_write_b32 v16, v14
	s_or_b64 exec, exec, s[14:15]
	s_waitcnt lgkmcnt(0)
	s_barrier

	// Every quad reads the four wave sums and reduces them identically.
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
	// 1/2048 is exactly representable, so the specialization does not need
	// the deployed generic kernel's latency-bearing reciprocal instruction.
	v_mov_b32_e32 v14, 0x3a000000
	v_mul_f32_e32 v0, v14, v0
	v_cvt_f64_f32_e32 v[14:15], v0
	v_add_f64 v[14:15], s[12:13], v[14:15]
	v_cvt_f32_f64_e32 v0, v[14:15]
	v_rsq_f32_e32 v14, v0
	s_nop 3
	v_mov_b32_e32 v15, v14
	v_pk_mul_f32 v[12:13], v[12:13], v[14:15]
	v_pk_mul_f32 v[10:11], v[10:11], v[14:15]
	v_pk_mul_f32 v[8:9], v[8:9], v[14:15]
	v_pk_mul_f32 v[6:7], v[6:7], v[14:15]

	// Multiply by the already materialized Gemma weight (checkpoint + 1).
	v_pk_mul_f32 v[12:13], v[12:13], v[18:19]
	v_pk_mul_f32 v[10:11], v[10:11], v[20:21]
	v_pk_mul_f32 v[8:9], v[8:9], v[22:23]
	v_pk_mul_f32 v[6:7], v[6:7], v[24:25]

	v_cvt_pk_bf16_f32 v2, v12, v13
	v_cvt_pk_bf16_f32 v3, v10, v11
	v_cvt_pk_bf16_f32 v4, v8, v9
	v_cvt_pk_bf16_f32 v5, v6, v7
	global_store_dwordx4 v1, v[2:5], s[2:3]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_gemma_add_rmsnorm_m1_n2048_gfx950
		.amdhsa_group_segment_fixed_size 16
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 48
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 27
		.amdhsa_accum_offset 28
		.amdhsa_next_free_sgpr 16
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_gemma_add_rmsnorm_m1_n2048_gfx950, .Lfunc_end0-qwen36_gemma_add_rmsnorm_m1_n2048_gfx950

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
      - { .name: epsilon, .offset: 40, .size: 8,
          .value_kind: by_value }
    .group_segment_fixed_size: 16
    .kernarg_segment_align: 8
    .kernarg_segment_size: 48
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_gemma_add_rmsnorm_m1_n2048_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 16
    .sgpr_spill_count: 0
    .symbol: qwen36_gemma_add_rmsnorm_m1_n2048_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 27
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
