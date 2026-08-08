// SPDX-License-Identifier: MIT
//
// Qwen3.6 GDN target-verification causal convolution consuming the QKV prefix
// directly from contiguous QKVZ rows. Exact shape family: B>=1, M=12,
// QKVZ=12288, QKV=8192, width=4, BF16, SiLU.
//
// One 256-thread wave64 workgroup owns 256 contiguous features of one
// sequence.  Unlike the Triton oracle, the raw kernel has no masked lanes,
// barrier, buffer descriptors, or generic state-length/tree branches.  It
// preserves the full speculative intermediate-window ABI for commit/rollback.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text

	.macro CONV_TOKEN
	// Load this token's BF16 input and expand it exactly to FP32.
	global_load_ushort v11, v1, s[4:5]
	s_waitcnt vmcnt(0)
	v_lshlrev_b32_e32 v11, 16, v11

	// Triton gives BF16 multiplication semantics to the BF16 operands before
	// the four products are accumulated in FP32.  Pack conversion reproduces
	// the deployed round-to-nearest-even product boundary for finite Qwen data.
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

	// Save the post-token [previous-1, previous, current] BF16 window.
	v_cvt_pk_bf16_f32 v29, v5, v6
	v_cvt_pk_bf16_f32 v30, v11, v11
	global_store_dword v3, v29, s[12:13]
	global_store_short v3, v30, s[12:13] offset:4

	// Match OCML's subnormal-preserving exp2 lowering used by Triton for
	// exp(-acc), followed by its IEEE FP32 division refinement.
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
	global_store_short v2, v28, s[16:17]

	// Roll the FP32-exact BF16 state and advance token/window byte offsets.
	v_mov_b32_e32 v4, v5
	v_mov_b32_e32 v5, v6
	v_mov_b32_e32 v6, v11
	v_add_u32_e32 v1, 0x6000, v1
	v_add_u32_e32 v2, 0x4000, v2
	v_add_u32_e32 v3, 0xc000, v3
	.endm

	.protected qwen36_gdn_qkvz_conv_m12_gfx950
	.globl qwen36_gdn_qkvz_conv_m12_gfx950
	.p2align 8
	.type qwen36_gdn_qkvz_conv_m12_gfx950,@function
qwen36_gdn_qkvz_conv_m12_gfx950:
	// Kernargs: x, weight, state, state_indices, intermediate_window,
	// intermediate_indices, output, batch.
	s_mov_b32 s20, s2
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dwordx2 s[10:11], s[0:1], 24
	s_load_dwordx2 s[12:13], s[0:1], 32
	s_load_dwordx2 s[14:15], s[0:1], 40
	s_load_dwordx2 s[16:17], s[0:1], 48
	s_load_dword s18, s[0:1], 56
	s_waitcnt lgkmcnt(0)

	// workgroup = sequence*32 + 256-feature block.
	s_lshr_b32 s21, s20, 5
	s_and_b32 s22, s20, 31
	s_cmp_ge_u32 s21, s18
	s_cbranch_scc1 .Lend
	s_lshl_b32 s25, s21, 2
	s_load_dword s23, s[10:11], s25
	s_load_dword s24, s[14:15], s25
	s_waitcnt lgkmcnt(0)
	// Captured B64 graphs replay smaller live batches with -1 in padded cache
	// slots.  Triton's USE_PAD_SLOT path returns before touching either cache;
	// preserve the same contract in raw assembly.
	s_cmp_eq_u32 s23, 0xffffffff
	s_cbranch_scc1 .Lend
	s_cmp_eq_u32 s24, 0xffffffff
	s_cbranch_scc1 .Lend

	// Sequence-local QKVZ source plus the 256-feature QKV block.
	s_mul_i32 s25, s21, 0x48000
	s_lshl_b32 s26, s22, 9
	s_add_u32 s25, s25, s26
	s_add_u32 s4, s4, s25
	s_addc_u32 s5, s5, 0
	// Packed output remains [B,12,8192].
	s_mul_i32 s25, s21, 0x30000
	s_add_u32 s25, s25, s26
	s_add_u32 s16, s16, s25
	s_addc_u32 s17, s17, 0

	// Per-feature four-column weight base for this block.
	s_lshl_b32 s25, s22, 11
	s_add_u32 s6, s6, s25
	s_addc_u32 s7, s7, 0

	// Live cache state is contiguous (cache,D,3).  The serving cache has
	// millions of slots, so slot*49152 exceeds 32 bits.  Preserve both halves
	// of the product before adding the small feature-block displacement.
	s_mul_i32 s25, s23, 0xc000
	s_mul_hi_u32 s26, s23, 0xc000
	s_mul_i32 s27, s22, 0x600
	s_add_u32 s25, s25, s27
	s_addc_u32 s26, s26, 0
	s_add_u32 s8, s8, s25
	s_addc_u32 s9, s9, s26

	// Speculative window is contiguous (cache,12,D,3).  Its 589824-byte slot
	// stride crosses 4 GiB even sooner, so widen this address independently.
	s_mul_i32 s25, s24, 0x90000
	s_mul_hi_u32 s26, s24, 0x90000
	s_mul_i32 s27, s22, 0x600
	s_add_u32 s25, s25, s27
	s_addc_u32 s26, s26, 0
	s_add_u32 s12, s12, s25
	s_addc_u32 s13, s13, s26

	// Lane byte offsets for BF16 feature, four BF16 weights, and 3-BF16
	// intermediate records.
	v_lshlrev_b32_e32 v1, 1, v0
	v_lshlrev_b32_e32 v2, 3, v0
	v_lshlrev_b32_e32 v3, 2, v0
	v_lshl_add_u32 v3, v0, 1, v3

	global_load_dword v30, v3, s[8:9]
	global_load_ushort v6, v3, s[8:9] offset:4
	global_load_dwordx2 v[16:17], v2, s[6:7]
	s_waitcnt vmcnt(0)
	v_lshlrev_b32_e32 v4, 16, v30
	v_and_b32_e32 v5, 0xffff0000, v30
	v_lshlrev_b32_e32 v6, 16, v6
	v_lshlrev_b32_e32 v7, 16, v16
	v_and_b32_e32 v8, 0xffff0000, v16
	v_lshlrev_b32_e32 v9, 16, v17
	v_and_b32_e32 v10, 0xffff0000, v17
	v_lshlrev_b32_e32 v2, 1, v0

	s_mov_b32 s26, 0x42800000	// 64.0f
	s_mov_b32 s27, -64		// ldexp compensation
	s_mov_b32 s28, 0x3fb8aa3b	// log2(e)
	s_mov_b32 s29, 0xc2fc0000	// -126.0f
	v_mov_b32_e32 v31, s26
	v_mov_b32_e32 v32, s27

	.rept 12
	CONV_TOKEN
	.endr

	// Persist the final three BF16 inputs to the contiguous cache.
	v_cvt_pk_bf16_f32 v29, v4, v5
	v_cvt_pk_bf16_f32 v30, v6, v6
	v_lshlrev_b32_e32 v3, 2, v0
	v_lshl_add_u32 v3, v0, 1, v3
	global_store_dword v3, v29, s[8:9]
	global_store_short v3, v30, s[8:9] offset:4
.Lend:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_gdn_qkvz_conv_m12_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 64
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
	.size qwen36_gdn_qkvz_conv_m12_gfx950, .Lfunc_end0-qwen36_gdn_qkvz_conv_m12_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: qkvz_bf16, .offset: 0, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: weight_bf16, .offset: 8, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: state_bf16, .offset: 16, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_write }
      - { .name: state_indices_i32, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: intermediate_window_bf16, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: intermediate_indices_i32, .offset: 40, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: output_bf16, .offset: 48, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: batch, .offset: 56, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 64
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_gdn_qkvz_conv_m12_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 34
    .sgpr_spill_count: 0
    .symbol: qwen36_gdn_qkvz_conv_m12_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 33
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
