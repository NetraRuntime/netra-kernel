// SPDX-License-Identifier: MIT
// Shared BF16 packing and first output store for every GQA6 M=8 pointer ABI.
	.macro NETRA_ATTENTION_GQA6_M8_OUTPUT_PACK_FIRST_STORE
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
	.endm
