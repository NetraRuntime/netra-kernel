// SPDX-License-Identifier: MIT
//
// DeepSeek-V4 DSpARK target-verification metadata expansion for gfx950.
// Every lane writes one int32 causal length and one int64 request-pool index.
// A null extend_start_locs pointer selects either static DSpARK width: five
// draft-verification tokens or six target-verification tokens per request.
// Otherwise a nine-step upper-bound search covers ragged batches up to 256
// requests. Padded tokens inherit the final request-pool index and receive
// causal length one.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected dsv4_dspark_expand_metadata_gfx950
	.globl dsv4_dspark_expand_metadata_gfx950
	.p2align 8
	.type dsv4_dspark_expand_metadata_gfx950,@function
dsv4_dspark_expand_metadata_gfx950:
	// Kernargs: causal out, request out, request pool, sequence lengths,
	// extension lengths, optional extension starts, batch, real tokens, total.
	// Preserve workgroup X before pointer loads reuse s2.
	s_mov_b32 s20, s2
	s_load_dwordx4 s[4:7], s[0:1], 0
	s_load_dwordx4 s[8:11], s[0:1], 16
	s_load_dwordx4 s[12:15], s[0:1], 32
	s_load_dwordx2 s[16:17], s[0:1], 48
	s_load_dwordx2 s[18:19], s[0:1], 56
	s_waitcnt lgkmcnt(0)

	// Global token index: workgroup * 256 + workitem.
	s_lshl_b32 s21, s20, 8
	v_add_u32_e32 v1, s21, v0
	v_cmp_gt_u32_e64 vcc, s18, v1
	s_and_b64 exec, exec, vcc
	s_cbranch_execz .Lend
	s_mov_b64 s[26:27], exec

	// Partition the workgroup into real and padded token masks. Scalar control
	// flow is safe only after the per-lane masks have updated exec.
	v_cmp_lt_u32_e64 vcc, v1, s17
	s_mov_b64 s[28:29], vcc
	s_and_b64 exec, s[26:27], s[28:29]
	s_cbranch_execz .Lafter_real

	// Null starts selects a static DSpARK width passed in s19. Both exact widths
	// use multiply-high division and avoid scalar metadata scans.
	s_or_b32 s21, s14, s15
	s_cmp_eq_u32 s21, 0
	s_cbranch_scc0 .Lragged
	s_cmp_eq_u32 s19, 5
	s_cbranch_scc0 .Luniform_six
	v_mov_b32_e32 v2, 0xcccccccd
	v_mul_hi_u32 v2, v1, v2
	v_lshrrev_b32_e32 v2, 2, v2
	v_mul_u32_u24 v3, 5, v2
	s_branch .Lload_real
.Luniform_six:
	v_mov_b32_e32 v2, 0xaaaaaaab
	v_mul_hi_u32 v2, v1, v2
	v_lshrrev_b32_e32 v2, 2, v2
	v_mul_u32_u24 v3, 6, v2
	s_branch .Lload_real

.Lragged:
	// Per-lane upper_bound(extend_start_locs, token), with [lo, hi) in v2:v3.
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, s16
	v_mov_b32_e32 v9, s16
	.rept 9
		v_add_u32_e32 v4, v2, v3
		v_lshrrev_b32_e32 v4, 1, v4
		v_add_u32_e32 v5, -1, v9
		v_min_u32_e32 v5, v4, v5
		v_lshlrev_b32_e32 v5, 2, v5
		global_load_dword v6, v5, s[14:15]
		s_waitcnt vmcnt(0)
		v_cmp_lt_u32_e32 vcc, v4, v9
		s_mov_b64 s[24:25], vcc
		v_cmp_ge_u32_e32 vcc, v1, v6
		s_and_b64 vcc, vcc, s[24:25]
		v_add_u32_e32 v5, 1, v4
		v_cndmask_b32_e32 v3, v4, v3, vcc
		v_cndmask_b32_e32 v2, v2, v5, vcc
	.endr
	v_add_u32_e32 v2, -1, v2
	v_lshlrev_b32_e32 v5, 2, v2
	global_load_dword v3, v5, s[14:15]
	s_waitcnt vmcnt(0)

.Lload_real:
	// v2=request, v3=start. Sequence lengths and request-pool indices are int64;
	// extension lengths are int32. Serving lengths are bounded below 2^32, so
	// only the low sequence-length dword is required.
	v_lshlrev_b32_e32 v4, 2, v2
	global_load_dword v6, v4, s[12:13]
	v_lshlrev_b32_e32 v10, 3, v2
	global_load_dword v5, v10, s[10:11]
	global_load_dwordx2 v[8:9], v10, s[8:9]
	s_waitcnt vmcnt(0)
	v_sub_u32_e32 v5, v5, v6
	v_add_u32_e32 v5, 1, v5
	v_sub_u32_e32 v6, v1, v3
	v_add_u32_e32 v5, v5, v6
	v_lshlrev_b32_e32 v4, 2, v1
	v_lshlrev_b32_e32 v10, 3, v1
	global_store_dword v4, v5, s[4:5]
	global_store_dwordx2 v10, v[8:9], s[6:7]
	s_waitcnt vmcnt(0)

.Lafter_real:
	// Padded outputs avoid all input reads except req_pool[batch - 1].
	s_andn2_b64 exec, s[26:27], s[28:29]
	s_cbranch_execz .Lend
	v_mov_b32_e32 v2, s16
	v_add_u32_e32 v2, -1, v2
	v_lshlrev_b32_e32 v2, 3, v2
	global_load_dwordx2 v[8:9], v2, s[8:9]
	v_mov_b32_e32 v5, 1
	s_waitcnt vmcnt(0)
	v_lshlrev_b32_e32 v4, 2, v1
	v_lshlrev_b32_e32 v10, 3, v1
	global_store_dword v4, v5, s[4:5]
	global_store_dwordx2 v10, v[8:9], s[6:7]
	s_waitcnt vmcnt(0)
.Lend:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel dsv4_dspark_expand_metadata_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 64
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 11
		.amdhsa_accum_offset 12
		.amdhsa_next_free_sgpr 30
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size dsv4_dspark_expand_metadata_gfx950, .Lfunc_end0-dsv4_dspark_expand_metadata_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: seq_lens_causal_i32, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: req_pool_repeated_i64, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: req_pool_i64, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: seq_lens_i64, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: extend_lens_i32, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: extend_starts_i32, .offset: 40, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: batch, .offset: 48, .size: 4, .value_kind: by_value }
      - { .name: real_tokens, .offset: 52, .size: 4, .value_kind: by_value }
      - { .name: total_tokens, .offset: 56, .size: 4, .value_kind: by_value }
      - { .name: uniform_width, .offset: 60, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 64
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: dsv4_dspark_expand_metadata_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 30
    .sgpr_spill_count: 0
    .symbol: dsv4_dspark_expand_metadata_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 11
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
