// SPDX-License-Identifier: MIT
//
// Experimental raw gfx950 Qwen3.6 GDN chunk output.
// Exact shape: B1/T8192/H32/Hg16/K128/V128/BT64/BV64.
// Grid=(2,128,32), block=(256,1,1), wave64.
//
// Four waves own the four 16-row query tiles of one 64-token chunk.  Each
// wave keeps four 16x16 QH accumulators live, computes the causal gated QK
// matrix into BF16 LDS, then accumulates A@V with native CDNA4 BF16 MFMA.
// This source is intentionally under experiments until the real-checkpoint
// gate and HIP-event comparison pass.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text

	.macro ZERO4 BASE
	v_mov_b32_e32 v[\BASE+0], 0
	v_mov_b32_e32 v[\BASE+1], 0
	v_mov_b32_e32 v[\BASE+2], 0
	v_mov_b32_e32 v[\BASE+3], 0
	.endm

	.macro GATE_STORE NT, RR, AREG
	// safe_exp(g[row] - g[col]) and the causal mask.
	v_sub_f32_e32 v108, v[100+\RR], v[104+\NT]
	v_cmp_le_f32_e32 vcc, v108, v114
	v_cndmask_b32_e32 v108, v113, v108, vcc
	v_mul_f32_e32 v108, 0x3fb8aa3b, v108
	v_exp_f32_e32 v108, v108
	v_add_u32_e32 v109, \RR, v121
	v_add_u32_e32 v110, (\NT*16), v2
	v_cmp_ge_u32_e32 vcc, v109, v110
	v_cndmask_b32_e32 v108, 0, v108, vcc
	v_mul_f32_e32 v[\AREG], v[\AREG], v108
	v_cvt_pk_bf16_f32 v111, v[\AREG], v[\AREG]
	v_lshlrev_b32_e32 v112, 7, v109
	v_lshl_add_u32 v112, v110, 1, v112
	ds_write_b16 v112, v111
	.endm

	.macro LOAD_V_MFMA NT, ACC
	// B operand: eight K-adjacent BF16 values at a fixed output column.
	v_add_u32_e32 v45, (8192+\NT*32), v125
	ds_read_u16 v8, v45 offset:0
	ds_read_u16 v9, v45 offset:128
	ds_read_u16 v10, v45 offset:256
	ds_read_u16 v11, v45 offset:384
	ds_read_u16 v12, v45 offset:512
	ds_read_u16 v13, v45 offset:640
	ds_read_u16 v14, v45 offset:768
	ds_read_u16 v15, v45 offset:896
	s_waitcnt lgkmcnt(0)
	v_lshl_or_b32 v16, v9, 16, v8
	v_lshl_or_b32 v17, v11, 16, v10
	v_lshl_or_b32 v18, v13, 16, v12
	v_lshl_or_b32 v19, v15, 16, v14
	v_mfma_f32_16x16x32_bf16 v[\ACC:\ACC+3], v[20:23], v[16:19], v[\ACC:\ACC+3]
	.endm

	.protected qwen36_gdn_chunk_o_m8192_bv64_gfx950
	.globl qwen36_gdn_chunk_o_m8192_bv64_gfx950
	.p2align 8
	.type qwen36_gdn_chunk_o_m8192_bv64_gfx950,@function
qwen36_gdn_chunk_o_m8192_bv64_gfx950:
	// q, k, v_new, h, g_cumsum, output, scale.
	s_load_dwordx2 s[8:9], s[0:1], 0
	s_load_dwordx2 s[10:11], s[0:1], 8
	s_load_dwordx2 s[12:13], s[0:1], 16
	s_load_dwordx2 s[14:15], s[0:1], 24
	s_load_dwordx2 s[16:17], s[0:1], 32
	s_load_dwordx2 s[18:19], s[0:1], 40
	s_load_dword s20, s[0:1], 48
	s_waitcnt lgkmcnt(0)

	// Fixed-shape scalar byte bases. s2=V tile, s3=chunk, s4=value head.
	s_lshr_b32 s21, s4, 1
	s_lshl_b32 s22, s3, 18
	s_lshl_b32 s28, s21, 8
	s_add_u32 s22, s22, s28              // q/k chunk + grouped-head
	s_lshl_b32 s23, s3, 20
	s_lshl_b32 s28, s4, 15
	s_add_u32 s23, s23, s28
	s_lshl_b32 s28, s2, 14
	s_add_u32 s23, s23, s28              // h chunk/head/BV64
	s_lshl_b32 s25, s3, 19
	s_lshl_b32 s28, s4, 8
	s_add_u32 s25, s25, s28
	s_lshl_b32 s28, s2, 7
	s_add_u32 s25, s25, s28              // v chunk/head/BV64
	s_lshl_b32 s26, s3, 13
	s_lshl_b32 s28, s4, 2
	s_add_u32 s26, s26, s28              // gate chunk/head
	s_mov_b32 s27, s25                    // output has v's layout

	// wave=row tile, lane low nibble=row/column, lane[5:4]=K subgroup.
	v_and_b32_e32 v1, 63, v0
	v_and_b32_e32 v2, 15, v0
	v_and_b32_e32 v3, 48, v0
	v_lshrrev_b32_e32 v4, 6, v0
	v_lshlrev_b32_e32 v5, 4, v4
	v_add_u32_e32 v5, v5, v2
	v_lshlrev_b32_e32 v44, 12, v5
	v_add_u32_e32 v44, s22, v44
	v_add_u32_e32 v44, v3, v44           // Q address

	// H and K B-operand addresses for four N16 tiles.
	.set NT, 0
	.rept 4
		v_add_u32_e32 v[45+NT], (NT*16), v2
		v_lshlrev_b32_e32 v[45+NT], 8, v[45+NT]
		v_add_u32_e32 v[45+NT], s23, v[45+NT]
		v_add_u32_e32 v[45+NT], v3, v[45+NT]
		v_add_u32_e32 v[49+NT], (NT*16), v2
		v_lshlrev_b32_e32 v[49+NT], 12, v[49+NT]
		v_add_u32_e32 v[49+NT], s22, v[49+NT]
		v_add_u32_e32 v[49+NT], v3, v[49+NT]
		.set NT, NT+1
	.endr

	ZERO4 64
	ZERO4 68
	ZERO4 72
	ZERO4 76
	ZERO4 80
	ZERO4 84
	ZERO4 88
	ZERO4 92

	// Four K32 steps. Q is reused by all QH and QK output tiles.
	s_mov_b32 s29, 4
.Lqhk_loop:
	global_load_dwordx4 v[8:11], v44, s[8:9]
	global_load_dwordx4 v[12:15], v45, s[14:15]
	global_load_dwordx4 v[16:19], v46, s[14:15]
	global_load_dwordx4 v[20:23], v47, s[14:15]
	global_load_dwordx4 v[24:27], v48, s[14:15]
	global_load_dwordx4 v[28:31], v49, s[10:11]
	global_load_dwordx4 v[32:35], v50, s[10:11]
	global_load_dwordx4 v[36:39], v51, s[10:11]
	global_load_dwordx4 v[40:43], v52, s[10:11]
	s_waitcnt vmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[64:67], v[8:11], v[12:15], v[64:67]
	v_mfma_f32_16x16x32_bf16 v[68:71], v[8:11], v[16:19], v[68:71]
	v_mfma_f32_16x16x32_bf16 v[72:75], v[8:11], v[20:23], v[72:75]
	v_mfma_f32_16x16x32_bf16 v[76:79], v[8:11], v[24:27], v[76:79]
	v_mfma_f32_16x16x32_bf16 v[80:83], v[8:11], v[28:31], v[80:83]
	v_mfma_f32_16x16x32_bf16 v[84:87], v[8:11], v[32:35], v[84:87]
	v_mfma_f32_16x16x32_bf16 v[88:91], v[8:11], v[36:39], v[88:91]
	v_mfma_f32_16x16x32_bf16 v[92:95], v[8:11], v[40:43], v[92:95]
	v_add_u32_e32 v44, 64, v44
	.set AR, 45
	.rept 8
		v_add_u32_e32 v[AR], 64, v[AR]
		.set AR, AR+1
	.endr
	s_sub_u32 s29, s29, 1
	s_cmp_lg_u32 s29, 0
	s_cbranch_scc1 .Lqhk_loop

	// Gate QH once per result row. Load four row gates and four column gates.
	v_lshrrev_b32_e32 v120, 4, v1
	v_lshlrev_b32_e32 v120, 2, v120
	v_lshlrev_b32_e32 v121, 4, v4
	v_add_u32_e32 v121, v121, v120
	v_lshlrev_b32_e32 v122, 7, v121
	v_add_u32_e32 v122, s26, v122
	global_load_dword v100, v122, s[16:17] offset:0
	global_load_dword v101, v122, s[16:17] offset:128
	global_load_dword v102, v122, s[16:17] offset:256
	global_load_dword v103, v122, s[16:17] offset:384
	.set NT, 0
	.rept 4
		v_add_u32_e32 v123, (NT*16), v2
		v_lshlrev_b32_e32 v123, 7, v123
		v_add_u32_e32 v123, s26, v123
		global_load_dword v[104+NT], v123, s[16:17]
		.set NT, NT+1
	.endr
	s_waitcnt vmcnt(0)
	v_mov_b32_e32 v113, 0xff800000
	v_mov_b32_e32 v114, 0
	.set RR, 0
	.rept 4
		v_mul_f32_e32 v108, 0x3fb8aa3b, v[100+RR]
		v_exp_f32_e32 v108, v108
		v_mul_f32_e32 v[64+RR], v[64+RR], v108
		v_mul_f32_e32 v[68+RR], v[68+RR], v108
		v_mul_f32_e32 v[72+RR], v[72+RR], v108
		v_mul_f32_e32 v[76+RR], v[76+RR], v108
		.set RR, RR+1
	.endr

	// Convert the causal gated QK matrix to BF16 LDS.
	GATE_STORE 0, 0, 80
	GATE_STORE 0, 1, 81
	GATE_STORE 0, 2, 82
	GATE_STORE 0, 3, 83
	GATE_STORE 1, 0, 84
	GATE_STORE 1, 1, 85
	GATE_STORE 1, 2, 86
	GATE_STORE 1, 3, 87
	GATE_STORE 2, 0, 88
	GATE_STORE 2, 1, 89
	GATE_STORE 2, 2, 90
	GATE_STORE 2, 3, 91
	GATE_STORE 3, 0, 92
	GATE_STORE 3, 1, 93
	GATE_STORE 3, 2, 94
	GATE_STORE 3, 3, 95

	// Cooperatively stage V[64,64] at LDS+8192, 32 bytes per thread.
	v_lshrrev_b32_e32 v115, 2, v0
	v_lshlrev_b32_e32 v115, 8, v115
	v_and_b32_e32 v116, 3, v0
	v_lshlrev_b32_e32 v116, 5, v116
	v_add_u32_e32 v115, v116, v115
	v_add_u32_e32 v115, s25, v115
	global_load_dwordx4 v[116:119], v115, s[12:13]
	global_load_dwordx4 v[120:123], v115, s[12:13] offset:16
	s_waitcnt vmcnt(0)
	v_lshlrev_b32_e32 v124, 5, v0
	v_add_u32_e32 v124, 8192, v124
	ds_write_b128 v124, v[116:119]
	ds_write_b128 v124, v[120:123] offset:16
	s_waitcnt lgkmcnt(0)
	s_barrier

	// Two K32 A@V steps. A is contiguous; V is gathered from row-major LDS.
	v_lshlrev_b32_e32 v44, 4, v4
	v_add_u32_e32 v44, v2, v44
	v_lshlrev_b32_e32 v44, 7, v44
	v_add_u32_e32 v44, v3, v44
	v_lshlrev_b32_e32 v125, 6, v3
	v_lshlrev_b32_e32 v126, 1, v2
	v_add_u32_e32 v125, v126, v125
	ds_read_b128 v[20:23], v44
	s_waitcnt lgkmcnt(0)
	LOAD_V_MFMA 0, 64
	LOAD_V_MFMA 1, 68
	LOAD_V_MFMA 2, 72
	LOAD_V_MFMA 3, 76
	v_add_u32_e32 v44, 64, v44
	v_add_u32_e32 v125, 4096, v125
	ds_read_b128 v[20:23], v44
	s_waitcnt lgkmcnt(0)
	LOAD_V_MFMA 0, 64
	LOAD_V_MFMA 1, 68
	LOAD_V_MFMA 2, 72
	LOAD_V_MFMA 3, 76

	// Scale and store BF16 output in the native [T,H,V] layout.
	s_nop 8
	.set AR, 64
	.rept 16
		v_mul_f32_e32 v[AR], s20, v[AR]
		.set AR, AR+1
	.endr
	v_lshrrev_b32_e32 v46, 4, v1
	v_lshlrev_b32_e32 v46, 2, v46
	v_lshlrev_b32_e32 v47, 4, v4
	v_add_u32_e32 v46, v47, v46
	v_lshlrev_b32_e32 v47, 13, v46
	v_lshlrev_b32_e32 v48, 1, v2
	v_add_u32_e32 v47, v48, v47
	v_add_u32_e32 v47, s27, v47
	.set NT, 0
	.rept 4
		.set RR, 0
		.rept 4
			.set AREG, 64+NT*4+RR
			v_cvt_pk_bf16_f32 v49, v[AREG], v[AREG]
			v_add_u32_e32 v50, (RR*8192), v47
			global_store_short v50, v49, s[18:19] offset:(NT*32)
			.set RR, RR+1
		.endr
		.set NT, NT+1
	.endr
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_gdn_chunk_o_m8192_bv64_gfx950
		.amdhsa_group_segment_fixed_size 16384
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 56
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 127
		.amdhsa_accum_offset 128
		.amdhsa_next_free_sgpr 30
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
	.size qwen36_gdn_chunk_o_m8192_bv64_gfx950, .Lfunc_end0-qwen36_gdn_chunk_o_m8192_bv64_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: q_bf16, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: k_bf16, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: v_new_bf16, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: h_bf16, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: g_f32, .offset: 32, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: output_bf16, .offset: 40, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: scale, .offset: 48, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 16384
    .kernarg_segment_align: 8
    .kernarg_segment_size: 56
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_gdn_chunk_o_m8192_bv64_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 30
    .sgpr_spill_count: 0
    .symbol: qwen36_gdn_chunk_o_m8192_bv64_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 127
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
