// SPDX-License-Identifier: MIT
//
// Experimental gfx950 Qwen3.6 decode-MoE epilogue:
//   FP32 [rows, 2, 512] gate/up
//     -> BF16-rounded SiLU(gate) * up
//     -> FP8 E4M3 [rows, 512] plus FP32 [rows, 4] scales.
//
// One wave64 workgroup handles one routed row. Each 16-lane subgroup owns one
// 128-element quantization group and each lane owns eight contiguous values.
// This is raw AMDGCN compute; the HIP harness only loads, dispatches, checks,
// and times the code object.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_silu_mul_quant_fp8_gfx950
	.globl qwen36_moe_silu_mul_quant_fp8_gfx950
	.p2align 8
	.type qwen36_moe_silu_mul_quant_fp8_gfx950,@function
qwen36_moe_silu_mul_quant_fp8_gfx950:
	// Kernargs: input_f32, output_fp8, output_scale_f32, rows.
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dword s10, s[0:1], 24
	s_waitcnt lgkmcnt(0)
	s_cmp_ge_u32 s2, s10
	s_cbranch_scc1 .Lend

	// Row byte offsets: input=2*512*f32, output=512*fp8, scales=4*f32.
	s_lshl_b32 s11, s2, 12
	s_lshl_b32 s12, s2, 9
	s_lshl_b32 s13, s2, 4
	s_mov_b32 s14, 0x3f800000	// 1.0f
	s_mov_b32 s15, 0xbfb8aa3b	// -log2(e)
	s_mov_b32 s16, 0x3b124925	// 1.0f / 448.0f
	s_mov_b32 s17, 0x2edbe6ff	// 1.0e-10f
	s_mov_b32 s24, 0x05040100	// pack low FP8 pairs as [lo, hi]

	// lane*8 elements = lane*32 input bytes.
	v_lshlrev_b32_e32 v1, 5, v0
	v_add_u32_e32 v2, s11, v1
	v_add_u32_e32 v3, 2048, v2
	global_load_dwordx4 v[4:7], v2, s[4:5]
	global_load_dwordx4 v[8:11], v2, s[4:5] offset:16
	global_load_dwordx4 v[12:15], v3, s[4:5]
	global_load_dwordx4 v[16:19], v3, s[4:5] offset:16
	s_waitcnt vmcnt(0)

	// SiLU(x) = x / (1 + exp(-x)); v_exp_f32 consumes base-2 input.
	v_mul_f32_e32 v20, s15, v4
	v_mul_f32_e32 v21, s15, v5
	v_mul_f32_e32 v22, s15, v6
	v_mul_f32_e32 v23, s15, v7
	v_mul_f32_e32 v24, s15, v8
	v_mul_f32_e32 v25, s15, v9
	v_mul_f32_e32 v26, s15, v10
	v_mul_f32_e32 v27, s15, v11
	v_exp_f32_e32 v20, v20
	v_exp_f32_e32 v21, v21
	v_exp_f32_e32 v22, v22
	v_exp_f32_e32 v23, v23
	v_exp_f32_e32 v24, v24
	v_exp_f32_e32 v25, v25
	v_exp_f32_e32 v26, v26
	v_exp_f32_e32 v27, v27
	v_add_f32_e32 v20, s14, v20
	v_add_f32_e32 v21, s14, v21
	v_add_f32_e32 v22, s14, v22
	v_add_f32_e32 v23, s14, v23
	v_add_f32_e32 v24, s14, v24
	v_add_f32_e32 v25, s14, v25
	v_add_f32_e32 v26, s14, v26
	v_add_f32_e32 v27, s14, v27
	v_rcp_f32_e32 v20, v20
	v_rcp_f32_e32 v21, v21
	v_rcp_f32_e32 v22, v22
	v_rcp_f32_e32 v23, v23
	v_rcp_f32_e32 v24, v24
	v_rcp_f32_e32 v25, v25
	v_rcp_f32_e32 v26, v26
	v_rcp_f32_e32 v27, v27
	v_pk_mul_f32 v[4:5], v[20:21], v[4:5]
	v_pk_mul_f32 v[6:7], v[22:23], v[6:7]
	v_pk_mul_f32 v[8:9], v[24:25], v[8:9]
	v_pk_mul_f32 v[10:11], v[26:27], v[10:11]
	v_pk_mul_f32 v[4:5], v[4:5], v[12:13]
	v_pk_mul_f32 v[6:7], v[6:7], v[14:15]
	v_pk_mul_f32 v[8:9], v[8:9], v[16:17]
	v_pk_mul_f32 v[10:11], v[10:11], v[18:19]

	// Match the deployed two-kernel path's BF16 intermediate rounding before
	// calculating the FP8 scale.
	v_cvt_pk_bf16_f32 v28, v4, v5
	v_cvt_pk_bf16_f32 v29, v6, v7
	v_cvt_pk_bf16_f32 v30, v8, v9
	v_cvt_pk_bf16_f32 v31, v10, v11
	v_lshlrev_b32_e32 v4, 16, v28
	v_and_b32_e32 v5, 0xffff0000, v28
	v_lshlrev_b32_e32 v6, 16, v29
	v_and_b32_e32 v7, 0xffff0000, v29
	v_lshlrev_b32_e32 v8, 16, v30
	v_and_b32_e32 v9, 0xffff0000, v30
	v_lshlrev_b32_e32 v10, 16, v31
	v_and_b32_e32 v11, 0xffff0000, v31

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
	.amdhsa_kernel qwen36_moe_silu_mul_quant_fp8_gfx950
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
	.size qwen36_moe_silu_mul_quant_fp8_gfx950, .Lfunc_end0-qwen36_moe_silu_mul_quant_fp8_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: input_f32, .offset: 0, .size: 8,
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
    .name: qwen36_moe_silu_mul_quant_fp8_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 27
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_silu_mul_quant_fp8_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 35
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
