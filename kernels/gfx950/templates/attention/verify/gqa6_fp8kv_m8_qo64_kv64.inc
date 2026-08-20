// Netra model-independent fixed-contract tactic template.
	.include "kernels/gfx950/templates/common/primitives.inc"
	NETRA_GFX950_MODULE_HEADER 5
	; DFlash verification attention: M=8, GQA6, D=256.
	; Grid = [batch, 4 KV heads, 3 query-head pairs].
	.macro NETRA_ATTENTION_GQA6_FP8KV_QO64_KV64 symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_M_MAX, 8
	NETRA_REQUIRE_EQ NETRA_QUERY_HEADS, 24
	NETRA_REQUIRE_EQ NETRA_KV_HEADS, 4
	NETRA_REQUIRE_EQ NETRA_HEAD_DIM, 256
	NETRA_REQUIRE_EQ NETRA_VALUE_TOKEN_STRIDE, 14336
	NETRA_REQUIRE_EQ NETRA_KV_LAYOUT_ID, 1
	NETRA_REQUIRE_EQ NETRA_QO_INDPTR_BITS, 64
	NETRA_REQUIRE_EQ NETRA_KV_INDEX_BITS, 64
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
	s_mov_b32 s33, s17
	s_mov_b64 s[80:81], s[10:11]
	s_mov_b64 s[76:77], s[6:7]
.Ltmp1:
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	s_ashr_i32 s17, s16, 31
	s_lshl_b64 s[6:7], s[16:17], 3
	s_add_u32 s6, s14, s6
	s_addc_u32 s7, s15, s7
	v_mov_b32_e32 v167, 0
	global_load_dwordx4 v[2:5], v167, s[6:7]
	s_lshl_b64 s[6:7], s[16:17], 2
	s_waitcnt lgkmcnt(0)
	s_add_u32 s2, s2, s6
	s_mul_i32 s10, s33, 0x600
	s_addc_u32 s3, s3, s7
	s_lshl_b32 s89, s18, 9
	v_lshrrev_b32_e32 v6, 5, v0
	v_and_b32_e32 v1, 31, v0
	global_load_dwordx2 v[22:23], v167, s[2:3]
	s_add_i32 s89, s89, s10
	v_or_b32_e32 v8, 2, v6
	v_or_b32_e32 v10, 4, v6
	v_or_b32_e32 v12, 6, v6
	v_or_b32_e32 v14, 8, v6
	v_or_b32_e32 v16, 10, v6
	v_or_b32_e32 v18, 12, v6
	v_or_b32_e32 v20, 14, v6
	v_mul_u32_u24_e32 v25, 0x1800, v6
	v_lshl_or_b32 v33, v1, 3, s89
	v_mov_b32_e32 v7, v167
	v_mul_u32_u24_e32 v26, 0x1800, v8
	v_mul_u32_u24_e32 v27, 0x1800, v10
	v_mul_u32_u24_e32 v28, 0x1800, v12
	v_mul_u32_u24_e32 v29, 0x1800, v14
	v_mul_u32_u24_e32 v30, 0x1800, v16
	v_mul_u32_u24_e32 v31, 0x1800, v18
	v_mul_u32_u24_e32 v32, 0x1800, v20
	v_add_u32_e32 v34, v25, v33
	v_bfrev_b32_e32 v24, 1
	v_mov_b32_e32 v9, v167
	v_mov_b32_e32 v11, v167
	v_mov_b32_e32 v13, v167
	v_mov_b32_e32 v15, v167
	v_mov_b32_e32 v17, v167
	v_add_u32_e32 v35, v26, v33
	v_add_u32_e32 v36, v27, v33
	v_add_u32_e32 v37, v28, v33
	v_add_u32_e32 v38, v29, v33
	v_add_u32_e32 v39, v30, v33
	v_add_u32_e32 v40, v31, v33
	v_add_u32_e32 v41, v32, v33
	v_or_b32_e32 v33, 0x100, v33
	s_mov_b32 s27, 0x27000
	s_mov_b32 s26, 0x7ffffffe
	s_and_b32 s25, s25, 0xffff
	v_add_u32_e32 v25, v25, v33
	v_add_u32_e32 v26, v26, v33
	v_add_u32_e32 v27, v27, v33
	v_add_u32_e32 v28, v28, v33
	v_add_u32_e32 v29, v29, v33
	v_add_u32_e32 v30, v30, v33
	v_add_u32_e32 v31, v31, v33
	v_add_u32_e32 v32, v32, v33
	v_mov_b32_e32 v19, v167
	v_mov_b32_e32 v21, v167
	v_and_b32_e32 v166, 15, v0
	s_waitcnt vmcnt(1)
	v_readfirstlane_b32 s2, v3
	v_readfirstlane_b32 s91, v2
	s_nop 0
	v_mov_b32_e32 v2, s2
	s_mul_i32 s88, s91, 0x1800
	v_subrev_co_u32_e32 v230, vcc, s91, v4
	v_add_lshl_u32 v3, v35, s88, 1
	s_nop 0
	v_subb_co_u32_e32 v231, vcc, v5, v2, vcc
	v_add_lshl_u32 v2, v34, s88, 1
	v_cmp_gt_i64_e32 vcc, v[230:231], v[6:7]
	v_add_lshl_u32 v4, v36, s88, 1
	v_add_lshl_u32 v5, v37, s88, 1
	v_add_lshl_u32 v33, v38, s88, 1
	v_add_lshl_u32 v34, v39, s88, 1
	v_cndmask_b32_e32 v2, v24, v2, vcc
	v_cmp_gt_i64_e64 s[2:3], v[230:231], v[8:9]
	v_cmp_gt_i64_e64 s[6:7], v[230:231], v[10:11]
	v_cmp_gt_i64_e64 s[10:11], v[230:231], v[12:13]
	v_cmp_gt_i64_e64 s[14:15], v[230:231], v[14:15]
	v_cmp_gt_i64_e64 s[16:17], v[230:231], v[16:17]
	v_cndmask_b32_e64 v3, v24, v3, s[2:3]
	v_cndmask_b32_e64 v4, v24, v4, s[6:7]
	v_cndmask_b32_e64 v5, v24, v5, s[10:11]
	v_cndmask_b32_e64 v6, v24, v33, s[14:15]
	buffer_load_dwordx4 a[28:31], v2, s[24:27], 0 offen
	buffer_load_dwordx4 a[20:23], v3, s[24:27], 0 offen
	buffer_load_dwordx4 a[8:11], v4, s[24:27], 0 offen
	buffer_load_dwordx4 a[0:3], v5, s[24:27], 0 offen
	v_cndmask_b32_e64 v2, v24, v34, s[16:17]
	buffer_load_dwordx4 a[12:15], v6, s[24:27], 0 offen
	buffer_load_dwordx4 a[4:7], v2, s[24:27], 0 offen
	v_add_lshl_u32 v2, v40, s88, 1
	v_cmp_gt_i64_e64 s[18:19], v[230:231], v[18:19]
	v_add_lshl_u32 v3, v41, s88, 1
	v_cmp_gt_i64_e64 s[20:21], v[230:231], v[20:21]
	v_cndmask_b32_e64 v2, v24, v2, s[18:19]
	v_and_b32_e32 v10, 48, v0
	v_cndmask_b32_e64 v3, v24, v3, s[20:21]
	buffer_load_dwordx4 a[24:27], v2, s[24:27], 0 offen
	buffer_load_dwordx4 a[16:19], v3, s[24:27], 0 offen
	v_add_lshl_u32 v2, v25, s88, 1
	v_cndmask_b32_e32 v2, v24, v2, vcc
	v_add_lshl_u32 v3, v26, s88, 1
	v_cndmask_b32_e64 v3, v24, v3, s[2:3]
	buffer_load_dwordx4 a[36:39], v2, s[24:27], 0 offen
	buffer_load_dwordx4 a[32:35], v3, s[24:27], 0 offen
	v_add_lshl_u32 v2, v27, s88, 1
	v_cndmask_b32_e64 v2, v24, v2, s[6:7]
	v_add_lshl_u32 v3, v28, s88, 1
	v_cndmask_b32_e64 v3, v24, v3, s[10:11]
	buffer_load_dwordx4 a[52:55], v2, s[24:27], 0 offen
	buffer_load_dwordx4 a[40:43], v3, s[24:27], 0 offen
	v_add_lshl_u32 v2, v29, s88, 1
	v_cndmask_b32_e64 v2, v24, v2, s[14:15]
	v_add_lshl_u32 v3, v30, s88, 1
	v_cndmask_b32_e64 v3, v24, v3, s[16:17]
	buffer_load_dwordx4 a[56:59], v2, s[24:27], 0 offen
	buffer_load_dwordx4 a[44:47], v3, s[24:27], 0 offen
	v_add_lshl_u32 v2, v31, s88, 1
	v_cndmask_b32_e64 v2, v24, v2, s[18:19]
	v_add_lshl_u32 v3, v32, s88, 1
	v_cndmask_b32_e64 v3, v24, v3, s[20:21]
	buffer_load_dwordx4 a[60:63], v2, s[24:27], 0 offen
	buffer_load_dwordx4 a[48:51], v3, s[24:27], 0 offen
	v_and_b32_e32 v3, 32, v0
	v_bfe_i32 v2, v0, 5, 1
	s_movk_i32 s6, 0x220
	v_lshlrev_b32_e32 v4, 4, v1
	v_accvgpr_write_b32 a129, v3
	v_cmp_eq_u32_e64 s[2:3], 0, v3
	v_lshrrev_b32_e32 v3, 1, v10
	v_bitop3_b32 v2, v2, v4, s6 bitop3:0x6c
	v_accvgpr_write_b32 a174, v3
	v_accvgpr_write_b32 a177, v4
	v_add_u32_e32 v3, 0, v2
	v_xad_u32 v4, v2, 64, 0
	v_xor_b32_e32 v5, 0x80, v2
	v_xor_b32_e32 v6, 0xc0, v2
	v_xor_b32_e32 v7, 0x100, v2
	v_xor_b32_e32 v8, 0x140, v2
	v_xor_b32_e32 v9, 0x180, v2
	v_xor_b32_e32 v2, 0x1c0, v2
	v_add_u32_e32 v2, 0, v2
	s_waitcnt vmcnt(16)
	v_readfirstlane_b32 s6, v23
	v_readfirstlane_b32 s14, v22
	v_add_u32_e32 v5, 0, v5
	v_add_u32_e32 v6, 0, v6
	v_add_u32_e32 v7, 0, v7
	v_add_u32_e32 v8, 0, v8
	v_add_u32_e32 v9, 0, v9
	s_sub_i32 s93, s6, s14
	v_cmp_gt_i64_e64 s[44:45], v[230:231], v[166:167]
	s_cmp_gt_i32 s93, 0
	s_waitcnt vmcnt(15)
	ds_write_b128 v3, a[28:31]
	s_waitcnt vmcnt(14)
	ds_write_b128 v4, a[20:23] offset:1024
	s_waitcnt vmcnt(13)
	ds_write_b128 v5, a[8:11] offset:2048
	s_waitcnt vmcnt(12)
	ds_write_b128 v6, a[0:3] offset:3072
	s_waitcnt vmcnt(11)
	ds_write_b128 v7, a[12:15] offset:4096
	s_waitcnt vmcnt(10)
	ds_write_b128 v8, a[4:7] offset:5120
	s_waitcnt vmcnt(9)
	ds_write_b128 v9, a[24:27] offset:6144
	s_waitcnt vmcnt(8)
	ds_write_b128 v2, a[16:19] offset:7168
	s_waitcnt vmcnt(7)
	ds_write_b128 v3, a[36:39] offset:8192
	s_waitcnt vmcnt(6)
	ds_write_b128 v4, a[32:35] offset:9216
	s_waitcnt vmcnt(5)
	ds_write_b128 v5, a[52:55] offset:10240
	s_waitcnt vmcnt(4)
	ds_write_b128 v6, a[40:43] offset:11264
	s_waitcnt vmcnt(3)
	ds_write_b128 v7, a[56:59] offset:12288
	s_waitcnt vmcnt(2)
	ds_write_b128 v8, a[44:47] offset:13312
	s_waitcnt vmcnt(1)
	ds_write_b128 v9, a[60:63] offset:14336
	s_waitcnt vmcnt(0)
	ds_write_b128 v2, a[48:51] offset:15360
	v_lshlrev_b32_e32 v2, 3, v0
	v_accvgpr_write_b32 a175, v2
	s_waitcnt lgkmcnt(0)
	; wave barrier
	s_cbranch_scc1 .LBB0_2
; %bb.1:                                ; %.._crit_edge_crit_edge
	s_lshl_b32 s92, s33, 8
	s_mov_b64 s[6:7], 0
	s_branch .LBB0_3
.LBB0_2:
	s_mov_b64 s[6:7], -1
                                        ; implicit-def: $sgpr92
.LBB0_3:                                ; %Flow1294
	s_load_dword s90, s[0:1], 0x48
	v_accvgpr_write_b32 a176, v10
	v_lshrrev_b32_e32 v232, 2, v10
	v_lshrrev_b32_e32 v182, 4, v0
	v_lshlrev_b32_e32 v165, 4, v166
	s_andn2_b64 vcc, exec, s[6:7]
	v_mov_b32_e32 v175, 0
	v_mov_b32_e32 v174, 0
	v_mov_b32_e32 v51, 0
	v_mov_b32_e32 v50, 0
	v_mov_b32_e32 v53, 0
	v_mov_b32_e32 v52, 0
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
	v_mov_b32_e32 v75, 0
	v_mov_b32_e32 v74, 0
	v_mov_b32_e32 v77, 0
	v_mov_b32_e32 v76, 0
	v_mov_b32_e32 v79, 0
	v_mov_b32_e32 v78, 0
	v_mov_b32_e32 v81, 0
	v_mov_b32_e32 v80, 0
	v_mov_b32_e32 v83, 0
	v_mov_b32_e32 v82, 0
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
	v_mov_b32_e32 v105, 0
	v_mov_b32_e32 v104, 0
	v_accvgpr_write_b32 a159, 0
	v_accvgpr_write_b32 a158, 0
	v_accvgpr_write_b32 a161, 0
	v_accvgpr_write_b32 a160, 0
	v_accvgpr_write_b32 a163, 0
	v_accvgpr_write_b32 a162, 0
	v_accvgpr_write_b32 a165, 0
	v_accvgpr_write_b32 a164, 0
	v_accvgpr_write_b32 a167, 0
	v_accvgpr_write_b32 a166, 0
	v_accvgpr_write_b32 a169, 0
	v_accvgpr_write_b32 a168, 0
	v_accvgpr_write_b32 a171, 0
	v_accvgpr_write_b32 a170, 0
	v_accvgpr_write_b32 a173, 0
	v_accvgpr_write_b32 a172, 0
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
	v_mov_b32_e32 v236, 0xff800000
	v_mov_b32_e32 v237, 0xff800000
	s_cbranch_vccnz .LBB0_9
; %bb.4:                                ; %.lr.ph
	v_accvgpr_read_b32 v68, a176
	v_mul_u32_u24_e32 v2, 0x220, v166
	v_lshlrev_b32_e32 v3, 1, v68
	v_xor_b32_e32 v2, v2, v3
	v_xor_b32_e32 v3, 0x180, v2
	v_add_u32_e32 v3, 0, v3
	ds_read_b128 v[32:35], v3 offset:8208
	ds_read_b128 v[36:39], v3 offset:8192
	ds_read_b128 v[14:17], v3
	ds_read_b128 v[18:21], v3 offset:16
	v_xor_b32_e32 v3, 0x100, v2
	v_add_u32_e32 v3, 0, v3
	ds_read_b128 v[28:31], v3 offset:8208
	ds_read_b128 v[40:43], v3 offset:8192
	ds_read_b128 v[10:13], v3
	ds_read_b128 v[22:25], v3 offset:16
	v_xor_b32_e32 v3, 0x80, v2
	v_add_u32_e32 v3, 0, v3
	v_add_u32_e32 v26, 0, v2
	ds_read_b128 v[44:47], v3 offset:8208
	ds_read_b128 v[48:51], v3 offset:8192
	ds_read_b128 v[6:9], v3
	ds_read_b128 v[52:55], v3 offset:16
	ds_read_b128 v[56:59], v26 offset:8208
	ds_read_b128 v[60:63], v26 offset:8192
	ds_read_b128 v[2:5], v26
	ds_read_b128 v[64:67], v26 offset:16
	v_lshlrev_b32_e32 v26, 6, v0
	v_and_b32_e32 v26, 0xc0, v26
	v_lshlrev_b32_e32 v27, 1, v0
	v_and_b32_e32 v162, 56, v27
	v_add_u32_e32 v26, 0, v26
	v_accvgpr_read_b32 v27, a129
	v_lshl_add_u32 v163, v27, 3, v26
	s_waitcnt lgkmcnt(0)
	v_cvt_scalef32_pk_fp8_bf16 v27, v42, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v32, v32, 1.0
	v_lshlrev_b32_e32 v1, 2, v1
	v_cvt_scalef32_pk_fp8_bf16 v10, v10, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v27, v43, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v32, v33, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v33, v34, 1.0
	v_lshlrev_b32_e32 v34, 4, v0
	v_accvgpr_read_b32 v43, a174
	v_cvt_scalef32_pk_fp8_bf16 v10, v11, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v11, v12, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v12, v22, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v28, v28, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v33, v35, 1.0 op_sel:[0,0,1]
	v_xor_b32_e32 v35, v34, v68
	v_xor_b32_e32 v34, v34, v43
	v_add_u32_e32 v173, 0, v1
	v_add_u32_e32 v1, v163, v162
	s_load_dwordx2 s[84:85], s[0:1], 0x40
	v_cvt_scalef32_pk_fp8_bf16 v12, v23, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v23, v50, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v28, v29, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v29, v30, 1.0
	v_xor_b32_e32 v43, 8, v34
	v_accvgpr_write_b32 a134, v1
	v_add_u32_e32 v1, 0, v34
	v_cvt_scalef32_pk_fp8_bf16 v11, v13, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v13, v24, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v14, v14, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v23, v51, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v24, v44, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v29, v31, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v31, v38, 1.0
	v_xor_b32_e32 v44, 32, v34
	v_lshlrev_b32_e32 v50, 2, v0
	v_accvgpr_read_b32 v51, a175
	v_accvgpr_write_b32 a135, v1
	v_add_u32_e32 v1, 0, v43
	s_lshl_b32 s92, s33, 8
	v_cvt_scalef32_pk_fp8_bf16 v2, v2, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v6, v6, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v14, v15, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v15, v16, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v22, v48, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v24, v45, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v31, v39, 1.0 op_sel:[0,0,1]
	v_mul_u32_u24_e32 v39, 0x110, v166
	v_xor_b32_e32 v45, 40, v34
	v_lshl_or_b32 v50, v0, 7, v50
	v_and_b32_e32 v51, 8, v51
	s_movk_i32 s0, 0x1f78
	v_accvgpr_write_b32 a136, v1
	v_add_u32_e32 v1, 0, v44
	v_accvgpr_write_b32 a132, v165
	v_or_b32_e32 v183, s92, v165
	v_cvt_scalef32_pk_fp8_bf16 v2, v3, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v3, v4, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v6, v7, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v7, v8, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v13, v25, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v15, v17, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v16, v18, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v17, v20, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v22, v49, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v25, v46, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v26, v40, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v30, v36, 1.0
	v_xor_b32_e32 v39, v39, v68
	v_xor_b32_e32 v49, 0x68, v34
	v_bitop3_b32 v165, v50, v51, s0 bitop3:0x6c
	v_accvgpr_write_b32 a137, v1
	v_add_u32_e32 v1, 0, v45
	v_lshlrev_b32_e32 v164, 2, v68
	v_cvt_scalef32_pk_fp8_bf16 v3, v5, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v4, v64, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v5, v66, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v7, v9, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v8, v52, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v9, v54, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v16, v19, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v17, v21, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v18, v60, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v19, v62, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v20, v56, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v21, v58, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v25, v47, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v26, v41, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v30, v37, 1.0 op_sel:[0,0,1]
	v_xor_b32_e32 v36, 64, v35
	v_xor_b32_e32 v37, 0x80, v35
	v_xor_b32_e32 v38, 0xc0, v35
	v_accvgpr_write_b32 a128, v166
	v_xor_b32_e32 v40, 64, v39
	v_xor_b32_e32 v41, 0x80, v39
	v_xor_b32_e32 v42, 0xc0, v39
	v_xor_b32_e32 v46, 64, v34
	v_xor_b32_e32 v47, 0x48, v34
	v_xor_b32_e32 v48, 0x60, v34
	v_xor_b32_e32 v166, 16, v165
	v_xor_b32_e32 v167, 32, v165
	v_xor_b32_e32 v168, 48, v165
	v_xor_b32_e32 v169, 64, v165
	v_xor_b32_e32 v170, 0x50, v165
	v_xor_b32_e32 v171, 0x60, v165
	v_xor_b32_e32 v172, 0x70, v165
	v_accvgpr_write_b32 a138, v1
	v_add_u32_e32 v1, 0, v49
	v_cmp_lt_i64_e32 vcc, 0, v[230:231]
	v_cmp_lt_i64_e64 s[6:7], 1, v[230:231]
	v_cmp_lt_i64_e64 s[10:11], 2, v[230:231]
	v_cmp_lt_i64_e64 s[16:17], 3, v[230:231]
	v_cmp_lt_i64_e64 s[18:19], 4, v[230:231]
	v_cmp_lt_i64_e64 s[20:21], 5, v[230:231]
	v_cmp_lt_i64_e64 s[22:23], 6, v[230:231]
	v_cmp_lt_i64_e64 s[24:25], 7, v[230:231]
	v_cmp_lt_i64_e64 s[26:27], 8, v[230:231]
	v_cmp_lt_i64_e64 s[28:29], 9, v[230:231]
	v_cmp_lt_i64_e64 s[30:31], 10, v[230:231]
	v_cmp_lt_i64_e64 s[34:35], 11, v[230:231]
	v_cmp_lt_i64_e64 s[36:37], 12, v[230:231]
	v_cmp_lt_i64_e64 s[38:39], 13, v[230:231]
	v_cmp_lt_i64_e64 s[40:41], 14, v[230:231]
	v_cmp_lt_i64_e64 s[42:43], 15, v[230:231]
	s_mov_b32 s94, 0
	s_waitcnt lgkmcnt(0)
	s_and_b32 s85, s85, 0xffff
	s_mov_b32 s87, 0x27000
	s_mov_b32 s86, 0x7ffffffe
	s_and_b32 s81, s81, 0xffff
	v_cvt_scalef32_pk_fp8_bf16 v4, v65, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v5, v67, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v8, v53, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v9, v55, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v18, v61, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v19, v63, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v20, v57, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v21, v59, 1.0 op_sel:[0,0,1]
	s_and_b32 s13, s13, 0xffff
	v_add_lshl_u32 v187, s14, v0, 3
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
	v_accvgpr_write_b32 a172, 0
	v_accvgpr_write_b32 a173, 0
	v_accvgpr_write_b32 a170, 0
	v_accvgpr_write_b32 a171, 0
	v_accvgpr_write_b32 a168, 0
	v_accvgpr_write_b32 a169, 0
	v_accvgpr_write_b32 a166, 0
	v_accvgpr_write_b32 a167, 0
	v_accvgpr_write_b32 a164, 0
	v_accvgpr_write_b32 a165, 0
	v_accvgpr_write_b32 a162, 0
	v_accvgpr_write_b32 a163, 0
	v_accvgpr_write_b32 a160, 0
	v_accvgpr_write_b32 a161, 0
	v_accvgpr_write_b32 a158, 0
	v_accvgpr_write_b32 a159, 0
	v_mov_b32_e32 v104, 0
	v_mov_b32_e32 v105, 0
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
	v_mov_b32_e32 v82, 0
	v_mov_b32_e32 v83, 0
	v_mov_b32_e32 v80, 0
	v_mov_b32_e32 v81, 0
	v_mov_b32_e32 v78, 0
	v_mov_b32_e32 v79, 0
	v_mov_b32_e32 v76, 0
	v_mov_b32_e32 v77, 0
	v_mov_b32_e32 v74, 0
	v_mov_b32_e32 v75, 0
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
	v_mov_b32_e32 v52, 0
	v_mov_b32_e32 v53, 0
	v_mov_b32_e32 v50, 0
	v_mov_b32_e32 v51, 0
	v_mov_b32_e32 v174, 0
	v_mov_b32_e32 v175, 0
	v_add_u32_e32 v191, 0, v164
	v_add_u32_e32 v192, 0, v35
	v_add_u32_e32 v193, 0, v36
	v_add_u32_e32 v194, 0, v37
	v_add_u32_e32 v195, 0, v38
	v_add_u32_e32 v196, 0, v39
	v_add_u32_e32 v197, 0, v40
	v_add_u32_e32 v198, 0, v41
	v_add_u32_e32 v199, 0, v42
	s_mov_b32 s33, 0xff800000
	s_mov_b32 s95, 0xc2fc0000
	v_add_u32_e32 v184, 0, v46
	v_add_u32_e32 v189, 0, v47
	v_add_u32_e32 v190, 0, v48
	v_accvgpr_write_b32 a139, v1
	v_add_u32_e32 v208, 0, v165
	v_add_u32_e32 v209, 0, v166
	v_add_u32_e32 v210, 0, v167
	v_add_u32_e32 v211, 0, v168
	v_add_u32_e32 v212, 0, v169
	v_add_u32_e32 v213, 0, v170
	v_add_u32_e32 v214, 0, v171
	v_add_u32_e32 v215, 0, v172
	v_mov_b32_e32 v216, 0
	v_bfrev_b32_e32 v217, 1
	v_mov_b32_e32 v219, 0x42800000
	v_not_b32_e32 v220, 63
	v_mov_b32_e32 v237, 0xff800000
	v_mov_b32_e32 v236, 0xff800000
	s_branch .LBB0_6
.LBB0_5:                                ;   in Loop: Header=BB0_6 Depth=1
	s_or_b64 exec, exec, s[78:79]
	s_add_i32 s94, s94, 64
	s_cmp_lt_i32 s94, s93
	v_add_u32_e32 v187, 0x200, v187
	s_cbranch_scc0 .LBB0_8
.LBB0_6:                                ; =>This Inner Loop Header: Depth=1
	v_add_u32_e32 v1, s94, v0
	v_cmp_gt_i32_e64 s[0:1], s93, v1
	s_and_b64 s[14:15], vcc, s[0:1]
	v_cndmask_b32_e64 v1, 0, 1, s[14:15]
	s_and_b64 s[14:15], s[6:7], s[0:1]
	v_cndmask_b32_e64 v34, 0, 1, s[14:15]
.Ltmp2:
	v_max_i32_dpp v1, v1, v1 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp3:
	s_and_b64 s[14:15], s[10:11], s[0:1]
	v_cndmask_b32_e64 v35, 0, 1, s[14:15]
.Ltmp4:
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp5:
	s_and_b64 s[14:15], s[16:17], s[0:1]
	v_cndmask_b32_e64 v36, 0, 1, s[14:15]
.Ltmp6:
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp7:
	s_and_b64 s[14:15], s[18:19], s[0:1]
	v_cndmask_b32_e64 v37, 0, 1, s[14:15]
.Ltmp8:
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp9:
	v_mov_b32_e32 v49, v1
.Ltmp10:
	s_and_b64 s[14:15], s[20:21], s[0:1]
	v_cndmask_b32_e64 v38, 0, 1, s[14:15]
.Ltmp11:
	v_mov_b32_dpp v49, v49 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp12:
	v_max_i32_e32 v1, v1, v49
.Ltmp13:
	s_and_b64 s[14:15], s[22:23], s[0:1]
	v_cndmask_b32_e64 v39, 0, 1, s[14:15]
.Ltmp14:
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp15:
	s_and_b64 s[14:15], s[24:25], s[0:1]
.Ltmp16:
	v_readlane_b32 s48, v1, 63
.Ltmp17:
	v_max_i32_dpp v1, v34, v34 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp18:
	v_cndmask_b32_e64 v40, 0, 1, s[14:15]
	s_and_b64 s[14:15], s[26:27], s[0:1]
.Ltmp19:
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp20:
	v_cndmask_b32_e64 v41, 0, 1, s[14:15]
	s_and_b64 s[14:15], s[28:29], s[0:1]
.Ltmp21:
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp22:
	v_cndmask_b32_e64 v42, 0, 1, s[14:15]
	s_and_b64 s[14:15], s[30:31], s[0:1]
.Ltmp23:
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp24:
	v_mov_b32_e32 v34, v1
.Ltmp25:
	v_cndmask_b32_e64 v43, 0, 1, s[14:15]
	s_and_b64 s[14:15], s[34:35], s[0:1]
.Ltmp26:
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp27:
	v_max_i32_e32 v1, v1, v34
.Ltmp28:
	v_cndmask_b32_e64 v44, 0, 1, s[14:15]
	s_and_b64 s[14:15], s[36:37], s[0:1]
.Ltmp29:
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp30:
	v_cndmask_b32_e64 v45, 0, 1, s[14:15]
.Ltmp31:
	v_readlane_b32 s49, v1, 63
.Ltmp32:
	v_max_i32_dpp v1, v35, v35 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp33:
	s_and_b64 s[14:15], s[38:39], s[0:1]
	v_cndmask_b32_e64 v46, 0, 1, s[14:15]
.Ltmp34:
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp35:
	s_and_b64 s[14:15], s[40:41], s[0:1]
	v_cndmask_b32_e64 v47, 0, 1, s[14:15]
.Ltmp36:
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp37:
	s_and_b64 s[14:15], s[42:43], s[0:1]
	v_cndmask_b32_e64 v48, 0, 1, s[14:15]
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
	v_readlane_b32 s50, v1, 63
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
	v_readlane_b32 s51, v1, 63
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
	v_readlane_b32 s52, v1, 63
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
	v_readlane_b32 s53, v1, 63
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
	v_readlane_b32 s54, v1, 63
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
	v_readlane_b32 s55, v1, 63
.Ltmp64:
	v_max_i32_dpp v1, v41, v41 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp65:
	v_mov_b64_e32 v[38:39], s[52:53]
	v_mov_b64_e32 v[40:41], s[54:55]
.Ltmp66:
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp67:
	ds_write_b128 v216, v[38:41] offset:16
.Ltmp68:
	s_nop 0
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
	v_readlane_b32 s56, v1, 63
.Ltmp72:
	v_max_i32_dpp v1, v42, v42 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
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
	v_readlane_b32 s57, v1, 63
.Ltmp76:
	v_max_i32_dpp v1, v43, v43 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
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
	v_readlane_b32 s58, v1, 63
.Ltmp80:
	v_max_i32_dpp v1, v44, v44 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
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
	v_readlane_b32 s59, v1, 63
.Ltmp84:
	v_max_i32_dpp v1, v45, v45 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp85:
	v_mov_b64_e32 v[42:43], s[56:57]
	v_mov_b64_e32 v[44:45], s[58:59]
.Ltmp86:
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp87:
	ds_write_b128 v216, v[42:45] offset:32
.Ltmp88:
	s_nop 0
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
	v_readlane_b32 s60, v1, 63
.Ltmp92:
	v_max_i32_dpp v1, v46, v46 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
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
	v_readlane_b32 s61, v1, 63
.Ltmp96:
	v_max_i32_dpp v1, v47, v47 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
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
	v_readlane_b32 s62, v1, 63
.Ltmp100:
	v_max_i32_dpp v1, v48, v48 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
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
	v_mov_b64_e32 v[34:35], s[48:49]
	v_mov_b64_e32 v[36:37], s[50:51]
.Ltmp104:
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp105:
	ds_write_b128 v216, v[34:37]
.Ltmp106:
	v_readlane_b32 s63, v1, 63
.Ltmp107:
	v_mov_b64_e32 v[46:47], s[60:61]
	s_nop 0
	v_mov_b64_e32 v[48:49], s[62:63]
	ds_write_b128 v216, v[46:49] offset:48
	ds_write_b128 v216, v[34:37] offset:64
	ds_write_b128 v216, v[38:41] offset:80
	ds_write_b128 v216, v[42:45] offset:96
	ds_write_b128 v216, v[46:49] offset:112
	; wave barrier
	ds_read_b32 v1, v173
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
	v_cmp_ne_u32_e64 s[14:15], 0, v1
	s_and_saveexec_b64 s[78:79], s[14:15]
	s_cbranch_execz .LBB0_5
; %bb.7:                                ;   in Loop: Header=BB0_6 Depth=1
	v_cndmask_b32_e64 v49, v217, v187, s[0:1]
	buffer_load_dwordx2 v[200:201], v49, s[84:87], 0 offen
	v_accvgpr_read_b32 v49, a134
	s_waitcnt lgkmcnt(0)
	; wave barrier
	v_accvgpr_write_b32 a130, v174
	v_accvgpr_write_b32 a133, v173
	v_accvgpr_write_b32 a131, v175
	v_add_u32_e32 v1, s94, v182
	v_add_u32_e32 v48, 4, v1
	v_cmp_gt_i32_e64 s[0:1], s93, v1
	v_add_u32_e32 v34, 60, v1
	v_add_u32_e32 v35, 56, v1
	v_add_u32_e32 v36, 52, v1
	v_add_u32_e32 v37, 48, v1
	v_add_u32_e32 v38, 44, v1
	v_add_u32_e32 v39, 40, v1
	v_add_u32_e32 v40, 36, v1
	v_add_u32_e32 v41, 32, v1
	v_add_u32_e32 v42, 28, v1
	v_add_u32_e32 v43, 24, v1
	v_add_u32_e32 v44, 20, v1
	v_add_u32_e32 v45, 16, v1
	v_add_u32_e32 v46, 12, v1
	v_add_u32_e32 v47, 8, v1
	v_cmp_gt_i32_e64 s[46:47], s93, v48
	v_cmp_gt_i32_e64 s[48:49], s93, v47
	v_cmp_gt_i32_e64 s[50:51], s93, v46
	v_cmp_gt_i32_e64 s[52:53], s93, v45
	v_cmp_gt_i32_e64 s[54:55], s93, v44
	v_cmp_gt_i32_e64 s[56:57], s93, v43
	v_cmp_gt_i32_e64 s[58:59], s93, v42
	v_cmp_gt_i32_e64 s[60:61], s93, v41
	v_cmp_gt_i32_e64 s[62:63], s93, v40
	v_cmp_gt_i32_e64 s[64:65], s93, v39
	v_cmp_gt_i32_e64 s[66:67], s93, v38
	v_cmp_gt_i32_e64 s[68:69], s93, v37
	v_cmp_gt_i32_e64 s[70:71], s93, v36
	v_cmp_gt_i32_e64 s[72:73], s93, v35
	s_mov_b32 s82, s86
	s_mov_b32 s83, s87
	v_cmp_gt_i32_e64 s[74:75], s93, v34
	s_mov_b32 s14, s86
	s_mov_b32 s15, s87
	v_accvgpr_read_b32 v185, a136
	v_accvgpr_read_b32 v186, a137
	v_accvgpr_read_b32 v218, a138
	s_waitcnt vmcnt(0)
	ds_write_b64 v49, v[200:201]
	; wave barrier
	ds_read_b128 v[222:225], v191
	ds_read_b128 v[238:241], v191 offset:16
	ds_read_b128 v[242:245], v191 offset:32
	ds_read_b128 v[178:181], v191 offset:48
	ds_read_b128 v[170:173], v191 offset:272
	ds_read_b128 v[166:169], v191 offset:288
	ds_read_b128 v[162:165], v191 offset:304
	ds_read_b128 v[174:177], v191 offset:256
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_write_b64 v49, v[200:201]
	; wave barrier
	v_lshl_add_u32 v49, v222, 10, v183
	v_lshl_add_u32 v163, v224, 10, v183
	ds_read_b128 v[222:225], v191
	v_lshl_add_u32 v165, v238, 10, v183
	v_lshl_add_u32 v167, v240, 10, v183
	ds_read_b128 v[238:241], v191 offset:16
	v_lshl_add_u32 v169, v242, 10, v183
	s_waitcnt lgkmcnt(1)
	v_lshl_add_u32 v173, v222, 10, v183
	v_cndmask_b32_e64 v1, v217, v173, s[0:1]
	v_lshl_add_u32 v173, v224, 10, v183
	ds_read_b128 v[222:225], v191 offset:32
	v_cndmask_b32_e64 v48, v217, v173, s[46:47]
	s_waitcnt lgkmcnt(1)
	v_lshl_add_u32 v173, v238, 10, v183
	v_cndmask_b32_e64 v47, v217, v173, s[48:49]
	v_lshl_add_u32 v173, v240, 10, v183
	ds_read_b128 v[238:241], v191 offset:48
	v_cndmask_b32_e64 v46, v217, v173, s[50:51]
	s_waitcnt lgkmcnt(1)
	v_lshl_add_u32 v173, v222, 10, v183
	v_cndmask_b32_e64 v45, v217, v173, s[52:53]
	v_lshl_add_u32 v173, v224, 10, v183
	ds_read_b128 v[222:225], v191 offset:256
	v_cndmask_b32_e64 v44, v217, v173, s[54:55]
	s_waitcnt lgkmcnt(1)
	v_lshl_add_u32 v173, v238, 10, v183
	v_cndmask_b32_e64 v43, v217, v173, s[56:57]
	v_lshl_add_u32 v173, v240, 10, v183
	ds_read_b128 v[238:241], v191 offset:272
	v_cndmask_b32_e64 v42, v217, v173, s[58:59]
	s_waitcnt lgkmcnt(1)
	v_lshl_add_u32 v173, v222, 10, v183
	v_cndmask_b32_e64 v41, v217, v173, s[60:61]
	v_lshl_add_u32 v173, v224, 10, v183
	ds_read_b128 v[222:225], v191 offset:288
	v_cndmask_b32_e64 v40, v217, v173, s[62:63]
	s_waitcnt lgkmcnt(1)
	v_lshl_add_u32 v173, v238, 10, v183
	v_cndmask_b32_e64 v39, v217, v173, s[64:65]
	v_lshl_add_u32 v173, v240, 10, v183
	ds_read_b128 v[238:241], v191 offset:304
	v_cndmask_b32_e64 v38, v217, v173, s[66:67]
	s_waitcnt lgkmcnt(1)
	v_lshl_add_u32 v173, v222, 10, v183
	v_cndmask_b32_e64 v37, v217, v173, s[68:69]
	v_lshl_add_u32 v173, v224, 10, v183
	v_cndmask_b32_e64 v36, v217, v173, s[70:71]
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u32 v173, v238, 10, v183
	v_cndmask_b32_e64 v35, v217, v173, s[72:73]
	v_lshl_add_u32 v173, v240, 10, v183
	v_lshl_add_u32 v171, v244, 10, v183
	v_cndmask_b32_e64 v34, v217, v173, s[74:75]
	buffer_load_dwordx4 v[200:203], v1, s[80:83], 0 offen
	buffer_load_dwordx4 v[204:207], v48, s[80:83], 0 offen
	buffer_load_dwordx4 v[222:225], v47, s[80:83], 0 offen
	buffer_load_dwordx4 v[226:229], v46, s[80:83], 0 offen
	buffer_load_dwordx4 v[238:241], v45, s[80:83], 0 offen
	buffer_load_dwordx4 v[242:245], v44, s[80:83], 0 offen
	buffer_load_dwordx4 v[246:249], v43, s[80:83], 0 offen
	buffer_load_dwordx4 v[250:253], v42, s[80:83], 0 offen
	buffer_load_dwordx4 a[64:67], v41, s[80:83], 0 offen
	buffer_load_dwordx4 a[68:71], v40, s[80:83], 0 offen
	buffer_load_dwordx4 a[72:75], v39, s[80:83], 0 offen
	buffer_load_dwordx4 a[76:79], v38, s[80:83], 0 offen
	buffer_load_dwordx4 a[80:83], v37, s[80:83], 0 offen
	buffer_load_dwordx4 a[84:87], v36, s[80:83], 0 offen
	buffer_load_dwordx4 a[88:91], v35, s[80:83], 0 offen
	buffer_load_dwordx4 a[92:95], v34, s[80:83], 0 offen
	s_waitcnt lgkmcnt(0)
	; wave barrier
	v_lshl_add_u32 v41, v162, 10, v183
	v_lshl_add_u32 v42, v164, 10, v183
	v_cndmask_b32_e64 v44, v217, v163, s[46:47]
	v_cndmask_b32_e64 v45, v217, v165, s[48:49]
	v_lshl_add_u32 v1, v178, 10, v183
	v_lshl_add_u32 v34, v180, 10, v183
	v_cndmask_b32_e64 v43, v217, v49, s[0:1]
	v_lshl_add_u32 v35, v174, 10, v183
	v_lshl_add_u32 v36, v176, 10, v183
	v_lshl_add_u32 v37, v170, 10, v183
	v_lshl_add_u32 v38, v172, 10, v183
	v_cndmask_b32_e64 v46, v217, v167, s[50:51]
	v_cndmask_b32_e64 v47, v217, v169, s[52:53]
	v_cndmask_b32_e64 v48, v217, v171, s[54:55]
	v_cndmask_b32_e64 v1, v217, v1, s[56:57]
	v_cndmask_b32_e64 v34, v217, v34, s[58:59]
	v_lshl_add_u32 v39, v166, 10, v183
	v_lshl_add_u32 v40, v168, 10, v183
	v_cndmask_b32_e64 v35, v217, v35, s[60:61]
	v_cndmask_b32_e64 v36, v217, v36, s[62:63]
	v_cndmask_b32_e64 v37, v217, v37, s[64:65]
	v_cndmask_b32_e64 v38, v217, v38, s[66:67]
	v_cndmask_b32_e64 v39, v217, v39, s[68:69]
	v_cndmask_b32_e64 v49, v217, v40, s[70:71]
	v_cndmask_b32_e64 v166, v217, v41, s[72:73]
	v_cndmask_b32_e64 v167, v217, v42, s[74:75]
	s_waitcnt vmcnt(15)
	ds_write_b128 v192, v[200:203]
	s_waitcnt vmcnt(14)
	ds_write_b128 v193, v[204:207] offset:1024
	s_waitcnt vmcnt(13)
	ds_write_b128 v194, v[222:225] offset:2048
	s_waitcnt vmcnt(12)
	ds_write_b128 v195, v[226:229] offset:3072
	s_waitcnt vmcnt(11)
	ds_write_b128 v192, v[238:241] offset:4096
	s_waitcnt vmcnt(10)
	ds_write_b128 v193, v[242:245] offset:5120
	s_waitcnt vmcnt(9)
	ds_write_b128 v194, v[246:249] offset:6144
	s_waitcnt vmcnt(8)
	ds_write_b128 v195, v[250:253] offset:7168
	s_waitcnt vmcnt(7)
	ds_write_b128 v192, a[64:67] offset:8192
	s_waitcnt vmcnt(6)
	ds_write_b128 v193, a[68:71] offset:9216
	s_waitcnt vmcnt(5)
	ds_write_b128 v194, a[72:75] offset:10240
	s_waitcnt vmcnt(4)
	ds_write_b128 v195, a[76:79] offset:11264
	s_waitcnt vmcnt(3)
	ds_write_b128 v192, a[80:83] offset:12288
	s_waitcnt vmcnt(2)
	ds_write_b128 v193, a[84:87] offset:13312
	s_waitcnt vmcnt(1)
	ds_write_b128 v194, a[88:91] offset:14336
	s_waitcnt vmcnt(0)
	ds_write_b128 v195, a[92:95] offset:15360
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
	buffer_load_dwordx4 v[178:181], v43, s[12:15], 0 offen
	buffer_load_dwordx4 v[222:225], v44, s[12:15], 0 offen
	buffer_load_dwordx4 v[238:241], v45, s[12:15], 0 offen
	buffer_load_dwordx4 v[170:173], v46, s[12:15], 0 offen
	buffer_load_dwordx4 v[242:245], v47, s[12:15], 0 offen
	buffer_load_dwordx4 v[246:249], v48, s[12:15], 0 offen
	buffer_load_dwordx4 v[250:253], v1, s[12:15], 0 offen
	buffer_load_dwordx4 v[174:177], v34, s[12:15], 0 offen
	v_accvgpr_read_b32 v1, a135
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x128_f8f6f4 v[226:229], a[96:103], v[10:17], v[162:165]
	buffer_load_dwordx4 v[200:203], v35, s[12:15], 0 offen
	buffer_load_dwordx4 v[204:207], v36, s[12:15], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[34:37], v37, s[12:15], 0 offen
	s_nop 2
	buffer_load_dwordx4 v[162:165], v38, s[12:15], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[38:41], v39, s[12:15], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[42:45], v49, s[12:15], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[46:49], v166, s[12:15], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[166:169], v167, s[12:15], 0 offen
	s_waitcnt vmcnt(11) lgkmcnt(0)
	; wave barrier
	ds_write2st64_b64 v1, v[178:179], v[242:243] offset1:8
	ds_write2st64_b64 v185, v[180:181], v[244:245] offset1:8
	v_mfma_f32_16x16x128_f8f6f4 v[178:181], a[72:79], v[2:9], 0
	s_waitcnt vmcnt(10)
	ds_write2st64_b64 v186, v[222:223], v[246:247] offset0:2 offset1:10
	ds_write2st64_b64 v218, v[224:225], v[248:249] offset0:2 offset1:10
	s_waitcnt vmcnt(9)
	ds_write2st64_b64 v184, v[238:239], v[250:251] offset0:4 offset1:12
	ds_write2st64_b64 v189, v[240:241], v[252:253] offset0:4 offset1:12
	s_waitcnt vmcnt(3)
	ds_write2st64_b64 v1, v[200:201], v[38:39] offset0:16 offset1:24
	ds_write2st64_b64 v185, v[202:203], v[40:41] offset0:16 offset1:24
	s_waitcnt vmcnt(2)
	ds_write2st64_b64 v186, v[204:205], v[42:43] offset0:18 offset1:26
	ds_write2st64_b64 v218, v[206:207], v[44:45] offset0:18 offset1:26
	s_waitcnt vmcnt(1)
	ds_write2st64_b64 v184, v[34:35], v[46:47] offset0:20 offset1:28
	v_mfma_f32_16x16x128_f8f6f4 v[38:41], a[104:111], v[10:17], v[178:181]
	ds_write2st64_b64 v189, v[36:37], v[48:49] offset0:20 offset1:28
	v_add_u32_e32 v1, s94, v232
	v_add_u32_e32 v185, 51, v1
	v_add_u32_e32 v186, 50, v1
	v_cmp_gt_i32_e64 s[0:1], s93, v185
	v_add_u32_e32 v185, 49, v1
	v_cmp_gt_i32_e64 s[14:15], s93, v186
	v_mfma_f32_16x16x128_f8f6f4 v[178:181], a[80:87], v[18:25], 0
	v_add_u32_e32 v186, 48, v1
	v_cmp_gt_i32_e64 s[46:47], s93, v185
	v_add_u32_e32 v185, 35, v1
	v_cmp_gt_i32_e64 s[48:49], s93, v186
	v_add_u32_e32 v186, 34, v1
	v_cmp_gt_i32_e64 s[50:51], s93, v185
	v_add_u32_e32 v185, 33, v1
	v_mfma_f32_16x16x128_f8f6f4 v[34:37], a[80:87], v[2:9], 0
	v_cmp_gt_i32_e64 s[52:53], s93, v186
	v_add_u32_e32 v186, 32, v1
	v_cmp_gt_i32_e64 s[54:55], s93, v185
	v_add_u32_e32 v185, 19, v1
	v_cmp_gt_i32_e64 s[56:57], s93, v186
	v_add_u32_e32 v186, 18, v1
	v_cmp_gt_i32_e64 s[58:59], s93, v185
	v_mfma_f32_16x16x128_f8f6f4 v[204:207], a[88:95], v[2:9], 0
	v_add_u32_e32 v185, 17, v1
	v_cmp_gt_i32_e64 s[60:61], s93, v186
	v_add_u32_e32 v186, 16, v1
	v_cmp_gt_i32_e64 s[62:63], s93, v185
	v_add_u32_e32 v185, 3, v1
	v_cmp_gt_i32_e64 s[64:65], s93, v186
	v_add_u32_e32 v186, 2, v1
	v_mfma_f32_16x16x128_f8f6f4 v[42:45], a[64:71], v[18:25], 0
	v_cmp_gt_i32_e64 s[66:67], s93, v1
	v_add_u32_e32 v1, 1, v1
	v_cmp_gt_i32_e64 s[72:73], s93, v1
	v_cmp_gt_i32_e64 s[68:69], s93, v185
	v_cmp_gt_i32_e64 s[70:71], s93, v186
	v_mul_f32_e32 v1, s90, v226
	v_mul_f32_e32 v185, s90, v227
	v_mfma_f32_16x16x128_f8f6f4 v[46:49], a[72:79], v[18:25], 0
	s_and_b64 s[66:67], s[44:45], s[66:67]
	s_and_b64 s[72:73], s[44:45], s[72:73]
	v_mul_f32_e32 v186, s90, v228
	v_mul_f32_e32 v218, s90, v229
	v_cndmask_b32_e64 v1, v188, v1, s[66:67]
	v_cndmask_b32_e64 v185, v188, v185, s[72:73]
	s_and_b64 s[70:71], s[44:45], s[70:71]
	v_mfma_f32_16x16x128_f8f6f4 v[178:181], a[112:119], v[26:33], v[178:181]
	s_and_b64 s[68:69], s[44:45], s[68:69]
	s_and_b64 s[56:57], s[44:45], s[56:57]
	v_mul_f32_e32 v38, s90, v38
	v_mul_f32_e32 v39, s90, v39
	v_cndmask_b32_e64 v186, v188, v186, s[70:71]
	v_cndmask_b32_e64 v218, v188, v218, s[68:69]
	s_and_b64 s[64:65], s[44:45], s[64:65]
	v_mfma_f32_16x16x128_f8f6f4 v[34:37], a[112:119], v[10:17], v[34:37]
	s_and_b64 s[62:63], s[44:45], s[62:63]
	v_mul_f32_e32 v40, s90, v40
	v_mul_f32_e32 v41, s90, v41
	v_cndmask_b32_e64 v38, v188, v38, s[64:65]
	v_mul_f32_e32 v178, s90, v178
	v_cndmask_b32_e64 v221, v188, v178, s[56:57]
.Ltmp118:
	v_max_f32_e32 v178, v1, v185
.Ltmp119:
	v_mfma_f32_16x16x128_f8f6f4 v[200:203], a[88:95], v[18:25], 0
	v_cndmask_b32_e64 v39, v188, v39, s[62:63]
	s_and_b64 s[60:61], s[44:45], s[60:61]
	s_and_b64 s[58:59], s[44:45], s[58:59]
.Ltmp120:
	v_max3_f32 v178, v178, v186, v218
.Ltmp121:
	v_mul_f32_e32 v34, s90, v34
	v_mul_f32_e32 v35, s90, v35
	v_cndmask_b32_e64 v40, v188, v40, s[60:61]
	v_mfma_f32_16x16x128_f8f6f4 v[204:207], a[120:127], v[10:17], v[204:207]
	v_cndmask_b32_e64 v41, v188, v41, s[58:59]
	s_and_b64 s[54:55], s[44:45], s[54:55]
.Ltmp122:
	v_max3_f32 v178, v178, v38, v39
.Ltmp123:
	v_mul_f32_e32 v36, s90, v36
	v_mul_f32_e32 v37, s90, v37
	v_cndmask_b32_e64 v34, v188, v34, s[56:57]
	v_cndmask_b32_e64 v35, v188, v35, s[54:55]
	v_mfma_f32_16x16x128_f8f6f4 v[42:45], a[96:103], v[26:33], v[42:45]
	s_and_b64 s[52:53], s[44:45], s[52:53]
	s_and_b64 s[50:51], s[44:45], s[50:51]
.Ltmp124:
	v_max3_f32 v178, v178, v40, v41
.Ltmp125:
	v_cndmask_b32_e64 v36, v188, v36, s[52:53]
	v_mul_f32_e32 v204, s90, v204
	v_mul_f32_e32 v205, s90, v205
	v_cndmask_b32_e64 v37, v188, v37, s[50:51]
	v_mfma_f32_16x16x128_f8f6f4 v[46:49], a[104:111], v[26:33], v[46:49]
	s_and_b64 s[48:49], s[44:45], s[48:49]
	s_and_b64 s[46:47], s[44:45], s[46:47]
.Ltmp126:
	v_max3_f32 v178, v178, v34, v35
.Ltmp127:
	v_mul_f32_e32 v206, s90, v206
	v_mul_f32_e32 v207, s90, v207
	v_mul_f32_e32 v42, s90, v42
	v_mul_f32_e32 v43, s90, v43
	v_mfma_f32_16x16x128_f8f6f4 v[200:203], a[120:127], v[26:33], v[200:203]
	v_cndmask_b32_e64 v204, v188, v204, s[48:49]
	v_cndmask_b32_e64 v205, v188, v205, s[46:47]
	s_and_b64 s[14:15], s[44:45], s[14:15]
	s_and_b64 s[0:1], s[44:45], s[0:1]
.Ltmp128:
	v_max3_f32 v178, v178, v36, v37
.Ltmp129:
	v_mul_f32_e32 v44, s90, v44
	v_mul_f32_e32 v45, s90, v45
	v_mul_f32_e32 v179, s90, v179
	v_cndmask_b32_e64 v206, v188, v206, s[14:15]
	v_cndmask_b32_e64 v207, v188, v207, s[0:1]
	v_cndmask_b32_e64 v42, v188, v42, s[66:67]
	v_cndmask_b32_e64 v43, v188, v43, s[72:73]
.Ltmp130:
	v_max3_f32 v178, v178, v204, v205
.Ltmp131:
	v_mul_f32_e32 v46, s90, v46
	v_mul_f32_e32 v47, s90, v47
	v_mul_f32_e32 v180, s90, v180
	v_cndmask_b32_e64 v44, v188, v44, s[70:71]
	v_cndmask_b32_e64 v45, v188, v45, s[68:69]
	v_cndmask_b32_e64 v222, v188, v179, s[54:55]
.Ltmp132:
	v_max3_f32 v178, v178, v206, v207
	v_max_f32_e32 v179, v42, v43
.Ltmp133:
	v_mul_f32_e32 v48, s90, v48
	v_mul_f32_e32 v49, s90, v49
	v_cndmask_b32_e64 v46, v188, v46, s[64:65]
	v_cndmask_b32_e64 v47, v188, v47, s[62:63]
	v_cndmask_b32_e64 v223, v188, v180, s[52:53]
.Ltmp134:
	v_max3_f32 v179, v179, v44, v45
.Ltmp135:
	v_mov_b32_e32 v180, v178
.Ltmp136:
	v_cndmask_b32_e64 v48, v188, v48, s[60:61]
	v_cndmask_b32_e64 v49, v188, v49, s[58:59]
.Ltmp137:
	v_max3_f32 v179, v179, v46, v47
.Ltmp138:
	v_permlane32_swap_b32_e32 v178, v180
.Ltmp139:
	v_mul_f32_e32 v181, s90, v181
.Ltmp140:
	v_max3_f32 v179, v179, v48, v49
	v_max_f32_e32 v180, v180, v180
	v_max_f32_e32 v178, v178, v178
.Ltmp141:
	v_mul_f32_e32 v200, s90, v200
	v_mul_f32_e32 v201, s90, v201
	v_cndmask_b32_e64 v224, v188, v181, s[50:51]
.Ltmp142:
	v_max3_f32 v179, v179, v221, v222
	v_max_f32_e32 v178, v178, v180
.Ltmp143:
	v_mul_f32_e32 v202, s90, v202
	v_mul_f32_e32 v203, s90, v203
	v_cndmask_b32_e64 v200, v188, v200, s[48:49]
	v_cndmask_b32_e64 v201, v188, v201, s[46:47]
.Ltmp144:
	v_max3_f32 v179, v179, v223, v224
.Ltmp145:
	v_mov_b32_e32 v180, v178
.Ltmp146:
	v_cndmask_b32_e64 v202, v188, v202, s[14:15]
	v_cndmask_b32_e64 v203, v188, v203, s[0:1]
.Ltmp147:
	v_max3_f32 v179, v179, v200, v201
.Ltmp148:
	v_permlane16_swap_b32_e32 v178, v180
.Ltmp149:
	v_max3_f32 v179, v179, v202, v203
	v_max_f32_e32 v180, v180, v180
	v_max_f32_e32 v178, v178, v178
	v_max_f32_e32 v178, v178, v180
.Ltmp150:
	v_mov_b32_e32 v180, v179
	s_nop 1
	v_permlane32_swap_b32_e32 v179, v180
.Ltmp151:
	v_max_f32_e32 v180, v180, v180
	v_max_f32_e32 v179, v179, v179
	v_max_f32_e32 v179, v179, v180
.Ltmp152:
	v_mov_b32_e32 v180, v179
	s_nop 1
	v_permlane16_swap_b32_e32 v179, v180
.Ltmp153:
	v_max_f32_e32 v180, v180, v180
	v_max_f32_e32 v179, v179, v179
	v_max_f32_e32 v179, v179, v180
.Ltmp154:
	v_cmp_neq_f32_e64 s[0:1], s33, v178
	v_mov_b32_e32 v180, 0xe0ad78ec
	ds_write2st64_b64 v190, v[170:171], v[174:175] offset0:6 offset1:14
	v_cndmask_b32_e64 v178, v180, v178, s[0:1]
	v_cmp_neq_f32_e64 s[0:1], s33, v179
	s_nop 1
	v_cndmask_b32_e64 v179, v180, v179, s[0:1]
	v_max_f32_e32 v180, v237, v237
	v_max_f32_e32 v180, v178, v180
	v_max_f32_e32 v178, v236, v236
	v_max_f32_e32 v181, v179, v178
	v_sub_f32_e32 v178, v237, v180
	v_mul_f32_e32 v225, 0x3fb8aa3b, v178
	v_cmp_gt_f32_e64 s[0:1], s95, v225
	v_sub_f32_e32 v179, v236, v181
	v_sub_f32_e32 v1, v1, v180
	v_cndmask_b32_e64 v225, 0, v219, s[0:1]
	v_fmac_f32_e32 v225, 0x3fb8aa3b, v178
	v_exp_f32_e32 v178, v225
	v_mul_f32_e32 v225, 0x3fb8aa3b, v179
	v_cmp_gt_f32_e64 s[14:15], s95, v225
	v_sub_f32_e32 v226, v186, v180
	v_sub_f32_e32 v186, v201, v181
	v_cndmask_b32_e64 v225, 0, v219, s[14:15]
	v_fmac_f32_e32 v225, 0x3fb8aa3b, v179
	v_exp_f32_e32 v179, v225
	v_cndmask_b32_e64 v225, 0, v220, s[0:1]
	v_ldexp_f32 v178, v178, v225
	v_cndmask_b32_e64 v225, 0, v220, s[14:15]
	v_ldexp_f32 v179, v179, v225
	v_sub_f32_e32 v225, v185, v180
	v_sub_f32_e32 v185, v200, v181
	v_mul_f32_e32 v200, 0x3fb8aa3b, v1
	v_cmp_gt_f32_e64 s[0:1], s95, v200
	v_sub_f32_e32 v229, v221, v181
	v_sub_f32_e32 v227, v202, v181
	v_cndmask_b32_e64 v200, 0, v219, s[0:1]
	v_fmac_f32_e32 v200, 0x3fb8aa3b, v1
	v_exp_f32_e32 v200, v200
	v_cndmask_b32_e64 v201, 0, v220, s[0:1]
	v_sub_f32_e32 v228, v218, v180
	v_sub_f32_e32 v234, v222, v181
	v_ldexp_f32 v221, v200, v201
	v_mul_f32_e32 v200, 0x3fb8aa3b, v225
	v_cmp_gt_f32_e64 s[0:1], s95, v200
	v_mul_f32_e32 v201, 0x3fb8aa3b, v226
	v_cmp_gt_f32_e64 s[14:15], s95, v201
	v_cndmask_b32_e64 v200, 0, v219, s[0:1]
	v_fmac_f32_e32 v200, 0x3fb8aa3b, v225
	v_cndmask_b32_e64 v201, 0, v219, s[14:15]
	v_exp_f32_e32 v200, v200
	v_fmac_f32_e32 v201, 0x3fb8aa3b, v226
	v_exp_f32_e32 v201, v201
	v_cndmask_b32_e64 v202, 0, v220, s[0:1]
	v_ldexp_f32 v222, v200, v202
	v_cndmask_b32_e64 v200, 0, v220, s[14:15]
	v_sub_f32_e32 v38, v38, v180
	v_sub_f32_e32 v254, v223, v181
	v_ldexp_f32 v223, v201, v200
	v_mul_f32_e32 v200, 0x3fb8aa3b, v228
	v_cmp_gt_f32_e64 s[0:1], s95, v200
	v_mul_f32_e32 v201, 0x3fb8aa3b, v38
	v_cmp_gt_f32_e64 s[14:15], s95, v201
	v_cndmask_b32_e64 v200, 0, v219, s[0:1]
	v_fmac_f32_e32 v200, 0x3fb8aa3b, v228
	v_cndmask_b32_e64 v201, 0, v219, s[14:15]
	v_exp_f32_e32 v200, v200
	v_fmac_f32_e32 v201, 0x3fb8aa3b, v38
	v_exp_f32_e32 v38, v201
	v_cndmask_b32_e64 v201, 0, v220, s[0:1]
	v_sub_f32_e32 v39, v39, v180
	v_sub_f32_e32 v218, v224, v181
	v_ldexp_f32 v224, v200, v201
	v_cndmask_b32_e64 v200, 0, v220, s[14:15]
	v_ldexp_f32 v225, v38, v200
	v_mul_f32_e32 v38, 0x3fb8aa3b, v39
	v_cmp_gt_f32_e64 s[0:1], s95, v38
	v_sub_f32_e32 v40, v40, v180
	v_sub_f32_e32 v41, v41, v180
	v_cndmask_b32_e64 v38, 0, v219, s[0:1]
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v39
	v_mul_f32_e32 v39, 0x3fb8aa3b, v40
	v_cmp_gt_f32_e64 s[14:15], s95, v39
	v_exp_f32_e32 v38, v38
	v_sub_f32_e32 v34, v34, v180
	v_cndmask_b32_e64 v39, 0, v219, s[14:15]
	v_fmac_f32_e32 v39, 0x3fb8aa3b, v40
	v_exp_f32_e32 v39, v39
	v_cndmask_b32_e64 v40, 0, v220, s[0:1]
	v_ldexp_f32 v233, v38, v40
	v_cndmask_b32_e64 v38, 0, v220, s[14:15]
	v_ldexp_f32 v235, v39, v38
	v_mul_f32_e32 v38, 0x3fb8aa3b, v41
	v_cmp_gt_f32_e64 s[0:1], s95, v38
	v_mul_f32_e32 v39, 0x3fb8aa3b, v34
	v_cmp_gt_f32_e64 s[14:15], s95, v39
	v_cndmask_b32_e64 v38, 0, v219, s[0:1]
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v41
	v_cndmask_b32_e64 v39, 0, v219, s[14:15]
	v_exp_f32_e32 v38, v38
	v_fmac_f32_e32 v39, 0x3fb8aa3b, v34
	v_exp_f32_e32 v34, v39
	v_cndmask_b32_e64 v39, 0, v220, s[0:1]
	v_sub_f32_e32 v35, v35, v180
	v_ldexp_f32 v236, v38, v39
	v_cndmask_b32_e64 v38, 0, v220, s[14:15]
	v_ldexp_f32 v237, v34, v38
	v_mul_f32_e32 v34, 0x3fb8aa3b, v35
	v_cmp_gt_f32_e64 s[0:1], s95, v34
	v_sub_f32_e32 v36, v36, v180
	v_sub_f32_e32 v37, v37, v180
	v_cndmask_b32_e64 v34, 0, v219, s[0:1]
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v35
	v_mul_f32_e32 v35, 0x3fb8aa3b, v36
	v_cmp_gt_f32_e64 s[14:15], s95, v35
	v_exp_f32_e32 v34, v34
	v_sub_f32_e32 v204, v204, v180
	v_cndmask_b32_e64 v35, 0, v219, s[14:15]
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v36
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e64 v36, 0, v220, s[0:1]
	v_ldexp_f32 v238, v34, v36
	v_cndmask_b32_e64 v34, 0, v220, s[14:15]
	v_ldexp_f32 v239, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v37
	v_cmp_gt_f32_e64 s[0:1], s95, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v204
	v_cmp_gt_f32_e64 s[14:15], s95, v35
	v_cndmask_b32_e64 v34, 0, v219, s[0:1]
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v37
	v_cndmask_b32_e64 v35, 0, v219, s[14:15]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v204
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e64 v36, 0, v220, s[0:1]
	v_sub_f32_e32 v205, v205, v180
	v_ldexp_f32 v240, v34, v36
	v_cndmask_b32_e64 v34, 0, v220, s[14:15]
	v_sub_f32_e32 v206, v206, v180
	v_ldexp_f32 v241, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v205
	v_cmp_gt_f32_e64 s[0:1], s95, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v206
	v_cmp_gt_f32_e64 s[14:15], s95, v35
	v_cndmask_b32_e64 v34, 0, v219, s[0:1]
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v205
	v_cndmask_b32_e64 v35, 0, v219, s[14:15]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v206
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e64 v36, 0, v220, s[0:1]
	v_sub_f32_e32 v207, v207, v180
	v_ldexp_f32 v242, v34, v36
	v_cndmask_b32_e64 v34, 0, v220, s[14:15]
	v_sub_f32_e32 v42, v42, v181
	v_ldexp_f32 v243, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v207
	v_cmp_gt_f32_e64 s[0:1], s95, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v42
	v_cmp_gt_f32_e64 s[14:15], s95, v35
	v_cndmask_b32_e64 v34, 0, v219, s[0:1]
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v207
	v_cndmask_b32_e64 v35, 0, v219, s[14:15]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v42
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e64 v36, 0, v220, s[0:1]
	v_sub_f32_e32 v43, v43, v181
	v_ldexp_f32 v244, v34, v36
	v_cndmask_b32_e64 v34, 0, v220, s[14:15]
	v_sub_f32_e32 v44, v44, v181
	v_ldexp_f32 v245, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v43
	v_cmp_gt_f32_e64 s[0:1], s95, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v44
	v_cmp_gt_f32_e64 s[14:15], s95, v35
	v_cndmask_b32_e64 v34, 0, v219, s[0:1]
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v43
	v_cndmask_b32_e64 v35, 0, v219, s[14:15]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v44
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e64 v36, 0, v220, s[0:1]
	v_sub_f32_e32 v45, v45, v181
	v_ldexp_f32 v246, v34, v36
	v_cndmask_b32_e64 v34, 0, v220, s[14:15]
	v_sub_f32_e32 v46, v46, v181
	v_ldexp_f32 v247, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v45
	v_cmp_gt_f32_e64 s[0:1], s95, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v46
	v_cmp_gt_f32_e64 s[14:15], s95, v35
	v_cndmask_b32_e64 v34, 0, v219, s[0:1]
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v45
	v_cndmask_b32_e64 v35, 0, v219, s[14:15]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v46
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e64 v36, 0, v220, s[0:1]
	v_sub_f32_e32 v47, v47, v181
	v_ldexp_f32 v249, v34, v36
	v_cndmask_b32_e64 v34, 0, v220, s[14:15]
	v_sub_f32_e32 v48, v48, v181
	v_ldexp_f32 v248, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v47
	v_cmp_gt_f32_e64 s[0:1], s95, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v48
	v_cmp_gt_f32_e64 s[14:15], s95, v35
	v_cndmask_b32_e64 v34, 0, v219, s[0:1]
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v47
	v_cndmask_b32_e64 v35, 0, v219, s[14:15]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v48
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e64 v36, 0, v220, s[0:1]
	v_sub_f32_e32 v49, v49, v181
	v_ldexp_f32 v250, v34, v36
	v_cndmask_b32_e64 v34, 0, v220, s[14:15]
	v_ldexp_f32 v251, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v49
	v_cmp_gt_f32_e64 s[0:1], s95, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v229
	v_cmp_gt_f32_e64 s[14:15], s95, v35
	v_cndmask_b32_e64 v34, 0, v219, s[0:1]
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v49
	v_cndmask_b32_e64 v35, 0, v219, s[14:15]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v229
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e64 v36, 0, v220, s[0:1]
	v_ldexp_f32 v253, v34, v36
	v_cndmask_b32_e64 v34, 0, v220, s[14:15]
	v_ldexp_f32 v252, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v234
	v_cmp_gt_f32_e64 s[0:1], s95, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v254
	v_cmp_gt_f32_e64 s[14:15], s95, v35
	v_cndmask_b32_e64 v34, 0, v219, s[0:1]
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v234
	v_cndmask_b32_e64 v35, 0, v219, s[14:15]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v254
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e64 v36, 0, v220, s[0:1]
	v_ldexp_f32 v254, v34, v36
	v_cndmask_b32_e64 v34, 0, v220, s[14:15]
	v_ldexp_f32 v255, v35, v34
	v_accvgpr_read_b32 v34, a139
	ds_write2st64_b64 v34, v[172:173], v[176:177] offset0:6 offset1:14
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v190, v[162:163], v[166:167] offset0:22 offset1:30
	ds_write2st64_b64 v34, v[164:165], v[168:169] offset0:22 offset1:30
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_read_b64_tr_b8 v[44:45], v208
	ds_read_b64_tr_b8 a[64:65], v211
	ds_read_b64_tr_b8 a[72:73], v212
	v_cvt_scalef32_pk_fp8_f32 v170, v221, v222, 1.0
	v_cvt_scalef32_pk_fp8_f32 v171, v225, v233, 1.0
	v_cvt_scalef32_pk_fp8_f32 v170, v223, v224, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v171, v235, v236, 1.0 op_sel:[0,0,0,1]
	v_pk_mul_f32 v[36:37], v[160:161], v[178:179] op_sel_hi:[1,0]
	s_nop 0
	v_permlane32_swap_b32_e32 v170, v171
	s_nop 1
	v_permlane16_swap_b32_e32 v170, v171
	v_pk_mul_f32 v[34:35], v[158:159], v[178:179] op_sel_hi:[1,0]
	v_sub_f32_e32 v1, v203, v181
	v_cvt_scalef32_pk_fp8_f32 v172, v237, v238, 1.0
	v_cvt_scalef32_pk_fp8_f32 v173, v241, v242, 1.0
	ds_read_b64_tr_b8 v[46:47], v208 offset:8192
	ds_read_b64_tr_b8 v[48:49], v208 offset:8320
	ds_read_b64_tr_b8 v[166:167], v208 offset:128
	ds_read_b64_tr_b8 v[168:169], v209
	ds_read_b64_tr_b8 v[202:203], v210
	s_waitcnt lgkmcnt(7)
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[44:45], v[170:171], v[34:37]
	v_cvt_scalef32_pk_fp8_f32 v172, v239, v240, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v173, v243, v244, 1.0 op_sel:[0,0,0,1]
	ds_read_b64_tr_b8 v[174:175], v209 offset:8192
	ds_read_b64_tr_b8 v[176:177], v209 offset:8320
	ds_read_b64_tr_b8 v[200:201], v209 offset:128
	v_permlane32_swap_b32_e32 v172, v173
	s_nop 1
	v_permlane16_swap_b32_e32 v172, v173
	ds_read_b64_tr_b8 v[204:205], v210 offset:8192
	ds_read_b64_tr_b8 v[206:207], v210 offset:8320
	ds_read_b64_tr_b8 v[228:229], v210 offset:128
	s_waitcnt lgkmcnt(10)
	v_mfma_f32_16x16x32_fp8_fp8 v[158:161], v[46:47], v[172:173], v[34:37]
	ds_read_b64_tr_b8 a[66:67], v211 offset:8192
	ds_read_b64_tr_b8 a[68:69], v211 offset:8320
	ds_read_b64_tr_b8 a[70:71], v211 offset:128
	v_pk_mul_f32 v[36:37], v[156:157], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[154:155], v[178:179] op_sel_hi:[1,0]
	ds_read_b64_tr_b8 a[80:81], v213
	ds_read_b64_tr_b8 a[88:89], v214
	ds_read_b64_tr_b8 a[96:97], v215
	s_waitcnt lgkmcnt(13)
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[168:169], v[170:171], v[34:37]
	ds_read_b64_tr_b8 a[74:75], v212 offset:8192
	ds_read_b64_tr_b8 a[76:77], v212 offset:8320
	ds_read_b64_tr_b8 a[78:79], v212 offset:128
	ds_read_b64_tr_b8 a[82:83], v213 offset:8192
	ds_read_b64_tr_b8 a[84:85], v213 offset:8320
	ds_read_b64_tr_b8 a[86:87], v213 offset:128
	ds_read_b64_tr_b8 a[90:91], v214 offset:8192
	ds_read_b64_tr_b8 a[92:93], v214 offset:8320
	ds_read_b64_tr_b8 a[94:95], v214 offset:128
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_fp8_fp8 v[154:157], v[174:175], v[172:173], v[34:37]
	ds_read_b64_tr_b8 a[98:99], v215 offset:8192
	ds_read_b64_tr_b8 a[100:101], v215 offset:8320
	ds_read_b64_tr_b8 a[102:103], v215 offset:128
	v_pk_mul_f32 v[36:37], v[152:153], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[150:151], v[178:179] op_sel_hi:[1,0]
	v_mul_f32_e32 v234, 0x3fb8aa3b, v218
	v_cmp_gt_f32_e64 s[0:1], s95, v234
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[202:203], v[170:171], v[34:37]
	v_mul_f32_e32 v41, 0x3fb8aa3b, v186
	v_cndmask_b32_e64 v38, 0, v219, s[0:1]
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v218
	v_mfma_f32_16x16x32_fp8_fp8 v[150:153], v[204:205], v[172:173], v[34:37]
	v_exp_f32_e32 v38, v38
	v_cndmask_b32_e64 v39, 0, v220, s[0:1]
	v_mul_f32_e32 v43, 0x3fb8aa3b, v1
	v_cvt_scalef32_pk_fp8_f32 v162, v245, v246, 1.0
	v_pk_mul_f32 v[36:37], v[148:149], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[146:147], v[178:179] op_sel_hi:[1,0]
	v_ldexp_f32 v39, v38, v39
	v_mul_f32_e32 v38, 0x3fb8aa3b, v185
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[64:65], v[170:171], v[34:37]
	v_cmp_gt_f32_e64 s[0:1], s95, v38
	v_cvt_scalef32_pk_fp8_f32 v163, v248, v250, 1.0
	v_cvt_scalef32_pk_fp8_f32 v162, v247, v249, 1.0 op_sel:[0,0,0,1]
	v_mfma_f32_16x16x32_fp8_fp8 v[146:149], a[66:67], v[172:173], v[34:37]
	v_cndmask_b32_e64 v38, 0, v219, s[0:1]
	v_cndmask_b32_e64 v40, 0, v220, s[0:1]
	v_cmp_gt_f32_e64 s[0:1], s95, v41
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v185
	v_pk_mul_f32 v[36:37], v[144:145], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[142:143], v[178:179] op_sel_hi:[1,0]
	v_cndmask_b32_e64 v41, 0, v219, s[0:1]
	v_exp_f32_e32 v38, v38
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[72:73], v[170:171], v[34:37]
	v_fmac_f32_e32 v41, 0x3fb8aa3b, v186
	v_exp_f32_e32 v41, v41
	v_ldexp_f32 v40, v38, v40
	s_waitcnt lgkmcnt(11)
	v_mfma_f32_16x16x32_fp8_fp8 v[142:145], a[74:75], v[172:173], v[34:37]
	v_cndmask_b32_e64 v38, 0, v220, s[0:1]
	v_ldexp_f32 v41, v41, v38
	v_mul_f32_e32 v38, 0x3fb8aa3b, v227
	v_cmp_gt_f32_e64 s[0:1], s95, v38
	v_pk_mul_f32 v[36:37], v[140:141], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[138:139], v[178:179] op_sel_hi:[1,0]
	v_cndmask_b32_e64 v38, 0, v219, s[0:1]
	v_cndmask_b32_e64 v42, 0, v220, s[0:1]
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[80:81], v[170:171], v[34:37]
	v_cmp_gt_f32_e64 s[0:1], s95, v43
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v227
	v_exp_f32_e32 v38, v38
	s_waitcnt lgkmcnt(8)
	v_mfma_f32_16x16x32_fp8_fp8 v[138:141], a[82:83], v[172:173], v[34:37]
	v_cndmask_b32_e64 v43, 0, v219, s[0:1]
	v_fmac_f32_e32 v43, 0x3fb8aa3b, v1
	v_exp_f32_e32 v1, v43
	v_ldexp_f32 v42, v38, v42
	v_pk_mul_f32 v[36:37], v[136:137], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[134:135], v[178:179] op_sel_hi:[1,0]
	v_cndmask_b32_e64 v38, 0, v220, s[0:1]
	v_cvt_scalef32_pk_fp8_f32 v163, v251, v253, 1.0 op_sel:[0,0,0,1]
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[88:89], v[170:171], v[34:37]
	v_ldexp_f32 v1, v1, v38
	v_permlane32_swap_b32_e32 v162, v163
	s_waitcnt lgkmcnt(5)
	v_mfma_f32_16x16x32_fp8_fp8 v[134:137], a[90:91], v[172:173], v[34:37]
	v_mov_b32_e32 v38, v179
	v_permlane16_swap_b32_e32 v162, v163
	v_cvt_scalef32_pk_fp8_f32 v164, v252, v254, 1.0
	s_nop 0
	v_pk_mul_f32 v[36:37], v[132:133], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[130:131], v[178:179] op_sel_hi:[1,0]
	v_cvt_scalef32_pk_fp8_f32 v165, v40, v41, 1.0
	v_cvt_scalef32_pk_fp8_f32 v164, v255, v39, 1.0 op_sel:[0,0,0,1]
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[96:97], v[170:171], v[34:37]
	v_cvt_scalef32_pk_fp8_f32 v165, v42, v1, 1.0 op_sel:[0,0,0,1]
.Ltmp155:
	v_add_f32_e32 v43, v221, v222
.Ltmp156:
	s_nop 0
	v_permlane32_swap_b32_e32 v164, v165
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_fp8_fp8 v[130:133], a[98:99], v[172:173], v[34:37]
	v_permlane16_swap_b32_e32 v164, v165
.Ltmp157:
	v_add_f32_e32 v43, v223, v43
.Ltmp158:
	s_nop 0
	v_pk_mul_f32 v[36:37], v[128:129], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[126:127], v[178:179] op_sel_hi:[1,0]
.Ltmp159:
	v_add_f32_e32 v43, v224, v43
	v_add_f32_e32 v43, v225, v43
.Ltmp160:
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[166:167], v[170:171], v[34:37]
.Ltmp161:
	v_add_f32_e32 v43, v233, v43
	v_add_f32_e32 v43, v235, v43
	v_add_f32_e32 v43, v236, v43
.Ltmp162:
	v_mfma_f32_16x16x32_fp8_fp8 v[126:129], v[48:49], v[172:173], v[34:37]
.Ltmp163:
	v_add_f32_e32 v43, v237, v43
	v_add_f32_e32 v43, v238, v43
	v_add_f32_e32 v43, v239, v43
	v_add_f32_e32 v43, v240, v43
.Ltmp164:
	v_pk_mul_f32 v[36:37], v[124:125], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[122:123], v[178:179] op_sel_hi:[1,0]
.Ltmp165:
	v_add_f32_e32 v43, v241, v43
	v_add_f32_e32 v43, v242, v43
.Ltmp166:
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[200:201], v[170:171], v[34:37]
.Ltmp167:
	v_add_f32_e32 v43, v243, v43
	v_add_f32_e32 v43, v244, v43
	v_mov_b32_e32 v237, v180
.Ltmp168:
	v_mfma_f32_16x16x32_fp8_fp8 v[122:125], v[176:177], v[172:173], v[34:37]
	v_mov_b32_e32 v236, v181
	s_nop 2
	v_pk_mul_f32 v[36:37], v[120:121], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[118:119], v[178:179] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[228:229], v[170:171], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[118:121], v[206:207], v[172:173], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v116, v178
	v_mul_f32_e64 v37, v117, v178
	v_pk_mul_f32 v[34:35], v[114:115], v[178:179] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[70:71], v[170:171], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[114:117], a[68:69], v[172:173], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v112, v178
	v_mul_f32_e64 v37, v113, v178
	v_pk_mul_f32 v[34:35], v[110:111], v[178:179] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[78:79], v[170:171], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[110:113], a[76:77], v[172:173], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v108, v178
	v_mul_f32_e64 v37, v109, v178
	v_pk_mul_f32 v[34:35], v[106:107], v[178:179] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[86:87], v[170:171], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[106:109], a[84:85], v[172:173], v[34:37]
	s_nop 6
	v_accvgpr_read_b32 v34, a170
	v_accvgpr_read_b32 v35, a171
	v_accvgpr_read_b32 v36, a172
	v_accvgpr_read_b32 v37, a173
	v_pk_mul_f32 v[36:37], v[36:37], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[34:35], v[178:179] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[94:95], v[170:171], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[92:93], v[172:173], v[34:37]
	s_nop 7
	v_accvgpr_write_b32 a173, v37
	v_accvgpr_write_b32 a172, v36
	v_accvgpr_write_b32 a171, v35
	v_accvgpr_write_b32 a170, v34
	v_accvgpr_read_b32 v34, a166
	v_accvgpr_read_b32 v35, a167
	v_accvgpr_read_b32 v36, a168
	v_accvgpr_read_b32 v37, a169
	v_pk_mul_f32 v[36:37], v[36:37], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[34:35], v[178:179] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(0)
	s_nop 0
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[102:103], v[170:171], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[100:101], v[172:173], v[34:37]
	v_accvgpr_read_b32 v173, a133
	s_nop 6
	v_accvgpr_write_b32 a169, v37
	v_accvgpr_write_b32 a168, v36
	v_accvgpr_write_b32 a167, v35
	v_accvgpr_write_b32 a166, v34
	v_accvgpr_read_b32 v34, a162
	v_accvgpr_read_b32 v35, a163
	v_accvgpr_read_b32 v36, a164
	v_accvgpr_read_b32 v37, a165
	v_pk_mul_f32 v[36:37], v[36:37], v[38:39] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[34:35], v[38:39] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[44:45], v[162:163], v[34:37]
.Ltmp169:
	v_add_f32_e32 v44, v245, v246
	v_add_f32_e32 v44, v247, v44
	v_add_f32_e32 v44, v249, v44
.Ltmp170:
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[46:47], v[164:165], v[34:37]
.Ltmp171:
	v_add_f32_e32 v44, v248, v44
	v_add_f32_e32 v44, v250, v44
	v_add_f32_e32 v44, v251, v44
	v_add_f32_e32 v44, v253, v44
	v_add_f32_e32 v44, v252, v44
	v_add_f32_e32 v44, v254, v44
	v_add_f32_e32 v44, v255, v44
	s_nop 0
	v_accvgpr_write_b32 a165, v37
	v_accvgpr_write_b32 a164, v36
	v_accvgpr_write_b32 a163, v35
	v_accvgpr_write_b32 a162, v34
	v_accvgpr_read_b32 v34, a158
	v_accvgpr_read_b32 v35, a159
	v_accvgpr_read_b32 v36, a160
	v_accvgpr_read_b32 v37, a161
.Ltmp172:
	v_pk_mul_f32 v[36:37], v[36:37], v[38:39] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[34:35], v[38:39] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[168:169], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[174:175], v[164:165], v[34:37]
	v_accvgpr_read_b32 v175, a131
	v_accvgpr_read_b32 v174, a130
	s_nop 5
	v_accvgpr_write_b32 a161, v37
	v_accvgpr_write_b32 a160, v36
	v_accvgpr_write_b32 a159, v35
	v_accvgpr_write_b32 a158, v34
	v_pk_mul_f32 v[36:37], v[104:105], v[38:39] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[102:103], v[38:39] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[202:203], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[102:105], v[204:205], v[164:165], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v100, v38
	v_mul_f32_e64 v37, v101, v38
	v_pk_mul_f32 v[34:35], v[98:99], v[38:39] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[64:65], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[98:101], a[66:67], v[164:165], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v96, v38
	v_mul_f32_e64 v37, v97, v38
	v_pk_mul_f32 v[34:35], v[94:95], v[38:39] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[72:73], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[94:97], a[74:75], v[164:165], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v92, v38
	v_mul_f32_e64 v37, v93, v38
	v_pk_mul_f32 v[34:35], v[90:91], v[38:39] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[80:81], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[90:93], a[82:83], v[164:165], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v88, v38
	v_mul_f32_e64 v37, v89, v38
	v_pk_mul_f32 v[34:35], v[86:87], v[38:39] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[88:89], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[86:89], a[90:91], v[164:165], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v84, v38
	v_mul_f32_e64 v37, v85, v38
	v_pk_mul_f32 v[34:35], v[82:83], v[38:39] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[96:97], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[82:85], a[98:99], v[164:165], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v80, v38
	v_mul_f32_e64 v37, v81, v38
	v_pk_mul_f32 v[34:35], v[78:79], v[38:39] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[166:167], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[78:81], v[48:49], v[164:165], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v76, v38
	v_mul_f32_e64 v37, v77, v38
	v_pk_mul_f32 v[34:35], v[74:75], v[38:39] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[200:201], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[74:77], v[176:177], v[164:165], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v72, v38
	v_mul_f32_e64 v37, v73, v38
	v_pk_mul_f32 v[34:35], v[70:71], v[38:39] op_sel_hi:[1,0]
.Ltmp173:
	v_add_f32_e32 v39, v39, v44
.Ltmp174:
	s_nop 0
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[228:229], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[70:73], v[206:207], v[164:165], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v68, v38
	v_mul_f32_e64 v37, v69, v38
	v_pk_mul_f32 v[34:35], v[66:67], v[38:39] op_sel_hi:[1,0]
.Ltmp175:
	v_add_f32_e32 v39, v40, v39
	v_add_f32_e32 v39, v41, v39
.Ltmp176:
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[70:71], v[162:163], v[34:37]
.Ltmp177:
	v_add_f32_e32 v39, v42, v39
	v_add_f32_e32 v1, v1, v39
.Ltmp178:
	v_mfma_f32_16x16x32_fp8_fp8 v[66:69], a[68:69], v[164:165], v[34:37]
	s_nop 4
	v_mul_f32_e64 v36, v64, v38
	v_mul_f32_e64 v37, v65, v38
	v_pk_mul_f32 v[34:35], v[62:63], v[38:39] op_sel_hi:[1,0]
.Ltmp179:
	v_mov_b32_e32 v39, v43
	s_nop 1
	v_permlane32_swap_b32_e32 v43, v39
.Ltmp180:
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[78:79], v[162:163], v[34:37]
.Ltmp181:
	v_add_f32_e32 v40, v43, v39
.Ltmp182:
	v_mov_b32_e32 v42, v40
	s_nop 1
	v_permlane16_swap_b32_e32 v40, v42
.Ltmp183:
	v_mfma_f32_16x16x32_fp8_fp8 v[62:65], a[76:77], v[164:165], v[34:37]
	s_nop 2
	v_mul_f32_e64 v36, v60, v38
	v_mul_f32_e64 v37, v61, v38
	v_pk_mul_f32 v[34:35], v[58:59], v[38:39] op_sel_hi:[1,0]
.Ltmp184:
	v_mov_b32_e32 v39, v1
.Ltmp185:
	s_nop 0
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[86:87], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[58:61], a[84:85], v[164:165], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v56, v38
	v_mul_f32_e64 v37, v57, v38
	v_pk_mul_f32 v[34:35], v[54:55], v[38:39] op_sel_hi:[1,0]
.Ltmp186:
	v_permlane32_swap_b32_e32 v1, v39
.Ltmp187:
	s_nop 0
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[94:95], v[162:163], v[34:37]
.Ltmp188:
	v_add_f32_e32 v41, v1, v39
.Ltmp189:
	v_mov_b32_e32 v43, v41
	s_nop 1
	v_permlane16_swap_b32_e32 v41, v43
.Ltmp190:
	v_mfma_f32_16x16x32_fp8_fp8 v[54:57], a[92:93], v[164:165], v[34:37]
	s_nop 2
	v_mul_f32_e64 v36, v52, v38
	v_mul_f32_e64 v37, v53, v38
	v_pk_mul_f32 v[34:35], v[50:51], v[38:39] op_sel_hi:[1,0]
.Ltmp191:
	v_pk_add_f32 v[38:39], v[40:41], v[42:43]
.Ltmp192:
	s_nop 0
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[102:103], v[162:163], v[34:37]
	v_fma_f32 v174, v174, v178, v38
	v_fma_f32 v175, v175, v179, v39
	v_mfma_f32_16x16x32_fp8_fp8 v[50:53], a[100:101], v[164:165], v[34:37]
	s_branch .LBB0_5
.LBB0_8:                                ; %Flow
	v_accvgpr_read_b32 v166, a128
	v_accvgpr_read_b32 v165, a132
.LBB0_9:                                ; %._crit_edge
	v_or_b32_e32 v32, 8, v165
	v_mov_b32_e32 v233, 0
	s_lshl_b32 s33, s91, 10
	v_lshlrev_b32_e32 v33, 10, v182
	v_or_b32_e32 v2, 4, v182
	v_mov_b32_e32 v183, v233
	s_add_i32 s33, s33, s92
	v_or_b32_e32 v49, v33, v165
	v_or_b32_e32 v33, v33, v32
	v_lshlrev_b32_e32 v34, 10, v2
	v_add_lshl_u32 v49, v49, s33, 1
	v_bfrev_b32_e32 v235, 1
	v_cmp_gt_i64_e64 s[34:35], v[230:231], v[182:183]
	v_add_lshl_u32 v33, v33, s33, 1
	v_or_b32_e32 v4, 8, v182
	v_mov_b32_e32 v3, v233
	v_or_b32_e32 v162, v34, v165
	s_and_b32 s5, s5, 0xffff
	s_mov_b32 s7, 0x27000
	s_mov_b32 s6, 0x7ffffffe
	v_cndmask_b32_e64 v49, v235, v49, s[34:35]
	v_cndmask_b32_e64 v33, v235, v33, s[34:35]
	v_lshlrev_b32_e32 v35, 10, v4
	v_or_b32_e32 v34, v34, v32
	buffer_load_dwordx4 v[178:181], v49, s[4:7], 0 offen
	buffer_load_dwordx4 v[184:187], v33, s[4:7], 0 offen
	v_add_lshl_u32 v33, v162, s33, 1
	v_cmp_gt_i64_e32 vcc, v[230:231], v[2:3]
	v_or_b32_e32 v6, 12, v182
	v_mov_b32_e32 v5, v233
	v_or_b32_e32 v163, v35, v165
	v_cndmask_b32_e32 v3, v235, v33, vcc
	v_add_lshl_u32 v33, v34, s33, 1
	v_lshlrev_b32_e32 v36, 10, v6
	v_or_b32_e32 v35, v35, v32
	v_cndmask_b32_e32 v33, v235, v33, vcc
	buffer_load_dwordx4 v[188:191], v3, s[4:7], 0 offen
	buffer_load_dwordx4 v[192:195], v33, s[4:7], 0 offen
	v_add_lshl_u32 v3, v163, s33, 1
	v_cmp_gt_i64_e64 s[0:1], v[230:231], v[4:5]
	v_accvgpr_write_b32 a117, v69
	v_or_b32_e32 v8, 16, v182
	v_mov_b32_e32 v7, v233
	v_or_b32_e32 v164, v36, v165
	v_cndmask_b32_e64 v3, v235, v3, s[0:1]
	v_add_lshl_u32 v5, v35, s33, 1
	v_accvgpr_write_b32 a116, v68
	v_accvgpr_write_b32 a115, v67
	v_accvgpr_write_b32 a114, v66
	v_lshlrev_b32_e32 v37, 10, v8
	v_or_b32_e32 v36, v36, v32
	v_mov_b32_e32 v66, v165
	v_cndmask_b32_e64 v5, v235, v5, s[0:1]
	buffer_load_dwordx4 v[196:199], v3, s[4:7], 0 offen
	buffer_load_dwordx4 v[200:203], v5, s[4:7], 0 offen
	v_add_lshl_u32 v3, v164, s33, 1
	v_cmp_gt_i64_e64 s[10:11], v[230:231], v[6:7]
	v_or_b32_e32 v10, 20, v182
	v_mov_b32_e32 v9, v233
	v_or_b32_e32 v165, v37, v66
	v_cndmask_b32_e64 v3, v235, v3, s[10:11]
	v_add_lshl_u32 v5, v36, s33, 1
	v_lshlrev_b32_e32 v38, 10, v10
	v_or_b32_e32 v37, v37, v32
	v_cndmask_b32_e64 v5, v235, v5, s[10:11]
	buffer_load_dwordx4 v[204:207], v3, s[4:7], 0 offen
	buffer_load_dwordx4 v[208:211], v5, s[4:7], 0 offen
	v_add_lshl_u32 v3, v165, s33, 1
	v_cmp_gt_i64_e64 s[36:37], v[230:231], v[8:9]
	v_or_b32_e32 v12, 24, v182
	v_lshlrev_b32_e32 v1, 9, v166
	v_mov_b32_e32 v11, v233
	v_mov_b32_e32 v68, v166
	v_or_b32_e32 v166, v38, v66
	v_cndmask_b32_e64 v3, v235, v3, s[36:37]
	v_add_lshl_u32 v5, v37, s33, 1
	v_lshlrev_b32_e32 v39, 10, v12
	v_or_b32_e32 v38, v38, v32
	v_cndmask_b32_e64 v5, v235, v5, s[36:37]
	buffer_load_dwordx4 v[34:37], v3, s[4:7], 0 offen
	buffer_load_dwordx4 v[162:165], v5, s[4:7], 0 offen
	v_add_lshl_u32 v3, v166, s33, 1
	v_cmp_gt_i64_e64 s[12:13], v[230:231], v[10:11]
	v_or_b32_e32 v14, 28, v182
	v_mov_b32_e32 v13, v233
	v_or_b32_e32 v167, v39, v66
	v_cndmask_b32_e64 v3, v235, v3, s[12:13]
	v_add_lshl_u32 v5, v38, s33, 1
	v_lshlrev_b32_e32 v40, 10, v14
	v_or_b32_e32 v39, v39, v32
	v_cndmask_b32_e64 v5, v235, v5, s[12:13]
	buffer_load_dwordx4 v[212:215], v3, s[4:7], 0 offen
	buffer_load_dwordx4 v[216:219], v5, s[4:7], 0 offen
	v_add_lshl_u32 v3, v167, s33, 1
	v_cmp_gt_i64_e64 s[14:15], v[230:231], v[12:13]
	v_or_b32_e32 v16, 32, v182
	v_mov_b32_e32 v15, v233
	v_or_b32_e32 v168, v40, v66
	v_cndmask_b32_e64 v3, v235, v3, s[14:15]
	v_add_lshl_u32 v5, v39, s33, 1
	v_lshlrev_b32_e32 v41, 10, v16
	v_or_b32_e32 v40, v40, v32
	v_cndmask_b32_e64 v5, v235, v5, s[14:15]
	buffer_load_dwordx4 v[220:223], v3, s[4:7], 0 offen
	buffer_load_dwordx4 v[224:227], v5, s[4:7], 0 offen
	v_add_lshl_u32 v3, v168, s33, 1
	v_cmp_gt_i64_e64 s[16:17], v[230:231], v[14:15]
	v_or_b32_e32 v18, 36, v182
	v_mov_b32_e32 v17, v233
	v_or_b32_e32 v169, v41, v66
	v_cndmask_b32_e64 v3, v235, v3, s[16:17]
	v_add_lshl_u32 v5, v40, s33, 1
	v_lshlrev_b32_e32 v42, 10, v18
	v_or_b32_e32 v41, v41, v32
	v_cndmask_b32_e64 v5, v235, v5, s[16:17]
	buffer_load_dwordx4 v[238:241], v3, s[4:7], 0 offen
	buffer_load_dwordx4 v[242:245], v5, s[4:7], 0 offen
	v_add_lshl_u32 v3, v169, s33, 1
	v_cmp_gt_i64_e64 s[30:31], v[230:231], v[16:17]
	v_or_b32_e32 v20, 40, v182
	v_mov_b32_e32 v19, v233
	v_or_b32_e32 v170, v42, v66
	v_cndmask_b32_e64 v3, v235, v3, s[30:31]
	v_add_lshl_u32 v5, v41, s33, 1
	v_lshlrev_b32_e32 v43, 10, v20
	v_or_b32_e32 v42, v42, v32
	v_cndmask_b32_e64 v5, v235, v5, s[30:31]
	buffer_load_dwordx4 v[38:41], v3, s[4:7], 0 offen
	buffer_load_dwordx4 v[166:169], v5, s[4:7], 0 offen
	v_add_lshl_u32 v3, v170, s33, 1
	v_cmp_gt_i64_e64 s[18:19], v[230:231], v[18:19]
	v_or_b32_e32 v22, 44, v182
	v_mov_b32_e32 v21, v233
	v_or_b32_e32 v171, v43, v66
	v_cndmask_b32_e64 v3, v235, v3, s[18:19]
	v_add_lshl_u32 v5, v42, s33, 1
	v_lshlrev_b32_e32 v44, 10, v22
	v_or_b32_e32 v43, v43, v32
	v_cndmask_b32_e64 v5, v235, v5, s[18:19]
	buffer_load_dwordx4 v[246:249], v3, s[4:7], 0 offen
	buffer_load_dwordx4 a[64:67], v5, s[4:7], 0 offen
	v_add_lshl_u32 v3, v171, s33, 1
	v_cmp_gt_i64_e64 s[20:21], v[230:231], v[20:21]
	v_or_b32_e32 v24, 48, v182
	v_mov_b32_e32 v23, v233
	v_or_b32_e32 v172, v44, v66
	v_cndmask_b32_e64 v3, v235, v3, s[20:21]
	v_add_lshl_u32 v5, v43, s33, 1
	v_lshlrev_b32_e32 v45, 10, v24
	v_or_b32_e32 v44, v44, v32
	v_cndmask_b32_e64 v5, v235, v5, s[20:21]
	buffer_load_dwordx4 a[68:71], v3, s[4:7], 0 offen
	buffer_load_dwordx4 a[72:75], v5, s[4:7], 0 offen
	v_add_lshl_u32 v3, v172, s33, 1
	v_cmp_gt_i64_e64 s[22:23], v[230:231], v[22:23]
	v_or_b32_e32 v26, 52, v182
	v_mov_b32_e32 v25, v233
	v_or_b32_e32 v173, v45, v66
	v_cndmask_b32_e64 v3, v235, v3, s[22:23]
	v_add_lshl_u32 v5, v44, s33, 1
	v_accvgpr_write_b32 a112, v174
	v_lshlrev_b32_e32 v46, 10, v26
	v_or_b32_e32 v45, v45, v32
	v_cndmask_b32_e64 v5, v235, v5, s[22:23]
	buffer_load_dwordx4 a[76:79], v3, s[4:7], 0 offen
	buffer_load_dwordx4 a[92:95], v5, s[4:7], 0 offen
	v_add_lshl_u32 v3, v173, s33, 1
	v_cmp_gt_i64_e64 s[38:39], v[230:231], v[24:25]
	v_accvgpr_write_b32 a113, v175
	v_mov_b32_e32 v27, v233
	v_or_b32_e32 v174, v46, v66
	v_cndmask_b32_e64 v3, v235, v3, s[38:39]
	v_add_lshl_u32 v5, v45, s33, 1
	v_or_b32_e32 v46, v46, v32
	v_cndmask_b32_e64 v5, v235, v5, s[38:39]
	buffer_load_dwordx4 v[42:45], v3, s[4:7], 0 offen
	buffer_load_dwordx4 v[170:173], v5, s[4:7], 0 offen
	v_add_lshl_u32 v3, v174, s33, 1
	v_cmp_gt_i64_e64 s[24:25], v[230:231], v[26:27]
	v_or_b32_e32 v28, 56, v182
	v_add_lshl_u32 v5, v46, s33, 1
	v_cndmask_b32_e64 v3, v235, v3, s[24:25]
	v_lshlrev_b32_e32 v47, 10, v28
	v_cndmask_b32_e64 v5, v235, v5, s[24:25]
	buffer_load_dwordx4 a[96:99], v3, s[4:7], 0 offen
	buffer_load_dwordx4 a[100:103], v5, s[4:7], 0 offen
	v_mov_b32_e32 v29, v233
	v_or_b32_e32 v175, v47, v66
	v_or_b32_e32 v30, 60, v182
	v_or_b32_e32 v47, v47, v32
	v_add_lshl_u32 v3, v175, s33, 1
	v_cmp_gt_i64_e64 s[26:27], v[230:231], v[28:29]
	v_lshlrev_b32_e32 v48, 10, v30
	v_add_lshl_u32 v5, v47, s33, 1
	v_cndmask_b32_e64 v3, v235, v3, s[26:27]
	v_mov_b32_e32 v31, v233
	v_or_b32_e32 v176, v48, v66
	v_cndmask_b32_e64 v5, v235, v5, s[26:27]
	buffer_load_dwordx4 a[104:107], v3, s[4:7], 0 offen
	buffer_load_dwordx4 a[108:111], v5, s[4:7], 0 offen
	v_or_b32_e32 v48, v48, v32
	v_add_lshl_u32 v3, v176, s33, 1
	v_cmp_gt_i64_e64 s[28:29], v[230:231], v[30:31]
	v_add_lshl_u32 v5, v48, s33, 1
	v_accvgpr_read_b32 v11, a176
	v_cndmask_b32_e64 v3, v235, v3, s[28:29]
	v_cndmask_b32_e64 v5, v235, v5, s[28:29]
	buffer_load_dwordx4 v[46:49], v3, s[4:7], 0 offen
	buffer_load_dwordx4 v[174:177], v5, s[4:7], 0 offen
	v_mov_b32_e32 v3, 0x210
	v_cndmask_b32_e64 v3, v3, 0, s[2:3]
	v_accvgpr_read_b32 v5, a177
	v_xor_b32_e32 v3, v3, v5
	v_add_u32_e32 v5, 0, v3
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_write_b128 v5, a[28:31]
	ds_write_b128 v5, a[36:39] offset:8192
	v_xad_u32 v5, v3, 32, 0
	ds_write_b128 v5, a[20:23] offset:1024
	ds_write_b128 v5, a[32:35] offset:9216
	v_xad_u32 v5, v3, 64, 0
	ds_write_b128 v5, a[8:11] offset:2048
	ds_write_b128 v5, a[52:55] offset:10240
	v_xor_b32_e32 v5, 0x60, v3
	v_add_u32_e32 v5, 0, v5
	ds_write_b128 v5, a[0:3] offset:3072
	ds_write_b128 v5, a[40:43] offset:11264
	v_xor_b32_e32 v5, 0x80, v3
	v_add_u32_e32 v5, 0, v5
	ds_write_b128 v5, a[12:15] offset:4096
	ds_write_b128 v5, a[56:59] offset:12288
	v_xor_b32_e32 v5, 0xa0, v3
	v_add_u32_e32 v5, 0, v5
	ds_write_b128 v5, a[4:7] offset:5120
	ds_write_b128 v5, a[44:47] offset:13312
	v_xor_b32_e32 v5, 0xc0, v3
	v_xor_b32_e32 v3, 0xe0, v3
	v_add_u32_e32 v5, 0, v5
	v_add_u32_e32 v3, 0, v3
	v_bitop3_b32 v1, v1, v11, v66 bitop3:0x36
	ds_write_b128 v5, a[24:27] offset:6144
	ds_write_b128 v5, a[60:63] offset:14336
	ds_write_b128 v3, a[16:19] offset:7168
	ds_write_b128 v3, a[48:51] offset:15360
	v_add_u32_e32 v3, 0, v1
	v_xad_u32 v5, v1, 64, 0
	v_xor_b32_e32 v7, 0x80, v1
	v_xor_b32_e32 v1, 0xc0, v1
	v_add_u32_e32 v9, 0, v1
	v_lshlrev_b32_e32 v1, 5, v0
	v_xor_b32_e32 v11, v1, v11
	v_add_u32_e32 v7, 0, v7
	v_add_u32_e32 v13, 0, v11
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_read_b128 a[12:15], v3
	ds_read_b128 a[4:7], v3 offset:256
	ds_read_b128 a[0:3], v3 offset:8192
	ds_read_b128 a[80:83], v3 offset:8448
	ds_read_b128 a[28:31], v5
	ds_read_b128 a[20:23], v5 offset:256
	ds_read_b128 a[8:11], v5 offset:8192
	ds_read_b128 a[84:87], v5 offset:8448
	ds_read_b128 a[36:39], v7
	ds_read_b128 a[32:35], v7 offset:256
	ds_read_b128 a[16:19], v7 offset:8192
	ds_read_b128 a[88:91], v7 offset:8448
	ds_read_b128 a[44:47], v9
	ds_read_b128 a[40:43], v9 offset:256
	ds_read_b128 a[24:27], v9 offset:8192
	ds_read_b128 v[250:253], v9 offset:8448
	s_waitcnt vmcnt(31) lgkmcnt(0)
	; wave barrier
	ds_write_b128 v13, v[178:181]
	s_waitcnt vmcnt(23)
	ds_write_b128 v13, v[34:37] offset:8192
	s_waitcnt vmcnt(15)
	ds_write_b128 v13, v[38:41] offset:16384
	s_waitcnt vmcnt(7)
	ds_write_b128 v13, v[42:45] offset:24576
	v_xad_u32 v13, v11, 16, 0
	ds_write_b128 v13, v[184:187]
	ds_write_b128 v13, v[162:165] offset:8192
	ds_write_b128 v13, v[166:169] offset:16384
	s_waitcnt vmcnt(6)
	ds_write_b128 v13, v[170:173] offset:24576
	v_xad_u32 v13, v11, 64, 0
	ds_write_b128 v13, v[188:191] offset:2048
	ds_write_b128 v13, v[212:215] offset:10240
	ds_write_b128 v13, v[246:249] offset:18432
	s_waitcnt vmcnt(5)
	ds_write_b128 v13, a[96:99] offset:26624
	v_xor_b32_e32 v13, 0x50, v11
	v_add_u32_e32 v13, 0, v13
	ds_write_b128 v13, v[192:195] offset:2048
	ds_write_b128 v13, v[216:219] offset:10240
	ds_write_b128 v13, a[64:67] offset:18432
	s_waitcnt vmcnt(4)
	ds_write_b128 v13, a[100:103] offset:26624
	v_xor_b32_e32 v13, 0x80, v11
	v_add_u32_e32 v13, 0, v13
	ds_write_b128 v13, v[196:199] offset:4096
	ds_write_b128 v13, v[220:223] offset:12288
	ds_write_b128 v13, a[68:71] offset:20480
	s_waitcnt vmcnt(3)
	ds_write_b128 v13, a[104:107] offset:28672
	v_xor_b32_e32 v13, 0x90, v11
	v_add_u32_e32 v13, 0, v13
	ds_write_b128 v13, v[200:203] offset:4096
	ds_write_b128 v13, v[224:227] offset:12288
	ds_write_b128 v13, a[72:75] offset:20480
	s_waitcnt vmcnt(2)
	ds_write_b128 v13, a[108:111] offset:28672
	v_xor_b32_e32 v13, 0xc0, v11
	v_xor_b32_e32 v11, 0xd0, v11
	v_add_u32_e32 v13, 0, v13
	v_add_u32_e32 v11, 0, v11
	ds_write_b128 v13, v[204:207] offset:6144
	ds_write_b128 v13, v[238:241] offset:14336
	ds_write_b128 v13, a[76:79] offset:22528
	s_waitcnt vmcnt(1)
	ds_write_b128 v13, v[46:49] offset:30720
	ds_write_b128 v11, v[208:211] offset:6144
	ds_write_b128 v11, v[242:245] offset:14336
	ds_write_b128 v11, a[92:95] offset:22528
	s_waitcnt vmcnt(0)
	ds_write_b128 v11, v[174:177] offset:30720
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_read_b128 a[72:75], v3
	ds_read_b128 a[60:63], v3 offset:256
	ds_read_b128 a[76:79], v5
	ds_read_b128 a[56:59], v5 offset:256
	ds_read_b128 a[68:71], v7
	ds_read_b128 a[52:55], v7 offset:256
	ds_read_b128 a[64:67], v9
	ds_read_b128 a[48:51], v9 offset:256
	v_mul_u32_u24_e32 v4, 0x3800, v4
	v_mul_u32_u24_e32 v5, 0x3800, v6
	v_mul_u32_u24_e32 v6, 0x3800, v8
	s_mul_i32 s2, s91, 0x3400
	v_mul_u32_u24_e32 v8, 0x3800, v12
	v_mul_u32_u24_e32 v12, 0x3800, v20
	s_add_i32 s33, s33, s2
	v_or_b32_e32 v20, v4, v66
	v_or_b32_e32 v21, v4, v32
	v_or_b32_e32 v4, v6, v66
	v_mul_u32_u24_e32 v7, 0x3800, v10
	v_mul_u32_u24_e32 v10, 0x3800, v16
	v_mul_u32_u24_e32 v15, 0x3800, v26
	v_or_b32_e32 v26, v5, v66
	v_or_b32_e32 v27, v5, v32
	v_or_b32_e32 v5, v6, v32
	v_add_lshl_u32 v4, v4, s33, 1
	v_or_b32_e32 v6, v10, v66
	s_and_b32 s77, s77, 0xffff
	s_mov_b32 s78, s6
	s_mov_b32 s79, s7
	v_cndmask_b32_e64 v4, v235, v4, s[36:37]
	v_add_lshl_u32 v5, v5, s33, 1
	v_mul_u32_u24_e32 v9, 0x3800, v14
	v_mul_u32_u24_e32 v14, 0x3800, v24
	v_cndmask_b32_e64 v5, v235, v5, s[36:37]
	buffer_load_dwordx4 v[42:45], v4, s[76:79], 0 offen
	buffer_load_dwordx4 v[46:49], v5, s[76:79], 0 offen
	v_add_lshl_u32 v4, v6, s33, 1
	v_mul_u32_u24_e32 v17, 0x3800, v30
	v_or_b32_e32 v30, v8, v66
	v_or_b32_e32 v31, v8, v32
	v_or_b32_e32 v8, v14, v66
	v_cndmask_b32_e64 v4, v235, v4, s[30:31]
	v_mul_u32_u24_e32 v3, 0x3800, v182
	buffer_load_dwordx4 v[226:229], v4, s[76:79], 0 offen
	v_add_lshl_u32 v4, v8, s33, 1
	v_mul_u32_u24_e32 v11, 0x3800, v18
	v_mul_u32_u24_e32 v16, 0x3800, v28
	v_or_b32_e32 v18, v3, v66
	v_or_b32_e32 v28, v7, v66
	v_or_b32_e32 v29, v7, v32
	v_or_b32_e32 v7, v10, v32
	v_cndmask_b32_e64 v4, v235, v4, s[38:39]
	v_or_b32_e32 v3, v3, v32
	v_add_lshl_u32 v10, v18, s33, 1
	buffer_load_dwordx4 v[238:241], v4, s[76:79], 0 offen
	v_add_lshl_u32 v4, v7, s33, 1
	v_or_b32_e32 v33, v9, v66
	v_or_b32_e32 v170, v9, v32
	v_or_b32_e32 v9, v14, v32
	v_cndmask_b32_e64 v10, v235, v10, s[34:35]
	v_add_lshl_u32 v3, v3, s33, 1
	v_cndmask_b32_e64 v4, v235, v4, s[30:31]
	v_cndmask_b32_e64 v3, v235, v3, s[34:35]
	buffer_load_dwordx4 v[34:37], v10, s[76:79], 0 offen
	buffer_load_dwordx4 v[38:41], v3, s[76:79], 0 offen
	buffer_load_dwordx4 v[242:245], v4, s[76:79], 0 offen
	v_add_lshl_u32 v4, v9, s33, 1
	v_cndmask_b32_e64 v4, v235, v4, s[38:39]
	buffer_load_dwordx4 v[246:249], v4, s[76:79], 0 offen
	v_mul_u32_u24_e32 v2, 0x3800, v2
	v_or_b32_e32 v19, v2, v66
	v_or_b32_e32 v2, v2, v32
	v_add_lshl_u32 v3, v19, s33, 1
	v_add_lshl_u32 v2, v2, s33, 1
	v_cndmask_b32_e32 v3, v235, v3, vcc
	v_cndmask_b32_e32 v6, v235, v2, vcc
	buffer_load_dwordx4 v[2:5], v3, s[76:79], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[186:189], v6, s[76:79], 0 offen
	v_add_lshl_u32 v6, v20, s33, 1
	v_or_b32_e32 v171, v11, v66
	v_or_b32_e32 v180, v15, v66
	v_cndmask_b32_e64 v6, v235, v6, s[0:1]
	v_add_lshl_u32 v7, v21, s33, 1
	v_add_lshl_u32 v10, v28, s33, 1
	v_mul_u32_u24_e32 v13, 0x3800, v22
	v_or_b32_e32 v172, v11, v32
	v_or_b32_e32 v181, v15, v32
	v_cndmask_b32_e64 v7, v235, v7, s[0:1]
	buffer_load_dwordx4 v[166:169], v6, s[76:79], 0 offen
	buffer_load_dwordx4 v[22:25], v7, s[76:79], 0 offen
	v_add_lshl_u32 v6, v26, s33, 1
	v_cndmask_b32_e64 v10, v235, v10, s[12:13]
	v_add_lshl_u32 v11, v29, s33, 1
	v_add_lshl_u32 v26, v171, s33, 1
	v_add_lshl_u32 v28, v180, s33, 1
	v_or_b32_e32 v173, v12, v66
	v_or_b32_e32 v194, v16, v66
	v_add_lshl_u32 v7, v27, s33, 1
	v_cndmask_b32_e64 v11, v235, v11, s[12:13]
	buffer_load_dwordx4 v[222:225], v10, s[76:79], 0 offen
	buffer_load_dwordx4 v[198:201], v11, s[76:79], 0 offen
	v_add_lshl_u32 v10, v30, s33, 1
	v_cndmask_b32_e64 v26, v235, v26, s[18:19]
	v_add_lshl_u32 v27, v172, s33, 1
	v_cndmask_b32_e64 v30, v235, v28, s[24:25]
	v_add_lshl_u32 v28, v181, s33, 1
	v_or_b32_e32 v174, v12, v32
	v_or_b32_e32 v195, v16, v32
	v_cndmask_b32_e64 v10, v235, v10, s[14:15]
	v_add_lshl_u32 v11, v31, s33, 1
	v_cndmask_b32_e64 v27, v235, v27, s[18:19]
	buffer_load_dwordx4 v[210:213], v26, s[76:79], 0 offen
	buffer_load_dwordx4 v[202:205], v27, s[76:79], 0 offen
	v_add_lshl_u32 v26, v173, s33, 1
	v_cndmask_b32_e64 v31, v235, v28, s[24:25]
	v_add_lshl_u32 v28, v194, s33, 1
	v_or_b32_e32 v178, v13, v66
	v_or_b32_e32 v196, v17, v66
	v_cndmask_b32_e64 v11, v235, v11, s[14:15]
	buffer_load_dwordx4 v[182:185], v10, s[76:79], 0 offen
	buffer_load_dwordx4 v[162:165], v11, s[76:79], 0 offen
	v_add_lshl_u32 v10, v33, s33, 1
	v_cndmask_b32_e64 v26, v235, v26, s[20:21]
	v_add_lshl_u32 v27, v174, s33, 1
	v_cndmask_b32_e64 v33, v235, v28, s[26:27]
	v_add_lshl_u32 v28, v195, s33, 1
	v_or_b32_e32 v179, v13, v32
	v_or_b32_e32 v32, v17, v32
	v_cndmask_b32_e64 v27, v235, v27, s[20:21]
	buffer_load_dwordx4 v[190:193], v26, s[76:79], 0 offen
	buffer_load_dwordx4 v[174:177], v27, s[76:79], 0 offen
	v_add_lshl_u32 v26, v178, s33, 1
	v_cndmask_b32_e64 v178, v235, v28, s[26:27]
	v_add_lshl_u32 v28, v196, s33, 1
	v_accvgpr_read_b32 v66, a174
	v_add_lshl_u32 v11, v170, s33, 1
	v_add_lshl_u32 v27, v179, s33, 1
	v_cndmask_b32_e64 v179, v235, v28, s[28:29]
	v_add_lshl_u32 v28, v32, s33, 1
	v_or_b32_e32 v234, v1, v66
	v_cndmask_b32_e64 v6, v235, v6, s[10:11]
	v_cndmask_b32_e64 v7, v235, v7, s[10:11]
	v_cndmask_b32_e64 v10, v235, v10, s[16:17]
	v_cndmask_b32_e64 v11, v235, v11, s[16:17]
	v_cndmask_b32_e64 v26, v235, v26, s[22:23]
	v_cndmask_b32_e64 v27, v235, v27, s[22:23]
	v_cndmask_b32_e64 v32, v235, v28, s[28:29]
	v_add_u32_e32 v254, 0, v234
	buffer_load_dwordx4 v[14:17], v6, s[76:79], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[6:9], v7, s[76:79], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[18:21], v10, s[76:79], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[10:13], v11, s[76:79], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[170:173], v26, s[76:79], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[26:29], v27, s[76:79], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[218:221], v30, s[76:79], 0 offen
	buffer_load_dwordx4 v[214:217], v31, s[76:79], 0 offen
	buffer_load_dwordx4 v[206:209], v33, s[76:79], 0 offen
	buffer_load_dwordx4 v[194:197], v178, s[76:79], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[178:181], v179, s[76:79], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[30:33], v32, s[76:79], 0 offen
	s_waitcnt vmcnt(27) lgkmcnt(0)
	; wave barrier
	ds_write2st64_b64 v254, v[34:35], v[42:43] offset1:16
	ds_write2st64_b64 v254, v[226:227], v[238:239] offset0:32 offset1:48
	v_xad_u32 v34, v234, 8, 0
	ds_write2st64_b64 v34, v[36:37], v[44:45] offset1:16
	ds_write2st64_b64 v34, v[228:229], v[240:241] offset0:32 offset1:48
	v_xad_u32 v34, v234, 16, 0
	s_waitcnt vmcnt(26)
	ds_write2st64_b64 v34, v[38:39], v[46:47] offset1:16
	s_waitcnt vmcnt(24)
	ds_write2st64_b64 v34, v[242:243], v[246:247] offset0:32 offset1:48
	v_xad_u32 v34, v234, 24, 0
	ds_write2st64_b64 v34, v[40:41], v[48:49] offset1:16
	ds_write2st64_b64 v34, v[244:245], v[248:249] offset0:32 offset1:48
	v_mfma_f32_16x16x32_bf16 v[34:37], a[72:75], a[12:15], 0
	v_or_b32_e32 v42, 1, v232
	v_or_b32_e32 v44, 2, v232
	v_mov_b32_e32 v43, v233
	v_mfma_f32_16x16x32_bf16 v[38:41], a[72:75], a[0:3], 0
	v_mov_b32_e32 v45, v233
	v_cmp_gt_i64_e32 vcc, v[230:231], v[42:43]
	v_or_b32_e32 v42, 3, v232
	v_mfma_f32_16x16x32_bf16 v[34:37], a[76:79], a[28:31], v[34:37]
	v_cmp_gt_i64_e64 s[0:1], v[230:231], v[232:233]
	v_cmp_gt_i64_e64 s[2:3], v[230:231], v[44:45]
	v_cmp_ge_u32_e64 s[10:11], v68, v232
	v_mfma_f32_16x16x32_bf16 v[38:41], a[76:79], a[8:11], v[38:41]
	v_cmp_gt_u32_e64 s[12:13], v68, v232
	v_cmp_ge_u32_e64 s[14:15], v68, v44
	v_cmp_gt_i64_e64 s[4:5], v[230:231], v[42:43]
	v_mfma_f32_16x16x32_bf16 v[34:37], a[68:71], a[36:39], v[34:37]
	v_cmp_ge_u32_e64 s[16:17], v68, v42
	s_and_b64 s[0:1], s[10:11], s[0:1]
	s_and_b64 s[10:11], s[12:13], vcc
	v_mfma_f32_16x16x32_bf16 v[38:41], a[68:71], a[16:19], v[38:41]
	s_and_b64 s[2:3], s[14:15], s[2:3]
	s_and_b64 s[4:5], s[16:17], s[4:5]
	v_mov_b32_e32 v42, 0xff800000
	v_mfma_f32_16x16x32_bf16 v[34:37], a[64:67], a[44:47], v[34:37]
	s_and_b64 vcc, s[44:45], s[0:1]
	s_and_b64 s[0:1], s[44:45], s[10:11]
	s_and_b64 s[2:3], s[44:45], s[2:3]
	v_mfma_f32_16x16x32_bf16 v[38:41], a[64:67], a[24:27], v[38:41]
	s_and_b64 s[4:5], s[44:45], s[4:5]
	s_mov_b32 s12, 0xff800000
	v_accvgpr_write_b32 a157, v105
	v_mfma_f32_16x16x32_bf16 v[34:37], a[60:63], a[4:7], v[34:37]
	v_accvgpr_write_b32 a156, v104
	v_accvgpr_write_b32 a155, v103
	v_accvgpr_write_b32 a154, v102
	v_mfma_f32_16x16x32_bf16 v[38:41], a[60:63], a[80:83], v[38:41]
	v_accvgpr_write_b32 a153, v101
	v_accvgpr_write_b32 a152, v100
	v_accvgpr_write_b32 a151, v99
	v_mfma_f32_16x16x32_bf16 v[34:37], a[56:59], a[20:23], v[34:37]
	v_accvgpr_write_b32 a150, v98
	v_accvgpr_write_b32 a149, v97
	v_accvgpr_write_b32 a148, v96
	v_mfma_f32_16x16x32_bf16 v[38:41], a[56:59], a[84:87], v[38:41]
	v_accvgpr_write_b32 a147, v95
	v_accvgpr_write_b32 a146, v94
	v_accvgpr_write_b32 a145, v93
	v_mfma_f32_16x16x32_bf16 v[34:37], a[52:55], a[32:35], v[34:37]
	v_accvgpr_write_b32 a144, v92
	v_accvgpr_write_b32 a143, v91
	v_accvgpr_write_b32 a142, v90
	v_mfma_f32_16x16x32_bf16 v[38:41], a[52:55], a[88:91], v[38:41]
	v_accvgpr_write_b32 a141, v89
	v_accvgpr_write_b32 a140, v88
	v_accvgpr_write_b32 a139, v87
	v_mfma_f32_16x16x32_bf16 v[34:37], a[48:51], a[40:43], v[34:37]
	v_accvgpr_write_b32 a138, v86
	v_accvgpr_write_b32 a137, v85
	v_accvgpr_write_b32 a136, v84
	v_mfma_f32_16x16x32_bf16 v[38:41], a[48:51], v[250:253], v[38:41]
	v_accvgpr_write_b32 a135, v83
	v_accvgpr_write_b32 a134, v82
	v_accvgpr_write_b32 a133, v81
	v_accvgpr_write_b32 a132, v80
	v_mul_f32_e32 v34, s90, v34
	v_mul_f32_e32 v35, s90, v35
	v_mul_f32_e32 v36, s90, v36
	v_mul_f32_e32 v37, s90, v37
	v_mul_f32_e32 v38, s90, v38
	v_cndmask_b32_e32 v34, v42, v34, vcc
	v_cndmask_b32_e64 v35, v42, v35, s[0:1]
	v_cndmask_b32_e64 v36, v42, v36, s[2:3]
	v_cndmask_b32_e64 v37, v42, v37, s[4:5]
	v_cndmask_b32_e32 v240, v42, v38, vcc
.Ltmp193:
	v_max3_f32 v38, v34, v35, v36
.Ltmp194:
	v_mul_f32_e32 v40, s90, v40
.Ltmp195:
	v_max3_f32 v38, v38, v37, s12
.Ltmp196:
	v_cndmask_b32_e64 v239, v42, v40, s[2:3]
.Ltmp197:
	v_mov_b32_e32 v40, v38
	s_nop 1
	v_permlane32_swap_b32_e32 v38, v40
.Ltmp198:
	v_max_f32_e32 v40, v40, v40
	v_max_f32_e32 v38, v38, v38
.Ltmp199:
	v_mul_f32_e32 v39, s90, v39
.Ltmp200:
	v_max_f32_e32 v38, v38, v40
.Ltmp201:
	v_mul_f32_e32 v41, s90, v41
	v_cndmask_b32_e64 v241, v42, v39, s[0:1]
.Ltmp202:
	v_mov_b32_e32 v40, v38
.Ltmp203:
	v_cndmask_b32_e64 v238, v42, v41, s[4:5]
.Ltmp204:
	v_max3_f32 v39, v240, v241, v239
.Ltmp205:
	v_permlane16_swap_b32_e32 v38, v40
.Ltmp206:
	v_max3_f32 v39, v39, v238, s12
	v_max_f32_e32 v40, v40, v40
	v_max_f32_e32 v38, v38, v38
	v_max_f32_e32 v38, v38, v40
.Ltmp207:
	v_mov_b32_e32 v40, v39
	s_nop 1
	v_permlane32_swap_b32_e32 v39, v40
.Ltmp208:
	v_max_f32_e32 v40, v40, v40
	v_max_f32_e32 v39, v39, v39
	v_max_f32_e32 v39, v39, v40
.Ltmp209:
	v_mov_b32_e32 v40, v39
	s_nop 1
	v_permlane16_swap_b32_e32 v39, v40
.Ltmp210:
	v_max_f32_e32 v40, v40, v40
	v_max_f32_e32 v39, v39, v39
	v_max_f32_e32 v39, v39, v40
.Ltmp211:
	v_mov_b32_e32 v40, 0xe0ad78ec
	v_cmp_neq_f32_e32 vcc, s12, v38
	s_mov_b32 s2, 0xc2fc0000
	v_accvgpr_write_b32 a131, v79
	v_cndmask_b32_e32 v38, v40, v38, vcc
	v_cmp_neq_f32_e32 vcc, s12, v39
	v_accvgpr_write_b32 a130, v78
	v_accvgpr_write_b32 a125, v77
	v_cndmask_b32_e32 v39, v40, v39, vcc
	v_max_f32_e32 v40, v237, v237
	v_max_f32_e32 v38, v38, v40
	v_max_f32_e32 v40, v236, v236
	v_max_f32_e32 v242, v39, v40
	v_sub_f32_e32 v39, v237, v38
	v_mul_f32_e32 v40, 0x3fb8aa3b, v39
	v_mov_b32_e32 v237, 0x42800000
	v_cmp_gt_f32_e32 vcc, s2, v40
	v_sub_f32_e32 v243, v236, v242
	v_not_b32_e32 v236, 63
	v_cndmask_b32_e32 v40, 0, v237, vcc
	v_fmac_f32_e32 v40, 0x3fb8aa3b, v39
	v_exp_f32_e32 v39, v40
	v_cndmask_b32_e32 v40, 0, v236, vcc
	v_sub_f32_e32 v34, v34, v38
	v_sub_f32_e32 v35, v35, v38
	v_ldexp_f32 v230, v39, v40
	v_mul_f32_e32 v39, 0x3fb8aa3b, v34
	v_cmp_gt_f32_e32 vcc, s2, v39
	v_sub_f32_e32 v36, v36, v38
	v_sub_f32_e32 v37, v37, v38
	v_cndmask_b32_e32 v39, 0, v237, vcc
	v_fmac_f32_e32 v39, 0x3fb8aa3b, v34
	v_exp_f32_e32 v34, v39
	v_cndmask_b32_e32 v39, 0, v236, vcc
	v_sub_f32_e32 v38, 0xff800000, v38
	v_accvgpr_write_b32 a124, v76
	v_ldexp_f32 v231, v34, v39
	v_mul_f32_e32 v34, 0x3fb8aa3b, v35
	v_cmp_gt_f32_e32 vcc, s2, v34
	v_accvgpr_write_b32 a123, v75
	v_accvgpr_write_b32 a122, v74
	v_cndmask_b32_e32 v34, 0, v237, vcc
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v35
	v_mul_f32_e32 v35, 0x3fb8aa3b, v36
	v_cmp_gt_f32_e64 s[0:1], s2, v35
	v_exp_f32_e32 v34, v34
	v_accvgpr_write_b32 a121, v73
	v_cndmask_b32_e64 v35, 0, v237, s[0:1]
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v36
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e32 v36, 0, v236, vcc
	v_ldexp_f32 v232, v34, v36
	v_cndmask_b32_e64 v34, 0, v236, s[0:1]
	v_ldexp_f32 v233, v35, v34
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
	v_ldexp_f32 v234, v34, v36
	v_cndmask_b32_e64 v34, 0, v236, s[0:1]
	s_movk_i32 s0, 0x820
	v_ldexp_f32 v227, v35, v34
	v_bitop3_b32 v34, v1, s0, v66 bitop3:0x36
	v_add_u32_e32 v34, 0, v34
	s_movk_i32 s0, 0x828
	s_waitcnt vmcnt(19)
	ds_write2st64_b64 v34, v[2:3], v[222:223] offset1:16
	s_waitcnt vmcnt(5)
	ds_write2st64_b64 v34, v[210:211], v[218:219] offset0:32 offset1:48
	v_bitop3_b32 v2, v1, s0, v66 bitop3:0x36
	v_add_u32_e32 v34, 0, v2
	s_movk_i32 s0, 0x830
	ds_write2st64_b64 v34, v[4:5], v[224:225] offset1:16
	v_bitop3_b32 v5, v1, s0, v66 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	s_movk_i32 s0, 0x838
	ds_write2st64_b64 v34, v[212:213], v[220:221] offset0:32 offset1:48
	ds_write2st64_b64 v5, v[186:187], v[198:199] offset1:16
	s_waitcnt vmcnt(4)
	ds_write2st64_b64 v5, v[202:203], v[214:215] offset0:32 offset1:48
	v_bitop3_b32 v5, v1, s0, v66 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	s_movk_i32 s0, 0x1040
	ds_write2st64_b64 v5, v[188:189], v[200:201] offset1:16
	ds_write2st64_b64 v5, v[204:205], v[216:217] offset0:32 offset1:48
	v_bitop3_b32 v5, v1, s0, v66 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	s_movk_i32 s0, 0x1048
	ds_write2st64_b64 v5, v[166:167], v[182:183] offset1:16
	s_waitcnt vmcnt(3)
	ds_write2st64_b64 v5, v[190:191], v[206:207] offset0:32 offset1:48
	v_bitop3_b32 v5, v1, s0, v66 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	s_movk_i32 s0, 0x1050
	ds_write2st64_b64 v5, v[168:169], v[184:185] offset1:16
	ds_write2st64_b64 v5, v[192:193], v[208:209] offset0:32 offset1:48
	v_bitop3_b32 v5, v1, s0, v66 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	s_movk_i32 s0, 0x1058
	ds_write2st64_b64 v5, v[22:23], v[162:163] offset1:16
	s_waitcnt vmcnt(2)
	ds_write2st64_b64 v5, v[174:175], v[194:195] offset0:32 offset1:48
	v_bitop3_b32 v5, v1, s0, v66 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	s_movk_i32 s0, 0x1860
	ds_write2st64_b64 v5, v[24:25], v[164:165] offset1:16
	ds_write2st64_b64 v5, v[176:177], v[196:197] offset0:32 offset1:48
	v_bitop3_b32 v5, v1, s0, v66 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	s_movk_i32 s0, 0x1868
	ds_write2st64_b64 v5, v[14:15], v[18:19] offset1:16
	s_waitcnt vmcnt(1)
	ds_write2st64_b64 v5, v[170:171], v[178:179] offset0:32 offset1:48
	v_bitop3_b32 v5, v1, s0, v66 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	s_movk_i32 s0, 0x1870
	ds_write2st64_b64 v5, v[16:17], v[20:21] offset1:16
	ds_write2st64_b64 v5, v[172:173], v[180:181] offset0:32 offset1:48
	v_bitop3_b32 v5, v1, s0, v66 bitop3:0x36
	s_movk_i32 s0, 0x1878
	v_bitop3_b32 v1, v1, s0, v66 bitop3:0x36
	v_add_u32_e32 v5, 0, v5
	v_add_u32_e32 v1, 0, v1
	ds_write2st64_b64 v5, v[6:7], v[10:11] offset1:16
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v5, v[26:27], v[30:31] offset0:32 offset1:48
	ds_write2st64_b64 v1, v[8:9], v[12:13] offset1:16
	ds_write2st64_b64 v1, v[28:29], v[32:33] offset0:32 offset1:48
	v_and_b32_e32 v1, 60, v0
	v_accvgpr_read_b32 v6, a175
	v_lshlrev_b32_e32 v5, 7, v1
	v_and_b32_e32 v6, 24, v6
	v_lshlrev_b32_e32 v1, 1, v1
	v_bitop3_b32 v1, v5, v1, v6 bitop3:0x36
	v_add_u32_e32 v5, 0, v1
	v_cvt_pk_bf16_f32 v4, v227, v227
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
	ds_read_b64_tr_b16 v[42:43], v5 offset:16384
	ds_read_b64_tr_b16 v[198:199], v5 offset:16512
	ds_read_b64_tr_b16 v[18:19], v5 offset:16640
	ds_read_b64_tr_b16 v[166:167], v5 offset:16768
	ds_read_b64_tr_b16 v[44:45], v5 offset:24576
	ds_read_b64_tr_b16 v[200:201], v5 offset:24704
	ds_read_b64_tr_b16 v[20:21], v5 offset:24832
	ds_read_b64_tr_b16 v[168:169], v5 offset:24960
	v_xad_u32 v5, v1, 32, 0
	v_cvt_pk_bf16_f32 v2, v231, v232
	v_cvt_pk_bf16_f32 v3, v233, v234
	ds_read_b64_tr_b16 v[46:47], v5
	ds_read_b64_tr_b16 v[202:203], v5 offset:128
	ds_read_b64_tr_b16 v[22:23], v5 offset:256
	ds_read_b64_tr_b16 v[170:171], v5 offset:384
	ds_read_b64_tr_b16 v[48:49], v5 offset:8192
	ds_read_b64_tr_b16 v[204:205], v5 offset:8320
	ds_read_b64_tr_b16 v[24:25], v5 offset:8448
	ds_read_b64_tr_b16 v[172:173], v5 offset:8576
	ds_read_b64_tr_b16 v[222:223], v5 offset:16384
	ds_read_b64_tr_b16 v[206:207], v5 offset:16512
	ds_read_b64_tr_b16 v[186:187], v5 offset:16640
	ds_read_b64_tr_b16 v[174:175], v5 offset:16768
	ds_read_b64_tr_b16 v[224:225], v5 offset:24576
	ds_read_b64_tr_b16 v[208:209], v5 offset:24704
	ds_read_b64_tr_b16 v[188:189], v5 offset:24832
	ds_read_b64_tr_b16 v[176:177], v5 offset:24960
	v_mov_b32_e32 v5, v4
	v_pk_mul_f32 v[32:33], v[160:161], v[230:231] op_sel_hi:[1,0]
	v_pk_mul_f32 v[30:31], v[158:159], v[230:231] op_sel_hi:[1,0]
	v_mov_b32_e32 v6, v4
	v_mov_b32_e32 v7, v4
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_bf16 v[30:33], v[218:221], v[2:5], v[30:33]
	v_mov_b32_e32 v8, v4
	v_mov_b32_e32 v9, v4
	v_xad_u32 v34, v1, 64, 0
	v_xor_b32_e32 v1, 0x60, v1
	v_mfma_f32_16x16x32_bf16 v[158:161], v[42:45], v[6:9], v[30:33]
	v_add_u32_e32 v1, 0, v1
	ds_read_b64_tr_b16 v[244:245], v34
	ds_read_b64_tr_b16 v[210:211], v34 offset:128
	ds_read_b64_tr_b16 v[190:191], v34 offset:256
	ds_read_b64_tr_b16 v[178:179], v34 offset:384
	ds_read_b64_tr_b16 v[246:247], v34 offset:8192
	ds_read_b64_tr_b16 v[212:213], v34 offset:8320
	ds_read_b64_tr_b16 v[192:193], v34 offset:8448
	ds_read_b64_tr_b16 v[180:181], v34 offset:8576
	ds_read_b64_tr_b16 v[248:249], v34 offset:16384
	ds_read_b64_tr_b16 v[214:215], v34 offset:16512
	ds_read_b64_tr_b16 v[194:195], v34 offset:16640
	ds_read_b64_tr_b16 v[182:183], v34 offset:16768
	v_pk_mul_f32 v[32:33], v[156:157], v[230:231] op_sel_hi:[1,0]
	v_pk_mul_f32 v[30:31], v[154:155], v[230:231] op_sel_hi:[1,0]
	ds_read_b64_tr_b16 v[254:255], v1 offset:24576
	ds_read_b64_tr_b16 v[250:251], v34 offset:24576
	ds_read_b64_tr_b16 v[216:217], v34 offset:24704
	ds_read_b64_tr_b16 v[196:197], v34 offset:24832
	ds_read_b64_tr_b16 v[184:185], v34 offset:24960
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_bf16 v[30:33], v[46:49], v[2:5], v[30:33]
	ds_read_b64_tr_b16 a[0:1], v1
	ds_read_b64_tr_b16 a[4:5], v1 offset:128
	ds_read_b64_tr_b16 a[8:9], v1 offset:256
	ds_read_b64_tr_b16 a[12:13], v1 offset:384
	ds_read_b64_tr_b16 a[2:3], v1 offset:8192
	ds_read_b64_tr_b16 a[6:7], v1 offset:8320
	ds_read_b64_tr_b16 a[10:11], v1 offset:8448
	ds_read_b64_tr_b16 a[14:15], v1 offset:8576
	ds_read_b64_tr_b16 v[252:253], v1 offset:16384
	ds_read_b64_tr_b16 a[16:17], v1 offset:16512
	ds_read_b64_tr_b16 a[20:21], v1 offset:16640
	ds_read_b64_tr_b16 a[24:25], v1 offset:16768
	v_mfma_f32_16x16x32_bf16 v[154:157], v[222:225], v[6:9], v[30:33]
	ds_read_b64_tr_b16 a[18:19], v1 offset:24704
	ds_read_b64_tr_b16 a[22:23], v1 offset:24832
	ds_read_b64_tr_b16 a[26:27], v1 offset:24960
	v_pk_mul_f32 v[32:33], v[152:153], v[230:231] op_sel_hi:[1,0]
	v_pk_mul_f32 v[30:31], v[150:151], v[230:231] op_sel_hi:[1,0]
	v_mul_f32_e32 v1, 0x3fb8aa3b, v243
	v_cmp_gt_f32_e32 vcc, s2, v1
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_bf16 v[30:33], v[244:247], v[2:5], v[30:33]
	v_accvgpr_write_b32 a120, v72
	v_cndmask_b32_e32 v1, 0, v237, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v243
	v_mfma_f32_16x16x32_bf16 v[150:153], v[248:251], v[6:9], v[30:33]
	v_exp_f32_e32 v1, v1
	v_cndmask_b32_e32 v38, 0, v236, vcc
	v_accvgpr_write_b32 a119, v71
	v_accvgpr_write_b32 a118, v70
	v_pk_mul_f32 v[32:33], v[148:149], v[230:231] op_sel_hi:[1,0]
	v_pk_mul_f32 v[30:31], v[146:147], v[230:231] op_sel_hi:[1,0]
	v_mov_b32_e32 v226, v68
	s_and_b32 s9, s9, 0xffff
	s_waitcnt lgkmcnt(10)
	v_mfma_f32_16x16x32_bf16 v[30:33], a[0:3], v[2:5], v[30:33]
	s_mov_b32 s10, s6
	s_mov_b32 s11, s7
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[146:149], v[252:255], v[6:9], v[30:33]
	s_nop 3
	v_mul_f32_e64 v32, v144, v230
	v_mul_f32_e64 v33, v145, v230
	v_pk_mul_f32 v[30:31], v[142:143], v[230:231] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[30:33], v[26:29], v[2:5], v[30:33]
	v_mfma_f32_16x16x32_bf16 v[142:145], v[198:201], v[6:9], v[30:33]
	s_nop 6
	v_mul_f32_e64 v32, v140, v230
	v_mul_f32_e64 v33, v141, v230
	v_pk_mul_f32 v[30:31], v[138:139], v[230:231] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[34:37], v[202:205], v[2:5], v[30:33]
	v_mfma_f32_16x16x32_bf16 v[138:141], v[206:209], v[6:9], v[34:37]
	s_nop 1
	v_ldexp_f32 v32, v1, v38
	v_sub_f32_e32 v1, v240, v242
	v_mul_f32_e32 v39, 0x3fb8aa3b, v1
	v_cmp_gt_f32_e32 vcc, s2, v39
	s_nop 0
	v_pk_mul_f32 v[36:37], v[136:137], v[230:231] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[134:135], v[230:231] op_sel_hi:[1,0]
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
	v_pk_mul_f32 v[36:37], v[132:133], v[230:231] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[130:131], v[230:231] op_sel_hi:[1,0]
	v_cndmask_b32_e32 v40, 0, v237, vcc
	v_fmac_f32_e32 v40, 0x3fb8aa3b, v30
	v_mfma_f32_16x16x32_bf16 v[34:37], a[4:7], v[2:5], v[34:37]
	v_exp_f32_e32 v30, v40
	v_cndmask_b32_e32 v1, 0, v236, vcc
	v_sub_f32_e32 v33, v238, v242
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[130:133], a[16:19], v[6:9], v[34:37]
	v_ldexp_f32 v30, v30, v1
	v_mul_f32_e32 v1, 0x3fb8aa3b, v31
	v_cmp_gt_f32_e32 vcc, s2, v1
	v_sub_f32_e32 v38, 0xff800000, v242
	v_pk_mul_f32 v[36:37], v[128:129], v[230:231] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[126:127], v[230:231] op_sel_hi:[1,0]
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
	v_pk_mul_f32 v[36:37], v[124:125], v[230:231] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[122:123], v[230:231] op_sel_hi:[1,0]
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
	v_pk_mul_f32 v[36:37], v[120:121], v[230:231] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[118:119], v[230:231] op_sel_hi:[1,0]
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
	v_pk_mul_f32 v[36:37], v[116:117], v[230:231] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[114:115], v[230:231] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[34:37], a[8:11], v[2:5], v[34:37]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[114:117], a[20:23], v[6:9], v[34:37]
	s_nop 5
	v_mul_f32_e64 v36, v112, v230
	v_mul_f32_e64 v37, v113, v230
	v_pk_mul_f32 v[34:35], v[110:111], v[230:231] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[34:37], v[10:13], v[2:5], v[34:37]
	v_mfma_f32_16x16x32_bf16 v[110:113], v[166:169], v[6:9], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v108, v230
	v_mul_f32_e64 v37, v109, v230
	v_pk_mul_f32 v[34:35], v[106:107], v[230:231] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[34:37], v[170:173], v[2:5], v[34:37]
	v_mfma_f32_16x16x32_bf16 v[106:109], v[174:177], v[6:9], v[34:37]
	s_nop 6
	v_accvgpr_read_b32 v34, a170
	v_accvgpr_read_b32 v35, a171
	v_accvgpr_read_b32 v36, a172
	v_accvgpr_read_b32 v37, a173
	v_pk_mul_f32 v[36:37], v[36:37], v[230:231] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[34:35], v[230:231] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[34:37], v[178:181], v[2:5], v[34:37]
	v_mfma_f32_16x16x32_bf16 v[102:105], v[182:185], v[6:9], v[34:37]
	s_nop 6
	v_accvgpr_read_b32 v34, a166
	v_accvgpr_read_b32 v35, a167
	v_accvgpr_read_b32 v36, a168
	v_accvgpr_read_b32 v37, a169
	v_pk_mul_f32 v[36:37], v[36:37], v[230:231] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[34:35], v[230:231] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[2:5], a[12:15], v[2:5], v[34:37]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[98:101], a[24:27], v[6:9], v[2:5]
	s_nop 0
	v_mov_b32_e32 v34, v164
	v_mov_b32_e32 v35, v164
	v_mov_b32_e32 v36, v164
	v_mov_b32_e32 v37, v164
	s_nop 0
	v_accvgpr_read_b32 v2, a162
	v_accvgpr_read_b32 v3, a163
	v_accvgpr_read_b32 v4, a164
	v_accvgpr_read_b32 v5, a165
	v_pk_mul_f32 v[4:5], v[4:5], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[2:5], v[218:221], v[162:165], v[2:5]
	v_mfma_f32_16x16x32_bf16 v[94:97], v[42:45], v[34:37], v[2:5]
	s_nop 6
	v_accvgpr_read_b32 v2, a158
	v_accvgpr_read_b32 v3, a159
	v_accvgpr_read_b32 v4, a160
	v_accvgpr_read_b32 v5, a161
	v_pk_mul_f32 v[4:5], v[4:5], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[2:5], v[46:49], v[162:165], v[2:5]
	v_and_or_b32 v49, v0, 16, v1
	v_or_b32_e32 v218, 0xe0, v49
	v_or_b32_e32 v219, 0xc0, v49
	v_mfma_f32_16x16x32_bf16 v[90:93], v[222:225], v[34:37], v[2:5]
	v_or_b32_e32 v220, 0xa0, v49
	v_or_b32_e32 v221, 0x80, v49
	v_or_b32_e32 v222, 0x60, v49
	v_or_b32_e32 v223, 64, v49
	v_accvgpr_read_b32 v2, a154
	v_accvgpr_read_b32 v3, a155
	v_accvgpr_read_b32 v4, a156
	v_accvgpr_read_b32 v5, a157
	v_pk_mul_f32 v[4:5], v[4:5], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	v_or_b32_e32 v224, 32, v49
	s_nop 0
	v_mfma_f32_16x16x32_bf16 v[2:5], v[244:247], v[162:165], v[2:5]
	v_mfma_f32_16x16x32_bf16 v[86:89], v[248:251], v[34:37], v[2:5]
	v_accvgpr_read_b32 v0, a150
	v_accvgpr_read_b32 v1, a151
	v_pk_mul_f32 v[0:1], v[0:1], v[32:33] op_sel_hi:[1,0]
	s_nop 3
	v_accvgpr_read_b32 v2, a152
	v_accvgpr_read_b32 v3, a153
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
.Ltmp212:
	v_add_f32_e32 v5, v39, v30
	v_add_f32_e32 v5, v31, v5
.Ltmp213:
	v_mfma_f32_16x16x32_bf16 v[0:3], a[0:3], v[162:165], v[0:3]
.Ltmp214:
	v_add_f32_e32 v4, v231, v232
	v_add_f32_e32 v4, v233, v4
	v_add_f32_e32 v4, v234, v4
.Ltmp215:
	v_mfma_f32_16x16x32_bf16 v[82:85], v[252:255], v[34:37], v[0:3]
.Ltmp216:
	v_add_f32_e32 v4, v227, v4
	v_add_f32_e32 v4, v227, v4
	v_add_f32_e32 v4, v227, v4
	v_add_f32_e32 v4, v227, v4
	v_accvgpr_read_b32 v0, a146
	v_accvgpr_read_b32 v1, a147
	v_accvgpr_read_b32 v2, a148
	v_accvgpr_read_b32 v3, a149
.Ltmp217:
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[0:1], v[32:33] op_sel_hi:[1,0]
.Ltmp218:
	v_add_f32_e32 v4, v227, v4
	v_add_f32_e32 v5, v33, v5
.Ltmp219:
	v_mfma_f32_16x16x32_bf16 v[0:3], v[26:29], v[162:165], v[0:3]
.Ltmp220:
	v_add_f32_e32 v4, v227, v4
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v4, v227, v4
.Ltmp221:
	v_mfma_f32_16x16x32_bf16 v[78:81], v[198:201], v[34:37], v[0:3]
.Ltmp222:
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v4, v227, v4
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v4, v227, v4
	v_accvgpr_read_b32 v0, a142
	v_accvgpr_read_b32 v1, a143
	v_accvgpr_read_b32 v2, a144
	v_accvgpr_read_b32 v3, a145
.Ltmp223:
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[0:1], v[32:33] op_sel_hi:[1,0]
.Ltmp224:
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v4, v227, v4
.Ltmp225:
	v_mfma_f32_16x16x32_bf16 v[0:3], v[202:205], v[162:165], v[0:3]
.Ltmp226:
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v4, v227, v4
	v_add_f32_e32 v5, v38, v5
.Ltmp227:
	v_mfma_f32_16x16x32_bf16 v[74:77], v[206:209], v[34:37], v[0:3]
.Ltmp228:
	v_add_f32_e32 v4, v227, v4
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v5, v38, v5
.Ltmp229:
	v_mov_b32_e32 v6, v4
	v_accvgpr_read_b32 v0, a138
	v_accvgpr_read_b32 v1, a139
	v_accvgpr_read_b32 v2, a140
	v_accvgpr_read_b32 v3, a141
.Ltmp230:
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[0:1], v[32:33] op_sel_hi:[1,0]
.Ltmp231:
	v_add_f32_e32 v5, v38, v5
.Ltmp232:
	v_permlane32_swap_b32_e32 v4, v6
.Ltmp233:
	v_mfma_f32_16x16x32_bf16 v[0:3], v[210:213], v[162:165], v[0:3]
.Ltmp234:
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v4, v4, v6
	v_add_f32_e32 v5, v38, v5
.Ltmp235:
	v_mfma_f32_16x16x32_bf16 v[70:73], v[214:217], v[34:37], v[0:3]
.Ltmp236:
	v_mov_b32_e32 v6, v4
.Ltmp237:
	v_add_f32_e32 v5, v38, v5
.Ltmp238:
	s_nop 0
	v_permlane16_swap_b32_e32 v4, v6
	v_accvgpr_read_b32 v0, a134
	v_accvgpr_read_b32 v1, a135
	v_accvgpr_read_b32 v2, a136
	v_accvgpr_read_b32 v3, a137
.Ltmp239:
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[0:1], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[0:3], a[4:7], v[162:165], v[0:3]
	v_mfma_f32_16x16x32_bf16 v[66:69], a[16:19], v[34:37], v[0:3]
	s_nop 6
	v_accvgpr_read_b32 v0, a130
	v_accvgpr_read_b32 v1, a131
	v_accvgpr_read_b32 v2, a132
	v_accvgpr_read_b32 v3, a133
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[0:1], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[0:3], v[14:17], v[162:165], v[0:3]
	v_mfma_f32_16x16x32_bf16 v[28:31], v[18:21], v[34:37], v[0:3]
	s_nop 6
	v_accvgpr_read_b32 v0, a122
	v_accvgpr_read_b32 v1, a123
	v_accvgpr_read_b32 v2, a124
	v_accvgpr_read_b32 v3, a125
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[0:1], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[0:3], v[22:25], v[162:165], v[0:3]
	v_mfma_f32_16x16x32_bf16 v[24:27], v[186:189], v[34:37], v[0:3]
	s_nop 6
	v_accvgpr_read_b32 v0, a118
	v_accvgpr_read_b32 v1, a119
	v_accvgpr_read_b32 v2, a120
	v_accvgpr_read_b32 v3, a121
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[0:1], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[0:3], v[190:193], v[162:165], v[0:3]
	v_mfma_f32_16x16x32_bf16 v[20:23], v[194:197], v[34:37], v[0:3]
	s_nop 6
	v_accvgpr_read_b32 v0, a114
	v_accvgpr_read_b32 v1, a115
	v_accvgpr_read_b32 v2, a116
	v_accvgpr_read_b32 v3, a117
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[0:1], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[0:3], a[8:11], v[162:165], v[0:3]
	v_mfma_f32_16x16x32_bf16 v[16:19], a[20:23], v[34:37], v[0:3]
	s_nop 6
	v_mul_f32_e64 v2, v64, v32
	v_mul_f32_e64 v3, v65, v32
	v_pk_mul_f32 v[0:1], v[62:63], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[0:3], v[10:13], v[162:165], v[0:3]
	v_mfma_f32_16x16x32_bf16 v[12:15], v[166:169], v[34:37], v[0:3]
.Ltmp240:
	v_add_f32_e32 v166, v4, v6
.Ltmp241:
	v_mov_b32_e32 v4, v5
	s_nop 1
	v_permlane32_swap_b32_e32 v5, v4
.Ltmp242:
	s_nop 1
	v_pk_mul_f32 v[2:3], v[60:61], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[58:59], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[0:3], v[170:173], v[162:165], v[0:3]
	v_mfma_f32_16x16x32_bf16 v[8:11], v[174:177], v[34:37], v[0:3]
	s_nop 6
	v_mul_f32_e64 v2, v56, v32
	v_mul_f32_e64 v3, v57, v32
	v_pk_mul_f32 v[0:1], v[54:55], v[32:33] op_sel_hi:[1,0]
.Ltmp243:
	v_add_f32_e32 v33, v5, v4
.Ltmp244:
	v_mov_b32_e32 v38, v33
.Ltmp245:
	v_mfma_f32_16x16x32_bf16 v[0:3], v[178:181], v[162:165], v[0:3]
.Ltmp246:
	s_nop 0
	v_permlane16_swap_b32_e32 v33, v38
.Ltmp247:
	v_add_f32_e32 v48, v33, v38
	v_accvgpr_read_b32 v38, a112
	v_accvgpr_read_b32 v39, a113
.Ltmp248:
	v_mfma_f32_16x16x32_bf16 v[4:7], v[182:185], v[34:37], v[0:3]
	v_fmac_f32_e32 v48, v39, v32
	v_fmac_f32_e32 v166, v38, v230
	s_nop 0
	v_pk_mul_f32 v[2:3], v[52:53], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[50:51], v[32:33] op_sel_hi:[1,0]
	v_mul_u32_u24_e32 v32, 0x1800, v226
	v_add_u32_e32 v32, s89, v32
	v_add_u32_e32 v50, 0x100, v32
	v_or_b32_e32 v47, v32, v49
	v_or_b32_e32 v39, v50, v49
	v_div_scale_f32 v49, s[0:1], v166, v166, v158
	v_mfma_f32_16x16x32_bf16 v[0:3], a[12:15], v[162:165], v[0:3]
	v_rcp_f32_e32 v51, v49
	v_or_b32_e32 v46, v32, v224
	v_or_b32_e32 v45, v32, v223
	v_mfma_f32_16x16x32_bf16 v[0:3], a[24:27], v[34:37], v[0:3]
	v_or_b32_e32 v44, v32, v222
	v_or_b32_e32 v43, v32, v221
	v_or_b32_e32 v42, v32, v220
	v_or_b32_e32 v41, v32, v219
	v_or_b32_e32 v40, v32, v218
	v_or_b32_e32 v38, v50, v224
	v_or_b32_e32 v37, v50, v223
	v_or_b32_e32 v36, v50, v222
	v_or_b32_e32 v35, v50, v221
	v_or_b32_e32 v34, v50, v220
	v_or_b32_e32 v33, v50, v219
	v_or_b32_e32 v32, v50, v218
	v_fma_f32 v50, -v49, v51, 1.0
	v_fmac_f32_e32 v51, v50, v51
	v_div_scale_f32 v50, vcc, v158, v166, v158
	v_mul_f32_e32 v52, v50, v51
	v_fma_f32 v53, -v49, v52, v50
	v_fmac_f32_e32 v52, v53, v51
	v_fma_f32 v49, -v49, v52, v50
	v_div_scale_f32 v50, s[0:1], v166, v166, v159
	v_rcp_f32_e32 v53, v50
	v_div_fmas_f32 v49, v49, v51, v52
	v_div_fixup_f32 v49, v49, v166, v158
	v_add_lshl_u32 v47, v47, s88, 1
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
	v_cndmask_b32_e64 v47, v235, v47, s[44:45]
	v_fma_f32 v52, -v51, v54, 1.0
	v_fmac_f32_e32 v54, v52, v54
	v_div_scale_f32 v52, vcc, v160, v166, v160
	v_mul_f32_e32 v53, v52, v54
	v_fma_f32 v55, -v51, v53, v52
	v_fmac_f32_e32 v53, v55, v54
	v_fma_f32 v51, -v51, v53, v52
	v_div_scale_f32 v52, s[0:1], v166, v166, v161
	v_rcp_f32_e32 v55, v52
	v_div_fmas_f32 v51, v51, v54, v53
	v_div_fixup_f32 v51, v51, v166, v160
	v_fma_f32 v53, -v52, v55, 1.0
	v_fmac_f32_e32 v55, v53, v55
	v_div_scale_f32 v53, vcc, v161, v166, v161
	v_mul_f32_e32 v54, v53, v55
	v_fma_f32 v56, -v52, v54, v53
	v_fmac_f32_e32 v54, v56, v55
	v_fma_f32 v52, -v52, v54, v53
	v_div_scale_f32 v53, s[0:1], v166, v166, v154
	v_rcp_f32_e32 v56, v53
	v_div_fmas_f32 v52, v52, v55, v54
	v_div_fixup_f32 v52, v52, v166, v161
	v_fma_f32 v54, -v53, v56, 1.0
	v_fmac_f32_e32 v56, v54, v56
	v_div_scale_f32 v54, vcc, v154, v166, v154
	v_mul_f32_e32 v55, v54, v56
	v_fma_f32 v57, -v53, v55, v54
	v_fmac_f32_e32 v55, v57, v56
	v_fma_f32 v53, -v53, v55, v54
	v_div_scale_f32 v54, s[0:1], v166, v166, v155
	v_rcp_f32_e32 v57, v54
	v_div_fmas_f32 v53, v53, v56, v55
	v_div_fixup_f32 v53, v53, v166, v154
	v_fma_f32 v55, -v54, v57, 1.0
	v_fmac_f32_e32 v57, v55, v57
	v_div_scale_f32 v55, vcc, v155, v166, v155
	v_mul_f32_e32 v56, v55, v57
	v_fma_f32 v58, -v54, v56, v55
	v_fmac_f32_e32 v56, v58, v57
	v_fma_f32 v54, -v54, v56, v55
	v_div_scale_f32 v55, s[0:1], v166, v166, v156
	v_rcp_f32_e32 v58, v55
	v_div_fmas_f32 v54, v54, v57, v56
	v_div_fixup_f32 v54, v54, v166, v155
	v_fma_f32 v56, -v55, v58, 1.0
	v_fmac_f32_e32 v58, v56, v58
	v_div_scale_f32 v56, vcc, v156, v166, v156
	v_mul_f32_e32 v57, v56, v58
	v_fma_f32 v59, -v55, v57, v56
	v_fmac_f32_e32 v57, v59, v58
	v_fma_f32 v55, -v55, v57, v56
	v_div_scale_f32 v56, s[0:1], v166, v166, v157
	v_rcp_f32_e32 v59, v56
	v_div_fmas_f32 v55, v55, v58, v57
	v_div_fixup_f32 v55, v55, v166, v156
	v_fma_f32 v57, -v56, v59, 1.0
	v_fmac_f32_e32 v59, v57, v59
	v_div_scale_f32 v57, vcc, v157, v166, v157
	v_mul_f32_e32 v58, v57, v59
	v_fma_f32 v60, -v56, v58, v57
	v_fmac_f32_e32 v58, v60, v59
	v_fma_f32 v56, -v56, v58, v57
	v_div_scale_f32 v57, s[0:1], v166, v166, v150
	v_rcp_f32_e32 v60, v57
	v_div_fmas_f32 v56, v56, v59, v58
	v_div_fixup_f32 v56, v56, v166, v157
	v_fma_f32 v58, -v57, v60, 1.0
	v_fmac_f32_e32 v60, v58, v60
	v_div_scale_f32 v58, vcc, v150, v166, v150
	v_mul_f32_e32 v59, v58, v60
	v_fma_f32 v61, -v57, v59, v58
	v_fmac_f32_e32 v59, v61, v60
	v_fma_f32 v57, -v57, v59, v58
	v_div_scale_f32 v58, s[0:1], v166, v166, v151
	v_rcp_f32_e32 v61, v58
	v_div_fmas_f32 v57, v57, v60, v59
	v_div_fixup_f32 v57, v57, v166, v150
	v_fma_f32 v59, -v58, v61, 1.0
	v_fmac_f32_e32 v61, v59, v61
	v_div_scale_f32 v59, vcc, v151, v166, v151
	v_mul_f32_e32 v60, v59, v61
	v_fma_f32 v62, -v58, v60, v59
	v_fmac_f32_e32 v60, v62, v61
	v_fma_f32 v58, -v58, v60, v59
	v_div_scale_f32 v59, s[0:1], v166, v166, v152
	v_rcp_f32_e32 v62, v59
	v_div_fmas_f32 v58, v58, v61, v60
	v_div_fixup_f32 v58, v58, v166, v151
	v_fma_f32 v60, -v59, v62, 1.0
	v_fmac_f32_e32 v62, v60, v62
	v_div_scale_f32 v60, vcc, v152, v166, v152
	v_mul_f32_e32 v61, v60, v62
	v_fma_f32 v63, -v59, v61, v60
	v_fmac_f32_e32 v61, v63, v62
	v_fma_f32 v59, -v59, v61, v60
	v_div_scale_f32 v60, s[0:1], v166, v166, v153
	v_rcp_f32_e32 v63, v60
	v_div_fmas_f32 v59, v59, v62, v61
	v_div_fixup_f32 v59, v59, v166, v152
	v_fma_f32 v61, -v60, v63, 1.0
	v_fmac_f32_e32 v63, v61, v63
	v_div_scale_f32 v61, vcc, v153, v166, v153
	v_mul_f32_e32 v62, v61, v63
	v_fma_f32 v64, -v60, v62, v61
	v_fmac_f32_e32 v62, v64, v63
	v_fma_f32 v60, -v60, v62, v61
	v_div_scale_f32 v61, s[0:1], v166, v166, v146
	v_rcp_f32_e32 v64, v61
	v_div_fmas_f32 v60, v60, v63, v62
	v_div_fixup_f32 v60, v60, v166, v153
	v_fma_f32 v62, -v61, v64, 1.0
	v_fmac_f32_e32 v64, v62, v64
	v_div_scale_f32 v62, vcc, v146, v166, v146
	v_mul_f32_e32 v63, v62, v64
	v_fma_f32 v65, -v61, v63, v62
	v_fmac_f32_e32 v63, v65, v64
	v_fma_f32 v61, -v61, v63, v62
	v_div_scale_f32 v62, s[0:1], v166, v166, v147
	v_rcp_f32_e32 v65, v62
	v_div_fmas_f32 v61, v61, v64, v63
	v_div_fixup_f32 v61, v61, v166, v146
	v_fma_f32 v63, -v62, v65, 1.0
	v_fmac_f32_e32 v65, v63, v65
	v_div_scale_f32 v63, vcc, v147, v166, v147
	v_mul_f32_e32 v64, v63, v65
	v_fma_f32 v146, -v62, v64, v63
	v_fmac_f32_e32 v64, v146, v65
	v_fma_f32 v62, -v62, v64, v63
	v_div_scale_f32 v63, s[0:1], v166, v166, v148
	v_rcp_f32_e32 v146, v63
	v_div_fmas_f32 v62, v62, v65, v64
	v_div_fixup_f32 v62, v62, v166, v147
	v_fma_f32 v64, -v63, v146, 1.0
	v_fmac_f32_e32 v146, v64, v146
	v_div_scale_f32 v64, vcc, v148, v166, v148
	v_mul_f32_e32 v65, v64, v146
	v_fma_f32 v147, -v63, v65, v64
	v_fmac_f32_e32 v65, v147, v146
	v_fma_f32 v63, -v63, v65, v64
	v_div_scale_f32 v64, s[0:1], v166, v166, v149
	v_rcp_f32_e32 v147, v64
	v_div_fmas_f32 v63, v63, v146, v65
	v_div_fixup_f32 v63, v63, v166, v148
	v_fma_f32 v65, -v64, v147, 1.0
	v_fmac_f32_e32 v147, v65, v147
	v_div_scale_f32 v65, vcc, v149, v166, v149
	v_mul_f32_e32 v146, v65, v147
	v_fma_f32 v148, -v64, v146, v65
	v_fmac_f32_e32 v146, v148, v147
	v_fma_f32 v64, -v64, v146, v65
	v_div_scale_f32 v65, s[0:1], v166, v166, v142
	v_rcp_f32_e32 v148, v65
	v_div_fmas_f32 v64, v64, v147, v146
	v_div_fixup_f32 v64, v64, v166, v149
	v_fma_f32 v146, -v65, v148, 1.0
	v_fmac_f32_e32 v148, v146, v148
	v_div_scale_f32 v146, vcc, v142, v166, v142
	v_mul_f32_e32 v147, v146, v148
	v_fma_f32 v149, -v65, v147, v146
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v65, -v65, v147, v146
	v_div_scale_f32 v146, s[0:1], v166, v166, v143
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v65, v65, v148, v147
	v_div_fixup_f32 v65, v65, v166, v142
	v_fma_f32 v142, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v142, v149
	v_div_scale_f32 v142, vcc, v143, v166, v143
	v_mul_f32_e32 v147, v142, v149
	v_fma_f32 v148, -v146, v147, v142
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v142, -v146, v147, v142
	v_div_scale_f32 v146, s[0:1], v166, v166, v144
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v142, v142, v149, v147
	v_div_fixup_f32 v142, v142, v166, v143
	v_fma_f32 v143, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v143, v148
	v_div_scale_f32 v143, vcc, v144, v166, v144
	v_mul_f32_e32 v147, v143, v148
	v_fma_f32 v149, -v146, v147, v143
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v143, -v146, v147, v143
	v_div_scale_f32 v146, s[0:1], v166, v166, v145
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v143, v143, v148, v147
	v_div_fixup_f32 v143, v143, v166, v144
	v_fma_f32 v144, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v144, v149
	v_div_scale_f32 v144, vcc, v145, v166, v145
	v_mul_f32_e32 v147, v144, v149
	v_fma_f32 v148, -v146, v147, v144
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v144, -v146, v147, v144
	v_div_scale_f32 v146, s[0:1], v166, v166, v138
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v144, v144, v149, v147
	v_div_fixup_f32 v144, v144, v166, v145
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v138, v166, v138
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v139
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v138, v145, v166, v138
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v139, v166, v139
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v140
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v139, v145, v166, v139
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v140, v166, v140
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v141
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v140, v145, v166, v140
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v141, v166, v141
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v134
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v141, v145, v166, v141
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v134, v166, v134
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v135
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v134, v145, v166, v134
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v135, v166, v135
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v136
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v135, v145, v166, v135
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v136, v166, v136
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v137
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v136, v145, v166, v136
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v137, v166, v137
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v130
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v137, v145, v166, v137
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v130, v166, v130
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v131
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v130, v145, v166, v130
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v131, v166, v131
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v132
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v131, v145, v166, v131
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v132, v166, v132
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v133
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v132, v145, v166, v132
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v133, v166, v133
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v126
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v133, v145, v166, v133
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v126, v166, v126
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v127
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v126, v145, v166, v126
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v127, v166, v127
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v128
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v127, v145, v166, v127
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v128, v166, v128
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v129
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v128, v145, v166, v128
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v129, v166, v129
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v122
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v129, v145, v166, v129
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v122, v166, v122
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v123
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v122, v145, v166, v122
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v123, v166, v123
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v124
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v123, v145, v166, v123
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v124, v166, v124
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v125
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v124, v145, v166, v124
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v125, v166, v125
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v118
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v125, v145, v166, v125
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v118, v166, v118
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v119
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v118, v145, v166, v118
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v119, v166, v119
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v120
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v119, v145, v166, v119
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v120, v166, v120
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v121
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v120, v145, v166, v120
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v121, v166, v121
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v114
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v121, v145, v166, v121
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v114, v166, v114
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v115
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v114, v145, v166, v114
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v115, v166, v115
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v116
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v115, v145, v166, v115
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v116, v166, v116
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v117
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v116, v145, v166, v116
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v117, v166, v117
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v110
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v117, v145, v166, v117
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v110, v166, v110
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v111
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v110, v145, v166, v110
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v111, v166, v111
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v112
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v111, v145, v166, v111
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v112, v166, v112
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v113
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v112, v145, v166, v112
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v113, v166, v113
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v106
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v113, v145, v166, v113
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v106, v166, v106
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v107
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v106, v145, v166, v106
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v107, v166, v107
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v108
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v107, v145, v166, v107
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v108, v166, v108
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v109
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v108, v145, v166, v108
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v109, v166, v109
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v102
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v109, v145, v166, v109
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v102, v166, v102
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v103
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v102, v145, v166, v102
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v103, v166, v103
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v104
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v103, v145, v166, v103
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v104, v166, v104
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v105
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v104, v145, v166, v104
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v105, v166, v105
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v98
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v105, v145, v166, v105
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v98, v166, v98
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v99
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v98, v145, v166, v98
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v99, v166, v99
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v100
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v99, v145, v166, v99
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v100, v166, v100
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v166, v166, v101
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v100, v145, v166, v100
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v101, v166, v101
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v94
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v101, v145, v166, v101
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v94, v48, v94
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v95
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v94, v145, v48, v94
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v95, v48, v95
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v96
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v95, v145, v48, v95
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v96, v48, v96
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v97
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v96, v145, v48, v96
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v97, v48, v97
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v90
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v97, v145, v48, v97
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v90, v48, v90
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v91
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v90, v145, v48, v90
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v91, v48, v91
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v92
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v91, v145, v48, v91
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v92, v48, v92
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v93
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v92, v145, v48, v92
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v93, v48, v93
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v86
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v93, v145, v48, v93
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v86, v48, v86
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v87
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v86, v145, v48, v86
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v87, v48, v87
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v88
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v87, v145, v48, v87
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v88, v48, v88
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v89
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v88, v145, v48, v88
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v89, v48, v89
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v82
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v89, v145, v48, v89
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v82, v48, v82
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v83
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v82, v145, v48, v82
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v83, v48, v83
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v84
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v83, v145, v48, v83
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v84, v48, v84
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v85
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v84, v145, v48, v84
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v85, v48, v85
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v78
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v85, v145, v48, v85
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v78, v48, v78
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v79
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v78, v145, v48, v78
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v79, v48, v79
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v80
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v79, v145, v48, v79
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v80, v48, v80
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v81
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v80, v145, v48, v80
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v81, v48, v81
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v74
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v81, v145, v48, v81
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v74, v48, v74
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v75
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v74, v145, v48, v74
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v75, v48, v75
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v76
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v75, v145, v48, v75
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v76, v48, v76
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v77
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v76, v145, v48, v76
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v77, v48, v77
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v70
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v77, v145, v48, v77
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v70, v48, v70
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v71
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v70, v145, v48, v70
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v71, v48, v71
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v72
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v71, v145, v48, v71
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v72, v48, v72
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v73
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v72, v145, v48, v72
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v73, v48, v73
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v66
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v73, v145, v48, v73
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v66, v48, v66
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v67
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v66, v145, v48, v66
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v67, v48, v67
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v68
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v67, v145, v48, v67
	v_cvt_pk_bf16_f32 v66, v66, v67
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v68, v48, v68
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v69
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v68, v145, v48, v68
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v69, v48, v69
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v28
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v69, v145, v48, v69
	v_cvt_pk_bf16_f32 v67, v68, v69
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v28, v48, v28
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v29
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v28, v145, v48, v28
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v29, v48, v29
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v30
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v29, v145, v48, v29
	v_cvt_pk_bf16_f32 v28, v28, v29
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v30, v48, v30
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v31
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v30, v145, v48, v30
	v_fma_f32 v145, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v145, v149
	v_div_scale_f32 v145, vcc, v31, v48, v31
	v_mul_f32_e32 v147, v145, v149
	v_fma_f32 v148, -v146, v147, v145
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v24
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v145, v145, v149, v147
	v_div_fixup_f32 v31, v145, v48, v31
	v_cvt_pk_bf16_f32 v29, v30, v31
	v_fma_f32 v145, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v145, v148
	v_div_scale_f32 v145, vcc, v24, v48, v24
	v_mul_f32_e32 v147, v145, v148
	v_fma_f32 v149, -v146, v147, v145
	v_fmac_f32_e32 v147, v149, v148
	v_fma_f32 v145, -v146, v147, v145
	v_div_scale_f32 v146, s[0:1], v48, v48, v25
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v145, v145, v148, v147
	v_div_fixup_f32 v145, v145, v48, v24
	v_fma_f32 v24, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v24, v149
	v_div_scale_f32 v24, vcc, v25, v48, v25
	v_mul_f32_e32 v147, v24, v149
	v_fma_f32 v148, -v146, v147, v24
	v_fmac_f32_e32 v147, v148, v149
	v_fma_f32 v24, -v146, v147, v24
	v_div_scale_f32 v146, s[0:1], v48, v48, v26
	v_rcp_f32_e32 v148, v146
	v_div_fmas_f32 v24, v24, v149, v147
	v_div_fixup_f32 v147, v24, v48, v25
	v_cvt_pk_bf16_f32 v30, v145, v147
	v_fma_f32 v24, -v146, v148, 1.0
	v_fmac_f32_e32 v148, v24, v148
	v_div_scale_f32 v24, vcc, v26, v48, v26
	v_mul_f32_e32 v25, v24, v148
	v_fma_f32 v149, -v146, v25, v24
	v_fmac_f32_e32 v25, v149, v148
	v_fma_f32 v24, -v146, v25, v24
	v_div_scale_f32 v146, s[0:1], v48, v48, v27
	v_rcp_f32_e32 v149, v146
	v_div_fmas_f32 v24, v24, v148, v25
	v_div_fixup_f32 v148, v24, v48, v26
	v_permlane16_swap_b32_e32 v28, v30
	v_fma_f32 v24, -v146, v149, 1.0
	v_fmac_f32_e32 v149, v24, v149
	v_div_scale_f32 v24, vcc, v27, v48, v27
	v_mul_f32_e32 v25, v24, v149
	v_fma_f32 v26, -v146, v25, v24
	v_fmac_f32_e32 v25, v26, v149
	v_div_scale_f32 v26, s[0:1], v48, v48, v20
	v_fma_f32 v24, -v146, v25, v24
	v_rcp_f32_e32 v146, v26
	v_div_fmas_f32 v24, v24, v149, v25
	v_div_fixup_f32 v149, v24, v48, v27
	v_cvt_pk_bf16_f32 v31, v148, v149
	v_fma_f32 v24, -v26, v146, 1.0
	v_fmac_f32_e32 v146, v24, v146
	v_div_scale_f32 v24, vcc, v20, v48, v20
	v_mul_f32_e32 v25, v24, v146
	v_fma_f32 v27, -v26, v25, v24
	v_fmac_f32_e32 v25, v27, v146
	v_fma_f32 v24, -v26, v25, v24
	v_div_scale_f32 v26, s[0:1], v48, v48, v21
	v_rcp_f32_e32 v27, v26
	v_div_fmas_f32 v24, v24, v146, v25
	v_div_fixup_f32 v146, v24, v48, v20
	v_permlane16_swap_b32_e32 v29, v31
	v_fma_f32 v20, -v26, v27, 1.0
	v_fmac_f32_e32 v27, v20, v27
	v_div_scale_f32 v20, vcc, v21, v48, v21
	v_mul_f32_e32 v24, v20, v27
	v_fma_f32 v25, -v26, v24, v20
	v_fmac_f32_e32 v24, v25, v27
	v_div_scale_f32 v25, s[0:1], v48, v48, v22
	v_fma_f32 v20, -v26, v24, v20
	v_rcp_f32_e32 v26, v25
	v_div_fmas_f32 v20, v20, v27, v24
	v_div_fixup_f32 v150, v20, v48, v21
	v_cvt_pk_bf16_f32 v27, v108, v109
	v_fma_f32 v20, -v25, v26, 1.0
	v_fmac_f32_e32 v26, v20, v26
	v_div_scale_f32 v20, vcc, v22, v48, v22
	v_mul_f32_e32 v21, v20, v26
	v_fma_f32 v24, -v25, v21, v20
	v_fmac_f32_e32 v21, v24, v26
	v_div_scale_f32 v24, s[0:1], v48, v48, v23
	v_fma_f32 v20, -v25, v21, v20
	v_rcp_f32_e32 v25, v24
	v_div_fmas_f32 v20, v20, v26, v21
	v_div_fixup_f32 v151, v20, v48, v22
	v_cvt_pk_bf16_f32 v26, v106, v107
	v_fma_f32 v20, -v24, v25, 1.0
	v_fmac_f32_e32 v25, v20, v25
	v_div_scale_f32 v20, vcc, v23, v48, v23
	v_mul_f32_e32 v21, v20, v25
	v_fma_f32 v22, -v24, v21, v20
	v_fmac_f32_e32 v21, v22, v25
	v_div_scale_f32 v22, s[0:1], v48, v48, v16
	v_fma_f32 v20, -v24, v21, v20
	v_rcp_f32_e32 v24, v22
	v_div_fmas_f32 v20, v20, v25, v21
	v_div_fixup_f32 v152, v20, v48, v23
	v_cvt_pk_bf16_f32 v25, v112, v113
	v_fma_f32 v20, -v22, v24, 1.0
	v_fmac_f32_e32 v24, v20, v24
	v_div_scale_f32 v20, vcc, v16, v48, v16
	v_mul_f32_e32 v21, v20, v24
	v_fma_f32 v23, -v22, v21, v20
	v_fmac_f32_e32 v21, v23, v24
	v_fma_f32 v20, -v22, v21, v20
	v_div_scale_f32 v22, s[0:1], v48, v48, v17
	v_rcp_f32_e32 v23, v22
	v_div_fmas_f32 v20, v20, v24, v21
	v_div_fixup_f32 v153, v20, v48, v16
	v_cvt_pk_bf16_f32 v24, v110, v111
	v_fma_f32 v16, -v22, v23, 1.0
	v_fmac_f32_e32 v23, v16, v23
	v_div_scale_f32 v16, vcc, v17, v48, v17
	v_mul_f32_e32 v20, v16, v23
	v_fma_f32 v21, -v22, v20, v16
	v_fmac_f32_e32 v20, v21, v23
	v_div_scale_f32 v21, s[0:1], v48, v48, v18
	v_fma_f32 v16, -v22, v20, v16
	v_rcp_f32_e32 v22, v21
	v_div_fmas_f32 v16, v16, v23, v20
	v_div_fixup_f32 v154, v16, v48, v17
	v_cvt_pk_bf16_f32 v23, v116, v117
	v_fma_f32 v16, -v21, v22, 1.0
	v_fmac_f32_e32 v22, v16, v22
	v_div_scale_f32 v16, vcc, v18, v48, v18
	v_mul_f32_e32 v17, v16, v22
	v_fma_f32 v20, -v21, v17, v16
	v_fmac_f32_e32 v17, v20, v22
	v_div_scale_f32 v20, s[0:1], v48, v48, v19
	v_fma_f32 v16, -v21, v17, v16
	v_rcp_f32_e32 v21, v20
	v_div_fmas_f32 v16, v16, v22, v17
	v_div_fixup_f32 v155, v16, v48, v18
	v_cvt_pk_bf16_f32 v22, v114, v115
	v_fma_f32 v16, -v20, v21, 1.0
	v_fmac_f32_e32 v21, v16, v21
	v_div_scale_f32 v16, vcc, v19, v48, v19
	v_mul_f32_e32 v17, v16, v21
	v_fma_f32 v18, -v20, v17, v16
	v_fmac_f32_e32 v17, v18, v21
	v_div_scale_f32 v18, s[0:1], v48, v48, v12
	v_fma_f32 v16, -v20, v17, v16
	v_rcp_f32_e32 v20, v18
	v_div_fmas_f32 v16, v16, v21, v17
	v_div_fixup_f32 v156, v16, v48, v19
	v_cvt_pk_bf16_f32 v21, v120, v121
	v_fma_f32 v16, -v18, v20, 1.0
	v_fmac_f32_e32 v20, v16, v20
	v_div_scale_f32 v16, vcc, v12, v48, v12
	v_mul_f32_e32 v17, v16, v20
	v_fma_f32 v19, -v18, v17, v16
	v_fmac_f32_e32 v17, v19, v20
	v_fma_f32 v16, -v18, v17, v16
	v_div_scale_f32 v18, s[0:1], v48, v48, v13
	v_rcp_f32_e32 v19, v18
	v_div_fmas_f32 v16, v16, v20, v17
	v_div_fixup_f32 v157, v16, v48, v12
	v_cvt_pk_bf16_f32 v20, v118, v119
	v_fma_f32 v12, -v18, v19, 1.0
	v_fmac_f32_e32 v19, v12, v19
	v_div_scale_f32 v12, vcc, v13, v48, v13
	v_mul_f32_e32 v16, v12, v19
	v_fma_f32 v17, -v18, v16, v12
	v_fmac_f32_e32 v16, v17, v19
	v_div_scale_f32 v17, s[0:1], v48, v48, v14
	v_fma_f32 v12, -v18, v16, v12
	v_rcp_f32_e32 v18, v17
	v_div_fmas_f32 v12, v12, v19, v16
	v_div_fixup_f32 v158, v12, v48, v13
	v_cvt_pk_bf16_f32 v19, v124, v125
	v_fma_f32 v12, -v17, v18, 1.0
	v_fmac_f32_e32 v18, v12, v18
	v_div_scale_f32 v12, vcc, v14, v48, v14
	v_mul_f32_e32 v13, v12, v18
	v_fma_f32 v16, -v17, v13, v12
	v_fmac_f32_e32 v13, v16, v18
	v_div_scale_f32 v16, s[0:1], v48, v48, v15
	v_fma_f32 v12, -v17, v13, v12
	v_rcp_f32_e32 v17, v16
	v_div_fmas_f32 v12, v12, v18, v13
	v_div_fixup_f32 v159, v12, v48, v14
	v_cvt_pk_bf16_f32 v18, v122, v123
	v_fma_f32 v12, -v16, v17, 1.0
	v_fmac_f32_e32 v17, v12, v17
	v_div_scale_f32 v12, vcc, v15, v48, v15
	v_mul_f32_e32 v13, v12, v17
	v_fma_f32 v14, -v16, v13, v12
	v_fmac_f32_e32 v13, v14, v17
	v_div_scale_f32 v14, s[0:1], v48, v48, v8
	v_fma_f32 v12, -v16, v13, v12
	v_rcp_f32_e32 v16, v14
	v_div_fmas_f32 v12, v12, v17, v13
	v_div_fixup_f32 v160, v12, v48, v15
	v_cvt_pk_bf16_f32 v17, v128, v129
	v_fma_f32 v12, -v14, v16, 1.0
	v_fmac_f32_e32 v16, v12, v16
	v_div_scale_f32 v12, vcc, v8, v48, v8
	v_mul_f32_e32 v13, v12, v16
	v_fma_f32 v15, -v14, v13, v12
	v_fmac_f32_e32 v13, v15, v16
	v_fma_f32 v12, -v14, v13, v12
	v_div_scale_f32 v14, s[0:1], v48, v48, v9
	v_rcp_f32_e32 v15, v14
	v_div_fmas_f32 v12, v12, v16, v13
	v_div_fixup_f32 v161, v12, v48, v8
	v_cvt_pk_bf16_f32 v16, v126, v127
	v_fma_f32 v8, -v14, v15, 1.0
	v_fmac_f32_e32 v15, v8, v15
	v_div_scale_f32 v8, vcc, v9, v48, v9
	v_mul_f32_e32 v12, v8, v15
	v_fma_f32 v13, -v14, v12, v8
	v_fmac_f32_e32 v12, v13, v15
	v_div_scale_f32 v13, s[0:1], v48, v48, v10
	v_fma_f32 v8, -v14, v12, v8
	v_rcp_f32_e32 v14, v13
	v_div_fmas_f32 v8, v8, v15, v12
	v_div_fixup_f32 v162, v8, v48, v9
	v_cvt_pk_bf16_f32 v15, v132, v133
	v_fma_f32 v8, -v13, v14, 1.0
	v_fmac_f32_e32 v14, v8, v14
	v_div_scale_f32 v8, vcc, v10, v48, v10
	v_mul_f32_e32 v9, v8, v14
	v_fma_f32 v12, -v13, v9, v8
	v_fmac_f32_e32 v9, v12, v14
	v_div_scale_f32 v12, s[0:1], v48, v48, v11
	v_fma_f32 v8, -v13, v9, v8
	v_rcp_f32_e32 v13, v12
	v_div_fmas_f32 v8, v8, v14, v9
	v_div_fixup_f32 v163, v8, v48, v10
	v_cvt_pk_bf16_f32 v14, v130, v131
	v_fma_f32 v8, -v12, v13, 1.0
	v_fmac_f32_e32 v13, v8, v13
	v_div_scale_f32 v8, vcc, v11, v48, v11
	v_mul_f32_e32 v9, v8, v13
	v_fma_f32 v10, -v12, v9, v8
	v_fmac_f32_e32 v9, v10, v13
	v_div_scale_f32 v10, s[0:1], v48, v48, v4
	v_fma_f32 v8, -v12, v9, v8
	v_rcp_f32_e32 v12, v10
	v_div_fmas_f32 v8, v8, v13, v9
	v_div_fixup_f32 v164, v8, v48, v11
	v_cvt_pk_bf16_f32 v13, v136, v137
	v_fma_f32 v8, -v10, v12, 1.0
	v_fmac_f32_e32 v12, v8, v12
	v_div_scale_f32 v8, vcc, v4, v48, v4
	v_mul_f32_e32 v9, v8, v12
	v_fma_f32 v11, -v10, v9, v8
	v_fmac_f32_e32 v9, v11, v12
	v_fma_f32 v8, -v10, v9, v8
	v_div_scale_f32 v10, s[0:1], v48, v48, v5
	v_rcp_f32_e32 v11, v10
	v_div_fmas_f32 v8, v8, v12, v9
	v_div_fixup_f32 v165, v8, v48, v4
	v_cvt_pk_bf16_f32 v12, v134, v135
	v_fma_f32 v4, -v10, v11, 1.0
	v_fmac_f32_e32 v11, v4, v11
	v_div_scale_f32 v4, vcc, v5, v48, v5
	v_mul_f32_e32 v8, v4, v11
	v_fma_f32 v9, -v10, v8, v4
	v_fmac_f32_e32 v8, v9, v11
	v_div_scale_f32 v9, s[0:1], v48, v48, v6
	v_fma_f32 v4, -v10, v8, v4
	v_rcp_f32_e32 v10, v9
	v_div_fmas_f32 v4, v4, v11, v8
	v_div_fixup_f32 v166, v4, v48, v5
	v_cvt_pk_bf16_f32 v11, v140, v141
	v_fma_f32 v4, -v9, v10, 1.0
	v_fmac_f32_e32 v10, v4, v10
	v_div_scale_f32 v4, vcc, v6, v48, v6
	v_mul_f32_e32 v5, v4, v10
	v_fma_f32 v8, -v9, v5, v4
	v_fmac_f32_e32 v5, v8, v10
	v_div_scale_f32 v8, s[0:1], v48, v48, v7
	v_fma_f32 v4, -v9, v5, v4
	v_rcp_f32_e32 v9, v8
	v_div_fmas_f32 v4, v4, v10, v5
	v_div_fixup_f32 v167, v4, v48, v6
	v_cvt_pk_bf16_f32 v10, v138, v139
	v_fma_f32 v4, -v8, v9, 1.0
	v_fmac_f32_e32 v9, v4, v9
	v_div_scale_f32 v4, vcc, v7, v48, v7
	v_mul_f32_e32 v5, v4, v9
	v_fma_f32 v6, -v8, v5, v4
	v_fmac_f32_e32 v5, v6, v9
	v_div_scale_f32 v6, s[0:1], v48, v48, v0
	v_fma_f32 v4, -v8, v5, v4
	v_rcp_f32_e32 v8, v6
	v_div_fmas_f32 v4, v4, v9, v5
	v_div_fixup_f32 v168, v4, v48, v7
	v_cvt_pk_bf16_f32 v9, v143, v144
	v_fma_f32 v4, -v6, v8, 1.0
	v_fmac_f32_e32 v8, v4, v8
	v_div_scale_f32 v4, vcc, v0, v48, v0
	v_mul_f32_e32 v5, v4, v8
	v_fma_f32 v7, -v6, v5, v4
	v_fmac_f32_e32 v5, v7, v8
	v_fma_f32 v4, -v6, v5, v4
	v_div_scale_f32 v6, s[0:1], v48, v48, v1
	v_rcp_f32_e32 v7, v6
	v_div_fmas_f32 v4, v4, v8, v5
	v_div_fixup_f32 v169, v4, v48, v0
	v_cvt_pk_bf16_f32 v8, v65, v142
	v_fma_f32 v0, -v6, v7, 1.0
	v_fmac_f32_e32 v7, v0, v7
	v_div_scale_f32 v0, vcc, v1, v48, v1
	v_mul_f32_e32 v4, v0, v7
	v_fma_f32 v5, -v6, v4, v0
	v_fmac_f32_e32 v4, v5, v7
	v_div_scale_f32 v5, s[0:1], v48, v48, v2
	v_fma_f32 v0, -v6, v4, v0
	v_rcp_f32_e32 v6, v5
	v_div_fmas_f32 v0, v0, v7, v4
	v_div_fixup_f32 v170, v0, v48, v1
	v_cvt_pk_bf16_f32 v7, v63, v64
	v_fma_f32 v0, -v5, v6, 1.0
	v_fmac_f32_e32 v6, v0, v6
	v_div_scale_f32 v0, vcc, v2, v48, v2
	v_mul_f32_e32 v1, v0, v6
	v_fma_f32 v4, -v5, v1, v0
	v_fmac_f32_e32 v1, v4, v6
	v_div_scale_f32 v4, s[0:1], v48, v48, v3
	v_fma_f32 v0, -v5, v1, v0
	v_rcp_f32_e32 v5, v4
	v_div_fmas_f32 v0, v0, v6, v1
	v_div_fixup_f32 v171, v0, v48, v2
	v_cvt_pk_bf16_f32 v6, v61, v62
	v_fma_f32 v0, -v4, v5, 1.0
	v_fmac_f32_e32 v5, v0, v5
	v_div_scale_f32 v0, vcc, v3, v48, v3
	v_mul_f32_e32 v1, v0, v5
	v_fma_f32 v2, -v4, v1, v0
	v_fmac_f32_e32 v1, v2, v5
	v_fma_f32 v0, -v4, v1, v0
	v_div_fmas_f32 v0, v0, v5, v1
	v_div_fixup_f32 v172, v0, v48, v3
	v_cvt_pk_bf16_f32 v0, v49, v50
	v_cvt_pk_bf16_f32 v1, v51, v52
	v_cvt_pk_bf16_f32 v2, v53, v54
	v_cvt_pk_bf16_f32 v3, v55, v56
	s_nop 0
	v_permlane16_swap_b32_e32 v0, v2
	v_permlane16_swap_b32_e32 v1, v3
	v_cvt_pk_bf16_f32 v4, v57, v58
	v_cvt_pk_bf16_f32 v5, v59, v60
	buffer_store_dwordx4 v[0:3], v47, s[8:11], 0 offen
	v_permlane16_swap_b32_e32 v4, v6
	s_nop 0
	v_add_lshl_u32 v0, v46, s88, 1
	v_permlane16_swap_b32_e32 v5, v7
	v_cndmask_b32_e64 v0, v235, v0, s[44:45]
	buffer_store_dwordx4 v[4:7], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v45, s88, 1
	v_permlane16_swap_b32_e32 v8, v10
	v_permlane16_swap_b32_e32 v9, v11
	v_cndmask_b32_e64 v0, v235, v0, s[44:45]
	buffer_store_dwordx4 v[8:11], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v44, s88, 1
	v_permlane16_swap_b32_e32 v12, v14
	v_permlane16_swap_b32_e32 v13, v15
	v_cndmask_b32_e64 v0, v235, v0, s[44:45]
	buffer_store_dwordx4 v[12:15], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v43, s88, 1
	v_permlane16_swap_b32_e32 v16, v18
	v_permlane16_swap_b32_e32 v17, v19
	v_cndmask_b32_e64 v0, v235, v0, s[44:45]
	buffer_store_dwordx4 v[16:19], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v42, s88, 1
	v_permlane16_swap_b32_e32 v20, v22
	v_permlane16_swap_b32_e32 v21, v23
	v_cndmask_b32_e64 v0, v235, v0, s[44:45]
	buffer_store_dwordx4 v[20:23], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v41, s88, 1
	v_permlane16_swap_b32_e32 v24, v26
	v_permlane16_swap_b32_e32 v25, v27
	v_cndmask_b32_e64 v0, v235, v0, s[44:45]
	v_cvt_pk_bf16_f32 v48, v102, v103
	v_cvt_pk_bf16_f32 v49, v104, v105
	v_cvt_pk_bf16_f32 v50, v98, v99
	v_cvt_pk_bf16_f32 v51, v100, v101
	buffer_store_dwordx4 v[24:27], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v40, s88, 1
	v_permlane16_swap_b32_e32 v48, v50
	v_permlane16_swap_b32_e32 v49, v51
	v_cndmask_b32_e64 v0, v235, v0, s[44:45]
	v_cvt_pk_bf16_f32 v52, v94, v95
	v_cvt_pk_bf16_f32 v53, v96, v97
	v_cvt_pk_bf16_f32 v54, v90, v91
	v_cvt_pk_bf16_f32 v55, v92, v93
	buffer_store_dwordx4 v[48:51], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v39, s88, 1
	v_permlane16_swap_b32_e32 v52, v54
	v_permlane16_swap_b32_e32 v53, v55
	v_cndmask_b32_e64 v0, v235, v0, s[44:45]
	v_cvt_pk_bf16_f32 v56, v86, v87
	v_cvt_pk_bf16_f32 v57, v88, v89
	v_cvt_pk_bf16_f32 v58, v82, v83
	v_cvt_pk_bf16_f32 v59, v84, v85
	buffer_store_dwordx4 v[52:55], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v38, s88, 1
	v_permlane16_swap_b32_e32 v56, v58
	v_permlane16_swap_b32_e32 v57, v59
	v_cndmask_b32_e64 v0, v235, v0, s[44:45]
	v_cvt_pk_bf16_f32 v60, v78, v79
	v_cvt_pk_bf16_f32 v61, v80, v81
	v_cvt_pk_bf16_f32 v62, v74, v75
	v_cvt_pk_bf16_f32 v63, v76, v77
	buffer_store_dwordx4 v[56:59], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v37, s88, 1
	v_permlane16_swap_b32_e32 v60, v62
	v_permlane16_swap_b32_e32 v61, v63
	v_cndmask_b32_e64 v0, v235, v0, s[44:45]
	v_cvt_pk_bf16_f32 v64, v70, v71
	v_cvt_pk_bf16_f32 v65, v72, v73
	buffer_store_dwordx4 v[60:63], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v36, s88, 1
	v_permlane16_swap_b32_e32 v64, v66
	v_permlane16_swap_b32_e32 v65, v67
	v_cndmask_b32_e64 v0, v235, v0, s[44:45]
	buffer_store_dwordx4 v[64:67], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v35, s88, 1
	v_cndmask_b32_e64 v0, v235, v0, s[44:45]
	v_cvt_pk_bf16_f32 v68, v146, v150
	v_cvt_pk_bf16_f32 v69, v151, v152
	v_cvt_pk_bf16_f32 v70, v153, v154
	v_cvt_pk_bf16_f32 v71, v155, v156
	buffer_store_dwordx4 v[28:31], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v34, s88, 1
	v_permlane16_swap_b32_e32 v68, v70
	v_permlane16_swap_b32_e32 v69, v71
	v_cndmask_b32_e64 v0, v235, v0, s[44:45]
	v_cvt_pk_bf16_f32 v72, v157, v158
	v_cvt_pk_bf16_f32 v73, v159, v160
	v_cvt_pk_bf16_f32 v74, v161, v162
	v_cvt_pk_bf16_f32 v75, v163, v164
	buffer_store_dwordx4 v[68:71], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v33, s88, 1
	v_permlane16_swap_b32_e32 v72, v74
	v_permlane16_swap_b32_e32 v73, v75
	v_cndmask_b32_e64 v0, v235, v0, s[44:45]
	v_cvt_pk_bf16_f32 v76, v165, v166
	v_cvt_pk_bf16_f32 v77, v167, v168
	v_cvt_pk_bf16_f32 v78, v169, v170
	v_cvt_pk_bf16_f32 v79, v171, v172
	buffer_store_dwordx4 v[72:75], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v32, s88, 1
	v_permlane16_swap_b32_e32 v76, v78
	v_permlane16_swap_b32_e32 v77, v79
	v_cndmask_b32_e64 v0, v235, v0, s[44:45]
	buffer_store_dwordx4 v[76:79], v0, s[8:11], 0 offen
	s_endpgm
.Ltmp249:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel \symbol
		.amdhsa_group_segment_fixed_size 32768
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
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 434
		.amdhsa_next_free_sgpr 96
		.amdhsa_accum_offset 256
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
                                        ; -- End function
	.set \symbol\().num_vgpr, 256
	.set \symbol\().num_agpr, 178
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
; codeLenInByte = 31076
; TotalNumSgprs: 102
; NumVgprs: 256
; NumAgprs: 178
; TotalNumVgprs: 434
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 12
; VGPRBlocks: 54
; NumSGPRsForWavesPerEU: 102
; NumVGPRsForWavesPerEU: 434
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
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     178
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
    .group_segment_fixed_size: 32768
    .kernarg_segment_align: 8
    .kernarg_segment_size: 96
    .max_flat_workgroup_size: 64
    .name:           \symbol
    .private_segment_fixed_size: 0
    .sgpr_count:     102
    .sgpr_spill_count: 0
    .symbol:         \symbol\().kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     434
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
.Lline_table_start0:
	.endm
