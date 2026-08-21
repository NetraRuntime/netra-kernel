// Netra model-independent fixed-contract assembly tactic.
	.include "kernels/gfx950/templates/common/primitives.inc"
	NETRA_GFX950_MODULE_HEADER 5
	.macro NETRA_ADD_RMSNORM_GROUP_QUANT_N5120 symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_WIDTH, 5120
	NETRA_REQUIRE_EQ NETRA_QUANT_GROUP_SIZE, 128
	NETRA_REQUIRE_EQ NETRA_SCALE_LAYOUT_ID, 1
	.text
	.globl	\symbol ; -- Begin function \symbol
	.p2align	8
	.type	\symbol,@function
\symbol: ; @\symbol
.Lfunc_begin0:
; %bb.7:
	s_load_dwordx2 s[2:3], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_waitcnt lgkmcnt(0)
	s_branch .LBB0_0
.Ltmp0:
	.p2align	8
; %bb.8:
.LBB0_0:
	s_mov_b64 s[28:29], s[10:11]
	s_mov_b64 s[24:25], s[6:7]
	s_load_dwordx2 s[10:11], s[0:1], 0x3c
	s_load_dword s6, s[0:1], 0x44
	s_mov_b64 s[20:21], s[14:15]
	s_mov_b64 s[36:37], s[2:3]
.Ltmp1:
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_readfirstlane_b32 s17, v0
	s_movk_i32 s2, 0xffc0
	s_mov_b32 s39, 0x27000
	v_mov_b32_e32 v1, s17
	v_bfi_b32 v1, s2, v1, v0
	v_lshlrev_b32_e32 v2, 3, v1
	v_and_b32_e32 v13, 0x1ff8, v2
	s_waitcnt lgkmcnt(0)
	s_mul_i32 s2, s11, s16
	s_mul_i32 s11, s6, s16
	s_mov_b32 s38, 0x7ffffffe
	v_add_lshl_u32 v2, v13, s2, 1
	v_bfrev_b32_e32 v12, 1
	v_cmp_gt_i32_e64 s[2:3], s10, v13
	v_add_lshl_u32 v6, v13, s11, 1
	s_and_b32 s37, s37, 0xffff
	v_cndmask_b32_e64 v2, v12, v2, s[2:3]
	s_and_b32 s5, s5, 0xffff
	s_mov_b32 s6, s38
	s_mov_b32 s7, s39
	v_cndmask_b32_e64 v6, v12, v6, s[2:3]
	buffer_load_dwordx4 v[2:5], v2, s[36:39], 0 offen
	s_and_b32 s29, s29, 0xffff
	buffer_load_dwordx4 v[6:9], v6, s[4:7], 0 offen
	s_mul_i32 s4, s10, s16
	v_add_u32_e32 v11, s4, v13
	v_lshlrev_b32_e32 v14, 1, v11
	v_cndmask_b32_e64 v12, v12, v14, s[2:3]
	s_mov_b32 s30, s38
	s_mov_b32 s31, s39
	v_and_b32_e32 v10, 63, v0
.Ltmp2:
	v_cmp_eq_u32_e32 vcc, 0, v10
.Ltmp3:
	s_waitcnt vmcnt(1)
	v_and_b32_e32 v15, 0xffff0000, v2
	v_lshlrev_b32_e32 v14, 16, v2
	s_waitcnt vmcnt(0)
	v_and_b32_e32 v17, 0xffff0000, v6
	v_lshlrev_b32_e32 v16, 16, v6
	v_and_b32_e32 v19, 0xffff0000, v3
	v_lshlrev_b32_e32 v18, 16, v3
	v_and_b32_e32 v21, 0xffff0000, v7
	v_lshlrev_b32_e32 v20, 16, v7
	v_and_b32_e32 v7, 0xffff0000, v4
	v_lshlrev_b32_e32 v6, 16, v4
	v_and_b32_e32 v23, 0xffff0000, v8
	v_lshlrev_b32_e32 v22, 16, v8
	v_and_b32_e32 v25, 0xffff0000, v5
	v_lshlrev_b32_e32 v24, 16, v5
	v_and_b32_e32 v27, 0xffff0000, v9
	v_lshlrev_b32_e32 v26, 16, v9
	v_pk_add_f32 v[2:3], v[14:15], v[16:17]
	v_pk_add_f32 v[4:5], v[18:19], v[20:21]
	v_pk_add_f32 v[6:7], v[6:7], v[22:23]
	v_pk_add_f32 v[8:9], v[24:25], v[26:27]
	v_cvt_pk_bf16_f32 v14, v2, v3
	v_cvt_pk_bf16_f32 v15, v4, v5
	v_cvt_pk_bf16_f32 v16, v6, v7
	v_cvt_pk_bf16_f32 v17, v8, v9
	v_pk_mul_f32 v[18:19], v[2:3], v[2:3]
	v_pk_mul_f32 v[20:21], v[4:5], v[4:5]
	buffer_store_dwordx4 v[14:17], v12, s[28:31], 0 offen
	v_pk_mul_f32 v[22:23], v[6:7], v[6:7]
	v_pk_mul_f32 v[24:25], v[8:9], v[8:9]
.Ltmp4:
	v_add_f32_e32 v14, v18, v19
	v_add_f32_e32 v14, v20, v14
	v_add_f32_e32 v14, v21, v14
	v_add_f32_e32 v14, v22, v14
	v_add_f32_e32 v14, v23, v14
	v_add_f32_e32 v14, v24, v14
	v_add_f32_e32 v14, v25, v14
	s_nop 1
	v_add_f32_dpp v14, v14, v14 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_add_f32_dpp v14, v14, v14 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_add_f32_dpp v14, v14, v14 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_add_f32_dpp v14, v14, v14 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp5:
	v_mov_b32_e32 v15, v14
	s_nop 1
	v_mov_b32_dpp v15, v15 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp6:
	v_add_f32_e32 v14, v15, v14
	s_nop 1
	v_add_f32_dpp v14, v14, v14 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp7:
	s_nop 0
	v_readlane_b32 s6, v14, 63
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_2
; %bb.1:
	s_lshr_b32 s7, s17, 4
	s_and_b32 s7, s7, 60
	s_add_i32 s7, s7, 0
	v_mov_b32_e32 v14, s7
	v_mov_b32_e32 v15, s6
	ds_write_b32 v14, v15
.LBB0_2:
	s_or_b64 exec, exec, s[4:5]
	v_cmp_gt_u32_e32 vcc, 16, v0
	v_lshl_add_u32 v14, v0, 2, 0
.Ltmp8:
	v_mov_b32_e32 v15, 0
.Ltmp9:
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[4:5], vcc
; %bb.3:
	ds_read_b32 v15, v14
; %bb.4:
	s_or_b64 exec, exec, s[4:5]
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v16, v15
	s_load_dword s6, s[0:1], 0x38
	s_load_dwordx2 s[4:5], s[0:1], 0x48
	v_mov_b32_dpp v16, v16 row_shr:8 row_mask:0xf bank_mask:0xc
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_nop 0
	v_mov_b32_dpp v16, v15 row_shl:8 row_mask:0xf bank_mask:0x3
.Ltmp10:
	v_add_f32_e32 v15, v15, v16
.Ltmp11:
	v_mov_b32_e32 v16, v15
	s_nop 1
	v_mov_b32_dpp v16, v16 row_shr:4 row_mask:0xf bank_mask:0xa
	s_nop 1
	v_mov_b32_dpp v16, v15 row_shl:4 row_mask:0xf bank_mask:0x5
.Ltmp12:
	v_add_f32_e32 v15, v15, v16
.Ltmp13:
	v_mov_b32_e32 v16, v15
	s_nop 1
	v_mov_b32_dpp v16, v16 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
.Ltmp14:
	v_add_f32_e32 v15, v15, v16
.Ltmp15:
	v_mov_b32_e32 v16, v15
	s_nop 1
	v_mov_b32_dpp v16, v16 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	s_and_saveexec_b64 s[0:1], vcc
; %bb.5:
	v_add_f32_e32 v0, v15, v16
	ds_write_b32 v14, v0
.Ltmp16:
; %bb.6:
	s_or_b64 exec, exec, s[0:1]
	v_lshlrev_b32_e32 v0, 2, v13
	v_bfrev_b32_e32 v13, 1
	s_and_b32 s25, s25, 0xffff
	s_mov_b32 s27, 0x27000
	s_mov_b32 s26, 0x7ffffffe
	v_cndmask_b32_e64 v14, v13, v0, s[2:3]
	v_or_b32_e32 v0, 16, v0
.Ltmp17:
	s_waitcnt lgkmcnt(0)
	s_barrier
.Ltmp18:
	buffer_load_dwordx4 v[14:17], v14, s[24:27], 0 offen
	v_cndmask_b32_e64 v0, v13, v0, s[2:3]
	buffer_load_dwordx4 v[18:21], v0, s[24:27], 0 offen
.Ltmp19:
	v_mov_b32_e32 v0, 0
	ds_read_b32 v0, v0
.Ltmp20:
	v_cvt_f32_i32_e32 v22, s10
	s_and_b32 s9, s9, 0xffff
	s_mov_b32 s10, s26
	s_mov_b32 s11, s27
	s_waitcnt lgkmcnt(0)
	v_div_scale_f32 v23, s[0:1], v22, v22, v0
	v_rcp_f32_e32 v24, v23
	v_div_scale_f32 v25, vcc, v0, v22, v0
	s_and_b32 s13, s13, 0xffff
	v_fma_f32 v26, -v23, v24, 1.0
	v_fmac_f32_e32 v24, v26, v24
	v_mul_f32_e32 v26, v25, v24
	v_fma_f32 v27, -v23, v26, v25
	v_fmac_f32_e32 v26, v27, v24
	v_fma_f32 v23, -v23, v26, v25
	v_div_fmas_f32 v23, v23, v24, v26
	v_div_fixup_f32 v0, v23, v22, v0
	v_add_f32_e32 v0, s4, v0
	v_sqrt_f32_e32 v0, v0
	s_mov_b32 s4, 0x2edbe6ff
	s_mov_b32 s14, s26
	s_mov_b32 s15, s27
	v_div_scale_f32 v22, s[0:1], v0, v0, 1.0
	v_rcp_f32_e32 v23, v22
	v_div_scale_f32 v24, vcc, 1.0, v0, 1.0
	s_and_b32 s21, s21, 0xffff
	v_fma_f32 v25, -v22, v23, 1.0
	v_fmac_f32_e32 v23, v25, v23
	v_mul_f32_e32 v25, v24, v23
	v_fma_f32 v26, -v22, v25, v24
	v_fmac_f32_e32 v25, v26, v23
	v_fma_f32 v22, -v22, v25, v24
	v_div_fmas_f32 v22, v22, v23, v25
	v_div_fixup_f32 v0, v22, v0, 1.0
	v_pk_mul_f32 v[2:3], v[2:3], v[0:1] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[4:5], v[0:1] op_sel_hi:[1,0]
	v_pk_mul_f32 v[6:7], v[6:7], v[0:1] op_sel_hi:[1,0]
	v_pk_mul_f32 v[8:9], v[8:9], v[0:1] op_sel_hi:[1,0]
	v_lshrrev_b32_e32 v1, 2, v1
	v_and_b32_e32 v1, 0xfc, v1
	v_add_u32_e32 v1, 0, v1
	s_mov_b32 s22, s26
	s_mov_b32 s23, s27
	s_waitcnt vmcnt(1)
	v_pk_add_f32 v[14:15], v[14:15], 1.0 op_sel_hi:[1,0]
	v_pk_add_f32 v[16:17], v[16:17], 1.0 op_sel_hi:[1,0]
	v_pk_mul_f32 v[2:3], v[14:15], v[2:3]
	s_waitcnt vmcnt(0)
	v_pk_add_f32 v[14:15], v[18:19], 1.0 op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[16:17], v[4:5]
	v_pk_mul_f32 v[6:7], v[14:15], v[6:7]
	v_cvt_pk_bf16_f32 v2, v2, v3
	v_pk_add_f32 v[16:17], v[20:21], 1.0 op_sel_hi:[1,0]
	v_cvt_pk_bf16_f32 v3, v4, v5
	v_cvt_pk_bf16_f32 v4, v6, v7
	v_lshlrev_b32_e32 v0, 16, v2
	v_and_b32_e32 v6, 0xffff0000, v2
	v_pk_mul_f32 v[8:9], v[16:17], v[8:9]
.Ltmp21:
	v_max_f32_e64 v17, |v6|, |v6|
	v_max_f32_e64 v18, |v0|, |v0|
.Ltmp22:
	v_cvt_pk_bf16_f32 v5, v8, v9
	v_lshlrev_b32_e32 v7, 16, v3
	v_and_b32_e32 v8, 0xffff0000, v3
.Ltmp23:
	v_max_f32_e32 v17, v18, v17
.Ltmp24:
	v_lshlrev_b32_e32 v9, 16, v4
	v_and_b32_e32 v14, 0xffff0000, v4
.Ltmp25:
	v_max3_f32 v17, v17, |v7|, |v8|
.Ltmp26:
	v_lshlrev_b32_e32 v15, 16, v5
	v_and_b32_e32 v16, 0xffff0000, v5
.Ltmp27:
	v_max3_f32 v17, v17, |v9|, |v14|
	v_max3_f32 v17, v17, |v15|, |v16|
.Ltmp28:
	v_mov_b32_e32 v18, v17
.Ltmp29:
	buffer_store_dwordx4 v[2:5], v12, s[8:11], 0 offen
.Ltmp30:
	s_nop 0
	v_mov_b32_dpp v18, v18 row_shr:8 row_mask:0xf bank_mask:0xc
	s_nop 1
	v_mov_b32_dpp v18, v17 row_shl:8 row_mask:0xf bank_mask:0x3
.Ltmp31:
	v_max_f32_e32 v18, v18, v18
	v_max_f32_e32 v17, v17, v18
.Ltmp32:
	v_mov_b32_e32 v18, v17
	s_nop 1
	v_mov_b32_dpp v18, v18 row_shr:4 row_mask:0xf bank_mask:0xa
	s_nop 1
	v_mov_b32_dpp v18, v17 row_shl:4 row_mask:0xf bank_mask:0x5
.Ltmp33:
	v_max_f32_e32 v18, v18, v18
	v_max_f32_e32 v17, v17, v18
.Ltmp34:
	v_mov_b32_e32 v18, v17
	s_nop 1
	v_mov_b32_dpp v18, v18 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
.Ltmp35:
	v_max_f32_e32 v18, v18, v18
	v_max_f32_e32 v17, v17, v18
.Ltmp36:
	v_mov_b32_e32 v18, v17
	s_nop 1
	v_mov_b32_dpp v18, v18 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
.Ltmp37:
	v_max3_f32 v17, v17, v18, s4
	v_mul_f32_e32 v17, s5, v17
	v_div_scale_f32 v18, s[0:1], v17, v17, 1.0
	v_rcp_f32_e32 v19, v18
	v_div_scale_f32 v2, vcc, 1.0, v17, 1.0
	s_and_b32 s0, s17, 0x3c0
	v_fma_f32 v3, -v18, v19, 1.0
	v_fmac_f32_e32 v19, v3, v19
	v_mul_f32_e32 v3, v2, v19
	v_fma_f32 v4, -v18, v3, v2
	v_fmac_f32_e32 v3, v4, v19
	v_fma_f32 v2, -v18, v3, v2
	v_div_fmas_f32 v2, v2, v19, v3
	v_div_fixup_f32 v2, v2, v17, 1.0
	v_mul_f32_e32 v0, v2, v0
	v_mul_f32_e32 v3, v2, v6
	v_mul_f32_e32 v4, v2, v7
	v_mul_f32_e32 v6, v2, v9
	v_mul_f32_e32 v7, v2, v14
	v_mul_f32_e32 v5, v2, v8
	v_mul_f32_e32 v8, v2, v15
	v_mul_f32_e32 v9, v2, v16
	v_cvt_scalef32_pk_fp8_f32 v2, v0, v3, 1.0
	v_cvt_scalef32_pk_fp8_f32 v3, v6, v7, 1.0
	v_cvt_scalef32_pk_fp8_f32 v2, v4, v5, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v3, v8, v9, 1.0 op_sel:[0,0,0,1]
	v_cndmask_b32_e64 v0, v13, v11, s[2:3]
	buffer_store_dwordx2 v[2:3], v0, s[12:15], 0 offen
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b32 v1, v17
	v_lshl_add_u32 v1, v10, 2, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b32 v1, v1
	s_cmp_eq_u32 s0, 0
	v_cmp_gt_u32_e32 vcc, 40, v10
	v_mul_lo_u32 v0, s6, v10
	s_cselect_b64 s[0:1], -1, 0
	v_add_lshl_u32 v0, v0, s16, 2
	s_and_b64 vcc, vcc, s[0:1]
	v_cndmask_b32_e32 v0, v13, v0, vcc
	s_waitcnt lgkmcnt(0)
	buffer_store_dword v1, v0, s[20:23], 0 offen
	s_endpgm
.Ltmp38:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel \symbol
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 96
		.amdhsa_user_sgpr_count 16
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 0
		.amdhsa_user_sgpr_kernarg_preload_length 14
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 28
		.amdhsa_next_free_sgpr 40
		.amdhsa_accum_offset 28
		.amdhsa_reserve_vcc 1
		.amdhsa_reserve_xnack_mask 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
		.amdhsa_exception_fp_ieee_invalid_op 0
		.amdhsa_exception_fp_denorm_src 0
		.amdhsa_exception_fp_ieee_div_zero 0
		.amdhsa_exception_fp_ieee_overflow 0
		.amdhsa_exception_fp_ieee_underflow 0
		.amdhsa_exception_fp_ieee_inexact 0
		.amdhsa_exception_int_div_zero 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size	\symbol, .Lfunc_end0-\symbol
                                        ; -- End function
	.set \symbol\().num_vgpr, 28
	.set \symbol\().num_agpr, 0
	.set \symbol\().numbered_sgpr, 40
	.set \symbol\().num_named_barrier, 0
	.set \symbol\().private_seg_size, 0
	.set \symbol\().uses_vcc, 1
	.set \symbol\().uses_flat_scratch, 0
	.set \symbol\().has_dyn_sized_stack, 0
	.set \symbol\().has_recursion, 0
	.set \symbol\().has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1964
; TotalNumSgprs: 46
; NumVgprs: 28
; NumAgprs: 0
; TotalNumVgprs: 28
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 5
; VGPRBlocks: 3
; NumSGPRsForWavesPerEU: 46
; NumVGPRsForWavesPerEU: 28
; AccumOffset: 28
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 6
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.set amdgpu.max_num_named_barrier, 0
	.text
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         24
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         32
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         40
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         48
        .size:           8
        .value_kind:     global_buffer
      - .offset:         56
        .size:           4
        .value_kind:     by_value
      - .offset:         60
        .size:           4
        .value_kind:     by_value
      - .offset:         64
        .size:           4
        .value_kind:     by_value
      - .offset:         68
        .size:           4
        .value_kind:     by_value
      - .offset:         72
        .size:           4
        .value_kind:     by_value
      - .offset:         76
        .size:           4
        .value_kind:     by_value
      - .address_space:  global
        .offset:         80
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         88
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 96
    .max_flat_workgroup_size: 1024
    .name:           \symbol
    .private_segment_fixed_size: 0
    .sgpr_count:     46
    .sgpr_spill_count: 0
    .symbol:         \symbol\().kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     28
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
.Lline_table_start0:
	.endm
