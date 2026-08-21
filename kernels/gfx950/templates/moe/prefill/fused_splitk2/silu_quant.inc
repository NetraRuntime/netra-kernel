// SPDX-License-Identifier: MIT
// Fixed SiLU, route-scale, and FP8 activation quantization schedule.

	.macro NETRA_MOE_PREFILL_FUSED_SPLITK2_SILU_QUANT
.L_w13_after_k:
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
	// The route-scale and quantized-activation addresses advance by fixed
	// strides across the eight s76 groups.  Form each base once instead of
	// rebuilding both expressions in every quantization iteration.
	v_add_u32_e32 v34, s27, v2
	v_lshlrev_b32_e32 v34, 4, v34
	s_lshl_b32 s77, s80, 2
	v_add_u32_e32 v34, s77, v34
	v_lshlrev_b32_e32 v35, 9, v2
	s_lshl_b32 s77, s80, 7
	v_add_u32_e32 v35, s77, v35
	v_lshlrev_b32_e32 v36, 2, v1
	v_add_u32_e32 v35, v36, v35
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
	v_cmp_eq_u32_e64 s[78:79], 0, v1
	s_and_saveexec_b64 s[82:83], s[78:79]
	global_store_dword v34, v24, s[84:85]
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
	ds_write_b32 v35, v28
	v_add_u32_e32 v34, 128, v34
	v_add_u32_e32 v35, 4096, v35
	s_add_u32 s76, s76, 1
	s_cmp_lt_u32 s76, 8
	s_cbranch_scc1 .L_0a04
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	s_add_u32 s80, s80, 1
	s_cmp_lt_u32 s80, s89
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
	v_lshlrev_b32_e32 v96, 4, v0
	v_readfirstlane_b32 s75, v0
	s_mov_b32 s80, 0
	.endm
