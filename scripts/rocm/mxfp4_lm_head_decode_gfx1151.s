// SPDX-License-Identifier: MIT
//
// Raw gfx1151 MXFP4 LM-head decode: M=1, N=248320, K=2048.
// packed=[K/2,N], scales=[K/32,N], activation=[K], output=[N].
// grid=(485,1,1), block=(128,1,1); each lane owns four logits.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
	.amdhsa_code_object_version 6
	.text

	.macro DECODE_DOT W A
	v_and_b32_e32 v18, 0x07070707, \W
	v_lshrrev_b32_e32 v19, 4, \W
	v_and_b32_e32 v19, 0x07070707, v19
	v_lshlrev_b32_e32 v24, 4, \W
	v_and_b32_e32 v33, 0x80808080, \W
	v_perm_b32 v20, v5, v4, v18
	v_perm_b32 v22, v5, v4, v19
	v_perm_b32 v21, v7, v6, v18
	v_perm_b32 v23, v7, v6, v19
	v_and_b32_e32 v24, 0x80808080, v24
	v_or_b32_e32 v21, v24, v21
	v_or_b32_e32 v23, v33, v23
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

	.macro LOAD_ROW WREG AREG AOFF
	global_load_b32 \WREG, v2, s[4:5]
	s_load_b32 \AREG, s[8:9], \AOFF
	v_add_nc_u32_e32 v2, 248320, v2
	.endm

	.protected mxfp4_lm_head_decode_gfx1151
	.globl mxfp4_lm_head_decode_gfx1151
	.p2align 8
	.type mxfp4_lm_head_decode_gfx1151,@function
mxfp4_lm_head_decode_gfx1151:
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0
	s_load_b128 s[8:11], s[0:1], 16
	s_waitcnt lgkmcnt(0)

	// Global column = workgroup*512 + lane*4.
	s_lshl_b32 s12, s2, 9
	v_lshlrev_b32_e32 v1, 2, v0
	s_waitcnt_depctr 0
	v_add_nc_u32_e32 v1, s12, v1

	v_mov_b32_e32 v4, 0xc0800000
	v_mov_b32_e32 v5, 0xc0804000
	v_mov_b32_e32 v6, 0x3f3f3f00
	v_mov_b32_e32 v7, 0x40404040
	v_dual_mov_b32 v8, 0 :: v_dual_mov_b32 v9, 0
	v_dual_mov_b32 v10, 0 :: v_dual_mov_b32 v11, 0
	s_mov_b32 s16, 64

.Lmxblock:
	v_dual_mov_b32 v12, 0 :: v_dual_mov_b32 v13, 0
	v_dual_mov_b32 v14, 0 :: v_dual_mov_b32 v15, 0
	global_load_b32 v30, v1, s[6:7]
	v_mov_b32_e32 v2, v1

	LOAD_ROW v16 s20 0
	LOAD_ROW v17 s21 4
	s_waitcnt vmcnt(0) lgkmcnt(0)
	DECODE_DOT v16 s20
	LOAD_ROW v16 s20 8
	DECODE_DOT v17 s21
	LOAD_ROW v17 s21 12
	s_waitcnt vmcnt(0) lgkmcnt(0)
	DECODE_DOT v16 s20
	LOAD_ROW v16 s20 16
	DECODE_DOT v17 s21
	LOAD_ROW v17 s21 20
	s_waitcnt vmcnt(0) lgkmcnt(0)
	DECODE_DOT v16 s20
	LOAD_ROW v16 s20 24
	DECODE_DOT v17 s21
	LOAD_ROW v17 s21 28
	s_waitcnt vmcnt(0) lgkmcnt(0)
	DECODE_DOT v16 s20
	DECODE_DOT v17 s21

	LOAD_ROW v16 s20 32
	LOAD_ROW v17 s21 36
	s_waitcnt vmcnt(0) lgkmcnt(0)
	DECODE_DOT v16 s20
	LOAD_ROW v16 s20 40
	DECODE_DOT v17 s21
	LOAD_ROW v17 s21 44
	s_waitcnt vmcnt(0) lgkmcnt(0)
	DECODE_DOT v16 s20
	LOAD_ROW v16 s20 48
	DECODE_DOT v17 s21
	LOAD_ROW v17 s21 52
	s_waitcnt vmcnt(0) lgkmcnt(0)
	DECODE_DOT v16 s20
	LOAD_ROW v16 s20 56
	DECODE_DOT v17 s21
	LOAD_ROW v17 s21 60
	s_waitcnt vmcnt(0) lgkmcnt(0)
	DECODE_DOT v16 s20
	DECODE_DOT v17 s21

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

	s_add_u32 s4, s4, 3973120
	s_addc_u32 s5, s5, 0
	s_add_u32 s6, s6, 248320
	s_addc_u32 s7, s7, 0
	s_add_u32 s8, s8, 64
	s_addc_u32 s9, s9, 0
	s_sub_u32 s16, s16, 1
	s_waitcnt_depctr 0
	s_cmp_lg_u32 s16, 0
	s_cbranch_scc1 .Lmxblock

	v_lshlrev_b32_e32 v2, 2, v1
	global_store_b128 v2, v[8:11], s[10:11]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel mxfp4_lm_head_decode_gfx1151
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 32
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_wavefront_size32 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 34
		.amdhsa_next_free_sgpr 22
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_workgroup_processor_mode 1
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size mxfp4_lm_head_decode_gfx1151, .Lfunc_end0-mxfp4_lm_head_decode_gfx1151

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
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 128
    .name: mxfp4_lm_head_decode_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 24
    .sgpr_spill_count: 0
    .symbol: mxfp4_lm_head_decode_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 34
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
