// SPDX-License-Identifier: MIT
// Fixed split-K2 W2 MFMA schedule and FP16 partial stores.

	.macro NETRA_MOE_PREFILL_FUSED_SPLITK2_DOWN_PARTIAL
.L_0ca4:
	s_lshl_b32 s30, s80, 17
	s_add_u32 s32, s68, s30
	s_addc_u32 s33, s69, 0
	s_lshl_b32 s30, s80, 5
	s_add_u32 s37, s31, s30
	v_mov_b32_e32 v128, 0
	v_mov_b32_e32 v129, 0
	v_mov_b32_e32 v130, 0
	v_mov_b32_e32 v131, 0
	v_mov_b32_e32 v132, 0
	v_mov_b32_e32 v133, 0
	v_mov_b32_e32 v134, 0
	v_mov_b32_e32 v135, 0
	v_mov_b32_e32 v136, 0
	v_mov_b32_e32 v137, 0
	v_mov_b32_e32 v138, 0
	v_mov_b32_e32 v139, 0
	v_mov_b32_e32 v140, 0
	v_mov_b32_e32 v141, 0
	v_mov_b32_e32 v142, 0
	v_mov_b32_e32 v143, 0
	v_mov_b32_e32 v144, 0
	v_mov_b32_e32 v145, 0
	v_mov_b32_e32 v146, 0
	v_mov_b32_e32 v147, 0
	v_mov_b32_e32 v148, 0
	v_mov_b32_e32 v149, 0
	v_mov_b32_e32 v150, 0
	v_mov_b32_e32 v151, 0
	v_mov_b32_e32 v152, 0
	v_mov_b32_e32 v153, 0
	v_mov_b32_e32 v154, 0
	v_mov_b32_e32 v155, 0
	v_mov_b32_e32 v156, 0
	v_mov_b32_e32 v157, 0
	v_mov_b32_e32 v158, 0
	v_mov_b32_e32 v159, 0
	v_mov_b32_e32 v160, 0
	v_mov_b32_e32 v161, 0
	v_mov_b32_e32 v162, 0
	v_mov_b32_e32 v163, 0
	v_mov_b32_e32 v164, 0
	v_mov_b32_e32 v165, 0
	v_mov_b32_e32 v166, 0
	v_mov_b32_e32 v167, 0
	v_mov_b32_e32 v168, 0
	v_mov_b32_e32 v169, 0
	v_mov_b32_e32 v170, 0
	v_mov_b32_e32 v171, 0
	v_mov_b32_e32 v172, 0
	v_mov_b32_e32 v173, 0
	v_mov_b32_e32 v174, 0
	v_mov_b32_e32 v175, 0
	v_mov_b32_e32 v176, 0
	v_mov_b32_e32 v177, 0
	v_mov_b32_e32 v178, 0
	v_mov_b32_e32 v179, 0
	v_mov_b32_e32 v180, 0
	v_mov_b32_e32 v181, 0
	v_mov_b32_e32 v182, 0
	v_mov_b32_e32 v183, 0
	v_mov_b32_e32 v184, 0
	v_mov_b32_e32 v185, 0
	v_mov_b32_e32 v186, 0
	v_mov_b32_e32 v187, 0
	v_mov_b32_e32 v188, 0
	v_mov_b32_e32 v189, 0
	v_mov_b32_e32 v190, 0
	v_mov_b32_e32 v191, 0
	s_mov_b32 s38, s88
	// Software-pipelined W2 K loop mirroring the W13 pipeline:
	// the next 32 KiB W2 slab is in flight in v[192:223] while the
	// current slab computes; activation fragments and scales
	// prefetch after the ACC chains consume the previous values.
	s_lshl_b32 s39, s38, 11
	v_add_u32_e32 v99, s39, v96
	s_cmp_lt_u32 s75, 128
	s_cbranch_scc0 .L_w2_half_prime_done
	global_load_dwordx4 v[192:195], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[196:199], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[200:203], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[204:207], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[208:211], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[212:215], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[216:219], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[220:223], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[224:227], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[228:231], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[232:235], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[236:239], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[240:243], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[244:247], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[248:251], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[252:255], v99, s[32:33]
.L_w2_half_prime_done:
	s_cmp_eq_u64 s[66:67], 0
	s_cbranch_scc1 .L_w2_primed
	s_lshl_b32 s54, s38, 7
	v_add_u32_e32 v100, s54, v98
	ds_read_b128 v[8:11], v100
	ds_read_b128 v[12:15], v100 offset:64
	v_lshrrev_b32_e32 v100, 2, v2
	v_add_u32_e32 v100, v5, v100
	v_add_u32_e32 v100, s27, v100
	v_lshlrev_b32_e32 v100, 4, v100
	s_lshl_b32 s54, s38, 2
	v_add_u32_e32 v100, s54, v100
	global_load_dword v108, v100, s[84:85]
	global_load_dword v109, v100, s[84:85] offset:16
	global_load_dword v110, v100, s[84:85] offset:32
	global_load_dword v111, v100, s[84:85] offset:48
	s_add_u32 s54, s37, s54
	s_load_dword s72, s[70:71], s54
	s_add_u32 s54, s54, 16
	s_load_dword s73, s[70:71], s54
.L_w2_primed:
.L_0dbc:
	// Drain the sixteen current B loads while leaving the four activation
	// scale loads in flight.  Padding waves issue no scale loads.
	s_cmp_lt_u32 s75, 128
	s_cbranch_scc0 .L_w2_half_write_done
	s_cmp_eq_u64 s[66:67], 0
	s_cbranch_scc1 .L_w2_sk2_padwait
	s_waitcnt vmcnt(4)
	s_branch .L_w2_sk2_waited
.L_w2_sk2_padwait:
	s_waitcnt vmcnt(0)
.L_w2_sk2_waited:
	v_add_u32_e32 v100, 0x8000, v96
	ds_write_b128 v100, v[192:195]
	ds_write_b128 v100, v[196:199] offset:2048
	ds_write_b128 v100, v[200:203] offset:4096
	ds_write_b128 v100, v[204:207] offset:6144
	ds_write_b128 v100, v[208:211] offset:8192
	ds_write_b128 v100, v[212:215] offset:10240
	ds_write_b128 v100, v[216:219] offset:12288
	ds_write_b128 v100, v[220:223] offset:14336
	ds_write_b128 v100, v[224:227] offset:16384
	ds_write_b128 v100, v[228:231] offset:18432
	ds_write_b128 v100, v[232:235] offset:20480
	ds_write_b128 v100, v[236:239] offset:22528
	ds_write_b128 v100, v[240:243] offset:24576
	ds_write_b128 v100, v[244:247] offset:26624
	ds_write_b128 v100, v[248:251] offset:28672
	ds_write_b128 v100, v[252:255] offset:30720
.L_w2_half_write_done:
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_add_u32 s38, s38, 1
	s_cmp_lt_u32 s38, s89
	s_cbranch_scc0 .L_w2_nopf
	s_lshl_b32 s39, s38, 11
	v_add_u32_e32 v99, s39, v96
	s_cmp_lt_u32 s75, 128
	s_cbranch_scc0 .L_w2_nopf
	global_load_dwordx4 v[192:195], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[196:199], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[200:203], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[204:207], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[208:211], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[212:215], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[216:219], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[220:223], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[224:227], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[228:231], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[232:235], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[236:239], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[240:243], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[244:247], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[248:251], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx4 v[252:255], v99, s[32:33]
.L_w2_nopf:
	s_cmp_eq_u64 s[66:67], 0
	s_cbranch_scc1 .L_1368
	ds_read_b128 v[16:19], v97
	ds_read_b128 v[20:23], v97 offset:1024
	ds_read_b128 v[24:27], v97 offset:2048
	ds_read_b128 v[28:31], v97 offset:3072
	ds_read_b128 v[32:35], v97 offset:4096
	ds_read_b128 v[36:39], v97 offset:5120
	ds_read_b128 v[40:43], v97 offset:6144
	ds_read_b128 v[44:47], v97 offset:7168
	// Complete the four older activation-scale loads and keep the sixteen
	// next-slab B loads in flight whenever the split half has another K.
	s_cmp_lt_u32 s38, s89
	s_cbranch_scc0 .L_w2_sk2_lastwait
	s_cmp_lt_u32 s75, 128
	s_cbranch_scc0 .L_w2_half_consumer_wait
	s_waitcnt vmcnt(16) lgkmcnt(0)
	s_branch .L_w2_sk2_mfma
.L_w2_half_consumer_wait:
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_branch .L_w2_sk2_mfma
.L_w2_sk2_lastwait:
	s_waitcnt vmcnt(0) lgkmcnt(0)
.L_w2_sk2_mfma:
	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
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
	v_fmac_f32_e32 v128, v108, v48
	v_mul_f32_e32 v49, s72, v49
	v_fmac_f32_e32 v129, v109, v49
	v_mul_f32_e32 v50, s72, v50
	v_fmac_f32_e32 v130, v110, v50
	v_mul_f32_e32 v51, s72, v51
	v_fmac_f32_e32 v131, v111, v51
	v_mul_f32_e32 v52, s72, v52
	v_fmac_f32_e32 v132, v108, v52
	v_mul_f32_e32 v53, s72, v53
	v_fmac_f32_e32 v133, v109, v53
	v_mul_f32_e32 v54, s72, v54
	v_fmac_f32_e32 v134, v110, v54
	v_mul_f32_e32 v55, s72, v55
	v_fmac_f32_e32 v135, v111, v55
	v_mul_f32_e32 v56, s72, v56
	v_fmac_f32_e32 v136, v108, v56
	v_mul_f32_e32 v57, s72, v57
	v_fmac_f32_e32 v137, v109, v57
	v_mul_f32_e32 v58, s72, v58
	v_fmac_f32_e32 v138, v110, v58
	v_mul_f32_e32 v59, s72, v59
	v_fmac_f32_e32 v139, v111, v59
	v_mul_f32_e32 v60, s72, v60
	v_fmac_f32_e32 v140, v108, v60
	v_mul_f32_e32 v61, s72, v61
	v_fmac_f32_e32 v141, v109, v61
	v_mul_f32_e32 v62, s72, v62
	v_fmac_f32_e32 v142, v110, v62
	v_mul_f32_e32 v63, s72, v63
	v_fmac_f32_e32 v143, v111, v63
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	ds_read_b128 v[16:19], v97 offset:16384
	ds_read_b128 v[20:23], v97 offset:17408
	ds_read_b128 v[24:27], v97 offset:18432
	ds_read_b128 v[28:31], v97 offset:19456
	ds_read_b128 v[32:35], v97 offset:20480
	ds_read_b128 v[36:39], v97 offset:21504
	ds_read_b128 v[40:43], v97 offset:22528
	ds_read_b128 v[44:47], v97 offset:23552
	s_nop 4
	v_mul_f32_e32 v48, s72, v48
	v_fmac_f32_e32 v144, v108, v48
	v_mul_f32_e32 v49, s72, v49
	v_fmac_f32_e32 v145, v109, v49
	v_mul_f32_e32 v50, s72, v50
	v_fmac_f32_e32 v146, v110, v50
	v_mul_f32_e32 v51, s72, v51
	v_fmac_f32_e32 v147, v111, v51
	v_mul_f32_e32 v52, s72, v52
	v_fmac_f32_e32 v148, v108, v52
	v_mul_f32_e32 v53, s72, v53
	v_fmac_f32_e32 v149, v109, v53
	v_mul_f32_e32 v54, s72, v54
	v_fmac_f32_e32 v150, v110, v54
	v_mul_f32_e32 v55, s72, v55
	v_fmac_f32_e32 v151, v111, v55
	v_mul_f32_e32 v56, s72, v56
	v_fmac_f32_e32 v152, v108, v56
	v_mul_f32_e32 v57, s72, v57
	v_fmac_f32_e32 v153, v109, v57
	v_mul_f32_e32 v58, s72, v58
	v_fmac_f32_e32 v154, v110, v58
	v_mul_f32_e32 v59, s72, v59
	v_fmac_f32_e32 v155, v111, v59
	v_mul_f32_e32 v60, s72, v60
	v_fmac_f32_e32 v156, v108, v60
	v_mul_f32_e32 v61, s72, v61
	v_fmac_f32_e32 v157, v109, v61
	v_mul_f32_e32 v62, s72, v62
	v_fmac_f32_e32 v158, v110, v62
	v_mul_f32_e32 v63, s72, v63
	v_fmac_f32_e32 v159, v111, v63
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	ds_read_b128 v[16:19], v97 offset:24576
	ds_read_b128 v[20:23], v97 offset:25600
	ds_read_b128 v[24:27], v97 offset:26624
	ds_read_b128 v[28:31], v97 offset:27648
	ds_read_b128 v[32:35], v97 offset:28672
	ds_read_b128 v[36:39], v97 offset:29696
	ds_read_b128 v[40:43], v97 offset:30720
	ds_read_b128 v[44:47], v97 offset:31744
	s_nop 4
	v_mul_f32_e32 v48, s73, v48
	v_fmac_f32_e32 v160, v108, v48
	v_mul_f32_e32 v49, s73, v49
	v_fmac_f32_e32 v161, v109, v49
	v_mul_f32_e32 v50, s73, v50
	v_fmac_f32_e32 v162, v110, v50
	v_mul_f32_e32 v51, s73, v51
	v_fmac_f32_e32 v163, v111, v51
	v_mul_f32_e32 v52, s73, v52
	v_fmac_f32_e32 v164, v108, v52
	v_mul_f32_e32 v53, s73, v53
	v_fmac_f32_e32 v165, v109, v53
	v_mul_f32_e32 v54, s73, v54
	v_fmac_f32_e32 v166, v110, v54
	v_mul_f32_e32 v55, s73, v55
	v_fmac_f32_e32 v167, v111, v55
	v_mul_f32_e32 v56, s73, v56
	v_fmac_f32_e32 v168, v108, v56
	v_mul_f32_e32 v57, s73, v57
	v_fmac_f32_e32 v169, v109, v57
	v_mul_f32_e32 v58, s73, v58
	v_fmac_f32_e32 v170, v110, v58
	v_mul_f32_e32 v59, s73, v59
	v_fmac_f32_e32 v171, v111, v59
	v_mul_f32_e32 v60, s73, v60
	v_fmac_f32_e32 v172, v108, v60
	v_mul_f32_e32 v61, s73, v61
	v_fmac_f32_e32 v173, v109, v61
	v_mul_f32_e32 v62, s73, v62
	v_fmac_f32_e32 v174, v110, v62
	v_mul_f32_e32 v63, s73, v63
	v_fmac_f32_e32 v175, v111, v63
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	s_nop 12
	v_mul_f32_e32 v48, s73, v48
	v_fmac_f32_e32 v176, v108, v48
	v_mul_f32_e32 v49, s73, v49
	v_fmac_f32_e32 v177, v109, v49
	v_mul_f32_e32 v50, s73, v50
	v_fmac_f32_e32 v178, v110, v50
	v_mul_f32_e32 v51, s73, v51
	v_fmac_f32_e32 v179, v111, v51
	v_mul_f32_e32 v52, s73, v52
	v_fmac_f32_e32 v180, v108, v52
	v_mul_f32_e32 v53, s73, v53
	v_fmac_f32_e32 v181, v109, v53
	v_mul_f32_e32 v54, s73, v54
	v_fmac_f32_e32 v182, v110, v54
	v_mul_f32_e32 v55, s73, v55
	v_fmac_f32_e32 v183, v111, v55
	v_mul_f32_e32 v56, s73, v56
	v_fmac_f32_e32 v184, v108, v56
	v_mul_f32_e32 v57, s73, v57
	v_fmac_f32_e32 v185, v109, v57
	v_mul_f32_e32 v58, s73, v58
	v_fmac_f32_e32 v186, v110, v58
	v_mul_f32_e32 v59, s73, v59
	v_fmac_f32_e32 v187, v111, v59
	v_mul_f32_e32 v60, s73, v60
	v_fmac_f32_e32 v188, v108, v60
	v_mul_f32_e32 v61, s73, v61
	v_fmac_f32_e32 v189, v109, v61
	v_mul_f32_e32 v62, s73, v62
	v_fmac_f32_e32 v190, v110, v62
	v_mul_f32_e32 v63, s73, v63
	v_fmac_f32_e32 v191, v111, v63
	s_cmp_lt_u32 s38, s89
	s_cbranch_scc0 .L_1368
	s_lshl_b32 s54, s38, 7
	v_add_u32_e32 v100, s54, v98
	ds_read_b128 v[8:11], v100
	ds_read_b128 v[12:15], v100 offset:64
	v_lshrrev_b32_e32 v100, 2, v2
	v_add_u32_e32 v100, v5, v100
	v_add_u32_e32 v100, s27, v100
	v_lshlrev_b32_e32 v100, 4, v100
	s_lshl_b32 s54, s38, 2
	v_add_u32_e32 v100, s54, v100
	global_load_dword v108, v100, s[84:85]
	global_load_dword v109, v100, s[84:85] offset:16
	global_load_dword v110, v100, s[84:85] offset:32
	global_load_dword v111, v100, s[84:85] offset:48
	s_add_u32 s54, s37, s54
	s_load_dword s72, s[70:71], s54
	s_add_u32 s54, s54, 16
	s_load_dword s73, s[70:71], s54
.L_1368:
	s_barrier
	s_cmp_lt_u32 s38, s89
	s_cbranch_scc1 .L_0dbc
	s_cmp_eq_u64 s[66:67], 0
	s_cbranch_scc1 .L_1834
	s_lshl_b32 s54, s80, 8
	v_add_u32_e32 v115, s54, v1
	// Form the four route bases once.  All later output groups use the global
	// instruction's immediate byte offset instead of rebuilding these bases.
	v_add_u32_e32 v116, 0, v115
	v_lshlrev_b32_e32 v116, 1, v116
	v_lshlrev_b32_e32 v117, 12, v120
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 12, v121
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 12, v122
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 12, v123
	v_add_u32_e32 v124, v116, v124
	v_cvt_pk_f16_f32 v16, v128, v129
	v_cvt_pk_f16_f32 v17, v130, v131
	global_store_short v117, v16, s[24:25]
	global_store_short_d16_hi v118, v16, s[24:25]
	global_store_short v119, v17, s[24:25]
	global_store_short_d16_hi v124, v17, s[24:25]
	v_cvt_pk_f16_f32 v16, v132, v133
	v_cvt_pk_f16_f32 v17, v134, v135
	global_store_short v117, v16, s[24:25] offset:32
	global_store_short_d16_hi v118, v16, s[24:25] offset:32
	global_store_short v119, v17, s[24:25] offset:32
	global_store_short_d16_hi v124, v17, s[24:25] offset:32
	v_cvt_pk_f16_f32 v16, v136, v137
	v_cvt_pk_f16_f32 v17, v138, v139
	global_store_short v117, v16, s[24:25] offset:64
	global_store_short_d16_hi v118, v16, s[24:25] offset:64
	global_store_short v119, v17, s[24:25] offset:64
	global_store_short_d16_hi v124, v17, s[24:25] offset:64
	v_cvt_pk_f16_f32 v16, v140, v141
	v_cvt_pk_f16_f32 v17, v142, v143
	global_store_short v117, v16, s[24:25] offset:96
	global_store_short_d16_hi v118, v16, s[24:25] offset:96
	global_store_short v119, v17, s[24:25] offset:96
	global_store_short_d16_hi v124, v17, s[24:25] offset:96
	v_cvt_pk_f16_f32 v16, v144, v145
	v_cvt_pk_f16_f32 v17, v146, v147
	global_store_short v117, v16, s[24:25] offset:128
	global_store_short_d16_hi v118, v16, s[24:25] offset:128
	global_store_short v119, v17, s[24:25] offset:128
	global_store_short_d16_hi v124, v17, s[24:25] offset:128
	v_cvt_pk_f16_f32 v16, v148, v149
	v_cvt_pk_f16_f32 v17, v150, v151
	global_store_short v117, v16, s[24:25] offset:160
	global_store_short_d16_hi v118, v16, s[24:25] offset:160
	global_store_short v119, v17, s[24:25] offset:160
	global_store_short_d16_hi v124, v17, s[24:25] offset:160
	v_cvt_pk_f16_f32 v16, v152, v153
	v_cvt_pk_f16_f32 v17, v154, v155
	global_store_short v117, v16, s[24:25] offset:192
	global_store_short_d16_hi v118, v16, s[24:25] offset:192
	global_store_short v119, v17, s[24:25] offset:192
	global_store_short_d16_hi v124, v17, s[24:25] offset:192
	v_cvt_pk_f16_f32 v16, v156, v157
	v_cvt_pk_f16_f32 v17, v158, v159
	global_store_short v117, v16, s[24:25] offset:224
	global_store_short_d16_hi v118, v16, s[24:25] offset:224
	global_store_short v119, v17, s[24:25] offset:224
	global_store_short_d16_hi v124, v17, s[24:25] offset:224
	v_cvt_pk_f16_f32 v16, v160, v161
	v_cvt_pk_f16_f32 v17, v162, v163
	global_store_short v117, v16, s[24:25] offset:256
	global_store_short_d16_hi v118, v16, s[24:25] offset:256
	global_store_short v119, v17, s[24:25] offset:256
	global_store_short_d16_hi v124, v17, s[24:25] offset:256
	v_cvt_pk_f16_f32 v16, v164, v165
	v_cvt_pk_f16_f32 v17, v166, v167
	global_store_short v117, v16, s[24:25] offset:288
	global_store_short_d16_hi v118, v16, s[24:25] offset:288
	global_store_short v119, v17, s[24:25] offset:288
	global_store_short_d16_hi v124, v17, s[24:25] offset:288
	v_cvt_pk_f16_f32 v16, v168, v169
	v_cvt_pk_f16_f32 v17, v170, v171
	global_store_short v117, v16, s[24:25] offset:320
	global_store_short_d16_hi v118, v16, s[24:25] offset:320
	global_store_short v119, v17, s[24:25] offset:320
	global_store_short_d16_hi v124, v17, s[24:25] offset:320
	v_cvt_pk_f16_f32 v16, v172, v173
	v_cvt_pk_f16_f32 v17, v174, v175
	global_store_short v117, v16, s[24:25] offset:352
	global_store_short_d16_hi v118, v16, s[24:25] offset:352
	global_store_short v119, v17, s[24:25] offset:352
	global_store_short_d16_hi v124, v17, s[24:25] offset:352
	v_cvt_pk_f16_f32 v16, v176, v177
	v_cvt_pk_f16_f32 v17, v178, v179
	global_store_short v117, v16, s[24:25] offset:384
	global_store_short_d16_hi v118, v16, s[24:25] offset:384
	global_store_short v119, v17, s[24:25] offset:384
	global_store_short_d16_hi v124, v17, s[24:25] offset:384
	v_cvt_pk_f16_f32 v16, v180, v181
	v_cvt_pk_f16_f32 v17, v182, v183
	global_store_short v117, v16, s[24:25] offset:416
	global_store_short_d16_hi v118, v16, s[24:25] offset:416
	global_store_short v119, v17, s[24:25] offset:416
	global_store_short_d16_hi v124, v17, s[24:25] offset:416
	v_cvt_pk_f16_f32 v16, v184, v185
	v_cvt_pk_f16_f32 v17, v186, v187
	global_store_short v117, v16, s[24:25] offset:448
	global_store_short_d16_hi v118, v16, s[24:25] offset:448
	global_store_short v119, v17, s[24:25] offset:448
	global_store_short_d16_hi v124, v17, s[24:25] offset:448
	v_cvt_pk_f16_f32 v16, v188, v189
	v_cvt_pk_f16_f32 v17, v190, v191
	global_store_short v117, v16, s[24:25] offset:480
	global_store_short_d16_hi v118, v16, s[24:25] offset:480
	global_store_short v119, v17, s[24:25] offset:480
	global_store_short_d16_hi v124, v17, s[24:25] offset:480
.L_1834:
	s_waitcnt vmcnt(0)
	s_add_u32 s80, s80, 1
	s_cmp_lt_u32 s80, 8
	s_cbranch_scc1 .L_0ca4
.L_1844:
	s_endpgm

	.endm
