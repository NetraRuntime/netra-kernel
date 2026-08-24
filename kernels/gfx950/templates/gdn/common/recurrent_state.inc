// SPDX-License-Identifier: MIT
// Shared fixed-order recurrent-state primitives for GDN gfx950 schedules.

	.ifndef NETRA_GFX950_GDN_RECURRENT_STATE_INC
	.set NETRA_GFX950_GDN_RECURRENT_STATE_INC, 1

	// Apply one scalar V row to eight K columns of the recurrent state. The
	// unused r1 argument is retained because it is part of the golden schedule's
	// register-allocation interface.
	.macro NETRA_GDN_UPDATE8_F32 r0, r1, s0, s1, s2, s3, s4, s5, s6, s7
	v_mov_b32_e32 v64, v\r0
	v_mov_b32_e32 v65, v\r0
	v_pk_fma_f32 v[\s0:\s1], v[8:9], v[64:65], v[\s0:\s1]
	v_pk_fma_f32 v[\s2:\s3], v[10:11], v[64:65], v[\s2:\s3]
	v_pk_fma_f32 v[\s4:\s5], v[12:13], v[64:65], v[\s4:\s5]
	v_pk_fma_f32 v[\s6:\s7], v[14:15], v[64:65], v[\s6:\s7]
	.endm

	// Round one state pair to BF16 and immediately re-expand to the exact FP32
	// values consumed by the next recurrent position.
	.macro NETRA_GDN_ROUND_STATE_BF16_PAIR lo, hi, tmp
	v_cvt_pk_bf16_f32 v\tmp, v\lo, v\hi
	v_lshlrev_b32_e32 v\lo, 16, v\tmp
	v_and_b32_e32 v\hi, 0xffff0000, v\tmp
	.endm

	// Serialize the fixed 4x8-register state tile in its deployed packed BF16
	// layout. Address registers and store order are deliberately unchanged.
	.macro NETRA_GDN_PACK_STORE_STATE_BF16 base_lo, base_hi
	v_cvt_pk_bf16_f32 v8, v32, v33
	v_cvt_pk_bf16_f32 v9, v34, v35
	v_cvt_pk_bf16_f32 v10, v36, v37
	v_cvt_pk_bf16_f32 v11, v38, v39
	v_cvt_pk_bf16_f32 v12, v40, v41
	v_cvt_pk_bf16_f32 v13, v42, v43
	v_cvt_pk_bf16_f32 v14, v44, v45
	v_cvt_pk_bf16_f32 v15, v46, v47
	v_cvt_pk_bf16_f32 v16, v48, v49
	v_cvt_pk_bf16_f32 v17, v50, v51
	v_cvt_pk_bf16_f32 v18, v52, v53
	v_cvt_pk_bf16_f32 v19, v54, v55
	v_cvt_pk_bf16_f32 v20, v56, v57
	v_cvt_pk_bf16_f32 v21, v58, v59
	v_cvt_pk_bf16_f32 v22, v60, v61
	v_cvt_pk_bf16_f32 v23, v62, v63
	global_store_dwordx4 v7, v[8:11], s[\base_lo:\base_hi]
	v_add_u32_e32 v5, 1024, v7
	global_store_dwordx4 v5, v[12:15], s[\base_lo:\base_hi]
	v_add_u32_e32 v5, 2048, v7
	global_store_dwordx4 v5, v[16:19], s[\base_lo:\base_hi]
	v_add_u32_e32 v5, 3072, v7
	global_store_dwordx4 v5, v[20:23], s[\base_lo:\base_hi]
	.endm

	.endif
