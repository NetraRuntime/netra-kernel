// SPDX-License-Identifier: MIT
//
// Correctness-first deterministic Qwen3.6 M=1 MoE down projection:
//   FP8 E4M3 activation [9,512] with [9,4] FP32 scales
//   FP8 E4M3 expert weights [E,2048,512] with [E,16,4] FP32 scales
//   nine routed expert IDs and FP32 weights
//     -> fixed-order FP32 expert reduction -> BF16 [2048].
//
// One wave64 owns 64 output columns; lane i computes one complete dot product.
// This first raw gfx950 implementation deliberately expands FP8 values through
// native conversions and scalar FMAs so its addressing, dequantization, and
// reduction semantics can be validated before CDNA4 MFMA tiling.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_down_reduce_fp8_gfx950
	.globl qwen36_moe_down_reduce_fp8_gfx950
	.p2align 8
	.type qwen36_moe_down_reduce_fp8_gfx950,@function
qwen36_moe_down_reduce_fp8_gfx950:
	// Kernargs: activation, activation_scale, w2, w2_scale,
	//           topk_weights, topk_ids, output.
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dwordx2 s[10:11], s[0:1], 24
	s_load_dwordx2 s[12:13], s[0:1], 32
	s_load_dwordx2 s[14:15], s[0:1], 40
	s_load_dwordx2 s[16:17], s[0:1], 48
	s_waitcnt lgkmcnt(0)

	// n = workgroup_id_x * 64 + lane_id.
	s_lshl_b32 s36, s2, 6
	v_add_u32_e32 v1, s36, v0
	// Per-lane base into one expert's [2048,512] byte tensor.
	v_lshlrev_b32_e32 v2, 9, v1
	v_mov_b32_e32 v4, 0			// deterministic total
	s_mov_b32 s18, 0			// routed slot

.Lslot:
	// Load this slot's compact/full expert ID and router weight.
	s_lshl_b32 s19, s18, 2
	s_load_dword s20, s[14:15], s19
	s_load_dword s21, s[12:13], s19

	// activation slot base = activation + slot * 512 bytes.
	s_lshl_b32 s19, s18, 9
	s_add_u32 s22, s4, s19
	s_addc_u32 s23, s5, 0
	// activation-scale slot base = scale + slot * 16 bytes.
	s_lshl_b32 s19, s18, 4
	s_add_u32 s28, s6, s19
	s_addc_u32 s29, s7, 0
	s_waitcnt lgkmcnt(0)

	// Weight expert base = w2 + expert * 2048 * 512.
	s_lshl_b32 s19, s20, 20
	s_add_u32 s24, s8, s19
	s_addc_u32 s25, s9, 0
	// Scale base = scale + expert*16*4 + (n/128)*4*4.
	s_lshl_b32 s19, s20, 8
	s_lshr_b32 s37, s2, 1
	s_lshl_b32 s37, s37, 4
	s_add_u32 s19, s19, s37
	s_add_u32 s26, s10, s19
	s_addc_u32 s27, s11, 0

	s_mov_b32 s33, 0			// K block [0,4)
.Lkblock:
	v_mov_b32_e32 v5, 0			// block FP32 dot
	s_lshl_b32 s36, s33, 2
	s_load_dword s30, s[28:29], s36
	s_load_dword s31, s[26:27], s36
	// Byte offset for this 128-wide K block.
	s_lshl_b32 s38, s33, 7
	v_add_u32_e32 v3, s38, v2
	s_mov_b32 s34, 0

.Ldot:
	// One packed dword contains four OCP FP8 E4M3 values.
	s_load_dword s35, s[22:23], s38
	global_load_dword v7, v3, s[24:25]
	s_waitcnt vmcnt(0) & lgkmcnt(0)
	v_mov_b32_e32 v6, s35
	// gfx950 exposes OCP FP8 conversion and MFMA, but not the RDNA-oriented
	// packed dot4 opcode. Expand this correctness version explicitly.
	v_cvt_f32_fp8 v8, v6
	v_cvt_f32_fp8 v9, v7
	v_fma_f32 v5, v8, v9, v5
	v_lshrrev_b32_e32 v6, 8, v6
	v_lshrrev_b32_e32 v7, 8, v7
	v_cvt_f32_fp8 v8, v6
	v_cvt_f32_fp8 v9, v7
	v_fma_f32 v5, v8, v9, v5
	v_lshrrev_b32_e32 v6, 8, v6
	v_lshrrev_b32_e32 v7, 8, v7
	v_cvt_f32_fp8 v8, v6
	v_cvt_f32_fp8 v9, v7
	v_fma_f32 v5, v8, v9, v5
	v_lshrrev_b32_e32 v6, 8, v6
	v_lshrrev_b32_e32 v7, 8, v7
	v_cvt_f32_fp8 v8, v6
	v_cvt_f32_fp8 v9, v7
	v_fma_f32 v5, v8, v9, v5
	v_add_u32_e32 v3, 4, v3
	s_add_u32 s38, s38, 4
	s_add_u32 s34, s34, 1
	s_cmp_lt_u32 s34, 32
	s_cbranch_scc1 .Ldot

	// Apply the 128x128 activation/weight scales and router weight once per
	// block, then add experts and blocks in a fixed program order.
	v_mul_f32_e32 v5, s30, v5
	v_mul_f32_e32 v5, s31, v5
	v_mul_f32_e32 v5, s21, v5
	v_add_f32_e32 v4, v4, v5
	s_add_u32 s33, s33, 1
	s_cmp_lt_u32 s33, 4
	s_cbranch_scc1 .Lkblock

	s_add_u32 s18, s18, 1
	s_cmp_lt_u32 s18, 9
	s_cbranch_scc1 .Lslot

	// Store lane-owned BF16 output.
	v_cvt_pk_bf16_f32 v8, v4, v4
	v_lshlrev_b32_e32 v9, 1, v1
	global_store_short v9, v8, s[16:17]
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_down_reduce_fp8_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 56
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 10
		.amdhsa_accum_offset 12
		.amdhsa_next_free_sgpr 39
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_moe_down_reduce_fp8_gfx950, .Lfunc_end0-qwen36_moe_down_reduce_fp8_gfx950

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
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 56
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 64
    .name: qwen36_moe_down_reduce_fp8_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 41
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_down_reduce_fp8_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 10
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
