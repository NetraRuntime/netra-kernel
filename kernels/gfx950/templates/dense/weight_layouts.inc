// SPDX-License-Identifier: MIT
// The layout ID is resolved by the compiler; assembly sees only this constant.

	.ifndef NETRA_DENSE_WEIGHT_LAYOUTS_INC
	.set NETRA_DENSE_WEIGHT_LAYOUTS_INC, 1

	.set NETRA_WEIGHT_LAYOUT_AITER_SHUFFLE_16X16_FP8_BLOCK128, 1

	.macro NETRA_REQUIRE_AITER_SHUFFLE_16X16
	.if NETRA_WEIGHT_LAYOUT != NETRA_WEIGHT_LAYOUT_AITER_SHUFFLE_16X16_FP8_BLOCK128
	.error "dense_fp8_m1 requires AITER shuffle_weight(weight, (16,16))"
	.endif
	.endm

	.endif
