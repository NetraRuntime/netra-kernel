// SPDX-License-Identifier: MIT
// Exact conversion helpers; these preserve declared rounding boundaries.

	.ifndef NETRA_GFX950_NUMERICS_INC
	.set NETRA_GFX950_NUMERICS_INC, 1

	.macro NETRA_EXPAND_BF16_PAIR low, high, packed
	v_lshlrev_b32_e32 \low, 16, \packed
	v_and_b32_e32 \high, 0xffff0000, \packed
	.endm

	.macro NETRA_ROUND_F32_TO_BF16_PAIR output, low, high
	v_cvt_pk_bf16_f32 \output, \low, \high
	.endm

	// Exact IEEE f32 division sequence emitted by the pinned ROCm compiler.
	// scratch_num preserves the original numerator for the optional fixup.
	// Registers holding temporaries are explicit so a schedule retains full
	// ownership of its allocation and dependency order.
	.macro NETRA_DIV_F32_IEEE out, numerator, denominator, scratch_scale, scratch_rcp, scratch_scaled_num, scratch_residual, scratch_num, fixup=1
	v_mov_b32_e32 \scratch_num, \numerator
	v_div_scale_f32 \scratch_scale, s[34:35], \denominator, \denominator, \scratch_num
	v_rcp_f32_e32 \scratch_rcp, \scratch_scale
	v_div_scale_f32 \scratch_scaled_num, vcc, \scratch_num, \denominator, \scratch_num
	v_fma_f32 \scratch_residual, -\scratch_scale, \scratch_rcp, 1.0
	v_fmac_f32_e32 \scratch_rcp, \scratch_residual, \scratch_rcp
	v_mul_f32_e32 \out, \scratch_scaled_num, \scratch_rcp
	v_fma_f32 \scratch_residual, -\scratch_scale, \out, \scratch_scaled_num
	v_fmac_f32_e32 \out, \scratch_residual, \scratch_rcp
	v_fma_f32 \scratch_scale, -\scratch_scale, \out, \scratch_scaled_num
	v_div_fmas_f32 \scratch_scale, \scratch_scale, \scratch_rcp, \out
	.if \fixup
	v_div_fixup_f32 \out, \scratch_scale, \denominator, \scratch_num
	.else
	v_mov_b32_e32 \out, \scratch_scale
	.endif
	.endm

	.macro NETRA_BF16_DOT4_ACCUM sum, a0, a1, a2, a3, b0, b1, b2, b3, a_pair, a_lo, a_hi, b_pair, b_lo, b_hi, pair, pair_lo, pair_hi, scratch
	NETRA_EXPAND_BF16_PAIR \a_lo, \a_hi, \a0
	NETRA_EXPAND_BF16_PAIR \b_lo, \b_hi, \b0
	v_pk_mul_f32 \pair, \a_pair, \b_pair
	NETRA_EXPAND_BF16_PAIR \a_lo, \a_hi, \a1
	NETRA_EXPAND_BF16_PAIR \b_lo, \b_hi, \b1
	v_pk_fma_f32 \pair, \a_pair, \b_pair, \pair
	NETRA_EXPAND_BF16_PAIR \a_lo, \a_hi, \a2
	NETRA_EXPAND_BF16_PAIR \b_lo, \b_hi, \b2
	v_pk_fma_f32 \pair, \a_pair, \b_pair, \pair
	NETRA_EXPAND_BF16_PAIR \a_lo, \a_hi, \a3
	NETRA_EXPAND_BF16_PAIR \b_lo, \b_hi, \b3
	v_pk_fma_f32 \pair, \a_pair, \b_pair, \pair
	s_nop 0
	v_add_f32_e32 \scratch, \pair_lo, \pair_hi
	v_add_f32_e32 \sum, \scratch, \sum
	.endm

	.endif
