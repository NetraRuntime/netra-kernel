// Netra model-independent fixed-contract tactic template.
	.include "kernels/gfx950/templates/common/primitives.inc"
// SPDX-License-Identifier: MIT
//
// Production native-CDNA4 MFMA Qwen3.6 rowwise MoE down projection.
//
// Two wave64s share each 16-column output tile. Wave 0 evaluates routed slots
// 0..4. Wave 1 evaluates slots 5..8 and writes each individually scaled K-block
// contribution to LDS. After a workgroup barrier, wave 0 consumes those
// contributions in the original slot/K order. Grid Y selects an independent
// token without changing that validated M=1 accumulation order.

	NETRA_GFX950_MODULE_HEADER 6
	.macro NETRA_MOE_DOWN_REDUCE_MFMA_2WAVE symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_M, 1
	NETRA_REQUIRE_EQ NETRA_HIDDEN_SIZE, 2048
	NETRA_REQUIRE_EQ NETRA_INTERMEDIATE_SIZE, 512
	NETRA_REQUIRE_EQ NETRA_TOPK, 9
	NETRA_REQUIRE_EQ NETRA_SCALE_BLOCK, 128
	NETRA_REQUIRE_EQ NETRA_WAVES_PER_WG, 2
	NETRA_REQUIRE_EQ NETRA_WEIGHT_LAYOUT_ID, 1
	NETRA_KERNEL_ENTRY \symbol, 1
	// Kernargs: activation, activation_scale, w2, w2_scale,
	//           topk_weights, topk_ids, output.
	NETRA_LOAD_KERNARG_PTR s[4:5], 0
	NETRA_LOAD_KERNARG_PTR s[6:7], 8
	NETRA_LOAD_KERNARG_PTR s[8:9], 16
	NETRA_LOAD_KERNARG_PTR s[10:11], 24
	NETRA_LOAD_KERNARG_PTR s[12:13], 32
	NETRA_LOAD_KERNARG_PTR s[14:15], 40
	NETRA_LOAD_KERNARG_PTR s[16:17], 48
	NETRA_WAIT_LGKM0

	// Token-local activation, scale, routing, and output bases. Grid Y is the
	// token index. Per-token byte strides are 9*512, 9*4*f32, 9*f32,
	// and 2048*bf16 respectively.
	s_lshl_b32 s32, s3, 12
	s_lshl_b32 s33, s3, 9
	s_add_u32 s32, s32, s33
	NETRA_ADD_U64_INPLACE s4, s5, s32
	s_lshl_b32 s32, s3, 7
	s_lshl_b32 s33, s3, 4
	s_add_u32 s32, s32, s33
	NETRA_ADD_U64_INPLACE s6, s7, s32
	s_lshl_b32 s32, s3, 5
	s_lshl_b32 s33, s3, 2
	s_add_u32 s32, s32, s33
	NETRA_ADD_U64_INPLACE s12, s13, s32
	NETRA_ADD_U64_INPLACE s14, s15, s32
	s_lshl_b32 s32, s3, 12
	NETRA_ADD_U64_INPLACE s16, s17, s32

	// v0 is the 0..127 workitem id and v30 is the wave-local lane id.
	v_and_b32_e32 v30, 63, v0
	v_lshrrev_b32_e32 v31, 6, v0

	// lane column and K fragment:
	//   column = lane & 15
	//   fragment = (lane >> 4) * 16
	NETRA_WAVE64_LANE_AND_FRAGMENT v1, v2, v30
	s_lshl_b32 s34, s2, 4
	v_add_u32_e32 v3, s34, v1
	// AITER's resident FP8 expert tensor is physically shuffled as
	// [N/16,K/32,K-half,N-lane,K16]. Address the current N16 tile and
	// the wave's K16 fragment directly while preserving logical N in v3.
	s_lshl_b32 s34, s2, 13
	NETRA_AITER_N16_K16_OFFSET v4, s34, v1, v2, v5

	v_cmp_eq_u32_e32 vcc, 0, v31
	s_cbranch_vccnz .Lwave0

	// Wave 1 computes slots 5..8. Every K-block contribution is retained
	// separately so wave 0 can reproduce the original sequential additions.
	s_mov_b32 s18, 5
.Lwave1_slot:
	s_lshl_b32 s19, s18, 2
	s_load_dword s20, s[14:15], s19
	s_load_dword s21, s[12:13], s19

	s_lshl_b32 s19, s18, 9
	NETRA_ADD_U64 s22, s23, s4, s5, s19
	s_lshl_b32 s19, s18, 4
	NETRA_ADD_U64 s28, s29, s6, s7, s19
	NETRA_WAIT_LGKM0

	s_lshl_b32 s19, s20, 20
	NETRA_ADD_U64 s24, s25, s8, s9, s19
	s_lshl_b32 s19, s20, 8
	s_lshr_b32 s35, s2, 3
	s_lshl_b32 s35, s35, 4
	s_add_u32 s19, s19, s35
	NETRA_ADD_U64 s26, s27, s10, s11, s19

	s_mov_b32 s32, 0
.Lwave1_kblock:
	s_lshl_b32 s33, s32, 7
	s_lshl_b32 s37, s32, 11
	s_lshl_b32 s36, s32, 2
	s_load_dword s30, s[28:29], s36
	s_load_dword s31, s[26:27], s36

	v_add_u32_e32 v5, s33, v2
	global_load_dwordx4 v[10:13], v5, s[22:23]
	global_load_dwordx4 v[14:17], v5, s[22:23] offset:64
	v_add_u32_e32 v7, s37, v4
	global_load_dwordx4 v[18:21], v7, s[24:25]
	global_load_dwordx4 v[22:25], v7, s[24:25] offset:1024
	NETRA_ZERO_ACC4 v26, v27, v28, v29
	NETRA_WAIT_VM0_LGKM0
	v_mfma_f32_16x16x128_f8f6f4 v[26:29], v[10:17], v[18:25], 0
	// Eleven explicit delay cycles are the shortest deterministic gfx950
	// dependency schedule validated for the MFMA result consumed below.
	s_nop 11

	NETRA_SCALE_PRODUCT3 v7, s30, s31, s21, v26

	// LDS layout: [slot - 5][K block][column], with 64 bytes per
	// contribution. Only the first MFMA lane group owns row zero.
	s_sub_u32 s37, s18, 5
	s_lshl_b32 s37, s37, 2
	s_add_u32 s37, s37, s32
	s_lshl_b32 s37, s37, 6
	v_lshlrev_b32_e32 v8, 2, v1
	v_add_u32_e32 v8, s37, v8
	v_cmp_gt_u32_e32 vcc, 16, v30
	s_and_saveexec_b64 s[38:39], vcc
	ds_write_b32 v8, v7
	s_or_b64 exec, exec, s[38:39]

	s_add_u32 s32, s32, 1
	s_cmp_lt_u32 s32, 4
	s_cbranch_scc1 .Lwave1_kblock

	s_add_u32 s18, s18, 1
	s_cmp_lt_u32 s18, 9
	s_cbranch_scc1 .Lwave1_slot

	NETRA_WAIT_LGKM0_BARRIER
	s_endpgm

	// Wave 0 computes slots 0..4 in the original order.
.Lwave0:
	v_mov_b32_e32 v6, 0
	s_mov_b32 s18, 0
.Lwave0_slot:
	s_lshl_b32 s19, s18, 2
	s_load_dword s20, s[14:15], s19
	s_load_dword s21, s[12:13], s19

	s_lshl_b32 s19, s18, 9
	NETRA_ADD_U64 s22, s23, s4, s5, s19
	s_lshl_b32 s19, s18, 4
	NETRA_ADD_U64 s28, s29, s6, s7, s19
	NETRA_WAIT_LGKM0

	s_lshl_b32 s19, s20, 20
	NETRA_ADD_U64 s24, s25, s8, s9, s19
	s_lshl_b32 s19, s20, 8
	s_lshr_b32 s35, s2, 3
	s_lshl_b32 s35, s35, 4
	s_add_u32 s19, s19, s35
	NETRA_ADD_U64 s26, s27, s10, s11, s19

	s_mov_b32 s32, 0
.Lwave0_kblock:
	s_lshl_b32 s33, s32, 7
	s_lshl_b32 s37, s32, 11
	s_lshl_b32 s36, s32, 2
	s_load_dword s30, s[28:29], s36
	s_load_dword s31, s[26:27], s36

	v_add_u32_e32 v5, s33, v2
	global_load_dwordx4 v[10:13], v5, s[22:23]
	global_load_dwordx4 v[14:17], v5, s[22:23] offset:64
	v_add_u32_e32 v7, s37, v4
	global_load_dwordx4 v[18:21], v7, s[24:25]
	global_load_dwordx4 v[22:25], v7, s[24:25] offset:1024
	NETRA_ZERO_ACC4 v26, v27, v28, v29
	NETRA_WAIT_VM0_LGKM0
	v_mfma_f32_16x16x128_f8f6f4 v[26:29], v[10:17], v[18:25], 0
	// Match the validated wave-1 MFMA dependency schedule.
	s_nop 11

	NETRA_SCALE_PRODUCT3 v7, s30, s31, s21, v26
	v_add_f32_e32 v6, v6, v7

	s_add_u32 s32, s32, 1
	s_cmp_lt_u32 s32, 4
	s_cbranch_scc1 .Lwave0_kblock

	s_add_u32 s18, s18, 1
	s_cmp_lt_u32 s18, 5
	s_cbranch_scc1 .Lwave0_slot

	// All wave-1 writes are visible after the barrier. Add them in exact
	// slot-5/K-0 through slot-8/K-3 order.
	NETRA_BARRIER
	v_cmp_gt_u32_e32 vcc, 16, v30
	s_and_saveexec_b64 s[38:39], vcc
	s_mov_b32 s18, 0
.Lwave0_lds_add:
	s_lshl_b32 s19, s18, 6
	v_lshlrev_b32_e32 v8, 2, v1
	v_add_u32_e32 v8, s19, v8
	ds_read_b32 v7, v8
	NETRA_WAIT_LGKM0
	v_add_f32_e32 v6, v6, v7
	s_add_u32 s18, s18, 1
	s_cmp_lt_u32 s18, 16
	s_cbranch_scc1 .Lwave0_lds_add

	v_cvt_pk_bf16_f32 v8, v6, v6
	v_lshlrev_b32_e32 v9, 1, v3
	global_store_short v9, v8, s[16:17]
	s_or_b64 exec, exec, s[38:39]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel \symbol
		.amdhsa_group_segment_fixed_size 1024
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 56
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 32
		.amdhsa_accum_offset 32
		.amdhsa_next_free_sgpr 40
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
      - { .name: activation_fp8, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: activation_scale_f32, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: w2_fp8, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: w2_scale_f32, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: topk_weights_f32, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: topk_ids_i32, .offset: 40, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: output_bf16, .offset: 48, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
    .group_segment_fixed_size: 1024
    .kernarg_segment_align: 8
    .kernarg_segment_size: 56
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 128
    .name: \symbol
    .private_segment_fixed_size: 0
    .sgpr_count: 42
    .sgpr_spill_count: 0
    .symbol: \symbol\().kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 32
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
	.endm
