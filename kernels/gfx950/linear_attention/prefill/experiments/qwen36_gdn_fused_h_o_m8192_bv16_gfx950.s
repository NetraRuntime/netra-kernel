// SPDX-License-Identifier: MIT
//
// Experimental exact-path fusion for Qwen3.6 GDN on gfx950.
// B1/T8192/H32/Hg16/K128/V128/BT64/BV16, wave64.
// Grid=(8,32,1), block=(256,1,1), LDS=18432 bytes.
//
// One workgroup owns a (head,V16) recurrent-state tile and walks all 128
// chunks. Four waves own the four token-M16 tiles. The kernel fuses
//   v_new = u - w @ state^T
//   o = scale * (exp(g) * q @ state^T + causal_gated(q @ k^T) @ v_new)
//   state = exp(g_last) * state + (exp(g_last-g) * v_new)^T @ k
// without materializing the full h or v_new tensors in HBM. State remains
// FP32 across chunks and is converted to BF16 at MFMA boundaries, matching the
// deployed recurrence. Prefix-state emission is intentionally absent in this
// first isolated experiment.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text

	.macro ZERO4 BASE
	v_mov_b32_e32 v[\BASE+0], 0
	v_mov_b32_e32 v[\BASE+1], 0
	v_mov_b32_e32 v[\BASE+2], 0
	v_mov_b32_e32 v[\BASE+3], 0
	.endm

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
	ds_write_b16 v40, v42
	.endm

	.macro GATE_A_STORE NT, RR, REG
	v_sub_f32_e32 v108, v[84+\RR], v[104+\NT]
	v_cmp_le_f32_e32 vcc, v108, v112
	v_cndmask_b32_e32 v108, v111, v108, vcc
	v_mul_f32_e32 v108, 0x3fb8aa3b, v108
	v_exp_f32_e32 v108, v108
	s_nop 4
	v_add_u32_e32 v109, \RR, v43
	v_add_u32_e32 v110, (\NT*16), v2
	v_cmp_ge_u32_e32 vcc, v109, v110
	v_cndmask_b32_e32 v108, 0, v108, vcc
	v_mul_f32_e32 v[\REG], v[\REG], v108
	v_cvt_pk_bf16_f32 v113, v[\REG], v[\REG]
	v_lshlrev_b32_e32 v114, 7, v109
	v_lshl_add_u32 v114, v110, 1, v114
	v_add_u32_e32 v114, 6144, v114
	ds_write_b16 v114, v113
	.ifdef NETRA_DIAG_GATED_QK
		s_waitcnt lgkmcnt(0)
		ds_read_u16 v113, v114
		s_waitcnt lgkmcnt(0)
		v_lshlrev_b32_e32 v115, 13, v109
		v_lshlrev_b32_e32 v116, 1, v110
		v_add_u32_e32 v115, v116, v115
		v_add_u32_e32 v115, s32, v115
		global_store_short v115, v113, s[20:21] offset:0
		global_store_short v115, v113, s[20:21] offset:128
	.endif
	.endm

	.macro LOAD_VNEW_B NT, OUT
	v_add_u32_e32 v56, (4096+\NT*32), v117
	ds_read_u16 v8, v56 offset:0
	ds_read_u16 v9, v56 offset:32
	ds_read_u16 v10, v56 offset:64
	ds_read_u16 v11, v56 offset:96
	ds_read_u16 v12, v56 offset:128
	ds_read_u16 v13, v56 offset:160
	ds_read_u16 v14, v56 offset:192
	ds_read_u16 v15, v56 offset:224
	s_waitcnt lgkmcnt(0)
	v_lshl_or_b32 v[\OUT+0], v9, 16, v8
	v_lshl_or_b32 v[\OUT+1], v11, 16, v10
	v_lshl_or_b32 v[\OUT+2], v13, 16, v12
	v_lshl_or_b32 v[\OUT+3], v15, 16, v14
	s_nop 4
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
	// Weighted v_new B operand.
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
	.endm

	.protected qwen36_gdn_fused_h_o_m8192_bv16_gfx950
	.globl qwen36_gdn_fused_h_o_m8192_bv16_gfx950
	.p2align 8
	.type qwen36_gdn_fused_h_o_m8192_bv16_gfx950,@function
qwen36_gdn_fused_h_o_m8192_bv16_gfx950:
	// q, k, u, w, g, state(in/out), output, scale, diagnostic chunk count.
	s_load_dwordx2 s[8:9], s[0:1], 0
	s_load_dwordx2 s[10:11], s[0:1], 8
	s_load_dwordx2 s[12:13], s[0:1], 16
	s_load_dwordx2 s[14:15], s[0:1], 24
	s_load_dwordx2 s[16:17], s[0:1], 32
	s_load_dwordx2 s[18:19], s[0:1], 40
	s_load_dwordx2 s[20:21], s[0:1], 48
	s_load_dword s22, s[0:1], 56
	s_load_dword s24, s[0:1], 60
	s_waitcnt lgkmcnt(0)

	v_and_b32_e32 v1, 63, v0
	v_and_b32_e32 v2, 15, v0
	v_and_b32_e32 v3, 48, v0
	v_lshrrev_b32_e32 v4, 6, v0
	v_lshrrev_b32_e32 v5, 4, v1

	// Initial scalar byte bases.
	s_lshr_b32 s23, s3, 1
	s_lshl_b32 s31, s23, 8              // q/k grouped-head base
	s_lshl_b32 s32, s3, 8               // w head base
	s_lshl_b32 s33, s2, 5
	s_add_u32 s33, s33, s32             // u/o head + V16 base
	s_lshl_b32 s34, s3, 2               // gate head base
	s_lshl_b32 s26, s3, 15
	s_lshl_b32 s27, s2, 12
	s_add_u32 s26, s26, s27             // state head + V16 base

	// Load the FP32 recurrent state distribution (two K16 tiles per wave).
	v_lshlrev_b32_e32 v40, 5, v4
	v_lshlrev_b32_e32 v41, 2, v5
	v_add_u32_e32 v40, v41, v40
	v_lshlrev_b32_e32 v42, 8, v2
	v_lshlrev_b32_e32 v40, 1, v40
	v_add_u32_e32 v40, v42, v40
	v_add_u32_e32 v40, s26, v40
	global_load_ushort v64, v40, s[18:19] offset:0
	global_load_ushort v65, v40, s[18:19] offset:2
	global_load_ushort v66, v40, s[18:19] offset:4
	global_load_ushort v67, v40, s[18:19] offset:6
	global_load_ushort v68, v40, s[18:19] offset:32
	global_load_ushort v69, v40, s[18:19] offset:34
	global_load_ushort v70, v40, s[18:19] offset:36
	global_load_ushort v71, v40, s[18:19] offset:38
	s_waitcnt vmcnt(0)
	.set SR, 64
	.rept 8
		v_lshlrev_b32_e32 v[SR], 16, v[SR]
		.set SR, SR+1
	.endr

	s_mov_b32 s30, 0
.Lchunk_loop:
	.ifdef NETRA_RESET_SEG32
		s_and_b32 s35, s30, 31
		s_cmp_lg_u32 s35, 0
		s_cbranch_scc1 .Lkeep_segment_state
		ZERO4 64
		ZERO4 68
.Lkeep_segment_state:
	.endif
	// Make the current FP32 state available as BF16 [V16,K128] in LDS.
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

	ZERO4 72
	ZERO4 76
	// A-operand row for this wave's token M16 tile.
	v_lshlrev_b32_e32 v40, 4, v4
	v_add_u32_e32 v40, v2, v40
	v_lshlrev_b32_e32 v41, 13, v40
	v_add_u32_e32 v41, s32, v41
	v_add_u32_e32 v41, v3, v41           // W
	v_lshlrev_b32_e32 v42, 12, v40
	v_add_u32_e32 v42, s31, v42
	v_add_u32_e32 v42, v3, v42           // Q
	v_lshlrev_b32_e32 v43, 8, v2
	v_add_u32_e32 v43, v3, v43           // state B
	s_mov_b32 s35, 4
.Lws_qs_loop:
	global_load_dwordx4 v[8:11], v41, s[14:15]
	global_load_dwordx4 v[12:15], v42, s[8:9]
	ds_read_b128 v[16:19], v43
	s_waitcnt vmcnt(0) & lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[72:75], v[8:11], v[16:19], v[72:75]
	v_mfma_f32_16x16x32_bf16 v[76:79], v[12:15], v[16:19], v[76:79]
	v_add_u32_e32 v41, 64, v41
	v_add_u32_e32 v42, 64, v42
	v_add_u32_e32 v43, 64, v43
	s_sub_u32 s35, s35, 1
	s_cmp_lg_u32 s35, 0
	s_cbranch_scc1 .Lws_qs_loop

	// Result rows are wave*16 + lane-subgroup*4 + accumulator index.
	v_lshlrev_b32_e32 v43, 4, v4
	v_lshlrev_b32_e32 v44, 2, v5
	v_add_u32_e32 v43, v44, v43
	v_lshlrev_b32_e32 v44, 13, v43
	v_lshlrev_b32_e32 v45, 1, v2
	v_add_u32_e32 v44, v45, v44
	v_add_u32_e32 v44, s33, v44
	global_load_ushort v80, v44, s[12:13] offset:0
	v_add_u32_e32 v45, 8192, v44
	v_add_u32_e32 v46, 16384, v44
	v_add_u32_e32 v47, 24576, v44
	global_load_ushort v81, v45, s[12:13]
	global_load_ushort v82, v46, s[12:13]
	global_load_ushort v83, v47, s[12:13]
	// Load row gates for QH and weighted-state update.
	v_lshlrev_b32_e32 v45, 7, v43
	v_add_u32_e32 v45, s34, v45
	global_load_dword v84, v45, s[16:17] offset:0
	global_load_dword v85, v45, s[16:17] offset:128
	global_load_dword v86, v45, s[16:17] offset:256
	global_load_dword v87, v45, s[16:17] offset:384
	s_waitcnt vmcnt(0)
	.set RR, 0
	.rept 4
		v_lshlrev_b32_e32 v[80+RR], 16, v[80+RR]
		v_sub_f32_e32 v[72+RR], v[80+RR], v[72+RR]
		.ifdef NETRA_DIAG_VNEW
			// Expose the first recurrent product through the ordinary output
			// buffer so its MFMA lane mapping can be checked independently.
			v_cvt_pk_bf16_f32 v108, v[72+RR], v[72+RR]
			v_add_u32_e32 v109, (RR*8192), v44
			global_store_short v109, v108, s[20:21]
		.endif
		v_cvt_pk_bf16_f32 v108, v[72+RR], v[72+RR]
		v_add_u32_e32 v109, RR, v43
		v_lshlrev_b32_e32 v109, 5, v109
		v_lshlrev_b32_e32 v110, 1, v2
		v_add_u32_e32 v109, v110, v109
		v_add_u32_e32 v109, 4096, v109
		ds_write_b16 v109, v108
		v_mul_f32_e32 v108, 0x3fb8aa3b, v[84+RR]
		v_exp_f32_e32 v108, v108
		s_nop 4
		v_mul_f32_e32 v[76+RR], v[76+RR], v108
		.ifdef NETRA_DIAG_QH
			v_mul_f32_e32 v108, s22, v[76+RR]
			v_cvt_pk_bf16_f32 v108, v108, v108
			v_add_u32_e32 v109, (RR*8192), v44
			global_store_short v109, v108, s[20:21]
		.endif
		.set RR, RR+1
	.endr

	// QK: four causal token-N16 tiles.
	ZERO4 88
	ZERO4 92
	ZERO4 96
	ZERO4 100
	v_lshlrev_b32_e32 v40, 4, v4
	v_add_u32_e32 v40, v2, v40
	v_lshlrev_b32_e32 v42, 12, v40
	v_add_u32_e32 v42, s31, v42
	v_add_u32_e32 v42, v3, v42
	.set NT, 0
	.rept 4
		v_add_u32_e32 v[46+NT], (NT*16), v2
		v_lshlrev_b32_e32 v[46+NT], 12, v[46+NT]
		v_add_u32_e32 v[46+NT], s31, v[46+NT]
		v_add_u32_e32 v[46+NT], v3, v[46+NT]
		.set NT, NT+1
	.endr
	s_mov_b32 s35, 4
.Lqk_loop:
	global_load_dwordx4 v[8:11], v42, s[8:9]
	global_load_dwordx4 v[12:15], v46, s[10:11]
	global_load_dwordx4 v[16:19], v47, s[10:11]
	global_load_dwordx4 v[20:23], v48, s[10:11]
	global_load_dwordx4 v[24:27], v49, s[10:11]
	s_waitcnt vmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[88:91], v[8:11], v[12:15], v[88:91]
	v_mfma_f32_16x16x32_bf16 v[92:95], v[8:11], v[16:19], v[92:95]
	v_mfma_f32_16x16x32_bf16 v[96:99], v[8:11], v[20:23], v[96:99]
	v_mfma_f32_16x16x32_bf16 v[100:103], v[8:11], v[24:27], v[100:103]
	v_add_u32_e32 v42, 64, v42
	v_add_u32_e32 v46, 64, v46
	v_add_u32_e32 v47, 64, v47
	v_add_u32_e32 v48, 64, v48
	v_add_u32_e32 v49, 64, v49
	s_sub_u32 s35, s35, 1
	s_cmp_lg_u32 s35, 0
	s_cbranch_scc1 .Lqk_loop
	// Column gates and causal gated A -> LDS.
	.set NT, 0
	.rept 4
		v_add_u32_e32 v108, (NT*16), v2
		v_lshlrev_b32_e32 v108, 7, v108
		v_add_u32_e32 v108, s34, v108
		global_load_dword v[104+NT], v108, s[16:17]
		.set NT, NT+1
	.endr
	s_waitcnt vmcnt(0)
	v_mov_b32_e32 v111, 0xff800000
	v_mov_b32_e32 v112, 0
	GATE_A_STORE 0, 0, 88
	GATE_A_STORE 0, 1, 89
	GATE_A_STORE 0, 2, 90
	GATE_A_STORE 0, 3, 91
	GATE_A_STORE 1, 0, 92
	GATE_A_STORE 1, 1, 93
	GATE_A_STORE 1, 2, 94
	GATE_A_STORE 1, 3, 95
	GATE_A_STORE 2, 0, 96
	GATE_A_STORE 2, 1, 97
	GATE_A_STORE 2, 2, 98
	GATE_A_STORE 2, 3, 99
	GATE_A_STORE 3, 0, 100
	GATE_A_STORE 3, 1, 101
	GATE_A_STORE 3, 2, 102
	GATE_A_STORE 3, 3, 103
	s_waitcnt lgkmcnt(0)
	s_barrier

	// AV, accumulating into the gated QH fragment.
	v_lshlrev_b32_e32 v40, 4, v4
	v_add_u32_e32 v40, v2, v40
	v_lshlrev_b32_e32 v40, 7, v40
	v_add_u32_e32 v40, v3, v40
	v_add_u32_e32 v40, 6144, v40
	v_lshlrev_b32_e32 v117, 4, v3
	v_lshlrev_b32_e32 v118, 1, v2
	v_add_u32_e32 v117, v118, v117
	ds_read_b128 v[20:23], v40
	s_waitcnt lgkmcnt(0)
	LOAD_VNEW_B 0, 16
	v_mfma_f32_16x16x32_bf16 v[76:79], v[20:23], v[16:19], v[76:79]
	v_add_u32_e32 v40, 64, v40
	v_add_u32_e32 v117, 1024, v117
	ds_read_b128 v[20:23], v40
	s_waitcnt lgkmcnt(0)
	LOAD_VNEW_B 0, 16
	v_mfma_f32_16x16x32_bf16 v[76:79], v[20:23], v[16:19], v[76:79]

	// Scale and write the V16 output tile.
	.ifndef NETRA_DIAG_VNEW
		.ifndef NETRA_DIAG_WEIGHTED_VNEW
			.ifndef NETRA_DIAG_QH
				.ifndef NETRA_DIAG_GATED_QK
					s_nop 8
					.set RR, 0
					.rept 4
						v_mul_f32_e32 v[76+RR], s22, v[76+RR]
						v_cvt_pk_bf16_f32 v108, v[76+RR], v[76+RR]
						v_add_u32_e32 v109, (RR*8192), v44
						global_store_short v109, v108, s[20:21]
						.set RR, RR+1
					.endr
				.endif
			.endif
		.endif
	.endif

	// Load g_last and create BF16 exp(g_last-g)*v_new at LDS+16384.
	v_mov_b32_e32 v108, 8064
	v_add_u32_e32 v108, s34, v108
	global_load_dword v110, v108, s[16:17]
	s_waitcnt vmcnt(0)
	.set RR, 0
	.rept 4
		v_add_u32_e32 v108, RR, v43
		v_lshlrev_b32_e32 v108, 5, v108
		v_lshlrev_b32_e32 v109, 1, v2
		v_add_u32_e32 v108, v109, v108
		v_add_u32_e32 v109, 4096, v108
		ds_read_u16 v113, v109
		s_waitcnt lgkmcnt(0)
		v_lshlrev_b32_e32 v113, 16, v113
		v_sub_f32_e32 v114, v110, v[84+RR]
		v_mul_f32_e32 v114, 0x3fb8aa3b, v114
		v_exp_f32_e32 v114, v114
		s_nop 4
		v_mul_f32_e32 v113, v113, v114
		v_cvt_pk_bf16_f32 v113, v113, v113
		v_add_u32_e32 v108, 16384, v108
		ds_write_b16 v108, v113
		.ifdef NETRA_DIAG_WEIGHTED_VNEW
			v_add_u32_e32 v115, (RR*8192), v44
			global_store_short v115, v113, s[20:21]
		.endif
		.set RR, RR+1
	.endr
	// State decay remains FP32 across chunks.
	v_mul_f32_e32 v108, 0x3fb8aa3b, v110
	v_exp_f32_e32 v108, v108
	s_nop 4
	.set SR, 64
	.rept 8
		v_mul_f32_e32 v[SR], v[SR], v108
		.set SR, SR+1
	.endr

	// Stage K[64,128] row-major at LDS 0, 64 bytes per thread.
	v_lshrrev_b32_e32 v40, 2, v0
	v_lshlrev_b32_e32 v40, 12, v40
	v_and_b32_e32 v41, 3, v0
	v_lshlrev_b32_e32 v41, 6, v41
	v_add_u32_e32 v40, v41, v40
	v_add_u32_e32 v40, s31, v40
	global_load_dwordx4 v[32:35], v40, s[10:11] offset:0
	global_load_dwordx4 v[36:39], v40, s[10:11] offset:16
	global_load_dwordx4 v[44:47], v40, s[10:11] offset:32
	global_load_dwordx4 v[48:51], v40, s[10:11] offset:48
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
	.ifdef NETRA_DIAG_K_LDS
		ds_read_b128 v[32:35], v52 offset:0
		ds_read_b128 v[36:39], v52 offset:16
		ds_read_b128 v[44:47], v52 offset:32
		ds_read_b128 v[48:51], v52 offset:48
		s_waitcnt lgkmcnt(0)
		v_lshrrev_b32_e32 v54, 2, v0
		v_lshlrev_b32_e32 v54, 13, v54
		v_and_b32_e32 v55, 3, v0
		v_lshlrev_b32_e32 v55, 6, v55
		v_add_u32_e32 v54, v55, v54
		v_add_u32_e32 v54, s32, v54
		global_store_dwordx4 v54, v[32:35], s[20:21] offset:0
		global_store_dwordx4 v54, v[36:39], s[20:21] offset:16
		global_store_dwordx4 v54, v[44:47], s[20:21] offset:32
		global_store_dwordx4 v54, v[48:51], s[20:21] offset:48
	.endif

	// K^T @ weighted-v update directly into the live state registers.
	STATE_UPDATE 0, 0, 64
	STATE_UPDATE 1, 0, 68
	STATE_UPDATE 0, 1, 64
	STATE_UPDATE 1, 1, 68
	s_nop 8
	s_barrier

	// Advance fixed-shape chunk bases.
	s_add_u32 s31, s31, 262144
	s_add_u32 s32, s32, 524288
	s_add_u32 s33, s33, 524288
	s_add_u32 s34, s34, 8192
	s_add_u32 s30, s30, 1
	s_cmp_lt_u32 s30, s24
	s_cbranch_scc1 .Lchunk_loop

	// Final BF16 state writeback.
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
		global_store_short v40, v108, s[18:19] offset:(RR*2)
		v_cvt_pk_bf16_f32 v108, v[68+RR], v[68+RR]
		global_store_short v40, v108, s[18:19] offset:(32+RR*2)
		.set RR, RR+1
	.endr
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_gdn_fused_h_o_m8192_bv16_gfx950
		.amdhsa_group_segment_fixed_size 18432
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 64
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 119
		.amdhsa_accum_offset 120
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
	.size qwen36_gdn_fused_h_o_m8192_bv16_gfx950, .Lfunc_end0-qwen36_gdn_fused_h_o_m8192_bv16_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: q_bf16, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: k_bf16, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: u_bf16, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: w_bf16, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: g_f32, .offset: 32, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: state_bf16, .offset: 40, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_write }
      - { .name: output_bf16, .offset: 48, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: scale, .offset: 56, .size: 4, .value_kind: by_value }
      - { .name: num_chunks, .offset: 60, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 18432
    .kernarg_segment_align: 8
    .kernarg_segment_size: 64
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_gdn_fused_h_o_m8192_bv16_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 36
    .sgpr_spill_count: 0
    .symbol: qwen36_gdn_fused_h_o_m8192_bv16_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 119
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...
	.end_amdgpu_metadata
