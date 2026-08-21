// Netra model-independent fixed-contract assembly tactic.
	.include "kernels/gfx950/templates/common/primitives.inc"
	NETRA_GFX950_MODULE_HEADER 5
	.macro NETRA_GATED_RMSNORM_QUANT_D128_RPB1 symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_WIDTH, 128
	NETRA_REQUIRE_EQ NETRA_HEADS, 48
	NETRA_REQUIRE_EQ NETRA_QUANT_GROUP_SIZE, 128
	NETRA_REQUIRE_EQ NETRA_SCALE_LAYOUT_ID, 1
	NETRA_REQUIRE_EQ NETRA_ROWS_PER_BLOCK, 1
	.text
	.globl	\symbol ; -- Begin function \symbol
	.p2align	8
	.type	\symbol,@function
\symbol:     ; @\symbol
.Lfunc_begin0:
; %bb.1:
	s_load_dwordx2 s[2:3], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_waitcnt lgkmcnt(0)
	s_branch .LBB0_0
.Ltmp0:
	.p2align	8
; %bb.2:
.LBB0_0:
	s_load_dwordx4 s[28:31], s[0:1], 0x38
	s_load_dwordx2 s[18:19], s[0:1], 0x48
	s_load_dword s17, s[0:1], 0x50
	s_mov_b64 s[24:25], s[10:11]
	s_mov_b64 s[36:37], s[6:7]
	s_mov_b64 s[20:21], s[2:3]
.Ltmp1:
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	s_waitcnt lgkmcnt(0)
	s_cmp_lt_i32 s16, s30
	s_cselect_b64 s[0:1], -1, 0
	s_abs_i32 s2, s31
	v_cvt_f32_u32_e32 v3, s2
	v_lshlrev_b32_e32 v1, 1, v0
	s_mul_i32 s14, s14, s16
	s_sub_i32 s7, 0, s2
	v_rcp_iflag_f32_e32 v3, v3
	v_add_lshl_u32 v2, s14, v1, 1
	v_bfrev_b32_e32 v8, 1
	s_and_b32 s21, s21, 0xffff
	v_mul_f32_e32 v3, 0x4f7ffffe, v3
	v_cvt_u32_f32_e32 v3, v3
	s_mov_b32 s23, 0x27000
	s_mov_b32 s22, 0x7ffffffe
	v_cndmask_b32_e64 v2, v8, v2, s[0:1]
	v_readfirstlane_b32 s10, v3
	s_mul_i32 s7, s7, s10
	s_mul_hi_u32 s7, s10, s7
	buffer_load_dword v2, v2, s[20:23], 0 offen
	s_abs_i32 s6, s16
	s_add_i32 s10, s10, s7
	s_mul_hi_u32 s7, s6, s10
	s_mul_i32 s10, s7, s2
	s_xor_b32 s3, s16, s31
	s_sub_i32 s6, s6, s10
	s_and_b32 s37, s37, 0xffff
	s_ashr_i32 s3, s3, 31
	s_add_i32 s10, s7, 1
	s_sub_i32 s11, s6, s2
	s_cmp_ge_u32 s6, s2
	s_cselect_b32 s7, s10, s7
	s_cselect_b32 s6, s11, s6
	s_add_i32 s10, s7, 1
	s_cmp_ge_u32 s6, s2
	s_cselect_b32 s2, s10, s7
	s_xor_b32 s2, s2, s3
	s_sub_i32 s14, s2, s3
	s_mul_i32 s3, s14, s31
	s_sub_i32 s20, s16, s3
	s_mul_i32 s2, s14, s28
	s_mul_i32 s3, s20, s29
	s_add_i32 s3, s3, s2
	v_add_lshl_u32 v3, s3, v1, 1
	s_mov_b32 s38, s22
	s_mov_b32 s39, s23
	v_lshlrev_b32_e32 v4, 2, v0
	s_and_b32 s9, s9, 0xffff
	s_mov_b32 s10, s22
	s_mov_b32 s11, s23
	v_cndmask_b32_e64 v3, v8, v3, s[0:1]
	buffer_load_dword v5, v4, s[36:39], 0 offen
	buffer_load_dword v9, v3, s[8:11], 0 offen
	s_mul_i32 s15, s15, s16
	v_add_lshl_u32 v3, s15, v1, 1
	v_cndmask_b32_e64 v12, v8, v3, s[0:1]
	v_mov_b32_e32 v4, s19
	v_bfrev_b32_e32 v6, 60
	s_mov_b32 s2, 0x3fb8aa3b
	s_mov_b32 s3, 0xc2fc0000
.Ltmp2:
	v_mov_b32_e32 v10, 0x42800000
	v_not_b32_e32 v11, 63
.Ltmp3:
	s_mov_b32 s6, s22
	s_mov_b32 s7, s23
	s_and_b32 s5, s5, 0xffff
	v_lshl_or_b32 v1, s16, 7, v1
	s_and_b32 s25, s25, 0xffff
	s_mov_b32 s26, s22
	s_mov_b32 s27, s23
	v_cndmask_b32_e64 v1, v8, v1, s[0:1]
	s_and_b32 s13, s13, 0xffff
	s_mov_b32 s15, s23
	s_waitcnt vmcnt(2)
	v_and_b32_e32 v3, 0xffff0000, v2
	v_lshlrev_b32_e32 v2, 16, v2
	v_cndmask_b32_e64 v13, 0, v3, s[0:1]
	v_cndmask_b32_e64 v7, 0, v2, s[0:1]
	v_mul_f32_e32 v13, v13, v13
.Ltmp4:
	v_fmac_f32_e32 v13, v7, v7
	s_nop 1
	v_add_f32_dpp v7, v13, v13 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_add_f32_dpp v7, v7, v7 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_add_f32_dpp v7, v7, v7 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_add_f32_dpp v7, v7, v7 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp5:
	v_mov_b32_e32 v13, v7
	s_nop 1
	v_mov_b32_dpp v13, v13 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp6:
	v_add_f32_e32 v7, v13, v7
	s_nop 1
	v_add_f32_dpp v7, v7, v7 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp7:
	s_nop 0
	v_readlane_b32 s8, v7, 63
.Ltmp8:
	s_waitcnt vmcnt(1)
	v_and_b32_e32 v7, 0xffff0000, v5
	v_fma_f32 v4, s8, v6, v4
	v_rsq_f32_e32 v4, v4
	v_lshlrev_b32_e32 v6, 16, v5
	v_pk_mul_f32 v[2:3], v[4:5], v[2:3] op_sel_hi:[0,1]
	s_waitcnt vmcnt(0)
	v_and_b32_e32 v5, 0xffff0000, v9
	v_lshlrev_b32_e32 v4, 16, v9
.Ltmp9:
	v_mul_f32_e64 v9, -v4, s2
	v_mul_f32_e64 v13, -v5, s2
	v_cmp_gt_f32_e32 vcc, s3, v9
	v_cmp_gt_f32_e64 s[2:3], s3, v13
.Ltmp10:
	v_pk_mul_f32 v[2:3], v[2:3], v[6:7]
.Ltmp11:
	v_sub_f32_e32 v6, 0, v4
	v_sub_f32_e32 v7, 0, v5
	v_cndmask_b32_e32 v9, 0, v10, vcc
	v_cndmask_b32_e64 v10, 0, v10, s[2:3]
	v_fmac_f32_e32 v9, 0x3fb8aa3b, v6
	v_fmac_f32_e32 v10, 0x3fb8aa3b, v7
	v_exp_f32_e32 v6, v9
	v_exp_f32_e32 v7, v10
	v_cndmask_b32_e32 v9, 0, v11, vcc
	v_cndmask_b32_e64 v10, 0, v11, s[2:3]
	v_ldexp_f32 v6, v6, v9
	v_ldexp_f32 v7, v7, v10
	v_pk_add_f32 v[6:7], v[6:7], 1.0 op_sel_hi:[1,0]
	s_nop 0
	v_div_scale_f32 v9, s[2:3], v7, v7, 1.0
	v_div_scale_f32 v11, s[2:3], v6, v6, 1.0
	v_rcp_f32_e32 v13, v9
	v_rcp_f32_e32 v14, v11
	v_div_scale_f32 v10, vcc, 1.0, v7, 1.0
	v_fma_f32 v16, -v9, v13, 1.0
	v_fma_f32 v17, -v11, v14, 1.0
	v_fmac_f32_e32 v13, v16, v13
	v_div_scale_f32 v15, s[2:3], 1.0, v6, 1.0
	v_fmac_f32_e32 v14, v17, v14
	v_mul_f32_e32 v16, v10, v13
	v_mul_f32_e32 v17, v15, v14
	v_fma_f32 v18, -v9, v16, v10
	v_fma_f32 v19, -v11, v17, v15
	v_fmac_f32_e32 v16, v18, v13
	v_fmac_f32_e32 v17, v19, v14
	v_fma_f32 v9, -v9, v16, v10
	v_fma_f32 v10, -v11, v17, v15
	v_div_fmas_f32 v9, v9, v13, v16
	s_mov_b64 vcc, s[2:3]
	v_div_fixup_f32 v7, v9, v7, 1.0
	v_div_fmas_f32 v9, v10, v14, v17
	v_div_fixup_f32 v6, v9, v6, 1.0
.Ltmp12:
	v_pk_mul_f32 v[4:5], v[6:7], v[4:5]
	s_nop 0
	v_pk_mul_f32 v[2:3], v[2:3], v[4:5]
	s_nop 0
	v_cvt_pk_bf16_f32 v2, v2, v3
	v_lshlrev_b32_e32 v3, 16, v2
	v_and_b32_e32 v4, 0xffff0000, v2
	v_cndmask_b32_e64 v3, 0, v3, s[0:1]
	v_cndmask_b32_e64 v4, 0, v4, s[0:1]
.Ltmp13:
	v_max_f32_e64 v5, |v4|, |v4|
	v_max_f32_e64 v6, |v3|, |v3|
	v_max_f32_e32 v5, v6, v5
.Ltmp14:
	buffer_store_dword v2, v12, s[4:7], 0 offen
.Ltmp15:
	s_nop 0
	v_mov_b32_dpp v6, v5 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp16:
	v_max_f32_e32 v6, v6, v6
	v_max_f32_e32 v5, v5, v6
.Ltmp17:
	s_nop 1
	v_mov_b32_dpp v6, v5 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp18:
	v_max_f32_e32 v6, v6, v6
	v_max_f32_e32 v5, v5, v6
.Ltmp19:
	s_nop 1
	v_mov_b32_dpp v6, v5 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp20:
	v_max_f32_e32 v6, v6, v6
	v_max_f32_e32 v5, v5, v6
.Ltmp21:
	s_nop 1
	v_mov_b32_dpp v6, v5 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp22:
	v_max_f32_e32 v6, v6, v6
	v_max_f32_e32 v5, v5, v6
.Ltmp23:
	v_mov_b32_e32 v6, v5
	s_nop 1
	v_mov_b32_dpp v6, v6 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp24:
	v_max_f32_e32 v6, v6, v6
	v_max_f32_e32 v5, v5, v6
.Ltmp25:
	s_nop 1
	v_mov_b32_dpp v6, v5 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp26:
	v_max_f32_e32 v6, v6, v6
	v_max_f32_e32 v5, v5, v6
.Ltmp27:
	s_nop 0
	v_readlane_b32 s2, v5, 63
.Ltmp28:
	s_nop 1
	v_max_f32_e64 v5, s2, s2
	v_max_f32_e32 v5, 0x2edbe6ff, v5
	v_mul_f32_e32 v5, s17, v5
	v_div_scale_f32 v6, s[2:3], v5, v5, 1.0
	v_rcp_f32_e32 v7, v6
	v_div_scale_f32 v2, vcc, 1.0, v5, 1.0
	s_mul_i32 s2, s20, s18
	v_fma_f32 v9, -v6, v7, 1.0
	v_fmac_f32_e32 v7, v9, v7
	v_mul_f32_e32 v9, v2, v7
	v_fma_f32 v10, -v6, v9, v2
	v_fmac_f32_e32 v9, v10, v7
	v_fma_f32 v2, -v6, v9, v2
	v_div_fmas_f32 v2, v2, v7, v9
	v_div_fixup_f32 v2, v2, v5, 1.0
	v_mul_f32_e32 v3, v2, v3
	v_mul_f32_e32 v2, v2, v4
	s_add_i32 s2, s2, s14
	v_cvt_scalef32_pk_fp8_f32 v2, v3, v2, 1.0
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_lshl_b32 s2, s2, 2
	v_cvt_scalef32_pk_fp8_f32 v2, s0, v0, 1.0 op_sel:[0,0,0,1]
	v_mov_b32_e32 v0, s2
	s_and_b64 vcc, vcc, s[0:1]
	s_mov_b32 s14, s22
	v_cndmask_b32_e32 v0, v8, v0, vcc
	buffer_store_short v2, v1, s[24:27], 0 offen
	buffer_store_dword v5, v0, s[12:15], 0 offen
	s_endpgm
.Ltmp29:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel \symbol
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 104
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
		.amdhsa_next_free_vgpr 20
		.amdhsa_next_free_sgpr 40
		.amdhsa_accum_offset 20
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
	.set \symbol\().num_vgpr, 20
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
; codeLenInByte = 1532
; TotalNumSgprs: 46
; NumVgprs: 20
; NumAgprs: 0
; TotalNumVgprs: 20
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 5
; VGPRBlocks: 2
; NumSGPRsForWavesPerEU: 46
; NumVGPRsForWavesPerEU: 20
; AccumOffset: 20
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 4
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
      - .offset:         48
        .size:           4
        .value_kind:     by_value
      - .offset:         52
        .size:           4
        .value_kind:     by_value
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
      - .offset:         80
        .size:           4
        .value_kind:     by_value
      - .address_space:  global
        .offset:         88
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         96
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 104
    .max_flat_workgroup_size: 64
    .name:           \symbol
    .private_segment_fixed_size: 0
    .sgpr_count:     46
    .sgpr_spill_count: 0
    .symbol:         \symbol\().kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     20
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
