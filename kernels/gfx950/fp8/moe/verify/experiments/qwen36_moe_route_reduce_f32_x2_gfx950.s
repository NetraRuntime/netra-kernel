// SPDX-License-Identifier: MIT
//
// Vectorized deterministic Qwen3.6 verification MoE route reduction for
// gfx950. Each lane reduces two adjacent hidden columns in the original
// top-k slot order. Compared with the scalar reducer this halves the number
// of waves and uses coalesced dwordx2 reads plus packed-BF16 dword stores.
//
// Grid:  (16, rows, 1), workgroup: (64, 1, 1)
// Shape: partials [rows, 9, 2048] FP32, weights [rows, 9] FP32,
//        output [rows, 2048] BF16.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_route_reduce_f32_x2_gfx950
	.globl qwen36_moe_route_reduce_f32_x2_gfx950
	.p2align 8
	.type qwen36_moe_route_reduce_f32_x2_gfx950,@function
qwen36_moe_route_reduce_f32_x2_gfx950:
	// Kernargs: partial_f32, topk_weights_f32, output_bf16.
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_waitcnt lgkmcnt(0)

	// Token strides: partials 9*2048*4 = 73728 bytes, weights 36 bytes,
	// output 2048*2 = 4096 bytes.
	s_lshl_b32 s20, s3, 16
	s_lshl_b32 s21, s3, 13
	s_add_u32 s20, s20, s21
	s_add_u32 s4, s4, s20
	s_addc_u32 s5, s5, 0
	s_lshl_b32 s20, s3, 5
	s_lshl_b32 s21, s3, 2
	s_add_u32 s20, s20, s21
	s_add_u32 s6, s6, s20
	s_addc_u32 s7, s7, 0
	s_lshl_b32 s20, s3, 12
	s_add_u32 s8, s8, s20
	s_addc_u32 s9, s9, 0

	// All lanes use the same token's weights.
	s_load_dword s10, s[6:7], 0
	s_load_dword s11, s[6:7], 4
	s_load_dword s12, s[6:7], 8
	s_load_dword s13, s[6:7], 12
	s_load_dword s14, s[6:7], 16
	s_load_dword s15, s[6:7], 20
	s_load_dword s16, s[6:7], 24
	s_load_dword s17, s[6:7], 28
	s_load_dword s18, s[6:7], 32

	// first_column = workgroup_id_x*128 + lane_id*2.
	s_lshl_b32 s20, s2, 7
	v_lshlrev_b32_e32 v1, 1, v0
	v_add_u32_e32 v1, s20, v1
	v_lshlrev_b32_e32 v2, 2, v1

	// Each route plane is 8192 bytes. Issue nine adjacent-column pairs,
	// then perform two independent reductions in fixed slot order.
	global_load_dwordx2 v[4:5], v2, s[4:5]
	v_add_u32_e32 v22, 8192, v2
	global_load_dwordx2 v[6:7], v22, s[4:5]
	v_add_u32_e32 v22, 8192, v22
	global_load_dwordx2 v[8:9], v22, s[4:5]
	v_add_u32_e32 v22, 8192, v22
	global_load_dwordx2 v[10:11], v22, s[4:5]
	v_add_u32_e32 v22, 8192, v22
	global_load_dwordx2 v[12:13], v22, s[4:5]
	v_add_u32_e32 v22, 8192, v22
	global_load_dwordx2 v[14:15], v22, s[4:5]
	v_add_u32_e32 v22, 8192, v22
	global_load_dwordx2 v[16:17], v22, s[4:5]
	v_add_u32_e32 v22, 8192, v22
	global_load_dwordx2 v[18:19], v22, s[4:5]
	v_add_u32_e32 v22, 8192, v22
	global_load_dwordx2 v[20:21], v22, s[4:5]
	s_waitcnt vmcnt(0) & lgkmcnt(0)

	.macro REDUCE_PAIR dst0,dst1,src0,src1,weight
	v_mul_f32_e32 v\src0, s\weight, v\src0
	v_mul_f32_e32 v\src1, s\weight, v\src1
	v_add_f32_e32 v\dst0, v\dst0, v\src0
	v_add_f32_e32 v\dst1, v\dst1, v\src1
	.endm
	v_mul_f32_e32 v4, s10, v4
	v_mul_f32_e32 v5, s10, v5
	REDUCE_PAIR 4,5,6,7,11
	REDUCE_PAIR 4,5,8,9,12
	REDUCE_PAIR 4,5,10,11,13
	REDUCE_PAIR 4,5,12,13,14
	REDUCE_PAIR 4,5,14,15,15
	REDUCE_PAIR 4,5,16,17,16
	REDUCE_PAIR 4,5,18,19,17
	REDUCE_PAIR 4,5,20,21,18

	v_cvt_pk_bf16_f32 v5, v4, v5
	v_lshlrev_b32_e32 v6, 1, v1
	global_store_dword v6, v5, s[8:9]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_route_reduce_f32_x2_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 24
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 23
		.amdhsa_accum_offset 24
		.amdhsa_next_free_sgpr 22
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_moe_route_reduce_f32_x2_gfx950, .Lfunc_end0-qwen36_moe_route_reduce_f32_x2_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count: 0
    .args:
      - { .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global }
      - { .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global }
      - { .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .max_flat_workgroup_size: 64
    .name: qwen36_moe_route_reduce_f32_x2_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 22
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_route_reduce_f32_x2_gfx950.kd
    .vgpr_count: 24
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
