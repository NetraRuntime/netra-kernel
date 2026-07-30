// SPDX-License-Identifier: MIT
//
// Raw gfx1151 exact-order reduction for fixed N=12800, K=2048 decode.
// partials=[64,N] FP32 and scales=[64,N] E8M0 are reduced in the same
// 64-FMA order as the original kernel, then stored as output=[N] BF16.
// Launch: grid=(50,1,1), block=(256,1,1).

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
	v_add_nc_u32_e32 v2, s12, v2
	.endm

	.macro FP32_TO_BF16 V TMP
	v_lshrrev_b32_e32 \TMP, 16, \V
	v_and_b32_e32 \TMP, 1, \TMP
	v_add_nc_u32_e32 \TMP, 0x7fff, \TMP
	v_add_nc_u32_e32 \V, \TMP, \V
	v_lshrrev_b32_e32 \V, 16, \V
	.endm

	.protected mxfp4_linear_decode_n12800_block64_reduce_gfx1151
	.globl mxfp4_linear_decode_n12800_block64_reduce_gfx1151
	.p2align 8
	.type mxfp4_linear_decode_n12800_block64_reduce_gfx1151,@function
mxfp4_linear_decode_n12800_block64_reduce_gfx1151:
	s_clause 0x1
	s_load_b128 s[4:7], s[0:1], 0
	s_load_b64 s[8:9], s[0:1], 16
	s_waitcnt lgkmcnt(0)

	// One work-item reproduces the original 64-block FP32 FMA order.
	s_lshl_b32 s14, s2, 8
	v_add_nc_u32_e32 v1, s14, v0
	v_lshlrev_b32_e32 v7, 2, v1
	v_mov_b32_e32 v2, 0
	s_mov_b32 s16, 64
.Lreduce_block:
	global_load_b32 v3, v7, s[4:5]
	global_load_ubyte v4, v1, s[6:7]
	s_waitcnt vmcnt(0)
	v_lshlrev_b32_e32 v4, 23, v4
	v_fmac_f32_e32 v2, v3, v4
	s_add_u32 s4, s4, 51200
	s_addc_u32 s5, s5, 0
	s_add_u32 s6, s6, 12800
	s_addc_u32 s7, s7, 0
	s_sub_u32 s16, s16, 1
	s_waitcnt_depctr 0
	s_cmp_lg_u32 s16, 0
	s_cbranch_scc1 .Lreduce_block

	// Round-to-nearest-even FP32 to BF16.
	v_lshrrev_b32_e32 v6, 16, v2
	v_and_b32_e32 v6, 1, v6
	v_add_nc_u32_e32 v6, 0x7fff, v6
	v_add_nc_u32_e32 v2, v6, v2
	v_lshrrev_b32_e32 v2, 16, v2
	v_lshlrev_b32_e32 v1, 1, v1
	global_store_short v1, v2, s[8:9]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel mxfp4_linear_decode_n12800_block64_reduce_gfx1151
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 40
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
	.size mxfp4_linear_decode_n12800_block64_reduce_gfx1151, .Lfunc_end0-mxfp4_linear_decode_n12800_block64_reduce_gfx1151

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
      - { .offset: 32, .size: 4, .value_kind: by_value }
      - { .offset: 36, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 40
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: mxfp4_linear_decode_n12800_block64_reduce_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 24
    .sgpr_spill_count: 0
    .symbol: mxfp4_linear_decode_n12800_block64_reduce_gfx1151.kd
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
