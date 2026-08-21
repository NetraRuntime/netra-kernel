// SPDX-License-Identifier: MIT
// Fixed raw gfx950 GQA8 causal tail output stage.
	.macro NETRA_ATTENTION_GQA8_CAUSAL_TAIL_OUTPUT symbol
.LBB0_8:
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
	v_mov_b32_e32 v43, 0
	v_mov_b32_e32 v42, 0
	v_mov_b32_e32 v45, 0
	v_mov_b32_e32 v44, 0
	v_mov_b32_e32 v47, 0
	v_mov_b32_e32 v46, 0
	v_mov_b32_e32 v49, 0
	v_mov_b32_e32 v48, 0
	v_mov_b32_e32 v87, 0xff800000
	v_mov_b32_e32 v55, 0
.LBB0_9:                                ; %._crit_edge
	s_lshl_b32 s0, s63, 9
	v_lshlrev_b32_e32 v2, 9, v59
	s_add_i32 s0, s0, s65
	v_or_b32_e32 v4, v2, v56
	v_or_b32_e32 v2, v2, v60
	v_lshlrev_b32_e32 v3, 9, v58
	v_or_b32_e32 v5, s0, v56
	v_add_lshl_u32 v4, v4, s0, 1
	v_bfrev_b32_e32 v16, 1
	v_cmp_gt_i32_e32 vcc, s57, v59
	v_add_lshl_u32 v2, v2, s0, 1
	v_or_b32_e32 v6, s0, v60
	v_cndmask_b32_e32 v12, v16, v4, vcc
	v_cndmask_b32_e32 v17, v16, v2, vcc
	v_add_lshl_u32 v2, v5, v3, 1
	v_cmp_gt_i32_e32 vcc, s57, v58
	s_and_b32 s5, s5, 0xffff
	s_mov_b32 s7, 0x27000
	s_mov_b32 s6, 0x7ffffffe
	v_cndmask_b32_e32 v13, v16, v2, vcc
	v_add_lshl_u32 v2, v6, v3, 1
	buffer_load_dwordx4 v[64:67], v12, s[4:7], 0 offen
	buffer_load_dwordx4 v[68:71], v17, s[4:7], 0 offen
	v_cndmask_b32_e32 v58, v16, v2, vcc
	buffer_load_dwordx4 v[72:75], v13, s[4:7], 0 offen
	buffer_load_dwordx4 v[76:79], v58, s[4:7], 0 offen
	v_or_b32_e32 v3, s64, v56
	v_xor_b32_e32 v2, v50, v62
	v_bitop3_b32 v4, s64, v53, v56 bitop3:0x36
	s_movk_i32 s4, 0x80
	s_movk_i32 s5, 0xc0
	v_bitop3_b32 v5, v63, v53, v56 bitop3:0x36
	v_bitop3_b32 v3, v3, v63, v53 bitop3:0xde
	v_add_u32_e32 v11, 0, v2
	v_bitop3_b32 v14, v4, s4, v63 bitop3:0x36
	v_bitop3_b32 v4, v4, s5, v63 bitop3:0x36
	v_add_u32_e32 v15, 0, v5
	v_add_u32_e32 v56, 0, v3
	v_xad_u32 v2, v2, 16, 0
	v_xad_u32 v3, v3, 64, 0
	v_add_u32_e32 v14, 0, v14
	v_add_u32_e32 v4, 0, v4
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_write_b128 v11, v[96:99]
	ds_write_b128 v11, v[104:107] offset:16384
	ds_write_b128 v2, v[92:95]
	ds_write_b128 v2, v[100:103] offset:16384
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b128 v[80:83], v56
	ds_read_b128 v[88:91], v56 offset:256
	ds_read_b128 v[92:95], v3
	ds_read_b128 v[96:99], v3 offset:256
	ds_read_b128 v[100:103], v14
	ds_read_b128 v[104:107], v14 offset:256
	ds_read_b128 v[108:111], v4
	ds_read_b128 v[112:115], v4 offset:256
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	v_xor_b32_e32 v14, 0xc0, v5
	v_or_b32_e32 v6, 1, v61
	v_or_b32_e32 v7, 2, v61
	v_or_b32_e32 v8, 3, v61
	v_cmp_gt_i32_e32 vcc, s57, v61
	v_cmp_ge_u32_e64 s[0:1], v1, v61
	v_cmp_gt_u32_e64 s[4:5], v1, v61
	v_add_u32_e32 v14, 0, v14
	v_cmp_gt_i32_e64 s[10:11], s57, v6
	s_and_b64 s[0:1], s[0:1], vcc
	v_cmp_gt_i32_e64 s[12:13], s57, v7
	v_cmp_ge_u32_e64 s[16:17], v1, v7
	s_and_b64 s[4:5], s[4:5], s[10:11]
	s_and_b64 vcc, s[2:3], s[0:1]
	v_cmp_gt_i32_e64 s[14:15], s57, v8
	v_cmp_ge_u32_e64 s[18:19], v1, v8
	s_and_b64 s[10:11], s[16:17], s[12:13]
	s_and_b64 s[12:13], s[18:19], s[14:15]
	s_mov_b32 s20, 0xff800000
	v_lshrrev_b32_e32 v9, 2, v57
	v_lshlrev_b32_e32 v10, 12, v1
	v_not_b32_e32 v57, 63
	s_and_b32 s41, s41, 0xffff
	s_mov_b32 s42, s6
	s_mov_b32 s43, s7
	v_lshlrev_b32_e32 v1, 1, v1
	v_lshl_or_b32 v1, v53, 5, v1
	v_and_b32_e32 v51, 24, v51
	s_and_b32 s9, s9, 0xffff
	s_waitcnt vmcnt(3)
	ds_write_b128 v11, v[64:67]
	s_waitcnt vmcnt(2)
	ds_write_b128 v2, v[68:71]
	s_waitcnt vmcnt(1)
	ds_write_b128 v11, v[72:75] offset:16384
	NETRA_WAIT_VM0
	ds_write_b128 v2, v[76:79] offset:16384
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b128 v[62:65], v15
	v_xad_u32 v11, v5, 64, 0
	ds_read_b128 v[66:69], v11
	v_xor_b32_e32 v2, 0x80, v5
	v_add_u32_e32 v56, 0, v2
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[62:65], v[80:83], 0
	ds_read_b128 v[70:73], v15 offset:256
	ds_read_b128 v[74:77], v56
	ds_read_b128 v[60:63], v11 offset:256
	ds_read_b128 v[78:81], v14
	v_mov_b32_e32 v11, 0xff800000
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[66:69], v[92:95], v[2:5]
	ds_read_b128 v[64:67], v56 offset:256
	v_mov_b32_e32 v15, 0xe0ad78ec
	v_and_b32_e32 v68, 28, v9
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[74:77], v[100:103], v[2:5]
	ds_read_b128 v[74:77], v14 offset:256
	v_max_f32_e32 v56, v87, v87
	v_lshl_or_b32 v69, s55, 1, v10
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[78:81], v[108:111], v[2:5]
	v_add_u32_e32 v6, s33, v69
	v_mfma_f32_16x16x32_bf16 v[2:5], v[70:73], v[88:91], v[2:5]
	v_or_b32_e32 v70, v68, v6
	v_mfma_f32_16x16x32_bf16 v[2:5], v[60:63], v[96:99], v[2:5]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[2:5], v[64:67], v[104:107], v[2:5]
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[2:5], v[74:77], v[112:115], v[2:5]
	s_nop 7
	v_mul_f32_e32 v2, s62, v2
	v_mul_f32_e32 v3, s62, v3
	v_cndmask_b32_e32 v2, v11, v2, vcc
	s_and_b64 vcc, s[2:3], s[4:5]
	v_mul_f32_e32 v4, s62, v4
	v_cndmask_b32_e32 v3, v11, v3, vcc
	s_and_b64 vcc, s[2:3], s[10:11]
	v_mul_f32_e32 v5, s62, v5
	v_cndmask_b32_e32 v4, v11, v4, vcc
	s_and_b64 vcc, s[2:3], s[12:13]
	v_cndmask_b32_e32 v5, v11, v5, vcc
.Ltmp62:
	v_max3_f32 v7, v2, v3, v4
	v_max3_f32 v7, v7, v5, s20
.Ltmp63:
	v_mov_b32_e32 v8, v7
	s_nop 1
	v_permlane32_swap_b32_e32 v7, v8
.Ltmp64:
	v_max_f32_e32 v8, v8, v8
	v_max_f32_e32 v7, v7, v7
	v_max_f32_e32 v7, v7, v8
.Ltmp65:
	v_mov_b32_e32 v8, v7
	s_nop 1
	v_permlane16_swap_b32_e32 v7, v8
.Ltmp66:
	v_max_f32_e32 v8, v8, v8
	v_max_f32_e32 v7, v7, v7
	v_max_f32_e32 v7, v7, v8
.Ltmp67:
	v_cmp_neq_f32_e32 vcc, s20, v7
	s_mov_b32 s4, 0xc2fc0000
	s_mov_b32 s10, s6
	v_cndmask_b32_e32 v7, v15, v7, vcc
	v_max_f32_e32 v7, v7, v56
	v_sub_f32_e32 v8, v87, v7
	v_mul_f32_e32 v9, 0x3fb8aa3b, v8
	v_mov_b32_e32 v56, 0x42800000
	v_cmp_gt_f32_e32 vcc, s4, v9
	v_sub_f32_e32 v2, v2, v7
	v_sub_f32_e32 v3, v3, v7
	v_cndmask_b32_e32 v9, 0, v56, vcc
	v_fmac_f32_e32 v9, 0x3fb8aa3b, v8
	v_exp_f32_e32 v8, v9
	v_cndmask_b32_e32 v6, 0, v57, vcc
	v_sub_f32_e32 v59, v5, v7
	v_sub_f32_e32 v4, v4, v7
	v_ldexp_f32 v71, v8, v6
	v_mul_f32_e32 v6, 0x3fb8aa3b, v2
	v_cmp_gt_f32_e32 vcc, s4, v6
	v_sub_f32_e32 v60, 0xff800000, v7
	s_mov_b32 s11, s7
	v_cndmask_b32_e32 v6, 0, v56, vcc
	v_fmac_f32_e32 v6, 0x3fb8aa3b, v2
	v_exp_f32_e32 v2, v6
	v_cndmask_b32_e32 v5, 0, v57, vcc
	v_ldexp_f32 v61, v2, v5
	v_mul_f32_e32 v2, 0x3fb8aa3b, v3
	v_cmp_gt_f32_e32 vcc, s4, v2
	s_nop 1
	v_cndmask_b32_e32 v2, 0, v56, vcc
	v_fmac_f32_e32 v2, 0x3fb8aa3b, v3
	v_exp_f32_e32 v2, v2
	v_mul_f32_e32 v3, 0x3fb8aa3b, v4
	v_cmp_gt_f32_e64 s[0:1], s4, v3
	s_nop 1
	v_cndmask_b32_e64 v3, 0, v56, s[0:1]
	v_fmac_f32_e32 v3, 0x3fb8aa3b, v4
	v_cndmask_b32_e32 v4, 0, v57, vcc
	v_ldexp_f32 v62, v2, v4
	buffer_load_dwordx4 v[4:7], v12, s[40:43], 0 offen
	buffer_load_dwordx4 v[8:11], v13, s[40:43], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[12:15], v17, s[40:43], 0 offen
	buffer_load_dwordx4 v[64:67], v58, s[40:43], 0 offen
	v_exp_f32_e32 v3, v3
	v_cndmask_b32_e64 v2, 0, v57, s[0:1]
	v_mul_f32_e32 v17, 0x3fb8aa3b, v60
	v_cmp_gt_f32_e64 s[0:1], s4, v17
	v_ldexp_f32 v3, v3, v2
	v_mul_f32_e32 v2, 0x3fb8aa3b, v59
	v_cmp_gt_f32_e32 vcc, s4, v2
	v_cndmask_b32_e64 v17, 0, v56, s[0:1]
	v_fmac_f32_e32 v17, 0x3fb8aa3b, v60
	v_cndmask_b32_e32 v2, 0, v56, vcc
	v_fmac_f32_e32 v2, 0x3fb8aa3b, v59
	v_exp_f32_e32 v2, v2
	v_cndmask_b32_e32 v56, 0, v57, vcc
	v_exp_f32_e32 v17, v17
	NETRA_WAIT_LGKM0
	v_ldexp_f32 v56, v2, v56
	v_cndmask_b32_e64 v2, 0, v57, s[0:1]
	s_add_i32 s0, s59, 0
	s_add_i32 s0, s0, s60
	v_add_u32_e32 v73, s0, v54
	s_add_i32 s0, s58, 0
	s_add_i32 s0, s0, s61
	v_add_u32_e32 v54, s0, v54
	s_lshr_b32 s0, s54, 1
	v_ldexp_f32 v17, v17, v2
.Ltmp68:
	v_add_f32_e32 v2, v61, v62
.Ltmp69:
	v_bitop3_b32 v1, s0, v53, v1 bitop3:0x36
.Ltmp70:
	v_add_f32_e32 v2, v3, v2
.Ltmp71:
	v_add_u32_e32 v53, 0, v1
	v_cvt_pk_bf16_f32 v57, v61, s0
.Ltmp72:
	v_add_f32_e32 v72, v56, v2
.Ltmp73:
	NETRA_BARRIER
	ds_write_b32 v73, v71
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b32 v2, v54
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_write_b16 v53, v57
	v_cvt_pk_bf16_f32 v57, v62, s0
	v_xad_u32 v1, v1, 8, 0
	v_cvt_pk_bf16_f32 v3, v3, s0
	ds_write_b16 v53, v57 offset:128
	v_cvt_pk_bf16_f32 v57, v17, s0
	ds_write_b16 v1, v3 offset:256
	v_cvt_pk_bf16_f32 v3, v56, s0
	ds_write_b16 v53, v57 offset:2048
	ds_write_b16 v53, v57 offset:2176
	ds_write_b16 v53, v57 offset:4096
	ds_write_b16 v53, v57 offset:4224
	ds_write_b16 v53, v57 offset:6144
	ds_write_b16 v53, v57 offset:6272
	ds_write_b16 v1, v3 offset:384
	ds_write_b16 v1, v57 offset:2304
	ds_write_b16 v1, v57 offset:2432
	ds_write_b16 v1, v57 offset:4352
	ds_write_b16 v1, v57 offset:4480
	ds_write_b16 v1, v57 offset:6400
	ds_write_b16 v1, v57 offset:6528
	v_and_b32_e32 v1, 60, v0
	v_lshlrev_b32_e32 v3, 5, v1
	v_and_b32_e32 v0, 56, v0
	s_lshr_b32 s0, s55, 2
	v_bitop3_b32 v0, v3, v0, v51 bitop3:0x36
	v_xor_b32_e32 v0, s0, v0
	v_add_u32_e32 v0, 0, v0
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b64_tr_b16 v[60:61], v0
	ds_read_b64_tr_b16 v[62:63], v0 offset:2048
	ds_read_b64_tr_b16 v[56:57], v0 offset:4096
	ds_read_b64_tr_b16 v[58:59], v0 offset:6144
	v_xor_b32_e32 v0, v52, v50
	v_add_u32_e32 v3, 0, v0
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	s_lshr_b32 s0, s56, 1
	s_waitcnt vmcnt(2)
	ds_write2st64_b64 v3, v[4:5], v[8:9] offset1:32
	v_xad_u32 v3, v0, 8, 0
	ds_write2st64_b64 v3, v[6:7], v[10:11] offset1:32
	v_xad_u32 v3, v0, 16, 0
	v_xad_u32 v0, v0, 24, 0
	NETRA_WAIT_VM0
	ds_write2st64_b64 v3, v[12:13], v[64:65] offset1:32
	ds_write2st64_b64 v0, v[14:15], v[66:67] offset1:32
	v_lshlrev_b32_e32 v0, 7, v1
	v_lshlrev_b32_e32 v1, 1, v1
	v_bitop3_b32 v0, v0, v1, v51 bitop3:0x36
	v_xor_b32_e32 v0, s0, v0
	v_add_u32_e32 v1, 0, v0
	v_pk_mul_f32 v[6:7], v[48:49], v[2:3] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[46:47], v[2:3] op_sel_hi:[1,0]
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b64_tr_b16 v[8:9], v1
	ds_read_b64_tr_b16 v[12:13], v1 offset:128
	ds_read_b64_tr_b16 v[50:51], v1 offset:256
	ds_read_b64_tr_b16 v[64:65], v1 offset:384
	ds_read_b64_tr_b16 v[10:11], v1 offset:8192
	ds_read_b64_tr_b16 v[14:15], v1 offset:8320
	ds_read_b64_tr_b16 v[52:53], v1 offset:8448
	ds_read_b64_tr_b16 v[66:67], v1 offset:8576
	ds_read_b64_tr_b16 v[74:75], v1 offset:16384
	ds_read_b64_tr_b16 v[78:79], v1 offset:16512
	ds_read_b64_tr_b16 v[82:83], v1 offset:16640
	ds_read_b64_tr_b16 v[86:87], v1 offset:16768
	ds_read_b64_tr_b16 v[76:77], v1 offset:24576
	ds_read_b64_tr_b16 v[80:81], v1 offset:24704
	ds_read_b64_tr_b16 v[84:85], v1 offset:24832
	ds_read_b64_tr_b16 v[88:89], v1 offset:24960
	s_waitcnt lgkmcnt(11)
	v_mfma_f32_16x16x32_bf16 v[4:7], v[8:11], v[60:63], v[4:7]
	v_xad_u32 v0, v0, 64, 0
	ds_read_b64_tr_b16 v[92:93], v0 offset:24576
	ds_read_b64_tr_b16 v[94:95], v0
	ds_read_b64_tr_b16 v[98:99], v0 offset:128
	ds_read_b64_tr_b16 v[102:103], v0 offset:256
	ds_read_b64_tr_b16 v[106:107], v0 offset:384
	ds_read_b64_tr_b16 v[96:97], v0 offset:8192
	ds_read_b64_tr_b16 v[100:101], v0 offset:8320
	ds_read_b64_tr_b16 v[104:105], v0 offset:8448
	ds_read_b64_tr_b16 v[108:109], v0 offset:8576
	s_waitcnt lgkmcnt(12)
	v_mfma_f32_16x16x32_bf16 v[46:49], v[74:77], v[56:59], v[4:7]
	ds_read_b64_tr_b16 v[90:91], v0 offset:16384
	ds_read_b64_tr_b16 v[8:9], v0 offset:16512
	ds_read_b64_tr_b16 v[74:75], v0 offset:16640
	ds_read_b64_tr_b16 v[110:111], v0 offset:16768
	v_pk_mul_f32 v[6:7], v[44:45], v[2:3] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[42:43], v[2:3] op_sel_hi:[1,0]
	ds_read_b64_tr_b16 v[10:11], v0 offset:24704
	ds_read_b64_tr_b16 v[76:77], v0 offset:24832
	ds_read_b64_tr_b16 v[112:113], v0 offset:24960
	s_waitcnt lgkmcnt(10)
	v_mfma_f32_16x16x32_bf16 v[4:7], v[94:97], v[60:63], v[4:7]
.Ltmp74:
	v_add_f32_e32 v0, v17, v72
	v_add_f32_e32 v0, v17, v0
	v_add_f32_e32 v0, v17, v0
.Ltmp75:
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[42:45], v[90:93], v[56:59], v[4:7]
.Ltmp76:
	v_add_f32_e32 v0, v17, v0
	v_add_f32_e32 v0, v17, v0
	v_add_f32_e32 v0, v17, v0
.Ltmp77:
	v_pk_mul_f32 v[6:7], v[40:41], v[2:3] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[38:39], v[2:3] op_sel_hi:[1,0]
.Ltmp78:
	v_add_f32_e32 v0, v17, v0
	v_add_f32_e32 v0, v17, v0
.Ltmp79:
	v_mfma_f32_16x16x32_bf16 v[4:7], v[12:15], v[60:63], v[4:7]
.Ltmp80:
	v_add_f32_e32 v0, v17, v0
	v_add_f32_e32 v0, v17, v0
	v_add_f32_e32 v0, v17, v0
.Ltmp81:
	v_mfma_f32_16x16x32_bf16 v[38:41], v[78:81], v[56:59], v[4:7]
.Ltmp82:
	v_add_f32_e32 v0, v17, v0
.Ltmp83:
	v_mov_b32_e32 v1, v0
	s_nop 1
	v_permlane32_swap_b32_e32 v0, v1
.Ltmp84:
	v_pk_mul_f32 v[6:7], v[36:37], v[2:3] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[34:35], v[2:3] op_sel_hi:[1,0]
.Ltmp85:
	v_add_f32_e32 v0, v0, v1
.Ltmp86:
	v_mov_b32_e32 v1, v0
.Ltmp87:
	v_mfma_f32_16x16x32_bf16 v[4:7], v[98:101], v[60:63], v[4:7]
.Ltmp88:
	s_nop 0
	v_permlane16_swap_b32_e32 v0, v1
.Ltmp89:
	v_add_f32_e32 v0, v0, v1
.Ltmp90:
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[34:37], v[8:11], v[56:59], v[4:7]
	v_fmac_f32_e32 v0, v55, v71
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	v_pk_mul_f32 v[6:7], v[32:33], v[2:3] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[30:31], v[2:3] op_sel_hi:[1,0]
	ds_write_b32 v73, v0
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[4:7], v[50:53], v[60:63], v[4:7]
	NETRA_BARRIER
	v_pk_mul_f32 v[20:21], v[20:21], v[2:3] op_sel_hi:[1,0]
	v_mfma_f32_16x16x32_bf16 v[12:15], v[82:85], v[56:59], v[4:7]
	v_mul_f32_e64 v18, v18, v2
	v_mul_f32_e64 v19, v19, v2
	v_lshlrev_b32_e32 v17, 1, v70
	s_nop 1
	v_pk_mul_f32 v[6:7], v[28:29], v[2:3] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[26:27], v[2:3] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[4:7], v[102:105], v[60:63], v[4:7]
	v_mfma_f32_16x16x32_bf16 v[8:11], v[74:77], v[56:59], v[4:7]
	s_nop 6
	v_mul_f32_e64 v4, v22, v2
	v_mul_f32_e64 v5, v23, v2
	ds_read_b32 v22, v54
	v_pk_mul_f32 v[6:7], v[24:25], v[2:3] op_sel_hi:[1,0]
	v_mfma_f32_16x16x32_bf16 v[0:3], v[106:109], v[60:63], v[18:21]
	NETRA_WAIT_LGKM0
	s_nop 1
	v_div_scale_f32 v19, s[0:1], v22, v22, v46
	v_rcp_f32_e32 v20, v19
	v_mfma_f32_16x16x32_bf16 v[4:7], v[64:67], v[60:63], v[4:7]
	v_or_b32_e32 v18, v68, v69
	v_add_lshl_u32 v18, v18, s33, 1
	v_fma_f32 v21, -v19, v20, 1.0
	v_fmac_f32_e32 v20, v21, v20
	v_div_scale_f32 v21, vcc, v46, v22, v46
	v_mul_f32_e32 v23, v21, v20
	v_fma_f32 v24, -v19, v23, v21
	v_fmac_f32_e32 v23, v24, v20
	v_fma_f32 v19, -v19, v23, v21
	v_div_scale_f32 v21, s[0:1], v22, v22, v47
	v_rcp_f32_e32 v24, v21
	v_div_fmas_f32 v19, v19, v20, v23
	v_mfma_f32_16x16x32_bf16 v[4:7], v[86:89], v[56:59], v[4:7]
	v_div_fixup_f32 v19, v19, v22, v46
	v_fma_f32 v20, -v21, v24, 1.0
	v_fmac_f32_e32 v24, v20, v24
	v_div_scale_f32 v20, vcc, v47, v22, v47
	v_mul_f32_e32 v23, v20, v24
	v_fma_f32 v25, -v21, v23, v20
	v_fmac_f32_e32 v23, v25, v24
	v_fma_f32 v20, -v21, v23, v20
	v_div_scale_f32 v21, s[0:1], v22, v22, v48
	v_rcp_f32_e32 v25, v21
	v_div_fmas_f32 v20, v20, v24, v23
	v_mfma_f32_16x16x32_bf16 v[0:3], v[110:113], v[56:59], v[0:3]
	v_div_fixup_f32 v20, v20, v22, v47
	v_fma_f32 v23, -v21, v25, 1.0
	v_fmac_f32_e32 v25, v23, v25
	v_div_scale_f32 v23, vcc, v48, v22, v48
	v_mul_f32_e32 v24, v23, v25
	v_fma_f32 v26, -v21, v24, v23
	v_fmac_f32_e32 v24, v26, v25
	v_fma_f32 v21, -v21, v24, v23
	v_div_scale_f32 v23, s[0:1], v22, v22, v49
	v_rcp_f32_e32 v26, v23
	v_div_fmas_f32 v21, v21, v25, v24
	v_div_fixup_f32 v21, v21, v22, v48
	v_cndmask_b32_e64 v18, v16, v18, s[2:3]
	v_fma_f32 v24, -v23, v26, 1.0
	v_fmac_f32_e32 v26, v24, v26
	v_div_scale_f32 v24, vcc, v49, v22, v49
	v_mul_f32_e32 v25, v24, v26
	v_fma_f32 v27, -v23, v25, v24
	v_fmac_f32_e32 v25, v27, v26
	v_fma_f32 v23, -v23, v25, v24
	v_div_scale_f32 v24, s[0:1], v22, v22, v42
	v_rcp_f32_e32 v27, v24
	v_div_fmas_f32 v23, v23, v26, v25
	v_div_fixup_f32 v23, v23, v22, v49
	v_fma_f32 v25, -v24, v27, 1.0
	v_fmac_f32_e32 v27, v25, v27
	v_div_scale_f32 v25, vcc, v42, v22, v42
	v_mul_f32_e32 v26, v25, v27
	v_fma_f32 v28, -v24, v26, v25
	v_fmac_f32_e32 v26, v28, v27
	v_fma_f32 v24, -v24, v26, v25
	v_div_scale_f32 v25, s[0:1], v22, v22, v43
	v_rcp_f32_e32 v28, v25
	v_div_fmas_f32 v24, v24, v27, v26
	v_div_fixup_f32 v24, v24, v22, v42
	v_fma_f32 v26, -v25, v28, 1.0
	v_fmac_f32_e32 v28, v26, v28
	v_div_scale_f32 v26, vcc, v43, v22, v43
	v_mul_f32_e32 v27, v26, v28
	v_fma_f32 v29, -v25, v27, v26
	v_fmac_f32_e32 v27, v29, v28
	v_fma_f32 v25, -v25, v27, v26
	v_div_scale_f32 v26, s[0:1], v22, v22, v44
	v_rcp_f32_e32 v29, v26
	v_div_fmas_f32 v25, v25, v28, v27
	v_div_fixup_f32 v25, v25, v22, v43
	v_fma_f32 v27, -v26, v29, 1.0
	v_fmac_f32_e32 v29, v27, v29
	v_div_scale_f32 v27, vcc, v44, v22, v44
	v_mul_f32_e32 v28, v27, v29
	v_fma_f32 v30, -v26, v28, v27
	v_fmac_f32_e32 v28, v30, v29
	v_fma_f32 v26, -v26, v28, v27
	v_div_scale_f32 v27, s[0:1], v22, v22, v45
	v_rcp_f32_e32 v30, v27
	v_div_fmas_f32 v26, v26, v29, v28
	v_div_fixup_f32 v26, v26, v22, v44
	v_fma_f32 v28, -v27, v30, 1.0
	v_fmac_f32_e32 v30, v28, v30
	v_div_scale_f32 v28, vcc, v45, v22, v45
	v_mul_f32_e32 v29, v28, v30
	v_fma_f32 v31, -v27, v29, v28
	v_fmac_f32_e32 v29, v31, v30
	v_fma_f32 v27, -v27, v29, v28
	v_div_scale_f32 v28, s[0:1], v22, v22, v38
	v_rcp_f32_e32 v31, v28
	v_div_fmas_f32 v27, v27, v30, v29
	v_div_fixup_f32 v27, v27, v22, v45
	v_fma_f32 v29, -v28, v31, 1.0
	v_fmac_f32_e32 v31, v29, v31
	v_div_scale_f32 v29, vcc, v38, v22, v38
	v_mul_f32_e32 v30, v29, v31
	v_fma_f32 v32, -v28, v30, v29
	v_fmac_f32_e32 v30, v32, v31
	v_fma_f32 v28, -v28, v30, v29
	v_div_scale_f32 v29, s[0:1], v22, v22, v39
	v_rcp_f32_e32 v32, v29
	v_div_fmas_f32 v28, v28, v31, v30
	v_div_fixup_f32 v28, v28, v22, v38
	v_fma_f32 v30, -v29, v32, 1.0
	v_fmac_f32_e32 v32, v30, v32
	v_div_scale_f32 v30, vcc, v39, v22, v39
	v_mul_f32_e32 v31, v30, v32
	v_fma_f32 v33, -v29, v31, v30
	v_fmac_f32_e32 v31, v33, v32
	v_fma_f32 v29, -v29, v31, v30
	v_div_scale_f32 v30, s[0:1], v22, v22, v40
	v_rcp_f32_e32 v33, v30
	v_div_fmas_f32 v29, v29, v32, v31
	v_div_fixup_f32 v29, v29, v22, v39
	v_fma_f32 v31, -v30, v33, 1.0
	v_fmac_f32_e32 v33, v31, v33
	v_div_scale_f32 v31, vcc, v40, v22, v40
	v_mul_f32_e32 v32, v31, v33
	v_fma_f32 v38, -v30, v32, v31
	v_fmac_f32_e32 v32, v38, v33
	v_fma_f32 v30, -v30, v32, v31
	v_div_scale_f32 v31, s[0:1], v22, v22, v41
	v_rcp_f32_e32 v38, v31
	v_div_fmas_f32 v30, v30, v33, v32
	v_div_fixup_f32 v30, v30, v22, v40
	v_fma_f32 v32, -v31, v38, 1.0
	v_fmac_f32_e32 v38, v32, v38
	v_div_scale_f32 v32, vcc, v41, v22, v41
	v_mul_f32_e32 v33, v32, v38
	v_fma_f32 v39, -v31, v33, v32
	v_fmac_f32_e32 v33, v39, v38
	v_fma_f32 v31, -v31, v33, v32
	v_div_scale_f32 v32, s[0:1], v22, v22, v34
	v_rcp_f32_e32 v39, v32
	v_div_fmas_f32 v31, v31, v38, v33
	v_div_fixup_f32 v31, v31, v22, v41
	v_fma_f32 v33, -v32, v39, 1.0
	v_fmac_f32_e32 v39, v33, v39
	v_div_scale_f32 v33, vcc, v34, v22, v34
	v_mul_f32_e32 v38, v33, v39
	v_fma_f32 v40, -v32, v38, v33
	v_fmac_f32_e32 v38, v40, v39
	v_fma_f32 v32, -v32, v38, v33
	v_div_scale_f32 v33, s[0:1], v22, v22, v35
	v_rcp_f32_e32 v40, v33
	v_div_fmas_f32 v32, v32, v39, v38
	v_div_fixup_f32 v32, v32, v22, v34
	v_fma_f32 v34, -v33, v40, 1.0
	v_fmac_f32_e32 v40, v34, v40
	v_div_scale_f32 v34, vcc, v35, v22, v35
	v_mul_f32_e32 v38, v34, v40
	v_fma_f32 v39, -v33, v38, v34
	v_fmac_f32_e32 v38, v39, v40
	v_fma_f32 v33, -v33, v38, v34
	v_div_scale_f32 v34, s[0:1], v22, v22, v36
	v_rcp_f32_e32 v39, v34
	v_div_fmas_f32 v33, v33, v40, v38
	v_div_fixup_f32 v33, v33, v22, v35
	v_fma_f32 v35, -v34, v39, 1.0
	v_fmac_f32_e32 v39, v35, v39
	v_div_scale_f32 v35, vcc, v36, v22, v36
	v_mul_f32_e32 v38, v35, v39
	v_fma_f32 v40, -v34, v38, v35
	v_fmac_f32_e32 v38, v40, v39
	v_fma_f32 v34, -v34, v38, v35
	v_div_scale_f32 v35, s[0:1], v22, v22, v37
	v_rcp_f32_e32 v40, v35
	v_div_fmas_f32 v34, v34, v39, v38
	v_div_fixup_f32 v34, v34, v22, v36
	v_fma_f32 v36, -v35, v40, 1.0
	v_fmac_f32_e32 v40, v36, v40
	v_div_scale_f32 v36, vcc, v37, v22, v37
	v_mul_f32_e32 v38, v36, v40
	v_fma_f32 v39, -v35, v38, v36
	v_fmac_f32_e32 v38, v39, v40
	v_fma_f32 v35, -v35, v38, v36
	v_div_scale_f32 v36, s[0:1], v22, v22, v12
	v_rcp_f32_e32 v39, v36
	v_div_fmas_f32 v35, v35, v40, v38
	v_div_fixup_f32 v35, v35, v22, v37
	v_fma_f32 v37, -v36, v39, 1.0
	v_fmac_f32_e32 v39, v37, v39
	v_div_scale_f32 v37, vcc, v12, v22, v12
	v_mul_f32_e32 v38, v37, v39
	v_fma_f32 v40, -v36, v38, v37
	v_fmac_f32_e32 v38, v40, v39
	v_fma_f32 v36, -v36, v38, v37
	v_div_scale_f32 v37, s[0:1], v22, v22, v13
	v_rcp_f32_e32 v40, v37
	v_div_fmas_f32 v36, v36, v39, v38
	v_div_fixup_f32 v12, v36, v22, v12
	v_fma_f32 v36, -v37, v40, 1.0
	v_fmac_f32_e32 v40, v36, v40
	v_div_scale_f32 v36, vcc, v13, v22, v13
	v_mul_f32_e32 v38, v36, v40
	v_fma_f32 v39, -v37, v38, v36
	v_fmac_f32_e32 v38, v39, v40
	v_fma_f32 v36, -v37, v38, v36
	v_div_scale_f32 v37, s[0:1], v22, v22, v14
	v_rcp_f32_e32 v39, v37
	v_div_fmas_f32 v36, v36, v40, v38
	v_div_fixup_f32 v13, v36, v22, v13
	v_fma_f32 v36, -v37, v39, 1.0
	v_fmac_f32_e32 v39, v36, v39
	v_div_scale_f32 v36, vcc, v14, v22, v14
	v_mul_f32_e32 v38, v36, v39
	v_fma_f32 v40, -v37, v38, v36
	v_fmac_f32_e32 v38, v40, v39
	v_fma_f32 v36, -v37, v38, v36
	v_div_scale_f32 v37, s[0:1], v22, v22, v15
	v_rcp_f32_e32 v40, v37
	v_div_fmas_f32 v36, v36, v39, v38
	v_div_fixup_f32 v14, v36, v22, v14
	v_fma_f32 v36, -v37, v40, 1.0
	v_fmac_f32_e32 v40, v36, v40
	v_div_scale_f32 v36, vcc, v15, v22, v15
	v_mul_f32_e32 v38, v36, v40
	v_fma_f32 v39, -v37, v38, v36
	v_fmac_f32_e32 v38, v39, v40
	v_fma_f32 v36, -v37, v38, v36
	v_div_scale_f32 v37, s[0:1], v22, v22, v8
	v_rcp_f32_e32 v39, v37
	v_div_fmas_f32 v36, v36, v40, v38
	v_div_fixup_f32 v15, v36, v22, v15
	v_fma_f32 v36, -v37, v39, 1.0
	v_fmac_f32_e32 v39, v36, v39
	v_div_scale_f32 v36, vcc, v8, v22, v8
	v_mul_f32_e32 v38, v36, v39
	v_fma_f32 v40, -v37, v38, v36
	v_fmac_f32_e32 v38, v40, v39
	v_fma_f32 v36, -v37, v38, v36
	v_div_scale_f32 v37, s[0:1], v22, v22, v9
	v_rcp_f32_e32 v40, v37
	v_div_fmas_f32 v36, v36, v39, v38
	v_div_fixup_f32 v36, v36, v22, v8
	v_fma_f32 v8, -v37, v40, 1.0
	v_fmac_f32_e32 v40, v8, v40
	v_div_scale_f32 v8, vcc, v9, v22, v9
	v_mul_f32_e32 v38, v8, v40
	v_fma_f32 v39, -v37, v38, v8
	v_fmac_f32_e32 v38, v39, v40
	v_fma_f32 v8, -v37, v38, v8
	v_div_scale_f32 v37, s[0:1], v22, v22, v10
	v_rcp_f32_e32 v39, v37
	v_div_fmas_f32 v8, v8, v40, v38
	v_div_fixup_f32 v38, v8, v22, v9
	v_fma_f32 v8, -v37, v39, 1.0
	v_fmac_f32_e32 v39, v8, v39
	v_div_scale_f32 v8, vcc, v10, v22, v10
	v_mul_f32_e32 v9, v8, v39
	v_fma_f32 v40, -v37, v9, v8
	v_fmac_f32_e32 v9, v40, v39
	v_fma_f32 v8, -v37, v9, v8
	v_div_scale_f32 v37, s[0:1], v22, v22, v11
	v_rcp_f32_e32 v40, v37
	v_div_fmas_f32 v8, v8, v39, v9
	v_div_fixup_f32 v39, v8, v22, v10
	v_fma_f32 v8, -v37, v40, 1.0
	v_fmac_f32_e32 v40, v8, v40
	v_div_scale_f32 v8, vcc, v11, v22, v11
	v_mul_f32_e32 v9, v8, v40
	v_fma_f32 v10, -v37, v9, v8
	v_fmac_f32_e32 v9, v10, v40
	v_div_scale_f32 v10, s[0:1], v22, v22, v4
	v_fma_f32 v8, -v37, v9, v8
	v_rcp_f32_e32 v37, v10
	v_div_fmas_f32 v8, v8, v40, v9
	v_div_fixup_f32 v11, v8, v22, v11
	v_cvt_pk_bf16_f32 v11, v39, v11
	v_fma_f32 v8, -v10, v37, 1.0
	v_fmac_f32_e32 v37, v8, v37
	v_div_scale_f32 v8, vcc, v4, v22, v4
	v_mul_f32_e32 v9, v8, v37
	v_fma_f32 v40, -v10, v9, v8
	v_fmac_f32_e32 v9, v40, v37
	v_fma_f32 v8, -v10, v9, v8
	v_div_scale_f32 v10, s[0:1], v22, v22, v5
	v_rcp_f32_e32 v40, v10
	v_div_fmas_f32 v8, v8, v37, v9
	v_div_fixup_f32 v37, v8, v22, v4
	v_fma_f32 v4, -v10, v40, 1.0
	v_fmac_f32_e32 v40, v4, v40
	v_div_scale_f32 v4, vcc, v5, v22, v5
	v_mul_f32_e32 v8, v4, v40
	v_fma_f32 v9, -v10, v8, v4
	v_fmac_f32_e32 v8, v9, v40
	v_div_scale_f32 v9, s[0:1], v22, v22, v6
	v_fma_f32 v4, -v10, v8, v4
	v_rcp_f32_e32 v10, v9
	v_div_fmas_f32 v4, v4, v40, v8
	v_div_fixup_f32 v40, v4, v22, v5
	v_fma_f32 v4, -v9, v10, 1.0
	v_fmac_f32_e32 v10, v4, v10
	v_div_scale_f32 v4, vcc, v6, v22, v6
	v_mul_f32_e32 v5, v4, v10
	v_fma_f32 v8, -v9, v5, v4
	v_fmac_f32_e32 v5, v8, v10
	v_div_scale_f32 v8, s[0:1], v22, v22, v7
	v_fma_f32 v4, -v9, v5, v4
	v_rcp_f32_e32 v9, v8
	v_div_fmas_f32 v4, v4, v10, v5
	v_div_fixup_f32 v41, v4, v22, v6
	v_cvt_pk_bf16_f32 v10, v36, v38
	v_fma_f32 v4, -v8, v9, 1.0
	v_fmac_f32_e32 v9, v4, v9
	v_div_scale_f32 v4, vcc, v7, v22, v7
	v_mul_f32_e32 v5, v4, v9
	v_fma_f32 v6, -v8, v5, v4
	v_fmac_f32_e32 v5, v6, v9
	v_div_scale_f32 v6, s[0:1], v22, v22, v0
	v_fma_f32 v4, -v8, v5, v4
	v_rcp_f32_e32 v8, v6
	v_div_fmas_f32 v4, v4, v9, v5
	v_div_fixup_f32 v42, v4, v22, v7
	v_cvt_pk_bf16_f32 v9, v14, v15
	v_fma_f32 v4, -v6, v8, 1.0
	v_fmac_f32_e32 v8, v4, v8
	v_div_scale_f32 v4, vcc, v0, v22, v0
	v_mul_f32_e32 v5, v4, v8
	v_fma_f32 v7, -v6, v5, v4
	v_fmac_f32_e32 v5, v7, v8
	v_fma_f32 v4, -v6, v5, v4
	v_div_scale_f32 v6, s[0:1], v22, v22, v1
	v_rcp_f32_e32 v7, v6
	v_div_fmas_f32 v4, v4, v8, v5
	v_div_fixup_f32 v43, v4, v22, v0
	v_cvt_pk_bf16_f32 v8, v12, v13
	v_fma_f32 v0, -v6, v7, 1.0
	v_fmac_f32_e32 v7, v0, v7
	v_div_scale_f32 v0, vcc, v1, v22, v1
	v_mul_f32_e32 v4, v0, v7
	v_fma_f32 v5, -v6, v4, v0
	v_fmac_f32_e32 v4, v5, v7
	v_div_scale_f32 v5, s[0:1], v22, v22, v2
	v_fma_f32 v0, -v6, v4, v0
	v_rcp_f32_e32 v6, v5
	v_div_fmas_f32 v0, v0, v7, v4
	v_div_fixup_f32 v44, v0, v22, v1
	v_cvt_pk_bf16_f32 v7, v34, v35
	v_fma_f32 v0, -v5, v6, 1.0
	v_fmac_f32_e32 v6, v0, v6
	v_div_scale_f32 v0, vcc, v2, v22, v2
	v_mul_f32_e32 v1, v0, v6
	v_fma_f32 v4, -v5, v1, v0
	v_fmac_f32_e32 v1, v4, v6
	v_div_scale_f32 v4, s[0:1], v22, v22, v3
	v_fma_f32 v0, -v5, v1, v0
	v_rcp_f32_e32 v5, v4
	v_div_fmas_f32 v0, v0, v6, v1
	v_div_fixup_f32 v45, v0, v22, v2
	v_cvt_pk_bf16_f32 v6, v32, v33
	v_fma_f32 v0, -v4, v5, 1.0
	v_fmac_f32_e32 v5, v0, v5
	v_div_scale_f32 v0, vcc, v3, v22, v3
	v_mul_f32_e32 v1, v0, v5
	v_fma_f32 v2, -v4, v1, v0
	v_fmac_f32_e32 v1, v2, v5
	v_fma_f32 v0, -v4, v1, v0
	v_div_fmas_f32 v0, v0, v5, v1
	v_div_fixup_f32 v22, v0, v22, v3
	v_cvt_pk_bf16_f32 v0, v19, v20
	v_cvt_pk_bf16_f32 v1, v21, v23
	buffer_store_dwordx2 v[0:1], v18, s[8:11], 0 offen
	v_or_b32_e32 v0, 64, v17
	v_cvt_pk_bf16_f32 v2, v24, v25
	v_cvt_pk_bf16_f32 v3, v26, v27
	v_cndmask_b32_e64 v0, v16, v0, s[2:3]
	buffer_store_dwordx2 v[2:3], v0, s[8:11], 0 offen
	v_or_b32_e32 v0, 0x80, v17
	v_cvt_pk_bf16_f32 v4, v28, v29
	v_cvt_pk_bf16_f32 v5, v30, v31
	v_cndmask_b32_e64 v0, v16, v0, s[2:3]
	buffer_store_dwordx2 v[4:5], v0, s[8:11], 0 offen
	v_or_b32_e32 v0, 0xc0, v17
	v_cndmask_b32_e64 v0, v16, v0, s[2:3]
	buffer_store_dwordx2 v[6:7], v0, s[8:11], 0 offen
	v_or_b32_e32 v0, 0x100, v17
	v_cndmask_b32_e64 v0, v16, v0, s[2:3]
	buffer_store_dwordx2 v[8:9], v0, s[8:11], 0 offen
	v_or_b32_e32 v0, 0x140, v17
	v_cndmask_b32_e64 v0, v16, v0, s[2:3]
	buffer_store_dwordx2 v[10:11], v0, s[8:11], 0 offen
	v_or_b32_e32 v0, 0x180, v17
	v_cvt_pk_bf16_f32 v12, v37, v40
	v_cvt_pk_bf16_f32 v13, v41, v42
	v_cndmask_b32_e64 v0, v16, v0, s[2:3]
	buffer_store_dwordx2 v[12:13], v0, s[8:11], 0 offen
	v_or_b32_e32 v0, 0x1c0, v17
	v_cvt_pk_bf16_f32 v14, v43, v44
	v_cvt_pk_bf16_f32 v15, v45, v22
	v_cndmask_b32_e64 v0, v16, v0, s[2:3]
	buffer_store_dwordx2 v[14:15], v0, s[8:11], 0 offen
	s_endpgm
.Ltmp91:
	.endm
