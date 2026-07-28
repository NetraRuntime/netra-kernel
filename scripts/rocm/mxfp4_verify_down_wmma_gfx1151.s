// SPDX-License-Identifier: MIT
//
// Raw gfx1151 WMMA MXFP4 speculative verification.
// Qwen3.6 expert down projection: E=8, M=12, N=2048, K=512.
// Launch grid=(128,8,1), block=(32,1,1), one 16x16 WMMA tile per wave.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
	.amdhsa_code_object_version 6
	.text

	.macro DECODE_LOCAL W
	v_and_b32_e32 v49, 0x07070707, \W
	v_lshrrev_b32_e32 v50, 4, \W
	v_and_b32_e32 v50, 0x07070707, v50
	v_lshlrev_b32_e32 v55, 4, \W
	v_and_b32_e32 v59, 0x80808080, \W
	v_perm_b32 v51, v5, v4, v49
	v_perm_b32 v53, v5, v4, v50
	v_perm_b32 v52, v7, v6, v49
	v_perm_b32 v54, v7, v6, v50
	v_and_b32_e32 v55, 0x80808080, v55
	v_or_b32_e32 v52, v55, v52
	v_or_b32_e32 v54, v59, v54
	v_perm_b32 v56, v52, v51, 0x05010400
	v_perm_b32 v57, v52, v51, 0x07030602
	v_perm_b32 v58, v54, v53, 0x05010400
	v_perm_b32 v59, v54, v53, 0x07030602
	v_perm_b32 v24, v58, v56, 0x05040100
	v_perm_b32 v25, v58, v56, 0x07060302
	v_perm_b32 v26, v59, v57, 0x05040100
	v_perm_b32 v27, v59, v57, 0x07060302
	.endm

	.macro LOAD_HALF AEXTRA BASE
	global_load_b128 v[16:19], v8, s[8:9] offset:\AEXTRA
	global_load_ubyte v48, \BASE, s[4:5]
	global_load_ubyte v49, \BASE, s[4:5] offset:2048
	v_add_nc_u32_e32 v13, 4096, \BASE
	global_load_ubyte v50, v13, s[4:5]
	global_load_ubyte v51, v13, s[4:5] offset:2048
	s_waitcnt vmcnt(0)
	ds_swizzle_b32 v20, v16 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v21, v17 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v22, v18 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v23, v19 offset:swizzle(SWAP,16)
	v_lshl_or_b32 v49, v49, 8, v48
	v_lshl_or_b32 v51, v51, 8, v50
	v_lshl_or_b32 v48, v51, 16, v49
	DECODE_LOCAL v48
	ds_swizzle_b32 v28, v24 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v29, v25 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v30, v26 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v31, v27 offset:swizzle(SWAP,16)
	.endm

	.protected mxfp4_verify_down_wmma_gfx1151
	.globl mxfp4_verify_down_wmma_gfx1151
	.p2align 8
	.type mxfp4_verify_down_wmma_gfx1151,@function
mxfp4_verify_down_wmma_gfx1151:
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0
	s_load_b128 s[8:11], s[0:1], 16
	s_waitcnt lgkmcnt(0)

	// Per-expert packed and scale byte counts match gate/up.
	s_lshl_b32 s12, s3, 19
	s_lshl_b32 s13, s3, 15
	s_mul_i32 s14, s3, 98304
	s_waitcnt_depctr 0
	s_add_u32 s4, s4, s12
	s_addc_u32 s5, s5, 0
	s_add_u32 s6, s6, s13
	s_addc_u32 s7, s7, 0
	s_add_u32 s10, s10, s14
	s_addc_u32 s11, s11, 0

	v_and_b32_e32 v1, 15, v0
	v_lshrrev_b32_e32 v2, 4, v0
	s_lshl_b32 s15, s2, 4
	s_waitcnt_depctr 0
	v_add_nc_u32_e32 v3, s15, v1

	// A: row*(512*2) + subgroup*8*2.
	v_lshlrev_b32_e32 v8, 10, v1
	v_lshl_add_u32 v8, v2, 4, v8

	// Packed B: column + subgroup*4 packed rows*2048.
	v_lshl_add_u32 v9, v2, 13, v3
	v_mov_b32_e32 v10, v3

	v_mov_b32_e32 v4, 0xc0800000
	v_mov_b32_e32 v5, 0xc0804000
	v_mov_b32_e32 v6, 0x3f3f3f00
	v_mov_b32_e32 v7, 0x40404040

	v_dual_mov_b32 v32, 0 :: v_dual_mov_b32 v33, 0
	v_dual_mov_b32 v34, 0 :: v_dual_mov_b32 v35, 0
	v_dual_mov_b32 v36, 0 :: v_dual_mov_b32 v37, 0
	v_dual_mov_b32 v38, 0 :: v_dual_mov_b32 v39, 0
	s_mov_b32 s16, 16

.Lmxblock:
	v_dual_mov_b32 v40, 0 :: v_dual_mov_b32 v41, 0
	v_dual_mov_b32 v42, 0 :: v_dual_mov_b32 v43, 0
	v_dual_mov_b32 v44, 0 :: v_dual_mov_b32 v45, 0
	v_dual_mov_b32 v46, 0 :: v_dual_mov_b32 v47, 0
	global_load_ubyte v63, v10, s[6:7]

	LOAD_HALF 0 v9
	s_waitcnt lgkmcnt(0)
	v_wmma_f32_16x16x16_bf16 v[40:47], v[16:23], v[24:31], v[40:47]

	v_add_nc_u32_e32 v12, 16384, v9
	LOAD_HALF 32 v12
	s_waitcnt lgkmcnt(0)
	v_wmma_f32_16x16x16_bf16 v[40:47], v[16:23], v[24:31], v[40:47]

	s_waitcnt vmcnt(0)
	v_lshlrev_b32_e32 v64, 23, v63
	v_fmac_f32_e32 v32, v40, v64
	v_fmac_f32_e32 v33, v41, v64
	v_fmac_f32_e32 v34, v42, v64
	v_fmac_f32_e32 v35, v43, v64
	v_fmac_f32_e32 v36, v44, v64
	v_fmac_f32_e32 v37, v45, v64
	v_fmac_f32_e32 v38, v46, v64
	v_fmac_f32_e32 v39, v47, v64

	s_add_u32 s4, s4, 32768
	s_addc_u32 s5, s5, 0
	s_add_u32 s6, s6, 2048
	s_addc_u32 s7, s7, 0
	s_add_u32 s8, s8, 64
	s_addc_u32 s9, s9, 0
	s_sub_u32 s16, s16, 1
	s_waitcnt_depctr 0
	s_cmp_lg_u32 s16, 0
	s_cbranch_scc1 .Lmxblock

	ds_swizzle_b32 v16, v36 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v20, v32 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v17, v37 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v21, v33 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v18, v38 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v22, v34 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v19, v39 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v23, v35 offset:swizzle(ROTATE,1,16)
	s_waitcnt lgkmcnt(0)
	v_mov_b32_dpp v16, v32 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp v36, v20 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp v17, v33 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp v37, v21 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp v18, v34 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp v38, v22 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp v19, v35 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp v39, v23 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf

	// [expert,12,2048] output; subgroup 1 suppresses padded rows 12..15.
	v_lshlrev_b32_e32 v11, 2, v3
	v_lshl_add_u32 v11, v2, 16, v11
	global_store_b32 v11, v16, s[10:11]
	v_add_nc_u32_e32 v11, 8192, v11
	global_store_b32 v11, v36, s[10:11]
	v_add_nc_u32_e32 v11, 8192, v11
	global_store_b32 v11, v17, s[10:11]
	v_add_nc_u32_e32 v11, 8192, v11
	global_store_b32 v11, v37, s[10:11]
	v_add_nc_u32_e32 v11, 8192, v11
	s_mov_b32 s20, exec_lo
	v_cmpx_eq_u32_e32 0, v2
	global_store_b32 v11, v18, s[10:11]
	v_add_nc_u32_e32 v11, 8192, v11
	global_store_b32 v11, v38, s[10:11]
	v_add_nc_u32_e32 v11, 8192, v11
	global_store_b32 v11, v19, s[10:11]
	v_add_nc_u32_e32 v11, 8192, v11
	global_store_b32 v11, v39, s[10:11]
	s_mov_b32 exec_lo, s20
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel mxfp4_verify_down_wmma_gfx1151
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 32
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_wavefront_size32 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 65
		.amdhsa_next_free_sgpr 21
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
	.size mxfp4_verify_down_wmma_gfx1151, .Lfunc_end0-mxfp4_verify_down_wmma_gfx1151

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: packed, .offset: 0, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: scales, .offset: 8, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: activation_padded_m16, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: output_m12, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 32
    .name: mxfp4_verify_down_wmma_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 23
    .sgpr_spill_count: 0
    .symbol: mxfp4_verify_down_wmma_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 65
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
