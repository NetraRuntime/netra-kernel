// SPDX-License-Identifier: MIT
// Model-independent fixed-order reducer for two FP16 routed-expert halves.

	.include "kernels/gfx950/templates/common/primitives.inc"

	.macro NETRA_MOE_REDUCE_PAIR_F16X2 half0, half1, weight, first=0
	// Unpack both adjacent FP16 columns from each split-K half.
	v_lshrrev_b32_e32 v21, 16, \half0
	v_cvt_f32_f16_e32 v21, v21
	v_cvt_f32_f16_e32 \half0, \half0
	v_lshrrev_b32_e32 v22, 16, \half1
	v_cvt_f32_f16_e32 v22, v22
	v_cvt_f32_f16_e32 \half1, \half1
	// Sum K halves before applying the route weight, then retain fixed slot order.
	v_add_f32_e32 \half0, \half0, \half1
	v_add_f32_e32 v21, v21, v22
	.if \first
	v_mul_f32_e32 v23, \weight, \half0
	v_mul_f32_e32 v24, \weight, v21
	.else
	v_mul_f32_e32 \half0, \weight, \half0
	v_mul_f32_e32 v21, \weight, v21
	v_add_f32_e32 v23, v23, \half0
	v_add_f32_e32 v24, v24, v21
	.endif
	.endm

	NETRA_GFX950_MODULE_HEADER 6

	.macro NETRA_MOE_PREFILL_ROUTE_REDUCE_SPLITK2_F16 symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_ROWS, 768
	NETRA_REQUIRE_EQ NETRA_HIDDEN_SIZE, 2048
	NETRA_REQUIRE_EQ NETRA_TOPK, 9
	NETRA_REQUIRE_EQ NETRA_SPLIT_K, 2
	NETRA_KERNEL_ENTRY \symbol, 1
	// Kernargs: partial0_f16, topk_weights_f32, output_bf16, partial1_f16.
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dwordx2 s[22:23], s[0:1], 24
	s_waitcnt lgkmcnt(0)

	// Token strides: partials 9*2048*2 = 36864 bytes, weights 36 bytes,
	// output 2048*2 = 4096 bytes.
	s_lshl_b32 s20, s3, 15
	s_lshl_b32 s21, s3, 12
	s_add_u32 s20, s20, s21
	s_add_u32 s4, s4, s20
	s_addc_u32 s5, s5, 0
	s_add_u32 s22, s22, s20
	s_addc_u32 s23, s23, 0
	s_lshl_b32 s20, s3, 5
	s_lshl_b32 s21, s3, 2
	s_add_u32 s20, s20, s21
	s_add_u32 s6, s6, s20
	s_addc_u32 s7, s7, 0
	s_lshl_b32 s20, s3, 12
	s_add_u32 s8, s8, s20
	s_addc_u32 s9, s9, 0

	// The wave shares the nine route weights.
	s_load_dword s10, s[6:7], 0
	s_load_dword s11, s[6:7], 4
	s_load_dword s12, s[6:7], 8
	s_load_dword s13, s[6:7], 12
	s_load_dword s14, s[6:7], 16
	s_load_dword s15, s[6:7], 20
	s_load_dword s16, s[6:7], 24
	s_load_dword s17, s[6:7], 28
	s_load_dword s18, s[6:7], 32

	// Byte address for columns (workgroup_x*128 + lane*2).
	s_lshl_b32 s20, s2, 8
	v_lshlrev_b32_e32 v2, 2, v0
	v_add_u32_e32 v2, s20, v2

	// Issue both FP16 columns for all nine routes and both split-K halves.
	global_load_dword v3, v2, s[4:5]
	global_load_dword v12, v2, s[22:23]
	v_add_u32_e32 v1, 4096, v2
	global_load_dword v4, v1, s[4:5]
	global_load_dword v13, v1, s[22:23]
	v_add_u32_e32 v1, 4096, v1
	global_load_dword v5, v1, s[4:5]
	global_load_dword v14, v1, s[22:23]
	v_add_u32_e32 v1, 4096, v1
	global_load_dword v6, v1, s[4:5]
	global_load_dword v15, v1, s[22:23]
	v_add_u32_e32 v1, 4096, v1
	global_load_dword v7, v1, s[4:5]
	global_load_dword v16, v1, s[22:23]
	v_add_u32_e32 v1, 4096, v1
	global_load_dword v8, v1, s[4:5]
	global_load_dword v17, v1, s[22:23]
	v_add_u32_e32 v1, 4096, v1
	global_load_dword v9, v1, s[4:5]
	global_load_dword v18, v1, s[22:23]
	v_add_u32_e32 v1, 4096, v1
	global_load_dword v10, v1, s[4:5]
	global_load_dword v19, v1, s[22:23]
	v_add_u32_e32 v1, 4096, v1
	global_load_dword v11, v1, s[4:5]
	global_load_dword v20, v1, s[22:23]
	s_waitcnt vmcnt(0) lgkmcnt(0)

	NETRA_MOE_REDUCE_PAIR_F16X2 v3, v12, s10, 1
	NETRA_MOE_REDUCE_PAIR_F16X2 v4, v13, s11
	NETRA_MOE_REDUCE_PAIR_F16X2 v5, v14, s12
	NETRA_MOE_REDUCE_PAIR_F16X2 v6, v15, s13
	NETRA_MOE_REDUCE_PAIR_F16X2 v7, v16, s14
	NETRA_MOE_REDUCE_PAIR_F16X2 v8, v17, s15
	NETRA_MOE_REDUCE_PAIR_F16X2 v9, v18, s16
	NETRA_MOE_REDUCE_PAIR_F16X2 v10, v19, s17
	NETRA_MOE_REDUCE_PAIR_F16X2 v11, v20, s18

	v_cvt_pk_bf16_f32 v23, v23, v24
	global_store_dword v2, v23, s[8:9]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel \symbol
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 32
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 25
		.amdhsa_accum_offset 28
		.amdhsa_next_free_sgpr 24
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size \symbol, .Lfunc_end0-\symbol

	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - { .address_space: global, .offset: 0, .size: 8, .value_kind: global_buffer }
      - { .address_space: global, .offset: 8, .size: 8, .value_kind: global_buffer }
      - { .address_space: global, .offset: 16, .size: 8, .value_kind: global_buffer }
      - { .address_space: global, .offset: 24, .size: 8, .value_kind: global_buffer }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .max_flat_workgroup_size: 64
    .name: \symbol
    .private_segment_fixed_size: 0
    .sgpr_count: 26
    .sgpr_spill_count: 0
    .symbol: \symbol\().kd
    .vgpr_count: 28
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
	.endm
