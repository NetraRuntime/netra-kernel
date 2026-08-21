// Netra model-independent fixed-contract tactic template.
	.include "kernels/gfx950/templates/common/primitives.inc"
	.include "kernels/gfx950/templates/attention/common/kernel_descriptor.inc"
	.include "kernels/gfx950/templates/attention/verify/splitseq_metadata.inc"
	NETRA_GFX950_MODULE_HEADER 5
; Qwen3.6 full-attention M=16 speculative verification, stage 2.
; Hand-maintained gfx950/wave64 assembly for the real deterministic serving
; contract (MAX_KV_SPLITS=129).  The pointer at kernarg offset 32 addresses
; sixteen int32 sequence lengths rather than a 17-entry CSR indptr.
	.macro NETRA_ATTENTION_SPLITSEQ_STAGE2 symbol
	NETRA_REQUIRE_GFX950_WAVE64
	NETRA_REQUIRE_EQ NETRA_M_MAX, 16
	NETRA_REQUIRE_EQ NETRA_QUERY_HEADS, 16
	NETRA_REQUIRE_EQ NETRA_KV_HEADS, 2
	NETRA_REQUIRE_EQ NETRA_HEAD_DIM, 256
	NETRA_REQUIRE_EQ NETRA_KV_SPLITS_MAX, 129
	NETRA_KERNEL_ENTRY \symbol, 0
.Lfunc_begin0:
; %bb.9:
	NETRA_LOAD_KERNARG_PTR s[2:3], 0x0
	NETRA_LOAD_KERNARG_U32X8 s[4:11], 0x8
	NETRA_LOAD_KERNARG_U32X4 s[12:15], 0x28
	NETRA_WAIT_LGKM0
	s_branch .LBB0_0
.Ltmp0:
	.p2align	8
; %bb.10:
.LBB0_0:
	s_mov_b64 s[24:25], s[2:3]
.Ltmp1:
	s_ashr_i32 s3, s16, 31
	s_mov_b32 s2, s16
	s_lshl_b64 s[2:3], s[2:3], 2
	s_add_u32 s2, s10, s2
	s_addc_u32 s3, s11, s3
	s_mov_b64 s[10:11], s[2:3]
	s_mov_b64 s[20:21], s[6:7]
	s_load_dword s18, s[10:11], 0x0
	s_load_dwordx2 s[2:3], s[0:1], 0x38
	s_load_dword s6, s[0:1], 0x40
	s_mov_b32 s9, s17
	s_ashr_i32 s17, s16, 31
	NETRA_WAIT_LGKM0
	s_mov_b32 s10, s18
	s_lshl_b64 s[0:1], s[16:17], 2
	s_add_u32 s0, s12, s0
	s_addc_u32 s1, s13, s1
	s_load_dword s0, s[0:1], 0x0
	v_readfirstlane_b32 s7, v0
	v_and_b32_e32 v2, 63, v0
	s_mul_i32 s1, s14, s16
	s_mul_i32 s17, s15, s9
.Ltmp2:
	NETRA_WAIT_LGKM0
	s_abs_i32 s13, s0
	v_cvt_f32_u32_e32 v0, s13
.Ltmp3:
	s_add_i32 s11, s17, s1
	s_ashr_i32 s12, s11, 31
	s_lshr_b32 s12, s12, 24
.Ltmp4:
	v_rcp_iflag_f32_e32 v0, v0
	s_sub_i32 s15, 0, s13
.Ltmp5:
	s_add_i32 s11, s11, s12
.Ltmp6:
	s_add_i32 s12, s0, s10
	v_mul_f32_e32 v0, 0x4f7ffffe, v0
	v_cvt_u32_f32_e32 v0, v0
	s_add_i32 s12, s12, -1
	s_abs_i32 s14, s12
	s_xor_b32 s0, s12, s0
	v_readfirstlane_b32 s18, v0
	s_mul_i32 s15, s15, s18
	s_mul_hi_u32 s15, s18, s15
	s_add_i32 s18, s18, s15
	s_mul_hi_u32 s15, s14, s18
	s_mul_i32 s18, s15, s13
	s_sub_i32 s14, s14, s18
.Ltmp7:
	s_ashr_i32 s11, s11, 8
.Ltmp8:
	s_ashr_i32 s0, s0, 31
	s_add_i32 s18, s15, 1
	s_sub_i32 s19, s14, s13
	s_cmp_ge_u32 s14, s13
	s_cselect_b32 s15, s18, s15
	s_cselect_b32 s14, s19, s14
	s_add_i32 s18, s15, 1
	s_cmp_ge_u32 s14, s13
	s_cselect_b32 s13, s18, s15
	s_xor_b32 s13, s13, s0
	s_sub_i32 s0, s13, s0
.Ltmp9:
	s_add_i32 s0, s0, 31
	s_ashr_i32 s13, s0, 31
	s_lshr_b32 s13, s13, 27
.Ltmp10:
	s_lshl_b32 s1, s1, 2
.Ltmp11:
	s_add_i32 s13, s0, s13
.Ltmp12:
	s_lshl2_add_u32 s1, s17, s1
	s_lshl_b32 s17, s7, 2
.Ltmp13:
	s_ashr_i32 s0, s13, 5
.Ltmp14:
	v_lshlrev_b32_e32 v3, 2, v2
	s_and_b32 s17, s17, 0x300
	v_mov_b32_e32 v0, 0
	s_mov_b32 s12, 0
	s_andn2_b32 s13, s13, 31
	s_mov_b32 s27, 0x27000
	s_mov_b32 s26, 0x7ffffffe
	s_and_b32 s25, s25, 0xffff
	s_lshl_b32 s14, s2, 1
	s_mul_i32 s15, s2, 3
	v_lshl_add_u32 v4, s2, 3, v3
	s_add_i32 s17, s1, s17
	s_mul_i32 s18, s2, 12
	v_lshl_add_u32 v5, s2, 2, v3
	s_mul_i32 s19, s0, 0x60
	s_lshl_b32 s22, s0, 6
	v_mov_b32_e32 v1, v0
	s_movk_i32 s23, 0x81
	v_mov_b32_e32 v7, 0xff800000
	s_mov_b32 s28, 0xc2fc0000
	v_mov_b32_e32 v6, 0x42800000
	s_mov_b32 s29, 0
	s_branch .LBB0_2
.LBB0_1:                                ;   in Loop: Header=BB0_2 Depth=1
	s_add_i32 s23, s23, -3
	s_add_i32 s29, s29, s15
	s_add_i32 s17, s17, s18
	s_cmp_lg_u32 s23, 0
	s_cbranch_scc0 .LBB0_8
.LBB0_2:                                ; =>This Inner Loop Header: Depth=1
	s_add_i32 s31, s13, s12
	s_min_i32 s0, s31, s10
	s_cmp_le_i32 s0, s12
	s_cbranch_scc0 .LBB0_5
; %bb.3:                                ;   in Loop: Header=BB0_2 Depth=1
	s_add_i32 s30, s22, s12
	s_min_i32 s0, s30, s10
	s_cmp_le_i32 s0, s31
	s_cbranch_scc0 .LBB0_6
.LBB0_4:                                ;   in Loop: Header=BB0_2 Depth=1
	s_add_i32 s12, s19, s12
	s_min_i32 s0, s12, s10
	s_cmp_le_i32 s0, s30
	s_cbranch_scc1 .LBB0_1
	s_branch .LBB0_7
.LBB0_5:                                ;   in Loop: Header=BB0_2 Depth=1
	v_add_u32_e32 v8, s17, v3
	buffer_load_dword v9, v8, s[24:27], 0 offen
	s_ashr_i32 s0, s29, 31
	s_lshr_b32 s0, s0, 24
	s_add_i32 s0, s29, s0
	s_ashr_i32 s0, s0, 8
	s_add_i32 s0, s0, s11
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s0, s4, s0
	s_addc_u32 s1, s5, s1
	s_load_dword s0, s[0:1], 0x0
	v_max_f32_e32 v8, v7, v7
	NETRA_WAIT_LGKM0
	v_max_f32_e64 v10, s0, s0
	v_max_f32_e32 v12, v10, v8
	v_sub_f32_e32 v7, v7, v12
	v_sub_f32_e32 v8, s0, v12
	v_mul_f32_e32 v10, 0x3fb8aa3b, v7
	v_mul_f32_e32 v11, 0x3fb8aa3b, v8
	v_cmp_gt_f32_e32 vcc, s28, v10
	v_cmp_gt_f32_e64 s[0:1], s28, v11
	s_and_b64 s[34:35], vcc, exec
	v_cndmask_b32_e32 v10, 0, v6, vcc
	v_cndmask_b32_e64 v11, 0, v6, s[0:1]
	v_fmac_f32_e32 v10, 0x3fb8aa3b, v7
	v_fmac_f32_e32 v11, 0x3fb8aa3b, v8
	v_exp_f32_e32 v7, v10
	v_exp_f32_e32 v10, v11
	s_cselect_b32 s30, 0xffffffc0, 0
	s_and_b64 s[0:1], s[0:1], exec
	s_cselect_b32 s0, 0xffffffc0, 0
	v_ldexp_f32 v10, v10, s0
	v_ldexp_f32 v8, v7, s30
	v_mov_b32_e32 v7, v12
	NETRA_WAIT_VM0
	v_mul_f32_e32 v11, v9, v10
	v_pk_fma_f32 v[0:1], v[0:1], v[8:9], v[10:11] op_sel_hi:[1,0,1]
	s_add_i32 s30, s22, s12
	s_min_i32 s0, s30, s10
	s_cmp_le_i32 s0, s31
	s_cbranch_scc1 .LBB0_4
.LBB0_6:                                ;   in Loop: Header=BB0_2 Depth=1
	v_add_u32_e32 v8, s17, v5
	buffer_load_dword v9, v8, s[24:27], 0 offen
	s_add_i32 s0, s2, s29
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 24
	s_add_i32 s0, s0, s1
	s_ashr_i32 s0, s0, 8
	s_add_i32 s0, s0, s11
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s0, s4, s0
	s_addc_u32 s1, s5, s1
	s_load_dword s0, s[0:1], 0x0
	v_max_f32_e32 v8, v7, v7
	NETRA_WAIT_LGKM0
	v_max_f32_e64 v10, s0, s0
	v_max_f32_e32 v12, v10, v8
	v_sub_f32_e32 v7, v7, v12
	v_sub_f32_e32 v8, s0, v12
	v_mul_f32_e32 v10, 0x3fb8aa3b, v7
	v_mul_f32_e32 v11, 0x3fb8aa3b, v8
	v_cmp_gt_f32_e32 vcc, s28, v10
	v_cmp_gt_f32_e64 s[0:1], s28, v11
	s_and_b64 s[34:35], vcc, exec
	v_cndmask_b32_e32 v10, 0, v6, vcc
	v_cndmask_b32_e64 v11, 0, v6, s[0:1]
	v_fmac_f32_e32 v10, 0x3fb8aa3b, v7
	v_fmac_f32_e32 v11, 0x3fb8aa3b, v8
	v_exp_f32_e32 v7, v10
	v_exp_f32_e32 v10, v11
	s_cselect_b32 s31, 0xffffffc0, 0
	s_and_b64 s[0:1], s[0:1], exec
	s_cselect_b32 s0, 0xffffffc0, 0
	v_ldexp_f32 v10, v10, s0
	v_ldexp_f32 v8, v7, s31
	v_mov_b32_e32 v7, v12
	NETRA_WAIT_VM0
	v_mul_f32_e32 v11, v9, v10
	v_pk_fma_f32 v[0:1], v[0:1], v[8:9], v[10:11] op_sel_hi:[1,0,1]
	s_add_i32 s12, s19, s12
	s_min_i32 s0, s12, s10
	s_cmp_le_i32 s0, s30
	s_cbranch_scc1 .LBB0_1
.LBB0_7:                                ;   in Loop: Header=BB0_2 Depth=1
	v_add_u32_e32 v8, s17, v4
	buffer_load_dword v9, v8, s[24:27], 0 offen
	s_add_i32 s0, s14, s29
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 24
	s_add_i32 s0, s0, s1
	s_ashr_i32 s0, s0, 8
	s_add_i32 s0, s0, s11
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s0, s4, s0
	s_addc_u32 s1, s5, s1
	s_load_dword s0, s[0:1], 0x0
	v_max_f32_e32 v8, v7, v7
	NETRA_WAIT_LGKM0
	v_max_f32_e64 v10, s0, s0
	v_max_f32_e32 v12, v10, v8
	v_sub_f32_e32 v7, v7, v12
	v_sub_f32_e32 v8, s0, v12
	v_mul_f32_e32 v10, 0x3fb8aa3b, v7
	v_mul_f32_e32 v11, 0x3fb8aa3b, v8
	v_cmp_gt_f32_e32 vcc, s28, v10
	v_cmp_gt_f32_e64 s[0:1], s28, v11
	s_and_b64 s[30:31], vcc, exec
	v_cndmask_b32_e32 v10, 0, v6, vcc
	v_cndmask_b32_e64 v11, 0, v6, s[0:1]
	v_fmac_f32_e32 v10, 0x3fb8aa3b, v7
	v_fmac_f32_e32 v11, 0x3fb8aa3b, v8
	v_exp_f32_e32 v7, v10
	v_exp_f32_e32 v10, v11
	s_cselect_b32 s30, 0xffffffc0, 0
	s_and_b64 s[0:1], s[0:1], exec
	s_cselect_b32 s0, 0xffffffc0, 0
	v_ldexp_f32 v10, v10, s0
	v_ldexp_f32 v8, v7, s30
	v_mov_b32_e32 v7, v12
	NETRA_WAIT_VM0
	v_mul_f32_e32 v11, v9, v10
	v_pk_fma_f32 v[0:1], v[0:1], v[8:9], v[10:11] op_sel_hi:[1,0,1]
	s_branch .LBB0_1
.LBB0_8:
	s_and_b32 s0, s7, 0xc0
	v_or_b32_e32 v2, s0, v2
	v_div_scale_f32 v3, s[0:1], v0, v0, v1
	v_rcp_f32_e32 v4, v3
	s_mul_i32 s0, s3, s16
	s_mul_i32 s1, s6, s9
	s_add_i32 s1, s1, s0
	v_fma_f32 v5, -v3, v4, 1.0
	v_fmac_f32_e32 v4, v5, v4
	v_div_scale_f32 v5, vcc, v1, v0, v1
	v_mul_f32_e32 v6, v5, v4
	v_fma_f32 v7, -v3, v6, v5
	v_fmac_f32_e32 v6, v7, v4
	v_fma_f32 v3, -v3, v6, v5
	v_div_fmas_f32 v3, v3, v4, v6
	v_div_fixup_f32 v0, v3, v0, v1
	v_mul_f32_e32 v0, s8, v0
	v_cvt_pk_bf16_f32 v0, v0, s0
	s_and_b32 s21, s21, 0xffff
	s_mov_b32 s23, 0x27000
	s_mov_b32 s22, 0x7ffffffe
	v_add_lshl_u32 v1, s1, v2, 1
	buffer_store_short v0, v1, s[20:23], 0 offen
	s_endpgm
.Ltmp15:
	NETRA_ATTENTION_KERNEL_DESCRIPTOR \symbol, 0, 88, 1, 0, 97, 96, 16
	.text
.Lfunc_end0:
	.size	\symbol, .Lfunc_end0-\symbol
                                        ; -- End function
	.set \symbol\().num_vgpr, 13
	.set \symbol\().num_agpr, 0
	.set \symbol\().numbered_sgpr, 36
	.set \symbol\().num_named_barrier, 0
	.set \symbol\().private_seg_size, 0
	.set \symbol\().uses_vcc, 1
	.set \symbol\().uses_flat_scratch, 0
	.set \symbol\().has_dyn_sized_stack, 0
	.set \symbol\().has_recursion, 0
	.set \symbol\().has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1564
; TotalNumSgprs: 42
; NumVgprs: 13
; NumAgprs: 0
; TotalNumVgprs: 13
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 12
; VGPRBlocks: 12
; NumSGPRsForWavesPerEU: 102
; NumVGPRsForWavesPerEU: 97
; AccumOffset: 16
; Occupancy: 4
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 3
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
	.section	".note.GNU-stack","",@progbits
	NETRA_ATTENTION_SPLITSEQ_STAGE2_METADATA \symbol
	.endm
