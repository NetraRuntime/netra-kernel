// SPDX-License-Identifier: MIT
//
// Qwen3.6 GDN BA M16 projection:
//   BF16 hidden [16,2048] x BF16 weight^T [2048,64]
//     -> BF16 output [16,64].
//
// One wave64 computes one 16x16 output tile with
// v_mfma_f32_16x16x32_bf16. Four workgroups cover N=64. Direct global loads
// preserve the deployed MFMA accumulation order while avoiding the generic
// persistent-matmul launch geometry. An LDS variant remains a future tuning
// direction; this implementation is the measured eager/full-graph candidate.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_gdn_ba_bf16_mfma_direct_gfx950
	.globl qwen36_gdn_ba_bf16_mfma_direct_gfx950
	.p2align 8
	.type qwen36_gdn_ba_bf16_mfma_direct_gfx950,@function
qwen36_gdn_ba_bf16_mfma_direct_gfx950:
	// Preserve workgroup X before loading the three pointer arguments.
	s_mov_b32 s12, s2
	s_load_dwordx2 s[2:3], s[0:1], 0
	s_load_dwordx2 s[4:5], s[0:1], 8
	s_load_dwordx2 s[6:7], s[0:1], 16
	s_waitcnt lgkmcnt(0)

	// MFMA operand distribution for a 16x16x32 BF16 instruction:
	//   row/column = lane[3:0]
	//   K subgroup  = lane[5:4], eight BF16 values per lane.
	v_and_b32_e32 v1, 15, v0
	v_and_b32_e32 v2, 48, v0

	// hidden byte offset = row*4096 + K_subgroup*16.
	v_lshlrev_b32_e32 v3, 12, v1
	v_add_u32_e32 v4, v3, v2

	// weight byte offset =
	//   (workgroup_x*16 + column)*4096 + K_subgroup*16.
	s_lshl_b32 s13, s12, 4
	v_add_u32_e32 v5, s13, v1
	v_lshlrev_b32_e32 v5, 12, v5
	v_add_u32_e32 v5, v5, v2

	v_mov_b32_e32 v24, 0
	v_mov_b32_e32 v25, 0
	v_mov_b32_e32 v26, 0
	v_mov_b32_e32 v27, 0
	s_mov_b32 s14, 0

.Lmfma_k_loop:
	global_load_dwordx4 v[8:11], v4, s[4:5]
	global_load_dwordx4 v[16:19], v5, s[6:7]
	s_waitcnt vmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[24:27], v[8:11], v[16:19], v[24:27]

	v_add_u32_e32 v4, 64, v4
	v_add_u32_e32 v5, 64, v5
	s_add_u32 s14, s14, 1
	s_cmp_lt_u32 s14, 64
	s_cbranch_scc1 .Lmfma_k_loop

	// Each lane owns one column and four rows. lane[3:0] selects the column;
	// lane[5:4] selects the four-row group; accumulator registers select the
	// row within that group.
	v_add_u32_e32 v3, s13, v1
	v_lshlrev_b32_e32 v3, 1, v3
	v_lshlrev_b32_e32 v2, 5, v2
	v_add_u32_e32 v6, v2, v3

	s_nop 2
	v_cvt_pk_bf16_f32 v28, v24, v25
	v_cvt_pk_bf16_f32 v29, v26, v27
	v_lshrrev_b32_e32 v30, 16, v28
	v_lshrrev_b32_e32 v31, 16, v29
	global_store_short v6, v28, s[2:3]
	v_add_u32_e32 v7, 128, v6
	global_store_short v7, v30, s[2:3]
	v_add_u32_e32 v7, 256, v6
	global_store_short v7, v29, s[2:3]
	v_add_u32_e32 v7, 384, v6
	global_store_short v7, v31, s[2:3]
	s_waitcnt vmcnt(0)
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_gdn_ba_bf16_mfma_direct_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 24
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 32
		.amdhsa_accum_offset 32
		.amdhsa_next_free_sgpr 15
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_gdn_ba_bf16_mfma_direct_gfx950, .Lfunc_end0-qwen36_gdn_ba_bf16_mfma_direct_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: output_ba_bf16, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: hidden_bf16, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: ba_weight_bf16, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 64
    .name: qwen36_gdn_ba_bf16_mfma_direct_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 15
    .sgpr_spill_count: 0
    .symbol: qwen36_gdn_ba_bf16_mfma_direct_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 32
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
