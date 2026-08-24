// SPDX-License-Identifier: MIT
// Fixed raw gfx950 GQA4 prefix fp8kv attention stage.
	.macro NETRA_ATTENTION_GQA4_PREFIX_FP8KV_ATTENTION symbol
.LBB0_2:
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
	s_mov_b32 s55, 0
	s_load_dwordx2 s[60:61], s[0:1], 0x40
	s_or_b32 s0, s54, 4
	s_mov_b32 s1, s55
	v_lshlrev_b32_e32 v2, 5, v2
	v_lshlrev_b32_e32 v4, 1, v1
	v_cmp_lt_i64_e64 s[2:3], s[0:1], v[46:47]
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
	s_or_b32 s6, s54, 8
	s_or_b32 s10, s54, 12
	s_mov_b32 s7, s55
	s_mov_b32 s11, s55
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
	v_add_u32_e32 v10, s16, v51
	v_cmp_lt_i64_e32 vcc, s[54:55], v[46:47]
	v_cmp_lt_i64_e64 s[6:7], s[6:7], v[46:47]
	v_cmp_lt_i64_e64 s[10:11], s[10:11], v[46:47]
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
	s_lshl_b32 s72, s14, 3
	v_lshrrev_b32_e32 v62, 3, v10
	v_and_b32_e32 v63, 0x1f8, v10
	v_mov_b32_e32 v60, 0xff800000
	v_mov_b32_e32 v61, 0
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
	s_add_i32 s55, s55, 64
	s_cmp_lt_i32 s55, s67
	v_add_u32_e32 v63, 0x200, v63
	s_cbranch_scc0 .LBB0_9
.LBB0_6:                                ; =>This Inner Loop Header: Depth=1
	v_add_u32_e32 v79, s55, v51
	v_cmp_gt_i32_e64 s[0:1], s67, v79
	v_add_u32_e32 v79, 0xfff, v79
	v_cmp_le_i32_e64 s[14:15], s68, v79
	s_and_b64 s[14:15], vcc, s[14:15]
	s_and_b64 s[14:15], s[0:1], s[14:15]
	v_cmp_le_i32_e64 s[16:17], s69, v79
	v_cmp_le_i32_e64 s[18:19], s70, v79
	v_cmp_le_i32_e64 s[20:21], s71, v79
	v_cndmask_b32_e64 v79, 0, 1, s[14:15]
	s_and_b64 s[16:17], s[2:3], s[16:17]
	s_and_b64 s[14:15], s[0:1], s[16:17]
.Ltmp2:
	v_max_i32_dpp v79, v79, v79 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp3:
	v_cndmask_b32_e64 v80, 0, 1, s[14:15]
	s_and_b64 s[18:19], s[6:7], s[18:19]
.Ltmp4:
	v_max_i32_dpp v79, v79, v79 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp5:
	s_and_b64 s[14:15], s[0:1], s[18:19]
	v_cndmask_b32_e64 v81, 0, 1, s[14:15]
.Ltmp6:
	v_max_i32_dpp v79, v79, v79 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp7:
	s_and_b64 s[20:21], s[10:11], s[20:21]
	s_and_b64 s[0:1], s[0:1], s[20:21]
.Ltmp8:
	v_max_i32_dpp v79, v79, v79 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp9:
	v_mov_b32_e32 v83, v79
.Ltmp10:
	v_cndmask_b32_e64 v82, 0, 1, s[0:1]
.Ltmp11:
	NETRA_WAIT_LGKM0
.Ltmp12:
	v_mov_b32_dpp v83, v83 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp13:
	v_max_i32_e32 v79, v79, v83
.Ltmp14:
	NETRA_BARRIER
.Ltmp15:
	s_nop 0
	v_max_i32_dpp v79, v79, v79 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp16:
	s_nop 0
	v_readlane_b32 s16, v79, 63
.Ltmp17:
	v_max_i32_dpp v79, v80, v80 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp18:
	v_mov_b32_e32 v80, v79
	s_nop 1
	v_mov_b32_dpp v80, v80 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp19:
	v_max_i32_e32 v79, v79, v80
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp20:
	s_nop 0
	v_readlane_b32 s17, v79, 63
.Ltmp21:
	v_max_i32_dpp v79, v81, v81 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp22:
	v_mov_b32_e32 v80, v79
	s_nop 1
	v_mov_b32_dpp v80, v80 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp23:
	v_max_i32_e32 v79, v79, v80
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp24:
	s_nop 0
	v_readlane_b32 s18, v79, 63
.Ltmp25:
	v_max_i32_dpp v79, v82, v82 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp26:
	v_mov_b32_e32 v80, v79
	s_nop 1
	v_mov_b32_dpp v80, v80 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp27:
	v_max_i32_e32 v79, v79, v80
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp28:
	s_nop 0
	v_readlane_b32 s19, v79, 63
.Ltmp29:
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
	v_mov_b32_e32 v80, v79
	s_nop 1
	v_mov_b32_dpp v80, v80 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp32:
	v_max_i32_e32 v79, v79, v80
	s_nop 1
	v_max_i32_dpp v79, v79, v79 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp33:
	s_nop 0
	v_readlane_b32 s0, v79, 63
.Ltmp34:
	s_cmp_eq_u32 s0, 0
	s_cbranch_scc1 .LBB0_5
; %bb.7:                                ;   in Loop: Header=BB0_6 Depth=1
	v_add_u32_e32 v79, s55, v58
	v_add_u32_e32 v80, 51, v79
	v_add_u32_e32 v81, 0x1032, v79
	v_cmp_le_i32_e64 s[0:1], v53, v81
	v_cmp_gt_i32_e64 s[14:15], s67, v80
	s_and_b64 s[0:1], s[14:15], s[0:1]
	v_add_u32_e32 v80, 50, v79
	v_add_u32_e32 v81, 0x1031, v79
	s_and_b64 s[14:15], s[48:49], s[0:1]
	v_cmp_le_i32_e64 s[0:1], v53, v81
	v_cmp_gt_i32_e64 s[16:17], s67, v80
	s_and_b64 s[0:1], s[16:17], s[0:1]
	v_add_u32_e32 v80, 49, v79
	v_add_u32_e32 v81, 0x1030, v79
	s_and_b64 s[16:17], s[48:49], s[0:1]
	v_cmp_le_i32_e64 s[0:1], v53, v81
	v_cmp_gt_i32_e64 s[18:19], s67, v80
	s_and_b64 s[0:1], s[18:19], s[0:1]
	v_add_u32_e32 v80, 48, v79
	v_add_u32_e32 v81, 0x102f, v79
	s_and_b64 s[18:19], s[48:49], s[0:1]
	v_cmp_le_i32_e64 s[0:1], v53, v81
	v_cmp_gt_i32_e64 s[20:21], s67, v80
	s_and_b64 s[0:1], s[20:21], s[0:1]
	v_add_u32_e32 v80, 35, v79
	v_add_u32_e32 v81, 0x1022, v79
	s_and_b64 s[20:21], s[48:49], s[0:1]
	v_cmp_le_i32_e64 s[0:1], v53, v81
	v_cmp_gt_i32_e64 s[22:23], s67, v80
	s_and_b64 s[0:1], s[22:23], s[0:1]
	v_add_u32_e32 v80, 34, v79
	v_add_u32_e32 v81, 0x1021, v79
	s_and_b64 s[22:23], s[48:49], s[0:1]
	v_cmp_le_i32_e64 s[0:1], v53, v81
	v_cmp_gt_i32_e64 s[24:25], s67, v80
	s_and_b64 s[0:1], s[24:25], s[0:1]
	v_add_u32_e32 v80, 33, v79
	v_add_u32_e32 v81, 0x1020, v79
	s_and_b64 s[24:25], s[48:49], s[0:1]
	v_cmp_le_i32_e64 s[0:1], v53, v81
	v_cmp_gt_i32_e64 s[26:27], s67, v80
	s_and_b64 s[0:1], s[26:27], s[0:1]
	v_add_u32_e32 v80, 32, v79
	v_add_u32_e32 v81, 0x101f, v79
	s_and_b64 s[26:27], s[48:49], s[0:1]
	v_cmp_le_i32_e64 s[0:1], v53, v81
	v_cmp_gt_i32_e64 s[28:29], s67, v80
	s_and_b64 s[0:1], s[28:29], s[0:1]
	v_add_u32_e32 v80, 19, v79
	v_add_u32_e32 v81, 0x1012, v79
	s_and_b64 s[28:29], s[48:49], s[0:1]
	v_cmp_le_i32_e64 s[0:1], v53, v81
	v_cmp_gt_i32_e64 s[30:31], s67, v80
	s_and_b64 s[0:1], s[30:31], s[0:1]
	v_add_u32_e32 v80, 18, v79
	v_add_u32_e32 v81, 0x1011, v79
	s_and_b64 s[30:31], s[48:49], s[0:1]
	v_cmp_le_i32_e64 s[0:1], v53, v81
	v_cmp_gt_i32_e64 s[34:35], s67, v80
	s_and_b64 s[0:1], s[34:35], s[0:1]
	v_add_u32_e32 v80, 17, v79
	v_add_u32_e32 v81, 0x1010, v79
	s_and_b64 s[34:35], s[48:49], s[0:1]
	v_cmp_le_i32_e64 s[0:1], v53, v81
	v_cmp_gt_i32_e64 s[36:37], s67, v80
	s_and_b64 s[0:1], s[36:37], s[0:1]
	v_add_u32_e32 v80, 16, v79
	v_add_u32_e32 v81, 0x100f, v79
	s_and_b64 s[36:37], s[48:49], s[0:1]
	v_cmp_le_i32_e64 s[0:1], v53, v81
	v_cmp_gt_i32_e64 s[38:39], s67, v80
	s_and_b64 s[0:1], s[38:39], s[0:1]
	v_add_u32_e32 v80, 3, v79
	v_add_u32_e32 v81, 0x1002, v79
	s_and_b64 s[38:39], s[48:49], s[0:1]
	v_cmp_le_i32_e64 s[0:1], v53, v81
	v_cmp_gt_i32_e64 s[40:41], s67, v80
	s_and_b64 s[0:1], s[40:41], s[0:1]
	v_add_u32_e32 v80, 2, v79
	v_add_u32_e32 v81, 0x1001, v79
	s_and_b64 s[40:41], s[48:49], s[0:1]
	v_cmp_le_i32_e64 s[0:1], v53, v81
	v_cmp_gt_i32_e64 s[42:43], s67, v80
	s_and_b64 s[0:1], s[42:43], s[0:1]
	v_add_u32_e32 v80, 1, v79
	v_add_u32_e32 v81, 0x1000, v79
	s_and_b64 s[42:43], s[48:49], s[0:1]
	v_cmp_le_i32_e64 s[0:1], v53, v81
	v_cmp_gt_i32_e64 s[44:45], s67, v80
	s_and_b64 s[0:1], s[44:45], s[0:1]
	v_add_u32_e32 v80, 0xfff, v79
	s_and_b64 s[44:45], s[48:49], s[0:1]
	v_cmp_le_i32_e64 s[0:1], v53, v80
	v_cmp_gt_i32_e64 s[46:47], s67, v79
	v_add_u32_e32 v79, s55, v62
	s_and_b64 s[0:1], s[46:47], s[0:1]
	v_add_u32_e32 v80, 32, v79
	v_cmp_gt_i32_e64 s[50:51], s67, v79
	v_add_u32_e32 v79, s72, v63
	s_and_b64 s[46:47], s[48:49], s[0:1]
	v_cmp_gt_i32_e64 s[0:1], s67, v80
	v_cndmask_b32_e64 v80, v74, v79, s[50:51]
	v_add_u32_e32 v79, 0x100, v79
	buffer_load_dwordx2 v[80:81], v80, s[60:63], 0 offen
	v_cndmask_b32_e64 v79, v74, v79, s[0:1]
	buffer_load_dwordx2 v[82:83], v79, s[60:63], 0 offen
	s_mov_b32 s58, s62
	s_mov_b32 s59, s63
	s_waitcnt vmcnt(1)
	v_lshl_add_u32 v79, v80, 10, v59
	v_cndmask_b32_e64 v79, v74, v79, s[50:51]
	NETRA_WAIT_VM0
	v_lshl_add_u32 v80, v82, 10, v59
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
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x128_f8f6f4 v[82:85], v[82:89], v[2:9], 0
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x128_f8f6f4 v[86:89], v[90:97], v[2:9], 0
	s_nop 9
	v_mul_f32_e32 v81, s33, v82
	v_mul_f32_e32 v82, s33, v83
	v_mul_f32_e32 v83, s33, v84
	v_mul_f32_e32 v84, s33, v85
	v_cndmask_b32_e64 v85, v75, v81, s[46:47]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x128_f8f6f4 v[90:93], v[114:121], v[2:9], 0
	v_mul_f32_e32 v114, s33, v86
	v_cndmask_b32_e64 v86, v75, v82, s[44:45]
	v_mul_f32_e32 v115, s33, v87
	v_mul_f32_e32 v116, s33, v88
	v_cndmask_b32_e64 v87, v75, v83, s[42:43]
	v_cndmask_b32_e64 v88, v75, v84, s[40:41]
.Ltmp35:
	v_max_f32_e32 v81, v85, v86
.Ltmp36:
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x128_f8f6f4 v[94:97], v[122:129], v[2:9], 0
	v_mul_f32_e32 v117, s33, v89
	s_nop 1
	v_mul_f32_e32 v118, s33, v90
	v_cndmask_b32_e64 v89, v75, v114, s[38:39]
	v_cndmask_b32_e64 v90, v75, v115, s[36:37]
.Ltmp37:
	v_max3_f32 v81, v81, v87, v88
.Ltmp38:
	v_mul_f32_e32 v119, s33, v91
	v_mul_f32_e32 v120, s33, v92
	v_cndmask_b32_e64 v91, v75, v116, s[34:35]
	v_cndmask_b32_e64 v92, v75, v117, s[30:31]
.Ltmp39:
	v_max3_f32 v81, v81, v89, v90
.Ltmp40:
	v_mul_f32_e32 v121, s33, v93
	v_mul_f32_e32 v122, s33, v94
	v_cndmask_b32_e64 v93, v75, v118, s[28:29]
	v_cndmask_b32_e64 v94, v75, v119, s[26:27]
.Ltmp41:
	v_max3_f32 v81, v81, v91, v92
.Ltmp42:
	v_mul_f32_e32 v123, s33, v95
	v_mul_f32_e32 v124, s33, v96
	v_cndmask_b32_e64 v95, v75, v120, s[24:25]
	v_cndmask_b32_e64 v96, v75, v121, s[22:23]
.Ltmp43:
	v_max3_f32 v81, v81, v93, v94
.Ltmp44:
	v_mul_f32_e32 v125, s33, v97
	v_cndmask_b32_e64 v97, v75, v122, s[20:21]
	v_cndmask_b32_e64 v83, v75, v123, s[18:19]
.Ltmp45:
	v_max3_f32 v81, v81, v95, v96
.Ltmp46:
	v_cndmask_b32_e64 v84, v75, v124, s[16:17]
	v_cndmask_b32_e64 v82, v75, v125, s[14:15]
.Ltmp47:
	v_max3_f32 v81, v81, v97, v83
	v_max3_f32 v81, v81, v84, v82
.Ltmp48:
	v_mov_b32_e32 v114, v81
	s_nop 1
	v_permlane32_swap_b32_e32 v81, v114
.Ltmp49:
	v_max_f32_e32 v114, v114, v114
	v_max_f32_e32 v81, v81, v81
	v_max_f32_e32 v81, v81, v114
.Ltmp50:
	v_mov_b32_e32 v114, v81
	s_nop 1
	v_permlane16_swap_b32_e32 v81, v114
.Ltmp51:
	v_max_f32_e32 v114, v114, v114
	v_max_f32_e32 v81, v81, v81
	v_max_f32_e32 v81, v81, v114
.Ltmp52:
	v_cmp_neq_f32_e64 s[0:1], s74, v81
	v_max_f32_e32 v114, v60, v60
	s_mov_b32 s14, s62
	v_cndmask_b32_e64 v81, v76, v81, s[0:1]
	v_max_f32_e32 v81, v81, v114
	v_sub_f32_e32 v60, v60, v81
	v_mul_f32_e32 v114, 0x3fb8aa3b, v60
	v_cmp_gt_f32_e64 s[0:1], s75, v114
	v_sub_f32_e32 v85, v85, v81
	v_sub_f32_e32 v86, v86, v81
	v_cndmask_b32_e64 v114, 0, v77, s[0:1]
	v_fmac_f32_e32 v114, 0x3fb8aa3b, v60
	v_exp_f32_e32 v60, v114
	v_cndmask_b32_e64 v114, 0, v78, s[0:1]
	v_sub_f32_e32 v87, v87, v81
	v_sub_f32_e32 v88, v88, v81
	v_ldexp_f32 v60, v60, v114
	v_mul_f32_e32 v114, 0x3fb8aa3b, v85
	v_cmp_gt_f32_e64 s[0:1], s75, v114
	v_sub_f32_e32 v89, v89, v81
	v_sub_f32_e32 v90, v90, v81
	v_cndmask_b32_e64 v114, 0, v77, s[0:1]
	v_fmac_f32_e32 v114, 0x3fb8aa3b, v85
	v_exp_f32_e32 v85, v114
	v_cndmask_b32_e64 v114, 0, v78, s[0:1]
	v_sub_f32_e32 v91, v91, v81
	v_sub_f32_e32 v92, v92, v81
	v_ldexp_f32 v114, v85, v114
	v_mul_f32_e32 v85, 0x3fb8aa3b, v86
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	v_sub_f32_e32 v93, v93, v81
	v_sub_f32_e32 v94, v94, v81
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v86
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	v_sub_f32_e32 v95, v95, v81
	v_sub_f32_e32 v96, v96, v81
	v_ldexp_f32 v115, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v87
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	v_sub_f32_e32 v97, v97, v81
	v_sub_f32_e32 v83, v83, v81
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v87
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	v_sub_f32_e32 v84, v84, v81
	v_sub_f32_e32 v82, v82, v81
	v_ldexp_f32 v116, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v88
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	s_mov_b32 s15, s63
	v_pk_mul_f32 v[40:41], v[40:41], v[60:61] op_sel_hi:[1,0]
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v88
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	v_pk_mul_f32 v[38:39], v[38:39], v[60:61] op_sel_hi:[1,0]
	v_pk_mul_f32 v[36:37], v[36:37], v[60:61] op_sel_hi:[1,0]
	v_ldexp_f32 v117, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v89
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	v_pk_mul_f32 v[34:35], v[34:35], v[60:61] op_sel_hi:[1,0]
	v_pk_mul_f32 v[32:33], v[32:33], v[60:61] op_sel_hi:[1,0]
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v89
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	v_pk_mul_f32 v[30:31], v[30:31], v[60:61] op_sel_hi:[1,0]
	v_pk_mul_f32 v[28:29], v[28:29], v[60:61] op_sel_hi:[1,0]
	v_ldexp_f32 v118, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v90
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	v_pk_mul_f32 v[26:27], v[26:27], v[60:61] op_sel_hi:[1,0]
	v_pk_mul_f32 v[24:25], v[24:25], v[60:61] op_sel_hi:[1,0]
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v90
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	v_pk_mul_f32 v[22:23], v[22:23], v[60:61] op_sel_hi:[1,0]
	v_pk_mul_f32 v[20:21], v[20:21], v[60:61] op_sel_hi:[1,0]
	v_ldexp_f32 v119, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v91
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	v_pk_mul_f32 v[18:19], v[18:19], v[60:61] op_sel_hi:[1,0]
	v_pk_mul_f32 v[16:17], v[16:17], v[60:61] op_sel_hi:[1,0]
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v91
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	v_pk_mul_f32 v[14:15], v[14:15], v[60:61] op_sel_hi:[1,0]
	v_pk_mul_f32 v[12:13], v[12:13], v[60:61] op_sel_hi:[1,0]
	v_ldexp_f32 v120, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v92
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	v_pk_mul_f32 v[10:11], v[10:11], v[60:61] op_sel_hi:[1,0]
	s_nop 0
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v92
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	v_cvt_scalef32_pk_fp8_f32 v92, v114, v115, 1.0
	v_cvt_scalef32_pk_fp8_f32 v92, v116, v117, 1.0 op_sel:[0,0,0,1]
	v_ldexp_f32 v121, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v93
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	s_nop 1
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v93
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	v_cvt_scalef32_pk_fp8_f32 v93, v118, v119, 1.0
	v_cvt_scalef32_pk_fp8_f32 v93, v120, v121, 1.0 op_sel:[0,0,0,1]
	v_ldexp_f32 v122, v85, v86
	v_mul_f32_e32 v85, 0x3fb8aa3b, v94
	v_cmp_gt_f32_e64 s[0:1], s75, v85
	v_permlane32_swap_b32_e32 v92, v93
	s_nop 0
	v_cndmask_b32_e64 v85, 0, v77, s[0:1]
	v_fmac_f32_e32 v85, 0x3fb8aa3b, v94
	v_exp_f32_e32 v85, v85
	v_cndmask_b32_e64 v86, 0, v78, s[0:1]
	v_permlane16_swap_b32_e32 v92, v93
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
	v_mov_b32_e32 v84, v82
	s_nop 1
	v_permlane32_swap_b32_e32 v82, v84
.Ltmp55:
	v_add_f32_e32 v82, v82, v84
.Ltmp56:
	v_mov_b32_e32 v84, v82
	s_nop 1
	v_permlane16_swap_b32_e32 v82, v84
.Ltmp57:
	v_add_f32_e32 v82, v82, v84
.Ltmp58:
	buffer_load_dwordx4 v[84:87], v79, s[12:15], 0 offen
	buffer_load_dwordx4 v[88:91], v80, s[12:15], 0 offen
	v_cvt_scalef32_pk_fp8_f32 v94, v122, v94, 1.0
	v_cvt_scalef32_pk_fp8_f32 v94, v95, v96, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v95, v97, v83, 1.0
	v_cvt_scalef32_pk_fp8_f32 v95, v123, v124, 1.0 op_sel:[0,0,0,1]
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
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_fp8_fp8 v[38:41], v[84:85], v[92:93], v[38:41]
	v_permlane32_swap_b32_e32 v94, v95
	s_nop 1
	v_permlane16_swap_b32_e32 v94, v95
	s_waitcnt lgkmcnt(11)
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[96:97], v[92:93], v[34:37]
	v_fmac_f32_e32 v82, v61, v60
	v_mov_b32_e32 v61, v82
	v_mov_b32_e32 v60, v81
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
	.endm
