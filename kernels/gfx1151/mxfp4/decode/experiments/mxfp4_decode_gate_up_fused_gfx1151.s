// SPDX-License-Identifier: MIT
//
// Raw gfx1151 fused Qwen3.6 decode gate/up + SiLU multiplication.
// E=8, M=1, N=512, K=2048. Output is [E,512] BF16 for down projection.
// grid=(4,8,1), block=(32,1,1); no split-K or intermediate FP32 stores.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
	.amdhsa_code_object_version 6
	.text

	.macro DECODE_DOT W A C0 C1 C2 C3
	v_and_b32_e32 v26, 0x07070707, \W
	v_lshrrev_b32_e32 v27, 4, \W
	v_and_b32_e32 v27, 0x07070707, v27
	v_lshlrev_b32_e32 v32, 4, \W
	v_and_b32_e32 v41, 0x80808080, \W
	v_perm_b32 v28, v5, v4, v26
	v_perm_b32 v30, v5, v4, v27
	v_perm_b32 v29, v7, v6, v26
	v_perm_b32 v31, v7, v6, v27
	v_and_b32_e32 v32, 0x80808080, v32
	v_or_b32_e32 v29, v32, v29
	v_or_b32_e32 v31, v41, v31
	v_perm_b32 v33, v29, v28, 0x05010400
	v_perm_b32 v34, v29, v28, 0x07030602
	v_perm_b32 v35, v31, v30, 0x05010400
	v_perm_b32 v36, v31, v30, 0x07030602
	v_perm_b32 v37, v35, v33, 0x05040100
	v_perm_b32 v38, v35, v33, 0x07060302
	v_perm_b32 v39, v36, v34, 0x05040100
	v_perm_b32 v40, v36, v34, 0x07060302
	v_dot2_f32_bf16 \C0, v37, \A, \C0
	v_dot2_f32_bf16 \C1, v38, \A, \C1
	v_dot2_f32_bf16 \C2, v39, \A, \C2
	v_dot2_f32_bf16 \C3, v40, \A, \C3
	.endm

	.macro TWO_ROWS AOFF
	global_load_b32 v24, v2, s[4:5]
	global_load_b32 v25, v2, s[8:9]
	s_load_b32 s20, s[12:13], \AOFF
	v_add_nc_u32_e32 v2, 512, v2
	global_load_b32 v48, v2, s[4:5]
	global_load_b32 v49, v2, s[8:9]
	s_load_b32 s21, s[12:13], \AOFF+4
	v_add_nc_u32_e32 v2, 512, v2
	s_waitcnt vmcnt(0) lgkmcnt(0)
	DECODE_DOT v24 s20 v16 v17 v18 v19
	DECODE_DOT v25 s20 v20 v21 v22 v23
	DECODE_DOT v48 s21 v16 v17 v18 v19
	DECODE_DOT v49 s21 v20 v21 v22 v23
	.endm

	.protected mxfp4_decode_gate_up_fused_gfx1151
	.globl mxfp4_decode_gate_up_fused_gfx1151
	.p2align 8
	.type mxfp4_decode_gate_up_fused_gfx1151,@function
mxfp4_decode_gate_up_fused_gfx1151:
	// gate packed/scales, up packed/scales, activation, output.
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

	s_lshl_b32 s17, s2, 7
	v_lshlrev_b32_e32 v1, 2, v0
	s_waitcnt_depctr 0
	v_add_nc_u32_e32 v1, s17, v1
	v_mov_b32_e32 v4, 0xc0800000
	v_mov_b32_e32 v5, 0xc0804000
	v_mov_b32_e32 v6, 0x3f3f3f00
	v_mov_b32_e32 v7, 0x40404040
	v_dual_mov_b32 v8, 0 :: v_dual_mov_b32 v9, 0
	v_dual_mov_b32 v10, 0 :: v_dual_mov_b32 v11, 0
	v_dual_mov_b32 v12, 0 :: v_dual_mov_b32 v13, 0
	v_dual_mov_b32 v14, 0 :: v_dual_mov_b32 v15, 0
	s_mov_b32 s16, 64

.Lmxblock:
	v_dual_mov_b32 v16, 0 :: v_dual_mov_b32 v17, 0
	v_dual_mov_b32 v18, 0 :: v_dual_mov_b32 v19, 0
	v_dual_mov_b32 v20, 0 :: v_dual_mov_b32 v21, 0
	v_dual_mov_b32 v22, 0 :: v_dual_mov_b32 v23, 0
	global_load_b32 v46, v1, s[6:7]
	global_load_b32 v47, v1, s[10:11]
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
	v_bfe_u32 v42, v46, 0, 8
	v_lshlrev_b32_e32 v42, 23, v42
	v_fmac_f32_e32 v8, v16, v42
	v_bfe_u32 v42, v46, 8, 8
	v_lshlrev_b32_e32 v42, 23, v42
	v_fmac_f32_e32 v9, v17, v42
	v_bfe_u32 v42, v46, 16, 8
	v_lshlrev_b32_e32 v42, 23, v42
	v_fmac_f32_e32 v10, v18, v42
	v_lshrrev_b32_e32 v42, 24, v46
	v_lshlrev_b32_e32 v42, 23, v42
	v_fmac_f32_e32 v11, v19, v42
	v_bfe_u32 v42, v47, 0, 8
	v_lshlrev_b32_e32 v42, 23, v42
	v_fmac_f32_e32 v12, v20, v42
	v_bfe_u32 v42, v47, 8, 8
	v_lshlrev_b32_e32 v42, 23, v42
	v_fmac_f32_e32 v13, v21, v42
	v_bfe_u32 v42, v47, 16, 8
	v_lshlrev_b32_e32 v42, 23, v42
	v_fmac_f32_e32 v14, v22, v42
	v_lshrrev_b32_e32 v42, 24, v47
	v_lshlrev_b32_e32 v42, 23, v42
	v_fmac_f32_e32 v15, v23, v42

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

	// silu(gate)*up using the native base-2 exponential approximation.
	v_mov_b32_e32 v50, 0xbfb8aa3b
	v_mov_b32_e32 v51, 0x3f800000
	v_mul_f32_e32 v52, v8, v50
	v_exp_f32_e32 v52, v52
	v_add_f32_e32 v52, v51, v52
	v_rcp_f32_e32 v52, v52
	v_mul_f32_e32 v53, v8, v12
	v_mul_f32_e32 v8, v53, v52
	v_mul_f32_e32 v52, v9, v50
	v_exp_f32_e32 v52, v52
	v_add_f32_e32 v52, v51, v52
	v_rcp_f32_e32 v52, v52
	v_mul_f32_e32 v53, v9, v13
	v_mul_f32_e32 v9, v53, v52
	v_mul_f32_e32 v52, v10, v50
	v_exp_f32_e32 v52, v52
	v_add_f32_e32 v52, v51, v52
	v_rcp_f32_e32 v52, v52
	v_mul_f32_e32 v53, v10, v14
	v_mul_f32_e32 v10, v53, v52
	v_mul_f32_e32 v52, v11, v50
	v_exp_f32_e32 v52, v52
	v_add_f32_e32 v52, v51, v52
	v_rcp_f32_e32 v52, v52
	v_mul_f32_e32 v53, v11, v15
	v_mul_f32_e32 v11, v53, v52
	// gfx1151 has no packed f32->bf16 conversion. Perform IEEE
	// round-to-nearest-even on the bit patterns and pack two results per VGPR.
	v_lshrrev_b32_e32 v52, 16, v8
	v_and_b32_e32 v52, 1, v52
	v_add_nc_u32_e32 v52, 0x7fff, v52
	v_add_nc_u32_e32 v8, v52, v8
	v_lshrrev_b32_e32 v8, 16, v8
	v_lshrrev_b32_e32 v52, 16, v9
	v_and_b32_e32 v52, 1, v52
	v_add_nc_u32_e32 v52, 0x7fff, v52
	v_add_nc_u32_e32 v9, v52, v9
	v_lshrrev_b32_e32 v9, 16, v9
	v_lshl_or_b32 v8, v9, 16, v8
	v_lshrrev_b32_e32 v52, 16, v10
	v_and_b32_e32 v52, 1, v52
	v_add_nc_u32_e32 v52, 0x7fff, v52
	v_add_nc_u32_e32 v10, v52, v10
	v_lshrrev_b32_e32 v10, 16, v10
	v_lshrrev_b32_e32 v52, 16, v11
	v_and_b32_e32 v52, 1, v52
	v_add_nc_u32_e32 v52, 0x7fff, v52
	v_add_nc_u32_e32 v11, v52, v11
	v_lshrrev_b32_e32 v11, 16, v11
	v_lshl_or_b32 v9, v11, 16, v10
	v_lshlrev_b32_e32 v2, 1, v1
	global_store_b64 v2, v[8:9], s[14:15]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel mxfp4_decode_gate_up_fused_gfx1151
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
		.amdhsa_next_free_vgpr 54
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
	.size mxfp4_decode_gate_up_fused_gfx1151, .Lfunc_end0-mxfp4_decode_gate_up_fused_gfx1151

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
    .name: mxfp4_decode_gate_up_fused_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 24
    .sgpr_spill_count: 0
    .symbol: mxfp4_decode_gate_up_fused_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 54
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
