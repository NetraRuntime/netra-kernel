// SPDX-License-Identifier: MIT
// Fixed raw gfx950 GQA4 causal tail output stage.
	.macro NETRA_ATTENTION_GQA4_CAUSAL_TAIL_OUTPUT symbol
.LBB0_8:
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
	v_lshlrev_b32_e32 v2, 10, v42
	v_mov_b32_e32 v59, 0
	v_add_u32_e32 v2, s66, v2
	v_mov_b32_e32 v53, v59
	v_lshlrev_b32_e32 v3, 10, v52
	v_or_b32_e32 v5, v2, v54
	v_or_b32_e32 v2, v2, v56
	v_mov_b32_e32 v51, v59
	v_lshlrev_b32_e32 v4, 10, v50
	v_add_lshl_u32 v6, v5, v3, 1
	v_bfrev_b32_e32 v9, 1
	v_cmp_gt_i64_e32 vcc, v[46:47], v[52:53]
	v_add_lshl_u32 v3, v2, v3, 1
	s_and_b32 s5, s5, 0xffff
	s_mov_b32 s7, 0x27000
	s_mov_b32 s6, 0x7ffffffe
	v_cndmask_b32_e32 v8, v9, v6, vcc
	v_cndmask_b32_e32 v54, v9, v3, vcc
	v_add_lshl_u32 v3, v5, v4, 1
	v_cmp_gt_i64_e32 vcc, v[46:47], v[50:51]
	buffer_load_dwordx4 v[68:71], v8, s[4:7], 0 offen
	buffer_load_dwordx4 v[72:75], v54, s[4:7], 0 offen
	v_cndmask_b32_e32 v56, v9, v3, vcc
	buffer_load_dwordx4 v[76:79], v56, s[4:7], 0 offen
	v_add_lshl_u32 v2, v2, v4, 1
	v_cndmask_b32_e32 v66, v9, v2, vcc
	buffer_load_dwordx4 v[80:83], v66, s[4:7], 0 offen
	s_or_b32 s2, s54, s64
	v_and_b32_e32 v50, 0x78, v55
	v_lshlrev_b32_e32 v51, 4, v44
	v_or_b32_e32 v2, 1, v58
	v_or_b32_e32 v4, 2, v58
	v_or_b32_e32 v6, 3, v58
	v_cmp_ge_u32_e64 s[0:1], v44, v58
	v_cmp_gt_u32_e32 vcc, v44, v58
	s_lshl_b32 s18, s2, 7
	v_cmp_gt_i64_e64 s[2:3], v[46:47], v[58:59]
	v_lshlrev_b32_e32 v50, 1, v50
	v_bitop3_b32 v58, v51, v57, v1 bitop3:0xde
	s_movk_i32 s10, 0x80
	v_mov_b32_e32 v52, s65
	s_movk_i32 s11, 0xc0
	v_bitop3_b32 v51, v57, v1, v51 bitop3:0x36
	v_xor_b32_e32 v1, v50, v49
	v_or_b32_e32 v50, s65, v58
	v_mov_b32_e32 v3, v59
	v_mov_b32_e32 v5, v59
	v_mov_b32_e32 v7, v59
	v_bitop3_b32 v57, v58, s10, v52 bitop3:0x36
	v_bitop3_b32 v52, v58, s11, v52 bitop3:0x36
	v_add_u32_e32 v58, 0, v51
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
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	v_and_b32_e32 v42, 16, v0
	v_lshrrev_b32_e32 v0, 2, v0
	v_and_b32_e32 v0, 8, v0
	v_or3_b32 v42, v0, v42, v48
	v_xad_u32 v0, v51, 64, 0
	v_cmp_gt_i64_e64 s[12:13], v[46:47], v[2:3]
	v_xor_b32_e32 v48, 0xc0, v51
	v_add_u32_e32 v48, 0, v48
	s_and_b64 s[0:1], s[0:1], s[2:3]
	v_mov_b32_e32 v53, 0xff800000
	v_cmp_ge_u32_e64 s[4:5], v44, v4
	v_cmp_gt_i64_e64 s[14:15], v[46:47], v[4:5]
	s_and_b64 s[2:3], vcc, s[12:13]
	s_and_b64 vcc, s[48:49], s[0:1]
	v_cmp_ge_u32_e64 s[10:11], v44, v6
	v_cmp_gt_i64_e64 s[16:17], v[46:47], v[6:7]
	s_and_b64 s[4:5], s[4:5], s[14:15]
	s_and_b64 s[10:11], s[10:11], s[16:17]
	s_mov_b32 s19, 0xff800000
	s_and_b32 s53, s53, 0xffff
	s_mov_b32 s54, s6
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
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[0:3], v[68:71], v[62:65], 0
	ds_read_b128 v[62:65], v48
	s_mov_b32 s55, s7
	v_mov_b32_e32 v48, 0x42800000
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[0:3], v[72:75], v[84:87], v[0:3]
	s_and_b32 s9, s9, 0xffff
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[0:3], v[76:79], v[88:91], v[0:3]
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[0:3], v[62:65], v[92:95], v[0:3]
	s_nop 7
	v_mul_f32_e32 v0, s33, v0
	v_mul_f32_e32 v1, s33, v1
	v_cndmask_b32_e32 v0, v53, v0, vcc
	s_and_b64 vcc, s[48:49], s[2:3]
	v_mul_f32_e32 v2, s33, v2
	v_cndmask_b32_e32 v1, v53, v1, vcc
	s_and_b64 vcc, s[48:49], s[4:5]
	v_mul_f32_e32 v3, s33, v3
	v_cndmask_b32_e32 v2, v53, v2, vcc
	s_and_b64 vcc, s[48:49], s[10:11]
	v_cndmask_b32_e32 v3, v53, v3, vcc
.Ltmp59:
	v_max3_f32 v4, v0, v1, v2
	v_max3_f32 v4, v4, v3, s19
.Ltmp60:
	v_mov_b32_e32 v5, v4
	s_nop 1
	v_permlane32_swap_b32_e32 v4, v5
.Ltmp61:
	v_max_f32_e32 v46, v5, v5
	v_max_f32_e32 v47, v4, v4
.Ltmp62:
	buffer_load_dwordx4 v[4:7], v8, s[52:55], 0 offen
	buffer_load_dwordx4 v[50:53], v56, s[52:55], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[56:59], v54, s[52:55], 0 offen
	buffer_load_dwordx4 v[62:65], v66, s[52:55], 0 offen
.Ltmp63:
	v_max_f32_e32 v8, v47, v46
.Ltmp64:
	v_mov_b32_e32 v46, v8
	s_nop 1
	v_permlane16_swap_b32_e32 v8, v46
.Ltmp65:
	v_max_f32_e32 v46, v46, v46
	v_max_f32_e32 v8, v8, v8
	v_max_f32_e32 v8, v8, v46
.Ltmp66:
	v_mov_b32_e32 v46, 0xe0ad78ec
	v_cmp_neq_f32_e32 vcc, s19, v8
	s_mov_b32 s2, 0xc2fc0000
	s_movk_i32 s3, 0x78
	v_cndmask_b32_e32 v8, v46, v8, vcc
	v_max_f32_e32 v46, v60, v60
	v_max_f32_e32 v46, v8, v46
	v_sub_f32_e32 v8, v60, v46
	v_mul_f32_e32 v47, 0x3fb8aa3b, v8
	v_cmp_gt_f32_e32 vcc, s2, v47
	v_sub_f32_e32 v0, v0, v46
	v_sub_f32_e32 v1, v1, v46
	v_cndmask_b32_e32 v47, 0, v48, vcc
	v_fmac_f32_e32 v47, 0x3fb8aa3b, v8
	v_exp_f32_e32 v8, v47
	v_not_b32_e32 v47, 63
	v_cndmask_b32_e32 v54, 0, v47, vcc
	v_sub_f32_e32 v2, v2, v46
	v_ldexp_f32 v8, v8, v54
	v_mul_f32_e32 v54, 0x3fb8aa3b, v0
	v_cmp_gt_f32_e32 vcc, s2, v54
	v_sub_f32_e32 v3, v3, v46
	v_sub_f32_e32 v46, 0xff800000, v46
	v_cndmask_b32_e32 v54, 0, v48, vcc
	v_fmac_f32_e32 v54, 0x3fb8aa3b, v0
	v_exp_f32_e32 v0, v54
	v_cndmask_b32_e32 v54, 0, v47, vcc
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	v_ldexp_f32 v0, v0, v54
	v_mul_f32_e32 v54, 0x3fb8aa3b, v1
	v_cmp_gt_f32_e32 vcc, s2, v54
	v_pk_mul_f32 v[12:13], v[12:13], v[8:9] op_sel_hi:[1,0]
	v_pk_mul_f32 v[10:11], v[10:11], v[8:9] op_sel_hi:[1,0]
	v_cndmask_b32_e32 v54, 0, v48, vcc
	v_fmac_f32_e32 v54, 0x3fb8aa3b, v1
	v_exp_f32_e32 v1, v54
	v_mul_f32_e32 v54, 0x3fb8aa3b, v2
	v_cmp_gt_f32_e64 s[0:1], s2, v54
	s_mov_b32 s10, s6
	s_mov_b32 s11, s7
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
	v_add_f32_e32 v46, v0, v1
	v_add_f32_e32 v46, v2, v46
	v_add_f32_e32 v46, v3, v46
	v_add_f32_e32 v46, v54, v46
	v_add_f32_e32 v46, v54, v46
.Ltmp68:
	v_cvt_pk_bf16_f32 v0, v0, v1
	v_cvt_pk_bf16_f32 v1, v2, v3
	v_bitop3_b32 v3, v49, v55, s3 bitop3:0x78
.Ltmp69:
	v_add_f32_e32 v60, v54, v46
.Ltmp70:
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
	v_cvt_pk_bf16_f32 v2, v54, v54
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
	v_mov_b32_e32 v3, v2
	v_pk_mul_f32 v[6:7], v[40:41], v[8:9] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[38:39], v[8:9] op_sel_hi:[1,0]
	v_mov_b32_e32 v46, v2
	v_mov_b32_e32 v47, v2
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_bf16 v[4:7], v[48:51], v[0:3], v[4:7]
	v_mov_b32_e32 v48, v2
	v_mov_b32_e32 v49, v2
	v_xad_u32 v45, v43, 64, 0
	ds_read_b64_tr_b16 v[50:51], v45 offset:8192
	ds_read_b64_tr_b16 v[52:53], v45 offset:12288
	s_waitcnt lgkmcnt(12)
	v_mfma_f32_16x16x32_bf16 v[38:41], v[62:65], v[46:49], v[4:7]
	s_nop 2
	v_mul_f32_e64 v6, v36, v8
	v_mul_f32_e64 v7, v37, v8
	v_pk_mul_f32 v[4:5], v[34:35], v[8:9] op_sel_hi:[1,0]
	v_xor_b32_e32 v34, 0x60, v43
	v_add_u32_e32 v43, 0, v34
	s_waitcnt lgkmcnt(8)
	v_mfma_f32_16x16x32_bf16 v[4:7], v[70:73], v[0:3], v[4:7]
	ds_read_b64_tr_b16 v[62:63], v45
	ds_read_b64_tr_b16 v[64:65], v45 offset:4096
	ds_read_b64_tr_b16 v[72:73], v45 offset:4224
	ds_read_b64_tr_b16 v[70:71], v45 offset:128
	s_waitcnt lgkmcnt(8)
	v_mfma_f32_16x16x32_bf16 v[34:37], v[78:81], v[46:49], v[4:7]
	ds_read_b64_tr_b16 v[78:79], v43
	ds_read_b64_tr_b16 v[80:81], v43 offset:4096
	s_nop 0
	v_pk_mul_f32 v[6:7], v[32:33], v[8:9] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[30:31], v[8:9] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(4)
	s_nop 0
	v_mfma_f32_16x16x32_bf16 v[4:7], v[62:65], v[0:3], v[4:7]
	ds_read_b64_tr_b16 v[64:65], v45 offset:12416
	ds_read_b64_tr_b16 v[62:63], v45 offset:8320
	ds_read_b64_tr_b16 v[86:87], v43 offset:8192
	ds_read_b64_tr_b16 v[88:89], v43 offset:12288
.Ltmp71:
	v_add_f32_e32 v45, v54, v60
.Ltmp72:
	v_mfma_f32_16x16x32_bf16 v[30:33], v[50:53], v[46:49], v[4:7]
	ds_read_b64_tr_b16 v[52:53], v43 offset:4224
	ds_read_b64_tr_b16 v[50:51], v43 offset:128
	s_nop 0
	v_pk_mul_f32 v[6:7], v[28:29], v[8:9] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[26:27], v[8:9] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(6)
	s_nop 0
	v_mfma_f32_16x16x32_bf16 v[4:7], v[78:81], v[0:3], v[4:7]
	ds_read_b64_tr_b16 v[80:81], v43 offset:12416
	ds_read_b64_tr_b16 v[78:79], v43 offset:8320
.Ltmp73:
	v_add_f32_e32 v43, v54, v45
.Ltmp74:
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x32_bf16 v[26:29], v[86:89], v[46:49], v[4:7]
	s_nop 2
	v_mul_f32_e64 v6, v24, v8
	v_mul_f32_e64 v7, v25, v8
	v_pk_mul_f32 v[4:5], v[22:23], v[8:9] op_sel_hi:[1,0]
.Ltmp75:
	v_add_f32_e32 v22, v54, v43
	v_add_f32_e32 v22, v54, v22
.Ltmp76:
	v_mfma_f32_16x16x32_bf16 v[4:7], v[56:59], v[0:3], v[4:7]
.Ltmp77:
	v_add_f32_e32 v43, v54, v22
	v_add_f32_e32 v43, v54, v43
.Ltmp78:
	v_mfma_f32_16x16x32_bf16 v[22:25], v[66:69], v[46:49], v[4:7]
	s_nop 4
	v_mul_f32_e64 v6, v20, v8
	v_mul_f32_e64 v7, v21, v8
	v_pk_mul_f32 v[4:5], v[18:19], v[8:9] op_sel_hi:[1,0]
.Ltmp79:
	v_add_f32_e32 v18, v54, v43
	v_add_f32_e32 v18, v54, v18
.Ltmp80:
	v_mfma_f32_16x16x32_bf16 v[4:7], v[74:77], v[0:3], v[4:7]
.Ltmp81:
	v_add_f32_e32 v43, v54, v18
.Ltmp82:
	v_mov_b32_e32 v45, v43
	s_nop 1
	v_permlane32_swap_b32_e32 v43, v45
.Ltmp83:
	v_mfma_f32_16x16x32_bf16 v[18:21], v[82:85], v[46:49], v[4:7]
	s_nop 2
	v_mul_f32_e64 v4, v14, v8
	v_mul_f32_e64 v5, v15, v8
.Ltmp84:
	v_add_f32_e32 v14, v43, v45
.Ltmp85:
	v_mov_b32_e32 v15, v14
.Ltmp86:
	v_pk_mul_f32 v[6:7], v[16:17], v[8:9] op_sel_hi:[1,0]
.Ltmp87:
	s_nop 0
	v_permlane16_swap_b32_e32 v14, v15
.Ltmp88:
	v_mfma_f32_16x16x32_bf16 v[4:7], v[70:73], v[0:3], v[4:7]
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[0:3], v[50:53], v[0:3], v[10:13]
.Ltmp89:
	s_nop 2
	v_add_f32_e32 v13, v14, v15
.Ltmp90:
	v_fmac_f32_e32 v13, v61, v8
	v_div_scale_f32 v14, s[0:1], v13, v13, v38
	v_rcp_f32_e32 v15, v14
	v_mfma_f32_16x16x32_bf16 v[4:7], v[62:65], v[46:49], v[4:7]
	v_lshl_add_u32 v8, v44, 12, s18
	v_or_b32_e32 v12, 32, v42
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
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[0:3], v[78:81], v[46:49], v[0:3]
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
	v_or_b32_e32 v11, 64, v42
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
	v_or_b32_e32 v10, 0x60, v42
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
	v_cvt_pk_bf16_f32 v7, v28, v29
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
	v_cvt_pk_bf16_f32 v6, v26, v27
	v_fma_f32 v0, -v4, v5, 1.0
	v_fmac_f32_e32 v5, v0, v5
	v_div_scale_f32 v0, vcc, v3, v13, v3
	v_mul_f32_e32 v1, v0, v5
	v_fma_f32 v2, -v4, v1, v0
	v_fmac_f32_e32 v1, v2, v5
	v_fma_f32 v0, -v4, v1, v0
	v_div_fmas_f32 v0, v0, v5, v1
	v_div_fixup_f32 v13, v0, v13, v3
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
	s_endpgm
.Ltmp91:
	.endm
