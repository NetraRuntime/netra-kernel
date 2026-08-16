// SPDX-License-Identifier: MIT
//
// Experimental gfx950 Qwen3.6 decode-MoE quantization epilogue:
//   compact BF16 [rows,512]
//     -> FP8 E4M3 [rows,512] plus FP32 [rows,4] scales.
//
// One wave64 workgroup handles one routed row. Each 16-lane subgroup owns one
// 128-element quantization group and each lane owns eight contiguous values.
// This is raw AMDGCN compute; the HIP harness only loads, dispatches, checks,
// and times the code object.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_quant_bf16_fp8_m1_gfx950
	.globl qwen36_moe_quant_bf16_fp8_m1_gfx950
	.p2align 8
	.type qwen36_moe_quant_bf16_fp8_m1_gfx950,@function
qwen36_moe_quant_bf16_fp8_m1_gfx950:
	// Kernargs: input_bf16, output_fp8, output_scale_f32, rows.
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dword s10, s[0:1], 24
	s_waitcnt lgkmcnt(0)
	s_cmp_ge_u32 s2, s10
	s_cbranch_scc1 .Lend

	// Row byte offsets: input=512*bf16, output=512*fp8, scales=4*f32.
	s_lshl_b32 s11, s2, 10
	s_lshl_b32 s12, s2, 9
	s_lshl_b32 s13, s2, 4
	s_mov_b32 s16, 0x3b124925	// 1.0f / 448.0f
	s_mov_b32 s17, 0x2edbe6ff	// 1.0e-10f
	s_mov_b32 s24, 0x05040100	// pack low FP8 pairs as [lo, hi]

	// lane*8 elements = lane*16 compact BF16 input bytes.
	v_lshlrev_b32_e32 v1, 4, v0
	v_add_u32_e32 v2, s11, v1
	global_load_dwordx4 v[4:7], v2, s[4:5]
	s_waitcnt vmcnt(0)

	// Expand eight packed BF16 values to their exact FP32 representations.
	v_lshlrev_b32_e32 v12, 16, v4
	v_and_b32_e32 v13, 0xffff0000, v4
	v_lshlrev_b32_e32 v14, 16, v5
	v_and_b32_e32 v15, 0xffff0000, v5
	v_lshlrev_b32_e32 v16, 16, v6
	v_and_b32_e32 v17, 0xffff0000, v6
	v_lshlrev_b32_e32 v18, 16, v7
	v_and_b32_e32 v19, 0xffff0000, v7
	v_mov_b32_e32 v4, v12
	v_mov_b32_e32 v5, v13
	v_mov_b32_e32 v6, v14
	v_mov_b32_e32 v7, v15
	v_mov_b32_e32 v8, v16
	v_mov_b32_e32 v9, v17
	v_mov_b32_e32 v10, v18
	v_mov_b32_e32 v11, v19

	// Per-lane maximum followed by a 16-lane row reduction. DPP row_shr
	// accumulates toward the high lane, so lanes 15/31/47/63 hold their
	// 128-value group maximum after the four steps.
	v_max3_f32 v28, |v4|, |v5|, s17
	v_max3_f32 v28, v28, |v6|, |v7|
	v_max3_f32 v28, v28, |v8|, |v9|
	v_max3_f32 v28, v28, |v10|, |v11|
	// DPP source reads need the same explicit VALU spacing emitted by the
	// deployed gfx950 quantizer.
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
	v_mul_f32_e32 v28, s16, v28

	// Store one scale per 16-lane subgroup from its high lane.
	v_and_b32_e32 v30, 15, v0
	v_cmp_eq_u32_e32 vcc, 15, v30
	s_and_saveexec_b64 s[18:19], vcc
	v_lshrrev_b32_e32 v31, 4, v0
	v_lshlrev_b32_e32 v31, 2, v31
	v_add_u32_e32 v31, s13, v31
	global_store_dword v31, v28, s[8:9]
	s_or_b64 exec, exec, s[18:19]

	// Broadcast the high-lane scale within each 16-lane subgroup.
	v_and_b32_e32 v30, 0x30, v0
	v_lshlrev_b32_e32 v30, 2, v30
	v_add_u32_e32 v30, 60, v30
	ds_bpermute_b32 v31, v30, v28
	s_waitcnt lgkmcnt(0)

	// Refine the native reciprocal once with explicit gfx950 dependency
	// spacing. Byte equality against the deployed division path is enforced
	// by the harness.
	v_rcp_f32_e32 v32, v31
	s_nop 1
	v_fma_f32 v33, -v31, v32, 1.0
	s_nop 1
	v_fma_f32 v34, v33, v32, v32
	s_nop 1
	v_mov_b32_e32 v32, v34
	s_nop 0
	v_mul_f32_e32 v4, v32, v4
	v_mul_f32_e32 v5, v32, v5
	v_mul_f32_e32 v6, v32, v6
	v_mul_f32_e32 v7, v32, v7
	v_mul_f32_e32 v8, v32, v8
	v_mul_f32_e32 v9, v32, v9
	v_mul_f32_e32 v10, v32, v10
	v_mul_f32_e32 v11, v32, v11
	v_cvt_pk_fp8_f32 v20, v4, v5
	v_cvt_pk_fp8_f32 v21, v6, v7
	v_cvt_pk_fp8_f32 v22, v8, v9
	v_cvt_pk_fp8_f32 v23, v10, v11
	s_nop 1
	v_perm_b32 v20, v21, v20, s24
	v_perm_b32 v21, v23, v22, s24

	v_lshlrev_b32_e32 v34, 3, v0
	v_add_u32_e32 v34, s12, v34
	global_store_dwordx2 v34, v[20:21], s[6:7]
.Lend:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_quant_bf16_fp8_m1_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 32
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 35
		// gfx950 requires the architected accumulator range boundary even
		// when this kernel does not allocate AGPRs.
		.amdhsa_accum_offset 36
		.amdhsa_next_free_sgpr 25
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_moe_quant_bf16_fp8_m1_gfx950, .Lfunc_end0-qwen36_moe_quant_bf16_fp8_m1_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: input_bf16, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: output_fp8, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: output_scale_f32, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: rows, .offset: 24, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 64
    .name: qwen36_moe_quant_bf16_fp8_m1_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 27
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_quant_bf16_fp8_m1_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 35
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
