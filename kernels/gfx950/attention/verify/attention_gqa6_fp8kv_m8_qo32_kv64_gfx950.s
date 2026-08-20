	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 5
.text
	.globl	_grouped_gqa8_fp8kv_fwd_kernel  ; -- Begin function _grouped_gqa8_fp8kv_fwd_kernel
	.p2align	8
	.type	_grouped_gqa8_fp8kv_fwd_kernel,@function
_grouped_gqa8_fp8kv_fwd_kernel:         ; @_grouped_gqa8_fp8kv_fwd_kernel
.Lfunc_begin0:
	.cfi_sections .debug_frame
	.cfi_startproc
; %bb.10:
	.file	1 "/" "bench.py"
	.loc	1 298 0 prologue_end            ; bench.py:298:0
	s_load_dwordx2 s[2:3], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_waitcnt lgkmcnt(0)
	s_branch .LBB0_0
	.loc	1 0 0 is_stmt 0                 ; :0:0
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
	.loc	1 298 0 is_stmt 1               ; bench.py:298
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	.loc	1 332 22                        ; bench.py:332:22
	s_ashr_i32 s21, s16, 31
	s_lshl_b64 s[6:7], s[20:21], 2
	s_add_u32 s10, s14, s6
	s_addc_u32 s11, s15, s7
	v_mov_b32_e32 v4, 0
	global_load_dwordx2 v[2:3], v4, s[10:11]
	.loc	1 337 31                        ; bench.py:337:31
	v_lshrrev_b32_e32 v5, 5, v0
	.loc	1 354 27                        ; bench.py:354:27
	s_mul_i32 s10, s17, 0x600
	.loc	1 352 17                        ; bench.py:352:17
	v_and_b32_e32 v1, 31, v0
	.loc	1 354 27                        ; bench.py:354:27
	v_mul_u32_u24_e32 v14, 0x1800, v5
	v_lshl_or_b32 v14, v1, 3, v14
	.loc	1 354 16 is_stmt 0              ; bench.py:354:16
	v_bfrev_b32_e32 v6, 1
	.loc	1 337 31 is_stmt 1              ; bench.py:337:31
	v_or_b32_e32 v7, 2, v5
	v_or_b32_e32 v8, 4, v5
	v_or_b32_e32 v9, 6, v5
	v_or_b32_e32 v10, 8, v5
	v_or_b32_e32 v11, 10, v5
	v_or_b32_e32 v12, 12, v5
	v_or_b32_e32 v13, 14, v5
	s_mov_b32 s27, 0x27000
	s_mov_b32 s26, 0x7ffffffe
	v_and_b32_e32 v165, 15, v0
	.loc	1 341 26                        ; bench.py:341:26
	v_and_b32_e32 v166, 48, v0
	v_lshrrev_b32_e32 v75, 1, v166
	v_lshlrev_b32_e32 v104, 3, v0
	.loc	1 332 22                        ; bench.py:332:22
	s_waitcnt vmcnt(0)
	v_readfirstlane_b32 s90, v2
	.loc	1 333 47                        ; bench.py:333:47
	v_readfirstlane_b32 s11, v3
	s_sub_i32 s88, s11, s90
	.loc	1 334 23                        ; bench.py:334:23
	s_waitcnt lgkmcnt(0)
	s_add_u32 s2, s2, s6
	s_addc_u32 s3, s3, s7
	.loc	1 354 27                        ; bench.py:354:27
	s_lshl_b32 s6, s18, 9
	s_mul_i32 s11, s90, 0x1800
	s_add_i32 s33, s6, s10
	s_add_i32 s33, s33, s11
	.loc	1 334 23                        ; bench.py:334:23
	global_load_dwordx2 v[2:3], v4, s[2:3]
	.loc	1 354 27                        ; bench.py:354:27
	v_add_lshl_u32 v4, v14, s33, 1
	.loc	1 342 26                        ; bench.py:342:26
	v_cmp_gt_i32_e32 vcc, s88, v5
	.loc	1 354 16                        ; bench.py:354:16
	v_or_b32_e32 v21, 0x200, v4
	s_and_b32 s25, s25, 0xffff
	v_cndmask_b32_e32 v5, v6, v4, vcc
	.loc	1 354 27 is_stmt 0              ; bench.py:354:27
	v_add_u32_e32 v14, 0x6000, v4
	v_add_u32_e32 v15, 0xc000, v4
	v_add_u32_e32 v16, 0x12000, v4
	v_add_u32_e32 v17, 0x18000, v4
	v_add_u32_e32 v18, 0x1e000, v4
	v_add_u32_e32 v19, 0x24000, v4
	v_add_u32_e32 v20, 0x2a000, v4
	.loc	1 354 16                        ; bench.py:354:16
	v_add_u32_e32 v22, 0x6200, v4
	v_add_u32_e32 v23, 0xc200, v4
	v_add_u32_e32 v24, 0x12200, v4
	v_add_u32_e32 v25, 0x18200, v4
	v_add_u32_e32 v26, 0x1e200, v4
	v_add_u32_e32 v27, 0x24200, v4
	v_add_u32_e32 v4, 0x2a200, v4
	.loc	1 342 26 is_stmt 1              ; bench.py:342:26
	v_cmp_gt_i32_e64 s[2:3], s88, v7
	v_cmp_gt_i32_e64 s[6:7], s88, v8
	v_cmp_gt_i32_e64 s[10:11], s88, v9
	v_cmp_gt_i32_e64 s[14:15], s88, v10
	v_cmp_gt_i32_e64 s[18:19], s88, v11
	v_cmp_gt_i32_e64 s[20:21], s88, v12
	v_cmp_gt_i32_e64 s[22:23], s88, v13
	.loc	1 354 16                        ; bench.py:354:16
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
	.loc	1 337 31                        ; bench.py:337:31
	v_and_b32_e32 v5, 32, v0
	v_bfe_i32 v4, v0, 5, 1
	s_movk_i32 s6, 0x220
	v_accvgpr_write_b32 a129, v5
	v_cmp_eq_u32_e64 s[2:3], 0, v5
	.loc	1 381 29                        ; bench.py:381:29
	v_lshlrev_b32_e32 v5, 4, v1
	v_bitop3_b32 v4, v4, v5, s6 bitop3:0x6c
	v_accvgpr_write_b32 a147, v5
	v_add_u32_e32 v5, 0, v4
	v_xad_u32 v6, v4, 64, 0
	v_xor_b32_e32 v7, 0x80, v4
	v_xor_b32_e32 v8, 0xc0, v4
	v_xor_b32_e32 v9, 0x100, v4
	v_xor_b32_e32 v10, 0x140, v4
	v_xor_b32_e32 v11, 0x180, v4
	v_xor_b32_e32 v4, 0x1c0, v4
	.loc	1 342 26                        ; bench.py:342:26
	v_cmp_gt_i32_e64 s[34:35], s88, v165
	.loc	1 381 29                        ; bench.py:381:29
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
	.loc	1 335 52                        ; bench.py:335:52
	v_readfirstlane_b32 s6, v3
	v_readfirstlane_b32 s10, v2
	s_sub_i32 s92, s6, s10
	.loc	1 360 40                        ; bench.py:360:40
	s_cmp_gt_i32 s92, 0
	.loc	1 381 29                        ; bench.py:381:29
	s_waitcnt lgkmcnt(0)
	; wave barrier
	.loc	1 360 40                        ; bench.py:360:40
	s_cbranch_scc1 .LBB0_2
; %bb.1:                                ; %.._crit_edge_crit_edge
	.loc	1 406 24                        ; bench.py:406:24
	s_lshl_b32 s91, s17, 8
	s_mov_b64 s[6:7], 0
	s_branch .LBB0_3
.LBB0_2:
	.loc	1 0 24 is_stmt 0                ; bench.py:0:24
	s_mov_b64 s[6:7], -1
                                        ; implicit-def: $sgpr91
.LBB0_3:                                ; %Flow1294
	s_load_dword s89, s[0:1], 0x48
	v_lshrrev_b32_e32 v2, 4, v0
	v_lshrrev_b32_e32 v105, 2, v166
	v_accvgpr_write_b32 a145, v2
	v_lshlrev_b32_e32 v74, 4, v165
	s_andn2_b64 vcc, exec, s[6:7]
	v_mov_b32_e32 v185, 0
	v_mov_b32_e32 v184, 0
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
	v_mov_b32_e32 v233, 0xff800000
	v_mov_b32_e32 v234, 0xff800000
	s_cbranch_vccnz .LBB0_9
; %bb.4:                                ; %.lr.ph
	.loc	1 342 26 is_stmt 1              ; bench.py:342:26
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
	.loc	1 381 29                        ; bench.py:381:29
	v_mul_u32_u24_e32 v2, 0x220, v165
	v_lshlrev_b32_e32 v3, 1, v166
	.loc	1 342 26                        ; bench.py:342:26
	s_cselect_b64 s[64:65], -1, 0
	s_cmp_gt_i32 s88, 6
	.loc	1 381 29                        ; bench.py:381:29
	v_xor_b32_e32 v2, v2, v3
	.loc	1 342 26                        ; bench.py:342:26
	s_cselect_b64 s[66:67], -1, 0
	s_cmp_gt_i32 s88, 7
	.loc	1 381 29                        ; bench.py:381:29
	v_xor_b32_e32 v3, 0x180, v2
	.loc	1 342 26                        ; bench.py:342:26
	s_cselect_b64 s[68:69], -1, 0
	s_cmp_gt_i32 s88, 8
	.loc	1 381 29                        ; bench.py:381:29
	v_add_u32_e32 v3, 0, v3
	.loc	1 342 26                        ; bench.py:342:26
	s_cselect_b64 s[70:71], -1, 0
	s_cmp_gt_i32 s88, 9
	.loc	1 381 29                        ; bench.py:381:29
	ds_read_b128 v[32:35], v3 offset:8208
	ds_read_b128 v[36:39], v3 offset:8192
	ds_read_b128 v[14:17], v3
	ds_read_b128 v[18:21], v3 offset:16
	v_xor_b32_e32 v3, 0x100, v2
	.loc	1 342 26                        ; bench.py:342:26
	s_cselect_b64 s[72:73], -1, 0
	s_cmp_gt_i32 s88, 10
	.loc	1 381 29                        ; bench.py:381:29
	v_add_u32_e32 v3, 0, v3
	.loc	1 342 26                        ; bench.py:342:26
	s_cselect_b64 s[74:75], -1, 0
	s_cmp_gt_i32 s88, 11
	.loc	1 381 29                        ; bench.py:381:29
	ds_read_b128 v[28:31], v3 offset:8208
	ds_read_b128 v[40:43], v3 offset:8192
	ds_read_b128 v[10:13], v3
	ds_read_b128 v[22:25], v3 offset:16
	v_xor_b32_e32 v3, 0x80, v2
	.loc	1 342 26                        ; bench.py:342:26
	s_cselect_b64 s[76:77], -1, 0
	s_cmp_gt_i32 s88, 12
	.loc	1 381 29                        ; bench.py:381:29
	v_add_u32_e32 v3, 0, v3
	v_add_u32_e32 v26, 0, v2
	.loc	1 342 26                        ; bench.py:342:26
	s_cselect_b64 s[78:79], -1, 0
	s_cmp_gt_i32 s88, 13
	.loc	1 381 29                        ; bench.py:381:29
	ds_read_b128 v[44:47], v3 offset:8208
	ds_read_b128 v[48:51], v3 offset:8192
	ds_read_b128 v[6:9], v3
	ds_read_b128 v[52:55], v3 offset:16
	ds_read_b128 v[56:59], v26 offset:8208
	ds_read_b128 v[60:63], v26 offset:8192
	ds_read_b128 v[2:5], v26
	ds_read_b128 v[64:67], v26 offset:16
	v_lshlrev_b32_e32 v26, 6, v0
	.loc	1 342 26                        ; bench.py:342:26
	s_cselect_b64 s[80:81], -1, 0
	s_cmp_gt_i32 s88, 14
	v_and_b32_e32 v26, 0xc0, v26
	v_lshlrev_b32_e32 v27, 1, v0
	s_waitcnt lgkmcnt(0)
	v_cvt_scalef32_pk_fp8_bf16 v28, v28, 1.0
	s_cselect_b64 s[82:83], -1, 0
	s_cmp_gt_i32 s88, 15
	v_and_b32_e32 v162, 56, v27
	v_add_u32_e32 v26, 0, v26
	v_accvgpr_read_b32 v27, a129
	v_cvt_scalef32_pk_fp8_bf16 v28, v29, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v29, v30, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v32, v32, 1.0
	s_cselect_b64 s[84:85], -1, 0
	v_lshlrev_b32_e32 v1, 2, v1
	v_lshl_add_u32 v163, v27, 3, v26
	s_lshl_b32 s91, s17, 8
	v_cvt_scalef32_pk_fp8_bf16 v29, v31, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v31, v38, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v32, v33, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v33, v34, 1.0
	v_lshlrev_b32_e32 v34, 4, v0
	s_load_dwordx2 s[52:53], s[0:1], 0x40
	v_accvgpr_write_b32 a144, v74
	v_or_b32_e32 v190, s91, v74
	v_cvt_scalef32_pk_fp8_bf16 v31, v39, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v33, v35, 1.0 op_sel:[0,0,1]
	v_xor_b32_e32 v35, v34, v166
	v_mul_u32_u24_e32 v39, 0x110, v165
	v_xor_b32_e32 v34, v34, v75
	v_add_u32_e32 v74, 0, v1
	v_add_u32_e32 v1, v163, v162
	v_lshlrev_b32_e32 v164, 2, v166
	v_cvt_scalef32_pk_fp8_bf16 v10, v10, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v14, v14, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v27, v42, 1.0
	v_accvgpr_write_b32 a146, v166
	v_xor_b32_e32 v39, v39, v166
	v_xor_b32_e32 v166, 8, v34
	v_lshlrev_b32_e32 v42, 2, v0
	v_accvgpr_write_b32 a148, v1
	v_add_u32_e32 v1, 0, v34
	v_cvt_scalef32_pk_fp8_bf16 v2, v2, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v6, v6, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v10, v11, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v11, v12, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v14, v15, 1.0 op_sel:[0,0,1]
	v_cvt_scalef32_pk_fp8_bf16 v15, v16, 1.0
	v_cvt_scalef32_pk_fp8_bf16 v27, v43, 1.0 op_sel:[0,0,1]
	v_xor_b32_e32 v167, 32, v34
	v_lshl_or_b32 v42, v0, 7, v42
	v_and_b32_e32 v43, 8, v104
	s_movk_i32 s0, 0x1f78
	v_accvgpr_write_b32 a149, v1
	v_add_u32_e32 v1, 0, v166
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
	v_xor_b32_e32 v168, 40, v34
	v_bitop3_b32 v173, v42, v43, s0 bitop3:0x6c
	v_accvgpr_write_b32 a150, v1
	v_add_u32_e32 v1, 0, v167
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
	v_accvgpr_write_b32 a128, v165
	v_xor_b32_e32 v40, 64, v39
	v_xor_b32_e32 v41, 0x80, v39
	v_xor_b32_e32 v165, 0xc0, v39
	v_xor_b32_e32 v169, 64, v34
	v_xor_b32_e32 v170, 0x48, v34
	v_xor_b32_e32 v171, 0x60, v34
	v_xor_b32_e32 v172, 0x68, v34
	v_xor_b32_e32 v174, 16, v173
	v_xor_b32_e32 v175, 32, v173
	v_xor_b32_e32 v176, 48, v173
	v_xor_b32_e32 v177, 64, v173
	v_xor_b32_e32 v178, 0x50, v173
	v_xor_b32_e32 v179, 0x60, v173
	v_xor_b32_e32 v180, 0x70, v173
	v_accvgpr_write_b32 a151, v1
	v_add_u32_e32 v1, 0, v168
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
	.loc	1 360 40                        ; bench.py:360:40
	v_add_lshl_u32 v191, s10, v0, 3
	v_mov_b32_e32 v192, 0xff800000
	.loc	1 362 27                        ; bench.py:362:27
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
	v_mov_b32_e32 v184, 0
	v_mov_b32_e32 v185, 0
	v_add_u32_e32 v195, 0, v164
	v_add_u32_e32 v196, 0, v35
	v_add_u32_e32 v197, 0, v36
	v_add_u32_e32 v198, 0, v37
	v_add_u32_e32 v199, 0, v38
	v_add_u32_e32 v200, 0, v39
	v_add_u32_e32 v201, 0, v40
	v_add_u32_e32 v202, 0, v41
	v_add_u32_e32 v203, 0, v165
	s_mov_b32 s94, 0xff800000
	s_mov_b32 s95, 0xc2fc0000
	v_accvgpr_write_b32 a152, v1
	v_add_u32_e32 v227, 0, v169
	v_add_u32_e32 v226, 0, v170
	v_add_u32_e32 v193, 0, v171
	v_add_u32_e32 v194, 0, v172
	v_add_u32_e32 v212, 0, v173
	v_add_u32_e32 v213, 0, v174
	v_add_u32_e32 v214, 0, v175
	v_add_u32_e32 v215, 0, v176
	v_add_u32_e32 v216, 0, v177
	v_add_u32_e32 v217, 0, v178
	v_add_u32_e32 v218, 0, v179
	v_add_u32_e32 v219, 0, v180
	v_mov_b32_e32 v220, 0
	v_bfrev_b32_e32 v221, 1
	v_mov_b32_e32 v223, 0x42800000
	v_not_b32_e32 v224, 63
	v_mov_b32_e32 v234, 0xff800000
	v_mov_b32_e32 v233, 0xff800000
	s_branch .LBB0_6
.LBB0_5:                                ;   in Loop: Header=BB0_6 Depth=1
	.loc	1 0 27 is_stmt 0                ; bench.py:0:27
	s_or_b64 exec, exec, s[86:87]
	.loc	1 360 40 is_stmt 1              ; bench.py:360:40
	s_add_i32 s93, s93, 64
	s_cmp_lt_i32 s93, s92
	v_add_u32_e32 v191, 0x200, v191
	s_cbranch_scc0 .LBB0_8
.LBB0_6:                                ; =>This Inner Loop Header: Depth=1
	.loc	1 362 36                        ; bench.py:362:36
	v_add_u32_e32 v1, s93, v0
	v_cmp_gt_i32_e32 vcc, s92, v1
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[0:1], s[46:47], vcc
	.loc	1 368 48                        ; bench.py:368:48
	v_cndmask_b32_e64 v1, 0, 1, s[0:1]
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[0:1], s[56:57], vcc
	.loc	1 368 48                        ; bench.py:368:48
	v_cndmask_b32_e64 v34, 0, 1, s[0:1]
.Ltmp2:
	.file	2 "/sgl-workspace/triton-custom/python/triton/language" "standard.py"
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v1, v1 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp3:
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[0:1], s[58:59], vcc
	.loc	1 368 48                        ; bench.py:368:48
	v_cndmask_b32_e64 v35, 0, 1, s[0:1]
.Ltmp4:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp5:
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[0:1], s[60:61], vcc
	.loc	1 368 48                        ; bench.py:368:48
	v_cndmask_b32_e64 v36, 0, 1, s[0:1]
.Ltmp6:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp7:
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[0:1], s[62:63], vcc
	.loc	1 368 48                        ; bench.py:368:48
	v_cndmask_b32_e64 v37, 0, 1, s[0:1]
.Ltmp8:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp9:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_mov_b32_e32 v169, v1
.Ltmp10:
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[0:1], s[64:65], vcc
	.loc	1 368 48                        ; bench.py:368:48
	v_cndmask_b32_e64 v38, 0, 1, s[0:1]
.Ltmp11:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_mov_b32_dpp v169, v169 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp12:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_e32 v1, v1, v169
.Ltmp13:
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[0:1], s[66:67], vcc
	.loc	1 368 48                        ; bench.py:368:48
	v_cndmask_b32_e64 v39, 0, 1, s[0:1]
.Ltmp14:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp15:
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[0:1], s[68:69], vcc
.Ltmp16:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_readlane_b32 s16, v1, 63
.Ltmp17:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v34, v34 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp18:
	.loc	1 368 48                        ; bench.py:368:48
	v_cndmask_b32_e64 v40, 0, 1, s[0:1]
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[0:1], s[70:71], vcc
.Ltmp19:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp20:
	.loc	1 368 48                        ; bench.py:368:48
	v_cndmask_b32_e64 v41, 0, 1, s[0:1]
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[0:1], s[72:73], vcc
.Ltmp21:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp22:
	.loc	1 368 48                        ; bench.py:368:48
	v_cndmask_b32_e64 v162, 0, 1, s[0:1]
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[0:1], s[74:75], vcc
.Ltmp23:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp24:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_mov_b32_e32 v34, v1
.Ltmp25:
	.loc	1 368 48                        ; bench.py:368:48
	v_cndmask_b32_e64 v163, 0, 1, s[0:1]
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[0:1], s[76:77], vcc
.Ltmp26:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp27:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_e32 v1, v1, v34
.Ltmp28:
	.loc	1 368 48                        ; bench.py:368:48
	v_cndmask_b32_e64 v164, 0, 1, s[0:1]
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[0:1], s[78:79], vcc
.Ltmp29:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp30:
	.loc	1 368 48                        ; bench.py:368:48
	v_cndmask_b32_e64 v165, 0, 1, s[0:1]
.Ltmp31:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_readlane_b32 s17, v1, 63
.Ltmp32:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v35, v35 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp33:
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[0:1], s[80:81], vcc
	.loc	1 368 48                        ; bench.py:368:48
	v_cndmask_b32_e64 v166, 0, 1, s[0:1]
.Ltmp34:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp35:
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[0:1], s[82:83], vcc
	.loc	1 368 48                        ; bench.py:368:48
	v_cndmask_b32_e64 v167, 0, 1, s[0:1]
.Ltmp36:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp37:
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[0:1], s[84:85], vcc
	.loc	1 368 48                        ; bench.py:368:48
	v_cndmask_b32_e64 v168, 0, 1, s[0:1]
.Ltmp38:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp39:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_mov_b32_e32 v34, v1
.Ltmp40:
	.loc	2 191 40 is_stmt 0              ; standard.py:191:40 @[ bench.py:368:27 ]
	s_waitcnt lgkmcnt(0)
.Ltmp41:
	; wave barrier
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	s_nop 0
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp42:
	.loc	2 170 27 is_stmt 1              ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp43:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	s_nop 0
	v_readlane_b32 s18, v1, 63
.Ltmp44:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v36, v36 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp45:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp46:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp47:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	s_nop 0
	v_readlane_b32 s19, v1, 63
.Ltmp48:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v37, v37 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp49:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp50:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp51:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	s_nop 0
	v_readlane_b32 s20, v1, 63
.Ltmp52:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v38, v38 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp53:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp54:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp55:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	s_nop 0
	v_readlane_b32 s21, v1, 63
.Ltmp56:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v39, v39 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp57:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp58:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp59:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	s_nop 0
	v_readlane_b32 s22, v1, 63
.Ltmp60:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v40, v40 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp61:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp62:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp63:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	s_nop 0
	v_readlane_b32 s23, v1, 63
.Ltmp64:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v41, v41 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp65:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:27 ]
	s_nop 0
	v_mov_b64_e32 v[40:41], s[22:23]
.Ltmp66:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp67:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:27 ]
	v_mov_b64_e32 v[38:39], s[20:21]
	ds_write_b128 v220, v[38:41] offset:16
.Ltmp68:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp69:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp70:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp71:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	s_nop 0
	v_readlane_b32 s24, v1, 63
.Ltmp72:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v162, v162 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp73:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp74:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp75:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	s_nop 0
	v_readlane_b32 s25, v1, 63
.Ltmp76:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v163, v163 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp77:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp78:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp79:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	s_nop 0
	v_readlane_b32 s26, v1, 63
.Ltmp80:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v164, v164 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp81:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp82:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp83:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	s_nop 0
	v_readlane_b32 s27, v1, 63
.Ltmp84:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v165, v165 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp85:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:27 ]
	s_nop 0
	v_mov_b64_e32 v[164:165], s[26:27]
.Ltmp86:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp87:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:27 ]
	v_mov_b64_e32 v[162:163], s[24:25]
	ds_write_b128 v220, v[162:165] offset:32
.Ltmp88:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp89:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp90:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp91:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	s_nop 0
	v_readlane_b32 s28, v1, 63
.Ltmp92:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v166, v166 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp93:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp94:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp95:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	s_nop 0
	v_readlane_b32 s29, v1, 63
.Ltmp96:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v167, v167 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp97:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp98:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_e32 v1, v1, v34
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp99:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	s_nop 0
	v_readlane_b32 s30, v1, 63
.Ltmp100:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v168, v168 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_max_i32_dpp v1, v1, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp101:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:34 ]
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp102:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_e32 v1, v1, v34
.Ltmp103:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:27 ]
	v_mov_b64_e32 v[36:37], s[18:19]
	v_mov_b64_e32 v[34:35], s[16:17]
.Ltmp104:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:34 ] ]
	v_max_i32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp105:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:27 ]
	ds_write_b128 v220, v[34:37]
.Ltmp106:
	.loc	2 191 40 is_stmt 0              ; standard.py:191:40 @[ bench.py:368:34 ]
	v_readlane_b32 s31, v1, 63
.Ltmp107:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:27 ]
	s_nop 1
	v_mov_b64_e32 v[168:169], s[30:31]
	v_mov_b64_e32 v[166:167], s[28:29]
	ds_write_b128 v220, v[166:169] offset:48
	ds_write_b128 v220, v[34:37] offset:64
	ds_write_b128 v220, v[38:41] offset:80
	ds_write_b128 v220, v[162:165] offset:96
	ds_write_b128 v220, v[166:169] offset:112
	; wave barrier
	ds_read_b32 v1, v74
	s_waitcnt lgkmcnt(0)
	ds_swizzle_b32 v34, v1 offset:swizzle(SWAP,16)
.Ltmp108:
	.loc	2 170 27 is_stmt 1              ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:27 ] ]
	s_waitcnt lgkmcnt(0)
	v_max_i32_e32 v1, v1, v34
.Ltmp109:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:27 ]
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_shr:8 row_mask:0xf bank_mask:0xc
	s_nop 1
	v_mov_b32_dpp v34, v1 row_shl:8 row_mask:0xf bank_mask:0x3
.Ltmp110:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:27 ] ]
	v_max_i32_e32 v1, v1, v34
.Ltmp111:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:27 ]
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 row_shr:4 row_mask:0xf bank_mask:0xa
	s_nop 1
	v_mov_b32_dpp v34, v1 row_shl:4 row_mask:0xf bank_mask:0x5
.Ltmp112:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:27 ] ]
	v_max_i32_e32 v1, v1, v34
.Ltmp113:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:27 ]
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
.Ltmp114:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:27 ] ]
	v_max_i32_e32 v1, v1, v34
.Ltmp115:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:368:27 ]
	v_mov_b32_e32 v34, v1
	s_nop 1
	v_mov_b32_dpp v34, v34 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
.Ltmp116:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:368:27 ] ]
	v_max_i32_e32 v1, v1, v34
.Ltmp117:
	.loc	1 0 0 is_stmt 0                 ; bench.py:0
	v_cmp_ne_u32_e64 s[0:1], 0, v1
	.loc	1 369 11 is_stmt 1              ; bench.py:369:11
	s_and_saveexec_b64 s[86:87], s[0:1]
	s_cbranch_execz .LBB0_5
; %bb.7:                                ;   in Loop: Header=BB0_6 Depth=1
	.loc	1 371 16                        ; bench.py:371:16
	v_cndmask_b32_e32 v162, v221, v191, vcc
	buffer_load_dwordx2 v[208:209], v162, s[52:55], 0 offen
	v_accvgpr_read_b32 v207, a148
	.loc	1 393 18                        ; bench.py:393:18
	s_waitcnt lgkmcnt(0)
	; wave barrier
	v_accvgpr_write_b32 a130, v184
	v_accvgpr_write_b32 a131, v185
	v_accvgpr_read_b32 v1, a145
	.loc	1 362 36                        ; bench.py:362:36
	v_add_u32_e32 v1, s93, v1
	v_add_u32_e32 v41, 32, v1
	v_add_u32_e32 v40, 36, v1
	v_cmp_gt_i32_e64 s[24:25], s92, v41
	v_add_u32_e32 v39, 40, v1
	v_cmp_gt_i32_e64 s[26:27], s92, v40
	v_cmp_gt_i32_e64 s[28:29], s92, v39
	v_add_u32_e32 v38, 44, v1
	v_add_u32_e32 v37, 48, v1
	v_cmp_gt_i32_e64 s[30:31], s92, v38
	v_add_u32_e32 v36, 52, v1
	v_cmp_gt_i32_e64 s[36:37], s92, v37
	v_add_u32_e32 v35, 56, v1
	v_cmp_gt_i32_e64 s[38:39], s92, v36
	v_add_u32_e32 v34, 60, v1
	v_add_u32_e32 v186, 28, v1
	v_add_u32_e32 v187, 24, v1
	v_add_u32_e32 v188, 20, v1
	v_add_u32_e32 v189, 16, v1
	v_add_u32_e32 v204, 12, v1
	v_add_u32_e32 v205, 8, v1
	v_add_u32_e32 v206, 4, v1
	v_cmp_gt_i32_e32 vcc, s92, v1
	v_cmp_gt_i32_e64 s[40:41], s92, v35
	.loc	1 380 24                        ; bench.py:380:24
	s_mov_b32 s50, s54
	s_mov_b32 s51, s55
	.loc	1 362 36                        ; bench.py:362:36
	v_cmp_gt_i32_e64 s[0:1], s92, v206
	v_cmp_gt_i32_e64 s[6:7], s92, v205
	v_cmp_gt_i32_e64 s[10:11], s92, v204
	v_cmp_gt_i32_e64 s[16:17], s92, v189
	v_cmp_gt_i32_e64 s[18:19], s92, v188
	v_cmp_gt_i32_e64 s[20:21], s92, v187
	v_cmp_gt_i32_e64 s[22:23], s92, v186
	v_cmp_gt_i32_e64 s[42:43], s92, v34
	.loc	1 395 24                        ; bench.py:395:24
	s_mov_b32 s14, s54
	s_mov_b32 s15, s55
	.loc	1 393 18                        ; bench.py:393:18
	s_waitcnt vmcnt(0)
	ds_write_b64 v207, v[208:209]
	; wave barrier
	ds_read_b128 v[236:239], v195
	ds_read_b128 v[240:243], v195 offset:16
	ds_read_b128 v[182:185], v195 offset:32
	ds_read_b128 v[178:181], v195 offset:48
	ds_read_b128 v[174:177], v195 offset:256
	ds_read_b128 v[170:173], v195 offset:272
	ds_read_b128 v[166:169], v195 offset:288
	ds_read_b128 v[162:165], v195 offset:304
	.loc	1 380 24                        ; bench.py:380:24
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_write_b64 v207, v[208:209]
	; wave barrier
	ds_read_b128 v[244:247], v195
	.loc	1 395 35                        ; bench.py:395:35
	v_lshl_add_u32 v163, v236, 10, v190
	v_lshl_add_u32 v165, v238, 10, v190
	.loc	1 380 24                        ; bench.py:380:24
	ds_read_b128 v[236:239], v195 offset:16
	.loc	1 395 35                        ; bench.py:395:35
	v_lshl_add_u32 v167, v240, 10, v190
	v_lshl_add_u32 v169, v242, 10, v190
	.loc	1 380 24                        ; bench.py:380:24
	ds_read_b128 v[240:243], v195 offset:32
	.loc	1 380 35 is_stmt 0              ; bench.py:380:35
	s_waitcnt lgkmcnt(2)
	v_lshl_add_u32 v171, v244, 10, v190
	s_waitcnt lgkmcnt(1)
	v_lshl_add_u32 v173, v236, 10, v190
	v_lshl_add_u32 v175, v238, 10, v190
	.loc	1 380 24                        ; bench.py:380:24
	ds_read_b128 v[236:239], v195 offset:48
	.loc	1 380 35                        ; bench.py:380:35
	s_waitcnt lgkmcnt(1)
	v_lshl_add_u32 v177, v240, 10, v190
	v_lshl_add_u32 v179, v242, 10, v190
	.loc	1 380 24                        ; bench.py:380:24
	ds_read_b128 v[240:243], v195 offset:256
	v_cndmask_b32_e32 v1, v221, v171, vcc
	.loc	1 380 35                        ; bench.py:380:35
	s_waitcnt lgkmcnt(1)
	v_lshl_add_u32 v181, v236, 10, v190
	v_lshl_add_u32 v183, v238, 10, v190
	.loc	1 380 24                        ; bench.py:380:24
	ds_read_b128 v[236:239], v195 offset:272
	.loc	1 380 35                        ; bench.py:380:35
	s_waitcnt lgkmcnt(1)
	v_lshl_add_u32 v185, v240, 10, v190
	.loc	1 380 24                        ; bench.py:380:24
	v_cndmask_b32_e64 v41, v221, v185, s[24:25]
	.loc	1 380 35                        ; bench.py:380:35
	v_lshl_add_u32 v185, v242, 10, v190
	.loc	1 380 24                        ; bench.py:380:24
	ds_read_b128 v[240:243], v195 offset:288
	v_cndmask_b32_e64 v40, v221, v185, s[26:27]
	.loc	1 380 35                        ; bench.py:380:35
	s_waitcnt lgkmcnt(1)
	v_lshl_add_u32 v185, v236, 10, v190
	.loc	1 380 24                        ; bench.py:380:24
	v_cndmask_b32_e64 v39, v221, v185, s[28:29]
	.loc	1 380 35                        ; bench.py:380:35
	v_lshl_add_u32 v185, v238, 10, v190
	.loc	1 380 24                        ; bench.py:380:24
	ds_read_b128 v[236:239], v195 offset:304
	v_cndmask_b32_e64 v38, v221, v185, s[30:31]
	.loc	1 380 35                        ; bench.py:380:35
	s_waitcnt lgkmcnt(1)
	v_lshl_add_u32 v185, v240, 10, v190
	.loc	1 380 24                        ; bench.py:380:24
	v_cndmask_b32_e64 v37, v221, v185, s[36:37]
	.loc	1 380 35                        ; bench.py:380:35
	v_lshl_add_u32 v185, v242, 10, v190
	.loc	1 380 24                        ; bench.py:380:24
	v_cndmask_b32_e64 v36, v221, v185, s[38:39]
	.loc	1 380 35                        ; bench.py:380:35
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u32 v185, v236, 10, v190
	v_lshl_add_u32 v171, v246, 10, v190
	.loc	1 380 24                        ; bench.py:380:24
	v_cndmask_b32_e64 v35, v221, v185, s[40:41]
	.loc	1 380 35                        ; bench.py:380:35
	v_lshl_add_u32 v185, v238, 10, v190
	.loc	1 380 24                        ; bench.py:380:24
	v_cndmask_b32_e64 v171, v221, v171, s[0:1]
	v_cndmask_b32_e64 v173, v221, v173, s[6:7]
	v_cndmask_b32_e64 v175, v221, v175, s[10:11]
	v_cndmask_b32_e64 v177, v221, v177, s[16:17]
	v_cndmask_b32_e64 v179, v221, v179, s[18:19]
	v_cndmask_b32_e64 v181, v221, v181, s[20:21]
	v_cndmask_b32_e64 v183, v221, v183, s[22:23]
	v_cndmask_b32_e64 v34, v221, v185, s[42:43]
	buffer_load_dwordx4 v[186:189], v1, s[48:51], 0 offen
	buffer_load_dwordx4 v[204:207], v171, s[48:51], 0 offen
	buffer_load_dwordx4 v[208:211], v173, s[48:51], 0 offen
	buffer_load_dwordx4 v[228:231], v175, s[48:51], 0 offen
	buffer_load_dwordx4 v[236:239], v177, s[48:51], 0 offen
	buffer_load_dwordx4 v[240:243], v179, s[48:51], 0 offen
	buffer_load_dwordx4 v[244:247], v181, s[48:51], 0 offen
	buffer_load_dwordx4 v[248:251], v183, s[48:51], 0 offen
	buffer_load_dwordx4 v[252:255], v41, s[48:51], 0 offen
	buffer_load_dwordx4 a[64:67], v40, s[48:51], 0 offen
	buffer_load_dwordx4 a[68:71], v39, s[48:51], 0 offen
	buffer_load_dwordx4 a[72:75], v38, s[48:51], 0 offen
	buffer_load_dwordx4 a[76:79], v37, s[48:51], 0 offen
	buffer_load_dwordx4 a[80:83], v36, s[48:51], 0 offen
	buffer_load_dwordx4 a[84:87], v35, s[48:51], 0 offen
	buffer_load_dwordx4 a[88:91], v34, s[48:51], 0 offen
	.loc	1 395 35 is_stmt 1              ; bench.py:395:35
	v_lshl_add_u32 v162, v162, 10, v190
	v_lshl_add_u32 v164, v164, 10, v190
	.loc	1 380 24                        ; bench.py:380:24
	s_waitcnt lgkmcnt(0)
	; wave barrier
	.loc	1 395 35                        ; bench.py:395:35
	v_lshl_add_u32 v39, v170, 10, v190
	v_lshl_add_u32 v41, v166, 10, v190
	v_lshl_add_u32 v166, v168, 10, v190
	.loc	1 395 24 is_stmt 0              ; bench.py:395:24
	v_cndmask_b32_e32 v168, v221, v163, vcc
	v_cndmask_b32_e64 v170, v221, v165, s[0:1]
	v_cndmask_b32_e64 v222, v221, v162, s[40:41]
	v_cndmask_b32_e64 v225, v221, v164, s[42:43]
	.loc	1 395 35                        ; bench.py:395:35
	v_lshl_add_u32 v1, v182, 10, v190
	v_lshl_add_u32 v34, v184, 10, v190
	v_lshl_add_u32 v35, v178, 10, v190
	v_lshl_add_u32 v36, v180, 10, v190
	v_lshl_add_u32 v37, v174, 10, v190
	v_lshl_add_u32 v38, v176, 10, v190
	v_lshl_add_u32 v40, v172, 10, v190
	.loc	1 395 24                        ; bench.py:395:24
	v_cndmask_b32_e64 v167, v221, v167, s[6:7]
	v_cndmask_b32_e64 v169, v221, v169, s[10:11]
	v_cndmask_b32_e64 v1, v221, v1, s[16:17]
	v_cndmask_b32_e64 v34, v221, v34, s[18:19]
	v_cndmask_b32_e64 v35, v221, v35, s[20:21]
	v_cndmask_b32_e64 v36, v221, v36, s[22:23]
	v_cndmask_b32_e64 v37, v221, v37, s[24:25]
	v_cndmask_b32_e64 v38, v221, v38, s[26:27]
	v_cndmask_b32_e64 v39, v221, v39, s[28:29]
	v_cndmask_b32_e64 v40, v221, v40, s[30:31]
	v_cndmask_b32_e64 v41, v221, v41, s[36:37]
	v_cndmask_b32_e64 v166, v221, v166, s[38:39]
	.loc	1 380 24 is_stmt 1              ; bench.py:380:24
	s_waitcnt vmcnt(15)
	ds_write_b128 v196, v[186:189]
	s_waitcnt vmcnt(14)
	ds_write_b128 v197, v[204:207] offset:1024
	s_waitcnt vmcnt(13)
	ds_write_b128 v198, v[208:211] offset:2048
	s_waitcnt vmcnt(12)
	ds_write_b128 v199, v[228:231] offset:3072
	s_waitcnt vmcnt(11)
	ds_write_b128 v196, v[236:239] offset:4096
	s_waitcnt vmcnt(10)
	ds_write_b128 v197, v[240:243] offset:5120
	s_waitcnt vmcnt(9)
	ds_write_b128 v198, v[244:247] offset:6144
	s_waitcnt vmcnt(8)
	ds_write_b128 v199, v[248:251] offset:7168
	s_waitcnt vmcnt(7)
	ds_write_b128 v196, v[252:255] offset:8192
	s_waitcnt vmcnt(6)
	ds_write_b128 v197, a[64:67] offset:9216
	s_waitcnt vmcnt(5)
	ds_write_b128 v198, a[68:71] offset:10240
	s_waitcnt vmcnt(4)
	ds_write_b128 v199, a[72:75] offset:11264
	s_waitcnt vmcnt(3)
	ds_write_b128 v196, a[76:79] offset:12288
	s_waitcnt vmcnt(2)
	ds_write_b128 v197, a[80:83] offset:13312
	s_waitcnt vmcnt(1)
	ds_write_b128 v198, a[84:87] offset:14336
	s_waitcnt vmcnt(0)
	ds_write_b128 v199, a[88:91] offset:15360
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_read_b128 a[64:67], v200
	ds_read_b128 a[72:75], v200 offset:4096
	ds_read_b128 a[80:83], v200 offset:8192
	ds_read_b128 a[88:91], v200 offset:12288
	ds_read_b128 a[68:71], v201
	ds_read_b128 a[76:79], v201 offset:4096
	ds_read_b128 a[84:87], v201 offset:8192
	ds_read_b128 a[92:95], v201 offset:12288
	ds_read_b128 a[96:99], v202
	ds_read_b128 a[104:107], v202 offset:4096
	ds_read_b128 a[112:115], v202 offset:8192
	ds_read_b128 a[120:123], v202 offset:12288
	ds_read_b128 a[100:103], v203
	ds_read_b128 a[108:111], v203 offset:4096
	ds_read_b128 a[116:119], v203 offset:8192
	ds_read_b128 a[124:127], v203 offset:12288
	.loc	1 381 39                        ; bench.py:381:39
	s_waitcnt lgkmcnt(11)
	v_mfma_f32_16x16x128_f8f6f4 v[162:165], a[64:71], v[2:9], 0
	.loc	1 395 24                        ; bench.py:395:24
	buffer_load_dwordx4 v[178:181], v168, s[12:15], 0 offen
	buffer_load_dwordx4 v[182:185], v170, s[12:15], 0 offen
	buffer_load_dwordx4 v[236:239], v167, s[12:15], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[170:173], v169, s[12:15], 0 offen
	buffer_load_dwordx4 v[240:243], v1, s[12:15], 0 offen
	buffer_load_dwordx4 v[244:247], v34, s[12:15], 0 offen
	buffer_load_dwordx4 v[248:251], v35, s[12:15], 0 offen
	buffer_load_dwordx4 v[174:177], v36, s[12:15], 0 offen
	v_accvgpr_read_b32 v1, a149
	.loc	1 381 39                        ; bench.py:381:39
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x128_f8f6f4 v[252:255], a[96:103], v[10:17], v[162:165]
	.loc	1 395 24                        ; bench.py:395:24
	buffer_load_dwordx4 v[228:231], v37, s[12:15], 0 offen
	buffer_load_dwordx4 v[186:189], v38, s[12:15], 0 offen
	buffer_load_dwordx4 v[204:207], v39, s[12:15], 0 offen
	s_nop 3
	buffer_load_dwordx4 v[162:165], v40, s[12:15], 0 offen
	buffer_load_dwordx4 v[208:211], v41, s[12:15], 0 offen
	buffer_load_dwordx4 v[34:37], v166, s[12:15], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[38:41], v222, s[12:15], 0 offen
	buffer_load_dwordx4 v[166:169], v225, s[12:15], 0 offen
	v_accvgpr_read_b32 v222, a150
	s_waitcnt lgkmcnt(0)
	; wave barrier
	v_accvgpr_read_b32 v225, a151
	s_waitcnt vmcnt(11)
	ds_write2st64_b64 v1, v[178:179], v[240:241] offset1:8
	ds_write2st64_b64 v222, v[180:181], v[242:243] offset1:8
	.loc	1 381 39                        ; bench.py:381:39
	v_mfma_f32_16x16x128_f8f6f4 v[178:181], a[72:79], v[2:9], 0
	.loc	1 395 24                        ; bench.py:395:24
	s_waitcnt vmcnt(10)
	ds_write2st64_b64 v225, v[182:183], v[244:245] offset0:2 offset1:10
	v_accvgpr_read_b32 v182, a152
	ds_write2st64_b64 v182, v[184:185], v[246:247] offset0:2 offset1:10
	s_waitcnt vmcnt(9)
	ds_write2st64_b64 v227, v[236:237], v[248:249] offset0:4 offset1:12
	ds_write2st64_b64 v226, v[238:239], v[250:251] offset0:4 offset1:12
	s_waitcnt vmcnt(3)
	ds_write2st64_b64 v1, v[228:229], v[208:209] offset0:16 offset1:24
	ds_write2st64_b64 v222, v[230:231], v[210:211] offset0:16 offset1:24
	s_waitcnt vmcnt(2)
	ds_write2st64_b64 v225, v[186:187], v[34:35] offset0:18 offset1:26
	ds_write2st64_b64 v182, v[188:189], v[36:37] offset0:18 offset1:26
	s_waitcnt vmcnt(1)
	ds_write2st64_b64 v227, v[204:205], v[38:39] offset0:20 offset1:28
	.loc	1 381 39                        ; bench.py:381:39
	v_mfma_f32_16x16x128_f8f6f4 v[34:37], a[104:111], v[10:17], v[178:181]
	.loc	1 395 24                        ; bench.py:395:24
	ds_write2st64_b64 v226, v[206:207], v[40:41] offset0:20 offset1:28
	.loc	1 362 27                        ; bench.py:362:27
	v_add_u32_e32 v1, s93, v105
	.loc	1 362 36 is_stmt 0              ; bench.py:362:36
	v_add_u32_e32 v222, 51, v1
	v_add_u32_e32 v225, 50, v1
	v_add_u32_e32 v228, 49, v1
	v_add_u32_e32 v229, 48, v1
	v_cmp_gt_i32_e32 vcc, s92, v222
	.loc	1 381 39 is_stmt 1              ; bench.py:381:39
	v_mfma_f32_16x16x128_f8f6f4 v[178:181], a[64:71], v[18:25], 0
	.loc	1 362 36                        ; bench.py:362:36
	v_add_u32_e32 v222, 35, v1
	v_cmp_gt_i32_e64 s[0:1], s92, v225
	v_add_u32_e32 v225, 34, v1
	v_cmp_gt_i32_e64 s[6:7], s92, v228
	v_add_u32_e32 v228, 33, v1
	v_cmp_gt_i32_e64 s[10:11], s92, v229
	v_add_u32_e32 v229, 32, v1
	.loc	1 381 39                        ; bench.py:381:39
	v_mfma_f32_16x16x128_f8f6f4 v[38:41], a[80:87], v[2:9], 0
	.loc	1 362 36                        ; bench.py:362:36
	v_cmp_gt_i32_e64 s[14:15], s92, v222
	v_add_u32_e32 v222, 19, v1
	v_cmp_gt_i32_e64 s[16:17], s92, v225
	v_add_u32_e32 v225, 18, v1
	v_cmp_gt_i32_e64 s[18:19], s92, v228
	v_add_u32_e32 v228, 17, v1
	v_cmp_gt_i32_e64 s[20:21], s92, v229
	.loc	1 381 39                        ; bench.py:381:39
	v_mfma_f32_16x16x128_f8f6f4 v[208:211], a[88:95], v[2:9], 0
	.loc	1 362 36                        ; bench.py:362:36
	v_add_u32_e32 v229, 16, v1
	v_cmp_gt_i32_e64 s[22:23], s92, v222
	v_add_u32_e32 v222, 3, v1
	v_cmp_gt_i32_e64 s[24:25], s92, v225
	v_add_u32_e32 v225, 2, v1
	v_cmp_gt_i32_e64 s[26:27], s92, v1
	v_add_u32_e32 v1, 1, v1
	.loc	1 381 39                        ; bench.py:381:39
	v_mfma_f32_16x16x128_f8f6f4 v[182:185], a[72:79], v[18:25], 0
	.loc	1 362 36                        ; bench.py:362:36
	v_cmp_gt_i32_e64 s[40:41], s92, v1
	v_cmp_gt_i32_e64 s[36:37], s92, v222
	v_cmp_gt_i32_e64 s[38:39], s92, v225
	.loc	1 381 66                        ; bench.py:381:66
	v_mul_f32_e32 v1, s89, v252
	v_mul_f32_e32 v222, s89, v253
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[26:27], s[34:35], s[26:27]
	s_and_b64 s[40:41], s[34:35], s[40:41]
	.loc	1 381 39                        ; bench.py:381:39
	v_mfma_f32_16x16x128_f8f6f4 v[178:181], a[96:103], v[26:33], v[178:181]
	.loc	1 362 36                        ; bench.py:362:36
	v_cmp_gt_i32_e64 s[28:29], s92, v228
	v_cmp_gt_i32_e64 s[30:31], s92, v229
	.loc	1 381 66                        ; bench.py:381:66
	v_mul_f32_e32 v225, s89, v254
	v_mul_f32_e32 v228, s89, v255
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v1, v192, v1, s[26:27]
	v_cndmask_b32_e64 v222, v192, v222, s[40:41]
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[38:39], s[34:35], s[38:39]
	.loc	1 381 39                        ; bench.py:381:39
	v_mfma_f32_16x16x128_f8f6f4 v[186:189], a[80:87], v[18:25], 0
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[36:37], s[34:35], s[36:37]
	.loc	1 381 66                        ; bench.py:381:66
	v_mul_f32_e32 v34, s89, v34
	v_mul_f32_e32 v35, s89, v35
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v225, v192, v225, s[38:39]
	.loc	1 381 66                        ; bench.py:381:66
	v_mul_f32_e32 v178, s89, v178
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v228, v192, v228, s[36:37]
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[30:31], s[34:35], s[30:31]
	.loc	1 381 39                        ; bench.py:381:39
	v_mfma_f32_16x16x128_f8f6f4 v[38:41], a[112:119], v[10:17], v[38:41]
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[28:29], s[34:35], s[28:29]
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v229, v192, v178, s[26:27]
.Ltmp118:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:383:29 ] ]
	v_max_f32_e32 v178, v1, v222
.Ltmp119:
	.loc	1 381 66                        ; bench.py:381:66
	v_mul_f32_e32 v36, s89, v36
	v_mul_f32_e32 v37, s89, v37
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v34, v192, v34, s[30:31]
	v_cndmask_b32_e64 v35, v192, v35, s[28:29]
	.loc	1 381 39                        ; bench.py:381:39
	v_mfma_f32_16x16x128_f8f6f4 v[204:207], a[88:95], v[18:25], 0
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[24:25], s[34:35], s[24:25]
	s_and_b64 s[22:23], s[34:35], s[22:23]
.Ltmp120:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:383:29 ] ]
	v_max3_f32 v178, v178, v225, v228
.Ltmp121:
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v36, v192, v36, s[24:25]
	.loc	1 381 66                        ; bench.py:381:66
	v_mul_f32_e32 v38, s89, v38
	v_mul_f32_e32 v39, s89, v39
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v37, v192, v37, s[22:23]
	.loc	1 381 39                        ; bench.py:381:39
	v_mfma_f32_16x16x128_f8f6f4 v[208:211], a[120:127], v[10:17], v[208:211]
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[20:21], s[34:35], s[20:21]
	s_and_b64 s[18:19], s[34:35], s[18:19]
.Ltmp122:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:383:29 ] ]
	v_max3_f32 v178, v178, v34, v35
.Ltmp123:
	.loc	1 381 66                        ; bench.py:381:66
	v_mul_f32_e32 v40, s89, v40
	v_mul_f32_e32 v41, s89, v41
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v38, v192, v38, s[20:21]
	v_cndmask_b32_e64 v39, v192, v39, s[18:19]
	.loc	1 381 39                        ; bench.py:381:39
	v_mfma_f32_16x16x128_f8f6f4 v[182:185], a[104:111], v[26:33], v[182:185]
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[16:17], s[34:35], s[16:17]
	s_and_b64 s[14:15], s[34:35], s[14:15]
.Ltmp124:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:383:29 ] ]
	v_max3_f32 v178, v178, v36, v37
.Ltmp125:
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v40, v192, v40, s[16:17]
	.loc	1 381 66                        ; bench.py:381:66
	v_mul_f32_e32 v208, s89, v208
	v_mul_f32_e32 v209, s89, v209
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v41, v192, v41, s[14:15]
	.loc	1 381 39                        ; bench.py:381:39
	v_mfma_f32_16x16x128_f8f6f4 v[186:189], a[112:119], v[26:33], v[186:189]
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[10:11], s[34:35], s[10:11]
	s_and_b64 s[6:7], s[34:35], s[6:7]
.Ltmp126:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:383:29 ] ]
	v_max3_f32 v178, v178, v38, v39
.Ltmp127:
	.loc	1 381 66                        ; bench.py:381:66
	v_mul_f32_e32 v210, s89, v210
	v_mul_f32_e32 v211, s89, v211
	v_mul_f32_e32 v179, s89, v179
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v208, v192, v208, s[10:11]
	.loc	1 381 39                        ; bench.py:381:39
	v_mfma_f32_16x16x128_f8f6f4 v[204:207], a[120:127], v[26:33], v[204:207]
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v209, v192, v209, s[6:7]
	.loc	1 363 39                        ; bench.py:363:39
	s_and_b64 s[0:1], s[34:35], s[0:1]
	s_and_b64 vcc, s[34:35], vcc
.Ltmp128:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:383:29 ] ]
	v_max3_f32 v178, v178, v40, v41
.Ltmp129:
	.loc	1 381 66                        ; bench.py:381:66
	v_mul_f32_e32 v180, s89, v180
	v_mul_f32_e32 v181, s89, v181
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v210, v192, v210, s[0:1]
	v_cndmask_b32_e32 v211, v192, v211, vcc
	v_cndmask_b32_e64 v230, v192, v179, s[40:41]
.Ltmp130:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:383:29 ] ]
	v_max3_f32 v178, v178, v208, v209
.Ltmp131:
	.loc	1 381 66                        ; bench.py:381:66
	v_mul_f32_e32 v182, s89, v182
	v_mul_f32_e32 v183, s89, v183
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v180, v192, v180, s[38:39]
	v_cndmask_b32_e64 v181, v192, v181, s[36:37]
.Ltmp132:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:383:29 ] ]
	v_max3_f32 v178, v178, v210, v211
	v_max_f32_e32 v179, v229, v230
.Ltmp133:
	.loc	1 381 66                        ; bench.py:381:66
	v_mul_f32_e32 v184, s89, v184
	v_mul_f32_e32 v185, s89, v185
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v231, v192, v182, s[30:31]
	v_cndmask_b32_e64 v232, v192, v183, s[28:29]
.Ltmp134:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:383:29 ] ]
	v_max3_f32 v179, v179, v180, v181
.Ltmp135:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:383:29 ]
	v_mov_b32_e32 v182, v178
.Ltmp136:
	.loc	1 381 66                        ; bench.py:381:66
	v_mul_f32_e32 v186, s89, v186
	v_mul_f32_e32 v187, s89, v187
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v184, v192, v184, s[24:25]
	v_cndmask_b32_e64 v185, v192, v185, s[22:23]
.Ltmp137:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:383:29 ] ]
	v_max3_f32 v179, v179, v231, v232
.Ltmp138:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:383:29 ]
	v_permlane32_swap_b32_e32 v178, v182
.Ltmp139:
	.loc	1 381 66                        ; bench.py:381:66
	v_mul_f32_e32 v188, s89, v188
	v_mul_f32_e32 v189, s89, v189
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v186, v192, v186, s[20:21]
	v_cndmask_b32_e64 v187, v192, v187, s[18:19]
.Ltmp140:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:383:29 ] ]
	v_max3_f32 v179, v179, v184, v185
	v_max_f32_e32 v182, v182, v182
	v_max_f32_e32 v178, v178, v178
.Ltmp141:
	.loc	1 381 66                        ; bench.py:381:66
	v_mul_f32_e32 v204, s89, v204
	v_mul_f32_e32 v205, s89, v205
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v188, v192, v188, s[16:17]
	v_cndmask_b32_e64 v189, v192, v189, s[14:15]
.Ltmp142:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:383:29 ] ]
	v_max3_f32 v179, v179, v186, v187
	v_max_f32_e32 v178, v178, v182
.Ltmp143:
	.loc	1 381 66                        ; bench.py:381:66
	v_mul_f32_e32 v206, s89, v206
	v_mul_f32_e32 v207, s89, v207
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v204, v192, v204, s[10:11]
	v_cndmask_b32_e64 v205, v192, v205, s[6:7]
.Ltmp144:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:383:29 ] ]
	v_max3_f32 v179, v179, v188, v189
.Ltmp145:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:383:29 ]
	v_mov_b32_e32 v182, v178
.Ltmp146:
	.loc	1 382 42                        ; bench.py:382:42
	v_cndmask_b32_e64 v206, v192, v206, s[0:1]
	v_cndmask_b32_e32 v207, v192, v207, vcc
.Ltmp147:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:383:29 ] ]
	v_max3_f32 v179, v179, v204, v205
.Ltmp148:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:383:29 ]
	v_permlane16_swap_b32_e32 v178, v182
.Ltmp149:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:383:29 ] ]
	v_max3_f32 v179, v179, v206, v207
	v_max_f32_e32 v182, v182, v182
	v_max_f32_e32 v178, v178, v178
	v_max_f32_e32 v178, v178, v182
.Ltmp150:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:383:29 ]
	v_mov_b32_e32 v182, v179
	s_nop 1
	v_permlane32_swap_b32_e32 v179, v182
.Ltmp151:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:383:29 ] ]
	v_max_f32_e32 v182, v182, v182
	v_max_f32_e32 v179, v179, v179
	v_max_f32_e32 v179, v179, v182
.Ltmp152:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:383:29 ]
	v_mov_b32_e32 v182, v179
	s_nop 1
	v_permlane16_swap_b32_e32 v179, v182
.Ltmp153:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:383:29 ] ]
	v_max_f32_e32 v182, v182, v182
	v_max_f32_e32 v179, v179, v179
	v_max_f32_e32 v179, v179, v182
.Ltmp154:
	.loc	1 384 66                        ; bench.py:384:66
	v_cmp_neq_f32_e32 vcc, s94, v178
	v_mov_b32_e32 v182, 0xe0ad78ec
	.loc	1 395 24                        ; bench.py:395:24
	ds_write2st64_b64 v193, v[170:171], v[174:175] offset0:6 offset1:14
	ds_write2st64_b64 v194, v[172:173], v[176:177] offset0:6 offset1:14
	.loc	1 384 66                        ; bench.py:384:66
	v_cndmask_b32_e32 v178, v182, v178, vcc
	v_cmp_neq_f32_e32 vcc, s94, v179
	.loc	1 395 24                        ; bench.py:395:24
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v193, v[162:163], v[166:167] offset0:22 offset1:30
	ds_write2st64_b64 v194, v[164:165], v[168:169] offset0:22 offset1:30
	.loc	1 384 66                        ; bench.py:384:66
	v_cndmask_b32_e32 v179, v182, v179, vcc
	.loc	1 385 43                        ; bench.py:385:43
	v_max_f32_e32 v182, v234, v234
	v_max_f32_e32 v182, v178, v182
	v_max_f32_e32 v178, v233, v233
	v_max_f32_e32 v183, v179, v178
	.loc	1 386 37                        ; bench.py:386:37
	v_sub_f32_e32 v178, v234, v182
	v_sub_f32_e32 v179, v233, v183
	.loc	1 386 29 is_stmt 0              ; bench.py:386:29
	v_mul_f32_e32 v233, 0x3fb8aa3b, v178
	v_cmp_gt_f32_e32 vcc, s95, v233
	.loc	1 387 40 is_stmt 1              ; bench.py:387:40
	v_sub_f32_e32 v1, v1, v182
	v_sub_f32_e32 v251, v184, v183
	.loc	1 386 29                        ; bench.py:386:29
	v_cndmask_b32_e32 v233, 0, v223, vcc
	v_fmac_f32_e32 v233, 0x3fb8aa3b, v178
	v_exp_f32_e32 v178, v233
	v_mul_f32_e32 v233, 0x3fb8aa3b, v179
	v_cmp_gt_f32_e64 s[0:1], s95, v233
	.loc	1 387 35                        ; bench.py:387:35
	v_mul_f32_e32 v184, 0x3fb8aa3b, v1
	.loc	1 387 40 is_stmt 0              ; bench.py:387:40
	v_sub_f32_e32 v222, v222, v182
	.loc	1 386 29 is_stmt 1              ; bench.py:386:29
	v_cndmask_b32_e64 v233, 0, v223, s[0:1]
	v_fmac_f32_e32 v233, 0x3fb8aa3b, v179
	v_exp_f32_e32 v179, v233
	v_cndmask_b32_e32 v233, 0, v224, vcc
	.loc	1 387 35                        ; bench.py:387:35
	v_cmp_gt_f32_e32 vcc, s95, v184
	.loc	1 387 40 is_stmt 0              ; bench.py:387:40
	v_sub_f32_e32 v252, v185, v183
	v_sub_f32_e32 v225, v225, v182
	.loc	1 387 35                        ; bench.py:387:35
	v_cndmask_b32_e32 v184, 0, v223, vcc
	v_fmac_f32_e32 v184, 0x3fb8aa3b, v1
	v_exp_f32_e32 v184, v184
	v_cndmask_b32_e32 v185, 0, v224, vcc
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v254, v188, v183
	v_sub_f32_e32 v188, v204, v183
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v184, v184, v185
	v_mul_f32_e32 v185, 0x3fb8aa3b, v222
	v_cmp_gt_f32_e32 vcc, s95, v185
	v_mul_f32_e32 v204, 0x3fb8aa3b, v225
	.loc	1 386 29 is_stmt 1              ; bench.py:386:29
	v_ldexp_f32 v178, v178, v233
	v_cndmask_b32_e64 v233, 0, v224, s[0:1]
	.loc	1 387 35                        ; bench.py:387:35
	v_cndmask_b32_e32 v185, 0, v223, vcc
	v_cmp_gt_f32_e64 s[0:1], s95, v204
	v_fmac_f32_e32 v185, 0x3fb8aa3b, v222
	v_exp_f32_e32 v185, v185
	v_cndmask_b32_e64 v204, 0, v223, s[0:1]
	v_fmac_f32_e32 v204, 0x3fb8aa3b, v225
	v_exp_f32_e32 v204, v204
	.loc	1 387 40 is_stmt 0              ; bench.py:387:40
	v_sub_f32_e32 v244, v229, v183
	v_sub_f32_e32 v229, v189, v183
	v_sub_f32_e32 v189, v205, v183
	.loc	1 387 35                        ; bench.py:387:35
	v_cndmask_b32_e32 v205, 0, v224, vcc
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v228, v228, v182
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v185, v185, v205
	v_cndmask_b32_e64 v205, 0, v224, s[0:1]
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v34, v34, v182
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v225, v204, v205
	v_mul_f32_e32 v204, 0x3fb8aa3b, v228
	v_cmp_gt_f32_e32 vcc, s95, v204
	v_mul_f32_e32 v205, 0x3fb8aa3b, v34
	v_cmp_gt_f32_e64 s[0:1], s95, v205
	v_cndmask_b32_e32 v204, 0, v223, vcc
	v_fmac_f32_e32 v204, 0x3fb8aa3b, v228
	v_cndmask_b32_e64 v205, 0, v223, s[0:1]
	v_exp_f32_e32 v204, v204
	v_fmac_f32_e32 v205, 0x3fb8aa3b, v34
	v_exp_f32_e32 v34, v205
	v_cndmask_b32_e32 v205, 0, v224, vcc
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v35, v35, v182
	v_sub_f32_e32 v250, v232, v183
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v232, v204, v205
	v_cndmask_b32_e64 v204, 0, v224, s[0:1]
	.loc	1 386 29 is_stmt 1              ; bench.py:386:29
	v_ldexp_f32 v179, v179, v233
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v233, v34, v204
	v_mul_f32_e32 v34, 0x3fb8aa3b, v35
	v_cmp_gt_f32_e32 vcc, s95, v34
	.loc	1 387 40 is_stmt 0              ; bench.py:387:40
	v_sub_f32_e32 v36, v36, v182
	v_sub_f32_e32 v37, v37, v182
	.loc	1 387 35                        ; bench.py:387:35
	v_cndmask_b32_e32 v34, 0, v223, vcc
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v35
	v_mul_f32_e32 v35, 0x3fb8aa3b, v36
	v_cmp_gt_f32_e64 s[0:1], s95, v35
	v_exp_f32_e32 v34, v34
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v38, v38, v182
	.loc	1 387 35                        ; bench.py:387:35
	v_cndmask_b32_e64 v35, 0, v223, s[0:1]
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v36
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e32 v36, 0, v224, vcc
	v_ldexp_f32 v234, v34, v36
	v_cndmask_b32_e64 v34, 0, v224, s[0:1]
	v_ldexp_f32 v235, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v37
	v_cmp_gt_f32_e32 vcc, s95, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v38
	v_cmp_gt_f32_e64 s[0:1], s95, v35
	v_cndmask_b32_e32 v34, 0, v223, vcc
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v37
	v_cndmask_b32_e64 v35, 0, v223, s[0:1]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v38
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e32 v36, 0, v224, vcc
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v39, v39, v182
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v236, v34, v36
	v_cndmask_b32_e64 v34, 0, v224, s[0:1]
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v40, v40, v182
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v237, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v39
	v_cmp_gt_f32_e32 vcc, s95, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v40
	v_cmp_gt_f32_e64 s[0:1], s95, v35
	v_cndmask_b32_e32 v34, 0, v223, vcc
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v39
	v_cndmask_b32_e64 v35, 0, v223, s[0:1]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v40
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e32 v36, 0, v224, vcc
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v41, v41, v182
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v238, v34, v36
	v_cndmask_b32_e64 v34, 0, v224, s[0:1]
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v208, v208, v182
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v239, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v41
	v_cmp_gt_f32_e32 vcc, s95, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v208
	v_cmp_gt_f32_e64 s[0:1], s95, v35
	v_cndmask_b32_e32 v34, 0, v223, vcc
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v41
	v_cndmask_b32_e64 v35, 0, v223, s[0:1]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v208
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e32 v36, 0, v224, vcc
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v209, v209, v182
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v240, v34, v36
	v_cndmask_b32_e64 v34, 0, v224, s[0:1]
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v210, v210, v182
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v241, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v209
	v_cmp_gt_f32_e32 vcc, s95, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v210
	v_cmp_gt_f32_e64 s[0:1], s95, v35
	v_cndmask_b32_e32 v34, 0, v223, vcc
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v209
	v_cndmask_b32_e64 v35, 0, v223, s[0:1]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v210
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e32 v36, 0, v224, vcc
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v211, v211, v182
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v242, v34, v36
	v_cndmask_b32_e64 v34, 0, v224, s[0:1]
	v_ldexp_f32 v243, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v211
	v_cmp_gt_f32_e32 vcc, s95, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v244
	v_cmp_gt_f32_e64 s[0:1], s95, v35
	v_cndmask_b32_e32 v34, 0, v223, vcc
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v211
	v_cndmask_b32_e64 v35, 0, v223, s[0:1]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v244
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e32 v36, 0, v224, vcc
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v230, v230, v183
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v244, v34, v36
	v_cndmask_b32_e64 v34, 0, v224, s[0:1]
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v180, v180, v183
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v245, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v230
	v_cmp_gt_f32_e32 vcc, s95, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v180
	v_cmp_gt_f32_e64 s[0:1], s95, v35
	v_cndmask_b32_e32 v34, 0, v223, vcc
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v230
	v_cndmask_b32_e64 v35, 0, v223, s[0:1]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v180
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e32 v36, 0, v224, vcc
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v181, v181, v183
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v246, v34, v36
	v_cndmask_b32_e64 v34, 0, v224, s[0:1]
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v248, v231, v183
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v247, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v181
	v_cmp_gt_f32_e32 vcc, s95, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v248
	v_cmp_gt_f32_e64 s[0:1], s95, v35
	v_cndmask_b32_e32 v34, 0, v223, vcc
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v181
	v_cndmask_b32_e64 v35, 0, v223, s[0:1]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v248
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e32 v36, 0, v224, vcc
	v_ldexp_f32 v249, v34, v36
	v_cndmask_b32_e64 v34, 0, v224, s[0:1]
	v_ldexp_f32 v248, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v250
	v_cmp_gt_f32_e32 vcc, s95, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v251
	v_cmp_gt_f32_e64 s[0:1], s95, v35
	v_cndmask_b32_e32 v34, 0, v223, vcc
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v250
	v_cndmask_b32_e64 v35, 0, v223, s[0:1]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v251
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e32 v36, 0, v224, vcc
	v_ldexp_f32 v250, v34, v36
	v_cndmask_b32_e64 v34, 0, v224, s[0:1]
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v186, v186, v183
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v251, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v252
	v_cmp_gt_f32_e32 vcc, s95, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v186
	v_cmp_gt_f32_e64 s[0:1], s95, v35
	v_cndmask_b32_e32 v34, 0, v223, vcc
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v252
	v_cndmask_b32_e64 v35, 0, v223, s[0:1]
	v_exp_f32_e32 v34, v34
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v186
	v_exp_f32_e32 v35, v35
	v_cndmask_b32_e32 v36, 0, v224, vcc
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v187, v187, v183
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v253, v34, v36
	v_cndmask_b32_e64 v34, 0, v224, s[0:1]
	v_ldexp_f32 v252, v35, v34
	v_mul_f32_e32 v34, 0x3fb8aa3b, v187
	v_cmp_gt_f32_e32 vcc, s95, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v254
	.loc	1 395 24 is_stmt 1              ; bench.py:395:24
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_read_b64_tr_b8 v[168:169], v212
	ds_read_b64_tr_b8 v[210:211], v214
	ds_read_b64_tr_b8 a[70:71], v215
	ds_read_b64_tr_b8 a[78:79], v216
	.loc	1 387 35                        ; bench.py:387:35
	v_cndmask_b32_e32 v34, 0, v223, vcc
	v_cmp_gt_f32_e64 s[0:1], s95, v35
	v_fmac_f32_e32 v34, 0x3fb8aa3b, v187
	v_exp_f32_e32 v34, v34
	v_cndmask_b32_e64 v35, 0, v223, s[0:1]
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v254
	v_exp_f32_e32 v35, v35
	.loc	1 397 33                        ; bench.py:397:33
	v_cvt_scalef32_pk_fp8_f32 v180, v184, v185, 1.0
	v_cvt_scalef32_pk_fp8_f32 v181, v233, v234, 1.0
	.loc	1 387 35                        ; bench.py:387:35
	v_cndmask_b32_e32 v36, 0, v224, vcc
	.loc	1 397 33                        ; bench.py:397:33
	v_cvt_scalef32_pk_fp8_f32 v180, v225, v232, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v181, v235, v236, 1.0 op_sel:[0,0,0,1]
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v254, v34, v36
	v_cndmask_b32_e64 v34, 0, v224, s[0:1]
	.loc	1 397 33                        ; bench.py:397:33
	v_permlane32_swap_b32_e32 v180, v181
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v255, v35, v34
	.loc	1 397 33                        ; bench.py:397:33
	s_nop 0
	v_permlane16_swap_b32_e32 v180, v181
	.loc	1 397 43 is_stmt 0              ; bench.py:397:43
	v_pk_mul_f32 v[36:37], v[160:161], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[158:159], v[178:179] op_sel_hi:[1,0]
	.loc	1 397 33                        ; bench.py:397:33
	v_cvt_scalef32_pk_fp8_f32 v170, v237, v238, 1.0
	v_cvt_scalef32_pk_fp8_f32 v171, v241, v242, 1.0
	.loc	1 395 24 is_stmt 1              ; bench.py:395:24
	ds_read_b64_tr_b8 v[172:173], v212 offset:8192
	ds_read_b64_tr_b8 v[174:175], v212 offset:8320
	ds_read_b64_tr_b8 v[176:177], v212 offset:128
	ds_read_b64_tr_b8 v[186:187], v213
	.loc	1 397 43                        ; bench.py:397:43
	s_waitcnt lgkmcnt(7)
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[168:169], v[180:181], v[34:37]
	.loc	1 397 33 is_stmt 0              ; bench.py:397:33
	v_cvt_scalef32_pk_fp8_f32 v170, v239, v240, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v171, v243, v244, 1.0 op_sel:[0,0,0,1]
	.loc	1 387 40 is_stmt 1              ; bench.py:387:40
	v_sub_f32_e32 v231, v206, v183
	.loc	1 397 33                        ; bench.py:397:33
	s_nop 0
	v_permlane32_swap_b32_e32 v170, v171
	s_nop 1
	v_permlane16_swap_b32_e32 v170, v171
	.loc	1 387 40                        ; bench.py:387:40
	v_sub_f32_e32 v1, v207, v183
	.loc	1 397 43                        ; bench.py:397:43
	s_waitcnt lgkmcnt(3)
	v_mfma_f32_16x16x32_fp8_fp8 v[158:161], v[172:173], v[170:171], v[34:37]
	.loc	1 395 24                        ; bench.py:395:24
	ds_read_b64_tr_b8 v[204:205], v213 offset:8192
	ds_read_b64_tr_b8 v[206:207], v213 offset:8320
	ds_read_b64_tr_b8 v[208:209], v213 offset:128
	.loc	1 397 43                        ; bench.py:397:43
	v_pk_mul_f32 v[36:37], v[156:157], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[154:155], v[178:179] op_sel_hi:[1,0]
	.loc	1 395 24                        ; bench.py:395:24
	ds_read_b64_tr_b8 a[64:65], v214 offset:8192
	ds_read_b64_tr_b8 a[66:67], v214 offset:8320
	ds_read_b64_tr_b8 a[68:69], v214 offset:128
	.loc	1 397 43                        ; bench.py:397:43
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[186:187], v[180:181], v[34:37]
	.loc	1 395 24                        ; bench.py:395:24
	ds_read_b64_tr_b8 a[72:73], v215 offset:8192
	ds_read_b64_tr_b8 a[74:75], v215 offset:8320
	ds_read_b64_tr_b8 a[76:77], v215 offset:128
	ds_read_b64_tr_b8 a[84:85], v217
	ds_read_b64_tr_b8 a[92:93], v218
	ds_read_b64_tr_b8 a[100:101], v219
	.loc	1 397 43                        ; bench.py:397:43
	s_waitcnt lgkmcnt(11)
	v_mfma_f32_16x16x32_fp8_fp8 v[154:157], v[204:205], v[170:171], v[34:37]
	.loc	1 387 35                        ; bench.py:387:35
	v_mul_f32_e32 v222, 0x3fb8aa3b, v229
	v_cmp_gt_f32_e32 vcc, s95, v222
	.loc	1 395 24                        ; bench.py:395:24
	ds_read_b64_tr_b8 a[86:87], v217 offset:8192
	ds_read_b64_tr_b8 a[88:89], v217 offset:8320
	ds_read_b64_tr_b8 a[90:91], v217 offset:128
	.loc	1 397 43                        ; bench.py:397:43
	v_pk_mul_f32 v[36:37], v[152:153], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[150:151], v[178:179] op_sel_hi:[1,0]
	.loc	1 387 35                        ; bench.py:387:35
	v_cndmask_b32_e32 v38, 0, v223, vcc
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v229
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[210:211], v[180:181], v[34:37]
	.loc	1 395 24                        ; bench.py:395:24
	ds_read_b64_tr_b8 v[228:229], v216 offset:8192
	ds_read_b64_tr_b8 a[80:81], v216 offset:8320
	ds_read_b64_tr_b8 a[82:83], v216 offset:128
	ds_read_b64_tr_b8 a[94:95], v218 offset:8192
	ds_read_b64_tr_b8 a[96:97], v218 offset:8320
	ds_read_b64_tr_b8 a[98:99], v218 offset:128
	ds_read_b64_tr_b8 a[102:103], v219 offset:8192
	ds_read_b64_tr_b8 a[104:105], v219 offset:8320
	ds_read_b64_tr_b8 a[106:107], v219 offset:128
	.loc	1 397 43                        ; bench.py:397:43
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_fp8_fp8 v[150:153], a[64:65], v[170:171], v[34:37]
	.loc	1 387 35                        ; bench.py:387:35
	v_exp_f32_e32 v38, v38
	v_cndmask_b32_e32 v39, 0, v224, vcc
	v_mul_f32_e32 v40, 0x3fb8aa3b, v189
	.loc	1 397 43                        ; bench.py:397:43
	v_pk_mul_f32 v[36:37], v[148:149], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[146:147], v[178:179] op_sel_hi:[1,0]
	.loc	1 387 35                        ; bench.py:387:35
	v_ldexp_f32 v41, v38, v39
	v_mul_f32_e32 v38, 0x3fb8aa3b, v188
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[70:71], v[180:181], v[34:37]
	.loc	1 387 35                        ; bench.py:387:35
	v_cmp_gt_f32_e32 vcc, s95, v38
	.loc	1 397 33                        ; bench.py:397:33
	v_cvt_scalef32_pk_fp8_f32 v162, v245, v246, 1.0
	v_cvt_scalef32_pk_fp8_f32 v163, v248, v250, 1.0
	.loc	1 397 43 is_stmt 0              ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[146:149], a[72:73], v[170:171], v[34:37]
	.loc	1 387 35 is_stmt 1              ; bench.py:387:35
	v_cndmask_b32_e32 v38, 0, v223, vcc
	v_cndmask_b32_e32 v39, 0, v224, vcc
	v_cmp_gt_f32_e32 vcc, s95, v40
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v188
	.loc	1 397 43                        ; bench.py:397:43
	v_pk_mul_f32 v[36:37], v[144:145], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[142:143], v[178:179] op_sel_hi:[1,0]
	.loc	1 387 35                        ; bench.py:387:35
	v_cndmask_b32_e32 v40, 0, v223, vcc
	v_exp_f32_e32 v38, v38
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[78:79], v[180:181], v[34:37]
	.loc	1 387 35                        ; bench.py:387:35
	v_fmac_f32_e32 v40, 0x3fb8aa3b, v189
	v_exp_f32_e32 v40, v40
	v_ldexp_f32 v164, v38, v39
	.loc	1 397 43                        ; bench.py:397:43
	s_waitcnt lgkmcnt(8)
	v_mfma_f32_16x16x32_fp8_fp8 v[142:145], v[228:229], v[170:171], v[34:37]
	.loc	1 387 35                        ; bench.py:387:35
	v_cndmask_b32_e32 v38, 0, v224, vcc
	v_ldexp_f32 v165, v40, v38
	v_mul_f32_e32 v38, 0x3fb8aa3b, v231
	v_cmp_gt_f32_e32 vcc, s95, v38
	.loc	1 397 43                        ; bench.py:397:43
	v_pk_mul_f32 v[36:37], v[140:141], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[138:139], v[178:179] op_sel_hi:[1,0]
	.loc	1 387 35                        ; bench.py:387:35
	v_mul_f32_e32 v40, 0x3fb8aa3b, v1
	v_cndmask_b32_e32 v38, 0, v223, vcc
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[84:85], v[180:181], v[34:37]
	.loc	1 387 35                        ; bench.py:387:35
	v_cndmask_b32_e32 v39, 0, v224, vcc
	v_cmp_gt_f32_e32 vcc, s95, v40
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v231
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[138:141], a[86:87], v[170:171], v[34:37]
	.loc	1 387 35                        ; bench.py:387:35
	v_cndmask_b32_e32 v40, 0, v223, vcc
	v_exp_f32_e32 v38, v38
	v_fmac_f32_e32 v40, 0x3fb8aa3b, v1
	v_exp_f32_e32 v1, v40
	.loc	1 397 43                        ; bench.py:397:43
	v_pk_mul_f32 v[36:37], v[136:137], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[134:135], v[178:179] op_sel_hi:[1,0]
	.loc	1 397 33 is_stmt 0              ; bench.py:397:33
	v_cvt_scalef32_pk_fp8_f32 v162, v247, v249, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v163, v251, v253, 1.0 op_sel:[0,0,0,1]
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[92:93], v[180:181], v[34:37]
	.loc	1 397 33                        ; bench.py:397:33
	s_nop 0
	v_permlane32_swap_b32_e32 v162, v163
	.loc	1 397 43                        ; bench.py:397:43
	v_mov_b32_e32 v40, v179
	s_waitcnt lgkmcnt(5)
	v_mfma_f32_16x16x32_fp8_fp8 v[134:137], a[94:95], v[170:171], v[34:37]
	.loc	1 387 35 is_stmt 1              ; bench.py:387:35
	v_ldexp_f32 v166, v38, v39
	v_cndmask_b32_e32 v38, 0, v224, vcc
	.loc	1 397 33                        ; bench.py:397:33
	v_permlane16_swap_b32_e32 v162, v163
	.loc	1 397 43 is_stmt 0              ; bench.py:397:43
	v_pk_mul_f32 v[36:37], v[132:133], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[130:131], v[178:179] op_sel_hi:[1,0]
	.loc	1 387 35 is_stmt 1              ; bench.py:387:35
	v_ldexp_f32 v1, v1, v38
	.loc	1 397 33                        ; bench.py:397:33
	v_cvt_scalef32_pk_fp8_f32 v38, v252, v254, 1.0
	.loc	1 397 43 is_stmt 0              ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[100:101], v[180:181], v[34:37]
	.loc	1 397 33                        ; bench.py:397:33
	v_cvt_scalef32_pk_fp8_f32 v39, v164, v165, 1.0
	v_cvt_scalef32_pk_fp8_f32 v38, v255, v41, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v39, v166, v1, 1.0 op_sel:[0,0,0,1]
	.loc	1 397 43                        ; bench.py:397:43
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_fp8_fp8 v[130:133], a[102:103], v[170:171], v[34:37]
	.loc	1 397 33                        ; bench.py:397:33
	v_permlane32_swap_b32_e32 v38, v39
	s_nop 1
	v_permlane16_swap_b32_e32 v38, v39
	.loc	1 397 43                        ; bench.py:397:43
	v_pk_mul_f32 v[36:37], v[128:129], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[126:127], v[178:179] op_sel_hi:[1,0]
.Ltmp155:
	.loc	2 263 15 is_stmt 1              ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_add_f32_e32 v167, v184, v185
	v_add_f32_e32 v167, v225, v167
.Ltmp156:
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[176:177], v[180:181], v[34:37]
	v_accvgpr_read_b32 v185, a131
	v_accvgpr_read_b32 v184, a130
	v_mfma_f32_16x16x32_fp8_fp8 v[126:129], v[174:175], v[170:171], v[34:37]
	s_nop 4
	v_mul_f32_e64 v36, v124, v178
	v_mul_f32_e64 v37, v125, v178
	v_pk_mul_f32 v[34:35], v[122:123], v[178:179] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[208:209], v[180:181], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[122:125], v[206:207], v[170:171], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v120, v178
	v_mul_f32_e64 v37, v121, v178
	v_pk_mul_f32 v[34:35], v[118:119], v[178:179] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[68:69], v[180:181], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[118:121], a[66:67], v[170:171], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v116, v178
	v_mul_f32_e64 v37, v117, v178
	v_pk_mul_f32 v[34:35], v[114:115], v[178:179] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[76:77], v[180:181], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[114:117], a[74:75], v[170:171], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v112, v178
	v_mul_f32_e64 v37, v113, v178
	v_pk_mul_f32 v[34:35], v[110:111], v[178:179] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[82:83], v[180:181], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[110:113], a[80:81], v[170:171], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v108, v178
	v_mul_f32_e64 v37, v109, v178
	v_pk_mul_f32 v[34:35], v[106:107], v[178:179] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[90:91], v[180:181], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[106:109], a[88:89], v[170:171], v[34:37]
	s_nop 6
	v_accvgpr_read_b32 v34, a140
	v_accvgpr_read_b32 v35, a141
	v_accvgpr_read_b32 v36, a142
	v_accvgpr_read_b32 v37, a143
	v_pk_mul_f32 v[36:37], v[36:37], v[178:179] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[34:35], v[178:179] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[98:99], v[180:181], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[96:97], v[170:171], v[34:37]
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
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[106:107], v[180:181], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[104:105], v[170:171], v[34:37]
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
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[172:173], v[38:39], v[34:37]
	s_nop 7
	v_accvgpr_write_b32 a135, v37
	v_accvgpr_write_b32 a134, v36
	v_accvgpr_write_b32 a133, v35
	v_accvgpr_write_b32 a132, v34
	v_pk_mul_f32 v[36:37], v[102:103], v[40:41] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[100:101], v[40:41] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[186:187], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[100:103], v[204:205], v[38:39], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v98, v40
	v_mul_f32_e64 v37, v99, v40
	v_pk_mul_f32 v[34:35], v[96:97], v[40:41] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[210:211], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[96:99], a[64:65], v[38:39], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v94, v40
	v_mul_f32_e64 v37, v95, v40
	v_pk_mul_f32 v[34:35], v[92:93], v[40:41] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[70:71], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[92:95], a[72:73], v[38:39], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v90, v40
	v_mul_f32_e64 v37, v91, v40
	v_pk_mul_f32 v[34:35], v[88:89], v[40:41] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[78:79], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[88:91], v[228:229], v[38:39], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v86, v40
	v_mul_f32_e64 v37, v87, v40
	v_pk_mul_f32 v[34:35], v[84:85], v[40:41] op_sel_hi:[1,0]
	v_mov_b32_e32 v84, v74
.Ltmp157:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_add_f32_e32 v74, v232, v167
.Ltmp158:
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[84:85], v[162:163], v[34:37]
.Ltmp159:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_add_f32_e32 v74, v233, v74
	v_add_f32_e32 v167, v234, v74
	v_mov_b32_e32 v74, v84
.Ltmp160:
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[84:87], a[86:87], v[38:39], v[34:37]
.Ltmp161:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_add_f32_e32 v167, v235, v167
	v_mov_b32_e32 v234, v182
	v_mov_b32_e32 v233, v183
.Ltmp162:
	.loc	1 397 43                        ; bench.py:397:43
	s_nop 0
	v_pk_mul_f32 v[36:37], v[72:73], v[40:41] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[70:71], v[40:41] op_sel_hi:[1,0]
.Ltmp163:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_add_f32_e32 v70, v236, v167
	v_add_f32_e32 v70, v237, v70
.Ltmp164:
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[92:93], v[162:163], v[34:37]
.Ltmp165:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_add_f32_e32 v167, v238, v70
	v_add_f32_e32 v167, v239, v167
.Ltmp166:
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[70:73], a[94:95], v[38:39], v[34:37]
	s_nop 4
	v_mul_f32_e64 v36, v68, v40
	v_mul_f32_e64 v37, v69, v40
	v_pk_mul_f32 v[34:35], v[66:67], v[40:41] op_sel_hi:[1,0]
.Ltmp167:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_add_f32_e32 v66, v240, v167
	v_add_f32_e32 v66, v241, v66
.Ltmp168:
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[100:101], v[162:163], v[34:37]
.Ltmp169:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_add_f32_e32 v167, v242, v66
	v_add_f32_e32 v167, v243, v167
	v_add_f32_e32 v167, v244, v167
.Ltmp170:
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[66:69], a[102:103], v[38:39], v[34:37]
	s_nop 3
	v_mul_f32_e64 v36, v64, v40
	v_mul_f32_e64 v37, v65, v40
	v_pk_mul_f32 v[34:35], v[62:63], v[40:41] op_sel_hi:[1,0]
.Ltmp171:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_add_f32_e32 v62, v245, v246
	v_add_f32_e32 v168, v247, v62
.Ltmp172:
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[176:177], v[162:163], v[34:37]
.Ltmp173:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_add_f32_e32 v168, v249, v168
.Ltmp174:
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[62:65], v[174:175], v[38:39], v[34:37]
	s_nop 5
	v_mul_f32_e64 v36, v60, v40
	v_mul_f32_e64 v37, v61, v40
	v_pk_mul_f32 v[34:35], v[58:59], v[40:41] op_sel_hi:[1,0]
.Ltmp175:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_add_f32_e32 v58, v248, v168
	v_add_f32_e32 v58, v250, v58
.Ltmp176:
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], v[208:209], v[162:163], v[34:37]
.Ltmp177:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_add_f32_e32 v168, v251, v58
	v_add_f32_e32 v168, v253, v168
.Ltmp178:
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[58:61], v[206:207], v[38:39], v[34:37]
	s_nop 4
	v_mul_f32_e64 v36, v56, v40
	v_mul_f32_e64 v37, v57, v40
	v_pk_mul_f32 v[34:35], v[54:55], v[40:41] op_sel_hi:[1,0]
.Ltmp179:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_add_f32_e32 v54, v252, v168
	v_add_f32_e32 v54, v254, v54
.Ltmp180:
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[68:69], v[162:163], v[34:37]
.Ltmp181:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_add_f32_e32 v168, v255, v54
	v_add_f32_e32 v41, v41, v168
.Ltmp182:
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[54:57], a[66:67], v[38:39], v[34:37]
	s_nop 4
	v_mul_f32_e64 v36, v82, v40
	v_mul_f32_e64 v37, v83, v40
	v_pk_mul_f32 v[34:35], v[80:81], v[40:41] op_sel_hi:[1,0]
.Ltmp183:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_add_f32_e32 v41, v164, v41
	v_add_f32_e32 v41, v165, v41
.Ltmp184:
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[76:77], v[162:163], v[34:37]
.Ltmp185:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_add_f32_e32 v41, v166, v41
	v_add_f32_e32 v1, v1, v41
.Ltmp186:
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[80:83], a[74:75], v[38:39], v[34:37]
	s_nop 4
	v_mul_f32_e64 v36, v78, v40
	v_mul_f32_e64 v37, v79, v40
	v_pk_mul_f32 v[34:35], v[76:77], v[40:41] op_sel_hi:[1,0]
.Ltmp187:
	.loc	2 293 36                        ; standard.py:293:36 @[ bench.py:388:43 ]
	v_mov_b32_e32 v41, v167
	s_nop 1
	v_permlane32_swap_b32_e32 v167, v41
.Ltmp188:
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[82:83], v[162:163], v[34:37]
.Ltmp189:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_add_f32_e32 v164, v167, v41
.Ltmp190:
	.loc	2 293 36                        ; standard.py:293:36 @[ bench.py:388:43 ]
	v_mov_b32_e32 v166, v164
	s_nop 1
	v_permlane16_swap_b32_e32 v164, v166
.Ltmp191:
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[76:79], a[80:81], v[38:39], v[34:37]
	s_nop 2
	v_mul_f32_e64 v36, v52, v40
	v_mul_f32_e64 v37, v53, v40
	v_pk_mul_f32 v[34:35], v[50:51], v[40:41] op_sel_hi:[1,0]
.Ltmp192:
	.loc	2 293 36                        ; standard.py:293:36 @[ bench.py:388:43 ]
	v_mov_b32_e32 v41, v1
.Ltmp193:
	.loc	1 397 43                        ; bench.py:397:43
	s_nop 0
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[90:91], v[162:163], v[34:37]
	v_mfma_f32_16x16x32_fp8_fp8 v[50:53], a[88:89], v[38:39], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v48, v40
	v_mul_f32_e64 v37, v49, v40
	v_pk_mul_f32 v[34:35], v[46:47], v[40:41] op_sel_hi:[1,0]
.Ltmp194:
	.loc	2 293 36                        ; standard.py:293:36 @[ bench.py:388:43 ]
	v_permlane32_swap_b32_e32 v1, v41
.Ltmp195:
	.loc	1 397 43                        ; bench.py:397:43
	s_nop 0
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[98:99], v[162:163], v[34:37]
.Ltmp196:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_add_f32_e32 v165, v1, v41
.Ltmp197:
	.loc	2 293 36                        ; standard.py:293:36 @[ bench.py:388:43 ]
	v_mov_b32_e32 v167, v165
	s_nop 1
	v_permlane16_swap_b32_e32 v165, v167
.Ltmp198:
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[46:49], a[96:97], v[38:39], v[34:37]
	s_nop 2
	v_mul_f32_e64 v36, v44, v40
	v_mul_f32_e64 v37, v45, v40
	v_pk_mul_f32 v[34:35], v[42:43], v[40:41] op_sel_hi:[1,0]
.Ltmp199:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:388:43 ] ]
	v_pk_add_f32 v[40:41], v[164:165], v[166:167]
.Ltmp200:
	.loc	1 397 43                        ; bench.py:397:43
	s_nop 0
	v_mfma_f32_16x16x32_fp8_fp8 v[34:37], a[106:107], v[162:163], v[34:37]
	.loc	1 388 36                        ; bench.py:388:36
	v_fma_f32 v184, v184, v178, v40
	v_fma_f32 v185, v185, v179, v41
	.loc	1 397 43                        ; bench.py:397:43
	v_mfma_f32_16x16x32_fp8_fp8 v[42:45], a[104:105], v[38:39], v[34:37]
	s_branch .LBB0_5
.LBB0_8:                                ; %Flow
	.loc	1 0 43 is_stmt 0                ; bench.py:0:43
	v_accvgpr_read_b32 v165, a128
	v_accvgpr_read_b32 v74, a144
	v_accvgpr_read_b32 v166, a146
.LBB0_9:                                ; %._crit_edge
	v_accvgpr_write_b32 a101, v79
	v_accvgpr_write_b32 a100, v78
	v_accvgpr_write_b32 a99, v77
	v_accvgpr_write_b32 a98, v76
	v_accvgpr_read_b32 v76, a145
	.loc	1 352 17 is_stmt 1              ; bench.py:352:17
	v_or_b32_e32 v2, 8, v74
	.loc	1 409 27                        ; bench.py:409:27
	s_lshl_b32 s42, s90, 10
	v_lshlrev_b32_e32 v18, 6, v166
	.loc	1 341 26                        ; bench.py:341:26
	v_or_b32_e32 v1, 4, v76
	.loc	1 409 27                        ; bench.py:409:27
	s_add_i32 s42, s42, s91
	v_or_b32_e32 v34, v18, v74
	v_or_b32_e32 v18, v2, v18
	v_lshlrev_b32_e32 v19, 10, v1
	.loc	1 409 16 is_stmt 0              ; bench.py:409:16
	v_add_lshl_u32 v34, v34, s42, 1
	v_bfrev_b32_e32 v232, 1
	.loc	1 401 22 is_stmt 1              ; bench.py:401:22
	v_cmp_gt_i32_e64 s[36:37], s88, v76
	.loc	1 409 16                        ; bench.py:409:16
	v_add_lshl_u32 v18, v18, s42, 1
	.loc	1 341 26                        ; bench.py:341:26
	v_or_b32_e32 v3, 8, v76
	.loc	1 409 27                        ; bench.py:409:27
	v_or_b32_e32 v35, v19, v74
	.loc	1 409 16 is_stmt 0              ; bench.py:409:16
	s_and_b32 s5, s5, 0xffff
	s_mov_b32 s7, 0x27000
	s_mov_b32 s6, 0x7ffffffe
	v_cndmask_b32_e64 v34, v232, v34, s[36:37]
	v_cndmask_b32_e64 v18, v232, v18, s[36:37]
	.loc	1 409 27                        ; bench.py:409:27
	v_lshlrev_b32_e32 v20, 10, v3
	v_or_b32_e32 v19, v19, v2
	.loc	1 409 16                        ; bench.py:409:16
	buffer_load_dwordx4 v[170:173], v34, s[4:7], 0 offen
	buffer_load_dwordx4 v[174:177], v18, s[4:7], 0 offen
	v_add_lshl_u32 v18, v35, s42, 1
	.loc	1 401 22 is_stmt 1              ; bench.py:401:22
	v_cmp_gt_i32_e32 vcc, s88, v1
	v_accvgpr_write_b32 a96, v184
	.loc	1 341 26                        ; bench.py:341:26
	v_or_b32_e32 v4, 12, v76
	.loc	1 409 27                        ; bench.py:409:27
	v_or_b32_e32 v36, v20, v74
	.loc	1 409 16 is_stmt 0              ; bench.py:409:16
	v_cndmask_b32_e32 v1, v232, v18, vcc
	v_add_lshl_u32 v18, v19, s42, 1
	v_accvgpr_write_b32 a97, v185
	.loc	1 409 27                        ; bench.py:409:27
	v_lshlrev_b32_e32 v21, 10, v4
	v_or_b32_e32 v20, v20, v2
	.loc	1 409 16                        ; bench.py:409:16
	v_cndmask_b32_e32 v18, v232, v18, vcc
	buffer_load_dwordx4 v[178:181], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[182:185], v18, s[4:7], 0 offen
	v_add_lshl_u32 v1, v36, s42, 1
	.loc	1 401 22 is_stmt 1              ; bench.py:401:22
	v_cmp_gt_i32_e64 s[10:11], s88, v3
	.loc	1 341 26                        ; bench.py:341:26
	v_or_b32_e32 v5, 16, v76
	.loc	1 409 27                        ; bench.py:409:27
	v_or_b32_e32 v37, v21, v74
	.loc	1 409 16 is_stmt 0              ; bench.py:409:16
	v_cndmask_b32_e64 v1, v232, v1, s[10:11]
	v_add_lshl_u32 v3, v20, s42, 1
	.loc	1 409 27                        ; bench.py:409:27
	v_lshlrev_b32_e32 v22, 10, v5
	v_or_b32_e32 v21, v21, v2
	.loc	1 409 16                        ; bench.py:409:16
	v_cndmask_b32_e64 v3, v232, v3, s[10:11]
	buffer_load_dwordx4 v[186:189], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[190:193], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v37, s42, 1
	.loc	1 401 22 is_stmt 1              ; bench.py:401:22
	v_cmp_gt_i32_e64 s[12:13], s88, v4
	.loc	1 341 26                        ; bench.py:341:26
	v_or_b32_e32 v6, 20, v76
	.loc	1 409 27                        ; bench.py:409:27
	v_or_b32_e32 v38, v22, v74
	.loc	1 409 16 is_stmt 0              ; bench.py:409:16
	v_cndmask_b32_e64 v1, v232, v1, s[12:13]
	v_add_lshl_u32 v3, v21, s42, 1
	.loc	1 409 27                        ; bench.py:409:27
	v_lshlrev_b32_e32 v23, 10, v6
	v_or_b32_e32 v22, v22, v2
	.loc	1 409 16                        ; bench.py:409:16
	v_cndmask_b32_e64 v3, v232, v3, s[12:13]
	buffer_load_dwordx4 v[18:21], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[34:37], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v38, s42, 1
	.loc	1 401 22 is_stmt 1              ; bench.py:401:22
	v_cmp_gt_i32_e64 s[38:39], s88, v5
	.loc	1 341 26                        ; bench.py:341:26
	v_or_b32_e32 v7, 24, v76
	.loc	1 409 27                        ; bench.py:409:27
	v_or_b32_e32 v39, v23, v74
	.loc	1 409 16 is_stmt 0              ; bench.py:409:16
	v_cndmask_b32_e64 v1, v232, v1, s[38:39]
	v_add_lshl_u32 v3, v22, s42, 1
	.loc	1 409 27                        ; bench.py:409:27
	v_lshlrev_b32_e32 v24, 10, v7
	v_or_b32_e32 v23, v23, v2
	.loc	1 409 16                        ; bench.py:409:16
	v_cndmask_b32_e64 v3, v232, v3, s[38:39]
	buffer_load_dwordx4 v[194:197], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[198:201], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v39, s42, 1
	.loc	1 401 22 is_stmt 1              ; bench.py:401:22
	v_cmp_gt_i32_e64 s[14:15], s88, v6
	.loc	1 341 26                        ; bench.py:341:26
	v_or_b32_e32 v8, 28, v76
	.loc	1 409 27                        ; bench.py:409:27
	v_or_b32_e32 v40, v24, v74
	.loc	1 409 16 is_stmt 0              ; bench.py:409:16
	v_cndmask_b32_e64 v1, v232, v1, s[14:15]
	v_add_lshl_u32 v3, v23, s42, 1
	.loc	1 409 27                        ; bench.py:409:27
	v_lshlrev_b32_e32 v25, 10, v8
	v_or_b32_e32 v24, v24, v2
	.loc	1 409 16                        ; bench.py:409:16
	v_cndmask_b32_e64 v3, v232, v3, s[14:15]
	buffer_load_dwordx4 v[202:205], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[206:209], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v40, s42, 1
	.loc	1 401 22 is_stmt 1              ; bench.py:401:22
	v_cmp_gt_i32_e64 s[16:17], s88, v7
	.loc	1 341 26                        ; bench.py:341:26
	v_or_b32_e32 v9, 32, v76
	.loc	1 409 27                        ; bench.py:409:27
	v_or_b32_e32 v41, v25, v74
	.loc	1 409 16 is_stmt 0              ; bench.py:409:16
	v_cndmask_b32_e64 v1, v232, v1, s[16:17]
	v_add_lshl_u32 v3, v24, s42, 1
	.loc	1 409 27                        ; bench.py:409:27
	v_lshlrev_b32_e32 v26, 10, v9
	v_or_b32_e32 v25, v25, v2
	.loc	1 409 16                        ; bench.py:409:16
	v_cndmask_b32_e64 v3, v232, v3, s[16:17]
	buffer_load_dwordx4 v[210:213], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[214:217], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v41, s42, 1
	.loc	1 401 22 is_stmt 1              ; bench.py:401:22
	v_cmp_gt_i32_e64 s[18:19], s88, v8
	.loc	1 341 26                        ; bench.py:341:26
	v_or_b32_e32 v10, 36, v76
	.loc	1 409 27                        ; bench.py:409:27
	v_or_b32_e32 v162, v26, v74
	.loc	1 409 16 is_stmt 0              ; bench.py:409:16
	v_cndmask_b32_e64 v1, v232, v1, s[18:19]
	v_add_lshl_u32 v3, v25, s42, 1
	.loc	1 409 27                        ; bench.py:409:27
	v_lshlrev_b32_e32 v27, 10, v10
	v_or_b32_e32 v26, v26, v2
	.loc	1 409 16                        ; bench.py:409:16
	v_cndmask_b32_e64 v3, v232, v3, s[18:19]
	buffer_load_dwordx4 v[22:25], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[38:41], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v162, s42, 1
	.loc	1 401 22 is_stmt 1              ; bench.py:401:22
	v_cmp_gt_i32_e64 s[0:1], s88, v9
	.loc	1 341 26                        ; bench.py:341:26
	v_or_b32_e32 v11, 40, v76
	.loc	1 409 27                        ; bench.py:409:27
	v_or_b32_e32 v163, v27, v74
	.loc	1 409 16 is_stmt 0              ; bench.py:409:16
	v_cndmask_b32_e64 v1, v232, v1, s[0:1]
	v_add_lshl_u32 v3, v26, s42, 1
	.loc	1 409 27                        ; bench.py:409:27
	v_lshlrev_b32_e32 v28, 10, v11
	v_or_b32_e32 v27, v27, v2
	.loc	1 409 16                        ; bench.py:409:16
	v_cndmask_b32_e64 v3, v232, v3, s[0:1]
	buffer_load_dwordx4 v[218:221], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[222:225], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v163, s42, 1
	.loc	1 401 22 is_stmt 1              ; bench.py:401:22
	v_cmp_gt_i32_e64 s[20:21], s88, v10
	.loc	1 341 26                        ; bench.py:341:26
	v_or_b32_e32 v12, 44, v76
	.loc	1 409 27                        ; bench.py:409:27
	v_or_b32_e32 v164, v28, v74
	.loc	1 409 16 is_stmt 0              ; bench.py:409:16
	v_cndmask_b32_e64 v1, v232, v1, s[20:21]
	v_add_lshl_u32 v3, v27, s42, 1
	.loc	1 409 27                        ; bench.py:409:27
	v_lshlrev_b32_e32 v29, 10, v12
	v_or_b32_e32 v28, v28, v2
	.loc	1 409 16                        ; bench.py:409:16
	v_cndmask_b32_e64 v3, v232, v3, s[20:21]
	buffer_load_dwordx4 v[226:229], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[236:239], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v164, s42, 1
	.loc	1 401 22 is_stmt 1              ; bench.py:401:22
	v_cmp_gt_i32_e64 s[22:23], s88, v11
	.loc	1 341 26                        ; bench.py:341:26
	v_or_b32_e32 v13, 48, v76
	.loc	1 381 29                        ; bench.py:381:29
	v_lshlrev_b32_e32 v17, 9, v165
	v_mov_b32_e32 v78, v165
	.loc	1 409 27                        ; bench.py:409:27
	v_or_b32_e32 v165, v29, v74
	.loc	1 409 16 is_stmt 0              ; bench.py:409:16
	v_cndmask_b32_e64 v1, v232, v1, s[22:23]
	v_add_lshl_u32 v3, v28, s42, 1
	.loc	1 409 27                        ; bench.py:409:27
	v_lshlrev_b32_e32 v30, 10, v13
	v_or_b32_e32 v29, v29, v2
	.loc	1 409 16                        ; bench.py:409:16
	v_cndmask_b32_e64 v3, v232, v3, s[22:23]
	buffer_load_dwordx4 v[240:243], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[244:247], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v165, s42, 1
	.loc	1 401 22 is_stmt 1              ; bench.py:401:22
	v_cmp_gt_i32_e64 s[24:25], s88, v12
	.loc	1 341 26                        ; bench.py:341:26
	v_or_b32_e32 v14, 52, v76
	v_mov_b32_e32 v77, v166
	.loc	1 409 27                        ; bench.py:409:27
	v_or_b32_e32 v166, v30, v74
	.loc	1 409 16 is_stmt 0              ; bench.py:409:16
	v_cndmask_b32_e64 v1, v232, v1, s[24:25]
	v_add_lshl_u32 v3, v29, s42, 1
	.loc	1 409 27                        ; bench.py:409:27
	v_lshlrev_b32_e32 v31, 10, v14
	v_or_b32_e32 v30, v30, v2
	.loc	1 409 16                        ; bench.py:409:16
	v_cndmask_b32_e64 v3, v232, v3, s[24:25]
	buffer_load_dwordx4 v[26:29], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[162:165], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v166, s42, 1
	.loc	1 401 22 is_stmt 1              ; bench.py:401:22
	v_cmp_gt_i32_e64 s[40:41], s88, v13
	.loc	1 409 27                        ; bench.py:409:27
	v_or_b32_e32 v167, v31, v74
	.loc	1 409 16 is_stmt 0              ; bench.py:409:16
	v_add_lshl_u32 v3, v30, s42, 1
	v_cndmask_b32_e64 v1, v232, v1, s[40:41]
	.loc	1 409 27                        ; bench.py:409:27
	v_or_b32_e32 v31, v31, v2
	.loc	1 409 16                        ; bench.py:409:16
	v_cndmask_b32_e64 v3, v232, v3, s[40:41]
	buffer_load_dwordx4 v[10:13], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[248:251], v3, s[4:7], 0 offen
	v_add_lshl_u32 v1, v167, s42, 1
	.loc	1 401 22 is_stmt 1              ; bench.py:401:22
	v_cmp_gt_i32_e64 s[26:27], s88, v14
	.loc	1 341 26                        ; bench.py:341:26
	v_or_b32_e32 v15, 56, v76
	.loc	1 409 16                        ; bench.py:409:16
	v_add_lshl_u32 v3, v31, s42, 1
	v_cndmask_b32_e64 v1, v232, v1, s[26:27]
	.loc	1 409 27 is_stmt 0              ; bench.py:409:27
	v_lshlrev_b32_e32 v32, 10, v15
	.loc	1 409 16                        ; bench.py:409:16
	v_cndmask_b32_e64 v3, v232, v3, s[26:27]
	buffer_load_dwordx4 v[252:255], v1, s[4:7], 0 offen
	buffer_load_dwordx4 a[64:67], v3, s[4:7], 0 offen
	.loc	1 409 27                        ; bench.py:409:27
	v_or_b32_e32 v168, v32, v74
	.loc	1 341 26 is_stmt 1              ; bench.py:341:26
	v_or_b32_e32 v16, 60, v76
	.loc	1 409 27                        ; bench.py:409:27
	v_or_b32_e32 v32, v32, v2
	.loc	1 409 16 is_stmt 0              ; bench.py:409:16
	v_add_lshl_u32 v1, v168, s42, 1
	.loc	1 401 22 is_stmt 1              ; bench.py:401:22
	v_cmp_gt_i32_e64 s[28:29], s88, v15
	.loc	1 409 27                        ; bench.py:409:27
	v_lshlrev_b32_e32 v33, 10, v16
	.loc	1 409 16 is_stmt 0              ; bench.py:409:16
	v_add_lshl_u32 v3, v32, s42, 1
	v_cndmask_b32_e64 v1, v232, v1, s[28:29]
	.loc	1 409 27                        ; bench.py:409:27
	v_or_b32_e32 v169, v33, v74
	.loc	1 409 16                        ; bench.py:409:16
	v_cndmask_b32_e64 v3, v232, v3, s[28:29]
	buffer_load_dwordx4 a[68:71], v1, s[4:7], 0 offen
	buffer_load_dwordx4 a[72:75], v3, s[4:7], 0 offen
	.loc	1 409 27                        ; bench.py:409:27
	v_or_b32_e32 v33, v33, v2
	.loc	1 409 16                        ; bench.py:409:16
	v_add_lshl_u32 v1, v169, s42, 1
	.loc	1 401 22 is_stmt 1              ; bench.py:401:22
	v_cmp_gt_i32_e64 s[30:31], s88, v16
	.loc	1 409 16                        ; bench.py:409:16
	v_add_lshl_u32 v3, v33, s42, 1
	.loc	1 424 27                        ; bench.py:424:27
	v_mov_b32_e32 v9, 0x54000
	.loc	1 409 16                        ; bench.py:409:16
	v_cndmask_b32_e64 v1, v232, v1, s[30:31]
	v_cndmask_b32_e64 v3, v232, v3, s[30:31]
	buffer_load_dwordx4 v[30:33], v1, s[4:7], 0 offen
	buffer_load_dwordx4 v[166:169], v3, s[4:7], 0 offen
	.loc	1 354 16                        ; bench.py:354:16
	v_mov_b32_e32 v1, 0x210
	v_cndmask_b32_e64 v1, v1, 0, s[2:3]
	v_accvgpr_read_b32 v3, a147
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
	.loc	1 409 16                        ; bench.py:409:16
	v_lshlrev_b32_e32 v1, 5, v0
	v_xor_b32_e32 v7, v1, v77
	.loc	1 354 16                        ; bench.py:354:16
	v_add_u32_e32 v5, 0, v5
	.loc	1 409 16                        ; bench.py:409:16
	v_add_u32_e32 v8, 0, v7
	.loc	1 354 16                        ; bench.py:354:16
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_read_b128 a[8:11], v3
	ds_read_b128 a[0:3], v3 offset:256
	ds_read_b128 a[80:83], v3 offset:8192
	ds_read_b128 a[76:79], v3 offset:8448
	ds_read_b128 a[20:23], v4
	ds_read_b128 a[12:15], v4 offset:256
	ds_read_b128 a[88:91], v4 offset:8192
	ds_read_b128 a[84:87], v4 offset:8448
	ds_read_b128 a[32:35], v5
	ds_read_b128 a[28:31], v5 offset:256
	ds_read_b128 a[4:7], v5 offset:8192
	ds_read_b128 a[92:95], v5 offset:8448
	ds_read_b128 a[40:43], v6
	ds_read_b128 a[36:39], v6 offset:256
	ds_read_b128 a[24:27], v6 offset:8192
	ds_read_b128 a[16:19], v6 offset:8448
	.loc	1 409 16                        ; bench.py:409:16
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
	ds_read_b128 a[56:59], v3
	ds_read_b128 a[44:47], v3 offset:256
	ds_read_b128 a[64:67], v4
	ds_read_b128 a[48:51], v4 offset:256
	ds_read_b128 a[68:71], v5
	ds_read_b128 a[52:55], v5 offset:256
	ds_read_b128 a[72:75], v6
	ds_read_b128 a[60:63], v6 offset:256
	s_movk_i32 s2, 0x3800
	.loc	1 424 27                        ; bench.py:424:27
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
	v_or_b32_e32 v22, v5, v74
	v_or_b32_e32 v5, v5, v2
	v_or_b32_e32 v23, v6, v74
	v_or_b32_e32 v6, v6, v2
	v_or_b32_e32 v21, v7, v74
	v_or_b32_e32 v7, v7, v2
	v_or_b32_e32 v24, v8, v74
	v_or_b32_e32 v8, v8, v2
	v_or_b32_e32 v25, v9, v74
	v_or_b32_e32 v9, v9, v2
	v_or_b32_e32 v30, v10, v74
	v_or_b32_e32 v31, v10, v2
	v_or_b32_e32 v10, v11, v74
	v_or_b32_e32 v11, v11, v2
	v_or_b32_e32 v33, v12, v2
	v_or_b32_e32 v162, v13, v74
	v_or_b32_e32 v163, v13, v2
	v_or_b32_e32 v164, v14, v74
	v_or_b32_e32 v14, v14, v2
	v_or_b32_e32 v13, v15, v2
	v_or_b32_e32 v178, v16, v2
	v_or_b32_e32 v180, v17, v2
	v_or_b32_e32 v194, v18, v2
	.loc	1 424 16 is_stmt 0              ; bench.py:424:16
	v_add_lshl_u32 v2, v19, s42, 1
	v_add_lshl_u32 v3, v3, s42, 1
	s_and_b32 s45, s45, 0xffff
	s_mov_b32 s46, s6
	s_mov_b32 s47, s7
	v_cndmask_b32_e64 v2, v232, v2, s[36:37]
	v_cndmask_b32_e64 v3, v232, v3, s[36:37]
	buffer_load_dwordx4 v[34:37], v2, s[44:47], 0 offen
	buffer_load_dwordx4 v[38:41], v3, s[44:47], 0 offen
	v_add_lshl_u32 v3, v4, s42, 1
	v_add_lshl_u32 v4, v21, s42, 1
	v_cndmask_b32_e64 v4, v232, v4, s[38:39]
	v_add_lshl_u32 v7, v7, s42, 1
	v_cndmask_b32_e64 v7, v232, v7, s[38:39]
	buffer_load_dwordx4 v[226:229], v4, s[44:47], 0 offen
	buffer_load_dwordx4 v[236:239], v7, s[44:47], 0 offen
	v_add_lshl_u32 v4, v10, s42, 1
	.loc	1 424 27                        ; bench.py:424:27
	v_or_b32_e32 v32, v12, v74
	v_or_b32_e32 v12, v15, v74
	.loc	1 424 16                        ; bench.py:424:16
	v_cndmask_b32_e64 v4, v232, v4, s[0:1]
	buffer_load_dwordx4 v[240:243], v4, s[44:47], 0 offen
	v_add_lshl_u32 v4, v12, s42, 1
	v_cndmask_b32_e64 v4, v232, v4, s[40:41]
	buffer_load_dwordx4 v[244:247], v4, s[44:47], 0 offen
	v_add_lshl_u32 v4, v11, s42, 1
	v_cndmask_b32_e64 v4, v232, v4, s[0:1]
	buffer_load_dwordx4 v[248:251], v4, s[44:47], 0 offen
	v_add_lshl_u32 v4, v13, s42, 1
	v_cndmask_b32_e64 v4, v232, v4, s[40:41]
	buffer_load_dwordx4 v[252:255], v4, s[44:47], 0 offen
	v_add_lshl_u32 v2, v20, s42, 1
	v_cndmask_b32_e32 v2, v232, v2, vcc
	v_cndmask_b32_e32 v3, v232, v3, vcc
	.loc	1 424 27                        ; bench.py:424:27
	v_or_b32_e32 v181, v18, v74
	.loc	1 424 16                        ; bench.py:424:16
	buffer_load_dwordx4 v[18:21], v2, s[44:47], 0 offen
	buffer_load_dwordx4 v[186:189], v3, s[44:47], 0 offen
	v_add_lshl_u32 v2, v22, s42, 1
	v_add_lshl_u32 v3, v5, s42, 1
	v_add_lshl_u32 v15, v32, s42, 1
	.loc	1 424 27                        ; bench.py:424:27
	v_or_b32_e32 v165, v16, v74
	.loc	1 424 16                        ; bench.py:424:16
	v_cndmask_b32_e64 v2, v232, v2, s[10:11]
	v_cndmask_b32_e64 v3, v232, v3, s[10:11]
	v_cndmask_b32_e64 v15, v232, v15, s[20:21]
	v_add_lshl_u32 v16, v33, s42, 1
	buffer_load_dwordx4 v[170:173], v2, s[44:47], 0 offen
	buffer_load_dwordx4 v[26:29], v3, s[44:47], 0 offen
	v_add_lshl_u32 v3, v6, s42, 1
	v_add_lshl_u32 v6, v24, s42, 1
	v_add_lshl_u32 v7, v8, s42, 1
	v_cndmask_b32_e64 v16, v232, v16, s[20:21]
	buffer_load_dwordx4 v[210:213], v15, s[44:47], 0 offen
	buffer_load_dwordx4 v[202:205], v16, s[44:47], 0 offen
	v_add_lshl_u32 v15, v162, s42, 1
	.loc	1 424 27                        ; bench.py:424:27
	v_or_b32_e32 v179, v17, v74
	.loc	1 424 16                        ; bench.py:424:16
	v_cndmask_b32_e64 v6, v232, v6, s[14:15]
	v_cndmask_b32_e64 v7, v232, v7, s[14:15]
	v_cndmask_b32_e64 v15, v232, v15, s[22:23]
	v_add_lshl_u32 v16, v163, s42, 1
	buffer_load_dwordx4 v[222:225], v6, s[44:47], 0 offen
	buffer_load_dwordx4 v[198:201], v7, s[44:47], 0 offen
	v_add_lshl_u32 v6, v25, s42, 1
	v_add_lshl_u32 v7, v9, s42, 1
	v_cndmask_b32_e64 v16, v232, v16, s[22:23]
	buffer_load_dwordx4 v[190:193], v15, s[44:47], 0 offen
	buffer_load_dwordx4 v[174:177], v16, s[44:47], 0 offen
	v_add_lshl_u32 v15, v164, s42, 1
	v_add_lshl_u32 v162, v165, s42, 1
	v_add_lshl_u32 v163, v178, s42, 1
	v_add_lshl_u32 v164, v179, s42, 1
	v_add_lshl_u32 v165, v180, s42, 1
	v_add_lshl_u32 v178, v181, s42, 1
	v_add_lshl_u32 v179, v194, s42, 1
	v_cndmask_b32_e64 v6, v232, v6, s[16:17]
	v_cndmask_b32_e64 v7, v232, v7, s[16:17]
	v_cndmask_b32_e64 v162, v232, v162, s[26:27]
	v_cndmask_b32_e64 v163, v232, v163, s[26:27]
	v_cndmask_b32_e64 v164, v232, v164, s[28:29]
	v_cndmask_b32_e64 v165, v232, v165, s[28:29]
	v_cndmask_b32_e64 v178, v232, v178, s[30:31]
	v_cndmask_b32_e64 v230, v232, v179, s[30:31]
	v_add_lshl_u32 v2, v23, s42, 1
	buffer_load_dwordx4 v[182:185], v6, s[44:47], 0 offen
	buffer_load_dwordx4 v[166:169], v7, s[44:47], 0 offen
	v_add_lshl_u32 v6, v30, s42, 1
	v_add_lshl_u32 v7, v31, s42, 1
	v_add_lshl_u32 v14, v14, s42, 1
	buffer_load_dwordx4 v[218:221], v162, s[44:47], 0 offen
	buffer_load_dwordx4 v[214:217], v163, s[44:47], 0 offen
	buffer_load_dwordx4 v[206:209], v164, s[44:47], 0 offen
	buffer_load_dwordx4 v[194:197], v165, s[44:47], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[178:181], v178, s[44:47], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[162:165], v230, s[44:47], 0 offen
	v_or_b32_e32 v230, v1, v75
	v_cndmask_b32_e64 v2, v232, v2, s[12:13]
	v_cndmask_b32_e64 v3, v232, v3, s[12:13]
	v_cndmask_b32_e64 v6, v232, v6, s[18:19]
	v_cndmask_b32_e64 v7, v232, v7, s[18:19]
	v_cndmask_b32_e64 v15, v232, v15, s[24:25]
	v_cndmask_b32_e64 v14, v232, v14, s[24:25]
	v_add_u32_e32 v231, 0, v230
	buffer_load_dwordx4 v[10:13], v2, s[44:47], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[2:5], v3, s[44:47], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[22:25], v6, s[44:47], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[6:9], v7, s[44:47], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[30:33], v15, s[44:47], 0 offen
	s_nop 0
	buffer_load_dwordx4 v[14:17], v14, s[44:47], 0 offen
	s_waitcnt vmcnt(29) lgkmcnt(0)
	; wave barrier
	ds_write2st64_b64 v231, v[34:35], v[226:227] offset1:16
	s_waitcnt vmcnt(26)
	ds_write2st64_b64 v231, v[240:241], v[244:245] offset0:32 offset1:48
	v_xad_u32 v34, v230, 8, 0
	ds_write2st64_b64 v34, v[36:37], v[228:229] offset1:16
	ds_write2st64_b64 v34, v[242:243], v[246:247] offset0:32 offset1:48
	v_xad_u32 v34, v230, 16, 0
	ds_write2st64_b64 v34, v[38:39], v[236:237] offset1:16
	s_waitcnt vmcnt(24)
	ds_write2st64_b64 v34, v[248:249], v[252:253] offset0:32 offset1:48
	.loc	1 410 31 is_stmt 1              ; bench.py:410:31
	v_mfma_f32_16x16x32_bf16 v[34:37], a[56:59], a[8:11], 0
	.loc	1 424 16                        ; bench.py:424:16
	v_xad_u32 v38, v230, 24, 0
	ds_write2st64_b64 v38, v[40:41], v[238:239] offset1:16
	.loc	1 341 26                        ; bench.py:341:26
	v_or_b32_e32 v227, 1, v105
	.loc	1 410 31                        ; bench.py:410:31
	v_mfma_f32_16x16x32_bf16 v[34:37], a[64:67], a[20:23], v[34:37]
	.loc	1 401 22                        ; bench.py:401:22
	v_cmp_gt_i32_e32 vcc, s88, v227
	.loc	1 341 26                        ; bench.py:341:26
	v_or_b32_e32 v227, 2, v105
	.loc	1 401 22                        ; bench.py:401:22
	v_cmp_gt_i32_e64 s[0:1], s88, v227
	.loc	1 410 31                        ; bench.py:410:31
	v_mfma_f32_16x16x32_bf16 v[34:37], a[68:71], a[32:35], v[34:37]
	.loc	1 403 41                        ; bench.py:403:41
	v_cmp_ge_u32_e64 s[2:3], v78, v227
	.loc	1 401 22                        ; bench.py:401:22
	v_cmp_gt_i32_e64 s[4:5], s88, v105
	.loc	1 403 41                        ; bench.py:403:41
	v_cmp_ge_u32_e64 s[10:11], v78, v105
	.loc	1 410 31                        ; bench.py:410:31
	v_mfma_f32_16x16x32_bf16 v[34:37], a[72:75], a[40:43], v[34:37]
	.loc	1 403 41                        ; bench.py:403:41
	v_cmp_gt_u32_e64 s[12:13], v78, v105
	.loc	1 341 26                        ; bench.py:341:26
	v_or_b32_e32 v227, 3, v105
	.loc	1 401 22                        ; bench.py:401:22
	v_cmp_gt_i32_e64 s[14:15], s88, v227
	.loc	1 410 31                        ; bench.py:410:31
	v_mfma_f32_16x16x32_bf16 v[34:37], a[44:47], a[0:3], v[34:37]
	.loc	1 403 41                        ; bench.py:403:41
	v_cmp_ge_u32_e64 s[16:17], v78, v227
	.loc	1 403 18 is_stmt 0              ; bench.py:403:18
	s_and_b64 s[4:5], s[10:11], s[4:5]
	s_and_b64 s[10:11], s[12:13], vcc
	.loc	1 410 31 is_stmt 1              ; bench.py:410:31
	v_mfma_f32_16x16x32_bf16 v[34:37], a[48:51], a[12:15], v[34:37]
	.loc	1 403 18                        ; bench.py:403:18
	s_and_b64 s[2:3], s[2:3], s[0:1]
	s_and_b64 s[12:13], s[16:17], s[14:15]
	.loc	1 411 34                        ; bench.py:411:34
	v_mov_b32_e32 v227, 0xff800000
	.loc	1 410 31                        ; bench.py:410:31
	v_mfma_f32_16x16x32_bf16 v[34:37], a[52:55], a[28:31], v[34:37]
	.loc	1 403 18                        ; bench.py:403:18
	s_and_b64 vcc, s[34:35], s[4:5]
	s_and_b64 s[0:1], s[34:35], s[10:11]
	s_and_b64 s[2:3], s[34:35], s[2:3]
	.loc	1 410 31                        ; bench.py:410:31
	v_mfma_f32_16x16x32_bf16 v[34:37], a[60:63], a[36:39], v[34:37]
	.loc	1 403 18                        ; bench.py:403:18
	s_and_b64 s[4:5], s[34:35], s[12:13]
	.loc	1 415 21                        ; bench.py:415:21
	v_mov_b32_e32 v241, 0x42800000
	v_not_b32_e32 v240, 63
	.loc	1 424 16                        ; bench.py:424:16
	ds_write2st64_b64 v38, v[250:251], v[254:255] offset0:32 offset1:48
	v_accvgpr_write_b32 a125, v103
	v_accvgpr_write_b32 a124, v102
	v_accvgpr_write_b32 a123, v101
	v_accvgpr_write_b32 a122, v100
	.loc	1 410 58                        ; bench.py:410:58
	v_mul_f32_e32 v39, s89, v34
	v_mul_f32_e32 v40, s89, v35
	v_mul_f32_e32 v41, s89, v36
	v_mul_f32_e32 v226, s89, v37
	.loc	1 410 31 is_stmt 0              ; bench.py:410:31
	v_mfma_f32_16x16x32_bf16 v[34:37], a[56:59], a[80:83], 0
	.loc	1 411 34 is_stmt 1              ; bench.py:411:34
	v_cndmask_b32_e32 v39, v227, v39, vcc
	v_cndmask_b32_e64 v40, v227, v40, s[0:1]
	v_cndmask_b32_e64 v41, v227, v41, s[2:3]
	.loc	1 410 31                        ; bench.py:410:31
	v_mfma_f32_16x16x32_bf16 v[34:37], a[64:67], a[88:91], v[34:37]
	.loc	1 411 34                        ; bench.py:411:34
	v_cndmask_b32_e64 v226, v227, v226, s[4:5]
	v_accvgpr_write_b32 a121, v99
	v_accvgpr_write_b32 a120, v98
	.loc	1 410 31                        ; bench.py:410:31
	v_mfma_f32_16x16x32_bf16 v[34:37], a[68:71], a[4:7], v[34:37]
	v_accvgpr_write_b32 a119, v97
	v_accvgpr_write_b32 a118, v96
	v_accvgpr_write_b32 a117, v95
	v_mfma_f32_16x16x32_bf16 v[34:37], a[72:75], a[24:27], v[34:37]
	v_accvgpr_write_b32 a116, v94
	v_accvgpr_write_b32 a115, v93
	v_accvgpr_write_b32 a114, v92
	v_mfma_f32_16x16x32_bf16 v[34:37], a[44:47], a[76:79], v[34:37]
	v_accvgpr_write_b32 a113, v91
	v_accvgpr_write_b32 a112, v90
	v_accvgpr_write_b32 a111, v89
	v_mfma_f32_16x16x32_bf16 v[34:37], a[48:51], a[84:87], v[34:37]
	v_accvgpr_write_b32 a110, v88
	v_accvgpr_write_b32 a109, v87
	v_accvgpr_write_b32 a108, v86
	v_mfma_f32_16x16x32_bf16 v[34:37], a[52:55], a[92:95], v[34:37]
	v_accvgpr_write_b32 a107, v85
	v_accvgpr_write_b32 a106, v84
	v_accvgpr_write_b32 a105, v83
	v_mfma_f32_16x16x32_bf16 v[34:37], a[60:63], a[16:19], v[34:37]
	v_accvgpr_write_b32 a104, v82
	v_accvgpr_write_b32 a103, v81
	v_accvgpr_write_b32 a102, v80
	v_mov_b32_e32 v230, v78
	.loc	1 434 38                        ; bench.py:434:38
	s_and_b32 s9, s9, 0xffff
	s_mov_b32 s10, s6
	s_mov_b32 s11, s7
	.loc	1 410 58                        ; bench.py:410:58
	s_nop 0
	v_mul_f32_e32 v34, s89, v34
	v_mul_f32_e32 v35, s89, v35
	.loc	1 411 34                        ; bench.py:411:34
	v_cndmask_b32_e32 v238, v227, v34, vcc
	v_cndmask_b32_e64 v239, v227, v35, s[0:1]
	s_mov_b32 s0, 0xff800000
.Ltmp201:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:412:21 ] ]
	v_max3_f32 v34, v39, v40, v41
.Ltmp202:
	.loc	1 410 58                        ; bench.py:410:58
	v_mul_f32_e32 v36, s89, v36
.Ltmp203:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:412:21 ] ]
	v_max3_f32 v34, v34, v226, s0
.Ltmp204:
	.loc	1 411 34                        ; bench.py:411:34
	v_cndmask_b32_e64 v237, v227, v36, s[2:3]
.Ltmp205:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:412:21 ]
	v_mov_b32_e32 v36, v34
	s_nop 1
	v_permlane32_swap_b32_e32 v34, v36
.Ltmp206:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:412:21 ] ]
	v_max_f32_e32 v36, v36, v36
	v_max_f32_e32 v34, v34, v34
	v_max_f32_e32 v34, v34, v36
.Ltmp207:
	.loc	1 410 58                        ; bench.py:410:58
	v_mul_f32_e32 v37, s89, v37
.Ltmp208:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:412:21 ]
	v_mov_b32_e32 v36, v34
.Ltmp209:
	.loc	1 411 34                        ; bench.py:411:34
	v_cndmask_b32_e64 v236, v227, v37, s[4:5]
.Ltmp210:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:412:21 ] ]
	v_max3_f32 v35, v238, v239, v237
.Ltmp211:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:412:21 ]
	v_permlane16_swap_b32_e32 v34, v36
.Ltmp212:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:412:21 ] ]
	v_max3_f32 v35, v35, v236, s0
	v_max_f32_e32 v36, v36, v36
	v_max_f32_e32 v34, v34, v34
	v_max_f32_e32 v34, v34, v36
.Ltmp213:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:412:21 ]
	v_mov_b32_e32 v36, v35
	s_nop 1
	v_permlane32_swap_b32_e32 v35, v36
.Ltmp214:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:412:21 ] ]
	v_max_f32_e32 v36, v36, v36
	v_max_f32_e32 v35, v35, v35
	v_max_f32_e32 v35, v35, v36
.Ltmp215:
	.loc	2 191 40                        ; standard.py:191:40 @[ bench.py:412:21 ]
	v_mov_b32_e32 v36, v35
	s_nop 1
	v_permlane16_swap_b32_e32 v35, v36
.Ltmp216:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ bench.py:412:21 ] ]
	v_max_f32_e32 v36, v36, v36
	v_max_f32_e32 v35, v35, v35
	v_max_f32_e32 v35, v35, v36
.Ltmp217:
	.loc	1 413 58                        ; bench.py:413:58
	v_mov_b32_e32 v36, 0xe0ad78ec
	v_cmp_neq_f32_e32 vcc, s0, v34
	s_mov_b32 s2, 0xc2fc0000
	s_nop 0
	v_cndmask_b32_e32 v34, v36, v34, vcc
	v_cmp_neq_f32_e32 vcc, s0, v35
	s_nop 1
	v_cndmask_b32_e32 v35, v36, v35, vcc
	.loc	1 414 35                        ; bench.py:414:35
	v_max_f32_e32 v36, v234, v234
	v_max_f32_e32 v34, v34, v36
	v_max_f32_e32 v36, v233, v233
	v_max_f32_e32 v242, v35, v36
	.loc	1 415 29                        ; bench.py:415:29
	v_sub_f32_e32 v35, v234, v34
	.loc	1 415 21 is_stmt 0              ; bench.py:415:21
	v_mul_f32_e32 v36, 0x3fb8aa3b, v35
	v_cmp_gt_f32_e32 vcc, s2, v36
	.loc	1 416 32 is_stmt 1              ; bench.py:416:32
	v_sub_f32_e32 v37, v41, v34
	.loc	1 415 29                        ; bench.py:415:29
	v_sub_f32_e32 v243, v233, v242
	.loc	1 415 21 is_stmt 0              ; bench.py:415:21
	v_cndmask_b32_e32 v36, 0, v241, vcc
	v_fmac_f32_e32 v36, 0x3fb8aa3b, v35
	v_exp_f32_e32 v35, v36
	v_cndmask_b32_e32 v36, 0, v240, vcc
	v_ldexp_f32 v228, v35, v36
	.loc	1 416 32 is_stmt 1              ; bench.py:416:32
	v_sub_f32_e32 v35, v39, v34
	.loc	1 416 27 is_stmt 0              ; bench.py:416:27
	v_mul_f32_e32 v38, 0x3fb8aa3b, v35
	v_cmp_gt_f32_e32 vcc, s2, v38
	.loc	1 416 32                        ; bench.py:416:32
	v_sub_f32_e32 v36, v40, v34
	.loc	1 416 27                        ; bench.py:416:27
	s_nop 0
	v_cndmask_b32_e32 v38, 0, v241, vcc
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v35
	v_exp_f32_e32 v35, v38
	v_cndmask_b32_e32 v39, 0, v240, vcc
	.loc	1 416 32                        ; bench.py:416:32
	v_sub_f32_e32 v38, v226, v34
	v_sub_f32_e32 v34, 0xff800000, v34
	.loc	1 416 27                        ; bench.py:416:27
	v_ldexp_f32 v231, v35, v39
	v_mul_f32_e32 v35, 0x3fb8aa3b, v36
	v_cmp_gt_f32_e32 vcc, s2, v35
	s_nop 1
	v_cndmask_b32_e32 v35, 0, v241, vcc
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v36
	v_mul_f32_e32 v36, 0x3fb8aa3b, v37
	v_cmp_gt_f32_e64 s[0:1], s2, v36
	v_exp_f32_e32 v35, v35
	s_nop 0
	v_cndmask_b32_e64 v36, 0, v241, s[0:1]
	v_fmac_f32_e32 v36, 0x3fb8aa3b, v37
	v_exp_f32_e32 v36, v36
	v_cndmask_b32_e32 v37, 0, v240, vcc
	v_ldexp_f32 v233, v35, v37
	v_cndmask_b32_e64 v35, 0, v240, s[0:1]
	v_ldexp_f32 v234, v36, v35
	v_mul_f32_e32 v35, 0x3fb8aa3b, v38
	v_cmp_gt_f32_e32 vcc, s2, v35
	v_mul_f32_e32 v36, 0x3fb8aa3b, v34
	v_cmp_gt_f32_e64 s[0:1], s2, v36
	v_cndmask_b32_e32 v35, 0, v241, vcc
	v_fmac_f32_e32 v35, 0x3fb8aa3b, v38
	v_cndmask_b32_e64 v36, 0, v241, s[0:1]
	v_exp_f32_e32 v35, v35
	v_fmac_f32_e32 v36, 0x3fb8aa3b, v34
	v_exp_f32_e32 v34, v36
	v_cndmask_b32_e32 v36, 0, v240, vcc
	v_ldexp_f32 v235, v35, v36
	v_cndmask_b32_e64 v35, 0, v240, s[0:1]
	s_movk_i32 s0, 0x820
	v_ldexp_f32 v229, v34, v35
	.loc	1 424 16 is_stmt 1              ; bench.py:424:16
	v_bitop3_b32 v34, v1, s0, v75 bitop3:0x36
	v_add_u32_e32 v34, 0, v34
	s_movk_i32 s0, 0x828
	s_waitcnt vmcnt(17)
	ds_write2st64_b64 v34, v[18:19], v[222:223] offset1:16
	s_waitcnt vmcnt(11)
	ds_write2st64_b64 v34, v[210:211], v[218:219] offset0:32 offset1:48
	v_bitop3_b32 v18, v1, s0, v75 bitop3:0x36
	v_add_u32_e32 v34, 0, v18
	s_movk_i32 s0, 0x830
	ds_write2st64_b64 v34, v[20:21], v[224:225] offset1:16
	v_bitop3_b32 v21, v1, s0, v75 bitop3:0x36
	v_add_u32_e32 v21, 0, v21
	s_movk_i32 s0, 0x838
	ds_write2st64_b64 v34, v[212:213], v[220:221] offset0:32 offset1:48
	ds_write2st64_b64 v21, v[186:187], v[198:199] offset1:16
	s_waitcnt vmcnt(10)
	ds_write2st64_b64 v21, v[202:203], v[214:215] offset0:32 offset1:48
	v_bitop3_b32 v21, v1, s0, v75 bitop3:0x36
	v_add_u32_e32 v21, 0, v21
	s_movk_i32 s0, 0x1040
	ds_write2st64_b64 v21, v[188:189], v[200:201] offset1:16
	ds_write2st64_b64 v21, v[204:205], v[216:217] offset0:32 offset1:48
	v_bitop3_b32 v21, v1, s0, v75 bitop3:0x36
	v_add_u32_e32 v21, 0, v21
	s_movk_i32 s0, 0x1048
	ds_write2st64_b64 v21, v[170:171], v[182:183] offset1:16
	s_waitcnt vmcnt(9)
	ds_write2st64_b64 v21, v[190:191], v[206:207] offset0:32 offset1:48
	v_bitop3_b32 v21, v1, s0, v75 bitop3:0x36
	v_add_u32_e32 v21, 0, v21
	s_movk_i32 s0, 0x1050
	ds_write2st64_b64 v21, v[172:173], v[184:185] offset1:16
	ds_write2st64_b64 v21, v[192:193], v[208:209] offset0:32 offset1:48
	v_bitop3_b32 v21, v1, s0, v75 bitop3:0x36
	v_add_u32_e32 v21, 0, v21
	s_movk_i32 s0, 0x1058
	ds_write2st64_b64 v21, v[26:27], v[166:167] offset1:16
	s_waitcnt vmcnt(8)
	ds_write2st64_b64 v21, v[174:175], v[194:195] offset0:32 offset1:48
	v_bitop3_b32 v21, v1, s0, v75 bitop3:0x36
	v_add_u32_e32 v21, 0, v21
	s_movk_i32 s0, 0x1860
	ds_write2st64_b64 v21, v[28:29], v[168:169] offset1:16
	ds_write2st64_b64 v21, v[176:177], v[196:197] offset0:32 offset1:48
	v_bitop3_b32 v21, v1, s0, v75 bitop3:0x36
	v_add_u32_e32 v21, 0, v21
	s_movk_i32 s0, 0x1868
	s_waitcnt vmcnt(3)
	ds_write2st64_b64 v21, v[10:11], v[22:23] offset1:16
	s_waitcnt vmcnt(1)
	ds_write2st64_b64 v21, v[30:31], v[178:179] offset0:32 offset1:48
	v_bitop3_b32 v10, v1, s0, v75 bitop3:0x36
	v_add_u32_e32 v10, 0, v10
	s_movk_i32 s0, 0x1870
	ds_write2st64_b64 v10, v[12:13], v[24:25] offset1:16
	ds_write2st64_b64 v10, v[32:33], v[180:181] offset0:32 offset1:48
	v_bitop3_b32 v10, v1, s0, v75 bitop3:0x36
	s_movk_i32 s0, 0x1878
	v_bitop3_b32 v1, v1, s0, v75 bitop3:0x36
	v_add_u32_e32 v10, 0, v10
	v_add_u32_e32 v1, 0, v1
	ds_write2st64_b64 v10, v[2:3], v[6:7] offset1:16
	s_waitcnt vmcnt(0)
	ds_write2st64_b64 v10, v[14:15], v[162:163] offset0:32 offset1:48
	ds_write2st64_b64 v1, v[4:5], v[8:9] offset1:16
	ds_write2st64_b64 v1, v[16:17], v[164:165] offset0:32 offset1:48
	v_and_b32_e32 v1, 60, v0
	v_lshlrev_b32_e32 v2, 7, v1
	v_and_b32_e32 v3, 24, v104
	v_lshlrev_b32_e32 v1, 1, v1
	.loc	1 426 25                        ; bench.py:426:25
	v_cvt_pk_bf16_f32 v20, v229, v229
	.loc	1 424 16                        ; bench.py:424:16
	v_bitop3_b32 v1, v2, v1, v3 bitop3:0x36
	.loc	1 426 25                        ; bench.py:426:25
	v_cvt_pk_bf16_f32 v18, v231, v233
	v_cvt_pk_bf16_f32 v19, v234, v235
	.loc	1 424 16                        ; bench.py:424:16
	v_add_u32_e32 v2, 0, v1
	.loc	1 426 35                        ; bench.py:426:35
	v_mov_b32_e32 v21, v20
	v_pk_mul_f32 v[32:33], v[160:161], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[30:31], v[158:159], v[228:229] op_sel_hi:[1,0]
	.loc	1 424 16                        ; bench.py:424:16
	s_waitcnt lgkmcnt(0)
	; wave barrier
	ds_read_b64_tr_b16 v[218:219], v2
	ds_read_b64_tr_b16 v[26:27], v2 offset:128
	ds_read_b64_tr_b16 v[14:15], v2 offset:256
	ds_read_b64_tr_b16 v[6:7], v2 offset:384
	ds_read_b64_tr_b16 v[220:221], v2 offset:8192
	ds_read_b64_tr_b16 v[28:29], v2 offset:8320
	ds_read_b64_tr_b16 v[16:17], v2 offset:8448
	ds_read_b64_tr_b16 v[8:9], v2 offset:8576
	ds_read_b64_tr_b16 v[222:223], v2 offset:16384
	ds_read_b64_tr_b16 v[198:199], v2 offset:16512
	ds_read_b64_tr_b16 v[22:23], v2 offset:16640
	ds_read_b64_tr_b16 v[10:11], v2 offset:16768
	ds_read_b64_tr_b16 v[224:225], v2 offset:24576
	ds_read_b64_tr_b16 v[200:201], v2 offset:24704
	ds_read_b64_tr_b16 v[24:25], v2 offset:24832
	ds_read_b64_tr_b16 v[12:13], v2 offset:24960
	.loc	1 426 35                        ; bench.py:426:35
	s_waitcnt lgkmcnt(11)
	v_mfma_f32_16x16x32_bf16 v[30:33], v[218:221], v[18:21], v[30:33]
	.loc	1 424 16                        ; bench.py:424:16
	v_xad_u32 v2, v1, 32, 0
	ds_read_b64_tr_b16 v[244:245], v2
	ds_read_b64_tr_b16 v[202:203], v2 offset:128
	ds_read_b64_tr_b16 v[182:183], v2 offset:256
	ds_read_b64_tr_b16 v[166:167], v2 offset:384
	ds_read_b64_tr_b16 v[246:247], v2 offset:8192
	ds_read_b64_tr_b16 v[204:205], v2 offset:8320
	ds_read_b64_tr_b16 v[184:185], v2 offset:8448
	ds_read_b64_tr_b16 v[168:169], v2 offset:8576
	ds_read_b64_tr_b16 v[248:249], v2 offset:16384
	ds_read_b64_tr_b16 v[206:207], v2 offset:16512
	ds_read_b64_tr_b16 v[186:187], v2 offset:16640
	ds_read_b64_tr_b16 v[170:171], v2 offset:16768
	ds_read_b64_tr_b16 v[250:251], v2 offset:24576
	ds_read_b64_tr_b16 v[208:209], v2 offset:24704
	ds_read_b64_tr_b16 v[188:189], v2 offset:24832
	ds_read_b64_tr_b16 v[172:173], v2 offset:24960
	.loc	1 426 35                        ; bench.py:426:35
	v_mov_b32_e32 v2, v20
	v_mov_b32_e32 v3, v20
	v_mov_b32_e32 v4, v20
	v_mov_b32_e32 v5, v20
	.loc	1 424 16                        ; bench.py:424:16
	v_xad_u32 v34, v1, 64, 0
	v_xor_b32_e32 v1, 0x60, v1
	.loc	1 426 35                        ; bench.py:426:35
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_bf16 v[158:161], v[222:225], v[2:5], v[30:33]
	.loc	1 424 16                        ; bench.py:424:16
	v_add_u32_e32 v1, 0, v1
	ds_read_b64_tr_b16 v[252:253], v34
	ds_read_b64_tr_b16 v[210:211], v34 offset:128
	ds_read_b64_tr_b16 v[190:191], v34 offset:256
	ds_read_b64_tr_b16 v[174:175], v34 offset:384
	ds_read_b64_tr_b16 v[254:255], v34 offset:8192
	ds_read_b64_tr_b16 v[212:213], v34 offset:8320
	ds_read_b64_tr_b16 v[192:193], v34 offset:8448
	ds_read_b64_tr_b16 v[176:177], v34 offset:8576
	ds_read_b64_tr_b16 a[0:1], v34 offset:16384
	ds_read_b64_tr_b16 v[214:215], v34 offset:16512
	ds_read_b64_tr_b16 v[194:195], v34 offset:16640
	ds_read_b64_tr_b16 v[178:179], v34 offset:16768
	.loc	1 426 35                        ; bench.py:426:35
	v_pk_mul_f32 v[32:33], v[156:157], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[30:31], v[154:155], v[228:229] op_sel_hi:[1,0]
	.loc	1 424 16                        ; bench.py:424:16
	ds_read_b64_tr_b16 a[6:7], v1 offset:24576
	ds_read_b64_tr_b16 a[2:3], v34 offset:24576
	ds_read_b64_tr_b16 v[216:217], v34 offset:24704
	ds_read_b64_tr_b16 v[196:197], v34 offset:24832
	ds_read_b64_tr_b16 v[180:181], v34 offset:24960
	.loc	1 426 35                        ; bench.py:426:35
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_bf16 v[30:33], v[244:247], v[18:21], v[30:33]
	.loc	1 424 16                        ; bench.py:424:16
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
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[154:157], v[248:251], v[2:5], v[30:33]
	.loc	1 424 16                        ; bench.py:424:16
	ds_read_b64_tr_b16 a[26:27], v1 offset:24704
	ds_read_b64_tr_b16 a[30:31], v1 offset:24832
	ds_read_b64_tr_b16 a[34:35], v1 offset:24960
	.loc	1 426 35                        ; bench.py:426:35
	v_pk_mul_f32 v[32:33], v[152:153], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[30:31], v[150:151], v[228:229] op_sel_hi:[1,0]
	.loc	1 415 21                        ; bench.py:415:21
	v_mul_f32_e32 v1, 0x3fb8aa3b, v243
	v_cmp_gt_f32_e32 vcc, s2, v1
	.loc	1 426 35                        ; bench.py:426:35
	s_waitcnt lgkmcnt(14)
	v_mfma_f32_16x16x32_bf16 v[30:33], v[252:255], v[18:21], v[30:33]
	.loc	1 415 21                        ; bench.py:415:21
	v_cndmask_b32_e32 v1, 0, v241, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v243
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[150:153], a[0:3], v[2:5], v[30:33]
	.loc	1 415 21                        ; bench.py:415:21
	v_exp_f32_e32 v1, v1
	v_cndmask_b32_e32 v38, 0, v240, vcc
	.loc	1 426 35                        ; bench.py:426:35
	s_nop 2
	v_pk_mul_f32 v[32:33], v[148:149], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[30:31], v[146:147], v[228:229] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(10)
	s_nop 0
	v_mfma_f32_16x16x32_bf16 v[30:33], a[8:11], v[18:21], v[30:33]
	s_waitcnt lgkmcnt(6)
	v_mfma_f32_16x16x32_bf16 v[146:149], a[4:7], v[2:5], v[30:33]
	s_nop 5
	v_mul_f32_e64 v32, v144, v228
	v_mul_f32_e64 v33, v145, v228
	v_pk_mul_f32 v[30:31], v[142:143], v[228:229] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[30:33], v[26:29], v[18:21], v[30:33]
	v_mfma_f32_16x16x32_bf16 v[142:145], v[198:201], v[2:5], v[30:33]
	s_nop 6
	v_mul_f32_e64 v32, v140, v228
	v_mul_f32_e64 v33, v141, v228
	v_pk_mul_f32 v[30:31], v[138:139], v[228:229] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[34:37], v[202:205], v[18:21], v[30:33]
	v_mfma_f32_16x16x32_bf16 v[138:141], v[206:209], v[2:5], v[34:37]
	.loc	1 415 21                        ; bench.py:415:21
	s_nop 1
	v_ldexp_f32 v32, v1, v38
	.loc	1 416 32                        ; bench.py:416:32
	v_sub_f32_e32 v1, v238, v242
	.loc	1 416 27 is_stmt 0              ; bench.py:416:27
	v_mul_f32_e32 v39, 0x3fb8aa3b, v1
	v_cmp_gt_f32_e32 vcc, s2, v39
	.loc	1 426 35 is_stmt 1              ; bench.py:426:35
	s_nop 0
	v_pk_mul_f32 v[36:37], v[136:137], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[134:135], v[228:229] op_sel_hi:[1,0]
	.loc	1 416 32                        ; bench.py:416:32
	v_sub_f32_e32 v30, v239, v242
	.loc	1 416 27 is_stmt 0              ; bench.py:416:27
	v_cndmask_b32_e32 v39, 0, v241, vcc
	.loc	1 426 35 is_stmt 1              ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[34:37], v[210:213], v[18:21], v[34:37]
	.loc	1 416 27                        ; bench.py:416:27
	v_fmac_f32_e32 v39, 0x3fb8aa3b, v1
	v_mul_f32_e32 v40, 0x3fb8aa3b, v30
	v_exp_f32_e32 v1, v39
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[134:137], v[214:217], v[2:5], v[34:37]
	.loc	1 416 27                        ; bench.py:416:27
	v_cndmask_b32_e32 v39, 0, v240, vcc
	v_cmp_gt_f32_e32 vcc, s2, v40
	.loc	1 416 32 is_stmt 0              ; bench.py:416:32
	v_sub_f32_e32 v31, v237, v242
	.loc	1 416 27                        ; bench.py:416:27
	v_ldexp_f32 v39, v1, v39
	.loc	1 426 35 is_stmt 1              ; bench.py:426:35
	v_pk_mul_f32 v[36:37], v[132:133], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[130:131], v[228:229] op_sel_hi:[1,0]
	.loc	1 416 27                        ; bench.py:416:27
	v_cndmask_b32_e32 v40, 0, v241, vcc
	v_fmac_f32_e32 v40, 0x3fb8aa3b, v30
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[34:37], a[12:15], v[18:21], v[34:37]
	.loc	1 416 27                        ; bench.py:416:27
	v_exp_f32_e32 v30, v40
	v_cndmask_b32_e32 v1, 0, v240, vcc
	.loc	1 416 32 is_stmt 0              ; bench.py:416:32
	v_sub_f32_e32 v33, v236, v242
	.loc	1 426 35 is_stmt 1              ; bench.py:426:35
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[130:133], a[24:27], v[2:5], v[34:37]
	.loc	1 416 27                        ; bench.py:416:27
	v_ldexp_f32 v30, v30, v1
	v_mul_f32_e32 v1, 0x3fb8aa3b, v31
	v_cmp_gt_f32_e32 vcc, s2, v1
	.loc	1 416 32 is_stmt 0              ; bench.py:416:32
	v_sub_f32_e32 v38, 0xff800000, v242
	.loc	1 426 35 is_stmt 1              ; bench.py:426:35
	v_pk_mul_f32 v[36:37], v[128:129], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[126:127], v[228:229] op_sel_hi:[1,0]
	.loc	1 416 27                        ; bench.py:416:27
	v_cndmask_b32_e32 v1, 0, v241, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v31
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[34:37], v[14:17], v[18:21], v[34:37]
	.loc	1 416 27                        ; bench.py:416:27
	v_exp_f32_e32 v1, v1
	v_cndmask_b32_e32 v31, 0, v240, vcc
	v_mul_f32_e32 v40, 0x3fb8aa3b, v38
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[126:129], v[22:25], v[2:5], v[34:37]
	.loc	1 416 27                        ; bench.py:416:27
	v_ldexp_f32 v31, v1, v31
	v_mul_f32_e32 v1, 0x3fb8aa3b, v33
	v_cmp_gt_f32_e32 vcc, s2, v1
	.loc	1 426 25                        ; bench.py:426:25
	v_cvt_pk_bf16_f32 v162, v39, v30
	.loc	1 426 35 is_stmt 0              ; bench.py:426:35
	v_pk_mul_f32 v[36:37], v[124:125], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[122:123], v[228:229] op_sel_hi:[1,0]
	.loc	1 416 27 is_stmt 1              ; bench.py:416:27
	v_cndmask_b32_e32 v1, 0, v241, vcc
	v_fmac_f32_e32 v1, 0x3fb8aa3b, v33
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[34:37], v[182:185], v[18:21], v[34:37]
	.loc	1 416 27                        ; bench.py:416:27
	v_cndmask_b32_e32 v33, 0, v240, vcc
	v_cmp_gt_f32_e32 vcc, s2, v40
	v_exp_f32_e32 v1, v1
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[122:125], v[186:189], v[2:5], v[34:37]
	.loc	1 416 27                        ; bench.py:416:27
	v_cndmask_b32_e32 v40, 0, v241, vcc
	v_fmac_f32_e32 v40, 0x3fb8aa3b, v38
	v_exp_f32_e32 v38, v40
	v_ldexp_f32 v33, v1, v33
	.loc	1 426 35                        ; bench.py:426:35
	v_pk_mul_f32 v[36:37], v[120:121], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[118:119], v[228:229] op_sel_hi:[1,0]
	.loc	1 416 27                        ; bench.py:416:27
	v_cndmask_b32_e32 v1, 0, v240, vcc
	v_ldexp_f32 v38, v38, v1
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[34:37], v[190:193], v[18:21], v[34:37]
	.loc	1 426 25 is_stmt 0              ; bench.py:426:25
	v_cvt_pk_bf16_f32 v164, v38, v38
	v_cvt_pk_bf16_f32 v163, v31, v33
	.loc	1 426 35                        ; bench.py:426:35
	v_mov_b32_e32 v165, v164
	v_mfma_f32_16x16x32_bf16 v[118:121], v[194:197], v[2:5], v[34:37]
	v_accvgpr_read_b32 v1, a129
	.loc	1 352 17 is_stmt 1              ; bench.py:352:17
	v_lshrrev_b32_e32 v1, 2, v1
	.loc	1 426 35                        ; bench.py:426:35
	s_nop 1
	v_pk_mul_f32 v[36:37], v[116:117], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[114:115], v[228:229] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[34:37], a[16:19], v[18:21], v[34:37]
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[114:117], a[28:31], v[2:5], v[34:37]
	s_nop 5
	v_mul_f32_e64 v36, v112, v228
	v_mul_f32_e64 v37, v113, v228
	v_pk_mul_f32 v[34:35], v[110:111], v[228:229] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[34:37], v[6:9], v[18:21], v[34:37]
	v_mfma_f32_16x16x32_bf16 v[110:113], v[10:13], v[2:5], v[34:37]
	s_nop 6
	v_mul_f32_e64 v36, v108, v228
	v_mul_f32_e64 v37, v109, v228
	v_pk_mul_f32 v[34:35], v[106:107], v[228:229] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[34:37], v[166:169], v[18:21], v[34:37]
	v_mfma_f32_16x16x32_bf16 v[106:109], v[170:173], v[2:5], v[34:37]
	s_nop 6
	v_accvgpr_read_b32 v34, a140
	v_accvgpr_read_b32 v35, a141
	v_accvgpr_read_b32 v36, a142
	v_accvgpr_read_b32 v37, a143
	v_pk_mul_f32 v[36:37], v[36:37], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[34:35], v[228:229] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[34:37], v[174:177], v[18:21], v[34:37]
	v_mfma_f32_16x16x32_bf16 v[102:105], v[178:181], v[2:5], v[34:37]
	s_nop 6
	v_accvgpr_read_b32 v34, a136
	v_accvgpr_read_b32 v35, a137
	v_accvgpr_read_b32 v36, a138
	v_accvgpr_read_b32 v37, a139
	v_pk_mul_f32 v[36:37], v[36:37], v[228:229] op_sel_hi:[1,0]
	v_pk_mul_f32 v[34:35], v[34:35], v[228:229] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[18:21], a[20:23], v[18:21], v[34:37]
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x32_bf16 v[98:101], a[32:35], v[2:5], v[18:21]
	v_accvgpr_read_b32 v2, a132
	v_accvgpr_read_b32 v3, a133
	v_accvgpr_read_b32 v4, a134
	v_accvgpr_read_b32 v5, a135
	v_pk_mul_f32 v[4:5], v[4:5], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	v_mov_b32_e32 v34, v164
	v_mov_b32_e32 v35, v164
	v_mfma_f32_16x16x32_bf16 v[2:5], v[218:221], v[162:165], v[2:5]
	v_mov_b32_e32 v36, v164
	v_mov_b32_e32 v37, v164
	.loc	1 352 17                        ; bench.py:352:17
	v_and_or_b32 v218, v0, 16, v1
	v_or_b32_e32 v219, 0xe0, v218
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[94:97], v[222:225], v[34:37], v[2:5]
	.loc	1 352 17                        ; bench.py:352:17
	v_or_b32_e32 v220, 0xc0, v218
	v_or_b32_e32 v221, 0xa0, v218
	v_or_b32_e32 v222, 0x80, v218
	v_accvgpr_read_b32 v2, a122
	v_accvgpr_read_b32 v3, a123
	v_accvgpr_read_b32 v4, a124
	v_accvgpr_read_b32 v5, a125
	.loc	1 426 35                        ; bench.py:426:35
	v_pk_mul_f32 v[4:5], v[4:5], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	.loc	1 352 17                        ; bench.py:352:17
	v_or_b32_e32 v223, 0x60, v218
	v_or_b32_e32 v224, 64, v218
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[2:5], v[244:247], v[162:165], v[2:5]
	.loc	1 352 17                        ; bench.py:352:17
	v_or_b32_e32 v225, 32, v218
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[90:93], v[248:251], v[34:37], v[2:5]
	s_nop 5
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
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:417:35 ] ]
	v_add_f32_e32 v5, v39, v30
	v_add_f32_e32 v5, v31, v5
.Ltmp219:
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[0:3], a[8:11], v[162:165], v[0:3]
.Ltmp220:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:417:35 ] ]
	v_add_f32_e32 v4, v231, v233
	v_add_f32_e32 v4, v234, v4
	v_add_f32_e32 v4, v235, v4
.Ltmp221:
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[82:85], a[4:7], v[34:37], v[0:3]
.Ltmp222:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:417:35 ] ]
	v_add_f32_e32 v4, v229, v4
	v_add_f32_e32 v4, v229, v4
	v_add_f32_e32 v4, v229, v4
	v_add_f32_e32 v4, v229, v4
	v_accvgpr_read_b32 v0, a110
	v_accvgpr_read_b32 v1, a111
	v_accvgpr_read_b32 v2, a112
	v_accvgpr_read_b32 v3, a113
.Ltmp223:
	.loc	1 426 35                        ; bench.py:426:35
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[0:1], v[32:33] op_sel_hi:[1,0]
.Ltmp224:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:417:35 ] ]
	v_add_f32_e32 v4, v229, v4
	v_add_f32_e32 v5, v33, v5
.Ltmp225:
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[0:3], v[26:29], v[162:165], v[0:3]
.Ltmp226:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:417:35 ] ]
	v_add_f32_e32 v4, v229, v4
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v4, v229, v4
.Ltmp227:
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[78:81], v[198:201], v[34:37], v[0:3]
.Ltmp228:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:417:35 ] ]
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v4, v229, v4
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v4, v229, v4
	v_accvgpr_read_b32 v0, a106
	v_accvgpr_read_b32 v1, a107
	v_accvgpr_read_b32 v2, a108
	v_accvgpr_read_b32 v3, a109
.Ltmp229:
	.loc	1 426 35                        ; bench.py:426:35
	v_pk_mul_f32 v[2:3], v[2:3], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[0:1], v[32:33] op_sel_hi:[1,0]
.Ltmp230:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:417:35 ] ]
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v4, v229, v4
.Ltmp231:
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[0:3], v[202:205], v[162:165], v[0:3]
.Ltmp232:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:417:35 ] ]
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v4, v229, v4
	v_add_f32_e32 v5, v38, v5
.Ltmp233:
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[74:77], v[206:209], v[34:37], v[0:3]
.Ltmp234:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:417:35 ] ]
	v_add_f32_e32 v4, v229, v4
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v5, v38, v5
.Ltmp235:
	.loc	1 426 35                        ; bench.py:426:35
	v_pk_mul_f32 v[2:3], v[72:73], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[70:71], v[32:33] op_sel_hi:[1,0]
.Ltmp236:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:417:35 ] ]
	v_add_f32_e32 v5, v38, v5
	v_add_f32_e32 v5, v38, v5
.Ltmp237:
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[0:3], v[210:213], v[162:165], v[0:3]
.Ltmp238:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:417:35 ] ]
	v_add_f32_e32 v5, v38, v5
.Ltmp239:
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[70:73], v[214:217], v[34:37], v[0:3]
	s_nop 5
	v_mul_f32_e64 v2, v68, v32
	v_mul_f32_e64 v3, v69, v32
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
.Ltmp240:
	.loc	2 293 36                        ; standard.py:293:36 @[ bench.py:417:35 ]
	v_mov_b32_e32 v14, v4
	s_nop 1
	v_permlane32_swap_b32_e32 v4, v14
.Ltmp241:
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[28:31], v[22:25], v[34:37], v[0:3]
.Ltmp242:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:417:35 ] ]
	v_add_f32_e32 v4, v4, v14
.Ltmp243:
	.loc	1 426 35                        ; bench.py:426:35
	s_nop 1
	v_pk_mul_f32 v[2:3], v[60:61], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[58:59], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[0:3], v[182:185], v[162:165], v[0:3]
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
	v_mfma_f32_16x16x32_bf16 v[0:3], v[6:9], v[162:165], v[0:3]
.Ltmp244:
	.loc	2 293 36                        ; standard.py:293:36 @[ bench.py:417:35 ]
	v_mov_b32_e32 v6, v4
	s_nop 1
	v_permlane16_swap_b32_e32 v4, v6
.Ltmp245:
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[12:15], v[10:13], v[34:37], v[0:3]
	s_nop 2
	v_mul_f32_e64 v2, v52, v32
	v_mul_f32_e64 v3, v53, v32
	v_pk_mul_f32 v[0:1], v[50:51], v[32:33] op_sel_hi:[1,0]
	s_nop 1
	v_mfma_f32_16x16x32_bf16 v[0:3], v[166:169], v[162:165], v[0:3]
.Ltmp246:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:417:35 ] ]
	v_add_f32_e32 v166, v4, v6
.Ltmp247:
	.loc	2 293 36                        ; standard.py:293:36 @[ bench.py:417:35 ]
	v_mov_b32_e32 v4, v5
	s_nop 1
	v_permlane32_swap_b32_e32 v5, v4
.Ltmp248:
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[8:11], v[170:173], v[34:37], v[0:3]
	s_nop 2
	v_mul_f32_e64 v2, v48, v32
	v_mul_f32_e64 v3, v49, v32
	v_pk_mul_f32 v[0:1], v[46:47], v[32:33] op_sel_hi:[1,0]
.Ltmp249:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:417:35 ] ]
	v_add_f32_e32 v33, v5, v4
.Ltmp250:
	.loc	2 293 36                        ; standard.py:293:36 @[ bench.py:417:35 ]
	v_mov_b32_e32 v38, v33
.Ltmp251:
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[0:3], v[174:177], v[162:165], v[0:3]
.Ltmp252:
	.loc	2 293 36                        ; standard.py:293:36 @[ bench.py:417:35 ]
	s_nop 0
	v_permlane16_swap_b32_e32 v33, v38
.Ltmp253:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ bench.py:417:35 ] ]
	v_add_f32_e32 v48, v33, v38
	v_accvgpr_read_b32 v38, a96
.Ltmp254:
	.loc	1 417 28                        ; bench.py:417:28
	v_fmac_f32_e32 v166, v38, v228
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[4:7], v[178:181], v[34:37], v[0:3]
	.loc	1 434 44                        ; bench.py:434:44
	v_div_scale_f32 v50, s[0:1], v166, v166, v158
	v_rcp_f32_e32 v51, v50
	.loc	1 426 35                        ; bench.py:426:35
	s_nop 0
	v_pk_mul_f32 v[2:3], v[44:45], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[0:1], v[42:43], v[32:33] op_sel_hi:[1,0]
	v_accvgpr_read_b32 v39, a97
	.loc	1 417 28                        ; bench.py:417:28
	v_fmac_f32_e32 v48, v39, v32
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[0:3], a[20:23], v[162:165], v[0:3]
	.loc	1 434 22                        ; bench.py:434:22
	v_mul_u32_u24_e32 v32, 0x1800, v230
	v_or_b32_e32 v49, 0x100, v32
	v_or_b32_e32 v47, v218, v32
	.loc	1 426 35                        ; bench.py:426:35
	v_mfma_f32_16x16x32_bf16 v[0:3], a[32:35], v[34:37], v[0:3]
	.loc	1 434 22                        ; bench.py:434:22
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
	.loc	1 434 44 is_stmt 0              ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_add_lshl_u32 v47, v47, s33, 1
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cndmask_b32_e64 v47, v232, v47, s[34:35]
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v66, v66, v67
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v67, v68, v69
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v28, v28, v29
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v29, v30, v31
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v30, v145, v147
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_permlane16_swap_b32_e32 v28, v30
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v31, v148, v149
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_permlane16_swap_b32_e32 v29, v31
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v27, v108, v109
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v26, v106, v107
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v25, v112, v113
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v24, v110, v111
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v23, v116, v117
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v22, v114, v115
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v21, v120, v121
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v20, v118, v119
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v19, v124, v125
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v18, v122, v123
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v17, v128, v129
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v16, v126, v127
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v15, v132, v133
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v14, v130, v131
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v13, v136, v137
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v12, v134, v135
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v11, v140, v141
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v10, v138, v139
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v9, v143, v144
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v8, v65, v142
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v7, v63, v64
	.loc	1 434 44                        ; bench.py:434:44
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
	.loc	1 434 38                        ; bench.py:434:38
	v_cvt_pk_bf16_f32 v6, v61, v62
	.loc	1 434 44                        ; bench.py:434:44
	v_fma_f32 v0, -v4, v5, 1.0
	v_fmac_f32_e32 v5, v0, v5
	v_div_scale_f32 v0, vcc, v3, v48, v3
	v_mul_f32_e32 v1, v0, v5
	v_fma_f32 v2, -v4, v1, v0
	v_fmac_f32_e32 v1, v2, v5
	v_fma_f32 v0, -v4, v1, v0
	v_div_fmas_f32 v0, v0, v5, v1
	v_div_fixup_f32 v172, v0, v48, v3
	.loc	1 434 38                        ; bench.py:434:38
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
	v_add_lshl_u32 v0, v46, s33, 1
	v_permlane16_swap_b32_e32 v5, v7
	v_cndmask_b32_e64 v0, v232, v0, s[34:35]
	buffer_store_dwordx4 v[4:7], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v45, s33, 1
	v_permlane16_swap_b32_e32 v8, v10
	v_permlane16_swap_b32_e32 v9, v11
	v_cndmask_b32_e64 v0, v232, v0, s[34:35]
	buffer_store_dwordx4 v[8:11], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v44, s33, 1
	v_permlane16_swap_b32_e32 v12, v14
	v_permlane16_swap_b32_e32 v13, v15
	v_cndmask_b32_e64 v0, v232, v0, s[34:35]
	buffer_store_dwordx4 v[12:15], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v43, s33, 1
	v_permlane16_swap_b32_e32 v16, v18
	v_permlane16_swap_b32_e32 v17, v19
	v_cndmask_b32_e64 v0, v232, v0, s[34:35]
	buffer_store_dwordx4 v[16:19], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v42, s33, 1
	v_permlane16_swap_b32_e32 v20, v22
	v_permlane16_swap_b32_e32 v21, v23
	v_cndmask_b32_e64 v0, v232, v0, s[34:35]
	buffer_store_dwordx4 v[20:23], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v41, s33, 1
	v_permlane16_swap_b32_e32 v24, v26
	v_permlane16_swap_b32_e32 v25, v27
	v_cndmask_b32_e64 v0, v232, v0, s[34:35]
	v_cvt_pk_bf16_f32 v48, v102, v103
	v_cvt_pk_bf16_f32 v49, v104, v105
	v_cvt_pk_bf16_f32 v50, v98, v99
	v_cvt_pk_bf16_f32 v51, v100, v101
	buffer_store_dwordx4 v[24:27], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v40, s33, 1
	v_permlane16_swap_b32_e32 v48, v50
	v_permlane16_swap_b32_e32 v49, v51
	v_cndmask_b32_e64 v0, v232, v0, s[34:35]
	v_cvt_pk_bf16_f32 v52, v94, v95
	v_cvt_pk_bf16_f32 v53, v96, v97
	v_cvt_pk_bf16_f32 v54, v90, v91
	v_cvt_pk_bf16_f32 v55, v92, v93
	buffer_store_dwordx4 v[48:51], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v39, s33, 1
	v_permlane16_swap_b32_e32 v52, v54
	v_permlane16_swap_b32_e32 v53, v55
	v_cndmask_b32_e64 v0, v232, v0, s[34:35]
	v_cvt_pk_bf16_f32 v56, v86, v87
	v_cvt_pk_bf16_f32 v57, v88, v89
	v_cvt_pk_bf16_f32 v58, v82, v83
	v_cvt_pk_bf16_f32 v59, v84, v85
	buffer_store_dwordx4 v[52:55], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v38, s33, 1
	v_permlane16_swap_b32_e32 v56, v58
	v_permlane16_swap_b32_e32 v57, v59
	v_cndmask_b32_e64 v0, v232, v0, s[34:35]
	v_cvt_pk_bf16_f32 v60, v78, v79
	v_cvt_pk_bf16_f32 v61, v80, v81
	v_cvt_pk_bf16_f32 v62, v74, v75
	v_cvt_pk_bf16_f32 v63, v76, v77
	buffer_store_dwordx4 v[56:59], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v37, s33, 1
	v_permlane16_swap_b32_e32 v60, v62
	v_permlane16_swap_b32_e32 v61, v63
	v_cndmask_b32_e64 v0, v232, v0, s[34:35]
	v_cvt_pk_bf16_f32 v64, v70, v71
	v_cvt_pk_bf16_f32 v65, v72, v73
	buffer_store_dwordx4 v[60:63], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v36, s33, 1
	v_permlane16_swap_b32_e32 v64, v66
	v_permlane16_swap_b32_e32 v65, v67
	v_cndmask_b32_e64 v0, v232, v0, s[34:35]
	buffer_store_dwordx4 v[64:67], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v35, s33, 1
	v_cndmask_b32_e64 v0, v232, v0, s[34:35]
	v_cvt_pk_bf16_f32 v68, v146, v150
	v_cvt_pk_bf16_f32 v69, v151, v152
	v_cvt_pk_bf16_f32 v70, v153, v154
	v_cvt_pk_bf16_f32 v71, v155, v156
	buffer_store_dwordx4 v[28:31], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v34, s33, 1
	v_permlane16_swap_b32_e32 v68, v70
	v_permlane16_swap_b32_e32 v69, v71
	v_cndmask_b32_e64 v0, v232, v0, s[34:35]
	v_cvt_pk_bf16_f32 v72, v157, v158
	v_cvt_pk_bf16_f32 v73, v159, v160
	v_cvt_pk_bf16_f32 v74, v161, v162
	v_cvt_pk_bf16_f32 v75, v163, v164
	buffer_store_dwordx4 v[68:71], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v33, s33, 1
	v_permlane16_swap_b32_e32 v72, v74
	v_permlane16_swap_b32_e32 v73, v75
	v_cndmask_b32_e64 v0, v232, v0, s[34:35]
	v_cvt_pk_bf16_f32 v76, v165, v166
	v_cvt_pk_bf16_f32 v77, v167, v168
	v_cvt_pk_bf16_f32 v78, v169, v170
	v_cvt_pk_bf16_f32 v79, v171, v172
	buffer_store_dwordx4 v[72:75], v0, s[8:11], 0 offen
	v_add_lshl_u32 v0, v32, s33, 1
	v_permlane16_swap_b32_e32 v76, v78
	v_permlane16_swap_b32_e32 v77, v79
	v_cndmask_b32_e64 v0, v232, v0, s[34:35]
	buffer_store_dwordx4 v[76:79], v0, s[8:11], 0 offen
	.loc	1 434 4                         ; bench.py:434:4
	s_endpgm
.Ltmp255:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _grouped_gqa8_fp8kv_fwd_kernel
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
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 409
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
	.size	_grouped_gqa8_fp8kv_fwd_kernel, .Lfunc_end0-_grouped_gqa8_fp8kv_fwd_kernel
	.cfi_endproc
                                        ; -- End function
	.set _grouped_gqa8_fp8kv_fwd_kernel.num_vgpr, 256
	.set _grouped_gqa8_fp8kv_fwd_kernel.num_agpr, 153
	.set _grouped_gqa8_fp8kv_fwd_kernel.numbered_sgpr, 96
	.set _grouped_gqa8_fp8kv_fwd_kernel.num_named_barrier, 0
	.set _grouped_gqa8_fp8kv_fwd_kernel.private_seg_size, 0
	.set _grouped_gqa8_fp8kv_fwd_kernel.uses_vcc, 1
	.set _grouped_gqa8_fp8kv_fwd_kernel.uses_flat_scratch, 0
	.set _grouped_gqa8_fp8kv_fwd_kernel.has_dyn_sized_stack, 0
	.set _grouped_gqa8_fp8kv_fwd_kernel.has_recursion, 0
	.set _grouped_gqa8_fp8kv_fwd_kernel.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 30300
; TotalNumSgprs: 102
; NumVgprs: 256
; NumAgprs: 153
; TotalNumVgprs: 409
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 12
; VGPRBlocks: 51
; NumSGPRsForWavesPerEU: 102
; NumVGPRsForWavesPerEU: 409
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
	.byte	5                               ; DW_FORM_data2
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
	.byte	0                               ; EOM(3)
	.section	.debug_info,"",@progbits
.Lcu_begin0:
	.long	.Ldebug_info_end0-.Ldebug_info_start0 ; Length of Unit
.Ldebug_info_start0:
	.short	4                               ; DWARF version number
	.long	.debug_abbrev                   ; Offset Into Abbrev. Section
	.byte	8                               ; Address Size (in bytes)
	.byte	1                               ; Abbrev [1] 0xb:0xd6 DW_TAG_compile_unit
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
	.byte	3                               ; Abbrev [3] 0x30:0xb0 DW_TAG_subprogram
	.quad	.Lfunc_begin0                   ; DW_AT_low_pc
	.long	.Lfunc_end0-.Lfunc_begin0       ; DW_AT_high_pc
	.long	42                              ; DW_AT_abstract_origin
	.byte	4                               ; Abbrev [4] 0x41:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges0                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	368                             ; DW_AT_call_line
	.byte	34                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x4e:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges1                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0x5b:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges2                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	368                             ; DW_AT_call_line
	.byte	27                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x68:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges3                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0x75:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges4                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	383                             ; DW_AT_call_line
	.byte	29                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x82:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges5                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0x8f:0x1b DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges6                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	388                             ; DW_AT_call_line
	.byte	43                              ; DW_AT_call_column
	.byte	6                               ; Abbrev [6] 0x9c:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges7                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.short	293                             ; DW_AT_call_line
	.byte	36                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0xaa:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges8                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	412                             ; DW_AT_call_line
	.byte	21                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0xb7:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges9                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0xc4:0x1b DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges10                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.short	417                             ; DW_AT_call_line
	.byte	35                              ; DW_AT_call_column
	.byte	6                               ; Abbrev [6] 0xd1:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges11                ; DW_AT_ranges
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
	.quad	.Ltmp11-.Lfunc_begin0
	.quad	.Ltmp13-.Lfunc_begin0
	.quad	.Ltmp14-.Lfunc_begin0
	.quad	.Ltmp15-.Lfunc_begin0
	.quad	.Ltmp16-.Lfunc_begin0
	.quad	.Ltmp18-.Lfunc_begin0
	.quad	.Ltmp19-.Lfunc_begin0
	.quad	.Ltmp20-.Lfunc_begin0
	.quad	.Ltmp21-.Lfunc_begin0
	.quad	.Ltmp22-.Lfunc_begin0
	.quad	.Ltmp23-.Lfunc_begin0
	.quad	.Ltmp25-.Lfunc_begin0
	.quad	.Ltmp26-.Lfunc_begin0
	.quad	.Ltmp28-.Lfunc_begin0
	.quad	.Ltmp29-.Lfunc_begin0
	.quad	.Ltmp30-.Lfunc_begin0
	.quad	.Ltmp31-.Lfunc_begin0
	.quad	.Ltmp33-.Lfunc_begin0
	.quad	.Ltmp34-.Lfunc_begin0
	.quad	.Ltmp35-.Lfunc_begin0
	.quad	.Ltmp36-.Lfunc_begin0
	.quad	.Ltmp37-.Lfunc_begin0
	.quad	.Ltmp38-.Lfunc_begin0
	.quad	.Ltmp40-.Lfunc_begin0
	.quad	.Ltmp41-.Lfunc_begin0
	.quad	.Ltmp65-.Lfunc_begin0
	.quad	.Ltmp66-.Lfunc_begin0
	.quad	.Ltmp67-.Lfunc_begin0
	.quad	.Ltmp68-.Lfunc_begin0
	.quad	.Ltmp85-.Lfunc_begin0
	.quad	.Ltmp86-.Lfunc_begin0
	.quad	.Ltmp87-.Lfunc_begin0
	.quad	.Ltmp88-.Lfunc_begin0
	.quad	.Ltmp103-.Lfunc_begin0
	.quad	.Ltmp104-.Lfunc_begin0
	.quad	.Ltmp105-.Lfunc_begin0
	.quad	.Ltmp106-.Lfunc_begin0
	.quad	.Ltmp107-.Lfunc_begin0
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
	.quad	.Ltmp12-.Lfunc_begin0
	.quad	.Ltmp13-.Lfunc_begin0
	.quad	.Ltmp14-.Lfunc_begin0
	.quad	.Ltmp15-.Lfunc_begin0
	.quad	.Ltmp17-.Lfunc_begin0
	.quad	.Ltmp18-.Lfunc_begin0
	.quad	.Ltmp19-.Lfunc_begin0
	.quad	.Ltmp20-.Lfunc_begin0
	.quad	.Ltmp21-.Lfunc_begin0
	.quad	.Ltmp22-.Lfunc_begin0
	.quad	.Ltmp23-.Lfunc_begin0
	.quad	.Ltmp24-.Lfunc_begin0
	.quad	.Ltmp27-.Lfunc_begin0
	.quad	.Ltmp28-.Lfunc_begin0
	.quad	.Ltmp29-.Lfunc_begin0
	.quad	.Ltmp30-.Lfunc_begin0
	.quad	.Ltmp32-.Lfunc_begin0
	.quad	.Ltmp33-.Lfunc_begin0
	.quad	.Ltmp34-.Lfunc_begin0
	.quad	.Ltmp35-.Lfunc_begin0
	.quad	.Ltmp36-.Lfunc_begin0
	.quad	.Ltmp37-.Lfunc_begin0
	.quad	.Ltmp38-.Lfunc_begin0
	.quad	.Ltmp39-.Lfunc_begin0
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
	.quad	.Ltmp66-.Lfunc_begin0
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
	.quad	.Ltmp83-.Lfunc_begin0
	.quad	.Ltmp84-.Lfunc_begin0
	.quad	.Ltmp85-.Lfunc_begin0
	.quad	.Ltmp86-.Lfunc_begin0
	.quad	.Ltmp87-.Lfunc_begin0
	.quad	.Ltmp88-.Lfunc_begin0
	.quad	.Ltmp89-.Lfunc_begin0
	.quad	.Ltmp90-.Lfunc_begin0
	.quad	.Ltmp91-.Lfunc_begin0
	.quad	.Ltmp92-.Lfunc_begin0
	.quad	.Ltmp93-.Lfunc_begin0
	.quad	.Ltmp94-.Lfunc_begin0
	.quad	.Ltmp95-.Lfunc_begin0
	.quad	.Ltmp96-.Lfunc_begin0
	.quad	.Ltmp97-.Lfunc_begin0
	.quad	.Ltmp98-.Lfunc_begin0
	.quad	.Ltmp99-.Lfunc_begin0
	.quad	.Ltmp100-.Lfunc_begin0
	.quad	.Ltmp101-.Lfunc_begin0
	.quad	.Ltmp102-.Lfunc_begin0
	.quad	.Ltmp103-.Lfunc_begin0
	.quad	.Ltmp104-.Lfunc_begin0
	.quad	.Ltmp105-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges2:
	.quad	.Ltmp40-.Lfunc_begin0
	.quad	.Ltmp41-.Lfunc_begin0
	.quad	.Ltmp65-.Lfunc_begin0
	.quad	.Ltmp66-.Lfunc_begin0
	.quad	.Ltmp67-.Lfunc_begin0
	.quad	.Ltmp68-.Lfunc_begin0
	.quad	.Ltmp85-.Lfunc_begin0
	.quad	.Ltmp86-.Lfunc_begin0
	.quad	.Ltmp87-.Lfunc_begin0
	.quad	.Ltmp88-.Lfunc_begin0
	.quad	.Ltmp103-.Lfunc_begin0
	.quad	.Ltmp104-.Lfunc_begin0
	.quad	.Ltmp105-.Lfunc_begin0
	.quad	.Ltmp106-.Lfunc_begin0
	.quad	.Ltmp107-.Lfunc_begin0
	.quad	.Ltmp117-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges3:
	.quad	.Ltmp108-.Lfunc_begin0
	.quad	.Ltmp109-.Lfunc_begin0
	.quad	.Ltmp110-.Lfunc_begin0
	.quad	.Ltmp111-.Lfunc_begin0
	.quad	.Ltmp112-.Lfunc_begin0
	.quad	.Ltmp113-.Lfunc_begin0
	.quad	.Ltmp114-.Lfunc_begin0
	.quad	.Ltmp115-.Lfunc_begin0
	.quad	.Ltmp116-.Lfunc_begin0
	.quad	.Ltmp117-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges4:
	.quad	.Ltmp118-.Lfunc_begin0
	.quad	.Ltmp119-.Lfunc_begin0
	.quad	.Ltmp120-.Lfunc_begin0
	.quad	.Ltmp121-.Lfunc_begin0
	.quad	.Ltmp122-.Lfunc_begin0
	.quad	.Ltmp123-.Lfunc_begin0
	.quad	.Ltmp124-.Lfunc_begin0
	.quad	.Ltmp125-.Lfunc_begin0
	.quad	.Ltmp126-.Lfunc_begin0
	.quad	.Ltmp127-.Lfunc_begin0
	.quad	.Ltmp128-.Lfunc_begin0
	.quad	.Ltmp129-.Lfunc_begin0
	.quad	.Ltmp130-.Lfunc_begin0
	.quad	.Ltmp131-.Lfunc_begin0
	.quad	.Ltmp132-.Lfunc_begin0
	.quad	.Ltmp133-.Lfunc_begin0
	.quad	.Ltmp134-.Lfunc_begin0
	.quad	.Ltmp136-.Lfunc_begin0
	.quad	.Ltmp137-.Lfunc_begin0
	.quad	.Ltmp139-.Lfunc_begin0
	.quad	.Ltmp140-.Lfunc_begin0
	.quad	.Ltmp141-.Lfunc_begin0
	.quad	.Ltmp142-.Lfunc_begin0
	.quad	.Ltmp143-.Lfunc_begin0
	.quad	.Ltmp144-.Lfunc_begin0
	.quad	.Ltmp146-.Lfunc_begin0
	.quad	.Ltmp147-.Lfunc_begin0
	.quad	.Ltmp154-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges5:
	.quad	.Ltmp118-.Lfunc_begin0
	.quad	.Ltmp119-.Lfunc_begin0
	.quad	.Ltmp120-.Lfunc_begin0
	.quad	.Ltmp121-.Lfunc_begin0
	.quad	.Ltmp122-.Lfunc_begin0
	.quad	.Ltmp123-.Lfunc_begin0
	.quad	.Ltmp124-.Lfunc_begin0
	.quad	.Ltmp125-.Lfunc_begin0
	.quad	.Ltmp126-.Lfunc_begin0
	.quad	.Ltmp127-.Lfunc_begin0
	.quad	.Ltmp128-.Lfunc_begin0
	.quad	.Ltmp129-.Lfunc_begin0
	.quad	.Ltmp130-.Lfunc_begin0
	.quad	.Ltmp131-.Lfunc_begin0
	.quad	.Ltmp132-.Lfunc_begin0
	.quad	.Ltmp133-.Lfunc_begin0
	.quad	.Ltmp134-.Lfunc_begin0
	.quad	.Ltmp135-.Lfunc_begin0
	.quad	.Ltmp137-.Lfunc_begin0
	.quad	.Ltmp138-.Lfunc_begin0
	.quad	.Ltmp140-.Lfunc_begin0
	.quad	.Ltmp141-.Lfunc_begin0
	.quad	.Ltmp142-.Lfunc_begin0
	.quad	.Ltmp143-.Lfunc_begin0
	.quad	.Ltmp144-.Lfunc_begin0
	.quad	.Ltmp145-.Lfunc_begin0
	.quad	.Ltmp147-.Lfunc_begin0
	.quad	.Ltmp148-.Lfunc_begin0
	.quad	.Ltmp149-.Lfunc_begin0
	.quad	.Ltmp150-.Lfunc_begin0
	.quad	.Ltmp151-.Lfunc_begin0
	.quad	.Ltmp152-.Lfunc_begin0
	.quad	.Ltmp153-.Lfunc_begin0
	.quad	.Ltmp154-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges6:
	.quad	.Ltmp155-.Lfunc_begin0
	.quad	.Ltmp156-.Lfunc_begin0
	.quad	.Ltmp157-.Lfunc_begin0
	.quad	.Ltmp158-.Lfunc_begin0
	.quad	.Ltmp159-.Lfunc_begin0
	.quad	.Ltmp160-.Lfunc_begin0
	.quad	.Ltmp161-.Lfunc_begin0
	.quad	.Ltmp162-.Lfunc_begin0
	.quad	.Ltmp163-.Lfunc_begin0
	.quad	.Ltmp164-.Lfunc_begin0
	.quad	.Ltmp165-.Lfunc_begin0
	.quad	.Ltmp166-.Lfunc_begin0
	.quad	.Ltmp167-.Lfunc_begin0
	.quad	.Ltmp168-.Lfunc_begin0
	.quad	.Ltmp169-.Lfunc_begin0
	.quad	.Ltmp170-.Lfunc_begin0
	.quad	.Ltmp171-.Lfunc_begin0
	.quad	.Ltmp172-.Lfunc_begin0
	.quad	.Ltmp173-.Lfunc_begin0
	.quad	.Ltmp174-.Lfunc_begin0
	.quad	.Ltmp175-.Lfunc_begin0
	.quad	.Ltmp176-.Lfunc_begin0
	.quad	.Ltmp177-.Lfunc_begin0
	.quad	.Ltmp178-.Lfunc_begin0
	.quad	.Ltmp179-.Lfunc_begin0
	.quad	.Ltmp180-.Lfunc_begin0
	.quad	.Ltmp181-.Lfunc_begin0
	.quad	.Ltmp182-.Lfunc_begin0
	.quad	.Ltmp183-.Lfunc_begin0
	.quad	.Ltmp184-.Lfunc_begin0
	.quad	.Ltmp185-.Lfunc_begin0
	.quad	.Ltmp186-.Lfunc_begin0
	.quad	.Ltmp187-.Lfunc_begin0
	.quad	.Ltmp188-.Lfunc_begin0
	.quad	.Ltmp189-.Lfunc_begin0
	.quad	.Ltmp191-.Lfunc_begin0
	.quad	.Ltmp192-.Lfunc_begin0
	.quad	.Ltmp193-.Lfunc_begin0
	.quad	.Ltmp194-.Lfunc_begin0
	.quad	.Ltmp195-.Lfunc_begin0
	.quad	.Ltmp196-.Lfunc_begin0
	.quad	.Ltmp198-.Lfunc_begin0
	.quad	.Ltmp199-.Lfunc_begin0
	.quad	.Ltmp200-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges7:
	.quad	.Ltmp155-.Lfunc_begin0
	.quad	.Ltmp156-.Lfunc_begin0
	.quad	.Ltmp157-.Lfunc_begin0
	.quad	.Ltmp158-.Lfunc_begin0
	.quad	.Ltmp159-.Lfunc_begin0
	.quad	.Ltmp160-.Lfunc_begin0
	.quad	.Ltmp161-.Lfunc_begin0
	.quad	.Ltmp162-.Lfunc_begin0
	.quad	.Ltmp163-.Lfunc_begin0
	.quad	.Ltmp164-.Lfunc_begin0
	.quad	.Ltmp165-.Lfunc_begin0
	.quad	.Ltmp166-.Lfunc_begin0
	.quad	.Ltmp167-.Lfunc_begin0
	.quad	.Ltmp168-.Lfunc_begin0
	.quad	.Ltmp169-.Lfunc_begin0
	.quad	.Ltmp170-.Lfunc_begin0
	.quad	.Ltmp171-.Lfunc_begin0
	.quad	.Ltmp172-.Lfunc_begin0
	.quad	.Ltmp173-.Lfunc_begin0
	.quad	.Ltmp174-.Lfunc_begin0
	.quad	.Ltmp175-.Lfunc_begin0
	.quad	.Ltmp176-.Lfunc_begin0
	.quad	.Ltmp177-.Lfunc_begin0
	.quad	.Ltmp178-.Lfunc_begin0
	.quad	.Ltmp179-.Lfunc_begin0
	.quad	.Ltmp180-.Lfunc_begin0
	.quad	.Ltmp181-.Lfunc_begin0
	.quad	.Ltmp182-.Lfunc_begin0
	.quad	.Ltmp183-.Lfunc_begin0
	.quad	.Ltmp184-.Lfunc_begin0
	.quad	.Ltmp185-.Lfunc_begin0
	.quad	.Ltmp186-.Lfunc_begin0
	.quad	.Ltmp189-.Lfunc_begin0
	.quad	.Ltmp190-.Lfunc_begin0
	.quad	.Ltmp196-.Lfunc_begin0
	.quad	.Ltmp197-.Lfunc_begin0
	.quad	.Ltmp199-.Lfunc_begin0
	.quad	.Ltmp200-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges8:
	.quad	.Ltmp201-.Lfunc_begin0
	.quad	.Ltmp202-.Lfunc_begin0
	.quad	.Ltmp203-.Lfunc_begin0
	.quad	.Ltmp204-.Lfunc_begin0
	.quad	.Ltmp205-.Lfunc_begin0
	.quad	.Ltmp207-.Lfunc_begin0
	.quad	.Ltmp208-.Lfunc_begin0
	.quad	.Ltmp209-.Lfunc_begin0
	.quad	.Ltmp210-.Lfunc_begin0
	.quad	.Ltmp217-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges9:
	.quad	.Ltmp201-.Lfunc_begin0
	.quad	.Ltmp202-.Lfunc_begin0
	.quad	.Ltmp203-.Lfunc_begin0
	.quad	.Ltmp204-.Lfunc_begin0
	.quad	.Ltmp206-.Lfunc_begin0
	.quad	.Ltmp207-.Lfunc_begin0
	.quad	.Ltmp210-.Lfunc_begin0
	.quad	.Ltmp211-.Lfunc_begin0
	.quad	.Ltmp212-.Lfunc_begin0
	.quad	.Ltmp213-.Lfunc_begin0
	.quad	.Ltmp214-.Lfunc_begin0
	.quad	.Ltmp215-.Lfunc_begin0
	.quad	.Ltmp216-.Lfunc_begin0
	.quad	.Ltmp217-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges10:
	.quad	.Ltmp218-.Lfunc_begin0
	.quad	.Ltmp219-.Lfunc_begin0
	.quad	.Ltmp220-.Lfunc_begin0
	.quad	.Ltmp221-.Lfunc_begin0
	.quad	.Ltmp222-.Lfunc_begin0
	.quad	.Ltmp223-.Lfunc_begin0
	.quad	.Ltmp224-.Lfunc_begin0
	.quad	.Ltmp225-.Lfunc_begin0
	.quad	.Ltmp226-.Lfunc_begin0
	.quad	.Ltmp227-.Lfunc_begin0
	.quad	.Ltmp228-.Lfunc_begin0
	.quad	.Ltmp229-.Lfunc_begin0
	.quad	.Ltmp230-.Lfunc_begin0
	.quad	.Ltmp231-.Lfunc_begin0
	.quad	.Ltmp232-.Lfunc_begin0
	.quad	.Ltmp233-.Lfunc_begin0
	.quad	.Ltmp234-.Lfunc_begin0
	.quad	.Ltmp235-.Lfunc_begin0
	.quad	.Ltmp236-.Lfunc_begin0
	.quad	.Ltmp237-.Lfunc_begin0
	.quad	.Ltmp238-.Lfunc_begin0
	.quad	.Ltmp239-.Lfunc_begin0
	.quad	.Ltmp240-.Lfunc_begin0
	.quad	.Ltmp241-.Lfunc_begin0
	.quad	.Ltmp242-.Lfunc_begin0
	.quad	.Ltmp243-.Lfunc_begin0
	.quad	.Ltmp244-.Lfunc_begin0
	.quad	.Ltmp245-.Lfunc_begin0
	.quad	.Ltmp246-.Lfunc_begin0
	.quad	.Ltmp248-.Lfunc_begin0
	.quad	.Ltmp249-.Lfunc_begin0
	.quad	.Ltmp251-.Lfunc_begin0
	.quad	.Ltmp252-.Lfunc_begin0
	.quad	.Ltmp254-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges11:
	.quad	.Ltmp218-.Lfunc_begin0
	.quad	.Ltmp219-.Lfunc_begin0
	.quad	.Ltmp220-.Lfunc_begin0
	.quad	.Ltmp221-.Lfunc_begin0
	.quad	.Ltmp222-.Lfunc_begin0
	.quad	.Ltmp223-.Lfunc_begin0
	.quad	.Ltmp224-.Lfunc_begin0
	.quad	.Ltmp225-.Lfunc_begin0
	.quad	.Ltmp226-.Lfunc_begin0
	.quad	.Ltmp227-.Lfunc_begin0
	.quad	.Ltmp228-.Lfunc_begin0
	.quad	.Ltmp229-.Lfunc_begin0
	.quad	.Ltmp230-.Lfunc_begin0
	.quad	.Ltmp231-.Lfunc_begin0
	.quad	.Ltmp232-.Lfunc_begin0
	.quad	.Ltmp233-.Lfunc_begin0
	.quad	.Ltmp234-.Lfunc_begin0
	.quad	.Ltmp235-.Lfunc_begin0
	.quad	.Ltmp236-.Lfunc_begin0
	.quad	.Ltmp237-.Lfunc_begin0
	.quad	.Ltmp238-.Lfunc_begin0
	.quad	.Ltmp239-.Lfunc_begin0
	.quad	.Ltmp242-.Lfunc_begin0
	.quad	.Ltmp243-.Lfunc_begin0
	.quad	.Ltmp246-.Lfunc_begin0
	.quad	.Ltmp247-.Lfunc_begin0
	.quad	.Ltmp249-.Lfunc_begin0
	.quad	.Ltmp250-.Lfunc_begin0
	.quad	.Ltmp253-.Lfunc_begin0
	.quad	.Ltmp254-.Lfunc_begin0
	.quad	0
	.quad	0
	.section	.debug_str,"MS",@progbits,1
.Linfo_string0:
	.asciz	"triton"                        ; string offset=0
.Linfo_string1:
	.asciz	"bench.py"                      ; string offset=7
.Linfo_string2:
	.asciz	"/"                             ; string offset=16
.Linfo_string3:
	.asciz	"_grouped_gqa8_fp8kv_fwd_kernel" ; string offset=18
	.section	".note.GNU-stack","",@progbits
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     153
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
    .max_flat_workgroup_size: 64
    .name:           _grouped_gqa8_fp8kv_fwd_kernel
    .private_segment_fixed_size: 0
    .sgpr_count:     102
    .sgpr_spill_count: 0
    .symbol:         _grouped_gqa8_fp8kv_fwd_kernel.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     409
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
