// SPDX-License-Identifier: MIT
// Fixed raw gfx950 GQA8 prefix fp8kv attention stage.
	.macro NETRA_ATTENTION_GQA8_PREFIX_FP8KV_ATTENTION symbol
.LBB0_2:
	s_mov_b64 s[6:7], -1
                                        ; implicit-def: $sgpr65
                                        ; implicit-def: $sgpr56
                                        ; implicit-def: $sgpr59
                                        ; implicit-def: $sgpr58
                                        ; implicit-def: $sgpr60
                                        ; implicit-def: $sgpr61
.LBB0_3:                                ; %Flow373
	s_load_dword s62, s[0:1], 0x48
	s_and_b32 s55, s11, 0x180
	v_lshrrev_b32_e32 v61, 2, v53
	v_lshlrev_b32_e32 v63, 9, v1
	s_andn2_b64 vcc, exec, s[6:7]
	s_lshl_b32 s64, s54, 7
	s_cbranch_vccnz .LBB0_8
; %bb.4:                                ; %.lr.ph
	s_load_dwordx2 s[48:49], s[0:1], 0x40
	s_lshr_b32 s0, s10, 6
	s_or_b32 s1, s0, 8
	v_lshlrev_b32_e32 v2, 5, v1
	v_lshlrev_b32_e32 v3, 1, v53
	s_cmp_lt_i32 s0, s57
	v_bitop3_b32 v2, v2, v63, v3 bitop3:0xde
	s_movk_i32 s0, 0x180
	v_mov_b32_e32 v4, s64
	v_bitop3_b32 v5, v2, s0, v4 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	ds_read_b128 v[14:17], v5
	ds_read_b128 v[18:21], v5 offset:16
	s_movk_i32 s0, 0x100
	v_bitop3_b32 v5, v2, s0, v4 bitop3:0x36
	s_movk_i32 s0, 0x80
	v_or_b32_e32 v3, s64, v2
	v_bitop3_b32 v2, v2, s0, v4 bitop3:0x36
	NETRA_WAIT_LGKM0
	v_cvt_scalef32_pk_fp8_bf16 v14, v14, 1.0
	v_add_u32_e32 v5, 0, v5
	v_add_u32_e32 v2, 0, v2
	v_add_u32_e32 v30, 0, v3
	v_cvt_scalef32_pk_fp8_bf16 v14, v15, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v15, v16, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v16, v18, 1.0
	ds_read_b128 v[10:13], v5
	ds_read_b128 v[22:25], v5 offset:16
	ds_read_b128 v[6:9], v2
	ds_read_b128 v[26:29], v2 offset:16
	ds_read_b128 v[2:5], v30
	ds_read_b128 v[30:33], v30 offset:16
	v_cvt_scalef32_pk_fp8_bf16 v16, v19, 1.0 op_sel:[0,0,1]
	v_mul_u32_u24_e32 v19, 0x110, v1
	s_cselect_b64 s[42:43], -1, 0
	s_cmp_lt_i32 s1, s57
	v_lshlrev_b32_e32 v34, 5, v0
	v_cvt_scalef32_pk_fp8_bf16 v15, v17, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v17, v20, 1.0
	v_lshlrev_b32_e32 v18, 4, v57
	v_xor_b32_e32 v68, v19, v53
	v_lshlrev_b32_e32 v19, 4, v53
	v_lshrrev_b32_e32 v20, 1, v53
	s_cselect_b64 s[52:53], -1, 0
	s_lshr_b32 s0, s54, 2
	v_and_b32_e32 v34, 0xe0, v34
	v_lshrrev_b32_e32 v35, 1, v0
	v_xor_b32_e32 v67, v18, v62
	v_bitop3_b32 v19, v19, v20, v1 bitop3:0x36
	v_xor_b32_e32 v74, v52, v18
	v_lshlrev_b32_e32 v18, 2, v0
	v_and_b32_e32 v55, 28, v35
	v_add_u32_e32 v66, 0, v34
	s_and_b32 s56, s11, 64
	v_xor_b32_e32 v72, s0, v19
	v_and_b32_e32 v19, 62, v0
	v_and_b32_e32 v18, 0x78, v18
	s_waitcnt lgkmcnt(1)
	v_cvt_scalef32_pk_fp8_bf16 v2, v2, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v6, v6, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v10, v10, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v17, v21, 1.0 op_sel:[0,0,1]
	v_and_b32_e32 v20, 24, v0
	v_and_b32_e32 v21, 8, v51
	s_lshr_b32 s0, s56, 2
	v_lshl_or_b32 v18, v19, 7, v18
	v_add_u32_e32 v66, v66, v55
	v_xor_b32_e32 v55, 0xc0, v68
	s_lshr_b32 s1, s55, 3
	v_cvt_scalef32_pk_fp8_bf16 v2, v3, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v3, v4, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v6, v7, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v7, v8, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v10, v11, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v11, v12, 1.0
	s_lshl_b32 s59, s56, 1
	s_and_b32 s58, s11, 0x80
	s_lshr_b32 s7, s11, 2
	v_lshl_or_b32 v20, v19, 5, v20
	v_bitop3_b32 v76, s0, v18, v21 bitop3:0x36
	v_add_u32_e32 v18, s10, v64
	v_add_u32_e32 v71, 0, v55
	v_xor_b32_e32 v55, 8, v74
	s_lshr_b32 s6, s10, 1
	s_lshl_b32 s65, s17, 8
	v_cvt_scalef32_pk_fp8_bf16 v3, v5, 1.0 op_sel:[0,0,1]
	NETRA_WAIT_LGKM0
	v_cvt_scalef32_pk_fp8_bf16 v4, v30, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v5, v32, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v7, v9, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v8, v26, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v9, v28, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v11, v13, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v12, v22, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v13, v24, 1.0
	v_xor_b32_e32 v69, 64, v68
	v_xor_b32_e32 v70, 0x80, v68
	s_lshr_b32 s60, s58, 1
	s_add_i32 s68, s59, 0
	s_and_b32 s61, s7, 64
	s_add_i32 s69, s58, 0
	v_bitop3_b32 v73, s1, v20, v21 bitop3:0x36
	v_lshrrev_b32_e32 v65, 4, v18
	v_add_u32_e32 v75, 0, v55
	v_xor_b32_e32 v55, 32, v76
	v_xor_b32_e32 v78, 64, v76
	v_xor_b32_e32 v79, 0x60, v76
	s_mov_b32 s67, 0
	s_and_b32 s49, s49, 0xffff
	s_mov_b32 s51, 0x27000
	s_mov_b32 s50, 0x7ffffffe
	s_and_b32 s45, s45, 0xffff
	v_cvt_scalef32_pk_fp8_bf16 v4, v31, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v5, v33, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v8, v27, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v9, v29, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v12, v23, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v13, v25, 1.0 op_sel:[0,0,1]
	s_and_b32 s13, s13, 0xffff
	s_add_i32 s68, s68, s60
	s_add_i32 s69, s69, s61
	s_lshl_b32 s70, s14, 3
	v_mov_b32_e32 v48, 0
	v_mov_b32_e32 v49, 0
	v_mov_b32_e32 v46, 0
	v_mov_b32_e32 v47, 0
	v_mov_b32_e32 v44, 0
	v_mov_b32_e32 v45, 0
	v_mov_b32_e32 v42, 0
	v_mov_b32_e32 v43, 0
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
	s_add_i32 s71, s6, 0
	v_add_u32_e32 v67, 0, v67
	v_add_u32_e32 v68, 0, v68
	v_add_u32_e32 v69, 0, v69
	v_add_u32_e32 v70, 0, v70
	s_mov_b32 s72, 0xff800000
	s_mov_b32 s73, 0xc2fc0000
	v_add_u32_e32 v72, 0, v72
	v_add_u32_e32 v73, 0, v73
	v_add_u32_e32 v74, 0, v74
	v_add_u32_e32 v76, 0, v76
	v_add_u32_e32 v77, 0, v55
	v_add_u32_e32 v78, 0, v78
	v_add_u32_e32 v79, 0, v79
	v_or_b32_e32 v80, s65, v56
	v_lshlrev_b32_e32 v81, 3, v65
	v_mov_b32_e32 v87, 0xff800000
	v_mov_b32_e32 v55, 0
	v_bfrev_b32_e32 v82, 1
	v_mov_b32_e32 v83, 0xff800000
	v_mov_b32_e32 v84, 0xe0ad78ec
	v_mov_b32_e32 v85, 0x42800000
	v_not_b32_e32 v86, 63
	s_branch .LBB0_6
.LBB0_5:                                ;   in Loop: Header=BB0_6 Depth=1
	s_add_i32 s67, s67, 64
	s_cmp_lt_i32 s67, s66
	v_add_u32_e32 v81, 0x200, v81
	s_cbranch_scc0 .LBB0_9
.LBB0_6:                                ; =>This Inner Loop Header: Depth=1
	v_add_u32_e32 v88, s67, v64
	v_cmp_gt_i32_e32 vcc, s66, v88
	s_and_b64 s[0:1], s[42:43], vcc
	v_cndmask_b32_e64 v88, 0, 1, s[0:1]
	s_and_b64 s[0:1], s[52:53], vcc
	v_cndmask_b32_e64 v89, 0, 1, s[0:1]
.Ltmp2:
	v_max_i32_dpp v88, v88, v88 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp3:
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
.Ltmp4:
	v_max_i32_dpp v88, v88, v88 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp5:
	v_mov_b32_e32 v90, v88
	s_nop 1
	v_mov_b32_dpp v90, v90 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp6:
	v_max_i32_e32 v88, v88, v90
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp7:
	s_nop 0
	v_readlane_b32 s16, v88, 63
.Ltmp8:
	v_max_i32_dpp v88, v89, v89 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp9:
	s_mov_b32 s18, s16
.Ltmp10:
	s_nop 0
	v_max_i32_dpp v88, v88, v88 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp11:
	v_mov_b32_e32 v89, v88
	s_nop 1
	v_mov_b32_dpp v89, v89 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp12:
	v_max_i32_e32 v88, v88, v89
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp13:
	s_nop 0
	v_readlane_b32 s17, v88, 63
.Ltmp14:
	s_mov_b32 s19, s17
	v_mov_b64_e32 v[110:111], s[18:19]
	v_mov_b32_e32 v88, s71
	v_mov_b64_e32 v[108:109], s[16:17]
	ds_write_b128 v88, v[108:111]
	ds_write_b128 v88, v[108:111] offset:16
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b32 v88, v66
.Ltmp15:
	NETRA_WAIT_LGKM0
	s_nop 0
	v_max_i32_dpp v88, v88, v88 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp16:
	v_mov_b32_e32 v89, v88
	s_nop 1
	v_mov_b32_dpp v89, v89 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp17:
	v_max_i32_e32 v88, v88, v89
	s_nop 1
	v_max_i32_dpp v88, v88, v88 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp18:
	s_nop 0
	v_readlane_b32 s0, v88, 63
.Ltmp19:
	s_cmp_eq_u32 s0, 0
	s_cbranch_scc1 .LBB0_5
; %bb.7:                                ;   in Loop: Header=BB0_6 Depth=1
	v_add_u32_e32 v88, s67, v65
	v_add_u32_e32 v89, 32, v88
	v_add_u32_e32 v90, s70, v81
	v_cmp_gt_i32_e32 vcc, s66, v88
	v_add_u32_e32 v88, 0x100, v90
	v_cmp_gt_i32_e64 s[0:1], s66, v89
	v_cndmask_b32_e32 v108, v82, v90, vcc
	s_mov_b32 s46, s50
	v_cndmask_b32_e64 v109, v82, v88, s[0:1]
	buffer_load_dwordx2 v[88:89], v108, s[48:51], 0 offen
	buffer_load_dwordx2 v[90:91], v109, s[48:51], 0 offen
	s_mov_b32 s47, s51
	NETRA_WAIT_VM0
	v_max_f32_e32 v91, v87, v87
	v_lshl_add_u32 v88, v88, 9, v80
	v_lshl_add_u32 v89, v90, 9, v80
	v_cndmask_b32_e32 v88, v82, v88, vcc
	v_cndmask_b32_e64 v89, v82, v89, s[0:1]
	buffer_load_dwordx4 v[108:111], v88, s[44:47], 0 offen
	buffer_load_dwordx4 v[112:115], v89, s[44:47], 0 offen
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	v_add_u32_e32 v90, s67, v61
	v_add_u32_e32 v120, 35, v90
	v_add_u32_e32 v121, 34, v90
	v_add_u32_e32 v122, 33, v90
	v_add_u32_e32 v123, 32, v90
	v_cmp_gt_i32_e64 s[16:17], s66, v120
	v_cmp_gt_i32_e64 s[18:19], s66, v121
	v_cmp_gt_i32_e64 s[20:21], s66, v122
	v_cmp_gt_i32_e64 s[22:23], s66, v123
	v_add_u32_e32 v116, 51, v90
	v_add_u32_e32 v117, 50, v90
	v_add_u32_e32 v118, 49, v90
	v_add_u32_e32 v119, 48, v90
	v_cmp_gt_i32_e64 s[0:1], s66, v116
	v_cmp_gt_i32_e64 s[6:7], s66, v117
	v_cmp_gt_i32_e64 s[10:11], s66, v118
	v_cmp_gt_i32_e64 s[14:15], s66, v119
	v_add_u32_e32 v124, 19, v90
	v_add_u32_e32 v125, 18, v90
	v_add_u32_e32 v126, 17, v90
	v_add_u32_e32 v127, 16, v90
	v_add_u32_e32 v128, 3, v90
	v_add_u32_e32 v129, 2, v90
	v_add_u32_e32 v130, 1, v90
	v_cmp_gt_i32_e64 s[24:25], s66, v124
	v_cmp_gt_i32_e64 s[26:27], s66, v125
	v_cmp_gt_i32_e64 s[28:29], s66, v126
	v_cmp_gt_i32_e64 s[30:31], s66, v127
	v_cmp_gt_i32_e64 s[34:35], s66, v128
	v_cmp_gt_i32_e64 s[36:37], s66, v129
	v_cmp_gt_i32_e64 s[38:39], s66, v130
	v_cmp_gt_i32_e32 vcc, s66, v90
	s_and_b64 vcc, s[2:3], vcc
	s_and_b64 s[38:39], s[2:3], s[38:39]
	s_and_b64 s[36:37], s[2:3], s[36:37]
	s_and_b64 s[34:35], s[2:3], s[34:35]
	s_and_b64 s[30:31], s[2:3], s[30:31]
	s_and_b64 s[28:29], s[2:3], s[28:29]
	s_and_b64 s[26:27], s[2:3], s[26:27]
	s_and_b64 s[24:25], s[2:3], s[24:25]
	s_and_b64 s[22:23], s[2:3], s[22:23]
	s_and_b64 s[20:21], s[2:3], s[20:21]
	s_and_b64 s[18:19], s[2:3], s[18:19]
	s_and_b64 s[16:17], s[2:3], s[16:17]
	s_and_b64 s[14:15], s[2:3], s[14:15]
	s_and_b64 s[10:11], s[2:3], s[10:11]
	s_and_b64 s[6:7], s[2:3], s[6:7]
	s_and_b64 s[0:1], s[2:3], s[0:1]
	s_waitcnt vmcnt(1)
	ds_write_b128 v67, v[108:111]
	NETRA_WAIT_VM0
	ds_write_b128 v67, v[112:115] offset:8192
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b128 v[112:115], v69
	ds_read_b128 v[108:111], v68
	ds_read_b128 v[132:135], v68 offset:4096
	ds_read_b128 v[136:139], v69 offset:4096
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[108:111], v[108:115], v[2:9], 0
	ds_read_b128 v[140:143], v68 offset:8192
	ds_read_b128 v[144:147], v69 offset:8192
	ds_read_b128 v[124:127], v70 offset:8192
	ds_read_b128 v[128:131], v71 offset:8192
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[132:139], v[2:9], 0
	ds_read_b128 v[132:135], v68 offset:12288
	ds_read_b128 v[136:139], v69 offset:12288
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[132:139], v[2:9], 0
	ds_read_b128 v[132:135], v70 offset:4096
	ds_read_b128 v[136:139], v71 offset:4096
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[140:147], v[2:9], 0
	ds_read_b128 v[140:143], v70
	ds_read_b128 v[144:147], v71
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[112:115], v[132:139], v[10:17], v[112:115]
	ds_read_b128 v[132:135], v70 offset:12288
	ds_read_b128 v[136:139], v71 offset:12288
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[108:111], v[140:147], v[10:17], v[108:111]
	v_mfma_f32_16x16x128_f8f6f4 v[116:119], v[124:131], v[10:17], v[116:119]
	s_nop 10
	v_mul_f32_e32 v90, s62, v108
	v_mul_f32_e32 v108, s62, v109
	v_mul_f32_e32 v109, s62, v110
	v_mul_f32_e32 v110, s62, v111
	v_mul_f32_e32 v111, s62, v112
	v_mul_f32_e32 v112, s62, v113
	v_mul_f32_e32 v113, s62, v114
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x128_f8f6f4 v[120:123], v[132:139], v[10:17], v[120:123]
	v_mul_f32_e32 v114, s62, v115
	v_mul_f32_e32 v115, s62, v116
	v_mul_f32_e32 v116, s62, v117
	v_mul_f32_e32 v117, s62, v118
	v_mul_f32_e32 v118, s62, v119
	v_cndmask_b32_e64 v108, v83, v108, s[38:39]
	v_cndmask_b32_e64 v109, v83, v109, s[36:37]
	s_nop 4
	v_mul_f32_e32 v119, s62, v120
	v_mul_f32_e32 v120, s62, v121
	v_mul_f32_e32 v121, s62, v122
	v_mul_f32_e32 v122, s62, v123
	v_cndmask_b32_e32 v123, v83, v90, vcc
	v_cndmask_b32_e64 v110, v83, v110, s[34:35]
.Ltmp20:
	v_max_f32_e32 v90, v123, v108
.Ltmp21:
	v_cndmask_b32_e64 v111, v83, v111, s[30:31]
	v_cndmask_b32_e64 v112, v83, v112, s[28:29]
.Ltmp22:
	v_max3_f32 v90, v90, v109, v110
.Ltmp23:
	v_cndmask_b32_e64 v113, v83, v113, s[26:27]
	v_cndmask_b32_e64 v114, v83, v114, s[24:25]
.Ltmp24:
	v_max3_f32 v90, v90, v111, v112
.Ltmp25:
	v_cndmask_b32_e64 v115, v83, v115, s[22:23]
	v_cndmask_b32_e64 v116, v83, v116, s[20:21]
.Ltmp26:
	v_max3_f32 v90, v90, v113, v114
.Ltmp27:
	v_cndmask_b32_e64 v117, v83, v117, s[18:19]
	v_cndmask_b32_e64 v118, v83, v118, s[16:17]
.Ltmp28:
	v_max3_f32 v90, v90, v115, v116
.Ltmp29:
	v_cndmask_b32_e64 v119, v83, v119, s[14:15]
	v_cndmask_b32_e64 v120, v83, v120, s[10:11]
.Ltmp30:
	v_max3_f32 v90, v90, v117, v118
.Ltmp31:
	v_cndmask_b32_e64 v121, v83, v121, s[6:7]
	v_cndmask_b32_e64 v122, v83, v122, s[0:1]
.Ltmp32:
	v_max3_f32 v90, v90, v119, v120
	v_max3_f32 v90, v90, v121, v122
.Ltmp33:
	v_mov_b32_e32 v124, v90
	s_nop 1
	v_permlane32_swap_b32_e32 v90, v124
.Ltmp34:
	v_max_f32_e32 v124, v124, v124
	v_max_f32_e32 v90, v90, v90
	v_max_f32_e32 v90, v90, v124
.Ltmp35:
	v_mov_b32_e32 v124, v90
	s_nop 1
	v_permlane16_swap_b32_e32 v90, v124
.Ltmp36:
	v_max_f32_e32 v124, v124, v124
	v_max_f32_e32 v90, v90, v90
	v_max_f32_e32 v90, v90, v124
.Ltmp37:
	v_cmp_neq_f32_e32 vcc, s72, v90
	s_nop 1
	v_cndmask_b32_e32 v90, v84, v90, vcc
	v_max_f32_e32 v90, v90, v91
	v_sub_f32_e32 v108, v108, v90
	v_sub_f32_e32 v113, v113, v90
	v_mul_f32_e32 v125, 0x3fb8aa3b, v108
	v_sub_f32_e32 v109, v109, v90
	v_mul_f32_e32 v130, 0x3fb8aa3b, v113
	v_cmp_gt_f32_e64 s[6:7], s73, v125
	v_mul_f32_e32 v126, 0x3fb8aa3b, v109
	v_cmp_gt_f32_e64 s[20:21], s73, v130
	v_cndmask_b32_e64 v125, 0, v85, s[6:7]
	v_sub_f32_e32 v87, v87, v90
	v_cmp_gt_f32_e64 s[10:11], s73, v126
	v_cndmask_b32_e64 v130, 0, v85, s[20:21]
	v_fmac_f32_e32 v125, 0x3fb8aa3b, v108
	v_sub_f32_e32 v91, v123, v90
	v_sub_f32_e32 v111, v111, v90
	v_mul_f32_e32 v123, 0x3fb8aa3b, v87
	v_cndmask_b32_e64 v126, 0, v85, s[10:11]
	v_fmac_f32_e32 v130, 0x3fb8aa3b, v113
	v_exp_f32_e32 v108, v125
	v_mul_f32_e32 v128, 0x3fb8aa3b, v111
	v_cmp_gt_f32_e32 vcc, s73, v123
	v_fmac_f32_e32 v126, 0x3fb8aa3b, v109
	v_exp_f32_e32 v113, v130
	v_mul_f32_e32 v124, 0x3fb8aa3b, v91
	v_cmp_gt_f32_e64 s[16:17], s73, v128
	v_cndmask_b32_e32 v123, 0, v85, vcc
	v_exp_f32_e32 v109, v126
	v_sub_f32_e32 v110, v110, v90
	v_cmp_gt_f32_e64 s[0:1], s73, v124
	v_cndmask_b32_e64 v128, 0, v85, s[16:17]
	v_cndmask_b32_e64 v133, 0, v86, s[6:7]
	v_fmac_f32_e32 v123, 0x3fb8aa3b, v87
	v_sub_f32_e32 v114, v114, v90
	v_mul_f32_e32 v127, 0x3fb8aa3b, v110
	v_cndmask_b32_e64 v124, 0, v85, s[0:1]
	v_fmac_f32_e32 v128, 0x3fb8aa3b, v111
	v_exp_f32_e32 v87, v123
	v_ldexp_f32 v123, v108, v133
	v_cndmask_b32_e64 v108, 0, v86, s[20:21]
	v_sub_f32_e32 v115, v115, v90
	v_cmp_gt_f32_e64 s[14:15], s73, v127
	v_cndmask_b32_e64 v134, 0, v86, s[10:11]
	v_fmac_f32_e32 v124, 0x3fb8aa3b, v91
	v_exp_f32_e32 v111, v128
	v_ldexp_f32 v128, v113, v108
	v_mul_f32_e32 v108, 0x3fb8aa3b, v114
	v_cndmask_b32_e64 v127, 0, v85, s[14:15]
	v_cndmask_b32_e32 v131, 0, v86, vcc
	v_exp_f32_e32 v91, v124
	v_ldexp_f32 v124, v109, v134
	v_cmp_gt_f32_e32 vcc, s73, v108
	v_mul_f32_e32 v109, 0x3fb8aa3b, v115
	v_cndmask_b32_e64 v132, 0, v86, s[0:1]
	v_fmac_f32_e32 v127, 0x3fb8aa3b, v110
	v_cndmask_b32_e32 v108, 0, v85, vcc
	v_cmp_gt_f32_e64 s[0:1], s73, v109
	v_sub_f32_e32 v112, v112, v90
	v_exp_f32_e32 v110, v127
	v_fmac_f32_e32 v108, 0x3fb8aa3b, v114
	v_cndmask_b32_e64 v109, 0, v85, s[0:1]
	v_mul_f32_e32 v129, 0x3fb8aa3b, v112
	v_exp_f32_e32 v108, v108
	v_fmac_f32_e32 v109, 0x3fb8aa3b, v115
	v_cmp_gt_f32_e64 s[18:19], s73, v129
	v_exp_f32_e32 v109, v109
	v_cndmask_b32_e64 v135, 0, v86, s[14:15]
	v_cndmask_b32_e64 v129, 0, v85, s[18:19]
	v_fmac_f32_e32 v129, 0x3fb8aa3b, v112
	v_ldexp_f32 v125, v110, v135
	v_cndmask_b32_e32 v110, 0, v86, vcc
	v_sub_f32_e32 v116, v116, v90
	v_exp_f32_e32 v112, v129
	v_ldexp_f32 v129, v108, v110
	v_cndmask_b32_e64 v108, 0, v86, s[0:1]
	v_sub_f32_e32 v117, v117, v90
	v_ldexp_f32 v130, v109, v108
	v_mul_f32_e32 v108, 0x3fb8aa3b, v116
	v_cmp_gt_f32_e32 vcc, s73, v108
	v_mul_f32_e32 v109, 0x3fb8aa3b, v117
	v_cmp_gt_f32_e64 s[0:1], s73, v109
	v_cndmask_b32_e32 v108, 0, v85, vcc
	v_fmac_f32_e32 v108, 0x3fb8aa3b, v116
	v_cndmask_b32_e64 v109, 0, v85, s[0:1]
	v_exp_f32_e32 v108, v108
	v_fmac_f32_e32 v109, 0x3fb8aa3b, v117
	v_exp_f32_e32 v109, v109
	v_cndmask_b32_e32 v110, 0, v86, vcc
	v_sub_f32_e32 v118, v118, v90
	v_ldexp_f32 v116, v108, v110
	v_cndmask_b32_e64 v108, 0, v86, s[0:1]
	v_ldexp_f32 v117, v109, v108
	v_mul_f32_e32 v108, 0x3fb8aa3b, v118
	v_cmp_gt_f32_e32 vcc, s73, v108
	v_cndmask_b32_e64 v136, 0, v86, s[16:17]
	v_cndmask_b32_e64 v137, 0, v86, s[18:19]
	v_cndmask_b32_e32 v108, 0, v85, vcc
	v_fmac_f32_e32 v108, 0x3fb8aa3b, v118
	s_mov_b32 s14, s50
	s_mov_b32 s15, s51
	v_ldexp_f32 v126, v111, v136
	v_ldexp_f32 v127, v112, v137
	v_exp_f32_e32 v118, v108
	buffer_load_dwordx4 v[108:111], v88, s[12:15], 0 offen
	buffer_load_dwordx4 v[112:115], v89, s[12:15], 0 offen
	v_sub_f32_e32 v119, v119, v90
	v_cndmask_b32_e32 v88, 0, v86, vcc
	v_sub_f32_e32 v120, v120, v90
	v_ldexp_f32 v89, v118, v88
	v_mul_f32_e32 v88, 0x3fb8aa3b, v119
	v_cmp_gt_f32_e32 vcc, s73, v88
	v_mul_f32_e32 v118, 0x3fb8aa3b, v120
	v_cmp_gt_f32_e64 s[0:1], s73, v118
	v_cndmask_b32_e32 v88, 0, v85, vcc
	v_fmac_f32_e32 v88, 0x3fb8aa3b, v119
	v_cndmask_b32_e64 v118, 0, v85, s[0:1]
	v_exp_f32_e32 v88, v88
	v_fmac_f32_e32 v118, 0x3fb8aa3b, v120
	v_exp_f32_e32 v118, v118
	v_cndmask_b32_e32 v119, 0, v86, vcc
	v_sub_f32_e32 v121, v121, v90
	v_ldexp_f32 v119, v88, v119
	v_cndmask_b32_e64 v88, 0, v86, s[0:1]
	v_sub_f32_e32 v122, v122, v90
	v_ldexp_f32 v118, v118, v88
	v_mul_f32_e32 v88, 0x3fb8aa3b, v121
	v_cmp_gt_f32_e32 vcc, s73, v88
	v_mul_f32_e32 v120, 0x3fb8aa3b, v122
	v_cmp_gt_f32_e64 s[0:1], s73, v120
	v_cndmask_b32_e32 v88, 0, v85, vcc
	v_fmac_f32_e32 v88, 0x3fb8aa3b, v121
	v_cndmask_b32_e64 v120, 0, v85, s[0:1]
	v_exp_f32_e32 v88, v88
	v_fmac_f32_e32 v120, 0x3fb8aa3b, v122
	v_exp_f32_e32 v120, v120
	v_ldexp_f32 v91, v91, v132
	v_cndmask_b32_e32 v121, 0, v86, vcc
	v_ldexp_f32 v121, v88, v121
	v_cndmask_b32_e64 v88, 0, v86, s[0:1]
	v_cvt_scalef32_pk_fp8_f32 v122, v91, v123, 1.0
	v_ldexp_f32 v87, v87, v131
	v_ldexp_f32 v120, v120, v88
	v_add_u32_e32 v88, s68, v54
	v_cvt_scalef32_pk_fp8_f32 v122, v124, v125, 1.0 op_sel:[0,0,0,1]
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_write_b32 v88, v87
	v_add_u32_e32 v88, s69, v54
	v_cvt_scalef32_pk_fp8_f32 v131, v126, v127, 1.0
	v_lshrrev_b32_e32 v134, 8, v122
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b32 v88, v88
	v_cvt_scalef32_pk_fp8_f32 v131, v128, v129, 1.0 op_sel:[0,0,0,1]
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_write_b8 v72, v122
	ds_write_b8 v72, v134 offset:64
	ds_write_b8_d16_hi v72, v122 offset:128
	v_lshrrev_b32_e32 v122, 24, v122
	v_cvt_scalef32_pk_fp8_f32 v132, v130, v116, 1.0
	ds_write_b8 v72, v122 offset:192
	ds_write_b8 v72, v131 offset:1024
	v_lshrrev_b32_e32 v122, 8, v131
	v_cvt_scalef32_pk_fp8_f32 v132, v117, v89, 1.0 op_sel:[0,0,0,1]
	ds_write_b8 v72, v122 offset:1088
	ds_write_b8_d16_hi v72, v131 offset:1152
	v_lshrrev_b32_e32 v122, 24, v131
	v_cvt_scalef32_pk_fp8_f32 v133, v119, v118, 1.0
	ds_write_b8 v72, v122 offset:1216
	ds_write_b8 v72, v132 offset:2048
	v_lshrrev_b32_e32 v122, 8, v132
	v_cvt_scalef32_pk_fp8_f32 v133, v121, v120, 1.0 op_sel:[0,0,0,1]
	ds_write_b8 v72, v122 offset:2112
	ds_write_b8_d16_hi v72, v132 offset:2176
	v_lshrrev_b32_e32 v122, 24, v132
	ds_write_b8 v72, v122 offset:2240
	ds_write_b8 v72, v133 offset:3072
	v_lshrrev_b32_e32 v122, 8, v133
	ds_write_b8 v72, v122 offset:3136
	ds_write_b8_d16_hi v72, v133 offset:3200
	v_lshrrev_b32_e32 v122, 24, v133
	ds_write_b8 v72, v122 offset:3264
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b64_tr_b8 v[132:133], v73
	ds_read_b64_tr_b8 v[134:135], v73 offset:2048
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	NETRA_WAIT_VM0
	ds_write2st64_b64 v74, v[108:109], v[112:113] offset1:16
	ds_write2st64_b64 v75, v[110:111], v[114:115] offset1:16
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b64_tr_b8 v[108:109], v76
	ds_read_b64_tr_b8 v[110:111], v76 offset:8192
	v_pk_mul_f32 v[48:49], v[48:49], v[88:89] op_sel_hi:[1,0]
	v_pk_mul_f32 v[46:47], v[46:47], v[88:89] op_sel_hi:[1,0]
	v_pk_mul_f32 v[44:45], v[44:45], v[88:89] op_sel_hi:[1,0]
	v_pk_mul_f32 v[42:43], v[42:43], v[88:89] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_fp8_fp8 v[46:49], v[108:109], v[132:133], v[46:49]
	ds_read_b64_tr_b8 v[108:109], v77
	ds_read_b64_tr_b8 v[112:113], v76 offset:8320
	ds_read_b64_tr_b8 v[114:115], v76 offset:128
.Ltmp38:
	v_add_f32_e32 v91, v91, v123
	v_add_f32_e32 v91, v124, v91
.Ltmp39:
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_fp8_fp8 v[42:45], v[108:109], v[132:133], v[42:45]
	ds_read_b64_tr_b8 v[108:109], v78
.Ltmp40:
	v_add_f32_e32 v91, v125, v91
	v_add_f32_e32 v91, v126, v91
	v_add_f32_e32 v91, v127, v91
	v_add_f32_e32 v91, v128, v91
	v_add_f32_e32 v91, v129, v91
	v_add_f32_e32 v91, v130, v91
.Ltmp41:
	v_mfma_f32_16x16x32_fp8_fp8 v[46:49], v[110:111], v[134:135], v[46:49]
	ds_read_b64_tr_b8 v[110:111], v77 offset:8192
	ds_read_b64_tr_b8 v[136:137], v77 offset:8320
	ds_read_b64_tr_b8 v[138:139], v77 offset:128
.Ltmp42:
	v_add_f32_e32 v91, v116, v91
.Ltmp43:
	v_pk_mul_f32 v[40:41], v[40:41], v[88:89] op_sel_hi:[1,0]
	v_pk_mul_f32 v[38:39], v[38:39], v[88:89] op_sel_hi:[1,0]
.Ltmp44:
	v_add_f32_e32 v91, v117, v91
.Ltmp45:
	v_pk_mul_f32 v[36:37], v[36:37], v[88:89] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_fp8_fp8 v[38:41], v[108:109], v[132:133], v[38:41]
	ds_read_b64_tr_b8 v[108:109], v79
	v_pk_mul_f32 v[34:35], v[34:35], v[88:89] op_sel_hi:[1,0]
	v_pk_mul_f32 v[32:33], v[32:33], v[88:89] op_sel_hi:[1,0]
	v_pk_mul_f32 v[30:31], v[30:31], v[88:89] op_sel_hi:[1,0]
.Ltmp46:
	v_add_f32_e32 v89, v89, v91
.Ltmp47:
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_fp8_fp8 v[42:45], v[110:111], v[134:135], v[42:45]
	ds_read_b64_tr_b8 v[110:111], v78 offset:8192
	ds_read_b64_tr_b8 v[122:123], v78 offset:8320
	ds_read_b64_tr_b8 v[140:141], v78 offset:128
.Ltmp48:
	v_add_f32_e32 v89, v119, v89
.Ltmp49:
	v_pk_mul_f32 v[28:29], v[28:29], v[88:89] op_sel_hi:[1,0]
	v_pk_mul_f32 v[26:27], v[26:27], v[88:89] op_sel_hi:[1,0]
.Ltmp50:
	v_add_f32_e32 v89, v118, v89
	v_add_f32_e32 v89, v121, v89
.Ltmp51:
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_fp8_fp8 v[38:41], v[110:111], v[134:135], v[38:41]
	ds_read_b64_tr_b8 v[110:111], v79 offset:8192
	ds_read_b64_tr_b8 v[124:125], v79 offset:8320
	ds_read_b64_tr_b8 v[142:143], v79 offset:128
.Ltmp52:
	v_add_f32_e32 v89, v120, v89
.Ltmp53:
	v_mov_b32_e32 v91, v89
.Ltmp54:
	v_pk_mul_f32 v[24:25], v[24:25], v[88:89] op_sel_hi:[1,0]
	v_pk_mul_f32 v[22:23], v[22:23], v[88:89] op_sel_hi:[1,0]
.Ltmp55:
	v_permlane32_swap_b32_e32 v89, v91
.Ltmp56:
	v_add_f32_e32 v89, v89, v91
.Ltmp57:
	v_pk_mul_f32 v[20:21], v[20:21], v[88:89] op_sel_hi:[1,0]
	v_pk_mul_f32 v[18:19], v[18:19], v[88:89] op_sel_hi:[1,0]
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[108:109], v[132:133], v[34:37]
.Ltmp58:
	v_mov_b32_e32 v91, v89
	s_nop 1
	v_permlane16_swap_b32_e32 v89, v91
.Ltmp59:
	v_mfma_f32_16x16x32_fp8_fp8 v[30:33], v[114:115], v[132:133], v[30:33]
.Ltmp60:
	v_add_f32_e32 v88, v89, v91
.Ltmp61:
	v_fmac_f32_e32 v88, v55, v87
	v_mov_b32_e32 v55, v88
	v_mfma_f32_16x16x32_fp8_fp8 v[26:29], v[138:139], v[132:133], v[26:29]
	v_mov_b32_e32 v87, v90
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_fp8_fp8 v[22:25], v[140:141], v[132:133], v[22:25]
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_fp8_fp8 v[18:21], v[142:143], v[132:133], v[18:21]
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[110:111], v[134:135], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[30:33], v[112:113], v[134:135], v[30:33]
	v_mfma_f32_16x16x32_fp8_fp8 v[26:29], v[136:137], v[134:135], v[26:29]
	v_mfma_f32_16x16x32_fp8_fp8 v[22:25], v[122:123], v[134:135], v[22:25]
	v_mfma_f32_16x16x32_fp8_fp8 v[18:21], v[124:125], v[134:135], v[18:21]
	s_branch .LBB0_5
	.endm
