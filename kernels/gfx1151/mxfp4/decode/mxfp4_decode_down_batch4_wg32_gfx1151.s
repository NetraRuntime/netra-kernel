// SPDX-License-Identifier: MIT
//
// Accepted batched raw AMDGCN MXFP4 decode kernel for gfx1151.
//
// Fixed real Qwen3.6-35B-A3B down-projection shape:
//   8 selected experts, N=2048, K=512, no split K.
//
// Inputs are load-time repacked (not dequantized):
//   packed: [8, K/2, N] u8
//   scales: [8, K/32, N] E8M0 u8
//   a:      [K] bf16
//   y:      [8, N] fp32
//
// Launch: grid=(16,8,1), block=(32,1,1).

	.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
	.amdhsa_code_object_version 6
	.text

	.macro DECODE_DOT W, A
	v_and_b32_e32 v18, 0x07070707, \W
	v_lshrrev_b32_e32 v19, 4, \W
	v_and_b32_e32 v19, 0x07070707, v19
	v_lshlrev_b32_e32 v24, 4, \W
	v_and_b32_e32 v33, 0x80808080, \W

	// Exact E2M1 -> BF16 byte tables.
	v_perm_b32 v20, v5, v4, v18
	v_perm_b32 v22, v5, v4, v19
	v_perm_b32 v21, v7, v6, v18
	v_perm_b32 v23, v7, v6, v19
	v_and_b32_e32 v24, 0x80808080, v24
	v_or_b32_e32 v21, v24, v21
	v_or_b32_e32 v23, v33, v23

	// First pair by N, then re-pair adjacent K values for packed BF16 dot2.
	v_perm_b32 v25, v21, v20, 0x05010400
	v_perm_b32 v26, v21, v20, 0x07030602
	v_perm_b32 v27, v23, v22, 0x05010400
	v_perm_b32 v28, v23, v22, 0x07030602
	v_perm_b32 v29, v27, v25, 0x05040100
	v_perm_b32 v31, v27, v25, 0x07060302
	v_perm_b32 v32, v28, v26, 0x05040100
	v_perm_b32 v33, v28, v26, 0x07060302
	v_dot2_f32_bf16 v12, v29, \A, v12
	v_dot2_f32_bf16 v13, v31, \A, v13
	v_dot2_f32_bf16 v14, v32, \A, v14
	v_dot2_f32_bf16 v15, v33, \A, v15
	.endm

	.macro ISSUE_PAIR W0, W1, A0, A1, AOFF
	global_load_b32 \W0, v1, s[4:5]
	global_load_b32 \W1, v1, s[4:5] offset:2048
	s_load_b32 \A0, s[8:9], \AOFF
	s_load_b32 \A1, s[8:9], \AOFF+4
	// The global address is captured at issue. Advance it for the next
	// coalesced pair; adjacent issues use an explicit dependency wait.
	s_add_u32 s4, s4, 4096
	s_addc_u32 s5, s5, 0
	.endm

	.protected mxfp4_decode_down_pipeline_gfx1151
	.globl mxfp4_decode_down_pipeline_gfx1151
	.p2align 8
	.type mxfp4_decode_down_pipeline_gfx1151,@function
mxfp4_decode_down_pipeline_gfx1151:
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0
	s_load_b128 s[8:11], s[0:1], 16
	s_load_b64 s[24:25], s[0:1], 32
	s_waitcnt lgkmcnt(0)

	// workgroup_id_y is the selected-expert slot. Resolve it through the
	// runtime top-k IDs for resident weight addressing.
	s_lshl_b32 s22, s3, 2
	s_waitcnt_depctr 0
	s_load_b32 s23, s[24:25], s22
	s_waitcnt lgkmcnt(0)
	s_lshl_b32 s12, s23, 19
	s_lshl_b32 s13, s23, 15
	s_lshl_b32 s14, s3, 13
	s_lshl_b32 s22, s3, 10
	s_waitcnt_depctr 0
	s_add_u32 s4, s4, s12
	s_addc_u32 s5, s5, 0
	s_add_u32 s6, s6, s13
	s_addc_u32 s7, s7, 0
	s_add_u32 s8, s8, s22
	s_addc_u32 s9, s9, 0
	s_add_u32 s10, s10, s14
	s_addc_u32 s11, s11, 0

	// Each workgroup covers 128 output columns; each lane owns four.
	s_lshl_b32 s15, s2, 7
	v_lshlrev_b32_e32 v1, 2, v0
	s_waitcnt_depctr 0
	v_add_nc_u32_e32 v1, s15, v1
	s_lshl_b32 s15, s2, 9
	v_lshlrev_b32_e32 v2, 4, v0
	s_waitcnt_depctr 0
	v_add_nc_u32_e32 v2, s15, v2

	v_mov_b32_e32 v4, 0xc0800000
	v_mov_b32_e32 v5, 0xc0804000
	v_mov_b32_e32 v6, 0x3f3f3f00
	v_mov_b32_e32 v7, 0x40404040
	v_dual_mov_b32 v8, 0 :: v_dual_mov_b32 v9, 0
	v_dual_mov_b32 v10, 0 :: v_dual_mov_b32 v11, 0
	s_mov_b32 s16, 16

.Lmxblock:
	v_dual_mov_b32 v12, 0 :: v_dual_mov_b32 v13, 0
	v_dual_mov_b32 v14, 0 :: v_dual_mov_b32 v15, 0
	global_load_b32 v30, v1, s[6:7]

	// Batch four pairs before each full dependency wait. Four pair buffers
	// exactly fill the existing 40-VGPR allocation granule without spilling.
	ISSUE_PAIR v16, v17, s20, s21, 0
	s_waitcnt_depctr 0
	ISSUE_PAIR v34, v35, s22, s23, 8
	s_waitcnt_depctr 0
	ISSUE_PAIR v36, v37, s26, s27, 16
	s_waitcnt_depctr 0
	ISSUE_PAIR v38, v39, s28, s29, 24
	s_waitcnt vmcnt(0) lgkmcnt(0)
	DECODE_DOT v16, s20
	DECODE_DOT v17, s21
	DECODE_DOT v34, s22
	DECODE_DOT v35, s23
	DECODE_DOT v36, s26
	DECODE_DOT v37, s27
	DECODE_DOT v38, s28
	DECODE_DOT v39, s29
	ISSUE_PAIR v16, v17, s20, s21, 32
	s_waitcnt_depctr 0
	ISSUE_PAIR v34, v35, s22, s23, 40
	s_waitcnt_depctr 0
	ISSUE_PAIR v36, v37, s26, s27, 48
	s_waitcnt_depctr 0
	ISSUE_PAIR v38, v39, s28, s29, 56
	s_waitcnt vmcnt(0) lgkmcnt(0)
	DECODE_DOT v16, s20
	DECODE_DOT v17, s21
	DECODE_DOT v34, s22
	DECODE_DOT v35, s23
	DECODE_DOT v36, s26
	DECODE_DOT v37, s27
	DECODE_DOT v38, s28
	DECODE_DOT v39, s29

	s_waitcnt vmcnt(0)
	v_bfe_u32 v31, v30, 0, 8
	v_lshlrev_b32_e32 v31, 23, v31
	v_fmac_f32_e32 v8, v12, v31
	v_bfe_u32 v31, v30, 8, 8
	v_lshlrev_b32_e32 v31, 23, v31
	v_fmac_f32_e32 v9, v13, v31
	v_bfe_u32 v31, v30, 16, 8
	v_lshlrev_b32_e32 v31, 23, v31
	v_fmac_f32_e32 v10, v14, v31
	v_lshrrev_b32_e32 v31, 24, v30
	v_lshlrev_b32_e32 v31, 23, v31
	v_fmac_f32_e32 v11, v15, v31

	s_add_u32 s6, s6, 2048
	s_addc_u32 s7, s7, 0
	s_add_u32 s8, s8, 64
	s_addc_u32 s9, s9, 0
	s_sub_u32 s16, s16, 1
	s_waitcnt_depctr 0
	s_cmp_lg_u32 s16, 0
	s_cbranch_scc1 .Lmxblock

	// No split K: direct coalesced stores.
	global_store_b32 v2, v8, s[10:11]
	global_store_b32 v2, v9, s[10:11] offset:4
	global_store_b32 v2, v10, s[10:11] offset:8
	global_store_b32 v2, v11, s[10:11] offset:12
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel mxfp4_decode_down_pipeline_gfx1151
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 40
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_wavefront_size32 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 40
		.amdhsa_next_free_sgpr 30
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_workgroup_processor_mode 1
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_shared_vgpr_count 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size mxfp4_decode_down_pipeline_gfx1151, .Lfunc_end0-mxfp4_decode_down_pipeline_gfx1151

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: packed, .offset: 0, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: scales, .offset: 8, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: activation, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: output, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: expert_ids, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 40
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: mxfp4_decode_down_pipeline_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 30
    .sgpr_spill_count: 0
    .symbol: mxfp4_decode_down_pipeline_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 40
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
