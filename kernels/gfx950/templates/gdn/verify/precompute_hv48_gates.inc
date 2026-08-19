// Netra model-independent fixed-contract tactic template.
	.include "kernels/gfx950/templates/common/primitives.inc"
// SPDX-License-Identifier: MIT
//
// Shape-gated raw gfx950 QK-only producer for the exact HV48 dFlash
// verification family T=12, H=16, HV=48, K=128, B=1..128.
//
// Grid: B*192 one-wave workgroups. workgroup_x = global_token * 16 + q_head.
// Each lane loads two BF16 elements from Q and K, and the wave produces the
// normalized FP32 vectors. Lane zero produces the three HV48 decay/beta
// gate pairs in-kernel, mirroring the accepted HV32 chains.
//
// Variant builds isolate norm-reduction, divide rounding, and the packed
// decoder's BF16 beta boundary. Variant 8 is the production selection.

	NETRA_GFX950_MODULE_HEADER 6

	//   0: original FMA square + sequential row sums + reciprocal multiply
	//   1: Triton square/reduction order + reciprocal multiply
	//   2: Triton square/reduction order + per-element divide with fixup
	//   3: original norm reduction + per-element divide with fixup
	//   4: Triton norm reduction + per-element divide without fixup
	//   5: deployed Triton contiguous lane layout + exact reduction + divide
	//   6: variant 5 plus deployed compensated log-to-natural conversion
	//   7: variant 6 plus deployed subnormal-preserving final exponential
	//   8: variant 7 plus packed-decode BF16 beta round/re-expand
	.ifndef NETRA_GDN_PRECOMPUTE_VARIANT
	.set NETRA_GDN_PRECOMPUTE_VARIANT, 8
	.endif
	.set NETRA_GDN_VALUE_HEADS, 48
	.set NETRA_GDN_QK_ONLY, 0
	.set NETRA_GDN_PRECOMPUTE_VGPRS, 53
	.set NETRA_GDN_PRECOMPUTE_ACCUM_OFFSET, 56

	.macro NETRA_GDN_DIV_NORMAL_F32 out, numerator, denominator
	.if NETRA_GDN_PRECOMPUTE_VARIANT != 4
	NETRA_DIV_F32_IEEE v\out, v\numerator, v\denominator, v12, v13, v14, v16, v15, 1
	.else
	NETRA_DIV_F32_IEEE v\out, v\numerator, v\denominator, v12, v13, v14, v16, v15, 0
	.endif
	.endm

	.macro NETRA_GDN_VERIFY_PRECOMPUTE_HV48_GATES symbol
	NETRA_REQUIRE_GFX950_WAVE64
	.if (NETRA_TOKENS != 8) && (NETRA_TOKENS != 12)
	.error "NETRA_TOKENS must be 8 or 12"
	.endif
	NETRA_REQUIRE_EQ NETRA_QK_HEADS, 16
	NETRA_REQUIRE_EQ NETRA_VALUE_HEADS, 48
	NETRA_REQUIRE_EQ NETRA_QK_DIM, 128
	NETRA_REQUIRE_EQ NETRA_VALUE_DIM, 128
	NETRA_KERNEL_ENTRY \symbol, 1
	// Preserve workgroup X and load ten pointers plus the four token strides
	// (in elements) carried by the real SGLang tensor views.
	s_mov_b32 s22, s2
	NETRA_LOAD_KERNARG_PTR s[2:3], 0
	NETRA_LOAD_KERNARG_PTR s[4:5], 8
	NETRA_LOAD_KERNARG_PTR s[6:7], 16
	NETRA_LOAD_KERNARG_PTR s[8:9], 24
	NETRA_LOAD_KERNARG_PTR s[10:11], 32
	NETRA_LOAD_KERNARG_PTR s[12:13], 40
	NETRA_LOAD_KERNARG_PTR s[14:15], 48
	NETRA_LOAD_KERNARG_PTR s[16:17], 56
	NETRA_LOAD_KERNARG_PTR s[18:19], 64
	NETRA_LOAD_KERNARG_PTR s[20:21], 72
	NETRA_LOAD_KERNARG_U32X4 s[28:31], 80
	NETRA_WAIT_LGKM0

	// token = workgroup_x / 16, q_head = workgroup_x % 16.
	// Q/K heads contain 128 contiguous BF16 values, while their token strides
	// may include neighboring packed projections. A/B contribute two HV values
	// per q_head for HV32 and three for the 27B HV48 contract.
	s_lshr_b32 s23, s22, 4
	s_and_b32 s27, s22, 15
	s_lshl_b32 s24, s27, 7
	s_mul_i32 s25, s23, s28
	s_add_u32 s25, s25, s24
	s_lshl_b32 s25, s25, 1
	s_add_u32 s8, s8, s25
	s_addc_u32 s9, s9, 0
	s_mul_i32 s26, s23, s29
	s_add_u32 s26, s26, s24
	s_lshl_b32 s26, s26, 1
	s_add_u32 s10, s10, s26
	s_addc_u32 s11, s11, 0

	.if NETRA_GDN_VALUE_HEADS == 32
	s_lshl_b32 s24, s27, 1
	.else
	s_mul_i32 s24, s27, 3
	.endif
	s_mul_i32 s25, s23, s30
	s_add_u32 s25, s25, s24
	s_lshl_b32 s25, s25, 1
	s_add_u32 s4, s4, s25
	s_addc_u32 s5, s5, 0
	s_mul_i32 s25, s23, s31
	s_add_u32 s25, s25, s24
	s_lshl_b32 s25, s25, 1
	s_add_u32 s12, s12, s25
	s_addc_u32 s13, s13, 0

	// Raw outputs are compact and contiguous.
	s_lshl_b32 s24, s22, 9
	.if NETRA_GDN_VALUE_HEADS == 32
	s_lshl_b32 s26, s22, 3
	.else
	s_mul_i32 s26, s22, 12
	.endif
	s_add_u32 s14, s14, s24
	s_addc_u32 s15, s15, 0
	s_add_u32 s16, s16, s24
	s_addc_u32 s17, s17, 0
	s_add_u32 s18, s18, s26
	s_addc_u32 s19, s19, 0
	s_add_u32 s20, s20, s26
	s_addc_u32 s21, s21, 0

	// Triton's sizePerThread=[2], threadsPerWarp=[64] blocked layout assigns
	// adjacent K values (2*lane, 2*lane+1) to each lane.  Older experiments
	// intentionally retain the interleaved lane/lane+64 ownership.
	.if NETRA_GDN_PRECOMPUTE_VARIANT >= 5
	v_lshlrev_b32_e32 v1, 2, v0
	global_load_dword v3, v1, s[8:9]
	global_load_dword v5, v1, s[10:11]
	NETRA_WAIT_VM0
	v_and_b32_e32 v4, 0xffff0000, v3
	v_lshlrev_b32_e32 v3, 16, v3
	v_and_b32_e32 v6, 0xffff0000, v5
	v_lshlrev_b32_e32 v5, 16, v5
	.else
	// Two BF16 Q/K elements per lane: k=lane and k=lane+64.
	v_lshlrev_b32_e32 v1, 1, v0
	global_load_ushort v3, v1, s[8:9]
	global_load_ushort v4, v1, s[8:9] offset:128
	global_load_ushort v5, v1, s[10:11]
	global_load_ushort v6, v1, s[10:11] offset:128
	NETRA_WAIT_VM0
	v_lshlrev_b32_e32 v3, 16, v3
	v_lshlrev_b32_e32 v4, 16, v4
	v_lshlrev_b32_e32 v5, 16, v5
	v_lshlrev_b32_e32 v6, 16, v6
	.endif

	// Accumulate 128 squares as two interleaved wave64 reductions.
	.if (NETRA_GDN_PRECOMPUTE_VARIANT == 0) || (NETRA_GDN_PRECOMPUTE_VARIANT == 3)
	v_mul_f32_e32 v7, v3, v3
	v_mul_f32_e32 v8, v5, v5
	v_fmac_f32_e32 v7, v4, v4
	v_fmac_f32_e32 v8, v6, v6
	.else
	// Triton squares the two lane-owned values independently, then adds them.
	v_mov_b32_e32 v16, v3
	v_mov_b32_e32 v17, v4
	v_pk_mul_f32 v[16:17], v[16:17], v[16:17]
	v_add_f32_e32 v7, v16, v17
	v_mov_b32_e32 v16, v5
	v_mov_b32_e32 v17, v6
	v_pk_mul_f32 v[16:17], v[16:17], v[16:17]
	v_add_f32_e32 v8, v16, v17
	.endif
	s_nop 0
	v_add_f32_dpp v7, v7, v7 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v8, v8, v8 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 0
	v_add_f32_dpp v7, v7, v7 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v8, v8, v8 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 0
	v_add_f32_dpp v7, v7, v7 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v8, v8, v8 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 0
	v_add_f32_dpp v7, v7, v7 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v8, v8, v8 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1

	.if (NETRA_GDN_PRECOMPUTE_VARIANT == 0) || (NETRA_GDN_PRECOMPUTE_VARIANT == 3)
	// Original sequential combination of the four 16-lane row sums.
	v_readlane_b32 s34, v7, 15
	v_readlane_b32 s35, v7, 31
	v_readlane_b32 s36, v7, 47
	v_readlane_b32 s37, v7, 63
	v_readlane_b32 s38, v8, 15
	v_readlane_b32 s39, v8, 31
	v_readlane_b32 s40, v8, 47
	v_readlane_b32 s41, v8, 63
	v_mov_b32_e32 v10, s34
	v_mov_b32_e32 v11, s38
	v_add_f32_e32 v10, s35, v10
	v_add_f32_e32 v11, s39, v11
	v_add_f32_e32 v10, s36, v10
	v_add_f32_e32 v11, s40, v11
	v_add_f32_e32 v10, s37, v10
	v_add_f32_e32 v11, s41, v11
	.else
	// Triton combines rows 0+1 and 2+3 first, then those two halves.
	v_mov_b32_e32 v9, v7
	v_mov_b32_e32 v10, v8
	v_mov_b32_dpp v9, v9 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
	v_mov_b32_dpp v10, v10 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
	.if NETRA_GDN_PRECOMPUTE_VARIANT >= 5
	// The compiler emits opposite source order for the Q and K row-pair joins.
	v_add_f32_e32 v7, v9, v7
	v_add_f32_e32 v8, v8, v10
	.else
	v_add_f32_e32 v7, v7, v9
	v_add_f32_e32 v8, v8, v10
	.endif
	v_add_f32_dpp v7, v7, v7 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v8, v8, v8 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_readlane_b32 s34, v7, 63
	v_readlane_b32 s38, v8, 63
	v_mov_b32_e32 v10, s34
	v_mov_b32_e32 v11, s38
	.endif
	v_add_f32_e32 v10, 0x358637bd, v10
	v_add_f32_e32 v11, 0x358637bd, v11

	// Normalize Q/K. Variants 0/1 retain the fast reciprocal experiment;
	// variants 2/3/4 use a quotient refinement for every element.
	v_sqrt_f32_e32 v10, v10
	v_sqrt_f32_e32 v11, v11
	.if NETRA_GDN_PRECOMPUTE_VARIANT <= 1
	v_rcp_f32_e32 v12, v10
	v_rcp_f32_e32 v13, v11
	v_fma_f32 v14, -v10, v12, 1.0
	v_fma_f32 v15, -v11, v13, 1.0
	v_fmac_f32_e32 v12, v14, v12
	v_fmac_f32_e32 v13, v15, v13
	v_fma_f32 v14, -v10, v12, 1.0
	v_fma_f32 v15, -v11, v13, 1.0
	v_fmac_f32_e32 v12, v14, v12
	v_fmac_f32_e32 v13, v15, v13
	v_mul_f32_e32 v12, 0x3db504f3, v12

	v_mul_f32_e32 v3, v12, v3
	v_mul_f32_e32 v4, v12, v4
	v_mul_f32_e32 v5, v13, v5
	v_mul_f32_e32 v6, v13, v6
	.else
	NETRA_GDN_DIV_NORMAL_F32 3, 3, 10
	v_mul_f32_e32 v3, 0x3db504f3, v3
	NETRA_GDN_DIV_NORMAL_F32 4, 4, 10
	v_mul_f32_e32 v4, 0x3db504f3, v4
	NETRA_GDN_DIV_NORMAL_F32 5, 5, 11
	NETRA_GDN_DIV_NORMAL_F32 6, 6, 11
	.endif
	.if NETRA_GDN_PRECOMPUTE_VARIANT >= 5
	v_lshlrev_b32_e32 v18, 3, v0
	v_mov_b32_e32 v16, v3
	v_mov_b32_e32 v17, v4
	global_store_dwordx2 v18, v[16:17], s[14:15]
	v_mov_b32_e32 v16, v5
	v_mov_b32_e32 v17, v6
	global_store_dwordx2 v18, v[16:17], s[16:17]
	.else
	v_lshlrev_b32_e32 v18, 2, v0
	global_store_dword v18, v3, s[14:15]
	global_store_dword v18, v4, s[14:15] offset:256
	global_store_dword v18, v5, s[16:17]
	global_store_dword v18, v6, s[16:17] offset:256
	.endif

	// The 27B hybrid path replaces the gate pairs with an exact Triton
	// precompute before launching the recurrent core.  Its QK-only build skips
	// this lane-zero work instead of producing values that are immediately
	// overwritten.
	.if NETRA_GDN_QK_ONLY == 0
	// Lane zero produces the recurrent gate pairs.
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_and_saveexec_b64 s[30:31], vcc
	s_cbranch_execz .Lgate_done
	v_mov_b32_e32 v25, 0
	.if NETRA_GDN_VALUE_HEADS == 32
	s_lshl_b32 s28, s27, 3
	.else
	s_mul_i32 s28, s27, 12
	.endif
	s_add_u32 s2, s2, s28
	s_addc_u32 s3, s3, 0
	.if NETRA_GDN_VALUE_HEADS == 32
	s_lshl_b32 s28, s27, 2
	.else
	s_mul_i32 s28, s27, 6
	.endif
	s_add_u32 s6, s6, s28
	s_addc_u32 s7, s7, 0
	global_load_dwordx2 v[20:21], v25, s[2:3]
	global_load_dword v22, v25, s[4:5]
	global_load_dword v23, v25, s[6:7]
	global_load_dword v24, v25, s[12:13]
	.if NETRA_GDN_VALUE_HEADS == 48
	global_load_dword v42, v25, s[2:3] offset:8
	global_load_ushort v43, v25, s[4:5] offset:4
	global_load_ushort v44, v25, s[6:7] offset:4
	global_load_ushort v45, v25, s[12:13] offset:4
	.endif
	NETRA_WAIT_VM0
	s_mov_b32 s28, 0x41a00000

	// Unpack the two BF16 a, dt_bias, and b values.
	v_lshlrev_b32_e32 v26, 16, v22
	v_and_b32_e32 v27, 0xffff0000, v22
	v_lshlrev_b32_e32 v28, 16, v23
	v_and_b32_e32 v29, 0xffff0000, v23
	v_lshlrev_b32_e32 v30, 16, v24
	v_and_b32_e32 v31, 0xffff0000, v24
	v_add_f32_e32 v26, v28, v26
	v_add_f32_e32 v27, v29, v27
	.if NETRA_GDN_VALUE_HEADS == 48
	v_lshlrev_b32_e32 v43, 16, v43
	v_lshlrev_b32_e32 v44, 16, v44
	v_lshlrev_b32_e32 v45, 16, v45
	v_add_f32_e32 v43, v44, v43
	.endif

	// softplus(x) = ln(1 + exp(x)); native exp/log are base two.
	v_mul_f32_e32 v32, 0x3fb8aa3b, v26
	v_mul_f32_e32 v33, 0x3fb8aa3b, v27
	v_exp_f32_e32 v32, v32
	v_exp_f32_e32 v33, v33
	v_add_f32_e32 v32, 1.0, v32
	v_add_f32_e32 v33, 1.0, v33
	v_log_f32_e32 v32, v32
	v_log_f32_e32 v33, v33
	.if NETRA_GDN_VALUE_HEADS == 48
	v_mul_f32_e32 v46, 0x3fb8aa3b, v43
	v_exp_f32_e32 v46, v46
	v_add_f32_e32 v46, 1.0, v46
	v_log_f32_e32 v46, v46
	.endif
	.if NETRA_GDN_PRECOMPUTE_VARIANT >= 6
	// Triton converts log2 to natural log using a compensated split ln(2).
	s_mov_b32 s32, 0x3f317217
	v_mul_f32_e32 v38, 0x3f317217, v32
	v_fma_f32 v38, v32, s32, -v38
	v_fmac_f32_e32 v38, 0x3377d1cf, v32
	v_fmac_f32_e32 v38, 0x3f317217, v32
	v_mov_b32_e32 v32, v38
	v_mul_f32_e32 v39, 0x3f317217, v33
	v_fma_f32 v39, v33, s32, -v39
	v_fmac_f32_e32 v39, 0x3377d1cf, v33
	v_fmac_f32_e32 v39, 0x3f317217, v33
	v_mov_b32_e32 v33, v39
	.if NETRA_GDN_VALUE_HEADS == 48
	v_mul_f32_e32 v47, 0x3f317217, v46
	v_fma_f32 v47, v46, s32, -v47
	v_fmac_f32_e32 v47, 0x3377d1cf, v46
	v_fmac_f32_e32 v47, 0x3f317217, v46
	v_mov_b32_e32 v46, v47
	.endif
	.else
	v_mul_f32_e32 v32, 0x3f317218, v32
	v_mul_f32_e32 v33, 0x3f317218, v33
	.if NETRA_GDN_VALUE_HEADS == 48
	v_mul_f32_e32 v46, 0x3f317218, v46
	.endif
	.endif
	v_cmp_ge_f32_e32 vcc, s28, v26
	v_cndmask_b32_e32 v32, v26, v32, vcc
	v_cmp_ge_f32_e32 vcc, s28, v27
	v_cndmask_b32_e32 v33, v27, v33, vcc
	.if NETRA_GDN_VALUE_HEADS == 48
	v_cmp_ge_f32_e32 vcc, s28, v43
	v_cndmask_b32_e32 v46, v43, v46, vcc
	.endif

	// decay = exp(-exp(A_log) * softplus).
	v_mul_f32_e32 v34, 0x3fb8aa3b, v20
	v_mul_f32_e32 v35, 0x3fb8aa3b, v21
	v_exp_f32_e32 v34, v34
	v_exp_f32_e32 v35, v35
	v_mul_f32_e64 v34, -v34, v32
	v_mul_f32_e64 v35, -v35, v33
	.if NETRA_GDN_VALUE_HEADS == 48
	v_mul_f32_e32 v49, 0x3fb8aa3b, v42
	v_exp_f32_e32 v49, v49
	v_mul_f32_e64 v49, -v49, v46
	.endif
	.if NETRA_GDN_PRECOMPUTE_VARIANT == 7
	// Triton shifts values below exp2(-126) by +64 before v_exp_f32 and
	// restores the scale with v_ldexp_f32 so FP32 subnormals are preserved.
	s_mov_b32 s33, 0xc2fc0000
	v_mov_b32_e32 v40, 0x42800000
	v_mov_b32_e32 v36, v34
	v_mov_b32_e32 v37, v35
	v_mul_f32_e32 v34, 0x3fb8aa3b, v36
	v_cmp_gt_f32_e32 vcc, s33, v34
	s_and_b64 s[36:37], vcc, exec
	s_cselect_b32 s34, 0xffffffc0, 0
	v_cndmask_b32_e32 v38, 0, v40, vcc
	v_fmac_f32_e32 v38, 0x3fb8aa3b, v36
	v_exp_f32_e32 v34, v38
	s_nop 0
	v_ldexp_f32 v34, v34, s34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v37
	v_cmp_gt_f32_e32 vcc, s33, v35
	s_and_b64 s[36:37], vcc, exec
	s_cselect_b32 s35, 0xffffffc0, 0
	v_cndmask_b32_e32 v39, 0, v40, vcc
	v_fmac_f32_e32 v39, 0x3fb8aa3b, v37
	v_exp_f32_e32 v35, v39
	s_nop 0
	v_ldexp_f32 v35, v35, s35
	.if NETRA_GDN_VALUE_HEADS == 48
	v_mov_b32_e32 v51, v49
	v_mul_f32_e32 v49, 0x3fb8aa3b, v51
	v_cmp_gt_f32_e32 vcc, s33, v49
	s_and_b64 s[36:37], vcc, exec
	s_cselect_b32 s34, 0xffffffc0, 0
	v_cndmask_b32_e32 v52, 0, v40, vcc
	v_fmac_f32_e32 v52, 0x3fb8aa3b, v51
	v_exp_f32_e32 v49, v52
	s_nop 0
	v_ldexp_f32 v49, v49, s34
	.endif
	.else
	v_mul_f32_e32 v34, 0x3fb8aa3b, v34
	v_mul_f32_e32 v35, 0x3fb8aa3b, v35
	v_exp_f32_e32 v34, v34
	v_exp_f32_e32 v35, v35
	.if NETRA_GDN_VALUE_HEADS == 48
	v_mul_f32_e32 v49, 0x3fb8aa3b, v49
	v_exp_f32_e32 v49, v49
	.endif
	.endif

	// beta = sigmoid(b), with one reciprocal refinement.
	v_mul_f32_e32 v36, 0xbfb8aa3b, v30
	v_mul_f32_e32 v37, 0xbfb8aa3b, v31
	v_exp_f32_e32 v36, v36
	v_exp_f32_e32 v37, v37
	v_add_f32_e32 v36, 1.0, v36
	v_add_f32_e32 v37, 1.0, v37
	v_rcp_f32_e32 v38, v36
	v_rcp_f32_e32 v39, v37
	v_fma_f32 v40, -v36, v38, 1.0
	v_fma_f32 v41, -v37, v39, 1.0
	v_fmac_f32_e32 v38, v40, v38
	v_fmac_f32_e32 v39, v41, v39
	.if NETRA_GDN_VALUE_HEADS == 48
	v_mul_f32_e32 v50, 0xbfb8aa3b, v45
	v_exp_f32_e32 v50, v50
	v_add_f32_e32 v50, 1.0, v50
	v_rcp_f32_e32 v51, v50
	v_fma_f32 v52, -v50, v51, 1.0
	v_fmac_f32_e32 v51, v52, v51
	.endif

	.if NETRA_GDN_PRECOMPUTE_VARIANT == 8
	// Packed M=1 decode explicitly casts sigmoid(beta) through the BF16
	// input dtype before using it in FP32 recurrence arithmetic.
	v_cvt_pk_bf16_f32 v40, v38, v39
	v_lshlrev_b32_e32 v38, 16, v40
	v_and_b32_e32 v39, 0xffff0000, v40
	.if NETRA_GDN_VALUE_HEADS == 48
	v_cvt_pk_bf16_f32 v52, v51, v51
	v_lshlrev_b32_e32 v51, 16, v52
	.endif
	.endif

	.if NETRA_GDN_VALUE_HEADS == 48
	// Compute the third gate after the packed pair so it can reuse the proven
	// low VGPR range and the exact scalar instruction sequence.
	v_mul_f32_e32 v21, 0x3fb8aa3b, v43
	v_exp_f32_e32 v21, v21
	s_nop 0
	v_add_f32_e32 v21, 1.0, v21
	v_log_f32_e32 v21, v21
	s_nop 0
	.if NETRA_GDN_PRECOMPUTE_VARIANT >= 6
	v_mul_f32_e32 v22, 0x3f317217, v21
	v_fma_f32 v22, v21, s32, -v22
	v_fmac_f32_e32 v22, 0x3377d1cf, v21
	v_fmac_f32_e32 v22, 0x3f317217, v21
	v_mov_b32_e32 v21, v22
	.else
	v_mul_f32_e32 v21, 0x3f317218, v21
	.endif
	v_cmp_ge_f32_e32 vcc, s28, v43
	v_cndmask_b32_e32 v21, v43, v21, vcc

	v_mul_f32_e32 v20, 0x3fb8aa3b, v42
	v_exp_f32_e32 v20, v20
	s_nop 0
	v_mul_f32_e64 v20, -v20, v21
	.if NETRA_GDN_PRECOMPUTE_VARIANT == 7
	v_mov_b32_e32 v22, v20
	v_mul_f32_e32 v20, 0x3fb8aa3b, v22
	v_cmp_gt_f32_e32 vcc, s33, v20
	s_and_b64 s[36:37], vcc, exec
	s_cselect_b32 s34, 0xffffffc0, 0
	v_mov_b32_e32 v26, 0x42800000
	v_cndmask_b32_e32 v23, 0, v26, vcc
	v_fmac_f32_e32 v23, 0x3fb8aa3b, v22
	v_exp_f32_e32 v20, v23
	s_nop 0
	v_ldexp_f32 v20, v20, s34
	.else
	v_mul_f32_e32 v20, 0x3fb8aa3b, v20
	v_exp_f32_e32 v20, v20
	.endif

	v_mul_f32_e32 v23, 0xbfb8aa3b, v45
	v_exp_f32_e32 v23, v23
	s_nop 0
	v_add_f32_e32 v23, 1.0, v23
	v_rcp_f32_e32 v24, v23
	s_nop 0
	v_fma_f32 v26, -v23, v24, 1.0
	v_fmac_f32_e32 v24, v26, v24
	.if NETRA_GDN_PRECOMPUTE_VARIANT == 8
	v_cvt_pk_bf16_f32 v26, v24, v24
	v_lshlrev_b32_e32 v24, 16, v26
	.endif
	.endif

	global_store_dword v25, v34, s[18:19]
	global_store_dword v25, v35, s[18:19] offset:4
	global_store_dword v25, v38, s[20:21]
	global_store_dword v25, v39, s[20:21] offset:4
	.if NETRA_GDN_VALUE_HEADS == 48
	.ifdef NETRA_DEBUG_GDN_HV48_GATE_LOADS
	global_store_dword v25, v42, s[18:19] offset:8
	global_store_dword v25, v45, s[20:21] offset:8
	.else
	global_store_dword v25, v20, s[18:19] offset:8
	global_store_dword v25, v24, s[20:21] offset:8
	.endif
	.endif
.Lgate_done:
	s_or_b64 exec, exec, s[30:31]
	.endif
	NETRA_WAIT_VM0
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel \symbol
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 96
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr NETRA_GDN_PRECOMPUTE_VGPRS
		.amdhsa_accum_offset NETRA_GDN_PRECOMPUTE_ACCUM_OFFSET
		.amdhsa_next_free_sgpr 42
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size \symbol, .Lfunc_end0-\symbol

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: A_log_f32, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: a_bf16, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: dt_bias_bf16, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: q_bf16, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: k_bf16, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: b_bf16, .offset: 40, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: q_normalized_f32, .offset: 48, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: k_normalized_f32, .offset: 56, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: decay_f32, .offset: 64, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: beta_f32, .offset: 72, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: stride_q, .offset: 80, .size: 4,
          .value_kind: by_value }
      - { .name: stride_k, .offset: 84, .size: 4,
          .value_kind: by_value }
      - { .name: stride_a, .offset: 88, .size: 4,
          .value_kind: by_value }
      - { .name: stride_b, .offset: 92, .size: 4,
          .value_kind: by_value }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 96
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 64
    .name: \symbol
    .private_segment_fixed_size: 0
    .sgpr_count: 48
    .sgpr_spill_count: 0
    .symbol: \symbol\().kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 56
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
	.endm
