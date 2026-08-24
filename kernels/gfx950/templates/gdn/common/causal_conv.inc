// SPDX-License-Identifier: MIT
// Exact one-token causal-convolution/state primitive for GDN gfx950 schedules.

	.ifndef NETRA_GFX950_GDN_CAUSAL_CONV_INC
	.set NETRA_GFX950_GDN_CAUSAL_CONV_INC, 1

	.macro NETRA_GDN_CONV_TOKEN_EXACT
	// Load this token's BF16 input and expand it exactly to FP32.
	global_load_ushort v11, v1, s[4:5]
	NETRA_WAIT_VM0
	v_lshlrev_b32_e32 v11, 16, v11

	// Preserve the deployed BF16 product boundary before FP32 accumulation.
	v_mul_f32_e32 v12, v4, v7
	v_mul_f32_e32 v13, v5, v8
	v_mul_f32_e32 v14, v6, v9
	v_mul_f32_e32 v15, v11, v10
	v_cvt_pk_bf16_f32 v16, v12, v13
	v_cvt_pk_bf16_f32 v17, v14, v15
	NETRA_EXPAND_BF16_PAIR v12, v13, v16
	NETRA_EXPAND_BF16_PAIR v14, v15, v17
	v_add_f32_e32 v18, v12, v13
	v_add_f32_e32 v18, v18, v14
	v_add_f32_e32 v18, v18, v15

	// Save the post-token [previous-1, previous, current] BF16 window.
	v_cvt_pk_bf16_f32 v29, v5, v6
	v_cvt_pk_bf16_f32 v30, v11, v11
	global_store_dword v3, v29, s[12:13]
	global_store_short v3, v30, s[12:13] offset:4

	// Match OCML's subnormal-preserving exp2 lowering and IEEE division.
	v_mul_f32_e64 v19, -v18, s28
	v_cmp_gt_f32_e32 vcc, s29, v19
	v_sub_f32_e32 v20, 0, v18
	v_cndmask_b32_e32 v19, 0, v31, vcc
	v_fmac_f32_e32 v19, s28, v20
	v_exp_f32_e32 v20, v19
	v_cndmask_b32_e32 v19, 0, v32, vcc
	v_ldexp_f32 v20, v20, v19
	v_add_f32_e32 v20, 1.0, v20

	v_div_scale_f32 v21, s[30:31], v20, v20, v18
	v_rcp_f32_e32 v22, v21
	v_div_scale_f32 v23, vcc, v18, v20, v18
	v_fma_f32 v24, -v21, v22, 1.0
	v_fmac_f32_e32 v22, v24, v22
	v_mul_f32_e32 v25, v23, v22
	v_fma_f32 v24, -v21, v25, v23
	v_fmac_f32_e32 v25, v24, v22
	v_fma_f32 v21, -v21, v25, v23
	v_div_fmas_f32 v21, v21, v22, v25
	v_div_fixup_f32 v18, v21, v20, v18

	v_cvt_pk_bf16_f32 v28, v18, v18
	global_store_short v2, v28, s[16:17]

	// Roll the FP32-exact BF16 state and advance token/window byte offsets.
	v_mov_b32_e32 v4, v5
	v_mov_b32_e32 v5, v6
	v_mov_b32_e32 v6, v11
	v_add_u32_e32 v1, 0x6000, v1
	v_add_u32_e32 v2, 0x4000, v2
	v_add_u32_e32 v3, 0xc000, v3
	.endm

	.endif
