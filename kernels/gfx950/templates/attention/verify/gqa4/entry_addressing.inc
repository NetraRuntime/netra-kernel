// SPDX-License-Identifier: MIT
// Fixed raw gfx950 GQA4 entry addressing stage.
	.macro NETRA_ATTENTION_GQA4_ENTRY_ADDRESSING symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_M_MAX, 16
	NETRA_REQUIRE_EQ NETRA_QUERY_HEADS, 32
	NETRA_REQUIRE_EQ NETRA_KV_HEADS, 8
	NETRA_REQUIRE_EQ NETRA_HEAD_DIM, 128
	NETRA_REQUIRE_EQ NETRA_KV_LAYOUT_ID, 1
	NETRA_KERNEL_ENTRY \symbol, 0
.Lfunc_begin0:
; %bb.10:
	NETRA_LOAD_KERNARG_PTR s[2:3], 0x0
	NETRA_LOAD_KERNARG_U32X8 s[4:11], 0x8
	NETRA_LOAD_KERNARG_U32X4 s[12:15], 0x28
	NETRA_WAIT_LGKM0
	s_branch .LBB0_0
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
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_readfirstlane_b32 s6, v0
	s_ashr_i32 s19, s18, 31
	s_and_b32 s16, s6, 0xc0
	s_lshl_b64 s[10:11], s[18:19], 3
	s_add_u32 s10, s14, s10
	s_addc_u32 s11, s15, s11
	v_mov_b32_e32 v5, 0
	global_load_dwordx4 v[42:45], v5, s[10:11]
	v_and_b32_e32 v51, 63, v0
	v_or_b32_e32 v55, s16, v51
	s_lshl_b64 s[10:11], s[18:19], 2
	v_lshrrev_b32_e32 v52, 3, v55
	NETRA_WAIT_LGKM0
	s_add_u32 s2, s2, s10
	v_or_b32_e32 v50, 32, v52
	v_and_b32_e32 v2, 7, v0
	v_bfe_u32 v4, v55, 3, 4
	s_addc_u32 s3, s3, s11
	v_lshrrev_b32_e32 v8, 4, v50
	s_lshl_b32 s64, s17, 2
	s_lshl_b32 s7, s17, 9
	s_and_b32 s10, s6, 0x80
	v_lshlrev_b32_e32 v54, 4, v2
	v_lshlrev_b32_e32 v3, 12, v4
	global_load_dwordx2 v[6:7], v5, s[2:3]
	v_or_b32_e32 v8, s64, v8
	s_or_b32 s2, s10, s7
	v_or_b32_e32 v56, 8, v54
	v_add_u32_e32 v9, s2, v3
	v_lshl_add_u32 v3, v8, 7, v3
	v_bfrev_b32_e32 v1, 1
	s_mov_b32 s23, 0x27000
	s_mov_b32 s22, 0x7ffffffe
	s_and_b32 s21, s21, 0xffff
	s_waitcnt vmcnt(1)
	v_sub_co_u32_e32 v46, vcc, v44, v42
	v_lshlrev_b64 v[48:49], 12, v[42:43]
	s_nop 0
	v_subb_co_u32_e32 v47, vcc, v45, v43, vcc
	v_or_b32_e32 v8, v48, v54
	v_or_b32_e32 v10, v48, v56
	v_add_lshl_u32 v11, v8, v9, 1
	v_cmp_gt_i64_e32 vcc, v[46:47], v[4:5]
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
	v_lshlrev_b32_e32 v3, 2, v0
	s_waitcnt vmcnt(4)
	v_readfirstlane_b32 s14, v6
	v_readfirstlane_b32 s2, v7
	v_and_b32_e32 v44, 15, v0
	v_mov_b32_e32 v45, v5
	v_and_b32_e32 v3, 0xe0, v3
	v_lshlrev_b32_e32 v49, 5, v55
	s_sub_i32 s67, s2, s14
	v_and_b32_e32 v1, 48, v0
	v_and_b32_e32 v43, 60, v0
	v_xad_u32 v3, v49, v3, 0
	v_cmp_gt_i64_e64 s[48:49], v[46:47], v[44:45]
	s_cmp_gt_i32 s67, 0
	v_lshlrev_b32_e32 v45, 3, v0
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
	s_cbranch_scc1 .LBB0_2
; %bb.1:                                ; %.._crit_edge_crit_edge
	s_lshl_b32 s66, s17, 7
	s_mov_b64 s[2:3], 0
	s_branch .LBB0_3
	.endm
