// SPDX-License-Identifier: MIT
// Fixed-order reductions. Reordering these macros is a numerical ABI change.

	.ifndef NETRA_GFX950_REDUCTIONS_INC
	.set NETRA_GFX950_REDUCTIONS_INC, 1

	.macro NETRA_ROW16_MAX_F32 value, scratch
	s_nop 1
	v_mov_b32_dpp \scratch, \value row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 \value, \value, \scratch
	s_nop 1
	v_mov_b32_dpp \scratch, \value row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 \value, \value, \scratch
	s_nop 1
	v_mov_b32_dpp \scratch, \value row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 \value, \value, \scratch
	s_nop 1
	v_mov_b32_dpp \scratch, \value row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 \value, \value, \scratch
	s_nop 1
	.endm

	.macro NETRA_WAVE64_SUM_F32_ROUTER value
	s_nop 0
	v_add_f32_dpp \value, \value, \value row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 0
	s_nop 0
	v_add_f32_dpp \value, \value, \value row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 0
	s_nop 0
	v_add_f32_dpp \value, \value, \value row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 0
	s_nop 0
	v_add_f32_dpp \value, \value, \value wave_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 0
	s_nop 0
	v_add_f32_dpp \value, \value, \value row_bcast:15 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 0
	s_nop 0
	v_add_f32_dpp \value, \value, \value row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
	.endm

	.endif
