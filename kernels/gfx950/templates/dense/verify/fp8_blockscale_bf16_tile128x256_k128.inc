// SPDX-License-Identifier: MIT
// Model-independent, fixed-contract gfx950 schedule frozen from profiled machine code.
	.include "kernels/gfx950/templates/common/primitives.inc"
	NETRA_GFX950_MODULE_HEADER 6
	.macro NETRA_DENSE_FP8_BLOCKSCALE_BF16_TILE128X256_K128 symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_M, 1536
	NETRA_REQUIRE_EQ NETRA_N, 5120
	.section	.text,"axG",@progbits,\symbol,comdat,unique,20
	.protected	\symbol ; -- Begin function \symbol
	.globl	\symbol
	.p2align	8
	.type	\symbol,@function
\symbol: ; @\symbol
; %bb.0:
	s_load_dwordx4 s[16:19], s[0:1], 0x28
	s_load_dwordx2 s[12:13], s[0:1], 0x20
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	s_waitcnt lgkmcnt(0)
	s_add_i32 s14, s17, 0xff
	s_ashr_i32 s15, s14, 31
	s_lshr_b32 s15, s15, 24
	s_add_i32 s14, s14, s15
	s_ashr_i32 s20, s14, 8
	s_abs_i32 s22, s20
	v_cvt_f32_u32_e32 v1, s22
	s_load_dwordx2 s[14:15], s[0:1], 0x38
	s_load_dwordx2 s[28:29], s[0:1], 0x44
	s_load_dword s34, s[0:1], 0x50
	s_getpc_b64 s[0:1]
	s_add_u32 s0, s0, .Lnetra_dense_constant_0@rel32@lo+4
	s_addc_u32 s1, s1, .Lnetra_dense_constant_0@rel32@hi+12
	v_mov_b32_e32 v2, 0
	v_rcp_iflag_f32_e32 v1, v1
	v_mov_b32_e32 v3, s17
	global_store_dword v2, v3, s[0:1]
	s_xor_b32 s0, s2, s20
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	s_ashr_i32 s1, s0, 31
	s_abs_i32 s21, s2
	s_sub_i32 s23, 0, s22
	v_readfirstlane_b32 s0, v1
	s_mul_i32 s23, s23, s0
	s_mul_hi_u32 s23, s0, s23
	s_add_i32 s0, s0, s23
	s_mul_hi_u32 s0, s21, s0
	s_mul_i32 s23, s0, s22
	s_sub_i32 s21, s21, s23
	s_add_i32 s24, s0, 1
	s_sub_i32 s23, s21, s22
	s_cmp_ge_u32 s21, s22
	s_cselect_b32 s0, s24, s0
	s_cselect_b32 s23, s23, s21
	s_add_i32 s21, s0, 1
	s_cmp_ge_u32 s23, s22
	s_cselect_b32 s22, s21, s0
	s_waitcnt lgkmcnt(0)
	s_lshl_b32 s0, s34, 7
	s_abs_i32 s21, s0
	v_cvt_f32_u32_e32 v1, s21
	s_xor_b32 s22, s22, s1
	s_sub_i32 s22, s22, s1
	s_mul_i32 s23, s22, s20
	v_rcp_iflag_f32_e32 v1, v1
	s_add_i32 s1, s18, s0
	s_add_i32 s1, s1, -1
	s_xor_b32 s0, s1, s0
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	s_ashr_i32 s0, s0, 31
	s_abs_i32 s20, s1
	s_sub_i32 s24, 0, s21
	v_readfirstlane_b32 s1, v1
	s_mul_i32 s24, s24, s1
	s_mul_hi_u32 s24, s1, s24
	s_add_i32 s1, s1, s24
	s_mul_hi_u32 s1, s20, s1
	s_mul_i32 s24, s1, s21
	s_sub_i32 s20, s20, s24
	s_add_i32 s25, s1, 1
	s_sub_i32 s24, s20, s21
	s_cmp_ge_u32 s20, s21
	s_cselect_b32 s1, s25, s1
	s_cselect_b32 s24, s24, s20
	s_add_i32 s20, s1, 1
	s_cmp_ge_u32 s24, s21
	s_cselect_b32 s1, s20, s1
	s_xor_b32 s1, s1, s0
	s_sub_i32 s0, s1, s0
	s_lshl_b32 s24, s0, 7
	s_ashr_i32 s0, s24, 31
	s_mul_i32 s0, s0, s3
	s_mul_hi_u32 s1, s24, s3
	s_add_i32 s1, s1, s0
	s_add_i32 s20, s34, -1
	s_cmp_ge_u32 s3, s20
	s_mul_i32 s0, s24, s3
	s_cbranch_scc0 .LBB19_2
; %bb.1:
	s_mul_i32 s3, s24, s20
	s_sub_i32 s42, s18, s3
	s_mov_b64 vcc, exec
	s_cbranch_execz .LBB19_3
	s_branch .LBB19_4
.LBB19_2:
                                        ; implicit-def: $sgpr42
	s_mov_b64 vcc, 0
.LBB19_3:
	s_mov_b32 s42, s24
.LBB19_4:                               ; %_ZN7ck_tile15QuantGemmKernelINS_21GemmTile1DPartitionerINS_13TileGemmShapeINS_8sequenceIJLi128ELi256ELi128EEEENS3_IJLi4ELi2ELi1EEEENS3_IJLi16ELi16ELi128EEEELb0ELb0EEEEENS_35ABQuantGemmPipelineAgBgCrEightWavesINS_28GemmQuantPipelineProblemBaseIDB8_fSB_ffS7_NS_19TileGemmQuantTraitsILb1ELb0ELb0ELb0ELb0ELb1ENS_13tensor_layout4gemm8RowMajorENSE_11ColumnMajorESF_LNS_9QuantTypeE4ESG_SG_Lb1ELb1ELb0ELi16EEENS_15QuantGroupShapeINS3_IJLi1ELi1ELi128EEEEEENSJ_INS3_IJLi1ELi128ELi128EEEEEELb1ESB_LNS_21GemmPipelineSchedulerE1ELb1ELNS_10TailNumberE1ELNS_10CastPolicyE1EEENS_36GemmABQuantPipelineAgBgCrAsyncPolicyEEENS_16CShuffleEpilogueINS_23CShuffleEpilogueProblemISB_SB_NS_5tupleIJEEEfDF16bSX_SF_NS_12element_wise11PassThroughELi128ELi256ELi4ELi2ELi16ELi16ELi128ELb1ELi1ELb0ELi1ELi1ELb0EEEvEELSH_4EE17SplitKBatchOffsetC2ERKNS_19QuantGemmKernelArgsEm.exit.i.i
	s_lshl_b32 s33, s22, 7
	s_sub_i32 s35, s2, s23
	s_ashr_i32 s2, s0, 31
	s_lshr_b32 s2, s2, 25
	s_add_i32 s2, s0, s2
	s_ashr_i32 s2, s2, 7
	s_bfe_i64 s[0:1], s[0:1], 0x200000
	s_add_u32 s20, s4, s0
	s_addc_u32 s40, s5, s1
	s_add_u32 s4, s6, s0
	s_addc_u32 s39, s7, s1
	s_ashr_i32 s3, s2, 31
	s_lshl_b64 s[0:1], s[2:3], 2
	s_add_u32 s8, s8, s0
	s_addc_u32 s9, s9, s1
	s_add_u32 s24, s10, s0
	s_addc_u32 s25, s11, s1
	s_mov_b32 s43, -1
	s_add_i32 s16, s16, -1
	s_ashr_i32 s3, s16, 31
	s_mul_hi_i32 s1, s16, s15
	s_mul_i32 s0, s16, s15
	s_add_i32 s6, s42, -1
	s_ashr_i32 s5, s6, 31
	s_add_u32 s0, s0, s6
	s_addc_u32 s1, s1, s5
	s_add_u32 s0, s0, 1
	s_addc_u32 s1, s1, 0
	v_mov_b64_e32 v[2:3], 0x7fffffff
	v_cmp_lt_i64_e32 vcc, s[0:1], v[2:3]
	s_and_b64 s[6:7], vcc, exec
	s_cselect_b32 s22, s0, 0x7fffffff
	s_ashr_i32 s0, s42, 31
	s_ashr_i32 s1, s18, 31
	s_lshr_b32 s1, s1, 25
	s_add_i32 s1, s18, s1
	s_ashr_i32 s41, s1, 7
	s_lshl_b32 s11, s41, 11
	s_abs_i32 s7, s11
	v_cvt_f32_u32_e32 v1, s7
	s_lshr_b32 s0, s0, 25
	s_add_i32 s0, s42, s0
	s_lshl_b32 s0, s0, 4
	v_rcp_iflag_f32_e32 v1, v1
	s_and_b32 s6, s0, 0xfffff800
	s_mul_i32 s0, s18, s17
	s_xor_b32 s1, s0, s11
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	s_ashr_i32 s1, s1, 31
	s_abs_i32 s5, s0
	s_sub_i32 s10, 0, s7
	v_readfirstlane_b32 s0, v1
	s_mul_i32 s10, s10, s0
	s_mul_hi_u32 s10, s0, s10
	s_add_i32 s0, s0, s10
	s_mul_hi_u32 s0, s5, s0
	s_mul_i32 s10, s0, s7
	s_sub_i32 s5, s5, s10
	s_add_i32 s18, s0, 1
	s_sub_i32 s10, s5, s7
	s_cmp_ge_u32 s5, s7
	s_cselect_b32 s0, s18, s0
	s_cselect_b32 s10, s10, s5
	s_add_i32 s5, s0, 1
	s_cmp_ge_u32 s10, s7
	s_cselect_b32 s0, s5, s0
	s_xor_b32 s0, s0, s1
	s_not_b32 s1, s1
	s_add_i32 s0, s1, s0
	s_mul_hi_i32 s1, s0, s11
	s_mul_i32 s0, s0, s11
	s_add_i32 s6, s6, -1
	s_ashr_i32 s5, s6, 31
	s_add_u32 s0, s6, s0
	s_addc_u32 s1, s5, s1
	s_add_u32 s0, s0, 1
	s_addc_u32 s1, s1, 0
	v_cmp_lt_i64_e32 vcc, s[0:1], v[2:3]
	s_and_b64 s[6:7], vcc, exec
	s_cselect_b32 s0, s0, 0x7fffffff
	s_lshl_b32 s26, s35, 4
	s_not_b32 s5, s2
	s_add_i32 s2, s5, s19
	s_mul_hi_i32 s1, s2, s29
	s_mul_i32 s2, s2, s29
	s_add_u32 s2, s16, s2
	s_addc_u32 s1, s3, s1
	s_add_u32 s2, s2, 1
	s_addc_u32 s3, s1, 0
	v_cmp_lt_i64_e32 vcc, s[2:3], v[2:3]
	s_and_b64 s[6:7], vcc, exec
	s_cselect_b32 s47, s2, 0x7fffffff
	s_add_i32 s1, s17, 0x7f
	s_ashr_i32 s2, s1, 31
	s_lshr_b32 s2, s2, 25
	s_add_i32 s1, s1, s2
	s_ashr_i32 s2, s1, 7
	s_add_i32 s2, s2, -1
	s_mul_hi_i32 s1, s2, s14
	s_mul_i32 s2, s2, s14
	s_add_i32 s5, s5, s14
	s_ashr_i32 s3, s5, 31
	s_add_u32 s2, s2, s5
	s_addc_u32 s1, s1, s3
	s_add_u32 s2, s2, 1
	s_addc_u32 s3, s1, 0
	v_cmp_lt_i64_e32 vcc, s[2:3], v[2:3]
	s_and_b64 s[6:7], vcc, exec
	s_cselect_b32 s51, s2, 0x7fffffff
	s_lshl_b32 s21, s35, 1
	v_readfirstlane_b32 s10, v0
	s_lshr_b32 s48, s10, 6
	s_cmpk_gt_u32 s10, 0xff
	s_cselect_b64 s[18:19], -1, 0
	s_cmpk_lt_u32 s10, 0x100
	s_cselect_b64 s[2:3], -1, 0
	s_and_b64 s[6:7], s[2:3], exec
	s_cselect_b32 s44, 0xc010, 0
	v_mbcnt_lo_u32_b32 v1, -1, 0
	v_mbcnt_hi_u32_b32 v82, -1, v1
	v_lshrrev_b32_e32 v83, 3, v82
	v_lshlrev_b32_e32 v4, 4, v82
	v_and_b32_e32 v2, 0x70, v4
	s_lshl_b32 s1, s48, 3
	s_add_i32 s1, s1, s33
	v_add_u32_e32 v1, s1, v83
	v_ashrrev_i32_e32 v3, 31, v1
	v_lshrrev_b32_e32 v3, 30, v3
	v_add_u32_e32 v3, v1, v3
	v_and_b32_e32 v3, -4, v3
	v_sub_u32_e32 v149, v1, v3
	v_bitop3_b32 v151, v149, v82, 7 bitop3:0x78
	v_mul_lo_u32 v1, v1, s15
	v_lshl_add_u32 v3, v151, 4, v1
	v_and_b32_e32 v1, 15, v82
	s_lshr_b32 s1, s10, 8
	s_bfe_u32 s23, s10, 0x10007
	s_lshl_b32 s6, s10, 4
	s_and_b32 s53, s6, 0x400
	s_lshl_b32 s27, s1, 3
	s_lshl_b32 s54, s23, 13
	s_lshr_b32 s50, s10, 9
	s_bfe_u32 s49, s10, 0x10008
	s_lshr_b32 s5, s10, 2
	s_and_b32 s5, s5, 48
	s_mul_i32 s7, s50, s29
	s_add_i32 s26, s27, s26
	s_or_b32 s23, s26, s23
	s_mul_i32 s11, s23, s11
	s_or_b32 s52, s49, s21
	s_mul_i32 s52, s52, s14
	s_or_b32 s11, s11, s53
	v_add_u32_e32 v4, s11, v4
	s_add_i32 s7, s7, s33
	s_add_i32 s5, s7, s5
	v_add_u32_e32 v5, s5, v1
	s_add_i32 s52, s52, s50
	; sched_barrier mask(0x00000000)
	s_bitcmp1_b32 s10, 6
	s_cselect_b32 s5, 0x2010, 0
	s_and_b32 s6, s6, 0x1800
	s_lshl_b32 s7, s10, 1
	s_and_b32 s45, s7, 0xfffffc00
	s_add_i32 s45, s45, s6
	s_add_i32 s45, s45, s5
	s_and_b64 vcc, exec, s[18:19]
	s_mul_i32 s55, s41, 0x3000
	s_cbranch_vccz .LBB19_6
; %bb.5:                                ; %_ZZN7ck_tile30move_tensor_adaptor_coordinateILb1ENS_17tensor_descriptorINS_5tupleIJNS_5embedINS2_IJiiEEES4_Lb0EEENS_12pass_throughIiEES7_NS_7unmergeINS2_IJiNS_8constantILi4EEEEEELb0EEENS8_INS2_IJiNS9_ILi1EEENS9_ILi8EEENS9_ILi16EEEEEELb0EEES7_NS_5xor_tINS2_IJSA_SE_EEELb1EEES7_NS6_ISD_EENS6_ISF_EENS_21merge_v3_division_modISB_EENSN_ISG_EEEEENS2_IJNS_8sequenceIJLi0EEEENSR_IJLi1EEEENSR_IJLi2EEEENSR_IJLi3EEEENSR_IJLi4EEEENSR_IJLi5EEEENSR_IJLi6ELi9EEEENSR_IJLi7EEEENSR_IJLi8EEEENSR_IJLi10EEEENSR_IJLi11ELi12EEEENSR_IJLi14ELi15ELi13ELi16EEEEEEENS2_IJNSR_IJLi1ELi2EEEESV_SW_NSR_IJLi5ELi6EEEENSR_IJLi7ELi8ELi9ELi10EEEENSR_IJLi11EEEENSR_IJLi12ELi13EEEENSR_IJLi14EEEENSR_IJLi15EEEENSR_IJLi16EEEENSR_IJLi17EEEENSR_IJLi18EEEEEEENSR_IJLi17ELi18EEEEiNSR_IJLin1ELin1ELi16ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEENSR_IJLin1ELin1ELi1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEEEENS_17tensor_coordinateILi19ES1G_EENS_5arrayIiLi2EEENS1M_IiLi1EEEEEvRKT0_RT1_
	s_lshl_b32 s1, s1, 14
	s_add_i32 s5, s44, s45
	s_mov_b32 s23, 0x20000
	s_and_b32 s21, s40, 0xffff
	s_mov_b32 m0, s5
	s_nop 0
	buffer_load_dwordx4 v3, s[20:23], 0 offen lds
	s_add_i32 m0, s5, 0x400
	s_lshl_b32 s14, s15, 6
	buffer_load_dwordx4 v3, s[20:23], s14 offen lds
	s_lshl_b32 s10, s47, 2
	s_mov_b32 s11, s23
	v_lshlrev_b32_e32 v6, 2, v5
	buffer_load_dword v160, v6, s[8:11], 0 offen
	buffer_load_dword v158, v6, s[8:11], 0 offen offset:256
	s_lshl_b32 s26, s51, 2
	s_mov_b32 s27, s23
	s_lshl_b32 s5, s52, 2
	v_mov_b32_e32 v6, s5
	buffer_load_dword v161, v6, s[24:27], 0 offen
	s_lshl_b32 s5, s53, 2
	s_or_b32 s1, s5, s1
	s_or_b32 s46, s1, s54
	s_add_i32 s1, s44, s46
	s_add_i32 m0, s1, 0x4010
	s_and_b32 s5, s39, 0xffff
	s_mov_b32 s6, s0
	s_mov_b32 s7, s23
	buffer_load_dwordx4 v4, s[4:7], 0 offen lds
	s_add_i32 m0, s1, 0x4410
	s_lshl_b32 s36, s41, 12
	buffer_load_dwordx4 v4, s[4:7], s36 offen lds
	s_add_i32 m0, s1, 0x4810
	s_lshl_b32 s37, s41, 13
	buffer_load_dwordx4 v4, s[4:7], s37 offen lds
	s_add_i32 m0, s1, 0x4c10
	s_mul_i32 s38, s41, 0x3000
	buffer_load_dwordx4 v4, s[4:7], s38 offen lds
	s_mov_b32 s1, s23
	s_waitcnt vmcnt(7)
	s_barrier
	v_or_b32_e32 v154, 0x80, v2
	v_add_u32_e32 v153, 0x80, v3
	v_add_u32_e32 v168, 0x800, v4
	v_add_u32_e32 v152, s29, v5
	s_add_i32 s56, s52, 1
	s_mov_b64 s[6:7], s[0:1]
	s_mov_b64 vcc, exec
	s_cbranch_execz .LBB19_7
	s_branch .LBB19_8
.LBB19_6:
                                        ; implicit-def: $vgpr154
                                        ; implicit-def: $vgpr153
                                        ; implicit-def: $vgpr152
                                        ; implicit-def: $sgpr56
                                        ; implicit-def: $vgpr168
                                        ; implicit-def: $vgpr161
                                        ; implicit-def: $vgpr160
                                        ; implicit-def: $vgpr158
                                        ; implicit-def: $sgpr14
                                        ; implicit-def: $sgpr46
                                        ; implicit-def: $sgpr36
                                        ; implicit-def: $sgpr37
                                        ; implicit-def: $sgpr38
	s_mov_b64 vcc, 0
.LBB19_7:                               ; %_ZN7ck_tile5arrayIiLi2EEC2ESt16initializer_listIiE.exit113._crit_edge.i.i.i.i.i.i.i.i
	s_mov_b32 s23, 0x20000
	s_and_b32 s21, s40, 0xffff
	s_lshl_b32 s14, s15, 6
	s_lshl_b32 s10, s47, 2
	s_lshl_b32 s26, s51, 2
	s_lshl_b32 s1, s53, 2
	s_or_b32 s46, s1, s54
	s_mov_b32 s1, s23
	s_and_b32 s5, s39, 0xffff
	s_lshl_b32 s36, s41, 12
	s_lshl_b32 s37, s41, 13
	s_mov_b32 s43, 0
	s_waitcnt vmcnt(5)
	v_mov_b32_e32 v158, 0
	s_waitcnt vmcnt(4)
	v_mov_b32_e32 v161, 0
	s_mov_b32 s38, s55
	s_mov_b64 s[6:7], s[0:1]
	v_mov_b32_e32 v160, 0
	v_mov_b32_e32 v168, v4
	s_mov_b32 s56, s52
	v_mov_b32_e32 v152, v5
	v_mov_b32_e32 v153, v3
	v_mov_b32_e32 v154, v2
.LBB19_8:
	s_and_b64 s[0:1], s[2:3], exec
	s_cselect_b32 s47, 0, 0xc010
	v_and_b32_e32 v2, 0x70, v82
	v_lshrrev_b16_e32 v3, 4, v82
	v_bitop3_b16 v3, v3, v82, 3 bitop3:0x78
	v_bfe_i32 v4, v82, 3, 1
	v_and_b32_e32 v4, 0x2010, v4
	s_lshl_b32 s0, s48, 11
	s_and_b32 s0, s0, 0x1800
	v_lshlrev_b32_e32 v5, 7, v82
	v_and_b32_e32 v5, 0x380, v5
	v_and_b32_e32 v3, 0xffff, v3
	v_or3_b32 v4, s0, v5, v4
	v_lshl_add_u32 v169, v3, 4, v4
	v_lshl_or_b32 v3, s50, 7, v2
	v_ashrrev_i32_e32 v2, 31, v3
	v_lshrrev_b32_e32 v2, 26, v2
	v_add_u32_e32 v2, v3, v2
	v_and_b32_e32 v4, 0xc0, v2
	v_sub_u32_e32 v3, v3, v4
	v_mov_b32_e32 v4, 4
	v_ashrrev_i16_sdwa v3, v4, sext(v3) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	s_lshl_b32 s0, s49, 14
	v_lshlrev_b32_e32 v2, 6, v2
	v_and_b32_e32 v2, 0xfffff000, v2
	v_mov_b32_e32 v4, 8
	v_lshlrev_b32_sdwa v3, v4, sext(v3) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_lshl_or_b32 v4, v1, 4, s0
	v_add3_u32 v167, v4, v2, v3
	s_mov_b32 s11, 0x20000
	s_mov_b32 s27, s11
	; sched_barrier mask(0x00000000)
	s_waitcnt vmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s15, s47, s45
	s_mov_b32 m0, s15
	s_nop 0
	buffer_load_dwordx4 v153, s[20:23], 0 offen lds
	s_add_i32 s40, s15, 0x400
	s_mov_b32 m0, s40
	s_nop 0
	buffer_load_dwordx4 v153, s[20:23], s14 offen lds
	v_lshlrev_b32_e32 v159, 2, v152
	buffer_load_dword v155, v159, s[8:11], 0 offen
	buffer_load_dword v156, v159, s[8:11], 0 offen offset:256
	s_lshl_b32 s49, s56, 2
	v_mov_b32_e32 v2, s49
	buffer_load_dword v157, v2, s[24:27], 0 offen
	s_add_i32 s39, s47, s46
	s_add_i32 s41, s39, 0x4010
	s_mov_b32 m0, s41
	s_nop 0
	buffer_load_dwordx4 v168, s[4:7], 0 offen lds
	s_add_i32 s30, s39, 0x4410
	s_mov_b32 m0, s30
	s_nop 0
	buffer_load_dwordx4 v168, s[4:7], s36 offen lds
	s_add_i32 s31, s39, 0x4810
	s_mov_b32 m0, s31
	s_nop 0
	buffer_load_dwordx4 v168, s[4:7], s37 offen lds
	s_addk_i32 s39, 0x4c10
	s_mov_b32 m0, s39
	s_nop 0
	buffer_load_dwordx4 v168, s[4:7], s38 offen lds
	v_mov_b32_e32 v84, 0
	v_cndmask_b32_e64 v2, 0, 1, s[18:19]
	v_cmp_ne_u32_e64 s[0:1], 1, v2
	s_andn2_b64 vcc, exec, s[18:19]
	v_add_u32_e32 v129, s44, v169
	v_add_u32_e32 v127, s44, v167
	v_mov_b32_e32 v74, 0
	v_mov_b32_e32 v75, 0
	v_mov_b32_e32 v76, 0
	v_mov_b32_e32 v77, 0
	v_mov_b32_e32 v78, 0
	v_mov_b32_e32 v79, 0
	v_mov_b32_e32 v80, 0
	v_mov_b32_e32 v81, 0
	v_mov_b32_e32 v18, 0
	v_mov_b32_e32 v19, 0
	v_mov_b32_e32 v20, 0
	v_mov_b32_e32 v21, 0
	v_mov_b32_e32 v22, 0
	v_mov_b32_e32 v23, 0
	v_mov_b32_e32 v24, 0
	v_mov_b32_e32 v25, 0
	v_mov_b32_e32 v26, 0
	v_mov_b32_e32 v27, 0
	v_mov_b32_e32 v28, 0
	v_mov_b32_e32 v29, 0
	v_mov_b32_e32 v30, 0
	v_mov_b32_e32 v31, 0
	v_mov_b32_e32 v32, 0
	v_mov_b32_e32 v33, 0
	v_mov_b32_e32 v34, 0
	v_mov_b32_e32 v35, 0
	v_mov_b32_e32 v36, 0
	v_mov_b32_e32 v37, 0
	v_mov_b32_e32 v38, 0
	v_mov_b32_e32 v39, 0
	v_mov_b32_e32 v40, 0
	v_mov_b32_e32 v41, 0
	v_mov_b32_e32 v42, 0
	v_mov_b32_e32 v43, 0
	v_mov_b32_e32 v44, 0
	v_mov_b32_e32 v45, 0
	v_mov_b32_e32 v46, 0
	v_mov_b32_e32 v47, 0
	v_mov_b32_e32 v48, 0
	v_mov_b32_e32 v49, 0
	v_mov_b32_e32 v50, 0
	v_mov_b32_e32 v51, 0
	v_mov_b32_e32 v52, 0
	v_mov_b32_e32 v53, 0
	v_mov_b32_e32 v54, 0
	v_mov_b32_e32 v55, 0
	v_mov_b32_e32 v56, 0
	v_mov_b32_e32 v57, 0
	v_mov_b32_e32 v66, 0
	v_mov_b32_e32 v67, 0
	v_mov_b32_e32 v68, 0
	v_mov_b32_e32 v69, 0
	v_mov_b32_e32 v70, 0
	v_mov_b32_e32 v71, 0
	v_mov_b32_e32 v72, 0
	v_mov_b32_e32 v73, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v7, 0
	v_mov_b32_e32 v8, 0
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v58, 0
	v_mov_b32_e32 v59, 0
	v_mov_b32_e32 v60, 0
	v_mov_b32_e32 v61, 0
	v_mov_b32_e32 v62, 0
	v_mov_b32_e32 v63, 0
	v_mov_b32_e32 v64, 0
	v_mov_b32_e32 v65, 0
	v_mov_b32_e32 v10, 0
	v_mov_b32_e32 v11, 0
	v_mov_b32_e32 v12, 0
	v_mov_b32_e32 v13, 0
	v_mov_b32_e32 v14, 0
	v_mov_b32_e32 v15, 0
	v_mov_b32_e32 v16, 0
	v_mov_b32_e32 v17, 0
	s_cbranch_vccnz .LBB19_10
; %bb.9:
	ds_read_b128 v[10:13], v129
	ds_read_b128 v[14:17], v129 offset:64
	ds_read_b128 v[2:5], v129 offset:1024
	ds_read_b128 v[6:9], v129 offset:1088
	ds_read_b128 v[58:61], v127 offset:16400
	ds_read_b128 v[50:53], v127 offset:17424
	ds_read_b128 v[62:65], v127 offset:20496
	ds_read_b128 v[54:57], v127 offset:21520
	ds_read_b128 v[66:69], v127 offset:24592
	ds_read_b128 v[42:45], v127 offset:25616
	ds_read_b128 v[70:73], v127 offset:28688
	ds_read_b128 v[46:49], v127 offset:29712
	ds_read_b128 v[34:37], v127 offset:18448
	ds_read_b128 v[18:21], v127 offset:19472
	ds_read_b128 v[38:41], v127 offset:22544
	ds_read_b128 v[22:25], v127 offset:23568
	ds_read_b128 v[26:29], v127 offset:26640
	ds_read_b128 v[74:77], v127 offset:27664
	ds_read_b128 v[30:33], v127 offset:30736
	ds_read_b128 v[78:81], v127 offset:31760
.LBB19_10:
	s_waitcnt vmcnt(7)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_and_b64 vcc, exec, s[0:1]
	v_mov_b32_e32 v85, 0
	v_mov_b32_e32 v87, 0
	v_mov_b32_e32 v89, 0
	v_mov_b32_e32 v91, 0
	v_mov_b32_e32 v93, 0
	v_mov_b32_e32 v94, 0
	v_mov_b32_e32 v96, 0
	v_mov_b32_e32 v98, 0
	v_mov_b32_e32 v100, 0
	v_mov_b32_e32 v102, 0
	v_mov_b32_e32 v103, 0
	v_mov_b32_e32 v106, 0
	v_mov_b32_e32 v107, 0
	v_mov_b32_e32 v110, 0
	v_mov_b32_e32 v111, 0
	v_mov_b32_e32 v113, 0
	v_mov_b32_e32 v115, 0
	v_mov_b32_e32 v117, 0
	v_mov_b32_e32 v119, 0
	v_mov_b32_e32 v120, 0
	v_mov_b32_e32 v122, 0
	v_mov_b32_e32 v124, 0
	v_mov_b32_e32 v126, 0
	v_mov_b32_e32 v130, 0
	v_mov_b32_e32 v131, 0
	v_mov_b32_e32 v133, 0
	v_mov_b32_e32 v135, 0
	v_mov_b32_e32 v136, 0
	v_mov_b32_e32 v138, 0
	v_mov_b32_e32 v140, 0
	v_mov_b32_e32 v142, 0
	v_mov_b32_e32 v86, 0
	v_mov_b32_e32 v88, 0
	v_mov_b32_e32 v90, 0
	v_mov_b32_e32 v92, 0
	v_mov_b32_e32 v95, 0
	v_mov_b32_e32 v97, 0
	v_mov_b32_e32 v99, 0
	v_mov_b32_e32 v101, 0
	v_mov_b32_e32 v104, 0
	v_mov_b32_e32 v105, 0
	v_mov_b32_e32 v108, 0
	v_mov_b32_e32 v109, 0
	v_mov_b32_e32 v112, 0
	v_mov_b32_e32 v114, 0
	v_mov_b32_e32 v116, 0
	v_mov_b32_e32 v118, 0
	v_mov_b32_e32 v121, 0
	v_mov_b32_e32 v123, 0
	v_mov_b32_e32 v125, 0
	v_mov_b32_e32 v128, 0
	v_mov_b32_e32 v132, 0
	v_mov_b32_e32 v134, 0
	v_mov_b32_e32 v137, 0
	v_mov_b32_e32 v139, 0
	v_mov_b32_e32 v141, 0
	v_mov_b32_e32 v143, 0
	v_mov_b32_e32 v144, 0
	v_mov_b32_e32 v145, 0
	v_mov_b32_e32 v146, 0
	v_mov_b32_e32 v147, 0
	v_mov_b32_e32 v148, 0
	v_mov_b32_e32 v150, 0
	s_cbranch_vccnz .LBB19_12
; %bb.11:
	; sched_barrier mask(0x00000000)
	s_getpc_b64 s[0:1]
	s_add_u32 s0, s0, .Lnetra_dense_constant_1@rel32@lo+4
	s_addc_u32 s1, s1, .Lnetra_dense_constant_1@rel32@hi+12
	s_load_dword s0, s[0:1], 0x0
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v130, s0
	s_nop 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[162:165], v[74:81], v[10:17], 0, v130, v130 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[74:81], v[2:9], 0, v130, v130 op_sel_hi:[0,0,0]
	v_mul_f32_e32 v142, v160, v161
	v_mul_f32_e32 v150, v158, v161
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[18:25], v[2:9], 0, v130, v130 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[58:65], v[10:17], 0, v130, v130 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v84, v142, v86, 0
	v_fma_f32 v85, v142, v87, 0
	v_fma_f32 v87, v142, v88, 0
	v_fma_f32 v89, v142, v89, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[58:65], v[2:9], 0, v130, v130 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v86, v150, v58, 0
	v_fma_f32 v88, v150, v59, 0
	v_fma_f32 v90, v150, v60, 0
	v_fma_f32 v92, v150, v61, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[66:73], v[10:17], 0, v130, v130 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v91, v142, v58, 0
	v_fma_f32 v93, v142, v59, 0
	v_fma_f32 v94, v142, v60, 0
	v_fma_f32 v96, v142, v61, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[66:73], v[2:9], 0, v130, v130 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v95, v150, v58, 0
	v_fma_f32 v97, v150, v59, 0
	v_fma_f32 v99, v150, v60, 0
	v_fma_f32 v101, v150, v61, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[50:57], v[10:17], 0, v130, v130 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v98, v142, v58, 0
	v_fma_f32 v100, v142, v59, 0
	v_fma_f32 v102, v142, v60, 0
	v_fma_f32 v103, v142, v61, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[50:57], v[2:9], 0, v130, v130 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v104, v150, v50, 0
	v_fma_f32 v105, v150, v51, 0
	v_fma_f32 v108, v150, v52, 0
	v_fma_f32 v109, v150, v53, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[42:49], v[10:17], 0, v130, v130 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v106, v142, v50, 0
	v_fma_f32 v107, v142, v51, 0
	v_fma_f32 v110, v142, v52, 0
	v_fma_f32 v111, v142, v53, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[42:49], v[2:9], 0, v130, v130 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v112, v150, v42, 0
	v_fma_f32 v114, v150, v43, 0
	v_fma_f32 v116, v150, v44, 0
	v_fma_f32 v118, v150, v45, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[34:41], v[10:17], 0, v130, v130 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v113, v142, v42, 0
	v_fma_f32 v115, v142, v43, 0
	v_fma_f32 v117, v142, v44, 0
	v_fma_f32 v119, v142, v45, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[34:41], v[2:9], 0, v130, v130 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v121, v150, v34, 0
	v_fma_f32 v123, v150, v35, 0
	v_fma_f32 v125, v150, v36, 0
	v_fma_f32 v128, v150, v37, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[26:33], v[10:17], 0, v130, v130 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v120, v142, v34, 0
	v_fma_f32 v122, v142, v35, 0
	v_fma_f32 v124, v142, v36, 0
	v_fma_f32 v126, v142, v37, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[26:33], v[2:9], 0, v130, v130 op_sel_hi:[0,0,0]
	;;#ASMSTART
	s_nop 0
	;;#ASMEND
	s_nop 11
	v_fma_f32 v132, v150, v2, 0
	v_fma_f32 v134, v150, v3, 0
	v_fma_f32 v137, v150, v4, 0
	v_fma_f32 v139, v150, v5, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[18:25], v[10:17], 0, v130, v130 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v130, v142, v2, 0
	v_fma_f32 v131, v142, v3, 0
	v_fma_f32 v133, v142, v4, 0
	v_fma_f32 v135, v142, v5, 0
	v_fma_f32 v141, v150, v78, 0
	v_fma_f32 v143, v150, v79, 0
	v_fma_f32 v144, v150, v80, 0
	v_fma_f32 v145, v150, v81, 0
	v_fma_f32 v136, v142, v162, 0
	v_fma_f32 v138, v142, v163, 0
	v_fma_f32 v140, v142, v164, 0
	v_fma_f32 v142, v142, v165, 0
	v_fma_f32 v146, v150, v74, 0
	v_fma_f32 v147, v150, v75, 0
	v_fma_f32 v148, v150, v76, 0
	v_fma_f32 v150, v150, v77, 0
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	s_waitcnt lgkmcnt(4)
	; sched_group_barrier mask(0x00000004) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(12) SyncID(0)
	; sched_barrier mask(0x00000000)
.LBB19_12:                              ; %_ZZN7ck_tile30move_tensor_adaptor_coordinateILb1ENS_17tensor_descriptorINS_5tupleIJNS_5embedINS2_IJiiEEES4_Lb0EEENS_12pass_throughIiEES7_NS_7unmergeINS2_IJiNS_8constantILi4EEEEEELb0EEENS8_INS2_IJiNS9_ILi1EEENS9_ILi8EEENS9_ILi16EEEEEELb0EEES7_NS_5xor_tINS2_IJSA_SE_EEELb1EEES7_NS6_ISD_EENS6_ISF_EENS_21merge_v3_division_modISB_EENSN_ISG_EEEEENS2_IJNS_8sequenceIJLi0EEEENSR_IJLi1EEEENSR_IJLi2EEEENSR_IJLi3EEEENSR_IJLi4EEEENSR_IJLi5EEEENSR_IJLi6ELi9EEEENSR_IJLi7EEEENSR_IJLi8EEEENSR_IJLi10EEEENSR_IJLi11ELi12EEEENSR_IJLi14ELi15ELi13ELi16EEEEEEENS2_IJNSR_IJLi1ELi2EEEESV_SW_NSR_IJLi5ELi6EEEENSR_IJLi7ELi8ELi9ELi10EEEENSR_IJLi11EEEENSR_IJLi12ELi13EEEENSR_IJLi14EEEENSR_IJLi15EEEENSR_IJLi16EEEENSR_IJLi17EEEENSR_IJLi18EEEEEEENSR_IJLi17ELi18EEEEiNSR_IJLin1ELin1ELi16ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEENSR_IJLin1ELin1ELi1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEEEENS_17tensor_coordinateILi19ES1G_EENS_5arrayIiLi2EEENS1M_IiLi1EEEEEvRKT0_R336
	s_add_i32 s48, s42, 0x7f
	v_add_u32_e32 v166, 0x80, v154
	v_lshrrev_b32_e32 v164, 7, v166
	v_add_u32_e32 v2, s43, v164
	v_lshl_add_u32 v160, v2, 7, v153
	v_add_u32_e32 v165, 0x800, v168
	v_add_u32_e32 v158, s29, v152
	s_waitcnt vmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s0, s44, s45
	s_mov_b32 m0, s0
	s_nop 0
	buffer_load_dwordx4 v160, s[20:23], 0 offen lds
	s_add_i32 s1, s0, 0x400
	s_mov_b32 m0, s1
	s_nop 0
	buffer_load_dwordx4 v160, s[20:23], s14 offen lds
	v_lshlrev_b32_e32 v2, 2, v158
	buffer_load_dword v161, v2, s[8:11], 0 offen
	buffer_load_dword v162, v2, s[8:11], 0 offen offset:256
	v_mov_b32_e32 v2, s49
	buffer_load_dword v163, v2, s[24:27], 0 offen offset:4
	s_add_i32 s43, s44, s46
	s_add_i32 s18, s43, 0x4010
	s_mov_b32 m0, s18
	s_nop 0
	buffer_load_dwordx4 v165, s[4:7], 0 offen lds
	s_add_i32 s19, s43, 0x4410
	s_mov_b32 m0, s19
	s_nop 0
	buffer_load_dwordx4 v165, s[4:7], s36 offen lds
	s_add_i32 s42, s43, 0x4810
	s_mov_b32 m0, s42
	s_nop 0
	buffer_load_dwordx4 v165, s[4:7], s37 offen lds
	s_addk_i32 s43, 0x4c10
	s_mov_b32 m0, s43
	s_nop 0
	buffer_load_dwordx4 v165, s[4:7], s38 offen lds
	s_mov_b32 s44, 0
	v_add_u32_e32 v153, s47, v169
	ds_read_b128 v[2:5], v153
	ds_read_b128 v[6:9], v153 offset:64
	ds_read_b128 v[10:13], v153 offset:1024
	ds_read_b128 v[14:17], v153 offset:1088
	v_add_u32_e32 v152, s47, v167
	s_waitcnt lgkmcnt(14)
	ds_read_b128 v[66:69], v152 offset:16400
	s_waitcnt lgkmcnt(8)
	ds_read_b128 v[26:29], v152 offset:17424
	ds_read_b128 v[70:73], v152 offset:20496
	s_waitcnt lgkmcnt(8)
	ds_read_b128 v[30:33], v152 offset:21520
	ds_read_b128 v[58:61], v152 offset:24592
	ds_read_b128 v[34:37], v152 offset:25616
	ds_read_b128 v[62:65], v152 offset:28688
	ds_read_b128 v[38:41], v152 offset:29712
	ds_read_b128 v[42:45], v152 offset:18448
	ds_read_b128 v[18:21], v152 offset:19472
	ds_read_b128 v[46:49], v152 offset:22544
	ds_read_b128 v[22:25], v152 offset:23568
	ds_read_b128 v[50:53], v152 offset:26640
	ds_read_b128 v[74:77], v152 offset:27664
	ds_read_b128 v[54:57], v152 offset:30736
	s_waitcnt lgkmcnt(14)
	ds_read_b128 v[78:81], v152 offset:31760
	s_mov_b32 s45, 4
	s_waitcnt vmcnt(7)
	s_cmpk_lt_i32 s48, 0x280
	s_barrier
	s_cbranch_scc1 .LBB19_16
; %bb.13:                               ; %_ZZN7ck_tile30move_tensor_adaptor_coordinateILb1ENS_17tensor_descriptorINS_5tupleIJNS_5embedINS2_IJiiEEES4_Lb0EEENS_12pass_throughIiEES7_NS_7unmergeINS2_IJiNS_8constantILi4EEEEEELb0EEENS8_INS2_IJiNS9_ILi1EEENS9_ILi8EEENS9_ILi16EEEEEELb0EEES7_NS_5xor_tINS2_IJSA_SE_EEELb1EEES7_NS6_ISD_EENS6_ISF_EENS_21merge_v3_division_modISB_EENSN_ISG_EEEEENS2_IJNS_8sequenceIJLi0EEEENSR_IJLi1EEEENSR_IJLi2EEEENSR_IJLi3EEEENSR_IJLi4EEEENSR_IJLi5EEEENSR_IJLi6ELi9EEEENSR_IJLi7EEEENSR_IJLi8EEEENSR_IJLi10EEEENSR_IJLi11ELi12EEEENSR_IJLi14ELi15ELi13ELi16EEEEEEENS2_IJNSR_IJLi1ELi2EEEESV_SW_NSR_IJLi5ELi6EEEENSR_IJLi7ELi8ELi9ELi10EEEENSR_IJLi11EEEENSR_IJLi12ELi13EEEENSR_IJLi14EEEENSR_IJLi15EEEENSR_IJLi16EEEENSR_IJLi17EEEENSR_IJLi18EEEEEEENSR_IJLi17ELi18EEEEiNSR_IJLin1ELin1ELi16ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEENSR_IJLin1ELin1ELi1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEEEENS_17tensor_coordinateILi19ES1G_EENS_5arrayIiLi2EEENS1M_IiLi1EEEEEvRKT014639
	s_ashr_i32 s46, s48, 31
	s_lshr_b32 s46, s46, 25
	s_add_i32 s48, s48, s46
	s_ashr_i32 s46, s48, 7
	s_getpc_b64 s[50:51]
	s_add_u32 s50, s50, .Lnetra_dense_constant_1@rel32@lo+4
	s_addc_u32 s51, s51, .Lnetra_dense_constant_1@rel32@hi+12
	s_load_dword s50, s[50:51], 0x0
	v_add_u32_e32 v165, 0x180, v154
	v_lshrrev_b32_e32 v166, 7, v165
	v_and_b32_e32 v167, 0xffffff80, v165
	s_mul_i32 s47, s29, 12
	s_lshl_b32 s48, s29, 3
	s_add_i32 s52, s49, 8
	v_add_u32_e32 v168, 0x1000, v168
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v169, s50
	s_add_i32 s49, s29, s29
	s_mov_b32 s50, s48
.LBB19_14:                              ; %_ZZN7ck_tile30move_tensor_adaptor_coordinateILb1ENS_17tensor_descriptorINS_5tupleIJNS_5embedINS2_IJiiEEES4_Lb0EEENS_12pass_throughIiEES7_NS_7unmergeINS2_IJiNS_8constantILi4EEEEEELb0EEENS8_INS2_IJiNS9_ILi1EEENS9_ILi8EEENS9_ILi16EEEEEELb0EEES7_NS_5xor_tINS2_IJSA_SE_EEELb1EEES7_NS6_ISD_EENS6_ISF_EENS_21merge_v3_division_modISB_EENSN_ISG_EEEEENS2_IJNS_8sequenceIJLi0EEEENSR_IJLi1EEEENSR_IJLi2EEEENSR_IJLi3EEEENSR_IJLi4EEEENSR_IJLi5EEEENSR_IJLi6ELi9EEEENSR_IJLi7EEEENSR_IJLi8EEEENSR_IJLi10EEEENSR_IJLi11ELi12EEEENSR_IJLi14ELi15ELi13ELi16EEEEEEENS2_IJNSR_IJLi1ELi2EEEESV_SW_NSR_IJLi5ELi6EEEENSR_IJLi7ELi8ELi9ELi10EEEENSR_IJLi11EEEENSR_IJLi12ELi13EEEENSR_IJLi14EEEENSR_IJLi15EEEENSR_IJLi16EEEENSR_IJLi17EEEENSR_IJLi18EEEEEEENSR_IJLi17ELi18EEEEiNSR_IJLin1ELin1ELi16ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEENSR_IJLin1ELin1ELi1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEEEENS_17tensor_coordinateILi19ES1G_EENS_5arrayIiLi2EEENS1M_IiLi1EEEEEvRKT0_R603
                                        ; =>This Inner Loop Header: Depth=1
	s_mov_b32 s51, s52
	;;#ASMSTART
	;; HotLoop Start ;;
	;;#ASMEND
	; sched_barrier mask(0x00000000)
	s_setprio 1
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(13)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[178:181], v[66:73], v[2:9], 0, v169, v169 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[174:177], v[66:73], v[10:17], 0, v169, v169 op_sel_hi:[0,0,0]
	v_mul_f32_e32 v165, v155, v157
	v_mul_f32_e32 v155, v156, v157
	s_waitcnt lgkmcnt(9)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[170:173], v[58:65], v[2:9], 0, v169, v169 op_sel_hi:[0,0,0]
	;;#ASMSTART
	s_nop 0
	;;#ASMEND
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[58:65], v[10:17], 0, v169, v169 op_sel_hi:[0,0,0]
	s_nop 4
	v_fmac_f32_e32 v84, v165, v178
	v_fmac_f32_e32 v85, v165, v179
	v_fmac_f32_e32 v87, v165, v180
	v_fmac_f32_e32 v89, v165, v181
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[26:33], v[2:9], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v86, v155, v174
	v_fmac_f32_e32 v88, v155, v175
	v_fmac_f32_e32 v90, v155, v176
	v_fmac_f32_e32 v92, v155, v177
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[26:33], v[10:17], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v91, v165, v170
	v_fmac_f32_e32 v93, v165, v171
	v_fmac_f32_e32 v94, v165, v172
	v_fmac_f32_e32 v96, v165, v173
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[34:41], v[2:9], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v95, v155, v70
	v_fmac_f32_e32 v97, v155, v71
	v_fmac_f32_e32 v99, v155, v72
	v_fmac_f32_e32 v101, v155, v73
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[34:41], v[10:17], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v98, v165, v66
	v_fmac_f32_e32 v100, v165, v67
	v_fmac_f32_e32 v102, v165, v68
	v_fmac_f32_e32 v103, v165, v69
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[42:49], v[2:9], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v104, v155, v62
	v_fmac_f32_e32 v105, v155, v63
	v_fmac_f32_e32 v108, v155, v64
	v_fmac_f32_e32 v109, v155, v65
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[42:49], v[10:17], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v106, v165, v58
	v_fmac_f32_e32 v107, v165, v59
	v_fmac_f32_e32 v110, v165, v60
	v_fmac_f32_e32 v111, v165, v61
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[50:57], v[2:9], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v112, v155, v30
	v_fmac_f32_e32 v114, v155, v31
	v_fmac_f32_e32 v116, v155, v32
	v_fmac_f32_e32 v118, v155, v33
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[50:57], v[10:17], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v113, v165, v26
	v_fmac_f32_e32 v115, v165, v27
	v_fmac_f32_e32 v117, v165, v28
	v_fmac_f32_e32 v119, v165, v29
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[18:25], v[2:9], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v121, v155, v38
	v_fmac_f32_e32 v123, v155, v39
	v_fmac_f32_e32 v125, v155, v40
	v_fmac_f32_e32 v128, v155, v41
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[18:25], v[10:17], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v120, v165, v34
	v_fmac_f32_e32 v122, v165, v35
	v_fmac_f32_e32 v124, v165, v36
	v_fmac_f32_e32 v126, v165, v37
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[74:81], v[2:9], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v132, v155, v30
	v_fmac_f32_e32 v134, v155, v31
	v_fmac_f32_e32 v137, v155, v32
	v_fmac_f32_e32 v139, v155, v33
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[74:81], v[10:17], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v130, v165, v26
	v_fmac_f32_e32 v131, v165, v27
	v_fmac_f32_e32 v133, v165, v28
	v_fmac_f32_e32 v135, v165, v29
	v_fmac_f32_e32 v141, v155, v18
	v_fmac_f32_e32 v143, v155, v19
	v_fmac_f32_e32 v144, v155, v20
	v_fmac_f32_e32 v145, v155, v21
	v_fmac_f32_e32 v136, v165, v6
	v_fmac_f32_e32 v138, v165, v7
	v_fmac_f32_e32 v140, v165, v8
	v_fmac_f32_e32 v142, v165, v9
	v_fmac_f32_e32 v146, v155, v2
	v_fmac_f32_e32 v147, v155, v3
	v_fmac_f32_e32 v148, v155, v4
	v_fmac_f32_e32 v150, v155, v5
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000004) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(12) SyncID(0)
	; sched_barrier mask(0x00000000)
	v_lshlrev_b32_e32 v165, 7, v164
	v_add_u32_e32 v2, s44, v154
	v_sub_u32_e32 v2, v2, v165
	v_add_u32_e32 v2, 0x100, v2
	v_and_b32_e32 v2, 0xffffff80, v2
	v_add_u32_e32 v2, v2, v160
	s_waitcnt vmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_mov_b32 m0, s15
	s_nop 0
	buffer_load_dwordx4 v2, s[20:23], 0 offen lds
	s_mov_b32 m0, s40
	s_nop 0
	buffer_load_dwordx4 v2, s[20:23], s14 offen lds
	s_setprio 0
	s_mov_b32 m0, s41
	v_add_u32_e32 v2, s50, v159
	buffer_load_dword v155, v2, s[8:11], 0 offen
	buffer_load_dword v156, v2, s[8:11], 0 offen offset:256
	v_mov_b32_e32 v174, s52
	buffer_load_dword v157, v174, s[24:27], 0 offen
	ds_read_b128 v[18:21], v129
	ds_read_b128 v[22:25], v129 offset:64
	ds_read_b128 v[10:13], v129 offset:1024
	ds_read_b128 v[14:17], v129 offset:1088
	buffer_load_dwordx4 v168, s[4:7], 0 offen lds
	s_mov_b32 m0, s30
	s_nop 0
	buffer_load_dwordx4 v168, s[4:7], s36 offen lds
	s_mov_b32 m0, s31
	s_nop 0
	buffer_load_dwordx4 v168, s[4:7], s37 offen lds
	s_mov_b32 m0, s39
	s_nop 0
	buffer_load_dwordx4 v168, s[4:7], s38 offen lds
	ds_read_b128 v[74:77], v127 offset:16400
	ds_read_b128 v[58:61], v127 offset:17424
	ds_read_b128 v[78:81], v127 offset:20496
	ds_read_b128 v[62:65], v127 offset:21520
	ds_read_b128 v[66:69], v127 offset:24592
	ds_read_b128 v[50:53], v127 offset:25616
	ds_read_b128 v[70:73], v127 offset:28688
	ds_read_b128 v[54:57], v127 offset:29712
	ds_read_b128 v[42:45], v127 offset:18448
	ds_read_b128 v[26:29], v127 offset:19472
	ds_read_b128 v[46:49], v127 offset:22544
	ds_read_b128 v[30:33], v127 offset:23568
	ds_read_b128 v[34:37], v127 offset:26640
	ds_read_b128 v[2:5], v127 offset:27664
	ds_read_b128 v[38:41], v127 offset:30736
	ds_read_b128 v[6:9], v127 offset:31760
	; sched_barrier mask(0x00000000)
	s_waitcnt vmcnt(7)
	s_barrier
	; sched_barrier mask(0x00000000)
	; sched_barrier mask(0x00000000)
	s_setprio 1
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(13)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[170:173], v[74:81], v[18:25], 0, v169, v169 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[74:81], v[10:17], 0, v169, v169 op_sel_hi:[0,0,0]
	v_mul_f32_e32 v164, v161, v163
	v_mul_f32_e32 v161, v162, v163
	s_waitcnt lgkmcnt(9)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[66:73], v[18:25], 0, v169, v169 op_sel_hi:[0,0,0]
	;;#ASMSTART
	s_nop 0
	;;#ASMEND
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[66:73], v[10:17], 0, v169, v169 op_sel_hi:[0,0,0]
	s_nop 4
	v_fmac_f32_e32 v84, v164, v170
	v_fmac_f32_e32 v85, v164, v171
	v_fmac_f32_e32 v87, v164, v172
	v_fmac_f32_e32 v89, v164, v173
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[58:65], v[18:25], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v86, v161, v78
	v_fmac_f32_e32 v88, v161, v79
	v_fmac_f32_e32 v90, v161, v80
	v_fmac_f32_e32 v92, v161, v81
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[58:65], v[10:17], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v91, v164, v74
	v_fmac_f32_e32 v93, v164, v75
	v_fmac_f32_e32 v94, v164, v76
	v_fmac_f32_e32 v96, v164, v77
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[50:57], v[18:25], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v95, v161, v70
	v_fmac_f32_e32 v97, v161, v71
	v_fmac_f32_e32 v99, v161, v72
	v_fmac_f32_e32 v101, v161, v73
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[50:57], v[10:17], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v98, v164, v66
	v_fmac_f32_e32 v100, v164, v67
	v_fmac_f32_e32 v102, v164, v68
	v_fmac_f32_e32 v103, v164, v69
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[42:49], v[18:25], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v104, v161, v62
	v_fmac_f32_e32 v105, v161, v63
	v_fmac_f32_e32 v108, v161, v64
	v_fmac_f32_e32 v109, v161, v65
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[42:49], v[10:17], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v106, v164, v58
	v_fmac_f32_e32 v107, v164, v59
	v_fmac_f32_e32 v110, v164, v60
	v_fmac_f32_e32 v111, v164, v61
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[34:41], v[18:25], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v112, v161, v54
	v_fmac_f32_e32 v114, v161, v55
	v_fmac_f32_e32 v116, v161, v56
	v_fmac_f32_e32 v118, v161, v57
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[34:41], v[10:17], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v113, v164, v50
	v_fmac_f32_e32 v115, v164, v51
	v_fmac_f32_e32 v117, v164, v52
	v_fmac_f32_e32 v119, v164, v53
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[26:33], v[18:25], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v121, v161, v46
	v_fmac_f32_e32 v123, v161, v47
	v_fmac_f32_e32 v125, v161, v48
	v_fmac_f32_e32 v128, v161, v49
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[26:33], v[10:17], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v120, v164, v42
	v_fmac_f32_e32 v122, v164, v43
	v_fmac_f32_e32 v124, v164, v44
	v_fmac_f32_e32 v126, v164, v45
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[2:9], v[18:25], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v132, v161, v38
	v_fmac_f32_e32 v134, v161, v39
	v_fmac_f32_e32 v137, v161, v40
	v_fmac_f32_e32 v139, v161, v41
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[2:9], v[10:17], 0, v169, v169 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v130, v164, v34
	v_fmac_f32_e32 v131, v164, v35
	v_fmac_f32_e32 v133, v164, v36
	v_fmac_f32_e32 v135, v164, v37
	v_fmac_f32_e32 v141, v161, v26
	v_fmac_f32_e32 v143, v161, v27
	v_fmac_f32_e32 v144, v161, v28
	v_fmac_f32_e32 v145, v161, v29
	v_fmac_f32_e32 v136, v164, v18
	v_fmac_f32_e32 v138, v164, v19
	v_fmac_f32_e32 v140, v164, v20
	v_fmac_f32_e32 v142, v164, v21
	v_fmac_f32_e32 v146, v161, v2
	v_fmac_f32_e32 v147, v161, v3
	v_fmac_f32_e32 v148, v161, v4
	v_fmac_f32_e32 v150, v161, v5
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000004) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(12) SyncID(0)
	; sched_barrier mask(0x00000000)
	v_add3_u32 v164, v166, s45, -4
	v_sub_u32_e32 v2, v160, v165
	v_add_u32_e32 v170, v167, v2
	v_add_u32_e32 v160, s44, v170
	s_waitcnt vmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_mov_b32 m0, s0
	s_nop 0
	buffer_load_dwordx4 v160, s[20:23], 0 offen lds
	s_mov_b32 m0, s1
	s_nop 0
	buffer_load_dwordx4 v160, s[20:23], s14 offen lds
	s_setprio 0
	s_mov_b32 m0, s18
	v_add_u32_e32 v2, s47, v159
	buffer_load_dword v161, v2, s[8:11], 0 offen
	buffer_load_dword v162, v2, s[8:11], 0 offen offset:256
	v_add_u32_e32 v165, 0x800, v168
	buffer_load_dword v163, v174, s[24:27], 0 offen offset:4
	ds_read_b128 v[2:5], v153
	ds_read_b128 v[6:9], v153 offset:64
	ds_read_b128 v[10:13], v153 offset:1024
	ds_read_b128 v[14:17], v153 offset:1088
	buffer_load_dwordx4 v165, s[4:7], 0 offen lds
	s_mov_b32 m0, s19
	s_nop 0
	buffer_load_dwordx4 v165, s[4:7], s36 offen lds
	s_mov_b32 m0, s42
	s_nop 0
	buffer_load_dwordx4 v165, s[4:7], s37 offen lds
	s_mov_b32 m0, s43
	s_nop 0
	buffer_load_dwordx4 v165, s[4:7], s38 offen lds
	ds_read_b128 v[66:69], v152 offset:16400
	ds_read_b128 v[26:29], v152 offset:17424
	ds_read_b128 v[70:73], v152 offset:20496
	ds_read_b128 v[30:33], v152 offset:21520
	ds_read_b128 v[58:61], v152 offset:24592
	ds_read_b128 v[34:37], v152 offset:25616
	ds_read_b128 v[62:65], v152 offset:28688
	ds_read_b128 v[38:41], v152 offset:29712
	ds_read_b128 v[42:45], v152 offset:18448
	ds_read_b128 v[18:21], v152 offset:19472
	ds_read_b128 v[46:49], v152 offset:22544
	ds_read_b128 v[22:25], v152 offset:23568
	ds_read_b128 v[50:53], v152 offset:26640
	ds_read_b128 v[74:77], v152 offset:27664
	ds_read_b128 v[54:57], v152 offset:30736
	ds_read_b128 v[78:81], v152 offset:31760
	v_add_u32_e32 v158, s49, v158
	; sched_barrier mask(0x00000000)
	s_waitcnt vmcnt(7)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s45, s45, 2
	;;#ASMSTART
	;; HotLoop End ;;
	;;#ASMEND
	s_addk_i32 s44, 0x100
	s_add_i32 s47, s47, s48
	s_add_i32 s50, s50, s48
	s_add_i32 s52, s52, 8
	s_cmp_lt_i32 s45, s46
	v_add_u32_e32 v168, 0x1000, v168
	s_cbranch_scc1 .LBB19_14
; %bb.15:                               ; %Flow4785
	s_add_i32 s46, s51, 4
	v_add_u32_e32 v159, s44, v170
	v_add_u32_e32 v160, 0xffffff00, v159
	v_add3_u32 v164, v166, s45, -6
	v_add_u32_e32 v154, s44, v154
	v_add_u32_e32 v166, 0x80, v154
	s_branch .LBB19_17
.LBB19_16:
	s_add_i32 s46, s49, 4
.LBB19_17:                              ; %_ZZN7ck_tile30move_tensor_adaptor_coordinateILb1ENS_17tensor_descriptorINS_5tupleIJNS_5embedINS2_IJiiEEES4_Lb0EEENS_12pass_throughIiEES7_NS_7unmergeINS2_IJiNS_8constantILi4EEEEEELb0EEENS8_INS2_IJiNS9_ILi1EEENS9_ILi8EEENS9_ILi16EEEEEELb0EEES7_NS_5xor_tINS2_IJSA_SE_EEELb1EEES7_NS6_ISD_EENS6_ISF_EENS_21merge_v3_division_modISB_EENSN_ISG_EEEEENS2_IJNS_8sequenceIJLi0EEEENSR_IJLi1EEEENSR_IJLi2EEEENSR_IJLi3EEEENSR_IJLi4EEEENSR_IJLi5EEEENSR_IJLi6ELi9EEEENSR_IJLi7EEEENSR_IJLi8EEEENSR_IJLi10EEEENSR_IJLi11ELi12EEEENSR_IJLi14ELi15ELi13ELi16EEEEEEENS2_IJNSR_IJLi1ELi2EEEESV_SW_NSR_IJLi5ELi6EEEENSR_IJLi7ELi8ELi9ELi10EEEENSR_IJLi11EEEENSR_IJLi12ELi13EEEENSR_IJLi14EEEENSR_IJLi15EEEENSR_IJLi16EEEENSR_IJLi17EEEENSR_IJLi18EEEEEEENSR_IJLi17ELi18EEEEiNSR_IJLin1ELin1ELi16ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEENSR_IJLin1ELin1ELi1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEEEENS_17tensor_coordinateILi19ES1G_EENS_5arrayIiLi2EEENS1M_IiLi1EEEEEvRKT0_4009
	;;#ASMSTART
	;; Even Tail Start ;;
	;;#ASMEND
	s_barrier
	; sched_barrier mask(0x00000000)
	s_setprio 1
	; sched_barrier mask(0x00000000)
	s_getpc_b64 s[44:45]
	s_add_u32 s44, s44, .Lnetra_dense_constant_1@rel32@lo+4
	s_addc_u32 s45, s45, .Lnetra_dense_constant_1@rel32@hi+12
	s_load_dword s44, s[44:45], 0x0
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v167, s44
	s_nop 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[168:171], v[74:81], v[2:9], 0, v167, v167 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[74:81], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	v_mul_f32_e32 v172, v155, v157
	v_mul_f32_e32 v159, v156, v157
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[18:25], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[154:157], v[66:73], v[2:9], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v84, v172, v154
	v_fmac_f32_e32 v85, v172, v155
	v_fmac_f32_e32 v87, v172, v156
	v_fmac_f32_e32 v89, v172, v157
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[66:73], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v86, v159, v66
	v_fmac_f32_e32 v88, v159, v67
	v_fmac_f32_e32 v90, v159, v68
	v_fmac_f32_e32 v92, v159, v69
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[58:65], v[2:9], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v91, v172, v66
	v_fmac_f32_e32 v93, v172, v67
	v_fmac_f32_e32 v94, v172, v68
	v_fmac_f32_e32 v96, v172, v69
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[58:65], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v95, v159, v58
	v_fmac_f32_e32 v97, v159, v59
	v_fmac_f32_e32 v99, v159, v60
	v_fmac_f32_e32 v101, v159, v61
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[26:33], v[2:9], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v98, v172, v58
	v_fmac_f32_e32 v100, v172, v59
	v_fmac_f32_e32 v102, v172, v60
	v_fmac_f32_e32 v103, v172, v61
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[26:33], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v104, v159, v26
	v_fmac_f32_e32 v105, v159, v27
	v_fmac_f32_e32 v108, v159, v28
	v_fmac_f32_e32 v109, v159, v29
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[34:41], v[2:9], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v106, v172, v26
	v_fmac_f32_e32 v107, v172, v27
	v_fmac_f32_e32 v110, v172, v28
	v_fmac_f32_e32 v111, v172, v29
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[34:41], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v112, v159, v26
	v_fmac_f32_e32 v114, v159, v27
	v_fmac_f32_e32 v116, v159, v28
	v_fmac_f32_e32 v118, v159, v29
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[42:49], v[2:9], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v113, v172, v26
	v_fmac_f32_e32 v115, v172, v27
	v_fmac_f32_e32 v117, v172, v28
	v_fmac_f32_e32 v119, v172, v29
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[42:49], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v121, v159, v26
	v_fmac_f32_e32 v123, v159, v27
	v_fmac_f32_e32 v125, v159, v28
	v_fmac_f32_e32 v128, v159, v29
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[50:57], v[2:9], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v120, v172, v26
	v_fmac_f32_e32 v122, v172, v27
	v_fmac_f32_e32 v124, v172, v28
	v_fmac_f32_e32 v126, v172, v29
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[50:57], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	;;#ASMSTART
	s_nop 0
	;;#ASMEND
	s_nop 11
	v_fmac_f32_e32 v132, v159, v10
	v_fmac_f32_e32 v134, v159, v11
	v_fmac_f32_e32 v137, v159, v12
	v_fmac_f32_e32 v139, v159, v13
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[18:25], v[2:9], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v130, v172, v2
	v_fmac_f32_e32 v131, v172, v3
	v_fmac_f32_e32 v133, v172, v4
	v_fmac_f32_e32 v135, v172, v5
	v_fmac_f32_e32 v141, v159, v78
	v_fmac_f32_e32 v143, v159, v79
	v_fmac_f32_e32 v144, v159, v80
	v_fmac_f32_e32 v145, v159, v81
	v_fmac_f32_e32 v136, v172, v168
	v_fmac_f32_e32 v138, v172, v169
	v_fmac_f32_e32 v140, v172, v170
	v_fmac_f32_e32 v142, v172, v171
	v_fmac_f32_e32 v146, v159, v74
	v_fmac_f32_e32 v147, v159, v75
	v_fmac_f32_e32 v148, v159, v76
	v_fmac_f32_e32 v150, v159, v77
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	s_waitcnt lgkmcnt(4)
	; sched_group_barrier mask(0x00000004) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(12) SyncID(0)
	; sched_barrier mask(0x00000000)
	v_add_u32_e32 v2, 0x80, v166
	v_ashrrev_i32_e32 v3, 31, v2
	v_lshrrev_b32_e32 v3, 25, v3
	v_add_u32_e32 v3, v2, v3
	v_ashrrev_i32_e32 v173, 7, v3
	v_sub_u32_e32 v4, v173, v164
	v_and_b32_e32 v3, 0xff80, v3
	v_sub_u32_e32 v2, v2, v3
	v_mov_b32_e32 v172, 11
	v_lshrrev_b16_sdwa v3, v172, sext(v2) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	v_and_b32_e32 v3, 15, v3
	v_add_u16_e32 v5, v2, v3
	v_mov_b32_e32 v171, 4
	v_ashrrev_i16_sdwa v3, v171, sext(v5) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	v_and_b32_e32 v5, -16, v5
	v_sub_u16_e32 v170, v2, v5
	v_bfe_i32 v2, v170, 0, 8
	v_xor_b32_sdwa v164, v149, sext(v3) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_sub_u32_e32 v3, v164, v151
	v_lshlrev_b32_e32 v3, 4, v3
	v_lshl_add_u32 v4, v4, 7, v160
	v_add3_u32 v160, v4, v2, v3
	s_waitcnt vmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_mov_b32 m0, s15
	s_nop 0
	buffer_load_dwordx4 v160, s[20:23], 0 offen lds
	s_mov_b32 m0, s40
	s_nop 0
	buffer_load_dwordx4 v160, s[20:23], s14 offen lds
	s_setprio 0
	s_mov_b32 m0, s41
	v_add_u32_e32 v159, s29, v158
	v_lshlrev_b32_e32 v2, 2, v159
	buffer_load_dword v169, v2, s[8:11], 0 offen
	buffer_load_dword v151, v2, s[8:11], 0 offen offset:256
	v_add_u32_e32 v2, 0x800, v165
	v_mov_b32_e32 v158, s46
	buffer_load_dword v168, v158, s[24:27], 0 offen offset:4
	ds_read_b128 v[18:21], v129
	ds_read_b128 v[22:25], v129 offset:64
	ds_read_b128 v[10:13], v129 offset:1024
	ds_read_b128 v[14:17], v129 offset:1088
	buffer_load_dwordx4 v2, s[4:7], 0 offen lds
	s_mov_b32 m0, s30
	s_nop 0
	buffer_load_dwordx4 v2, s[4:7], s36 offen lds
	s_mov_b32 m0, s31
	s_nop 0
	buffer_load_dwordx4 v2, s[4:7], s37 offen lds
	s_mov_b32 m0, s39
	s_nop 0
	buffer_load_dwordx4 v2, s[4:7], s38 offen lds
	ds_read_b128 v[74:77], v127 offset:16400
	ds_read_b128 v[58:61], v127 offset:17424
	ds_read_b128 v[78:81], v127 offset:20496
	ds_read_b128 v[62:65], v127 offset:21520
	ds_read_b128 v[66:69], v127 offset:24592
	ds_read_b128 v[50:53], v127 offset:25616
	ds_read_b128 v[70:73], v127 offset:28688
	ds_read_b128 v[54:57], v127 offset:29712
	ds_read_b128 v[42:45], v127 offset:18448
	ds_read_b128 v[26:29], v127 offset:19472
	ds_read_b128 v[46:49], v127 offset:22544
	ds_read_b128 v[30:33], v127 offset:23568
	ds_read_b128 v[34:37], v127 offset:26640
	ds_read_b128 v[2:5], v127 offset:27664
	ds_read_b128 v[38:41], v127 offset:30736
	ds_read_b128 v[6:9], v127 offset:31760
	; sched_barrier mask(0x00000000)
	s_waitcnt vmcnt(7)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_barrier
	;;#ASMSTART
	;; Even Tail End ;;
	;;#ASMEND
	s_barrier
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(13)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[154:157], v[74:81], v[18:25], 0, v167, v167 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[74:81], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	v_mul_f32_e32 v174, v161, v163
	v_mul_f32_e32 v161, v162, v163
	s_waitcnt lgkmcnt(9)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[66:73], v[18:25], 0, v167, v167 op_sel_hi:[0,0,0]
	;;#ASMSTART
	s_nop 0
	;;#ASMEND
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[66:73], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 4
	v_fmac_f32_e32 v84, v174, v154
	v_fmac_f32_e32 v85, v174, v155
	v_fmac_f32_e32 v87, v174, v156
	v_fmac_f32_e32 v89, v174, v157
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[58:65], v[18:25], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v86, v161, v78
	v_fmac_f32_e32 v88, v161, v79
	v_fmac_f32_e32 v90, v161, v80
	v_fmac_f32_e32 v92, v161, v81
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[58:65], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v91, v174, v74
	v_fmac_f32_e32 v93, v174, v75
	v_fmac_f32_e32 v94, v174, v76
	v_fmac_f32_e32 v96, v174, v77
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[50:57], v[18:25], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v95, v161, v70
	v_fmac_f32_e32 v97, v161, v71
	v_fmac_f32_e32 v99, v161, v72
	v_fmac_f32_e32 v101, v161, v73
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[50:57], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v98, v174, v66
	v_fmac_f32_e32 v100, v174, v67
	v_fmac_f32_e32 v102, v174, v68
	v_fmac_f32_e32 v103, v174, v69
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[42:49], v[18:25], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v104, v161, v62
	v_fmac_f32_e32 v105, v161, v63
	v_fmac_f32_e32 v108, v161, v64
	v_fmac_f32_e32 v109, v161, v65
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[42:49], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v106, v174, v58
	v_fmac_f32_e32 v107, v174, v59
	v_fmac_f32_e32 v110, v174, v60
	v_fmac_f32_e32 v111, v174, v61
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[34:41], v[18:25], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v112, v161, v54
	v_fmac_f32_e32 v114, v161, v55
	v_fmac_f32_e32 v116, v161, v56
	v_fmac_f32_e32 v118, v161, v57
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[34:41], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v113, v174, v50
	v_fmac_f32_e32 v115, v174, v51
	v_fmac_f32_e32 v117, v174, v52
	v_fmac_f32_e32 v119, v174, v53
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[26:33], v[18:25], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v121, v161, v46
	v_fmac_f32_e32 v123, v161, v47
	v_fmac_f32_e32 v125, v161, v48
	v_fmac_f32_e32 v128, v161, v49
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[26:33], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v120, v174, v42
	v_fmac_f32_e32 v122, v174, v43
	v_fmac_f32_e32 v124, v174, v44
	v_fmac_f32_e32 v126, v174, v45
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[2:9], v[18:25], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v132, v161, v38
	v_fmac_f32_e32 v134, v161, v39
	v_fmac_f32_e32 v137, v161, v40
	v_fmac_f32_e32 v139, v161, v41
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[2:9], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v130, v174, v34
	v_fmac_f32_e32 v131, v174, v35
	v_fmac_f32_e32 v133, v174, v36
	v_fmac_f32_e32 v135, v174, v37
	v_fmac_f32_e32 v141, v161, v26
	v_fmac_f32_e32 v143, v161, v27
	v_fmac_f32_e32 v144, v161, v28
	v_fmac_f32_e32 v145, v161, v29
	v_fmac_f32_e32 v136, v174, v18
	v_fmac_f32_e32 v138, v174, v19
	v_fmac_f32_e32 v140, v174, v20
	v_fmac_f32_e32 v142, v174, v21
	v_fmac_f32_e32 v146, v161, v2
	v_fmac_f32_e32 v147, v161, v3
	v_fmac_f32_e32 v148, v161, v4
	v_fmac_f32_e32 v150, v161, v5
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000004) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(12) SyncID(0)
	; sched_barrier mask(0x00000000)
	v_add_u32_e32 v2, 0x100, v166
	v_ashrrev_i32_e32 v3, 31, v2
	v_lshrrev_b32_e32 v3, 25, v3
	v_add_u32_e32 v4, v2, v3
	v_lshrrev_b32_e32 v3, 7, v4
	v_sub_u32_e32 v3, v3, v173
	v_and_b32_e32 v4, 0xff80, v4
	v_sub_u32_e32 v4, v2, v4
	v_lshrrev_b16_sdwa v2, v172, sext(v4) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	v_and_b32_e32 v2, 15, v2
	v_add_u16_e32 v5, v4, v2
	v_ashrrev_i16_sdwa v2, v171, sext(v5) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	v_and_b32_e32 v5, 0xf0, v5
	v_sub_u16_e32 v4, v4, v5
	v_sub_u16_e32 v4, v4, v170
	v_bfe_i32 v4, v4, 0, 8
	v_xor_b32_sdwa v2, v149, sext(v2) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_sub_u32_e32 v2, v2, v164
	v_lshlrev_b32_e32 v2, 4, v2
	v_lshl_add_u32 v3, v3, 7, v4
	v_add3_u32 v2, v3, v2, v160
	v_add_u32_e32 v5, 0x1000, v165
	s_waitcnt vmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_mov_b32 m0, s0
	s_nop 0
	buffer_load_dwordx4 v2, s[20:23], 0 offen lds
	s_mov_b32 m0, s1
	s_nop 0
	buffer_load_dwordx4 v2, s[20:23], s14 offen lds
	v_add_lshl_u32 v6, v159, s29, 2
	buffer_load_dword v2, v6, s[8:11], 0 offen
	buffer_load_dword v3, v6, s[8:11], 0 offen offset:256
	buffer_load_dword v4, v158, s[24:27], 0 offen offset:8
                                        ; kill: killed $sgpr8_sgpr9_sgpr10 killed $sgpr11
                                        ; kill: killed $vgpr6
                                        ; kill: killed $sgpr24_sgpr25_sgpr26 killed $sgpr27
                                        ; kill: killed $vgpr158
	s_mov_b32 m0, s18
	s_nop 0
	buffer_load_dwordx4 v5, s[4:7], 0 offen lds
	s_mov_b32 m0, s19
	s_nop 0
	buffer_load_dwordx4 v5, s[4:7], s36 offen lds
	s_mov_b32 m0, s42
	s_nop 0
	buffer_load_dwordx4 v5, s[4:7], s37 offen lds
	s_mov_b32 m0, s43
	s_nop 0
	buffer_load_dwordx4 v5, s[4:7], s38 offen lds
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[22:25], v153
	ds_read_b128 v[26:29], v153 offset:64
	ds_read_b128 v[14:17], v153 offset:1024
	ds_read_b128 v[18:21], v153 offset:1088
	ds_read_b128 v[154:157], v152 offset:16400
	ds_read_b128 v[62:65], v152 offset:17424
	ds_read_b128 v[158:161], v152 offset:20496
	ds_read_b128 v[66:69], v152 offset:21520
	ds_read_b128 v[70:73], v152 offset:24592
	ds_read_b128 v[54:57], v152 offset:25616
	ds_read_b128 v[74:77], v152 offset:28688
	ds_read_b128 v[58:61], v152 offset:29712
	ds_read_b128 v[46:49], v152 offset:18448
	ds_read_b128 v[30:33], v152 offset:19472
	ds_read_b128 v[50:53], v152 offset:22544
	ds_read_b128 v[34:37], v152 offset:23568
	ds_read_b128 v[38:41], v152 offset:26640
	ds_read_b128 v[6:9], v152 offset:27664
	ds_read_b128 v[42:45], v152 offset:30736
	ds_read_b128 v[10:13], v152 offset:31760
	s_waitcnt vmcnt(7)
	s_barrier
	; sched_barrier mask(0x00000000)
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(13)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[162:165], v[154:161], v[22:29], 0, v167, v167 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[152:155], v[154:161], v[14:21], 0, v167, v167 op_sel_hi:[0,0,0]
	v_mul_f32_e32 v149, v169, v168
	v_mul_f32_e32 v5, v151, v168
	s_waitcnt lgkmcnt(9)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[70:77], v[22:29], 0, v167, v167 op_sel_hi:[0,0,0]
	;;#ASMSTART
	s_nop 0
	;;#ASMEND
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[70:77], v[14:21], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 4
	v_fmac_f32_e32 v84, v149, v162
	v_fmac_f32_e32 v85, v149, v163
	v_fmac_f32_e32 v87, v149, v164
	v_fmac_f32_e32 v89, v149, v165
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[62:69], v[22:29], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v86, v5, v152
	v_fmac_f32_e32 v88, v5, v153
	v_fmac_f32_e32 v90, v5, v154
	v_fmac_f32_e32 v92, v5, v155
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[62:69], v[14:21], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v91, v149, v78
	v_fmac_f32_e32 v93, v149, v79
	v_fmac_f32_e32 v94, v149, v80
	v_fmac_f32_e32 v96, v149, v81
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[54:61], v[22:29], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v95, v5, v74
	v_fmac_f32_e32 v97, v5, v75
	v_fmac_f32_e32 v99, v5, v76
	v_fmac_f32_e32 v101, v5, v77
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[54:61], v[14:21], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v98, v149, v70
	v_fmac_f32_e32 v100, v149, v71
	v_fmac_f32_e32 v102, v149, v72
	v_fmac_f32_e32 v103, v149, v73
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[46:53], v[22:29], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v104, v5, v66
	v_fmac_f32_e32 v105, v5, v67
	v_fmac_f32_e32 v108, v5, v68
	v_fmac_f32_e32 v109, v5, v69
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[46:53], v[14:21], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v106, v149, v62
	v_fmac_f32_e32 v107, v149, v63
	v_fmac_f32_e32 v110, v149, v64
	v_fmac_f32_e32 v111, v149, v65
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[38:45], v[22:29], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v112, v5, v58
	v_fmac_f32_e32 v114, v5, v59
	v_fmac_f32_e32 v116, v5, v60
	v_fmac_f32_e32 v118, v5, v61
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[38:45], v[14:21], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v113, v149, v54
	v_fmac_f32_e32 v115, v149, v55
	v_fmac_f32_e32 v117, v149, v56
	v_fmac_f32_e32 v119, v149, v57
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[30:37], v[22:29], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v121, v5, v50
	v_fmac_f32_e32 v123, v5, v51
	v_fmac_f32_e32 v125, v5, v52
	v_fmac_f32_e32 v128, v5, v53
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[30:37], v[14:21], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v120, v149, v46
	v_fmac_f32_e32 v122, v149, v47
	v_fmac_f32_e32 v124, v149, v48
	v_fmac_f32_e32 v126, v149, v49
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[6:13], v[22:29], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v132, v5, v42
	v_fmac_f32_e32 v134, v5, v43
	v_fmac_f32_e32 v137, v5, v44
	v_fmac_f32_e32 v139, v5, v45
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[6:13], v[14:21], 0, v167, v167 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v130, v149, v38
	v_fmac_f32_e32 v131, v149, v39
	v_fmac_f32_e32 v133, v149, v40
	v_fmac_f32_e32 v135, v149, v41
	v_fmac_f32_e32 v141, v5, v30
	v_fmac_f32_e32 v143, v5, v31
	v_fmac_f32_e32 v144, v5, v32
	v_fmac_f32_e32 v145, v5, v33
	v_fmac_f32_e32 v136, v149, v22
	v_fmac_f32_e32 v138, v149, v23
	v_fmac_f32_e32 v140, v149, v24
	v_fmac_f32_e32 v142, v149, v25
	v_fmac_f32_e32 v146, v5, v6
	v_fmac_f32_e32 v147, v5, v7
	v_fmac_f32_e32 v148, v5, v8
	v_fmac_f32_e32 v150, v5, v9
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000004) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(12) SyncID(0)
	; sched_barrier mask(0x00000000)
	s_waitcnt vmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_andn2_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB19_19
; %bb.18:
	ds_read_b128 v[22:25], v129
	ds_read_b128 v[26:29], v129 offset:64
	ds_read_b128 v[14:17], v129 offset:1024
	ds_read_b128 v[18:21], v129 offset:1088
	ds_read_b128 v[152:155], v127 offset:16400
	ds_read_b128 v[62:65], v127 offset:17424
	ds_read_b128 v[156:159], v127 offset:20496
	ds_read_b128 v[66:69], v127 offset:21520
	ds_read_b128 v[70:73], v127 offset:24592
	ds_read_b128 v[54:57], v127 offset:25616
	ds_read_b128 v[74:77], v127 offset:28688
	ds_read_b128 v[58:61], v127 offset:29712
	ds_read_b128 v[46:49], v127 offset:18448
	ds_read_b128 v[30:33], v127 offset:19472
	ds_read_b128 v[50:53], v127 offset:22544
	ds_read_b128 v[34:37], v127 offset:23568
	ds_read_b128 v[38:41], v127 offset:26640
	ds_read_b128 v[6:9], v127 offset:27664
	ds_read_b128 v[42:45], v127 offset:30736
	ds_read_b128 v[10:13], v127 offset:31760
	s_barrier
	; sched_barrier mask(0x00000000)
	; sched_barrier mask(0x00000000)
	v_mov_b32_e32 v149, s44
	s_waitcnt lgkmcnt(13)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[160:163], v[152:159], v[22:29], 0, v149, v149 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[152:155], v[152:159], v[14:21], 0, v149, v149 op_sel_hi:[0,0,0]
	v_mul_f32_e32 v129, v2, v4
	v_mul_f32_e32 v127, v3, v4
	s_waitcnt lgkmcnt(9)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[70:77], v[22:29], 0, v149, v149 op_sel_hi:[0,0,0]
	;;#ASMSTART
	s_nop 0
	;;#ASMEND
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[70:77], v[14:21], 0, v149, v149 op_sel_hi:[0,0,0]
	s_nop 4
	v_fmac_f32_e32 v84, v129, v160
	v_fmac_f32_e32 v85, v129, v161
	v_fmac_f32_e32 v87, v129, v162
	v_fmac_f32_e32 v89, v129, v163
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[62:69], v[22:29], 0, v149, v149 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v86, v127, v152
	v_fmac_f32_e32 v88, v127, v153
	v_fmac_f32_e32 v90, v127, v154
	v_fmac_f32_e32 v92, v127, v155
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[62:69], v[14:21], 0, v149, v149 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v91, v129, v78
	v_fmac_f32_e32 v93, v129, v79
	v_fmac_f32_e32 v94, v129, v80
	v_fmac_f32_e32 v96, v129, v81
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[54:61], v[22:29], 0, v149, v149 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v95, v127, v2
	v_fmac_f32_e32 v97, v127, v3
	v_fmac_f32_e32 v99, v127, v4
	v_fmac_f32_e32 v101, v127, v5
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[54:61], v[14:21], 0, v149, v149 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v98, v129, v70
	v_fmac_f32_e32 v100, v129, v71
	v_fmac_f32_e32 v102, v129, v72
	v_fmac_f32_e32 v103, v129, v73
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[46:53], v[22:29], 0, v149, v149 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v104, v127, v66
	v_fmac_f32_e32 v105, v127, v67
	v_fmac_f32_e32 v108, v127, v68
	v_fmac_f32_e32 v109, v127, v69
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[46:53], v[14:21], 0, v149, v149 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v106, v129, v62
	v_fmac_f32_e32 v107, v129, v63
	v_fmac_f32_e32 v110, v129, v64
	v_fmac_f32_e32 v111, v129, v65
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[38:45], v[22:29], 0, v149, v149 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v112, v127, v2
	v_fmac_f32_e32 v114, v127, v3
	v_fmac_f32_e32 v116, v127, v4
	v_fmac_f32_e32 v118, v127, v5
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[38:45], v[14:21], 0, v149, v149 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v113, v129, v54
	v_fmac_f32_e32 v115, v129, v55
	v_fmac_f32_e32 v117, v129, v56
	v_fmac_f32_e32 v119, v129, v57
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[30:37], v[22:29], 0, v149, v149 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v121, v127, v50
	v_fmac_f32_e32 v123, v127, v51
	v_fmac_f32_e32 v125, v127, v52
	v_fmac_f32_e32 v128, v127, v53
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[30:37], v[14:21], 0, v149, v149 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v120, v129, v46
	v_fmac_f32_e32 v122, v129, v47
	v_fmac_f32_e32 v124, v129, v48
	v_fmac_f32_e32 v126, v129, v49
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[6:13], v[22:29], 0, v149, v149 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v132, v127, v2
	v_fmac_f32_e32 v134, v127, v3
	v_fmac_f32_e32 v137, v127, v4
	v_fmac_f32_e32 v139, v127, v5
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[6:13], v[14:21], 0, v149, v149 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v130, v129, v38
	v_fmac_f32_e32 v131, v129, v39
	v_fmac_f32_e32 v133, v129, v40
	v_fmac_f32_e32 v135, v129, v41
	v_fmac_f32_e32 v141, v127, v30
	v_fmac_f32_e32 v143, v127, v31
	v_fmac_f32_e32 v144, v127, v32
	v_fmac_f32_e32 v145, v127, v33
	v_fmac_f32_e32 v136, v129, v22
	v_fmac_f32_e32 v138, v129, v23
	v_fmac_f32_e32 v140, v129, v24
	v_fmac_f32_e32 v142, v129, v25
	v_fmac_f32_e32 v146, v127, v2
	v_fmac_f32_e32 v147, v127, v3
	v_fmac_f32_e32 v148, v127, v4
	v_fmac_f32_e32 v150, v127, v5
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000004) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(4) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(12) SyncID(0)
	; sched_barrier mask(0x00000000)
.LBB19_19:                              ; %_ZZN7ck_tile15QuantGemmKernelINS_21GemmTile1DPartitionerINS_13TileGemmShapeINS_8sequenceIJLi128ELi256ELi128EEEENS3_IJLi4ELi2ELi1EEEENS3_IJLi16ELi16ELi128EEEELb0ELb0EEEEENS_35ABQuantGemmPipelineAgBgCrEightWavesINS_28GemmQuantPipelineProblemBaseIDB8_fSB_ffS7_NS_19TileGemmQuantTraitsILb1ELb0ELb0ELb0ELb0ELb1ENS_13tensor_layout4gemm8RowMajorENSE_11ColumnMajorESF_LNS_9QuantTypeE4ESG_SG_Lb1ELb1ELb0ELi16EEENS_15QuantGroupShapeINS3_IJLi1ELi1ELi128EEEEEENSJ_INS3_IJLi1ELi128ELi128EEEEEELb1ESB_LNS_21GemmPipelineSchedulerE1ELb1ELNS_10TailNumberE1ELNS_10CastPolicyE1EEENS_36GemmABQuantPipelineAgBgCrAsyncPolicyEEENS_16CShuffleEpilogueINS_23CShuffleEpilogueProblemISB_SB_NS_5tupleIJEEEfDF16bSX_SF_NS_12element_wise11PassThroughELi128ELi256ELi4ELi2ELi16ELi16ELi128ELb1ELi1ELb0ELi1ELi1ELb0EEEvEELSH_4EE7RunGemmEPKSB_S14_PKfS16_PDF16bPvRKNS_19QuantGemmKernelArgsERKNS12_17SplitKBatchOffsetEiiENKUlvE_clEv.exit.i.i.i
	s_lshl_b32 s2, s35, 8
	s_add_i32 s0, s17, -1
	s_ashr_i32 s1, s0, 31
	s_mul_hi_i32 s3, s16, s28
	s_mul_i32 s4, s16, s28
	s_add_u32 s0, s0, s4
	s_addc_u32 s1, s1, s3
	s_add_u32 s0, s0, 1
	s_addc_u32 s1, s1, 0
	v_mov_b64_e32 v[2:3], 0x7fffffff
	v_cmp_lt_i64_e32 vcc, s[0:1], v[2:3]
	s_and_b64 s[4:5], vcc, exec
	s_cselect_b32 s3, s0, 0x7fffffff
	s_cmp_lg_u32 s34, 1
	v_lshrrev_b32_e32 v2, 2, v82
	v_and_b32_e32 v36, 28, v2
	s_waitcnt lgkmcnt(0)
	v_cvt_pk_bf16_f32 v33, v87, v89
	v_cvt_pk_bf16_f32 v32, v84, v85
	v_cvt_pk_bf16_f32 v31, v94, v96
	v_cvt_pk_bf16_f32 v30, v91, v93
	v_cvt_pk_bf16_f32 v29, v102, v103
	v_cvt_pk_bf16_f32 v28, v98, v100
	v_cvt_pk_bf16_f32 v27, v110, v111
	v_cvt_pk_bf16_f32 v26, v106, v107
	v_cvt_pk_bf16_f32 v25, v117, v119
	v_cvt_pk_bf16_f32 v24, v113, v115
	v_cvt_pk_bf16_f32 v23, v124, v126
	v_cvt_pk_bf16_f32 v22, v120, v122
	v_cvt_pk_bf16_f32 v21, v133, v135
	v_cvt_pk_bf16_f32 v20, v130, v131
	v_cvt_pk_bf16_f32 v19, v140, v142
	v_cvt_pk_bf16_f32 v18, v136, v138
	s_mov_b64 s[0:1], -1
	v_cvt_pk_bf16_f32 v3, v90, v92
	v_cvt_pk_bf16_f32 v2, v86, v88
	v_cvt_pk_bf16_f32 v5, v99, v101
	v_cvt_pk_bf16_f32 v4, v95, v97
	v_cvt_pk_bf16_f32 v7, v108, v109
	v_cvt_pk_bf16_f32 v6, v104, v105
	v_cvt_pk_bf16_f32 v9, v116, v118
	v_cvt_pk_bf16_f32 v8, v112, v114
	v_cvt_pk_bf16_f32 v11, v125, v128
	v_cvt_pk_bf16_f32 v10, v121, v123
	v_cvt_pk_bf16_f32 v13, v137, v139
	v_cvt_pk_bf16_f32 v12, v132, v134
	v_cvt_pk_bf16_f32 v15, v144, v145
	v_cvt_pk_bf16_f32 v14, v141, v143
	v_cvt_pk_bf16_f32 v17, v148, v150
	v_cvt_pk_bf16_f32 v16, v146, v147
	v_lshlrev_b32_e32 v35, 3, v82
	v_and_b32_e32 v34, 12, v83
	s_cbranch_scc1 .LBB19_22
; %bb.20:                               ; %Flow
	s_andn2_b64 vcc, exec, s[0:1]
	s_cbranch_vccz .LBB19_23
.LBB19_21:                              ; %_ZNK7ck_tile15QuantGemmKernelINS_21GemmTile1DPartitionerINS_13TileGemmShapeINS_8sequenceIJLi128ELi256ELi128EEEENS3_IJLi4ELi2ELi1EEEENS3_IJLi16ELi16ELi128EEEELb0ELb0EEEEENS_35ABQuantGemmPipelineAgBgCrEightWavesINS_28GemmQuantPipelineProblemBaseIDB8_fSB_ffS7_NS_19TileGemmQuantTraitsILb1ELb0ELb0ELb0ELb0ELb1ENS_13tensor_layout4gemm8RowMajorENSE_11ColumnMajorESF_LNS_9QuantTypeE4ESG_SG_Lb1ELb1ELb0ELi16EEENS_15QuantGroupShapeINS3_IJLi1ELi1ELi128EEEEEENSJ_INS3_IJLi1ELi128ELi128EEEEEELb1ESB_LNS_21GemmPipelineSchedulerE1ELb1ELNS_10TailNumberE1ELNS_10CastPolicyE1EEENS_36GemmABQuantPipelineAgBgCrAsyncPolicyEEENS_16CShuffleEpilogueINS_23CShuffleEpilogueProblemISB_SB_NS_5tupleIJEEEfDF16bSX_SF_NS_12element_wise11PassThroughELi128ELi256ELi4ELi2ELi16ELi16ELi128ELb1ELi1ELb0ELi1ELi1ELb0EEEvEELSH_4EEclERKNS_19QuantGemmKernelArgsE.exit
	s_endpgm
.LBB19_22:
	v_readfirstlane_b32 s0, v0
	s_lshr_b32 s1, s0, 1
	s_and_b32 s1, s1, 0x7fffff80
	v_or_b32_e32 v41, s1, v36
	v_ashrrev_i32_e32 v37, 31, v41
	v_lshrrev_b32_e32 v37, 29, v37
	v_add_u32_e32 v37, v41, v37
	v_lshrrev_b32_e32 v38, 3, v37
	v_and_b32_e32 v37, -8, v37
	v_sub_u32_e32 v42, v41, v37
	s_lshr_b32 s1, s0, 2
	v_and_or_b32 v39, s1, 48, v1
	v_mul_u32_u24_e32 v39, 0x102, v39
	v_add3_u32 v37, v42, v39, v37
	s_barrier
	v_lshlrev_b32_e32 v65, 1, v37
	ds_write_b64 v65, v[32:33]
	v_add_u32_e32 v40, 16, v41
	v_ashrrev_i32_e32 v39, 31, v40
	v_lshrrev_b32_e32 v39, 29, v39
	v_add_u32_e32 v43, v40, v39
	v_ashrrev_i32_e32 v39, 3, v43
	v_sub_u32_e32 v38, v39, v38
	v_and_b32_e32 v43, -8, v43
	v_sub_u32_e32 v40, v40, v43
	v_lshlrev_b32_e32 v38, 3, v38
	v_sub_u32_e32 v42, v40, v42
	v_add3_u32 v38, v42, v37, v38
	v_lshlrev_b32_e32 v64, 1, v38
	ds_write_b64 v64, v[30:31]
	v_add_u32_e32 v42, 32, v41
	v_ashrrev_i32_e32 v37, 31, v42
	v_lshrrev_b32_e32 v37, 29, v37
	v_add_u32_e32 v43, v42, v37
	v_ashrrev_i32_e32 v37, 3, v43
	v_sub_u32_e32 v39, v37, v39
	v_and_b32_e32 v43, -8, v43
	v_sub_u32_e32 v43, v42, v43
	v_sub_u32_e32 v40, v43, v40
	v_lshl_add_u32 v42, v39, 3, v40
	v_lshl_add_u32 v63, v42, 1, v64
	ds_write_b64 v63, v[28:29]
	v_add_u32_e32 v40, 48, v41
	v_ashrrev_i32_e32 v39, 31, v40
	v_lshrrev_b32_e32 v39, 29, v39
	v_add_u32_e32 v44, v40, v39
	v_ashrrev_i32_e32 v39, 3, v44
	v_sub_u32_e32 v37, v39, v37
	v_and_b32_e32 v44, -8, v44
	v_sub_u32_e32 v40, v40, v44
	v_sub_u32_e32 v43, v40, v43
	v_lshl_add_u32 v37, v37, 3, v43
	v_add3_u32 v38, v42, v38, v37
	v_lshl_add_u32 v62, v37, 1, v63
	ds_write_b64 v62, v[26:27]
	v_add_u32_e32 v42, 64, v41
	v_ashrrev_i32_e32 v37, 31, v42
	v_lshrrev_b32_e32 v37, 29, v37
	v_add_u32_e32 v43, v42, v37
	v_ashrrev_i32_e32 v37, 3, v43
	v_sub_u32_e32 v39, v37, v39
	v_and_b32_e32 v43, -8, v43
	v_sub_u32_e32 v43, v42, v43
	v_sub_u32_e32 v40, v43, v40
	v_lshl_add_u32 v39, v39, 3, v40
	v_lshl_add_u32 v61, v39, 1, v62
	ds_write_b64 v61, v[24:25]
	v_add_u32_e32 v42, 0x50, v41
	v_ashrrev_i32_e32 v40, 31, v42
	v_lshrrev_b32_e32 v40, 29, v40
	v_add_u32_e32 v44, v42, v40
	v_ashrrev_i32_e32 v40, 3, v44
	v_sub_u32_e32 v37, v40, v37
	v_and_b32_e32 v44, -8, v44
	v_sub_u32_e32 v42, v42, v44
	v_sub_u32_e32 v43, v42, v43
	v_lshl_add_u32 v37, v37, 3, v43
	v_add3_u32 v39, v39, v38, v37
	v_lshl_add_u32 v60, v37, 1, v61
	ds_write_b64 v60, v[22:23]
	v_add_u32_e32 v37, 0x60, v41
	v_ashrrev_i32_e32 v38, 31, v37
	v_lshrrev_b32_e32 v38, 29, v38
	v_add_u32_e32 v43, v37, v38
	v_ashrrev_i32_e32 v38, 3, v43
	v_sub_u32_e32 v40, v38, v40
	v_and_b32_e32 v43, -8, v43
	v_sub_u32_e32 v37, v37, v43
	v_sub_u32_e32 v42, v37, v42
	v_lshl_add_u32 v40, v40, 3, v42
	v_lshl_add_u32 v59, v40, 1, v60
	ds_write_b64 v59, v[20:21]
	v_add_u32_e32 v41, 0x70, v41
	v_ashrrev_i32_e32 v42, 31, v41
	v_lshrrev_b32_e32 v42, 29, v42
	v_add_u32_e32 v42, v41, v42
	v_lshrrev_b32_e32 v43, 3, v42
	v_sub_u32_e32 v38, v43, v38
	v_and_b32_e32 v42, 0x7ffffff8, v42
	v_sub_u32_e32 v41, v41, v42
	v_sub_u32_e32 v37, v41, v37
	v_lshlrev_b32_e32 v37, 1, v37
	v_lshlrev_b32_e32 v38, 4, v38
	v_add_lshl_u32 v39, v40, v39, 1
	v_add3_u32 v58, v37, v38, v39
	ds_write_b64 v58, v[18:19]
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_and_b32_e32 v54, 0xf8, v35
	s_lshr_b32 s0, s0, 3
	s_and_b32 s0, s0, 0x1ffffff8
	v_add_u32_e32 v37, s0, v34
	s_movk_i32 s0, 0x204
	v_mul_lo_u32 v38, v37, s0
	v_lshl_add_u32 v55, v54, 1, v38
	ds_read_b128 v[50:53], v55
	ds_read_b128 v[46:49], v55 offset:516
	ds_read_b128 v[42:45], v55 offset:1032
	ds_read_b128 v[38:41], v55 offset:1548
	v_add_u32_e32 v37, s33, v37
	v_or_b32_e32 v54, s2, v54
	v_mad_u64_u32 v[56:57], s[0:1], v37, s28, v[54:55]
	s_lshl_b32 s14, s3, 1
	s_mov_b32 s15, 0x20000
	v_lshlrev_b32_e32 v57, 1, v56
	s_waitcnt lgkmcnt(3)
	buffer_atomic_pk_add_bf16 v50, v57, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v51, v57, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v52, v57, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v53, v57, s[12:15], 12 offen
	v_add_u32_e32 v50, s28, v56
	v_lshlrev_b32_e32 v51, 1, v50
	s_waitcnt lgkmcnt(2)
	buffer_atomic_pk_add_bf16 v46, v51, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v47, v51, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v48, v51, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v49, v51, s[12:15], 12 offen
	v_add_u32_e32 v46, s28, v50
	v_lshlrev_b32_e32 v47, 1, v46
	s_waitcnt lgkmcnt(1)
	buffer_atomic_pk_add_bf16 v42, v47, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v43, v47, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v44, v47, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v45, v47, s[12:15], 12 offen
	v_add_lshl_u32 v42, v46, s28, 1
	s_waitcnt lgkmcnt(0)
	buffer_atomic_pk_add_bf16 v38, v42, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v39, v42, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v40, v42, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v41, v42, s[12:15], 12 offen
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b64 v65, v[2:3]
	ds_write_b64 v64, v[4:5]
	ds_write_b64 v63, v[6:7]
	ds_write_b64 v62, v[8:9]
	ds_write_b64 v61, v[10:11]
	ds_write_b64 v60, v[12:13]
	ds_write_b64 v59, v[14:15]
	ds_write_b64 v58, v[16:17]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[50:53], v55
	ds_read_b128 v[46:49], v55 offset:516
	ds_read_b128 v[42:45], v55 offset:1032
	ds_read_b128 v[38:41], v55 offset:1548
	v_add_u32_e32 v37, 64, v37
	v_mad_u64_u32 v[54:55], s[0:1], v37, s28, v[54:55]
	v_lshlrev_b32_e32 v37, 1, v54
	s_waitcnt lgkmcnt(3)
	buffer_atomic_pk_add_bf16 v50, v37, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v51, v37, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v52, v37, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v53, v37, s[12:15], 12 offen
	v_add_u32_e32 v37, s28, v54
	v_lshlrev_b32_e32 v50, 1, v37
	s_waitcnt lgkmcnt(2)
	buffer_atomic_pk_add_bf16 v46, v50, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v47, v50, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v48, v50, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v49, v50, s[12:15], 12 offen
	v_add_u32_e32 v37, s28, v37
	v_lshlrev_b32_e32 v46, 1, v37
	s_waitcnt lgkmcnt(1)
	buffer_atomic_pk_add_bf16 v42, v46, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v43, v46, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v44, v46, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v45, v46, s[12:15], 12 offen
	v_add_lshl_u32 v37, v37, s28, 1
	s_waitcnt lgkmcnt(0)
	buffer_atomic_pk_add_bf16 v38, v37, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v39, v37, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v40, v37, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v41, v37, s[12:15], 12 offen
	s_mov_b64 vcc, exec
	s_cbranch_execnz .LBB19_21
.LBB19_23:
	v_readfirstlane_b32 s0, v0
	s_lshr_b32 s1, s0, 1
	s_and_b32 s1, s1, 0x7fffff80
	v_or_b32_e32 v36, s1, v36
	v_ashrrev_i32_e32 v0, 31, v36
	v_lshrrev_b32_e32 v0, 29, v0
	v_add_u32_e32 v0, v36, v0
	v_lshrrev_b32_e32 v39, 3, v0
	v_and_b32_e32 v0, -8, v0
	v_sub_u32_e32 v38, v36, v0
	s_lshr_b32 s1, s0, 2
	v_and_or_b32 v1, s1, 48, v1
	v_mul_u32_u24_e32 v1, 0x102, v1
	v_add3_u32 v0, v38, v1, v0
	s_barrier
	v_lshlrev_b32_e32 v44, 1, v0
	ds_write_b64 v44, v[32:33]
	v_add_u32_e32 v32, 16, v36
	v_ashrrev_i32_e32 v1, 31, v32
	v_lshrrev_b32_e32 v1, 29, v1
	v_add_u32_e32 v33, v32, v1
	v_ashrrev_i32_e32 v37, 3, v33
	v_sub_u32_e32 v1, v37, v39
	v_and_b32_e32 v33, -8, v33
	v_sub_u32_e32 v33, v32, v33
	v_lshlrev_b32_e32 v1, 3, v1
	v_sub_u32_e32 v32, v33, v38
	v_add3_u32 v1, v32, v0, v1
	v_lshlrev_b32_e32 v43, 1, v1
	ds_write_b64 v43, v[30:31]
	v_add_u32_e32 v31, 32, v36
	v_ashrrev_i32_e32 v0, 31, v31
	v_lshrrev_b32_e32 v0, 29, v0
	v_add_u32_e32 v32, v31, v0
	v_ashrrev_i32_e32 v0, 3, v32
	v_sub_u32_e32 v30, v0, v37
	v_and_b32_e32 v32, -8, v32
	v_sub_u32_e32 v32, v31, v32
	v_sub_u32_e32 v31, v32, v33
	v_lshl_add_u32 v31, v30, 3, v31
	v_lshl_add_u32 v42, v31, 1, v43
	ds_write_b64 v42, v[28:29]
	v_add_u32_e32 v28, 48, v36
	v_ashrrev_i32_e32 v29, 31, v28
	v_lshrrev_b32_e32 v29, 29, v29
	v_add_u32_e32 v29, v28, v29
	v_ashrrev_i32_e32 v30, 3, v29
	v_sub_u32_e32 v0, v30, v0
	v_and_b32_e32 v29, -8, v29
	v_sub_u32_e32 v29, v28, v29
	v_sub_u32_e32 v28, v29, v32
	v_lshl_add_u32 v0, v0, 3, v28
	v_add3_u32 v1, v31, v1, v0
	v_lshl_add_u32 v41, v0, 1, v42
	ds_write_b64 v41, v[26:27]
	v_add_u32_e32 v27, 64, v36
	v_ashrrev_i32_e32 v0, 31, v27
	v_lshrrev_b32_e32 v0, 29, v0
	v_add_u32_e32 v28, v27, v0
	v_ashrrev_i32_e32 v0, 3, v28
	v_sub_u32_e32 v26, v0, v30
	v_and_b32_e32 v28, -8, v28
	v_sub_u32_e32 v28, v27, v28
	v_sub_u32_e32 v27, v28, v29
	v_lshl_add_u32 v27, v26, 3, v27
	v_lshl_add_u32 v40, v27, 1, v41
	ds_write_b64 v40, v[24:25]
	v_add_u32_e32 v24, 0x50, v36
	v_ashrrev_i32_e32 v25, 31, v24
	v_lshrrev_b32_e32 v25, 29, v25
	v_add_u32_e32 v25, v24, v25
	v_ashrrev_i32_e32 v26, 3, v25
	v_sub_u32_e32 v0, v26, v0
	v_and_b32_e32 v25, -8, v25
	v_sub_u32_e32 v25, v24, v25
	v_sub_u32_e32 v24, v25, v28
	v_lshl_add_u32 v0, v0, 3, v24
	v_add3_u32 v24, v27, v1, v0
	v_lshl_add_u32 v39, v0, 1, v40
	ds_write_b64 v39, v[22:23]
	v_add_u32_e32 v0, 0x60, v36
	v_ashrrev_i32_e32 v1, 31, v0
	v_lshrrev_b32_e32 v1, 29, v1
	v_add_u32_e32 v23, v0, v1
	v_ashrrev_i32_e32 v1, 3, v23
	v_sub_u32_e32 v22, v1, v26
	v_and_b32_e32 v23, -8, v23
	v_sub_u32_e32 v0, v0, v23
	v_sub_u32_e32 v23, v0, v25
	v_lshl_add_u32 v22, v22, 3, v23
	v_lshl_add_u32 v38, v22, 1, v39
	ds_write_b64 v38, v[20:21]
	v_add_u32_e32 v20, 0x70, v36
	v_ashrrev_i32_e32 v21, 31, v20
	v_lshrrev_b32_e32 v21, 29, v21
	v_add_u32_e32 v21, v20, v21
	v_lshrrev_b32_e32 v23, 3, v21
	v_sub_u32_e32 v1, v23, v1
	v_and_b32_e32 v21, 0x7ffffff8, v21
	v_sub_u32_e32 v20, v20, v21
	v_sub_u32_e32 v0, v20, v0
	v_lshlrev_b32_e32 v0, 1, v0
	v_lshlrev_b32_e32 v1, 4, v1
	v_add_lshl_u32 v20, v22, v24, 1
	v_add3_u32 v37, v0, v1, v20
	ds_write_b64 v37, v[18:19]
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_and_b32_e32 v0, 0xf8, v35
	s_lshr_b32 s0, s0, 3
	s_and_b32 s0, s0, 0x1ffffff8
	v_add_u32_e32 v1, s0, v34
	s_movk_i32 s0, 0x204
	v_mul_lo_u32 v18, v1, s0
	v_lshl_add_u32 v36, v0, 1, v18
	ds_read_b128 v[30:33], v36
	ds_read_b128 v[26:29], v36 offset:516
	ds_read_b128 v[22:25], v36 offset:1032
	ds_read_b128 v[18:21], v36 offset:1548
	v_add_u32_e32 v35, s33, v1
	v_or_b32_e32 v34, s2, v0
	v_mad_u64_u32 v[0:1], s[0:1], v35, s28, v[34:35]
	s_lshl_b32 s14, s3, 1
	s_mov_b32 s15, 0x20000
	v_lshlrev_b32_e32 v1, 1, v0
	s_waitcnt lgkmcnt(3)
	buffer_store_dwordx2 v[30:31], v1, s[12:15], 0 offen
	buffer_store_dwordx2 v[32:33], v1, s[12:15], 8 offen
	v_add_u32_e32 v0, s28, v0
	v_lshlrev_b32_e32 v1, 1, v0
	s_waitcnt lgkmcnt(2)
	buffer_store_dwordx2 v[26:27], v1, s[12:15], 0 offen
	buffer_store_dwordx2 v[28:29], v1, s[12:15], 8 offen
	v_add_u32_e32 v0, s28, v0
	v_lshlrev_b32_e32 v1, 1, v0
	s_waitcnt lgkmcnt(1)
	buffer_store_dwordx2 v[22:23], v1, s[12:15], 0 offen
	buffer_store_dwordx2 v[24:25], v1, s[12:15], 8 offen
	v_add_lshl_u32 v0, v0, s28, 1
	s_waitcnt lgkmcnt(0)
	buffer_store_dwordx2 v[18:19], v0, s[12:15], 0 offen
	buffer_store_dwordx2 v[20:21], v0, s[12:15], 8 offen
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b64 v44, v[2:3]
	ds_write_b64 v43, v[4:5]
	ds_write_b64 v42, v[6:7]
	ds_write_b64 v41, v[8:9]
	ds_write_b64 v40, v[10:11]
	ds_write_b64 v39, v[12:13]
	ds_write_b64 v38, v[14:15]
	ds_write_b64 v37, v[16:17]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[12:15], v36
	ds_read_b128 v[8:11], v36 offset:516
	ds_read_b128 v[4:7], v36 offset:1032
	ds_read_b128 v[0:3], v36 offset:1548
	v_add_u32_e32 v16, 64, v35
	v_mad_u64_u32 v[16:17], s[0:1], v16, s28, v[34:35]
	v_lshlrev_b32_e32 v17, 1, v16
	s_waitcnt lgkmcnt(3)
	buffer_store_dwordx2 v[12:13], v17, s[12:15], 0 offen
	buffer_store_dwordx2 v[14:15], v17, s[12:15], 8 offen
	v_add_u32_e32 v12, s28, v16
	v_lshlrev_b32_e32 v13, 1, v12
	s_waitcnt lgkmcnt(2)
	buffer_store_dwordx2 v[8:9], v13, s[12:15], 0 offen
	buffer_store_dwordx2 v[10:11], v13, s[12:15], 8 offen
	v_add_u32_e32 v8, s28, v12
	v_lshlrev_b32_e32 v9, 1, v8
	s_waitcnt lgkmcnt(1)
	buffer_store_dwordx2 v[4:5], v9, s[12:15], 0 offen
	buffer_store_dwordx2 v[6:7], v9, s[12:15], 8 offen
	v_add_lshl_u32 v4, v8, s28, 1
	s_waitcnt lgkmcnt(0)
	buffer_store_dwordx2 v[0:1], v4, s[12:15], 0 offen
	buffer_store_dwordx2 v[2:3], v4, s[12:15], 8 offen
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel \symbol
		.amdhsa_group_segment_fixed_size 98336
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 88
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 0
		.amdhsa_user_sgpr_kernarg_preload_length 0
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 182
		.amdhsa_next_free_sgpr 96
		.amdhsa_accum_offset 184
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 0
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
	.section	.text,"axG",@progbits,\symbol,comdat,unique,20
.Lfunc_end19:
	.size	\symbol, .Lfunc_end19-\symbol
                                        ; -- End function
	.set \symbol\().num_vgpr, 182
	.set \symbol\().num_agpr, 0
	.set \symbol\().numbered_sgpr, 57
	.set \symbol\().num_named_barrier, 0
	.set \symbol\().private_seg_size, 0
	.set \symbol\().uses_vcc, 1
	.set \symbol\().uses_flat_scratch, 0
	.set \symbol\().has_dyn_sized_stack, 0
	.set \symbol\().has_recursion, 0
	.set \symbol\().has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 11920
; TotalNumSgprs: 63
; NumVgprs: 182
; NumAgprs: 0
; TotalNumVgprs: 182
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 192
; IeeeMode: 1
; LDSByteSize: 98336 bytes/workgroup (compile time only)
; SGPRBlocks: 12
; VGPRBlocks: 22
; NumSGPRsForWavesPerEU: 102
; NumVGPRsForWavesPerEU: 182
; AccumOffset: 184
; Occupancy: 2
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 45
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.protected	.Lnetra_dense_constant_0 ; @.Lnetra_dense_constant_0
	.type	.Lnetra_dense_constant_0,@object
	.section	.bss,"awG",@nobits,.Lnetra_dense_constant_0,comdat,unique,42
	.weak	.Lnetra_dense_constant_0
	.p2align	2, 0x0
.Lnetra_dense_constant_0:
	.long	0                               ; 0x0
	.size	.Lnetra_dense_constant_0, 4
	.protected	.Lnetra_dense_constant_1 ; @.Lnetra_dense_constant_1
	.type	.Lnetra_dense_constant_1,@object
	.section	.rodata,"aG",@progbits,.Lnetra_dense_constant_1,comdat,unique,43
	.weak	.Lnetra_dense_constant_1
	.p2align	2, 0x0
.Lnetra_dense_constant_1:
	.long	2139062143                      ; 0x7f7f7f7f
	.size	.Lnetra_dense_constant_1, 4
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - .offset:         0
        .size:           88
        .value_kind:     by_value
    .group_segment_fixed_size: 98336
    .kernarg_segment_align: 8
    .kernarg_segment_size: 88
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 512
    .name:           \symbol
    .private_segment_fixed_size: 0
    .sgpr_count:     63
    .sgpr_spill_count: 0
    .symbol:         \symbol\().kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     182
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...
	.end_amdgpu_metadata
	.endm
