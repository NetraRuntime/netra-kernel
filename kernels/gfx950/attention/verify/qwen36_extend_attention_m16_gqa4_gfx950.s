	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 5
	; Qwen3.6 dFlash verification extend-attention, accepted M<=16 GQA4 path.
	; Hand-maintained gfx950/wave64 assembly for one sequence/KV-head per
	; workgroup. Four waves flatten 4 query heads x 16 tokens into M=64 so each
	; K/V tile is read once instead of once per query head. Qwen's live
	; piecewise-graph ABI supplies qo_indptr as int64 while kv_indptr remains
	; int32; sequence offsets use the low dword because the supported token
	; extent is far below 2^32. The final two
	; addressable SGPRs retain two long-lived scalars formerly spilled to v136.
	.text
	.globl	qwen36_extend_attention_m16_gqa4_gfx950
	.p2align	8
	.type	qwen36_extend_attention_m16_gqa4_gfx950,@function
qwen36_extend_attention_m16_gqa4_gfx950:
.Lfunc_begin0:
	.cfi_sections .debug_frame
	.cfi_startproc
; %bb.11:
	.file	1 "/netra-kernel/tools/benchmark" "benchmark_qwen36_extend_attention_m756.py"
	.loc	1 72 0 prologue_end             ; benchmark_qwen36_extend_attention_m756.py:72:0
	s_load_dwordx2 s[2:3], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_waitcnt lgkmcnt(0)
	s_branch .LBB0_0
	.loc	1 0 0 is_stmt 0                 ; :0:0
.Ltmp0:
	.p2align	8
; %bb.12:
.LBB0_0:
	s_mov_b32 s18, s16
	s_mov_b64 s[20:21], s[2:3]
.Ltmp1:
	.loc	1 194 16 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:194:16
	v_readfirstlane_b32 s2, v0
	.loc	1 100 22                        ; benchmark_qwen36_extend_attention_m756.py:100:22
	s_ashr_i32 s19, s16, 31
	.loc	1 206 8                         ; benchmark_qwen36_extend_attention_m756.py:206:8
	s_and_b32 s25, s2, 0xc0
	.loc	1 100 22                        ; benchmark_qwen36_extend_attention_m756.py:100:22
	s_lshl_b64 s[2:3], s[18:19], 3
	s_mov_b64 s[76:77], s[6:7]
	s_add_u32 s6, s14, s2
	s_addc_u32 s7, s15, s3
	s_mov_b64 s[80:81], s[10:11]
	s_load_dword s18, s[6:7], 0x0
	s_load_dword s19, s[6:7], 0x8
	s_load_dwordx2 s[10:11], s[0:1], 0x38
	; Restore the shared sequence byte offset for the int32 kv_indptr ABI.
	s_lshr_b64 s[2:3], s[2:3], 1
	.loc	1 105 31                        ; benchmark_qwen36_extend_attention_m756.py:105:31
	v_and_b32_e32 v56, 63, v0
	v_or_b32_e32 v4, s25, v56
	v_and_b32_e32 v43, 15, v0
	.loc	1 101 47                        ; benchmark_qwen36_extend_attention_m756.py:101:47
	s_waitcnt lgkmcnt(0)
	s_sub_i32 s75, s19, s18
	.loc	1 102 23                        ; benchmark_qwen36_extend_attention_m756.py:102:23
	s_add_u32 s2, s10, s2
	s_addc_u32 s3, s11, s3
	.loc	1 105 31                        ; benchmark_qwen36_extend_attention_m756.py:105:31
	v_lshrrev_b32_e32 v49, 4, v4
	.loc	1 115 17                        ; benchmark_qwen36_extend_attention_m756.py:115:17
	v_lshlrev_b32_e32 v50, 3, v43
	.loc	1 117 27                        ; benchmark_qwen36_extend_attention_m756.py:117:27
	s_lshl_b32 s6, s18, 12
	s_lshl_b32 s7, s17, 9
	s_add_i32 s24, s6, s7
	v_lshl_or_b32 v1, v49, 12, v50
	v_add_lshl_u32 v1, v1, s24, 1
	.loc	1 117 16 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:117:16
	v_bfrev_b32_e32 v2, 1
	.loc	1 110 26 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:110:26
	v_cmp_gt_i32_e64 s[26:27], s75, v49
	.loc	1 117 16                        ; benchmark_qwen36_extend_attention_m756.py:117:16
	s_and_b32 s21, s21, 0xffff
	s_mov_b32 s23, 0x27000
	s_mov_b32 s22, 0x7ffffffe
	v_cndmask_b32_e64 v3, v2, v1, s[26:27]
	v_or_b32_e32 v5, 0x100, v1
	v_cndmask_b32_e64 v5, v2, v5, s[26:27]
	buffer_load_dwordx4 v[10:13], v3, s[20:23], 0 offen
	buffer_load_dwordx4 v[14:17], v5, s[20:23], 0 offen
	v_or_b32_e32 v3, 0x200, v1
	v_cndmask_b32_e64 v3, v2, v3, s[26:27]
	v_or_b32_e32 v1, 0x300, v1
	v_cndmask_b32_e64 v1, v2, v1, s[26:27]
	buffer_load_dwordx4 v[18:21], v3, s[20:23], 0 offen
	buffer_load_dwordx4 v[22:25], v1, s[20:23], 0 offen
	.loc	1 105 31                        ; benchmark_qwen36_extend_attention_m756.py:105:31
	v_mov_b32_e32 v1, 0xf0
	s_movk_i32 s6, 0xf0
	v_bitop3_b32 v2, s25, v1, v56 bitop3:0xc8
	.loc	1 117 16                        ; benchmark_qwen36_extend_attention_m756.py:117:16
	v_lshlrev_b32_e32 v1, 4, v4
	v_bitop3_b32 v4, v1, v4, s6 bitop3:0x78
	.loc	1 102 23                        ; benchmark_qwen36_extend_attention_m756.py:102:23
	s_load_dwordx2 s[6:7], s[2:3], 0x0
	.loc	1 105 31                        ; benchmark_qwen36_extend_attention_m756.py:105:31
	v_and_b32_e32 v3, 48, v0
	.loc	1 117 16                        ; benchmark_qwen36_extend_attention_m756.py:117:16
	v_lshlrev_b32_e32 v6, 4, v43
	s_lshl_b32 s14, s25, 6
	s_movk_i32 s10, 0xc0
	s_movk_i32 s11, 0x80
	v_lshlrev_b32_e32 v5, 8, v43
	v_add_u32_e32 v48, 0, v4
	v_bitop3_b32 v4, s14, v6, v3 bitop3:0xf6
	v_bitop3_b32 v51, v5, v3, v6 bitop3:0x36
	v_or_b32_e32 v6, v4, v5
	v_bitop3_b32 v7, v4, s11, v5 bitop3:0x36
	v_bitop3_b32 v8, v4, s10, v5 bitop3:0x36
	.loc	1 103 52                        ; benchmark_qwen36_extend_attention_m756.py:103:52
	s_waitcnt lgkmcnt(0)
	s_sub_i32 s97, s7, s6
	v_xor_b32_e32 v52, 64, v51
	v_lshrrev_b32_e32 v2, 1, v2
	.loc	1 110 26                        ; benchmark_qwen36_extend_attention_m756.py:110:26
	v_cmp_gt_i32_e64 s[44:45], s75, v43
	.loc	1 117 16                        ; benchmark_qwen36_extend_attention_m756.py:117:16
	v_add_u32_e32 v4, 0, v6
	v_xad_u32 v5, v6, 64, 0
	v_add_u32_e32 v6, 0, v7
	v_add_u32_e32 v7, 0, v8
	.loc	1 123 40                        ; benchmark_qwen36_extend_attention_m756.py:123:40
	s_cmp_gt_i32 s97, 0
	v_and_b32_e32 v35, 60, v0
	.loc	1 117 16                        ; benchmark_qwen36_extend_attention_m756.py:117:16
	s_waitcnt vmcnt(3)
	ds_write_b128 v48, v[10:13]
	s_waitcnt vmcnt(2)
	ds_write_b128 v48, v[14:17] offset:4096
	s_waitcnt vmcnt(1)
	ds_write_b128 v48, v[18:21] offset:8192
	s_waitcnt vmcnt(0)
	ds_write_b128 v48, v[22:25] offset:12288
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 123 40                        ; benchmark_qwen36_extend_attention_m756.py:123:40
	s_cbranch_scc1 .LBB0_2
; %bb.1:                                ; %.._crit_edge_crit_edge
	.loc	1 194 16                        ; benchmark_qwen36_extend_attention_m756.py:194:16
	v_xor_b32_e32 v47, v2, v1
	.loc	1 176 24                        ; benchmark_qwen36_extend_attention_m756.py:176:24
	s_lshl_b32 s2, s17, 7
	.loc	1 179 16                        ; benchmark_qwen36_extend_attention_m756.py:179:16
	v_xor_b32_e32 v53, 0x80, v51
	v_xor_b32_e32 v54, 0xc0, v51
	.loc	1 194 16                        ; benchmark_qwen36_extend_attention_m756.py:194:16
	v_xor_b32_e32 v46, 8, v47
	v_lshlrev_b32_e32 v44, 6, v35
	v_lshlrev_b32_e32 v45, 1, v35
	s_mov_b64 s[10:11], 0
	s_branch .LBB0_3
.LBB0_2:
	.loc	1 0 16 is_stmt 0                ; benchmark_qwen36_extend_attention_m756.py:0:16
	s_mov_b64 s[10:11], -1
                                        ; implicit-def: $sgpr2
                                        ; implicit-def: $vgpr53
                                        ; implicit-def: $vgpr54
                                        ; implicit-def: $vgpr47
                                        ; implicit-def: $vgpr46
                                        ; implicit-def: $vgpr44
                                        ; implicit-def: $vgpr45
.LBB0_3:                                ; %Flow392
	ds_read_b128 v[84:87], v4
	ds_read_b128 v[80:83], v5
	ds_read_b128 v[76:79], v6
	ds_read_b128 v[72:75], v7
	s_load_dword s95, s[0:1], 0x48
	s_andn2_b64 vcc, exec, s[10:11]
	v_lshrrev_b32_e32 v55, 2, v3
	s_cbranch_vccnz .LBB0_8
; %bb.4:                                ; %.lr.ph
	s_load_dwordx2 s[84:85], s[0:1], 0x40
	.loc	1 105 31 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:105:31
	s_lshr_b32 s0, s25, 6
	s_or_b32 s1, s0, 4
	s_or_b32 s2, s0, 8
	s_or_b32 s3, s0, 12
                                        ; implicit-def: $vgpr136 : SGPR spill to VGPR lane
	.loc	1 110 26                        ; benchmark_qwen36_extend_attention_m756.py:110:26
	s_cmp_lt_i32 s0, s75
	s_mov_b32 s100, s26
	s_cselect_b64 s[78:79], -1, 0
	s_cmp_lt_i32 s1, s75
	s_mov_b32 s101, s27
	s_cselect_b64 s[88:89], -1, 0
	s_cmp_lt_i32 s2, s75
	v_and_b32_e32 v3, 3, v0
	v_writelane_b32 v136, s18, 2
	s_cselect_b64 s[90:91], -1, 0
	s_cmp_lt_i32 s3, s75
	v_xor_b32_e32 v47, v2, v1
	v_lshlrev_b32_e32 v44, 6, v35
	v_lshlrev_b32_e32 v1, 3, v3
	v_lshlrev_b32_e32 v45, 1, v35
	v_writelane_b32 v136, s19, 3
	s_cselect_b64 s[92:93], -1, 0
	.loc	1 127 36                        ; benchmark_qwen36_extend_attention_m756.py:127:36
	s_add_i32 s98, s97, s0
	s_lshl_b32 s0, s17, 7
	v_bitop3_b32 v37, v44, v45, v1 bitop3:0x36
	.loc	1 123 40                        ; benchmark_qwen36_extend_attention_m756.py:123:40
	v_add_u32_e32 v1, s25, v56
	v_writelane_b32 v136, s24, 4
	v_lshl_add_u32 v36, v3, 6, 0
	v_or_b32_e32 v4, s0, v50
	v_xor_b32_e32 v38, 32, v37
	v_xor_b32_e32 v39, 64, v37
	v_xor_b32_e32 v40, 0x60, v37
	v_lshrrev_b32_e32 v59, 4, v1
	.loc	1 127 36                        ; benchmark_qwen36_extend_attention_m756.py:127:36
	v_add_u32_e32 v57, s97, v43
	s_add_i32 s99, s98, 4
	s_add_i32 s96, s98, 8
	s_add_i32 s33, s98, 12
	s_mov_b32 s74, 0
	s_waitcnt lgkmcnt(0)
	s_and_b32 s85, s85, 0xffff
	s_mov_b32 s87, 0x27000
	s_mov_b32 s86, 0x7ffffffe
	v_writelane_b32 v136, s0, 5
	s_and_b32 s81, s81, 0xffff
	v_xor_b32_e32 v53, 0x80, v51
	v_xor_b32_e32 v54, 0xc0, v51
	s_and_b32 s13, s13, 0xffff
	v_xor_b32_e32 v46, 8, v47
	v_lshlrev_b32_e32 v58, 1, v4
	.loc	1 123 40                        ; benchmark_qwen36_extend_attention_m756.py:123:40
	s_lshl_b32 s94, s6, 3
	v_lshlrev_b32_e32 v60, 3, v59
	v_mov_b32_e32 v34, 0xff800000
	v_mov_b32_e32 v1, 0
	.loc	1 125 27                        ; benchmark_qwen36_extend_attention_m756.py:125:27
	v_mov_b32_e32 v32, 0
	v_mov_b32_e32 v33, 0
	v_mov_b32_e32 v30, 0
	v_mov_b32_e32 v31, 0
	v_mov_b32_e32 v28, 0
	v_mov_b32_e32 v29, 0
	v_mov_b32_e32 v26, 0
	v_mov_b32_e32 v27, 0
	v_mov_b32_e32 v24, 0
	v_mov_b32_e32 v25, 0
	v_mov_b32_e32 v22, 0
	v_mov_b32_e32 v23, 0
	v_mov_b32_e32 v20, 0
	v_mov_b32_e32 v21, 0
	v_mov_b32_e32 v18, 0
	v_mov_b32_e32 v19, 0
	v_mov_b32_e32 v16, 0
	v_mov_b32_e32 v17, 0
	v_mov_b32_e32 v14, 0
	v_mov_b32_e32 v15, 0
	v_mov_b32_e32 v12, 0
	v_mov_b32_e32 v13, 0
	v_mov_b32_e32 v10, 0
	v_mov_b32_e32 v11, 0
	v_mov_b32_e32 v8, 0
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v7, 0
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
	s_add_i32 s2, s25, 0
	v_add_u32_e32 v61, v36, v35
	s_mov_b32 s3, 0xc2fc0000
	v_add_u32_e32 v62, 0, v37
	v_add_u32_e32 v63, 0, v38
	v_add_u32_e32 v64, 0, v39
	v_add_u32_e32 v65, 0, v40
	v_bfrev_b32_e32 v66, 1
	v_mov_b32_e32 v67, 0xff800000
	v_mov_b32_e32 v68, 0xe0ad78ec
	v_mov_b32_e32 v69, 0x42800000
	v_not_b32_e32 v70, 63
	v_writelane_b32 v136, s25, 6
	s_branch .LBB0_6
.LBB0_5:                                ;   in Loop: Header=BB0_6 Depth=1
	.loc	1 123 40                        ; benchmark_qwen36_extend_attention_m756.py:123:40
	s_add_i32 s74, s74, 64
	s_cmp_lt_i32 s74, s97
	v_add_u32_e32 v60, 0x200, v60
	s_cbranch_scc0 .LBB0_9
.LBB0_6:                                ; =>This Inner Loop Header: Depth=1
	.loc	1 125 36                        ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_add_u32_e32 v35, s74, v56
	v_cmp_gt_i32_e32 vcc, s97, v35
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_add_u32_e32 v35, 0xfff, v35
	v_cmp_le_i32_e64 s[0:1], s98, v35
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 s[0:1], s[78:79], s[0:1]
	s_and_b64 s[0:1], vcc, s[0:1]
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_cmp_le_i32_e64 s[6:7], s99, v35
	v_cmp_le_i32_e64 s[10:11], s96, v35
	v_cmp_le_i32_e64 s[14:15], s33, v35
	.loc	1 130 48                        ; benchmark_qwen36_extend_attention_m756.py:130:48
	v_cndmask_b32_e64 v35, 0, 1, s[0:1]
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 s[6:7], s[88:89], s[6:7]
	s_and_b64 s[0:1], vcc, s[6:7]
.Ltmp2:
	.file	2 "/sgl-workspace/triton-custom/python/triton/language" "standard.py"
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ] ]
	v_max_i32_dpp v35, v35, v35 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp3:
	.loc	1 130 48                        ; benchmark_qwen36_extend_attention_m756.py:130:48
	v_cndmask_b32_e64 v36, 0, 1, s[0:1]
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 s[10:11], s[90:91], s[10:11]
.Ltmp4:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ] ]
	v_max_i32_dpp v35, v35, v35 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp5:
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 s[0:1], vcc, s[10:11]
	.loc	1 130 48                        ; benchmark_qwen36_extend_attention_m756.py:130:48
	v_cndmask_b32_e64 v37, 0, 1, s[0:1]
.Ltmp6:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ] ]
	v_max_i32_dpp v35, v35, v35 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp7:
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 s[14:15], s[92:93], s[14:15]
	s_and_b64 s[0:1], vcc, s[14:15]
.Ltmp8:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ] ]
	v_max_i32_dpp v35, v35, v35 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp9:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ]
	v_mov_b32_e32 v39, v35
.Ltmp10:
	.loc	1 130 48                        ; benchmark_qwen36_extend_attention_m756.py:130:48
	v_cndmask_b32_e64 v38, 0, 1, s[0:1]
.Ltmp11:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:27 ]
	s_waitcnt lgkmcnt(0)
.Ltmp12:
	.loc	2 191 40 is_stmt 0              ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ]
	v_mov_b32_dpp v39, v39 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp13:
	.loc	2 170 27 is_stmt 1              ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ] ]
	v_max_i32_e32 v35, v35, v39
.Ltmp14:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:27 ]
	s_barrier
.Ltmp15:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ] ]
	s_nop 0
	v_max_i32_dpp v35, v35, v35 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp16:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ]
	s_nop 0
	v_readlane_b32 s16, v35, 63
.Ltmp17:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ] ]
	v_max_i32_dpp v35, v36, v36 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v35, v35, v35 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v35, v35, v35 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v35, v35, v35 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp18:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ]
	v_mov_b32_e32 v36, v35
	s_nop 1
	v_mov_b32_dpp v36, v36 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp19:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ] ]
	v_max_i32_e32 v35, v35, v36
	s_nop 1
	v_max_i32_dpp v35, v35, v35 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp20:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ]
	s_nop 0
	v_readlane_b32 s17, v35, 63
.Ltmp21:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ] ]
	v_max_i32_dpp v35, v37, v37 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v35, v35, v35 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v35, v35, v35 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v35, v35, v35 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp22:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ]
	v_mov_b32_e32 v36, v35
	s_nop 1
	v_mov_b32_dpp v36, v36 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp23:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ] ]
	v_max_i32_e32 v35, v35, v36
	s_nop 1
	v_max_i32_dpp v35, v35, v35 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp24:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ]
	s_nop 0
	v_readlane_b32 s18, v35, 63
.Ltmp25:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ] ]
	v_max_i32_dpp v35, v38, v38 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v35, v35, v35 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v35, v35, v35 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v35, v35, v35 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp26:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ]
	v_mov_b32_e32 v36, v35
	s_nop 1
	v_mov_b32_dpp v36, v36 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp27:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ] ]
	v_max_i32_e32 v35, v35, v36
	s_nop 1
	v_max_i32_dpp v35, v35, v35 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp28:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:34 ]
	s_nop 0
	v_readlane_b32 s19, v35, 63
.Ltmp29:
	.loc	2 191 40 is_stmt 0              ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:27 ]
	v_mov_b32_e32 v35, s2
	s_nop 0
	v_mov_b64_e32 v[38:39], s[18:19]
	v_mov_b64_e32 v[36:37], s[16:17]
	ds_write_b128 v35, v[36:39]
	ds_write_b128 v35, v[36:39] offset:16
	ds_write_b128 v35, v[36:39] offset:32
	ds_write_b128 v35, v[36:39] offset:48
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b32 v35, v61
.Ltmp30:
	.loc	2 170 27 is_stmt 1              ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:27 ] ]
	s_waitcnt lgkmcnt(0)
	s_nop 0
	v_max_i32_dpp v35, v35, v35 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v35, v35, v35 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v35, v35, v35 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v35, v35, v35 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp31:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:27 ]
	v_mov_b32_e32 v36, v35
	s_nop 1
	v_mov_b32_dpp v36, v36 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp32:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:27 ] ]
	v_max_i32_e32 v35, v35, v36
	s_nop 1
	v_max_i32_dpp v35, v35, v35 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp33:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:130:27 ]
	s_nop 0
	v_readlane_b32 s0, v35, 63
.Ltmp34:
	.loc	1 0 0 is_stmt 0                 ; benchmark_qwen36_extend_attention_m756.py:0
	s_cmp_eq_u32 s0, 0
	.loc	1 131 11 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:131:11
	s_cbranch_scc1 .LBB0_5
; %bb.7:                                ;   in Loop: Header=BB0_6 Depth=1
	.loc	1 125 36                        ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_add_u32_e32 v35, s74, v59
	.loc	1 133 16                        ; benchmark_qwen36_extend_attention_m756.py:133:16
	v_add_u32_e32 v41, s94, v60
	.loc	1 125 36                        ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e32 vcc, s97, v35
	v_add_u32_e32 v38, 48, v35
	v_add_u32_e32 v39, 32, v35
	v_add_u32_e32 v40, 16, v35
	.loc	1 133 16                        ; benchmark_qwen36_extend_attention_m756.py:133:16
	v_cndmask_b32_e32 v35, v66, v41, vcc
	buffer_load_dwordx2 v[36:37], v35, s[84:87], 0 offen
	v_add_u32_e32 v35, 0x80, v41
	.loc	1 125 36                        ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e64 s[0:1], s97, v40
	.loc	1 133 16                        ; benchmark_qwen36_extend_attention_m756.py:133:16
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v37, 0x100, v41
	.loc	1 125 36                        ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e64 s[6:7], s97, v39
	.loc	1 133 16                        ; benchmark_qwen36_extend_attention_m756.py:133:16
	v_cndmask_b32_e64 v35, v66, v35, s[0:1]
	v_add_u32_e32 v39, 0x180, v41
	.loc	1 125 36                        ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e64 s[10:11], s97, v38
	.loc	1 133 16                        ; benchmark_qwen36_extend_attention_m756.py:133:16
	v_cndmask_b32_e64 v37, v66, v37, s[6:7]
	.loc	1 143 16                        ; benchmark_qwen36_extend_attention_m756.py:143:16
	s_mov_b32 s82, s86
	.loc	1 133 16                        ; benchmark_qwen36_extend_attention_m756.py:133:16
	v_cndmask_b32_e64 v42, v66, v39, s[10:11]
	buffer_load_dwordx2 v[38:39], v35, s[84:87], 0 offen
	buffer_load_dwordx2 v[40:41], v37, s[84:87], 0 offen
	buffer_load_dwordx2 v[88:89], v42, s[84:87], 0 offen
	.loc	1 143 16                        ; benchmark_qwen36_extend_attention_m756.py:143:16
	s_mov_b32 s83, s87
	s_waitcnt vmcnt(0)
	; The live KV pool is larger than 2 GiB.  The original Triton-derived
	; buffer descriptors bounded every cache load to 0x7ffffffe bytes, so
	; recycled token slots above 1,048,575 silently read zero.  Preserve full
	; 64-bit byte addresses for the four cache locations and use global loads.
	; Mask invalid tail lanes before widening. Buffer OOB loads do not provide a
	; usable int64 high dword, while every live cache slot fits in uint32.
	v_cndmask_b32_e32 v138, 0, v36, vcc
	v_cndmask_b32_e64 v140, 0, v38, s[0:1]
	v_cndmask_b32_e64 v142, 0, v40, s[6:7]
	v_cndmask_b32_e64 v144, 0, v88, s[10:11]
	v_lshrrev_b32_e32 v139, 21, v138
	v_lshrrev_b32_e32 v141, 21, v140
	v_lshrrev_b32_e32 v143, 21, v142
	v_lshrrev_b32_e32 v145, 21, v144
	v_lshlrev_b32_e32 v138, 11, v138
	v_lshlrev_b32_e32 v140, 11, v140
	v_lshlrev_b32_e32 v142, 11, v142
	v_lshlrev_b32_e32 v144, 11, v144
	v_add_co_u32 v138, vcc, v138, v58
	v_addc_co_u32 v139, vcc, v139, 0, vcc
	v_add_co_u32 v140, vcc, v140, v58
	v_addc_co_u32 v141, vcc, v141, 0, vcc
	v_add_co_u32 v142, vcc, v142, v58
	v_addc_co_u32 v143, vcc, v143, 0, vcc
	v_add_co_u32 v144, vcc, v144, v58
	v_addc_co_u32 v145, vcc, v145, 0, vcc
	v_mov_b64_e32 v[146:147], v[138:139]
	v_mov_b64_e32 v[148:149], v[140:141]
	v_mov_b64_e32 v[150:151], v[142:143]
	v_mov_b64_e32 v[152:153], v[144:145]
	v_mov_b32_e32 v154, s81
	v_mov_b32_e32 v155, s13
	v_add_co_u32 v138, vcc, v138, s80
	v_addc_co_u32 v139, vcc, v139, v154, vcc
	v_add_co_u32 v140, vcc, v140, s80
	v_addc_co_u32 v141, vcc, v141, v154, vcc
	v_add_co_u32 v142, vcc, v142, s80
	v_addc_co_u32 v143, vcc, v143, v154, vcc
	v_add_co_u32 v144, vcc, v144, s80
	v_addc_co_u32 v145, vcc, v145, v154, vcc
	v_add_co_u32 v146, vcc, v146, s12
	v_addc_co_u32 v147, vcc, v147, v155, vcc
	v_add_co_u32 v148, vcc, v148, s12
	v_addc_co_u32 v149, vcc, v149, v155, vcc
	v_add_co_u32 v150, vcc, v150, s12
	v_addc_co_u32 v151, vcc, v151, v155, vcc
	v_add_co_u32 v152, vcc, v152, s12
	v_addc_co_u32 v153, vcc, v153, v155, vcc
	v_add_u32_e32 v41, 0, v52
	v_add_u32_e32 v42, 0, v53
	v_add_u32_e32 v71, 0, v54
	v_lshl_add_u32 v35, v36, 11, v58
	v_cndmask_b32_e32 v35, v66, v35, vcc
	v_lshl_add_u32 v36, v38, 11, v58
	v_lshl_add_u32 v38, v40, 11, v58
	s_waitcnt vmcnt(0)
	v_lshl_add_u32 v39, v88, 11, v58
	v_cndmask_b32_e64 v37, v66, v36, s[0:1]
	v_cndmask_b32_e64 v36, v66, v38, s[6:7]
	v_cndmask_b32_e64 v38, v66, v39, s[10:11]
	global_load_dwordx4 v[120:123], v[138:139], off
	global_load_dwordx4 v[124:127], v[140:141], off
	global_load_dwordx4 v[128:131], v[142:143], off
	global_load_dwordx4 v[132:135], v[144:145], off
	.loc	1 125 27                        ; benchmark_qwen36_extend_attention_m756.py:125:27
	v_add_u32_e32 v39, s74, v55
	.loc	1 143 16                        ; benchmark_qwen36_extend_attention_m756.py:143:16
	v_add_u32_e32 v40, 0, v51
	.loc	1 128 40                        ; benchmark_qwen36_extend_attention_m756.py:128:40
	v_add_u32_e32 v88, 51, v39
	.loc	1 128 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_add_u32_e32 v89, 0x1032, v39
	.loc	1 128 40                        ; benchmark_qwen36_extend_attention_m756.py:128:40
	v_add_u32_e32 v90, 50, v39
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_add_u32_e32 v91, 0x1031, v39
	.loc	1 128 40                        ; benchmark_qwen36_extend_attention_m756.py:128:40
	v_add_u32_e32 v92, 49, v39
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_add_u32_e32 v93, 0x1030, v39
	.loc	1 128 40                        ; benchmark_qwen36_extend_attention_m756.py:128:40
	v_add_u32_e32 v94, 48, v39
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_add_u32_e32 v95, 0x102f, v39
	v_cmp_le_i32_e64 s[20:21], v57, v89
	.loc	1 125 36 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e64 s[22:23], s97, v88
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_cmp_le_i32_e64 s[24:25], v57, v91
	.loc	1 125 36                        ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e64 s[26:27], s97, v90
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_cmp_le_i32_e64 s[6:7], v57, v93
	.loc	1 125 36                        ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e64 s[10:11], s97, v92
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_cmp_le_i32_e64 s[14:15], v57, v95
	.loc	1 125 36                        ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e64 s[18:19], s97, v94
	.loc	1 143 16                        ; benchmark_qwen36_extend_attention_m756.py:143:16
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 128 40                        ; benchmark_qwen36_extend_attention_m756.py:128:40
	v_add_u32_e32 v104, 19, v39
	.loc	1 128 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_add_u32_e32 v105, 0x1012, v39
	.loc	1 128 40                        ; benchmark_qwen36_extend_attention_m756.py:128:40
	v_add_u32_e32 v106, 18, v39
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_add_u32_e32 v107, 0x1011, v39
	v_cmp_le_i32_e64 s[42:43], v57, v105
	.loc	1 125 36 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e64 s[46:47], s97, v104
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_cmp_le_i32_e64 s[48:49], v57, v107
	.loc	1 125 36                        ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e64 s[50:51], s97, v106
	.loc	1 128 40                        ; benchmark_qwen36_extend_attention_m756.py:128:40
	v_add_u32_e32 v96, 35, v39
	.loc	1 128 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_add_u32_e32 v97, 0x1022, v39
	.loc	1 128 40                        ; benchmark_qwen36_extend_attention_m756.py:128:40
	v_add_u32_e32 v98, 34, v39
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_add_u32_e32 v99, 0x1021, v39
	.loc	1 128 40                        ; benchmark_qwen36_extend_attention_m756.py:128:40
	v_add_u32_e32 v100, 33, v39
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_add_u32_e32 v101, 0x1020, v39
	.loc	1 128 40                        ; benchmark_qwen36_extend_attention_m756.py:128:40
	v_add_u32_e32 v102, 32, v39
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_add_u32_e32 v103, 0x101f, v39
	v_cmp_le_i32_e64 s[0:1], v57, v97
	.loc	1 125 36 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e64 s[36:37], s97, v96
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_cmp_le_i32_e64 s[38:39], v57, v99
	.loc	1 125 36                        ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e64 s[40:41], s97, v98
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_cmp_le_i32_e64 s[28:29], v57, v101
	.loc	1 125 36                        ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e64 s[30:31], s97, v100
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_cmp_le_i32_e64 s[34:35], v57, v103
	.loc	1 125 36                        ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e64 s[16:17], s97, v102
	.loc	1 128 40                        ; benchmark_qwen36_extend_attention_m756.py:128:40
	v_add_u32_e32 v108, 17, v39
	.loc	1 128 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_add_u32_e32 v109, 0x1010, v39
	.loc	1 128 40                        ; benchmark_qwen36_extend_attention_m756.py:128:40
	v_add_u32_e32 v110, 16, v39
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_add_u32_e32 v111, 0x100f, v39
	.loc	1 128 40                        ; benchmark_qwen36_extend_attention_m756.py:128:40
	v_add_u32_e32 v112, 3, v39
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_add_u32_e32 v113, 0x1002, v39
	.loc	1 128 40                        ; benchmark_qwen36_extend_attention_m756.py:128:40
	v_add_u32_e32 v114, 2, v39
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_add_u32_e32 v115, 0x1001, v39
	v_cmp_le_i32_e64 s[52:53], v57, v109
	.loc	1 125 36 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e64 s[54:55], s97, v108
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_cmp_le_i32_e64 s[56:57], v57, v111
	.loc	1 125 36                        ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e64 s[58:59], s97, v110
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_cmp_le_i32_e64 s[60:61], v57, v113
	.loc	1 125 36                        ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e64 s[62:63], s97, v112
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_cmp_le_i32_e64 s[64:65], v57, v115
	.loc	1 125 36                        ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e64 s[66:67], s97, v114
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_add_u32_e32 v118, 0xfff, v39
	.loc	1 128 40 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:128:40
	v_add_u32_e32 v116, 1, v39
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_add_u32_e32 v117, 0x1000, v39
	.loc	1 143 16 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:143:16
	s_waitcnt vmcnt(3)
	ds_write_b128 v48, v[120:123]
	s_waitcnt vmcnt(2)
	ds_write_b128 v48, v[124:127] offset:4096
	s_waitcnt vmcnt(1)
	ds_write_b128 v48, v[128:131] offset:8192
	s_waitcnt vmcnt(0)
	ds_write_b128 v48, v[132:135] offset:12288
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[88:91], v40
	ds_read_b128 v[92:95], v40 offset:4096
	ds_read_b128 v[120:123], v41
	ds_read_b128 v[104:107], v41 offset:4096
	ds_read_b128 v[96:99], v40 offset:8192
	ds_read_b128 v[100:103], v40 offset:12288
	.loc	1 147 27                        ; benchmark_qwen36_extend_attention_m756.py:147:27
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x32_bf16 v[92:95], v[92:95], v[84:87], 0
	.loc	1 143 16                        ; benchmark_qwen36_extend_attention_m756.py:143:16
	ds_read_b128 v[124:127], v41 offset:8192
	ds_read_b128 v[108:111], v41 offset:12288
	ds_read_b128 v[112:115], v42 offset:4096
	.loc	1 147 27                        ; benchmark_qwen36_extend_attention_m756.py:147:27
	s_waitcnt lgkmcnt(5)
	v_mfma_f32_16x16x32_bf16 v[92:95], v[104:107], v[80:83], v[92:95]
	.loc	1 143 16                        ; benchmark_qwen36_extend_attention_m756.py:143:16
	ds_read_b128 v[104:107], v42
	.loc	1 125 36                        ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e32 vcc, s97, v39
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_cmp_le_i32_e64 s[72:73], v57, v118
	.loc	1 147 27                        ; benchmark_qwen36_extend_attention_m756.py:147:27
	v_mfma_f32_16x16x32_bf16 v[88:91], v[88:91], v[84:87], 0
	.loc	1 128 12                        ; benchmark_qwen36_extend_attention_m756.py:128:12
	v_cmp_le_i32_e64 s[68:69], v57, v117
	.loc	1 125 36                        ; benchmark_qwen36_extend_attention_m756.py:125:36
	v_cmp_gt_i32_e64 s[70:71], s97, v116
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 s[6:7], s[10:11], s[6:7]
	.loc	1 147 27                        ; benchmark_qwen36_extend_attention_m756.py:147:27
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x32_bf16 v[100:103], v[100:103], v[84:87], 0
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 s[10:11], s[18:19], s[14:15]
	s_and_b64 s[14:15], s[40:41], s[38:39]
	s_and_b64 s[40:41], vcc, s[72:73]
	.loc	1 147 27                        ; benchmark_qwen36_extend_attention_m756.py:147:27
	v_mfma_f32_16x16x32_bf16 v[88:91], v[120:123], v[80:83], v[88:91]
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 s[38:39], s[70:71], s[68:69]
	s_and_b64 vcc, s[44:45], s[40:41]
	s_and_b64 s[0:1], s[36:37], s[0:1]
	.loc	1 147 27                        ; benchmark_qwen36_extend_attention_m756.py:147:27
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[100:103], v[108:111], v[80:83], v[100:103]
	.loc	1 143 16                        ; benchmark_qwen36_extend_attention_m756.py:143:16
	ds_read_b128 v[108:111], v42 offset:8192
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 s[36:37], s[66:67], s[64:65]
	s_and_b64 s[16:17], s[16:17], s[34:35]
	.loc	1 147 27                        ; benchmark_qwen36_extend_attention_m756.py:147:27
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[88:91], v[104:107], v[76:79], v[88:91]
	.loc	1 143 16                        ; benchmark_qwen36_extend_attention_m756.py:143:16
	ds_read_b128 v[104:107], v42 offset:12288
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 s[34:35], s[62:63], s[60:61]
	s_and_b64 s[18:19], s[30:31], s[28:29]
	.loc	1 147 27                        ; benchmark_qwen36_extend_attention_m756.py:147:27
	v_mfma_f32_16x16x32_bf16 v[96:99], v[96:99], v[84:87], 0
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 s[30:31], s[58:59], s[56:57]
	s_and_b64 s[28:29], s[54:55], s[52:53]
	s_and_b64 s[20:21], s[22:23], s[20:21]
	.loc	1 147 27                        ; benchmark_qwen36_extend_attention_m756.py:147:27
	v_mfma_f32_16x16x32_bf16 v[92:95], v[112:115], v[76:79], v[92:95]
	.loc	1 143 16                        ; benchmark_qwen36_extend_attention_m756.py:143:16
	ds_read_b128 v[112:115], v71
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 s[22:23], s[26:27], s[24:25]
	s_and_b64 s[26:27], s[50:51], s[48:49]
	.loc	1 147 27                        ; benchmark_qwen36_extend_attention_m756.py:147:27
	v_mfma_f32_16x16x32_bf16 v[96:99], v[124:127], v[80:83], v[96:99]
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 s[24:25], s[46:47], s[42:43]
	.loc	1 147 27                        ; benchmark_qwen36_extend_attention_m756.py:147:27
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[96:99], v[108:111], v[76:79], v[96:99]
	.loc	1 143 16                        ; benchmark_qwen36_extend_attention_m756.py:143:16
	ds_read_b128 v[108:111], v71 offset:4096
	.loc	1 147 27                        ; benchmark_qwen36_extend_attention_m756.py:147:27
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[100:103], v[104:107], v[76:79], v[100:103]
	.loc	1 143 16                        ; benchmark_qwen36_extend_attention_m756.py:143:16
	ds_read_b128 v[104:107], v71 offset:8192
	.loc	1 147 27                        ; benchmark_qwen36_extend_attention_m756.py:147:27
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[88:91], v[112:115], v[72:75], v[88:91]
	.loc	1 143 16                        ; benchmark_qwen36_extend_attention_m756.py:143:16
	ds_read_b128 v[112:115], v71 offset:12288
	.loc	1 147 27                        ; benchmark_qwen36_extend_attention_m756.py:147:27
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[92:95], v[108:111], v[72:75], v[92:95]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[96:99], v[104:107], v[72:75], v[96:99]
	.loc	1 147 54 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:147:54
	s_nop 2
	v_mul_f32_e32 v39, s95, v88
	v_mul_f32_e32 v40, s95, v89
	.loc	1 148 42 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:148:42
	v_cndmask_b32_e32 v39, v67, v39, vcc
	.loc	1 147 27                        ; benchmark_qwen36_extend_attention_m756.py:147:27
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[100:103], v[112:115], v[72:75], v[100:103]
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 vcc, s[44:45], s[38:39]
	.loc	1 147 54                        ; benchmark_qwen36_extend_attention_m756.py:147:54
	v_mul_f32_e32 v41, s95, v90
	.loc	1 148 42                        ; benchmark_qwen36_extend_attention_m756.py:148:42
	v_cndmask_b32_e32 v40, v67, v40, vcc
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 vcc, s[44:45], s[36:37]
	.loc	1 147 54                        ; benchmark_qwen36_extend_attention_m756.py:147:54
	v_mul_f32_e32 v42, s95, v91
	.loc	1 148 42                        ; benchmark_qwen36_extend_attention_m756.py:148:42
	v_cndmask_b32_e32 v41, v67, v41, vcc
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 vcc, s[44:45], s[34:35]
	.loc	1 147 54                        ; benchmark_qwen36_extend_attention_m756.py:147:54
	v_mul_f32_e32 v71, s95, v92
	v_mul_f32_e32 v89, s95, v94
	v_mul_f32_e32 v94, s95, v99
	.loc	1 148 42                        ; benchmark_qwen36_extend_attention_m756.py:148:42
	v_cndmask_b32_e32 v99, v67, v42, vcc
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 vcc, s[44:45], s[30:31]
	.loc	1 147 54                        ; benchmark_qwen36_extend_attention_m756.py:147:54
	v_mul_f32_e32 v88, s95, v93
	v_mul_f32_e32 v90, s95, v95
	v_mul_f32_e32 v95, s95, v100
	.loc	1 148 42                        ; benchmark_qwen36_extend_attention_m756.py:148:42
	v_cndmask_b32_e32 v100, v67, v71, vcc
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 vcc, s[44:45], s[28:29]
	.loc	1 148 42                        ; benchmark_qwen36_extend_attention_m756.py:148:42
	v_cndmask_b32_e32 v88, v67, v88, vcc
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 vcc, s[44:45], s[26:27]
	.loc	1 148 42                        ; benchmark_qwen36_extend_attention_m756.py:148:42
	v_cndmask_b32_e32 v89, v67, v89, vcc
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 vcc, s[44:45], s[24:25]
	.loc	1 147 54                        ; benchmark_qwen36_extend_attention_m756.py:147:54
	v_mul_f32_e32 v91, s95, v96
	.loc	1 148 42                        ; benchmark_qwen36_extend_attention_m756.py:148:42
	v_cndmask_b32_e32 v90, v67, v90, vcc
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 vcc, s[44:45], s[16:17]
	.loc	1 147 54                        ; benchmark_qwen36_extend_attention_m756.py:147:54
	v_mul_f32_e32 v92, s95, v97
	.loc	1 148 42                        ; benchmark_qwen36_extend_attention_m756.py:148:42
	v_cndmask_b32_e32 v91, v67, v91, vcc
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 vcc, s[44:45], s[18:19]
	.loc	1 147 54                        ; benchmark_qwen36_extend_attention_m756.py:147:54
	v_mul_f32_e32 v93, s95, v98
	.loc	1 148 42                        ; benchmark_qwen36_extend_attention_m756.py:148:42
	v_cndmask_b32_e32 v92, v67, v92, vcc
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 vcc, s[44:45], s[14:15]
.Ltmp35:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:149:29 ] ]
	v_max_f32_e32 v42, v39, v40
.Ltmp36:
	.loc	1 148 42                        ; benchmark_qwen36_extend_attention_m756.py:148:42
	v_cndmask_b32_e32 v93, v67, v93, vcc
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 vcc, s[44:45], s[0:1]
.Ltmp37:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:149:29 ] ]
	v_max3_f32 v42, v42, v41, v99
.Ltmp38:
	.loc	1 148 42                        ; benchmark_qwen36_extend_attention_m756.py:148:42
	v_cndmask_b32_e32 v94, v67, v94, vcc
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 vcc, s[44:45], s[10:11]
.Ltmp39:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:149:29 ] ]
	v_max3_f32 v42, v42, v100, v88
.Ltmp40:
	.loc	1 147 54                        ; benchmark_qwen36_extend_attention_m756.py:147:54
	v_mul_f32_e32 v96, s95, v101
	.loc	1 148 42                        ; benchmark_qwen36_extend_attention_m756.py:148:42
	v_cndmask_b32_e32 v95, v67, v95, vcc
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 vcc, s[44:45], s[6:7]
.Ltmp41:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:149:29 ] ]
	v_max3_f32 v42, v42, v89, v90
.Ltmp42:
	.loc	1 147 54                        ; benchmark_qwen36_extend_attention_m756.py:147:54
	v_mul_f32_e32 v97, s95, v102
	.loc	1 148 42                        ; benchmark_qwen36_extend_attention_m756.py:148:42
	v_cndmask_b32_e32 v96, v67, v96, vcc
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 vcc, s[44:45], s[22:23]
.Ltmp43:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:149:29 ] ]
	v_max3_f32 v42, v42, v91, v92
.Ltmp44:
	.loc	1 147 54                        ; benchmark_qwen36_extend_attention_m756.py:147:54
	v_mul_f32_e32 v98, s95, v103
	.loc	1 148 42                        ; benchmark_qwen36_extend_attention_m756.py:148:42
	v_cndmask_b32_e32 v97, v67, v97, vcc
	.loc	1 127 22                        ; benchmark_qwen36_extend_attention_m756.py:127:22
	s_and_b64 vcc, s[44:45], s[20:21]
.Ltmp45:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:149:29 ] ]
	v_max3_f32 v42, v42, v93, v94
.Ltmp46:
	.loc	1 148 42                        ; benchmark_qwen36_extend_attention_m756.py:148:42
	v_cndmask_b32_e32 v98, v67, v98, vcc
.Ltmp47:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:149:29 ] ]
	v_max3_f32 v42, v42, v95, v96
	v_max3_f32 v42, v42, v97, v98
.Ltmp48:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:149:29 ]
	v_mov_b32_e32 v71, v42
	s_nop 1
	v_permlane32_swap_b32_e32 v42, v71
.Ltmp49:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:149:29 ] ]
	v_max_f32_e32 v71, v71, v71
	v_max_f32_e32 v42, v42, v42
	v_max_f32_e32 v42, v42, v71
.Ltmp50:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:149:29 ]
	v_mov_b32_e32 v71, v42
	s_nop 1
	v_permlane16_swap_b32_e32 v42, v71
.Ltmp51:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:149:29 ] ]
	v_max_f32_e32 v71, v71, v71
	v_max_f32_e32 v42, v42, v42
	v_max_f32_e32 v42, v42, v71
	s_mov_b32 s0, 0xff800000
.Ltmp52:
	.loc	1 150 66                        ; benchmark_qwen36_extend_attention_m756.py:150:66
	v_cmp_neq_f32_e32 vcc, s0, v42
	.loc	1 151 43                        ; benchmark_qwen36_extend_attention_m756.py:151:43
	v_max_f32_e32 v71, v34, v34
	.loc	1 162 16                        ; benchmark_qwen36_extend_attention_m756.py:162:16
	s_mov_b32 s14, s86
	.loc	1 150 66                        ; benchmark_qwen36_extend_attention_m756.py:150:66
	v_cndmask_b32_e32 v42, v68, v42, vcc
	.loc	1 151 43                        ; benchmark_qwen36_extend_attention_m756.py:151:43
	v_max_f32_e32 v71, v42, v71
	.loc	1 152 37                        ; benchmark_qwen36_extend_attention_m756.py:152:37
	v_sub_f32_e32 v34, v34, v71
	.loc	1 152 29 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:152:29
	v_mul_f32_e32 v42, 0x3fb8aa3b, v34
	v_cmp_gt_f32_e32 vcc, s3, v42
	.loc	1 153 40 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:153:40
	v_sub_f32_e32 v104, v91, v71
	v_sub_f32_e32 v88, v88, v71
	.loc	1 152 29                        ; benchmark_qwen36_extend_attention_m756.py:152:29
	v_cndmask_b32_e32 v42, 0, v69, vcc
	v_fmac_f32_e32 v42, 0x3fb8aa3b, v34
	v_exp_f32_e32 v34, v42
	v_cndmask_b32_e32 v42, 0, v70, vcc
	.loc	1 153 40                        ; benchmark_qwen36_extend_attention_m756.py:153:40
	v_sub_f32_e32 v105, v92, v71
	.loc	1 153 35 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:153:35
	v_mul_f32_e32 v92, 0x3fb8aa3b, v88
	.loc	1 152 29 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:152:29
	v_ldexp_f32 v42, v34, v42
	.loc	1 153 40                        ; benchmark_qwen36_extend_attention_m756.py:153:40
	v_sub_f32_e32 v34, v39, v71
	.loc	1 153 35 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:153:35
	v_mul_f32_e32 v91, 0x3fb8aa3b, v34
	v_cmp_gt_f32_e32 vcc, s3, v91
	.loc	1 153 40                        ; benchmark_qwen36_extend_attention_m756.py:153:40
	v_sub_f32_e32 v39, v40, v71
	v_sub_f32_e32 v40, v41, v71
	.loc	1 153 35                        ; benchmark_qwen36_extend_attention_m756.py:153:35
	v_cndmask_b32_e32 v91, 0, v69, vcc
	v_fmac_f32_e32 v91, 0x3fb8aa3b, v34
	v_exp_f32_e32 v34, v91
	v_mul_f32_e32 v91, 0x3fb8aa3b, v39
	v_cmp_gt_f32_e64 s[0:1], s3, v91
	.loc	1 153 40                        ; benchmark_qwen36_extend_attention_m756.py:153:40
	v_sub_f32_e32 v41, v99, v71
	v_sub_f32_e32 v99, v100, v71
	.loc	1 153 35                        ; benchmark_qwen36_extend_attention_m756.py:153:35
	v_cndmask_b32_e64 v91, 0, v69, s[0:1]
	v_fmac_f32_e32 v91, 0x3fb8aa3b, v39
	v_exp_f32_e32 v39, v91
	v_cndmask_b32_e32 v91, 0, v70, vcc
	v_ldexp_f32 v34, v34, v91
	v_cndmask_b32_e64 v91, 0, v70, s[0:1]
	v_ldexp_f32 v39, v39, v91
	v_mul_f32_e32 v91, 0x3fb8aa3b, v40
	v_cmp_gt_f32_e32 vcc, s3, v91
	.loc	1 153 40                        ; benchmark_qwen36_extend_attention_m756.py:153:40
	v_sub_f32_e32 v89, v89, v71
	v_sub_f32_e32 v90, v90, v71
	.loc	1 153 35                        ; benchmark_qwen36_extend_attention_m756.py:153:35
	v_cndmask_b32_e32 v91, 0, v69, vcc
	v_fmac_f32_e32 v91, 0x3fb8aa3b, v40
	v_exp_f32_e32 v40, v91
	v_mul_f32_e32 v91, 0x3fb8aa3b, v41
	v_cmp_gt_f32_e64 s[0:1], s3, v91
	.loc	1 162 16 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:162:16
	s_mov_b32 s15, s87
	.loc	1 153 40                        ; benchmark_qwen36_extend_attention_m756.py:153:40
	v_sub_f32_e32 v106, v93, v71
	.loc	1 153 35 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:153:35
	v_cndmask_b32_e64 v91, 0, v69, s[0:1]
	v_fmac_f32_e32 v91, 0x3fb8aa3b, v41
	v_exp_f32_e32 v41, v91
	v_cndmask_b32_e32 v91, 0, v70, vcc
	v_ldexp_f32 v40, v40, v91
	v_cndmask_b32_e64 v91, 0, v70, s[0:1]
	v_ldexp_f32 v41, v41, v91
	v_mul_f32_e32 v91, 0x3fb8aa3b, v99
	v_cmp_gt_f32_e32 vcc, s3, v91
	v_cmp_gt_f32_e64 s[0:1], s3, v92
	.loc	1 153 40                        ; benchmark_qwen36_extend_attention_m756.py:153:40
	v_sub_f32_e32 v107, v94, v71
	.loc	1 153 35                        ; benchmark_qwen36_extend_attention_m756.py:153:35
	v_cndmask_b32_e32 v91, 0, v69, vcc
	v_fmac_f32_e32 v91, 0x3fb8aa3b, v99
	v_cndmask_b32_e64 v92, 0, v69, s[0:1]
	v_exp_f32_e32 v91, v91
	v_fmac_f32_e32 v92, 0x3fb8aa3b, v88
	v_exp_f32_e32 v88, v92
	v_cndmask_b32_e32 v92, 0, v70, vcc
	v_ldexp_f32 v112, v91, v92
	v_cndmask_b32_e64 v91, 0, v70, s[0:1]
	v_ldexp_f32 v113, v88, v91
	v_mul_f32_e32 v88, 0x3fb8aa3b, v89
	v_cmp_gt_f32_e32 vcc, s3, v88
	.loc	1 153 40                        ; benchmark_qwen36_extend_attention_m756.py:153:40
	v_sub_f32_e32 v108, v95, v71
	v_sub_f32_e32 v109, v96, v71
	.loc	1 153 35                        ; benchmark_qwen36_extend_attention_m756.py:153:35
	v_cndmask_b32_e32 v88, 0, v69, vcc
	v_fmac_f32_e32 v88, 0x3fb8aa3b, v89
	v_exp_f32_e32 v114, v88
	v_mul_f32_e32 v88, 0x3fb8aa3b, v90
	v_cmp_gt_f32_e64 s[0:1], s3, v88
	.loc	1 153 40                        ; benchmark_qwen36_extend_attention_m756.py:153:40
	v_sub_f32_e32 v110, v97, v71
	v_sub_f32_e32 v111, v98, v71
	.loc	1 153 35                        ; benchmark_qwen36_extend_attention_m756.py:153:35
	v_cndmask_b32_e64 v115, 0, v69, s[0:1]
	v_fmac_f32_e32 v115, 0x3fb8aa3b, v90
	.loc	1 162 16 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:162:16
	global_load_dwordx4 v[88:91], v[146:147], off
	global_load_dwordx4 v[92:95], v[148:149], off
	global_load_dwordx4 v[96:99], v[150:151], off
	global_load_dwordx4 v[100:103], v[152:153], off
	.loc	1 153 35                        ; benchmark_qwen36_extend_attention_m756.py:153:35
	v_exp_f32_e32 v35, v115
	v_cndmask_b32_e32 v36, 0, v70, vcc
	v_ldexp_f32 v37, v114, v36
	v_cndmask_b32_e64 v36, 0, v70, s[0:1]
	v_ldexp_f32 v114, v35, v36
	v_mul_f32_e32 v35, 0x3fb8aa3b, v104
	v_cmp_gt_f32_e32 vcc, s3, v35
	v_mul_f32_e32 v36, 0x3fb8aa3b, v105
	v_cmp_gt_f32_e64 s[0:1], s3, v36
	v_cndmask_b32_e32 v35, 0, v69, vcc
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v104
	v_cndmask_b32_e64 v36, 0, v69, s[0:1]
	v_exp_f32_e32 v35, v35
	v_fmac_f32_e32 v36, 0x3fb8aa3b, v105
	v_exp_f32_e32 v36, v36
	v_cndmask_b32_e32 v38, 0, v70, vcc
	v_ldexp_f32 v104, v35, v38
	v_cndmask_b32_e64 v35, 0, v70, s[0:1]
	v_ldexp_f32 v105, v36, v35
	v_mul_f32_e32 v35, 0x3fb8aa3b, v106
	v_cmp_gt_f32_e32 vcc, s3, v35
	v_mul_f32_e32 v36, 0x3fb8aa3b, v107
	v_cmp_gt_f32_e64 s[0:1], s3, v36
	v_cndmask_b32_e32 v35, 0, v69, vcc
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v106
	v_cndmask_b32_e64 v36, 0, v69, s[0:1]
	v_exp_f32_e32 v35, v35
	v_fmac_f32_e32 v36, 0x3fb8aa3b, v107
	v_exp_f32_e32 v36, v36
	v_cndmask_b32_e32 v38, 0, v70, vcc
	v_ldexp_f32 v106, v35, v38
	v_cndmask_b32_e64 v35, 0, v70, s[0:1]
	v_ldexp_f32 v107, v36, v35
	v_mul_f32_e32 v35, 0x3fb8aa3b, v108
	v_cmp_gt_f32_e32 vcc, s3, v35
	v_mul_f32_e32 v36, 0x3fb8aa3b, v109
	v_cmp_gt_f32_e64 s[0:1], s3, v36
	v_cndmask_b32_e32 v35, 0, v69, vcc
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v108
	v_cndmask_b32_e64 v36, 0, v69, s[0:1]
	v_exp_f32_e32 v35, v35
	v_fmac_f32_e32 v36, 0x3fb8aa3b, v109
	v_exp_f32_e32 v36, v36
	v_cndmask_b32_e32 v38, 0, v70, vcc
	v_ldexp_f32 v108, v35, v38
	v_cndmask_b32_e64 v35, 0, v70, s[0:1]
	v_ldexp_f32 v109, v36, v35
	v_mul_f32_e32 v35, 0x3fb8aa3b, v110
	v_cmp_gt_f32_e32 vcc, s3, v35
	v_mul_f32_e32 v36, 0x3fb8aa3b, v111
	v_cmp_gt_f32_e64 s[0:1], s3, v36
	v_cndmask_b32_e32 v35, 0, v69, vcc
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v110
	v_cndmask_b32_e64 v36, 0, v69, s[0:1]
	v_exp_f32_e32 v35, v35
	v_fmac_f32_e32 v36, 0x3fb8aa3b, v111
	v_exp_f32_e32 v36, v36
	v_cndmask_b32_e32 v38, 0, v70, vcc
	v_ldexp_f32 v110, v35, v38
	v_cndmask_b32_e64 v35, 0, v70, s[0:1]
	v_ldexp_f32 v111, v36, v35
.Ltmp53:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:154:43 ] ]
	v_add_f32_e32 v35, v34, v39
	v_add_f32_e32 v35, v40, v35
	v_add_f32_e32 v35, v41, v35
	v_add_f32_e32 v35, v112, v35
.Ltmp54:
	.loc	1 167 33                        ; benchmark_qwen36_extend_attention_m756.py:167:33
	v_cvt_pk_bf16_f32 v36, v112, v113
	.loc	1 162 16                        ; benchmark_qwen36_extend_attention_m756.py:162:16
	v_add_u32_e32 v112, 0, v47
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(2)
	ds_write2st64_b64 v112, v[88:89], v[92:93] offset1:8
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v112, v[96:97], v[100:101] offset0:16 offset1:24
	v_add_u32_e32 v88, 0, v46
	ds_write2st64_b64 v88, v[90:91], v[94:95] offset1:8
	ds_write2st64_b64 v88, v[98:99], v[102:103] offset0:16 offset1:24
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64_tr_b16 v[88:89], v62
	ds_read_b64_tr_b16 v[90:91], v62 offset:4096
	ds_read_b64_tr_b16 v[94:95], v62 offset:4224
	ds_read_b64_tr_b16 v[92:93], v62 offset:128
	ds_read_b64_tr_b16 v[96:97], v62 offset:8192
	ds_read_b64_tr_b16 v[98:99], v62 offset:12288
	ds_read_b64_tr_b16 v[102:103], v62 offset:12416
	ds_read_b64_tr_b16 v[100:101], v62 offset:8320
	ds_read_b64_tr_b16 v[116:117], v63
	ds_read_b64_tr_b16 v[118:119], v63 offset:4096
	ds_read_b64_tr_b16 v[122:123], v63 offset:4224
	ds_read_b64_tr_b16 v[120:121], v63 offset:128
.Ltmp55:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:154:43 ] ]
	v_add_f32_e32 v35, v113, v35
	v_add_f32_e32 v115, v37, v35
.Ltmp56:
	.loc	1 167 33                        ; benchmark_qwen36_extend_attention_m756.py:167:33
	v_cvt_pk_bf16_f32 v34, v34, v39
	v_cvt_pk_bf16_f32 v35, v40, v41
	v_cvt_pk_bf16_f32 v37, v37, v114
	.loc	1 167 43 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:167:43
	v_pk_mul_f32 v[32:33], v[32:33], v[42:43] op_sel_hi:[1,0]
	v_pk_mul_f32 v[30:31], v[30:31], v[42:43] op_sel_hi:[1,0]
	v_pk_mul_f32 v[28:29], v[28:29], v[42:43] op_sel_hi:[1,0]
	v_pk_mul_f32 v[26:27], v[26:27], v[42:43] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(10)
	v_mfma_f32_16x16x32_bf16 v[30:33], v[88:91], v[34:37], v[30:33]
	.loc	1 162 16 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:162:16
	ds_read_b64_tr_b16 v[88:89], v63 offset:8192
	ds_read_b64_tr_b16 v[90:91], v63 offset:12288
	ds_read_b64_tr_b16 v[126:127], v63 offset:12416
	ds_read_b64_tr_b16 v[124:125], v63 offset:8320
	.loc	1 167 33                        ; benchmark_qwen36_extend_attention_m756.py:167:33
	v_cvt_pk_bf16_f32 v38, v104, v105
	v_cvt_pk_bf16_f32 v39, v106, v107
	.loc	1 167 43 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:167:43
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[26:29], v[116:119], v[34:37], v[26:29]
	.loc	1 167 33                        ; benchmark_qwen36_extend_attention_m756.py:167:33
	v_cvt_pk_bf16_f32 v40, v108, v109
	v_cvt_pk_bf16_f32 v41, v110, v111
	.loc	1 167 43                        ; benchmark_qwen36_extend_attention_m756.py:167:43
	v_pk_mul_f32 v[24:25], v[24:25], v[42:43] op_sel_hi:[1,0]
	v_pk_mul_f32 v[22:23], v[22:23], v[42:43] op_sel_hi:[1,0]
	v_mfma_f32_16x16x32_bf16 v[30:33], v[96:99], v[38:41], v[30:33]
	.loc	1 162 16 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:162:16
	ds_read_b64_tr_b16 v[96:97], v64
	ds_read_b64_tr_b16 v[98:99], v64 offset:4096
	.loc	1 167 43                        ; benchmark_qwen36_extend_attention_m756.py:167:43
	v_pk_mul_f32 v[20:21], v[20:21], v[42:43] op_sel_hi:[1,0]
	v_pk_mul_f32 v[18:19], v[18:19], v[42:43] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x32_bf16 v[26:29], v[88:91], v[38:41], v[26:29]
	.loc	1 162 16                        ; benchmark_qwen36_extend_attention_m756.py:162:16
	ds_read_b64_tr_b16 v[88:89], v65
	ds_read_b64_tr_b16 v[90:91], v65 offset:4096
	ds_read_b64_tr_b16 v[116:117], v64 offset:8192
	ds_read_b64_tr_b16 v[118:119], v64 offset:12288
	ds_read_b64_tr_b16 v[130:131], v64 offset:4224
	ds_read_b64_tr_b16 v[128:129], v64 offset:128
	.loc	1 167 43                        ; benchmark_qwen36_extend_attention_m756.py:167:43
	v_pk_mul_f32 v[16:17], v[16:17], v[42:43] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[22:25], v[96:99], v[34:37], v[22:25]
	.loc	1 162 16                        ; benchmark_qwen36_extend_attention_m756.py:162:16
	ds_read_b64_tr_b16 v[98:99], v64 offset:12416
	ds_read_b64_tr_b16 v[96:97], v64 offset:8320
	ds_read_b64_tr_b16 v[132:133], v65 offset:8192
	ds_read_b64_tr_b16 v[134:135], v65 offset:12288
	.loc	1 167 43                        ; benchmark_qwen36_extend_attention_m756.py:167:43
	v_pk_mul_f32 v[14:15], v[14:15], v[42:43] op_sel_hi:[1,0]
	v_pk_mul_f32 v[12:13], v[12:13], v[42:43] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(8)
	v_mfma_f32_16x16x32_bf16 v[18:21], v[88:91], v[34:37], v[18:21]
.Ltmp57:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:154:43 ] ]
	v_add_f32_e32 v88, v114, v115
	v_add_f32_e32 v88, v104, v88
	v_add_f32_e32 v88, v105, v88
	v_add_f32_e32 v88, v106, v88
.Ltmp58:
	.loc	1 167 43                        ; benchmark_qwen36_extend_attention_m756.py:167:43
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[22:25], v[116:119], v[38:41], v[22:25]
	.loc	1 162 16                        ; benchmark_qwen36_extend_attention_m756.py:162:16
	ds_read_b64_tr_b16 v[118:119], v65 offset:4224
	ds_read_b64_tr_b16 v[116:117], v65 offset:128
.Ltmp59:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:154:43 ] ]
	v_add_f32_e32 v88, v107, v88
	v_add_f32_e32 v88, v108, v88
	v_add_f32_e32 v88, v109, v88
	v_add_f32_e32 v88, v110, v88
.Ltmp60:
	.loc	1 162 16                        ; benchmark_qwen36_extend_attention_m756.py:162:16
	ds_read_b64_tr_b16 v[114:115], v65 offset:12416
	ds_read_b64_tr_b16 v[112:113], v65 offset:8320
	.loc	1 167 43                        ; benchmark_qwen36_extend_attention_m756.py:167:43
	v_pk_mul_f32 v[10:11], v[10:11], v[42:43] op_sel_hi:[1,0]
.Ltmp61:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:154:43 ] ]
	v_add_f32_e32 v88, v111, v88
.Ltmp62:
	.loc	1 167 43                        ; benchmark_qwen36_extend_attention_m756.py:167:43
	v_pk_mul_f32 v[8:9], v[8:9], v[42:43] op_sel_hi:[1,0]
	v_pk_mul_f32 v[6:7], v[6:7], v[42:43] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[4:5], v[42:43] op_sel_hi:[1,0]
	v_pk_mul_f32 v[2:3], v[2:3], v[42:43] op_sel_hi:[1,0]
	v_mfma_f32_16x16x32_bf16 v[14:17], v[92:95], v[34:37], v[14:17]
.Ltmp63:
	.loc	2 293 36                        ; standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:154:43 ]
	v_mov_b32_e32 v89, v88
	s_nop 1
	v_permlane32_swap_b32_e32 v88, v89
.Ltmp64:
	.loc	1 167 43                        ; benchmark_qwen36_extend_attention_m756.py:167:43
	v_mfma_f32_16x16x32_bf16 v[10:13], v[120:123], v[34:37], v[10:13]
.Ltmp65:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:154:43 ] ]
	v_add_f32_e32 v88, v88, v89
.Ltmp66:
	.loc	2 293 36                        ; standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:154:43 ]
	v_mov_b32_e32 v89, v88
	s_nop 1
	v_permlane16_swap_b32_e32 v88, v89
.Ltmp67:
	.loc	1 167 43                        ; benchmark_qwen36_extend_attention_m756.py:167:43
	s_waitcnt lgkmcnt(8)
	v_mfma_f32_16x16x32_bf16 v[6:9], v[128:131], v[34:37], v[6:9]
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[116:119], v[34:37], v[2:5]
.Ltmp68:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:154:43 ] ]
	v_add_f32_e32 v34, v88, v89
.Ltmp69:
	.loc	1 154 36                        ; benchmark_qwen36_extend_attention_m756.py:154:36
	v_fmac_f32_e32 v34, v1, v42
	v_mov_b32_e32 v1, v34
	.loc	1 167 43                        ; benchmark_qwen36_extend_attention_m756.py:167:43
	v_mfma_f32_16x16x32_bf16 v[18:21], v[132:135], v[38:41], v[18:21]
	v_mov_b32_e32 v34, v71
	v_mfma_f32_16x16x32_bf16 v[14:17], v[100:103], v[38:41], v[14:17]
	v_mfma_f32_16x16x32_bf16 v[10:13], v[124:127], v[38:41], v[10:13]
	v_mfma_f32_16x16x32_bf16 v[6:9], v[96:99], v[38:41], v[6:9]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[112:115], v[38:41], v[2:5]
	s_branch .LBB0_5
.LBB0_8:
	.loc	1 0 43 is_stmt 0                ; benchmark_qwen36_extend_attention_m756.py:0:43
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v7, 0
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v8, 0
	v_mov_b32_e32 v11, 0
	v_mov_b32_e32 v10, 0
	v_mov_b32_e32 v13, 0
	v_mov_b32_e32 v12, 0
	v_mov_b32_e32 v15, 0
	v_mov_b32_e32 v14, 0
	v_mov_b32_e32 v17, 0
	v_mov_b32_e32 v16, 0
	v_mov_b32_e32 v19, 0
	v_mov_b32_e32 v18, 0
	v_mov_b32_e32 v21, 0
	v_mov_b32_e32 v20, 0
	v_mov_b32_e32 v23, 0
	v_mov_b32_e32 v22, 0
	v_mov_b32_e32 v25, 0
	v_mov_b32_e32 v24, 0
	v_mov_b32_e32 v27, 0
	v_mov_b32_e32 v26, 0
	v_mov_b32_e32 v29, 0
	v_mov_b32_e32 v28, 0
	v_mov_b32_e32 v31, 0
	v_mov_b32_e32 v30, 0
	v_mov_b32_e32 v33, 0
	v_mov_b32_e32 v32, 0
	v_mov_b32_e32 v34, 0xff800000
	v_mov_b32_e32 v1, 0
	s_branch .LBB0_10
.LBB0_9:
	s_mov_b32 s26, s100
	v_readlane_b32 s24, v136, 4
	s_mov_b32 s27, s101
	v_readlane_b32 s25, v136, 6
	v_readlane_b32 s18, v136, 2
	v_readlane_b32 s2, v136, 5
	v_readlane_b32 s19, v136, 3
.LBB0_10:                               ; %._crit_edge
	.loc	1 179 27 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:179:27
	s_lshl_b32 s0, s18, 10
	s_add_i32 s0, s0, s2
	v_or_b32_e32 v40, s0, v50
	.loc	1 105 31                        ; benchmark_qwen36_extend_attention_m756.py:105:31
	v_or_b32_e32 v35, 16, v49
	.loc	1 179 16                        ; benchmark_qwen36_extend_attention_m756.py:179:16
	v_lshlrev_b32_e32 v40, 1, v40
	.loc	1 105 31                        ; benchmark_qwen36_extend_attention_m756.py:105:31
	v_or_b32_e32 v36, 32, v49
	.loc	1 179 27                        ; benchmark_qwen36_extend_attention_m756.py:179:27
	v_lshl_or_b32 v38, v49, 10, v50
	.loc	1 179 16 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:179:16
	v_bfrev_b32_e32 v39, 1
	v_lshl_add_u32 v41, v35, 11, v40
	.loc	1 171 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:171:22
	v_cmp_gt_i32_e32 vcc, s75, v35
	.loc	1 105 31                        ; benchmark_qwen36_extend_attention_m756.py:105:31
	v_or_b32_e32 v37, 48, v49
	.loc	1 179 16                        ; benchmark_qwen36_extend_attention_m756.py:179:16
	v_add_lshl_u32 v38, v38, s0, 1
	v_cndmask_b32_e32 v35, v39, v41, vcc
	v_lshl_add_u32 v41, v36, 11, v40
	.loc	1 171 22                        ; benchmark_qwen36_extend_attention_m756.py:171:22
	v_cmp_gt_i32_e32 vcc, s75, v36
	.loc	1 179 16                        ; benchmark_qwen36_extend_attention_m756.py:179:16
	s_and_b32 s5, s5, 0xffff
	s_mov_b32 s7, 0x27000
	s_mov_b32 s6, 0x7ffffffe
	v_cndmask_b32_e64 v38, v39, v38, s[26:27]
	v_cndmask_b32_e32 v36, v39, v41, vcc
	v_lshl_add_u32 v40, v37, 11, v40
	.loc	1 171 22                        ; benchmark_qwen36_extend_attention_m756.py:171:22
	v_cmp_gt_i32_e32 vcc, s75, v37
	.loc	1 179 16                        ; benchmark_qwen36_extend_attention_m756.py:179:16
	buffer_load_dwordx4 v[56:59], v38, s[4:7], 0 offen
	buffer_load_dwordx4 v[60:63], v35, s[4:7], 0 offen
	v_cndmask_b32_e32 v37, v39, v40, vcc
	buffer_load_dwordx4 v[64:67], v36, s[4:7], 0 offen
	buffer_load_dwordx4 v[90:93], v37, s[4:7], 0 offen
	.loc	1 115 17                        ; benchmark_qwen36_extend_attention_m756.py:115:17
	v_and_b32_e32 v49, 16, v0
	v_lshrrev_b32_e32 v50, 2, v0
	.loc	1 179 16                        ; benchmark_qwen36_extend_attention_m756.py:179:16
	v_add_u32_e32 v51, 0, v51
	.loc	1 115 17                        ; benchmark_qwen36_extend_attention_m756.py:115:17
	v_and_or_b32 v89, v50, 8, v49
	.loc	1 179 16                        ; benchmark_qwen36_extend_attention_m756.py:179:16
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_add_u32_e32 v52, 0, v52
	v_add_u32_e32 v53, 0, v53
	v_add_u32_e32 v54, 0, v54
	.loc	1 194 16                        ; benchmark_qwen36_extend_attention_m756.py:194:16
	s_and_b32 s77, s77, 0xffff
	s_mov_b32 s78, s6
	s_mov_b32 s79, s7
	.loc	1 105 31                        ; benchmark_qwen36_extend_attention_m756.py:105:31
	v_or_b32_e32 v40, 1, v55
	v_or_b32_e32 v41, 2, v55
	v_or_b32_e32 v42, 3, v55
	.loc	1 171 22                        ; benchmark_qwen36_extend_attention_m756.py:171:22
	v_cmp_gt_i32_e64 s[0:1], s75, v55
	.loc	1 173 41                        ; benchmark_qwen36_extend_attention_m756.py:173:41
	v_cmp_ge_u32_e64 s[2:3], v43, v55
	v_cmp_gt_u32_e32 vcc, v43, v55
	.loc	1 171 22                        ; benchmark_qwen36_extend_attention_m756.py:171:22
	v_cmp_gt_i32_e64 s[4:5], s75, v40
	.loc	1 173 18                        ; benchmark_qwen36_extend_attention_m756.py:173:18
	s_and_b64 s[0:1], s[2:3], s[0:1]
	.loc	1 181 34                        ; benchmark_qwen36_extend_attention_m756.py:181:34
	v_mov_b32_e32 v68, 0xff800000
	.loc	1 171 22                        ; benchmark_qwen36_extend_attention_m756.py:171:22
	v_cmp_gt_i32_e64 s[10:11], s75, v41
	.loc	1 173 41                        ; benchmark_qwen36_extend_attention_m756.py:173:41
	v_cmp_ge_u32_e64 s[14:15], v43, v41
	.loc	1 173 18 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:173:18
	s_and_b64 s[2:3], vcc, s[4:5]
	s_and_b64 vcc, s[44:45], s[0:1]
	.loc	1 171 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:171:22
	v_cmp_gt_i32_e64 s[12:13], s75, v42
	.loc	1 173 41                        ; benchmark_qwen36_extend_attention_m756.py:173:41
	v_cmp_ge_u32_e64 s[16:17], v43, v42
	.loc	1 173 18 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:173:18
	s_and_b64 s[4:5], s[14:15], s[10:11]
	s_and_b64 s[10:11], s[16:17], s[12:13]
	s_mov_b32 s18, 0xff800000
	.loc	1 183 58 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:183:58
	v_mov_b32_e32 v69, 0xe0ad78ec
	.loc	1 184 35                        ; benchmark_qwen36_extend_attention_m756.py:184:35
	v_max_f32_e32 v70, v34, v34
	s_mov_b32 s19, 0xc2fc0000
	.loc	1 185 21                        ; benchmark_qwen36_extend_attention_m756.py:185:21
	v_mov_b32_e32 v71, 0x42800000
	v_not_b32_e32 v88, 63
	.loc	1 194 16                        ; benchmark_qwen36_extend_attention_m756.py:194:16
	v_lshlrev_b32_e32 v0, 3, v0
	v_and_b32_e32 v0, 24, v0
	v_bitop3_b32 v0, v44, v45, v0 bitop3:0x36
	.loc	1 206 8                         ; benchmark_qwen36_extend_attention_m756.py:206:8
	s_and_b32 s9, s9, 0xffff
	.loc	1 179 16                        ; benchmark_qwen36_extend_attention_m756.py:179:16
	s_waitcnt vmcnt(3)
	ds_write_b128 v48, v[56:59]
	s_waitcnt vmcnt(2)
	ds_write_b128 v48, v[60:63] offset:4096
	s_waitcnt vmcnt(1)
	ds_write_b128 v48, v[64:67] offset:8192
	s_waitcnt vmcnt(0)
	ds_write_b128 v48, v[90:93] offset:12288
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[48:51], v51
	ds_read_b128 v[56:59], v52
	ds_read_b128 v[60:63], v53
	.loc	1 180 19                        ; benchmark_qwen36_extend_attention_m756.py:180:19
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[48:51], v[48:51], v[84:87], 0
	.loc	1 179 16                        ; benchmark_qwen36_extend_attention_m756.py:179:16
	ds_read_b128 v[84:87], v54
	.loc	1 180 19                        ; benchmark_qwen36_extend_attention_m756.py:180:19
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[48:51], v[56:59], v[80:83], v[48:51]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[48:51], v[60:63], v[76:79], v[48:51]
	.loc	1 194 16                        ; benchmark_qwen36_extend_attention_m756.py:194:16
	buffer_load_dwordx4 v[52:55], v38, s[76:79], 0 offen
	buffer_load_dwordx4 v[56:59], v35, s[76:79], 0 offen
	buffer_load_dwordx4 v[60:63], v36, s[76:79], 0 offen
	buffer_load_dwordx4 v[64:67], v37, s[76:79], 0 offen
	s_waitcnt lgkmcnt(0)
	s_barrier
	.loc	1 180 19                        ; benchmark_qwen36_extend_attention_m756.py:180:19
	v_mfma_f32_16x16x32_bf16 v[48:51], v[84:87], v[72:75], v[48:51]
	.loc	1 180 46 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:180:46
	s_nop 7
	v_mul_f32_e32 v35, s95, v48
	v_mul_f32_e32 v36, s95, v49
	.loc	1 181 34 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:181:34
	v_cndmask_b32_e32 v35, v68, v35, vcc
	.loc	1 173 18                        ; benchmark_qwen36_extend_attention_m756.py:173:18
	s_and_b64 vcc, s[44:45], s[2:3]
	.loc	1 180 46                        ; benchmark_qwen36_extend_attention_m756.py:180:46
	v_mul_f32_e32 v37, s95, v50
	.loc	1 181 34                        ; benchmark_qwen36_extend_attention_m756.py:181:34
	v_cndmask_b32_e32 v36, v68, v36, vcc
	.loc	1 173 18                        ; benchmark_qwen36_extend_attention_m756.py:173:18
	s_and_b64 vcc, s[44:45], s[4:5]
	.loc	1 180 46                        ; benchmark_qwen36_extend_attention_m756.py:180:46
	v_mul_f32_e32 v38, s95, v51
	.loc	1 181 34                        ; benchmark_qwen36_extend_attention_m756.py:181:34
	v_cndmask_b32_e32 v37, v68, v37, vcc
	.loc	1 173 18                        ; benchmark_qwen36_extend_attention_m756.py:173:18
	s_and_b64 vcc, s[44:45], s[10:11]
	.loc	1 181 34                        ; benchmark_qwen36_extend_attention_m756.py:181:34
	v_cndmask_b32_e32 v38, v68, v38, vcc
.Ltmp70:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:182:21 ] ]
	v_max3_f32 v40, v35, v36, v37
	v_max3_f32 v40, v40, v38, s18
.Ltmp71:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:182:21 ]
	v_mov_b32_e32 v41, v40
	s_nop 1
	v_permlane32_swap_b32_e32 v40, v41
.Ltmp72:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:182:21 ] ]
	v_max_f32_e32 v41, v41, v41
	v_max_f32_e32 v40, v40, v40
	v_max_f32_e32 v40, v40, v41
.Ltmp73:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:182:21 ]
	v_mov_b32_e32 v41, v40
	s_nop 1
	v_permlane16_swap_b32_e32 v40, v41
.Ltmp74:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:182:21 ] ]
	v_max_f32_e32 v41, v41, v41
	v_max_f32_e32 v40, v40, v40
	v_max_f32_e32 v40, v40, v41
.Ltmp75:
	.loc	1 183 58                        ; benchmark_qwen36_extend_attention_m756.py:183:58
	v_cmp_neq_f32_e32 vcc, s18, v40
	.loc	1 206 8                         ; benchmark_qwen36_extend_attention_m756.py:206:8
	s_mov_b32 s10, s6
	s_mov_b32 s11, s7
	.loc	1 183 58                        ; benchmark_qwen36_extend_attention_m756.py:183:58
	v_cndmask_b32_e32 v40, v69, v40, vcc
	.loc	1 184 35                        ; benchmark_qwen36_extend_attention_m756.py:184:35
	v_max_f32_e32 v40, v40, v70
	.loc	1 185 29                        ; benchmark_qwen36_extend_attention_m756.py:185:29
	v_sub_f32_e32 v34, v34, v40
	.loc	1 186 32                        ; benchmark_qwen36_extend_attention_m756.py:186:32
	v_sub_f32_e32 v35, v35, v40
	v_sub_f32_e32 v41, v38, v40
	.loc	1 185 21                        ; benchmark_qwen36_extend_attention_m756.py:185:21
	v_mul_f32_e32 v38, 0x3fb8aa3b, v34
	.loc	1 186 27                        ; benchmark_qwen36_extend_attention_m756.py:186:27
	v_mul_f32_e32 v42, 0x3fb8aa3b, v35
	.loc	1 185 21                        ; benchmark_qwen36_extend_attention_m756.py:185:21
	v_cmp_gt_f32_e32 vcc, s19, v38
	.loc	1 186 27                        ; benchmark_qwen36_extend_attention_m756.py:186:27
	v_cmp_gt_f32_e64 s[0:1], s19, v42
	.loc	1 186 32 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:186:32
	v_sub_f32_e32 v36, v36, v40
	.loc	1 185 21 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:185:21
	v_cndmask_b32_e32 v38, 0, v71, vcc
	.loc	1 186 27                        ; benchmark_qwen36_extend_attention_m756.py:186:27
	v_cndmask_b32_e64 v42, 0, v71, s[0:1]
	.loc	1 185 21                        ; benchmark_qwen36_extend_attention_m756.py:185:21
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v34
	.loc	1 186 27                        ; benchmark_qwen36_extend_attention_m756.py:186:27
	v_fmac_f32_e32 v42, 0x3fb8aa3b, v35
	.loc	1 185 21                        ; benchmark_qwen36_extend_attention_m756.py:185:21
	v_exp_f32_e32 v38, v38
	.loc	1 186 27                        ; benchmark_qwen36_extend_attention_m756.py:186:27
	v_exp_f32_e32 v42, v42
	.loc	1 186 32 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:186:32
	v_sub_f32_e32 v37, v37, v40
	.loc	1 186 27                        ; benchmark_qwen36_extend_attention_m756.py:186:27
	v_mul_f32_e32 v48, 0x3fb8aa3b, v36
	v_mul_f32_e32 v49, 0x3fb8aa3b, v37
	v_cmp_gt_f32_e64 s[2:3], s19, v48
	.loc	1 185 21 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:185:21
	v_cndmask_b32_e32 v34, 0, v88, vcc
	.loc	1 186 27                        ; benchmark_qwen36_extend_attention_m756.py:186:27
	v_cndmask_b32_e64 v35, 0, v88, s[0:1]
	v_cndmask_b32_e64 v48, 0, v71, s[2:3]
	v_cmp_gt_f32_e32 vcc, s19, v49
	v_fmac_f32_e32 v48, 0x3fb8aa3b, v36
	.loc	1 185 21                        ; benchmark_qwen36_extend_attention_m756.py:185:21
	v_ldexp_f32 v38, v38, v34
	.loc	1 186 27                        ; benchmark_qwen36_extend_attention_m756.py:186:27
	v_ldexp_f32 v34, v42, v35
	v_cndmask_b32_e32 v35, 0, v71, vcc
	v_exp_f32_e32 v36, v48
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v37
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e64 v37, 0, v88, s[2:3]
	v_ldexp_f32 v36, v36, v37
	v_cndmask_b32_e32 v37, 0, v88, vcc
	v_ldexp_f32 v35, v35, v37
	v_mul_f32_e32 v37, 0x3fb8aa3b, v41
	v_cmp_gt_f32_e32 vcc, s19, v37
	.loc	1 186 32 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:186:32
	v_sub_f32_e32 v40, 0xff800000, v40
	.loc	1 196 35 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:196:35
	v_pk_mul_f32 v[28:29], v[28:29], v[38:39] op_sel_hi:[1,0]
	.loc	1 186 27                        ; benchmark_qwen36_extend_attention_m756.py:186:27
	v_cndmask_b32_e32 v37, 0, v71, vcc
	v_fmac_f32_e32 v37, 0x3fb8aa3b, v41
	v_mul_f32_e32 v41, 0x3fb8aa3b, v40
	v_cmp_gt_f32_e64 s[0:1], s19, v41
	v_exp_f32_e32 v37, v37
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	v_pk_mul_f32 v[26:27], v[26:27], v[38:39] op_sel_hi:[1,0]
	.loc	1 186 27                        ; benchmark_qwen36_extend_attention_m756.py:186:27
	v_cndmask_b32_e64 v41, 0, v71, s[0:1]
	v_fmac_f32_e32 v41, 0x3fb8aa3b, v40
	v_exp_f32_e32 v40, v41
	v_cndmask_b32_e32 v41, 0, v88, vcc
	v_ldexp_f32 v37, v37, v41
	v_cndmask_b32_e64 v41, 0, v88, s[0:1]
	v_ldexp_f32 v40, v40, v41
.Ltmp76:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:187:35 ] ]
	v_add_f32_e32 v41, v34, v36
	v_add_f32_e32 v41, v35, v41
	v_add_f32_e32 v41, v37, v41
.Ltmp77:
	.loc	1 196 25                        ; benchmark_qwen36_extend_attention_m756.py:196:25
	v_cvt_pk_bf16_f32 v35, v35, v37
	.loc	1 194 16                        ; benchmark_qwen36_extend_attention_m756.py:194:16
	v_add_u32_e32 v37, 0, v47
	s_waitcnt vmcnt(2)
	ds_write2st64_b64 v37, v[52:53], v[56:57] offset1:8
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v37, v[60:61], v[64:65] offset0:16 offset1:24
	v_add_u32_e32 v37, 0, v46
	ds_write2st64_b64 v37, v[54:55], v[58:59] offset1:8
	ds_write2st64_b64 v37, v[62:63], v[66:67] offset0:16 offset1:24
	v_add_u32_e32 v37, 0, v0
	.loc	1 196 25                        ; benchmark_qwen36_extend_attention_m756.py:196:25
	v_cvt_pk_bf16_f32 v34, v34, v36
	v_cvt_pk_bf16_f32 v36, v40, v40
	.loc	1 194 16                        ; benchmark_qwen36_extend_attention_m756.py:194:16
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b64_tr_b16 v[46:47], v37
	ds_read_b64_tr_b16 v[48:49], v37 offset:4096
	ds_read_b64_tr_b16 v[54:55], v37 offset:4224
	ds_read_b64_tr_b16 v[52:53], v37 offset:128
	ds_read_b64_tr_b16 v[56:57], v37 offset:8192
	ds_read_b64_tr_b16 v[58:59], v37 offset:12288
	ds_read_b64_tr_b16 v[62:63], v37 offset:12416
	ds_read_b64_tr_b16 v[60:61], v37 offset:8320
	v_xad_u32 v37, v0, 32, 0
	ds_read_b64_tr_b16 v[64:65], v37
	ds_read_b64_tr_b16 v[66:67], v37 offset:4096
	ds_read_b64_tr_b16 v[70:71], v37 offset:4224
	ds_read_b64_tr_b16 v[68:69], v37 offset:128
	ds_read_b64_tr_b16 v[72:73], v37 offset:8192
	ds_read_b64_tr_b16 v[74:75], v37 offset:12288
	ds_read_b64_tr_b16 v[78:79], v37 offset:12416
	ds_read_b64_tr_b16 v[76:77], v37 offset:8320
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	v_mov_b32_e32 v37, v36
	v_pk_mul_f32 v[32:33], v[32:33], v[38:39] op_sel_hi:[1,0]
	v_pk_mul_f32 v[30:31], v[30:31], v[38:39] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[26:29], v[64:67], v[34:37], v[26:29]
	.loc	1 194 16                        ; benchmark_qwen36_extend_attention_m756.py:194:16
	v_xad_u32 v42, v0, 64, 0
	v_xor_b32_e32 v0, 0x60, v0
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	v_mov_b32_e32 v44, v36
	v_mfma_f32_16x16x32_bf16 v[30:33], v[46:49], v[34:37], v[30:33]
	v_mov_b32_e32 v45, v36
	v_mov_b32_e32 v46, v36
	v_mov_b32_e32 v47, v36
	.loc	1 194 16                        ; benchmark_qwen36_extend_attention_m756.py:194:16
	ds_read_b64_tr_b16 v[64:65], v42
	ds_read_b64_tr_b16 v[66:67], v42 offset:4096
	ds_read_b64_tr_b16 v[82:83], v42 offset:4224
	ds_read_b64_tr_b16 v[80:81], v42 offset:128
	v_add_u32_e32 v0, 0, v0
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[48:51], v[72:75], v[44:47], v[26:29]
	.loc	1 194 16                        ; benchmark_qwen36_extend_attention_m756.py:194:16
	s_nop 2
	ds_read_b64_tr_b16 v[26:27], v0
	ds_read_b64_tr_b16 v[28:29], v0 offset:4096
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	v_pk_mul_f32 v[24:25], v[24:25], v[38:39] op_sel_hi:[1,0]
	v_pk_mul_f32 v[22:23], v[22:23], v[38:39] op_sel_hi:[1,0]
	v_mfma_f32_16x16x32_bf16 v[30:33], v[56:59], v[44:47], v[30:33]
	.loc	1 194 16                        ; benchmark_qwen36_extend_attention_m756.py:194:16
	ds_read_b64_tr_b16 v[56:57], v42 offset:8192
	ds_read_b64_tr_b16 v[58:59], v42 offset:12288
.Ltmp78:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:187:35 ] ]
	v_add_f32_e32 v41, v40, v41
	v_add_f32_e32 v41, v40, v41
.Ltmp79:
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[22:25], v[64:67], v[34:37], v[22:25]
.Ltmp80:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:187:35 ] ]
	v_add_f32_e32 v41, v40, v41
.Ltmp81:
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	v_pk_mul_f32 v[20:21], v[20:21], v[38:39] op_sel_hi:[1,0]
	v_pk_mul_f32 v[18:19], v[18:19], v[38:39] op_sel_hi:[1,0]
	.loc	1 194 16                        ; benchmark_qwen36_extend_attention_m756.py:194:16
	ds_read_b64_tr_b16 v[66:67], v42 offset:12416
	ds_read_b64_tr_b16 v[64:65], v42 offset:8320
	ds_read_b64_tr_b16 v[72:73], v0 offset:8192
	ds_read_b64_tr_b16 v[74:75], v0 offset:12288
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[18:21], v[26:29], v[34:37], v[18:21]
.Ltmp82:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:187:35 ] ]
	v_add_f32_e32 v26, v40, v41
.Ltmp83:
	.loc	1 194 16                        ; benchmark_qwen36_extend_attention_m756.py:194:16
	ds_read_b64_tr_b16 v[86:87], v0 offset:12416
	ds_read_b64_tr_b16 v[84:85], v0 offset:8320
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	v_pk_mul_f32 v[4:5], v[4:5], v[38:39] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[22:25], v[56:59], v[44:47], v[22:25]
	.loc	1 194 16                        ; benchmark_qwen36_extend_attention_m756.py:194:16
	ds_read_b64_tr_b16 v[58:59], v0 offset:4224
	ds_read_b64_tr_b16 v[56:57], v0 offset:128
.Ltmp84:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:187:35 ] ]
	v_add_f32_e32 v0, v40, v26
	v_add_f32_e32 v0, v40, v0
	v_add_f32_e32 v0, v40, v0
	v_add_f32_e32 v0, v40, v0
	v_add_f32_e32 v0, v40, v0
	v_add_f32_e32 v0, v40, v0
	v_add_f32_e32 v0, v40, v0
	v_add_f32_e32 v0, v40, v0
.Ltmp85:
	.loc	2 293 36                        ; standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:187:35 ]
	v_mov_b32_e32 v26, v0
	s_nop 1
	v_permlane32_swap_b32_e32 v0, v26
.Ltmp86:
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	v_pk_mul_f32 v[2:3], v[2:3], v[38:39] op_sel_hi:[1,0]
.Ltmp87:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:187:35 ] ]
	v_add_f32_e32 v0, v0, v26
.Ltmp88:
	.loc	2 293 36                        ; standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:187:35 ]
	v_mov_b32_e32 v26, v0
.Ltmp89:
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[56:59], v[34:37], v[2:5]
.Ltmp90:
	.loc	2 293 36                        ; standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:187:35 ]
	v_permlane16_swap_b32_e32 v0, v26
.Ltmp91:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:187:35 ] ]
	v_add_f32_e32 v28, v0, v26
.Ltmp92:
	.loc	1 187 28                        ; benchmark_qwen36_extend_attention_m756.py:187:28
	v_fmac_f32_e32 v28, v1, v38
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	v_mfma_f32_16x16x32_bf16 v[0:3], v[84:87], v[44:47], v[2:5]
	.loc	1 205 17                        ; benchmark_qwen36_extend_attention_m756.py:205:17
	s_lshl_b32 s0, s25, 1
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	v_pk_mul_f32 v[16:17], v[16:17], v[38:39] op_sel_hi:[1,0]
	v_pk_mul_f32 v[14:15], v[14:15], v[38:39] op_sel_hi:[1,0]
	.loc	1 205 17                        ; benchmark_qwen36_extend_attention_m756.py:205:17
	s_nop 0
	v_lshlrev_b32_e32 v4, 12, v43
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	v_pk_mul_f32 v[12:13], v[12:13], v[38:39] op_sel_hi:[1,0]
	v_pk_mul_f32 v[10:11], v[10:11], v[38:39] op_sel_hi:[1,0]
	v_pk_mul_f32 v[8:9], v[8:9], v[38:39] op_sel_hi:[1,0]
	v_pk_mul_f32 v[6:7], v[6:7], v[38:39] op_sel_hi:[1,0]
	.loc	1 205 17                        ; benchmark_qwen36_extend_attention_m756.py:205:17
	v_or3_b32 v27, s0, v4, v89
	.loc	1 206 14                        ; benchmark_qwen36_extend_attention_m756.py:206:14
	v_div_scale_f32 v29, s[0:1], v28, v28, v30
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	v_mfma_f32_16x16x32_bf16 v[14:17], v[52:55], v[34:37], v[14:17]
	.loc	1 205 17                        ; benchmark_qwen36_extend_attention_m756.py:205:17
	v_or_b32_e32 v26, 32, v27
	v_or_b32_e32 v5, 64, v27
	v_or_b32_e32 v4, 0x60, v27
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	v_mfma_f32_16x16x32_bf16 v[10:13], v[68:71], v[34:37], v[10:13]
	v_mfma_f32_16x16x32_bf16 v[6:9], v[80:83], v[34:37], v[6:9]
	.loc	1 206 14                        ; benchmark_qwen36_extend_attention_m756.py:206:14
	v_rcp_f32_e32 v34, v29
	s_nop 0
	v_fma_f32 v35, -v29, v34, 1.0
	v_fmac_f32_e32 v34, v35, v34
	v_div_scale_f32 v35, vcc, v30, v28, v30
	v_mul_f32_e32 v36, v35, v34
	v_fma_f32 v37, -v29, v36, v35
	v_fmac_f32_e32 v36, v37, v34
	v_fma_f32 v29, -v29, v36, v35
	v_div_scale_f32 v35, s[0:1], v28, v28, v31
	v_rcp_f32_e32 v37, v35
	v_div_fmas_f32 v29, v29, v34, v36
	v_div_fixup_f32 v29, v29, v28, v30
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	v_mfma_f32_16x16x32_bf16 v[18:21], v[72:75], v[44:47], v[18:21]
	.loc	1 206 14                        ; benchmark_qwen36_extend_attention_m756.py:206:14
	v_fma_f32 v30, -v35, v37, 1.0
	v_fmac_f32_e32 v37, v30, v37
	v_div_scale_f32 v30, vcc, v31, v28, v31
	v_mul_f32_e32 v34, v30, v37
	v_fma_f32 v36, -v35, v34, v30
	v_fmac_f32_e32 v34, v36, v37
	v_fma_f32 v30, -v35, v34, v30
	v_div_scale_f32 v35, s[0:1], v28, v28, v32
	v_rcp_f32_e32 v36, v35
	v_div_fmas_f32 v30, v30, v37, v34
	v_div_fixup_f32 v30, v30, v28, v31
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	v_mfma_f32_16x16x32_bf16 v[14:17], v[60:63], v[44:47], v[14:17]
	.loc	1 206 14                        ; benchmark_qwen36_extend_attention_m756.py:206:14
	v_fma_f32 v31, -v35, v36, 1.0
	v_fmac_f32_e32 v36, v31, v36
	v_div_scale_f32 v31, vcc, v32, v28, v32
	v_mul_f32_e32 v34, v31, v36
	v_fma_f32 v37, -v35, v34, v31
	v_fmac_f32_e32 v34, v37, v36
	v_fma_f32 v31, -v35, v34, v31
	v_div_scale_f32 v35, s[0:1], v28, v28, v33
	v_rcp_f32_e32 v37, v35
	v_div_fmas_f32 v31, v31, v36, v34
	v_div_fixup_f32 v31, v31, v28, v32
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	v_mfma_f32_16x16x32_bf16 v[10:13], v[76:79], v[44:47], v[10:13]
	.loc	1 206 14                        ; benchmark_qwen36_extend_attention_m756.py:206:14
	v_fma_f32 v32, -v35, v37, 1.0
	v_fmac_f32_e32 v37, v32, v37
	v_div_scale_f32 v32, vcc, v33, v28, v33
	v_mul_f32_e32 v34, v32, v37
	v_fma_f32 v36, -v35, v34, v32
	v_fmac_f32_e32 v34, v36, v37
	v_fma_f32 v32, -v35, v34, v32
	v_div_scale_f32 v35, s[0:1], v28, v28, v48
	v_rcp_f32_e32 v36, v35
	v_div_fmas_f32 v32, v32, v37, v34
	v_div_fixup_f32 v32, v32, v28, v33
	.loc	1 196 35                        ; benchmark_qwen36_extend_attention_m756.py:196:35
	v_mfma_f32_16x16x32_bf16 v[6:9], v[64:67], v[44:47], v[6:9]
	.loc	1 206 14                        ; benchmark_qwen36_extend_attention_m756.py:206:14
	v_fma_f32 v33, -v35, v36, 1.0
	v_fmac_f32_e32 v36, v33, v36
	v_div_scale_f32 v33, vcc, v48, v28, v48
	v_mul_f32_e32 v34, v33, v36
	v_fma_f32 v37, -v35, v34, v33
	v_fmac_f32_e32 v34, v37, v36
	v_fma_f32 v33, -v35, v34, v33
	v_div_scale_f32 v35, s[0:1], v28, v28, v49
	v_rcp_f32_e32 v37, v35
	v_div_fmas_f32 v33, v33, v36, v34
	v_div_fixup_f32 v33, v33, v28, v48
	v_fma_f32 v34, -v35, v37, 1.0
	v_fmac_f32_e32 v37, v34, v37
	v_div_scale_f32 v34, vcc, v49, v28, v49
	v_mul_f32_e32 v36, v34, v37
	v_fma_f32 v38, -v35, v36, v34
	v_fmac_f32_e32 v36, v38, v37
	v_fma_f32 v34, -v35, v36, v34
	v_div_scale_f32 v35, s[0:1], v28, v28, v50
	v_rcp_f32_e32 v38, v35
	v_div_fmas_f32 v34, v34, v37, v36
	v_div_fixup_f32 v34, v34, v28, v49
	v_fma_f32 v36, -v35, v38, 1.0
	v_fmac_f32_e32 v38, v36, v38
	v_div_scale_f32 v36, vcc, v50, v28, v50
	v_mul_f32_e32 v37, v36, v38
	v_fma_f32 v40, -v35, v37, v36
	v_fmac_f32_e32 v37, v40, v38
	v_fma_f32 v35, -v35, v37, v36
	v_div_scale_f32 v36, s[0:1], v28, v28, v51
	v_rcp_f32_e32 v40, v36
	v_div_fmas_f32 v35, v35, v38, v37
	v_div_fixup_f32 v35, v35, v28, v50
	v_fma_f32 v37, -v36, v40, 1.0
	v_fmac_f32_e32 v40, v37, v40
	v_div_scale_f32 v37, vcc, v51, v28, v51
	v_mul_f32_e32 v38, v37, v40
	v_fma_f32 v41, -v36, v38, v37
	v_fmac_f32_e32 v38, v41, v40
	v_fma_f32 v36, -v36, v38, v37
	v_div_scale_f32 v37, s[0:1], v28, v28, v22
	v_rcp_f32_e32 v41, v37
	v_div_fmas_f32 v36, v36, v40, v38
	v_div_fixup_f32 v36, v36, v28, v51
	v_fma_f32 v38, -v37, v41, 1.0
	v_fmac_f32_e32 v41, v38, v41
	v_div_scale_f32 v38, vcc, v22, v28, v22
	v_mul_f32_e32 v40, v38, v41
	v_fma_f32 v42, -v37, v40, v38
	v_fmac_f32_e32 v40, v42, v41
	v_fma_f32 v37, -v37, v40, v38
	v_div_scale_f32 v38, s[0:1], v28, v28, v23
	v_rcp_f32_e32 v42, v38
	v_div_fmas_f32 v37, v37, v41, v40
	v_div_fixup_f32 v22, v37, v28, v22
	v_fma_f32 v37, -v38, v42, 1.0
	v_fmac_f32_e32 v42, v37, v42
	v_div_scale_f32 v37, vcc, v23, v28, v23
	v_mul_f32_e32 v40, v37, v42
	v_fma_f32 v41, -v38, v40, v37
	v_fmac_f32_e32 v40, v41, v42
	v_fma_f32 v37, -v38, v40, v37
	v_div_scale_f32 v38, s[0:1], v28, v28, v24
	v_rcp_f32_e32 v41, v38
	v_div_fmas_f32 v37, v37, v42, v40
	v_div_fixup_f32 v23, v37, v28, v23
	v_fma_f32 v37, -v38, v41, 1.0
	v_fmac_f32_e32 v41, v37, v41
	v_div_scale_f32 v37, vcc, v24, v28, v24
	v_mul_f32_e32 v40, v37, v41
	v_fma_f32 v42, -v38, v40, v37
	v_fmac_f32_e32 v40, v42, v41
	v_fma_f32 v37, -v38, v40, v37
	v_div_scale_f32 v38, s[0:1], v28, v28, v25
	v_rcp_f32_e32 v42, v38
	v_div_fmas_f32 v37, v37, v41, v40
	v_div_fixup_f32 v24, v37, v28, v24
	v_fma_f32 v37, -v38, v42, 1.0
	v_fmac_f32_e32 v42, v37, v42
	v_div_scale_f32 v37, vcc, v25, v28, v25
	v_mul_f32_e32 v40, v37, v42
	v_fma_f32 v41, -v38, v40, v37
	v_fmac_f32_e32 v40, v41, v42
	v_fma_f32 v37, -v38, v40, v37
	v_div_scale_f32 v38, s[0:1], v28, v28, v18
	v_rcp_f32_e32 v41, v38
	v_div_fmas_f32 v37, v37, v42, v40
	v_div_fixup_f32 v25, v37, v28, v25
	v_fma_f32 v37, -v38, v41, 1.0
	v_fmac_f32_e32 v41, v37, v41
	v_div_scale_f32 v37, vcc, v18, v28, v18
	v_mul_f32_e32 v40, v37, v41
	v_fma_f32 v42, -v38, v40, v37
	v_fmac_f32_e32 v40, v42, v41
	v_fma_f32 v37, -v38, v40, v37
	v_div_scale_f32 v38, s[0:1], v28, v28, v19
	v_rcp_f32_e32 v42, v38
	v_div_fmas_f32 v37, v37, v41, v40
	v_div_fixup_f32 v18, v37, v28, v18
	v_fma_f32 v37, -v38, v42, 1.0
	v_fmac_f32_e32 v42, v37, v42
	v_div_scale_f32 v37, vcc, v19, v28, v19
	v_mul_f32_e32 v40, v37, v42
	v_fma_f32 v41, -v38, v40, v37
	v_fmac_f32_e32 v40, v41, v42
	v_fma_f32 v37, -v38, v40, v37
	v_div_scale_f32 v38, s[0:1], v28, v28, v20
	v_rcp_f32_e32 v41, v38
	v_div_fmas_f32 v37, v37, v42, v40
	v_div_fixup_f32 v19, v37, v28, v19
	v_fma_f32 v37, -v38, v41, 1.0
	v_fmac_f32_e32 v41, v37, v41
	v_div_scale_f32 v37, vcc, v20, v28, v20
	v_mul_f32_e32 v40, v37, v41
	v_fma_f32 v42, -v38, v40, v37
	v_fmac_f32_e32 v40, v42, v41
	v_fma_f32 v37, -v38, v40, v37
	v_div_scale_f32 v38, s[0:1], v28, v28, v21
	v_rcp_f32_e32 v42, v38
	v_div_fmas_f32 v37, v37, v41, v40
	v_div_fixup_f32 v20, v37, v28, v20
	v_fma_f32 v37, -v38, v42, 1.0
	v_fmac_f32_e32 v42, v37, v42
	v_div_scale_f32 v37, vcc, v21, v28, v21
	v_mul_f32_e32 v40, v37, v42
	v_fma_f32 v41, -v38, v40, v37
	v_fmac_f32_e32 v40, v41, v42
	v_fma_f32 v37, -v38, v40, v37
	v_div_scale_f32 v38, s[0:1], v28, v28, v14
	v_rcp_f32_e32 v41, v38
	v_div_fmas_f32 v37, v37, v42, v40
	v_div_fixup_f32 v21, v37, v28, v21
	v_fma_f32 v37, -v38, v41, 1.0
	v_fmac_f32_e32 v41, v37, v41
	v_div_scale_f32 v37, vcc, v14, v28, v14
	v_mul_f32_e32 v40, v37, v41
	v_fma_f32 v42, -v38, v40, v37
	v_fmac_f32_e32 v40, v42, v41
	v_fma_f32 v37, -v38, v40, v37
	v_div_scale_f32 v38, s[0:1], v28, v28, v15
	v_rcp_f32_e32 v42, v38
	v_div_fmas_f32 v37, v37, v41, v40
	v_div_fixup_f32 v14, v37, v28, v14
	v_fma_f32 v37, -v38, v42, 1.0
	v_fmac_f32_e32 v42, v37, v42
	v_div_scale_f32 v37, vcc, v15, v28, v15
	v_mul_f32_e32 v40, v37, v42
	v_fma_f32 v41, -v38, v40, v37
	v_fmac_f32_e32 v40, v41, v42
	v_fma_f32 v37, -v38, v40, v37
	v_div_scale_f32 v38, s[0:1], v28, v28, v16
	v_rcp_f32_e32 v41, v38
	v_div_fmas_f32 v37, v37, v42, v40
	v_div_fixup_f32 v15, v37, v28, v15
	v_fma_f32 v37, -v38, v41, 1.0
	v_fmac_f32_e32 v41, v37, v41
	v_div_scale_f32 v37, vcc, v16, v28, v16
	v_mul_f32_e32 v40, v37, v41
	v_fma_f32 v42, -v38, v40, v37
	v_fmac_f32_e32 v40, v42, v41
	v_fma_f32 v37, -v38, v40, v37
	v_div_scale_f32 v38, s[0:1], v28, v28, v17
	v_rcp_f32_e32 v42, v38
	v_div_fmas_f32 v37, v37, v41, v40
	v_div_fixup_f32 v16, v37, v28, v16
	v_fma_f32 v37, -v38, v42, 1.0
	v_fmac_f32_e32 v42, v37, v42
	v_div_scale_f32 v37, vcc, v17, v28, v17
	v_mul_f32_e32 v40, v37, v42
	v_fma_f32 v41, -v38, v40, v37
	v_fmac_f32_e32 v40, v41, v42
	v_fma_f32 v37, -v38, v40, v37
	v_div_scale_f32 v38, s[0:1], v28, v28, v10
	v_rcp_f32_e32 v41, v38
	v_div_fmas_f32 v37, v37, v42, v40
	v_div_fixup_f32 v17, v37, v28, v17
	v_fma_f32 v37, -v38, v41, 1.0
	v_fmac_f32_e32 v41, v37, v41
	v_div_scale_f32 v37, vcc, v10, v28, v10
	v_mul_f32_e32 v40, v37, v41
	v_fma_f32 v42, -v38, v40, v37
	v_fmac_f32_e32 v40, v42, v41
	v_fma_f32 v37, -v38, v40, v37
	v_div_scale_f32 v38, s[0:1], v28, v28, v11
	v_rcp_f32_e32 v42, v38
	v_div_fmas_f32 v37, v37, v41, v40
	v_div_fixup_f32 v37, v37, v28, v10
	v_fma_f32 v10, -v38, v42, 1.0
	v_fmac_f32_e32 v42, v10, v42
	v_div_scale_f32 v10, vcc, v11, v28, v11
	v_mul_f32_e32 v40, v10, v42
	v_fma_f32 v41, -v38, v40, v10
	v_fmac_f32_e32 v40, v41, v42
	v_fma_f32 v10, -v38, v40, v10
	v_div_scale_f32 v38, s[0:1], v28, v28, v12
	v_rcp_f32_e32 v41, v38
	v_div_fmas_f32 v10, v10, v42, v40
	v_div_fixup_f32 v40, v10, v28, v11
	v_fma_f32 v10, -v38, v41, 1.0
	v_fmac_f32_e32 v41, v10, v41
	v_div_scale_f32 v10, vcc, v12, v28, v12
	v_mul_f32_e32 v11, v10, v41
	v_fma_f32 v42, -v38, v11, v10
	v_fmac_f32_e32 v11, v42, v41
	v_fma_f32 v10, -v38, v11, v10
	v_div_scale_f32 v38, s[0:1], v28, v28, v13
	v_rcp_f32_e32 v42, v38
	v_div_fmas_f32 v10, v10, v41, v11
	v_div_fixup_f32 v41, v10, v28, v12
	v_fma_f32 v10, -v38, v42, 1.0
	v_fmac_f32_e32 v42, v10, v42
	v_div_scale_f32 v10, vcc, v13, v28, v13
	v_mul_f32_e32 v11, v10, v42
	v_fma_f32 v12, -v38, v11, v10
	v_fmac_f32_e32 v11, v12, v42
	v_div_scale_f32 v12, s[0:1], v28, v28, v6
	v_fma_f32 v10, -v38, v11, v10
	v_rcp_f32_e32 v38, v12
	v_div_fmas_f32 v10, v10, v42, v11
	v_div_fixup_f32 v13, v10, v28, v13
	.loc	1 206 8 is_stmt 0               ; benchmark_qwen36_extend_attention_m756.py:206:8
	v_cvt_pk_bf16_f32 v13, v41, v13
	.loc	1 206 14                        ; benchmark_qwen36_extend_attention_m756.py:206:14
	v_fma_f32 v10, -v12, v38, 1.0
	v_fmac_f32_e32 v38, v10, v38
	v_div_scale_f32 v10, vcc, v6, v28, v6
	v_mul_f32_e32 v11, v10, v38
	v_fma_f32 v42, -v12, v11, v10
	v_fmac_f32_e32 v11, v42, v38
	v_fma_f32 v10, -v12, v11, v10
	v_div_scale_f32 v12, s[0:1], v28, v28, v7
	v_rcp_f32_e32 v42, v12
	v_div_fmas_f32 v10, v10, v38, v11
	v_div_fixup_f32 v38, v10, v28, v6
	v_fma_f32 v6, -v12, v42, 1.0
	v_fmac_f32_e32 v42, v6, v42
	v_div_scale_f32 v6, vcc, v7, v28, v7
	v_mul_f32_e32 v10, v6, v42
	v_fma_f32 v11, -v12, v10, v6
	v_fmac_f32_e32 v10, v11, v42
	v_div_scale_f32 v11, s[0:1], v28, v28, v8
	v_fma_f32 v6, -v12, v10, v6
	v_rcp_f32_e32 v12, v11
	v_div_fmas_f32 v6, v6, v42, v10
	v_div_fixup_f32 v42, v6, v28, v7
	v_fma_f32 v6, -v11, v12, 1.0
	v_fmac_f32_e32 v12, v6, v12
	v_div_scale_f32 v6, vcc, v8, v28, v8
	v_mul_f32_e32 v7, v6, v12
	v_fma_f32 v10, -v11, v7, v6
	v_fmac_f32_e32 v7, v10, v12
	v_div_scale_f32 v10, s[0:1], v28, v28, v9
	v_fma_f32 v6, -v11, v7, v6
	v_rcp_f32_e32 v11, v10
	v_div_fmas_f32 v6, v6, v12, v7
	v_div_fixup_f32 v43, v6, v28, v8
	.loc	1 206 8                         ; benchmark_qwen36_extend_attention_m756.py:206:8
	v_cvt_pk_bf16_f32 v12, v37, v40
	.loc	1 206 14                        ; benchmark_qwen36_extend_attention_m756.py:206:14
	v_fma_f32 v6, -v10, v11, 1.0
	v_fmac_f32_e32 v11, v6, v11
	v_div_scale_f32 v6, vcc, v9, v28, v9
	v_mul_f32_e32 v7, v6, v11
	v_fma_f32 v8, -v10, v7, v6
	v_fmac_f32_e32 v7, v8, v11
	v_div_scale_f32 v8, s[0:1], v28, v28, v0
	v_fma_f32 v6, -v10, v7, v6
	v_rcp_f32_e32 v10, v8
	v_div_fmas_f32 v6, v6, v11, v7
	v_div_fixup_f32 v44, v6, v28, v9
	.loc	1 206 8                         ; benchmark_qwen36_extend_attention_m756.py:206:8
	v_cvt_pk_bf16_f32 v11, v16, v17
	.loc	1 206 14                        ; benchmark_qwen36_extend_attention_m756.py:206:14
	v_fma_f32 v6, -v8, v10, 1.0
	v_fmac_f32_e32 v10, v6, v10
	v_div_scale_f32 v6, vcc, v0, v28, v0
	v_mul_f32_e32 v7, v6, v10
	v_fma_f32 v9, -v8, v7, v6
	v_fmac_f32_e32 v7, v9, v10
	v_fma_f32 v6, -v8, v7, v6
	v_div_scale_f32 v8, s[0:1], v28, v28, v1
	v_rcp_f32_e32 v9, v8
	v_div_fmas_f32 v6, v6, v10, v7
	v_div_fixup_f32 v45, v6, v28, v0
	.loc	1 206 8                         ; benchmark_qwen36_extend_attention_m756.py:206:8
	v_cvt_pk_bf16_f32 v10, v14, v15
	.loc	1 206 14                        ; benchmark_qwen36_extend_attention_m756.py:206:14
	v_fma_f32 v0, -v8, v9, 1.0
	v_fmac_f32_e32 v9, v0, v9
	v_div_scale_f32 v0, vcc, v1, v28, v1
	v_mul_f32_e32 v6, v0, v9
	v_fma_f32 v7, -v8, v6, v0
	v_fmac_f32_e32 v6, v7, v9
	v_div_scale_f32 v7, s[0:1], v28, v28, v2
	v_fma_f32 v0, -v8, v6, v0
	v_rcp_f32_e32 v8, v7
	v_div_fmas_f32 v0, v0, v9, v6
	v_div_fixup_f32 v46, v0, v28, v1
	.loc	1 206 8                         ; benchmark_qwen36_extend_attention_m756.py:206:8
	v_cvt_pk_bf16_f32 v9, v20, v21
	.loc	1 206 14                        ; benchmark_qwen36_extend_attention_m756.py:206:14
	v_fma_f32 v0, -v7, v8, 1.0
	v_fmac_f32_e32 v8, v0, v8
	v_div_scale_f32 v0, vcc, v2, v28, v2
	v_mul_f32_e32 v1, v0, v8
	v_fma_f32 v6, -v7, v1, v0
	v_fmac_f32_e32 v1, v6, v8
	v_div_scale_f32 v6, s[0:1], v28, v28, v3
	v_fma_f32 v0, -v7, v1, v0
	v_rcp_f32_e32 v7, v6
	v_div_fmas_f32 v0, v0, v8, v1
	v_div_fixup_f32 v47, v0, v28, v2
	.loc	1 206 8                         ; benchmark_qwen36_extend_attention_m756.py:206:8
	v_cvt_pk_bf16_f32 v8, v18, v19
	.loc	1 206 14                        ; benchmark_qwen36_extend_attention_m756.py:206:14
	v_fma_f32 v0, -v6, v7, 1.0
	v_fmac_f32_e32 v7, v0, v7
	v_div_scale_f32 v0, vcc, v3, v28, v3
	v_mul_f32_e32 v1, v0, v7
	v_fma_f32 v2, -v6, v1, v0
	v_fmac_f32_e32 v1, v2, v7
	v_fma_f32 v0, -v6, v1, v0
	v_div_fmas_f32 v0, v0, v7, v1
	v_div_fixup_f32 v28, v0, v28, v3
	.loc	1 206 8                         ; benchmark_qwen36_extend_attention_m756.py:206:8
	v_cvt_pk_bf16_f32 v0, v29, v30
	v_cvt_pk_bf16_f32 v1, v31, v32
	v_cvt_pk_bf16_f32 v2, v33, v34
	v_cvt_pk_bf16_f32 v3, v35, v36
	v_add_lshl_u32 v18, v27, s24, 1
	v_permlane16_swap_b32_e32 v0, v2
	v_permlane16_swap_b32_e32 v1, v3
	v_cndmask_b32_e64 v18, v39, v18, s[44:45]
	v_cvt_pk_bf16_f32 v6, v22, v23
	v_cvt_pk_bf16_f32 v7, v24, v25
	buffer_store_dwordx4 v[0:3], v18, s[8:11], 0 offen
	v_permlane16_swap_b32_e32 v6, v8
	s_nop 0
	v_add_lshl_u32 v0, v26, s24, 1
	v_permlane16_swap_b32_e32 v7, v9
	v_cndmask_b32_e64 v0, v39, v0, s[44:45]
	buffer_store_dwordx4 v[6:9], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v5, s24, 1
	v_permlane16_swap_b32_e32 v10, v12
	v_permlane16_swap_b32_e32 v11, v13
	v_cndmask_b32_e64 v0, v39, v0, s[44:45]
	v_cvt_pk_bf16_f32 v14, v38, v42
	v_cvt_pk_bf16_f32 v15, v43, v44
	v_cvt_pk_bf16_f32 v16, v45, v46
	v_cvt_pk_bf16_f32 v17, v47, v28
	buffer_store_dwordx4 v[10:13], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v4, s24, 1
	v_permlane16_swap_b32_e32 v14, v16
	v_permlane16_swap_b32_e32 v15, v17
	v_cndmask_b32_e64 v0, v39, v0, s[44:45]
	buffer_store_dwordx4 v[14:17], v0, s[8:11], 0 offen
	.loc	1 204 4 is_stmt 1               ; benchmark_qwen36_extend_attention_m756.py:204:4
	s_endpgm
.Ltmp93:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel qwen36_extend_attention_m16_gqa4_gfx950
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 96
		.amdhsa_user_sgpr_count 16
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 0
		.amdhsa_user_sgpr_kernarg_preload_length 14
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 257
		.amdhsa_next_free_sgpr 102
		.amdhsa_accum_offset 140
		.amdhsa_reserve_vcc 1
		.amdhsa_reserve_xnack_mask 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
		.amdhsa_exception_fp_ieee_invalid_op 0
		.amdhsa_exception_fp_denorm_src 0
		.amdhsa_exception_fp_ieee_div_zero 0
		.amdhsa_exception_fp_ieee_overflow 0
		.amdhsa_exception_fp_ieee_underflow 0
		.amdhsa_exception_fp_ieee_inexact 0
		.amdhsa_exception_int_div_zero 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size	qwen36_extend_attention_m16_gqa4_gfx950, .Lfunc_end0-qwen36_extend_attention_m16_gqa4_gfx950
	.cfi_endproc
                                        ; -- End function
	.set qwen36_extend_attention_m16_gqa4_gfx950.num_vgpr, 137
	.set qwen36_extend_attention_m16_gqa4_gfx950.num_agpr, 0
	.set qwen36_extend_attention_m16_gqa4_gfx950.numbered_sgpr, 102
	.set qwen36_extend_attention_m16_gqa4_gfx950.num_named_barrier, 0
	.set qwen36_extend_attention_m16_gqa4_gfx950.private_seg_size, 0
	.set qwen36_extend_attention_m16_gqa4_gfx950.uses_vcc, 1
	.set qwen36_extend_attention_m16_gqa4_gfx950.uses_flat_scratch, 0
	.set qwen36_extend_attention_m16_gqa4_gfx950.has_dyn_sized_stack, 0
	.set qwen36_extend_attention_m16_gqa4_gfx950.has_recursion, 0
	.set qwen36_extend_attention_m16_gqa4_gfx950.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 9640
; TotalNumSgprs: 106
; NumVgprs: 137
; NumAgprs: 0
; TotalNumVgprs: 137
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 13
; VGPRBlocks: 32
; NumSGPRsForWavesPerEU: 106
; NumVGPRsForWavesPerEU: 257
; AccumOffset: 140
; Occupancy: 1
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 34
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.set amdgpu.max_num_named_barrier, 0
	.text
	.section	.debug_abbrev,"",@progbits
	.byte	1                               ; Abbreviation Code
	.byte	17                              ; DW_TAG_compile_unit
	.byte	1                               ; DW_CHILDREN_yes
	.byte	37                              ; DW_AT_producer
	.byte	14                              ; DW_FORM_strp
	.byte	19                              ; DW_AT_language
	.byte	5                               ; DW_FORM_data2
	.byte	3                               ; DW_AT_name
	.byte	14                              ; DW_FORM_strp
	.byte	16                              ; DW_AT_stmt_list
	.byte	23                              ; DW_FORM_sec_offset
	.byte	27                              ; DW_AT_comp_dir
	.byte	14                              ; DW_FORM_strp
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	2                               ; Abbreviation Code
	.byte	46                              ; DW_TAG_subprogram
	.byte	0                               ; DW_CHILDREN_no
	.byte	3                               ; DW_AT_name
	.byte	14                              ; DW_FORM_strp
	.byte	32                              ; DW_AT_inline
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	3                               ; Abbreviation Code
	.byte	46                              ; DW_TAG_subprogram
	.byte	1                               ; DW_CHILDREN_yes
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	4                               ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	1                               ; DW_CHILDREN_yes
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	85                              ; DW_AT_ranges
	.byte	23                              ; DW_FORM_sec_offset
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	11                              ; DW_FORM_data1
	.byte	87                              ; DW_AT_call_column
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	5                               ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	0                               ; DW_CHILDREN_no
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	85                              ; DW_AT_ranges
	.byte	23                              ; DW_FORM_sec_offset
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	11                              ; DW_FORM_data1
	.byte	87                              ; DW_AT_call_column
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	6                               ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	0                               ; DW_CHILDREN_no
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	85                              ; DW_AT_ranges
	.byte	23                              ; DW_FORM_sec_offset
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	5                               ; DW_FORM_data2
	.byte	87                              ; DW_AT_call_column
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	7                               ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	1                               ; DW_CHILDREN_yes
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	11                              ; DW_FORM_data1
	.byte	87                              ; DW_AT_call_column
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	0                               ; EOM(3)
	.section	.debug_info,"",@progbits
.Lcu_begin0:
	.long	.Ldebug_info_end0-.Ldebug_info_start0 ; Length of Unit
.Ldebug_info_start0:
	.short	4                               ; DWARF version number
	.long	.debug_abbrev                   ; Offset Into Abbrev. Section
	.byte	8                               ; Address Size (in bytes)
	.byte	1                               ; Abbrev [1] 0xb:0xd8 DW_TAG_compile_unit
	.long	.Linfo_string0                  ; DW_AT_producer
	.short	2                               ; DW_AT_language
	.long	.Linfo_string1                  ; DW_AT_name
	.long	.Lline_table_start0             ; DW_AT_stmt_list
	.long	.Linfo_string2                  ; DW_AT_comp_dir
	.quad	.Lfunc_begin0                   ; DW_AT_low_pc
	.long	.Lfunc_end0-.Lfunc_begin0       ; DW_AT_high_pc
	.byte	2                               ; Abbrev [2] 0x2a:0x6 DW_TAG_subprogram
	.long	.Linfo_string3                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x30:0xb2 DW_TAG_subprogram
	.quad	.Lfunc_begin0                   ; DW_AT_low_pc
	.long	.Lfunc_end0-.Lfunc_begin0       ; DW_AT_high_pc
	.long	42                              ; DW_AT_abstract_origin
	.byte	4                               ; Abbrev [4] 0x41:0x19 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges0                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	130                             ; DW_AT_call_line
	.byte	34                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x4d:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges1                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0x5a:0x19 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges2                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	130                             ; DW_AT_call_line
	.byte	27                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x66:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges3                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0x73:0x19 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges4                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	149                             ; DW_AT_call_line
	.byte	29                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x7f:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges5                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0x8c:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges6                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	154                             ; DW_AT_call_line
	.byte	43                              ; DW_AT_call_column
	.byte	6                               ; Abbrev [6] 0x98:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges7                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.short	293                             ; DW_AT_call_line
	.byte	36                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	7                               ; Abbrev [7] 0xa6:0x21 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.quad	.Ltmp70                         ; DW_AT_low_pc
	.long	.Ltmp75-.Ltmp70                 ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	182                             ; DW_AT_call_line
	.byte	21                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0xba:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges8                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0xc7:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges9                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	187                             ; DW_AT_call_line
	.byte	35                              ; DW_AT_call_column
	.byte	6                               ; Abbrev [6] 0xd3:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges10                ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.short	293                             ; DW_AT_call_line
	.byte	36                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
.Ldebug_info_end0:
	.section	.debug_ranges,"",@progbits
.Ldebug_ranges0:
	.quad	.Ltmp2-.Lfunc_begin0
	.quad	.Ltmp3-.Lfunc_begin0
	.quad	.Ltmp4-.Lfunc_begin0
	.quad	.Ltmp5-.Lfunc_begin0
	.quad	.Ltmp6-.Lfunc_begin0
	.quad	.Ltmp7-.Lfunc_begin0
	.quad	.Ltmp8-.Lfunc_begin0
	.quad	.Ltmp10-.Lfunc_begin0
	.quad	.Ltmp12-.Lfunc_begin0
	.quad	.Ltmp14-.Lfunc_begin0
	.quad	.Ltmp15-.Lfunc_begin0
	.quad	.Ltmp29-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges1:
	.quad	.Ltmp2-.Lfunc_begin0
	.quad	.Ltmp3-.Lfunc_begin0
	.quad	.Ltmp4-.Lfunc_begin0
	.quad	.Ltmp5-.Lfunc_begin0
	.quad	.Ltmp6-.Lfunc_begin0
	.quad	.Ltmp7-.Lfunc_begin0
	.quad	.Ltmp8-.Lfunc_begin0
	.quad	.Ltmp9-.Lfunc_begin0
	.quad	.Ltmp13-.Lfunc_begin0
	.quad	.Ltmp14-.Lfunc_begin0
	.quad	.Ltmp15-.Lfunc_begin0
	.quad	.Ltmp16-.Lfunc_begin0
	.quad	.Ltmp17-.Lfunc_begin0
	.quad	.Ltmp18-.Lfunc_begin0
	.quad	.Ltmp19-.Lfunc_begin0
	.quad	.Ltmp20-.Lfunc_begin0
	.quad	.Ltmp21-.Lfunc_begin0
	.quad	.Ltmp22-.Lfunc_begin0
	.quad	.Ltmp23-.Lfunc_begin0
	.quad	.Ltmp24-.Lfunc_begin0
	.quad	.Ltmp25-.Lfunc_begin0
	.quad	.Ltmp26-.Lfunc_begin0
	.quad	.Ltmp27-.Lfunc_begin0
	.quad	.Ltmp28-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges2:
	.quad	.Ltmp11-.Lfunc_begin0
	.quad	.Ltmp12-.Lfunc_begin0
	.quad	.Ltmp14-.Lfunc_begin0
	.quad	.Ltmp15-.Lfunc_begin0
	.quad	.Ltmp29-.Lfunc_begin0
	.quad	.Ltmp34-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges3:
	.quad	.Ltmp30-.Lfunc_begin0
	.quad	.Ltmp31-.Lfunc_begin0
	.quad	.Ltmp32-.Lfunc_begin0
	.quad	.Ltmp33-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges4:
	.quad	.Ltmp35-.Lfunc_begin0
	.quad	.Ltmp36-.Lfunc_begin0
	.quad	.Ltmp37-.Lfunc_begin0
	.quad	.Ltmp38-.Lfunc_begin0
	.quad	.Ltmp39-.Lfunc_begin0
	.quad	.Ltmp40-.Lfunc_begin0
	.quad	.Ltmp41-.Lfunc_begin0
	.quad	.Ltmp42-.Lfunc_begin0
	.quad	.Ltmp43-.Lfunc_begin0
	.quad	.Ltmp44-.Lfunc_begin0
	.quad	.Ltmp45-.Lfunc_begin0
	.quad	.Ltmp46-.Lfunc_begin0
	.quad	.Ltmp47-.Lfunc_begin0
	.quad	.Ltmp52-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges5:
	.quad	.Ltmp35-.Lfunc_begin0
	.quad	.Ltmp36-.Lfunc_begin0
	.quad	.Ltmp37-.Lfunc_begin0
	.quad	.Ltmp38-.Lfunc_begin0
	.quad	.Ltmp39-.Lfunc_begin0
	.quad	.Ltmp40-.Lfunc_begin0
	.quad	.Ltmp41-.Lfunc_begin0
	.quad	.Ltmp42-.Lfunc_begin0
	.quad	.Ltmp43-.Lfunc_begin0
	.quad	.Ltmp44-.Lfunc_begin0
	.quad	.Ltmp45-.Lfunc_begin0
	.quad	.Ltmp46-.Lfunc_begin0
	.quad	.Ltmp47-.Lfunc_begin0
	.quad	.Ltmp48-.Lfunc_begin0
	.quad	.Ltmp49-.Lfunc_begin0
	.quad	.Ltmp50-.Lfunc_begin0
	.quad	.Ltmp51-.Lfunc_begin0
	.quad	.Ltmp52-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges6:
	.quad	.Ltmp53-.Lfunc_begin0
	.quad	.Ltmp54-.Lfunc_begin0
	.quad	.Ltmp55-.Lfunc_begin0
	.quad	.Ltmp56-.Lfunc_begin0
	.quad	.Ltmp57-.Lfunc_begin0
	.quad	.Ltmp58-.Lfunc_begin0
	.quad	.Ltmp59-.Lfunc_begin0
	.quad	.Ltmp60-.Lfunc_begin0
	.quad	.Ltmp61-.Lfunc_begin0
	.quad	.Ltmp62-.Lfunc_begin0
	.quad	.Ltmp63-.Lfunc_begin0
	.quad	.Ltmp64-.Lfunc_begin0
	.quad	.Ltmp65-.Lfunc_begin0
	.quad	.Ltmp67-.Lfunc_begin0
	.quad	.Ltmp68-.Lfunc_begin0
	.quad	.Ltmp69-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges7:
	.quad	.Ltmp53-.Lfunc_begin0
	.quad	.Ltmp54-.Lfunc_begin0
	.quad	.Ltmp55-.Lfunc_begin0
	.quad	.Ltmp56-.Lfunc_begin0
	.quad	.Ltmp57-.Lfunc_begin0
	.quad	.Ltmp58-.Lfunc_begin0
	.quad	.Ltmp59-.Lfunc_begin0
	.quad	.Ltmp60-.Lfunc_begin0
	.quad	.Ltmp61-.Lfunc_begin0
	.quad	.Ltmp62-.Lfunc_begin0
	.quad	.Ltmp65-.Lfunc_begin0
	.quad	.Ltmp66-.Lfunc_begin0
	.quad	.Ltmp68-.Lfunc_begin0
	.quad	.Ltmp69-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges8:
	.quad	.Ltmp70-.Lfunc_begin0
	.quad	.Ltmp71-.Lfunc_begin0
	.quad	.Ltmp72-.Lfunc_begin0
	.quad	.Ltmp73-.Lfunc_begin0
	.quad	.Ltmp74-.Lfunc_begin0
	.quad	.Ltmp75-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges9:
	.quad	.Ltmp76-.Lfunc_begin0
	.quad	.Ltmp77-.Lfunc_begin0
	.quad	.Ltmp78-.Lfunc_begin0
	.quad	.Ltmp79-.Lfunc_begin0
	.quad	.Ltmp80-.Lfunc_begin0
	.quad	.Ltmp81-.Lfunc_begin0
	.quad	.Ltmp82-.Lfunc_begin0
	.quad	.Ltmp83-.Lfunc_begin0
	.quad	.Ltmp84-.Lfunc_begin0
	.quad	.Ltmp86-.Lfunc_begin0
	.quad	.Ltmp87-.Lfunc_begin0
	.quad	.Ltmp89-.Lfunc_begin0
	.quad	.Ltmp90-.Lfunc_begin0
	.quad	.Ltmp92-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges10:
	.quad	.Ltmp76-.Lfunc_begin0
	.quad	.Ltmp77-.Lfunc_begin0
	.quad	.Ltmp78-.Lfunc_begin0
	.quad	.Ltmp79-.Lfunc_begin0
	.quad	.Ltmp80-.Lfunc_begin0
	.quad	.Ltmp81-.Lfunc_begin0
	.quad	.Ltmp82-.Lfunc_begin0
	.quad	.Ltmp83-.Lfunc_begin0
	.quad	.Ltmp84-.Lfunc_begin0
	.quad	.Ltmp85-.Lfunc_begin0
	.quad	.Ltmp87-.Lfunc_begin0
	.quad	.Ltmp88-.Lfunc_begin0
	.quad	.Ltmp91-.Lfunc_begin0
	.quad	.Ltmp92-.Lfunc_begin0
	.quad	0
	.quad	0
	.section	.debug_str,"MS",@progbits,1
.Linfo_string0:
	.asciz	"triton"                        ; string offset=0
.Linfo_string1:
	.asciz	"benchmark_qwen36_extend_attention_m756.py" ; string offset=7
.Linfo_string2:
	.asciz	"/netra-kernel/tools/benchmark" ; string offset=49
.Linfo_string3:
	.asciz	"qwen36_extend_attention_m16_gqa4_gfx950"
	.section	".note.GNU-stack","",@progbits
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         24
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         32
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         40
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         48
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         56
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         64
        .size:           8
        .value_kind:     global_buffer
      - .offset:         72
        .size:           4
        .value_kind:     by_value
      - .address_space:  global
        .offset:         80
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         88
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 96
    .max_flat_workgroup_size: 256
    .name:           qwen36_extend_attention_m16_gqa4_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count:     106
    .sgpr_spill_count: 5
    .symbol:         qwen36_extend_attention_m16_gqa4_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     156
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
	.section	.debug_line,"",@progbits
.Lline_table_start0:
