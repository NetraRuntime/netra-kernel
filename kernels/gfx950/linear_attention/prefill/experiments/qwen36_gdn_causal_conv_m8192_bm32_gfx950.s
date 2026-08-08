// SPDX-License-Identifier: MIT
//
// Qwen3.6 GDN long-prefill causal convolution for gfx950.
// Exact shape: one M=8192 sequence, D=8192, width=4, BF16, SiLU.
//
// A 256-thread workgroup owns 256 adjacent features and 32 token rows.
// It amortizes weight/prefix loads across four times as many rows as the
// deployed BM8 Triton schedule while retaining contiguous feature accesses.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text

	.macro CONV_TOKEN_M8192
	global_load_ushort v11, v1, s[4:5]
	s_waitcnt vmcnt(0)
	v_lshlrev_b32_e32 v11, 16, v11

	// Preserve the deployed BF16-product / FP32-accumulation boundary.
	v_mul_f32_e32 v12, v4, v7
	v_mul_f32_e32 v13, v5, v8
	v_mul_f32_e32 v14, v6, v9
	v_mul_f32_e32 v15, v11, v10
	v_cvt_pk_bf16_f32 v16, v12, v13
	v_cvt_pk_bf16_f32 v17, v14, v15
	v_lshlrev_b32_e32 v12, 16, v16
	v_and_b32_e32 v13, 0xffff0000, v16
	v_lshlrev_b32_e32 v14, 16, v17
	v_and_b32_e32 v15, 0xffff0000, v17
	v_add_f32_e32 v18, v12, v13
	v_add_f32_e32 v18, v18, v14
	v_add_f32_e32 v18, v18, v15

	// Match Triton's subnormal-preserving exp2 lowering and FP32 division.
	v_mul_f32_e64 v19, -v18, s28
	v_cmp_gt_f32_e32 vcc, s29, v19
	v_sub_f32_e32 v20, 0, v18
	v_cndmask_b32_e32 v19, 0, v31, vcc
	v_fmac_f32_e32 v19, s28, v20
	v_exp_f32_e32 v20, v19
	v_cndmask_b32_e32 v19, 0, v32, vcc
	v_ldexp_f32 v20, v20, v19
	v_add_f32_e32 v20, 1.0, v20

	v_div_scale_f32 v21, s[30:31], v20, v20, v18
	v_rcp_f32_e32 v22, v21
	v_div_scale_f32 v23, vcc, v18, v20, v18
	v_fma_f32 v24, -v21, v22, 1.0
	v_fmac_f32_e32 v22, v24, v22
	v_mul_f32_e32 v25, v23, v22
	v_fma_f32 v24, -v21, v25, v23
	v_fmac_f32_e32 v25, v24, v22
	v_fma_f32 v21, -v21, v25, v23
	v_div_fmas_f32 v21, v21, v22, v25
	v_div_fixup_f32 v18, v21, v20, v18

	v_cvt_pk_bf16_f32 v28, v18, v18
	global_store_short v1, v28, s[14:15]

	v_mov_b32_e32 v4, v5
	v_mov_b32_e32 v5, v6
	v_mov_b32_e32 v6, v11
	v_add_u32_e32 v1, 0x4000, v1
	.endm

	.protected qwen36_gdn_causal_conv_m8192_bm32_gfx950
	.globl qwen36_gdn_causal_conv_m8192_bm32_gfx950
	.p2align 8
	.type qwen36_gdn_causal_conv_m8192_bm32_gfx950,@function
qwen36_gdn_causal_conv_m8192_bm32_gfx950:
	// Kernargs: x, weight, state pool, cache index, has-initial flag, output.
	s_mov_b32 s20, s2
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dwordx2 s[10:11], s[0:1], 24
	s_load_dwordx2 s[12:13], s[0:1], 32
	s_load_dwordx2 s[14:15], s[0:1], 40
	s_waitcnt lgkmcnt(0)
	s_load_dword s16, s[10:11], 0
	s_load_dword s17, s[12:13], 0
	s_waitcnt lgkmcnt(0)
	s_and_b32 s17, s17, 0xff
	s_mul_i32 s18, s16, 0xc000
	s_add_u32 s8, s8, s18
	s_addc_u32 s9, s9, 0

	// workgroup = token_chunk*32 + 256-feature block.
	s_lshr_b32 s21, s20, 5
	s_and_b32 s22, s20, 31

	// Feature-block byte displacement: 256 adjacent BF16 features.
	s_lshl_b32 s23, s22, 9
	// Chunk displacement: 32 token rows * 8192 BF16 features.
	s_lshl_b32 s24, s21, 19
	s_mov_b32 s25, s23
	s_add_u32 s4, s4, s25
	s_addc_u32 s5, s5, 0
	s_add_u32 s14, s14, s25
	s_addc_u32 s15, s15, 0

	// Weight and recurrent-state feature-block displacements.
	s_lshl_b32 s25, s22, 11
	s_add_u32 s6, s6, s25
	s_addc_u32 s7, s7, 0
	s_mul_i32 s25, s22, 0x600
	s_add_u32 s8, s8, s25
	s_addc_u32 s9, s9, 0

	// Lane offsets within a token row, four weights, and three states.
	v_lshlrev_b32_e32 v26, 1, v0
	v_add_u32_e32 v1, s24, v26
	v_lshlrev_b32_e32 v2, 3, v0
	v_lshlrev_b32_e32 v3, 1, v0
	v_lshl_add_u32 v3, v0, 2, v3

	global_load_dwordx2 v[16:17], v2, s[6:7]
	s_waitcnt vmcnt(0)
	v_lshlrev_b32_e32 v7, 16, v16
	v_and_b32_e32 v8, 0xffff0000, v16
	v_lshlrev_b32_e32 v9, 16, v17
	v_and_b32_e32 v10, 0xffff0000, v17

	// Only the first token chunk consumes the incoming recurrent state.
	s_cmp_eq_u32 s21, 0
	s_cbranch_scc0 .Lprior_x
	s_cmp_eq_u32 s17, 0
	s_cbranch_scc1 .Lzero_state
	global_load_dword v30, v3, s[8:9]
	global_load_ushort v6, v3, s[8:9] offset:4
	s_waitcnt vmcnt(0)
	v_lshlrev_b32_e32 v4, 16, v30
	v_and_b32_e32 v5, 0xffff0000, v30
	v_lshlrev_b32_e32 v6, 16, v6
	s_branch .Lstate_ready

.Lzero_state:
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v6, 0
	s_branch .Lstate_ready

.Lprior_x:
	v_add_u32_e32 v27, -0xc000, v1
	global_load_ushort v4, v27, s[4:5]
	v_add_u32_e32 v27, 0x4000, v27
	global_load_ushort v5, v27, s[4:5]
	v_add_u32_e32 v27, 0x4000, v27
	global_load_ushort v6, v27, s[4:5]
	s_waitcnt vmcnt(0)
	v_lshlrev_b32_e32 v4, 16, v4
	v_lshlrev_b32_e32 v5, 16, v5
	v_lshlrev_b32_e32 v6, 16, v6

.Lstate_ready:
	s_mov_b32 s26, 0x42800000
	s_mov_b32 s27, -64
	s_mov_b32 s28, 0x3fb8aa3b
	s_mov_b32 s29, 0xc2fc0000
	v_mov_b32_e32 v31, s26
	v_mov_b32_e32 v32, s27

	.rept 32
	CONV_TOKEN_M8192
	.endr

	// One workgroup per feature block installs the sequence's last three inputs.
	s_cmp_eq_u32 s21, 0
	s_cbranch_scc0 .Lend
	v_add_u32_e32 v27, 0x7ff4000, v26
	global_load_ushort v4, v27, s[4:5]
	v_add_u32_e32 v27, 0x4000, v27
	global_load_ushort v5, v27, s[4:5]
	v_add_u32_e32 v27, 0x4000, v27
	global_load_ushort v6, v27, s[4:5]
	s_waitcnt vmcnt(0)
	v_lshlrev_b32_e32 v4, 16, v4
	v_lshlrev_b32_e32 v5, 16, v5
	v_lshlrev_b32_e32 v6, 16, v6
	v_cvt_pk_bf16_f32 v29, v4, v5
	v_cvt_pk_bf16_f32 v30, v6, v6
	global_store_dword v3, v29, s[8:9]
	global_store_short v3, v30, s[8:9] offset:4

.Lend:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_gdn_causal_conv_m8192_bm32_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 48
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 33
		.amdhsa_accum_offset 36
		.amdhsa_next_free_sgpr 32
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_gdn_causal_conv_m8192_bm32_gfx950, .Lfunc_end0-qwen36_gdn_causal_conv_m8192_bm32_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: x_bf16, .offset: 0, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: weight_bf16, .offset: 8, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: state_bf16, .offset: 16, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_write }
      - { .name: cache_index_i32, .offset: 24, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: has_initial_state_i8, .offset: 32, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: output_bf16, .offset: 40, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: write_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 48
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_gdn_causal_conv_m8192_bm32_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 34
    .sgpr_spill_count: 0
    .symbol: qwen36_gdn_causal_conv_m8192_bm32_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 33
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
