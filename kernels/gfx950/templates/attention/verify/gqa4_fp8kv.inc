// Netra model-independent fixed-contract tactic template.
	.include "kernels/gfx950/templates/common/primitives.inc"
	NETRA_GFX950_MODULE_HEADER 5
	.macro NETRA_ATTENTION_GQA4_FP8KV symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_M_MAX, 16
	NETRA_REQUIRE_EQ NETRA_QUERY_HEADS, 32
	NETRA_REQUIRE_EQ NETRA_KV_HEADS, 8
	NETRA_REQUIRE_EQ NETRA_HEAD_DIM, 128
	NETRA_REQUIRE_EQ NETRA_KV_LAYOUT_ID, 1
	NETRA_KERNEL_ENTRY \symbol, 0
.Lfunc_begin0:
	.cfi_sections .debug_frame
	.cfi_startproc
; %bb.10:
	.file	1 "/netra-kernel/tools/benchmark" "benchmark_qwen36_extend_attention_m756.py"
	.loc	1 123 0 prologue_end            ; benchmark_qwen36_extend_attention_m756.py:123:0
	NETRA_LOAD_KERNARG_PTR s[2:3], 0x0
	NETRA_LOAD_KERNARG_U32X8 s[4:11], 0x8
	NETRA_LOAD_KERNARG_U32X4 s[12:15], 0x28
	NETRA_WAIT_LGKM0
	s_branch .LBB0_0
	.loc	1 0 0 is_stmt 0                 ; :0:0
.Ltmp0:
	.p2align	8
; %bb.11:
.LBB0_0:
	s_mov_b64 s[20:21], s[2:3]
	s_load_dwordx2 s[2:3], s[0:1], 0x38
	s_mov_b64 s[56:57], s[10:11]
	s_mov_b64 s[52:53], s[6:7]
	s_mov_b32 s18, s16
.Ltmp1:
	.loc	1 123 0 is_stmt 1               ; benchmark_qwen36_extend_attention_m756.py:123
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	.loc	1 245 16                        ; benchmark_qwen36_extend_attention_m756.py:245:16
	v_readfirstlane_b32 s6, v0
	.loc	1 151 22                        ; benchmark_qwen36_extend_attention_m756.py:151:22
	s_ashr_i32 s19, s18, 31
	.loc	1 257 8                         ; benchmark_qwen36_extend_attention_m756.py:257:8
	s_and_b32 s16, s6, 0xc0
	.loc	1 151 22                        ; benchmark_qwen36_extend_attention_m756.py:151:22
	s_lshl_b64 s[10:11], s[18:19], 3
	s_add_u32 s10, s14, s10
	s_addc_u32 s11, s15, s11
	v_mov_b32_e32 v5, 0
	global_load_dwordx4 v[42:45], v5, s[10:11]
	.loc	1 156 31                        ; benchmark_qwen36_extend_attention_m756.py:156:31
	v_and_b32_e32 v51, 63, v0
	v_or_b32_e32 v55, s16, v51
	.loc	1 153 23                        ; benchmark_qwen36_extend_attention_m756.py:153:23
	s_lshl_b64 s[10:11], s[18:19], 2
	.loc	1 156 31                        ; benchmark_qwen36_extend_attention_m756.py:156:31
	v_lshrrev_b32_e32 v52, 3, v55
	.loc	1 153 23                        ; benchmark_qwen36_extend_attention_m756.py:153:23
	NETRA_WAIT_LGKM0
	s_add_u32 s2, s2, s10
	.loc	1 156 31                        ; benchmark_qwen36_extend_attention_m756.py:156:31
	v_or_b32_e32 v50, 32, v52
	.loc	1 166 17                        ; benchmark_qwen36_extend_attention_m756.py:166:17
	v_and_b32_e32 v2, 7, v0
	.loc	1 157 31                        ; benchmark_qwen36_extend_attention_m756.py:157:31
	v_bfe_u32 v4, v55, 3, 4
	.loc	1 153 23                        ; benchmark_qwen36_extend_attention_m756.py:153:23
	s_addc_u32 s3, s3, s11
	.loc	1 158 35                        ; benchmark_qwen36_extend_attention_m756.py:158:35
	v_lshrrev_b32_e32 v8, 4, v50
	.loc	1 165 25                        ; benchmark_qwen36_extend_attention_m756.py:165:25
	s_lshl_b32 s64, s17, 2
	.loc	1 165 55 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:165:55
	s_lshl_b32 s7, s17, 9
	s_and_b32 s10, s6, 0x80
	.loc	1 166 17 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:166:17
	v_lshlrev_b32_e32 v54, 4, v2
	.loc	1 168 27                        ; benchmark_qwen36_extend_attention_m756.py:168:27
	v_lshlrev_b32_e32 v3, 12, v4
	.loc	1 153 23                        ; benchmark_qwen36_extend_attention_m756.py:153:23
	global_load_dwordx2 v[6:7], v5, s[2:3]
	.loc	1 165 29                        ; benchmark_qwen36_extend_attention_m756.py:165:29
	v_or_b32_e32 v8, s64, v8
	.loc	1 165 55 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:165:55
	s_or_b32 s2, s10, s7
	.loc	1 166 17 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:166:17
	v_or_b32_e32 v56, 8, v54
	.loc	1 168 27                        ; benchmark_qwen36_extend_attention_m756.py:168:27
	v_add_u32_e32 v9, s2, v3
	v_lshl_add_u32 v3, v8, 7, v3
	.loc	1 168 16 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:168:16
	v_bfrev_b32_e32 v1, 1
	s_mov_b32 s23, 0x27000
	s_mov_b32 s22, 0x7ffffffe
	s_and_b32 s21, s21, 0xffff
	.loc	1 152 47 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:152:47
	s_waitcnt vmcnt(1)
	v_sub_co_u32_e32 v46, vcc, v44, v42
	.loc	1 168 27                        ; benchmark_qwen36_extend_attention_m756.py:168:27
	v_lshlrev_b64 v[48:49], 12, v[42:43]
	.loc	1 152 47                        ; benchmark_qwen36_extend_attention_m756.py:152:47
	s_nop 0
	v_subb_co_u32_e32 v47, vcc, v45, v43, vcc
	.loc	1 168 27                        ; benchmark_qwen36_extend_attention_m756.py:168:27
	v_or_b32_e32 v8, v48, v54
	v_or_b32_e32 v10, v48, v56
	.loc	1 168 16 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:168:16
	v_add_lshl_u32 v11, v8, v9, 1
	.loc	1 161 26 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:161:26
	v_cmp_gt_i64_e32 vcc, v[46:47], v[4:5]
	.loc	1 168 16                        ; benchmark_qwen36_extend_attention_m756.py:168:16
	v_add_lshl_u32 v9, v10, v9, 1
	v_add_lshl_u32 v8, v8, v3, 1
	v_add_lshl_u32 v3, v10, v3, 1
	v_cndmask_b32_e32 v4, v1, v11, vcc
	v_cndmask_b32_e32 v9, v1, v9, vcc
	v_cndmask_b32_e32 v8, v1, v8, vcc
	v_cndmask_b32_e32 v1, v1, v3, vcc
	buffer_load_dwordx4 v[102:105], v4, s[20:23], 0 offen
	buffer_load_dwordx4 v[98:101], v9, s[20:23], 0 offen
	buffer_load_dwordx4 v[110:113], v8, s[20:23], 0 offen
	buffer_load_dwordx4 v[106:109], v1, s[20:23], 0 offen
	.loc	1 198 29                        ; benchmark_qwen36_extend_attention_m756.py:198:29
	v_lshlrev_b32_e32 v3, 2, v0
	.loc	1 153 23                        ; benchmark_qwen36_extend_attention_m756.py:153:23
	s_waitcnt vmcnt(4)
	v_readfirstlane_b32 s14, v6
	.loc	1 154 52                        ; benchmark_qwen36_extend_attention_m756.py:154:52
	v_readfirstlane_b32 s2, v7
	.loc	1 156 31                        ; benchmark_qwen36_extend_attention_m756.py:156:31
	v_and_b32_e32 v44, 15, v0
	.loc	1 161 26                        ; benchmark_qwen36_extend_attention_m756.py:161:26
	v_mov_b32_e32 v45, v5
	.loc	1 198 29                        ; benchmark_qwen36_extend_attention_m756.py:198:29
	v_and_b32_e32 v3, 0xe0, v3
	v_lshlrev_b32_e32 v49, 5, v55
	.loc	1 154 52                        ; benchmark_qwen36_extend_attention_m756.py:154:52
	s_sub_i32 s67, s2, s14
	.loc	1 156 31                        ; benchmark_qwen36_extend_attention_m756.py:156:31
	v_and_b32_e32 v1, 48, v0
	v_and_b32_e32 v43, 60, v0
	.loc	1 198 29                        ; benchmark_qwen36_extend_attention_m756.py:198:29
	v_xad_u32 v3, v49, v3, 0
	.loc	1 161 26                        ; benchmark_qwen36_extend_attention_m756.py:161:26
	v_cmp_gt_i64_e64 s[48:49], v[46:47], v[44:45]
	.loc	1 174 40                        ; benchmark_qwen36_extend_attention_m756.py:174:40
	s_cmp_gt_i32 s67, 0
	v_lshlrev_b32_e32 v45, 3, v0
	.loc	1 198 29                        ; benchmark_qwen36_extend_attention_m756.py:198:29
	s_waitcnt vmcnt(3)
	ds_write_b128 v3, v[102:105]
	s_waitcnt vmcnt(2)
	ds_write_b128 v3, v[98:101] offset:16
	s_waitcnt vmcnt(1)
	ds_write_b128 v3, v[110:113] offset:8192
	NETRA_WAIT_VM0
	ds_write_b128 v3, v[106:109] offset:8208
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	.loc	1 174 40                        ; benchmark_qwen36_extend_attention_m756.py:174:40
	s_cbranch_scc1 .LBB0_2
; %bb.1:                                ; %.._crit_edge_crit_edge
	.loc	1 227 24                        ; benchmark_qwen36_extend_attention_m756.py:227:24
	s_lshl_b32 s66, s17, 7
	s_mov_b64 s[2:3], 0
	s_branch .LBB0_3
.LBB0_2:
	.loc	1 0 24 is_stmt 0                ; benchmark_qwen36_extend_attention_m756.py:0:24
	s_mov_b64 s[2:3], -1
                                        ; implicit-def: $sgpr66
.LBB0_3:                                ; %Flow327
	s_load_dword s33, s[0:1], 0x48
	s_bfe_u32 s54, s6, 0x20006
	v_lshrrev_b32_e32 v58, 2, v1
	v_lshlrev_b32_e32 v57, 8, v44
	s_andn2_b64 vcc, exec, s[2:3]
	s_lshl_b32 s65, s16, 6
	s_cbranch_vccnz .LBB0_8
; %bb.4:                                ; %.lr.ph
	.loc	1 161 26 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:161:26
	s_mov_b32 s55, 0
	s_load_dwordx2 s[60:61], s[0:1], 0x40
	.loc	1 156 31                        ; benchmark_qwen36_extend_attention_m756.py:156:31
	s_or_b32 s0, s54, 4
	.loc	1 161 26                        ; benchmark_qwen36_extend_attention_m756.py:161:26
	s_mov_b32 s1, s55
	.loc	1 198 29                        ; benchmark_qwen36_extend_attention_m756.py:198:29
	v_lshlrev_b32_e32 v2, 5, v2
	v_lshlrev_b32_e32 v4, 1, v1
	.loc	1 161 26                        ; benchmark_qwen36_extend_attention_m756.py:161:26
	v_cmp_lt_i64_e64 s[2:3], s[0:1], v[46:47]
	.loc	1 198 29                        ; benchmark_qwen36_extend_attention_m756.py:198:29
	v_or_b32_e32 v3, s65, v2
	v_bitop3_b32 v2, s65, v4, v2 bitop3:0x36
	s_movk_i32 s0, 0x80
	v_bitop3_b32 v2, v2, s0, v57 bitop3:0x36
	v_add_u32_e32 v2, 0, v2
	ds_read_b128 v[6:9], v2
	ds_read_b128 v[10:13], v2 offset:16
	v_bitop3_b32 v3, v3, v57, v4 bitop3:0xde
	v_add_u32_e32 v14, 0, v3
	ds_read_b128 v[2:5], v14
	ds_read_b128 v[14:17], v14 offset:16
	NETRA_WAIT_LGKM0
	v_cvt_scalef32_pk_fp8_bf16 v6, v6, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v6, v7, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v7, v8, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v8, v10, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v8, v11, 1.0 op_sel:[0,0,1]
	v_and_b32_e32 v11, 0x70, v55
	v_cvt_scalef32_pk_fp8_bf16 v7, v9, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v9, v12, 1.0
	v_lshlrev_b32_e32 v10, 4, v55
	v_lshrrev_b32_e32 v11, 1, v11
	v_lshlrev_b32_e32 v18, 6, v0
	v_cvt_scalef32_pk_fp8_bf16 v9, v13, 1.0 op_sel:[0,0,1]
	s_movk_i32 s0, 0x70
	v_lshlrev_b32_e32 v12, 7, v44
	v_and_b32_e32 v13, 0x70, v45
	v_xor_b32_e32 v68, v11, v10
	v_lshlrev_b32_e32 v11, 1, v0
	v_cvt_scalef32_pk_fp8_bf16 v2, v2, 1.0
	v_bitop3_b32 v65, v10, v55, s0 bitop3:0x78
	v_bitop3_b32 v66, v12, v1, v13 bitop3:0x36
	v_and_b32_e32 v10, 0xf80, v18
	v_and_b32_e32 v11, 56, v11
	v_and_b32_e32 v12, 8, v45
	v_and_b32_e32 v19, 0xc0, v18
	v_cvt_scalef32_pk_fp8_bf16 v2, v3, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v3, v4, 1.0
	v_bitop3_b32 v70, v10, v12, v11 bitop3:0x36
	.loc	1 156 31                        ; benchmark_qwen36_extend_attention_m756.py:156:31
	s_or_b32 s6, s54, 8
	s_or_b32 s10, s54, 12
	.loc	1 161 26                        ; benchmark_qwen36_extend_attention_m756.py:161:26
	s_mov_b32 s7, s55
	s_mov_b32 s11, s55
	.loc	1 178 36                        ; benchmark_qwen36_extend_attention_m756.py:178:36
	s_add_i32 s68, s67, s54
	v_add_u32_e32 v64, 0, v19
	s_lshl_b32 s66, s17, 7
	v_cvt_scalef32_pk_fp8_bf16 v3, v5, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v4, v14, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v5, v16, 1.0
	v_xor_b32_e32 v67, 64, v66
	v_xor_b32_e32 v69, 8, v68
	v_xor_b32_e32 v71, 16, v70
	v_xor_b32_e32 v72, 32, v70
	v_xor_b32_e32 v73, 48, v70
	.loc	1 174 40                        ; benchmark_qwen36_extend_attention_m756.py:174:40
	v_add_u32_e32 v10, s16, v51
	.loc	1 161 26                        ; benchmark_qwen36_extend_attention_m756.py:161:26
	v_cmp_lt_i64_e32 vcc, s[54:55], v[46:47]
	v_cmp_lt_i64_e64 s[6:7], s[6:7], v[46:47]
	v_cmp_lt_i64_e64 s[10:11], s[10:11], v[46:47]
	.loc	1 178 36                        ; benchmark_qwen36_extend_attention_m756.py:178:36
	v_add_u32_e32 v53, s67, v44
	s_add_i32 s69, s68, 4
	s_add_i32 s70, s68, 8
	s_add_i32 s71, s68, 12
	s_and_b32 s61, s61, 0xffff
	s_mov_b32 s63, 0x27000
	s_mov_b32 s62, 0x7ffffffe
	v_or_b32_e32 v59, s66, v54
	s_and_b32 s57, s57, 0xffff
	v_cvt_scalef32_pk_fp8_bf16 v4, v15, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v5, v17, 1.0 op_sel:[0,0,1]
	s_and_b32 s13, s13, 0xffff
	.loc	1 174 40                        ; benchmark_qwen36_extend_attention_m756.py:174:40
	s_lshl_b32 s72, s14, 3
	v_lshrrev_b32_e32 v62, 3, v10
	v_and_b32_e32 v63, 0x1f8, v10
	v_mov_b32_e32 v60, 0xff800000
	v_mov_b32_e32 v61, 0
	.loc	1 176 27                        ; benchmark_qwen36_extend_attention_m756.py:176:27
	v_mov_b32_e32 v40, 0
	v_mov_b32_e32 v41, 0
	v_mov_b32_e32 v38, 0
	v_mov_b32_e32 v39, 0
	v_mov_b32_e32 v36, 0
	v_mov_b32_e32 v37, 0
	v_mov_b32_e32 v34, 0
	v_mov_b32_e32 v35, 0
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
	s_add_i32 s73, s16, 0
	v_add_u32_e32 v64, v64, v43
	v_add_u32_e32 v65, 0, v65
	v_add_u32_e32 v66, 0, v66
	v_add_u32_e32 v67, 0, v67
	s_mov_b32 s74, 0xff800000
	s_mov_b32 s75, 0xc2fc0000
	v_add_u32_e32 v68, 0, v68
	v_add_u32_e32 v69, 0, v69
	v_add_u32_e32 v70, 0, v70
	v_add_u32_e32 v71, 0, v71
	v_add_u32_e32 v72, 0, v72
	v_add_u32_e32 v73, 0, v73
	v_bfrev_b32_e32 v74, 1
	v_mov_b32_e32 v75, 0xff800000
	v_mov_b32_e32 v76, 0xe0ad78ec
	v_mov_b32_e32 v77, 0x42800000
	v_not_b32_e32 v78, 63
	s_branch .LBB0_6
.LBB0_5:                                ;   in Loop: Header=BB0_6 Depth=1
	.loc	1 174 40                        ; benchmark_qwen36_extend_attention_m756.py:174:40
	s_add_i32 s55, s55, 64
	s_cmp_lt_i32 s55, s67
	v_add_u32_e32 v63, 0x200, v63
	s_cbranch_scc0 .LBB0_9
.LBB0_6:                                ; =>This Inner Loop Header: Depth=1
	.loc	1 176 36                        ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_add_u32_e32 v79, s55, v51
	v_cmp_gt_i32_e64 s[0:1], s67, v79
	.loc	1 179 12                        ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_add_u32_e32 v79, 0xfff, v79
	v_cmp_le_i32_e64 s[14:15], s68, v79
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[14:15], vcc, s[14:15]
	s_and_b64 s[14:15], s[0:1], s[14:15]
	.loc	1 179 12                        ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_cmp_le_i32_e64 s[16:17], s69, v79
	v_cmp_le_i32_e64 s[18:19], s70, v79
	v_cmp_le_i32_e64 s[20:21], s71, v79
	.loc	1 181 48                        ; benchmark_qwen36_extend_attention_m756.py:181:48
	v_cndmask_b32_e64 v79, 0, 1, s[14:15]
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[16:17], s[2:3], s[16:17]
	s_and_b64 s[14:15], s[0:1], s[16:17]
.Ltmp2:
	.file	2 "/sgl-workspace/triton-custom/python/triton/language" "standard.py"
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ] ]
	v_max_i32_dpp v79, v79, v79 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp3:
	.loc	1 181 48                        ; benchmark_qwen36_extend_attention_m756.py:181:48
	v_cndmask_b32_e64 v80, 0, 1, s[14:15]
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[18:19], s[6:7], s[18:19]
.Ltmp4:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ] ]
	v_max_i32_dpp v79, v79, v79 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp5:
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[14:15], s[0:1], s[18:19]
	.loc	1 181 48                        ; benchmark_qwen36_extend_attention_m756.py:181:48
	v_cndmask_b32_e64 v81, 0, 1, s[14:15]
.Ltmp6:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ] ]
	v_max_i32_dpp v79, v79, v79 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp7:
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[20:21], s[10:11], s[20:21]
	s_and_b64 s[0:1], s[0:1], s[20:21]
.Ltmp8:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ] ]
	v_max_i32_dpp v79, v79, v79 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp9:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ]
	v_mov_b32_e32 v83, v79
.Ltmp10:
	.loc	1 181 48                        ; benchmark_qwen36_extend_attention_m756.py:181:48
	v_cndmask_b32_e64 v82, 0, 1, s[0:1]
.Ltmp11:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:27 ]
	NETRA_WAIT_LGKM0
.Ltmp12:
	.loc	2 191 40 is_stmt 0              ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ]
	v_mov_b32_dpp v83, v83 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp13:
	.loc	2 170 27 is_stmt 1              ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ] ]
	v_max_i32_e32 v79, v79, v83
.Ltmp14:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:27 ]
	NETRA_BARRIER
.Ltmp15:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ] ]
	s_nop 0
	v_max_i32_dpp v79, v79, v79 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp16:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ]
	s_nop 0
	v_readlane_b32 s16, v79, 63
.Ltmp17:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ] ]
	v_max_i32_dpp v79, v80, v80 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp18:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ]
	v_mov_b32_e32 v80, v79
	s_nop 1
	v_mov_b32_dpp v80, v80 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp19:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ] ]
	v_max_i32_e32 v79, v79, v80
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp20:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ]
	s_nop 0
	v_readlane_b32 s17, v79, 63
.Ltmp21:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ] ]
	v_max_i32_dpp v79, v81, v81 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp22:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ]
	v_mov_b32_e32 v80, v79
	s_nop 1
	v_mov_b32_dpp v80, v80 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp23:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ] ]
	v_max_i32_e32 v79, v79, v80
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp24:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ]
	s_nop 0
	v_readlane_b32 s18, v79, 63
.Ltmp25:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ] ]
	v_max_i32_dpp v79, v82, v82 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp26:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ]
	v_mov_b32_e32 v80, v79
	s_nop 1
	v_mov_b32_dpp v80, v80 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp27:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ] ]
	v_max_i32_e32 v79, v79, v80
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp28:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:34 ]
	s_nop 0
	v_readlane_b32 s19, v79, 63
.Ltmp29:
	.loc	2 191 40 is_stmt 0              ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:27 ]
	v_mov_b32_e32 v79, s73
	s_nop 0
	v_mov_b64_e32 v[82:83], s[18:19]
	v_mov_b64_e32 v[80:81], s[16:17]
	ds_write_b128 v79, v[80:83]
	ds_write_b128 v79, v[80:83] offset:16
	ds_write_b128 v79, v[80:83] offset:32
	ds_write_b128 v79, v[80:83] offset:48
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b32 v79, v64
.Ltmp30:
	.loc	2 170 27 is_stmt 1              ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:27 ] ]
	NETRA_WAIT_LGKM0
	s_nop 0
	v_max_i32_dpp v79, v79, v79 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp31:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:27 ]
	v_mov_b32_e32 v80, v79
	s_nop 1
	v_mov_b32_dpp v80, v80 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp32:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:27 ] ]
	v_max_i32_e32 v79, v79, v80
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp33:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:181:27 ]
	s_nop 0
	v_readlane_b32 s0, v79, 63
.Ltmp34:
	.loc	1 0 0 is_stmt 0                 ; benchmark_qwen36_extend_attention_m756.py:0
	s_cmp_eq_u32 s0, 0
	.loc	1 182 11 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:182:11
	s_cbranch_scc1 .LBB0_5
; %bb.7:                                ;   in Loop: Header=BB0_6 Depth=1
	.loc	1 176 27                        ; benchmark_qwen36_extend_attention_m756.py:176:27
	v_add_u32_e32 v79, s55, v58
	.loc	1 179 40                        ; benchmark_qwen36_extend_attention_m756.py:179:40
	v_add_u32_e32 v80, 51, v79
	.loc	1 179 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_add_u32_e32 v81, 0x1032, v79
	v_cmp_le_i32_e64 s[0:1], v53, v81
	.loc	1 176 36 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_cmp_gt_i32_e64 s[14:15], s67, v80
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[0:1], s[14:15], s[0:1]
	.loc	1 179 40                        ; benchmark_qwen36_extend_attention_m756.py:179:40
	v_add_u32_e32 v80, 50, v79
	.loc	1 179 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_add_u32_e32 v81, 0x1031, v79
	.loc	1 178 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[14:15], s[48:49], s[0:1]
	.loc	1 179 12                        ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_cmp_le_i32_e64 s[0:1], v53, v81
	.loc	1 176 36                        ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_cmp_gt_i32_e64 s[16:17], s67, v80
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[0:1], s[16:17], s[0:1]
	.loc	1 179 40                        ; benchmark_qwen36_extend_attention_m756.py:179:40
	v_add_u32_e32 v80, 49, v79
	.loc	1 179 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_add_u32_e32 v81, 0x1030, v79
	.loc	1 178 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[16:17], s[48:49], s[0:1]
	.loc	1 179 12                        ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_cmp_le_i32_e64 s[0:1], v53, v81
	.loc	1 176 36                        ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_cmp_gt_i32_e64 s[18:19], s67, v80
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[0:1], s[18:19], s[0:1]
	.loc	1 179 40                        ; benchmark_qwen36_extend_attention_m756.py:179:40
	v_add_u32_e32 v80, 48, v79
	.loc	1 179 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_add_u32_e32 v81, 0x102f, v79
	.loc	1 178 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[18:19], s[48:49], s[0:1]
	.loc	1 179 12                        ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_cmp_le_i32_e64 s[0:1], v53, v81
	.loc	1 176 36                        ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_cmp_gt_i32_e64 s[20:21], s67, v80
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[0:1], s[20:21], s[0:1]
	.loc	1 179 40                        ; benchmark_qwen36_extend_attention_m756.py:179:40
	v_add_u32_e32 v80, 35, v79
	.loc	1 179 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_add_u32_e32 v81, 0x1022, v79
	.loc	1 178 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[20:21], s[48:49], s[0:1]
	.loc	1 179 12                        ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_cmp_le_i32_e64 s[0:1], v53, v81
	.loc	1 176 36                        ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_cmp_gt_i32_e64 s[22:23], s67, v80
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[0:1], s[22:23], s[0:1]
	.loc	1 179 40                        ; benchmark_qwen36_extend_attention_m756.py:179:40
	v_add_u32_e32 v80, 34, v79
	.loc	1 179 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_add_u32_e32 v81, 0x1021, v79
	.loc	1 178 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[22:23], s[48:49], s[0:1]
	.loc	1 179 12                        ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_cmp_le_i32_e64 s[0:1], v53, v81
	.loc	1 176 36                        ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_cmp_gt_i32_e64 s[24:25], s67, v80
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[0:1], s[24:25], s[0:1]
	.loc	1 179 40                        ; benchmark_qwen36_extend_attention_m756.py:179:40
	v_add_u32_e32 v80, 33, v79
	.loc	1 179 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_add_u32_e32 v81, 0x1020, v79
	.loc	1 178 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[24:25], s[48:49], s[0:1]
	.loc	1 179 12                        ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_cmp_le_i32_e64 s[0:1], v53, v81
	.loc	1 176 36                        ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_cmp_gt_i32_e64 s[26:27], s67, v80
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[0:1], s[26:27], s[0:1]
	.loc	1 179 40                        ; benchmark_qwen36_extend_attention_m756.py:179:40
	v_add_u32_e32 v80, 32, v79
	.loc	1 179 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_add_u32_e32 v81, 0x101f, v79
	.loc	1 178 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[26:27], s[48:49], s[0:1]
	.loc	1 179 12                        ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_cmp_le_i32_e64 s[0:1], v53, v81
	.loc	1 176 36                        ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_cmp_gt_i32_e64 s[28:29], s67, v80
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[0:1], s[28:29], s[0:1]
	.loc	1 179 40                        ; benchmark_qwen36_extend_attention_m756.py:179:40
	v_add_u32_e32 v80, 19, v79
	.loc	1 179 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_add_u32_e32 v81, 0x1012, v79
	.loc	1 178 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[28:29], s[48:49], s[0:1]
	.loc	1 179 12                        ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_cmp_le_i32_e64 s[0:1], v53, v81
	.loc	1 176 36                        ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_cmp_gt_i32_e64 s[30:31], s67, v80
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[0:1], s[30:31], s[0:1]
	.loc	1 179 40                        ; benchmark_qwen36_extend_attention_m756.py:179:40
	v_add_u32_e32 v80, 18, v79
	.loc	1 179 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_add_u32_e32 v81, 0x1011, v79
	.loc	1 178 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[30:31], s[48:49], s[0:1]
	.loc	1 179 12                        ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_cmp_le_i32_e64 s[0:1], v53, v81
	.loc	1 176 36                        ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_cmp_gt_i32_e64 s[34:35], s67, v80
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[0:1], s[34:35], s[0:1]
	.loc	1 179 40                        ; benchmark_qwen36_extend_attention_m756.py:179:40
	v_add_u32_e32 v80, 17, v79
	.loc	1 179 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_add_u32_e32 v81, 0x1010, v79
	.loc	1 178 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[34:35], s[48:49], s[0:1]
	.loc	1 179 12                        ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_cmp_le_i32_e64 s[0:1], v53, v81
	.loc	1 176 36                        ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_cmp_gt_i32_e64 s[36:37], s67, v80
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[0:1], s[36:37], s[0:1]
	.loc	1 179 40                        ; benchmark_qwen36_extend_attention_m756.py:179:40
	v_add_u32_e32 v80, 16, v79
	.loc	1 179 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_add_u32_e32 v81, 0x100f, v79
	.loc	1 178 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[36:37], s[48:49], s[0:1]
	.loc	1 179 12                        ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_cmp_le_i32_e64 s[0:1], v53, v81
	.loc	1 176 36                        ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_cmp_gt_i32_e64 s[38:39], s67, v80
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[0:1], s[38:39], s[0:1]
	.loc	1 179 40                        ; benchmark_qwen36_extend_attention_m756.py:179:40
	v_add_u32_e32 v80, 3, v79
	.loc	1 179 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_add_u32_e32 v81, 0x1002, v79
	.loc	1 178 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[38:39], s[48:49], s[0:1]
	.loc	1 179 12                        ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_cmp_le_i32_e64 s[0:1], v53, v81
	.loc	1 176 36                        ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_cmp_gt_i32_e64 s[40:41], s67, v80
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[0:1], s[40:41], s[0:1]
	.loc	1 179 40                        ; benchmark_qwen36_extend_attention_m756.py:179:40
	v_add_u32_e32 v80, 2, v79
	.loc	1 179 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_add_u32_e32 v81, 0x1001, v79
	.loc	1 178 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[40:41], s[48:49], s[0:1]
	.loc	1 179 12                        ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_cmp_le_i32_e64 s[0:1], v53, v81
	.loc	1 176 36                        ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_cmp_gt_i32_e64 s[42:43], s67, v80
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[0:1], s[42:43], s[0:1]
	.loc	1 179 40                        ; benchmark_qwen36_extend_attention_m756.py:179:40
	v_add_u32_e32 v80, 1, v79
	.loc	1 179 12 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_add_u32_e32 v81, 0x1000, v79
	.loc	1 178 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[42:43], s[48:49], s[0:1]
	.loc	1 179 12                        ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_cmp_le_i32_e64 s[0:1], v53, v81
	.loc	1 176 36                        ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_cmp_gt_i32_e64 s[44:45], s67, v80
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[0:1], s[44:45], s[0:1]
	.loc	1 179 12                        ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_add_u32_e32 v80, 0xfff, v79
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[44:45], s[48:49], s[0:1]
	.loc	1 179 12                        ; benchmark_qwen36_extend_attention_m756.py:179:12
	v_cmp_le_i32_e64 s[0:1], v53, v80
	.loc	1 176 36                        ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_cmp_gt_i32_e64 s[46:47], s67, v79
	v_add_u32_e32 v79, s55, v62
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[0:1], s[46:47], s[0:1]
	.loc	1 176 36                        ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_add_u32_e32 v80, 32, v79
	v_cmp_gt_i32_e64 s[50:51], s67, v79
	.loc	1 184 16                        ; benchmark_qwen36_extend_attention_m756.py:184:16
	v_add_u32_e32 v79, s72, v63
	.loc	1 178 22                        ; benchmark_qwen36_extend_attention_m756.py:178:22
	s_and_b64 s[46:47], s[48:49], s[0:1]
	.loc	1 176 36                        ; benchmark_qwen36_extend_attention_m756.py:176:36
	v_cmp_gt_i32_e64 s[0:1], s67, v80
	.loc	1 184 16                        ; benchmark_qwen36_extend_attention_m756.py:184:16
	v_cndmask_b32_e64 v80, v74, v79, s[50:51]
	v_add_u32_e32 v79, 0x100, v79
	buffer_load_dwordx2 v[80:81], v80, s[60:63], 0 offen
	v_cndmask_b32_e64 v79, v74, v79, s[0:1]
	buffer_load_dwordx2 v[82:83], v79, s[60:63], 0 offen
	.loc	1 194 16                        ; benchmark_qwen36_extend_attention_m756.py:194:16
	s_mov_b32 s58, s62
	s_mov_b32 s59, s63
	.loc	1 194 27 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:194:27
	s_waitcnt vmcnt(1)
	v_lshl_add_u32 v79, v80, 10, v59
	.loc	1 194 16                        ; benchmark_qwen36_extend_attention_m756.py:194:16
	v_cndmask_b32_e64 v79, v74, v79, s[50:51]
	.loc	1 194 27                        ; benchmark_qwen36_extend_attention_m756.py:194:27
	NETRA_WAIT_VM0
	v_lshl_add_u32 v80, v82, 10, v59
	.loc	1 194 16                        ; benchmark_qwen36_extend_attention_m756.py:194:16
	buffer_load_dwordx4 v[82:85], v79, s[56:59], 0 offen
	v_cndmask_b32_e64 v80, v74, v80, s[0:1]
	buffer_load_dwordx4 v[86:89], v80, s[56:59], 0 offen
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	s_waitcnt vmcnt(1)
	ds_write_b128 v65, v[82:85]
	NETRA_WAIT_VM0
	ds_write_b128 v65, v[86:89] offset:4096
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b128 v[82:85], v66
	ds_read_b128 v[90:93], v66 offset:2048
	ds_read_b128 v[114:117], v66 offset:4096
	ds_read_b128 v[122:125], v66 offset:6144
	ds_read_b128 v[86:89], v67
	ds_read_b128 v[94:97], v67 offset:2048
	ds_read_b128 v[118:121], v67 offset:4096
	ds_read_b128 v[126:129], v67 offset:6144
	.loc	1 198 39 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:198:39
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x128_f8f6f4 v[82:85], v[82:89], v[2:9], 0
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[86:89], v[90:97], v[2:9], 0
	.loc	1 198 66 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:198:66
	s_nop 9
	v_mul_f32_e32 v81, s33, v82
	v_mul_f32_e32 v82, s33, v83
	v_mul_f32_e32 v83, s33, v84
	v_mul_f32_e32 v84, s33, v85
	.loc	1 199 42 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:199:42
	v_cndmask_b32_e64 v85, v75, v81, s[46:47]
	.loc	1 198 39                        ; benchmark_qwen36_extend_attention_m756.py:198:39
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x128_f8f6f4 v[90:93], v[114:121], v[2:9], 0
	.loc	1 198 66 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:198:66
	v_mul_f32_e32 v114, s33, v86
	.loc	1 199 42 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:199:42
	v_cndmask_b32_e64 v86, v75, v82, s[44:45]
	.loc	1 198 66                        ; benchmark_qwen36_extend_attention_m756.py:198:66
	v_mul_f32_e32 v115, s33, v87
	v_mul_f32_e32 v116, s33, v88
	.loc	1 199 42                        ; benchmark_qwen36_extend_attention_m756.py:199:42
	v_cndmask_b32_e64 v87, v75, v83, s[42:43]
	v_cndmask_b32_e64 v88, v75, v84, s[40:41]
.Ltmp35:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:200:29 ] ]
	v_max_f32_e32 v81, v85, v86
.Ltmp36:
	.loc	1 198 39                        ; benchmark_qwen36_extend_attention_m756.py:198:39
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x128_f8f6f4 v[94:97], v[122:129], v[2:9], 0
	.loc	1 198 66 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:198:66
	v_mul_f32_e32 v117, s33, v89
	s_nop 1
	v_mul_f32_e32 v118, s33, v90
	.loc	1 199 42 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:199:42
	v_cndmask_b32_e64 v89, v75, v114, s[38:39]
	v_cndmask_b32_e64 v90, v75, v115, s[36:37]
.Ltmp37:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:200:29 ] ]
	v_max3_f32 v81, v81, v87, v88
.Ltmp38:
	.loc	1 198 66                        ; benchmark_qwen36_extend_attention_m756.py:198:66
	v_mul_f32_e32 v119, s33, v91
	v_mul_f32_e32 v120, s33, v92
	.loc	1 199 42                        ; benchmark_qwen36_extend_attention_m756.py:199:42
	v_cndmask_b32_e64 v91, v75, v116, s[34:35]
	v_cndmask_b32_e64 v92, v75, v117, s[30:31]
.Ltmp39:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:200:29 ] ]
	v_max3_f32 v81, v81, v89, v90
.Ltmp40:
	.loc	1 198 66                        ; benchmark_qwen36_extend_attention_m756.py:198:66
	v_mul_f32_e32 v121, s33, v93
	v_mul_f32_e32 v122, s33, v94
	.loc	1 199 42                        ; benchmark_qwen36_extend_attention_m756.py:199:42
	v_cndmask_b32_e64 v93, v75, v118, s[28:29]
	v_cndmask_b32_e64 v94, v75, v119, s[26:27]
.Ltmp41:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:200:29 ] ]
	v_max3_f32 v81, v81, v91, v92
.Ltmp42:
	.loc	1 198 66                        ; benchmark_qwen36_extend_attention_m756.py:198:66
	v_mul_f32_e32 v123, s33, v95
	v_mul_f32_e32 v124, s33, v96
	.loc	1 199 42                        ; benchmark_qwen36_extend_attention_m756.py:199:42
	v_cndmask_b32_e64 v95, v75, v120, s[24:25]
	v_cndmask_b32_e64 v96, v75, v121, s[22:23]
.Ltmp43:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:200:29 ] ]
	v_max3_f32 v81, v81, v93, v94
.Ltmp44:
	.loc	1 198 66                        ; benchmark_qwen36_extend_attention_m756.py:198:66
	v_mul_f32_e32 v125, s33, v97
	.loc	1 199 42                        ; benchmark_qwen36_extend_attention_m756.py:199:42
	v_cndmask_b32_e64 v97, v75, v122, s[20:21]
	v_cndmask_b32_e64 v83, v75, v123, s[18:19]
.Ltmp45:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:200:29 ] ]
	v_max3_f32 v81, v81, v95, v96
.Ltmp46:
	.loc	1 199 42                        ; benchmark_qwen36_extend_attention_m756.py:199:42
	v_cndmask_b32_e64 v84, v75, v124, s[16:17]
	v_cndmask_b32_e64 v82, v75, v125, s[14:15]
.Ltmp47:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:200:29 ] ]
	v_max3_f32 v81, v81, v97, v83
	v_max3_f32 v81, v81, v84, v82
.Ltmp48:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:200:29 ]
	v_mov_b32_e32 v114, v81
	s_nop 1
	v_permlane32_swap_b32_e32 v81, v114
.Ltmp49:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:200:29 ] ]
	v_max_f32_e32 v114, v114, v114
	v_max_f32_e32 v81, v81, v81
	v_max_f32_e32 v81, v81, v114
.Ltmp50:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:200:29 ]
	v_mov_b32_e32 v114, v81
	s_nop 1
	v_permlane16_swap_b32_e32 v81, v114
.Ltmp51:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:200:29 ] ]
	v_max_f32_e32 v114, v114, v114
	v_max_f32_e32 v81, v81, v81
	v_max_f32_e32 v81, v81, v114
.Ltmp52:
	.loc	1 201 66                        ; benchmark_qwen36_extend_attention_m756.py:201:66
	v_cmp_neq_f32_e64 s[0:1], s74, v81
	.loc	1 202 43                        ; benchmark_qwen36_extend_attention_m756.py:202:43
	v_max_f32_e32 v114, v60, v60
	.loc	1 213 16                        ; benchmark_qwen36_extend_attention_m756.py:213:16
	s_mov_b32 s14, s62
	.loc	1 201 66                        ; benchmark_qwen36_extend_attention_m756.py:201:66
	v_cndmask_b32_e64 v81, v76, v81, s[0:1]
	.loc	1 202 43                        ; benchmark_qwen36_extend_attention_m756.py:202:43
	v_max_f32_e32 v81, v81, v114
	.loc	1 203 37                        ; benchmark_qwen36_extend_attention_m756.py:203:37
	v_sub_f32_e32 v60, v60, v81
	.loc	1 203 29 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:203:29
	v_mul_f32_e32 v114, 0x3fb8aa3b, v60
	v_cmp_gt_f32_e64 s[0:1], s75, v114
	.loc	1 204 40 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:204:40
	v_sub_f32_e32 v85, v85, v81
	v_sub_f32_e32 v86, v86, v81
	.loc	1 203 29                        ; benchmark_qwen36_extend_attention_m756.py:203:29
	v_cndmask_b32_e64 v114, 0, v77, s[0:1]
	v_fmac_f32_e32 v114, 0x3fb8aa3b, v60
	v_exp_f32_e32 v60, v114
	v_cndmask_b32_e64 v114, 0, v78, s[0:1]
	.loc	1 204 40                        ; benchmark_qwen36_extend_attention_m756.py:204:40
	v_sub_f32_e32 v87, v87, v81
	v_sub_f32_e32 v88, v88, v81
	.loc	1 203 29                        ; benchmark_qwen36_extend_attention_m756.py:203:29
	v_ldexp_f32 v60, v60, v114
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	v_mul_f32_e32 v114, 0x3fb8aa3b, v85
	v_cmp_gt_f32_e64 s[0:1], s75, v114
	.loc	1 204 40 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:204:40
	v_sub_f32_e32 v89, v89, v81
	v_sub_f32_e32 v90, v90, v81
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	v_cndmask_b32_e64 v114, 0, v77, s[0:1]
	v_fmac_f32_e32 v114, 0x3fb8aa3b, v85
	v_exp_f32_e32 v85, v114
	v_cndmask_b32_e64 v114, 0, v78, s[0:1]
	.loc	1 204 40                        ; benchmark_qwen36_extend_attention_m756.py:204:40
	v_sub_f32_e32 v91, v91, v81
	v_sub_f32_e32 v92, v92, v81
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	v_ldexp_f32 v114, v85, v114
	v_mul_f32_e32 v85, 0x3fb8aa3b, v86
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	.loc	1 204 40                        ; benchmark_qwen36_extend_attention_m756.py:204:40
	v_sub_f32_e32 v93, v93, v81
	v_sub_f32_e32 v94, v94, v81
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v86
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	.loc	1 204 40                        ; benchmark_qwen36_extend_attention_m756.py:204:40
	v_sub_f32_e32 v95, v95, v81
	v_sub_f32_e32 v96, v96, v81
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	v_ldexp_f32 v115, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v87
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	.loc	1 204 40                        ; benchmark_qwen36_extend_attention_m756.py:204:40
	v_sub_f32_e32 v97, v97, v81
	v_sub_f32_e32 v83, v83, v81
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v87
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	.loc	1 204 40                        ; benchmark_qwen36_extend_attention_m756.py:204:40
	v_sub_f32_e32 v84, v84, v81
	v_sub_f32_e32 v82, v82, v81
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	v_ldexp_f32 v116, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v88
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	.loc	1 213 16 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:213:16
	s_mov_b32 s15, s63
	.loc	1 218 43                        ; benchmark_qwen36_extend_attention_m756.py:218:43
	v_pk_mul_f32 v[40:41], v[40:41], v[60:61] op_sel_hi:[1,0]
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v88
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	.loc	1 218 43                        ; benchmark_qwen36_extend_attention_m756.py:218:43
	v_pk_mul_f32 v[38:39], v[38:39], v[60:61] op_sel_hi:[1,0]
	v_pk_mul_f32 v[36:37], v[36:37], v[60:61] op_sel_hi:[1,0]
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	v_ldexp_f32 v117, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v89
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	.loc	1 218 43                        ; benchmark_qwen36_extend_attention_m756.py:218:43
	v_pk_mul_f32 v[34:35], v[34:35], v[60:61] op_sel_hi:[1,0]
	v_pk_mul_f32 v[32:33], v[32:33], v[60:61] op_sel_hi:[1,0]
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v89
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	.loc	1 218 43                        ; benchmark_qwen36_extend_attention_m756.py:218:43
	v_pk_mul_f32 v[30:31], v[30:31], v[60:61] op_sel_hi:[1,0]
	v_pk_mul_f32 v[28:29], v[28:29], v[60:61] op_sel_hi:[1,0]
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	v_ldexp_f32 v118, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v90
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	.loc	1 218 43                        ; benchmark_qwen36_extend_attention_m756.py:218:43
	v_pk_mul_f32 v[26:27], v[26:27], v[60:61] op_sel_hi:[1,0]
	v_pk_mul_f32 v[24:25], v[24:25], v[60:61] op_sel_hi:[1,0]
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v90
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	.loc	1 218 43                        ; benchmark_qwen36_extend_attention_m756.py:218:43
	v_pk_mul_f32 v[22:23], v[22:23], v[60:61] op_sel_hi:[1,0]
	v_pk_mul_f32 v[20:21], v[20:21], v[60:61] op_sel_hi:[1,0]
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	v_ldexp_f32 v119, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v91
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	.loc	1 218 43                        ; benchmark_qwen36_extend_attention_m756.py:218:43
	v_pk_mul_f32 v[18:19], v[18:19], v[60:61] op_sel_hi:[1,0]
	v_pk_mul_f32 v[16:17], v[16:17], v[60:61] op_sel_hi:[1,0]
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v91
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	.loc	1 218 43                        ; benchmark_qwen36_extend_attention_m756.py:218:43
	v_pk_mul_f32 v[14:15], v[14:15], v[60:61] op_sel_hi:[1,0]
	v_pk_mul_f32 v[12:13], v[12:13], v[60:61] op_sel_hi:[1,0]
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	v_ldexp_f32 v120, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v92
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	.loc	1 218 43                        ; benchmark_qwen36_extend_attention_m756.py:218:43
	v_pk_mul_f32 v[10:11], v[10:11], v[60:61] op_sel_hi:[1,0]
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	s_nop 0
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v92
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	.loc	1 218 33                        ; benchmark_qwen36_extend_attention_m756.py:218:33
	v_cvt_scalef32_pk_fp8_f32 v92, v114, v115, 1.0
	v_cvt_scalef32_pk_fp8_f32 v92, v116, v117, 1.0 op_sel:[0,0,0,1]
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	v_ldexp_f32 v121, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v93
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	s_nop 1
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v93
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	.loc	1 218 33                        ; benchmark_qwen36_extend_attention_m756.py:218:33
	v_cvt_scalef32_pk_fp8_f32 v93, v118, v119, 1.0
	v_cvt_scalef32_pk_fp8_f32 v93, v120, v121, 1.0 op_sel:[0,0,0,1]
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	v_ldexp_f32 v122, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v94
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	.loc	1 218 33                        ; benchmark_qwen36_extend_attention_m756.py:218:33
	v_permlane32_swap_b32_e32 v92, v93
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	s_nop 0
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v94
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	.loc	1 218 33                        ; benchmark_qwen36_extend_attention_m756.py:218:33
	v_permlane16_swap_b32_e32 v92, v93
	.loc	1 204 35                        ; benchmark_qwen36_extend_attention_m756.py:204:35
	v_ldexp_f32 v94, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v95
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	s_nop 1
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v95
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	v_ldexp_f32 v95, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v96
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	s_nop 1
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v96
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	v_ldexp_f32 v96, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v97
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	s_nop 1
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v97
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	v_ldexp_f32 v97, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v83
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	s_nop 1
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v83
	v_exp_f32_e32 v83, v85
	v_cndmask_b32_e64 v85, 0, v78, s[0:1]
	v_ldexp_f32 v83, v83, v85
	v_mul_f32_e32 v85, 0x3fb8aa3b, v84
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	s_nop 1
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v84
	v_exp_f32_e32 v84, v85
	v_cndmask_b32_e64 v85, 0, v78, s[0:1]
	v_ldexp_f32 v123, v84, v85
	v_mul_f32_e32 v84, 0x3fb8aa3b, v82
	v_cmp_gt_f32_e64 s[0:1], s75, v84
	s_nop 1
	v_cndmask_b32_e64 v84, 0, v77, s[0:1]
	v_fmac_f32_e32 v84, 0x3fb8aa3b, v82
	v_exp_f32_e32 v82, v84
	v_cndmask_b32_e64 v84, 0, v78, s[0:1]
	v_ldexp_f32 v124, v82, v84
.Ltmp53:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:205:43 ] ]
	v_add_f32_e32 v82, v114, v115
	v_add_f32_e32 v82, v116, v82
	v_add_f32_e32 v82, v117, v82
	v_add_f32_e32 v82, v118, v82
	v_add_f32_e32 v82, v119, v82
	v_add_f32_e32 v82, v120, v82
	v_add_f32_e32 v82, v121, v82
	v_add_f32_e32 v82, v122, v82
	v_add_f32_e32 v82, v94, v82
	v_add_f32_e32 v82, v95, v82
	v_add_f32_e32 v82, v96, v82
	v_add_f32_e32 v82, v97, v82
	v_add_f32_e32 v82, v83, v82
	v_add_f32_e32 v82, v123, v82
	v_add_f32_e32 v82, v124, v82
.Ltmp54:
	.loc	2 293 36                        ; standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:205:43 ]
	v_mov_b32_e32 v84, v82
	s_nop 1
	v_permlane32_swap_b32_e32 v82, v84
.Ltmp55:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:205:43 ] ]
	v_add_f32_e32 v82, v82, v84
.Ltmp56:
	.loc	2 293 36                        ; standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:205:43 ]
	v_mov_b32_e32 v84, v82
	s_nop 1
	v_permlane16_swap_b32_e32 v82, v84
.Ltmp57:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:205:43 ] ]
	v_add_f32_e32 v82, v82, v84
.Ltmp58:
	.loc	1 213 16                        ; benchmark_qwen36_extend_attention_m756.py:213:16
	buffer_load_dwordx4 v[84:87], v79, s[12:15], 0 offen
	buffer_load_dwordx4 v[88:91], v80, s[12:15], 0 offen
	.loc	1 218 33                        ; benchmark_qwen36_extend_attention_m756.py:218:33
	v_cvt_scalef32_pk_fp8_f32 v94, v122, v94, 1.0
	v_cvt_scalef32_pk_fp8_f32 v94, v95, v96, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v95, v97, v83, 1.0
	v_cvt_scalef32_pk_fp8_f32 v95, v123, v124, 1.0 op_sel:[0,0,0,1]
	.loc	1 213 16                        ; benchmark_qwen36_extend_attention_m756.py:213:16
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	NETRA_WAIT_VM0
	ds_write2st64_b64 v68, v[84:85], v[88:89] offset1:8
	ds_write2st64_b64 v69, v[86:87], v[90:91] offset1:8
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b64_tr_b8 v[84:85], v70
	ds_read_b64_tr_b8 v[86:87], v70 offset:4096
	ds_read_b64_tr_b8 v[88:89], v70 offset:64
	ds_read_b64_tr_b8 v[90:91], v70 offset:4160
	ds_read_b64_tr_b8 v[96:97], v71
	ds_read_b64_tr_b8 v[114:115], v71 offset:4096
	ds_read_b64_tr_b8 v[116:117], v71 offset:64
	ds_read_b64_tr_b8 v[118:119], v71 offset:4160
	ds_read_b64_tr_b8 v[120:121], v72
	ds_read_b64_tr_b8 v[122:123], v72 offset:4096
	ds_read_b64_tr_b8 v[124:125], v72 offset:64
	ds_read_b64_tr_b8 v[126:127], v72 offset:4160
	ds_read_b64_tr_b8 v[128:129], v73
	ds_read_b64_tr_b8 v[130:131], v73 offset:4096
	ds_read_b64_tr_b8 v[132:133], v73 offset:64
	ds_read_b64_tr_b8 v[134:135], v73 offset:4160
	.loc	1 218 43                        ; benchmark_qwen36_extend_attention_m756.py:218:43
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_fp8_fp8 v[38:41], v[84:85], v[92:93], v[38:41]
	.loc	1 218 33 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:218:33
	v_permlane32_swap_b32_e32 v94, v95
	s_nop 1
	v_permlane16_swap_b32_e32 v94, v95
	.loc	1 218 43                        ; benchmark_qwen36_extend_attention_m756.py:218:43
	s_waitcnt lgkmcnt(11)
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[96:97], v[92:93], v[34:37]
	.loc	1 205 36 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:205:36
	v_fmac_f32_e32 v82, v61, v60
	v_mov_b32_e32 v61, v82
	v_mov_b32_e32 v60, v81
	.loc	1 218 43                        ; benchmark_qwen36_extend_attention_m756.py:218:43
	s_waitcnt lgkmcnt(7)
	v_mfma_f32_16x16x32_fp8_fp8 v[30:33], v[120:121], v[92:93], v[30:33]
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_fp8_fp8 v[26:29], v[128:129], v[92:93], v[26:29]
	v_mfma_f32_16x16x32_fp8_fp8 v[22:25], v[88:89], v[92:93], v[22:25]
	v_mfma_f32_16x16x32_fp8_fp8 v[18:21], v[116:117], v[92:93], v[18:21]
	v_mfma_f32_16x16x32_fp8_fp8 v[14:17], v[124:125], v[92:93], v[14:17]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_fp8_fp8 v[10:13], v[132:133], v[92:93], v[10:13]
	v_mfma_f32_16x16x32_fp8_fp8 v[38:41], v[86:87], v[94:95], v[38:41]
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[114:115], v[94:95], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[30:33], v[122:123], v[94:95], v[30:33]
	v_mfma_f32_16x16x32_fp8_fp8 v[26:29], v[130:131], v[94:95], v[26:29]
	v_mfma_f32_16x16x32_fp8_fp8 v[22:25], v[90:91], v[94:95], v[22:25]
	v_mfma_f32_16x16x32_fp8_fp8 v[18:21], v[118:119], v[94:95], v[18:21]
	v_mfma_f32_16x16x32_fp8_fp8 v[14:17], v[126:127], v[94:95], v[14:17]
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_fp8_fp8 v[10:13], v[134:135], v[94:95], v[10:13]
	s_branch .LBB0_5
.LBB0_8:
	.loc	1 0 43 is_stmt 0                ; benchmark_qwen36_extend_attention_m756.py:0:43
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
	v_mov_b32_e32 v35, 0
	v_mov_b32_e32 v34, 0
	v_mov_b32_e32 v37, 0
	v_mov_b32_e32 v36, 0
	v_mov_b32_e32 v39, 0
	v_mov_b32_e32 v38, 0
	v_mov_b32_e32 v41, 0
	v_mov_b32_e32 v40, 0
	v_mov_b32_e32 v60, 0xff800000
	v_mov_b32_e32 v61, 0
.LBB0_9:                                ; %._crit_edge
	.loc	1 230 27 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:230:27
	v_lshlrev_b32_e32 v2, 10, v42
	.loc	1 222 22                        ; benchmark_qwen36_extend_attention_m756.py:222:22
	v_mov_b32_e32 v59, 0
	.loc	1 230 27                        ; benchmark_qwen36_extend_attention_m756.py:230:27
	v_add_u32_e32 v2, s66, v2
	.loc	1 222 22                        ; benchmark_qwen36_extend_attention_m756.py:222:22
	v_mov_b32_e32 v53, v59
	.loc	1 230 27                        ; benchmark_qwen36_extend_attention_m756.py:230:27
	v_lshlrev_b32_e32 v3, 10, v52
	v_or_b32_e32 v5, v2, v54
	v_or_b32_e32 v2, v2, v56
	.loc	1 222 22                        ; benchmark_qwen36_extend_attention_m756.py:222:22
	v_mov_b32_e32 v51, v59
	.loc	1 230 27                        ; benchmark_qwen36_extend_attention_m756.py:230:27
	v_lshlrev_b32_e32 v4, 10, v50
	.loc	1 230 16 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:230:16
	v_add_lshl_u32 v6, v5, v3, 1
	v_bfrev_b32_e32 v9, 1
	.loc	1 222 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:222:22
	v_cmp_gt_i64_e32 vcc, v[46:47], v[52:53]
	.loc	1 230 16                        ; benchmark_qwen36_extend_attention_m756.py:230:16
	v_add_lshl_u32 v3, v2, v3, 1
	s_and_b32 s5, s5, 0xffff
	s_mov_b32 s7, 0x27000
	s_mov_b32 s6, 0x7ffffffe
	v_cndmask_b32_e32 v8, v9, v6, vcc
	v_cndmask_b32_e32 v54, v9, v3, vcc
	v_add_lshl_u32 v3, v5, v4, 1
	.loc	1 222 22                        ; benchmark_qwen36_extend_attention_m756.py:222:22
	v_cmp_gt_i64_e32 vcc, v[46:47], v[50:51]
	.loc	1 230 16                        ; benchmark_qwen36_extend_attention_m756.py:230:16
	buffer_load_dwordx4 v[68:71], v8, s[4:7], 0 offen
	buffer_load_dwordx4 v[72:75], v54, s[4:7], 0 offen
	v_cndmask_b32_e32 v56, v9, v3, vcc
	buffer_load_dwordx4 v[76:79], v56, s[4:7], 0 offen
	v_add_lshl_u32 v2, v2, v4, 1
	v_cndmask_b32_e32 v66, v9, v2, vcc
	buffer_load_dwordx4 v[80:83], v66, s[4:7], 0 offen
	.loc	1 165 29                        ; benchmark_qwen36_extend_attention_m756.py:165:29
	s_or_b32 s2, s54, s64
	.loc	1 168 16                        ; benchmark_qwen36_extend_attention_m756.py:168:16
	v_and_b32_e32 v50, 0x78, v55
	v_lshlrev_b32_e32 v51, 4, v44
	.loc	1 156 31                        ; benchmark_qwen36_extend_attention_m756.py:156:31
	v_or_b32_e32 v2, 1, v58
	v_or_b32_e32 v4, 2, v58
	v_or_b32_e32 v6, 3, v58
	.loc	1 224 41                        ; benchmark_qwen36_extend_attention_m756.py:224:41
	v_cmp_ge_u32_e64 s[0:1], v44, v58
	v_cmp_gt_u32_e32 vcc, v44, v58
	.loc	1 165 55                        ; benchmark_qwen36_extend_attention_m756.py:165:55
	s_lshl_b32 s18, s2, 7
	.loc	1 222 22                        ; benchmark_qwen36_extend_attention_m756.py:222:22
	v_cmp_gt_i64_e64 s[2:3], v[46:47], v[58:59]
	.loc	1 168 16                        ; benchmark_qwen36_extend_attention_m756.py:168:16
	v_lshlrev_b32_e32 v50, 1, v50
	v_bitop3_b32 v58, v51, v57, v1 bitop3:0xde
	s_movk_i32 s10, 0x80
	v_mov_b32_e32 v52, s65
	s_movk_i32 s11, 0xc0
	.loc	1 230 16                        ; benchmark_qwen36_extend_attention_m756.py:230:16
	v_bitop3_b32 v51, v57, v1, v51 bitop3:0x36
	.loc	1 168 16                        ; benchmark_qwen36_extend_attention_m756.py:168:16
	v_xor_b32_e32 v1, v50, v49
	v_or_b32_e32 v50, s65, v58
	.loc	1 222 22                        ; benchmark_qwen36_extend_attention_m756.py:222:22
	v_mov_b32_e32 v3, v59
	v_mov_b32_e32 v5, v59
	v_mov_b32_e32 v7, v59
	.loc	1 168 16                        ; benchmark_qwen36_extend_attention_m756.py:168:16
	v_bitop3_b32 v57, v58, s10, v52 bitop3:0x36
	v_bitop3_b32 v52, v58, s11, v52 bitop3:0x36
	.loc	1 230 16                        ; benchmark_qwen36_extend_attention_m756.py:230:16
	v_add_u32_e32 v58, 0, v51
	.loc	1 168 16                        ; benchmark_qwen36_extend_attention_m756.py:168:16
	v_add_u32_e32 v59, 0, v1
	v_add_u32_e32 v62, 0, v50
	v_xad_u32 v1, v1, 16, 0
	v_xad_u32 v50, v50, 64, 0
	v_add_u32_e32 v57, 0, v57
	v_add_u32_e32 v52, 0, v52
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_write_b128 v59, v[102:105]
	ds_write_b128 v59, v[110:113] offset:8192
	ds_write_b128 v1, v[98:101]
	ds_write_b128 v1, v[106:109] offset:8192
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b128 v[62:65], v62
	ds_read_b128 v[84:87], v50
	ds_read_b128 v[88:91], v57
	ds_read_b128 v[92:95], v52
	.loc	1 230 16                        ; benchmark_qwen36_extend_attention_m756.py:230:16
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	.loc	1 166 17                        ; benchmark_qwen36_extend_attention_m756.py:166:17
	v_and_b32_e32 v42, 16, v0
	v_lshrrev_b32_e32 v0, 2, v0
	v_and_b32_e32 v0, 8, v0
	v_or3_b32 v42, v0, v42, v48
	.loc	1 230 16                        ; benchmark_qwen36_extend_attention_m756.py:230:16
	v_xad_u32 v0, v51, 64, 0
	.loc	1 222 22                        ; benchmark_qwen36_extend_attention_m756.py:222:22
	v_cmp_gt_i64_e64 s[12:13], v[46:47], v[2:3]
	.loc	1 230 16                        ; benchmark_qwen36_extend_attention_m756.py:230:16
	v_xor_b32_e32 v48, 0xc0, v51
	v_add_u32_e32 v48, 0, v48
	.loc	1 224 18                        ; benchmark_qwen36_extend_attention_m756.py:224:18
	s_and_b64 s[0:1], s[0:1], s[2:3]
	.loc	1 232 34                        ; benchmark_qwen36_extend_attention_m756.py:232:34
	v_mov_b32_e32 v53, 0xff800000
	.loc	1 224 41                        ; benchmark_qwen36_extend_attention_m756.py:224:41
	v_cmp_ge_u32_e64 s[4:5], v44, v4
	.loc	1 222 22                        ; benchmark_qwen36_extend_attention_m756.py:222:22
	v_cmp_gt_i64_e64 s[14:15], v[46:47], v[4:5]
	.loc	1 224 18                        ; benchmark_qwen36_extend_attention_m756.py:224:18
	s_and_b64 s[2:3], vcc, s[12:13]
	s_and_b64 vcc, s[48:49], s[0:1]
	.loc	1 224 41 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:224:41
	v_cmp_ge_u32_e64 s[10:11], v44, v6
	.loc	1 222 22 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:222:22
	v_cmp_gt_i64_e64 s[16:17], v[46:47], v[6:7]
	.loc	1 224 18                        ; benchmark_qwen36_extend_attention_m756.py:224:18
	s_and_b64 s[4:5], s[4:5], s[14:15]
	s_and_b64 s[10:11], s[10:11], s[16:17]
	s_mov_b32 s19, 0xff800000
	.loc	1 245 16                        ; benchmark_qwen36_extend_attention_m756.py:245:16
	s_and_b32 s53, s53, 0xffff
	s_mov_b32 s54, s6
	.loc	1 230 16                        ; benchmark_qwen36_extend_attention_m756.py:230:16
	s_waitcnt vmcnt(3)
	ds_write_b128 v59, v[68:71]
	s_waitcnt vmcnt(1)
	ds_write_b128 v59, v[76:79] offset:8192
	ds_write_b128 v1, v[72:75]
	NETRA_WAIT_VM0
	ds_write_b128 v1, v[80:83] offset:8192
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b128 v[68:71], v58
	ds_read_b128 v[72:75], v0
	v_xor_b32_e32 v0, 0x80, v51
	v_add_u32_e32 v0, 0, v0
	ds_read_b128 v[76:79], v0
	.loc	1 231 19                        ; benchmark_qwen36_extend_attention_m756.py:231:19
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[0:3], v[68:71], v[62:65], 0
	.loc	1 230 16                        ; benchmark_qwen36_extend_attention_m756.py:230:16
	ds_read_b128 v[62:65], v48
	.loc	1 245 16                        ; benchmark_qwen36_extend_attention_m756.py:245:16
	s_mov_b32 s55, s7
	.loc	1 236 21                        ; benchmark_qwen36_extend_attention_m756.py:236:21
	v_mov_b32_e32 v48, 0x42800000
	.loc	1 231 19                        ; benchmark_qwen36_extend_attention_m756.py:231:19
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[0:3], v[72:75], v[84:87], v[0:3]
	.loc	1 257 8                         ; benchmark_qwen36_extend_attention_m756.py:257:8
	s_and_b32 s9, s9, 0xffff
	.loc	1 231 19                        ; benchmark_qwen36_extend_attention_m756.py:231:19
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[0:3], v[76:79], v[88:91], v[0:3]
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[0:3], v[62:65], v[92:95], v[0:3]
	.loc	1 231 46 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:231:46
	s_nop 7
	v_mul_f32_e32 v0, s33, v0
	v_mul_f32_e32 v1, s33, v1
	.loc	1 232 34 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:232:34
	v_cndmask_b32_e32 v0, v53, v0, vcc
	.loc	1 224 18                        ; benchmark_qwen36_extend_attention_m756.py:224:18
	s_and_b64 vcc, s[48:49], s[2:3]
	.loc	1 231 46                        ; benchmark_qwen36_extend_attention_m756.py:231:46
	v_mul_f32_e32 v2, s33, v2
	.loc	1 232 34                        ; benchmark_qwen36_extend_attention_m756.py:232:34
	v_cndmask_b32_e32 v1, v53, v1, vcc
	.loc	1 224 18                        ; benchmark_qwen36_extend_attention_m756.py:224:18
	s_and_b64 vcc, s[48:49], s[4:5]
	.loc	1 231 46                        ; benchmark_qwen36_extend_attention_m756.py:231:46
	v_mul_f32_e32 v3, s33, v3
	.loc	1 232 34                        ; benchmark_qwen36_extend_attention_m756.py:232:34
	v_cndmask_b32_e32 v2, v53, v2, vcc
	.loc	1 224 18                        ; benchmark_qwen36_extend_attention_m756.py:224:18
	s_and_b64 vcc, s[48:49], s[10:11]
	.loc	1 232 34                        ; benchmark_qwen36_extend_attention_m756.py:232:34
	v_cndmask_b32_e32 v3, v53, v3, vcc
.Ltmp59:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:233:21 ] ]
	v_max3_f32 v4, v0, v1, v2
	v_max3_f32 v4, v4, v3, s19
.Ltmp60:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:233:21 ]
	v_mov_b32_e32 v5, v4
	s_nop 1
	v_permlane32_swap_b32_e32 v4, v5
.Ltmp61:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:233:21 ] ]
	v_max_f32_e32 v46, v5, v5
	v_max_f32_e32 v47, v4, v4
.Ltmp62:
	.loc	1 245 16                        ; benchmark_qwen36_extend_attention_m756.py:245:16
	buffer_load_dwordx4 v[4:7], v8, s[52:55], 0 offen
	buffer_load_dwordx4 v[50:53], v56, s[52:55], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[56:59], v54, s[52:55], 0 offen
	buffer_load_dwordx4 v[62:65], v66, s[52:55], 0 offen
.Ltmp63:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:233:21 ] ]
	v_max_f32_e32 v8, v47, v46
.Ltmp64:
	.loc	2 191 40                        ; standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:233:21 ]
	v_mov_b32_e32 v46, v8
	s_nop 1
	v_permlane16_swap_b32_e32 v8, v46
.Ltmp65:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ benchmark_qwen36_extend_attention_m756.py:233:21 ] ]
	v_max_f32_e32 v46, v46, v46
	v_max_f32_e32 v8, v8, v8
	v_max_f32_e32 v8, v8, v46
.Ltmp66:
	.loc	1 234 58                        ; benchmark_qwen36_extend_attention_m756.py:234:58
	v_mov_b32_e32 v46, 0xe0ad78ec
	v_cmp_neq_f32_e32 vcc, s19, v8
	s_mov_b32 s2, 0xc2fc0000
	s_movk_i32 s3, 0x78
	v_cndmask_b32_e32 v8, v46, v8, vcc
	.loc	1 235 35                        ; benchmark_qwen36_extend_attention_m756.py:235:35
	v_max_f32_e32 v46, v60, v60
	v_max_f32_e32 v46, v8, v46
	.loc	1 236 29                        ; benchmark_qwen36_extend_attention_m756.py:236:29
	v_sub_f32_e32 v8, v60, v46
	.loc	1 236 21 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:236:21
	v_mul_f32_e32 v47, 0x3fb8aa3b, v8
	v_cmp_gt_f32_e32 vcc, s2, v47
	.loc	1 237 32 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:237:32
	v_sub_f32_e32 v0, v0, v46
	v_sub_f32_e32 v1, v1, v46
	.loc	1 236 21                        ; benchmark_qwen36_extend_attention_m756.py:236:21
	v_cndmask_b32_e32 v47, 0, v48, vcc
	v_fmac_f32_e32 v47, 0x3fb8aa3b, v8
	v_exp_f32_e32 v8, v47
	v_not_b32_e32 v47, 63
	v_cndmask_b32_e32 v54, 0, v47, vcc
	.loc	1 237 32                        ; benchmark_qwen36_extend_attention_m756.py:237:32
	v_sub_f32_e32 v2, v2, v46
	.loc	1 236 21                        ; benchmark_qwen36_extend_attention_m756.py:236:21
	v_ldexp_f32 v8, v8, v54
	.loc	1 237 27                        ; benchmark_qwen36_extend_attention_m756.py:237:27
	v_mul_f32_e32 v54, 0x3fb8aa3b, v0
	v_cmp_gt_f32_e32 vcc, s2, v54
	.loc	1 237 32 is_stmt 0              ; benchmark_qwen36_extend_attention_m756.py:237:32
	v_sub_f32_e32 v3, v3, v46
	v_sub_f32_e32 v46, 0xff800000, v46
	.loc	1 237 27                        ; benchmark_qwen36_extend_attention_m756.py:237:27
	v_cndmask_b32_e32 v54, 0, v48, vcc
	v_fmac_f32_e32 v54, 0x3fb8aa3b, v0
	v_exp_f32_e32 v0, v54
	v_cndmask_b32_e32 v54, 0, v47, vcc
	.loc	1 245 16 is_stmt 1              ; benchmark_qwen36_extend_attention_m756.py:245:16
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	.loc	1 237 27                        ; benchmark_qwen36_extend_attention_m756.py:237:27
	v_ldexp_f32 v0, v0, v54
	v_mul_f32_e32 v54, 0x3fb8aa3b, v1
	v_cmp_gt_f32_e32 vcc, s2, v54
	.loc	1 247 35                        ; benchmark_qwen36_extend_attention_m756.py:247:35
	v_pk_mul_f32 v[12:13], v[12:13], v[8:9] op_sel_hi:[1,0]
	v_pk_mul_f32 v[10:11], v[10:11], v[8:9] op_sel_hi:[1,0]
	.loc	1 237 27                        ; benchmark_qwen36_extend_attention_m756.py:237:27
	v_cndmask_b32_e32 v54, 0, v48, vcc
	v_fmac_f32_e32 v54, 0x3fb8aa3b, v1
	v_exp_f32_e32 v1, v54
	v_mul_f32_e32 v54, 0x3fb8aa3b, v2
	v_cmp_gt_f32_e64 s[0:1], s2, v54
	.loc	1 257 8                         ; benchmark_qwen36_extend_attention_m756.py:257:8
	s_mov_b32 s10, s6
	s_mov_b32 s11, s7
	.loc	1 237 27                        ; benchmark_qwen36_extend_attention_m756.py:237:27
	v_cndmask_b32_e64 v54, 0, v48, s[0:1]
	v_fmac_f32_e32 v54, 0x3fb8aa3b, v2
	v_exp_f32_e32 v2, v54
	v_cndmask_b32_e32 v54, 0, v47, vcc
	v_ldexp_f32 v1, v1, v54
	v_cndmask_b32_e64 v54, 0, v47, s[0:1]
	v_ldexp_f32 v2, v2, v54
	v_mul_f32_e32 v54, 0x3fb8aa3b, v3
	v_cmp_gt_f32_e32 vcc, s2, v54
	s_nop 1
	v_cndmask_b32_e32 v54, 0, v48, vcc
	v_fmac_f32_e32 v54, 0x3fb8aa3b, v3
	v_exp_f32_e32 v3, v54
	v_mul_f32_e32 v54, 0x3fb8aa3b, v46
	v_cmp_gt_f32_e64 s[0:1], s2, v54
	s_nop 1
	v_cndmask_b32_e64 v48, 0, v48, s[0:1]
	v_fmac_f32_e32 v48, 0x3fb8aa3b, v46
	v_exp_f32_e32 v46, v48
	v_cndmask_b32_e32 v48, 0, v47, vcc
	v_cndmask_b32_e64 v47, 0, v47, s[0:1]
	v_ldexp_f32 v3, v3, v48
	v_ldexp_f32 v54, v46, v47
.Ltmp67:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:238:35 ] ]
	v_add_f32_e32 v46, v0, v1
	v_add_f32_e32 v46, v2, v46
	v_add_f32_e32 v46, v3, v46
	v_add_f32_e32 v46, v54, v46
	v_add_f32_e32 v46, v54, v46
.Ltmp68:
	.loc	1 247 25                        ; benchmark_qwen36_extend_attention_m756.py:247:25
	v_cvt_pk_bf16_f32 v0, v0, v1
	v_cvt_pk_bf16_f32 v1, v2, v3
	.loc	1 245 16                        ; benchmark_qwen36_extend_attention_m756.py:245:16
	v_bitop3_b32 v3, v49, v55, s3 bitop3:0x78
.Ltmp69:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:238:35 ] ]
	v_add_f32_e32 v60, v54, v46
.Ltmp70:
	.loc	1 245 16                        ; benchmark_qwen36_extend_attention_m756.py:245:16
	v_add_u32_e32 v46, 0, v3
	s_waitcnt vmcnt(2)
	ds_write2st64_b64 v46, v[4:5], v[50:51] offset1:16
	v_xad_u32 v4, v3, 8, 0
	ds_write2st64_b64 v4, v[6:7], v[52:53] offset1:16
	v_xad_u32 v4, v3, 16, 0
	v_xad_u32 v3, v3, 24, 0
	NETRA_WAIT_VM0
	ds_write2st64_b64 v4, v[56:57], v[62:63] offset1:16
	ds_write2st64_b64 v3, v[58:59], v[64:65] offset1:16
	v_lshlrev_b32_e32 v3, 6, v43
	v_and_b32_e32 v4, 24, v45
	v_lshlrev_b32_e32 v5, 1, v43
	v_bitop3_b32 v43, v3, v5, v4 bitop3:0x36
	v_add_u32_e32 v3, 0, v43
	.loc	1 247 25                        ; benchmark_qwen36_extend_attention_m756.py:247:25
	v_cvt_pk_bf16_f32 v2, v54, v54
	.loc	1 245 16                        ; benchmark_qwen36_extend_attention_m756.py:245:16
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b64_tr_b16 v[48:49], v3
	ds_read_b64_tr_b16 v[50:51], v3 offset:4096
	ds_read_b64_tr_b16 v[58:59], v3 offset:4224
	ds_read_b64_tr_b16 v[56:57], v3 offset:128
	ds_read_b64_tr_b16 v[62:63], v3 offset:8192
	ds_read_b64_tr_b16 v[64:65], v3 offset:12288
	ds_read_b64_tr_b16 v[68:69], v3 offset:12416
	ds_read_b64_tr_b16 v[66:67], v3 offset:8320
	v_xad_u32 v3, v43, 32, 0
	ds_read_b64_tr_b16 v[70:71], v3
	ds_read_b64_tr_b16 v[72:73], v3 offset:4096
	ds_read_b64_tr_b16 v[76:77], v3 offset:4224
	ds_read_b64_tr_b16 v[74:75], v3 offset:128
	ds_read_b64_tr_b16 v[78:79], v3 offset:8192
	ds_read_b64_tr_b16 v[80:81], v3 offset:12288
	ds_read_b64_tr_b16 v[84:85], v3 offset:12416
	ds_read_b64_tr_b16 v[82:83], v3 offset:8320
	.loc	1 247 35                        ; benchmark_qwen36_extend_attention_m756.py:247:35
	v_mov_b32_e32 v3, v2
	v_pk_mul_f32 v[6:7], v[40:41], v[8:9] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[38:39], v[8:9] op_sel_hi:[1,0]
	v_mov_b32_e32 v46, v2
	v_mov_b32_e32 v47, v2
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_bf16 v[4:7], v[48:51], v[0:3], v[4:7]
	v_mov_b32_e32 v48, v2
	v_mov_b32_e32 v49, v2
	.loc	1 245 16                        ; benchmark_qwen36_extend_attention_m756.py:245:16
	v_xad_u32 v45, v43, 64, 0
	ds_read_b64_tr_b16 v[50:51], v45 offset:8192
	ds_read_b64_tr_b16 v[52:53], v45 offset:12288
	.loc	1 247 35                        ; benchmark_qwen36_extend_attention_m756.py:247:35
	s_waitcnt lgkmcnt(12)
	v_mfma_f32_16x16x32_bf16 v[38:41], v[62:65], v[46:49], v[4:7]
	s_nop 2
	v_mul_f32_e64 v6, v36, v8
	v_mul_f32_e64 v7, v37, v8
	v_pk_mul_f32 v[4:5], v[34:35], v[8:9] op_sel_hi:[1,0]
	.loc	1 245 16                        ; benchmark_qwen36_extend_attention_m756.py:245:16
	v_xor_b32_e32 v34, 0x60, v43
	v_add_u32_e32 v43, 0, v34
	.loc	1 247 35                        ; benchmark_qwen36_extend_attention_m756.py:247:35
	s_waitcnt lgkmcnt(8)
	v_mfma_f32_16x16x32_bf16 v[4:7], v[70:73], v[0:3], v[4:7]
	.loc	1 245 16                        ; benchmark_qwen36_extend_attention_m756.py:245:16
	ds_read_b64_tr_b16 v[62:63], v45
	ds_read_b64_tr_b16 v[64:65], v45 offset:4096
	ds_read_b64_tr_b16 v[72:73], v45 offset:4224
	ds_read_b64_tr_b16 v[70:71], v45 offset:128
	.loc	1 247 35                        ; benchmark_qwen36_extend_attention_m756.py:247:35
	s_waitcnt lgkmcnt(8)
	v_mfma_f32_16x16x32_bf16 v[34:37], v[78:81], v[46:49], v[4:7]
	.loc	1 245 16                        ; benchmark_qwen36_extend_attention_m756.py:245:16
	ds_read_b64_tr_b16 v[78:79], v43
	ds_read_b64_tr_b16 v[80:81], v43 offset:4096
	.loc	1 247 35                        ; benchmark_qwen36_extend_attention_m756.py:247:35
	s_nop 0
	v_pk_mul_f32 v[6:7], v[32:33], v[8:9] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[30:31], v[8:9] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(4)
	s_nop 0
	v_mfma_f32_16x16x32_bf16 v[4:7], v[62:65], v[0:3], v[4:7]
	.loc	1 245 16                        ; benchmark_qwen36_extend_attention_m756.py:245:16
	ds_read_b64_tr_b16 v[64:65], v45 offset:12416
	ds_read_b64_tr_b16 v[62:63], v45 offset:8320
	ds_read_b64_tr_b16 v[86:87], v43 offset:8192
	ds_read_b64_tr_b16 v[88:89], v43 offset:12288
.Ltmp71:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:238:35 ] ]
	v_add_f32_e32 v45, v54, v60
.Ltmp72:
	.loc	1 247 35                        ; benchmark_qwen36_extend_attention_m756.py:247:35
	v_mfma_f32_16x16x32_bf16 v[30:33], v[50:53], v[46:49], v[4:7]
	.loc	1 245 16                        ; benchmark_qwen36_extend_attention_m756.py:245:16
	ds_read_b64_tr_b16 v[52:53], v43 offset:4224
	ds_read_b64_tr_b16 v[50:51], v43 offset:128
	.loc	1 247 35                        ; benchmark_qwen36_extend_attention_m756.py:247:35
	s_nop 0
	v_pk_mul_f32 v[6:7], v[28:29], v[8:9] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[26:27], v[8:9] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(6)
	s_nop 0
	v_mfma_f32_16x16x32_bf16 v[4:7], v[78:81], v[0:3], v[4:7]
	.loc	1 245 16                        ; benchmark_qwen36_extend_attention_m756.py:245:16
	ds_read_b64_tr_b16 v[80:81], v43 offset:12416
	ds_read_b64_tr_b16 v[78:79], v43 offset:8320
.Ltmp73:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:238:35 ] ]
	v_add_f32_e32 v43, v54, v45
.Ltmp74:
	.loc	1 247 35                        ; benchmark_qwen36_extend_attention_m756.py:247:35
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x32_bf16 v[26:29], v[86:89], v[46:49], v[4:7]
	s_nop 2
	v_mul_f32_e64 v6, v24, v8
	v_mul_f32_e64 v7, v25, v8
	v_pk_mul_f32 v[4:5], v[22:23], v[8:9] op_sel_hi:[1,0]
.Ltmp75:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:238:35 ] ]
	v_add_f32_e32 v22, v54, v43
	v_add_f32_e32 v22, v54, v22
.Ltmp76:
	.loc	1 247 35                        ; benchmark_qwen36_extend_attention_m756.py:247:35
	v_mfma_f32_16x16x32_bf16 v[4:7], v[56:59], v[0:3], v[4:7]
.Ltmp77:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:238:35 ] ]
	v_add_f32_e32 v43, v54, v22
	v_add_f32_e32 v43, v54, v43
.Ltmp78:
	.loc	1 247 35                        ; benchmark_qwen36_extend_attention_m756.py:247:35
	v_mfma_f32_16x16x32_bf16 v[22:25], v[66:69], v[46:49], v[4:7]
	s_nop 4
	v_mul_f32_e64 v6, v20, v8
	v_mul_f32_e64 v7, v21, v8
	v_pk_mul_f32 v[4:5], v[18:19], v[8:9] op_sel_hi:[1,0]
.Ltmp79:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:238:35 ] ]
	v_add_f32_e32 v18, v54, v43
	v_add_f32_e32 v18, v54, v18
.Ltmp80:
	.loc	1 247 35                        ; benchmark_qwen36_extend_attention_m756.py:247:35
	v_mfma_f32_16x16x32_bf16 v[4:7], v[74:77], v[0:3], v[4:7]
.Ltmp81:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:238:35 ] ]
	v_add_f32_e32 v43, v54, v18
.Ltmp82:
	.loc	2 293 36                        ; standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:238:35 ]
	v_mov_b32_e32 v45, v43
	s_nop 1
	v_permlane32_swap_b32_e32 v43, v45
.Ltmp83:
	.loc	1 247 35                        ; benchmark_qwen36_extend_attention_m756.py:247:35
	v_mfma_f32_16x16x32_bf16 v[18:21], v[82:85], v[46:49], v[4:7]
	s_nop 2
	v_mul_f32_e64 v4, v14, v8
	v_mul_f32_e64 v5, v15, v8
.Ltmp84:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:238:35 ] ]
	v_add_f32_e32 v14, v43, v45
.Ltmp85:
	.loc	2 293 36                        ; standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:238:35 ]
	v_mov_b32_e32 v15, v14
.Ltmp86:
	.loc	1 247 35                        ; benchmark_qwen36_extend_attention_m756.py:247:35
	v_pk_mul_f32 v[6:7], v[16:17], v[8:9] op_sel_hi:[1,0]
.Ltmp87:
	.loc	2 293 36                        ; standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:238:35 ]
	s_nop 0
	v_permlane16_swap_b32_e32 v14, v15
.Ltmp88:
	.loc	1 247 35                        ; benchmark_qwen36_extend_attention_m756.py:247:35
	v_mfma_f32_16x16x32_bf16 v[4:7], v[70:73], v[0:3], v[4:7]
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[0:3], v[50:53], v[0:3], v[10:13]
.Ltmp89:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ benchmark_qwen36_extend_attention_m756.py:238:35 ] ]
	s_nop 2
	v_add_f32_e32 v13, v14, v15
.Ltmp90:
	.loc	1 238 28                        ; benchmark_qwen36_extend_attention_m756.py:238:28
	v_fmac_f32_e32 v13, v61, v8
	.loc	1 257 14                        ; benchmark_qwen36_extend_attention_m756.py:257:14
	v_div_scale_f32 v14, s[0:1], v13, v13, v38
	v_rcp_f32_e32 v15, v14
	.loc	1 247 35                        ; benchmark_qwen36_extend_attention_m756.py:247:35
	v_mfma_f32_16x16x32_bf16 v[4:7], v[62:65], v[46:49], v[4:7]
	.loc	1 256 17                        ; benchmark_qwen36_extend_attention_m756.py:256:17
	v_lshl_add_u32 v8, v44, 12, s18
	v_or_b32_e32 v12, 32, v42
	.loc	1 257 14                        ; benchmark_qwen36_extend_attention_m756.py:257:14
	v_fma_f32 v16, -v14, v15, 1.0
	v_fmac_f32_e32 v15, v16, v15
	v_div_scale_f32 v16, vcc, v38, v13, v38
	v_mul_f32_e32 v17, v16, v15
	v_fma_f32 v43, -v14, v17, v16
	v_fmac_f32_e32 v17, v43, v15
	v_fma_f32 v14, -v14, v17, v16
	v_div_scale_f32 v16, s[0:1], v13, v13, v39
	v_rcp_f32_e32 v43, v16
	v_div_fmas_f32 v14, v14, v15, v17
	v_div_fixup_f32 v14, v14, v13, v38
	.loc	1 247 35                        ; benchmark_qwen36_extend_attention_m756.py:247:35
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[0:3], v[78:81], v[46:49], v[0:3]
	.loc	1 257 14                        ; benchmark_qwen36_extend_attention_m756.py:257:14
	v_fma_f32 v15, -v16, v43, 1.0
	v_fmac_f32_e32 v43, v15, v43
	v_div_scale_f32 v15, vcc, v39, v13, v39
	v_mul_f32_e32 v17, v15, v43
	v_fma_f32 v38, -v16, v17, v15
	v_fmac_f32_e32 v17, v38, v43
	v_fma_f32 v15, -v16, v17, v15
	v_div_scale_f32 v16, s[0:1], v13, v13, v40
	v_rcp_f32_e32 v38, v16
	v_div_fmas_f32 v15, v15, v43, v17
	v_div_fixup_f32 v15, v15, v13, v39
	.loc	1 256 17                        ; benchmark_qwen36_extend_attention_m756.py:256:17
	v_or_b32_e32 v11, 64, v42
	.loc	1 257 14                        ; benchmark_qwen36_extend_attention_m756.py:257:14
	v_fma_f32 v17, -v16, v38, 1.0
	v_fmac_f32_e32 v38, v17, v38
	v_div_scale_f32 v17, vcc, v40, v13, v40
	v_mul_f32_e32 v39, v17, v38
	v_fma_f32 v43, -v16, v39, v17
	v_fmac_f32_e32 v39, v43, v38
	v_fma_f32 v16, -v16, v39, v17
	v_div_scale_f32 v17, s[0:1], v13, v13, v41
	v_rcp_f32_e32 v43, v17
	v_div_fmas_f32 v16, v16, v38, v39
	v_div_fixup_f32 v16, v16, v13, v40
	.loc	1 256 17                        ; benchmark_qwen36_extend_attention_m756.py:256:17
	v_or_b32_e32 v10, 0x60, v42
	.loc	1 257 14                        ; benchmark_qwen36_extend_attention_m756.py:257:14
	v_fma_f32 v38, -v17, v43, 1.0
	v_fmac_f32_e32 v43, v38, v43
	v_div_scale_f32 v38, vcc, v41, v13, v41
	v_mul_f32_e32 v39, v38, v43
	v_fma_f32 v40, -v17, v39, v38
	v_fmac_f32_e32 v39, v40, v43
	v_fma_f32 v17, -v17, v39, v38
	v_div_scale_f32 v38, s[0:1], v13, v13, v34
	v_rcp_f32_e32 v40, v38
	v_div_fmas_f32 v17, v17, v43, v39
	v_div_fixup_f32 v17, v17, v13, v41
	v_fma_f32 v39, -v38, v40, 1.0
	v_fmac_f32_e32 v40, v39, v40
	v_div_scale_f32 v39, vcc, v34, v13, v34
	v_mul_f32_e32 v41, v39, v40
	v_fma_f32 v43, -v38, v41, v39
	v_fmac_f32_e32 v41, v43, v40
	v_fma_f32 v38, -v38, v41, v39
	v_div_scale_f32 v39, s[0:1], v13, v13, v35
	v_rcp_f32_e32 v43, v39
	v_div_fmas_f32 v38, v38, v40, v41
	v_div_fixup_f32 v34, v38, v13, v34
	v_fma_f32 v38, -v39, v43, 1.0
	v_fmac_f32_e32 v43, v38, v43
	v_div_scale_f32 v38, vcc, v35, v13, v35
	v_mul_f32_e32 v40, v38, v43
	v_fma_f32 v41, -v39, v40, v38
	v_fmac_f32_e32 v40, v41, v43
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v36
	v_rcp_f32_e32 v41, v39
	v_div_fmas_f32 v38, v38, v43, v40
	v_div_fixup_f32 v35, v38, v13, v35
	v_fma_f32 v38, -v39, v41, 1.0
	v_fmac_f32_e32 v41, v38, v41
	v_div_scale_f32 v38, vcc, v36, v13, v36
	v_mul_f32_e32 v40, v38, v41
	v_fma_f32 v43, -v39, v40, v38
	v_fmac_f32_e32 v40, v43, v41
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v37
	v_rcp_f32_e32 v43, v39
	v_div_fmas_f32 v38, v38, v41, v40
	v_div_fixup_f32 v36, v38, v13, v36
	v_fma_f32 v38, -v39, v43, 1.0
	v_fmac_f32_e32 v43, v38, v43
	v_div_scale_f32 v38, vcc, v37, v13, v37
	v_mul_f32_e32 v40, v38, v43
	v_fma_f32 v41, -v39, v40, v38
	v_fmac_f32_e32 v40, v41, v43
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v30
	v_rcp_f32_e32 v41, v39
	v_div_fmas_f32 v38, v38, v43, v40
	v_div_fixup_f32 v37, v38, v13, v37
	v_fma_f32 v38, -v39, v41, 1.0
	v_fmac_f32_e32 v41, v38, v41
	v_div_scale_f32 v38, vcc, v30, v13, v30
	v_mul_f32_e32 v40, v38, v41
	v_fma_f32 v43, -v39, v40, v38
	v_fmac_f32_e32 v40, v43, v41
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v31
	v_rcp_f32_e32 v43, v39
	v_div_fmas_f32 v38, v38, v41, v40
	v_div_fixup_f32 v30, v38, v13, v30
	v_fma_f32 v38, -v39, v43, 1.0
	v_fmac_f32_e32 v43, v38, v43
	v_div_scale_f32 v38, vcc, v31, v13, v31
	v_mul_f32_e32 v40, v38, v43
	v_fma_f32 v41, -v39, v40, v38
	v_fmac_f32_e32 v40, v41, v43
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v32
	v_rcp_f32_e32 v41, v39
	v_div_fmas_f32 v38, v38, v43, v40
	v_div_fixup_f32 v31, v38, v13, v31
	v_fma_f32 v38, -v39, v41, 1.0
	v_fmac_f32_e32 v41, v38, v41
	v_div_scale_f32 v38, vcc, v32, v13, v32
	v_mul_f32_e32 v40, v38, v41
	v_fma_f32 v43, -v39, v40, v38
	v_fmac_f32_e32 v40, v43, v41
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v33
	v_rcp_f32_e32 v43, v39
	v_div_fmas_f32 v38, v38, v41, v40
	v_div_fixup_f32 v32, v38, v13, v32
	v_fma_f32 v38, -v39, v43, 1.0
	v_fmac_f32_e32 v43, v38, v43
	v_div_scale_f32 v38, vcc, v33, v13, v33
	v_mul_f32_e32 v40, v38, v43
	v_fma_f32 v41, -v39, v40, v38
	v_fmac_f32_e32 v40, v41, v43
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v26
	v_rcp_f32_e32 v41, v39
	v_div_fmas_f32 v38, v38, v43, v40
	v_div_fixup_f32 v33, v38, v13, v33
	v_fma_f32 v38, -v39, v41, 1.0
	v_fmac_f32_e32 v41, v38, v41
	v_div_scale_f32 v38, vcc, v26, v13, v26
	v_mul_f32_e32 v40, v38, v41
	v_fma_f32 v43, -v39, v40, v38
	v_fmac_f32_e32 v40, v43, v41
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v27
	v_rcp_f32_e32 v43, v39
	v_div_fmas_f32 v38, v38, v41, v40
	v_div_fixup_f32 v26, v38, v13, v26
	v_fma_f32 v38, -v39, v43, 1.0
	v_fmac_f32_e32 v43, v38, v43
	v_div_scale_f32 v38, vcc, v27, v13, v27
	v_mul_f32_e32 v40, v38, v43
	v_fma_f32 v41, -v39, v40, v38
	v_fmac_f32_e32 v40, v41, v43
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v28
	v_rcp_f32_e32 v41, v39
	v_div_fmas_f32 v38, v38, v43, v40
	v_div_fixup_f32 v27, v38, v13, v27
	v_fma_f32 v38, -v39, v41, 1.0
	v_fmac_f32_e32 v41, v38, v41
	v_div_scale_f32 v38, vcc, v28, v13, v28
	v_mul_f32_e32 v40, v38, v41
	v_fma_f32 v43, -v39, v40, v38
	v_fmac_f32_e32 v40, v43, v41
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v29
	v_rcp_f32_e32 v43, v39
	v_div_fmas_f32 v38, v38, v41, v40
	v_div_fixup_f32 v28, v38, v13, v28
	v_fma_f32 v38, -v39, v43, 1.0
	v_fmac_f32_e32 v43, v38, v43
	v_div_scale_f32 v38, vcc, v29, v13, v29
	v_mul_f32_e32 v40, v38, v43
	v_fma_f32 v41, -v39, v40, v38
	v_fmac_f32_e32 v40, v41, v43
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v22
	v_rcp_f32_e32 v41, v39
	v_div_fmas_f32 v38, v38, v43, v40
	v_div_fixup_f32 v29, v38, v13, v29
	v_fma_f32 v38, -v39, v41, 1.0
	v_fmac_f32_e32 v41, v38, v41
	v_div_scale_f32 v38, vcc, v22, v13, v22
	v_mul_f32_e32 v40, v38, v41
	v_fma_f32 v43, -v39, v40, v38
	v_fmac_f32_e32 v40, v43, v41
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v23
	v_rcp_f32_e32 v43, v39
	v_div_fmas_f32 v38, v38, v41, v40
	v_div_fixup_f32 v22, v38, v13, v22
	v_fma_f32 v38, -v39, v43, 1.0
	v_fmac_f32_e32 v43, v38, v43
	v_div_scale_f32 v38, vcc, v23, v13, v23
	v_mul_f32_e32 v40, v38, v43
	v_fma_f32 v41, -v39, v40, v38
	v_fmac_f32_e32 v40, v41, v43
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v24
	v_rcp_f32_e32 v41, v39
	v_div_fmas_f32 v38, v38, v43, v40
	v_div_fixup_f32 v23, v38, v13, v23
	v_fma_f32 v38, -v39, v41, 1.0
	v_fmac_f32_e32 v41, v38, v41
	v_div_scale_f32 v38, vcc, v24, v13, v24
	v_mul_f32_e32 v40, v38, v41
	v_fma_f32 v43, -v39, v40, v38
	v_fmac_f32_e32 v40, v43, v41
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v25
	v_rcp_f32_e32 v43, v39
	v_div_fmas_f32 v38, v38, v41, v40
	v_div_fixup_f32 v24, v38, v13, v24
	v_fma_f32 v38, -v39, v43, 1.0
	v_fmac_f32_e32 v43, v38, v43
	v_div_scale_f32 v38, vcc, v25, v13, v25
	v_mul_f32_e32 v40, v38, v43
	v_fma_f32 v41, -v39, v40, v38
	v_fmac_f32_e32 v40, v41, v43
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v18
	v_rcp_f32_e32 v41, v39
	v_div_fmas_f32 v38, v38, v43, v40
	v_div_fixup_f32 v25, v38, v13, v25
	v_fma_f32 v38, -v39, v41, 1.0
	v_fmac_f32_e32 v41, v38, v41
	v_div_scale_f32 v38, vcc, v18, v13, v18
	v_mul_f32_e32 v40, v38, v41
	v_fma_f32 v43, -v39, v40, v38
	v_fmac_f32_e32 v40, v43, v41
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v19
	v_rcp_f32_e32 v43, v39
	v_div_fmas_f32 v38, v38, v41, v40
	v_div_fixup_f32 v18, v38, v13, v18
	v_fma_f32 v38, -v39, v43, 1.0
	v_fmac_f32_e32 v43, v38, v43
	v_div_scale_f32 v38, vcc, v19, v13, v19
	v_mul_f32_e32 v40, v38, v43
	v_fma_f32 v41, -v39, v40, v38
	v_fmac_f32_e32 v40, v41, v43
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v20
	v_rcp_f32_e32 v41, v39
	v_div_fmas_f32 v38, v38, v43, v40
	v_div_fixup_f32 v19, v38, v13, v19
	v_fma_f32 v38, -v39, v41, 1.0
	v_fmac_f32_e32 v41, v38, v41
	v_div_scale_f32 v38, vcc, v20, v13, v20
	v_mul_f32_e32 v40, v38, v41
	v_fma_f32 v43, -v39, v40, v38
	v_fmac_f32_e32 v40, v43, v41
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v21
	v_rcp_f32_e32 v43, v39
	v_div_fmas_f32 v38, v38, v41, v40
	v_div_fixup_f32 v20, v38, v13, v20
	v_fma_f32 v38, -v39, v43, 1.0
	v_fmac_f32_e32 v43, v38, v43
	v_div_scale_f32 v38, vcc, v21, v13, v21
	v_mul_f32_e32 v40, v38, v43
	v_fma_f32 v41, -v39, v40, v38
	v_fmac_f32_e32 v40, v41, v43
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v4
	v_rcp_f32_e32 v41, v39
	v_div_fmas_f32 v38, v38, v43, v40
	v_div_fixup_f32 v21, v38, v13, v21
	v_fma_f32 v38, -v39, v41, 1.0
	v_fmac_f32_e32 v41, v38, v41
	v_div_scale_f32 v38, vcc, v4, v13, v4
	v_mul_f32_e32 v40, v38, v41
	v_fma_f32 v43, -v39, v40, v38
	v_fmac_f32_e32 v40, v43, v41
	v_fma_f32 v38, -v39, v40, v38
	v_div_scale_f32 v39, s[0:1], v13, v13, v5
	v_rcp_f32_e32 v43, v39
	v_div_fmas_f32 v38, v38, v41, v40
	v_div_fixup_f32 v38, v38, v13, v4
	v_fma_f32 v4, -v39, v43, 1.0
	v_fmac_f32_e32 v43, v4, v43
	v_div_scale_f32 v4, vcc, v5, v13, v5
	v_mul_f32_e32 v40, v4, v43
	v_fma_f32 v41, -v39, v40, v4
	v_fmac_f32_e32 v40, v41, v43
	v_fma_f32 v4, -v39, v40, v4
	v_div_scale_f32 v39, s[0:1], v13, v13, v6
	v_rcp_f32_e32 v41, v39
	v_div_fmas_f32 v4, v4, v43, v40
	v_div_fixup_f32 v40, v4, v13, v5
	v_fma_f32 v4, -v39, v41, 1.0
	v_fmac_f32_e32 v41, v4, v41
	v_div_scale_f32 v4, vcc, v6, v13, v6
	v_mul_f32_e32 v5, v4, v41
	v_fma_f32 v43, -v39, v5, v4
	v_fmac_f32_e32 v5, v43, v41
	v_fma_f32 v4, -v39, v5, v4
	v_div_scale_f32 v39, s[0:1], v13, v13, v7
	v_rcp_f32_e32 v43, v39
	v_div_fmas_f32 v4, v4, v41, v5
	v_div_fixup_f32 v41, v4, v13, v6
	v_fma_f32 v4, -v39, v43, 1.0
	v_fmac_f32_e32 v43, v4, v43
	v_div_scale_f32 v4, vcc, v7, v13, v7
	v_mul_f32_e32 v5, v4, v43
	v_fma_f32 v6, -v39, v5, v4
	v_fmac_f32_e32 v5, v6, v43
	v_div_scale_f32 v6, s[0:1], v13, v13, v0
	v_fma_f32 v4, -v39, v5, v4
	v_rcp_f32_e32 v39, v6
	v_div_fmas_f32 v4, v4, v43, v5
	v_div_fixup_f32 v43, v4, v13, v7
	v_fma_f32 v4, -v6, v39, 1.0
	v_fmac_f32_e32 v39, v4, v39
	v_div_scale_f32 v4, vcc, v0, v13, v0
	v_mul_f32_e32 v5, v4, v39
	v_fma_f32 v7, -v6, v5, v4
	v_fmac_f32_e32 v5, v7, v39
	v_fma_f32 v4, -v6, v5, v4
	v_div_scale_f32 v6, s[0:1], v13, v13, v1
	v_rcp_f32_e32 v7, v6
	v_div_fmas_f32 v4, v4, v39, v5
	v_div_fixup_f32 v39, v4, v13, v0
	v_fma_f32 v0, -v6, v7, 1.0
	v_fmac_f32_e32 v7, v0, v7
	v_div_scale_f32 v0, vcc, v1, v13, v1
	v_mul_f32_e32 v4, v0, v7
	v_fma_f32 v5, -v6, v4, v0
	v_fmac_f32_e32 v4, v5, v7
	v_div_scale_f32 v5, s[0:1], v13, v13, v2
	v_fma_f32 v0, -v6, v4, v0
	v_rcp_f32_e32 v6, v5
	v_div_fmas_f32 v0, v0, v7, v4
	v_div_fixup_f32 v44, v0, v13, v1
	.loc	1 257 8 is_stmt 0               ; benchmark_qwen36_extend_attention_m756.py:257:8
	v_cvt_pk_bf16_f32 v7, v28, v29
	.loc	1 257 14                        ; benchmark_qwen36_extend_attention_m756.py:257:14
	v_fma_f32 v0, -v5, v6, 1.0
	v_fmac_f32_e32 v6, v0, v6
	v_div_scale_f32 v0, vcc, v2, v13, v2
	v_mul_f32_e32 v1, v0, v6
	v_fma_f32 v4, -v5, v1, v0
	v_fmac_f32_e32 v1, v4, v6
	v_div_scale_f32 v4, s[0:1], v13, v13, v3
	v_fma_f32 v0, -v5, v1, v0
	v_rcp_f32_e32 v5, v4
	v_div_fmas_f32 v0, v0, v6, v1
	v_div_fixup_f32 v45, v0, v13, v2
	.loc	1 257 8                         ; benchmark_qwen36_extend_attention_m756.py:257:8
	v_cvt_pk_bf16_f32 v6, v26, v27
	.loc	1 257 14                        ; benchmark_qwen36_extend_attention_m756.py:257:14
	v_fma_f32 v0, -v4, v5, 1.0
	v_fmac_f32_e32 v5, v0, v5
	v_div_scale_f32 v0, vcc, v3, v13, v3
	v_mul_f32_e32 v1, v0, v5
	v_fma_f32 v2, -v4, v1, v0
	v_fmac_f32_e32 v1, v2, v5
	v_fma_f32 v0, -v4, v1, v0
	v_div_fmas_f32 v0, v0, v5, v1
	v_div_fixup_f32 v13, v0, v13, v3
	.loc	1 257 8                         ; benchmark_qwen36_extend_attention_m756.py:257:8
	v_cvt_pk_bf16_f32 v0, v14, v15
	v_cvt_pk_bf16_f32 v1, v16, v17
	v_cvt_pk_bf16_f32 v2, v34, v35
	v_cvt_pk_bf16_f32 v3, v36, v37
	v_cvt_pk_bf16_f32 v17, v20, v21
	v_cvt_pk_bf16_f32 v21, v45, v13
	v_add_lshl_u32 v13, v42, v8, 1
	v_permlane16_swap_b32_e32 v0, v2
	v_permlane16_swap_b32_e32 v1, v3
	v_cndmask_b32_e64 v13, v9, v13, s[48:49]
	v_cvt_pk_bf16_f32 v4, v30, v31
	v_cvt_pk_bf16_f32 v5, v32, v33
	buffer_store_dwordx4 v[0:3], v13, s[8:11], 0 offen
	v_permlane16_swap_b32_e32 v4, v6
	s_nop 0
	v_add_lshl_u32 v0, v12, v8, 1
	v_permlane16_swap_b32_e32 v5, v7
	v_cndmask_b32_e64 v0, v9, v0, s[48:49]
	v_cvt_pk_bf16_f32 v14, v22, v23
	v_cvt_pk_bf16_f32 v15, v24, v25
	v_cvt_pk_bf16_f32 v16, v18, v19
	buffer_store_dwordx4 v[4:7], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v11, v8, 1
	v_permlane16_swap_b32_e32 v14, v16
	v_permlane16_swap_b32_e32 v15, v17
	v_cndmask_b32_e64 v0, v9, v0, s[48:49]
	v_cvt_pk_bf16_f32 v18, v38, v40
	v_cvt_pk_bf16_f32 v19, v41, v43
	v_cvt_pk_bf16_f32 v20, v39, v44
	buffer_store_dwordx4 v[14:17], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v10, v8, 1
	v_permlane16_swap_b32_e32 v18, v20
	v_permlane16_swap_b32_e32 v19, v21
	v_cndmask_b32_e64 v0, v9, v0, s[48:49]
	buffer_store_dwordx4 v[18:21], v0, s[8:11], 0 offen
	.loc	1 255 4 is_stmt 1               ; benchmark_qwen36_extend_attention_m756.py:255:4
	s_endpgm
.Ltmp91:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel \symbol
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
		.amdhsa_next_free_sgpr 96
		.amdhsa_accum_offset 136
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
	.size	\symbol, .Lfunc_end0-\symbol
	.cfi_endproc
                                        ; -- End function
	.set \symbol\().num_vgpr, 136
	.set \symbol\().num_agpr, 0
	.set \symbol\().numbered_sgpr, 76
	.set \symbol\().num_named_barrier, 0
	.set \symbol\().private_seg_size, 0
	.set \symbol\().uses_vcc, 1
	.set \symbol\().uses_flat_scratch, 0
	.set \symbol\().has_dyn_sized_stack, 0
	.set \symbol\().has_recursion, 0
	.set \symbol\().has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 9780
; TotalNumSgprs: 82
; NumVgprs: 136
; NumAgprs: 0
; TotalNumVgprs: 136
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 12
; VGPRBlocks: 32
; NumSGPRsForWavesPerEU: 102
; NumVGPRsForWavesPerEU: 257
; AccumOffset: 136
; Occupancy: 1
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 33
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
	.byte	7                               ; Abbreviation Code
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
	.byte	181                             ; DW_AT_call_line
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
	.byte	181                             ; DW_AT_call_line
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
	.byte	200                             ; DW_AT_call_line
	.byte	29                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x7f:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges5                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	6                               ; Abbrev [6] 0x8c:0x22 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.quad	.Ltmp53                         ; DW_AT_low_pc
	.long	.Ltmp58-.Ltmp53                 ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	205                             ; DW_AT_call_line
	.byte	43                              ; DW_AT_call_column
	.byte	7                               ; Abbrev [7] 0xa0:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges6                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.short	293                             ; DW_AT_call_line
	.byte	36                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0xae:0x19 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges7                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	233                             ; DW_AT_call_line
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
	.byte	238                             ; DW_AT_call_line
	.byte	35                              ; DW_AT_call_column
	.byte	7                               ; Abbrev [7] 0xd3:0xd DW_TAG_inlined_subroutine
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
	.quad	0
	.quad	0
.Ldebug_ranges7:
	.quad	.Ltmp59-.Lfunc_begin0
	.quad	.Ltmp62-.Lfunc_begin0
	.quad	.Ltmp63-.Lfunc_begin0
	.quad	.Ltmp66-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges8:
	.quad	.Ltmp59-.Lfunc_begin0
	.quad	.Ltmp60-.Lfunc_begin0
	.quad	.Ltmp61-.Lfunc_begin0
	.quad	.Ltmp62-.Lfunc_begin0
	.quad	.Ltmp63-.Lfunc_begin0
	.quad	.Ltmp64-.Lfunc_begin0
	.quad	.Ltmp65-.Lfunc_begin0
	.quad	.Ltmp66-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges9:
	.quad	.Ltmp67-.Lfunc_begin0
	.quad	.Ltmp68-.Lfunc_begin0
	.quad	.Ltmp69-.Lfunc_begin0
	.quad	.Ltmp70-.Lfunc_begin0
	.quad	.Ltmp71-.Lfunc_begin0
	.quad	.Ltmp72-.Lfunc_begin0
	.quad	.Ltmp73-.Lfunc_begin0
	.quad	.Ltmp74-.Lfunc_begin0
	.quad	.Ltmp75-.Lfunc_begin0
	.quad	.Ltmp76-.Lfunc_begin0
	.quad	.Ltmp77-.Lfunc_begin0
	.quad	.Ltmp78-.Lfunc_begin0
	.quad	.Ltmp79-.Lfunc_begin0
	.quad	.Ltmp80-.Lfunc_begin0
	.quad	.Ltmp81-.Lfunc_begin0
	.quad	.Ltmp83-.Lfunc_begin0
	.quad	.Ltmp84-.Lfunc_begin0
	.quad	.Ltmp86-.Lfunc_begin0
	.quad	.Ltmp87-.Lfunc_begin0
	.quad	.Ltmp88-.Lfunc_begin0
	.quad	.Ltmp89-.Lfunc_begin0
	.quad	.Ltmp90-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges10:
	.quad	.Ltmp67-.Lfunc_begin0
	.quad	.Ltmp68-.Lfunc_begin0
	.quad	.Ltmp69-.Lfunc_begin0
	.quad	.Ltmp70-.Lfunc_begin0
	.quad	.Ltmp71-.Lfunc_begin0
	.quad	.Ltmp72-.Lfunc_begin0
	.quad	.Ltmp73-.Lfunc_begin0
	.quad	.Ltmp74-.Lfunc_begin0
	.quad	.Ltmp75-.Lfunc_begin0
	.quad	.Ltmp76-.Lfunc_begin0
	.quad	.Ltmp77-.Lfunc_begin0
	.quad	.Ltmp78-.Lfunc_begin0
	.quad	.Ltmp79-.Lfunc_begin0
	.quad	.Ltmp80-.Lfunc_begin0
	.quad	.Ltmp81-.Lfunc_begin0
	.quad	.Ltmp82-.Lfunc_begin0
	.quad	.Ltmp84-.Lfunc_begin0
	.quad	.Ltmp85-.Lfunc_begin0
	.quad	.Ltmp89-.Lfunc_begin0
	.quad	.Ltmp90-.Lfunc_begin0
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
	.asciz	"\symbol"      ; string offset=79
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
    .name:           \symbol
    .private_segment_fixed_size: 0
    .sgpr_count:     82
    .sgpr_spill_count: 0
    .symbol:         \symbol\().kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     136
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
	.endm
