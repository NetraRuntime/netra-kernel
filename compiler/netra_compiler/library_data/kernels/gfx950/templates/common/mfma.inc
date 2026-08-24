// SPDX-License-Identifier: MIT
// CDNA4 MFMA primitives with explicit registers and dependency delays.

	.ifndef NETRA_GFX950_MFMA_INC
	.set NETRA_GFX950_MFMA_INC, 1

	.macro NETRA_ZERO_ACC4 acc0, acc1, acc2, acc3
	v_mov_b32_e32 \acc0, 0
	v_mov_b32_e32 \acc1, 0
	v_mov_b32_e32 \acc2, 0
	v_mov_b32_e32 \acc3, 0
	.endm

	.macro NETRA_MFMA_FP8_16X16X128 acc, lhs, rhs, delay
	NETRA_WAIT_VM0_LGKM0
	v_mfma_f32_16x16x128_f8f6f4 \acc, \lhs, \rhs, 0
	s_nop \delay
	.endm

	.macro NETRA_SCALE_ACCUMULATE2 scratch, activation_scale, weight_scale, value, accumulator
	v_mul_f32_e32 \scratch, \activation_scale, \value
	v_mul_f32_e32 \scratch, \weight_scale, \scratch
	v_add_f32_e32 \accumulator, \accumulator, \scratch
	.endm

	.macro NETRA_SCALE_PRODUCT3 scratch, scale0, scale1, scale2, value
	v_mul_f32_e32 \scratch, \scale0, \value
	v_mul_f32_e32 \scratch, \scale1, \scratch
	v_mul_f32_e32 \scratch, \scale2, \scratch
	.endm

	.endif
