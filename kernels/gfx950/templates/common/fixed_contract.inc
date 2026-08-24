// SPDX-License-Identifier: MIT
// Assembler-time contract guards shared by specialized gfx950 tactics.

	.macro NETRA_REQUIRE_EQ value, expected
	.ifndef \value
	.error "missing Netra compile-time contract value"
	.endif
	.if (\value) != (\expected)
	.error "unsupported Netra compile-time contract value"
	.endif
	.endm

	.macro NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_TARGET_GFX, 950
	NETRA_REQUIRE_EQ NETRA_WAVE_SIZE, 64
	.endm
