	// Fixed QO32/KV32 register schedule leaf.
	; DFlash verification attention: M=8, GQA6, D=256.
	; Grid = [batch, 4 KV heads, 3 query-head pairs].
	.macro NETRA_ATTENTION_GQA6_FP8KV_QO32_KV32 symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_M_MAX, 8
	NETRA_REQUIRE_EQ NETRA_QUERY_HEADS, 24
	NETRA_REQUIRE_EQ NETRA_KV_HEADS, 4
	NETRA_REQUIRE_EQ NETRA_HEAD_DIM, 256
	NETRA_REQUIRE_EQ NETRA_VALUE_TOKEN_STRIDE, 14336
	NETRA_REQUIRE_EQ NETRA_KV_LAYOUT_ID, 1
	NETRA_REQUIRE_EQ NETRA_QO_INDPTR_BITS, 32
	NETRA_REQUIRE_EQ NETRA_KV_INDEX_BITS, 32
	.text
	.globl	\symbol  ; -- Begin function \symbol
	.p2align	8
	.type	\symbol,@function
\symbol:         ; @\symbol
.Lfunc_begin0:
; %bb.10:
	s_load_dwordx2 s[2:3], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_waitcnt lgkmcnt(0)
	s_branch .LBB0_0
.Ltmp0:
	.p2align	8
; %bb.11:
.LBB0_0:
	s_mov_b64 s[24:25], s[2:3]
	s_load_dwordx2 s[2:3], s[0:1], 0x38
	s_mov_b64 s[48:49], s[10:11]
	s_mov_b64 s[44:45], s[6:7]
	s_mov_b32 s20, s16
.Ltmp1:
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	s_ashr_i32 s21, s16, 31
	s_lshl_b64 s[6:7], s[20:21], 2
	s_add_u32 s10, s14, s6
	s_addc_u32 s11, s15, s7
	v_mov_b32_e32 v4, 0
	global_load_dwordx2 v[2:3], v4, s[10:11]
	v_lshrrev_b32_e32 v5, 5, v0
	s_mul_i32 s10, s17, 0x600
	v_and_b32_e32 v1, 31, v0
	v_mul_u32_u24_e32 v14, 0x1800, v5
	v_lshl_or_b32 v14, v1, 3, v14
	v_bfrev_b32_e32 v6, 1
	v_or_b32_e32 v7, 2, v5
	v_or_b32_e32 v8, 4, v5
	v_or_b32_e32 v9, 6, v5
	v_or_b32_e32 v10, 8, v5
	v_or_b32_e32 v11, 10, v5
	v_or_b32_e32 v12, 12, v5
	v_or_b32_e32 v13, 14, v5
	s_mov_b32 s27, 0x27000
	s_mov_b32 s26, 0x7ffffffe
	v_and_b32_e32 v164, 15, v0
	v_and_b32_e32 v165, 48, v0
	v_and_b32_e32 v75, 60, v0
	v_lshrrev_b32_e32 v104, 1, v165
	v_lshlrev_b32_e32 v105, 3, v0
	s_waitcnt vmcnt(0)
	v_readfirstlane_b32 s90, v2
	v_readfirstlane_b32 s11, v3
	s_sub_i32 s88, s11, s90
	s_waitcnt lgkmcnt(0)
	s_add_u32 s2, s2, s6
	s_addc_u32 s3, s3, s7
	s_lshl_b32 s6, s18, 9
	s_mul_i32 s11, s90, 0x1800
	s_add_i32 s33, s6, s10
	s_add_i32 s33, s33, s11
	global_load_dwordx2 v[2:3], v4, s[2:3]
	v_add_lshl_u32 v4, v14, s33, 1
	v_cmp_gt_i32_e32 vcc, s88, v5
	v_or_b32_e32 v21, 0x200, v4
	s_and_b32 s25, s25, 0xffff
	v_cndmask_b32_e32 v5, v6, v4, vcc
	v_add_u32_e32 v14, 0x6000, v4
	v_add_u32_e32 v15, 0xc000, v4
	v_add_u32_e32 v16, 0x12000, v4
	v_add_u32_e32 v17, 0x18000, v4
	v_add_u32_e32 v18, 0x1e000, v4
	v_add_u32_e32 v19, 0x24000, v4
	v_add_u32_e32 v20, 0x2a000, v4
	v_add_u32_e32 v22, 0x6200, v4
	v_add_u32_e32 v23, 0xc200, v4
	v_add_u32_e32 v24, 0x12200, v4
	v_add_u32_e32 v25, 0x18200, v4
	v_add_u32_e32 v26, 0x1e200, v4
	v_add_u32_e32 v27, 0x24200, v4
	v_add_u32_e32 v4, 0x2a200, v4
	v_cmp_gt_i32_e64 s[2:3], s88, v7
	v_cmp_gt_i32_e64 s[6:7], s88, v8
	v_cmp_gt_i32_e64 s[10:11], s88, v9
	v_cmp_gt_i32_e64 s[14:15], s88, v10
	v_cmp_gt_i32_e64 s[18:19], s88, v11
	v_cmp_gt_i32_e64 s[20:21], s88, v12
	v_cmp_gt_i32_e64 s[22:23], s88, v13
	v_cndmask_b32_e32 v13, v6, v21, vcc
	buffer_load_dwordx4 a[0:3], v5, s[24:27], 0 offen
	v_cndmask_b32_e64 v5, v6, v14, s[2:3]
	v_cndmask_b32_e64 v7, v6, v15, s[6:7]
	v_cndmask_b32_e64 v8, v6, v16, s[10:11]
	v_cndmask_b32_e64 v9, v6, v17, s[14:15]
	v_cndmask_b32_e64 v10, v6, v18, s[18:19]
	v_cndmask_b32_e64 v11, v6, v19, s[20:21]
	v_cndmask_b32_e64 v12, v6, v20, s[22:23]
	v_cndmask_b32_e64 v14, v6, v22, s[2:3]
	v_cndmask_b32_e64 v15, v6, v23, s[6:7]
	v_cndmask_b32_e64 v16, v6, v24, s[10:11]
	v_cndmask_b32_e64 v17, v6, v25, s[14:15]
	v_cndmask_b32_e64 v18, v6, v26, s[18:19]
	v_cndmask_b32_e64 v19, v6, v27, s[20:21]
	v_cndmask_b32_e64 v4, v6, v4, s[22:23]
	buffer_load_dwordx4 a[60:63], v13, s[24:27], 0 offen
	buffer_load_dwordx4 a[52:55], v5, s[24:27], 0 offen
	buffer_load_dwordx4 a[56:59], v14, s[24:27], 0 offen
	buffer_load_dwordx4 a[44:47], v7, s[24:27], 0 offen
	buffer_load_dwordx4 a[48:51], v15, s[24:27], 0 offen
	buffer_load_dwordx4 a[36:39], v8, s[24:27], 0 offen
	buffer_load_dwordx4 a[40:43], v16, s[24:27], 0 offen
	buffer_load_dwordx4 a[28:31], v9, s[24:27], 0 offen
	buffer_load_dwordx4 a[32:35], v17, s[24:27], 0 offen
	buffer_load_dwordx4 a[20:23], v10, s[24:27], 0 offen
	buffer_load_dwordx4 a[24:27], v18, s[24:27], 0 offen
	buffer_load_dwordx4 a[12:15], v11, s[24:27], 0 offen
	buffer_load_dwordx4 a[16:19], v19, s[24:27], 0 offen
	buffer_load_dwordx4 a[4:7], v12, s[24:27], 0 offen
	buffer_load_dwordx4 a[8:11], v4, s[24:27], 0 offen
	v_and_b32_e32 v5, 32, v0
	v_bfe_i32 v4, v0, 5, 1
	s_movk_i32 s6, 0x220
	v_accvgpr_write_b32 a129, v5
	v_cmp_eq_u32_e64 s[2:3], 0, v5
	v_lshlrev_b32_e32 v5, 4, v1
	v_bitop3_b32 v4, v4, v5, s6 bitop3:0x6c
	v_accvgpr_write_b32 a148, v5
	v_add_u32_e32 v5, 0, v4
	v_xad_u32 v6, v4, 64, 0
	v_xor_b32_e32 v7, 0x80, v4
	v_xor_b32_e32 v8, 0xc0, v4
	v_xor_b32_e32 v9, 0x100, v4
	v_xor_b32_e32 v10, 0x140, v4
	v_xor_b32_e32 v11, 0x180, v4
	v_xor_b32_e32 v4, 0x1c0, v4
	v_cmp_gt_i32_e64 s[30:31], s88, v164
	v_add_u32_e32 v7, 0, v7
	v_add_u32_e32 v8, 0, v8
	v_add_u32_e32 v9, 0, v9
	v_add_u32_e32 v10, 0, v10
	v_add_u32_e32 v11, 0, v11
	v_add_u32_e32 v4, 0, v4
	s_waitcnt vmcnt(15)
	ds_write_b128 v5, a[0:3]
	s_waitcnt vmcnt(14)
	ds_write_b128 v5, a[60:63] offset:8192
	s_waitcnt vmcnt(13)
	ds_write_b128 v6, a[52:55] offset:1024
	s_waitcnt vmcnt(12)
	ds_write_b128 v6, a[56:59] offset:9216
	s_waitcnt vmcnt(11)
	ds_write_b128 v7, a[44:47] offset:2048
	s_waitcnt vmcnt(10)
	ds_write_b128 v7, a[48:51] offset:10240
	s_waitcnt vmcnt(9)
	ds_write_b128 v8, a[36:39] offset:3072
	s_waitcnt vmcnt(8)
	ds_write_b128 v8, a[40:43] offset:11264
	s_waitcnt vmcnt(7)
	ds_write_b128 v9, a[28:31] offset:4096
	s_waitcnt vmcnt(6)
	ds_write_b128 v9, a[32:35] offset:12288
	s_waitcnt vmcnt(5)
	ds_write_b128 v10, a[20:23] offset:5120
	s_waitcnt vmcnt(4)
	ds_write_b128 v10, a[24:27] offset:13312
	s_waitcnt vmcnt(3)
	ds_write_b128 v11, a[12:15] offset:6144
	s_waitcnt vmcnt(2)
	ds_write_b128 v11, a[16:19] offset:14336
	s_waitcnt vmcnt(1)
	ds_write_b128 v4, a[4:7] offset:7168
	s_waitcnt vmcnt(0)
	ds_write_b128 v4, a[8:11] offset:15360
	v_readfirstlane_b32 s6, v3
	v_readfirstlane_b32 s10, v2
	s_sub_i32 s92, s6, s10
	s_cmp_gt_i32 s92, 0
	s_waitcnt lgkmcnt(0)
	; wave barrier
	s_cbranch_scc1 .LBB0_2
; %bb.1:                                ; %.._crit_edge_crit_edge
	s_lshl_b32 s91, s17, 8
	s_mov_b64 s[6:7], 0
	s_branch .LBB0_3
.LBB0_2:
	s_mov_b64 s[6:7], -1
                                        ; implicit-def: $sgpr91
.LBB0_3:                                ; %Flow1286
	s_load_dword s89, s[0:1], 0x48
	v_lshrrev_b32_e32 v2, 2, v165
	v_accvgpr_write_b32 a144, v2
	v_lshrrev_b32_e32 v2, 4, v0
	v_accvgpr_write_b32 a146, v2
	v_lshlrev_b32_e32 v74, 4, v164
	s_andn2_b64 vcc, exec, s[6:7]
	v_mov_b32_e32 v181, 0
	v_mov_b32_e32 v180, 0
	v_mov_b32_e32 v43, 0
	v_mov_b32_e32 v42, 0
	v_mov_b32_e32 v45, 0
	v_mov_b32_e32 v44, 0
	v_mov_b32_e32 v47, 0
	v_mov_b32_e32 v46, 0
	v_mov_b32_e32 v49, 0
	v_mov_b32_e32 v48, 0
	v_mov_b32_e32 v51, 0
	v_mov_b32_e32 v50, 0
	v_mov_b32_e32 v53, 0
	v_mov_b32_e32 v52, 0
	v_mov_b32_e32 v77, 0
	v_mov_b32_e32 v76, 0
	v_mov_b32_e32 v79, 0
	v_mov_b32_e32 v78, 0
	v_mov_b32_e32 v81, 0
	v_mov_b32_e32 v80, 0
	v_mov_b32_e32 v83, 0
	v_mov_b32_e32 v82, 0
	v_mov_b32_e32 v55, 0
	v_mov_b32_e32 v54, 0
	v_mov_b32_e32 v57, 0
	v_mov_b32_e32 v56, 0
	v_mov_b32_e32 v59, 0
	v_mov_b32_e32 v58, 0
	v_mov_b32_e32 v61, 0
	v_mov_b32_e32 v60, 0
	v_mov_b32_e32 v63, 0
	v_mov_b32_e32 v62, 0
	v_mov_b32_e32 v65, 0
	v_mov_b32_e32 v64, 0
	v_mov_b32_e32 v67, 0
	v_mov_b32_e32 v66, 0
	v_mov_b32_e32 v69, 0
	v_mov_b32_e32 v68, 0
	v_mov_b32_e32 v71, 0
	v_mov_b32_e32 v70, 0
	v_mov_b32_e32 v73, 0
	v_mov_b32_e32 v72, 0
	v_mov_b32_e32 v85, 0
	v_mov_b32_e32 v84, 0
	v_mov_b32_e32 v87, 0
	v_mov_b32_e32 v86, 0
	v_mov_b32_e32 v89, 0
	v_mov_b32_e32 v88, 0
	v_mov_b32_e32 v91, 0
	v_mov_b32_e32 v90, 0
	v_mov_b32_e32 v93, 0
	v_mov_b32_e32 v92, 0
	v_mov_b32_e32 v95, 0
	v_mov_b32_e32 v94, 0
	v_mov_b32_e32 v97, 0
	v_mov_b32_e32 v96, 0
	v_mov_b32_e32 v99, 0
	v_mov_b32_e32 v98, 0
	v_mov_b32_e32 v101, 0
	v_mov_b32_e32 v100, 0
	v_mov_b32_e32 v103, 0
	v_mov_b32_e32 v102, 0
	v_accvgpr_write_b32 a133, 0
	v_accvgpr_write_b32 a132, 0
	v_accvgpr_write_b32 a135, 0
	v_accvgpr_write_b32 a134, 0
	v_accvgpr_write_b32 a137, 0
	v_accvgpr_write_b32 a136, 0
	v_accvgpr_write_b32 a139, 0
	v_accvgpr_write_b32 a138, 0
	v_accvgpr_write_b32 a141, 0
	v_accvgpr_write_b32 a140, 0
	v_accvgpr_write_b32 a143, 0
	v_accvgpr_write_b32 a142, 0
	v_mov_b32_e32 v107, 0
	v_mov_b32_e32 v106, 0
	v_mov_b32_e32 v109, 0
	v_mov_b32_e32 v108, 0
	v_mov_b32_e32 v111, 0
	v_mov_b32_e32 v110, 0
	v_mov_b32_e32 v113, 0
	v_mov_b32_e32 v112, 0
	v_mov_b32_e32 v115, 0
	v_mov_b32_e32 v114, 0
	v_mov_b32_e32 v117, 0
	v_mov_b32_e32 v116, 0
	v_mov_b32_e32 v119, 0
	v_mov_b32_e32 v118, 0
	v_mov_b32_e32 v121, 0
	v_mov_b32_e32 v120, 0
	v_mov_b32_e32 v123, 0
	v_mov_b32_e32 v122, 0
	v_mov_b32_e32 v125, 0
	v_mov_b32_e32 v124, 0
	v_mov_b32_e32 v127, 0
	v_mov_b32_e32 v126, 0
	v_mov_b32_e32 v129, 0
	v_mov_b32_e32 v128, 0
	v_mov_b32_e32 v131, 0
	v_mov_b32_e32 v130, 0
	v_mov_b32_e32 v133, 0
	v_mov_b32_e32 v132, 0
	v_mov_b32_e32 v135, 0
	v_mov_b32_e32 v134, 0
	v_mov_b32_e32 v137, 0
	v_mov_b32_e32 v136, 0
	v_mov_b32_e32 v139, 0
	v_mov_b32_e32 v138, 0
	v_mov_b32_e32 v141, 0
	v_mov_b32_e32 v140, 0
	v_mov_b32_e32 v143, 0
	v_mov_b32_e32 v142, 0
	v_mov_b32_e32 v145, 0
	v_mov_b32_e32 v144, 0
	v_mov_b32_e32 v147, 0
	v_mov_b32_e32 v146, 0
	v_mov_b32_e32 v149, 0
	v_mov_b32_e32 v148, 0
	v_mov_b32_e32 v151, 0
	v_mov_b32_e32 v150, 0
	v_mov_b32_e32 v153, 0
	v_mov_b32_e32 v152, 0
	v_mov_b32_e32 v155, 0
	v_mov_b32_e32 v154, 0
	v_mov_b32_e32 v157, 0
	v_mov_b32_e32 v156, 0
	v_mov_b32_e32 v159, 0
	v_mov_b32_e32 v158, 0
	v_mov_b32_e32 v161, 0
	v_mov_b32_e32 v160, 0
	v_mov_b32_e32 v234, 0xff800000
	v_mov_b32_e32 v235, 0xff800000
	s_cbranch_vccnz .LBB0_9
; %bb.4:                                ; %.lr.ph
	s_cmp_gt_i32 s88, 0
	s_cselect_b64 s[46:47], -1, 0
	s_cmp_gt_i32 s88, 1
	s_cselect_b64 s[56:57], -1, 0
	s_cmp_gt_i32 s88, 2
	s_cselect_b64 s[58:59], -1, 0
	s_cmp_gt_i32 s88, 3
	s_cselect_b64 s[60:61], -1, 0
	s_cmp_gt_i32 s88, 4
	s_cselect_b64 s[62:63], -1, 0
	s_cmp_gt_i32 s88, 5
	s_cselect_b64 s[64:65], -1, 0
	s_cmp_gt_i32 s88, 6
	v_mul_u32_u24_e32 v2, 0x220, v164
	v_lshlrev_b32_e32 v3, 1, v165
	s_cselect_b64 s[66:67], -1, 0
	s_cmp_gt_i32 s88, 7
	v_xor_b32_e32 v2, v2, v3
	s_cselect_b64 s[68:69], -1, 0
	s_cmp_gt_i32 s88, 8
	v_xor_b32_e32 v3, 0x180, v2
	s_cselect_b64 s[70:71], -1, 0
	s_cmp_gt_i32 s88, 9
	v_add_u32_e32 v3, 0, v3
	s_cselect_b64 s[72:73], -1, 0
	s_cmp_gt_i32 s88, 10
	ds_read_b128 v[32:35], v3 offset:8208
	ds_read_b128 v[36:39], v3 offset:8192
	ds_read_b128 v[14:17], v3
	ds_read_b128 v[18:21], v3 offset:16
	v_xor_b32_e32 v3, 0x100, v2
	s_cselect_b64 s[74:75], -1, 0
	s_cmp_gt_i32 s88, 11
	v_add_u32_e32 v3, 0, v3
	s_cselect_b64 s[76:77], -1, 0
	s_cmp_gt_i32 s88, 12
	ds_read_b128 v[28:31], v3 offset:8208
	ds_read_b128 v[40:43], v3 offset:8192
	ds_read_b128 v[10:13], v3
	ds_read_b128 v[22:25], v3 offset:16
	v_xor_b32_e32 v3, 0x80, v2
	s_cselect_b64 s[78:79], -1, 0
	s_cmp_gt_i32 s88, 13
	v_add_u32_e32 v3, 0, v3
	v_add_u32_e32 v26, 0, v2
	s_cselect_b64 s[80:81], -1, 0
	s_cmp_gt_i32 s88, 14
	ds_read_b128 v[44:47], v3 offset:8208
	ds_read_b128 v[48:51], v3 offset:8192
	ds_read_b128 v[6:9], v3
	ds_read_b128 v[52:55], v3 offset:16
	ds_read_b128 v[56:59], v26 offset:8208
	ds_read_b128 v[60:63], v26 offset:8192
	ds_read_b128 v[2:5], v26
	ds_read_b128 v[64:67], v26 offset:16
	v_lshlrev_b32_e32 v26, 6, v0
	s_waitcnt lgkmcnt(0)
	v_cvt_scalef32_pk_fp8_bf16 v28, v28, 1.0
	s_cselect_b64 s[82:83], -1, 0
	s_cmp_gt_i32 s88, 15
	v_and_b32_e32 v26, 0xc0, v26
	v_cvt_scalef32_pk_fp8_bf16 v28, v29, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v29, v30, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v32, v32, 1.0
	s_cselect_b64 s[84:85], -1, 0
	v_lshlrev_b32_e32 v1, 2, v1
	v_add_u32_e32 v162, 0, v26
	s_lshl_b32 s91, s17, 8
	v_cvt_scalef32_pk_fp8_bf16 v29, v31, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v31, v38, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v32, v33, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v33, v34, 1.0
	v_lshlrev_b32_e32 v34, 4, v0
	v_accvgpr_write_b32 a145, v74
	v_or_b32_e32 v186, s91, v74
	v_cvt_scalef32_pk_fp8_bf16 v31, v39, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v33, v35, 1.0 op_sel:[0,0,1]
	v_xor_b32_e32 v35, v34, v165
	v_mul_u32_u24_e32 v39, 0x110, v164
	v_xor_b32_e32 v34, v34, v104
	v_add_u32_e32 v74, 0, v1
	v_add_u32_e32 v1, v162, v75
	v_lshlrev_b32_e32 v163, 2, v165
	v_accvgpr_write_b32 a147, v165
	v_xor_b32_e32 v39, v39, v165
	v_xor_b32_e32 v165, 8, v34
	v_accvgpr_write_b32 a149, v1
	v_add_u32_e32 v1, 0, v34
	s_load_dwordx2 s[52:53], s[0:1], 0x40
	v_xor_b32_e32 v166, 32, v34
	v_accvgpr_write_b32 a150, v1
	v_add_u32_e32 v1, 0, v165
	v_cvt_scalef32_pk_fp8_bf16 v10, v10, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v14, v14, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v27, v42, 1.0
	v_xor_b32_e32 v167, 40, v34
	v_lshlrev_b32_e32 v42, 2, v0
	v_accvgpr_write_b32 a151, v1
	v_add_u32_e32 v1, 0, v166
	v_cvt_scalef32_pk_fp8_bf16 v2, v2, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v6, v6, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v10, v11, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v11, v12, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v14, v15, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v15, v16, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v27, v43, 1.0 op_sel:[0,0,1]
	v_xor_b32_e32 v170, 0x60, v34
	v_lshl_or_b32 v42, v0, 7, v42
	v_and_b32_e32 v43, 8, v105
	s_movk_i32 s0, 0x1f78
	v_accvgpr_write_b32 a152, v1
	v_add_u32_e32 v1, 0, v167
	v_cvt_scalef32_pk_fp8_bf16 v2, v3, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v3, v4, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v6, v7, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v7, v8, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v11, v13, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v12, v22, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v13, v24, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v15, v17, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v16, v18, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v17, v20, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v26, v40, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v30, v36, 1.0
	v_xor_b32_e32 v171, 0x68, v34
	v_bitop3_b32 v172, v42, v43, s0 bitop3:0x6c
	v_accvgpr_write_b32 a153, v1
	v_add_u32_e32 v1, 0, v170
	v_cvt_scalef32_pk_fp8_bf16 v3, v5, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v4, v64, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v5, v66, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v7, v9, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v8, v52, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v9, v54, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v12, v23, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v13, v25, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v16, v19, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v17, v21, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v18, v60, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v19, v62, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v20, v56, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v21, v58, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v22, v48, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v23, v50, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v24, v44, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v25, v46, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v26, v41, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v30, v37, 1.0 op_sel:[0,0,1]
	v_xor_b32_e32 v36, 64, v35
	v_xor_b32_e32 v37, 0x80, v35
	v_xor_b32_e32 v38, 0xc0, v35
	v_accvgpr_write_b32 a128, v164
	v_xor_b32_e32 v40, 64, v39
	v_xor_b32_e32 v41, 0x80, v39
	v_xor_b32_e32 v164, 0xc0, v39
	v_xor_b32_e32 v168, 64, v34
	v_xor_b32_e32 v169, 0x48, v34
	v_xor_b32_e32 v173, 16, v172
	v_xor_b32_e32 v174, 32, v172
	v_xor_b32_e32 v175, 48, v172
	v_xor_b32_e32 v176, 64, v172
	v_xor_b32_e32 v177, 0x50, v172
	v_xor_b32_e32 v178, 0x60, v172
	v_xor_b32_e32 v179, 0x70, v172
	v_accvgpr_write_b32 a154, v1
	v_add_u32_e32 v1, 0, v171
	s_mov_b32 s93, 0
	s_waitcnt lgkmcnt(0)
	s_and_b32 s53, s53, 0xffff
	s_mov_b32 s55, 0x27000
	s_mov_b32 s54, 0x7ffffffe
	s_and_b32 s49, s49, 0xffff
	v_cvt_scalef32_pk_fp8_bf16 v4, v65, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v5, v67, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v8, v53, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v9, v55, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v18, v61, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v19, v63, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v20, v57, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v21, v59, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v22, v49, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v23, v51, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v24, v45, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v25, v47, 1.0 op_sel:[0,0,1]
	s_and_b32 s13, s13, 0xffff
	v_add_lshl_u32 v187, s10, v0, 2
	v_mov_b32_e32 v188, 0xff800000
	v_mov_b32_e32 v160, 0
	v_mov_b32_e32 v161, 0
	v_mov_b32_e32 v158, 0
	v_mov_b32_e32 v159, 0
	v_mov_b32_e32 v156, 0
	v_mov_b32_e32 v157, 0
	v_mov_b32_e32 v154, 0
	v_mov_b32_e32 v155, 0
	v_mov_b32_e32 v152, 0
	v_mov_b32_e32 v153, 0
	v_mov_b32_e32 v150, 0
	v_mov_b32_e32 v151, 0
	v_mov_b32_e32 v148, 0
	v_mov_b32_e32 v149, 0
	v_mov_b32_e32 v146, 0
	v_mov_b32_e32 v147, 0
	v_mov_b32_e32 v144, 0
	v_mov_b32_e32 v145, 0
	v_mov_b32_e32 v142, 0
	v_mov_b32_e32 v143, 0
	v_mov_b32_e32 v140, 0
	v_mov_b32_e32 v141, 0
	v_mov_b32_e32 v138, 0
	v_mov_b32_e32 v139, 0
	v_mov_b32_e32 v136, 0
	v_mov_b32_e32 v137, 0
	v_mov_b32_e32 v134, 0
	v_mov_b32_e32 v135, 0
	v_mov_b32_e32 v132, 0
	v_mov_b32_e32 v133, 0
	v_mov_b32_e32 v130, 0
	v_mov_b32_e32 v131, 0
	v_mov_b32_e32 v128, 0
	v_mov_b32_e32 v129, 0
	v_mov_b32_e32 v126, 0
	v_mov_b32_e32 v127, 0
	v_mov_b32_e32 v124, 0
	v_mov_b32_e32 v125, 0
	v_mov_b32_e32 v122, 0
	v_mov_b32_e32 v123, 0
	v_mov_b32_e32 v120, 0
	v_mov_b32_e32 v121, 0
	v_mov_b32_e32 v118, 0
	v_mov_b32_e32 v119, 0
	v_mov_b32_e32 v116, 0
	v_mov_b32_e32 v117, 0
	v_mov_b32_e32 v114, 0
	v_mov_b32_e32 v115, 0
	v_mov_b32_e32 v112, 0
	v_mov_b32_e32 v113, 0
	v_mov_b32_e32 v110, 0
	v_mov_b32_e32 v111, 0
	v_mov_b32_e32 v108, 0
	v_mov_b32_e32 v109, 0
	v_mov_b32_e32 v106, 0
	v_mov_b32_e32 v107, 0
	v_accvgpr_write_b32 a142, 0
	v_accvgpr_write_b32 a143, 0
	v_accvgpr_write_b32 a140, 0
	v_accvgpr_write_b32 a141, 0
	v_accvgpr_write_b32 a138, 0
	v_accvgpr_write_b32 a139, 0
	v_accvgpr_write_b32 a136, 0
	v_accvgpr_write_b32 a137, 0
	v_accvgpr_write_b32 a134, 0
	v_accvgpr_write_b32 a135, 0
	v_accvgpr_write_b32 a132, 0
	v_accvgpr_write_b32 a133, 0
	v_mov_b32_e32 v102, 0
	v_mov_b32_e32 v103, 0
	v_mov_b32_e32 v100, 0
	v_mov_b32_e32 v101, 0
	v_mov_b32_e32 v98, 0
	v_mov_b32_e32 v99, 0
	v_mov_b32_e32 v96, 0
	v_mov_b32_e32 v97, 0
	v_mov_b32_e32 v94, 0
	v_mov_b32_e32 v95, 0
	v_mov_b32_e32 v92, 0
	v_mov_b32_e32 v93, 0
	v_mov_b32_e32 v90, 0
	v_mov_b32_e32 v91, 0
	v_mov_b32_e32 v88, 0
	v_mov_b32_e32 v89, 0
	v_mov_b32_e32 v86, 0
	v_mov_b32_e32 v87, 0
	v_mov_b32_e32 v84, 0
	v_mov_b32_e32 v85, 0
	v_mov_b32_e32 v72, 0
	v_mov_b32_e32 v73, 0
	v_mov_b32_e32 v70, 0
	v_mov_b32_e32 v71, 0
	v_mov_b32_e32 v68, 0
	v_mov_b32_e32 v69, 0
	v_mov_b32_e32 v66, 0
	v_mov_b32_e32 v67, 0
	v_mov_b32_e32 v64, 0
	v_mov_b32_e32 v65, 0
	v_mov_b32_e32 v62, 0
	v_mov_b32_e32 v63, 0
	v_mov_b32_e32 v60, 0
	v_mov_b32_e32 v61, 0
	v_mov_b32_e32 v58, 0
	v_mov_b32_e32 v59, 0
	v_mov_b32_e32 v56, 0
	v_mov_b32_e32 v57, 0
	v_mov_b32_e32 v54, 0
	v_mov_b32_e32 v55, 0
	v_mov_b32_e32 v82, 0
	v_mov_b32_e32 v83, 0
	v_mov_b32_e32 v80, 0
	v_mov_b32_e32 v81, 0
	v_mov_b32_e32 v78, 0
	v_mov_b32_e32 v79, 0
	v_mov_b32_e32 v76, 0
	v_mov_b32_e32 v77, 0
	v_mov_b32_e32 v52, 0
	v_mov_b32_e32 v53, 0
	v_mov_b32_e32 v50, 0
	v_mov_b32_e32 v51, 0
	v_mov_b32_e32 v48, 0
	v_mov_b32_e32 v49, 0
	v_mov_b32_e32 v46, 0
	v_mov_b32_e32 v47, 0
	v_mov_b32_e32 v44, 0
	v_mov_b32_e32 v45, 0
	v_mov_b32_e32 v42, 0
	v_mov_b32_e32 v43, 0
	v_mov_b32_e32 v180, 0
	v_mov_b32_e32 v181, 0
	v_add_u32_e32 v191, 0, v163
	v_add_u32_e32 v192, 0, v35
	v_add_u32_e32 v193, 0, v36
	v_add_u32_e32 v194, 0, v37
	v_add_u32_e32 v195, 0, v38
	v_add_u32_e32 v196, 0, v39
	v_add_u32_e32 v197, 0, v40
	v_add_u32_e32 v198, 0, v41
	v_add_u32_e32 v199, 0, v164
	s_mov_b32 s94, 0xff800000
	s_mov_b32 s95, 0xc2fc0000
	v_add_u32_e32 v189, 0, v168
	v_add_u32_e32 v190, 0, v169
	v_accvgpr_write_b32 a155, v1
	v_add_u32_e32 v208, 0, v172
	v_add_u32_e32 v209, 0, v173
	v_add_u32_e32 v210, 0, v174
	v_add_u32_e32 v211, 0, v175
	v_add_u32_e32 v212, 0, v176
	v_add_u32_e32 v213, 0, v177
	v_add_u32_e32 v214, 0, v178
	v_add_u32_e32 v215, 0, v179
	v_mov_b32_e32 v216, 0
	v_bfrev_b32_e32 v217, 1
	v_mov_b32_e32 v219, 0x42800000
	v_not_b32_e32 v220, 63
	v_mov_b32_e32 v235, 0xff800000
	v_mov_b32_e32 v234, 0xff800000
	s_branch .LBB0_6
.LBB0_5:                                ;   in Loop: Header=BB0_6 Depth=1
	s_or_b64 exec, exec, s[86:87]
	s_add_i32 s93, s93, 64
	s_cmp_lt_i32 s93, s92
	v_add_u32_e32 v187, 0x100, v187
	s_cbranch_scc0 .LBB0_8
.LBB0_6:                                ; =>This Inner Loop Header: Depth=1
	v_add_u32_e32 v1, s93, v0
	v_cmp_gt_i32_e32 vcc, s92, v1
	s_and_b64 s[0:1], s[46:47], vcc
	v_cndmask_b32_e64 v1, 0, 1, s[0:1]
	s_and_b64 s[0:1], s[56:57], vcc
	v_cndmask_b32_e64 v34, 0, 1, s[0:1]
.Ltmp2:
	v_max_i32_dpp v1, v1, v1 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp3:
	s_and_b64 s[0:1], s[58:59], vcc
	v_cndmask_b32_e64 v35, 0, 1, s[0:1]
.Ltmp4:
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp5:
	s_and_b64 s[0:1], s[60:61], vcc
	v_cndmask_b32_e64 v36, 0, 1, s[0:1]
.Ltmp6:
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp7:
	s_and_b64 s[0:1], s[62:63], vcc
	v_cndmask_b32_e64 v37, 0, 1, s[0:1]
.Ltmp8:
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp9:
	v_mov_b32_e32 v169, v1
.Ltmp10:
	s_and_b64 s[0:1], s[64:65], vcc
	v_cndmask_b32_e64 v38, 0, 1, s[0:1]
.Ltmp11:
	v_mov_b32_dpp v169, v169 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp12:
	v_max_i32_e32 v1, v1, v169
.Ltmp13:
	s_and_b64 s[0:1], s[66:67], vcc
	v_cndmask_b32_e64 v39, 0, 1, s[0:1]
.Ltmp14:
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp15:
	s_and_b64 s[0:1], s[68:69], vcc
.Ltmp16:
	v_readlane_b32 s16, v1, 63
.Ltmp17:
	v_max_i32_dpp v1, v34, v34 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp18:
	v_cndmask_b32_e64 v40, 0, 1, s[0:1]
	s_and_b64 s[0:1], s[70:71], vcc
.Ltmp19:
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp20:
	v_cndmask_b32_e64 v41, 0, 1, s[0:1]
	s_and_b64 s[0:1], s[72:73], vcc
.Ltmp21:
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp22:
	v_cndmask_b32_e64 v162, 0, 1, s[0:1]
	s_and_b64 s[0:1], s[74:75], vcc
.Ltmp23:
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp24:
	v_mov_b32_e32 v34, v1
.Ltmp25:
	v_cndmask_b32_e64 v163, 0, 1, s[0:1]
	s_and_b64 s[0:1], s[76:77], vcc
.Ltmp26:
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp27:
	v_max_i32_e32 v1, v1, v34
.Ltmp28:
	v_cndmask_b32_e64 v164, 0, 1, s[0:1]
	s_and_b64 s[0:1], s[78:79], vcc
.Ltmp29:
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp30:
	v_cndmask_b32_e64 v165, 0, 1, s[0:1]
.Ltmp31:
	v_readlane_b32 s17, v1, 63
.Ltmp32:
	v_max_i32_dpp v1, v35, v35 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp33:
	s_and_b64 s[0:1], s[80:81], vcc
	v_cndmask_b32_e64 v166, 0, 1, s[0:1]
.Ltmp34:
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp35:
	s_and_b64 s[0:1], s[82:83], vcc
	v_cndmask_b32_e64 v167, 0, 1, s[0:1]
.Ltmp36:
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp37:
	s_and_b64 s[0:1], s[84:85], vcc
	v_cndmask_b32_e64 v168, 0, 1, s[0:1]
.Ltmp38:
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp39:
	v_mov_b32_e32 v34, v1
.Ltmp40:
	s_waitcnt lgkmcnt(0)
.Ltmp41:
	; wave barrier
	s_nop 0
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp42:
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp43:
	s_nop 0
	v_readlane_b32 s18, v1, 63
.Ltmp44:
	v_max_i32_dpp v1, v36, v36 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp45:
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp46:
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp47:
	s_nop 0
	v_readlane_b32 s19, v1, 63
.Ltmp48:
	v_max_i32_dpp v1, v37, v37 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp49:
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp50:
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp51:
	s_nop 0
	v_readlane_b32 s20, v1, 63
.Ltmp52:
	v_max_i32_dpp v1, v38, v38 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp53:
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp54:
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp55:
	s_nop 0
	v_readlane_b32 s21, v1, 63
.Ltmp56:
	v_max_i32_dpp v1, v39, v39 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp57:
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp58:
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp59:
	s_nop 0
	v_readlane_b32 s22, v1, 63
.Ltmp60:
	v_max_i32_dpp v1, v40, v40 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp61:
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp62:
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp63:
	s_nop 0
	v_readlane_b32 s23, v1, 63
.Ltmp64:
	v_max_i32_dpp v1, v41, v41 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp65:
	s_nop 0
	v_mov_b64_e32 v[40:41], s[22:23]
.Ltmp66:
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp67:
	v_mov_b64_e32 v[38:39], s[20:21]
	ds_write_b128 v216, v[38:41] offset:16
.Ltmp68:
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp69:
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp70:
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp71:
	s_nop 0
	v_readlane_b32 s24, v1, 63
.Ltmp72:
	v_max_i32_dpp v1, v162, v162 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp73:
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp74:
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp75:
	s_nop 0
	v_readlane_b32 s25, v1, 63
.Ltmp76:
	v_max_i32_dpp v1, v163, v163 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp77:
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp78:
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp79:
	s_nop 0
	v_readlane_b32 s26, v1, 63
.Ltmp80:
	v_max_i32_dpp v1, v164, v164 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp81:
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp82:
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp83:
	s_nop 0
	v_readlane_b32 s27, v1, 63
.Ltmp84:
	v_max_i32_dpp v1, v165, v165 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp85:
	s_nop 0
	v_mov_b64_e32 v[164:165], s[26:27]
.Ltmp86:
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp87:
	v_mov_b64_e32 v[162:163], s[24:25]
	ds_write_b128 v216, v[162:165] offset:32
.Ltmp88:
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp89:
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp90:
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp91:
	s_nop 0
	v_readlane_b32 s36, v1, 63
.Ltmp92:
	v_max_i32_dpp v1, v166, v166 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp93:
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp94:
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp95:
	s_nop 0
	v_readlane_b32 s37, v1, 63
.Ltmp96:
	v_max_i32_dpp v1, v167, v167 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp97:
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp98:
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp99:
	s_nop 0
	v_readlane_b32 s38, v1, 63
.Ltmp100:
	v_max_i32_dpp v1, v168, v168 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp101:
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp102:
	v_max_i32_e32 v1, v1, v34
.Ltmp103:
	v_mov_b64_e32 v[36:37], s[18:19]
	v_mov_b64_e32 v[34:35], s[16:17]
.Ltmp104:
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp105:
	ds_write_b128 v216, v[34:37]
.Ltmp106:
	v_readlane_b32 s39, v1, 63
.Ltmp107:
	s_nop 1
	v_mov_b64_e32 v[168:169], s[38:39]
	v_mov_b64_e32 v[166:167], s[36:37]
	ds_write_b128 v216, v[166:169] offset:48
	ds_write_b128 v216, v[34:37] offset:64
	ds_write_b128 v216, v[38:41] offset:80
	ds_write_b128 v216, v[162:165] offset:96
	ds_write_b128 v216, v[166:169] offset:112
	; wave barrier
	ds_read_b32 v1, v74
	s_waitcnt lgkmcnt(0)
	ds_swizzle_b32 v34, v1 offset:swizzle(SWAP,16)
.Ltmp108:
	s_waitcnt lgkmcnt(0)
	v_max_i32_e32 v1, v1, v34
.Ltmp109:
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_shr:8 row_mask:0xf bank_mask:0xc
	s_nop 1
	v_mov_b32_dpp v34, v1 row_shl:8 row_mask:0xf bank_mask:0x3
.Ltmp110:
	v_max_i32_e32 v1, v1, v34
.Ltmp111:
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_shr:4 row_mask:0xf bank_mask:0xa
	s_nop 1
	v_mov_b32_dpp v34, v1 row_shl:4 row_mask:0xf bank_mask:0x5
.Ltmp112:
	v_max_i32_e32 v1, v1, v34
.Ltmp113:
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
.Ltmp114:
	v_max_i32_e32 v1, v1, v34
.Ltmp115:
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
.Ltmp116:
	v_max_i32_e32 v1, v1, v34
.Ltmp117:
	v_cmp_ne_u32_e64 s[0:1], 0, v1
	s_and_saveexec_b64 s[86:87], s[0:1]
	s_cbranch_execz .LBB0_5
; %bb.7:                                ;   in Loop: Header=BB0_6 Depth=1
	v_cndmask_b32_e32 v162, v217, v187, vcc
	buffer_load_dword v178, v162, s[52:55], 0 offen
	v_accvgpr_read_b32 v179, a149
	v_accvgpr_write_b32 a130, v180
	v_accvgpr_read_b32 v1, a146
	s_waitcnt lgkmcnt(0)
	; wave barrier
	v_accvgpr_write_b32 a131, v181
	v_add_u32_e32 v1, s93, v1
	v_add_u32_e32 v184, 20, v1
	v_add_u32_e32 v185, 16, v1
	v_add_u32_e32 v183, 24, v1
	v_cmp_gt_i32_e64 s[16:17], s92, v185
	v_cmp_gt_i32_e64 s[18:19], s92, v184
	v_add_u32_e32 v182, 28, v1
	v_cmp_gt_i32_e64 s[20:21], s92, v183
	v_add_u32_e32 v41, 32, v1
	v_cmp_gt_i32_e64 s[22:23], s92, v182
	v_add_u32_e32 v40, 36, v1
	v_cmp_gt_i32_e64 s[24:25], s92, v41
	v_add_u32_e32 v39, 40, v1
	v_cmp_gt_i32_e64 s[26:27], s92, v40
	v_add_u32_e32 v38, 44, v1
	v_cmp_gt_i32_e64 s[28:29], s92, v39
	v_add_u32_e32 v37, 48, v1
	v_cmp_gt_i32_e64 s[34:35], s92, v38
	v_add_u32_e32 v36, 52, v1
	v_cmp_gt_i32_e64 s[36:37], s92, v37
	v_add_u32_e32 v35, 56, v1
	v_add_u32_e32 v200, 12, v1
	v_add_u32_e32 v201, 8, v1
	v_add_u32_e32 v202, 4, v1
	v_cmp_gt_i32_e32 vcc, s92, v1
	v_cmp_gt_i32_e64 s[38:39], s92, v36
	v_add_u32_e32 v34, 60, v1
	v_cmp_gt_i32_e64 s[0:1], s92, v202
	v_cmp_gt_i32_e64 s[6:7], s92, v201
	v_cmp_gt_i32_e64 s[10:11], s92, v200
	v_cmp_gt_i32_e64 s[40:41], s92, v35
	s_mov_b32 s50, s54
	s_mov_b32 s51, s55
	v_cmp_gt_i32_e64 s[42:43], s92, v34
	s_mov_b32 s14, s54
	s_mov_b32 s15, s55
	s_waitcnt vmcnt(0)
	ds_write_b32 v179, v178
	; wave barrier
	ds_read_b128 v[162:165], v191
	ds_read_b128 v[166:169], v191 offset:16
	ds_read_b128 v[170:173], v191 offset:32
	ds_read_b128 v[174:177], v191 offset:48
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_write_b32 v179, v178
	; wave barrier
	ds_read_b128 v[178:181], v191
	ds_read_b128 v[222:225], v191 offset:16
	ds_read_b128 v[236:239], v191 offset:32
	ds_read_b128 v[240:243], v191 offset:48
	v_lshl_add_u32 v162, v162, 10, v186
	s_waitcnt lgkmcnt(3)
	v_lshl_add_u32 v178, v178, 10, v186
	s_waitcnt lgkmcnt(2)
	v_lshl_add_u32 v185, v223, 10, v186
	v_cndmask_b32_e64 v184, v217, v185, s[18:19]
	v_lshl_add_u32 v185, v224, 10, v186
	v_cndmask_b32_e64 v183, v217, v185, s[20:21]
	v_lshl_add_u32 v185, v225, 10, v186
	v_cndmask_b32_e64 v182, v217, v185, s[22:23]
	s_waitcnt lgkmcnt(1)
	v_lshl_add_u32 v185, v236, 10, v186
	v_cndmask_b32_e64 v41, v217, v185, s[24:25]
	v_lshl_add_u32 v185, v237, 10, v186
	v_cndmask_b32_e64 v40, v217, v185, s[26:27]
	v_lshl_add_u32 v185, v238, 10, v186
	v_cndmask_b32_e64 v39, v217, v185, s[28:29]
	v_lshl_add_u32 v185, v239, 10, v186
	v_cndmask_b32_e64 v38, v217, v185, s[34:35]
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u32 v185, v240, 10, v186
	v_cndmask_b32_e64 v37, v217, v185, s[36:37]
	v_lshl_add_u32 v185, v241, 10, v186
	v_cndmask_b32_e32 v1, v217, v178, vcc
	v_lshl_add_u32 v178, v179, 10, v186
	v_lshl_add_u32 v179, v180, 10, v186
	v_lshl_add_u32 v180, v181, 10, v186
	v_lshl_add_u32 v181, v222, 10, v186
	v_cndmask_b32_e64 v36, v217, v185, s[38:39]
	v_lshl_add_u32 v185, v242, 10, v186
	v_cndmask_b32_e64 v178, v217, v178, s[0:1]
	v_cndmask_b32_e64 v179, v217, v179, s[6:7]
	v_cndmask_b32_e64 v180, v217, v180, s[10:11]
	v_cndmask_b32_e64 v181, v217, v181, s[16:17]
	v_cndmask_b32_e64 v35, v217, v185, s[40:41]
	v_lshl_add_u32 v185, v243, 10, v186
	v_cndmask_b32_e64 v34, v217, v185, s[42:43]
	buffer_load_dwordx4 v[202:205], v1, s[48:51], 0 offen
	buffer_load_dwordx4 v[222:225], v178, s[48:51], 0 offen
	buffer_load_dwordx4 v[226:229], v179, s[48:51], 0 offen
	buffer_load_dwordx4 v[230:233], v180, s[48:51], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[178:181], v181, s[48:51], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[236:239], v184, s[48:51], 0 offen
	buffer_load_dwordx4 v[240:243], v183, s[48:51], 0 offen
	buffer_load_dwordx4 v[244:247], v182, s[48:51], 0 offen
	buffer_load_dwordx4 v[248:251], v41, s[48:51], 0 offen
	buffer_load_dwordx4 v[252:255], v40, s[48:51], 0 offen
	buffer_load_dwordx4 a[64:67], v39, s[48:51], 0 offen
	buffer_load_dwordx4 a[68:71], v38, s[48:51], 0 offen
	buffer_load_dwordx4 a[72:75], v37, s[48:51], 0 offen
	buffer_load_dwordx4 a[76:79], v36, s[48:51], 0 offen
	buffer_load_dwordx4 a[80:83], v35, s[48:51], 0 offen
	buffer_load_dwordx4 a[84:87], v34, s[48:51], 0 offen
	v_lshl_add_u32 v1, v163, 10, v186
	v_lshl_add_u32 v34, v164, 10, v186
	v_lshl_add_u32 v35, v165, 10, v186
	v_lshl_add_u32 v163, v172, 10, v186
	v_lshl_add_u32 v164, v173, 10, v186
	v_lshl_add_u32 v165, v174, 10, v186
	s_waitcnt lgkmcnt(0)
	; wave barrier
	v_lshl_add_u32 v39, v169, 10, v186
	v_cndmask_b32_e32 v169, v217, v162, vcc
	v_cndmask_b32_e64 v182, v217, v163, s[28:29]
	v_cndmask_b32_e64 v200, v217, v164, s[34:35]
	v_cndmask_b32_e64 v201, v217, v165, s[36:37]
	v_lshl_add_u32 v36, v166, 10, v186
	v_lshl_add_u32 v37, v167, 10, v186
	v_lshl_add_u32 v38, v168, 10, v186
	v_lshl_add_u32 v40, v170, 10, v186
	v_lshl_add_u32 v166, v175, 10, v186
	v_lshl_add_u32 v167, v176, 10, v186
	v_lshl_add_u32 v168, v177, 10, v186
	v_lshl_add_u32 v41, v171, 10, v186
	v_cndmask_b32_e64 v34, v217, v34, s[6:7]
	v_cndmask_b32_e64 v35, v217, v35, s[10:11]
	v_cndmask_b32_e64 v36, v217, v36, s[16:17]
	v_cndmask_b32_e64 v37, v217, v37, s[18:19]
	v_cndmask_b32_e64 v40, v217, v40, s[24:25]
	v_cndmask_b32_e64 v166, v217, v166, s[38:39]
	v_cndmask_b32_e64 v167, v217, v167, s[40:41]
	v_cndmask_b32_e64 v168, v217, v168, s[42:43]
	v_cndmask_b32_e64 v1, v217, v1, s[0:1]
	v_cndmask_b32_e64 v38, v217, v38, s[20:21]
	v_cndmask_b32_e64 v39, v217, v39, s[22:23]
	v_cndmask_b32_e64 v41, v217, v41, s[26:27]
	s_waitcnt vmcnt(15)
	ds_write_b128 v192, v[202:205]
	s_waitcnt vmcnt(14)
	ds_write_b128 v193, v[222:225] offset:1024
	s_waitcnt vmcnt(13)
	ds_write_b128 v194, v[226:229] offset:2048
	s_waitcnt vmcnt(12)
	ds_write_b128 v195, v[230:233] offset:3072
	s_waitcnt vmcnt(11)
	ds_write_b128 v192, v[178:181] offset:4096
	s_waitcnt vmcnt(10)
	ds_write_b128 v193, v[236:239] offset:5120
	s_waitcnt vmcnt(9)
	ds_write_b128 v194, v[240:243] offset:6144
	s_waitcnt vmcnt(8)
	ds_write_b128 v195, v[244:247] offset:7168
	s_waitcnt vmcnt(7)
	ds_write_b128 v192, v[248:251] offset:8192
	s_waitcnt vmcnt(6)
	ds_write_b128 v193, v[252:255] offset:9216
	s_waitcnt vmcnt(5)
	ds_write_b128 v194, a[64:67] offset:10240
	s_waitcnt vmcnt(4)
	ds_write_b128 v195, a[68:71] offset:11264
	s_waitcnt vmcnt(3)
	ds_write_b128 v192, a[72:75] offset:12288
	s_waitcnt vmcnt(2)
	ds_write_b128 v193, a[76:79] offset:13312
	s_waitcnt vmcnt(1)
	ds_write_b128 v194, a[80:83] offset:14336
	s_waitcnt vmcnt(0)
	ds_write_b128 v195, a[84:87] offset:15360
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_read_b128 a[64:67], v196
	ds_read_b128 a[72:75], v196 offset:4096
	ds_read_b128 a[80:83], v196 offset:8192
	ds_read_b128 a[88:91], v196 offset:12288
	ds_read_b128 a[68:71], v197
	ds_read_b128 a[76:79], v197 offset:4096
	ds_read_b128 a[84:87], v197 offset:8192
	ds_read_b128 a[92:95], v197 offset:12288
	ds_read_b128 a[96:99], v198
	ds_read_b128 a[104:107], v198 offset:4096
	ds_read_b128 a[112:115], v198 offset:8192
	ds_read_b128 a[120:123], v198 offset:12288
	ds_read_b128 a[100:103], v199
	ds_read_b128 a[108:111], v199 offset:4096
	ds_read_b128 a[116:119], v199 offset:8192
	ds_read_b128 a[124:127], v199 offset:12288
	s_waitcnt lgkmcnt(11)
	v_mfma_f32_16x16x128_f8f6f4 v[162:165], a[64:71], v[2:9], 0
	buffer_load_dwordx4 v[178:181], v169, s[12:15], 0 offen
	buffer_load_dwordx4 v[222:225], v1, s[12:15], 0 offen
	buffer_load_dwordx4 v[236:239], v34, s[12:15], 0 offen
	buffer_load_dwordx4 v[170:173], v35, s[12:15], 0 offen
	buffer_load_dwordx4 v[240:243], v36, s[12:15], 0 offen
	buffer_load_dwordx4 v[244:247], v37, s[12:15], 0 offen
	buffer_load_dwordx4 v[248:251], v38, s[12:15], 0 offen
	buffer_load_dwordx4 v[174:177], v39, s[12:15], 0 offen
	v_accvgpr_read_b32 v1, a150
	v_accvgpr_read_b32 v38, a151
	v_accvgpr_read_b32 v39, a152
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x128_f8f6f4 v[252:255], a[96:103], v[10:17], v[162:165]
	buffer_load_dwordx4 v[230:233], v40, s[12:15], 0 offen
	buffer_load_dwordx4 v[226:229], v41, s[12:15], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[182:185], v182, s[12:15], 0 offen
	s_nop 2
	buffer_load_dwordx4 v[162:165], v200, s[12:15], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[200:203], v201, s[12:15], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[204:207], v166, s[12:15], 0 offen
	buffer_load_dwordx4 v[34:37], v167, s[12:15], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[166:169], v168, s[12:15], 0 offen
	s_waitcnt lgkmcnt(0)
	; wave barrier
	v_accvgpr_read_b32 v40, a153
	s_waitcnt vmcnt(11)
	ds_write2st64_b64 v1, v[178:179], v[240:241] offset1:8
	ds_write2st64_b64 v38, v[180:181], v[242:243] offset1:8
	v_mfma_f32_16x16x128_f8f6f4 v[178:181], a[72:79], v[2:9], 0
	s_waitcnt vmcnt(10)
	ds_write2st64_b64 v39, v[222:223], v[244:245] offset0:2 offset1:10
	ds_write2st64_b64 v40, v[224:225], v[246:247] offset0:2 offset1:10
	s_waitcnt vmcnt(9)
	ds_write2st64_b64 v189, v[236:237], v[248:249] offset0:4 offset1:12
	ds_write2st64_b64 v190, v[238:239], v[250:251] offset0:4 offset1:12
	s_waitcnt vmcnt(3)
	ds_write2st64_b64 v1, v[230:231], v[200:201] offset0:16 offset1:24
	ds_write2st64_b64 v38, v[232:233], v[202:203] offset0:16 offset1:24
	s_waitcnt vmcnt(2)
	ds_write2st64_b64 v39, v[226:227], v[204:205] offset0:18 offset1:26
	ds_write2st64_b64 v40, v[228:229], v[206:207] offset0:18 offset1:26
	s_waitcnt vmcnt(1)
	ds_write2st64_b64 v189, v[182:183], v[34:35] offset0:20 offset1:28
	v_mfma_f32_16x16x128_f8f6f4 v[226:229], a[88:95], v[2:9], 0
	ds_write2st64_b64 v190, v[184:185], v[36:37] offset0:20 offset1:28
	v_accvgpr_read_b32 v1, a144
	v_add_u32_e32 v1, s93, v1
	v_add_u32_e32 v38, 51, v1
	v_add_u32_e32 v39, 50, v1
	v_add_u32_e32 v40, 49, v1
	v_add_u32_e32 v41, 48, v1
	v_mfma_f32_16x16x128_f8f6f4 v[34:37], a[80:87], v[2:9], 0
	v_cmp_gt_i32_e32 vcc, s92, v38
	v_add_u32_e32 v38, 35, v1
	v_cmp_gt_i32_e64 s[0:1], s92, v39
	v_add_u32_e32 v39, 34, v1
	v_cmp_gt_i32_e64 s[6:7], s92, v40
	v_add_u32_e32 v40, 33, v1
	v_cmp_gt_i32_e64 s[10:11], s92, v41
	v_mfma_f32_16x16x128_f8f6f4 v[182:185], a[64:71], v[18:25], 0
	v_add_u32_e32 v41, 32, v1
	v_cmp_gt_i32_e64 s[14:15], s92, v38
	v_add_u32_e32 v38, 19, v1
	v_cmp_gt_i32_e64 s[16:17], s92, v39
	v_add_u32_e32 v39, 18, v1
	v_cmp_gt_i32_e64 s[18:19], s92, v40
	v_add_u32_e32 v40, 17, v1
	v_mfma_f32_16x16x128_f8f6f4 v[178:181], a[104:111], v[10:17], v[178:181]
	v_cmp_gt_i32_e64 s[20:21], s92, v41
	v_add_u32_e32 v41, 16, v1
	v_cmp_gt_i32_e64 s[22:23], s92, v38
	v_add_u32_e32 v38, 3, v1
	v_cmp_gt_i32_e64 s[24:25], s92, v39
	v_add_u32_e32 v39, 2, v1
	v_cmp_gt_i32_e64 s[26:27], s92, v1
	v_mfma_f32_16x16x128_f8f6f4 v[200:203], a[72:79], v[18:25], 0
	v_add_u32_e32 v1, 1, v1
	v_cmp_gt_i32_e64 s[40:41], s92, v1
	v_cmp_gt_i32_e64 s[28:29], s92, v40
	v_cmp_gt_i32_e64 s[36:37], s92, v38
	v_cmp_gt_i32_e64 s[38:39], s92, v39
	v_mul_f32_e32 v1, s89, v252
	v_mul_f32_e32 v38, s89, v253
	v_mfma_f32_16x16x128_f8f6f4 v[226:229], a[120:127], v[10:17], v[226:229]
	s_and_b64 s[26:27], s[30:31], s[26:27]
	s_and_b64 s[40:41], s[30:31], s[40:41]
	v_cmp_gt_i32_e64 s[34:35], s92, v41
	v_mul_f32_e32 v39, s89, v254
	v_mul_f32_e32 v40, s89, v255
	v_mul_f32_e32 v41, s89, v178
	v_mul_f32_e32 v178, s89, v179
	v_mfma_f32_16x16x128_f8f6f4 v[204:207], a[80:87], v[18:25], 0
	v_cndmask_b32_e64 v1, v188, v1, s[26:27]
	v_cndmask_b32_e64 v38, v188, v38, s[40:41]
	s_and_b64 s[38:39], s[30:31], s[38:39]
	s_and_b64 s[36:37], s[30:31], s[36:37]
	s_and_b64 s[28:29], s[30:31], s[28:29]
	v_mul_f32_e32 v218, s89, v227
	v_cndmask_b32_e64 v39, v188, v39, s[38:39]
	v_mfma_f32_16x16x128_f8f6f4 v[34:37], a[112:119], v[10:17], v[34:37]
	v_cndmask_b32_e64 v40, v188, v40, s[36:37]
	s_and_b64 s[34:35], s[30:31], s[34:35]
	v_cndmask_b32_e64 v227, v188, v178, s[28:29]
.Ltmp118:
	v_max_f32_e32 v178, v1, v38
.Ltmp119:
	v_mul_f32_e32 v179, s89, v180
	v_mul_f32_e32 v180, s89, v181
	v_cndmask_b32_e64 v41, v188, v41, s[34:35]
	v_mfma_f32_16x16x128_f8f6f4 v[222:225], a[88:95], v[18:25], 0
	s_and_b64 s[24:25], s[30:31], s[24:25]
	s_and_b64 s[22:23], s[30:31], s[22:23]
.Ltmp120:
	v_max3_f32 v178, v178, v39, v40
.Ltmp121:
	v_mul_f32_e32 v221, s89, v228
	v_mul_f32_e32 v34, s89, v34
	v_mul_f32_e32 v35, s89, v35
	v_cndmask_b32_e64 v228, v188, v179, s[24:25]
	v_mfma_f32_16x16x128_f8f6f4 v[182:185], a[96:103], v[26:33], v[182:185]
	v_cndmask_b32_e64 v180, v188, v180, s[22:23]
	s_and_b64 s[20:21], s[30:31], s[20:21]
	s_and_b64 s[18:19], s[30:31], s[18:19]
.Ltmp122:
	v_max3_f32 v178, v178, v41, v227
.Ltmp123:
	v_mul_f32_e32 v36, s89, v36
	v_mul_f32_e32 v37, s89, v37
	v_cndmask_b32_e64 v34, v188, v34, s[20:21]
	v_mfma_f32_16x16x128_f8f6f4 v[200:203], a[104:111], v[26:33], v[200:203]
	v_cndmask_b32_e64 v35, v188, v35, s[18:19]
	s_and_b64 s[16:17], s[30:31], s[16:17]
	s_and_b64 s[14:15], s[30:31], s[14:15]
.Ltmp124:
	v_max3_f32 v178, v178, v228, v180
.Ltmp125:
	v_mul_f32_e32 v181, s89, v226
	v_cndmask_b32_e64 v36, v188, v36, s[16:17]
	v_cndmask_b32_e64 v37, v188, v37, s[14:15]
	v_mfma_f32_16x16x128_f8f6f4 v[204:207], a[112:119], v[26:33], v[204:207]
	s_and_b64 s[10:11], s[30:31], s[10:11]
	s_and_b64 s[6:7], s[30:31], s[6:7]
.Ltmp126:
	v_max3_f32 v178, v178, v34, v35
.Ltmp127:
	v_mul_f32_e32 v226, s89, v229
	v_mul_f32_e32 v182, s89, v182
	v_mul_f32_e32 v183, s89, v183
	v_cndmask_b32_e64 v181, v188, v181, s[10:11]
	v_mfma_f32_16x16x128_f8f6f4 v[222:225], a[120:127], v[26:33], v[222:225]
	v_cndmask_b32_e64 v218, v188, v218, s[6:7]
	s_and_b64 s[0:1], s[30:31], s[0:1]
	s_and_b64 vcc, s[30:31], vcc
.Ltmp128:
	v_max3_f32 v178, v178, v36, v37
.Ltmp129:
	v_mul_f32_e32 v184, s89, v184
	v_mul_f32_e32 v185, s89, v185
	v_cndmask_b32_e64 v229, v188, v221, s[0:1]
	v_cndmask_b32_e32 v226, v188, v226, vcc
	v_cndmask_b32_e64 v182, v188, v182, s[26:27]
	v_cndmask_b32_e64 v183, v188, v183, s[40:41]
.Ltmp130:
	v_max3_f32 v178, v178, v181, v218
.Ltmp131:
	v_mul_f32_e32 v200, s89, v200
	v_mul_f32_e32 v201, s89, v201
	v_cndmask_b32_e64 v184, v188, v184, s[38:39]
	v_cndmask_b32_e64 v185, v188, v185, s[36:37]
.Ltmp132:
	v_max3_f32 v178, v178, v229, v226
	v_max_f32_e32 v179, v182, v183
.Ltmp133:
	v_mul_f32_e32 v202, s89, v202
	v_mul_f32_e32 v203, s89, v203
	v_cndmask_b32_e64 v200, v188, v200, s[34:35]
	v_cndmask_b32_e64 v201, v188, v201, s[28:29]
.Ltmp134:
	v_max3_f32 v179, v179, v184, v185
.Ltmp135:
	v_mov_b32_e32 v221, v178
.Ltmp136:
	v_mul_f32_e32 v204, s89, v204
	v_mul_f32_e32 v205, s89, v205
	v_cndmask_b32_e64 v202, v188, v202, s[24:25]
	v_cndmask_b32_e64 v203, v188, v203, s[22:23]
.Ltmp137:
	v_max3_f32 v179, v179, v200, v201
.Ltmp138:
	v_permlane32_swap_b32_e32 v178, v221
.Ltmp139:
	v_mul_f32_e32 v206, s89, v206
	v_mul_f32_e32 v207, s89, v207
	v_cndmask_b32_e64 v204, v188, v204, s[20:21]
	v_cndmask_b32_e64 v205, v188, v205, s[18:19]
.Ltmp140:
	v_max3_f32 v179, v179, v202, v203
	v_max_f32_e32 v221, v221, v221
	v_max_f32_e32 v178, v178, v178
.Ltmp141:
	v_mul_f32_e32 v222, s89, v222
	v_mul_f32_e32 v223, s89, v223
	v_cndmask_b32_e64 v206, v188, v206, s[16:17]
	v_cndmask_b32_e64 v207, v188, v207, s[14:15]
.Ltmp142:
	v_max3_f32 v179, v179, v204, v205
	v_max_f32_e32 v178, v178, v221
.Ltmp143:
	v_mul_f32_e32 v224, s89, v224
	v_mul_f32_e32 v225, s89, v225
	v_cndmask_b32_e64 v230, v188, v222, s[10:11]
	v_cndmask_b32_e64 v223, v188, v223, s[6:7]
.Ltmp144:
	v_max3_f32 v179, v179, v206, v207
.Ltmp145:
	v_mov_b32_e32 v221, v178
.Ltmp146:
	v_cndmask_b32_e64 v224, v188, v224, s[0:1]
	v_cndmask_b32_e32 v225, v188, v225, vcc
.Ltmp147:
	v_max3_f32 v179, v179, v230, v223
.Ltmp148:
	v_permlane16_swap_b32_e32 v178, v221
.Ltmp149:
	v_max3_f32 v179, v179, v224, v225
	v_max_f32_e32 v221, v221, v221
	v_max_f32_e32 v178, v178, v178
	v_max_f32_e32 v178, v178, v221
.Ltmp150:
	v_mov_b32_e32 v221, v179
	s_nop 1
	v_permlane32_swap_b32_e32 v179, v221
.Ltmp151:
	v_max_f32_e32 v221, v221, v221
	v_max_f32_e32 v179, v179, v179
	v_max_f32_e32 v179, v179, v221
.Ltmp152:
	v_mov_b32_e32 v221, v179
	s_nop 1
	v_permlane16_swap_b32_e32 v179, v221
.Ltmp153:
	v_max_f32_e32 v221, v221, v221
	v_max_f32_e32 v179, v179, v179
	v_max_f32_e32 v179, v179, v221
.Ltmp154:
	v_cmp_neq_f32_e32 vcc, s94, v178
	v_mov_b32_e32 v221, 0xe0ad78ec
	s_nop 0
	v_cndmask_b32_e32 v178, v221, v178, vcc
	v_cmp_neq_f32_e32 vcc, s94, v179
	s_nop 1
	v_cndmask_b32_e32 v179, v221, v179, vcc
	v_max_f32_e32 v221, v235, v235
	v_max_f32_e32 v221, v178, v221
	v_max_f32_e32 v178, v234, v234
	v_max_f32_e32 v222, v179, v178
	v_sub_f32_e32 v178, v235, v221
	v_mul_f32_e32 v231, 0x3fb8aa3b, v178
	v_cmp_gt_f32_e32 vcc, s95, v231
	v_sub_f32_e32 v179, v234, v222
	v_sub_f32_e32 v1, v1, v221
	v_cndmask_b32_e32 v231, 0, v219, vcc
	v_fmac_f32_e32 v231, 0x3fb8aa3b, v178
	v_exp_f32_e32 v178, v231
	v_mul_f32_e32 v231, 0x3fb8aa3b, v179
	v_cmp_gt_f32_e64 s[0:1], s95, v231
	v_sub_f32_e32 v38, v38, v221
	v_sub_f32_e32 v249, v185, v222
	v_cndmask_b32_e64 v231, 0, v219, s[0:1]
	v_fmac_f32_e32 v231, 0x3fb8aa3b, v179
	v_exp_f32_e32 v179, v231
	v_cndmask_b32_e32 v231, 0, v220, vcc
	v_ldexp_f32 v178, v178, v231
	v_cndmask_b32_e64 v231, 0, v220, s[0:1]
	v_ldexp_f32 v179, v179, v231
	v_sub_f32_e32 v231, v229, v221
	v_sub_f32_e32 v229, v207, v222
	v_mul_f32_e32 v207, 0x3fb8aa3b, v1
	v_cmp_gt_f32_e32 vcc, s95, v207
	v_sub_f32_e32 v185, v223, v222
	v_sub_f32_e32 v39, v39, v221
	v_cndmask_b32_e32 v207, 0, v219, vcc
	v_fmac_f32_e32 v207, 0x3fb8aa3b, v1
	v_exp_f32_e32 v1, v207
	v_cndmask_b32_e32 v207, 0, v220, vcc
	v_sub_f32_e32 v40, v40, v221
	v_sub_f32_e32 v247, v184, v222
	v_ldexp_f32 v223, v1, v207
	v_mul_f32_e32 v1, 0x3fb8aa3b, v38
	v_cmp_gt_f32_e32 vcc, s95, v1
	v_sub_f32_e32 v184, v230, v222
	v_sub_f32_e32 v230, v224, v222
	v_cndmask_b32_e32 v1, 0, v219, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v38
	v_mul_f32_e32 v38, 0x3fb8aa3b, v39
	v_cmp_gt_f32_e64 s[0:1], s95, v38
	v_exp_f32_e32 v1, v1
	v_sub_f32_e32 v41, v41, v221
	v_cndmask_b32_e64 v38, 0, v219, s[0:1]
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v39
	v_exp_f32_e32 v38, v38
	v_cndmask_b32_e32 v39, 0, v220, vcc
	v_ldexp_f32 v224, v1, v39
	v_cndmask_b32_e64 v1, 0, v220, s[0:1]
	v_sub_f32_e32 v232, v225, v222
	v_ldexp_f32 v225, v38, v1
	v_mul_f32_e32 v1, 0x3fb8aa3b, v40
	v_cmp_gt_f32_e32 vcc, s95, v1
	v_mul_f32_e32 v38, 0x3fb8aa3b, v41
	v_cmp_gt_f32_e64 s[0:1], s95, v38
	v_cndmask_b32_e32 v1, 0, v219, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v40
	v_cndmask_b32_e64 v38, 0, v219, s[0:1]
	v_exp_f32_e32 v1, v1
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v41
	v_exp_f32_e32 v38, v38
	v_cndmask_b32_e32 v39, 0, v220, vcc
	v_sub_f32_e32 v227, v227, v221
	v_ldexp_f32 v233, v1, v39
	v_cndmask_b32_e64 v1, 0, v220, s[0:1]
	v_sub_f32_e32 v228, v228, v221
	v_ldexp_f32 v234, v38, v1
	v_mul_f32_e32 v1, 0x3fb8aa3b, v227
	v_cmp_gt_f32_e32 vcc, s95, v1
	v_mul_f32_e32 v38, 0x3fb8aa3b, v228
	v_cmp_gt_f32_e64 s[0:1], s95, v38
	v_cndmask_b32_e32 v1, 0, v219, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v227
	v_cndmask_b32_e64 v38, 0, v219, s[0:1]
	v_exp_f32_e32 v1, v1
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v228
	v_exp_f32_e32 v38, v38
	v_cndmask_b32_e32 v39, 0, v220, vcc
	v_sub_f32_e32 v180, v180, v221
	v_ldexp_f32 v235, v1, v39
	v_cndmask_b32_e64 v1, 0, v220, s[0:1]
	v_sub_f32_e32 v34, v34, v221
	v_ldexp_f32 v236, v38, v1
	v_mul_f32_e32 v1, 0x3fb8aa3b, v180
	v_cmp_gt_f32_e32 vcc, s95, v1
	v_mul_f32_e32 v38, 0x3fb8aa3b, v34
	v_cmp_gt_f32_e64 s[0:1], s95, v38
	v_cndmask_b32_e32 v1, 0, v219, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v180
	v_cndmask_b32_e64 v38, 0, v219, s[0:1]
	v_exp_f32_e32 v1, v1
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v34
	v_exp_f32_e32 v34, v38
	v_cndmask_b32_e32 v38, 0, v220, vcc
	v_sub_f32_e32 v35, v35, v221
	v_ldexp_f32 v237, v1, v38
	v_cndmask_b32_e64 v1, 0, v220, s[0:1]
	v_sub_f32_e32 v36, v36, v221
	v_ldexp_f32 v238, v34, v1
	v_mul_f32_e32 v1, 0x3fb8aa3b, v35
	v_cmp_gt_f32_e32 vcc, s95, v1
	v_mul_f32_e32 v34, 0x3fb8aa3b, v36
	v_cmp_gt_f32_e64 s[0:1], s95, v34
	v_cndmask_b32_e32 v1, 0, v219, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v35
	v_cndmask_b32_e64 v34, 0, v219, s[0:1]
	v_exp_f32_e32 v1, v1
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v36
	v_exp_f32_e32 v34, v34
	v_cndmask_b32_e32 v35, 0, v220, vcc
	v_sub_f32_e32 v37, v37, v221
	v_ldexp_f32 v239, v1, v35
	v_cndmask_b32_e64 v1, 0, v220, s[0:1]
	v_sub_f32_e32 v181, v181, v221
	v_ldexp_f32 v240, v34, v1
	v_mul_f32_e32 v1, 0x3fb8aa3b, v37
	v_cmp_gt_f32_e32 vcc, s95, v1
	v_mul_f32_e32 v34, 0x3fb8aa3b, v181
	v_cmp_gt_f32_e64 s[0:1], s95, v34
	v_cndmask_b32_e32 v1, 0, v219, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v37
	v_cndmask_b32_e64 v34, 0, v219, s[0:1]
	v_exp_f32_e32 v1, v1
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v181
	v_exp_f32_e32 v34, v34
	v_cndmask_b32_e32 v35, 0, v220, vcc
	v_sub_f32_e32 v218, v218, v221
	v_ldexp_f32 v241, v1, v35
	v_cndmask_b32_e64 v1, 0, v220, s[0:1]
	v_ldexp_f32 v242, v34, v1
	v_mul_f32_e32 v1, 0x3fb8aa3b, v218
	v_cmp_gt_f32_e32 vcc, s95, v1
	v_mul_f32_e32 v34, 0x3fb8aa3b, v231
	v_cmp_gt_f32_e64 s[0:1], s95, v34
	v_cndmask_b32_e32 v1, 0, v219, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v218
	v_cndmask_b32_e64 v34, 0, v219, s[0:1]
	v_exp_f32_e32 v1, v1
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v231
	v_exp_f32_e32 v34, v34
	v_cndmask_b32_e32 v35, 0, v220, vcc
	v_sub_f32_e32 v226, v226, v221
	v_ldexp_f32 v243, v1, v35
	v_cndmask_b32_e64 v1, 0, v220, s[0:1]
	v_sub_f32_e32 v182, v182, v222
	v_ldexp_f32 v244, v34, v1
	v_mul_f32_e32 v1, 0x3fb8aa3b, v226
	v_cmp_gt_f32_e32 vcc, s95, v1
	v_mul_f32_e32 v34, 0x3fb8aa3b, v182
	v_cmp_gt_f32_e64 s[0:1], s95, v34
	v_cndmask_b32_e32 v1, 0, v219, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v226
	v_cndmask_b32_e64 v34, 0, v219, s[0:1]
	v_exp_f32_e32 v1, v1
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v182
	v_exp_f32_e32 v34, v34
	v_cndmask_b32_e32 v35, 0, v220, vcc
	v_sub_f32_e32 v183, v183, v222
	v_ldexp_f32 v245, v1, v35
	v_cndmask_b32_e64 v1, 0, v220, s[0:1]
	v_ldexp_f32 v246, v34, v1
	v_mul_f32_e32 v1, 0x3fb8aa3b, v183
	v_cmp_gt_f32_e32 vcc, s95, v1
	v_mul_f32_e32 v34, 0x3fb8aa3b, v247
	v_cmp_gt_f32_e64 s[0:1], s95, v34
	v_cndmask_b32_e32 v1, 0, v219, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v183
	v_cndmask_b32_e64 v34, 0, v219, s[0:1]
	v_exp_f32_e32 v1, v1
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v247
	v_exp_f32_e32 v34, v34
	v_cndmask_b32_e32 v35, 0, v220, vcc
	v_ldexp_f32 v247, v1, v35
	v_cndmask_b32_e64 v1, 0, v220, s[0:1]
	v_sub_f32_e32 v200, v200, v222
	v_ldexp_f32 v248, v34, v1
	v_mul_f32_e32 v1, 0x3fb8aa3b, v249
	v_cmp_gt_f32_e32 vcc, s95, v1
	v_mul_f32_e32 v34, 0x3fb8aa3b, v200
	v_cmp_gt_f32_e64 s[0:1], s95, v34
	v_cndmask_b32_e32 v1, 0, v219, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v249
	v_cndmask_b32_e64 v34, 0, v219, s[0:1]
	v_exp_f32_e32 v1, v1
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v200
	v_exp_f32_e32 v34, v34
	v_cndmask_b32_e32 v35, 0, v220, vcc
	v_sub_f32_e32 v201, v201, v222
	v_ldexp_f32 v250, v1, v35
	v_cndmask_b32_e64 v1, 0, v220, s[0:1]
	v_sub_f32_e32 v202, v202, v222
	v_ldexp_f32 v249, v34, v1
	v_mul_f32_e32 v1, 0x3fb8aa3b, v201
	v_cmp_gt_f32_e32 vcc, s95, v1
	v_mul_f32_e32 v34, 0x3fb8aa3b, v202
	v_cmp_gt_f32_e64 s[0:1], s95, v34
	v_cndmask_b32_e32 v1, 0, v219, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v201
	v_cndmask_b32_e64 v34, 0, v219, s[0:1]
	v_exp_f32_e32 v1, v1
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v202
	v_exp_f32_e32 v34, v34
	v_cndmask_b32_e32 v35, 0, v220, vcc
	v_sub_f32_e32 v203, v203, v222
	v_ldexp_f32 v251, v1, v35
	v_cndmask_b32_e64 v1, 0, v220, s[0:1]
	v_sub_f32_e32 v204, v204, v222
	v_ldexp_f32 v252, v34, v1
	v_mul_f32_e32 v1, 0x3fb8aa3b, v203
	v_cmp_gt_f32_e32 vcc, s95, v1
	v_mul_f32_e32 v34, 0x3fb8aa3b, v204
	v_cmp_gt_f32_e64 s[0:1], s95, v34
	v_cndmask_b32_e32 v1, 0, v219, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v203
	v_cndmask_b32_e64 v34, 0, v219, s[0:1]
	v_exp_f32_e32 v1, v1
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v204
	v_exp_f32_e32 v34, v34
	v_cndmask_b32_e32 v35, 0, v220, vcc
	v_sub_f32_e32 v205, v205, v222
	v_ldexp_f32 v254, v1, v35
	v_cndmask_b32_e64 v1, 0, v220, s[0:1]
	v_sub_f32_e32 v206, v206, v222
	v_ldexp_f32 v253, v34, v1
	v_mul_f32_e32 v1, 0x3fb8aa3b, v205
	v_cmp_gt_f32_e32 vcc, s95, v1
	v_mul_f32_e32 v34, 0x3fb8aa3b, v206
	v_cmp_gt_f32_e64 s[0:1], s95, v34
	v_cndmask_b32_e32 v1, 0, v219, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v205
	v_cndmask_b32_e64 v34, 0, v219, s[0:1]
	v_exp_f32_e32 v1, v1
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v206
	v_exp_f32_e32 v34, v34
	v_cndmask_b32_e32 v35, 0, v220, vcc
	v_ldexp_f32 v255, v1, v35
	v_cndmask_b32_e64 v1, 0, v220, s[0:1]
	v_ldexp_f32 v1, v34, v1
	v_accvgpr_read_b32 v34, a154
	v_accvgpr_read_b32 v35, a155
	ds_write2st64_b64 v34, v[170:171], v[174:175] offset0:6 offset1:14
	ds_write2st64_b64 v35, v[172:173], v[176:177] offset0:6 offset1:14
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v34, v[162:163], v[166:167] offset0:22 offset1:30
	ds_write2st64_b64 v35, v[164:165], v[168:169] offset0:22 offset1:30
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_read_b64_tr_b8 v[168:169], v208
	ds_read_b64_tr_b8 v[206:207], v210
	ds_read_b64_tr_b8 a[68:69], v211
	ds_read_b64_tr_b8 a[76:77], v212
	v_cvt_scalef32_pk_fp8_f32 v180, v223, v224, 1.0
	v_cvt_scalef32_pk_fp8_f32 v181, v234, v235, 1.0
	v_cvt_scalef32_pk_fp8_f32 v180, v225, v233, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v181, v236, v237, 1.0 op_sel:[0,0,0,1]
	v_pk_mul_f32 v[36:37], v[160:161], v[178:179] op_sel_hi:[1,0]
	s_nop 0
	v_permlane32_swap_b32_e32 v180, v181
	s_nop 1
	v_permlane16_swap_b32_e32 v180, v181
	v_pk_mul_f32 v[34:35], v[158:159], v[178:179] op_sel_hi:[1,0]
	v_cvt_scalef32_pk_fp8_f32 v170, v238, v239, 1.0
	v_cvt_scalef32_pk_fp8_f32 v171, v242, v243, 1.0
	ds_read_b64_tr_b8 v[172:173], v208 offset:8192
	ds_read_b64_tr_b8 v[174:175], v208 offset:8320
	ds_read_b64_tr_b8 v[176:177], v208 offset:128
	ds_read_b64_tr_b8 v[182:183], v209
	s_waitcnt lgkmcnt(7)
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[168:169], v[180:181], v[34:37]
	v_cvt_scalef32_pk_fp8_f32 v170, v240, v241, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v171, v244, v245, 1.0 op_sel:[0,0,0,1]
	ds_read_b64_tr_b8 v[200:201], v209 offset:8192
	ds_read_b64_tr_b8 v[202:203], v209 offset:8320
	ds_read_b64_tr_b8 v[204:205], v209 offset:128
	v_permlane32_swap_b32_e32 v170, v171
	s_nop 1
	v_permlane16_swap_b32_e32 v170, v171
	ds_read_b64_tr_b8 v[226:227], v210 offset:8192
	ds_read_b64_tr_b8 a[64:65], v210 offset:8320
	ds_read_b64_tr_b8 a[66:67], v210 offset:128
	s_waitcnt lgkmcnt(9)
	v_mfma_f32_16x16x32_fp8_fp8 v[158:161], v[172:173], v[170:171], v[34:37]
	ds_read_b64_tr_b8 a[70:71], v211 offset:8192
	ds_read_b64_tr_b8 a[72:73], v211 offset:8320
	ds_read_b64_tr_b8 a[74:75], v211 offset:128
	v_pk_mul_f32 v[36:37], v[156:157], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[154:155], v[178:179] op_sel_hi:[1,0]
	ds_read_b64_tr_b8 a[82:83], v213
	ds_read_b64_tr_b8 a[90:91], v214
	ds_read_b64_tr_b8 a[98:99], v215
	s_waitcnt lgkmcnt(12)
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[182:183], v[180:181], v[34:37]
	v_mul_f32_e32 v218, 0x3fb8aa3b, v229
	v_cmp_gt_f32_e32 vcc, s95, v218
	ds_read_b64_tr_b8 a[84:85], v213 offset:8192
	ds_read_b64_tr_b8 a[86:87], v213 offset:8320
	ds_read_b64_tr_b8 a[88:89], v213 offset:128
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_fp8_fp8 v[154:157], v[200:201], v[170:171], v[34:37]
	v_cndmask_b32_e32 v38, 0, v219, vcc
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v229
	ds_read_b64_tr_b8 v[228:229], v212 offset:8192
	ds_read_b64_tr_b8 a[78:79], v212 offset:8320
	ds_read_b64_tr_b8 a[80:81], v212 offset:128
	v_pk_mul_f32 v[36:37], v[152:153], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[150:151], v[178:179] op_sel_hi:[1,0]
	ds_read_b64_tr_b8 a[92:93], v214 offset:8192
	ds_read_b64_tr_b8 a[94:95], v214 offset:8320
	ds_read_b64_tr_b8 a[96:97], v214 offset:128
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[206:207], v[180:181], v[34:37]
	ds_read_b64_tr_b8 a[100:101], v215 offset:8192
	ds_read_b64_tr_b8 a[102:103], v215 offset:8320
	ds_read_b64_tr_b8 a[104:105], v215 offset:128
	v_exp_f32_e32 v38, v38
	v_cndmask_b32_e32 v39, 0, v220, vcc
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_fp8_fp8 v[150:153], v[226:227], v[170:171], v[34:37]
	v_mul_f32_e32 v40, 0x3fb8aa3b, v185
	v_ldexp_f32 v41, v38, v39
	v_mul_f32_e32 v38, 0x3fb8aa3b, v184
	v_pk_mul_f32 v[36:37], v[148:149], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[146:147], v[178:179] op_sel_hi:[1,0]
	v_cmp_gt_f32_e32 vcc, s95, v38
	v_cvt_scalef32_pk_fp8_f32 v162, v246, v247, 1.0
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[68:69], v[180:181], v[34:37]
	v_cndmask_b32_e32 v38, 0, v219, vcc
	v_cndmask_b32_e32 v39, 0, v220, vcc
	v_cmp_gt_f32_e32 vcc, s95, v40
	v_mfma_f32_16x16x32_fp8_fp8 v[146:149], a[70:71], v[170:171], v[34:37]
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v184
	v_cndmask_b32_e32 v40, 0, v219, vcc
	v_exp_f32_e32 v38, v38
	v_fmac_f32_e32 v40, 0x3fb8aa3b, v185
	v_pk_mul_f32 v[36:37], v[144:145], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[142:143], v[178:179] op_sel_hi:[1,0]
	v_exp_f32_e32 v40, v40
	v_ldexp_f32 v164, v38, v39
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[76:77], v[180:181], v[34:37]
	v_cndmask_b32_e32 v38, 0, v220, vcc
	v_ldexp_f32 v165, v40, v38
	v_mul_f32_e32 v38, 0x3fb8aa3b, v230
	s_waitcnt lgkmcnt(8)
	v_mfma_f32_16x16x32_fp8_fp8 v[142:145], v[228:229], v[170:171], v[34:37]
	v_cmp_gt_f32_e32 vcc, s95, v38
	v_mul_f32_e32 v40, 0x3fb8aa3b, v232
	v_cvt_scalef32_pk_fp8_f32 v163, v249, v251, 1.0
	v_cndmask_b32_e32 v38, 0, v219, vcc
	v_pk_mul_f32 v[36:37], v[140:141], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[138:139], v[178:179] op_sel_hi:[1,0]
	v_cndmask_b32_e32 v39, 0, v220, vcc
	v_cmp_gt_f32_e32 vcc, s95, v40
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[82:83], v[180:181], v[34:37]
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v230
	v_cndmask_b32_e32 v40, 0, v219, vcc
	v_exp_f32_e32 v38, v38
	v_mfma_f32_16x16x32_fp8_fp8 v[138:141], a[84:85], v[170:171], v[34:37]
	v_fmac_f32_e32 v40, 0x3fb8aa3b, v232
	v_exp_f32_e32 v40, v40
	v_ldexp_f32 v166, v38, v39
	v_cndmask_b32_e32 v38, 0, v220, vcc
	v_pk_mul_f32 v[36:37], v[136:137], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[134:135], v[178:179] op_sel_hi:[1,0]
	v_cvt_scalef32_pk_fp8_f32 v162, v248, v250, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v163, v252, v254, 1.0 op_sel:[0,0,0,1]
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[90:91], v[180:181], v[34:37]
	v_ldexp_f32 v167, v40, v38
	v_permlane32_swap_b32_e32 v162, v163
	s_waitcnt lgkmcnt(5)
	v_mfma_f32_16x16x32_fp8_fp8 v[134:137], a[92:93], v[170:171], v[34:37]
	v_mov_b32_e32 v40, v179
	v_permlane16_swap_b32_e32 v162, v163
	v_cvt_scalef32_pk_fp8_f32 v38, v253, v255, 1.0
	s_nop 0
	v_pk_mul_f32 v[36:37], v[132:133], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[130:131], v[178:179] op_sel_hi:[1,0]
	v_cvt_scalef32_pk_fp8_f32 v39, v164, v165, 1.0
	v_cvt_scalef32_pk_fp8_f32 v38, v1, v41, 1.0 op_sel:[0,0,0,1]
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[98:99], v[180:181], v[34:37]
	v_cvt_scalef32_pk_fp8_f32 v39, v166, v167, 1.0 op_sel:[0,0,0,1]
	s_nop 1
	v_permlane32_swap_b32_e32 v38, v39
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_fp8_fp8 v[130:133], a[100:101], v[170:171], v[34:37]
	v_permlane16_swap_b32_e32 v38, v39
	s_nop 1
	v_pk_mul_f32 v[36:37], v[128:129], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[126:127], v[178:179] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[176:177], v[180:181], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[126:129], v[174:175], v[170:171], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v124, v178
	v_mul_f32_e64 v37, v125, v178
	v_pk_mul_f32 v[34:35], v[122:123], v[178:179] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[204:205], v[180:181], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[122:125], v[202:203], v[170:171], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v120, v178
	v_mul_f32_e64 v37, v121, v178
	v_pk_mul_f32 v[34:35], v[118:119], v[178:179] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[66:67], v[180:181], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[118:121], a[64:65], v[170:171], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v116, v178
	v_mul_f32_e64 v37, v117, v178
	v_pk_mul_f32 v[34:35], v[114:115], v[178:179] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[74:75], v[180:181], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[114:117], a[72:73], v[170:171], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v112, v178
	v_mul_f32_e64 v37, v113, v178
	v_pk_mul_f32 v[34:35], v[110:111], v[178:179] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[80:81], v[180:181], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[110:113], a[78:79], v[170:171], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v108, v178
	v_mul_f32_e64 v37, v109, v178
	v_pk_mul_f32 v[34:35], v[106:107], v[178:179] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[88:89], v[180:181], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[106:109], a[86:87], v[170:171], v[34:37]
	s_nop 6
	v_accvgpr_read_b32 v34, a140
	v_accvgpr_read_b32 v35, a141
	v_accvgpr_read_b32 v36, a142
	v_accvgpr_read_b32 v37, a143
	v_pk_mul_f32 v[36:37], v[36:37], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[34:35], v[178:179] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[96:97], v[180:181], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[94:95], v[170:171], v[34:37]
	s_nop 7
	v_accvgpr_write_b32 a143, v37
	v_accvgpr_write_b32 a142, v36
	v_accvgpr_write_b32 a141, v35
	v_accvgpr_write_b32 a140, v34
	v_accvgpr_read_b32 v34, a136
	v_accvgpr_read_b32 v35, a137
	v_accvgpr_read_b32 v36, a138
	v_accvgpr_read_b32 v37, a139
	v_pk_mul_f32 v[36:37], v[36:37], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[34:35], v[178:179] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(0)
	s_nop 0
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[104:105], v[180:181], v[34:37]
	v_accvgpr_read_b32 v181, a131
	v_accvgpr_read_b32 v180, a130
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[102:103], v[170:171], v[34:37]
	s_nop 7
	v_accvgpr_write_b32 a139, v37
	v_accvgpr_write_b32 a138, v36
	v_accvgpr_write_b32 a137, v35
	v_accvgpr_write_b32 a136, v34
	v_accvgpr_read_b32 v34, a132
	v_accvgpr_read_b32 v35, a133
	v_accvgpr_read_b32 v36, a134
	v_accvgpr_read_b32 v37, a135
	v_pk_mul_f32 v[36:37], v[36:37], v[40:41] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[34:35], v[40:41] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[168:169], v[162:163], v[34:37]
.Ltmp155:
	v_add_f32_e32 v168, v223, v224
	v_add_f32_e32 v168, v225, v168
.Ltmp156:
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[172:173], v[38:39], v[34:37]
	s_nop 7
	v_accvgpr_write_b32 a135, v37
	v_accvgpr_write_b32 a134, v36
	v_accvgpr_write_b32 a133, v35
	v_accvgpr_write_b32 a132, v34
	v_pk_mul_f32 v[36:37], v[102:103], v[40:41] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[100:101], v[40:41] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[182:183], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[100:103], v[200:201], v[38:39], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v98, v40
	v_mul_f32_e64 v37, v99, v40
	v_pk_mul_f32 v[34:35], v[96:97], v[40:41] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[206:207], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[96:99], v[226:227], v[38:39], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v94, v40
	v_mul_f32_e64 v37, v95, v40
	v_pk_mul_f32 v[34:35], v[92:93], v[40:41] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[68:69], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[92:95], a[70:71], v[38:39], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v90, v40
	v_mul_f32_e64 v37, v91, v40
	v_pk_mul_f32 v[34:35], v[88:89], v[40:41] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[76:77], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[88:91], v[228:229], v[38:39], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v86, v40
	v_mul_f32_e64 v37, v87, v40
	v_pk_mul_f32 v[34:35], v[84:85], v[40:41] op_sel_hi:[1,0]
	v_mov_b32_e32 v84, v74
.Ltmp157:
	v_add_f32_e32 v74, v233, v168
.Ltmp158:
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[82:83], v[162:163], v[34:37]
.Ltmp159:
	v_add_f32_e32 v74, v234, v74
	v_add_f32_e32 v168, v235, v74
	v_mov_b32_e32 v74, v84
.Ltmp160:
	v_mfma_f32_16x16x32_fp8_fp8 v[84:87], a[84:85], v[38:39], v[34:37]
.Ltmp161:
	v_add_f32_e32 v168, v236, v168
	v_mov_b32_e32 v235, v221
	v_mov_b32_e32 v234, v222
.Ltmp162:
	s_nop 0
	v_pk_mul_f32 v[36:37], v[72:73], v[40:41] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[70:71], v[40:41] op_sel_hi:[1,0]
.Ltmp163:
	v_add_f32_e32 v70, v237, v168
	v_add_f32_e32 v70, v238, v70
.Ltmp164:
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[90:91], v[162:163], v[34:37]
.Ltmp165:
	v_add_f32_e32 v168, v239, v70
	v_add_f32_e32 v168, v240, v168
.Ltmp166:
	v_mfma_f32_16x16x32_fp8_fp8 v[70:73], a[92:93], v[38:39], v[34:37]
	s_nop 4
	v_mul_f32_e64 v36, v68, v40
	v_mul_f32_e64 v37, v69, v40
	v_pk_mul_f32 v[34:35], v[66:67], v[40:41] op_sel_hi:[1,0]
.Ltmp167:
	v_add_f32_e32 v66, v241, v168
	v_add_f32_e32 v66, v242, v66
.Ltmp168:
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[98:99], v[162:163], v[34:37]
.Ltmp169:
	v_add_f32_e32 v168, v243, v66
	v_add_f32_e32 v168, v244, v168
	v_add_f32_e32 v168, v245, v168
.Ltmp170:
	v_mfma_f32_16x16x32_fp8_fp8 v[66:69], a[100:101], v[38:39], v[34:37]
	s_nop 3
	v_mul_f32_e64 v36, v64, v40
	v_mul_f32_e64 v37, v65, v40
	v_pk_mul_f32 v[34:35], v[62:63], v[40:41] op_sel_hi:[1,0]
.Ltmp171:
	v_add_f32_e32 v62, v246, v247
	v_add_f32_e32 v169, v248, v62
.Ltmp172:
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[176:177], v[162:163], v[34:37]
.Ltmp173:
	v_add_f32_e32 v169, v250, v169
.Ltmp174:
	v_mfma_f32_16x16x32_fp8_fp8 v[62:65], v[174:175], v[38:39], v[34:37]
	s_nop 5
	v_mul_f32_e64 v36, v60, v40
	v_mul_f32_e64 v37, v61, v40
	v_pk_mul_f32 v[34:35], v[58:59], v[40:41] op_sel_hi:[1,0]
.Ltmp175:
	v_add_f32_e32 v58, v249, v169
	v_add_f32_e32 v58, v251, v58
.Ltmp176:
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[204:205], v[162:163], v[34:37]
.Ltmp177:
	v_add_f32_e32 v169, v252, v58
	v_add_f32_e32 v169, v254, v169
.Ltmp178:
	v_mfma_f32_16x16x32_fp8_fp8 v[58:61], v[202:203], v[38:39], v[34:37]
	s_nop 4
	v_mul_f32_e64 v36, v56, v40
	v_mul_f32_e64 v37, v57, v40
	v_pk_mul_f32 v[34:35], v[54:55], v[40:41] op_sel_hi:[1,0]
.Ltmp179:
	v_add_f32_e32 v54, v253, v169
	v_add_f32_e32 v54, v255, v54
.Ltmp180:
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[66:67], v[162:163], v[34:37]
.Ltmp181:
	v_add_f32_e32 v1, v1, v54
	v_add_f32_e32 v1, v41, v1
	v_add_f32_e32 v1, v164, v1
.Ltmp182:
	v_mfma_f32_16x16x32_fp8_fp8 v[54:57], a[64:65], v[38:39], v[34:37]
.Ltmp183:
	v_add_f32_e32 v1, v165, v1
	v_add_f32_e32 v1, v166, v1
	v_add_f32_e32 v1, v167, v1
.Ltmp184:
	s_nop 0
	v_pk_mul_f32 v[36:37], v[82:83], v[40:41] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[80:81], v[40:41] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[74:75], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[80:83], a[72:73], v[38:39], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v78, v40
	v_mul_f32_e64 v37, v79, v40
	v_pk_mul_f32 v[34:35], v[76:77], v[40:41] op_sel_hi:[1,0]
.Ltmp185:
	v_mov_b32_e32 v41, v168
	s_nop 1
	v_permlane32_swap_b32_e32 v168, v41
.Ltmp186:
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[80:81], v[162:163], v[34:37]
.Ltmp187:
	v_add_f32_e32 v164, v168, v41
.Ltmp188:
	v_mov_b32_e32 v166, v164
	s_nop 1
	v_permlane16_swap_b32_e32 v164, v166
.Ltmp189:
	v_mfma_f32_16x16x32_fp8_fp8 v[76:79], a[78:79], v[38:39], v[34:37]
	s_nop 2
	v_mul_f32_e64 v36, v52, v40
	v_mul_f32_e64 v37, v53, v40
	v_pk_mul_f32 v[34:35], v[50:51], v[40:41] op_sel_hi:[1,0]
.Ltmp190:
	v_mov_b32_e32 v41, v1
.Ltmp191:
	s_nop 0
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[88:89], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[50:53], a[86:87], v[38:39], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v48, v40
	v_mul_f32_e64 v37, v49, v40
	v_pk_mul_f32 v[34:35], v[46:47], v[40:41] op_sel_hi:[1,0]
.Ltmp192:
	v_permlane32_swap_b32_e32 v1, v41
.Ltmp193:
	s_nop 0
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[96:97], v[162:163], v[34:37]
.Ltmp194:
	v_add_f32_e32 v165, v1, v41
.Ltmp195:
	v_mov_b32_e32 v167, v165
	s_nop 1
	v_permlane16_swap_b32_e32 v165, v167
.Ltmp196:
	v_mfma_f32_16x16x32_fp8_fp8 v[46:49], a[94:95], v[38:39], v[34:37]
	s_nop 2
	v_mul_f32_e64 v36, v44, v40
	v_mul_f32_e64 v37, v45, v40
	v_pk_mul_f32 v[34:35], v[42:43], v[40:41] op_sel_hi:[1,0]
.Ltmp197:
	v_pk_add_f32 v[40:41], v[164:165], v[166:167]
.Ltmp198:
	s_nop 0
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[104:105], v[162:163], v[34:37]
	v_fma_f32 v180, v180, v178, v40
	v_fma_f32 v181, v181, v179, v41
	v_mfma_f32_16x16x32_fp8_fp8 v[42:45], a[102:103], v[38:39], v[34:37]
	s_branch .LBB0_5
.LBB0_8:                                ; %Flow
	v_accvgpr_read_b32 v164, a128
	v_accvgpr_read_b32 v74, a145
	v_accvgpr_read_b32 v165, a147
.LBB0_9:                                ; %._crit_edge
	v_accvgpr_write_b32 a101, v79
	v_accvgpr_write_b32 a100, v78
	v_accvgpr_write_b32 a99, v77
	v_accvgpr_write_b32 a98, v76
	v_accvgpr_read_b32 v76, a146
	v_or_b32_e32 v2, 8, v74
	s_lshl_b32 s42, s90, 10
	v_lshlrev_b32_e32 v18, 6, v165
	v_or_b32_e32 v1, 4, v76
	s_add_i32 s42, s42, s91
	v_or_b32_e32 v34, v18, v74
	v_or_b32_e32 v18, v2, v18
	v_lshlrev_b32_e32 v19, 10, v1
	v_add_lshl_u32 v34, v34, s42, 1
	v_bfrev_b32_e32 v233, 1
	v_cmp_gt_i32_e64 s[36:37], s88, v76
	v_add_lshl_u32 v18, v18, s42, 1
	v_or_b32_e32 v3, 8, v76
	v_or_b32_e32 v35, v19, v74
	s_and_b32 s5, s5, 0xffff
	s_mov_b32 s7, 0x27000
	s_mov_b32 s6, 0x7ffffffe
	v_cndmask_b32_e64 v34, v233, v34, s[36:37]
	v_cndmask_b32_e64 v18, v233, v18, s[36:37]
	v_lshlrev_b32_e32 v20, 10, v3
	v_or_b32_e32 v19, v19, v2
	buffer_load_dwordx4 v[170:173], v34, s[4:7], 0 offen
	buffer_load_dwordx4 v[174:177], v18, s[4:7], 0 offen
	v_add_lshl_u32 v18, v35, s42, 1
	v_cmp_gt_i32_e32 vcc, s88, v1
	v_accvgpr_write_b32 a96, v180
	v_or_b32_e32 v4, 12, v76
	v_or_b32_e32 v36, v20, v74
	v_cndmask_b32_e32 v1, v233, v18, vcc
	v_add_lshl_u32 v18, v19, s42, 1
	v_accvgpr_write_b32 a97, v181
	v_lshlrev_b32_e32 v21, 10, v4
	v_or_b32_e32 v20, v20, v2
	v_cndmask_b32_e32 v18, v233, v18, vcc
	buffer_load_dwordx4 v[178:181], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[182:185], v18, s[4:7], 0 offen
	v_add_lshl_u32 v1, v36, s42, 1
	v_cmp_gt_i32_e64 s[10:11], s88, v3
	v_or_b32_e32 v5, 16, v76
	v_or_b32_e32 v37, v21, v74
	v_cndmask_b32_e64 v1, v233, v1, s[10:11]
	v_add_lshl_u32 v3, v20, s42, 1
	v_lshlrev_b32_e32 v22, 10, v5
	v_or_b32_e32 v21, v21, v2
	v_cndmask_b32_e64 v3, v233, v3, s[10:11]
	buffer_load_dwordx4 v[186:189], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[190:193], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v37, s42, 1
	v_cmp_gt_i32_e64 s[12:13], s88, v4
	v_or_b32_e32 v6, 20, v76
	v_or_b32_e32 v38, v22, v74
	v_cndmask_b32_e64 v1, v233, v1, s[12:13]
	v_add_lshl_u32 v3, v21, s42, 1
	v_lshlrev_b32_e32 v23, 10, v6
	v_or_b32_e32 v22, v22, v2
	v_cndmask_b32_e64 v3, v233, v3, s[12:13]
	buffer_load_dwordx4 v[18:21], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[34:37], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v38, s42, 1
	v_cmp_gt_i32_e64 s[38:39], s88, v5
	v_or_b32_e32 v7, 24, v76
	v_or_b32_e32 v39, v23, v74
	v_cndmask_b32_e64 v1, v233, v1, s[38:39]
	v_add_lshl_u32 v3, v22, s42, 1
	v_lshlrev_b32_e32 v24, 10, v7
	v_or_b32_e32 v23, v23, v2
	v_cndmask_b32_e64 v3, v233, v3, s[38:39]
	buffer_load_dwordx4 v[194:197], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[198:201], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v39, s42, 1
	v_cmp_gt_i32_e64 s[14:15], s88, v6
	v_or_b32_e32 v8, 28, v76
	v_or_b32_e32 v40, v24, v74
	v_cndmask_b32_e64 v1, v233, v1, s[14:15]
	v_add_lshl_u32 v3, v23, s42, 1
	v_lshlrev_b32_e32 v25, 10, v8
	v_or_b32_e32 v24, v24, v2
	v_cndmask_b32_e64 v3, v233, v3, s[14:15]
	buffer_load_dwordx4 v[202:205], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[206:209], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v40, s42, 1
	v_cmp_gt_i32_e64 s[16:17], s88, v7
	v_or_b32_e32 v9, 32, v76
	v_or_b32_e32 v41, v25, v74
	v_cndmask_b32_e64 v1, v233, v1, s[16:17]
	v_add_lshl_u32 v3, v24, s42, 1
	v_lshlrev_b32_e32 v26, 10, v9
	v_or_b32_e32 v25, v25, v2
	v_cndmask_b32_e64 v3, v233, v3, s[16:17]
	buffer_load_dwordx4 v[210:213], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[214:217], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v41, s42, 1
	v_cmp_gt_i32_e64 s[18:19], s88, v8
	v_or_b32_e32 v10, 36, v76
	v_or_b32_e32 v162, v26, v74
	v_cndmask_b32_e64 v1, v233, v1, s[18:19]
	v_add_lshl_u32 v3, v25, s42, 1
	v_lshlrev_b32_e32 v27, 10, v10
	v_or_b32_e32 v26, v26, v2
	v_cndmask_b32_e64 v3, v233, v3, s[18:19]
	buffer_load_dwordx4 v[22:25], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[38:41], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v162, s42, 1
	v_cmp_gt_i32_e64 s[34:35], s88, v9
	v_or_b32_e32 v11, 40, v76
	v_or_b32_e32 v163, v27, v74
	v_cndmask_b32_e64 v1, v233, v1, s[34:35]
	v_add_lshl_u32 v3, v26, s42, 1
	v_lshlrev_b32_e32 v28, 10, v11
	v_or_b32_e32 v27, v27, v2
	v_cndmask_b32_e64 v3, v233, v3, s[34:35]
	buffer_load_dwordx4 v[218:221], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[222:225], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v163, s42, 1
	v_cmp_gt_i32_e64 s[20:21], s88, v10
	v_or_b32_e32 v12, 44, v76
	v_lshlrev_b32_e32 v17, 9, v164
	v_mov_b32_e32 v78, v164
	v_or_b32_e32 v164, v28, v74
	v_cndmask_b32_e64 v1, v233, v1, s[20:21]
	v_add_lshl_u32 v3, v27, s42, 1
	v_lshlrev_b32_e32 v29, 10, v12
	v_or_b32_e32 v28, v28, v2
	v_cndmask_b32_e64 v3, v233, v3, s[20:21]
	buffer_load_dwordx4 v[226:229], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[236:239], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v164, s42, 1
	v_cmp_gt_i32_e64 s[22:23], s88, v11
	v_or_b32_e32 v13, 48, v76
	v_mov_b32_e32 v77, v165
	v_or_b32_e32 v165, v29, v74
	v_cndmask_b32_e64 v1, v233, v1, s[22:23]
	v_add_lshl_u32 v3, v28, s42, 1
	v_lshlrev_b32_e32 v30, 10, v13
	v_or_b32_e32 v29, v29, v2
	v_cndmask_b32_e64 v3, v233, v3, s[22:23]
	buffer_load_dwordx4 v[240:243], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[244:247], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v165, s42, 1
	v_cmp_gt_i32_e64 s[24:25], s88, v12
	v_or_b32_e32 v14, 52, v76
	v_or_b32_e32 v166, v30, v74
	v_cndmask_b32_e64 v1, v233, v1, s[24:25]
	v_add_lshl_u32 v3, v29, s42, 1
	v_lshlrev_b32_e32 v31, 10, v14
	v_or_b32_e32 v30, v30, v2
	v_cndmask_b32_e64 v3, v233, v3, s[24:25]
	buffer_load_dwordx4 v[26:29], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[162:165], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v166, s42, 1
	v_cmp_gt_i32_e64 s[40:41], s88, v13
	v_or_b32_e32 v167, v31, v74
	v_add_lshl_u32 v3, v30, s42, 1
	v_cndmask_b32_e64 v1, v233, v1, s[40:41]
	v_or_b32_e32 v31, v31, v2
	v_cndmask_b32_e64 v3, v233, v3, s[40:41]
	buffer_load_dwordx4 v[10:13], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[248:251], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v167, s42, 1
	v_cmp_gt_i32_e64 s[26:27], s88, v14
	v_or_b32_e32 v15, 56, v76
	v_add_lshl_u32 v3, v31, s42, 1
	v_cndmask_b32_e64 v1, v233, v1, s[26:27]
	v_lshlrev_b32_e32 v32, 10, v15
	v_cndmask_b32_e64 v3, v233, v3, s[26:27]
	buffer_load_dwordx4 v[252:255], v1, s[4:7], 0 offen
	buffer_load_dwordx4 a[64:67], v3, s[4:7], 0 offen
	v_or_b32_e32 v168, v32, v74
	v_or_b32_e32 v16, 60, v76
	v_or_b32_e32 v32, v32, v2
	v_add_lshl_u32 v1, v168, s42, 1
	v_cmp_gt_i32_e64 s[28:29], s88, v15
	v_lshlrev_b32_e32 v33, 10, v16
	v_add_lshl_u32 v3, v32, s42, 1
	v_cndmask_b32_e64 v1, v233, v1, s[28:29]
	v_or_b32_e32 v169, v33, v74
	v_cndmask_b32_e64 v3, v233, v3, s[28:29]
	buffer_load_dwordx4 a[68:71], v1, s[4:7], 0 offen
	buffer_load_dwordx4 a[72:75], v3, s[4:7], 0 offen
	v_or_b32_e32 v33, v33, v2
	v_add_lshl_u32 v1, v169, s42, 1
	v_cmp_gt_i32_e64 s[0:1], s88, v16
	v_add_lshl_u32 v3, v33, s42, 1
	v_mov_b32_e32 v9, 0x54000
	v_cndmask_b32_e64 v1, v233, v1, s[0:1]
	v_cndmask_b32_e64 v3, v233, v3, s[0:1]
	buffer_load_dwordx4 v[30:33], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[166:169], v3, s[4:7], 0 offen
	v_mov_b32_e32 v1, 0x210
	v_cndmask_b32_e64 v1, v1, 0, s[2:3]
	v_accvgpr_read_b32 v3, a148
	v_xor_b32_e32 v1, v1, v3
	v_add_u32_e32 v3, 0, v1
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_write_b128 v3, a[0:3]
	ds_write_b128 v3, a[60:63] offset:8192
	v_xad_u32 v3, v1, 32, 0
	ds_write_b128 v3, a[52:55] offset:1024
	ds_write_b128 v3, a[56:59] offset:9216
	v_xad_u32 v3, v1, 64, 0
	ds_write_b128 v3, a[44:47] offset:2048
	ds_write_b128 v3, a[48:51] offset:10240
	v_xor_b32_e32 v3, 0x60, v1
	v_add_u32_e32 v3, 0, v3
	ds_write_b128 v3, a[36:39] offset:3072
	ds_write_b128 v3, a[40:43] offset:11264
	v_xor_b32_e32 v3, 0x80, v1
	v_add_u32_e32 v3, 0, v3
	ds_write_b128 v3, a[28:31] offset:4096
	ds_write_b128 v3, a[32:35] offset:12288
	v_xor_b32_e32 v3, 0xa0, v1
	v_add_u32_e32 v3, 0, v3
	ds_write_b128 v3, a[20:23] offset:5120
	ds_write_b128 v3, a[24:27] offset:13312
	v_xor_b32_e32 v3, 0xc0, v1
	v_xor_b32_e32 v1, 0xe0, v1
	v_add_u32_e32 v1, 0, v1
	v_add_u32_e32 v3, 0, v3
	ds_write_b128 v1, a[4:7] offset:7168
	ds_write_b128 v1, a[8:11] offset:15360
	v_bitop3_b32 v1, v17, v77, v74 bitop3:0x36
	ds_write_b128 v3, a[12:15] offset:6144
	ds_write_b128 v3, a[16:19] offset:14336
	v_add_u32_e32 v3, 0, v1
	v_xad_u32 v4, v1, 64, 0
	v_xor_b32_e32 v5, 0x80, v1
	v_xor_b32_e32 v1, 0xc0, v1
	v_add_u32_e32 v6, 0, v1
	v_lshlrev_b32_e32 v1, 5, v0
	v_xor_b32_e32 v7, v1, v77
	v_add_u32_e32 v5, 0, v5
	v_add_u32_e32 v8, 0, v7
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_read_b128 a[20:23], v3
	ds_read_b128 a[16:19], v3 offset:256
	ds_read_b128 a[0:3], v3 offset:8192
	ds_read_b128 a[76:79], v3 offset:8448
	ds_read_b128 a[28:31], v4
	ds_read_b128 a[24:27], v4 offset:256
	ds_read_b128 a[92:95], v4 offset:8192
	ds_read_b128 a[80:83], v4 offset:8448
	ds_read_b128 a[36:39], v5
	ds_read_b128 a[32:35], v5 offset:256
	ds_read_b128 a[4:7], v5 offset:8192
	ds_read_b128 a[84:87], v5 offset:8448
	ds_read_b128 a[40:43], v6
	ds_read_b128 a[12:15], v6 offset:256
	ds_read_b128 a[8:11], v6 offset:8192
	ds_read_b128 a[88:91], v6 offset:8448
	s_waitcnt vmcnt(31) lgkmcnt(0)
	; wave barrier
	ds_write_b128 v8, v[170:173]
	s_waitcnt vmcnt(23)
	ds_write_b128 v8, v[194:197] offset:8192
	s_waitcnt vmcnt(15)
	ds_write_b128 v8, v[218:221] offset:16384
	s_waitcnt vmcnt(7)
	ds_write_b128 v8, v[10:13] offset:24576
	v_xad_u32 v8, v7, 16, 0
	ds_write_b128 v8, v[174:177]
	ds_write_b128 v8, v[198:201] offset:8192
	ds_write_b128 v8, v[222:225] offset:16384
	s_waitcnt vmcnt(6)
	ds_write_b128 v8, v[248:251] offset:24576
	v_xad_u32 v8, v7, 64, 0
	ds_write_b128 v8, v[178:181] offset:2048
	ds_write_b128 v8, v[202:205] offset:10240
	ds_write_b128 v8, v[226:229] offset:18432
	s_waitcnt vmcnt(5)
	ds_write_b128 v8, v[252:255] offset:26624
	v_xor_b32_e32 v8, 0x50, v7
	v_add_u32_e32 v8, 0, v8
	ds_write_b128 v8, v[182:185] offset:2048
	ds_write_b128 v8, v[206:209] offset:10240
	ds_write_b128 v8, v[236:239] offset:18432
	s_waitcnt vmcnt(4)
	ds_write_b128 v8, a[64:67] offset:26624
	v_xor_b32_e32 v8, 0x80, v7
	v_add_u32_e32 v8, 0, v8
	ds_write_b128 v8, v[186:189] offset:4096
	ds_write_b128 v8, v[210:213] offset:12288
	ds_write_b128 v8, v[240:243] offset:20480
	s_waitcnt vmcnt(3)
	ds_write_b128 v8, a[68:71] offset:28672
	v_xor_b32_e32 v8, 0x90, v7
	v_add_u32_e32 v8, 0, v8
	ds_write_b128 v8, v[190:193] offset:4096
	ds_write_b128 v8, v[214:217] offset:12288
	ds_write_b128 v8, v[244:247] offset:20480
	s_waitcnt vmcnt(2)
	ds_write_b128 v8, a[72:75] offset:28672
	v_xor_b32_e32 v8, 0xc0, v7
	v_xor_b32_e32 v7, 0xd0, v7
	v_add_u32_e32 v8, 0, v8
	v_add_u32_e32 v7, 0, v7
	ds_write_b128 v8, v[18:21] offset:6144
	ds_write_b128 v8, v[22:25] offset:14336
	ds_write_b128 v8, v[26:29] offset:22528
	s_waitcnt vmcnt(1)
	ds_write_b128 v8, v[30:33] offset:30720
	ds_write_b128 v7, v[34:37] offset:6144
	ds_write_b128 v7, v[38:41] offset:14336
	ds_write_b128 v7, v[162:165] offset:22528
	s_waitcnt vmcnt(0)
	ds_write_b128 v7, v[166:169] offset:30720
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_read_b128 a[72:75], v3
	ds_read_b128 a[56:59], v3 offset:256
	ds_read_b128 a[64:67], v4
	ds_read_b128 a[52:55], v4 offset:256
	ds_read_b128 a[68:71], v5
	ds_read_b128 a[48:51], v5 offset:256
	ds_read_b128 a[60:63], v6
	ds_read_b128 a[44:47], v6 offset:256
	s_movk_i32 s2, 0x3800
	v_mul_u32_u24_e32 v3, 0x3800, v76
	v_mov_b32_e32 v4, 0xe000
	v_mov_b32_e32 v5, 0x1c000
	v_mov_b32_e32 v6, 0x2a000
	v_mov_b32_e32 v7, 0x38000
	v_mov_b32_e32 v8, 0x46000
	v_mov_b32_e32 v10, 0x62000
	v_mov_b32_e32 v12, 0x7e000
	v_mov_b32_e32 v13, 0x8c000
	v_mov_b32_e32 v14, 0x9a000
	v_mov_b32_e32 v15, 0xa8000
	v_mov_b32_e32 v16, 0xb6000
	v_mov_b32_e32 v17, 0xc4000
	v_mov_b32_e32 v18, 0xd2000
	s_mulk_i32 s90, 0x3400
	v_mad_u32_u24 v4, v76, s2, v4
	v_mad_u32_u24 v5, v76, s2, v5
	v_mad_u32_u24 v6, v76, s2, v6
	v_mad_u32_u24 v7, v76, s2, v7
	v_mad_u32_u24 v8, v76, s2, v8
	v_mad_u32_u24 v9, v76, s2, v9
	v_mad_u32_u24 v10, v76, s2, v10
	v_or_b32_e32 v11, 0x70000, v3
	v_mad_u32_u24 v12, v76, s2, v12
	v_mad_u32_u24 v13, v76, s2, v13
	v_mad_u32_u24 v14, v76, s2, v14
	v_mad_u32_u24 v15, v76, s2, v15
	v_mad_u32_u24 v16, v76, s2, v16
	v_mad_u32_u24 v17, v76, s2, v17
	v_mad_u32_u24 v18, v76, s2, v18
	s_add_i32 s42, s42, s90
	v_or_b32_e32 v19, v3, v74
	v_or_b32_e32 v3, v3, v2
	v_or_b32_e32 v20, v4, v74
	v_or_b32_e32 v4, v4, v2
	v_or_b32_e32 v21, v5, v74
	v_or_b32_e32 v22, v5, v2
	v_or_b32_e32 v23, v6, v74
	v_or_b32_e32 v6, v6, v2
	v_or_b32_e32 v5, v7, v74
	v_or_b32_e32 v7, v7, v2
	v_or_b32_e32 v25, v8, v2
	v_or_b32_e32 v30, v9, v74
	v_or_b32_e32 v31, v9, v2
	v_or_b32_e32 v32, v10, v74
	v_or_b32_e32 v10, v10, v2
	v_or_b32_e32 v9, v11, v2
	v_or_b32_e32 v33, v12, v74
	v_or_b32_e32 v162, v12, v2
	v_or_b32_e32 v164, v13, v2
	v_or_b32_e32 v178, v14, v2
	v_or_b32_e32 v12, v15, v2
	v_or_b32_e32 v180, v16, v2
	v_or_b32_e32 v194, v17, v2
	v_or_b32_e32 v196, v18, v2
	v_add_lshl_u32 v2, v19, s42, 1
	v_add_lshl_u32 v3, v3, s42, 1
	s_and_b32 s45, s45, 0xffff
	s_mov_b32 s46, s6
	s_mov_b32 s47, s7
	v_cndmask_b32_e64 v2, v233, v2, s[36:37]
	v_cndmask_b32_e64 v3, v233, v3, s[36:37]
	buffer_load_dwordx4 v[34:37], v2, s[44:47], 0 offen
	buffer_load_dwordx4 v[226:229], v3, s[44:47], 0 offen
	v_add_lshl_u32 v3, v4, s42, 1
	v_add_lshl_u32 v4, v5, s42, 1
	v_or_b32_e32 v24, v8, v74
	v_or_b32_e32 v8, v11, v74
	v_cndmask_b32_e64 v4, v233, v4, s[38:39]
	v_add_lshl_u32 v5, v7, s42, 1
	v_cndmask_b32_e64 v5, v233, v5, s[38:39]
	buffer_load_dwordx4 v[236:239], v4, s[44:47], 0 offen
	buffer_load_dwordx4 v[240:243], v5, s[44:47], 0 offen
	v_add_lshl_u32 v4, v8, s42, 1
	v_or_b32_e32 v11, v15, v74
	v_cndmask_b32_e64 v4, v233, v4, s[34:35]
	buffer_load_dwordx4 v[244:247], v4, s[44:47], 0 offen
	v_add_lshl_u32 v4, v11, s42, 1
	v_cndmask_b32_e64 v4, v233, v4, s[40:41]
	buffer_load_dwordx4 v[248:251], v4, s[44:47], 0 offen
	v_add_lshl_u32 v4, v9, s42, 1
	v_cndmask_b32_e64 v4, v233, v4, s[34:35]
	buffer_load_dwordx4 v[252:255], v4, s[44:47], 0 offen
	v_add_lshl_u32 v4, v12, s42, 1
	v_cndmask_b32_e64 v4, v233, v4, s[40:41]
	buffer_load_dwordx4 v[38:41], v4, s[44:47], 0 offen
	v_or_b32_e32 v195, v18, v74
	v_add_lshl_u32 v18, v33, s42, 1
	v_add_lshl_u32 v19, v162, s42, 1
	v_or_b32_e32 v163, v13, v74
	v_cndmask_b32_e64 v18, v233, v18, s[20:21]
	v_cndmask_b32_e64 v19, v233, v19, s[20:21]
	v_add_lshl_u32 v2, v20, s42, 1
	v_add_lshl_u32 v11, v24, s42, 1
	buffer_load_dwordx4 v[210:213], v18, s[44:47], 0 offen
	buffer_load_dwordx4 v[202:205], v19, s[44:47], 0 offen
	v_add_lshl_u32 v18, v163, s42, 1
	v_add_lshl_u32 v19, v164, s42, 1
	v_or_b32_e32 v165, v14, v74
	v_or_b32_e32 v179, v16, v74
	v_or_b32_e32 v181, v17, v74
	v_cndmask_b32_e32 v2, v233, v2, vcc
	v_cndmask_b32_e32 v7, v233, v3, vcc
	v_cndmask_b32_e64 v11, v233, v11, s[14:15]
	v_add_lshl_u32 v12, v25, s42, 1
	v_cndmask_b32_e64 v18, v233, v18, s[22:23]
	v_cndmask_b32_e64 v19, v233, v19, s[22:23]
	buffer_load_dwordx4 v[2:5], v2, s[44:47], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[186:189], v7, s[44:47], 0 offen
	v_add_lshl_u32 v7, v21, s42, 1
	v_cndmask_b32_e64 v12, v233, v12, s[14:15]
	buffer_load_dwordx4 v[222:225], v11, s[44:47], 0 offen
	buffer_load_dwordx4 v[198:201], v12, s[44:47], 0 offen
	v_add_lshl_u32 v11, v30, s42, 1
	buffer_load_dwordx4 v[190:193], v18, s[44:47], 0 offen
	buffer_load_dwordx4 v[174:177], v19, s[44:47], 0 offen
	v_add_lshl_u32 v18, v165, s42, 1
	v_add_lshl_u32 v19, v178, s42, 1
	v_add_lshl_u32 v162, v179, s42, 1
	v_add_lshl_u32 v163, v180, s42, 1
	v_add_lshl_u32 v164, v181, s42, 1
	v_add_lshl_u32 v165, v194, s42, 1
	v_add_lshl_u32 v178, v195, s42, 1
	v_add_lshl_u32 v179, v196, s42, 1
	v_cndmask_b32_e64 v7, v233, v7, s[10:11]
	v_add_lshl_u32 v8, v22, s42, 1
	v_cndmask_b32_e64 v11, v233, v11, s[16:17]
	v_add_lshl_u32 v12, v31, s42, 1
	v_cndmask_b32_e64 v162, v233, v162, s[26:27]
	v_cndmask_b32_e64 v163, v233, v163, s[26:27]
	v_cndmask_b32_e64 v164, v233, v164, s[28:29]
	v_cndmask_b32_e64 v165, v233, v165, s[28:29]
	v_cndmask_b32_e64 v178, v233, v178, s[0:1]
	v_cndmask_b32_e64 v230, v233, v179, s[0:1]
	v_cndmask_b32_e64 v8, v233, v8, s[10:11]
	buffer_load_dwordx4 v[170:173], v7, s[44:47], 0 offen
	buffer_load_dwordx4 v[26:29], v8, s[44:47], 0 offen
	v_add_lshl_u32 v7, v23, s42, 1
	v_add_lshl_u32 v6, v6, s42, 1
	v_cndmask_b32_e64 v12, v233, v12, s[16:17]
	buffer_load_dwordx4 v[182:185], v11, s[44:47], 0 offen
	buffer_load_dwordx4 v[166:169], v12, s[44:47], 0 offen
	v_add_lshl_u32 v11, v32, s42, 1
	v_add_lshl_u32 v10, v10, s42, 1
	buffer_load_dwordx4 v[218:221], v162, s[44:47], 0 offen
	buffer_load_dwordx4 v[214:217], v163, s[44:47], 0 offen
	buffer_load_dwordx4 v[206:209], v164, s[44:47], 0 offen
	buffer_load_dwordx4 v[194:197], v165, s[44:47], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[178:181], v178, s[44:47], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[162:165], v230, s[44:47], 0 offen
	v_or_b32_e32 v230, v1, v104
	v_cndmask_b32_e64 v7, v233, v7, s[12:13]
	v_cndmask_b32_e64 v6, v233, v6, s[12:13]
	v_cndmask_b32_e64 v11, v233, v11, s[18:19]
	v_cndmask_b32_e64 v10, v233, v10, s[18:19]
	v_cndmask_b32_e64 v18, v233, v18, s[24:25]
	v_cndmask_b32_e64 v19, v233, v19, s[24:25]
	v_add_u32_e32 v231, 0, v230
	buffer_load_dwordx4 v[14:17], v7, s[44:47], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[6:9], v6, s[44:47], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[22:25], v11, s[44:47], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[10:13], v10, s[44:47], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[30:33], v18, s[44:47], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[18:21], v19, s[44:47], 0 offen
	s_waitcnt vmcnt(29) lgkmcnt(0)
	; wave barrier
	ds_write2st64_b64 v231, v[34:35], v[236:237] offset1:16
	s_waitcnt vmcnt(26)
	ds_write2st64_b64 v231, v[244:245], v[248:249] offset0:32 offset1:48
	v_xad_u32 v34, v230, 8, 0
	ds_write2st64_b64 v34, v[36:37], v[238:239] offset1:16
	ds_write2st64_b64 v34, v[246:247], v[250:251] offset0:32 offset1:48
	v_xad_u32 v34, v230, 16, 0
	ds_write2st64_b64 v34, v[226:227], v[240:241] offset1:16
	s_waitcnt vmcnt(24)
	ds_write2st64_b64 v34, v[252:253], v[38:39] offset0:32 offset1:48
	v_xad_u32 v38, v230, 24, 0
	v_mfma_f32_16x16x32_bf16 v[34:37], a[72:75], a[20:23], 0
	ds_write2st64_b64 v38, v[228:229], v[242:243] offset1:16
	ds_write2st64_b64 v38, v[254:255], v[40:41] offset0:32 offset1:48
	v_accvgpr_read_b32 v74, a144
	v_mfma_f32_16x16x32_bf16 v[38:41], a[72:75], a[0:3], 0
	v_or_b32_e32 v226, 1, v74
	v_or_b32_e32 v227, 2, v74
	v_or_b32_e32 v228, 3, v74
	v_mfma_f32_16x16x32_bf16 v[34:37], a[64:67], a[28:31], v[34:37]
	v_cmp_gt_i32_e32 vcc, s88, v74
	v_cmp_gt_i32_e64 s[0:1], s88, v226
	v_cmp_gt_i32_e64 s[2:3], s88, v227
	v_mfma_f32_16x16x32_bf16 v[38:41], a[64:67], a[92:95], v[38:41]
	v_cmp_ge_u32_e64 s[10:11], v78, v74
	v_cmp_gt_u32_e64 s[12:13], v78, v74
	v_cmp_ge_u32_e64 s[14:15], v78, v227
	v_mfma_f32_16x16x32_bf16 v[34:37], a[68:71], a[36:39], v[34:37]
	v_cmp_gt_i32_e64 s[4:5], s88, v228
	v_cmp_ge_u32_e64 s[16:17], v78, v228
	s_and_b64 s[10:11], s[10:11], vcc
	v_mfma_f32_16x16x32_bf16 v[38:41], a[68:71], a[4:7], v[38:41]
	s_and_b64 s[0:1], s[12:13], s[0:1]
	s_and_b64 s[2:3], s[14:15], s[2:3]
	s_and_b64 s[4:5], s[16:17], s[4:5]
	v_mfma_f32_16x16x32_bf16 v[34:37], a[60:63], a[40:43], v[34:37]
	v_mov_b32_e32 v226, 0xff800000
	s_and_b64 vcc, s[30:31], s[10:11]
	s_and_b64 s[0:1], s[30:31], s[0:1]
	v_mfma_f32_16x16x32_bf16 v[38:41], a[60:63], a[8:11], v[38:41]
	s_and_b64 s[2:3], s[30:31], s[2:3]
	s_and_b64 s[4:5], s[30:31], s[4:5]
	s_mov_b32 s12, 0xff800000
	v_mfma_f32_16x16x32_bf16 v[34:37], a[56:59], a[16:19], v[34:37]
	v_mov_b32_e32 v237, 0x42800000
	v_not_b32_e32 v236, 63
	v_accvgpr_write_b32 a125, v103
	v_mfma_f32_16x16x32_bf16 v[38:41], a[56:59], a[76:79], v[38:41]
	v_accvgpr_write_b32 a124, v102
	v_accvgpr_write_b32 a123, v101
	v_accvgpr_write_b32 a122, v100
	v_mfma_f32_16x16x32_bf16 v[34:37], a[52:55], a[24:27], v[34:37]
	v_accvgpr_write_b32 a121, v99
	v_accvgpr_write_b32 a120, v98
	v_accvgpr_write_b32 a119, v97
	v_mfma_f32_16x16x32_bf16 v[38:41], a[52:55], a[80:83], v[38:41]
	v_accvgpr_write_b32 a118, v96
	v_accvgpr_write_b32 a117, v95
	v_accvgpr_write_b32 a116, v94
	v_mfma_f32_16x16x32_bf16 v[34:37], a[48:51], a[32:35], v[34:37]
	v_accvgpr_write_b32 a115, v93
	v_accvgpr_write_b32 a114, v92
	v_accvgpr_write_b32 a113, v91
	v_mfma_f32_16x16x32_bf16 v[38:41], a[48:51], a[84:87], v[38:41]
	v_accvgpr_write_b32 a112, v90
	v_accvgpr_write_b32 a111, v89
	v_accvgpr_write_b32 a110, v88
	v_mfma_f32_16x16x32_bf16 v[34:37], a[44:47], a[12:15], v[34:37]
	v_accvgpr_write_b32 a109, v87
	v_accvgpr_write_b32 a108, v86
	v_accvgpr_write_b32 a107, v85
	v_mfma_f32_16x16x32_bf16 v[38:41], a[44:47], a[88:91], v[38:41]
	v_accvgpr_write_b32 a106, v84
	v_accvgpr_write_b32 a105, v83
	v_accvgpr_write_b32 a104, v82
	v_accvgpr_write_b32 a103, v81
	v_mul_f32_e32 v34, s89, v34
	v_mul_f32_e32 v35, s89, v35
	v_mul_f32_e32 v36, s89, v36
	v_mul_f32_e32 v37, s89, v37
	v_mul_f32_e32 v38, s89, v38
	v_cndmask_b32_e32 v34, v226, v34, vcc
	v_cndmask_b32_e64 v35, v226, v35, s[0:1]
	v_cndmask_b32_e64 v36, v226, v36, s[2:3]
	v_cndmask_b32_e64 v37, v226, v37, s[4:5]
	v_cndmask_b32_e32 v240, v226, v38, vcc
.Ltmp199:
	v_max3_f32 v38, v34, v35, v36
.Ltmp200:
	v_mul_f32_e32 v40, s89, v40
.Ltmp201:
	v_max3_f32 v38, v38, v37, s12
.Ltmp202:
	v_cndmask_b32_e64 v239, v226, v40, s[2:3]
.Ltmp203:
	v_mov_b32_e32 v40, v38
	s_nop 1
	v_permlane32_swap_b32_e32 v38, v40
.Ltmp204:
	v_max_f32_e32 v40, v40, v40
	v_max_f32_e32 v38, v38, v38
.Ltmp205:
	v_mul_f32_e32 v39, s89, v39
.Ltmp206:
	v_max_f32_e32 v38, v38, v40
.Ltmp207:
	v_mul_f32_e32 v41, s89, v41
	v_cndmask_b32_e64 v241, v226, v39, s[0:1]
.Ltmp208:
	v_mov_b32_e32 v40, v38
.Ltmp209:
	v_cndmask_b32_e64 v238, v226, v41, s[4:5]
.Ltmp210:
	v_max3_f32 v39, v240, v241, v239
.Ltmp211:
	v_permlane16_swap_b32_e32 v38, v40
.Ltmp212:
	v_max3_f32 v39, v39, v238, s12
	v_max_f32_e32 v40, v40, v40
	v_max_f32_e32 v38, v38, v38
	v_max_f32_e32 v38, v38, v40
.Ltmp213:
	v_mov_b32_e32 v40, v39
	s_nop 1
	v_permlane32_swap_b32_e32 v39, v40
.Ltmp214:
	v_max_f32_e32 v40, v40, v40
	v_max_f32_e32 v39, v39, v39
	v_max_f32_e32 v39, v39, v40
.Ltmp215:
	v_mov_b32_e32 v40, v39
	s_nop 1
	v_permlane16_swap_b32_e32 v39, v40
.Ltmp216:
	v_max_f32_e32 v40, v40, v40
	v_max_f32_e32 v39, v39, v39
	v_max_f32_e32 v39, v39, v40
.Ltmp217:
	v_mov_b32_e32 v40, 0xe0ad78ec
	v_cmp_neq_f32_e32 vcc, s12, v38
	s_mov_b32 s2, 0xc2fc0000
	v_accvgpr_write_b32 a102, v80
	v_cndmask_b32_e32 v38, v40, v38, vcc
	v_cmp_neq_f32_e32 vcc, s12, v39
	v_mov_b32_e32 v227, v78
	s_and_b32 s9, s9, 0xffff
	v_cndmask_b32_e32 v39, v40, v39, vcc
	v_max_f32_e32 v40, v235, v235
	v_max_f32_e32 v38, v38, v40
	v_max_f32_e32 v40, v234, v234
	v_max_f32_e32 v242, v39, v40
	v_sub_f32_e32 v39, v235, v38
	v_mul_f32_e32 v40, 0x3fb8aa3b, v39
	v_cmp_gt_f32_e32 vcc, s2, v40
	v_sub_f32_e32 v34, v34, v38
	v_sub_f32_e32 v35, v35, v38
	v_cndmask_b32_e32 v40, 0, v237, vcc
	v_fmac_f32_e32 v40, 0x3fb8aa3b, v39
	v_exp_f32_e32 v39, v40
	v_cndmask_b32_e32 v40, 0, v236, vcc
	v_sub_f32_e32 v36, v36, v38
	v_sub_f32_e32 v37, v37, v38
	v_ldexp_f32 v228, v39, v40
	v_mul_f32_e32 v39, 0x3fb8aa3b, v34
	v_cmp_gt_f32_e32 vcc, s2, v39
	v_sub_f32_e32 v243, v234, v242
	v_sub_f32_e32 v38, 0xff800000, v38
	v_cndmask_b32_e32 v39, 0, v237, vcc
	v_fmac_f32_e32 v39, 0x3fb8aa3b, v34
	v_exp_f32_e32 v34, v39
	v_cndmask_b32_e32 v39, 0, v236, vcc
	s_mov_b32 s10, s6
	s_mov_b32 s11, s7
	v_ldexp_f32 v230, v34, v39
	v_mul_f32_e32 v34, 0x3fb8aa3b, v35
	v_cmp_gt_f32_e32 vcc, s2, v34
	s_nop 1
	v_cndmask_b32_e32 v34, 0, v237, vcc
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v35
	v_mul_f32_e32 v35, 0x3fb8aa3b, v36
	v_cmp_gt_f32_e64 s[0:1], s2, v35
	v_exp_f32_e32 v34, v34
	s_nop 0
	v_cndmask_b32_e64 v35, 0, v237, s[0:1]
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v36
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e32 v36, 0, v236, vcc
	v_ldexp_f32 v232, v34, v36
	v_cndmask_b32_e64 v34, 0, v236, s[0:1]
	v_ldexp_f32 v234, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v37
	v_cmp_gt_f32_e32 vcc, s2, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v38
	v_cmp_gt_f32_e64 s[0:1], s2, v35
	v_cndmask_b32_e32 v34, 0, v237, vcc
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v37
	v_cndmask_b32_e64 v35, 0, v237, s[0:1]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v38
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e32 v36, 0, v236, vcc
	v_ldexp_f32 v235, v34, v36
	v_cndmask_b32_e64 v34, 0, v236, s[0:1]
	s_movk_i32 s0, 0x820
	v_ldexp_f32 v229, v35, v34
	v_bitop3_b32 v34, v1, s0, v104 bitop3:0x36
	v_add_u32_e32 v34, 0, v34
	s_movk_i32 s0, 0x828
	s_waitcnt vmcnt(19)
	ds_write2st64_b64 v34, v[2:3], v[222:223] offset1:16
	s_waitcnt vmcnt(11)
	ds_write2st64_b64 v34, v[210:211], v[218:219] offset0:32 offset1:48
	v_bitop3_b32 v2, v1, s0, v104 bitop3:0x36
	v_add_u32_e32 v34, 0, v2
	s_movk_i32 s0, 0x830
	ds_write2st64_b64 v34, v[4:5], v[224:225] offset1:16
	v_bitop3_b32 v5, v1, s0, v104 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	s_movk_i32 s0, 0x838
	ds_write2st64_b64 v34, v[212:213], v[220:221] offset0:32 offset1:48
	ds_write2st64_b64 v5, v[186:187], v[198:199] offset1:16
	s_waitcnt vmcnt(10)
	ds_write2st64_b64 v5, v[202:203], v[214:215] offset0:32 offset1:48
	v_bitop3_b32 v5, v1, s0, v104 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	s_movk_i32 s0, 0x1040
	ds_write2st64_b64 v5, v[188:189], v[200:201] offset1:16
	ds_write2st64_b64 v5, v[204:205], v[216:217] offset0:32 offset1:48
	v_bitop3_b32 v5, v1, s0, v104 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	s_movk_i32 s0, 0x1048
	ds_write2st64_b64 v5, v[170:171], v[182:183] offset1:16
	s_waitcnt vmcnt(9)
	ds_write2st64_b64 v5, v[190:191], v[206:207] offset0:32 offset1:48
	v_bitop3_b32 v5, v1, s0, v104 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	s_movk_i32 s0, 0x1050
	ds_write2st64_b64 v5, v[172:173], v[184:185] offset1:16
	ds_write2st64_b64 v5, v[192:193], v[208:209] offset0:32 offset1:48
	v_bitop3_b32 v5, v1, s0, v104 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	s_movk_i32 s0, 0x1058
	ds_write2st64_b64 v5, v[26:27], v[166:167] offset1:16
	s_waitcnt vmcnt(8)
	ds_write2st64_b64 v5, v[174:175], v[194:195] offset0:32 offset1:48
	v_bitop3_b32 v5, v1, s0, v104 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	s_movk_i32 s0, 0x1860
	ds_write2st64_b64 v5, v[28:29], v[168:169] offset1:16
	ds_write2st64_b64 v5, v[176:177], v[196:197] offset0:32 offset1:48
	v_bitop3_b32 v5, v1, s0, v104 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	s_movk_i32 s0, 0x1868
	s_waitcnt vmcnt(3)
	ds_write2st64_b64 v5, v[14:15], v[22:23] offset1:16
	s_waitcnt vmcnt(1)
	ds_write2st64_b64 v5, v[30:31], v[178:179] offset0:32 offset1:48
	v_bitop3_b32 v5, v1, s0, v104 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	s_movk_i32 s0, 0x1870
	ds_write2st64_b64 v5, v[16:17], v[24:25] offset1:16
	ds_write2st64_b64 v5, v[32:33], v[180:181] offset0:32 offset1:48
	v_bitop3_b32 v5, v1, s0, v104 bitop3:0x36
	s_movk_i32 s0, 0x1878
	v_bitop3_b32 v1, v1, s0, v104 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	v_add_u32_e32 v1, 0, v1
	ds_write2st64_b64 v5, v[6:7], v[10:11] offset1:16
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v5, v[18:19], v[162:163] offset0:32 offset1:48
	ds_write2st64_b64 v1, v[8:9], v[12:13] offset1:16
	ds_write2st64_b64 v1, v[20:21], v[164:165] offset0:32 offset1:48
	v_lshlrev_b32_e32 v1, 7, v75
	v_and_b32_e32 v5, 24, v105
	v_lshlrev_b32_e32 v6, 1, v75
	v_bitop3_b32 v1, v1, v6, v5 bitop3:0x36
	v_add_u32_e32 v5, 0, v1
	v_cvt_pk_bf16_f32 v4, v229, v229
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_read_b64_tr_b16 v[218:219], v5
	ds_read_b64_tr_b16 v[26:27], v5 offset:128
	ds_read_b64_tr_b16 v[14:15], v5 offset:256
	ds_read_b64_tr_b16 v[10:11], v5 offset:384
	ds_read_b64_tr_b16 v[220:221], v5 offset:8192
	ds_read_b64_tr_b16 v[28:29], v5 offset:8320
	ds_read_b64_tr_b16 v[16:17], v5 offset:8448
	ds_read_b64_tr_b16 v[12:13], v5 offset:8576
	ds_read_b64_tr_b16 v[222:223], v5 offset:16384
	ds_read_b64_tr_b16 v[198:199], v5 offset:16512
	ds_read_b64_tr_b16 v[18:19], v5 offset:16640
	ds_read_b64_tr_b16 v[166:167], v5 offset:16768
	ds_read_b64_tr_b16 v[224:225], v5 offset:24576
	ds_read_b64_tr_b16 v[200:201], v5 offset:24704
	ds_read_b64_tr_b16 v[20:21], v5 offset:24832
	ds_read_b64_tr_b16 v[168:169], v5 offset:24960
	v_xad_u32 v5, v1, 32, 0
	v_cvt_pk_bf16_f32 v2, v230, v232
	v_cvt_pk_bf16_f32 v3, v234, v235
	ds_read_b64_tr_b16 v[244:245], v5
	ds_read_b64_tr_b16 v[202:203], v5 offset:128
	ds_read_b64_tr_b16 v[22:23], v5 offset:256
	ds_read_b64_tr_b16 v[170:171], v5 offset:384
	ds_read_b64_tr_b16 v[246:247], v5 offset:8192
	ds_read_b64_tr_b16 v[204:205], v5 offset:8320
	ds_read_b64_tr_b16 v[24:25], v5 offset:8448
	ds_read_b64_tr_b16 v[172:173], v5 offset:8576
	ds_read_b64_tr_b16 v[248:249], v5 offset:16384
	ds_read_b64_tr_b16 v[206:207], v5 offset:16512
	ds_read_b64_tr_b16 v[186:187], v5 offset:16640
	ds_read_b64_tr_b16 v[174:175], v5 offset:16768
	ds_read_b64_tr_b16 v[250:251], v5 offset:24576
	ds_read_b64_tr_b16 v[208:209], v5 offset:24704
	ds_read_b64_tr_b16 v[188:189], v5 offset:24832
	ds_read_b64_tr_b16 v[176:177], v5 offset:24960
	v_mov_b32_e32 v5, v4
	v_pk_mul_f32 v[32:33], v[160:161], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[30:31], v[158:159], v[228:229] op_sel_hi:[1,0]
	v_mov_b32_e32 v6, v4
	v_mov_b32_e32 v7, v4
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_bf16 v[30:33], v[218:221], v[2:5], v[30:33]
	v_mov_b32_e32 v8, v4
	v_mov_b32_e32 v9, v4
	v_xad_u32 v34, v1, 64, 0
	v_xor_b32_e32 v1, 0x60, v1
	v_mfma_f32_16x16x32_bf16 v[158:161], v[222:225], v[6:9], v[30:33]
	v_add_u32_e32 v1, 0, v1
	ds_read_b64_tr_b16 v[252:253], v34
	ds_read_b64_tr_b16 v[210:211], v34 offset:128
	ds_read_b64_tr_b16 v[190:191], v34 offset:256
	ds_read_b64_tr_b16 v[178:179], v34 offset:384
	ds_read_b64_tr_b16 v[254:255], v34 offset:8192
	ds_read_b64_tr_b16 v[212:213], v34 offset:8320
	ds_read_b64_tr_b16 v[192:193], v34 offset:8448
	ds_read_b64_tr_b16 v[180:181], v34 offset:8576
	ds_read_b64_tr_b16 a[0:1], v34 offset:16384
	ds_read_b64_tr_b16 v[214:215], v34 offset:16512
	ds_read_b64_tr_b16 v[194:195], v34 offset:16640
	ds_read_b64_tr_b16 v[182:183], v34 offset:16768
	v_pk_mul_f32 v[32:33], v[156:157], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[30:31], v[154:155], v[228:229] op_sel_hi:[1,0]
	ds_read_b64_tr_b16 a[6:7], v1 offset:24576
	ds_read_b64_tr_b16 a[2:3], v34 offset:24576
	ds_read_b64_tr_b16 v[216:217], v34 offset:24704
	ds_read_b64_tr_b16 v[196:197], v34 offset:24832
	ds_read_b64_tr_b16 v[184:185], v34 offset:24960
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_bf16 v[30:33], v[244:247], v[2:5], v[30:33]
	ds_read_b64_tr_b16 a[8:9], v1
	ds_read_b64_tr_b16 a[12:13], v1 offset:128
	ds_read_b64_tr_b16 a[16:17], v1 offset:256
	ds_read_b64_tr_b16 a[20:21], v1 offset:384
	ds_read_b64_tr_b16 a[10:11], v1 offset:8192
	ds_read_b64_tr_b16 a[14:15], v1 offset:8320
	ds_read_b64_tr_b16 a[18:19], v1 offset:8448
	ds_read_b64_tr_b16 a[22:23], v1 offset:8576
	ds_read_b64_tr_b16 a[4:5], v1 offset:16384
	ds_read_b64_tr_b16 a[24:25], v1 offset:16512
	ds_read_b64_tr_b16 a[28:29], v1 offset:16640
	ds_read_b64_tr_b16 a[32:33], v1 offset:16768
	v_mfma_f32_16x16x32_bf16 v[154:157], v[248:251], v[6:9], v[30:33]
	ds_read_b64_tr_b16 a[26:27], v1 offset:24704
	ds_read_b64_tr_b16 a[30:31], v1 offset:24832
	ds_read_b64_tr_b16 a[34:35], v1 offset:24960
	v_pk_mul_f32 v[32:33], v[152:153], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[30:31], v[150:151], v[228:229] op_sel_hi:[1,0]
	v_mul_f32_e32 v1, 0x3fb8aa3b, v243
	v_cmp_gt_f32_e32 vcc, s2, v1
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_bf16 v[30:33], v[252:255], v[2:5], v[30:33]
	v_cndmask_b32_e32 v1, 0, v237, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v243
	v_mfma_f32_16x16x32_bf16 v[150:153], a[0:3], v[6:9], v[30:33]
	v_exp_f32_e32 v1, v1
	v_cndmask_b32_e32 v38, 0, v236, vcc
	s_nop 2
	v_pk_mul_f32 v[32:33], v[148:149], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[30:31], v[146:147], v[228:229] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(10)
	s_nop 0
	v_mfma_f32_16x16x32_bf16 v[30:33], a[8:11], v[2:5], v[30:33]
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[146:149], a[4:7], v[6:9], v[30:33]
	s_nop 5
	v_mul_f32_e64 v32, v144, v228
	v_mul_f32_e64 v33, v145, v228
	v_pk_mul_f32 v[30:31], v[142:143], v[228:229] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[30:33], v[26:29], v[2:5], v[30:33]
	v_mfma_f32_16x16x32_bf16 v[142:145], v[198:201], v[6:9], v[30:33]
	s_nop 6
	v_mul_f32_e64 v32, v140, v228
	v_mul_f32_e64 v33, v141, v228
	v_pk_mul_f32 v[30:31], v[138:139], v[228:229] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[34:37], v[202:205], v[2:5], v[30:33]
	v_mfma_f32_16x16x32_bf16 v[138:141], v[206:209], v[6:9], v[34:37]
	s_nop 1
	v_ldexp_f32 v32, v1, v38
	v_sub_f32_e32 v1, v240, v242
	v_mul_f32_e32 v39, 0x3fb8aa3b, v1
	v_cmp_gt_f32_e32 vcc, s2, v39
	s_nop 0
	v_pk_mul_f32 v[36:37], v[136:137], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[134:135], v[228:229] op_sel_hi:[1,0]
	v_sub_f32_e32 v30, v241, v242
	v_cndmask_b32_e32 v39, 0, v237, vcc
	v_mfma_f32_16x16x32_bf16 v[34:37], v[210:213], v[2:5], v[34:37]
	v_fmac_f32_e32 v39, 0x3fb8aa3b, v1
	v_mul_f32_e32 v40, 0x3fb8aa3b, v30
	v_exp_f32_e32 v1, v39
	v_mfma_f32_16x16x32_bf16 v[134:137], v[214:217], v[6:9], v[34:37]
	v_cndmask_b32_e32 v39, 0, v236, vcc
	v_cmp_gt_f32_e32 vcc, s2, v40
	v_sub_f32_e32 v31, v239, v242
	v_ldexp_f32 v39, v1, v39
	v_pk_mul_f32 v[36:37], v[132:133], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[130:131], v[228:229] op_sel_hi:[1,0]
	v_cndmask_b32_e32 v40, 0, v237, vcc
	v_fmac_f32_e32 v40, 0x3fb8aa3b, v30
	v_mfma_f32_16x16x32_bf16 v[34:37], a[12:15], v[2:5], v[34:37]
	v_exp_f32_e32 v30, v40
	v_cndmask_b32_e32 v1, 0, v236, vcc
	v_sub_f32_e32 v33, v238, v242
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[130:133], a[24:27], v[6:9], v[34:37]
	v_ldexp_f32 v30, v30, v1
	v_mul_f32_e32 v1, 0x3fb8aa3b, v31
	v_cmp_gt_f32_e32 vcc, s2, v1
	v_sub_f32_e32 v38, 0xff800000, v242
	v_pk_mul_f32 v[36:37], v[128:129], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[126:127], v[228:229] op_sel_hi:[1,0]
	v_cndmask_b32_e32 v1, 0, v237, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v31
	v_mfma_f32_16x16x32_bf16 v[34:37], v[14:17], v[2:5], v[34:37]
	v_exp_f32_e32 v1, v1
	v_cndmask_b32_e32 v31, 0, v236, vcc
	v_mul_f32_e32 v40, 0x3fb8aa3b, v38
	v_mfma_f32_16x16x32_bf16 v[126:129], v[18:21], v[6:9], v[34:37]
	v_ldexp_f32 v31, v1, v31
	v_mul_f32_e32 v1, 0x3fb8aa3b, v33
	v_cmp_gt_f32_e32 vcc, s2, v1
	v_cvt_pk_bf16_f32 v162, v39, v30
	v_pk_mul_f32 v[36:37], v[124:125], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[122:123], v[228:229] op_sel_hi:[1,0]
	v_cndmask_b32_e32 v1, 0, v237, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v33
	v_mfma_f32_16x16x32_bf16 v[34:37], v[22:25], v[2:5], v[34:37]
	v_cndmask_b32_e32 v33, 0, v236, vcc
	v_cmp_gt_f32_e32 vcc, s2, v40
	v_exp_f32_e32 v1, v1
	v_mfma_f32_16x16x32_bf16 v[122:125], v[186:189], v[6:9], v[34:37]
	v_cndmask_b32_e32 v40, 0, v237, vcc
	v_fmac_f32_e32 v40, 0x3fb8aa3b, v38
	v_exp_f32_e32 v38, v40
	v_ldexp_f32 v33, v1, v33
	v_pk_mul_f32 v[36:37], v[120:121], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[118:119], v[228:229] op_sel_hi:[1,0]
	v_cndmask_b32_e32 v1, 0, v236, vcc
	v_ldexp_f32 v38, v38, v1
	v_mfma_f32_16x16x32_bf16 v[34:37], v[190:193], v[2:5], v[34:37]
	v_cvt_pk_bf16_f32 v164, v38, v38
	v_cvt_pk_bf16_f32 v163, v31, v33
	v_mov_b32_e32 v165, v164
	v_mfma_f32_16x16x32_bf16 v[118:121], v[194:197], v[6:9], v[34:37]
	v_accvgpr_read_b32 v1, a129
	v_lshrrev_b32_e32 v1, 2, v1
	s_nop 1
	v_pk_mul_f32 v[36:37], v[116:117], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[114:115], v[228:229] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[34:37], a[16:19], v[2:5], v[34:37]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[114:117], a[28:31], v[6:9], v[34:37]
	s_nop 5
	v_mul_f32_e64 v36, v112, v228
	v_mul_f32_e64 v37, v113, v228
	v_pk_mul_f32 v[34:35], v[110:111], v[228:229] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[34:37], v[10:13], v[2:5], v[34:37]
	v_mfma_f32_16x16x32_bf16 v[110:113], v[166:169], v[6:9], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v108, v228
	v_mul_f32_e64 v37, v109, v228
	v_pk_mul_f32 v[34:35], v[106:107], v[228:229] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[34:37], v[170:173], v[2:5], v[34:37]
	v_mfma_f32_16x16x32_bf16 v[106:109], v[174:177], v[6:9], v[34:37]
	s_nop 6
	v_accvgpr_read_b32 v34, a140
	v_accvgpr_read_b32 v35, a141
	v_accvgpr_read_b32 v36, a142
	v_accvgpr_read_b32 v37, a143
	v_pk_mul_f32 v[36:37], v[36:37], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[34:35], v[228:229] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[34:37], v[178:181], v[2:5], v[34:37]
	v_mfma_f32_16x16x32_bf16 v[102:105], v[182:185], v[6:9], v[34:37]
	s_nop 6
	v_accvgpr_read_b32 v34, a136
	v_accvgpr_read_b32 v35, a137
	v_accvgpr_read_b32 v36, a138
	v_accvgpr_read_b32 v37, a139
	v_pk_mul_f32 v[36:37], v[36:37], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[34:35], v[228:229] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[2:5], a[20:23], v[2:5], v[34:37]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[98:101], a[32:35], v[6:9], v[2:5]
	s_nop 0
	v_mov_b32_e32 v34, v164
	v_mov_b32_e32 v35, v164
	v_mov_b32_e32 v36, v164
	v_mov_b32_e32 v37, v164
	s_nop 0
	v_accvgpr_read_b32 v2, a132
	v_accvgpr_read_b32 v3, a133
	v_accvgpr_read_b32 v4, a134
	v_accvgpr_read_b32 v5, a135
	v_pk_mul_f32 v[4:5], v[4:5], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[2:5], v[218:221], v[162:165], v[2:5]
	v_and_or_b32 v218, v0, 16, v1
	v_or_b32_e32 v219, 0xe0, v218
	v_or_b32_e32 v220, 0xc0, v218
	v_mfma_f32_16x16x32_bf16 v[94:97], v[222:225], v[34:37], v[2:5]
	v_or_b32_e32 v221, 0xa0, v218
	v_or_b32_e32 v222, 0x80, v218
	v_or_b32_e32 v223, 0x60, v218
	v_or_b32_e32 v224, 64, v218
	v_accvgpr_read_b32 v2, a122
	v_accvgpr_read_b32 v3, a123
	v_accvgpr_read_b32 v4, a124
	v_accvgpr_read_b32 v5, a125
	v_pk_mul_f32 v[4:5], v[4:5], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	v_or_b32_e32 v225, 32, v218
	s_nop 0
	v_mfma_f32_16x16x32_bf16 v[2:5], v[244:247], v[162:165], v[2:5]
	v_mfma_f32_16x16x32_bf16 v[90:93], v[248:251], v[34:37], v[2:5]
	s_nop 6
	v_accvgpr_read_b32 v2, a118
	v_accvgpr_read_b32 v3, a119
	v_accvgpr_read_b32 v4, a120
	v_accvgpr_read_b32 v5, a121
	v_pk_mul_f32 v[4:5], v[4:5], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[2:5], v[252:255], v[162:165], v[2:5]
	v_mfma_f32_16x16x32_bf16 v[86:89], a[0:3], v[34:37], v[2:5]
	v_accvgpr_read_b32 v0, a114
	v_accvgpr_read_b32 v1, a115
	v_pk_mul_f32 v[0:1], v[0:1], v[32:33] op_sel_hi:[1,0]
	s_nop 3
	v_accvgpr_read_b32 v2, a116
	v_accvgpr_read_b32 v3, a117
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
.Ltmp218:
	v_add_f32_e32 v5, v39, v30
	v_add_f32_e32 v5, v31, v5
.Ltmp219:
	v_mfma_f32_16x16x32_bf16 v[0:3], a[8:11], v[162:165], v[0:3]
.Ltmp220:
	v_add_f32_e32 v4, v230, v232
	v_add_f32_e32 v4, v234, v4
	v_add_f32_e32 v4, v235, v4
.Ltmp221:
	v_mfma_f32_16x16x32_bf16 v[82:85], a[4:7], v[34:37], v[0:3]
.Ltmp222:
	v_add_f32_e32 v4, v229, v4
	v_add_f32_e32 v4, v229, v4
	v_add_f32_e32 v4, v229, v4
	v_add_f32_e32 v4, v229, v4
	v_accvgpr_read_b32 v0, a110
	v_accvgpr_read_b32 v1, a111
	v_accvgpr_read_b32 v2, a112
	v_accvgpr_read_b32 v3, a113
.Ltmp223:
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[0:1], v[32:33] op_sel_hi:[1,0]
.Ltmp224:
	v_add_f32_e32 v4, v229, v4
	v_add_f32_e32 v5, v33, v5
.Ltmp225:
	v_mfma_f32_16x16x32_bf16 v[0:3], v[26:29], v[162:165], v[0:3]
.Ltmp226:
	v_add_f32_e32 v4, v229, v4
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v4, v229, v4
.Ltmp227:
	v_mfma_f32_16x16x32_bf16 v[78:81], v[198:201], v[34:37], v[0:3]
.Ltmp228:
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v4, v229, v4
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v4, v229, v4
	v_accvgpr_read_b32 v0, a106
	v_accvgpr_read_b32 v1, a107
	v_accvgpr_read_b32 v2, a108
	v_accvgpr_read_b32 v3, a109
.Ltmp229:
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[0:1], v[32:33] op_sel_hi:[1,0]
.Ltmp230:
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v4, v229, v4
.Ltmp231:
	v_mfma_f32_16x16x32_bf16 v[0:3], v[202:205], v[162:165], v[0:3]
.Ltmp232:
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v4, v229, v4
	v_add_f32_e32 v5, v38, v5
.Ltmp233:
	v_mfma_f32_16x16x32_bf16 v[74:77], v[206:209], v[34:37], v[0:3]
.Ltmp234:
	v_add_f32_e32 v4, v229, v4
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v5, v38, v5
.Ltmp235:
	v_mov_b32_e32 v6, v4
.Ltmp236:
	v_pk_mul_f32 v[2:3], v[72:73], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[70:71], v[32:33] op_sel_hi:[1,0]
.Ltmp237:
	v_add_f32_e32 v5, v38, v5
.Ltmp238:
	v_permlane32_swap_b32_e32 v4, v6
.Ltmp239:
	v_mfma_f32_16x16x32_bf16 v[0:3], v[210:213], v[162:165], v[0:3]
.Ltmp240:
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v4, v4, v6
	v_add_f32_e32 v5, v38, v5
.Ltmp241:
	v_mfma_f32_16x16x32_bf16 v[70:73], v[214:217], v[34:37], v[0:3]
.Ltmp242:
	v_mov_b32_e32 v6, v4
.Ltmp243:
	v_add_f32_e32 v5, v38, v5
.Ltmp244:
	s_nop 0
	v_permlane16_swap_b32_e32 v4, v6
.Ltmp245:
	v_pk_mul_f32 v[2:3], v[68:69], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[66:67], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[0:3], a[12:15], v[162:165], v[0:3]
	v_mfma_f32_16x16x32_bf16 v[66:69], a[24:27], v[34:37], v[0:3]
	s_nop 6
	v_mul_f32_e64 v2, v64, v32
	v_mul_f32_e64 v3, v65, v32
	v_pk_mul_f32 v[0:1], v[62:63], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[0:3], v[14:17], v[162:165], v[0:3]
	v_mfma_f32_16x16x32_bf16 v[28:31], v[18:21], v[34:37], v[0:3]
	s_nop 6
	v_mul_f32_e64 v2, v60, v32
	v_mul_f32_e64 v3, v61, v32
	v_pk_mul_f32 v[0:1], v[58:59], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[0:3], v[22:25], v[162:165], v[0:3]
	v_mfma_f32_16x16x32_bf16 v[24:27], v[186:189], v[34:37], v[0:3]
	s_nop 6
	v_mul_f32_e64 v2, v56, v32
	v_mul_f32_e64 v3, v57, v32
	v_pk_mul_f32 v[0:1], v[54:55], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[0:3], v[190:193], v[162:165], v[0:3]
	v_mfma_f32_16x16x32_bf16 v[20:23], v[194:197], v[34:37], v[0:3]
	s_nop 6
	v_accvgpr_read_b32 v0, a102
	v_accvgpr_read_b32 v1, a103
	v_accvgpr_read_b32 v2, a104
	v_accvgpr_read_b32 v3, a105
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[0:1], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[0:3], a[16:19], v[162:165], v[0:3]
	v_mfma_f32_16x16x32_bf16 v[16:19], a[28:31], v[34:37], v[0:3]
	s_nop 6
	v_accvgpr_read_b32 v0, a98
	v_accvgpr_read_b32 v1, a99
	v_accvgpr_read_b32 v2, a100
	v_accvgpr_read_b32 v3, a101
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[0:1], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[0:3], v[10:13], v[162:165], v[0:3]
	v_mfma_f32_16x16x32_bf16 v[12:15], v[166:169], v[34:37], v[0:3]
.Ltmp246:
	v_add_f32_e32 v166, v4, v6
.Ltmp247:
	v_mov_b32_e32 v4, v5
	s_nop 1
	v_permlane32_swap_b32_e32 v5, v4
.Ltmp248:
	s_nop 1
	v_pk_mul_f32 v[2:3], v[52:53], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[50:51], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[0:3], v[170:173], v[162:165], v[0:3]
	v_mfma_f32_16x16x32_bf16 v[8:11], v[174:177], v[34:37], v[0:3]
	s_nop 6
	v_mul_f32_e64 v2, v48, v32
	v_mul_f32_e64 v3, v49, v32
	v_pk_mul_f32 v[0:1], v[46:47], v[32:33] op_sel_hi:[1,0]
.Ltmp249:
	v_add_f32_e32 v33, v5, v4
.Ltmp250:
	v_mov_b32_e32 v38, v33
.Ltmp251:
	v_mfma_f32_16x16x32_bf16 v[0:3], v[178:181], v[162:165], v[0:3]
.Ltmp252:
	s_nop 0
	v_permlane16_swap_b32_e32 v33, v38
.Ltmp253:
	v_add_f32_e32 v48, v33, v38
	v_accvgpr_read_b32 v38, a96
.Ltmp254:
	v_fmac_f32_e32 v166, v38, v228
	v_mfma_f32_16x16x32_bf16 v[4:7], v[182:185], v[34:37], v[0:3]
	v_div_scale_f32 v50, s[0:1], v166, v166, v158
	v_rcp_f32_e32 v51, v50
	s_nop 0
	v_pk_mul_f32 v[2:3], v[44:45], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[42:43], v[32:33] op_sel_hi:[1,0]
	v_accvgpr_read_b32 v39, a97
	v_fmac_f32_e32 v48, v39, v32
	v_mfma_f32_16x16x32_bf16 v[0:3], a[20:23], v[162:165], v[0:3]
	v_mul_u32_u24_e32 v32, 0x1800, v227
	v_or_b32_e32 v49, 0x100, v32
	v_or_b32_e32 v47, v218, v32
	v_mfma_f32_16x16x32_bf16 v[0:3], a[32:35], v[34:37], v[0:3]
	v_or_b32_e32 v46, v225, v32
	v_or_b32_e32 v45, v224, v32
	v_or_b32_e32 v44, v223, v32
	v_or_b32_e32 v43, v222, v32
	v_or_b32_e32 v42, v221, v32
	v_or_b32_e32 v41, v220, v32
	v_or_b32_e32 v40, v219, v32
	v_or_b32_e32 v39, v49, v218
	v_or_b32_e32 v38, v225, v49
	v_or_b32_e32 v37, v224, v49
	v_or_b32_e32 v36, v223, v49
	v_or_b32_e32 v35, v222, v49
	v_or_b32_e32 v34, v221, v49
	v_or_b32_e32 v33, v220, v49
	v_or_b32_e32 v32, v219, v49
	v_fma_f32 v49, -v50, v51, 1.0
	v_fmac_f32_e32 v51, v49, v51
	v_div_scale_f32 v49, vcc, v158, v166, v158
	v_mul_f32_e32 v52, v49, v51
	v_fma_f32 v53, -v50, v52, v49
	v_fmac_f32_e32 v52, v53, v51
	v_fma_f32 v49, -v50, v52, v49
	v_div_scale_f32 v50, s[0:1], v166, v166, v159
	v_rcp_f32_e32 v53, v50
	v_div_fmas_f32 v49, v49, v51, v52
	v_div_fixup_f32 v49, v49, v166, v158
	v_add_lshl_u32 v47, v47, s33, 1
	v_fma_f32 v51, -v50, v53, 1.0
	v_fmac_f32_e32 v53, v51, v53
	v_div_scale_f32 v51, vcc, v159, v166, v159
	v_mul_f32_e32 v52, v51, v53
	v_fma_f32 v54, -v50, v52, v51
	v_fmac_f32_e32 v52, v54, v53
	v_fma_f32 v50, -v50, v52, v51
	v_div_scale_f32 v51, s[0:1], v166, v166, v160
	v_rcp_f32_e32 v54, v51
	v_div_fmas_f32 v50, v50, v53, v52
	v_div_fixup_f32 v50, v50, v166, v159
	v_cndmask_b32_e64 v47, v233, v47, s[30:31]
	NETRA_ATTENTION_GQA6_M8_OUTPUT_NORMALIZE
	NETRA_ATTENTION_GQA6_M8_OUTPUT_PACK_FIRST_STORE
	v_add_lshl_u32 v0, v46, s33, 1
	v_permlane16_swap_b32_e32 v5, v7
	v_cndmask_b32_e64 v0, v233, v0, s[30:31]
	buffer_store_dwordx4 v[4:7], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v45, s33, 1
	v_permlane16_swap_b32_e32 v8, v10
	v_permlane16_swap_b32_e32 v9, v11
	v_cndmask_b32_e64 v0, v233, v0, s[30:31]
	buffer_store_dwordx4 v[8:11], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v44, s33, 1
	v_permlane16_swap_b32_e32 v12, v14
	v_permlane16_swap_b32_e32 v13, v15
	v_cndmask_b32_e64 v0, v233, v0, s[30:31]
	buffer_store_dwordx4 v[12:15], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v43, s33, 1
	v_permlane16_swap_b32_e32 v16, v18
	v_permlane16_swap_b32_e32 v17, v19
	v_cndmask_b32_e64 v0, v233, v0, s[30:31]
	buffer_store_dwordx4 v[16:19], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v42, s33, 1
	v_permlane16_swap_b32_e32 v20, v22
	v_permlane16_swap_b32_e32 v21, v23
	v_cndmask_b32_e64 v0, v233, v0, s[30:31]
	buffer_store_dwordx4 v[20:23], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v41, s33, 1
	v_permlane16_swap_b32_e32 v24, v26
	v_permlane16_swap_b32_e32 v25, v27
	v_cndmask_b32_e64 v0, v233, v0, s[30:31]
	v_cvt_pk_bf16_f32 v48, v102, v103
	v_cvt_pk_bf16_f32 v49, v104, v105
	v_cvt_pk_bf16_f32 v50, v98, v99
	v_cvt_pk_bf16_f32 v51, v100, v101
	buffer_store_dwordx4 v[24:27], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v40, s33, 1
	v_permlane16_swap_b32_e32 v48, v50
	v_permlane16_swap_b32_e32 v49, v51
	v_cndmask_b32_e64 v0, v233, v0, s[30:31]
	v_cvt_pk_bf16_f32 v52, v94, v95
	v_cvt_pk_bf16_f32 v53, v96, v97
	v_cvt_pk_bf16_f32 v54, v90, v91
	v_cvt_pk_bf16_f32 v55, v92, v93
	buffer_store_dwordx4 v[48:51], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v39, s33, 1
	v_permlane16_swap_b32_e32 v52, v54
	v_permlane16_swap_b32_e32 v53, v55
	v_cndmask_b32_e64 v0, v233, v0, s[30:31]
	v_cvt_pk_bf16_f32 v56, v86, v87
	v_cvt_pk_bf16_f32 v57, v88, v89
	v_cvt_pk_bf16_f32 v58, v82, v83
	v_cvt_pk_bf16_f32 v59, v84, v85
	buffer_store_dwordx4 v[52:55], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v38, s33, 1
	v_permlane16_swap_b32_e32 v56, v58
	v_permlane16_swap_b32_e32 v57, v59
	v_cndmask_b32_e64 v0, v233, v0, s[30:31]
	v_cvt_pk_bf16_f32 v60, v78, v79
	v_cvt_pk_bf16_f32 v61, v80, v81
	v_cvt_pk_bf16_f32 v62, v74, v75
	v_cvt_pk_bf16_f32 v63, v76, v77
	buffer_store_dwordx4 v[56:59], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v37, s33, 1
	v_permlane16_swap_b32_e32 v60, v62
	v_permlane16_swap_b32_e32 v61, v63
	v_cndmask_b32_e64 v0, v233, v0, s[30:31]
	v_cvt_pk_bf16_f32 v64, v70, v71
	v_cvt_pk_bf16_f32 v65, v72, v73
	buffer_store_dwordx4 v[60:63], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v36, s33, 1
	v_permlane16_swap_b32_e32 v64, v66
	v_permlane16_swap_b32_e32 v65, v67
	v_cndmask_b32_e64 v0, v233, v0, s[30:31]
	buffer_store_dwordx4 v[64:67], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v35, s33, 1
	v_cndmask_b32_e64 v0, v233, v0, s[30:31]
	v_cvt_pk_bf16_f32 v68, v146, v150
	v_cvt_pk_bf16_f32 v69, v151, v152
	v_cvt_pk_bf16_f32 v70, v153, v154
	v_cvt_pk_bf16_f32 v71, v155, v156
	buffer_store_dwordx4 v[28:31], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v34, s33, 1
	v_permlane16_swap_b32_e32 v68, v70
	v_permlane16_swap_b32_e32 v69, v71
	v_cndmask_b32_e64 v0, v233, v0, s[30:31]
	v_cvt_pk_bf16_f32 v72, v157, v158
	v_cvt_pk_bf16_f32 v73, v159, v160
	v_cvt_pk_bf16_f32 v74, v161, v162
	v_cvt_pk_bf16_f32 v75, v163, v164
	buffer_store_dwordx4 v[68:71], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v33, s33, 1
	v_permlane16_swap_b32_e32 v72, v74
	v_permlane16_swap_b32_e32 v73, v75
	v_cndmask_b32_e64 v0, v233, v0, s[30:31]
	v_cvt_pk_bf16_f32 v76, v165, v166
	v_cvt_pk_bf16_f32 v77, v167, v168
	v_cvt_pk_bf16_f32 v78, v169, v170
	v_cvt_pk_bf16_f32 v79, v171, v172
	buffer_store_dwordx4 v[72:75], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v32, s33, 1
	v_permlane16_swap_b32_e32 v76, v78
	v_permlane16_swap_b32_e32 v77, v79
	v_cndmask_b32_e64 v0, v233, v0, s[30:31]
	buffer_store_dwordx4 v[76:79], v0, s[8:11], 0 offen
	s_endpgm
.Ltmp255:
	NETRA_ATTENTION_KERNEL_DESCRIPTOR \symbol, 32768, 96, 1, 1, 412, 96, 256
	.text
.Lfunc_end0:
	.size	\symbol, .Lfunc_end0-\symbol
                                        ; -- End function
	.set \symbol\().num_vgpr, 256
	.set \symbol\().num_agpr, 156
	.set \symbol\().numbered_sgpr, 96
	.set \symbol\().num_named_barrier, 0
	.set \symbol\().private_seg_size, 0
	.set \symbol\().uses_vcc, 1
	.set \symbol\().uses_flat_scratch, 0
	.set \symbol\().has_dyn_sized_stack, 0
	.set \symbol\().has_recursion, 0
	.set \symbol\().has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 30264
; TotalNumSgprs: 102
; NumVgprs: 256
; NumAgprs: 156
; TotalNumVgprs: 412
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 12
; VGPRBlocks: 51
; NumSGPRsForWavesPerEU: 102
; NumVGPRsForWavesPerEU: 412
; AccumOffset: 256
; Occupancy: 1
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 63
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
	NETRA_ATTENTION_GQA4_GQA6_METADATA \symbol, 32768, 64, 412, 102, 156
.Lline_table_start0:
	.endm
