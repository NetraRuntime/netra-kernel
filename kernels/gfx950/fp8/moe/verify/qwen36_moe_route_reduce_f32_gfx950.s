// SPDX-License-Identifier: MIT
//
// Deterministic Qwen3.6 verification MoE route reduction for gfx950.
//
// The grouped down-projection kernel writes one unweighted FP32 partial for
// every [token, top-k slot, hidden column].  This kernel applies the nine
// router weights and accumulates in the original top-k slot order before the
// sole BF16 conversion and output store.  Keeping the reduction separate
// removes the unordered packed-BF16 global atomics used by the deployed AITER
// one-stage kernel while preserving expert-grouped weight reuse upstream.
//
// Grid:  (32, rows, 1), workgroup: (64, 1, 1)
// Shape: partials [rows, 9, 2048] FP32, weights [rows, 9] FP32,
//        output [rows, 2048] BF16.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_route_reduce_f32_gfx950
	.globl qwen36_moe_route_reduce_f32_gfx950
	.p2align 8
	.type qwen36_moe_route_reduce_f32_gfx950,@function
qwen36_moe_route_reduce_f32_gfx950:
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

	// All lanes in a wave use the same token's weights.
	s_load_dword s10, s[6:7], 0
	s_load_dword s11, s[6:7], 4
	s_load_dword s12, s[6:7], 8
	s_load_dword s13, s[6:7], 12
	s_load_dword s14, s[6:7], 16
	s_load_dword s15, s[6:7], 20
	s_load_dword s16, s[6:7], 24
	s_load_dword s17, s[6:7], 28
	s_load_dword s18, s[6:7], 32

	// column = workgroup_id_x*64 + lane_id.
	s_lshl_b32 s20, s2, 6
	v_add_u32_e32 v1, s20, v0
	v_lshlrev_b32_e32 v2, 2, v1

	// A route plane is 2048 FP32 values = 8192 bytes.  Issue all route
	// reads together, then perform the arithmetic in fixed slot order.
	global_load_dword v3, v2, s[4:5]
	v_add_u32_e32 v12, 8192, v2
	global_load_dword v4, v12, s[4:5]
	v_add_u32_e32 v12, 8192, v12
	global_load_dword v5, v12, s[4:5]
	v_add_u32_e32 v12, 8192, v12
	global_load_dword v6, v12, s[4:5]
	v_add_u32_e32 v12, 8192, v12
	global_load_dword v7, v12, s[4:5]
	v_add_u32_e32 v12, 8192, v12
	global_load_dword v8, v12, s[4:5]
	v_add_u32_e32 v12, 8192, v12
	global_load_dword v9, v12, s[4:5]
	v_add_u32_e32 v12, 8192, v12
	global_load_dword v10, v12, s[4:5]
	v_add_u32_e32 v12, 8192, v12
	global_load_dword v11, v12, s[4:5]
	s_waitcnt vmcnt(0) & lgkmcnt(0)

	v_mul_f32_e32 v3, s10, v3
	v_mul_f32_e32 v4, s11, v4
	v_add_f32_e32 v3, v3, v4
	v_mul_f32_e32 v5, s12, v5
	v_add_f32_e32 v3, v3, v5
	v_mul_f32_e32 v6, s13, v6
	v_add_f32_e32 v3, v3, v6
	v_mul_f32_e32 v7, s14, v7
	v_add_f32_e32 v3, v3, v7
	v_mul_f32_e32 v8, s15, v8
	v_add_f32_e32 v3, v3, v8
	v_mul_f32_e32 v9, s16, v9
	v_add_f32_e32 v3, v3, v9
	v_mul_f32_e32 v10, s17, v10
	v_add_f32_e32 v3, v3, v10
	v_mul_f32_e32 v11, s18, v11
	v_add_f32_e32 v3, v3, v11

	v_cvt_pk_bf16_f32 v4, v3, v3
	v_lshlrev_b32_e32 v5, 1, v1
	global_store_short v5, v4, s[8:9]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_route_reduce_f32_gfx950
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
		.amdhsa_next_free_vgpr 13
		.amdhsa_accum_offset 16
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
	.size qwen36_moe_route_reduce_f32_gfx950, .Lfunc_end0-qwen36_moe_route_reduce_f32_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - .address_space: global
        .offset: 0
        .size: 8
        .value_kind: global_buffer
      - .address_space: global
        .offset: 8
        .size: 8
        .value_kind: global_buffer
      - .address_space: global
        .offset: 16
        .size: 8
        .value_kind: global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .max_flat_workgroup_size: 64
    .name: qwen36_moe_route_reduce_f32_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 22
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_route_reduce_f32_gfx950.kd
    .vgpr_count: 16
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
