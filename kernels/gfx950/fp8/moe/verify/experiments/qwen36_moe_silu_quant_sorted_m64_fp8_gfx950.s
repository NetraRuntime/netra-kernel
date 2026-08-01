// SPDX-License-Identifier: MIT
//
// Qwen3.6 M64-sorted MoE activation epilogue for gfx950:
//   sorted BF16 [valid,1024] gate/up -> route-major FP8 E4M3 [rows*9,512]
//   plus route-major FP32 [rows*9,4] 1x128 scales.
// Four wave64s process four sorted routes per 256-thread workgroup.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_silu_quant_sorted_m64_fp8_gfx950
	.globl qwen36_moe_silu_quant_sorted_m64_fp8_gfx950
	.p2align 8
	.type qwen36_moe_silu_quant_sorted_m64_fp8_gfx950,@function
qwen36_moe_silu_quant_sorted_m64_fp8_gfx950:
	// sorted W13 BF16, sorted IDs, route FP8, route scales, valid count, rows.
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dwordx2 s[10:11], s[0:1], 24
	s_load_dwordx2 s[16:17], s[0:1], 32
	s_load_dword s18, s[0:1], 40
	s_waitcnt lgkmcnt(0)

	// Vector-native wave index and sorted row. The dispatch is exact because
	// the M64 valid span is divisible by four.
	v_lshrrev_b32_e32 v36, 6, v0
	s_lshl_b32 s12, s2, 2
	v_add_u32_e32 v36, s12, v36
	v_lshlrev_b32_e32 v37, 2, v36
	global_load_dword v37, v37, s[6:7]
	s_waitcnt vmcnt(0)

	// Decode (slot << 24) | token. Mask padding waves without a host sync.
	v_lshrrev_b32_e32 v38, 24, v37
	v_and_b32_e32 v39, 0x00ffffff, v37
	v_cmp_gt_u32_e32 vcc, 9, v38
	s_and_saveexec_b64 s[32:33], vcc
	v_cmp_gt_u32_e32 vcc, s18, v39
	s_and_b64 exec, exec, vcc
	v_mul_lo_u32 v40, 9, v39
	v_add_u32_e32 v40, v38, v40

	// Input row stride 2048 BF16 bytes; route output strides 512 and 16.
	v_lshlrev_b32_e32 v41, 11, v36
	v_lshlrev_b32_e32 v42, 9, v40
	v_lshlrev_b32_e32 v43, 4, v40
	v_and_b32_e32 v1, 63, v0
	v_lshlrev_b32_e32 v2, 4, v1
	v_add_u32_e32 v2, v41, v2
	global_load_dwordx4 v[4:7], v2, s[4:5]
	global_load_dwordx4 v[8:11], v2, s[4:5] offset:1024
	s_waitcnt vmcnt(0)

	// Expand eight gate and eight up BF16 values to FP32.
	v_lshlrev_b32_e32 v12, 16, v4
	v_and_b32_e32 v13, 0xffff0000, v4
	v_lshlrev_b32_e32 v14, 16, v5
	v_and_b32_e32 v15, 0xffff0000, v5
	v_lshlrev_b32_e32 v16, 16, v6
	v_and_b32_e32 v17, 0xffff0000, v6
	v_lshlrev_b32_e32 v18, 16, v7
	v_and_b32_e32 v19, 0xffff0000, v7
	v_lshlrev_b32_e32 v20, 16, v8
	v_and_b32_e32 v21, 0xffff0000, v8
	v_lshlrev_b32_e32 v22, 16, v9
	v_and_b32_e32 v23, 0xffff0000, v9
	v_lshlrev_b32_e32 v24, 16, v10
	v_and_b32_e32 v25, 0xffff0000, v10
	v_lshlrev_b32_e32 v26, 16, v11
	v_and_b32_e32 v27, 0xffff0000, v11

	s_mov_b32 s25, 0x3f800000       // 1.0f
	s_mov_b32 s26, 0xbfb8aa3b       // -log2(e)
	s_mov_b32 s27, 0x3b124925       // 1.0f / 448.0f
	s_mov_b32 s28, 0x2edbe6ff       // 1.0e-10f
	s_mov_b32 s29, 0x05040100       // pack low FP8 pairs

	// SiLU(gate) * up.
	v_mul_f32_e32 v28, s26, v12
	v_mul_f32_e32 v29, s26, v13
	v_mul_f32_e32 v30, s26, v14
	v_mul_f32_e32 v31, s26, v15
	v_mul_f32_e32 v32, s26, v16
	v_mul_f32_e32 v33, s26, v17
	v_mul_f32_e32 v34, s26, v18
	v_mul_f32_e32 v35, s26, v19
	.irp tmp,28,29,30,31,32,33,34,35
	v_exp_f32_e32 v\tmp, v\tmp
	.endr
	.irp tmp,28,29,30,31,32,33,34,35
	v_add_f32_e32 v\tmp, s25, v\tmp
	.endr
	.irp tmp,28,29,30,31,32,33,34,35
	v_rcp_f32_e32 v\tmp, v\tmp
	.endr
	v_mul_f32_e32 v12, v28, v12
	v_mul_f32_e32 v13, v29, v13
	v_mul_f32_e32 v14, v30, v14
	v_mul_f32_e32 v15, v31, v15
	v_mul_f32_e32 v16, v32, v16
	v_mul_f32_e32 v17, v33, v17
	v_mul_f32_e32 v18, v34, v18
	v_mul_f32_e32 v19, v35, v19
	v_mul_f32_e32 v12, v20, v12
	v_mul_f32_e32 v13, v21, v13
	v_mul_f32_e32 v14, v22, v14
	v_mul_f32_e32 v15, v23, v15
	v_mul_f32_e32 v16, v24, v16
	v_mul_f32_e32 v17, v25, v17
	v_mul_f32_e32 v18, v26, v18
	v_mul_f32_e32 v19, v27, v19

	// Match the deployed BF16 activation boundary before scale selection.
	v_cvt_pk_bf16_f32 v4, v12, v13
	v_cvt_pk_bf16_f32 v5, v14, v15
	v_cvt_pk_bf16_f32 v6, v16, v17
	v_cvt_pk_bf16_f32 v7, v18, v19
	v_lshlrev_b32_e32 v12, 16, v4
	v_and_b32_e32 v13, 0xffff0000, v4
	v_lshlrev_b32_e32 v14, 16, v5
	v_and_b32_e32 v15, 0xffff0000, v5
	v_lshlrev_b32_e32 v16, 16, v6
	v_and_b32_e32 v17, 0xffff0000, v6
	v_lshlrev_b32_e32 v18, 16, v7
	v_and_b32_e32 v19, 0xffff0000, v7

	// Maximum over eight values, then over each 16-lane (128-value) group.
	v_max3_f32 v28, |v12|, |v13|, s28
	v_max3_f32 v28, v28, |v14|, |v15|
	v_max3_f32 v28, v28, |v16|, |v17|
	v_max3_f32 v28, v28, |v18|, |v19|
	s_nop 1
	v_mov_b32_dpp v29, v28 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 v28, v28, v29
	s_nop 1
	v_mov_b32_dpp v29, v28 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 v28, v28, v29
	s_nop 1
	v_mov_b32_dpp v29, v28 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 v28, v28, v29
	s_nop 1
	v_mov_b32_dpp v29, v28 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 v28, v28, v29
	s_nop 1
	v_mul_f32_e32 v28, s27, v28

	// High subgroup lane stores one FP32 scale.
	v_and_b32_e32 v30, 15, v1
	v_cmp_eq_u32_e32 vcc, 15, v30
	s_and_saveexec_b64 s[30:31], vcc
	v_lshrrev_b32_e32 v31, 4, v1
	v_lshlrev_b32_e32 v31, 2, v31
	v_add_u32_e32 v31, v43, v31
	global_store_dword v31, v28, s[10:11]
	s_or_b64 exec, exec, s[30:31]

	// Broadcast each subgroup's high-lane scale and refine its reciprocal.
	v_and_b32_e32 v30, 0x30, v1
	v_lshlrev_b32_e32 v30, 2, v30
	v_add_u32_e32 v30, 60, v30
	ds_bpermute_b32 v31, v30, v28
	s_waitcnt lgkmcnt(0)
	v_rcp_f32_e32 v32, v31
	s_nop 1
	v_fma_f32 v33, -v31, v32, 1.0
	s_nop 1
	v_fma_f32 v32, v33, v32, v32
	s_nop 1

	.irp value,12,13,14,15,16,17,18,19
	v_mul_f32_e32 v\value, v32, v\value
	.endr
	v_cvt_pk_fp8_f32 v20, v12, v13
	v_cvt_pk_fp8_f32 v21, v14, v15
	v_cvt_pk_fp8_f32 v22, v16, v17
	v_cvt_pk_fp8_f32 v23, v18, v19
	s_nop 1
	v_perm_b32 v20, v21, v20, s29
	v_perm_b32 v21, v23, v22, s29

	// Eight FP8 bytes to the original route-major ABI.
	v_lshlrev_b32_e32 v34, 3, v1
	v_add_u32_e32 v34, v42, v34
	global_store_dwordx2 v34, v[20:21], s[8:9]
	s_waitcnt vmcnt(0)
	s_or_b64 exec, exec, s[32:33]
.Lend:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_silu_quant_sorted_m64_fp8_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 48
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 44
		.amdhsa_accum_offset 44
		.amdhsa_next_free_sgpr 34
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_moe_silu_quant_sorted_m64_fp8_gfx950, .Lfunc_end0-qwen36_moe_silu_quant_sorted_m64_fp8_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: sorted_w13_bf16, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: sorted_token_ids_i32, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: route_activation_fp8, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: route_scale_f32, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: num_valid_ids_i32, .offset: 32, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: rows, .offset: 40, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 48
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_moe_silu_quant_sorted_m64_fp8_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 36
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_silu_quant_sorted_m64_fp8_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 44
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
