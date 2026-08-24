// SPDX-License-Identifier: MIT
// Register-explicit address primitives shared across fixed layouts.

	.ifndef NETRA_GFX950_ADDRESSING_INC
	.set NETRA_GFX950_ADDRESSING_INC, 1

	.macro NETRA_ADD_U64 dst_lo, dst_hi, base_lo, base_hi, byte_offset
	s_add_u32 \dst_lo, \base_lo, \byte_offset
	s_addc_u32 \dst_hi, \base_hi, 0
	.endm

	.macro NETRA_ADD_U64_INPLACE dst_lo, dst_hi, byte_offset
	s_add_u32 \dst_lo, \dst_lo, \byte_offset
	s_addc_u32 \dst_hi, \dst_hi, 0
	.endm

	.macro NETRA_WAVE64_LANE_AND_FRAGMENT lane, fragment, workitem
	v_and_b32_e32 \lane, 15, \workitem
	v_and_b32_e32 \fragment, 48, \workitem
	.endm

	.macro NETRA_AITER_N16_K16_OFFSET output, tile_base, lane, fragment, scratch
	v_lshlrev_b32_e32 \output, 4, \lane
	v_lshlrev_b32_e32 \scratch, 4, \fragment
	v_add_u32_e32 \output, \output, \scratch
	v_add_u32_e32 \output, \tile_base, \output
	.endm

	.endif
