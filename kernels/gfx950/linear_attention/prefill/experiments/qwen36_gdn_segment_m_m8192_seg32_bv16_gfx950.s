// SPDX-License-Identifier: MIT
//
// Exact homogeneous segment summaries for Qwen3.6 GDN on gfx950.
// B1/T8192/H32/Hg16/K=V=128/BT64, four 32-chunk segments, wave64.
// Grid=(4*8,32,1), block=(256,1,1), LDS=20480 bytes.
//
// For state S[V,K], one chunk is
//   S' = H_chunk + S * (d*I - W^T*diag(e)*K).
// This kernel initializes S=I and U=0, then executes the deployed recurrence
// for 32 chunks.  Its output is the exact homogeneous segment transition M.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text

	.macro STORE_STATE_LDS TILE, RR, REG
	v_lshlrev_b32_e32 v40, 5, v4
	v_add_u32_e32 v40, (\TILE*16), v40
	v_lshlrev_b32_e32 v41, 2, v5
	v_add_u32_e32 v40, v41, v40
	v_add_u32_e32 v40, \RR, v40
	v_lshlrev_b32_e32 v40, 1, v40
	v_lshlrev_b32_e32 v41, 8, v2
	v_add_u32_e32 v40, v41, v40
	v_cvt_pk_bf16_f32 v42, v[\REG], v[\REG]
	s_nop 4
	ds_write_b16 v40, v42
	// Preserve the FP32 transition across chunks as a BF16 hi+lo pair.  A
	// single BF16 projection accumulates unacceptable error for M over 32
	// chunks even though the ordinary state path tolerates it.
	v_lshlrev_b32_e32 v43, 16, v42
	v_sub_f32_e32 v43, v[\REG], v43
	v_cvt_pk_bf16_f32 v43, v43, v43
	s_nop 4
	ds_write_b16 v40, v43 offset:4096
	.endm

	.macro INIT_IDENTITY REG, KOFF
	v_lshlrev_b32_e32 v40, 4, v7
	v_add_u32_e32 v40, v2, v40
	v_lshlrev_b32_e32 v41, 5, v4
	v_lshlrev_b32_e32 v42, 2, v5
	v_add_u32_e32 v41, v42, v41
	v_add_u32_e32 v41, \KOFF, v41
	v_cmp_eq_u32_e32 vcc, v40, v41
	v_mov_b32_e32 v42, 0x3f800000
	v_cndmask_b32_e32 v[\REG], 0, v42, vcc
	.endm

	.macro STATE_UPDATE TILE, KT, ACC
	// K^T A operand: fixed K output row, eight token-reduction values.
	v_lshlrev_b32_e32 v40, 5, v4
	v_add_u32_e32 v40, (\TILE*16), v40
	v_add_u32_e32 v40, v2, v40
	v_lshlrev_b32_e32 v40, 1, v40
	v_lshlrev_b32_e32 v41, 7, v3
	v_add_u32_e32 v40, v41, v40
	v_add_u32_e32 v40, (\KT*8192), v40
	ds_read_u16 v8, v40 offset:0
	ds_read_u16 v9, v40 offset:256
	ds_read_u16 v10, v40 offset:512
	ds_read_u16 v11, v40 offset:768
	ds_read_u16 v12, v40 offset:1024
	ds_read_u16 v13, v40 offset:1280
	ds_read_u16 v14, v40 offset:1536
	ds_read_u16 v15, v40 offset:1792
	// Weighted v_new B operand at LDS+16384.
	v_lshlrev_b32_e32 v42, 4, v3
	v_lshlrev_b32_e32 v43, 1, v2
	v_add_u32_e32 v42, v43, v42
	v_add_u32_e32 v42, (16384+\KT*1024), v42
	ds_read_u16 v24, v42 offset:0
	ds_read_u16 v25, v42 offset:32
	ds_read_u16 v26, v42 offset:64
	ds_read_u16 v27, v42 offset:96
	ds_read_u16 v28, v42 offset:128
	ds_read_u16 v29, v42 offset:160
	ds_read_u16 v30, v42 offset:192
	ds_read_u16 v31, v42 offset:224
	s_waitcnt lgkmcnt(0)
	v_lshl_or_b32 v16, v9, 16, v8
	v_lshl_or_b32 v17, v11, 16, v10
	v_lshl_or_b32 v18, v13, 16, v12
	v_lshl_or_b32 v19, v15, 16, v14
	v_lshl_or_b32 v20, v25, 16, v24
	v_lshl_or_b32 v21, v27, 16, v26
	v_lshl_or_b32 v22, v29, 16, v28
	v_lshl_or_b32 v23, v31, 16, v30
	s_nop 4
	v_mfma_f32_16x16x32_bf16 v[\ACC:\ACC+3], v[16:19], v[20:23], v[\ACC:\ACC+3]
	s_nop 8
	// Low BF16 residual of the FP32 weighted v_new.
	ds_read_u16 v24, v42 offset:2048
	ds_read_u16 v25, v42 offset:2080
	ds_read_u16 v26, v42 offset:2112
	ds_read_u16 v27, v42 offset:2144
	ds_read_u16 v28, v42 offset:2176
	ds_read_u16 v29, v42 offset:2208
	ds_read_u16 v30, v42 offset:2240
	ds_read_u16 v31, v42 offset:2272
	s_waitcnt lgkmcnt(0)
	v_lshl_or_b32 v20, v25, 16, v24
	v_lshl_or_b32 v21, v27, 16, v26
	v_lshl_or_b32 v22, v29, 16, v28
	v_lshl_or_b32 v23, v31, 16, v30
	s_nop 4
	v_mfma_f32_16x16x32_bf16 v[\ACC:\ACC+3], v[16:19], v[20:23], v[\ACC:\ACC+3]
	s_nop 8
	.endm

	.protected qwen36_gdn_segment_m_m8192_seg32_bv16_gfx950
	.globl qwen36_gdn_segment_m_m8192_seg32_bv16_gfx950
	.p2align 8
	.type qwen36_gdn_segment_m_m8192_seg32_bv16_gfx950,@function
qwen36_gdn_segment_m_m8192_seg32_bv16_gfx950:
	// k, w, g, m_out, chunks_per_segment.
	s_load_dwordx2 s[8:9], s[0:1], 0
	s_load_dwordx2 s[10:11], s[0:1], 8
	s_load_dwordx2 s[12:13], s[0:1], 16
	s_load_dwordx2 s[14:15], s[0:1], 24
	s_load_dword s20, s[0:1], 32
	s_waitcnt lgkmcnt(0)

	// workgroup-x = segment*8 + V16 tile.
	s_lshr_b32 s21, s2, 3
	s_and_b32 s2, s2, 7
	v_mov_b32_e32 v7, s2
	v_and_b32_e32 v1, 63, v0
	v_and_b32_e32 v2, 15, v0
	v_and_b32_e32 v3, 48, v0
	v_lshrrev_b32_e32 v4, 6, v0
	v_lshrrev_b32_e32 v5, 4, v1

	// Segment-local input bases and segment/head/V16 output base.
	s_lshr_b32 s22, s3, 1
	s_lshl_b32 s31, s22, 8
	s_lshl_b32 s23, s21, 23
	s_add_u32 s31, s31, s23              // K: segment * 32*64*16*128*2
	s_lshl_b32 s32, s3, 8
	s_lshl_b32 s23, s21, 24
	s_add_u32 s32, s32, s23              // W: segment * 32*64*32*128*2
	s_lshl_b32 s34, s3, 2
	s_lshl_b32 s23, s21, 18
	s_add_u32 s34, s34, s23              // g: segment * 32*64*32*4
	s_lshl_b32 s26, s21, 20
	s_lshl_b32 s27, s3, 15
	s_add_u32 s26, s26, s27
	s_lshl_b32 s27, s2, 12
	s_add_u32 s26, s26, s27              // M[segment,head,V16,K]

	// Identity transition in the same FP32 register distribution as live state.
	INIT_IDENTITY 64, 0
	INIT_IDENTITY 65, 1
	INIT_IDENTITY 66, 2
	INIT_IDENTITY 67, 3
	INIT_IDENTITY 68, 16
	INIT_IDENTITY 69, 17
	INIT_IDENTITY 70, 18
	INIT_IDENTITY 71, 19

	s_mov_b32 s30, 0
.Lchunk_loop:
	// BF16 hi+lo state tile for W @ state^T.
	STORE_STATE_LDS 0, 0, 64
	STORE_STATE_LDS 0, 1, 65
	STORE_STATE_LDS 0, 2, 66
	STORE_STATE_LDS 0, 3, 67
	STORE_STATE_LDS 1, 0, 68
	STORE_STATE_LDS 1, 1, 69
	STORE_STATE_LDS 1, 2, 70
	STORE_STATE_LDS 1, 3, 71
	s_waitcnt lgkmcnt(0)
	s_barrier

	// Homogeneous v_new = -W @ state^T.
	v_mov_b32_e32 v72, 0
	v_mov_b32_e32 v73, 0
	v_mov_b32_e32 v74, 0
	v_mov_b32_e32 v75, 0
	v_lshlrev_b32_e32 v40, 4, v4
	v_add_u32_e32 v40, v2, v40
	v_lshlrev_b32_e32 v41, 13, v40
	v_add_u32_e32 v41, s32, v41
	v_add_u32_e32 v41, v3, v41
	v_lshlrev_b32_e32 v43, 8, v2
	v_add_u32_e32 v43, v3, v43
	s_mov_b32 s35, 4
.Lws_loop:
	global_load_dwordx4 v[8:11], v41, s[10:11]
	ds_read_b128 v[16:19], v43
	ds_read_b128 v[20:23], v43 offset:4096
	s_waitcnt vmcnt(0) & lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[72:75], v[8:11], v[16:19], v[72:75]
	s_nop 8
	v_mfma_f32_16x16x32_bf16 v[72:75], v[8:11], v[20:23], v[72:75]
	s_nop 8
	v_add_u32_e32 v41, 64, v41
	v_add_u32_e32 v43, 64, v43
	s_sub_u32 s35, s35, 1
	s_cmp_lg_u32 s35, 0
	s_cbranch_scc1 .Lws_loop

	// MFMA result rows: wave*16 + lane-subgroup*4 + accumulator index.
	v_lshlrev_b32_e32 v43, 4, v4
	v_lshlrev_b32_e32 v44, 2, v5
	v_add_u32_e32 v43, v44, v43
	v_lshlrev_b32_e32 v45, 7, v43
	v_add_u32_e32 v45, s34, v45
	global_load_dword v84, v45, s[12:13] offset:0
	global_load_dword v85, v45, s[12:13] offset:128
	global_load_dword v86, v45, s[12:13] offset:256
	global_load_dword v87, v45, s[12:13] offset:384
	s_waitcnt vmcnt(0)
	.set RR, 0
	.rept 4
		v_sub_f32_e32 v[72+RR], 0, v[72+RR]
		// Preserve v_new in FP32 until the gate multiplication.
		v_add_u32_e32 v109, RR, v43
		v_lshlrev_b32_e32 v109, 6, v109
		v_lshlrev_b32_e32 v110, 2, v2
		v_add_u32_e32 v109, v110, v109
		v_add_u32_e32 v109, 8192, v109
		ds_write_b32 v109, v[72+RR]
		.set RR, RR+1
	.endr
	s_waitcnt lgkmcnt(0)
	s_barrier

	// exp(g_last-g)*v_new at LDS+16384 and exp(g_last) state decay.
	v_mov_b32_e32 v108, 8064
	v_add_u32_e32 v108, s34, v108
	global_load_dword v110, v108, s[12:13]
	s_waitcnt vmcnt(0)
	.set RR, 0
	.rept 4
		v_add_u32_e32 v108, RR, v43
		v_lshlrev_b32_e32 v108, 6, v108
		v_lshlrev_b32_e32 v109, 2, v2
		v_add_u32_e32 v108, v109, v108
		v_add_u32_e32 v109, 8192, v108
		ds_read_b32 v113, v109
		s_waitcnt lgkmcnt(0)
		v_sub_f32_e32 v114, v110, v[84+RR]
		v_mul_f32_e32 v114, 0x3fb8aa3b, v114
		v_exp_f32_e32 v114, v114
		s_nop 4
		v_mul_f32_e32 v113, v113, v114
		v_cvt_pk_bf16_f32 v114, v113, v113
		s_nop 4
		v_lshlrev_b32_e32 v115, 16, v114
		v_sub_f32_e32 v115, v113, v115
		v_cvt_pk_bf16_f32 v115, v115, v115
		s_nop 4
		// Convert the FP32-layout address back to packed-BF16 layout.
		v_lshrrev_b32_e32 v108, 1, v108
		v_add_u32_e32 v108, 16384, v108
		ds_write_b16 v108, v114
		ds_write_b16 v108, v115 offset:2048
		.set RR, RR+1
	.endr
	v_mul_f32_e32 v108, 0x3fb8aa3b, v110
	v_exp_f32_e32 v108, v108
	s_nop 4
	.set SR, 64
	.rept 8
		v_mul_f32_e32 v[SR], v[SR], v108
		.set SR, SR+1
	.endr

	// Stage grouped K[64,128] row-major at LDS 0.
	v_lshrrev_b32_e32 v40, 2, v0
	v_lshlrev_b32_e32 v40, 12, v40
	v_and_b32_e32 v41, 3, v0
	v_lshlrev_b32_e32 v41, 6, v41
	v_add_u32_e32 v40, v41, v40
	v_add_u32_e32 v40, s31, v40
	global_load_dwordx4 v[32:35], v40, s[8:9] offset:0
	global_load_dwordx4 v[36:39], v40, s[8:9] offset:16
	global_load_dwordx4 v[44:47], v40, s[8:9] offset:32
	global_load_dwordx4 v[48:51], v40, s[8:9] offset:48
	s_waitcnt vmcnt(0)
	v_lshrrev_b32_e32 v52, 2, v0
	v_lshlrev_b32_e32 v52, 8, v52
	v_and_b32_e32 v53, 3, v0
	v_lshlrev_b32_e32 v53, 6, v53
	v_add_u32_e32 v52, v53, v52
	ds_write_b128 v52, v[32:35] offset:0
	ds_write_b128 v52, v[36:39] offset:16
	ds_write_b128 v52, v[44:47] offset:32
	ds_write_b128 v52, v[48:51] offset:48
	s_waitcnt lgkmcnt(0)
	s_barrier

	STATE_UPDATE 0, 0, 64
	STATE_UPDATE 1, 0, 68
	STATE_UPDATE 0, 1, 64
	STATE_UPDATE 1, 1, 68
	s_nop 8
	s_barrier

	s_add_u32 s31, s31, 262144
	s_add_u32 s32, s32, 524288
	s_add_u32 s34, s34, 8192
	s_add_u32 s30, s30, 1
	s_cmp_lt_u32 s30, s20
	s_cbranch_scc1 .Lchunk_loop

	// BF16 M[segment,head,V,K].
	v_lshlrev_b32_e32 v40, 5, v4
	v_lshlrev_b32_e32 v41, 2, v5
	v_add_u32_e32 v40, v41, v40
	v_lshlrev_b32_e32 v42, 8, v2
	v_lshlrev_b32_e32 v40, 1, v40
	v_add_u32_e32 v40, v42, v40
	v_add_u32_e32 v40, s26, v40
	.set RR, 0
	.rept 4
		v_cvt_pk_bf16_f32 v108, v[64+RR], v[64+RR]
		s_nop 4
		global_store_short v40, v108, s[14:15] offset:(RR*2)
		v_cvt_pk_bf16_f32 v108, v[68+RR], v[68+RR]
		s_nop 4
		global_store_short v40, v108, s[14:15] offset:(32+RR*2)
		.set RR, RR+1
	.endr
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_gdn_segment_m_m8192_seg32_bv16_gfx950
		.amdhsa_group_segment_fixed_size 20480
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 40
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 116
		.amdhsa_accum_offset 116
		.amdhsa_next_free_sgpr 36
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
	.size qwen36_gdn_segment_m_m8192_seg32_bv16_gfx950, .Lfunc_end0-qwen36_gdn_segment_m_m8192_seg32_bv16_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: k_bf16, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: w_bf16, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: g_f32, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: m_bf16, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: chunks_per_segment, .offset: 32, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 20480
    .kernarg_segment_align: 8
    .kernarg_segment_size: 40
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_gdn_segment_m_m8192_seg32_bv16_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 36
    .sgpr_spill_count: 0
    .symbol: qwen36_gdn_segment_m_m8192_seg32_bv16_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 115
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...
	.end_amdgpu_metadata
