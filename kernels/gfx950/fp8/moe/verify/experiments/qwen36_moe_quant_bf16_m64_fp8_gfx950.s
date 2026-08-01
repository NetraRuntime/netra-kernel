// SPDX-License-Identifier: MIT
// Qwen3.6 route-major BF16 [routes,512] to FP8 E4M3 plus 1x128 scales.
// Four wave64s process four routes per 256-thread workgroup.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_quant_bf16_m64_fp8_gfx950
	.globl qwen36_moe_quant_bf16_m64_fp8_gfx950
	.p2align 8
	.type qwen36_moe_quant_bf16_m64_fp8_gfx950,@function
qwen36_moe_quant_bf16_m64_fp8_gfx950:
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dword s10, s[0:1], 24
	s_waitcnt lgkmcnt(0)

	// Vector-native route index; dispatch is ceil(routes/4).
	v_lshrrev_b32_e32 v32, 6, v0
	s_lshl_b32 s11, s2, 2
	v_add_u32_e32 v32, s11, v32
	v_cmp_gt_u32_e32 vcc, s10, v32
	s_and_saveexec_b64 s[18:19], vcc
	v_and_b32_e32 v1, 63, v0
	v_lshlrev_b32_e32 v2, 10, v32
	v_lshlrev_b32_e32 v3, 4, v1
	v_add_u32_e32 v2, v3, v2
	global_load_dwordx4 v[4:7], v2, s[4:5]
	s_waitcnt vmcnt(0)

	// Expand eight BF16 values.
	v_lshlrev_b32_e32 v8, 16, v4
	v_and_b32_e32 v9, 0xffff0000, v4
	v_lshlrev_b32_e32 v10, 16, v5
	v_and_b32_e32 v11, 0xffff0000, v5
	v_lshlrev_b32_e32 v12, 16, v6
	v_and_b32_e32 v13, 0xffff0000, v6
	v_lshlrev_b32_e32 v14, 16, v7
	v_and_b32_e32 v15, 0xffff0000, v7
	s_mov_b32 s12, 0x3b124925
	s_mov_b32 s13, 0x2edbe6ff
	s_mov_b32 s14, 0x05040100

	v_max3_f32 v16, |v8|, |v9|, s13
	v_max3_f32 v16, v16, |v10|, |v11|
	v_max3_f32 v16, v16, |v12|, |v13|
	v_max3_f32 v16, v16, |v14|, |v15|
	s_nop 1
	v_mov_b32_dpp v17, v16 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 v16, v16, v17
	s_nop 1
	v_mov_b32_dpp v17, v16 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 v16, v16, v17
	s_nop 1
	v_mov_b32_dpp v17, v16 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 v16, v16, v17
	s_nop 1
	v_mov_b32_dpp v17, v16 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 v16, v16, v17
	s_nop 1
	v_mul_f32_e32 v16, s12, v16

	// One scale from the high lane in each 16-lane subgroup.
	v_and_b32_e32 v18, 15, v1
	v_cmp_eq_u32_e32 vcc, 15, v18
	s_and_saveexec_b64 s[16:17], vcc
	v_lshrrev_b32_e32 v19, 4, v1
	v_lshlrev_b32_e32 v20, 4, v32
	v_lshlrev_b32_e32 v19, 2, v19
	v_add_u32_e32 v19, v20, v19
	global_store_dword v19, v16, s[8:9]
	s_or_b64 exec, exec, s[16:17]

	// Broadcast and refine reciprocal.
	v_and_b32_e32 v18, 0x30, v1
	v_lshlrev_b32_e32 v18, 2, v18
	v_add_u32_e32 v18, 60, v18
	ds_bpermute_b32 v19, v18, v16
	s_waitcnt lgkmcnt(0)
	v_rcp_f32_e32 v20, v19
	s_nop 1
	v_fma_f32 v21, -v19, v20, 1.0
	s_nop 1
	v_fma_f32 v20, v21, v20, v20
	s_nop 1
	.irp value,8,9,10,11,12,13,14,15
	v_mul_f32_e32 v\value, v20, v\value
	.endr
	v_cvt_pk_fp8_f32 v22, v8, v9
	v_cvt_pk_fp8_f32 v23, v10, v11
	v_cvt_pk_fp8_f32 v24, v12, v13
	v_cvt_pk_fp8_f32 v25, v14, v15
	s_nop 1
	v_perm_b32 v22, v23, v22, s14
	v_perm_b32 v23, v25, v24, s14
	v_lshlrev_b32_e32 v26, 9, v32
	v_lshlrev_b32_e32 v27, 3, v1
	v_add_u32_e32 v26, v27, v26
	global_store_dwordx2 v26, v[22:23], s[6:7]
	s_waitcnt vmcnt(0)
	s_or_b64 exec, exec, s[18:19]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_quant_bf16_m64_fp8_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 32
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 33
		.amdhsa_accum_offset 36
		.amdhsa_next_free_sgpr 20
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_moe_quant_bf16_m64_fp8_gfx950, .Lfunc_end0-qwen36_moe_quant_bf16_m64_fp8_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: activation_bf16, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: activation_fp8, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: activation_scale_f32, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: routes, .offset: 24, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_moe_quant_bf16_m64_fp8_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 22
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_quant_bf16_m64_fp8_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 33
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
