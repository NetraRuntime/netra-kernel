// SPDX-License-Identifier: MIT
// Compile-time-selected stores. Unsupported epilogues emit no machine code.

	.ifndef NETRA_DENSE_EPILOGUES_INC
	.set NETRA_DENSE_EPILOGUES_INC, 1

	.macro NETRA_STORE_IDENTITY_FIRST_16
	.if NETRA_EPILOGUE == NETRA_EPILOGUE_IDENTITY
	v_cmp_gt_u32_e32 vcc, 16, v0
	s_and_saveexec_b64 s[30:31], vcc
	v_cvt_pk_bf16_f32 v8, v6, v6
	v_lshlrev_b32_e32 v9, 1, v3
	global_store_short v9, v8, s[12:13]
	s_or_b64 exec, exec, s[30:31]
	.else
	.error "requested dense epilogue is not implemented"
	.endif
	.endm

	.macro NETRA_STORE_IDENTITY_LANE_GROUP_ZERO
	.if NETRA_EPILOGUE == NETRA_EPILOGUE_IDENTITY
	v_cmp_eq_u32_e32 vcc, 0, v2
	s_and_saveexec_b64 s[30:31], vcc
	v_cvt_pk_bf16_f32 v8, v6, v6
	v_lshlrev_b32_e32 v9, 1, v3
	global_store_short v9, v8, s[12:13]
	s_or_b64 exec, exec, s[30:31]
	.else
	.error "requested dense epilogue is not implemented"
	.endif
	.endm

	.endif
