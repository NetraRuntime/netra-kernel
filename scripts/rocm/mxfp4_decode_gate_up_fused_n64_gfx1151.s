// SPDX-License-Identifier: MIT
//
// Raw gfx1151 fused Qwen3.6 decode gate/up + SiLU multiplication.
// E=8, M=1, N=512, K=2048. One wave owns 64 columns (two per lane).
// grid=(8,8,1), block=(32,1,1). Output is [E,512] BF16.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
	.amdhsa_code_object_version 6
	.text

	.macro DECODE_DOT2 W A C0 C1
	v_and_b32_e32 v20, 0x07070707, \W
	v_lshrrev_b32_e32 v21, 4, \W
	v_and_b32_e32 v21, 0x07070707, v21
	v_lshlrev_b32_e32 v22, 4, \W
	v_and_b32_e32 v23, 0x80808080, \W
	v_perm_b32 v24, v5, v4, v20
	v_perm_b32 v25, v5, v4, v21
	v_perm_b32 v26, v7, v6, v20
	v_perm_b32 v27, v7, v6, v21
	v_and_b32_e32 v22, 0x80808080, v22
	v_or_b32_e32 v26, v22, v26
	v_or_b32_e32 v27, v23, v27
	v_perm_b32 v28, v26, v24, 0x05010400
	v_perm_b32 v29, v27, v25, 0x05010400
	v_perm_b32 v30, v29, v28, 0x05040100
	v_perm_b32 v31, v29, v28, 0x07060302
	v_dot2_f32_bf16 \C0, v30, \A, \C0
	v_dot2_f32_bf16 \C1, v31, \A, \C1
	.endm

	.macro TWO_ROWS AOFF
	global_load_ushort v16, v2, s[4:5]
	global_load_ushort v17, v2, s[8:9]
	s_load_b32 s20, s[12:13], \AOFF
	v_add_nc_u32_e32 v2, 512, v2
	global_load_ushort v18, v2, s[4:5]
	global_load_ushort v19, v2, s[8:9]
	s_load_b32 s21, s[12:13], \AOFF+4
	v_add_nc_u32_e32 v2, 512, v2
	s_waitcnt vmcnt(0) lgkmcnt(0)
	DECODE_DOT2 v16 s20 v12 v13
	DECODE_DOT2 v17 s20 v14 v15
	DECODE_DOT2 v18 s21 v12 v13
	DECODE_DOT2 v19 s21 v14 v15
	.endm

	.protected mxfp4_decode_gate_up_fused_n64_gfx1151
	.globl mxfp4_decode_gate_up_fused_n64_gfx1151
	.p2align 8
	.type mxfp4_decode_gate_up_fused_n64_gfx1151,@function
mxfp4_decode_gate_up_fused_n64_gfx1151:
	s_load_b128 s[4:7], s[0:1], 0
	s_load_b128 s[8:11], s[0:1], 16
	s_load_b128 s[12:15], s[0:1], 32
	s_waitcnt lgkmcnt(0)
	s_lshl_b32 s17, s3, 19
	s_lshl_b32 s18, s3, 15
	s_lshl_b32 s19, s3, 10
	s_waitcnt_depctr 0
	s_add_u32 s4, s4, s17
	s_addc_u32 s5, s5, 0
	s_add_u32 s8, s8, s17
	s_addc_u32 s9, s9, 0
	s_add_u32 s6, s6, s18
	s_addc_u32 s7, s7, 0
	s_add_u32 s10, s10, s18
	s_addc_u32 s11, s11, 0
	s_add_u32 s14, s14, s19
	s_addc_u32 s15, s15, 0
	s_lshl_b32 s17, s2, 6
	v_lshlrev_b32_e32 v1, 1, v0
	s_waitcnt_depctr 0
	v_add_nc_u32_e32 v1, s17, v1
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
	global_load_ushort v36, v1, s[6:7]
	global_load_ushort v37, v1, s[10:11]
	v_mov_b32_e32 v2, v1
	TWO_ROWS 0
	TWO_ROWS 8
	TWO_ROWS 16
	TWO_ROWS 24
	TWO_ROWS 32
	TWO_ROWS 40
	TWO_ROWS 48
	TWO_ROWS 56
	s_waitcnt vmcnt(0)
	v_bfe_u32 v32, v36, 0, 8
	v_lshlrev_b32_e32 v32, 23, v32
	v_fmac_f32_e32 v8, v12, v32
	v_lshrrev_b32_e32 v32, 8, v36
	v_lshlrev_b32_e32 v32, 23, v32
	v_fmac_f32_e32 v9, v13, v32
	v_bfe_u32 v32, v37, 0, 8
	v_lshlrev_b32_e32 v32, 23, v32
	v_fmac_f32_e32 v10, v14, v32
	v_lshrrev_b32_e32 v32, 8, v37
	v_lshlrev_b32_e32 v32, 23, v32
	v_fmac_f32_e32 v11, v15, v32
	s_add_u32 s4, s4, 8192
	s_addc_u32 s5, s5, 0
	s_add_u32 s8, s8, 8192
	s_addc_u32 s9, s9, 0
	s_add_u32 s6, s6, 512
	s_addc_u32 s7, s7, 0
	s_add_u32 s10, s10, 512
	s_addc_u32 s11, s11, 0
	s_add_u32 s12, s12, 64
	s_addc_u32 s13, s13, 0
	s_sub_u32 s16, s16, 1
	s_waitcnt_depctr 0
	s_cmp_lg_u32 s16, 0
	s_cbranch_scc1 .Lmxblock

	v_mov_b32_e32 v38, 0xbfb8aa3b
	v_mov_b32_e32 v39, 0x3f800000
	v_mul_f32_e32 v32, v8, v38
	v_exp_f32_e32 v32, v32
	v_add_f32_e32 v32, v39, v32
	v_rcp_f32_e32 v32, v32
	v_mul_f32_e32 v33, v8, v10
	v_mul_f32_e32 v8, v33, v32
	v_mul_f32_e32 v32, v9, v38
	v_exp_f32_e32 v32, v32
	v_add_f32_e32 v32, v39, v32
	v_rcp_f32_e32 v32, v32
	v_mul_f32_e32 v33, v9, v11
	v_mul_f32_e32 v9, v33, v32
	// Round two finite FP32 results to BF16 RNE and pack.
	v_lshrrev_b32_e32 v32, 16, v8
	v_and_b32_e32 v32, 1, v32
	v_add_nc_u32_e32 v32, 0x7fff, v32
	v_add_nc_u32_e32 v8, v32, v8
	v_lshrrev_b32_e32 v8, 16, v8
	v_lshrrev_b32_e32 v32, 16, v9
	v_and_b32_e32 v32, 1, v32
	v_add_nc_u32_e32 v32, 0x7fff, v32
	v_add_nc_u32_e32 v9, v32, v9
	v_lshrrev_b32_e32 v9, 16, v9
	v_lshl_or_b32 v8, v9, 16, v8
	v_lshlrev_b32_e32 v2, 1, v1
	global_store_b32 v2, v8, s[14:15]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel mxfp4_decode_gate_up_fused_n64_gfx1151
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 48
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_wavefront_size32 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 40
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
	.size mxfp4_decode_gate_up_fused_n64_gfx1151, .Lfunc_end0-mxfp4_decode_gate_up_fused_n64_gfx1151

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: gate_packed, .offset: 0, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: gate_scales, .offset: 8, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: up_packed, .offset: 16, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: up_scales, .offset: 24, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: activation, .offset: 32, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: down_activation_bf16, .offset: 40, .size: 8,
          .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 48
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 32
    .name: mxfp4_decode_gate_up_fused_n64_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 24
    .sgpr_spill_count: 0
    .symbol: mxfp4_decode_gate_up_fused_n64_gfx1151.kd
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
