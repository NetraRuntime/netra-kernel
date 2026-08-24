// SPDX-License-Identifier: MIT
// Shared exact FP32 output normalization for every GQA6 M=8 pointer ABI.
	.macro NETRA_ATTENTION_GQA6_M8_OUTPUT_NORMALIZE
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
	.endm
