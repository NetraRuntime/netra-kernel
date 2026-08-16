// SPDX-License-Identifier: MIT
//
// Expert-sorted Qwen3.6 FP8 down projection for gfx950 verification batches.
//
// Four wave64s compute a 16x64 output tile for one expert-sorted route block.
// This diagnostic variant keeps independent activation loads per wave so the
// wider workgroup and vector wave addressing can be validated before adding
// LDS sharing. The arithmetic and fixed-order raw reducer match the N16 path.
//
// Grid: (32 output-tile groups, sorted_token_ids.size()/16 blocks, 1)
// Workgroup: (256, 1, 1), four wave64s.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_grouped_down_m16n64_nolds_fp8_gfx950
	.globl qwen36_moe_grouped_down_m16n64_nolds_fp8_gfx950
	.p2align 8
	.type qwen36_moe_grouped_down_m16n64_nolds_fp8_gfx950,@function
qwen36_moe_grouped_down_m16n64_nolds_fp8_gfx950:
	// Preserve grid coordinates and derive wave-local lane and wave IDs.
	s_mov_b32 s40, s2
	s_mov_b32 s41, s3
	v_lshrrev_b32_e32 v46, 6, v0
	v_and_b32_e32 v47, 63, v0
	// inter FP8, inter scale FP32, w2 FP8, w2 scale FP32,
	// sorted token IDs, sorted expert IDs, valid padded count, partial FP32,
	// token rows.
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dwordx2 s[10:11], s[0:1], 24
	s_load_dwordx2 s[12:13], s[0:1], 32
	s_load_dwordx2 s[14:15], s[0:1], 40
	s_load_dwordx2 s[16:17], s[0:1], 48
	s_load_dwordx2 s[18:19], s[0:1], 56
	s_load_dword s20, s[0:1], 64
	s_waitcnt lgkmcnt(0)

	// sorted_start = block*16.  Blocks beyond num_valid_ids are unused
	// capacity in the graph-stable sorting workspace.
	s_lshl_b32 s21, s41, 4
	s_load_dword s22, s[16:17], 0
	s_lshl_b32 s23, s41, 2
	s_load_dword s23, s[14:15], s23
	s_waitcnt lgkmcnt(0)
	s_cmp_lt_u32 s21, s22
	s_cbranch_scc0 .Lend

	// route_count = rows*9.
	s_lshl_b32 s24, s20, 3
	s_add_u32 s24, s24, s20
	v_mov_b32_e32 v45, s24

	// MFMA distribution: row/column = lane[3:0], K subgroup = lane[5:4].
	v_and_b32_e32 v1, 15, v47
	v_and_b32_e32 v2, 48, v47

	// AITER packs each sorted ID as (topk_slot << 24) | token_row.  Decode
	// that value to the row-major route index token_row*9 + topk_slot used by
	// inter_states.  Slot 9 is the padding sentinel.
	v_add_u32_e32 v3, s21, v1
	v_lshlrev_b32_e32 v3, 2, v3
	global_load_dword v4, v3, s[12:13]

	// Each lane owns four result rows.  lane[5:4] selects their group.
	v_lshrrev_b32_e32 v3, 2, v2
	v_add_u32_e32 v3, s21, v3
	v_lshlrev_b32_e32 v3, 2, v3
	global_load_dword v5, v3, s[12:13]
	global_load_dword v6, v3, s[12:13] offset:4
	global_load_dword v7, v3, s[12:13] offset:8
	global_load_dword v8, v3, s[12:13] offset:12
	s_waitcnt vmcnt(0)

	// Decode the activation row for lane[3:0]. Invalid/padded entries safely
	// read route zero; their result lanes are never stored.
	v_lshrrev_b32_e32 v34, 24, v4
	v_and_b32_e32 v9, 0x00ffffff, v4
	v_mul_lo_u32 v9, 9, v9
	v_add_u32_e32 v9, v34, v9
	v_cmp_gt_u32_e32 vcc, s24, v9
	v_cndmask_b32_e32 v9, 0, v9, vcc
	v_cmp_gt_u32_e32 vcc, 9, v34
	v_cndmask_b32_e32 v9, 0, v9, vcc

	// Decode the four result rows owned by this lane. Invalid values retain
	// route_count so the guarded stores reject them, while v34:v37 contain
	// route-zero-clamped indices for safe scale loads.
	v_lshrrev_b32_e32 v34, 24, v5
	v_and_b32_e32 v5, 0x00ffffff, v5
	v_mul_lo_u32 v5, 9, v5
	v_add_u32_e32 v5, v34, v5
	v_cmp_gt_u32_e32 vcc, s24, v5
	v_cndmask_b32_e32 v5, v45, v5, vcc
	v_cmp_gt_u32_e32 vcc, 9, v34
	v_cndmask_b32_e32 v5, v45, v5, vcc
	v_cmp_gt_u32_e32 vcc, s24, v5
	v_cndmask_b32_e32 v34, 0, v5, vcc
	v_lshrrev_b32_e32 v35, 24, v6
	v_and_b32_e32 v6, 0x00ffffff, v6
	v_mul_lo_u32 v6, 9, v6
	v_add_u32_e32 v6, v35, v6
	v_cmp_gt_u32_e32 vcc, s24, v6
	v_cndmask_b32_e32 v6, v45, v6, vcc
	v_cmp_gt_u32_e32 vcc, 9, v35
	v_cndmask_b32_e32 v6, v45, v6, vcc
	v_cmp_gt_u32_e32 vcc, s24, v6
	v_cndmask_b32_e32 v35, 0, v6, vcc
	v_lshrrev_b32_e32 v36, 24, v7
	v_and_b32_e32 v7, 0x00ffffff, v7
	v_mul_lo_u32 v7, 9, v7
	v_add_u32_e32 v7, v36, v7
	v_cmp_gt_u32_e32 vcc, s24, v7
	v_cndmask_b32_e32 v7, v45, v7, vcc
	v_cmp_gt_u32_e32 vcc, 9, v36
	v_cndmask_b32_e32 v7, v45, v7, vcc
	v_cmp_gt_u32_e32 vcc, s24, v7
	v_cndmask_b32_e32 v36, 0, v7, vcc
	v_lshrrev_b32_e32 v37, 24, v8
	v_and_b32_e32 v8, 0x00ffffff, v8
	v_mul_lo_u32 v8, 9, v8
	v_add_u32_e32 v8, v37, v8
	v_cmp_gt_u32_e32 vcc, s24, v8
	v_cndmask_b32_e32 v8, v45, v8, vcc
	v_cmp_gt_u32_e32 vcc, 9, v37
	v_cndmask_b32_e32 v8, v45, v8, vcc
	v_cmp_gt_u32_e32 vcc, s24, v8
	v_cndmask_b32_e32 v37, 0, v8, vcc

	// Expert weight base: 2048*512 bytes per expert.  Weight scales are
	// [expert, 16 output blocks, 4 K blocks] FP32 = 256 bytes per expert.
	s_lshl_b32 s25, s23, 20
	s_add_u32 s26, s8, s25
	s_addc_u32 s27, s9, 0
	s_lshl_b32 s25, s23, 8
	s_lshr_b32 s28, s40, 1
	s_lshl_b32 s28, s28, 4
	s_add_u32 s25, s25, s28
	s_add_u32 s28, s10, s25
	s_addc_u32 s29, s11, 0

	// Base A byte offset. A route stride is 512 bytes.
	v_lshlrev_b32_e32 v38, 9, v9
	v_add_u32_e32 v38, v2, v38

	// The deployed SGLang loader applies AITER shuffle_weight(...,(16,16)):
	// [N/16,16,K/32,2,16] -> [N/16,K/32,2,16,16]. For one N16
	// tile, each K32 tile occupies 512 bytes. v2*16 maps the four MFMA
	// K subgroups (0,16,32,48) to shuffled offsets 0,256,512,768 and
	// lane[3:0]*16 selects the output row inside the tile.
	s_lshl_b32 s30, s40, 6
	s_lshl_b32 s36, s40, 15
	v_lshlrev_b32_e32 v39, 4, v1
	v_add_u32_e32 v39, s36, v39
	v_lshlrev_b32_e32 v40, 13, v46
	v_add_u32_e32 v39, v40, v39
	v_lshlrev_b32_e32 v40, 4, v2
	v_add_u32_e32 v39, v40, v39

	v_mov_b32_e32 v30, 0
	v_mov_b32_e32 v31, 0
	v_mov_b32_e32 v32, 0
	v_mov_b32_e32 v33, 0
	s_mov_b32 s31, 0
.Lkblock:
	// Load the four route-specific activation scales safely via clamped IDs.
	s_lshl_b32 s32, s31, 2
	v_lshlrev_b32_e32 v40, 4, v34
	v_add_u32_e32 v40, s32, v40
	global_load_dword v41, v40, s[6:7]
	v_lshlrev_b32_e32 v40, 4, v35
	v_add_u32_e32 v40, s32, v40
	global_load_dword v42, v40, s[6:7]
	v_lshlrev_b32_e32 v40, 4, v36
	v_add_u32_e32 v40, s32, v40
	global_load_dword v43, v40, s[6:7]
	v_lshlrev_b32_e32 v40, 4, v37
	v_add_u32_e32 v40, s32, v40
	global_load_dword v44, v40, s[6:7]
	s_load_dword s33, s[28:29], s32

	// Each K block is one native 16x16x128 E4M3 MFMA.
	s_lshl_b32 s34, s31, 7
	v_add_u32_e32 v40, s34, v38
	global_load_dwordx4 v[10:13], v40, s[4:5]
	global_load_dwordx4 v[14:17], v40, s[4:5] offset:64
	s_lshl_b32 s35, s31, 11
	v_add_u32_e32 v40, s35, v39
	global_load_dwordx4 v[18:21], v40, s[26:27]
	global_load_dwordx4 v[22:25], v40, s[26:27] offset:1024
	v_mov_b32_e32 v26, 0
	v_mov_b32_e32 v27, 0
	v_mov_b32_e32 v28, 0
	v_mov_b32_e32 v29, 0
	s_waitcnt vmcnt(0) & lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[26:29], v[10:17], v[18:25], 0
	s_nop 15
	v_mul_f32_e32 v26, v41, v26
	v_mul_f32_e32 v26, s33, v26
	v_add_f32_e32 v30, v30, v26
	v_mul_f32_e32 v27, v42, v27
	v_mul_f32_e32 v27, s33, v27
	v_add_f32_e32 v31, v31, v27
	v_mul_f32_e32 v28, v43, v28
	v_mul_f32_e32 v28, s33, v28
	v_add_f32_e32 v32, v32, v28
	v_mul_f32_e32 v29, v44, v29
	v_mul_f32_e32 v29, s33, v29
	v_add_f32_e32 v33, v33, v29
	s_add_u32 s31, s31, 1
	s_cmp_lt_u32 s31, 4
	s_cbranch_scc1 .Lkblock

	// Partial layout is [flattened token/top-k route, hidden column] FP32.
	v_lshlrev_b32_e32 v38, 4, v46
	v_add_u32_e32 v38, s30, v38
	v_add_u32_e32 v38, v1, v38
	v_lshlrev_b32_e32 v38, 2, v38
	v_cmp_gt_u32_e32 vcc, s24, v5
	s_and_saveexec_b64 s[42:43], vcc
	v_lshlrev_b32_e32 v39, 13, v5
	v_add_u32_e32 v39, v38, v39
	global_store_dword v39, v30, s[18:19]
	s_or_b64 exec, exec, s[42:43]
	v_cmp_gt_u32_e32 vcc, s24, v6
	s_and_saveexec_b64 s[42:43], vcc
	v_lshlrev_b32_e32 v39, 13, v6
	v_add_u32_e32 v39, v38, v39
	global_store_dword v39, v31, s[18:19]
	s_or_b64 exec, exec, s[42:43]
	v_cmp_gt_u32_e32 vcc, s24, v7
	s_and_saveexec_b64 s[42:43], vcc
	v_lshlrev_b32_e32 v39, 13, v7
	v_add_u32_e32 v39, v38, v39
	global_store_dword v39, v32, s[18:19]
	s_or_b64 exec, exec, s[42:43]
	v_cmp_gt_u32_e32 vcc, s24, v8
	s_and_saveexec_b64 s[42:43], vcc
	v_lshlrev_b32_e32 v39, 13, v8
	v_add_u32_e32 v39, v38, v39
	global_store_dword v39, v33, s[18:19]
	s_or_b64 exec, exec, s[42:43]
.Lend:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_grouped_down_m16n64_nolds_fp8_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 72
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 48
		.amdhsa_accum_offset 48
		.amdhsa_next_free_sgpr 44
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_moe_grouped_down_m16n64_nolds_fp8_gfx950, .Lfunc_end0-qwen36_moe_grouped_down_m16n64_nolds_fp8_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: inter_fp8, .offset: 0, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: inter_scale_f32, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: w2_fp8, .offset: 16, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: w2_scale_f32, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: sorted_token_ids_i32, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: sorted_expert_ids_i32, .offset: 40, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: num_valid_ids_i32, .offset: 48, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: partial_f32, .offset: 56, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: rows, .offset: 64, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 72
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_moe_grouped_down_m16n64_nolds_fp8_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 46
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_grouped_down_m16n64_nolds_fp8_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 48
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
