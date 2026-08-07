// SPDX-License-Identifier: MIT
//
// Qwen3.6 FP8 E4M3 one-stage routed expert kernel, deterministic partial
// output variant with software-pipelined W13 and W2 weight streams: the
// next weight slab is always in flight in staging v[192:223] while the
// current slab computes, and A fragments/scales prefetch after the ACC
// chains. Same kernel symbol and ABI as the unpipelined baseline.
// output variant, reconstructed from the retained 2026-08-07 code object
// (SHA-verified disassembly round trip). One workgroup owns a complete
// expert-sorted M64 route block: W13 -> SiLU -> FP8 quant -> W2, writing
// per-route FP32 partials in slot order for the fixed-order reducer.
//
// Grid:      (1, ceil(num_valid_ids/64), 1)
// Workgroup: (256, 1, 1), four wave64s
// LDS:       64 KiB

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_fused_m64n256_partial_fp8_gfx950
	.globl qwen36_moe_fused_m64n256_partial_fp8_gfx950
	.p2align 8
	.type qwen36_moe_fused_m64n256_partial_fp8_gfx950,@function
qwen36_moe_fused_m64n256_partial_fp8_gfx950:
	s_load_dwordx2 s[4:5], s[0:1], 0x0
	s_load_dwordx2 s[6:7], s[0:1], 0x8
	s_load_dwordx2 s[8:9], s[0:1], 0x10
	s_load_dwordx2 s[10:11], s[0:1], 0x18
	s_load_dwordx2 s[12:13], s[0:1], 0x20
	s_load_dwordx2 s[14:15], s[0:1], 0x28
	s_load_dwordx2 s[16:17], s[0:1], 0x30
	s_load_dwordx2 s[18:19], s[0:1], 0x38
	s_load_dwordx2 s[20:21], s[0:1], 0x40
	s_load_dwordx2 s[22:23], s[0:1], 0x48
	s_load_dwordx2 s[24:25], s[0:1], 0x50
	s_load_dword s26, s[0:1], 0x58
	s_load_dwordx2 s[84:85], s[0:1], 0x60
	s_load_dword s86, s[0:1], 0x68
	s_waitcnt lgkmcnt(0)
	s_lshl_b32 s27, s3, 6
	s_load_dword s28, s[22:23], 0x0
	s_lshl_b32 s29, s3, 2
	s_load_dword s29, s[20:21], s29
	s_waitcnt lgkmcnt(0)
	s_cmp_lt_u32 s27, s28
	s_cbranch_scc0 .L_1844
	v_and_b32_e32 v1, 15, v0
	v_and_b32_e32 v2, 48, v0
	v_lshrrev_b32_e32 v3, 6, v0
	v_lshlrev_b32_e32 v5, 4, v3
	v_add_u32_e32 v5, s27, v5
	v_add_u32_e32 v3, v5, v1
	v_lshlrev_b32_e32 v3, 2, v3
	global_load_dword v4, v3, s[16:17]
	v_lshrrev_b32_e32 v3, 2, v2
	v_add_u32_e32 v88, v5, v3
	v_add_u32_e32 v89, 1, v88
	v_add_u32_e32 v90, 2, v88
	v_add_u32_e32 v91, 3, v88
	v_lshlrev_b32_e32 v3, 2, v88
	global_load_dword v84, v3, s[16:17]
	global_load_dword v85, v3, s[16:17] offset:4
	global_load_dword v86, v3, s[16:17] offset:8
	global_load_dword v87, v3, s[16:17] offset:12
	s_waitcnt vmcnt(0)
	v_lshrrev_b32_e32 v6, 24, v4
	v_and_b32_e32 v4, 0xffffff, v4
	v_cmp_gt_u32_e32 vcc, s26, v4
	v_cndmask_b32_e32 v4, 0, v4, vcc
	v_cmp_gt_u32_e32 vcc, 9, v6
	v_cndmask_b32_e32 v4, 0, v4, vcc
	v_lshrrev_b32_e32 v6, 24, v84
	v_and_b32_e32 v7, 0xffffff, v84
	v_mul_lo_u32 v120, 9, v7
	v_add_u32_e32 v120, v6, v120
	v_cmp_gt_u32_e64 s[56:57], 9, v6
	v_cmp_gt_u32_e64 s[82:83], s26, v7
	s_and_b64 s[56:57], s[56:57], s[82:83]
	v_cndmask_b32_e64 v84, 0, v7, s[56:57]
	v_lshrrev_b32_e32 v6, 24, v85
	v_and_b32_e32 v7, 0xffffff, v85
	v_mul_lo_u32 v121, 9, v7
	v_add_u32_e32 v121, v6, v121
	v_cmp_gt_u32_e64 s[58:59], 9, v6
	v_cmp_gt_u32_e64 s[82:83], s26, v7
	s_and_b64 s[58:59], s[58:59], s[82:83]
	v_cndmask_b32_e64 v85, 0, v7, s[58:59]
	v_lshrrev_b32_e32 v6, 24, v86
	v_and_b32_e32 v7, 0xffffff, v86
	v_mul_lo_u32 v122, 9, v7
	v_add_u32_e32 v122, v6, v122
	v_cmp_gt_u32_e64 s[60:61], 9, v6
	v_cmp_gt_u32_e64 s[82:83], s26, v7
	s_and_b64 s[60:61], s[60:61], s[82:83]
	v_cndmask_b32_e64 v86, 0, v7, s[60:61]
	v_lshrrev_b32_e32 v6, 24, v87
	v_and_b32_e32 v7, 0xffffff, v87
	v_mul_lo_u32 v123, 9, v7
	v_add_u32_e32 v123, v6, v123
	v_cmp_gt_u32_e64 s[62:63], 9, v6
	v_cmp_gt_u32_e64 s[82:83], s26, v7
	s_and_b64 s[62:63], s[62:63], s[82:83]
	v_cndmask_b32_e64 v87, 0, v7, s[62:63]
	s_mul_i32 s54, s26, 9
	s_add_u32 s54, s54, s3
	v_mov_b32_e32 v6, s54
	v_cndmask_b32_e64 v120, v6, v120, s[56:57]
	v_cndmask_b32_e64 v121, v6, v121, s[58:59]
	v_cndmask_b32_e64 v122, v6, v122, s[60:61]
	v_cndmask_b32_e64 v123, v6, v123, s[62:63]
	s_or_b64 s[66:67], s[56:57], s[58:59]
	s_or_b64 s[64:65], s[60:61], s[62:63]
	s_or_b64 s[66:67], s[66:67], s[64:65]
	v_lshlrev_b32_e32 v94, 11, v4
	v_add_u32_e32 v94, v2, v94
	v_lshlrev_b32_e32 v93, 4, v2
	v_lshlrev_b32_e32 v92, 4, v1
	v_add_u32_e32 v93, v93, v92
	v_add_u32_e32 v93, 0x8000, v93
	v_lshlrev_b32_e32 v92, 3, v0
	s_lshl_b32 s30, s29, 21
	s_add_u32 s68, s8, s30
	s_addc_u32 s69, s9, 0
	s_lshl_b32 s30, s29, 9
	s_add_u32 s70, s10, s30
	s_addc_u32 s71, s11, 0
	s_mov_b32 s80, 0
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
	// Software pipeline: slab s38 weights are always in flight in
	// staging v[192:207] at the loop head; A fragments and scales
	// for the next slab issue after the ACC chains consume them.
	s_lshl_b32 s39, s38, 11
	v_add_u32_e32 v95, s39, v92
	global_load_dwordx2 v[192:193], v95, s[36:37]
	global_load_dwordx2 v[194:195], v95, s[40:41]
	global_load_dwordx2 v[196:197], v95, s[42:43]
	global_load_dwordx2 v[198:199], v95, s[44:45]
	global_load_dwordx2 v[200:201], v95, s[46:47]
	global_load_dwordx2 v[202:203], v95, s[48:49]
	global_load_dwordx2 v[204:205], v95, s[50:51]
	global_load_dwordx2 v[206:207], v95, s[52:53]
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
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_add_u32_e32 v96, 0x8000, v92
	ds_write_b64 v96, v[192:193]
	ds_write_b64 v96, v[194:195] offset:2048
	ds_write_b64 v96, v[196:197] offset:4096
	ds_write_b64 v96, v[198:199] offset:6144
	ds_write_b64 v96, v[200:201] offset:8192
	ds_write_b64 v96, v[202:203] offset:10240
	ds_write_b64 v96, v[204:205] offset:12288
	ds_write_b64 v96, v[206:207] offset:14336
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_add_u32 s38, s38, 1
	s_cmp_lt_u32 s38, 16
	s_cbranch_scc0 .L_dbuf_nopf
	s_lshl_b32 s39, s38, 11
	v_add_u32_e32 v95, s39, v92
	global_load_dwordx2 v[192:193], v95, s[36:37]
	global_load_dwordx2 v[194:195], v95, s[40:41]
	global_load_dwordx2 v[196:197], v95, s[42:43]
	global_load_dwordx2 v[198:199], v95, s[44:45]
	global_load_dwordx2 v[200:201], v95, s[46:47]
	global_load_dwordx2 v[202:203], v95, s[48:49]
	global_load_dwordx2 v[204:205], v95, s[50:51]
	global_load_dwordx2 v[206:207], v95, s[52:53]
.L_dbuf_nopf:
	s_cmp_eq_u64 s[66:67], 0
	s_cbranch_scc1 .L_064c
	ds_read_b128 v[16:19], v93
	ds_read_b128 v[20:23], v93 offset:1024
	ds_read_b128 v[24:27], v93 offset:2048
	ds_read_b128 v[28:31], v93 offset:3072
	ds_read_b128 v[32:35], v93 offset:4096
	ds_read_b128 v[36:39], v93 offset:5120
	ds_read_b128 v[40:43], v93 offset:6144
	ds_read_b128 v[44:47], v93 offset:7168
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	s_nop 12
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
	ds_read_b128 v[16:19], v93 offset:8192
	ds_read_b128 v[20:23], v93 offset:9216
	ds_read_b128 v[24:27], v93 offset:10240
	ds_read_b128 v[28:31], v93 offset:11264
	ds_read_b128 v[32:35], v93 offset:12288
	ds_read_b128 v[36:39], v93 offset:13312
	ds_read_b128 v[40:43], v93 offset:14336
	ds_read_b128 v[44:47], v93 offset:15360
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
	s_barrier
	s_cmp_lt_u32 s38, 16
	s_cbranch_scc1 .L_0358
	s_cmp_eq_u64 s[66:67], 0
	s_cbranch_scc1 .L_09c8
	v_lshrrev_b32_e32 v32, 6, v0
	v_lshlrev_b32_e32 v32, 11, v32
	v_and_b32_e32 v33, 63, v0
	v_lshlrev_b32_e32 v33, 5, v33
	v_add_u32_e32 v32, v33, v32
	v_add_u32_e32 v32, 0xc000, v32
	s_xor_b32 s74, s79, 1
	s_lshl_b32 s74, s74, 13
	v_add_u32_e32 v32, s74, v32
	s_mov_b32 s74, 0xbfb8aa3b
	s_mov_b32 s75, 1.0
	v_cvt_pk_bf16_f32 v16, v64, v65
	v_cvt_pk_bf16_f32 v17, v66, v67
	v_cvt_pk_bf16_f32 v18, v100, v101
	v_cvt_pk_bf16_f32 v19, v102, v103
	v_lshlrev_b32_e32 v20, 16, v16
	v_and_b32_e32 v21, 0xffff0000, v16
	v_lshlrev_b32_e32 v22, 16, v17
	v_and_b32_e32 v23, 0xffff0000, v17
	v_lshlrev_b32_e32 v24, 16, v18
	v_and_b32_e32 v25, 0xffff0000, v18
	v_lshlrev_b32_e32 v26, 16, v19
	v_and_b32_e32 v27, 0xffff0000, v19
	v_mul_f32_e32 v28, s74, v20
	v_mul_f32_e32 v29, s74, v21
	v_mul_f32_e32 v30, s74, v22
	v_mul_f32_e32 v31, s74, v23
	v_exp_f32_e32 v28, v28
	v_exp_f32_e32 v29, v29
	v_exp_f32_e32 v30, v30
	v_exp_f32_e32 v31, v31
	v_add_f32_e32 v28, s75, v28
	v_add_f32_e32 v29, s75, v29
	v_add_f32_e32 v30, s75, v30
	v_add_f32_e32 v31, s75, v31
	v_rcp_f32_e32 v28, v28
	v_rcp_f32_e32 v29, v29
	v_rcp_f32_e32 v30, v30
	v_rcp_f32_e32 v31, v31
	v_mul_f32_e32 v20, v28, v20
	v_mul_f32_e32 v21, v29, v21
	v_mul_f32_e32 v22, v30, v22
	v_mul_f32_e32 v23, v31, v23
	v_mul_f32_e32 v20, v24, v20
	v_mul_f32_e32 v21, v25, v21
	v_mul_f32_e32 v22, v26, v22
	v_mul_f32_e32 v23, v27, v23
	v_cvt_pk_bf16_f32 v16, v20, v21
	v_cvt_pk_bf16_f32 v17, v22, v23
	v_add_u32_e32 v18, 0, v32
	ds_write_b64 v18, v[16:17]
	v_cvt_pk_bf16_f32 v16, v68, v69
	v_cvt_pk_bf16_f32 v17, v70, v71
	v_cvt_pk_bf16_f32 v18, v104, v105
	v_cvt_pk_bf16_f32 v19, v106, v107
	v_lshlrev_b32_e32 v20, 16, v16
	v_and_b32_e32 v21, 0xffff0000, v16
	v_lshlrev_b32_e32 v22, 16, v17
	v_and_b32_e32 v23, 0xffff0000, v17
	v_lshlrev_b32_e32 v24, 16, v18
	v_and_b32_e32 v25, 0xffff0000, v18
	v_lshlrev_b32_e32 v26, 16, v19
	v_and_b32_e32 v27, 0xffff0000, v19
	v_mul_f32_e32 v28, s74, v20
	v_mul_f32_e32 v29, s74, v21
	v_mul_f32_e32 v30, s74, v22
	v_mul_f32_e32 v31, s74, v23
	v_exp_f32_e32 v28, v28
	v_exp_f32_e32 v29, v29
	v_exp_f32_e32 v30, v30
	v_exp_f32_e32 v31, v31
	v_add_f32_e32 v28, s75, v28
	v_add_f32_e32 v29, s75, v29
	v_add_f32_e32 v30, s75, v30
	v_add_f32_e32 v31, s75, v31
	v_rcp_f32_e32 v28, v28
	v_rcp_f32_e32 v29, v29
	v_rcp_f32_e32 v30, v30
	v_rcp_f32_e32 v31, v31
	v_mul_f32_e32 v20, v28, v20
	v_mul_f32_e32 v21, v29, v21
	v_mul_f32_e32 v22, v30, v22
	v_mul_f32_e32 v23, v31, v23
	v_mul_f32_e32 v20, v24, v20
	v_mul_f32_e32 v21, v25, v21
	v_mul_f32_e32 v22, v26, v22
	v_mul_f32_e32 v23, v27, v23
	v_cvt_pk_bf16_f32 v16, v20, v21
	v_cvt_pk_bf16_f32 v17, v22, v23
	v_add_u32_e32 v18, 8, v32
	ds_write_b64 v18, v[16:17]
	v_cvt_pk_bf16_f32 v16, v72, v73
	v_cvt_pk_bf16_f32 v17, v74, v75
	v_cvt_pk_bf16_f32 v18, v108, v109
	v_cvt_pk_bf16_f32 v19, v110, v111
	v_lshlrev_b32_e32 v20, 16, v16
	v_and_b32_e32 v21, 0xffff0000, v16
	v_lshlrev_b32_e32 v22, 16, v17
	v_and_b32_e32 v23, 0xffff0000, v17
	v_lshlrev_b32_e32 v24, 16, v18
	v_and_b32_e32 v25, 0xffff0000, v18
	v_lshlrev_b32_e32 v26, 16, v19
	v_and_b32_e32 v27, 0xffff0000, v19
	v_mul_f32_e32 v28, s74, v20
	v_mul_f32_e32 v29, s74, v21
	v_mul_f32_e32 v30, s74, v22
	v_mul_f32_e32 v31, s74, v23
	v_exp_f32_e32 v28, v28
	v_exp_f32_e32 v29, v29
	v_exp_f32_e32 v30, v30
	v_exp_f32_e32 v31, v31
	v_add_f32_e32 v28, s75, v28
	v_add_f32_e32 v29, s75, v29
	v_add_f32_e32 v30, s75, v30
	v_add_f32_e32 v31, s75, v31
	v_rcp_f32_e32 v28, v28
	v_rcp_f32_e32 v29, v29
	v_rcp_f32_e32 v30, v30
	v_rcp_f32_e32 v31, v31
	v_mul_f32_e32 v20, v28, v20
	v_mul_f32_e32 v21, v29, v21
	v_mul_f32_e32 v22, v30, v22
	v_mul_f32_e32 v23, v31, v23
	v_mul_f32_e32 v20, v24, v20
	v_mul_f32_e32 v21, v25, v21
	v_mul_f32_e32 v22, v26, v22
	v_mul_f32_e32 v23, v27, v23
	v_cvt_pk_bf16_f32 v16, v20, v21
	v_cvt_pk_bf16_f32 v17, v22, v23
	v_add_u32_e32 v18, 16, v32
	ds_write_b64 v18, v[16:17]
	v_cvt_pk_bf16_f32 v16, v76, v77
	v_cvt_pk_bf16_f32 v17, v78, v79
	v_cvt_pk_bf16_f32 v18, v112, v113
	v_cvt_pk_bf16_f32 v19, v114, v115
	v_lshlrev_b32_e32 v20, 16, v16
	v_and_b32_e32 v21, 0xffff0000, v16
	v_lshlrev_b32_e32 v22, 16, v17
	v_and_b32_e32 v23, 0xffff0000, v17
	v_lshlrev_b32_e32 v24, 16, v18
	v_and_b32_e32 v25, 0xffff0000, v18
	v_lshlrev_b32_e32 v26, 16, v19
	v_and_b32_e32 v27, 0xffff0000, v19
	v_mul_f32_e32 v28, s74, v20
	v_mul_f32_e32 v29, s74, v21
	v_mul_f32_e32 v30, s74, v22
	v_mul_f32_e32 v31, s74, v23
	v_exp_f32_e32 v28, v28
	v_exp_f32_e32 v29, v29
	v_exp_f32_e32 v30, v30
	v_exp_f32_e32 v31, v31
	v_add_f32_e32 v28, s75, v28
	v_add_f32_e32 v29, s75, v29
	v_add_f32_e32 v30, s75, v30
	v_add_f32_e32 v31, s75, v31
	v_rcp_f32_e32 v28, v28
	v_rcp_f32_e32 v29, v29
	v_rcp_f32_e32 v30, v30
	v_rcp_f32_e32 v31, v31
	v_mul_f32_e32 v20, v28, v20
	v_mul_f32_e32 v21, v29, v21
	v_mul_f32_e32 v22, v30, v22
	v_mul_f32_e32 v23, v31, v23
	v_mul_f32_e32 v20, v24, v20
	v_mul_f32_e32 v21, v25, v21
	v_mul_f32_e32 v22, v26, v22
	v_mul_f32_e32 v23, v27, v23
	v_cvt_pk_bf16_f32 v16, v20, v21
	v_cvt_pk_bf16_f32 v17, v22, v23
	v_add_u32_e32 v18, 24, v32
	ds_write_b64 v18, v[16:17]
.L_09c8:
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_add_u32 s79, s79, 1
	s_cmp_lt_u32 s79, 2
	s_cbranch_scc1 .L_0274
	v_and_b32_e32 v1, 31, v0
	v_lshrrev_b32_e32 v2, 5, v0
	v_and_b32_e32 v25, 63, v0
	s_mov_b32 s76, 0
	s_mov_b32 s72, 0x3b124925
	s_mov_b32 s73, 0x2edbe6ff
	s_mov_b32 s74, 0x5040100
.L_0a04:
	s_lshl_b32 s77, s76, 3
	v_add_u32_e32 v3, s77, v2
	v_lshrrev_b32_e32 v6, 4, v3
	v_lshlrev_b32_e32 v6, 11, v6
	v_and_b32_e32 v7, 15, v3
	v_lshrrev_b32_e32 v8, 2, v7
	v_lshlrev_b32_e32 v8, 9, v8
	v_add_u32_e32 v6, v8, v6
	v_and_b32_e32 v8, 3, v7
	v_lshlrev_b32_e32 v8, 1, v8
	v_add_u32_e32 v6, v8, v6
	v_and_b32_e32 v8, 15, v1
	v_lshlrev_b32_e32 v8, 2, v8
	v_and_b32_e32 v9, 15, v8
	v_lshlrev_b32_e32 v9, 5, v9
	v_add_u32_e32 v6, v9, v6
	v_lshrrev_b32_e32 v9, 4, v8
	v_lshlrev_b32_e32 v9, 3, v9
	v_add_u32_e32 v6, v9, v6
	v_cmp_gt_u32_e32 vcc, 16, v1
	v_mov_b32_e32 v9, 0x2000
	v_cndmask_b32_e32 v9, 0, v9, vcc
	v_add_u32_e32 v6, v9, v6
	v_add_u32_e32 v6, 0xc000, v6
	ds_read_u16 v12, v6
	ds_read_u16 v13, v6 offset:32
	ds_read_u16 v14, v6 offset:64
	ds_read_u16 v15, v6 offset:96
	s_waitcnt lgkmcnt(0)
	v_lshlrev_b32_e32 v20, 16, v12
	v_lshlrev_b32_e32 v21, 16, v13
	v_lshlrev_b32_e32 v22, 16, v14
	v_lshlrev_b32_e32 v23, 16, v15
	v_max3_f32 v24, |v20|, |v21|, s73
	v_max3_f32 v24, v24, |v22|, |v23|
	v_xor_b32_e32 v26, 1, v25
	v_lshlrev_b32_e32 v26, 2, v26
	ds_bpermute_b32 v27, v26, v24
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v24, v24, v27
	v_xor_b32_e32 v26, 2, v25
	v_lshlrev_b32_e32 v26, 2, v26
	ds_bpermute_b32 v27, v26, v24
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v24, v24, v27
	v_xor_b32_e32 v26, 4, v25
	v_lshlrev_b32_e32 v26, 2, v26
	ds_bpermute_b32 v27, v26, v24
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v24, v24, v27
	v_xor_b32_e32 v26, 8, v25
	v_lshlrev_b32_e32 v26, 2, v26
	ds_bpermute_b32 v27, v26, v24
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v24, v24, v27
	v_xor_b32_e32 v26, 16, v25
	v_lshlrev_b32_e32 v26, 2, v26
	ds_bpermute_b32 v27, v26, v24
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v24, v24, v27
	v_mul_f32_e32 v24, s72, v24
	v_add_u32_e32 v26, s27, v3
	v_lshlrev_b32_e32 v26, 4, v26
	s_lshl_b32 s77, s80, 2
	v_add_u32_e32 v26, s77, v26
	v_cmp_eq_u32_e64 s[78:79], 0, v1
	s_and_saveexec_b64 s[82:83], s[78:79]
	global_store_dword v26, v24, s[84:85]
	s_or_b64 exec, exec, s[82:83]
	v_rcp_f32_e32 v26, v24
	s_nop 1
	v_fma_f32 v27, -v24, v26, 1.0
	s_nop 1
	v_fma_f32 v26, v27, v26, v26
	s_nop 1
	v_mul_f32_e32 v20, v26, v20
	v_mul_f32_e32 v21, v26, v21
	v_mul_f32_e32 v22, v26, v22
	v_mul_f32_e32 v23, v26, v23
	v_cvt_pk_fp8_f32 v28, v20, v21
	v_cvt_pk_fp8_f32 v29, v22, v23
	v_perm_b32 v28, v29, v28, s74
	v_lshlrev_b32_e32 v26, 9, v3
	s_lshl_b32 s77, s80, 7
	v_add_u32_e32 v26, s77, v26
	v_lshlrev_b32_e32 v27, 2, v1
	v_add_u32_e32 v26, v27, v26
	ds_write_b32 v26, v28
	s_add_u32 s76, s76, 1
	s_cmp_lt_u32 s76, 8
	s_cbranch_scc1 .L_0a04
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	s_add_u32 s80, s80, 1
	s_cmp_lt_u32 s80, 4
	s_cbranch_scc1 .L_0258
	v_and_b32_e32 v1, 15, v0
	v_and_b32_e32 v2, 48, v0
	v_lshlrev_b32_e32 v93, 4, v2
	v_lshlrev_b32_e32 v92, 4, v1
	v_add_u32_e32 v93, v93, v92
	v_add_u32_e32 v93, 0x8000, v93
	v_lshlrev_b32_e32 v92, 3, v0
	s_cmp_eq_u32 s86, 2
	s_cbranch_scc1 .L_1844
	s_cmp_eq_u32 s86, 1
	s_cbranch_scc0 .L_0c50
	v_lshlrev_b32_e32 v112, 2, v0
	s_lshl_b32 s54, s3, 15
	v_add_u32_e32 v113, s54, v112
	s_mov_b32 s55, 0
.L_0c18:
	ds_read_b32 v114, v112
	s_waitcnt lgkmcnt(0)
	global_store_dword v113, v114, s[24:25]
	v_add_u32_e32 v112, 0x400, v112
	v_add_u32_e32 v113, 0x400, v113
	s_add_u32 s55, s55, 1
	s_cmp_lt_u32 s55, 32
	s_cbranch_scc1 .L_0c18
	s_waitcnt vmcnt(0)
	s_endpgm
.L_0c50:
	s_lshl_b32 s30, s29, 20
	s_add_u32 s68, s12, s30
	s_addc_u32 s69, s13, 0
	s_lshl_b32 s30, s29, 8
	s_add_u32 s70, s14, s30
	s_addc_u32 s71, s15, 0
	s_mov_b32 s31, 0
	v_and_b32_e32 v1, 15, v0
	v_and_b32_e32 v2, 48, v0
	v_lshrrev_b32_e32 v3, 6, v0
	v_lshlrev_b32_e32 v5, 4, v3
	v_add_u32_e32 v104, v5, v1
	v_lshlrev_b32_e32 v98, 9, v104
	v_add_u32_e32 v98, v2, v98
	v_lshlrev_b32_e32 v97, 4, v2
	v_lshlrev_b32_e32 v96, 4, v1
	v_add_u32_e32 v97, v97, v96
	v_add_u32_e32 v97, 0x8000, v97
	v_lshlrev_b32_e32 v96, 3, v0
	s_mov_b32 s80, 0
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
	s_mov_b32 s38, 0
	// Software-pipelined W2 K loop mirroring the W13 pipeline:
	// the next 32 KiB W2 slab is in flight in v[192:223] while the
	// current slab computes; activation fragments and scales
	// prefetch after the ACC chains consume the previous values.
	s_lshl_b32 s39, s38, 11
	v_add_u32_e32 v99, s39, v96
	global_load_dwordx2 v[192:193], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[194:195], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[196:197], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[198:199], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[200:201], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[202:203], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[204:205], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[206:207], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[208:209], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[210:211], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[212:213], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[214:215], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[216:217], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[218:219], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[220:221], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[222:223], v99, s[32:33]
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
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_add_u32_e32 v100, 0x8000, v96
	ds_write_b64 v100, v[192:193]
	ds_write_b64 v100, v[194:195] offset:2048
	ds_write_b64 v100, v[196:197] offset:4096
	ds_write_b64 v100, v[198:199] offset:6144
	ds_write_b64 v100, v[200:201] offset:8192
	ds_write_b64 v100, v[202:203] offset:10240
	ds_write_b64 v100, v[204:205] offset:12288
	ds_write_b64 v100, v[206:207] offset:14336
	ds_write_b64 v100, v[208:209] offset:16384
	ds_write_b64 v100, v[210:211] offset:18432
	ds_write_b64 v100, v[212:213] offset:20480
	ds_write_b64 v100, v[214:215] offset:22528
	ds_write_b64 v100, v[216:217] offset:24576
	ds_write_b64 v100, v[218:219] offset:26624
	ds_write_b64 v100, v[220:221] offset:28672
	ds_write_b64 v100, v[222:223] offset:30720
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_add_u32 s38, s38, 1
	s_cmp_lt_u32 s38, 4
	s_cbranch_scc0 .L_w2_nopf
	s_lshl_b32 s39, s38, 11
	v_add_u32_e32 v99, s39, v96
	global_load_dwordx2 v[192:193], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[194:195], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[196:197], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[198:199], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[200:201], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[202:203], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[204:205], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[206:207], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[208:209], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[210:211], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[212:213], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[214:215], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[216:217], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[218:219], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[220:221], v99, s[32:33]
	v_add_u32_e32 v99, 0x2000, v99
	global_load_dwordx2 v[222:223], v99, s[32:33]
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
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	s_nop 12
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
	ds_read_b128 v[16:19], v97 offset:8192
	ds_read_b128 v[20:23], v97 offset:9216
	ds_read_b128 v[24:27], v97 offset:10240
	ds_read_b128 v[28:31], v97 offset:11264
	ds_read_b128 v[32:35], v97 offset:12288
	ds_read_b128 v[36:39], v97 offset:13312
	ds_read_b128 v[40:43], v97 offset:14336
	ds_read_b128 v[44:47], v97 offset:15360
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	s_nop 12
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
	ds_read_b128 v[16:19], v97 offset:16384
	ds_read_b128 v[20:23], v97 offset:17408
	ds_read_b128 v[24:27], v97 offset:18432
	ds_read_b128 v[28:31], v97 offset:19456
	ds_read_b128 v[32:35], v97 offset:20480
	ds_read_b128 v[36:39], v97 offset:21504
	ds_read_b128 v[40:43], v97 offset:22528
	ds_read_b128 v[44:47], v97 offset:23552
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	s_nop 12
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
	ds_read_b128 v[16:19], v97 offset:24576
	ds_read_b128 v[20:23], v97 offset:25600
	ds_read_b128 v[24:27], v97 offset:26624
	ds_read_b128 v[28:31], v97 offset:27648
	ds_read_b128 v[32:35], v97 offset:28672
	ds_read_b128 v[36:39], v97 offset:29696
	ds_read_b128 v[40:43], v97 offset:30720
	ds_read_b128 v[44:47], v97 offset:31744
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
	s_cmp_lt_u32 s38, 4
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
	s_cmp_lt_u32 s38, 4
	s_cbranch_scc1 .L_0dbc
	s_cmp_eq_u64 s[66:67], 0
	s_cbranch_scc1 .L_1834
	s_lshl_b32 s54, s80, 8
	v_add_u32_e32 v115, s54, v1
	v_add_u32_e32 v116, 0, v115
	v_lshlrev_b32_e32 v116, 2, v116
	v_lshlrev_b32_e32 v117, 13, v120
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 13, v121
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 13, v122
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 13, v123
	v_add_u32_e32 v124, v116, v124
	global_store_dword v117, v128, s[24:25]
	global_store_dword v118, v129, s[24:25]
	global_store_dword v119, v130, s[24:25]
	global_store_dword v124, v131, s[24:25]
	v_add_u32_e32 v116, 16, v115
	v_lshlrev_b32_e32 v116, 2, v116
	v_lshlrev_b32_e32 v117, 13, v120
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 13, v121
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 13, v122
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 13, v123
	v_add_u32_e32 v124, v116, v124
	global_store_dword v117, v132, s[24:25]
	global_store_dword v118, v133, s[24:25]
	global_store_dword v119, v134, s[24:25]
	global_store_dword v124, v135, s[24:25]
	v_add_u32_e32 v116, 32, v115
	v_lshlrev_b32_e32 v116, 2, v116
	v_lshlrev_b32_e32 v117, 13, v120
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 13, v121
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 13, v122
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 13, v123
	v_add_u32_e32 v124, v116, v124
	global_store_dword v117, v136, s[24:25]
	global_store_dword v118, v137, s[24:25]
	global_store_dword v119, v138, s[24:25]
	global_store_dword v124, v139, s[24:25]
	v_add_u32_e32 v116, 48, v115
	v_lshlrev_b32_e32 v116, 2, v116
	v_lshlrev_b32_e32 v117, 13, v120
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 13, v121
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 13, v122
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 13, v123
	v_add_u32_e32 v124, v116, v124
	global_store_dword v117, v140, s[24:25]
	global_store_dword v118, v141, s[24:25]
	global_store_dword v119, v142, s[24:25]
	global_store_dword v124, v143, s[24:25]
	v_add_u32_e32 v116, 64, v115
	v_lshlrev_b32_e32 v116, 2, v116
	v_lshlrev_b32_e32 v117, 13, v120
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 13, v121
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 13, v122
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 13, v123
	v_add_u32_e32 v124, v116, v124
	global_store_dword v117, v144, s[24:25]
	global_store_dword v118, v145, s[24:25]
	global_store_dword v119, v146, s[24:25]
	global_store_dword v124, v147, s[24:25]
	v_add_u32_e32 v116, 0x50, v115
	v_lshlrev_b32_e32 v116, 2, v116
	v_lshlrev_b32_e32 v117, 13, v120
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 13, v121
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 13, v122
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 13, v123
	v_add_u32_e32 v124, v116, v124
	global_store_dword v117, v148, s[24:25]
	global_store_dword v118, v149, s[24:25]
	global_store_dword v119, v150, s[24:25]
	global_store_dword v124, v151, s[24:25]
	v_add_u32_e32 v116, 0x60, v115
	v_lshlrev_b32_e32 v116, 2, v116
	v_lshlrev_b32_e32 v117, 13, v120
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 13, v121
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 13, v122
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 13, v123
	v_add_u32_e32 v124, v116, v124
	global_store_dword v117, v152, s[24:25]
	global_store_dword v118, v153, s[24:25]
	global_store_dword v119, v154, s[24:25]
	global_store_dword v124, v155, s[24:25]
	v_add_u32_e32 v116, 0x70, v115
	v_lshlrev_b32_e32 v116, 2, v116
	v_lshlrev_b32_e32 v117, 13, v120
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 13, v121
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 13, v122
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 13, v123
	v_add_u32_e32 v124, v116, v124
	global_store_dword v117, v156, s[24:25]
	global_store_dword v118, v157, s[24:25]
	global_store_dword v119, v158, s[24:25]
	global_store_dword v124, v159, s[24:25]
	v_add_u32_e32 v116, 0x80, v115
	v_lshlrev_b32_e32 v116, 2, v116
	v_lshlrev_b32_e32 v117, 13, v120
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 13, v121
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 13, v122
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 13, v123
	v_add_u32_e32 v124, v116, v124
	global_store_dword v117, v160, s[24:25]
	global_store_dword v118, v161, s[24:25]
	global_store_dword v119, v162, s[24:25]
	global_store_dword v124, v163, s[24:25]
	v_add_u32_e32 v116, 0x90, v115
	v_lshlrev_b32_e32 v116, 2, v116
	v_lshlrev_b32_e32 v117, 13, v120
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 13, v121
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 13, v122
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 13, v123
	v_add_u32_e32 v124, v116, v124
	global_store_dword v117, v164, s[24:25]
	global_store_dword v118, v165, s[24:25]
	global_store_dword v119, v166, s[24:25]
	global_store_dword v124, v167, s[24:25]
	v_add_u32_e32 v116, 0xa0, v115
	v_lshlrev_b32_e32 v116, 2, v116
	v_lshlrev_b32_e32 v117, 13, v120
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 13, v121
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 13, v122
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 13, v123
	v_add_u32_e32 v124, v116, v124
	global_store_dword v117, v168, s[24:25]
	global_store_dword v118, v169, s[24:25]
	global_store_dword v119, v170, s[24:25]
	global_store_dword v124, v171, s[24:25]
	v_add_u32_e32 v116, 0xb0, v115
	v_lshlrev_b32_e32 v116, 2, v116
	v_lshlrev_b32_e32 v117, 13, v120
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 13, v121
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 13, v122
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 13, v123
	v_add_u32_e32 v124, v116, v124
	global_store_dword v117, v172, s[24:25]
	global_store_dword v118, v173, s[24:25]
	global_store_dword v119, v174, s[24:25]
	global_store_dword v124, v175, s[24:25]
	v_add_u32_e32 v116, 0xc0, v115
	v_lshlrev_b32_e32 v116, 2, v116
	v_lshlrev_b32_e32 v117, 13, v120
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 13, v121
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 13, v122
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 13, v123
	v_add_u32_e32 v124, v116, v124
	global_store_dword v117, v176, s[24:25]
	global_store_dword v118, v177, s[24:25]
	global_store_dword v119, v178, s[24:25]
	global_store_dword v124, v179, s[24:25]
	v_add_u32_e32 v116, 0xd0, v115
	v_lshlrev_b32_e32 v116, 2, v116
	v_lshlrev_b32_e32 v117, 13, v120
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 13, v121
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 13, v122
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 13, v123
	v_add_u32_e32 v124, v116, v124
	global_store_dword v117, v180, s[24:25]
	global_store_dword v118, v181, s[24:25]
	global_store_dword v119, v182, s[24:25]
	global_store_dword v124, v183, s[24:25]
	v_add_u32_e32 v116, 0xe0, v115
	v_lshlrev_b32_e32 v116, 2, v116
	v_lshlrev_b32_e32 v117, 13, v120
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 13, v121
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 13, v122
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 13, v123
	v_add_u32_e32 v124, v116, v124
	global_store_dword v117, v184, s[24:25]
	global_store_dword v118, v185, s[24:25]
	global_store_dword v119, v186, s[24:25]
	global_store_dword v124, v187, s[24:25]
	v_add_u32_e32 v116, 0xf0, v115
	v_lshlrev_b32_e32 v116, 2, v116
	v_lshlrev_b32_e32 v117, 13, v120
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 13, v121
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 13, v122
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 13, v123
	v_add_u32_e32 v124, v116, v124
	global_store_dword v117, v188, s[24:25]
	global_store_dword v118, v189, s[24:25]
	global_store_dword v119, v190, s[24:25]
	global_store_dword v124, v191, s[24:25]
.L_1834:
	s_waitcnt vmcnt(0)
	s_add_u32 s80, s80, 1
	s_cmp_lt_u32 s80, 8
	s_cbranch_scc1 .L_0ca4
.L_1844:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_fused_m64n256_partial_fp8_gfx950
		.amdhsa_group_segment_fixed_size 65536
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 112
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 224
		.amdhsa_accum_offset 224
		.amdhsa_next_free_sgpr 88
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_moe_fused_m64n256_partial_fp8_gfx950, .Lfunc_end0-qwen36_moe_fused_m64n256_partial_fp8_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: hidden_fp8, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: hidden_scale_f32, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: shuffled_w13_fp8, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: w13_scale_f32, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: shuffled_w2_fp8, .offset: 32, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: w2_scale_f32, .offset: 40, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: sorted_token_ids_i32, .offset: 48, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: unused_sorted_weights_f32, .offset: 56, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: compact_sorted_expert_ids_i32, .offset: 64, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: num_valid_ids_i32, .offset: 72, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: partial_f32, .offset: 80, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_write }
      - { .name: rows, .offset: 88, .size: 4, .value_kind: by_value }
      - { .name: route_scale_workspace_f32, .offset: 96, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_write }
      - { .name: debug_stage, .offset: 104, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 65536
    .kernarg_segment_align: 8
    .kernarg_segment_size: 112
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_moe_fused_m64n256_partial_fp8_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 90
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_fused_m64n256_partial_fp8_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 224
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
