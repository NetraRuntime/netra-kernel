// SPDX-License-Identifier: MIT
// Compile-time numerical contract for FP8 E4M3 block-scaled dense kernels.

	.ifndef NETRA_DENSE_FP8_BLOCK128_INC
	.set NETRA_DENSE_FP8_BLOCK128_INC, 1

	.macro NETRA_REQUIRE_FP8_BLOCK128_M1
	.if NETRA_M != 1
	.error "dense_fp8_m1 requires NETRA_M=1"
	.endif
	.if NETRA_N != 2048
	.error "this dense_fp8_m1 schedule requires NETRA_N=2048"
	.endif
	.if NETRA_K != 4096
	.error "this dense_fp8_m1 schedule requires NETRA_K=4096"
	.endif
	.if NETRA_SCALE_BLOCK_K != 128
	.error "dense_fp8_m1 requires 128-wide activation scales"
	.endif
	.if NETRA_SCALE_BLOCK_N != 128
	.error "dense_fp8_m1 requires 128x128 weight scales"
	.endif
	.if NETRA_EPILOGUE != NETRA_EPILOGUE_IDENTITY
	.error "only the identity raw-assembly epilogue is implemented"
	.endif
	.endm

	.endif
