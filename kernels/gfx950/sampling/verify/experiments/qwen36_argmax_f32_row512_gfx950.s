// SPDX-License-Identifier: MIT
//
// Exact large-batch Qwen3.6 dFlash verification argmax for contiguous FP32
// [rows, 248320] logits. One 512-thread workgroup owns one row. Eight wave64s
// scan 2,048 contiguous values per round, reduce within each wave, exchange
// eight keys through LDS, and emit one int64 index.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6

	.set QWEN36_ARGMAX_COLS, 248320
	.set QWEN36_ARGMAX_ROW_BYTES, 993280

	// Convert one FP32 bit pattern to the unsigned value-order key used by the
	// accepted two-stage kernel. Local indices are strictly increasing, so an
	// equal value never replaces the earlier index within a lane.
	.macro UPDATE_LOCAL_VALUE value:req, index:req
	v_and_b32_e32 v7, s11, \value
	v_cmp_ne_u32_e32 vcc, 0, v7
	v_cndmask_b32_e32 v8, 0, \value, vcc
	v_ashrrev_i32_e32 v9, 31, v8
	v_or_b32_e32 v10, s13, v9
	v_xor_b32_e32 v10, v8, v10
	v_cmp_lt_u32_e32 vcc, s12, v7
	v_cndmask_b32_e32 v10, v10, v51, vcc
	v_cmp_gt_u32_e32 vcc, v10, v4
	v_cndmask_b32_e32 v4, v4, v10, vcc
	v_cndmask_b32_e32 v5, v5, \index, vcc
	.endm

	// Select candidate (hi, lo) when its unsigned lexicographic key is larger.
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

	.macro REDUCE_KEY_XOR distance:req
	v_xor_b32_e32 v48, \distance, v1
	v_lshlrev_b32_e32 v48, 2, v48
	ds_bpermute_b32 v49, v48, v4
	ds_bpermute_b32 v50, v48, v5
	s_waitcnt lgkmcnt(0)
	SELECT_KEY v49, v50
	.endm

	.text
	.protected qwen36_argmax_f32_row512_gfx950
	.globl qwen36_argmax_f32_row512_gfx950
	.p2align 8
	.type qwen36_argmax_f32_row512_gfx950,@function
qwen36_argmax_f32_row512_gfx950:
	// Kernargs: output int64 [rows], logits FP32 [rows,248320]. With only
	// workgroup-id-y enabled, s2 is the row ID.
	s_mov_b32 s18, s2
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_waitcnt lgkmcnt(0)

	// Advance global pointers to this row.
	s_mul_i32 s8, s18, QWEN36_ARGMAX_ROW_BYTES
	s_add_u32 s6, s6, s8
	s_addc_u32 s7, s7, 0
	s_lshl_b32 s9, s18, 3
	s_add_u32 s4, s4, s9
	s_addc_u32 s5, s5, 0

	// Lane/wave decomposition. Each wave starts at a distinct 256-value panel.
	v_and_b32_e32 v1, 63, v0
	v_lshrrev_b32_e32 v2, 6, v0
	v_readfirstlane_b32 s14, v2
	v_lshlrev_b32_e32 v3, 10, v2
	v_lshlrev_b32_e32 v6, 4, v1
	v_add_u32_e32 v3, v3, v6
	v_lshlrev_b32_e32 v6, 8, v2
	v_lshlrev_b32_e32 v20, 2, v1
	v_add_u32_e32 v6, v6, v20

	// Constants and below-negative-infinity sentinel.
	s_mov_b32 s11, 0x7fffffff
	s_mov_b32 s12, 0x7f800000
	s_mov_b32 s13, 0x80000000
	v_mov_b32_e32 v51, -1
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, 0
	s_mov_b32 s10, 0

.Lrow_round:
	global_load_dwordx4 v[16:19], v3, s[6:7]
	s_waitcnt vmcnt(0)
	UPDATE_LOCAL_VALUE v16, v6
	v_add_u32_e32 v20, 1, v6
	UPDATE_LOCAL_VALUE v17, v20
	v_add_u32_e32 v20, 2, v6
	UPDATE_LOCAL_VALUE v18, v20
	v_add_u32_e32 v20, 3, v6
	UPDATE_LOCAL_VALUE v19, v20
	v_add_u32_e32 v3, 8192, v3
	v_add_u32_e32 v6, 2048, v6
	s_add_u32 s10, s10, 1
	s_cmp_lt_u32 s10, 121
	s_cbranch_scc1 .Lrow_round

	// 121 rounds cover 247,808 values. Waves 0 and 1 cover the exact
	// remaining 512 values without masked global memory accesses.
	s_cmp_lt_u32 s14, 2
	s_cbranch_scc0 .Lrow_local_done
	global_load_dwordx4 v[16:19], v3, s[6:7]
	s_waitcnt vmcnt(0)
	UPDATE_LOCAL_VALUE v16, v6
	v_add_u32_e32 v20, 1, v6
	UPDATE_LOCAL_VALUE v17, v20
	v_add_u32_e32 v20, 2, v6
	UPDATE_LOCAL_VALUE v18, v20
	v_add_u32_e32 v20, 3, v6
	UPDATE_LOCAL_VALUE v19, v20

.Lrow_local_done:
	// Add the index tie-break key once, then reduce the 64 lane keys.
	v_not_b32_e32 v5, v5
	REDUCE_KEY_XOR 1
	REDUCE_KEY_XOR 2
	REDUCE_KEY_XOR 4
	REDUCE_KEY_XOR 8
	REDUCE_KEY_XOR 16
	REDUCE_KEY_XOR 32

	// Lane zero of each wave publishes one 64-bit key to LDS.
	v_cmp_eq_u32_e32 vcc, 0, v1
	s_and_saveexec_b64 s[16:17], vcc
	v_lshlrev_b32_e32 v6, 3, v2
	ds_write_b64 v6, v[4:5]
	s_or_b64 exec, exec, s[16:17]
	s_waitcnt lgkmcnt(0)
	s_barrier

	// Only wave zero performs the final eight-key reduction.
	s_cmp_eq_u32 s14, 0
	s_cbranch_scc0 .Lrow_end
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, 0
	v_lshlrev_b32_e32 v6, 3, v1
	v_cmp_gt_u32_e32 vcc, 8, v1
	s_and_saveexec_b64 s[16:17], vcc
	ds_read_b64 v[4:5], v6
	s_waitcnt lgkmcnt(0)
	s_or_b64 exec, exec, s[16:17]
	REDUCE_KEY_XOR 1
	REDUCE_KEY_XOR 2
	REDUCE_KEY_XOR 4
	REDUCE_KEY_XOR 8
	REDUCE_KEY_XOR 16
	REDUCE_KEY_XOR 32

	v_cmp_eq_u32_e32 vcc, 0, v1
	s_and_saveexec_b64 s[16:17], vcc
	v_not_b32_e32 v8, v5
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v6, 0
	global_store_dwordx2 v6, v[8:9], s[4:5]
	s_waitcnt vmcnt(0)
.Lrow_end:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_argmax_f32_row512_gfx950
		.amdhsa_group_segment_fixed_size 64
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 16
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 0
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 52
		.amdhsa_accum_offset 52
		.amdhsa_next_free_sgpr 20
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
	.size qwen36_argmax_f32_row512_gfx950, .Lfunc_end0-qwen36_argmax_f32_row512_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: output_i64, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: logits_f32, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
    .group_segment_fixed_size: 64
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 512
    .name: qwen36_argmax_f32_row512_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 20
    .sgpr_spill_count: 0
    .symbol: qwen36_argmax_f32_row512_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 52
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
