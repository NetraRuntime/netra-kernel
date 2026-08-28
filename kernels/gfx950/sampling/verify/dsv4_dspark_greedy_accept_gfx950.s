// SPDX-License-Identifier: MIT
//
// DeepSeek-V4 DSpARK greedy-accept epilogue for gfx950.
// One lane owns one request.  The deployed geometry is fixed at five draft
// tokens and six target predictions.  The kernel folds the generic
// eq/cast/cumprod/sum/index chain, verify-length cap, accept-length finalize,
// output-token construction, persistent-buffer copies, and the fixed
// DeepSeek-V4 unified-SWA injection layout into one dispatch.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected dsv4_dspark_greedy_accept_gfx950
	.globl dsv4_dspark_greedy_accept_gfx950
	.p2align 8
	.type dsv4_dspark_greedy_accept_gfx950,@function
dsv4_dspark_greedy_accept_gfx950:
	// Outputs: correct i64, bonus i64, trim i32, commit i32,
	// new sequence length i64, output tokens i64 [batch,6].
	// Inputs: draft tokens i64 [batch,5], target predictions i64 [batch,6],
	// verify lengths i64, prefix lengths i64, batch u32.
	s_load_dwordx4 s[4:7], s[0:1], 0
	s_load_dwordx4 s[8:11], s[0:1], 16
	s_load_dwordx4 s[12:15], s[0:1], 32
	s_load_dwordx4 s[16:19], s[0:1], 48
	s_load_dwordx4 s[20:23], s[0:1], 64
	s_load_dwordx4 s[24:27], s[0:1], 80
	s_load_dwordx2 s[28:29], s[0:1], 96
	s_mov_b32 s30, 0xf6603d99
	s_waitcnt lgkmcnt(0)

	// Exactly one workgroup is launched.  Mask lanes above the live batch.
	v_cmp_gt_u32_e64 vcc, s24, v0
	s_and_b64 exec, exec, vcc
	s_cbranch_execz .Lend

	// Byte offsets for [b,5], [b,6], int64 vectors, and int32 vectors.
	v_mul_u32_u24 v1, 40, v0
	v_mul_u32_u24 v2, 48, v0
	v_lshlrev_b32_e32 v3, 3, v0
	v_lshlrev_b32_e32 v4, 2, v0

	// Serving token IDs fit in the low int64 dword.  Load five proposals and
	// all six target predictions, plus verify/prefix lengths.
	global_load_dword v5, v1, s[16:17] offset:0
	global_load_dword v6, v1, s[16:17] offset:8
	global_load_dword v7, v1, s[16:17] offset:16
	global_load_dword v8, v1, s[16:17] offset:24
	global_load_dword v9, v1, s[16:17] offset:32
	global_load_dword v10, v2, s[18:19] offset:0
	global_load_dword v11, v2, s[18:19] offset:8
	global_load_dword v12, v2, s[18:19] offset:16
	global_load_dword v13, v2, s[18:19] offset:24
	global_load_dword v14, v2, s[18:19] offset:32
	global_load_dword v15, v2, s[18:19] offset:40
	global_load_dword v16, v3, s[20:21]
	global_load_dwordx2 v[18:19], v3, s[22:23]
	global_load_dword v34, v3, s[26:27]
	s_waitcnt vmcnt(0)

	// Count the consecutive prefix of draft[k] == target[k].  Once any
	// mismatch appears, the accumulated XOR remains nonzero.
	v_xor_b32_e32 v21, v5, v10
	v_mov_b32_e32 v20, 0
	v_cmp_eq_u32_e32 vcc, 0, v21
	v_mov_b32_e32 v24, 1
	v_cndmask_b32_e32 v20, v20, v24, vcc
	v_xor_b32_e32 v23, v6, v11
	v_or_b32_e32 v21, v21, v23
	v_cmp_eq_u32_e32 vcc, 0, v21
	v_mov_b32_e32 v24, 2
	v_cndmask_b32_e32 v20, v20, v24, vcc
	v_xor_b32_e32 v23, v7, v12
	v_or_b32_e32 v21, v21, v23
	v_cmp_eq_u32_e32 vcc, 0, v21
	v_mov_b32_e32 v24, 3
	v_cndmask_b32_e32 v20, v20, v24, vcc
	v_xor_b32_e32 v23, v8, v13
	v_or_b32_e32 v21, v21, v23
	v_cmp_eq_u32_e32 vcc, 0, v21
	v_mov_b32_e32 v24, 4
	v_cndmask_b32_e32 v20, v20, v24, vcc
	v_xor_b32_e32 v23, v9, v14
	v_or_b32_e32 v21, v21, v23
	v_cmp_eq_u32_e32 vcc, 0, v21
	v_mov_b32_e32 v24, 5
	v_cndmask_b32_e32 v20, v20, v24, vcc

	// Cap to verify_len-1, matching CapCorrectLen.  Clamp padded rows at zero;
	// live serving rows have verify_len in [1,6].
	v_mov_b32_e32 v22, v20
	v_add_u32_e32 v21, -1, v16
	v_max_i32_e32 v21, 0, v21
	v_min_i32_e32 v20, v20, v21
	v_sub_u32_e32 v23, v22, v20
	v_add_u32_e32 v24, 1, v20

	// Bonus is target[capped_correct_len].
	v_mov_b32_e32 v25, v10
	v_cmp_eq_u32_e32 vcc, 1, v20
	v_cndmask_b32_e32 v25, v25, v11, vcc
	v_cmp_eq_u32_e32 vcc, 2, v20
	v_cndmask_b32_e32 v25, v25, v12, vcc
	v_cmp_eq_u32_e32 vcc, 3, v20
	v_cndmask_b32_e32 v25, v25, v13, vcc
	v_cmp_eq_u32_e32 vcc, 4, v20
	v_cndmask_b32_e32 v25, v25, v14, vcc
	v_cmp_eq_u32_e32 vcc, 5, v20
	v_cndmask_b32_e32 v25, v25, v15, vcc

	// new_seq_lens = prefix_lens + commit_lens.  Context is bounded below
	// 2^32 in this serving ABI, so the high prefix dword is unchanged.
	v_add_u32_e32 v26, v18, v24

	// Persistent scalar outputs.  v27 is the zero high dword for token IDs and
	// small counts.  The prefix high dword is retained for new_seq_lens.
	v_mov_b32_e32 v27, 0
	global_store_dword v3, v20, s[4:5] offset:0
	global_store_dword v3, v27, s[4:5] offset:4
	global_store_dword v3, v25, s[6:7] offset:0
	global_store_dword v3, v27, s[6:7] offset:4
	global_store_dword v4, v23, s[8:9]
	global_store_dword v4, v24, s[10:11]
	global_store_dword v3, v26, s[12:13] offset:0
	global_store_dword v3, v19, s[12:13] offset:4

	// Build [draft0..draft4, 0], replacing column correct_len with bonus.
	v_cmp_eq_u32_e32 vcc, 0, v20
	v_cndmask_b32_e32 v28, v5, v25, vcc
	v_cmp_eq_u32_e32 vcc, 1, v20
	v_cndmask_b32_e32 v29, v6, v25, vcc
	v_cmp_eq_u32_e32 vcc, 2, v20
	v_cndmask_b32_e32 v30, v7, v25, vcc
	v_cmp_eq_u32_e32 vcc, 3, v20
	v_cndmask_b32_e32 v31, v8, v25, vcc
	v_cmp_eq_u32_e32 vcc, 4, v20
	v_cndmask_b32_e32 v32, v9, v25, vcc
	v_cmp_eq_u32_e32 vcc, 5, v20
	v_cndmask_b32_e32 v33, v27, v25, vcc
	global_store_dword v2, v28, s[14:15] offset:0
	global_store_dword v2, v27, s[14:15] offset:4
	global_store_dword v2, v29, s[14:15] offset:8
	global_store_dword v2, v27, s[14:15] offset:12
	global_store_dword v2, v30, s[14:15] offset:16
	global_store_dword v2, v27, s[14:15] offset:20
	global_store_dword v2, v31, s[14:15] offset:24
	global_store_dword v2, v27, s[14:15] offset:28
	global_store_dword v2, v32, s[14:15] offset:32
	global_store_dword v2, v27, s[14:15] offset:36
	global_store_dword v2, v33, s[14:15] offset:40
	global_store_dword v2, v27, s[14:15] offset:44

	// Unified-SWA layout for this checkpoint is fixed at a 128-token window
	// plus five speculative slots: ring=133.  For prefix positions (<2^16),
	// floor(x/133) = (mul_hi(x, 0xf6603d99) >> 7) exactly.  Generate the six
	// consecutive ring locations and gate columns at commit_len, matching
	// TargetHiddenKvInjector._unified_inject_loc.
	v_mul_hi_u32 v35, s30, v18
	v_lshrrev_b32_e32 v35, 7, v35
	v_mul_u32_u24 v35, 133, v35
	v_sub_u32_e32 v36, v18, v35
	v_mul_u32_u24 v37, 133, v34
	v_lshrrev_b32_e32 v38, 1, v2

	v_add_u32_e32 v39, v37, v36
	v_cmp_lt_u32_e32 vcc, 0, v24
	v_cndmask_b32_e32 v39, -1, v39, vcc
	global_store_dword v38, v39, s[28:29] offset:0
	v_add_u32_e32 v36, 1, v36
	v_cmp_eq_u32_e32 vcc, 133, v36
	v_cndmask_b32_e32 v36, v36, v27, vcc
	v_add_u32_e32 v39, v37, v36
	v_cmp_lt_u32_e32 vcc, 1, v24
	v_cndmask_b32_e32 v39, -1, v39, vcc
	global_store_dword v38, v39, s[28:29] offset:4
	v_add_u32_e32 v36, 1, v36
	v_cmp_eq_u32_e32 vcc, 133, v36
	v_cndmask_b32_e32 v36, v36, v27, vcc
	v_add_u32_e32 v39, v37, v36
	v_cmp_lt_u32_e32 vcc, 2, v24
	v_cndmask_b32_e32 v39, -1, v39, vcc
	global_store_dword v38, v39, s[28:29] offset:8
	v_add_u32_e32 v36, 1, v36
	v_cmp_eq_u32_e32 vcc, 133, v36
	v_cndmask_b32_e32 v36, v36, v27, vcc
	v_add_u32_e32 v39, v37, v36
	v_cmp_lt_u32_e32 vcc, 3, v24
	v_cndmask_b32_e32 v39, -1, v39, vcc
	global_store_dword v38, v39, s[28:29] offset:12
	v_add_u32_e32 v36, 1, v36
	v_cmp_eq_u32_e32 vcc, 133, v36
	v_cndmask_b32_e32 v36, v36, v27, vcc
	v_add_u32_e32 v39, v37, v36
	v_cmp_lt_u32_e32 vcc, 4, v24
	v_cndmask_b32_e32 v39, -1, v39, vcc
	global_store_dword v38, v39, s[28:29] offset:16
	v_add_u32_e32 v36, 1, v36
	v_cmp_eq_u32_e32 vcc, 133, v36
	v_cndmask_b32_e32 v36, v36, v27, vcc
	v_add_u32_e32 v39, v37, v36
	v_cmp_lt_u32_e32 vcc, 5, v24
	v_cndmask_b32_e32 v39, -1, v39, vcc
	global_store_dword v38, v39, s[28:29] offset:20
	s_waitcnt vmcnt(0)
.Lend:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel dsv4_dspark_greedy_accept_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 104
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 40
		.amdhsa_accum_offset 40
		.amdhsa_next_free_sgpr 31
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size dsv4_dspark_greedy_accept_gfx950, .Lfunc_end0-dsv4_dspark_greedy_accept_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: correct_i64, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: bonus_i64, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: trim_i32, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: commit_i32, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: new_seq_i64, .offset: 32, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: out_tokens_i64, .offset: 40, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: draft_tokens_i64, .offset: 48, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: target_predict_i64, .offset: 56, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: verify_lens_i64, .offset: 64, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: prefix_lens_i64, .offset: 72, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: batch, .offset: 80, .size: 4, .value_kind: by_value }
      - { .name: req_slots_i64, .offset: 88, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: swa_loc_i32, .offset: 96, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 104
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: dsv4_dspark_greedy_accept_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 31
    .sgpr_spill_count: 0
    .symbol: dsv4_dspark_greedy_accept_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 40
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
