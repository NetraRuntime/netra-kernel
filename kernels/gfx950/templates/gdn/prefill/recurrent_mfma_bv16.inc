// Netra model-independent fixed-contract tactic template.
	.include "kernels/gfx950/templates/common/primitives.inc"
// SPDX-License-Identifier: MIT
//
// Raw gfx950 Qwen3.6 GDN prefill recurrence, re-derived for CDNA4 wave64.
// The 16-row V tile launches 256 workgroups, matching the 256 physical CUs,
// and native 16x16x32 BF16 MFMA performs both recurrent matrix products.  A
// three-stage LDS pipeline overlaps the next W/K tiles with the current MFMA;
// this was selected by exact real-checkpoint, interleaved HIP-event timing.
//
// Exact shape gate:
//   B=1, T=8192, H=32, Hg=16, K=V=128, BT=64, BV=16
//   grid=(8,32,1), block=(256,1,1), dynamic LDS=103,296 bytes
// Reference Triton code-object hash:
//   ff6bfca27b67d23b1fab866d2278958f73fd920fc06e58944855e7d833e80244

	NETRA_GFX950_MODULE_HEADER 5
	.macro NETRA_GDN_PREFILL_MFMA_BV16 symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_M, 8192
	NETRA_REQUIRE_EQ NETRA_HEADS, 32
	NETRA_REQUIRE_EQ NETRA_GROUP_HEADS, 16
	NETRA_REQUIRE_EQ NETRA_K, 128
	NETRA_REQUIRE_EQ NETRA_V, 128
	NETRA_REQUIRE_EQ NETRA_BLOCK_V, 16
	NETRA_REQUIRE_EQ NETRA_SCALE_BLOCK, 128
	NETRA_KERNEL_ENTRY \symbol, 0 // -- Begin function \symbol
.Lfunc_begin0:
; %bb.34:
	NETRA_LOAD_KERNARG_PTR s[2:3], 0x0
	NETRA_LOAD_KERNARG_U32X8 s[4:11], 0x8
	NETRA_LOAD_KERNARG_U32X4 s[12:15], 0x28
	NETRA_WAIT_LGKM0
	s_branch .LBB0_0
.Ltmp0:
	.p2align	8
; %bb.35:
.LBB0_0:
	s_mov_b64 s[36:37], s[2:3]
	s_load_dwordx4 s[20:23], s[0:1], 0x38
	s_load_dwordx2 s[2:3], s[0:1], 0x48
.Ltmp1:
	s_ashr_i32 s0, s17, 31
	s_lshr_b32 s0, s0, 27
	s_add_i32 s0, s17, s0
	s_ashr_i32 s46, s0, 5
	s_mov_b64 s[24:25], s[14:15]
	v_readfirstlane_b32 s15, v0
	s_andn2_b32 s0, s0, 31
	s_ashr_i32 s47, s46, 31
	s_bfe_u32 s62, s15, 0x20006
	s_sub_i32 s14, s17, s0
	s_lshl_b64 s[0:1], s[46:47], 2
	s_mov_b64 s[28:29], s[6:7]
	NETRA_WAIT_LGKM0
	s_add_u32 s6, s22, s0
	s_addc_u32 s7, s23, s1
	s_load_dwordx2 s[56:57], s[6:7], 0x0
	s_lshl_b64 s[6:7], s[46:47], 3
	v_and_b32_e32 v1, 63, v0
	v_and_b32_e32 v28, 15, v0
	v_lshlrev_b32_e32 v5, 2, v28
	NETRA_WAIT_LGKM0
	s_sub_i32 s50, s57, s56
.Ltmp2:
	s_add_i32 s64, s50, 63
.Ltmp3:
	s_add_u32 s2, s2, s6
	s_addc_u32 s3, s3, s7
	s_lshl_b32 s47, s56, 5
	s_add_i32 s47, s47, s14
	s_lshl_b32 s66, s14, 14
	s_lshl_b32 s33, s47, 7
	s_add_u32 s0, s20, s0
	s_addc_u32 s1, s21, s1
	s_load_dword s6, s[0:1], 0x0
	s_load_dwordx2 s[48:49], s[2:3], 0x0
	s_lshl_b32 s58, s16, 4
	s_lshl_b32 s57, s62, 6
	s_ashr_i32 s59, s58, 31
	NETRA_WAIT_LGKM0
	s_lshl_b32 s0, s6, 19
	v_or_b32_e32 v23, s57, v1
	s_add_i32 s0, s0, s66
	v_lshrrev_b32_e32 v4, 4, v23
	s_lshl_b64 s[34:35], s[58:59], 7
	v_or_b32_e32 v2, s58, v4
	v_mov_b32_e32 v3, s59
	v_lshl_or_b32 v4, v4, 7, v5
	s_cmp_gt_i32 s58, -1
	s_mov_b64 s[6:7], 0x80
	v_or_b32_e32 v5, s0, v4
	s_cselect_b64 s[44:45], -1, 0
	v_cmp_gt_i64_e32 vcc, s[6:7], v[2:3]
	s_mov_b32 s31, 0x27000
	s_mov_b32 s30, 0x7ffffffe
	v_add_lshl_u32 v2, v5, s34, 1
	v_bfrev_b32_e32 v14, 1
	s_and_b64 s[2:3], s[44:45], vcc
	s_and_b32 s25, s25, 0xffff
	s_mov_b32 s26, s30
	s_mov_b32 s27, s31
	v_cndmask_b32_e64 v32, v14, v2, s[2:3]
	buffer_load_dwordx2 v[10:11], v32, s[24:27], 0 offen
	s_and_b32 s63, s15, 64
	s_lshr_b32 s67, s63, 5
	s_cmp_lt_u32 s62, 2
	s_cselect_b64 s[60:61], -1, 0
	v_bfe_i32 v2, v0, 5, 1
	s_and_b64 s[0:1], s[60:61], exec
	v_and_b32_e32 v25, 16, v0
	v_lshlrev_b32_e32 v3, 3, v28
	v_and_b32_e32 v2, 0x84, v2
	s_cselect_b32 s0, 0, 0x200
	v_lshlrev_b32_e32 v39, 6, v25
	s_or_b32 s35, s34, 64
	v_or3_b32 v2, v2, s0, v3
	v_add_lshl_u32 v3, v5, s35, 1
	v_or3_b32 v2, v2, s67, v39
	v_cndmask_b32_e64 v33, v14, v3, s[2:3]
	v_add_u32_e32 v3, 0, v2
	v_xad_u32 v7, v2, 4, 0
	v_xad_u32 v9, v2, 32, 0
	v_xad_u32 v2, v2, 36, 0
	v_and_b32_e32 v30, 3, v0
	v_lshlrev_b32_e32 v22, 2, v30
	v_or_b32_e32 v16, s58, v22
	v_mov_b32_e32 v17, s59
	v_lshrrev_b32_e32 v34, 1, v0
	v_cmp_gt_i64_e64 s[6:7], s[6:7], v[16:17]
	v_lshlrev_b32_e32 v5, 3, v0
	v_and_b32_e32 v36, 12, v0
	v_bfe_i32 v6, v0, 1, 1
	v_and_b32_e32 v29, 28, v34
	s_lshl_b32 s49, s62, 5
	s_ashr_i32 s51, s50, 31
	s_and_b64 s[52:53], s[44:45], s[6:7]
	v_and_b32_e32 v35, 32, v0
	v_lshlrev_b32_e32 v12, 1, v36
	v_and_b32_e32 v18, 0x120, v6
	v_lshrrev_b32_e32 v8, 3, v25
	v_or_b32_e32 v6, s62, v29
	s_cmp_gt_i32 s64, 63
	v_lshlrev_b32_e32 v37, 4, v35
	s_mul_i32 s69, s62, 0x420
	v_cmp_gt_i32_e32 vcc, s50, v6
	v_bitop3_b32 v12, s49, v18, v12 bitop3:0x36
	s_cselect_b64 s[22:23], -1, 0
	s_add_i32 s15, s69, 0
	s_and_b64 vcc, vcc, s[22:23]
	s_and_b32 s29, s29, 0xffff
	s_add_i32 s6, s15, 0x1080
	s_mov_b32 m0, s15
	s_add_i32 s7, s15, 0x62e0
	s_add_i32 s18, s15, 0x7360
	s_and_b32 s5, s5, 0xffff
	v_mov_b32_e32 v38, 0
	NETRA_WAIT_VM0
	ds_write_b16 v3, v10
	ds_write_b16_d16_hi v7, v10
	ds_write_b16 v9, v11 offset:256
	ds_write_b16_d16_hi v2, v11 offset:256
	v_and_b32_e32 v11, 1, v0
	v_and_b32_e32 v10, 56, v5
	v_lshl_or_b32 v19, v11, 2, v8
	v_or_b32_e32 v8, 32, v6
	v_lshl_or_b32 v13, v6, 12, v10
	v_lshl_or_b32 v15, v8, 12, v10
	v_cmp_gt_i32_e64 s[0:1], s50, v8
	v_add_lshl_u32 v13, v13, s33, 1
	v_or3_b32 v12, v12, v19, v37
	v_add_lshl_u32 v15, v15, s33, 1
	v_add_u32_e32 v18, 0, v12
	v_cndmask_b32_e32 v19, v14, v13, vcc
	s_and_b64 s[0:1], s[0:1], s[22:23]
	v_or_b32_e32 v20, 0x80, v13
	v_xad_u32 v12, v12, 4, 0
	v_cndmask_b32_e64 v24, v14, v15, s[0:1]
	v_or_b32_e32 v21, 0x80, v15
	v_cndmask_b32_e32 v20, v14, v20, vcc
	v_cndmask_b32_e64 v21, v14, v21, s[0:1]
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	buffer_load_dwordx2 v[26:27], v33, s[24:27], 0 offen
	ds_read_u16 v40, v18
	ds_read_u16 v42, v18 offset:1024
	ds_read_u16 v41, v12 offset:128
	ds_read_u16 v43, v12 offset:1152
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	NETRA_WAIT_VM0
	ds_write_b16 v3, v26
	ds_write_b16_d16_hi v7, v26
	ds_write_b16 v9, v27 offset:256
	ds_write_b16_d16_hi v2, v27 offset:256
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_u16 v44, v18
	ds_read_u16 v47, v18 offset:1024
	ds_read_u16 v46, v12 offset:128
	ds_read_u16 v48, v12 offset:1152
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	buffer_load_dwordx4 v19, s[28:31], 0 offen lds
	s_mov_b32 m0, s6
	s_add_i32 s6, s58, s33
	buffer_load_dwordx4 v24, s[28:31], 0 offen lds
	s_mov_b32 m0, s7
	v_mov_b32_e32 v3, 0
	buffer_load_dwordx4 v20, s[28:31], 0 offen lds
	s_mov_b32 m0, s18
	v_lshrrev_b32_e32 v20, 2, v23
	buffer_load_dwordx4 v21, s[28:31], 0 offen lds
	v_cmp_gt_i32_e32 vcc, s50, v20
	v_lshlrev_b32_e32 v24, 12, v20
	s_and_b64 s[0:1], s[52:53], vcc
	v_or_b32_e32 v2, v24, v22
	s_add_i32 s18, s15, 0x80
	v_add_lshl_u32 v26, s6, v2, 1
	s_and_b64 vcc, s[22:23], s[0:1]
	v_mov_b32_e32 v7, v3
	v_mov_b32_e32 v9, v3
	v_mov_b32_e32 v21, v3
	s_cmp_lt_i32 s64, 64
	s_mov_b32 s6, s30
	s_mov_b32 s7, s31
	v_cndmask_b32_e32 v2, v14, v26, vcc
	s_cbranch_scc1 .LBB0_2
; %bb.1:
	s_min_u32 s0, s50, 64
	s_lshl_b32 s0, s0, 5
	s_add_i32 s0, s47, s0
	s_sub_i32 s0, s0, 32
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s0, s10, s0
	s_addc_u32 s1, s11, s1
	v_mov_b32_e32 v12, 0
	global_load_dword v38, v12, s[0:1]
.LBB0_2:
	s_bfe_u32 s0, s14, 0x10007
	s_add_i32 s14, s14, s0
	s_bfe_i32 s0, s14, 0x80000
	s_sext_i32_i16 s0, s0
	s_ashr_i32 s70, s0, 1
	s_lshl_b32 s0, s56, 11
	s_lshl_b32 s1, s70, 7
	s_lshl_b32 s65, s62, 4
	s_lshl_b32 s71, s62, 10
	s_add_i32 s14, s0, s1
	v_lshrrev_b32_e32 v60, 2, v25
	v_lshrrev_b32_e32 v61, 1, v35
	v_or_b32_e32 v12, s65, v28
	s_or_b32 s0, s71, 0x1000
	buffer_load_dwordx2 v[18:19], v2, s[4:7], 0 offen
	v_and_b32_e32 v31, 8, v0
	v_or_b32_e32 v2, v61, v60
	v_cmp_gt_i32_e32 vcc, s50, v12
	s_lshr_b32 s79, s0, 5
	v_lshlrev_b32_e32 v27, 7, v12
	v_or3_b32 v2, v2, v31, s62
	s_or_b32 s26, s79, s0
	v_lshl_add_u32 v50, s47, 2, v27
	s_and_b64 s[0:1], vcc, s[22:23]
	v_or_b32_e32 v53, 32, v2
	s_and_b32 s41, s11, 0xffff
	s_mov_b32 s40, s10
	s_mov_b32 s42, s30
	s_mov_b32 s43, s31
	v_cndmask_b32_e64 v27, v14, v50, s[0:1]
	v_lshl_or_b32 v45, v2, 11, v10
	v_cmp_gt_i32_e64 s[0:1], s50, v2
	buffer_load_dword v51, v27, s[40:43], 0 offen
	v_lshlrev_b32_e32 v27, 11, v53
	v_or_b32_e32 v49, s14, v10
	v_cmp_gt_i32_e64 s[6:7], s50, v53
	v_add_lshl_u32 v10, v45, s14, 1
	s_and_b64 s[0:1], s[0:1], s[22:23]
	s_and_b32 s37, s37, 0xffff
	s_mov_b32 s38, s30
	s_mov_b32 s39, s31
	s_add_i32 m0, s15, 0xc5c0
	v_cndmask_b32_e64 v45, v14, v10, s[0:1]
	v_add_lshl_u32 v49, v49, v27, 1
	s_and_b64 s[6:7], s[6:7], s[22:23]
	buffer_load_dwordx4 v45, s[36:39], 0 offen lds
	s_add_i32 m0, s18, 0xd5c0
	v_cndmask_b32_e64 v27, v14, v49, s[6:7]
	s_add_i32 s68, 0, 0x128a0
	buffer_load_dwordx4 v27, s[36:39], 0 offen lds
	s_add_i32 s20, s68, s69
	v_or_b32_e32 v27, 0x80, v10
	v_cndmask_b32_e64 v27, v14, v27, s[0:1]
	s_mov_b32 m0, s20
	v_or_b32_e32 v6, 64, v6
	buffer_load_dwordx4 v27, s[36:39], 0 offen lds
	s_add_i32 m0, s68, s26
	v_or_b32_e32 v27, 0x80, v49
	s_cmpk_gt_i32 s64, 0x7f
	v_cndmask_b32_e64 v27, v14, v27, s[6:7]
	s_cselect_b64 s[0:1], -1, 0
	v_cmp_gt_i64_e64 s[6:7], s[50:51], v[6:7]
	v_or_b32_e32 v8, 64, v8
	v_add_u32_e32 v6, 0x80000, v13
	s_and_b64 s[6:7], s[0:1], s[6:7]
	buffer_load_dwordx4 v27, s[36:39], 0 offen lds
	v_cmp_gt_i64_e64 s[14:15], s[50:51], v[8:9]
	s_add_i32 m0, s20, 0xfffef860
	v_cndmask_b32_e64 v6, v14, v6, s[6:7]
	s_add_i32 s18, s20, 0xffff08e0
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	buffer_load_dwordx4 v6, s[28:31], 0 offen lds
	v_add_u32_e32 v6, 0x80000, v15
	s_and_b64 s[14:15], s[0:1], s[14:15]
	v_cndmask_b32_e64 v6, v14, v6, s[14:15]
	s_mov_b32 m0, s18
	s_add_i32 s19, s20, 0xffff5b40
	buffer_load_dwordx4 v6, s[28:31], 0 offen lds
	v_add_u32_e32 v6, 0x80080, v13
	v_cndmask_b32_e64 v6, v14, v6, s[6:7]
	s_mov_b32 m0, s19
	s_add_i32 s21, s20, 0xffff6bc0
	buffer_load_dwordx4 v6, s[28:31], 0 offen lds
	v_add_u32_e32 v6, 0x80080, v15
	v_cndmask_b32_e64 v6, v14, v6, s[14:15]
	s_mov_b32 m0, s21
	v_or_b32_e32 v20, 64, v20
	buffer_load_dwordx4 v6, s[28:31], 0 offen lds
	v_cmp_gt_i64_e64 s[6:7], s[50:51], v[20:21]
	s_and_b64 s[6:7], s[52:53], s[6:7]
	s_add_i32 s38, s20, 0xfffed760
	s_add_i32 s27, s20, 0xfffed7e0
	v_add_u32_e32 v6, 0x80000, v26
	s_and_b64 s[6:7], s[0:1], s[6:7]
	v_cmp_eq_u32_e64 s[18:19], 0, v35
	v_mov_b32_e32 v13, v3
	s_cmpk_lt_i32 s64, 0x80
	v_cndmask_b32_e64 v6, v14, v6, s[6:7]
	s_mov_b32 s6, s30
	s_mov_b32 s7, s31
	v_mov_b32_e32 v45, v3
	s_cbranch_scc1 .LBB0_4
; %bb.3:
	s_min_u32 s14, s50, 0x80
	s_lshl_b32 s14, s14, 5
	s_add_i32 s14, s47, s14
	s_sub_i32 s14, s14, 32
	s_ashr_i32 s15, s14, 31
	s_lshl_b64 s[14:15], s[14:15], 2
	s_add_u32 s14, s10, s14
	s_addc_u32 s15, s11, s15
	v_mov_b32_e32 v7, 0
	global_load_dword v45, v7, s[14:15]
.LBB0_4:
	v_or_b32_e32 v12, 64, v12
	buffer_load_dwordx2 v[14:15], v6, s[4:7], 0 offen
	v_cmp_gt_i64_e64 s[6:7], s[50:51], v[12:13]
	v_or_b32_e32 v2, 64, v2
	v_add_u32_e32 v6, 0x2000, v50
	v_bfrev_b32_e32 v7, 1
	s_and_b64 s[14:15], s[0:1], s[6:7]
	v_cndmask_b32_e64 v6, v7, v6, s[14:15]
	v_cmp_gt_i64_e64 s[14:15], s[50:51], v[2:3]
	v_add_u32_e32 v26, 64, v53
	v_mov_b32_e32 v27, 0
	v_add_u32_e32 v2, 0x40000, v10
	s_and_b64 s[14:15], s[0:1], s[14:15]
	v_cmp_gt_i64_e64 s[20:21], s[50:51], v[26:27]
	s_add_i32 m0, s38, 0xe6c0
	v_cndmask_b32_e64 v2, v7, v2, s[14:15]
	s_mov_b32 s38, s30
	s_mov_b32 s39, s31
	buffer_load_dwordx4 v2, s[36:39], 0 offen lds
	v_add_u32_e32 v2, 0x40000, v49
	s_and_b64 s[20:21], s[0:1], s[20:21]
	s_add_i32 m0, s27, 0xf6c0
	v_cndmask_b32_e64 v2, v7, v2, s[20:21]
	buffer_load_dwordx4 v2, s[36:39], 0 offen lds
	s_add_i32 s75, 0, 0x149a0
	v_add_u32_e32 v2, 0x40080, v10
	s_add_i32 m0, s75, s69
	v_cndmask_b32_e64 v2, v7, v2, s[14:15]
	s_mov_b32 s40, s10
	s_mov_b32 s42, s30
	s_mov_b32 s43, s31
	buffer_load_dwordx4 v2, s[36:39], 0 offen lds
	v_add_u32_e32 v2, 0x40080, v49
	buffer_load_dword v52, v6, s[40:43], 0 offen
	s_add_i32 m0, s75, s26
	v_cndmask_b32_e64 v2, v7, v2, s[20:21]
	buffer_load_dwordx4 v2, s[36:39], 0 offen lds
.Ltmp4:
	s_ashr_i32 s14, s64, 31
	s_lshr_b32 s14, s14, 26
.Ltmp5:
	v_and_b32_e32 v54, 48, v0
.Ltmp6:
	s_add_i32 s14, s64, s14
.Ltmp7:
	v_lshrrev_b32_e32 v6, 2, v54
.Ltmp8:
	s_ashr_i32 s73, s14, 6
.Ltmp9:
	v_or_b32_e32 v56, s58, v6
	v_mov_b32_e32 v57, s59
	s_mov_b64 s[14:15], 0x80
	v_lshlrev_b32_e32 v7, 16, v42
	v_lshlrev_b32_e32 v6, 16, v40
	v_cmp_gt_i64_e64 s[14:15], s[14:15], v[56:57]
	v_and_b32_e32 v2, 2, v0
	v_cmp_eq_u32_e64 s[20:21], 0, v11
	v_lshlrev_b32_e32 v9, 16, v43
	v_lshlrev_b32_e32 v8, 16, v41
	v_pk_add_f32 v[10:11], v[6:7], 0 op_sel_hi:[1,0]
	v_lshlrev_b32_e32 v7, 16, v47
	v_lshlrev_b32_e32 v6, 16, v44
	v_lshlrev_b32_e32 v41, 16, v48
	v_lshlrev_b32_e32 v40, 16, v46
	s_and_b64 s[54:55], s[44:45], s[14:15]
	s_mov_b32 s72, 0
	v_pk_add_f32 v[8:9], v[8:9], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[12:13], v[6:7], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[6:7], v[40:41], 0 op_sel_hi:[1,0]
	s_cmpk_gt_i32 s64, 0xbf
	v_lshlrev_b32_e32 v66, 2, v36
	v_lshlrev_b32_e32 v67, 1, v2
	v_lshrrev_b32_e32 v68, 2, v35
	v_lshlrev_b32_e32 v65, 4, v23
	v_and_b32_e32 v62, 2, v34
	v_lshlrev_b32_e32 v63, 3, v31
	v_lshlrev_b32_e32 v64, 5, v25
	v_lshlrev_b32_e32 v59, 10, v30
	v_lshlrev_b32_e32 v58, 5, v23
	v_lshlrev_b32_e32 v56, 5, v54
	v_lshlrev_b32_e32 v57, 1, v1
	v_lshlrev_b32_e32 v55, 7, v28
	s_waitcnt vmcnt(8) lgkmcnt(0)
	NETRA_BARRIER
	s_cbranch_scc1 .LBB0_6
; %bb.5:                                ; %.._crit_edge_crit_edge
	v_mov_b32_e32 v25, v3
	v_lshlrev_b32_e32 v26, 12, v20
	v_mov_b32_e32 v2, 0x140
	s_and_b64 s[14:15], s[60:61], exec
	v_lshl_add_u64 v[20:21], v[26:27], 0, v[16:17]
	v_lshl_add_u64 v[16:17], v[24:25], 0, v[16:17]
	v_cndmask_b32_e64 v2, v2, 0, s[20:21]
	s_cselect_b32 s14, 0, 64
	v_bitop3_b32 v2, s14, v2, v66 bitop3:0x1e
	v_mov_b32_e32 v17, 0x88
	v_or3_b32 v50, v68, v67, v2
	v_and_b32_e32 v2, 0x430, v65
	v_cndmask_b32_e64 v17, v17, 0, s[18:19]
	s_cselect_b32 s14, 0, 8
	s_movk_i32 s26, 0x140
	v_or3_b32 v21, v62, v63, v64
	v_bitop3_b32 v2, v2, s14, v17 bitop3:0x36
	v_or_b32_e32 v34, v2, v21
	v_bitop3_b32 v35, v2, s26, v21 bitop3:0x36
	v_lshl_or_b32 v2, s63, 3, v59
	s_movk_i32 s26, 0x1180
	v_and_or_b32 v2, v58, s26, v2
	v_or_b32_e32 v17, v2, v54
	v_lshrrev_b32_e32 v2, 5, v2
	v_and_b32_e32 v2, 0xe0, v2
	s_movk_i32 s26, 0x70
	v_add_u32_e32 v40, v2, v17
	v_bitop3_b32 v48, s49, v56, v57 bitop3:0x1e
	v_and_b32_e32 v2, 0x70, v5
	v_bitop3_b32 v17, v5, v54, s26 bitop3:0x6c
	s_mov_b32 s15, 0x27000
	s_mov_b32 s14, 0x7ffffffe
	s_and_b32 s45, s13, 0xffff
	s_mov_b32 s44, s12
	v_add_u32_e32 v41, 64, v40
	v_xor_b32_e32 v49, 0x110, v48
	v_bitop3_b32 v42, v2, v55, v54 bitop3:0xde
	v_bitop3_b32 v43, v17, 64, v55 bitop3:0x36
	s_mov_b64 s[42:43], 0
	s_branch .LBB0_7
.LBB0_6:
	s_mov_b64 s[42:43], -1
                                        ; implicit-def: $vgpr20_vgpr21
                                        ; implicit-def: $vgpr16_vgpr17
                                        ; implicit-def: $vgpr50
                                        ; implicit-def: $vgpr34
                                        ; implicit-def: $vgpr35
                                        ; implicit-def: $sgpr44_sgpr45
                                        ; implicit-def: $vgpr40
                                        ; implicit-def: $vgpr41
                                        ; implicit-def: $vgpr48
                                        ; implicit-def: $vgpr49
                                        ; implicit-def: $vgpr42
                                        ; implicit-def: $vgpr43
.LBB0_7:                                ; %Flow195
	s_and_b64 s[38:39], s[54:55], vcc
	s_add_i32 s73, s73, -2
	s_and_b64 s[26:27], s[54:55], s[6:7]
	s_mov_b32 s77, 1
	s_andn2_b64 vcc, exec, s[42:43]
	v_bfe_u32 v46, v0, 4, 2
	v_lshlrev_b32_e32 v47, 2, v0
	v_lshlrev_b32_e32 v44, 3, v36
	s_cbranch_vccnz .LBB0_11
; %bb.8:                                ; %.lr.ph
	v_mov_b32_e32 v20, 0x140
	s_and_b64 s[6:7], s[60:61], exec
	v_cndmask_b32_e64 v20, v20, 0, s[20:21]
	s_cselect_b32 s6, 0, 64
	v_bitop3_b32 v20, s6, v20, v66 bitop3:0x1e
	v_or_b32_e32 v17, s67, v39
	v_or3_b32 v50, v68, v67, v20
	s_movk_i32 s6, 0x88
	v_mov_b32_e32 v20, 0x88
	v_or_b32_e32 v66, v50, v17
	v_bitop3_b32 v67, v50, s6, v17 bitop3:0x36
	v_and_b32_e32 v17, 0x430, v65
	v_cndmask_b32_e64 v20, v20, 0, s[18:19]
	s_cselect_b32 s6, 0, 8
	s_movk_i32 s14, 0x140
	v_or3_b32 v21, v62, v63, v64
	v_bitop3_b32 v17, v17, s6, v20 bitop3:0x36
	v_or_b32_e32 v34, v17, v21
	v_bitop3_b32 v35, v17, s14, v21 bitop3:0x36
	v_lshl_or_b32 v17, s63, 3, v59
	s_movk_i32 s6, 0x1180
	v_and_or_b32 v17, v58, s6, v17
	v_or_b32_e32 v20, v17, v54
	v_lshrrev_b32_e32 v17, 5, v17
	v_and_b32_e32 v17, 0xe0, v17
	v_add_u32_e32 v40, v17, v20
	s_movk_i32 s7, 0x70
	v_and_b32_e32 v17, 0x70, v5
	v_bitop3_b32 v20, v5, v54, s7 bitop3:0x6c
	v_bitop3_b32 v42, v17, v55, v54 bitop3:0xde
	v_and_or_b32 v17, v47, 60, v46
	s_lshl_b32 s7, s62, 17
	s_lshl_b32 s18, s56, 13
	s_lshl_b32 s19, s17, 8
	s_lshl_b32 s16, s16, 5
	v_sub_co_u32_e32 v2, vcc, s50, v53
	v_or_b32_e32 v16, s49, v37
	v_bitop3_b32 v43, v20, 64, v55 bitop3:0x36
	v_lshlrev_b32_e32 v53, 2, v17
	v_lshlrev_b32_e32 v17, 8, v36
	v_and_b32_e32 v20, 0x98, v5
	s_add_i32 s7, s7, s18
	s_add_i32 s16, s16, s19
	s_movk_i32 s6, 0xe0
	v_or3_b32 v16, v17, v20, v16
	v_mov_b32_e32 v17, 0x80
	v_add_u32_e32 v1, s57, v1
	s_add_i32 s7, s16, s7
	v_bitop3_b32 v17, v44, s6, v17 bitop3:0xc8
	s_max_i32 s6, s73, 1
	v_lshrrev_b32_e32 v24, 2, v1
	v_lshl_add_u32 v1, v28, 13, s7
	v_lshl_or_b32 v1, v46, 3, v1
	s_lshl_b32 s7, s46, 13
	s_lshl_b32 s80, s6, 6
	s_lshl_b32 s6, s62, 11
	v_bitop3_b32 v48, s49, v56, v57 bitop3:0x1e
	v_subrev_u32_e32 v56, s7, v1
	v_add_u32_e32 v1, s56, v28
	s_lshl2_add_u32 s6, s17, s6
	v_lshl_add_u32 v1, v1, 7, s6
	s_lshl_b32 s6, s46, 7
	v_subrev_u32_e32 v1, s6, v1
	v_add_u32_e32 v57, 0x4000, v1
	v_and_b32_e32 v1, 7, v0
	v_lshlrev_b32_e32 v58, 4, v1
	v_lshlrev_b32_e32 v1, 11, v0
	v_lshlrev_b32_e32 v20, 12, v0
	v_lshlrev_b32_e32 v0, 10, v0
	v_and_b32_e32 v1, 0x10000, v1
	v_and_b32_e32 v21, 0x8000, v20
	v_and_b32_e32 v0, 0x4000, v0
	s_add_i32 s6, s56, s62
	s_add_i32 s16, s16, s18
	v_or3_b32 v0, v1, v21, v0
	s_lshl_b32 s20, s6, 12
	s_lshl_b32 s21, s70, 8
	v_lshl_add_u32 v1, v24, 13, s16
	s_add_i32 s20, s21, s20
	v_lshl_or_b32 v1, v30, 3, v1
	v_add_u32_e32 v0, s20, v0
	v_subrev_u32_e32 v1, s7, v1
	s_lshl_b32 s6, s6, 13
	v_add_u32_e32 v59, 0xa0000, v0
	v_add_u32_e32 v0, v61, v31
	v_add_u32_e32 v61, 0x100000, v1
	v_and_b32_e32 v1, 0x38000, v20
	s_add_i32 s19, s19, s6
	v_add_u32_e32 v20, s19, v1
	v_subrev_u32_e32 v62, s7, v20
	s_lshl_b32 s6, s62, 13
	s_lshl_b32 s7, s47, 8
	s_lshl_b32 s20, s56, 12
	s_add_i32 s7, s7, s6
	v_add3_u32 v0, v0, v60, s62
	s_add_i32 s21, s21, s20
	v_add_u32_e32 v63, s7, v1
	v_mov_b32_e32 v1, 0
	s_mov_b64 s[6:7], 0x80
	v_mov_b32_e32 v23, v3
	v_lshl_or_b32 v22, v24, 12, v22
	v_lshl_add_u32 v60, v0, 12, s21
	v_lshl_add_u64 v[20:21], v[0:1], 0, s[6:7]
	v_add_u32_e32 v0, s65, v28
	s_lshl_b32 s6, s48, 19
	s_lshl_b32 s7, s17, 14
	v_mov_b32_e32 v3, s51
	v_add_u32_e32 v54, v16, v44
	v_add_u32_e32 v55, v17, v16
	v_lshl_add_u64 v[16:17], v[22:23], 0, s[58:59]
	v_or_b32_e32 v22, 0x80, v24
	v_or_b32_e32 v24, 0x80, v0
	v_add_u32_e32 v0, s62, v29
	s_add_i32 s6, s6, s7
	s_lshl_b32 s7, s46, 19
	s_add_i32 s82, 0, 0x18b80
	v_subbrev_co_u32_e32 v3, vcc, 0, v3, vcc
	s_and_b32 s13, s13, 0xffff
	s_mov_b32 s15, 0x27000
	s_mov_b32 s14, 0x7ffffffe
	v_add_u32_e32 v41, 64, v40
	v_xor_b32_e32 v49, 0x110, v48
	s_and_b32 s45, s9, 0xffff
	s_mov_b32 s44, s8
	s_sub_i32 s78, s47, 32
	s_add_i32 s79, s79, s71
	v_mov_b32_e32 v23, s72
	v_mov_b32_e32 v25, s72
	v_add_u32_e32 v26, 0xa0, v0
	v_mov_b32_e32 v27, s72
	v_or_b32_e32 v28, 0x80, v0
	v_mov_b32_e32 v29, s72
	s_sub_i32 s81, s6, s7
	s_add_i32 s71, 0, 0x2100
	s_add_i32 s74, 0, 0x62e0
	s_add_i32 s76, 0, 0x83e0
	s_add_i32 s16, 0, 0xc5c0
	s_add_i32 s70, 0, 0xe6c0
	s_add_i32 s68, 0, 0x128a0
	s_add_i32 s75, 0, 0x149a0
	s_mov_b64 s[56:57], 0
	s_and_b64 s[64:65], s[26:27], exec
	v_add_u32_e32 v0, s82, v66
	v_add_u32_e32 v64, s82, v67
	s_mov_b32 s83, 0x5040100
	s_mov_b32 s84, 0xc2fc0000
	s_mov_b64 s[60:61], 0x40000
	s_mov_b64 s[58:59], 0x80000
	v_bfrev_b32_e32 v65, 1
	v_mov_b32_e32 v66, 0xff800000
	v_mov_b32_e32 v67, 0x42800000
	v_not_b32_e32 v68, 63
	s_mov_b32 s85, 0
                                        ; implicit-def: $sgpr26_sgpr27
                                        ; implicit-def: $sgpr62_sgpr63
.LBB0_9:                                ; =>This Inner Loop Header: Depth=1
	v_cvt_pk_bf16_f32 v30, v10, s0
	v_add_u32_e32 v69, s82, v34
	s_waitcnt vmcnt(5)
	v_mov_b32_e32 v74, v14
	v_mov_b32_e32 v75, v15
	v_cvt_pk_bf16_f32 v31, v11, s0
	v_cvt_pk_bf16_f32 v73, v8, s0
	v_cvt_pk_bf16_f32 v77, v9, s0
	v_add_u32_e32 v70, s82, v35
	NETRA_WAIT_VM0
	ds_write_b16 v0, v30
	ds_write_b16 v0, v31 offset:512
	ds_write_b16 v64, v73
	ds_write_b16 v64, v77 offset:512
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_u16 v14, v69
	ds_read_u16 v15, v69 offset:4
	ds_read_u16 v71, v70 offset:4
	ds_read_u16 v72, v70
	s_add_i32 s6, s77, 1
	s_cmp_lt_i32 s6, 3
	s_cselect_b32 s77, s6, 0
	s_add_i32 s6, s81, s85
	s_waitcnt lgkmcnt(1)
	v_perm_b32 v15, v71, v15, s83
	v_add_u32_e32 v71, s6, v4
	NETRA_WAIT_LGKM0
	v_perm_b32 v14, v72, v14, s83
	v_add_lshl_u32 v72, v71, s34, 1
	v_cvt_pk_bf16_f32 v78, v12, s0
	v_cndmask_b32_e64 v72, v65, v72, s[2:3]
	v_cvt_pk_bf16_f32 v79, v13, s0
	buffer_store_dwordx2 v[14:15], v72, s[12:15], 0 offen
	v_cvt_pk_bf16_f32 v80, v6, s0
	v_cvt_pk_bf16_f32 v81, v7, s0
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_write_b16 v0, v78
	ds_write_b16 v0, v79 offset:512
	ds_write_b16 v64, v80
	ds_write_b16 v64, v81 offset:512
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_u16 v14, v69
	ds_read_u16 v15, v69 offset:4
	ds_read_u16 v69, v70 offset:4
	ds_read_u16 v70, v70
	s_mov_b32 s17, s72
	s_mov_b32 s18, s74
	s_mov_b32 s74, s76
	s_waitcnt lgkmcnt(1)
	v_perm_b32 v15, v69, v15, s83
	v_add_lshl_u32 v69, v71, s35, 1
	NETRA_WAIT_LGKM0
	v_perm_b32 v14, v70, v14, s83
	v_cndmask_b32_e64 v69, v65, v69, s[2:3]
	buffer_store_dwordx2 v[14:15], v69, s[12:15], 0 offen
	v_lshl_add_u64 v[14:15], v[28:29], 0, s[56:57]
	v_cmp_gt_i64_e32 vcc, s[50:51], v[14:15]
	v_lshl_add_u64 v[14:15], v[26:27], 0, s[56:57]
	s_mov_b32 s76, s16
	s_add_u32 s16, s56, 0x80
	v_cmp_gt_i64_e64 s[6:7], s[50:51], v[14:15]
	v_add_u32_e32 v14, s17, v40
	s_addc_u32 s17, s57, 0
	s_lshl_b32 s19, s77, 12
	s_ashr_i32 s20, s19, 5
	s_add_i32 s20, s20, s19
	v_add_u32_e32 v82, v58, v63
	s_mov_b32 s72, s71
	s_lshl1_add_u32 s71, s20, 0
	v_add_u32_e32 v70, 0x100000, v82
	v_add_u32_e32 v83, v58, v62
	s_add_i32 s87, s71, s69
	v_add_u32_e32 v71, 0x140000, v83
	s_mov_b32 s86, s68
	s_mov_b32 s68, s75
	v_cndmask_b32_e32 v15, v65, v70, vcc
	s_mov_b32 m0, s87
	s_add_i32 s75, s71, s79
	v_mov_b32_e32 v69, v38
	v_mov_b32_e32 v38, v45
	ds_bpermute_b32 v45, v53, v19
	buffer_load_dwordx4 v15, s[28:31], 0 offen lds
	v_cndmask_b32_e64 v19, v65, v71, s[6:7]
	s_add_i32 m0, s75, 0x1000
	v_add_u32_e32 v70, s82, v48
	v_add_u32_e32 v71, s82, v49
	v_add_u32_e32 v72, s82, v42
	ds_read_b128 v[84:87], v14
	ds_read_b128 v[88:91], v14 offset:64
	buffer_load_dwordx4 v19, s[28:31], 0 offen lds
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	NETRA_WAIT_VM0
	ds_write_b16 v70, v30
	ds_write_b16 v70, v31 offset:128
	ds_write_b16 v71, v73
	v_add_u32_e32 v73, s82, v43
	ds_write_b16 v71, v77 offset:128
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b128 v[92:95], v72
	ds_read_b128 v[96:99], v73
	v_add_u32_e32 v19, 0x100080, v82
	v_add_u32_e32 v30, 0x140080, v83
	v_cndmask_b32_e32 v19, v65, v19, vcc
	s_add_i32 m0, s87, 0x62e0
	v_add_u32_e32 v31, s18, v40
	v_cndmask_b32_e64 v30, v65, v30, s[6:7]
	buffer_load_dwordx4 v19, s[28:31], 0 offen lds
	s_add_i32 m0, s75, 0x72e0
	ds_read_b128 v[100:103], v31
	ds_read_b128 v[104:107], v31 offset:64
	buffer_load_dwordx4 v30, s[28:31], 0 offen lds
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	NETRA_WAIT_VM0
	ds_write_b16 v70, v78
	ds_write_b16 v70, v79 offset:128
	ds_write_b16 v71, v80
	ds_write_b16 v71, v81 offset:128
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	v_mfma_f32_16x16x32_bf16 v[78:81], v[92:95], v[84:87], 0
	ds_read_b128 v[82:85], v72
	ds_bpermute_b32 v18, v53, v18
	v_lshl_add_u64 v[14:15], v[22:23], 0, s[56:57]
	v_mfma_f32_16x16x32_bf16 v[78:81], v[96:99], v[88:91], v[78:81]
	ds_read_b128 v[86:89], v73
	v_and_b32_e32 v31, 0xffff0000, v45
	s_waitcnt lgkmcnt(1)
	v_and_b32_e32 v19, 0xffff0000, v18
	v_mfma_f32_16x16x32_bf16 v[78:81], v[82:85], v[100:103], v[78:81]
	v_lshlrev_b32_e32 v18, 16, v18
	v_lshlrev_b32_e32 v30, 16, v45
	v_cmp_gt_i64_e32 vcc, s[50:51], v[14:15]
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[78:81], v[86:89], v[104:107], v[78:81]
	v_mov_b32_e32 v76, v52
	v_add_u32_e32 v45, s85, v61
	v_add_u32_e32 v52, s85, v56
	s_and_b64 vcc, s[52:53], vcc
	s_mov_b32 s6, s30
	// Fill the final W@state MFMA dependency window with address/mask work
	// that the compiler placed after the accumulator consumers.
	s_mov_b32 s7, s31
	s_mov_b32 s46, s14
	s_mov_b32 s47, s15
	v_cndmask_b32_e64 v52, v65, v52, s[38:39]
	v_pk_add_f32 v[18:19], v[18:19], v[78:79] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[30:31], v[30:31], v[80:81] neg_lo:[0,1] neg_hi:[0,1]
	v_lshl_add_u64 v[78:79], v[20:21], 0, s[56:57]
	v_cmp_gt_i64_e64 s[18:19], s[50:51], v[78:79]
	v_cndmask_b32_e32 v14, v65, v45, vcc
	v_cvt_pk_bf16_f32 v78, v18, v19
	v_cvt_pk_bf16_f32 v79, v30, v31
	buffer_load_dwordx2 v[14:15], v14, s[4:7], 0 offen
	v_sub_f32_e32 v51, v69, v51
	buffer_store_dwordx2 v[78:79], v52, s[44:47], 0 offen
	v_mul_f32_e32 v52, 0x3fb8aa3b, v69
	v_cmp_gt_f32_e64 s[20:21], s84, v52
.Ltmp10:
	v_mul_f32_e32 v52, 0x3fb8aa3b, v51
	v_cmp_ge_f32_e64 s[6:7], 0, v51
.Ltmp11:
	s_add_i32 s46, s56, 0xc0
	s_min_i32 s46, s46, s50
.Ltmp12:
	v_cndmask_b32_e64 v51, v66, v52, s[6:7]
	v_cmp_gt_f32_e64 s[6:7], s84, v51
.Ltmp13:
	s_lshl_b32 s46, s46, 5
	s_add_i32 s46, s78, s46
.Ltmp14:
	v_cndmask_b32_e64 v52, 0, v67, s[6:7]
	v_add_f32_e32 v51, v51, v52
.Ltmp15:
	v_add_u32_e32 v52, s76, v54
	s_ashr_i32 s47, s46, 31
	ds_read_b64_tr_b16 v[82:83], v52
	ds_read_b64_tr_b16 v[84:85], v52 offset:256
	v_add_u32_e32 v52, s76, v55
	s_add_i32 s76, s71, 0x62e0
	s_lshl_b64 s[46:47], s[46:47], 2
	s_add_u32 s46, s10, s46
	v_add_u32_e32 v77, v58, v60
	v_lshl_add_u64 v[78:79], v[24:25], 0, s[56:57]
	s_addc_u32 s47, s11, s47
	v_add_u32_e32 v80, 0x80000, v77
	v_cmp_gt_i64_e32 vcc, s[50:51], v[78:79]
	v_cndmask_b32_e64 v79, 0, v67, s[20:21]
	s_and_b64 s[20:21], s[20:21], exec
.Ltmp16:
	v_exp_f32_e32 v51, v51
.Ltmp17:
	s_mov_b32 s38, s30
	s_mov_b32 s39, s31
	v_add_u32_e32 v45, v58, v59
	ds_read_b64_tr_b16 v[86:87], v52 offset:4096
	ds_read_b64_tr_b16 v[88:89], v52 offset:4352
	v_cndmask_b32_e64 v52, v65, v80, s[18:19]
	s_cselect_b32 s20, 0xffffffc0, 0
	s_add_i32 m0, s87, 0xc5c0
	v_cmp_lt_i64_e64 s[16:17], s[16:17], v[2:3]
	buffer_load_dwordx4 v52, s[36:39], 0 offen lds
	v_add_u32_e32 v52, 0x80, v45
	v_cndmask_b32_e64 v45, v65, v45, s[16:17]
	s_add_i32 m0, s75, 0xd5c0
	v_cndmask_b32_e64 v80, v65, v52, s[16:17]
	buffer_load_dwordx4 v45, s[36:39], 0 offen lds
.Ltmp18:
	v_cndmask_b32_e64 v45, 0, v68, s[6:7]
	v_ldexp_f32 v52, v51, v45
.Ltmp19:
	v_add_u32_e32 v77, 0x80080, v77
	s_add_i32 s75, s71, 0x128a0
	v_pk_mul_f32 v[18:19], v[52:53], v[18:19] op_sel_hi:[0,1]
	s_mov_b32 s40, s10
	s_mov_b32 s42, s30
	s_mov_b32 s43, s31
	v_cndmask_b32_e32 v78, v65, v57, vcc
	v_cndmask_b32_e64 v77, v65, v77, s[18:19]
	s_add_i32 s6, s75, s79
	s_add_i32 m0, s75, s69
	v_pk_mul_f32 v[30:31], v[52:53], v[30:31] op_sel_hi:[0,1]
	v_cvt_pk_bf16_f32 v18, v18, s0
	v_cvt_pk_bf16_f32 v19, v19, s0
	v_cvt_pk_bf16_f32 v30, v30, s0
	v_cvt_pk_bf16_f32 v31, v31, s0
	global_load_dword v45, v1, s[46:47]
	buffer_load_dword v52, v78, s[40:43], 0 offen
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	s_waitcnt vmcnt(2)
	ds_write_b16 v70, v18
	ds_write_b16 v70, v19 offset:128
	ds_write_b16 v71, v30
	ds_write_b16 v71, v31 offset:128
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b128 v[90:93], v72
	ds_read_b128 v[94:97], v73
	buffer_load_dwordx4 v77, s[36:39], 0 offen lds
	s_add_i32 m0, s6, 0x1000
	v_add_u32_e32 v70, s86, v54
	buffer_load_dwordx4 v80, s[36:39], 0 offen lds
	v_add_u32_e32 v71, s86, v55
	ds_read_b64_tr_b16 v[98:99], v70
	ds_read_b64_tr_b16 v[100:101], v70 offset:256
	ds_read_b64_tr_b16 v[102:103], v71 offset:4096
	ds_read_b64_tr_b16 v[104:105], v71 offset:4352
	s_waitcnt lgkmcnt(5)
	v_mfma_f32_16x16x32_bf16 v[70:73], v[90:93], v[82:85], 0
	v_fmac_f32_e32 v79, 0x3fb8aa3b, v69
	v_exp_f32_e32 v69, v79
	s_mov_b32 s16, s70
	s_waitcnt lgkmcnt(4)
	v_mfma_f32_16x16x32_bf16 v[70:73], v[94:97], v[86:89], v[70:73]
	s_add_i32 s70, s71, 0xc5c0
	v_ldexp_f32 v78, v69, s20
	s_and_b64 s[6:7], s[54:55], vcc
	s_add_i32 s85, s85, 0x80000
	s_add_u32 s56, s56, 64
	s_addc_u32 s57, s57, 0
	v_mov_b64_e32 v[30:31], v[16:17]
	v_pk_fma_f32 v[10:11], v[10:11], v[78:79], v[70:71] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[8:9], v[78:79], v[72:73] op_sel_hi:[1,0,1]
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[70:73], v[90:93], v[98:101], 0
	s_andn2_b64 s[18:19], s[64:65], exec
	s_and_b64 s[6:7], s[6:7], exec
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[70:73], v[94:97], v[102:105], v[70:73]
	s_andn2_b64 s[20:21], s[62:63], exec
	s_and_b64 s[42:43], s[64:65], exec
	s_andn2_b64 s[26:27], s[26:27], exec
	s_mov_b64 s[38:39], s[64:65]
	s_or_b64 s[64:65], s[18:19], s[6:7]
	s_or_b64 s[62:63], s[20:21], s[42:43]
	s_or_b64 s[26:27], s[26:27], s[6:7]
	v_add_u32_e32 v59, 0x40000, v59
	v_add_u32_e32 v60, 0x40000, v60
	v_add_u32_e32 v62, 0x80000, v62
	v_add_u32_e32 v63, 0x80000, v63
	v_lshl_add_u64 v[16:17], v[30:31], 0, s[60:61]
	v_add_u32_e32 v57, 0x2000, v57
	v_mov_b32_e32 v51, v76
	v_mov_b32_e32 v18, v74
	v_mov_b32_e32 v19, v75
	s_cmp_lg_u32 s80, s56
	v_pk_fma_f32 v[12:13], v[12:13], v[78:79], v[70:71] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[6:7], v[6:7], v[78:79], v[72:73] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(8) lgkmcnt(0)
	NETRA_BARRIER
	s_cbranch_scc1 .LBB0_9
; %bb.10:                               ; %Flow
	v_lshl_add_u64 v[20:21], v[30:31], 0, s[58:59]
	s_mov_b64 s[38:39], s[62:63]
	v_mov_b32_e32 v18, v74
	v_mov_b32_e32 v19, v75
	v_mov_b32_e32 v51, v76
	s_mov_b64 s[44:45], s[12:13]
	s_branch .LBB0_12
.LBB0_11:
	s_add_i32 s71, 0, 0x2100
	s_add_i32 s74, 0, 0x62e0
	s_add_i32 s76, 0, 0x83e0
	s_add_i32 s16, 0, 0xc5c0
	s_add_i32 s70, 0, 0xe6c0
.LBB0_12:                               ; %._crit_edge
	v_or_b32_e32 v0, s67, v50
	s_movk_i32 s5, 0x88
	v_or_b32_e32 v21, v0, v39
	s_add_i32 s7, 0, 0x18b80
	v_bitop3_b32 v22, v0, s5, v39 bitop3:0x36
	v_or_b32_e32 v0, 4, v34
	v_add_u32_e32 v26, s7, v21
	v_cvt_pk_bf16_f32 v25, v10, s0
	v_cvt_pk_bf16_f32 v27, v11, s0
	v_add_u32_e32 v28, s7, v22
	v_cvt_pk_bf16_f32 v29, v8, s0
	v_cvt_pk_bf16_f32 v39, v9, s0
	v_add_u32_e32 v30, s7, v34
	v_add_u32_e32 v50, s7, v0
	v_or_b32_e32 v0, 4, v35
	s_max_i32 s4, s73, 0
	NETRA_WAIT_VM0
	ds_write_b16 v26, v25
	ds_write_b16 v26, v27 offset:512
	ds_write_b16 v28, v29
	ds_write_b16 v28, v39 offset:512
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	v_add_u32_e32 v31, s7, v35
	v_add_u32_e32 v53, s7, v0
	ds_read_u16 v0, v30
	ds_read_u16 v1, v50
	ds_read_u16 v2, v31
	ds_read_u16 v3, v53
	s_add_i32 s4, s4, s48
	s_lshl_b32 s6, s4, 19
	s_add_i32 s6, s6, s66
	v_add_u32_e32 v23, s6, v4
	s_mov_b32 s4, 0x5040100
	NETRA_WAIT_LGKM0
	v_perm_b32 v1, v3, v1, s4
	v_perm_b32 v0, v2, v0, s4
	v_add_lshl_u32 v2, v23, s34, 1
	v_bfrev_b32_e32 v3, 1
	s_and_b64 vcc, s[22:23], s[2:3]
	v_cndmask_b32_e32 v2, v3, v2, vcc
	s_mov_b32 s46, s14
	s_mov_b32 s47, s15
	v_cvt_pk_bf16_f32 v17, v12, s0
	v_cvt_pk_bf16_f32 v54, v13, s0
	v_cvt_pk_bf16_f32 v55, v6, s0
	v_cvt_pk_bf16_f32 v56, v7, s0
	buffer_store_dwordx2 v[0:1], v2, s[44:47], 0 offen
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_write_b16 v26, v17
	ds_write_b16 v26, v54 offset:512
	ds_write_b16 v28, v55
	ds_write_b16 v28, v56 offset:512
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_u16 v0, v30
	ds_read_u16 v1, v50
	ds_read_u16 v2, v53
	ds_read_u16 v24, v31
	s_waitcnt lgkmcnt(1)
	v_perm_b32 v1, v2, v1, s4
	v_add_lshl_u32 v2, v23, s35, 1
	NETRA_WAIT_LGKM0
	v_perm_b32 v0, v24, v0, s4
	v_cndmask_b32_e32 v2, v3, v2, vcc
	buffer_store_dwordx2 v[0:1], v2, s[44:47], 0 offen
	v_add_u32_e32 v0, s72, v40
	v_add_u32_e32 v1, s72, v41
	ds_read_b128 v[58:61], v0
	ds_read_b128 v[0:3], v1
	v_add_u32_e32 v24, s7, v48
	v_cndmask_b32_e64 v48, 0, 1, s[22:23]
	v_add_u32_e32 v23, s7, v49
	v_cmp_ne_u32_e64 s[4:5], 1, v48
	s_andn2_b64 vcc, exec, s[22:23]
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_write_b16 v24, v25
	ds_write_b16 v24, v27 offset:128
	ds_write_b16 v23, v29
	ds_write_b16 v23, v39 offset:128
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	s_cbranch_vccnz .LBB0_14
; %bb.13:
	v_add_u32_e32 v48, s7, v42
	ds_read_b128 v[62:65], v48
	v_add_u32_e32 v48, s7, v43
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[58:61], v[62:65], v[58:61], 0
	ds_read_b128 v[62:65], v48
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[0:3], v[62:65], v[0:3], v[58:61]
	s_branch .LBB0_15
.LBB0_14:
	v_mov_b32_e32 v0, 0
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
.LBB0_15:
	v_add_u32_e32 v48, s74, v40
	v_add_u32_e32 v49, s74, v41
	ds_read_b128 v[62:65], v48
	s_nop 0
	ds_read_b128 v[58:61], v49
	s_and_b64 vcc, exec, s[4:5]
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_write_b16 v24, v17
	ds_write_b16 v24, v54 offset:128
	ds_write_b16 v23, v55
	ds_write_b16 v23, v56 offset:128
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	s_cbranch_vccnz .LBB0_17
; %bb.16:
	v_add_u32_e32 v17, s7, v42
	ds_read_b128 v[54:57], v17
	v_add_u32_e32 v17, s7, v43
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[0:3], v[54:57], v[62:65], v[0:3]
	ds_read_b128 v[54:57], v17
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[0:3], v[54:57], v[58:61], v[0:3]
.LBB0_17:
	v_and_or_b32 v17, v47, 60, v46
	v_lshlrev_b32_e32 v46, 2, v17
	v_add_u32_e32 v16, s33, v16
	ds_bpermute_b32 v17, v46, v18
	ds_bpermute_b32 v16, v46, v16
	ds_bpermute_b32 v47, v46, v19
	s_and_b64 vcc, s[22:23], s[38:39]
	s_mov_b32 s12, 0xc2fc0000
	s_waitcnt lgkmcnt(2)
	v_and_b32_e32 v19, 0xffff0000, v17
	v_lshlrev_b32_e32 v18, 16, v17
	s_waitcnt lgkmcnt(1)
	v_lshlrev_b32_e32 v16, 1, v16
	v_bfrev_b32_e32 v17, 1
	NETRA_WAIT_LGKM0
	v_and_b32_e32 v49, 0xffff0000, v47
	v_lshlrev_b32_e32 v48, 16, v47
	v_cndmask_b32_e32 v16, v17, v16, vcc
	v_sub_f32_e32 v17, v38, v51
	v_pk_add_f32 v[2:3], v[48:49], v[2:3] neg_lo:[0,1] neg_hi:[0,1]
.Ltmp20:
	v_mul_f32_e32 v47, 0x3fb8aa3b, v17
	v_mov_b32_e32 v48, 0xff800000
	v_cmp_ge_f32_e32 vcc, 0, v17
.Ltmp21:
	v_pk_add_f32 v[0:1], v[18:19], v[0:1] neg_lo:[0,1] neg_hi:[0,1]
	v_cvt_pk_bf16_f32 v19, v2, v3
.Ltmp22:
	v_cndmask_b32_e32 v17, v48, v47, vcc
	v_mov_b32_e32 v47, 0x42800000
	v_cmp_gt_f32_e32 vcc, s12, v17
.Ltmp23:
	v_cvt_pk_bf16_f32 v18, v0, v1
	s_mov_b32 s11, 0x27000
.Ltmp24:
	v_cndmask_b32_e32 v47, 0, v47, vcc
	v_add_f32_e32 v17, v17, v47
	v_exp_f32_e32 v17, v17
	s_mov_b32 s10, 0x7ffffffe
.Ltmp25:
	s_and_b32 s9, s9, 0xffff
	buffer_store_dwordx2 v[18:19], v16, s[8:11], 0 offen
.Ltmp26:
	v_not_b32_e32 v16, 63
	v_cndmask_b32_e32 v16, 0, v16, vcc
	v_ldexp_f32 v16, v17, v16
.Ltmp27:
	v_pk_mul_f32 v[48:49], v[16:17], v[0:1] op_sel_hi:[0,1]
	v_and_b32_e32 v0, 0x98, v5
	v_lshl_or_b32 v0, v36, 8, v0
	s_movk_i32 s13, 0xe0
	v_mov_b32_e32 v1, 0x80
	v_or3_b32 v0, s49, v0, v37
	v_bitop3_b32 v1, v44, s13, v1 bitop3:0xc8
	v_add_u32_e32 v5, v0, v44
	v_add_u32_e32 v18, v1, v0
	v_pk_mul_f32 v[16:17], v[16:17], v[2:3] op_sel_hi:[0,1]
	v_add_u32_e32 v2, s16, v5
	v_add_u32_e32 v19, s16, v18
	ds_read_b64_tr_b16 v[0:1], v2
	ds_read_b64_tr_b16 v[2:3], v2 offset:256
	ds_read_b64_tr_b16 v[62:63], v19 offset:4096
	ds_read_b64_tr_b16 v[64:65], v19 offset:4352
	v_cvt_pk_bf16_f32 v19, v48, s0
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_write_b16 v24, v19
	v_cvt_pk_bf16_f32 v19, v49, s0
	v_cvt_pk_bf16_f32 v16, v16, s0
	ds_write_b16 v24, v19 offset:128
	ds_write_b16 v23, v16
	v_cvt_pk_bf16_f32 v16, v17, s0
	v_add_u32_e32 v19, s7, v42
	ds_write_b16 v23, v16 offset:128
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	v_add_u32_e32 v36, s7, v43
	ds_read_b128 v[58:61], v19
	ds_read_b128 v[54:57], v36
	s_and_b64 vcc, exec, s[4:5]
	s_cbranch_vccnz .LBB0_19
; %bb.18:
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[0:3], v[58:61], v[0:3], 0
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[0:3], v[54:57], v[62:65], v[0:3]
	s_branch .LBB0_20
.LBB0_19:
	v_mov_b32_e32 v0, 0
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
.LBB0_20:
	v_mul_f32_e32 v16, 0x3fb8aa3b, v38
	v_mov_b32_e32 v17, 0x42800000
	v_cmp_gt_f32_e32 vcc, s12, v16
	s_and_b64 s[12:13], vcc, exec
	s_cselect_b32 s7, 0xffffffc0, 0
	v_cndmask_b32_e32 v16, 0, v17, vcc
	v_fmac_f32_e32 v16, 0x3fb8aa3b, v38
	v_exp_f32_e32 v16, v16
	s_and_b64 vcc, exec, s[4:5]
	v_ldexp_f32 v16, v16, s7
	v_mov_b32_e32 v17, v16
	s_cbranch_vccnz .LBB0_22
; %bb.21:
	v_add_u32_e32 v25, s68, v5
	ds_read_b64_tr_b16 v[62:63], v25
	ds_read_b64_tr_b16 v[64:65], v25 offset:256
	v_add_u32_e32 v25, s68, v18
	ds_read_b64_tr_b16 v[66:67], v25 offset:4096
	ds_read_b64_tr_b16 v[68:69], v25 offset:4352
	v_pk_fma_f32 v[8:9], v[8:9], v[16:17], v[2:3]
	v_pk_fma_f32 v[10:11], v[10:11], v[16:17], v[0:1]
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[58:61], v[58:61], v[62:65], 0
	v_cvt_pk_bf16_f32 v25, v10, s0
	v_cvt_pk_bf16_f32 v27, v11, s0
	v_cvt_pk_bf16_f32 v29, v8, s0
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[0:3], v[54:57], v[66:69], v[58:61]
	v_cvt_pk_bf16_f32 v39, v9, s0
	s_branch .LBB0_23
.LBB0_22:
	v_mov_b32_e32 v0, 0
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
.LBB0_23:
	s_nop 5
	v_pk_fma_f32 v[0:1], v[12:13], v[16:17], v[0:1]
	v_pk_fma_f32 v[2:3], v[6:7], v[16:17], v[2:3]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	NETRA_BARRIER
	v_cndmask_b32_e64 v13, v13, v1, s[22:23]
	v_cndmask_b32_e64 v16, v12, v0, s[22:23]
	v_cndmask_b32_e64 v17, v7, v3, s[22:23]
	ds_write_b16 v26, v25
	ds_write_b16 v26, v27 offset:512
	ds_write_b16 v28, v29
	ds_write_b16 v28, v39 offset:512
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_u16 v0, v30
	ds_read_u16 v1, v50
	ds_read_u16 v3, v31
	ds_read_u16 v7, v53
	s_add_i32 s6, s6, 0x80000
	v_cndmask_b32_e64 v12, v6, v2, s[22:23]
	v_add_u32_e32 v2, s6, v4
	s_mov_b32 s4, 0x5040100
	s_waitcnt lgkmcnt(1)
	v_perm_b32 v0, v3, v0, s4
	v_add_lshl_u32 v3, v2, s34, 1
	v_bfrev_b32_e32 v37, 1
	s_and_b64 vcc, s[0:1], s[2:3]
	NETRA_WAIT_LGKM0
	v_perm_b32 v1, v7, v1, s4
	v_cndmask_b32_e32 v3, v37, v3, vcc
	s_mov_b32 s46, s14
	s_mov_b32 s47, s15
	v_cvt_pk_bf16_f32 v4, v16, s0
	v_cvt_pk_bf16_f32 v6, v13, s0
	buffer_store_dwordx2 v[0:1], v3, s[44:47], 0 offen
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_write_b16 v26, v4
	ds_write_b16 v26, v6 offset:512
	v_cvt_pk_bf16_f32 v7, v12, s0
	v_cvt_pk_bf16_f32 v26, v17, s0
	ds_write_b16 v28, v7
	ds_write_b16 v28, v26 offset:512
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_u16 v0, v30
	ds_read_u16 v1, v50
	ds_read_u16 v3, v53
	ds_read_u16 v28, v31
	v_add_lshl_u32 v2, v2, s35, 1
	v_cndmask_b32_e32 v2, v37, v2, vcc
	s_andn2_b64 vcc, exec, s[0:1]
	s_waitcnt lgkmcnt(1)
	v_perm_b32 v1, v3, v1, s4
	NETRA_WAIT_LGKM0
	v_perm_b32 v0, v28, v0, s4
	buffer_store_dwordx2 v[0:1], v2, s[44:47], 0 offen
	v_add_u32_e32 v0, s71, v40
	v_add_u32_e32 v1, s71, v41
	ds_read_b128 v[48:51], v0
	ds_read_b128 v[0:3], v1
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_write_b16 v24, v25
	ds_write_b16 v24, v27 offset:128
	ds_write_b16 v23, v29
	ds_write_b16 v23, v39 offset:128
	v_cndmask_b32_e64 v25, 0, 1, s[0:1]
	v_cmp_ne_u32_e64 s[2:3], 1, v25
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	s_cbranch_vccnz .LBB0_25
; %bb.24:
	ds_read_b128 v[28:31], v19
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[28:31], v[28:31], v[48:51], 0
	ds_read_b128 v[48:51], v36
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[0:3], v[48:51], v[0:3], v[28:31]
	s_branch .LBB0_26
.LBB0_25:
	v_mov_b32_e32 v0, 0
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
.LBB0_26:
	v_add_u32_e32 v25, s76, v40
	v_add_u32_e32 v27, s76, v41
	ds_read_b128 v[38:41], v25
	s_nop 0
	ds_read_b128 v[28:31], v27
	s_and_b64 vcc, exec, s[2:3]
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_write_b16 v24, v4
	ds_write_b16 v24, v6 offset:128
	ds_write_b16 v23, v7
	ds_write_b16 v23, v26 offset:128
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	s_cbranch_vccnz .LBB0_28
; %bb.27:
	ds_read_b128 v[48:51], v19
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[0:3], v[48:51], v[38:41], v[0:3]
	ds_read_b128 v[38:41], v36
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[0:3], v[38:41], v[28:31], v[0:3]
.LBB0_28:
	ds_bpermute_b32 v4, v46, v14
	ds_bpermute_b32 v14, v46, v15
	s_and_b64 vcc, s[0:1], s[26:27]
	s_mov_b32 s4, 0xc2fc0000
	s_waitcnt lgkmcnt(1)
	v_and_b32_e32 v7, 0xffff0000, v4
	v_lshlrev_b32_e32 v6, 16, v4
	v_add_u32_e32 v4, s33, v20
	ds_bpermute_b32 v4, v46, v4
	s_waitcnt lgkmcnt(1)
	v_and_b32_e32 v15, 0xffff0000, v14
	v_lshlrev_b32_e32 v14, 16, v14
	v_pk_add_f32 v[2:3], v[14:15], v[2:3] neg_lo:[0,1] neg_hi:[0,1]
	v_bfrev_b32_e32 v14, 1
	NETRA_WAIT_LGKM0
	v_lshlrev_b32_e32 v4, 1, v4
	v_cndmask_b32_e32 v4, v14, v4, vcc
	v_sub_f32_e32 v14, v45, v52
.Ltmp28:
	v_mul_f32_e32 v15, 0x3fb8aa3b, v14
	v_mov_b32_e32 v20, 0xff800000
	v_cmp_ge_f32_e32 vcc, 0, v14
.Ltmp29:
	v_pk_add_f32 v[0:1], v[6:7], v[0:1] neg_lo:[0,1] neg_hi:[0,1]
	v_cvt_pk_bf16_f32 v7, v2, v3
.Ltmp30:
	v_cndmask_b32_e32 v14, v20, v15, vcc
	v_mov_b32_e32 v15, 0x42800000
	v_cmp_gt_f32_e32 vcc, s4, v14
.Ltmp31:
	v_cvt_pk_bf16_f32 v6, v0, v1
	buffer_store_dwordx2 v[6:7], v4, s[8:11], 0 offen
.Ltmp32:
	v_cndmask_b32_e32 v15, 0, v15, vcc
	v_add_f32_e32 v14, v14, v15
	v_exp_f32_e32 v14, v14
	v_not_b32_e32 v4, 63
	v_cndmask_b32_e32 v4, 0, v4, vcc
.Ltmp33:
	s_and_b64 vcc, exec, s[2:3]
.Ltmp34:
	v_ldexp_f32 v4, v14, v4
.Ltmp35:
	v_pk_mul_f32 v[6:7], v[4:5], v[0:1] op_sel_hi:[0,1]
	v_pk_mul_f32 v[14:15], v[4:5], v[2:3] op_sel_hi:[0,1]
	v_add_u32_e32 v2, s70, v5
	v_add_u32_e32 v4, s70, v18
	ds_read_b64_tr_b16 v[0:1], v2
	ds_read_b64_tr_b16 v[2:3], v2 offset:256
	ds_read_b64_tr_b16 v[38:39], v4 offset:4096
	ds_read_b64_tr_b16 v[40:41], v4 offset:4352
	v_cvt_pk_bf16_f32 v4, v6, s0
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_write_b16 v24, v4
	v_cvt_pk_bf16_f32 v4, v7, s0
	ds_write_b16 v24, v4 offset:128
	v_cvt_pk_bf16_f32 v4, v14, s0
	ds_write_b16 v23, v4
	v_cvt_pk_bf16_f32 v4, v15, s0
	ds_write_b16 v23, v4 offset:128
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_b128 v[24:27], v19
	ds_read_b128 v[28:31], v36
	s_cbranch_vccnz .LBB0_31
; %bb.29:
	s_waitcnt lgkmcnt(1)
	v_mfma_f32_16x16x32_bf16 v[0:3], v[24:27], v[0:3], 0
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[0:3], v[28:31], v[38:41], v[0:3]
	s_and_b64 vcc, exec, s[2:3]
	s_cbranch_vccz .LBB0_32
.LBB0_30:
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v7, 0
	s_branch .LBB0_33
.LBB0_31:
	v_mov_b32_e32 v0, 0
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
	s_and_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB0_30
.LBB0_32:
	v_add_u32_e32 v4, s75, v5
	ds_read_b64_tr_b16 v[36:37], v4
	ds_read_b64_tr_b16 v[38:39], v4 offset:256
	v_add_u32_e32 v4, s75, v18
	ds_read_b64_tr_b16 v[40:41], v4 offset:4096
	ds_read_b64_tr_b16 v[42:43], v4 offset:4352
	s_waitcnt lgkmcnt(2)
	v_mfma_f32_16x16x32_bf16 v[4:7], v[24:27], v[36:39], 0
	NETRA_WAIT_LGKM0
	v_mfma_f32_16x16x32_bf16 v[4:7], v[28:31], v[40:43], v[4:7]
.LBB0_33:
	v_mul_f32_e32 v14, 0x3fb8aa3b, v45
	s_mov_b32 s2, 0xc2fc0000
	v_mov_b32_e32 v15, 0x42800000
	v_cmp_gt_f32_e32 vcc, s2, v14
	s_and_b64 s[2:3], vcc, exec
	s_cselect_b32 s2, 0xffffffc0, 0
	v_cndmask_b32_e32 v14, 0, v15, vcc
	v_fmac_f32_e32 v14, 0x3fb8aa3b, v45
	v_exp_f32_e32 v14, v14
	s_mov_b32 s26, s30
	s_mov_b32 s27, s31
	v_ldexp_f32 v14, v14, s2
	v_pk_fma_f32 v[0:1], v[14:15], v[10:11], v[0:1] op_sel_hi:[0,1,1]
	v_fmac_f32_e32 v4, v14, v16
	v_cndmask_b32_e64 v10, v10, v0, s[0:1]
	v_cndmask_b32_e64 v11, v11, v1, s[0:1]
	v_pk_fma_f32 v[0:1], v[14:15], v[8:9], v[2:3] op_sel_hi:[0,1,1]
	v_cndmask_b32_e64 v2, v16, v4, s[0:1]
	v_cvt_pk_bf16_f32 v3, v10, s0
	v_add_u32_e32 v4, 0, v21
	v_cndmask_b32_e64 v0, v8, v0, s[0:1]
	ds_write_b16 v4, v3
	v_cvt_pk_bf16_f32 v3, v11, s0
	v_cndmask_b32_e64 v1, v9, v1, s[0:1]
	ds_write_b16 v4, v3 offset:512
	v_cvt_pk_bf16_f32 v0, v0, s0
	v_add_u32_e32 v3, 0, v22
	ds_write_b16 v3, v0
	v_cvt_pk_bf16_f32 v0, v1, s0
	v_add_u32_e32 v8, 0, v34
	ds_write_b16 v3, v0 offset:512
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	v_add_u32_e32 v9, 0, v35
	ds_read_u16 v0, v8
	ds_read_u16 v1, v8 offset:4
	ds_read_u16 v10, v9
	ds_read_u16 v11, v9 offset:4
	v_fmac_f32_e32 v5, v14, v13
	v_fmac_f32_e32 v6, v14, v12
	v_fmac_f32_e32 v7, v14, v17
	v_cndmask_b32_e64 v5, v13, v5, s[0:1]
	v_cndmask_b32_e64 v6, v12, v6, s[0:1]
	v_cndmask_b32_e64 v7, v17, v7, s[0:1]
	s_mov_b32 s0, 0x5040100
	NETRA_WAIT_LGKM0
	v_perm_b32 v1, v11, v1, s0
	v_perm_b32 v0, v10, v0, s0
	buffer_store_dwordx2 v[0:1], v32, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v2, s0
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_write_b16 v4, v0
	v_cvt_pk_bf16_f32 v0, v5, s0
	ds_write_b16 v4, v0 offset:512
	v_cvt_pk_bf16_f32 v0, v6, s0
	ds_write_b16 v3, v0
	v_cvt_pk_bf16_f32 v0, v7, s0
	ds_write_b16 v3, v0 offset:512
	NETRA_WAIT_LGKM0
	NETRA_BARRIER
	ds_read_u16 v0, v8
	ds_read_u16 v1, v8 offset:4
	ds_read_u16 v2, v9 offset:4
	ds_read_u16 v3, v9
	s_waitcnt lgkmcnt(1)
	v_perm_b32 v1, v2, v1, s0
	NETRA_WAIT_LGKM0
	v_perm_b32 v0, v3, v0, s0
	buffer_store_dwordx2 v[0:1], v33, s[24:27], 0 offen
	s_endpgm
.Ltmp36:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel \symbol
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 104
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
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 108
		.amdhsa_next_free_sgpr 88
		.amdhsa_accum_offset 108
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
	.set \symbol\().num_vgpr, 108
	.set \symbol\().num_agpr, 0
	.set \symbol\().numbered_sgpr, 88
	.set \symbol\().num_named_barrier, 0
	.set \symbol\().private_seg_size, 0
	.set \symbol\().uses_vcc, 1
	.set \symbol\().uses_flat_scratch, 0
	.set \symbol\().has_dyn_sized_stack, 0
	.set \symbol\().has_recursion, 0
	.set \symbol\().has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 8464
; TotalNumSgprs: 94
; NumVgprs: 108
; NumAgprs: 0
; TotalNumVgprs: 108
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 11
; VGPRBlocks: 13
; NumSGPRsForWavesPerEU: 94
; NumVGPRsForWavesPerEU: 108
; AccumOffset: 108
; Occupancy: 4
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 26
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
	.section	".note.GNU-stack","",@progbits
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
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
      - .address_space:  global
        .offset:         72
        .size:           8
        .value_kind:     global_buffer
      - .offset:         80
        .size:           4
        .value_kind:     by_value
      - .address_space:  global
        .offset:         88
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         96
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 104
    .max_flat_workgroup_size: 256
    .name:           \symbol
    .private_segment_fixed_size: 0
    .sgpr_count:     94
    .sgpr_spill_count: 0
    .symbol:         \symbol\().kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     108
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
	.endm
