// SPDX-License-Identifier: MIT
// Model-independent, fixed-contract gfx950 schedule frozen from profiled machine code.
	.include "kernels/gfx950/templates/common/primitives.inc"
	NETRA_GFX950_MODULE_HEADER 6
	.macro NETRA_DENSE_FP8_BLOCKSCALE_BF16_TILE192X256_K128 symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_M, 1536
	NETRA_REQUIRE_EQ NETRA_K, 5120
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
	s_sub_i32 s33, s22, s1
	s_mul_i32 s22, s33, s20
	v_rcp_iflag_f32_e32 v1, v1
	s_add_i32 s1, s18, s0
	s_add_i32 s1, s1, -1
	s_xor_b32 s0, s1, s0
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	s_ashr_i32 s0, s0, 31
	s_abs_i32 s20, s1
	s_sub_i32 s23, 0, s21
	v_readfirstlane_b32 s1, v1
	s_mul_i32 s23, s23, s1
	s_mul_hi_u32 s23, s1, s23
	s_add_i32 s1, s1, s23
	s_mul_hi_u32 s1, s20, s1
	s_mul_i32 s23, s1, s21
	s_sub_i32 s20, s20, s23
	s_add_i32 s24, s1, 1
	s_sub_i32 s23, s20, s21
	s_cmp_ge_u32 s20, s21
	s_cselect_b32 s1, s24, s1
	s_cselect_b32 s23, s23, s20
	s_add_i32 s20, s1, 1
	s_cmp_ge_u32 s23, s21
	s_cselect_b32 s1, s20, s1
	s_xor_b32 s1, s1, s0
	s_sub_i32 s0, s1, s0
	s_lshl_b32 s23, s0, 7
	s_ashr_i32 s0, s23, 31
	s_mul_i32 s0, s0, s3
	s_mul_hi_u32 s1, s23, s3
	s_add_i32 s1, s1, s0
	s_add_i32 s20, s34, -1
	s_cmp_ge_u32 s3, s20
	s_mul_i32 s0, s23, s3
	s_cbranch_scc0 .LBB19_2
; %bb.1:
	s_mul_i32 s3, s23, s20
	s_sub_i32 s44, s18, s3
	s_mov_b64 vcc, exec
	s_cbranch_execz .LBB19_3
	s_branch .LBB19_4
.LBB19_2:
                                        ; implicit-def: $sgpr44
	s_mov_b64 vcc, 0
.LBB19_3:
	s_mov_b32 s44, s23
.LBB19_4:                               ; %_ZN7ck_tile15QuantGemmKernelINS_21GemmTile1DPartitionerINS_13TileGemmShapeINS_8sequenceIJLi192ELi256ELi128EEEENS3_IJLi4ELi2ELi1EEEENS3_IJLi16ELi16ELi128EEEELb0ELb0EEEEENS_35ABQuantGemmPipelineAgBgCrEightWavesINS_28GemmQuantPipelineProblemBaseIDB8_fSB_ffS7_NS_19TileGemmQuantTraitsILb1ELb0ELb0ELb0ELb0ELb1ENS_13tensor_layout4gemm8RowMajorENSE_11ColumnMajorESF_LNS_9QuantTypeE4ESG_SG_Lb1ELb1ELb0ELi16EEENS_15QuantGroupShapeINS3_IJLi1ELi1ELi128EEEEEENSJ_INS3_IJLi1ELi128ELi128EEEEEELb1ESB_LNS_21GemmPipelineSchedulerE1ELb1ELNS_10TailNumberE1ELNS_10CastPolicyE1EEENS_36GemmABQuantPipelineAgBgCrAsyncPolicyEEENS_16CShuffleEpilogueINS_23CShuffleEpilogueProblemISB_SB_NS_5tupleIJEEEfDF16bSX_SF_NS_12element_wise11PassThroughELi192ELi256ELi4ELi2ELi16ELi16ELi128ELb1ELi1ELb0ELi1ELi1ELb0EEEvEELSH_4EE17SplitKBatchOffsetC2ERKNS_19QuantGemmKernelArgsEm.exit.i.i
	s_mulk_i32 s33, 0xc0
	s_sub_i32 s35, s2, s22
	s_ashr_i32 s2, s0, 31
	s_lshr_b32 s2, s2, 25
	s_add_i32 s2, s0, s2
	s_ashr_i32 s2, s2, 7
	s_bfe_i64 s[0:1], s[0:1], 0x200000
	s_add_u32 s20, s4, s0
	s_addc_u32 s41, s5, s1
	s_add_u32 s4, s6, s0
	s_addc_u32 s40, s7, s1
	s_ashr_i32 s3, s2, 31
	s_lshl_b64 s[0:1], s[2:3], 2
	s_add_u32 s8, s8, s0
	s_addc_u32 s9, s9, s1
	s_add_u32 s24, s10, s0
	s_addc_u32 s25, s11, s1
	s_mov_b32 s45, -1
	s_add_i32 s16, s16, -1
	s_ashr_i32 s3, s16, 31
	s_mul_hi_i32 s1, s16, s15
	s_mul_i32 s0, s16, s15
	s_add_i32 s6, s44, -1
	s_ashr_i32 s5, s6, 31
	s_add_u32 s0, s0, s6
	s_addc_u32 s1, s1, s5
	s_add_u32 s0, s0, 1
	s_addc_u32 s1, s1, 0
	v_mov_b64_e32 v[2:3], 0x7fffffff
	v_cmp_lt_i64_e32 vcc, s[0:1], v[2:3]
	s_and_b64 s[6:7], vcc, exec
	s_cselect_b32 s22, s0, 0x7fffffff
	s_ashr_i32 s0, s44, 31
	s_ashr_i32 s1, s18, 31
	s_lshr_b32 s1, s1, 25
	s_add_i32 s1, s18, s1
	s_ashr_i32 s42, s1, 7
	s_lshl_b32 s21, s42, 11
	s_abs_i32 s7, s21
	v_cvt_f32_u32_e32 v1, s7
	s_lshr_b32 s0, s0, 25
	s_add_i32 s0, s44, s0
	s_lshl_b32 s0, s0, 4
	v_rcp_iflag_f32_e32 v1, v1
	s_and_b32 s6, s0, 0xfffff800
	s_mul_i32 s0, s18, s17
	s_xor_b32 s1, s0, s21
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
	s_add_i32 s11, s0, 1
	s_sub_i32 s10, s5, s7
	s_cmp_ge_u32 s5, s7
	s_cselect_b32 s0, s11, s0
	s_cselect_b32 s10, s10, s5
	s_add_i32 s5, s0, 1
	s_cmp_ge_u32 s10, s7
	s_cselect_b32 s0, s5, s0
	s_xor_b32 s0, s0, s1
	s_not_b32 s1, s1
	s_add_i32 s0, s1, s0
	s_mul_hi_i32 s1, s0, s21
	s_mul_i32 s0, s0, s21
	s_add_i32 s6, s6, -1
	s_ashr_i32 s5, s6, 31
	s_add_u32 s0, s6, s0
	s_addc_u32 s1, s5, s1
	s_add_u32 s0, s0, 1
	s_addc_u32 s1, s1, 0
	v_cmp_lt_i64_e32 vcc, s[0:1], v[2:3]
	s_and_b64 s[6:7], vcc, exec
	s_cselect_b32 s0, s0, 0x7fffffff
	s_lshl_b32 s23, s35, 4
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
	s_cselect_b32 s49, s2, 0x7fffffff
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
	s_cselect_b32 s52, s2, 0x7fffffff
	s_lshl_b32 s11, s35, 1
	v_readfirstlane_b32 s10, v0
	s_lshr_b32 s43, s10, 6
	s_cmpk_gt_u32 s10, 0xff
	s_cselect_b64 s[18:19], -1, 0
	s_cmpk_lt_u32 s10, 0x100
	s_cselect_b64 s[2:3], -1, 0
	s_and_b64 s[6:7], s[2:3], exec
	s_cselect_b32 s46, 0xe010, 0
	v_mbcnt_lo_u32_b32 v1, -1, 0
	v_mbcnt_hi_u32_b32 v90, -1, v1
	v_lshrrev_b32_e32 v91, 3, v90
	v_lshlrev_b32_e32 v4, 4, v90
	v_and_b32_e32 v2, 0x70, v4
	s_lshl_b32 s1, s43, 3
	s_add_i32 s1, s1, s33
	v_add_u32_e32 v1, s1, v91
	v_ashrrev_i32_e32 v3, 31, v1
	v_lshrrev_b32_e32 v3, 30, v3
	v_add_u32_e32 v3, v1, v3
	v_and_b32_e32 v3, -4, v3
	v_sub_u32_e32 v190, v1, v3
	v_bitop3_b32 v191, v190, v90, 7 bitop3:0x78
	v_mul_lo_u32 v1, v1, s15
	v_lshl_add_u32 v3, v191, 4, v1
	v_and_b32_e32 v1, 15, v90
	s_lshr_b32 s1, s10, 8
	s_bfe_u32 s7, s10, 0x10007
	s_lshl_b32 s5, s10, 4
	s_and_b32 s54, s5, 0x400
	s_lshl_b32 s26, s1, 3
	s_lshl_b32 s55, s7, 13
	s_lshr_b32 s51, s10, 9
	s_bfe_u32 s50, s10, 0x10008
	s_lshr_b32 s5, s10, 2
	s_and_b32 s5, s5, 48
	s_mul_i32 s6, s51, s29
	s_add_i32 s23, s26, s23
	s_or_b32 s7, s23, s7
	s_mul_i32 s7, s7, s21
	s_or_b32 s53, s50, s11
	s_mul_i32 s53, s53, s14
	s_or_b32 s7, s7, s54
	v_add_u32_e32 v4, s7, v4
	s_add_i32 s6, s6, s33
	s_add_i32 s5, s6, s5
	v_add_u32_e32 v5, s5, v1
	s_add_i32 s53, s53, s51
	; sched_barrier mask(0x00000000)
	s_bfe_u32 s47, s10, 0x20007
	s_bitcmp1_b32 s10, 6
	s_cselect_b32 s5, 0x3010, 0
	s_mulk_i32 s47, 0xc00
	s_lshl_b32 s6, s10, 1
	s_and_b32 s6, s6, 0xfffffc00
	s_add_i32 s47, s47, s6
	s_add_i32 s47, s47, s5
	s_and_b64 vcc, exec, s[18:19]
	s_mul_i32 s56, s42, 0x3000
	s_cbranch_vccz .LBB19_6
; %bb.5:                                ; %_ZZN7ck_tile30move_tensor_adaptor_coordinateILb1ENS_17tensor_descriptorINS_5tupleIJNS_5embedINS2_IJiiEEES4_Lb0EEENS_12pass_throughIiEES7_NS_7unmergeINS2_IJiNS_8constantILi4EEEEEELb0EEENS8_INS2_IJiNS9_ILi1EEENS9_ILi8EEENS9_ILi16EEEEEELb0EEES7_NS_5xor_tINS2_IJSA_SE_EEELb1EEES7_NS6_ISD_EENS6_ISF_EENS_21merge_v3_division_modISB_EENSN_ISG_EEEEENS2_IJNS_8sequenceIJLi0EEEENSR_IJLi1EEEENSR_IJLi2EEEENSR_IJLi3EEEENSR_IJLi4EEEENSR_IJLi5EEEENSR_IJLi6ELi9EEEENSR_IJLi7EEEENSR_IJLi8EEEENSR_IJLi10EEEENSR_IJLi11ELi12EEEENSR_IJLi14ELi15ELi13ELi16EEEEEEENS2_IJNSR_IJLi1ELi2EEEESV_SW_NSR_IJLi5ELi6EEEENSR_IJLi7ELi8ELi9ELi10EEEENSR_IJLi11EEEENSR_IJLi12ELi13EEEENSR_IJLi14EEEENSR_IJLi15EEEENSR_IJLi16EEEENSR_IJLi17EEEENSR_IJLi18EEEEEEENSR_IJLi17ELi18EEEEiNSR_IJLin1ELin1ELi16ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEENSR_IJLin1ELin1ELi1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEEEENS_17tensor_coordinateILi19ES1G_EENS_5arrayIiLi2EEENS1M_IiLi1EEEEEvRKT0_RT1_
	s_lshl_b32 s1, s1, 14
	s_add_i32 s5, s46, s47
	s_mov_b32 s23, 0x20000
	s_and_b32 s21, s41, 0xffff
	s_mov_b32 m0, s5
	s_nop 0
	buffer_load_dwordx4 v3, s[20:23], 0 offen lds
	s_add_i32 m0, s5, 0x400
	s_lshl_b32 s14, s15, 6
	buffer_load_dwordx4 v3, s[20:23], s14 offen lds
	s_add_i32 m0, s5, 0x800
	s_lshl_b32 s36, s15, 7
	buffer_load_dwordx4 v3, s[20:23], s36 offen lds
	s_lshl_b32 s10, s49, 2
	s_mov_b32 s11, s23
	v_lshlrev_b32_e32 v6, 2, v5
	buffer_load_dword v203, v6, s[8:11], 0 offen
	buffer_load_dword v202, v6, s[8:11], 0 offen offset:256
	buffer_load_dword v199, v6, s[8:11], 0 offen offset:512
	s_lshl_b32 s26, s52, 2
	s_mov_b32 s27, s23
	s_lshl_b32 s5, s53, 2
	v_mov_b32_e32 v6, s5
	buffer_load_dword v200, v6, s[24:27], 0 offen
	s_lshl_b32 s5, s54, 2
	s_or_b32 s1, s5, s1
	s_or_b32 s48, s1, s55
	s_add_i32 s1, s46, s48
	s_add_i32 m0, s1, 0x6010
	s_and_b32 s5, s40, 0xffff
	s_mov_b32 s6, s0
	s_mov_b32 s7, s23
	buffer_load_dwordx4 v4, s[4:7], 0 offen lds
	s_add_i32 m0, s1, 0x6410
	s_lshl_b32 s37, s42, 12
	buffer_load_dwordx4 v4, s[4:7], s37 offen lds
	s_add_i32 m0, s1, 0x6810
	s_lshl_b32 s38, s42, 13
	buffer_load_dwordx4 v4, s[4:7], s38 offen lds
	s_add_i32 m0, s1, 0x6c10
	s_mul_i32 s39, s42, 0x3000
	buffer_load_dwordx4 v4, s[4:7], s39 offen lds
	s_mov_b32 s1, s23
	s_waitcnt vmcnt(8)
	s_barrier
	v_or_b32_e32 v194, 0x80, v2
	v_add_u32_e32 v193, 0x80, v3
	v_add_u32_e32 v210, 0x800, v4
	v_add_u32_e32 v192, s29, v5
	s_add_i32 s57, s53, 1
	s_mov_b64 s[6:7], s[0:1]
	s_mov_b64 vcc, exec
	s_cbranch_execz .LBB19_7
	s_branch .LBB19_8
.LBB19_6:
                                        ; implicit-def: $vgpr194
                                        ; implicit-def: $vgpr193
                                        ; implicit-def: $vgpr192
                                        ; implicit-def: $sgpr57
                                        ; implicit-def: $vgpr210
                                        ; implicit-def: $vgpr200
                                        ; implicit-def: $vgpr203
                                        ; implicit-def: $vgpr202
                                        ; implicit-def: $vgpr199
                                        ; implicit-def: $sgpr14
                                        ; implicit-def: $sgpr36
                                        ; implicit-def: $sgpr48
                                        ; implicit-def: $sgpr37
                                        ; implicit-def: $sgpr38
                                        ; implicit-def: $sgpr39
	s_mov_b64 vcc, 0
.LBB19_7:                               ; %_ZN7ck_tile5arrayIiLi2EEC2ESt16initializer_listIiE.exit113._crit_edge.i.i.i.i.i.i.i.i
	s_mov_b32 s23, 0x20000
	s_and_b32 s21, s41, 0xffff
	s_lshl_b32 s14, s15, 6
	s_lshl_b32 s36, s15, 7
	s_lshl_b32 s10, s49, 2
	s_lshl_b32 s26, s52, 2
	s_lshl_b32 s1, s54, 2
	s_or_b32 s48, s1, s55
	s_mov_b32 s1, s23
	s_and_b32 s5, s40, 0xffff
	s_lshl_b32 s37, s42, 12
	s_lshl_b32 s38, s42, 13
	s_mov_b32 s45, 0
	s_waitcnt vmcnt(5)
	v_mov_b32_e32 v199, 0
	s_waitcnt vmcnt(4)
	v_mov_b32_e32 v200, 0
	s_mov_b32 s39, s56
	s_mov_b64 s[6:7], s[0:1]
	v_mov_b32_e32 v202, 0
	v_mov_b32_e32 v203, 0
	v_mov_b32_e32 v210, v4
	s_mov_b32 s57, s53
	v_mov_b32_e32 v192, v5
	v_mov_b32_e32 v193, v3
	v_mov_b32_e32 v194, v2
.LBB19_8:
	s_and_b64 s[0:1], s[2:3], exec
	s_cselect_b32 s49, 0, 0xe010
	v_and_b32_e32 v2, 0x70, v90
	s_and_b32 s0, s43, 3
	v_lshrrev_b16_e32 v3, 4, v90
	v_bitop3_b16 v5, v3, v90, 3 bitop3:0x78
	v_bfe_i32 v3, v90, 3, 1
	v_and_b32_e32 v3, 0x3010, v3
	s_mulk_i32 s0, 0xc00
	v_lshlrev_b32_e32 v4, 7, v90
	v_and_b32_e32 v6, 0x380, v4
	v_mov_b32_e32 v4, 4
	v_lshlrev_b32_sdwa v5, v4, v5 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_or_b32_e32 v6, s0, v6
	v_add3_u32 v211, v6, v3, v5
	v_lshl_or_b32 v3, s51, 7, v2
	v_ashrrev_i32_e32 v2, 31, v3
	v_lshrrev_b32_e32 v2, 26, v2
	v_add_u32_e32 v2, v3, v2
	v_and_b32_e32 v5, 0xc0, v2
	v_sub_u32_e32 v3, v3, v5
	v_ashrrev_i16_sdwa v3, v4, sext(v3) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	s_lshl_b32 s0, s50, 14
	v_lshlrev_b32_e32 v2, 6, v2
	v_and_b32_e32 v2, 0xfffff000, v2
	v_mov_b32_e32 v4, 8
	v_lshlrev_b32_sdwa v3, v4, sext(v3) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_lshl_or_b32 v4, v1, 4, s0
	v_add3_u32 v209, v4, v2, v3
	s_mov_b32 s11, 0x20000
	s_mov_b32 s27, s11
	; sched_barrier mask(0x00000000)
	s_waitcnt vmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s30, s49, s47
	s_mov_b32 m0, s30
	s_nop 0
	buffer_load_dwordx4 v193, s[20:23], 0 offen lds
	s_add_i32 s41, s30, 0x400
	s_mov_b32 m0, s41
	s_nop 0
	buffer_load_dwordx4 v193, s[20:23], s14 offen lds
	s_add_i32 s42, s30, 0x800
	s_mov_b32 m0, s42
	s_nop 0
	buffer_load_dwordx4 v193, s[20:23], s36 offen lds
	v_lshlrev_b32_e32 v201, 2, v192
	buffer_load_dword v195, v201, s[8:11], 0 offen
	buffer_load_dword v196, v201, s[8:11], 0 offen offset:256
	buffer_load_dword v197, v201, s[8:11], 0 offen offset:512
	s_lshl_b32 s53, s57, 2
	v_mov_b32_e32 v2, s53
	buffer_load_dword v198, v2, s[24:27], 0 offen
	s_add_i32 s40, s49, s48
	s_add_i32 s43, s40, 0x6010
	s_mov_b32 m0, s43
	s_nop 0
	buffer_load_dwordx4 v210, s[4:7], 0 offen lds
	s_add_i32 s15, s40, 0x6410
	s_mov_b32 m0, s15
	s_nop 0
	buffer_load_dwordx4 v210, s[4:7], s37 offen lds
	s_add_i32 s31, s40, 0x6810
	s_mov_b32 m0, s31
	s_nop 0
	buffer_load_dwordx4 v210, s[4:7], s38 offen lds
	s_addk_i32 s40, 0x6c10
	s_mov_b32 m0, s40
	s_nop 0
	buffer_load_dwordx4 v210, s[4:7], s39 offen lds
	v_mov_b32_e32 v92, 0
	v_cndmask_b32_e64 v2, 0, 1, s[18:19]
	v_cmp_ne_u32_e64 s[0:1], 1, v2
	s_andn2_b64 vcc, exec, s[18:19]
	v_add_u32_e32 v189, s46, v211
	v_add_u32_e32 v188, s46, v209
	v_mov_b32_e32 v82, 0
	v_mov_b32_e32 v83, 0
	v_mov_b32_e32 v84, 0
	v_mov_b32_e32 v85, 0
	v_mov_b32_e32 v86, 0
	v_mov_b32_e32 v87, 0
	v_mov_b32_e32 v88, 0
	v_mov_b32_e32 v89, 0
	v_mov_b32_e32 v18, 0
	v_mov_b32_e32 v19, 0
	v_mov_b32_e32 v20, 0
	v_mov_b32_e32 v21, 0
	v_mov_b32_e32 v22, 0
	v_mov_b32_e32 v23, 0
	v_mov_b32_e32 v24, 0
	v_mov_b32_e32 v25, 0
	v_mov_b32_e32 v42, 0
	v_mov_b32_e32 v43, 0
	v_mov_b32_e32 v44, 0
	v_mov_b32_e32 v45, 0
	v_mov_b32_e32 v46, 0
	v_mov_b32_e32 v47, 0
	v_mov_b32_e32 v48, 0
	v_mov_b32_e32 v49, 0
	v_mov_b32_e32 v34, 0
	v_mov_b32_e32 v35, 0
	v_mov_b32_e32 v36, 0
	v_mov_b32_e32 v37, 0
	v_mov_b32_e32 v38, 0
	v_mov_b32_e32 v39, 0
	v_mov_b32_e32 v40, 0
	v_mov_b32_e32 v41, 0
	v_mov_b32_e32 v50, 0
	v_mov_b32_e32 v51, 0
	v_mov_b32_e32 v52, 0
	v_mov_b32_e32 v53, 0
	v_mov_b32_e32 v54, 0
	v_mov_b32_e32 v55, 0
	v_mov_b32_e32 v56, 0
	v_mov_b32_e32 v57, 0
	v_mov_b32_e32 v58, 0
	v_mov_b32_e32 v59, 0
	v_mov_b32_e32 v60, 0
	v_mov_b32_e32 v61, 0
	v_mov_b32_e32 v62, 0
	v_mov_b32_e32 v63, 0
	v_mov_b32_e32 v64, 0
	v_mov_b32_e32 v65, 0
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
	v_mov_b32_e32 v10, 0
	v_mov_b32_e32 v11, 0
	v_mov_b32_e32 v12, 0
	v_mov_b32_e32 v13, 0
	v_mov_b32_e32 v14, 0
	v_mov_b32_e32 v15, 0
	v_mov_b32_e32 v16, 0
	v_mov_b32_e32 v17, 0
	v_mov_b32_e32 v74, 0
	v_mov_b32_e32 v75, 0
	v_mov_b32_e32 v76, 0
	v_mov_b32_e32 v77, 0
	v_mov_b32_e32 v78, 0
	v_mov_b32_e32 v79, 0
	v_mov_b32_e32 v80, 0
	v_mov_b32_e32 v81, 0
	v_mov_b32_e32 v26, 0
	v_mov_b32_e32 v27, 0
	v_mov_b32_e32 v28, 0
	v_mov_b32_e32 v29, 0
	v_mov_b32_e32 v30, 0
	v_mov_b32_e32 v31, 0
	v_mov_b32_e32 v32, 0
	v_mov_b32_e32 v33, 0
	s_cbranch_vccnz .LBB19_10
; %bb.9:
	ds_read_b128 v[26:29], v189
	ds_read_b128 v[30:33], v189 offset:64
	ds_read_b128 v[10:13], v189 offset:1024
	ds_read_b128 v[14:17], v189 offset:1088
	ds_read_b128 v[2:5], v189 offset:2048
	ds_read_b128 v[6:9], v189 offset:2112
	ds_read_b128 v[74:77], v188 offset:24592
	ds_read_b128 v[58:61], v188 offset:25616
	ds_read_b128 v[78:81], v188 offset:28688
	ds_read_b128 v[62:65], v188 offset:29712
	ds_read_b128 v[66:69], v188 offset:32784
	ds_read_b128 v[50:53], v188 offset:33808
	ds_read_b128 v[70:73], v188 offset:36880
	ds_read_b128 v[54:57], v188 offset:37904
	ds_read_b128 v[34:37], v188 offset:26640
	ds_read_b128 v[18:21], v188 offset:27664
	ds_read_b128 v[38:41], v188 offset:30736
	ds_read_b128 v[22:25], v188 offset:31760
	ds_read_b128 v[42:45], v188 offset:34832
	ds_read_b128 v[82:85], v188 offset:35856
	ds_read_b128 v[46:49], v188 offset:38928
	ds_read_b128 v[86:89], v188 offset:39952
.LBB19_10:
	s_waitcnt vmcnt(8)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_and_b64 vcc, exec, s[0:1]
	v_mov_b32_e32 v93, 0
	v_mov_b32_e32 v95, 0
	v_mov_b32_e32 v97, 0
	v_mov_b32_e32 v100, 0
	v_mov_b32_e32 v101, 0
	v_mov_b32_e32 v102, 0
	v_mov_b32_e32 v104, 0
	v_mov_b32_e32 v111, 0
	v_mov_b32_e32 v113, 0
	v_mov_b32_e32 v114, 0
	v_mov_b32_e32 v115, 0
	v_mov_b32_e32 v122, 0
	v_mov_b32_e32 v124, 0
	v_mov_b32_e32 v126, 0
	v_mov_b32_e32 v127, 0
	v_mov_b32_e32 v132, 0
	v_mov_b32_e32 v135, 0
	v_mov_b32_e32 v137, 0
	v_mov_b32_e32 v139, 0
	v_mov_b32_e32 v142, 0
	v_mov_b32_e32 v145, 0
	v_mov_b32_e32 v148, 0
	v_mov_b32_e32 v150, 0
	v_mov_b32_e32 v153, 0
	v_mov_b32_e32 v155, 0
	v_mov_b32_e32 v159, 0
	v_mov_b32_e32 v161, 0
	v_mov_b32_e32 v167, 0
	v_mov_b32_e32 v170, 0
	v_mov_b32_e32 v172, 0
	v_mov_b32_e32 v174, 0
	v_mov_b32_e32 v94, 0
	v_mov_b32_e32 v96, 0
	v_mov_b32_e32 v98, 0
	v_mov_b32_e32 v99, 0
	v_mov_b32_e32 v103, 0
	v_mov_b32_e32 v105, 0
	v_mov_b32_e32 v107, 0
	v_mov_b32_e32 v109, 0
	v_mov_b32_e32 v116, 0
	v_mov_b32_e32 v117, 0
	v_mov_b32_e32 v119, 0
	v_mov_b32_e32 v121, 0
	v_mov_b32_e32 v128, 0
	v_mov_b32_e32 v129, 0
	v_mov_b32_e32 v131, 0
	v_mov_b32_e32 v134, 0
	v_mov_b32_e32 v140, 0
	v_mov_b32_e32 v141, 0
	v_mov_b32_e32 v144, 0
	v_mov_b32_e32 v147, 0
	v_mov_b32_e32 v152, 0
	v_mov_b32_e32 v154, 0
	v_mov_b32_e32 v157, 0
	v_mov_b32_e32 v160, 0
	v_mov_b32_e32 v169, 0
	v_mov_b32_e32 v171, 0
	v_mov_b32_e32 v173, 0
	v_mov_b32_e32 v175, 0
	v_mov_b32_e32 v176, 0
	v_mov_b32_e32 v177, 0
	v_mov_b32_e32 v178, 0
	v_mov_b32_e32 v180, 0
	v_mov_b32_e32 v106, 0
	v_mov_b32_e32 v108, 0
	v_mov_b32_e32 v110, 0
	v_mov_b32_e32 v112, 0
	v_mov_b32_e32 v118, 0
	v_mov_b32_e32 v120, 0
	v_mov_b32_e32 v123, 0
	v_mov_b32_e32 v125, 0
	v_mov_b32_e32 v130, 0
	v_mov_b32_e32 v133, 0
	v_mov_b32_e32 v136, 0
	v_mov_b32_e32 v138, 0
	v_mov_b32_e32 v143, 0
	v_mov_b32_e32 v146, 0
	v_mov_b32_e32 v149, 0
	v_mov_b32_e32 v151, 0
	v_mov_b32_e32 v156, 0
	v_mov_b32_e32 v158, 0
	v_mov_b32_e32 v162, 0
	v_mov_b32_e32 v163, 0
	v_mov_b32_e32 v164, 0
	v_mov_b32_e32 v165, 0
	v_mov_b32_e32 v166, 0
	v_mov_b32_e32 v168, 0
	v_mov_b32_e32 v179, 0
	v_mov_b32_e32 v181, 0
	v_mov_b32_e32 v182, 0
	v_mov_b32_e32 v183, 0
	v_mov_b32_e32 v184, 0
	v_mov_b32_e32 v185, 0
	v_mov_b32_e32 v186, 0
	v_mov_b32_e32 v187, 0
	s_cbranch_vccnz .LBB19_12
; %bb.11:
	; sched_barrier mask(0x00000000)
	s_getpc_b64 s[0:1]
	s_add_u32 s0, s0, .Lnetra_dense_constant_1@rel32@lo+4
	s_addc_u32 s1, s1, .Lnetra_dense_constant_1@rel32@hi+12
	s_load_dword s0, s[0:1], 0x0
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v167, s0
	s_nop 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[204:207], v[82:89], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[184:187], v[82:89], v[2:9], 0, v167, v167 op_sel_hi:[0,0,0]
	v_mul_f32_e32 v174, v203, v200
	v_mul_f32_e32 v180, v202, v200
	v_mul_f32_e32 v199, v199, v200
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[82:89], v[26:33], 0, v167, v167 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[74:81], v[26:33], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v92, v174, v86, 0
	v_fma_f32 v93, v174, v87, 0
	v_fma_f32 v95, v174, v88, 0
	v_fma_f32 v97, v174, v89, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[74:81], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v94, v180, v86, 0
	v_fma_f32 v96, v180, v87, 0
	v_fma_f32 v98, v180, v88, 0
	v_fma_f32 v99, v180, v89, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[74:81], v[2:9], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v106, v199, v74, 0
	v_fma_f32 v108, v199, v75, 0
	v_fma_f32 v110, v199, v76, 0
	v_fma_f32 v112, v199, v77, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[66:73], v[26:33], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v100, v174, v74, 0
	v_fma_f32 v101, v174, v75, 0
	v_fma_f32 v102, v174, v76, 0
	v_fma_f32 v104, v174, v77, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[66:73], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v103, v180, v74, 0
	v_fma_f32 v105, v180, v75, 0
	v_fma_f32 v107, v180, v76, 0
	v_fma_f32 v109, v180, v77, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[66:73], v[2:9], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v118, v199, v66, 0
	v_fma_f32 v120, v199, v67, 0
	v_fma_f32 v123, v199, v68, 0
	v_fma_f32 v125, v199, v69, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[58:65], v[26:33], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v111, v174, v66, 0
	v_fma_f32 v113, v174, v67, 0
	v_fma_f32 v114, v174, v68, 0
	v_fma_f32 v115, v174, v69, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[58:65], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v116, v180, v66, 0
	v_fma_f32 v117, v180, v67, 0
	v_fma_f32 v119, v180, v68, 0
	v_fma_f32 v121, v180, v69, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[58:65], v[2:9], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v130, v199, v58, 0
	v_fma_f32 v133, v199, v59, 0
	v_fma_f32 v136, v199, v60, 0
	v_fma_f32 v138, v199, v61, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[50:57], v[26:33], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v122, v174, v58, 0
	v_fma_f32 v124, v174, v59, 0
	v_fma_f32 v126, v174, v60, 0
	v_fma_f32 v127, v174, v61, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[50:57], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v128, v180, v58, 0
	v_fma_f32 v129, v180, v59, 0
	v_fma_f32 v131, v180, v60, 0
	v_fma_f32 v134, v180, v61, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[50:57], v[2:9], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v143, v199, v50, 0
	v_fma_f32 v146, v199, v51, 0
	v_fma_f32 v149, v199, v52, 0
	v_fma_f32 v151, v199, v53, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[34:41], v[26:33], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v132, v174, v50, 0
	v_fma_f32 v135, v174, v51, 0
	v_fma_f32 v137, v174, v52, 0
	v_fma_f32 v139, v174, v53, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[34:41], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v140, v180, v50, 0
	v_fma_f32 v141, v180, v51, 0
	v_fma_f32 v144, v180, v52, 0
	v_fma_f32 v147, v180, v53, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[34:41], v[2:9], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v156, v199, v34, 0
	v_fma_f32 v158, v199, v35, 0
	v_fma_f32 v162, v199, v36, 0
	v_fma_f32 v163, v199, v37, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[42:49], v[26:33], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v142, v174, v34, 0
	v_fma_f32 v145, v174, v35, 0
	v_fma_f32 v148, v174, v36, 0
	v_fma_f32 v150, v174, v37, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[42:49], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v152, v180, v34, 0
	v_fma_f32 v154, v180, v35, 0
	v_fma_f32 v157, v180, v36, 0
	v_fma_f32 v160, v180, v37, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[42:49], v[2:9], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v164, v199, v34, 0
	v_fma_f32 v165, v199, v35, 0
	v_fma_f32 v166, v199, v36, 0
	v_fma_f32 v168, v199, v37, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[18:25], v[26:33], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v153, v174, v26, 0
	v_fma_f32 v155, v174, v27, 0
	v_fma_f32 v159, v174, v28, 0
	v_fma_f32 v161, v174, v29, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[18:25], v[10:17], 0, v167, v167 op_sel_hi:[0,0,0]
	;;#ASMSTART
	s_nop 0
	;;#ASMEND
	s_nop 11
	v_fma_f32 v169, v180, v10, 0
	v_fma_f32 v171, v180, v11, 0
	v_fma_f32 v173, v180, v12, 0
	v_fma_f32 v175, v180, v13, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[18:25], v[2:9], 0, v167, v167 op_sel_hi:[0,0,0]
	s_nop 11
	v_fma_f32 v179, v199, v2, 0
	v_fma_f32 v181, v199, v3, 0
	v_fma_f32 v182, v199, v4, 0
	v_fma_f32 v183, v199, v5, 0
	v_fma_f32 v167, v174, v82, 0
	v_fma_f32 v170, v174, v83, 0
	v_fma_f32 v172, v174, v84, 0
	v_fma_f32 v174, v174, v85, 0
	v_fma_f32 v176, v180, v204, 0
	v_fma_f32 v177, v180, v205, 0
	v_fma_f32 v178, v180, v206, 0
	v_fma_f32 v180, v180, v207, 0
	v_fma_f32 v184, v199, v184, 0
	v_fma_f32 v185, v199, v185, 0
	v_fma_f32 v186, v199, v186, 0
	v_fma_f32 v187, v199, v187, 0
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(3) SyncID(0)
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
.LBB19_12:                              ; %_ZZN7ck_tile30move_tensor_adaptor_coordinateILb1ENS_17tensor_descriptorINS_5tupleIJNS_5embedINS2_IJiiEEES4_Lb0EEENS_12pass_throughIiEES7_NS_7unmergeINS2_IJiNS_8constantILi4EEEEEELb0EEENS8_INS2_IJiNS9_ILi1EEENS9_ILi8EEENS9_ILi16EEEEEELb0EEES7_NS_5xor_tINS2_IJSA_SE_EEELb1EEES7_NS6_ISD_EENS6_ISF_EENS_21merge_v3_division_modISB_EENSN_ISG_EEEEENS2_IJNS_8sequenceIJLi0EEEENSR_IJLi1EEEENSR_IJLi2EEEENSR_IJLi3EEEENSR_IJLi4EEEENSR_IJLi5EEEENSR_IJLi6ELi9EEEENSR_IJLi7EEEENSR_IJLi8EEEENSR_IJLi10EEEENSR_IJLi11ELi12EEEENSR_IJLi14ELi15ELi13ELi16EEEEEEENS2_IJNSR_IJLi1ELi2EEEESV_SW_NSR_IJLi5ELi6EEEENSR_IJLi7ELi8ELi9ELi10EEEENSR_IJLi11EEEENSR_IJLi12ELi13EEEENSR_IJLi14EEEENSR_IJLi15EEEENSR_IJLi16EEEENSR_IJLi17EEEENSR_IJLi18EEEEEEENSR_IJLi17ELi18EEEEiNSR_IJLin1ELin1ELi16ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEENSR_IJLin1ELin1ELi1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEEEENS_17tensor_coordinateILi19ES1G_EENS_5arrayIiLi2EEENS1M_IiLi1EEEEEvRKT0_R340
	s_add_i32 s50, s44, 0x7f
	v_add_u32_e32 v208, 0x80, v194
	v_lshrrev_b32_e32 v206, 7, v208
	v_add_u32_e32 v2, s45, v206
	v_lshl_add_u32 v200, v2, 7, v193
	v_add_u32_e32 v207, 0x800, v210
	v_add_u32_e32 v199, s29, v192
	s_waitcnt vmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s0, s46, s47
	s_mov_b32 m0, s0
	s_nop 0
	buffer_load_dwordx4 v200, s[20:23], 0 offen lds
	s_add_i32 s1, s0, 0x400
	s_mov_b32 m0, s1
	s_nop 0
	buffer_load_dwordx4 v200, s[20:23], s14 offen lds
	s_add_i32 s18, s0, 0x800
	s_mov_b32 m0, s18
	s_nop 0
	buffer_load_dwordx4 v200, s[20:23], s36 offen lds
	v_lshlrev_b32_e32 v2, 2, v199
	buffer_load_dword v202, v2, s[8:11], 0 offen
	buffer_load_dword v203, v2, s[8:11], 0 offen offset:256
	buffer_load_dword v204, v2, s[8:11], 0 offen offset:512
	v_mov_b32_e32 v2, s53
	buffer_load_dword v205, v2, s[24:27], 0 offen offset:4
	s_add_i32 s46, s46, s48
	s_add_i32 s19, s46, 0x6010
	s_mov_b32 m0, s19
	s_nop 0
	buffer_load_dwordx4 v207, s[4:7], 0 offen lds
	s_add_i32 s44, s46, 0x6410
	s_mov_b32 m0, s44
	s_nop 0
	buffer_load_dwordx4 v207, s[4:7], s37 offen lds
	s_add_i32 s45, s46, 0x6810
	s_mov_b32 m0, s45
	s_nop 0
	buffer_load_dwordx4 v207, s[4:7], s38 offen lds
	s_addk_i32 s46, 0x6c10
	s_mov_b32 m0, s46
	s_nop 0
	buffer_load_dwordx4 v207, s[4:7], s39 offen lds
	s_mov_b32 s47, 0
	v_add_u32_e32 v192, s49, v211
	ds_read_b128 v[10:13], v192
	ds_read_b128 v[14:17], v192 offset:64
	ds_read_b128 v[2:5], v192 offset:1024
	ds_read_b128 v[6:9], v192 offset:1088
	s_waitcnt lgkmcnt(10)
	ds_read_b128 v[18:21], v192 offset:2048
	s_waitcnt lgkmcnt(9)
	ds_read_b128 v[22:25], v192 offset:2112
	v_add_u32_e32 v193, s49, v209
	s_waitcnt lgkmcnt(8)
	ds_read_b128 v[82:85], v193 offset:24592
	ds_read_b128 v[50:53], v193 offset:25616
	s_waitcnt lgkmcnt(8)
	ds_read_b128 v[86:89], v193 offset:28688
	ds_read_b128 v[54:57], v193 offset:29712
	ds_read_b128 v[66:69], v193 offset:32784
	ds_read_b128 v[42:45], v193 offset:33808
	ds_read_b128 v[70:73], v193 offset:36880
	ds_read_b128 v[46:49], v193 offset:37904
	ds_read_b128 v[34:37], v193 offset:26640
	ds_read_b128 v[26:29], v193 offset:27664
	ds_read_b128 v[38:41], v193 offset:30736
	ds_read_b128 v[30:33], v193 offset:31760
	ds_read_b128 v[58:61], v193 offset:34832
	ds_read_b128 v[74:77], v193 offset:35856
	ds_read_b128 v[62:65], v193 offset:38928
	ds_read_b128 v[78:81], v193 offset:39952
	s_mov_b32 s48, 4
	s_waitcnt vmcnt(8)
	s_cmpk_lt_i32 s50, 0x280
	s_barrier
	s_cbranch_scc1 .LBB19_16
; %bb.13:                               ; %_ZZN7ck_tile30move_tensor_adaptor_coordinateILb1ENS_17tensor_descriptorINS_5tupleIJNS_5embedINS2_IJiiEEES4_Lb0EEENS_12pass_throughIiEES7_NS_7unmergeINS2_IJiNS_8constantILi4EEEEEELb0EEENS8_INS2_IJiNS9_ILi1EEENS9_ILi8EEENS9_ILi16EEEEEELb0EEES7_NS_5xor_tINS2_IJSA_SE_EEELb1EEES7_NS6_ISD_EENS6_ISF_EENS_21merge_v3_division_modISB_EENSN_ISG_EEEEENS2_IJNS_8sequenceIJLi0EEEENSR_IJLi1EEEENSR_IJLi2EEEENSR_IJLi3EEEENSR_IJLi4EEEENSR_IJLi5EEEENSR_IJLi6ELi9EEEENSR_IJLi7EEEENSR_IJLi8EEEENSR_IJLi10EEEENSR_IJLi11ELi12EEEENSR_IJLi14ELi15ELi13ELi16EEEEEEENS2_IJNSR_IJLi1ELi2EEEESV_SW_NSR_IJLi5ELi6EEEENSR_IJLi7ELi8ELi9ELi10EEEENSR_IJLi11EEEENSR_IJLi12ELi13EEEENSR_IJLi14EEEENSR_IJLi15EEEENSR_IJLi16EEEENSR_IJLi17EEEENSR_IJLi18EEEEEEENSR_IJLi17ELi18EEEEiNSR_IJLin1ELin1ELi16ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEENSR_IJLin1ELin1ELi1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEEEENS_17tensor_coordinateILi19ES1G_EENS_5arrayIiLi2EEENS1M_IiLi1EEEEEvRKT020290
	s_ashr_i32 s49, s50, 31
	s_lshr_b32 s49, s49, 25
	s_add_i32 s50, s50, s49
	s_ashr_i32 s49, s50, 7
	s_getpc_b64 s[50:51]
	s_add_u32 s50, s50, .Lnetra_dense_constant_1@rel32@lo+4
	s_addc_u32 s51, s51, .Lnetra_dense_constant_1@rel32@hi+12
	s_load_dword s50, s[50:51], 0x0
	v_add_u32_e32 v207, 0x180, v194
	v_lshrrev_b32_e32 v208, 7, v207
	v_and_b32_e32 v209, 0xffffff80, v207
	s_mul_i32 s51, s29, 12
	s_lshl_b32 s52, s29, 3
	s_add_i32 s56, s53, 8
	v_add_u32_e32 v210, 0x1000, v210
	s_add_i32 s53, s29, s29
	s_mov_b32 s54, s52
.LBB19_14:                              ; %_ZZN7ck_tile30move_tensor_adaptor_coordinateILb1ENS_17tensor_descriptorINS_5tupleIJNS_5embedINS2_IJiiEEES4_Lb0EEENS_12pass_throughIiEES7_NS_7unmergeINS2_IJiNS_8constantILi4EEEEEELb0EEENS8_INS2_IJiNS9_ILi1EEENS9_ILi8EEENS9_ILi16EEEEEELb0EEES7_NS_5xor_tINS2_IJSA_SE_EEELb1EEES7_NS6_ISD_EENS6_ISF_EENS_21merge_v3_division_modISB_EENSN_ISG_EEEEENS2_IJNS_8sequenceIJLi0EEEENSR_IJLi1EEEENSR_IJLi2EEEENSR_IJLi3EEEENSR_IJLi4EEEENSR_IJLi5EEEENSR_IJLi6ELi9EEEENSR_IJLi7EEEENSR_IJLi8EEEENSR_IJLi10EEEENSR_IJLi11ELi12EEEENSR_IJLi14ELi15ELi13ELi16EEEEEEENS2_IJNSR_IJLi1ELi2EEEESV_SW_NSR_IJLi5ELi6EEEENSR_IJLi7ELi8ELi9ELi10EEEENSR_IJLi11EEEENSR_IJLi12ELi13EEEENSR_IJLi14EEEENSR_IJLi15EEEENSR_IJLi16EEEENSR_IJLi17EEEENSR_IJLi18EEEEEEENSR_IJLi17ELi18EEEEiNSR_IJLin1ELin1ELi16ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEENSR_IJLin1ELin1ELi1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEEEENS_17tensor_coordinateILi19ES1G_EENS_5arrayIiLi2EEENS1M_IiLi1EEEEEvRKT0_R613
                                        ; =>This Inner Loop Header: Depth=1
	s_mov_b32 s55, s56
	;;#ASMSTART
	;; HotLoop Start ;;
	;;#ASMEND
	; sched_barrier mask(0x00000000)
	s_setprio 1
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v226, s50
	s_nop 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[212:215], v[82:89], v[10:17], 0, v226, v226 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[216:219], v[82:89], v[2:9], 0, v226, v226 op_sel_hi:[0,0,0]
	v_mul_f32_e32 v207, v195, v198
	v_mul_f32_e32 v196, v196, v198
	v_mul_f32_e32 v195, v197, v198
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[82:89], v[18:25], 0, v226, v226 op_sel_hi:[0,0,0]
	;;#ASMSTART
	s_nop 0
	;;#ASMEND
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[66:73], v[10:17], 0, v226, v226 op_sel_hi:[0,0,0]
	s_nop 4
	v_fmac_f32_e32 v92, v207, v212
	v_fmac_f32_e32 v93, v207, v213
	v_fmac_f32_e32 v95, v207, v214
	v_fmac_f32_e32 v97, v207, v215
	v_mfma_scale_f32_16x16x128_f8f6f4 v[212:215], v[66:73], v[2:9], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v94, v196, v216
	v_fmac_f32_e32 v96, v196, v217
	v_fmac_f32_e32 v98, v196, v218
	v_fmac_f32_e32 v99, v196, v219
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[66:73], v[18:25], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v106, v195, v86
	v_fmac_f32_e32 v108, v195, v87
	v_fmac_f32_e32 v110, v195, v88
	v_fmac_f32_e32 v112, v195, v89
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[50:57], v[10:17], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v100, v207, v82
	v_fmac_f32_e32 v101, v207, v83
	v_fmac_f32_e32 v102, v207, v84
	v_fmac_f32_e32 v104, v207, v85
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[50:57], v[2:9], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v103, v196, v212
	v_fmac_f32_e32 v105, v196, v213
	v_fmac_f32_e32 v107, v196, v214
	v_fmac_f32_e32 v109, v196, v215
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[50:57], v[18:25], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v118, v195, v66
	v_fmac_f32_e32 v120, v195, v67
	v_fmac_f32_e32 v123, v195, v68
	v_fmac_f32_e32 v125, v195, v69
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[42:49], v[10:17], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v111, v207, v86
	v_fmac_f32_e32 v113, v207, v87
	v_fmac_f32_e32 v114, v207, v88
	v_fmac_f32_e32 v115, v207, v89
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[42:49], v[2:9], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v116, v196, v82
	v_fmac_f32_e32 v117, v196, v83
	v_fmac_f32_e32 v119, v196, v84
	v_fmac_f32_e32 v121, v196, v85
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[42:49], v[18:25], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v130, v195, v70
	v_fmac_f32_e32 v133, v195, v71
	v_fmac_f32_e32 v136, v195, v72
	v_fmac_f32_e32 v138, v195, v73
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[34:41], v[10:17], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v122, v207, v66
	v_fmac_f32_e32 v124, v207, v67
	v_fmac_f32_e32 v126, v207, v68
	v_fmac_f32_e32 v127, v207, v69
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[34:41], v[2:9], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v128, v196, v54
	v_fmac_f32_e32 v129, v196, v55
	v_fmac_f32_e32 v131, v196, v56
	v_fmac_f32_e32 v134, v196, v57
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[34:41], v[18:25], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v143, v195, v50
	v_fmac_f32_e32 v146, v195, v51
	v_fmac_f32_e32 v149, v195, v52
	v_fmac_f32_e32 v151, v195, v53
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[58:65], v[10:17], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v132, v207, v46
	v_fmac_f32_e32 v135, v207, v47
	v_fmac_f32_e32 v137, v207, v48
	v_fmac_f32_e32 v139, v207, v49
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[58:65], v[2:9], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v140, v196, v42
	v_fmac_f32_e32 v141, v196, v43
	v_fmac_f32_e32 v144, v196, v44
	v_fmac_f32_e32 v147, v196, v45
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[58:65], v[18:25], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v156, v195, v38
	v_fmac_f32_e32 v158, v195, v39
	v_fmac_f32_e32 v162, v195, v40
	v_fmac_f32_e32 v163, v195, v41
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[26:33], v[10:17], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v142, v207, v34
	v_fmac_f32_e32 v145, v207, v35
	v_fmac_f32_e32 v148, v207, v36
	v_fmac_f32_e32 v150, v207, v37
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[26:33], v[2:9], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v152, v196, v46
	v_fmac_f32_e32 v154, v196, v47
	v_fmac_f32_e32 v157, v196, v48
	v_fmac_f32_e32 v160, v196, v49
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[26:33], v[18:25], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v164, v195, v42
	v_fmac_f32_e32 v165, v195, v43
	v_fmac_f32_e32 v166, v195, v44
	v_fmac_f32_e32 v168, v195, v45
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[74:81], v[10:17], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v153, v207, v38
	v_fmac_f32_e32 v155, v207, v39
	v_fmac_f32_e32 v159, v207, v40
	v_fmac_f32_e32 v161, v207, v41
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[74:81], v[2:9], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v169, v196, v34
	v_fmac_f32_e32 v171, v196, v35
	v_fmac_f32_e32 v173, v196, v36
	v_fmac_f32_e32 v175, v196, v37
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[74:81], v[18:25], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v179, v195, v26
	v_fmac_f32_e32 v181, v195, v27
	v_fmac_f32_e32 v182, v195, v28
	v_fmac_f32_e32 v183, v195, v29
	v_fmac_f32_e32 v167, v207, v10
	v_fmac_f32_e32 v170, v207, v11
	v_fmac_f32_e32 v172, v207, v12
	v_fmac_f32_e32 v174, v207, v13
	v_fmac_f32_e32 v176, v196, v6
	v_fmac_f32_e32 v177, v196, v7
	v_fmac_f32_e32 v178, v196, v8
	v_fmac_f32_e32 v180, v196, v9
	v_fmac_f32_e32 v184, v195, v2
	v_fmac_f32_e32 v185, v195, v3
	v_fmac_f32_e32 v186, v195, v4
	v_fmac_f32_e32 v187, v195, v5
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(3) SyncID(0)
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
	v_lshlrev_b32_e32 v207, 7, v206
	v_add_u32_e32 v2, s47, v194
	v_sub_u32_e32 v2, v2, v207
	v_add_u32_e32 v2, 0x100, v2
	v_and_b32_e32 v2, 0xffffff80, v2
	v_add_u32_e32 v2, v2, v200
	s_waitcnt vmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_mov_b32 m0, s30
	s_nop 0
	buffer_load_dwordx4 v2, s[20:23], 0 offen lds
	s_mov_b32 m0, s41
	s_nop 0
	buffer_load_dwordx4 v2, s[20:23], s14 offen lds
	s_mov_b32 m0, s42
	s_nop 0
	buffer_load_dwordx4 v2, s[20:23], s36 offen lds
	s_setprio 0
	s_mov_b32 m0, s43
	v_add_u32_e32 v2, s54, v201
	buffer_load_dword v195, v2, s[8:11], 0 offen
	buffer_load_dword v196, v2, s[8:11], 0 offen offset:256
	buffer_load_dword v197, v2, s[8:11], 0 offen offset:512
	v_mov_b32_e32 v224, s56
	buffer_load_dword v198, v224, s[24:27], 0 offen
	ds_read_b128 v[26:29], v189
	ds_read_b128 v[30:33], v189 offset:64
	ds_read_b128 v[18:21], v189 offset:1024
	ds_read_b128 v[22:25], v189 offset:1088
	ds_read_b128 v[10:13], v189 offset:2048
	ds_read_b128 v[14:17], v189 offset:2112
	buffer_load_dwordx4 v210, s[4:7], 0 offen lds
	s_mov_b32 m0, s15
	s_nop 0
	buffer_load_dwordx4 v210, s[4:7], s37 offen lds
	s_mov_b32 m0, s31
	s_nop 0
	buffer_load_dwordx4 v210, s[4:7], s38 offen lds
	s_mov_b32 m0, s40
	s_nop 0
	buffer_load_dwordx4 v210, s[4:7], s39 offen lds
	ds_read_b128 v[82:85], v188 offset:24592
	ds_read_b128 v[66:69], v188 offset:25616
	ds_read_b128 v[86:89], v188 offset:28688
	ds_read_b128 v[70:73], v188 offset:29712
	ds_read_b128 v[74:77], v188 offset:32784
	ds_read_b128 v[58:61], v188 offset:33808
	ds_read_b128 v[78:81], v188 offset:36880
	ds_read_b128 v[62:65], v188 offset:37904
	ds_read_b128 v[50:53], v188 offset:26640
	ds_read_b128 v[34:37], v188 offset:27664
	ds_read_b128 v[54:57], v188 offset:30736
	ds_read_b128 v[38:41], v188 offset:31760
	ds_read_b128 v[42:45], v188 offset:34832
	ds_read_b128 v[2:5], v188 offset:35856
	ds_read_b128 v[46:49], v188 offset:38928
	ds_read_b128 v[6:9], v188 offset:39952
	; sched_barrier mask(0x00000000)
	s_waitcnt vmcnt(8)
	s_barrier
	; sched_barrier mask(0x00000000)
	; sched_barrier mask(0x00000000)
	s_setprio 1
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(13)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[220:223], v[82:89], v[26:33], 0, v226, v226 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[216:219], v[82:89], v[18:25], 0, v226, v226 op_sel_hi:[0,0,0]
	v_mul_f32_e32 v225, v202, v205
	v_mul_f32_e32 v211, v203, v205
	v_mul_f32_e32 v206, v204, v205
	v_mfma_scale_f32_16x16x128_f8f6f4 v[212:215], v[82:89], v[10:17], 0, v226, v226 op_sel_hi:[0,0,0]
	;;#ASMSTART
	s_nop 0
	;;#ASMEND
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[202:205], v[74:81], v[26:33], 0, v226, v226 op_sel_hi:[0,0,0]
	s_nop 4
	v_fmac_f32_e32 v92, v225, v220
	v_fmac_f32_e32 v93, v225, v221
	v_fmac_f32_e32 v95, v225, v222
	v_fmac_f32_e32 v97, v225, v223
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[74:81], v[18:25], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v94, v211, v216
	v_fmac_f32_e32 v96, v211, v217
	v_fmac_f32_e32 v98, v211, v218
	v_fmac_f32_e32 v99, v211, v219
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[74:81], v[10:17], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v106, v206, v212
	v_fmac_f32_e32 v108, v206, v213
	v_fmac_f32_e32 v110, v206, v214
	v_fmac_f32_e32 v112, v206, v215
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[66:73], v[26:33], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v100, v225, v202
	v_fmac_f32_e32 v101, v225, v203
	v_fmac_f32_e32 v102, v225, v204
	v_fmac_f32_e32 v104, v225, v205
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[66:73], v[18:25], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v103, v211, v86
	v_fmac_f32_e32 v105, v211, v87
	v_fmac_f32_e32 v107, v211, v88
	v_fmac_f32_e32 v109, v211, v89
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[66:73], v[10:17], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v118, v206, v82
	v_fmac_f32_e32 v120, v206, v83
	v_fmac_f32_e32 v123, v206, v84
	v_fmac_f32_e32 v125, v206, v85
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[58:65], v[26:33], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v111, v225, v74
	v_fmac_f32_e32 v113, v225, v75
	v_fmac_f32_e32 v114, v225, v76
	v_fmac_f32_e32 v115, v225, v77
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[58:65], v[18:25], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v116, v211, v78
	v_fmac_f32_e32 v117, v211, v79
	v_fmac_f32_e32 v119, v211, v80
	v_fmac_f32_e32 v121, v211, v81
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[58:65], v[10:17], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v130, v206, v70
	v_fmac_f32_e32 v133, v206, v71
	v_fmac_f32_e32 v136, v206, v72
	v_fmac_f32_e32 v138, v206, v73
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[50:57], v[26:33], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v122, v225, v66
	v_fmac_f32_e32 v124, v225, v67
	v_fmac_f32_e32 v126, v225, v68
	v_fmac_f32_e32 v127, v225, v69
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[50:57], v[18:25], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v128, v211, v74
	v_fmac_f32_e32 v129, v211, v75
	v_fmac_f32_e32 v131, v211, v76
	v_fmac_f32_e32 v134, v211, v77
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[50:57], v[10:17], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v143, v206, v58
	v_fmac_f32_e32 v146, v206, v59
	v_fmac_f32_e32 v149, v206, v60
	v_fmac_f32_e32 v151, v206, v61
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[42:49], v[26:33], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v132, v225, v70
	v_fmac_f32_e32 v135, v225, v71
	v_fmac_f32_e32 v137, v225, v72
	v_fmac_f32_e32 v139, v225, v73
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[42:49], v[18:25], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v140, v211, v66
	v_fmac_f32_e32 v141, v211, v67
	v_fmac_f32_e32 v144, v211, v68
	v_fmac_f32_e32 v147, v211, v69
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[42:49], v[10:17], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v156, v206, v62
	v_fmac_f32_e32 v158, v206, v63
	v_fmac_f32_e32 v162, v206, v64
	v_fmac_f32_e32 v163, v206, v65
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[34:41], v[26:33], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v142, v225, v58
	v_fmac_f32_e32 v145, v225, v59
	v_fmac_f32_e32 v148, v225, v60
	v_fmac_f32_e32 v150, v225, v61
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[34:41], v[18:25], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v152, v211, v54
	v_fmac_f32_e32 v154, v211, v55
	v_fmac_f32_e32 v157, v211, v56
	v_fmac_f32_e32 v160, v211, v57
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[34:41], v[10:17], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v164, v206, v50
	v_fmac_f32_e32 v165, v206, v51
	v_fmac_f32_e32 v166, v206, v52
	v_fmac_f32_e32 v168, v206, v53
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[2:9], v[26:33], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v153, v225, v46
	v_fmac_f32_e32 v155, v225, v47
	v_fmac_f32_e32 v159, v225, v48
	v_fmac_f32_e32 v161, v225, v49
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[2:9], v[18:25], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v169, v211, v42
	v_fmac_f32_e32 v171, v211, v43
	v_fmac_f32_e32 v173, v211, v44
	v_fmac_f32_e32 v175, v211, v45
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[2:9], v[10:17], 0, v226, v226 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v179, v206, v34
	v_fmac_f32_e32 v181, v206, v35
	v_fmac_f32_e32 v182, v206, v36
	v_fmac_f32_e32 v183, v206, v37
	v_fmac_f32_e32 v167, v225, v26
	v_fmac_f32_e32 v170, v225, v27
	v_fmac_f32_e32 v172, v225, v28
	v_fmac_f32_e32 v174, v225, v29
	v_fmac_f32_e32 v176, v211, v18
	v_fmac_f32_e32 v177, v211, v19
	v_fmac_f32_e32 v178, v211, v20
	v_fmac_f32_e32 v180, v211, v21
	v_fmac_f32_e32 v184, v206, v2
	v_fmac_f32_e32 v185, v206, v3
	v_fmac_f32_e32 v186, v206, v4
	v_fmac_f32_e32 v187, v206, v5
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(3) SyncID(0)
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
	v_add3_u32 v206, v208, s48, -4
	v_sub_u32_e32 v2, v200, v207
	v_add_u32_e32 v211, v209, v2
	v_add_u32_e32 v200, s47, v211
	s_waitcnt vmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_mov_b32 m0, s0
	s_nop 0
	buffer_load_dwordx4 v200, s[20:23], 0 offen lds
	s_mov_b32 m0, s1
	s_nop 0
	buffer_load_dwordx4 v200, s[20:23], s14 offen lds
	s_mov_b32 m0, s18
	s_nop 0
	buffer_load_dwordx4 v200, s[20:23], s36 offen lds
	s_setprio 0
	s_mov_b32 m0, s19
	v_add_u32_e32 v2, s51, v201
	buffer_load_dword v202, v2, s[8:11], 0 offen
	buffer_load_dword v203, v2, s[8:11], 0 offen offset:256
	buffer_load_dword v204, v2, s[8:11], 0 offen offset:512
	v_add_u32_e32 v207, 0x800, v210
	buffer_load_dword v205, v224, s[24:27], 0 offen offset:4
	ds_read_b128 v[10:13], v192
	ds_read_b128 v[14:17], v192 offset:64
	ds_read_b128 v[2:5], v192 offset:1024
	ds_read_b128 v[6:9], v192 offset:1088
	ds_read_b128 v[18:21], v192 offset:2048
	ds_read_b128 v[22:25], v192 offset:2112
	buffer_load_dwordx4 v207, s[4:7], 0 offen lds
	s_mov_b32 m0, s44
	s_nop 0
	buffer_load_dwordx4 v207, s[4:7], s37 offen lds
	s_mov_b32 m0, s45
	s_nop 0
	buffer_load_dwordx4 v207, s[4:7], s38 offen lds
	s_mov_b32 m0, s46
	s_nop 0
	buffer_load_dwordx4 v207, s[4:7], s39 offen lds
	ds_read_b128 v[82:85], v193 offset:24592
	ds_read_b128 v[50:53], v193 offset:25616
	ds_read_b128 v[86:89], v193 offset:28688
	ds_read_b128 v[54:57], v193 offset:29712
	ds_read_b128 v[66:69], v193 offset:32784
	ds_read_b128 v[42:45], v193 offset:33808
	ds_read_b128 v[70:73], v193 offset:36880
	ds_read_b128 v[46:49], v193 offset:37904
	ds_read_b128 v[34:37], v193 offset:26640
	ds_read_b128 v[26:29], v193 offset:27664
	ds_read_b128 v[38:41], v193 offset:30736
	ds_read_b128 v[30:33], v193 offset:31760
	ds_read_b128 v[58:61], v193 offset:34832
	ds_read_b128 v[74:77], v193 offset:35856
	ds_read_b128 v[62:65], v193 offset:38928
	ds_read_b128 v[78:81], v193 offset:39952
	v_add_u32_e32 v199, s53, v199
	; sched_barrier mask(0x00000000)
	s_waitcnt vmcnt(8)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s48, s48, 2
	;;#ASMSTART
	;; HotLoop End ;;
	;;#ASMEND
	s_addk_i32 s47, 0x100
	s_add_i32 s51, s51, s52
	s_add_i32 s54, s54, s52
	s_add_i32 s56, s56, 8
	s_cmp_lt_i32 s48, s49
	v_add_u32_e32 v210, 0x1000, v210
	s_cbranch_scc1 .LBB19_14
; %bb.15:                               ; %Flow5460
	s_add_i32 s49, s55, 4
	v_add_u32_e32 v200, s47, v211
	v_add_u32_e32 v200, 0xffffff00, v200
	v_add3_u32 v206, v208, s48, -6
	v_add_u32_e32 v194, s47, v194
	v_add_u32_e32 v208, 0x80, v194
	s_branch .LBB19_17
.LBB19_16:
	s_add_i32 s49, s53, 4
.LBB19_17:                              ; %_ZZN7ck_tile30move_tensor_adaptor_coordinateILb1ENS_17tensor_descriptorINS_5tupleIJNS_5embedINS2_IJiiEEES4_Lb0EEENS_12pass_throughIiEES7_NS_7unmergeINS2_IJiNS_8constantILi4EEEEEELb0EEENS8_INS2_IJiNS9_ILi1EEENS9_ILi8EEENS9_ILi16EEEEEELb0EEES7_NS_5xor_tINS2_IJSA_SE_EEELb1EEES7_NS6_ISD_EENS6_ISF_EENS_21merge_v3_division_modISB_EENSN_ISG_EEEEENS2_IJNS_8sequenceIJLi0EEEENSR_IJLi1EEEENSR_IJLi2EEEENSR_IJLi3EEEENSR_IJLi4EEEENSR_IJLi5EEEENSR_IJLi6ELi9EEEENSR_IJLi7EEEENSR_IJLi8EEEENSR_IJLi10EEEENSR_IJLi11ELi12EEEENSR_IJLi14ELi15ELi13ELi16EEEEEEENS2_IJNSR_IJLi1ELi2EEEESV_SW_NSR_IJLi5ELi6EEEENSR_IJLi7ELi8ELi9ELi10EEEENSR_IJLi11EEEENSR_IJLi12ELi13EEEENSR_IJLi14EEEENSR_IJLi15EEEENSR_IJLi16EEEENSR_IJLi17EEEENSR_IJLi18EEEEEEENSR_IJLi17ELi18EEEEiNSR_IJLin1ELin1ELi16ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEENSR_IJLin1ELin1ELi1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1ELin1EEEEEENS_17tensor_coordinateILi19ES1G_EENS_5arrayIiLi2EEENS1M_IiLi1EEEEEvRKT0_5262
	;;#ASMSTART
	;; Even Tail Start ;;
	;;#ASMEND
	s_barrier
	; sched_barrier mask(0x00000000)
	s_setprio 1
	; sched_barrier mask(0x00000000)
	s_getpc_b64 s[50:51]
	s_add_u32 s50, s50, .Lnetra_dense_constant_1@rel32@lo+4
	s_addc_u32 s51, s51, .Lnetra_dense_constant_1@rel32@hi+12
	s_load_dword s47, s[50:51], 0x0
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v209, s47
	s_nop 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[214:217], v[74:81], v[2:9], 0, v209, v209 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[210:213], v[74:81], v[18:25], 0, v209, v209 op_sel_hi:[0,0,0]
	v_mul_f32_e32 v201, v195, v198
	v_mul_f32_e32 v195, v196, v198
	v_mul_f32_e32 v194, v197, v198
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[74:81], v[10:17], 0, v209, v209 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[82:89], v[10:17], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v92, v201, v78
	v_fmac_f32_e32 v93, v201, v79
	v_fmac_f32_e32 v95, v201, v80
	v_fmac_f32_e32 v97, v201, v81
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[82:89], v[2:9], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v94, v195, v78
	v_fmac_f32_e32 v96, v195, v79
	v_fmac_f32_e32 v98, v195, v80
	v_fmac_f32_e32 v99, v195, v81
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[82:89], v[18:25], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v106, v194, v78
	v_fmac_f32_e32 v108, v194, v79
	v_fmac_f32_e32 v110, v194, v80
	v_fmac_f32_e32 v112, v194, v81
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[66:73], v[10:17], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v100, v201, v78
	v_fmac_f32_e32 v101, v201, v79
	v_fmac_f32_e32 v102, v201, v80
	v_fmac_f32_e32 v104, v201, v81
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[66:73], v[2:9], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v103, v195, v78
	v_fmac_f32_e32 v105, v195, v79
	v_fmac_f32_e32 v107, v195, v80
	v_fmac_f32_e32 v109, v195, v81
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[66:73], v[18:25], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v118, v194, v66
	v_fmac_f32_e32 v120, v194, v67
	v_fmac_f32_e32 v123, v194, v68
	v_fmac_f32_e32 v125, v194, v69
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[50:57], v[10:17], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v111, v201, v66
	v_fmac_f32_e32 v113, v201, v67
	v_fmac_f32_e32 v114, v201, v68
	v_fmac_f32_e32 v115, v201, v69
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[50:57], v[2:9], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v116, v195, v66
	v_fmac_f32_e32 v117, v195, v67
	v_fmac_f32_e32 v119, v195, v68
	v_fmac_f32_e32 v121, v195, v69
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[50:57], v[18:25], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v130, v194, v50
	v_fmac_f32_e32 v133, v194, v51
	v_fmac_f32_e32 v136, v194, v52
	v_fmac_f32_e32 v138, v194, v53
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[42:49], v[10:17], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v122, v201, v50
	v_fmac_f32_e32 v124, v201, v51
	v_fmac_f32_e32 v126, v201, v52
	v_fmac_f32_e32 v127, v201, v53
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[42:49], v[2:9], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v128, v195, v50
	v_fmac_f32_e32 v129, v195, v51
	v_fmac_f32_e32 v131, v195, v52
	v_fmac_f32_e32 v134, v195, v53
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[42:49], v[18:25], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v143, v194, v42
	v_fmac_f32_e32 v146, v194, v43
	v_fmac_f32_e32 v149, v194, v44
	v_fmac_f32_e32 v151, v194, v45
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[34:41], v[10:17], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v132, v201, v42
	v_fmac_f32_e32 v135, v201, v43
	v_fmac_f32_e32 v137, v201, v44
	v_fmac_f32_e32 v139, v201, v45
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[34:41], v[2:9], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v140, v195, v42
	v_fmac_f32_e32 v141, v195, v43
	v_fmac_f32_e32 v144, v195, v44
	v_fmac_f32_e32 v147, v195, v45
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[34:41], v[18:25], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v156, v194, v34
	v_fmac_f32_e32 v158, v194, v35
	v_fmac_f32_e32 v162, v194, v36
	v_fmac_f32_e32 v163, v194, v37
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[58:65], v[10:17], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v142, v201, v34
	v_fmac_f32_e32 v145, v201, v35
	v_fmac_f32_e32 v148, v201, v36
	v_fmac_f32_e32 v150, v201, v37
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[58:65], v[2:9], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v152, v195, v34
	v_fmac_f32_e32 v154, v195, v35
	v_fmac_f32_e32 v157, v195, v36
	v_fmac_f32_e32 v160, v195, v37
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[58:65], v[18:25], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v164, v194, v34
	v_fmac_f32_e32 v165, v194, v35
	v_fmac_f32_e32 v166, v194, v36
	v_fmac_f32_e32 v168, v194, v37
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[26:33], v[10:17], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v153, v201, v10
	v_fmac_f32_e32 v155, v201, v11
	v_fmac_f32_e32 v159, v201, v12
	v_fmac_f32_e32 v161, v201, v13
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[26:33], v[2:9], 0, v209, v209 op_sel_hi:[0,0,0]
	;;#ASMSTART
	s_nop 0
	;;#ASMEND
	s_nop 11
	v_fmac_f32_e32 v169, v195, v2
	v_fmac_f32_e32 v171, v195, v3
	v_fmac_f32_e32 v173, v195, v4
	v_fmac_f32_e32 v175, v195, v5
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[26:33], v[18:25], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 11
	v_fmac_f32_e32 v179, v194, v2
	v_fmac_f32_e32 v181, v194, v3
	v_fmac_f32_e32 v182, v194, v4
	v_fmac_f32_e32 v183, v194, v5
	v_fmac_f32_e32 v167, v201, v74
	v_fmac_f32_e32 v170, v201, v75
	v_fmac_f32_e32 v172, v201, v76
	v_fmac_f32_e32 v174, v201, v77
	v_fmac_f32_e32 v176, v195, v214
	v_fmac_f32_e32 v177, v195, v215
	v_fmac_f32_e32 v178, v195, v216
	v_fmac_f32_e32 v180, v195, v217
	v_fmac_f32_e32 v184, v194, v210
	v_fmac_f32_e32 v185, v194, v211
	v_fmac_f32_e32 v186, v194, v212
	v_fmac_f32_e32 v187, v194, v213
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(3) SyncID(0)
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
	v_add_u32_e32 v2, 0x80, v208
	v_ashrrev_i32_e32 v3, 31, v2
	v_lshrrev_b32_e32 v3, 25, v3
	v_add_u32_e32 v3, v2, v3
	v_ashrrev_i32_e32 v227, 7, v3
	v_sub_u32_e32 v4, v227, v206
	v_and_b32_e32 v3, 0xff80, v3
	v_sub_u32_e32 v2, v2, v3
	v_mov_b32_e32 v226, 11
	v_lshrrev_b16_sdwa v3, v226, sext(v2) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	v_and_b32_e32 v3, 15, v3
	v_add_u16_e32 v5, v2, v3
	v_mov_b32_e32 v225, 4
	v_ashrrev_i16_sdwa v3, v225, sext(v5) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	v_and_b32_e32 v5, -16, v5
	v_sub_u16_e32 v224, v2, v5
	v_bfe_i32 v2, v224, 0, 8
	v_xor_b32_sdwa v223, v190, sext(v3) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_sub_u32_e32 v3, v223, v191
	v_lshlrev_b32_e32 v3, 4, v3
	v_lshl_add_u32 v4, v4, 7, v200
	v_add3_u32 v222, v4, v2, v3
	s_waitcnt vmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_mov_b32 m0, s30
	s_nop 0
	buffer_load_dwordx4 v222, s[20:23], 0 offen lds
	s_mov_b32 m0, s41
	s_nop 0
	buffer_load_dwordx4 v222, s[20:23], s14 offen lds
	s_mov_b32 m0, s42
	s_nop 0
	buffer_load_dwordx4 v222, s[20:23], s36 offen lds
	s_setprio 0
	s_mov_b32 m0, s43
	v_add_u32_e32 v221, s29, v199
	v_lshlrev_b32_e32 v2, 2, v221
	buffer_load_dword v220, v2, s[8:11], 0 offen
	buffer_load_dword v219, v2, s[8:11], 0 offen offset:256
	buffer_load_dword v206, v2, s[8:11], 0 offen offset:512
                                        ; kill: killed $vgpr2
	v_add_u32_e32 v2, 0x800, v207
	v_mov_b32_e32 v191, s49
	buffer_load_dword v218, v191, s[24:27], 0 offen offset:4
	ds_read_b128 v[26:29], v189
	ds_read_b128 v[30:33], v189 offset:64
	ds_read_b128 v[18:21], v189 offset:1024
	ds_read_b128 v[22:25], v189 offset:1088
	ds_read_b128 v[10:13], v189 offset:2048
	ds_read_b128 v[14:17], v189 offset:2112
	buffer_load_dwordx4 v2, s[4:7], 0 offen lds
	s_mov_b32 m0, s15
	s_nop 0
	buffer_load_dwordx4 v2, s[4:7], s37 offen lds
	s_mov_b32 m0, s31
	s_nop 0
	buffer_load_dwordx4 v2, s[4:7], s38 offen lds
	s_mov_b32 m0, s40
	s_nop 0
	buffer_load_dwordx4 v2, s[4:7], s39 offen lds
	ds_read_b128 v[82:85], v188 offset:24592
	ds_read_b128 v[66:69], v188 offset:25616
	ds_read_b128 v[86:89], v188 offset:28688
	ds_read_b128 v[70:73], v188 offset:29712
	ds_read_b128 v[74:77], v188 offset:32784
	ds_read_b128 v[58:61], v188 offset:33808
	ds_read_b128 v[78:81], v188 offset:36880
	ds_read_b128 v[62:65], v188 offset:37904
	ds_read_b128 v[50:53], v188 offset:26640
	ds_read_b128 v[34:37], v188 offset:27664
	ds_read_b128 v[54:57], v188 offset:30736
	ds_read_b128 v[38:41], v188 offset:31760
	ds_read_b128 v[42:45], v188 offset:34832
	ds_read_b128 v[2:5], v188 offset:35856
	ds_read_b128 v[46:49], v188 offset:38928
	ds_read_b128 v[6:9], v188 offset:39952
	; sched_barrier mask(0x00000000)
	s_waitcnt vmcnt(8)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_barrier
	;;#ASMSTART
	;; Even Tail End ;;
	;;#ASMEND
	s_barrier
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(13)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[214:217], v[82:89], v[26:33], 0, v209, v209 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[210:213], v[82:89], v[18:25], 0, v209, v209 op_sel_hi:[0,0,0]
	v_mul_f32_e32 v228, v202, v205
	v_mul_f32_e32 v203, v203, v205
	v_mul_f32_e32 v202, v204, v205
	v_mfma_scale_f32_16x16x128_f8f6f4 v[198:201], v[82:89], v[10:17], 0, v209, v209 op_sel_hi:[0,0,0]
	;;#ASMSTART
	s_nop 0
	;;#ASMEND
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[194:197], v[74:81], v[26:33], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 4
	v_fmac_f32_e32 v92, v228, v214
	v_fmac_f32_e32 v93, v228, v215
	v_fmac_f32_e32 v95, v228, v216
	v_fmac_f32_e32 v97, v228, v217
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[74:81], v[18:25], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v94, v203, v210
	v_fmac_f32_e32 v96, v203, v211
	v_fmac_f32_e32 v98, v203, v212
	v_fmac_f32_e32 v99, v203, v213
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[74:81], v[10:17], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v106, v202, v198
	v_fmac_f32_e32 v108, v202, v199
	v_fmac_f32_e32 v110, v202, v200
	v_fmac_f32_e32 v112, v202, v201
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[66:73], v[26:33], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v100, v228, v194
	v_fmac_f32_e32 v101, v228, v195
	v_fmac_f32_e32 v102, v228, v196
	v_fmac_f32_e32 v104, v228, v197
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[66:73], v[18:25], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v103, v203, v86
	v_fmac_f32_e32 v105, v203, v87
	v_fmac_f32_e32 v107, v203, v88
	v_fmac_f32_e32 v109, v203, v89
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[66:73], v[10:17], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v118, v202, v82
	v_fmac_f32_e32 v120, v202, v83
	v_fmac_f32_e32 v123, v202, v84
	v_fmac_f32_e32 v125, v202, v85
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[58:65], v[26:33], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v111, v228, v74
	v_fmac_f32_e32 v113, v228, v75
	v_fmac_f32_e32 v114, v228, v76
	v_fmac_f32_e32 v115, v228, v77
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[58:65], v[18:25], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v116, v203, v78
	v_fmac_f32_e32 v117, v203, v79
	v_fmac_f32_e32 v119, v203, v80
	v_fmac_f32_e32 v121, v203, v81
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[58:65], v[10:17], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v130, v202, v70
	v_fmac_f32_e32 v133, v202, v71
	v_fmac_f32_e32 v136, v202, v72
	v_fmac_f32_e32 v138, v202, v73
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[50:57], v[26:33], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v122, v228, v66
	v_fmac_f32_e32 v124, v228, v67
	v_fmac_f32_e32 v126, v228, v68
	v_fmac_f32_e32 v127, v228, v69
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[50:57], v[18:25], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v128, v203, v74
	v_fmac_f32_e32 v129, v203, v75
	v_fmac_f32_e32 v131, v203, v76
	v_fmac_f32_e32 v134, v203, v77
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[50:57], v[10:17], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v143, v202, v58
	v_fmac_f32_e32 v146, v202, v59
	v_fmac_f32_e32 v149, v202, v60
	v_fmac_f32_e32 v151, v202, v61
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[42:49], v[26:33], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v132, v228, v70
	v_fmac_f32_e32 v135, v228, v71
	v_fmac_f32_e32 v137, v228, v72
	v_fmac_f32_e32 v139, v228, v73
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[42:49], v[18:25], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v140, v203, v66
	v_fmac_f32_e32 v141, v203, v67
	v_fmac_f32_e32 v144, v203, v68
	v_fmac_f32_e32 v147, v203, v69
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[42:49], v[10:17], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v156, v202, v62
	v_fmac_f32_e32 v158, v202, v63
	v_fmac_f32_e32 v162, v202, v64
	v_fmac_f32_e32 v163, v202, v65
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[34:41], v[26:33], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v142, v228, v58
	v_fmac_f32_e32 v145, v228, v59
	v_fmac_f32_e32 v148, v228, v60
	v_fmac_f32_e32 v150, v228, v61
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[34:41], v[18:25], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v152, v203, v54
	v_fmac_f32_e32 v154, v203, v55
	v_fmac_f32_e32 v157, v203, v56
	v_fmac_f32_e32 v160, v203, v57
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[34:41], v[10:17], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v164, v202, v50
	v_fmac_f32_e32 v165, v202, v51
	v_fmac_f32_e32 v166, v202, v52
	v_fmac_f32_e32 v168, v202, v53
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[2:9], v[26:33], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v153, v228, v46
	v_fmac_f32_e32 v155, v228, v47
	v_fmac_f32_e32 v159, v228, v48
	v_fmac_f32_e32 v161, v228, v49
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[2:9], v[18:25], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v169, v203, v42
	v_fmac_f32_e32 v171, v203, v43
	v_fmac_f32_e32 v173, v203, v44
	v_fmac_f32_e32 v175, v203, v45
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[2:9], v[10:17], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v179, v202, v34
	v_fmac_f32_e32 v181, v202, v35
	v_fmac_f32_e32 v182, v202, v36
	v_fmac_f32_e32 v183, v202, v37
	v_fmac_f32_e32 v167, v228, v26
	v_fmac_f32_e32 v170, v228, v27
	v_fmac_f32_e32 v172, v228, v28
	v_fmac_f32_e32 v174, v228, v29
	v_fmac_f32_e32 v176, v203, v18
	v_fmac_f32_e32 v177, v203, v19
	v_fmac_f32_e32 v178, v203, v20
	v_fmac_f32_e32 v180, v203, v21
	v_fmac_f32_e32 v184, v202, v2
	v_fmac_f32_e32 v185, v202, v3
	v_fmac_f32_e32 v186, v202, v4
	v_fmac_f32_e32 v187, v202, v5
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(3) SyncID(0)
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
	v_add_u32_e32 v2, 0x100, v208
	v_ashrrev_i32_e32 v3, 31, v2
	v_lshrrev_b32_e32 v3, 25, v3
	v_add_u32_e32 v4, v2, v3
	v_lshrrev_b32_e32 v3, 7, v4
	v_sub_u32_e32 v3, v3, v227
	v_and_b32_e32 v4, 0xff80, v4
	v_sub_u32_e32 v4, v2, v4
	v_lshrrev_b16_sdwa v2, v226, sext(v4) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	v_and_b32_e32 v2, 15, v2
	v_add_u16_e32 v5, v4, v2
	v_ashrrev_i16_sdwa v2, v225, sext(v5) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
	v_and_b32_e32 v5, 0xf0, v5
	v_sub_u16_e32 v4, v4, v5
	v_sub_u16_e32 v4, v4, v224
	v_bfe_i32 v4, v4, 0, 8
	v_xor_b32_sdwa v2, v190, sext(v2) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_sub_u32_e32 v2, v2, v223
	v_lshlrev_b32_e32 v2, 4, v2
	v_lshl_add_u32 v3, v3, 7, v4
	v_add3_u32 v2, v3, v2, v222
	v_add_u32_e32 v6, 0x1000, v207
	s_waitcnt vmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_mov_b32 m0, s0
	s_nop 0
	buffer_load_dwordx4 v2, s[20:23], 0 offen lds
	s_mov_b32 m0, s1
	s_nop 0
	buffer_load_dwordx4 v2, s[20:23], s14 offen lds
	s_mov_b32 m0, s18
	s_nop 0
	buffer_load_dwordx4 v2, s[20:23], s36 offen lds
	v_add_lshl_u32 v7, v221, s29, 2
	buffer_load_dword v2, v7, s[8:11], 0 offen
	buffer_load_dword v3, v7, s[8:11], 0 offen offset:256
	buffer_load_dword v4, v7, s[8:11], 0 offen offset:512
	buffer_load_dword v5, v191, s[24:27], 0 offen offset:8
                                        ; kill: killed $sgpr24_sgpr25_sgpr26 killed $sgpr27
                                        ; kill: killed $vgpr7
                                        ; kill: killed $sgpr8_sgpr9_sgpr10 killed $sgpr11
                                        ; kill: killed $vgpr191
	s_mov_b32 m0, s19
	s_nop 0
	buffer_load_dwordx4 v6, s[4:7], 0 offen lds
	s_mov_b32 m0, s44
	s_nop 0
	buffer_load_dwordx4 v6, s[4:7], s37 offen lds
	s_mov_b32 m0, s45
	s_nop 0
	buffer_load_dwordx4 v6, s[4:7], s38 offen lds
	s_mov_b32 m0, s46
	s_nop 0
	buffer_load_dwordx4 v6, s[4:7], s39 offen lds
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[30:33], v192
	ds_read_b128 v[34:37], v192 offset:64
	ds_read_b128 v[22:25], v192 offset:1024
	ds_read_b128 v[26:29], v192 offset:1088
	ds_read_b128 v[14:17], v192 offset:2048
	ds_read_b128 v[18:21], v192 offset:2112
	ds_read_b128 v[194:197], v193 offset:24592
	ds_read_b128 v[70:73], v193 offset:25616
	ds_read_b128 v[198:201], v193 offset:28688
	ds_read_b128 v[74:77], v193 offset:29712
	ds_read_b128 v[78:81], v193 offset:32784
	ds_read_b128 v[62:65], v193 offset:33808
	ds_read_b128 v[82:85], v193 offset:36880
	ds_read_b128 v[66:69], v193 offset:37904
	ds_read_b128 v[54:57], v193 offset:26640
	ds_read_b128 v[38:41], v193 offset:27664
	ds_read_b128 v[58:61], v193 offset:30736
	ds_read_b128 v[42:45], v193 offset:31760
	ds_read_b128 v[46:49], v193 offset:34832
	ds_read_b128 v[6:9], v193 offset:35856
	ds_read_b128 v[50:53], v193 offset:38928
	ds_read_b128 v[10:13], v193 offset:39952
	s_waitcnt vmcnt(8)
	s_barrier
	; sched_barrier mask(0x00000000)
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(13)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[190:193], v[194:201], v[30:37], 0, v209, v209 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[194:201], v[22:29], 0, v209, v209 op_sel_hi:[0,0,0]
	v_mul_f32_e32 v204, v220, v218
	v_mul_f32_e32 v203, v219, v218
	v_mul_f32_e32 v202, v206, v218
	v_mfma_scale_f32_16x16x128_f8f6f4 v[198:201], v[194:201], v[14:21], 0, v209, v209 op_sel_hi:[0,0,0]
	;;#ASMSTART
	s_nop 0
	;;#ASMEND
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[194:197], v[78:85], v[30:37], 0, v209, v209 op_sel_hi:[0,0,0]
	s_nop 4
	v_fmac_f32_e32 v92, v204, v190
	v_fmac_f32_e32 v93, v204, v191
	v_fmac_f32_e32 v95, v204, v192
	v_fmac_f32_e32 v97, v204, v193
	v_mfma_scale_f32_16x16x128_f8f6f4 v[190:193], v[78:85], v[22:29], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v94, v203, v86
	v_fmac_f32_e32 v96, v203, v87
	v_fmac_f32_e32 v98, v203, v88
	v_fmac_f32_e32 v99, v203, v89
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[78:85], v[14:21], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v106, v202, v198
	v_fmac_f32_e32 v108, v202, v199
	v_fmac_f32_e32 v110, v202, v200
	v_fmac_f32_e32 v112, v202, v201
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[70:77], v[30:37], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v100, v204, v194
	v_fmac_f32_e32 v101, v204, v195
	v_fmac_f32_e32 v102, v204, v196
	v_fmac_f32_e32 v104, v204, v197
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[70:77], v[22:29], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v103, v203, v190
	v_fmac_f32_e32 v105, v203, v191
	v_fmac_f32_e32 v107, v203, v192
	v_fmac_f32_e32 v109, v203, v193
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[70:77], v[14:21], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v118, v202, v86
	v_fmac_f32_e32 v120, v202, v87
	v_fmac_f32_e32 v123, v202, v88
	v_fmac_f32_e32 v125, v202, v89
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[62:69], v[30:37], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v111, v204, v78
	v_fmac_f32_e32 v113, v204, v79
	v_fmac_f32_e32 v114, v204, v80
	v_fmac_f32_e32 v115, v204, v81
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[62:69], v[22:29], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v116, v203, v82
	v_fmac_f32_e32 v117, v203, v83
	v_fmac_f32_e32 v119, v203, v84
	v_fmac_f32_e32 v121, v203, v85
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[62:69], v[14:21], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v130, v202, v74
	v_fmac_f32_e32 v133, v202, v75
	v_fmac_f32_e32 v136, v202, v76
	v_fmac_f32_e32 v138, v202, v77
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[54:61], v[30:37], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v122, v204, v70
	v_fmac_f32_e32 v124, v204, v71
	v_fmac_f32_e32 v126, v204, v72
	v_fmac_f32_e32 v127, v204, v73
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[54:61], v[22:29], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v128, v203, v78
	v_fmac_f32_e32 v129, v203, v79
	v_fmac_f32_e32 v131, v203, v80
	v_fmac_f32_e32 v134, v203, v81
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[54:61], v[14:21], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v143, v202, v62
	v_fmac_f32_e32 v146, v202, v63
	v_fmac_f32_e32 v149, v202, v64
	v_fmac_f32_e32 v151, v202, v65
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[46:53], v[30:37], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v132, v204, v74
	v_fmac_f32_e32 v135, v204, v75
	v_fmac_f32_e32 v137, v204, v76
	v_fmac_f32_e32 v139, v204, v77
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[46:53], v[22:29], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v140, v203, v70
	v_fmac_f32_e32 v141, v203, v71
	v_fmac_f32_e32 v144, v203, v72
	v_fmac_f32_e32 v147, v203, v73
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[46:53], v[14:21], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v156, v202, v66
	v_fmac_f32_e32 v158, v202, v67
	v_fmac_f32_e32 v162, v202, v68
	v_fmac_f32_e32 v163, v202, v69
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[38:45], v[30:37], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v142, v204, v62
	v_fmac_f32_e32 v145, v204, v63
	v_fmac_f32_e32 v148, v204, v64
	v_fmac_f32_e32 v150, v204, v65
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[38:45], v[22:29], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v152, v203, v58
	v_fmac_f32_e32 v154, v203, v59
	v_fmac_f32_e32 v157, v203, v60
	v_fmac_f32_e32 v160, v203, v61
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[38:45], v[14:21], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v164, v202, v54
	v_fmac_f32_e32 v165, v202, v55
	v_fmac_f32_e32 v166, v202, v56
	v_fmac_f32_e32 v168, v202, v57
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[6:13], v[30:37], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v153, v204, v50
	v_fmac_f32_e32 v155, v204, v51
	v_fmac_f32_e32 v159, v204, v52
	v_fmac_f32_e32 v161, v204, v53
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[6:13], v[22:29], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v169, v203, v46
	v_fmac_f32_e32 v171, v203, v47
	v_fmac_f32_e32 v173, v203, v48
	v_fmac_f32_e32 v175, v203, v49
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[6:13], v[14:21], 0, v209, v209 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v179, v202, v38
	v_fmac_f32_e32 v181, v202, v39
	v_fmac_f32_e32 v182, v202, v40
	v_fmac_f32_e32 v183, v202, v41
	v_fmac_f32_e32 v167, v204, v30
	v_fmac_f32_e32 v170, v204, v31
	v_fmac_f32_e32 v172, v204, v32
	v_fmac_f32_e32 v174, v204, v33
	v_fmac_f32_e32 v176, v203, v22
	v_fmac_f32_e32 v177, v203, v23
	v_fmac_f32_e32 v178, v203, v24
	v_fmac_f32_e32 v180, v203, v25
	v_fmac_f32_e32 v184, v202, v6
	v_fmac_f32_e32 v185, v202, v7
	v_fmac_f32_e32 v186, v202, v8
	v_fmac_f32_e32 v187, v202, v9
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(3) SyncID(0)
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
	ds_read_b128 v[30:33], v189
	ds_read_b128 v[34:37], v189 offset:64
	ds_read_b128 v[22:25], v189 offset:1024
	ds_read_b128 v[26:29], v189 offset:1088
	ds_read_b128 v[14:17], v189 offset:2048
	ds_read_b128 v[18:21], v189 offset:2112
	ds_read_b128 v[190:193], v188 offset:24592
	ds_read_b128 v[70:73], v188 offset:25616
	ds_read_b128 v[194:197], v188 offset:28688
	ds_read_b128 v[74:77], v188 offset:29712
	ds_read_b128 v[78:81], v188 offset:32784
	ds_read_b128 v[62:65], v188 offset:33808
	ds_read_b128 v[82:85], v188 offset:36880
	ds_read_b128 v[66:69], v188 offset:37904
	ds_read_b128 v[54:57], v188 offset:26640
	ds_read_b128 v[38:41], v188 offset:27664
	ds_read_b128 v[58:61], v188 offset:30736
	ds_read_b128 v[42:45], v188 offset:31760
	ds_read_b128 v[46:49], v188 offset:34832
	ds_read_b128 v[6:9], v188 offset:35856
	ds_read_b128 v[50:53], v188 offset:38928
	ds_read_b128 v[10:13], v188 offset:39952
	s_barrier
	; sched_barrier mask(0x00000000)
	; sched_barrier mask(0x00000000)
	v_mov_b32_e32 v205, s47
	s_waitcnt lgkmcnt(13)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[198:201], v[190:197], v[30:37], 0, v205, v205 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[190:197], v[22:29], 0, v205, v205 op_sel_hi:[0,0,0]
	v_mul_f32_e32 v204, v2, v5
	v_mul_f32_e32 v203, v3, v5
	v_mul_f32_e32 v202, v4, v5
	v_mfma_scale_f32_16x16x128_f8f6f4 v[192:195], v[190:197], v[14:21], 0, v205, v205 op_sel_hi:[0,0,0]
	;;#ASMSTART
	s_nop 0
	;;#ASMEND
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[78:85], v[30:37], 0, v205, v205 op_sel_hi:[0,0,0]
	s_nop 4
	v_fmac_f32_e32 v92, v204, v198
	v_fmac_f32_e32 v93, v204, v199
	v_fmac_f32_e32 v95, v204, v200
	v_fmac_f32_e32 v97, v204, v201
	v_mfma_scale_f32_16x16x128_f8f6f4 v[188:191], v[78:85], v[22:29], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v94, v203, v86
	v_fmac_f32_e32 v96, v203, v87
	v_fmac_f32_e32 v98, v203, v88
	v_fmac_f32_e32 v99, v203, v89
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[78:85], v[14:21], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v106, v202, v192
	v_fmac_f32_e32 v108, v202, v193
	v_fmac_f32_e32 v110, v202, v194
	v_fmac_f32_e32 v112, v202, v195
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[70:77], v[30:37], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v100, v204, v2
	v_fmac_f32_e32 v101, v204, v3
	v_fmac_f32_e32 v102, v204, v4
	v_fmac_f32_e32 v104, v204, v5
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[70:77], v[22:29], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v103, v203, v188
	v_fmac_f32_e32 v105, v203, v189
	v_fmac_f32_e32 v107, v203, v190
	v_fmac_f32_e32 v109, v203, v191
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[70:77], v[14:21], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v118, v202, v86
	v_fmac_f32_e32 v120, v202, v87
	v_fmac_f32_e32 v123, v202, v88
	v_fmac_f32_e32 v125, v202, v89
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[62:69], v[30:37], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v111, v204, v82
	v_fmac_f32_e32 v113, v204, v83
	v_fmac_f32_e32 v114, v204, v84
	v_fmac_f32_e32 v115, v204, v85
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[62:69], v[22:29], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v116, v203, v2
	v_fmac_f32_e32 v117, v203, v3
	v_fmac_f32_e32 v119, v203, v4
	v_fmac_f32_e32 v121, v203, v5
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[62:69], v[14:21], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v130, v202, v78
	v_fmac_f32_e32 v133, v202, v79
	v_fmac_f32_e32 v136, v202, v80
	v_fmac_f32_e32 v138, v202, v81
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[54:61], v[30:37], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v122, v204, v74
	v_fmac_f32_e32 v124, v204, v75
	v_fmac_f32_e32 v126, v204, v76
	v_fmac_f32_e32 v127, v204, v77
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[54:61], v[22:29], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v128, v203, v70
	v_fmac_f32_e32 v129, v203, v71
	v_fmac_f32_e32 v131, v203, v72
	v_fmac_f32_e32 v134, v203, v73
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[54:61], v[14:21], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v143, v202, v2
	v_fmac_f32_e32 v146, v202, v3
	v_fmac_f32_e32 v149, v202, v4
	v_fmac_f32_e32 v151, v202, v5
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[46:53], v[30:37], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v132, v204, v66
	v_fmac_f32_e32 v135, v204, v67
	v_fmac_f32_e32 v137, v204, v68
	v_fmac_f32_e32 v139, v204, v69
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[46:53], v[22:29], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v140, v203, v62
	v_fmac_f32_e32 v141, v203, v63
	v_fmac_f32_e32 v144, v203, v64
	v_fmac_f32_e32 v147, v203, v65
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[46:53], v[14:21], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v156, v202, v58
	v_fmac_f32_e32 v158, v202, v59
	v_fmac_f32_e32 v162, v202, v60
	v_fmac_f32_e32 v163, v202, v61
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[38:45], v[30:37], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v142, v204, v2
	v_fmac_f32_e32 v145, v204, v3
	v_fmac_f32_e32 v148, v204, v4
	v_fmac_f32_e32 v150, v204, v5
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[38:45], v[22:29], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v152, v203, v54
	v_fmac_f32_e32 v154, v203, v55
	v_fmac_f32_e32 v157, v203, v56
	v_fmac_f32_e32 v160, v203, v57
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[38:45], v[14:21], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v164, v202, v50
	v_fmac_f32_e32 v165, v202, v51
	v_fmac_f32_e32 v166, v202, v52
	v_fmac_f32_e32 v168, v202, v53
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[6:13], v[30:37], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v153, v204, v46
	v_fmac_f32_e32 v155, v204, v47
	v_fmac_f32_e32 v159, v204, v48
	v_fmac_f32_e32 v161, v204, v49
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[6:13], v[22:29], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v169, v203, v2
	v_fmac_f32_e32 v171, v203, v3
	v_fmac_f32_e32 v173, v203, v4
	v_fmac_f32_e32 v175, v203, v5
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[6:13], v[14:21], 0, v205, v205 op_sel_hi:[0,0,0]
	v_fmac_f32_e32 v179, v202, v38
	v_fmac_f32_e32 v181, v202, v39
	v_fmac_f32_e32 v182, v202, v40
	v_fmac_f32_e32 v183, v202, v41
	v_fmac_f32_e32 v167, v204, v30
	v_fmac_f32_e32 v170, v204, v31
	v_fmac_f32_e32 v172, v204, v32
	v_fmac_f32_e32 v174, v204, v33
	v_fmac_f32_e32 v176, v203, v22
	v_fmac_f32_e32 v177, v203, v23
	v_fmac_f32_e32 v178, v203, v24
	v_fmac_f32_e32 v180, v203, v25
	v_fmac_f32_e32 v184, v202, v2
	v_fmac_f32_e32 v185, v202, v3
	v_fmac_f32_e32 v186, v202, v4
	v_fmac_f32_e32 v187, v202, v5
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(3) SyncID(0)
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
.LBB19_19:                              ; %_ZZN7ck_tile15QuantGemmKernelINS_21GemmTile1DPartitionerINS_13TileGemmShapeINS_8sequenceIJLi192ELi256ELi128EEEENS3_IJLi4ELi2ELi1EEEENS3_IJLi16ELi16ELi128EEEELb0ELb0EEEEENS_35ABQuantGemmPipelineAgBgCrEightWavesINS_28GemmQuantPipelineProblemBaseIDB8_fSB_ffS7_NS_19TileGemmQuantTraitsILb1ELb0ELb0ELb0ELb0ELb1ENS_13tensor_layout4gemm8RowMajorENSE_11ColumnMajorESF_LNS_9QuantTypeE4ESG_SG_Lb1ELb1ELb0ELi16EEENS_15QuantGroupShapeINS3_IJLi1ELi1ELi128EEEEEENSJ_INS3_IJLi1ELi128ELi128EEEEEELb1ESB_LNS_21GemmPipelineSchedulerE1ELb1ELNS_10TailNumberE1ELNS_10CastPolicyE1EEENS_36GemmABQuantPipelineAgBgCrAsyncPolicyEEENS_16CShuffleEpilogueINS_23CShuffleEpilogueProblemISB_SB_NS_5tupleIJEEEfDF16bSX_SF_NS_12element_wise11PassThroughELi192ELi256ELi4ELi2ELi16ELi16ELi128ELb1ELi1ELb0ELi1ELi1ELb0EEEvEELSH_4EE7RunGemmEPKSB_S14_PKfS16_PDF16bPvRKNS_19QuantGemmKernelArgsERKNS12_17SplitKBatchOffsetEiiENKUlvE_clEv.exit.i.i.i
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
	v_lshrrev_b32_e32 v2, 2, v90
	v_and_b32_e32 v52, 28, v2
	s_waitcnt lgkmcnt(0)
	v_cvt_pk_bf16_f32 v49, v95, v97
	v_cvt_pk_bf16_f32 v48, v92, v93
	v_cvt_pk_bf16_f32 v47, v102, v104
	v_cvt_pk_bf16_f32 v46, v100, v101
	v_cvt_pk_bf16_f32 v45, v114, v115
	v_cvt_pk_bf16_f32 v44, v111, v113
	v_cvt_pk_bf16_f32 v43, v126, v127
	v_cvt_pk_bf16_f32 v42, v122, v124
	v_cvt_pk_bf16_f32 v41, v137, v139
	v_cvt_pk_bf16_f32 v40, v132, v135
	v_cvt_pk_bf16_f32 v39, v148, v150
	v_cvt_pk_bf16_f32 v38, v142, v145
	v_cvt_pk_bf16_f32 v37, v159, v161
	v_cvt_pk_bf16_f32 v36, v153, v155
	v_cvt_pk_bf16_f32 v35, v172, v174
	v_cvt_pk_bf16_f32 v34, v167, v170
	s_mov_b64 s[0:1], -1
	v_cvt_pk_bf16_f32 v19, v98, v99
	v_cvt_pk_bf16_f32 v18, v94, v96
	v_cvt_pk_bf16_f32 v21, v107, v109
	v_cvt_pk_bf16_f32 v20, v103, v105
	v_cvt_pk_bf16_f32 v23, v119, v121
	v_cvt_pk_bf16_f32 v22, v116, v117
	v_cvt_pk_bf16_f32 v25, v131, v134
	v_cvt_pk_bf16_f32 v24, v128, v129
	v_cvt_pk_bf16_f32 v27, v144, v147
	v_cvt_pk_bf16_f32 v26, v140, v141
	v_cvt_pk_bf16_f32 v29, v157, v160
	v_cvt_pk_bf16_f32 v28, v152, v154
	v_cvt_pk_bf16_f32 v31, v173, v175
	v_cvt_pk_bf16_f32 v30, v169, v171
	v_cvt_pk_bf16_f32 v33, v178, v180
	v_cvt_pk_bf16_f32 v32, v176, v177
	v_cvt_pk_bf16_f32 v3, v110, v112
	v_cvt_pk_bf16_f32 v2, v106, v108
	v_cvt_pk_bf16_f32 v5, v123, v125
	v_cvt_pk_bf16_f32 v4, v118, v120
	v_cvt_pk_bf16_f32 v7, v136, v138
	v_cvt_pk_bf16_f32 v6, v130, v133
	v_cvt_pk_bf16_f32 v9, v149, v151
	v_cvt_pk_bf16_f32 v8, v143, v146
	v_cvt_pk_bf16_f32 v11, v162, v163
	v_cvt_pk_bf16_f32 v10, v156, v158
	v_cvt_pk_bf16_f32 v13, v166, v168
	v_cvt_pk_bf16_f32 v12, v164, v165
	v_cvt_pk_bf16_f32 v15, v182, v183
	v_cvt_pk_bf16_f32 v14, v179, v181
	v_cvt_pk_bf16_f32 v17, v186, v187
	v_cvt_pk_bf16_f32 v16, v184, v185
	v_lshlrev_b32_e32 v51, 3, v90
	v_and_b32_e32 v50, 12, v91
	s_cbranch_scc1 .LBB19_22
; %bb.20:                               ; %Flow
	s_andn2_b64 vcc, exec, s[0:1]
	s_cbranch_vccz .LBB19_23
.LBB19_21:                              ; %_ZNK7ck_tile15QuantGemmKernelINS_21GemmTile1DPartitionerINS_13TileGemmShapeINS_8sequenceIJLi192ELi256ELi128EEEENS3_IJLi4ELi2ELi1EEEENS3_IJLi16ELi16ELi128EEEELb0ELb0EEEEENS_35ABQuantGemmPipelineAgBgCrEightWavesINS_28GemmQuantPipelineProblemBaseIDB8_fSB_ffS7_NS_19TileGemmQuantTraitsILb1ELb0ELb0ELb0ELb0ELb1ENS_13tensor_layout4gemm8RowMajorENSE_11ColumnMajorESF_LNS_9QuantTypeE4ESG_SG_Lb1ELb1ELb0ELi16EEENS_15QuantGroupShapeINS3_IJLi1ELi1ELi128EEEEEENSJ_INS3_IJLi1ELi128ELi128EEEEEELb1ESB_LNS_21GemmPipelineSchedulerE1ELb1ELNS_10TailNumberE1ELNS_10CastPolicyE1EEENS_36GemmABQuantPipelineAgBgCrAsyncPolicyEEENS_16CShuffleEpilogueINS_23CShuffleEpilogueProblemISB_SB_NS_5tupleIJEEEfDF16bSX_SF_NS_12element_wise11PassThroughELi192ELi256ELi4ELi2ELi16ELi16ELi128ELb1ELi1ELb0ELi1ELi1ELb0EEEvEELSH_4EEclERKNS_19QuantGemmKernelArgsE.exit
	s_endpgm
.LBB19_22:
	v_readfirstlane_b32 s0, v0
	s_lshr_b32 s1, s0, 1
	s_and_b32 s1, s1, 0x7fffff80
	v_or_b32_e32 v57, s1, v52
	v_ashrrev_i32_e32 v53, 31, v57
	v_lshrrev_b32_e32 v53, 29, v53
	v_add_u32_e32 v53, v57, v53
	v_lshrrev_b32_e32 v54, 3, v53
	v_and_b32_e32 v53, -8, v53
	v_sub_u32_e32 v58, v57, v53
	s_lshr_b32 s1, s0, 2
	v_and_or_b32 v55, s1, 48, v1
	v_mul_u32_u24_e32 v55, 0x102, v55
	v_add3_u32 v53, v58, v55, v53
	s_barrier
	v_lshlrev_b32_e32 v81, 1, v53
	ds_write_b64 v81, v[48:49]
	v_add_u32_e32 v56, 16, v57
	v_ashrrev_i32_e32 v55, 31, v56
	v_lshrrev_b32_e32 v55, 29, v55
	v_add_u32_e32 v59, v56, v55
	v_ashrrev_i32_e32 v55, 3, v59
	v_sub_u32_e32 v54, v55, v54
	v_and_b32_e32 v59, -8, v59
	v_sub_u32_e32 v56, v56, v59
	v_lshlrev_b32_e32 v54, 3, v54
	v_sub_u32_e32 v58, v56, v58
	v_add3_u32 v54, v58, v53, v54
	v_lshlrev_b32_e32 v80, 1, v54
	ds_write_b64 v80, v[46:47]
	v_add_u32_e32 v58, 32, v57
	v_ashrrev_i32_e32 v53, 31, v58
	v_lshrrev_b32_e32 v53, 29, v53
	v_add_u32_e32 v59, v58, v53
	v_ashrrev_i32_e32 v53, 3, v59
	v_sub_u32_e32 v55, v53, v55
	v_and_b32_e32 v59, -8, v59
	v_sub_u32_e32 v59, v58, v59
	v_sub_u32_e32 v56, v59, v56
	v_lshl_add_u32 v58, v55, 3, v56
	v_lshl_add_u32 v79, v58, 1, v80
	ds_write_b64 v79, v[44:45]
	v_add_u32_e32 v56, 48, v57
	v_ashrrev_i32_e32 v55, 31, v56
	v_lshrrev_b32_e32 v55, 29, v55
	v_add_u32_e32 v60, v56, v55
	v_ashrrev_i32_e32 v55, 3, v60
	v_sub_u32_e32 v53, v55, v53
	v_and_b32_e32 v60, -8, v60
	v_sub_u32_e32 v56, v56, v60
	v_sub_u32_e32 v59, v56, v59
	v_lshl_add_u32 v53, v53, 3, v59
	v_add3_u32 v54, v58, v54, v53
	v_lshl_add_u32 v78, v53, 1, v79
	ds_write_b64 v78, v[42:43]
	v_add_u32_e32 v58, 64, v57
	v_ashrrev_i32_e32 v53, 31, v58
	v_lshrrev_b32_e32 v53, 29, v53
	v_add_u32_e32 v59, v58, v53
	v_ashrrev_i32_e32 v53, 3, v59
	v_sub_u32_e32 v55, v53, v55
	v_and_b32_e32 v59, -8, v59
	v_sub_u32_e32 v59, v58, v59
	v_sub_u32_e32 v56, v59, v56
	v_lshl_add_u32 v55, v55, 3, v56
	v_lshl_add_u32 v77, v55, 1, v78
	ds_write_b64 v77, v[40:41]
	v_add_u32_e32 v58, 0x50, v57
	v_ashrrev_i32_e32 v56, 31, v58
	v_lshrrev_b32_e32 v56, 29, v56
	v_add_u32_e32 v60, v58, v56
	v_ashrrev_i32_e32 v56, 3, v60
	v_sub_u32_e32 v53, v56, v53
	v_and_b32_e32 v60, -8, v60
	v_sub_u32_e32 v58, v58, v60
	v_sub_u32_e32 v59, v58, v59
	v_lshl_add_u32 v53, v53, 3, v59
	v_add3_u32 v55, v55, v54, v53
	v_lshl_add_u32 v76, v53, 1, v77
	ds_write_b64 v76, v[38:39]
	v_add_u32_e32 v53, 0x60, v57
	v_ashrrev_i32_e32 v54, 31, v53
	v_lshrrev_b32_e32 v54, 29, v54
	v_add_u32_e32 v59, v53, v54
	v_ashrrev_i32_e32 v54, 3, v59
	v_sub_u32_e32 v56, v54, v56
	v_and_b32_e32 v59, -8, v59
	v_sub_u32_e32 v53, v53, v59
	v_sub_u32_e32 v58, v53, v58
	v_lshl_add_u32 v56, v56, 3, v58
	v_lshl_add_u32 v75, v56, 1, v76
	ds_write_b64 v75, v[36:37]
	v_add_u32_e32 v57, 0x70, v57
	v_ashrrev_i32_e32 v58, 31, v57
	v_lshrrev_b32_e32 v58, 29, v58
	v_add_u32_e32 v58, v57, v58
	v_lshrrev_b32_e32 v59, 3, v58
	v_sub_u32_e32 v54, v59, v54
	v_and_b32_e32 v58, 0x7ffffff8, v58
	v_sub_u32_e32 v57, v57, v58
	v_sub_u32_e32 v53, v57, v53
	v_lshlrev_b32_e32 v53, 1, v53
	v_lshlrev_b32_e32 v54, 4, v54
	v_add_lshl_u32 v55, v56, v55, 1
	v_add3_u32 v74, v53, v54, v55
	ds_write_b64 v74, v[34:35]
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_and_b32_e32 v70, 0xf8, v51
	s_lshr_b32 s0, s0, 3
	s_and_b32 s0, s0, 0x1ffffff8
	v_add_u32_e32 v53, s0, v50
	s_movk_i32 s0, 0x204
	v_mul_lo_u32 v54, v53, s0
	v_lshl_add_u32 v71, v70, 1, v54
	ds_read_b128 v[66:69], v71
	ds_read_b128 v[62:65], v71 offset:516
	ds_read_b128 v[58:61], v71 offset:1032
	ds_read_b128 v[54:57], v71 offset:1548
	v_add_u32_e32 v53, s33, v53
	v_or_b32_e32 v70, s2, v70
	v_mad_u64_u32 v[72:73], s[0:1], v53, s28, v[70:71]
	s_lshl_b32 s14, s3, 1
	s_mov_b32 s15, 0x20000
	v_lshlrev_b32_e32 v73, 1, v72
	s_waitcnt lgkmcnt(3)
	buffer_atomic_pk_add_bf16 v66, v73, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v67, v73, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v68, v73, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v69, v73, s[12:15], 12 offen
	v_add_u32_e32 v66, s28, v72
	v_lshlrev_b32_e32 v67, 1, v66
	s_waitcnt lgkmcnt(2)
	buffer_atomic_pk_add_bf16 v62, v67, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v63, v67, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v64, v67, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v65, v67, s[12:15], 12 offen
	v_add_u32_e32 v62, s28, v66
	v_lshlrev_b32_e32 v63, 1, v62
	s_waitcnt lgkmcnt(1)
	buffer_atomic_pk_add_bf16 v58, v63, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v59, v63, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v60, v63, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v61, v63, s[12:15], 12 offen
	v_add_lshl_u32 v58, v62, s28, 1
	s_waitcnt lgkmcnt(0)
	buffer_atomic_pk_add_bf16 v54, v58, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v55, v58, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v56, v58, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v57, v58, s[12:15], 12 offen
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b64 v81, v[18:19]
	ds_write_b64 v80, v[20:21]
	ds_write_b64 v79, v[22:23]
	ds_write_b64 v78, v[24:25]
	ds_write_b64 v77, v[26:27]
	ds_write_b64 v76, v[28:29]
	ds_write_b64 v75, v[30:31]
	ds_write_b64 v74, v[32:33]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[66:69], v71
	ds_read_b128 v[62:65], v71 offset:516
	ds_read_b128 v[58:61], v71 offset:1032
	ds_read_b128 v[54:57], v71 offset:1548
	v_add_u32_e32 v72, 64, v53
	v_mad_u64_u32 v[72:73], s[0:1], v72, s28, v[70:71]
	v_lshlrev_b32_e32 v73, 1, v72
	s_waitcnt lgkmcnt(3)
	buffer_atomic_pk_add_bf16 v66, v73, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v67, v73, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v68, v73, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v69, v73, s[12:15], 12 offen
	v_add_u32_e32 v66, s28, v72
	v_lshlrev_b32_e32 v67, 1, v66
	s_waitcnt lgkmcnt(2)
	buffer_atomic_pk_add_bf16 v62, v67, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v63, v67, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v64, v67, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v65, v67, s[12:15], 12 offen
	v_add_u32_e32 v62, s28, v66
	v_lshlrev_b32_e32 v63, 1, v62
	s_waitcnt lgkmcnt(1)
	buffer_atomic_pk_add_bf16 v58, v63, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v59, v63, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v60, v63, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v61, v63, s[12:15], 12 offen
	v_add_lshl_u32 v58, v62, s28, 1
	s_waitcnt lgkmcnt(0)
	buffer_atomic_pk_add_bf16 v54, v58, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v55, v58, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v56, v58, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v57, v58, s[12:15], 12 offen
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b64 v81, v[2:3]
	ds_write_b64 v80, v[4:5]
	ds_write_b64 v79, v[6:7]
	ds_write_b64 v78, v[8:9]
	ds_write_b64 v77, v[10:11]
	ds_write_b64 v76, v[12:13]
	ds_write_b64 v75, v[14:15]
	ds_write_b64 v74, v[16:17]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[66:69], v71
	ds_read_b128 v[62:65], v71 offset:516
	ds_read_b128 v[58:61], v71 offset:1032
	ds_read_b128 v[54:57], v71 offset:1548
	v_add_u32_e32 v53, 0x80, v53
	v_mad_u64_u32 v[70:71], s[0:1], v53, s28, v[70:71]
	v_lshlrev_b32_e32 v53, 1, v70
	s_waitcnt lgkmcnt(3)
	buffer_atomic_pk_add_bf16 v66, v53, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v67, v53, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v68, v53, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v69, v53, s[12:15], 12 offen
	v_add_u32_e32 v53, s28, v70
	v_lshlrev_b32_e32 v66, 1, v53
	s_waitcnt lgkmcnt(2)
	buffer_atomic_pk_add_bf16 v62, v66, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v63, v66, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v64, v66, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v65, v66, s[12:15], 12 offen
	v_add_u32_e32 v53, s28, v53
	v_lshlrev_b32_e32 v62, 1, v53
	s_waitcnt lgkmcnt(1)
	buffer_atomic_pk_add_bf16 v58, v62, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v59, v62, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v60, v62, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v61, v62, s[12:15], 12 offen
	v_add_lshl_u32 v53, v53, s28, 1
	s_waitcnt lgkmcnt(0)
	buffer_atomic_pk_add_bf16 v54, v53, s[12:15], 0 offen
	buffer_atomic_pk_add_bf16 v55, v53, s[12:15], 4 offen
	buffer_atomic_pk_add_bf16 v56, v53, s[12:15], 8 offen
	buffer_atomic_pk_add_bf16 v57, v53, s[12:15], 12 offen
	s_mov_b64 vcc, exec
	s_cbranch_execnz .LBB19_21
.LBB19_23:
	v_readfirstlane_b32 s0, v0
	s_lshr_b32 s1, s0, 1
	s_and_b32 s1, s1, 0x7fffff80
	v_or_b32_e32 v52, s1, v52
	v_ashrrev_i32_e32 v0, 31, v52
	v_lshrrev_b32_e32 v0, 29, v0
	v_add_u32_e32 v0, v52, v0
	v_lshrrev_b32_e32 v55, 3, v0
	v_and_b32_e32 v0, -8, v0
	v_sub_u32_e32 v54, v52, v0
	s_lshr_b32 s1, s0, 2
	v_and_or_b32 v1, s1, 48, v1
	v_mul_u32_u24_e32 v1, 0x102, v1
	v_add3_u32 v0, v54, v1, v0
	s_barrier
	v_lshlrev_b32_e32 v60, 1, v0
	ds_write_b64 v60, v[48:49]
	v_add_u32_e32 v48, 16, v52
	v_ashrrev_i32_e32 v1, 31, v48
	v_lshrrev_b32_e32 v1, 29, v1
	v_add_u32_e32 v49, v48, v1
	v_ashrrev_i32_e32 v53, 3, v49
	v_sub_u32_e32 v1, v53, v55
	v_and_b32_e32 v49, -8, v49
	v_sub_u32_e32 v49, v48, v49
	v_lshlrev_b32_e32 v1, 3, v1
	v_sub_u32_e32 v48, v49, v54
	v_add3_u32 v1, v48, v0, v1
	v_lshlrev_b32_e32 v59, 1, v1
	ds_write_b64 v59, v[46:47]
	v_add_u32_e32 v47, 32, v52
	v_ashrrev_i32_e32 v0, 31, v47
	v_lshrrev_b32_e32 v0, 29, v0
	v_add_u32_e32 v48, v47, v0
	v_ashrrev_i32_e32 v0, 3, v48
	v_sub_u32_e32 v46, v0, v53
	v_and_b32_e32 v48, -8, v48
	v_sub_u32_e32 v48, v47, v48
	v_sub_u32_e32 v47, v48, v49
	v_lshl_add_u32 v47, v46, 3, v47
	v_lshl_add_u32 v58, v47, 1, v59
	ds_write_b64 v58, v[44:45]
	v_add_u32_e32 v44, 48, v52
	v_ashrrev_i32_e32 v45, 31, v44
	v_lshrrev_b32_e32 v45, 29, v45
	v_add_u32_e32 v45, v44, v45
	v_ashrrev_i32_e32 v46, 3, v45
	v_sub_u32_e32 v0, v46, v0
	v_and_b32_e32 v45, -8, v45
	v_sub_u32_e32 v45, v44, v45
	v_sub_u32_e32 v44, v45, v48
	v_lshl_add_u32 v0, v0, 3, v44
	v_add3_u32 v1, v47, v1, v0
	v_lshl_add_u32 v57, v0, 1, v58
	ds_write_b64 v57, v[42:43]
	v_add_u32_e32 v43, 64, v52
	v_ashrrev_i32_e32 v0, 31, v43
	v_lshrrev_b32_e32 v0, 29, v0
	v_add_u32_e32 v44, v43, v0
	v_ashrrev_i32_e32 v0, 3, v44
	v_sub_u32_e32 v42, v0, v46
	v_and_b32_e32 v44, -8, v44
	v_sub_u32_e32 v44, v43, v44
	v_sub_u32_e32 v43, v44, v45
	v_lshl_add_u32 v43, v42, 3, v43
	v_lshl_add_u32 v56, v43, 1, v57
	ds_write_b64 v56, v[40:41]
	v_add_u32_e32 v40, 0x50, v52
	v_ashrrev_i32_e32 v41, 31, v40
	v_lshrrev_b32_e32 v41, 29, v41
	v_add_u32_e32 v41, v40, v41
	v_ashrrev_i32_e32 v42, 3, v41
	v_sub_u32_e32 v0, v42, v0
	v_and_b32_e32 v41, -8, v41
	v_sub_u32_e32 v41, v40, v41
	v_sub_u32_e32 v40, v41, v44
	v_lshl_add_u32 v0, v0, 3, v40
	v_add3_u32 v40, v43, v1, v0
	v_lshl_add_u32 v55, v0, 1, v56
	ds_write_b64 v55, v[38:39]
	v_add_u32_e32 v0, 0x60, v52
	v_ashrrev_i32_e32 v1, 31, v0
	v_lshrrev_b32_e32 v1, 29, v1
	v_add_u32_e32 v39, v0, v1
	v_ashrrev_i32_e32 v1, 3, v39
	v_sub_u32_e32 v38, v1, v42
	v_and_b32_e32 v39, -8, v39
	v_sub_u32_e32 v0, v0, v39
	v_sub_u32_e32 v39, v0, v41
	v_lshl_add_u32 v38, v38, 3, v39
	v_lshl_add_u32 v54, v38, 1, v55
	ds_write_b64 v54, v[36:37]
	v_add_u32_e32 v36, 0x70, v52
	v_ashrrev_i32_e32 v37, 31, v36
	v_lshrrev_b32_e32 v37, 29, v37
	v_add_u32_e32 v37, v36, v37
	v_lshrrev_b32_e32 v39, 3, v37
	v_sub_u32_e32 v1, v39, v1
	v_and_b32_e32 v37, 0x7ffffff8, v37
	v_sub_u32_e32 v36, v36, v37
	v_sub_u32_e32 v0, v36, v0
	v_lshlrev_b32_e32 v0, 1, v0
	v_lshlrev_b32_e32 v1, 4, v1
	v_add_lshl_u32 v36, v38, v40, 1
	v_add3_u32 v53, v0, v1, v36
	ds_write_b64 v53, v[34:35]
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_and_b32_e32 v0, 0xf8, v51
	s_lshr_b32 s0, s0, 3
	s_and_b32 s0, s0, 0x1ffffff8
	v_add_u32_e32 v1, s0, v50
	s_movk_i32 s0, 0x204
	v_mul_lo_u32 v34, v1, s0
	v_lshl_add_u32 v52, v0, 1, v34
	ds_read_b128 v[46:49], v52
	ds_read_b128 v[42:45], v52 offset:516
	ds_read_b128 v[38:41], v52 offset:1032
	ds_read_b128 v[34:37], v52 offset:1548
	v_add_u32_e32 v51, s33, v1
	v_or_b32_e32 v50, s2, v0
	v_mad_u64_u32 v[0:1], s[0:1], v51, s28, v[50:51]
	s_lshl_b32 s14, s3, 1
	s_mov_b32 s15, 0x20000
	v_lshlrev_b32_e32 v1, 1, v0
	s_waitcnt lgkmcnt(3)
	buffer_store_dwordx2 v[46:47], v1, s[12:15], 0 offen
	buffer_store_dwordx2 v[48:49], v1, s[12:15], 8 offen
	v_add_u32_e32 v0, s28, v0
	v_lshlrev_b32_e32 v1, 1, v0
	s_waitcnt lgkmcnt(2)
	buffer_store_dwordx2 v[42:43], v1, s[12:15], 0 offen
	buffer_store_dwordx2 v[44:45], v1, s[12:15], 8 offen
	v_add_u32_e32 v0, s28, v0
	v_lshlrev_b32_e32 v1, 1, v0
	s_waitcnt lgkmcnt(1)
	buffer_store_dwordx2 v[38:39], v1, s[12:15], 0 offen
	buffer_store_dwordx2 v[40:41], v1, s[12:15], 8 offen
	v_add_lshl_u32 v0, v0, s28, 1
	s_waitcnt lgkmcnt(0)
	buffer_store_dwordx2 v[34:35], v0, s[12:15], 0 offen
	buffer_store_dwordx2 v[36:37], v0, s[12:15], 8 offen
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b64 v60, v[18:19]
	ds_write_b64 v59, v[20:21]
	ds_write_b64 v58, v[22:23]
	ds_write_b64 v57, v[24:25]
	ds_write_b64 v56, v[26:27]
	ds_write_b64 v55, v[28:29]
	ds_write_b64 v54, v[30:31]
	ds_write_b64 v53, v[32:33]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[30:33], v52
	ds_read_b128 v[26:29], v52 offset:516
	ds_read_b128 v[22:25], v52 offset:1032
	ds_read_b128 v[18:21], v52 offset:1548
	v_add_u32_e32 v0, 64, v51
	v_mad_u64_u32 v[0:1], s[0:1], v0, s28, v[50:51]
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
	ds_write_b64 v60, v[2:3]
	ds_write_b64 v59, v[4:5]
	ds_write_b64 v58, v[6:7]
	ds_write_b64 v57, v[8:9]
	ds_write_b64 v56, v[10:11]
	ds_write_b64 v55, v[12:13]
	ds_write_b64 v54, v[14:15]
	ds_write_b64 v53, v[16:17]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[12:15], v52
	ds_read_b128 v[8:11], v52 offset:516
	ds_read_b128 v[4:7], v52 offset:1032
	ds_read_b128 v[0:3], v52 offset:1548
	v_add_u32_e32 v16, 0x80, v51
	v_mad_u64_u32 v[16:17], s[0:1], v16, s28, v[50:51]
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
		.amdhsa_group_segment_fixed_size 114720
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
		.amdhsa_next_free_vgpr 229
		.amdhsa_next_free_sgpr 96
		.amdhsa_accum_offset 232
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
	.set \symbol\().num_vgpr, 229
	.set \symbol\().num_agpr, 0
	.set \symbol\().numbered_sgpr, 58
	.set \symbol\().num_named_barrier, 0
	.set \symbol\().private_seg_size, 0
	.set \symbol\().uses_vcc, 1
	.set \symbol\().uses_flat_scratch, 0
	.set \symbol\().has_dyn_sized_stack, 0
	.set \symbol\().has_recursion, 0
	.set \symbol\().has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 15032
; TotalNumSgprs: 64
; NumVgprs: 229
; NumAgprs: 0
; TotalNumVgprs: 229
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 192
; IeeeMode: 1
; LDSByteSize: 114720 bytes/workgroup (compile time only)
; SGPRBlocks: 12
; VGPRBlocks: 28
; NumSGPRsForWavesPerEU: 102
; NumVGPRsForWavesPerEU: 229
; AccumOffset: 232
; Occupancy: 2
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 57
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
    .group_segment_fixed_size: 114720
    .kernarg_segment_align: 8
    .kernarg_segment_size: 88
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 512
    .name:           \symbol
    .private_segment_fixed_size: 0
    .sgpr_count:     64
    .sgpr_spill_count: 0
    .symbol:         \symbol\().kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     227
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...
	.end_amdgpu_metadata
	.endm
