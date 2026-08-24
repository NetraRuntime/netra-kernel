// SPDX-License-Identifier: MIT
// Fixed CDNA4 MFMA tile contract used by the two retained schedules.

	.ifndef NETRA_DENSE_MFMA_TILES_INC
	.set NETRA_DENSE_MFMA_TILES_INC, 1

	.set NETRA_MFMA_TILE_N, 16
	.set NETRA_MFMA_K, 128
	.set NETRA_MFMA_KBLOCKS, NETRA_K / NETRA_SCALE_BLOCK_K

	.macro NETRA_REQUIRE_MFMA_TILE_N
	.if NETRA_TILE_N != NETRA_MFMA_TILE_N
	.error "dense_fp8_m1 requires a 16-column MFMA tile"
	.endif
	.endm

	.endif
