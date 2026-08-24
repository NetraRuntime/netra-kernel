// SPDX-License-Identifier: MIT
// Fixed four-wave W13 MFMA and direct-to-LDS software schedule.

	.macro NETRA_MOE_PREFILL_FUSED_SPLITK2_GATE_UP
.L_0258:
	s_lshl_b32 s30, s80, 18
	s_add_u32 s32, s68, s30
	s_addc_u32 s33, s69, 0
	s_lshl_b32 s31, s80, 6
	s_mov_b32 s34, s70
	s_mov_b32 s35, s71
	s_mov_b32 s79, 0
.L_0274:
	s_lshl_b32 s30, s79, 17
	s_add_u32 s36, s32, s30
	s_addc_u32 s37, s33, 0
	s_add_u32 s40, s36, 0x8000
	s_addc_u32 s41, s37, 0
	s_add_u32 s42, s36, 0x10000
	s_addc_u32 s43, s37, 0
	s_add_u32 s44, s36, 0x18000
	s_addc_u32 s45, s37, 0
	s_add_u32 s46, s36, 0x100000
	s_addc_u32 s47, s37, 0
	s_add_u32 s48, s40, 0x100000
	s_addc_u32 s49, s41, 0
	s_add_u32 s50, s42, 0x100000
	s_addc_u32 s51, s43, 0
	s_add_u32 s52, s44, 0x100000
	s_addc_u32 s53, s45, 0
	// Raw descriptor spanning the complete W13 expert slab.
	s_mov_b32 s56, s36
	s_and_b32 s57, s37, 0xffff
	s_or_b32 s57, s57, 0x40000
	s_mov_b32 s58, 0x120000
	s_mov_b32 s59, 0x20000
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
	v_mov_b32_e32 v74, 0
	v_mov_b32_e32 v75, 0
	v_mov_b32_e32 v76, 0
	v_mov_b32_e32 v77, 0
	v_mov_b32_e32 v78, 0
	v_mov_b32_e32 v79, 0
	v_mov_b32_e32 v100, 0
	v_mov_b32_e32 v101, 0
	v_mov_b32_e32 v102, 0
	v_mov_b32_e32 v103, 0
	v_mov_b32_e32 v104, 0
	v_mov_b32_e32 v105, 0
	v_mov_b32_e32 v106, 0
	v_mov_b32_e32 v107, 0
	v_mov_b32_e32 v108, 0
	v_mov_b32_e32 v109, 0
	v_mov_b32_e32 v110, 0
	v_mov_b32_e32 v111, 0
	v_mov_b32_e32 v112, 0
	v_mov_b32_e32 v113, 0
	v_mov_b32_e32 v114, 0
	v_mov_b32_e32 v115, 0
	s_mov_b32 s38, 0
	// s75 is reused by the SiLU epilogue between W13 passes.
	v_readfirstlane_b32 s75, v0
	// G2LDS addresses LDS within a wave, so retain the explicit 1 KiB wave
	// offset.  Derive it in SALU directly from v0 to avoid a VALU-read hazard.
	s_lshl_b32 s87, s75, 4
	// Pass zero can ping-pong its 16 KiB W13 slabs across the two upper LDS
	// banks.  Pass one owns the upper bank for its intermediate and falls back.
	s_mov_b32 s74, 0
	// Software pipeline: slab s38 weights are always in flight in
	// staging v[192:207] at the loop head; A fragments and scales
	// for the next slab issue after the ACC chains consume them.
	s_lshl_b32 s39, s38, 11
	v_add_u32_e32 v95, s39, v92
	s_cmp_eq_u32 s79, 0
	s_cbranch_scc1 .L_w13_g2lds_prime
	s_cmp_lt_u32 s75, 128
	s_cbranch_scc0 .L_w13_half_prime_done
	global_load_dwordx4 v[192:195], v95, s[36:37]
	global_load_dwordx4 v[196:199], v95, s[40:41]
	global_load_dwordx4 v[200:203], v95, s[42:43]
	global_load_dwordx4 v[204:207], v95, s[44:45]
	global_load_dwordx4 v[208:211], v95, s[46:47]
	global_load_dwordx4 v[212:215], v95, s[48:49]
	global_load_dwordx4 v[216:219], v95, s[50:51]
	global_load_dwordx4 v[220:223], v95, s[52:53]
	s_branch .L_w13_half_prime_done
.L_w13_g2lds_prime:
	v_lshlrev_b32_e32 v125, 4, v0
	v_add_u32_e32 v125, s39, v125
	s_cmp_lt_u32 s75, 128
	s_cbranch_scc0 .L_w13_half_prime_done
	s_add_u32 m0, s87, 0x8000
	buffer_load_dwordx4 v125, s[56:59], 0 offen lds
	v_add_u32_e32 v126, 0x8000, v125
	s_add_u32 m0, s87, 0x8800
	buffer_load_dwordx4 v126, s[56:59], 0 offen lds
	v_add_u32_e32 v126, 0x10000, v125
	s_add_u32 m0, s87, 0x9000
	buffer_load_dwordx4 v126, s[56:59], 0 offen lds
	v_add_u32_e32 v126, 0x18000, v125
	s_add_u32 m0, s87, 0x9800
	buffer_load_dwordx4 v126, s[56:59], 0 offen lds
	v_add_u32_e32 v126, 0x100000, v125
	s_add_u32 m0, s87, 0xa000
	buffer_load_dwordx4 v126, s[56:59], 0 offen lds
	v_add_u32_e32 v126, 0x108000, v125
	s_add_u32 m0, s87, 0xa800
	buffer_load_dwordx4 v126, s[56:59], 0 offen lds
	v_add_u32_e32 v126, 0x110000, v125
	s_add_u32 m0, s87, 0xb000
	buffer_load_dwordx4 v126, s[56:59], 0 offen lds
	v_add_u32_e32 v126, 0x118000, v125
	s_add_u32 m0, s87, 0xb800
	buffer_load_dwordx4 v126, s[56:59], 0 offen lds
.L_w13_half_prime_done:
	s_cmp_eq_u64 s[66:67], 0
	s_cbranch_scc1 .L_dbuf_primed
	s_lshl_b32 s54, s38, 7
	v_add_u32_e32 v96, s54, v94
	global_load_dwordx4 v[8:11], v96, s[4:5]
	global_load_dwordx4 v[12:15], v96, s[4:5] offset:64
	s_lshl_b32 s55, s38, 2
	v_lshlrev_b32_e32 v96, 6, v84
	v_add_u32_e32 v96, s55, v96
	global_load_dword v80, v96, s[6:7]
	v_lshlrev_b32_e32 v96, 6, v85
	v_add_u32_e32 v96, s55, v96
	global_load_dword v81, v96, s[6:7]
	v_lshlrev_b32_e32 v96, 6, v86
	v_add_u32_e32 v96, s55, v96
	global_load_dword v82, v96, s[6:7]
	v_lshlrev_b32_e32 v96, 6, v87
	v_add_u32_e32 v96, s55, v96
	global_load_dword v83, v96, s[6:7]
	s_add_u32 s54, s31, s55
	s_load_dword s72, s[34:35], s54
	s_add_u32 s54, s54, 0x100
	s_load_dword s73, s[34:35], s54
.L_dbuf_primed:
.L_0358:
	// Drain the eight current B loads while leaving the six A/scale VMEM
	// loads in flight.  Padding waves have no A loads and must drain all.
	s_cmp_eq_u32 s79, 0
	s_cbranch_scc1 .L_w13_g2lds_stage_wait
	s_cmp_lt_u32 s75, 128
	s_cbranch_scc0 .L_w13_half_write_done
	s_cmp_eq_u64 s[66:67], 0
	s_cbranch_scc1 .L_w13_sk2_padwait
	s_waitcnt vmcnt(6)
	s_branch .L_w13_sk2_waited
.L_w13_sk2_padwait:
	s_waitcnt vmcnt(0)
.L_w13_sk2_waited:
	v_add_u32_e32 v96, 0x8000, v92
	ds_write_b128 v96, v[192:195]
	ds_write_b128 v96, v[196:199] offset:2048
	ds_write_b128 v96, v[200:203] offset:4096
	ds_write_b128 v96, v[204:207] offset:6144
	ds_write_b128 v96, v[208:211] offset:8192
	ds_write_b128 v96, v[212:215] offset:10240
	ds_write_b128 v96, v[216:219] offset:12288
	ds_write_b128 v96, v[220:223] offset:14336
	s_branch .L_w13_half_write_done
.L_w13_g2lds_stage_wait:
	s_cmp_eq_u64 s[66:67], 0
	s_cbranch_scc1 .L_w13_g2lds_padwait
	s_cmp_lt_u32 s75, 128
	s_cbranch_scc0 .L_w13_g2lds_padwait
	s_waitcnt vmcnt(6)
	s_branch .L_w13_half_write_done
.L_w13_g2lds_padwait:
	s_waitcnt vmcnt(0)
.L_w13_half_write_done:
	s_waitcnt lgkmcnt(0)
	s_barrier

.L_w13_pp_advance:
	s_add_u32 s38, s38, 1
	s_cmp_lt_u32 s38, 16
	s_cbranch_scc0 .L_dbuf_nopf
	s_lshl_b32 s39, s38, 11
	v_add_u32_e32 v95, s39, v92
	s_cmp_eq_u32 s79, 0
	s_cbranch_scc1 .L_w13_g2lds_next
	s_cmp_lt_u32 s75, 128
	s_cbranch_scc0 .L_dbuf_nopf
	global_load_dwordx4 v[192:195], v95, s[36:37]
	global_load_dwordx4 v[196:199], v95, s[40:41]
	global_load_dwordx4 v[200:203], v95, s[42:43]
	global_load_dwordx4 v[204:207], v95, s[44:45]
	global_load_dwordx4 v[208:211], v95, s[46:47]
	global_load_dwordx4 v[212:215], v95, s[48:49]
	global_load_dwordx4 v[216:219], v95, s[50:51]
	global_load_dwordx4 v[220:223], v95, s[52:53]
	s_branch .L_dbuf_nopf
.L_w13_g2lds_next:
	v_lshlrev_b32_e32 v125, 4, v0
	v_add_u32_e32 v125, s39, v125
	s_cmp_lt_u32 s75, 128
	s_cbranch_scc0 .L_dbuf_nopf
	s_xor_b32 s77, s74, 0x4000
	s_add_u32 m0, s87, s77
	s_add_u32 m0, m0, 0x8000
	buffer_load_dwordx4 v125, s[56:59], 0 offen lds
	v_add_u32_e32 v126, 0x8000, v125
	s_add_u32 m0, m0, 0x800
	buffer_load_dwordx4 v126, s[56:59], 0 offen lds
	v_add_u32_e32 v126, 0x10000, v125
	s_add_u32 m0, m0, 0x800
	buffer_load_dwordx4 v126, s[56:59], 0 offen lds
	v_add_u32_e32 v126, 0x18000, v125
	s_add_u32 m0, m0, 0x800
	buffer_load_dwordx4 v126, s[56:59], 0 offen lds
	v_add_u32_e32 v126, 0x100000, v125
	s_add_u32 m0, m0, 0x800
	buffer_load_dwordx4 v126, s[56:59], 0 offen lds
	v_add_u32_e32 v126, 0x108000, v125
	s_add_u32 m0, m0, 0x800
	buffer_load_dwordx4 v126, s[56:59], 0 offen lds
	v_add_u32_e32 v126, 0x110000, v125
	s_add_u32 m0, m0, 0x800
	buffer_load_dwordx4 v126, s[56:59], 0 offen lds
	v_add_u32_e32 v126, 0x118000, v125
	s_add_u32 m0, m0, 0x800
	buffer_load_dwordx4 v126, s[56:59], 0 offen lds
.L_dbuf_nopf:
	s_cmp_eq_u64 s[66:67], 0
	s_cbranch_scc1 .L_064c
	v_add_u32_e32 v97, s74, v93
	ds_read_b128 v[16:19], v97
	ds_read_b128 v[20:23], v97 offset:1024
	ds_read_b128 v[24:27], v97 offset:2048
	ds_read_b128 v[28:31], v97 offset:3072
	ds_read_b128 v[32:35], v97 offset:4096
	ds_read_b128 v[36:39], v97 offset:5120
	ds_read_b128 v[40:43], v97 offset:6144
	ds_read_b128 v[44:47], v97 offset:7168
	// The six older A/scale loads must complete before MFMA; retain the
	// eight prefetched B loads for the next iteration when one exists.
	s_cmp_lt_u32 s38, 16
	s_cbranch_scc0 .L_w13_sk2_lastwait
	s_cmp_lt_u32 s75, 128
	s_cbranch_scc0 .L_w13_half_consumer_wait
	s_waitcnt vmcnt(8) lgkmcnt(0)
	s_branch .L_w13_sk2_mfma
.L_w13_half_consumer_wait:
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_branch .L_w13_sk2_mfma
.L_w13_sk2_lastwait:
	s_waitcnt vmcnt(0) lgkmcnt(0)
.L_w13_sk2_mfma:
	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	// Start the next LDS fragment while the current MFMA result matures.
	ds_read_b128 v[16:19], v97 offset:8192
	ds_read_b128 v[20:23], v97 offset:9216
	ds_read_b128 v[24:27], v97 offset:10240
	ds_read_b128 v[28:31], v97 offset:11264
	ds_read_b128 v[32:35], v97 offset:12288
	ds_read_b128 v[36:39], v97 offset:13312
	ds_read_b128 v[40:43], v97 offset:14336
	ds_read_b128 v[44:47], v97 offset:15360
	s_nop 4
	v_mul_f32_e32 v48, s72, v48
	v_fmac_f32_e32 v64, v80, v48
	v_mul_f32_e32 v49, s72, v49
	v_fmac_f32_e32 v65, v81, v49
	v_mul_f32_e32 v50, s72, v50
	v_fmac_f32_e32 v66, v82, v50
	v_mul_f32_e32 v51, s72, v51
	v_fmac_f32_e32 v67, v83, v51
	v_mul_f32_e32 v52, s72, v52
	v_fmac_f32_e32 v68, v80, v52
	v_mul_f32_e32 v53, s72, v53
	v_fmac_f32_e32 v69, v81, v53
	v_mul_f32_e32 v54, s72, v54
	v_fmac_f32_e32 v70, v82, v54
	v_mul_f32_e32 v55, s72, v55
	v_fmac_f32_e32 v71, v83, v55
	v_mul_f32_e32 v56, s72, v56
	v_fmac_f32_e32 v72, v80, v56
	v_mul_f32_e32 v57, s72, v57
	v_fmac_f32_e32 v73, v81, v57
	v_mul_f32_e32 v58, s72, v58
	v_fmac_f32_e32 v74, v82, v58
	v_mul_f32_e32 v59, s72, v59
	v_fmac_f32_e32 v75, v83, v59
	v_mul_f32_e32 v60, s72, v60
	v_fmac_f32_e32 v76, v80, v60
	v_mul_f32_e32 v61, s72, v61
	v_fmac_f32_e32 v77, v81, v61
	v_mul_f32_e32 v62, s72, v62
	v_fmac_f32_e32 v78, v82, v62
	v_mul_f32_e32 v63, s72, v63
	v_fmac_f32_e32 v79, v83, v63
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	s_nop 12
	v_mul_f32_e32 v48, s73, v48
	v_fmac_f32_e32 v100, v80, v48
	v_mul_f32_e32 v49, s73, v49
	v_fmac_f32_e32 v101, v81, v49
	v_mul_f32_e32 v50, s73, v50
	v_fmac_f32_e32 v102, v82, v50
	v_mul_f32_e32 v51, s73, v51
	v_fmac_f32_e32 v103, v83, v51
	v_mul_f32_e32 v52, s73, v52
	v_fmac_f32_e32 v104, v80, v52
	v_mul_f32_e32 v53, s73, v53
	v_fmac_f32_e32 v105, v81, v53
	v_mul_f32_e32 v54, s73, v54
	v_fmac_f32_e32 v106, v82, v54
	v_mul_f32_e32 v55, s73, v55
	v_fmac_f32_e32 v107, v83, v55
	v_mul_f32_e32 v56, s73, v56
	v_fmac_f32_e32 v108, v80, v56
	v_mul_f32_e32 v57, s73, v57
	v_fmac_f32_e32 v109, v81, v57
	v_mul_f32_e32 v58, s73, v58
	v_fmac_f32_e32 v110, v82, v58
	v_mul_f32_e32 v59, s73, v59
	v_fmac_f32_e32 v111, v83, v59
	v_mul_f32_e32 v60, s73, v60
	v_fmac_f32_e32 v112, v80, v60
	v_mul_f32_e32 v61, s73, v61
	v_fmac_f32_e32 v113, v81, v61
	v_mul_f32_e32 v62, s73, v62
	v_fmac_f32_e32 v114, v82, v62
	v_mul_f32_e32 v63, s73, v63
	v_fmac_f32_e32 v115, v83, v63
	s_cmp_lt_u32 s38, 16
	s_cbranch_scc0 .L_064c
	s_lshl_b32 s54, s38, 7
	v_add_u32_e32 v96, s54, v94
	global_load_dwordx4 v[8:11], v96, s[4:5]
	global_load_dwordx4 v[12:15], v96, s[4:5] offset:64
	s_lshl_b32 s55, s38, 2
	v_lshlrev_b32_e32 v96, 6, v84
	v_add_u32_e32 v96, s55, v96
	global_load_dword v80, v96, s[6:7]
	v_lshlrev_b32_e32 v96, 6, v85
	v_add_u32_e32 v96, s55, v96
	global_load_dword v81, v96, s[6:7]
	v_lshlrev_b32_e32 v96, 6, v86
	v_add_u32_e32 v96, s55, v96
	global_load_dword v82, v96, s[6:7]
	v_lshlrev_b32_e32 v96, 6, v87
	v_add_u32_e32 v96, s55, v96
	global_load_dword v83, v96, s[6:7]
	s_add_u32 s54, s31, s55
	s_load_dword s72, s[34:35], s54
	s_add_u32 s54, s54, 0x100
	s_load_dword s73, s[34:35], s54
.L_064c:
	s_cmp_eq_u32 s79, 0
	s_cbranch_scc1 .L_w13_pp_path
	// Pass one retains the established single-bank overwrite schedule.
	s_barrier
	s_cmp_lt_u32 s38, 16
	s_cbranch_scc1 .L_0358
	s_branch .L_w13_after_k
.L_w13_pp_path:
	s_cmp_lt_u32 s38, 16
	s_cbranch_scc0 .L_w13_pp_finished
	// Drain the next direct-to-LDS W13 slab while leaving the six A/scale
	// requests in flight.  This barrier also retires reads of the old bank.
	s_cmp_eq_u64 s[66:67], 0
	s_cbranch_scc1 .L_w13_pp_padwait
	s_waitcnt vmcnt(6)
	s_branch .L_w13_pp_waited
.L_w13_pp_padwait:
	s_waitcnt vmcnt(0)
.L_w13_pp_waited:
	s_xor_b32 s74, s74, 0x4000
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_branch .L_w13_pp_advance
.L_w13_pp_finished:
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	.endm
