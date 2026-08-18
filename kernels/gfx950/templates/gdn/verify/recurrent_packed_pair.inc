// Fixed-contract verification leaf for the shared gfx950 GDN BV16 schedule.
	.include "kernels/gfx950/templates/gdn/common/recurrent_bv16_core.inc"

	NETRA_REQUIRE_EQ NETRA_BATCH_MAX, 64

	.macro NETRA_GDN_RECURRENT_PACKED_PAIR symbol, dual_symbol
	NETRA_GDN_RECURRENT_BV16_CORE \symbol, \dual_symbol
	.endm
