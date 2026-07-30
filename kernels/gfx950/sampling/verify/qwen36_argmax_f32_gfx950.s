// SPDX-License-Identifier: MIT
//
// Exact Qwen3.6 dFlash verification argmax for contiguous FP32
// [rows, 248320] logits.
//
// The deployed ATen reduction assigns one 512-thread workgroup to each row.
// That exposes only sixteen workgroups for the measured block-16 TP1 shape.
// This two-stage wave64 implementation assigns 128 chunks to every row:
//
//   stage 1: grid [128, rows], one wave64 per 1,940-float chunk
//   stage 2: grid [1, rows], one wave64 over 128 partial keys
//
// A lexicographic uint64 key reproduces ATen GreaterOrNan<float> ordering:
//   * NaN sorts above every ordered value;
//   * all NaNs share one value key, so the lowest index wins;
//   * -0 and +0 are normalized before ordering, so the lowest index wins;
//   * finite values and infinities follow IEEE numeric ordering;
//   * the low word is bitwise-not(index), making lower indices sort higher.
//
// The output is int64 because torch.argmax returns torch.long.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6

	.set QWEN36_ARGMAX_COLS, 248320
	.set QWEN36_ARGMAX_CHUNKS, 128
	.set QWEN36_ARGMAX_CHUNK_COLS, 1940

	// Select candidate (hi, lo) when its unsigned lexicographic key is larger
	// than the current best in v4:v5. Uses v12-v15 and vcc as temporaries.
	.macro SELECT_KEY candidate_hi:req, candidate_lo:req
	v_cmp_gt_u32_e32 vcc, \candidate_hi, v4
	v_cndmask_b32_e32 v12, 0, v51, vcc
	v_cmp_eq_u32_e32 vcc, \candidate_hi, v4
	v_cndmask_b32_e32 v13, 0, v51, vcc
	v_cmp_gt_u32_e32 vcc, \candidate_lo, v5
	v_cndmask_b32_e32 v14, 0, v51, vcc
	v_and_b32_e32 v14, v13, v14
	v_or_b32_e32 v15, v12, v14
	v_cmp_ne_u32_e32 vcc, 0, v15
	v_cndmask_b32_e32 v4, v4, \candidate_hi, vcc
	v_cndmask_b32_e32 v5, v5, \candidate_lo, vcc
	.endm

	// Convert one FP32 bit pattern and its uint32 column index into the exact
	// ATen argmax ordering key, then accumulate it into v4:v5.
	.macro UPDATE_VALUE value:req, index:req
	v_and_b32_e32 v6, s11, \value
	v_cmp_ne_u32_e32 vcc, 0, v6
	v_cndmask_b32_e32 v7, 0, \value, vcc
	v_ashrrev_i32_e32 v8, 31, v7
	v_or_b32_e32 v9, s13, v8
	v_xor_b32_e32 v10, v7, v9
	v_cmp_lt_u32_e32 vcc, s12, v6
	v_cndmask_b32_e32 v10, v10, v51, vcc
	v_not_b32_e32 v11, \index
	SELECT_KEY v10, v11
	.endm

	// Full-wave XOR reduction of the lexicographic key in v4:v5.
	.macro REDUCE_KEY_XOR distance:req
	v_xor_b32_e32 v48, \distance, v0
	v_lshlrev_b32_e32 v48, 2, v48
	ds_bpermute_b32 v49, v48, v4
	ds_bpermute_b32 v50, v48, v5
	s_waitcnt lgkmcnt(0)
	SELECT_KEY v49, v50
	.endm

	.text
	.protected qwen36_argmax_f32_stage1_gfx950
	.globl qwen36_argmax_f32_stage1_gfx950
	.p2align 8
	.type qwen36_argmax_f32_stage1_gfx950,@function
qwen36_argmax_f32_stage1_gfx950:
	// Kernargs: partial uint32 keys [rows,128,2], logits FP32.
	// Preserve workgroup IDs before loading pointers into the same SGPR range.
	s_mov_b32 s18, s2
	s_mov_b32 s19, s3
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_waitcnt lgkmcnt(0)

	// Global starting column = chunk_id * 1,940.
	s_mul_i32 s8, s18, QWEN36_ARGMAX_CHUNK_COLS
	// Global starting element = row * 248,320 + starting column.
	s_mul_i32 s9, s19, QWEN36_ARGMAX_COLS
	s_add_u32 s9, s9, s8
	s_lshl_b32 s10, s9, 2
	s_add_u32 s6, s6, s10
	s_addc_u32 s7, s7, 0

	// Partial output byte offset = (row * 128 + chunk) * 8.
	s_lshl_b32 s10, s19, 7
	s_add_u32 s10, s10, s18
	s_lshl_b32 s10, s10, 3
	s_add_u32 s4, s4, s10
	s_addc_u32 s5, s5, 0

	// Constants for float-key construction.
	s_mov_b32 s11, 0x7fffffff
	s_mov_b32 s12, 0x7f800000
	s_mov_b32 s13, 0x80000000

	// Each lane reads four adjacent floats in seven complete 256-float rounds.
	v_lshlrev_b32_e32 v1, 4, v0
	global_load_dwordx4 v[16:19], v1, s[6:7] offset:0
	global_load_dwordx4 v[20:23], v1, s[6:7] offset:1024
	global_load_dwordx4 v[24:27], v1, s[6:7] offset:2048
	global_load_dwordx4 v[28:31], v1, s[6:7] offset:3072
	s_add_u32 s6, s6, 4096
	s_addc_u32 s7, s7, 0
	global_load_dwordx4 v[32:35], v1, s[6:7] offset:0
	global_load_dwordx4 v[36:39], v1, s[6:7] offset:1024
	global_load_dwordx4 v[40:43], v1, s[6:7] offset:2048
	s_waitcnt vmcnt(0)

	// Sentinel is below the ordered key for negative infinity.
	v_mov_b32_e32 v51, -1
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, 0
	v_lshlrev_b32_e32 v2, 2, v0
	v_add_u32_e32 v2, s8, v2

	UPDATE_VALUE v16, v2
	v_add_u32_e32 v3, 1, v2
	UPDATE_VALUE v17, v3
	v_add_u32_e32 v3, 2, v2
	UPDATE_VALUE v18, v3
	v_add_u32_e32 v3, 3, v2
	UPDATE_VALUE v19, v3

	v_add_u32_e32 v2, 256, v2
	UPDATE_VALUE v20, v2
	v_add_u32_e32 v3, 1, v2
	UPDATE_VALUE v21, v3
	v_add_u32_e32 v3, 2, v2
	UPDATE_VALUE v22, v3
	v_add_u32_e32 v3, 3, v2
	UPDATE_VALUE v23, v3

	v_add_u32_e32 v2, 256, v2
	UPDATE_VALUE v24, v2
	v_add_u32_e32 v3, 1, v2
	UPDATE_VALUE v25, v3
	v_add_u32_e32 v3, 2, v2
	UPDATE_VALUE v26, v3
	v_add_u32_e32 v3, 3, v2
	UPDATE_VALUE v27, v3

	v_add_u32_e32 v2, 256, v2
	UPDATE_VALUE v28, v2
	v_add_u32_e32 v3, 1, v2
	UPDATE_VALUE v29, v3
	v_add_u32_e32 v3, 2, v2
	UPDATE_VALUE v30, v3
	v_add_u32_e32 v3, 3, v2
	UPDATE_VALUE v31, v3

	v_add_u32_e32 v2, 256, v2
	UPDATE_VALUE v32, v2
	v_add_u32_e32 v3, 1, v2
	UPDATE_VALUE v33, v3
	v_add_u32_e32 v3, 2, v2
	UPDATE_VALUE v34, v3
	v_add_u32_e32 v3, 3, v2
	UPDATE_VALUE v35, v3

	v_add_u32_e32 v2, 256, v2
	UPDATE_VALUE v36, v2
	v_add_u32_e32 v3, 1, v2
	UPDATE_VALUE v37, v3
	v_add_u32_e32 v3, 2, v2
	UPDATE_VALUE v38, v3
	v_add_u32_e32 v3, 3, v2
	UPDATE_VALUE v39, v3

	v_add_u32_e32 v2, 256, v2
	UPDATE_VALUE v40, v2
	v_add_u32_e32 v3, 1, v2
	UPDATE_VALUE v41, v3
	v_add_u32_e32 v3, 2, v2
	UPDATE_VALUE v42, v3
	v_add_u32_e32 v3, 3, v2
	UPDATE_VALUE v43, v3

	// The final round has exactly 148 values: lanes 0..36 each read four.
	v_cmp_gt_u32_e32 vcc, 37, v0
	s_and_saveexec_b64 s[14:15], vcc
	global_load_dwordx4 v[44:47], v1, s[6:7] offset:3072
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v2, 256, v2
	UPDATE_VALUE v44, v2
	v_add_u32_e32 v3, 1, v2
	UPDATE_VALUE v45, v3
	v_add_u32_e32 v3, 2, v2
	UPDATE_VALUE v46, v3
	v_add_u32_e32 v3, 3, v2
	UPDATE_VALUE v47, v3
	s_or_b64 exec, exec, s[14:15]

	REDUCE_KEY_XOR 1
	REDUCE_KEY_XOR 2
	REDUCE_KEY_XOR 4
	REDUCE_KEY_XOR 8
	REDUCE_KEY_XOR 16
	REDUCE_KEY_XOR 32

	v_cmp_eq_u32_e32 vcc, 0, v0
	s_and_saveexec_b64 s[14:15], vcc
	v_mov_b32_e32 v1, 0
	global_store_dwordx2 v1, v[4:5], s[4:5]
	s_waitcnt vmcnt(0)
	s_endpgm
.Lstage1_end:

	.text
	.protected qwen36_argmax_f32_stage2_gfx950
	.globl qwen36_argmax_f32_stage2_gfx950
	.p2align 8
	.type qwen36_argmax_f32_stage2_gfx950,@function
qwen36_argmax_f32_stage2_gfx950:
	// Kernargs: output int64 [rows], partial uint32 keys [rows,128,2].
	s_mov_b32 s18, s3
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_waitcnt lgkmcnt(0)

	// Advance partials by row * 1,024 bytes and output by row * 8.
	s_lshl_b32 s8, s18, 10
	s_add_u32 s6, s6, s8
	s_addc_u32 s7, s7, 0
	s_lshl_b32 s8, s18, 3
	s_add_u32 s4, s4, s8
	s_addc_u32 s5, s5, 0

	v_lshlrev_b32_e32 v1, 3, v0
	global_load_dwordx2 v[4:5], v1, s[6:7] offset:0
	global_load_dwordx2 v[6:7], v1, s[6:7] offset:512
	s_waitcnt vmcnt(0)
	v_mov_b32_e32 v51, -1
	SELECT_KEY v6, v7

	REDUCE_KEY_XOR 1
	REDUCE_KEY_XOR 2
	REDUCE_KEY_XOR 4
	REDUCE_KEY_XOR 8
	REDUCE_KEY_XOR 16
	REDUCE_KEY_XOR 32

	v_cmp_eq_u32_e32 vcc, 0, v0
	s_and_saveexec_b64 s[14:15], vcc
	v_not_b32_e32 v8, v5
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v1, 0
	global_store_dwordx2 v1, v[8:9], s[4:5]
	s_waitcnt vmcnt(0)
	s_endpgm
.Lstage2_end:

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_argmax_f32_stage1_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 16
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 52
		.amdhsa_accum_offset 52
		.amdhsa_next_free_sgpr 20
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel

	.p2align 6, 0
	.amdhsa_kernel qwen36_argmax_f32_stage2_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 16
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 52
		.amdhsa_accum_offset 52
		.amdhsa_next_free_sgpr 20
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel

	.size qwen36_argmax_f32_stage1_gfx950, .Lstage1_end-qwen36_argmax_f32_stage1_gfx950
	.size qwen36_argmax_f32_stage2_gfx950, .Lstage2_end-qwen36_argmax_f32_stage2_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: partial_keys_u32, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: logits_f32, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 64
    .name: qwen36_argmax_f32_stage1_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 20
    .sgpr_spill_count: 0
    .symbol: qwen36_argmax_f32_stage1_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 52
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .args:
      - { .name: output_i64, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: partial_keys_u32, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 64
    .name: qwen36_argmax_f32_stage2_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 20
    .sgpr_spill_count: 0
    .symbol: qwen36_argmax_f32_stage2_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 52
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
