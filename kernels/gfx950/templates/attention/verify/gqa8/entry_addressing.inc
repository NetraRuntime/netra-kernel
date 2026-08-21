// SPDX-License-Identifier: MIT
// Fixed raw gfx950 GQA8 entry addressing stage.
	.macro NETRA_ATTENTION_GQA8_ENTRY_ADDRESSING symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_M_MAX, 16
	NETRA_REQUIRE_EQ NETRA_QUERY_HEADS, 16
	NETRA_REQUIRE_EQ NETRA_KV_HEADS, 2
	NETRA_REQUIRE_EQ NETRA_HEAD_DIM, 256
	NETRA_REQUIRE_EQ NETRA_KV_LAYOUT_ID, 1
	.if (NETRA_QO_INDPTR_BITS != 32) && (NETRA_QO_INDPTR_BITS != 64)
	.error "NETRA_QO_INDPTR_BITS must be 32 or 64"
	.endif
	NETRA_KERNEL_ENTRY \symbol, 0
.Lfunc_begin0:
; %bb.10:
	NETRA_LOAD_KERNARG_PTR s[2:3], 0x0
	NETRA_LOAD_KERNARG_U32X8 s[4:11], 0x8
	NETRA_LOAD_KERNARG_U32X4 s[12:15], 0x28
	NETRA_LOAD_KERNARG_U32 s22, 0x4c
	NETRA_WAIT_LGKM0
	s_branch .LBB0_0
.Ltmp0:
	.p2align	8
; %bb.11:
.LBB0_0:
	s_mov_b64 s[24:25], s[2:3]
	s_load_dwordx2 s[2:3], s[0:1], 0x38
	s_mov_b64 s[44:45], s[10:11]
	s_mov_b64 s[40:41], s[6:7]
	s_mov_b32 s20, s16
.Ltmp1:
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_readfirstlane_b32 s11, v0
	s_ashr_i32 s21, s16, 31
	s_and_b32 s10, s11, 0x1c0
	; SGLang supplies either int32 eager qo_indptr or int64 piecewise-graph
	; qo_indptr. The bridge passes its element size through the ABI gap at 0x4c.
	; Supported token capacity is below 2^32, so only the low dword is consumed.
	.if NETRA_QO_INDPTR_BITS == 32
	s_branch .Lnetra_qo_i32
	.else
	s_nop 0
	.endif
	.if NETRA_QO_INDPTR_BITS == 32
	s_cbranch_scc1 .Lnetra_qo_i32
	.else
	s_nop 0
	.endif
	s_lshl_b64 s[6:7], s[20:21], 3
	s_add_u32 s14, s14, s6
	s_addc_u32 s15, s15, s7
	v_mov_b32_e32 v4, 0
	global_load_dword v2, v4, s[14:15]
	global_load_dword v3, v4, s[14:15] offset:8
	s_branch .Lnetra_qo_ready
.Lnetra_qo_i32:
	s_lshl_b64 s[6:7], s[20:21], 2
	s_add_u32 s14, s14, s6
	s_addc_u32 s15, s15, s7
	v_mov_b32_e32 v4, 0
	global_load_dword v2, v4, s[14:15]
	global_load_dword v3, v4, s[14:15] offset:4
.Lnetra_qo_ready:
	v_and_b32_e32 v64, 63, v0
	v_or_b32_e32 v57, s10, v64
	v_lshrrev_b32_e32 v59, 4, v57
	v_bfe_u32 v6, v57, 4, 4
	v_or_b32_e32 v58, 32, v59
	s_movk_i32 s14, 0x300
	v_lshlrev_b32_e32 v7, 12, v6
	v_lshlrev_b32_e32 v8, 4, v58
	v_and_or_b32 v8, v8, s14, v7
	v_and_b32_e32 v1, 15, v0
	v_lshlrev_b32_e32 v56, 4, v1
	v_or_b32_e32 v60, 8, v56
	v_bfrev_b32_e32 v5, 1
	s_mov_b32 s27, 0x27000
	s_mov_b32 s26, 0x7ffffffe
	v_lshlrev_b32_e32 v50, 5, v57
	v_and_b32_e32 v53, 48, v0
	v_lshlrev_b32_e32 v51, 3, v0
	v_lshlrev_b32_e32 v54, 2, v1
	NETRA_WAIT_VM0
	v_readfirstlane_b32 s63, v2
	v_readfirstlane_b32 s14, v3
	s_sub_i32 s57, s14, s63
	NETRA_WAIT_LGKM0
	; kv_indptr is always int32, independent of the qo_indptr representation.
	s_lshl_b64 s[6:7], s[20:21], 2
	s_add_u32 s2, s2, s6
	s_addc_u32 s3, s3, s7
	s_lshl_b32 s7, s18, 10
	s_lshl_b32 s15, s17, 11
	s_lshl_b32 s14, s63, 12
	s_add_i32 s33, s15, s7
	s_and_b32 s6, s11, 0x100
	s_add_i32 s33, s33, s14
	global_load_dwordx2 v[2:3], v4, s[2:3]
	v_or_b32_e32 v4, s6, v7
	v_or_b32_e32 v7, s33, v56
	v_or_b32_e32 v9, s33, v60
	v_add_lshl_u32 v10, v7, v4, 1
	v_cmp_gt_i32_e32 vcc, s57, v6
	s_and_b32 s25, s25, 0xffff
	v_add_lshl_u32 v4, v9, v4, 1
	v_add_lshl_u32 v7, v7, v8, 1
	v_add_lshl_u32 v8, v9, v8, 1
	v_cndmask_b32_e32 v6, v5, v10, vcc
	v_cndmask_b32_e32 v4, v5, v4, vcc
	v_cndmask_b32_e32 v7, v5, v7, vcc
	v_cndmask_b32_e32 v5, v5, v8, vcc
	buffer_load_dwordx4 v[96:99], v6, s[24:27], 0 offen
	buffer_load_dwordx4 v[92:95], v4, s[24:27], 0 offen
	buffer_load_dwordx4 v[104:107], v7, s[24:27], 0 offen
	buffer_load_dwordx4 v[100:103], v5, s[24:27], 0 offen
	v_mov_b32_e32 v4, 0xf0
	v_bitop3_b32 v62, s10, v4, v64 bitop3:0xc8
	v_lshlrev_b32_e32 v4, 1, v62
	s_and_b32 s54, s11, 0xc0
	v_xad_u32 v4, v4, v50, 0
	v_cmp_gt_i32_e64 s[2:3], s57, v1
	v_lshrrev_b32_e32 v52, 1, v62
	s_waitcnt vmcnt(3)
	ds_write_b128 v4, v[96:99]
	s_waitcnt vmcnt(2)
	ds_write_b128 v4, v[92:95] offset:16
	s_waitcnt vmcnt(1)
	ds_write_b128 v4, v[104:107] offset:16384
	NETRA_WAIT_VM0
	ds_write_b128 v4, v[100:103] offset:16400
	v_readfirstlane_b32 s14, v2
	v_readfirstlane_b32 s6, v3
	s_sub_i32 s66, s6, s14
	s_cmp_gt_i32 s66, 0
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	s_cbranch_scc1 .LBB0_2
; %bb.1:                                ; %.._crit_edge_crit_edge
	s_and_b32 s56, s11, 64
	s_and_b32 s58, s11, 0x80
	s_lshr_b32 s6, s11, 2
	s_lshl_b32 s65, s17, 8
	s_lshl_b32 s59, s56, 1
	s_lshr_b32 s60, s58, 1
	s_and_b32 s61, s6, 64
	s_mov_b64 s[6:7], 0
	s_branch .LBB0_3
	.endm
