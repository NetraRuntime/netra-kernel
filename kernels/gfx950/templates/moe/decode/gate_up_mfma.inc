// Netra model-independent fixed-contract tactic template.
	.include "kernels/gfx950/templates/common/primitives.inc"
// SPDX-License-Identifier: MIT
//
// Production native-CDNA4 Qwen3.6 rowwise routed gate/up projection.
// Grid Y selects an independent token. Grid X retains the validated M=1
// slot/tile organization, so an M=16 verification launch has exactly the
// same reduction order within every row. One wave64 computes 16 columns for
// one routed slot.

	NETRA_GFX950_MODULE_HEADER 6
	.macro NETRA_MOE_GATE_UP_MFMA symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_M, 1
	NETRA_REQUIRE_EQ NETRA_HIDDEN_SIZE, 2048
	NETRA_REQUIRE_EQ NETRA_INTERMEDIATE_SIZE, 512
	NETRA_REQUIRE_EQ NETRA_TOPK, 9
	NETRA_REQUIRE_EQ NETRA_SCALE_BLOCK, 128
	NETRA_REQUIRE_EQ NETRA_WEIGHT_LAYOUT_ID, 1
	NETRA_KERNEL_ENTRY \symbol, 1
	// hidden FP8, hidden scale FP32, w13 FP8, w13 scale FP32,
	// topk IDs int32, output FP32.
	NETRA_LOAD_KERNARG_PTR s[4:5], 0
	NETRA_LOAD_KERNARG_PTR s[6:7], 8
	NETRA_LOAD_KERNARG_PTR s[8:9], 16
	NETRA_LOAD_KERNARG_PTR s[10:11], 24
	NETRA_LOAD_KERNARG_PTR s[12:13], 32
	NETRA_LOAD_KERNARG_PTR s[14:15], 40
	NETRA_WAIT_LGKM0

	// Token-local hidden/scales. Each token owns 2048 FP8 bytes and 16 f32
	// activation scales.
	s_lshl_b32 s36, s3, 11
	NETRA_ADD_U64_INPLACE s4, s5, s36
	s_lshl_b32 s36, s3, 6
	NETRA_ADD_U64_INPLACE s6, s7, s36

	// slot = workgroup/64, tile = workgroup%64, N = tile*16 + lane%16.
	// route = token*9 + slot indexes routing and output rows.
	s_lshr_b32 s18, s2, 6
	s_and_b32 s19, s2, 63
	s_mul_i32 s35, s3, 9
	s_add_u32 s35, s35, s18
	s_lshl_b32 s20, s35, 2
	s_load_dword s21, s[12:13], s20
	NETRA_WAVE64_LANE_AND_FRAGMENT v1, v2, v0
	// AITER physically shuffles each logical [N,K] expert weight as
	// [N/16,K/32,K-half,N-lane,K16].  Preserve logical N in v3 for the
	// output while v4 addresses the shuffled N16 tile, lane, and the
	// wave's 16-wide K fragment:
	//   tile*32768 + (lane%16)*16 + (lane/16)*256.
	s_lshl_b32 s22, s19, 4
	v_add_u32_e32 v3, s22, v1
	s_lshl_b32 s22, s19, 15
	NETRA_AITER_N16_K16_OFFSET v4, s22, v1, v2, v5
	v_mov_b32_e32 v6, 0
	NETRA_WAIT_LGKM0

	// Expert weight and scale bases.
	s_lshl_b32 s23, s21, 21
	NETRA_ADD_U64 s24, s25, s8, s9, s23
	s_lshl_b32 s23, s21, 9
	s_lshr_b32 s34, s19, 3
	s_lshl_b32 s34, s34, 6
	s_add_u32 s23, s23, s34
	NETRA_ADD_U64 s26, s27, s10, s11, s23

	s_mov_b32 s29, 0
.Lkblock:
	s_lshl_b32 s30, s29, 7
	s_lshl_b32 s34, s29, 11
	s_lshl_b32 s31, s29, 2
	s_load_dword s32, s[6:7], s31
	s_load_dword s33, s[26:27], s31
	v_add_u32_e32 v5, s30, v2
	global_load_dwordx4 v[10:13], v5, s[4:5]
	global_load_dwordx4 v[14:17], v5, s[4:5] offset:64
	v_add_u32_e32 v7, s34, v4
	global_load_dwordx4 v[18:21], v7, s[24:25]
	global_load_dwordx4 v[22:25], v7, s[24:25] offset:1024
	NETRA_ZERO_ACC4 v26, v27, v28, v29
	NETRA_MFMA_FP8_16X16X128 v[26:29], v[10:17], v[18:25], 15
	NETRA_SCALE_ACCUMULATE2 v7, s32, s33, v26, v6
	s_add_u32 s29, s29, 1
	s_cmp_lt_u32 s29, 16
	s_cbranch_scc1 .Lkblock

	v_cmp_gt_u32_e32 vcc, 16, v0
	s_and_saveexec_b64 s[36:37], vcc
	// output[(route*1024)+N]
	s_lshl_b32 s34, s35, 12
	v_lshlrev_b32_e32 v8, 2, v3
	v_add_u32_e32 v8, s34, v8
	global_store_dword v8, v6, s[14:15]
	s_or_b64 exec, exec, s[36:37]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel \symbol
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 48
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 30
		.amdhsa_accum_offset 32
		.amdhsa_next_free_sgpr 38
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
  - .args:
      - { .name: hidden_fp8, .offset: 0, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: hidden_scale_f32, .offset: 8, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: w13_fp8, .offset: 16, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: w13_scale_f32, .offset: 24, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: topk_ids_i32, .offset: 32, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: output_f32, .offset: 40, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: write_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 48
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 64
    .name: \symbol
    .private_segment_fixed_size: 0
    .sgpr_count: 40
    .sgpr_spill_count: 0
    .symbol: \symbol\().kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 30
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
	.endm
