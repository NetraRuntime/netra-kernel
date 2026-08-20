	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 5
	.text
	.globl	_gemma_fused_add_rmsnorm_group_quant_kernel ; -- Begin function _gemma_fused_add_rmsnorm_group_quant_kernel
	.p2align	8
	.type	_gemma_fused_add_rmsnorm_group_quant_kernel,@function
_gemma_fused_add_rmsnorm_group_quant_kernel: ; @_gemma_fused_add_rmsnorm_group_quant_kernel
.Lfunc_begin0:
	.cfi_sections .debug_frame
	.cfi_startproc
; %bb.7:
	.file	1 "/netra-server/python/sglang/jit_kernel/minimax_m3" "rmsnorm.py"
	.loc	1 149 0 prologue_end            ; rmsnorm.py:149:0
	s_load_dwordx2 s[2:3], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_waitcnt lgkmcnt(0)
	s_branch .LBB0_0
	.loc	1 0 0 is_stmt 0                 ; :0:0
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
	.loc	1 149 0 is_stmt 1               ; rmsnorm.py:149
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	.loc	1 219 49                        ; rmsnorm.py:219:49
	v_readfirstlane_b32 s17, v0
	s_movk_i32 s2, 0xffc0
	s_mov_b32 s39, 0x27000
	.loc	1 184 24                        ; rmsnorm.py:184:24
	v_mov_b32_e32 v1, s17
	v_bfi_b32 v1, s2, v1, v0
	v_lshlrev_b32_e32 v2, 3, v1
	v_and_b32_e32 v13, 0x1ff8, v2
	.loc	1 187 22                        ; rmsnorm.py:187:22
	s_waitcnt lgkmcnt(0)
	s_mul_i32 s2, s11, s16
	.loc	1 190 24                        ; rmsnorm.py:190:24
	s_mul_i32 s11, s6, s16
	s_mov_b32 s38, 0x7ffffffe
	.loc	1 187 8                         ; rmsnorm.py:187:8
	v_add_lshl_u32 v2, v13, s2, 1
	v_bfrev_b32_e32 v12, 1
	.loc	1 185 18                        ; rmsnorm.py:185:18
	v_cmp_gt_i32_e64 s[2:3], s10, v13
	.loc	1 190 8                         ; rmsnorm.py:190:8
	v_add_lshl_u32 v6, v13, s11, 1
	.loc	1 187 8                         ; rmsnorm.py:187:8
	s_and_b32 s37, s37, 0xffff
	v_cndmask_b32_e64 v2, v12, v2, s[2:3]
	.loc	1 190 8                         ; rmsnorm.py:190:8
	s_and_b32 s5, s5, 0xffff
	s_mov_b32 s6, s38
	s_mov_b32 s7, s39
	v_cndmask_b32_e64 v6, v12, v6, s[2:3]
	.loc	1 187 8                         ; rmsnorm.py:187:8
	buffer_load_dwordx4 v[2:5], v2, s[36:39], 0 offen
	.loc	1 195 8                         ; rmsnorm.py:195:8
	s_and_b32 s29, s29, 0xffff
	.loc	1 190 8                         ; rmsnorm.py:190:8
	buffer_load_dwordx4 v[6:9], v6, s[4:7], 0 offen
	.loc	1 194 28                        ; rmsnorm.py:194:28
	s_mul_i32 s4, s10, s16
	.loc	1 194 37 is_stmt 0              ; rmsnorm.py:194:37
	v_add_u32_e32 v11, s4, v13
	.loc	1 195 8 is_stmt 1               ; rmsnorm.py:195:8
	v_lshlrev_b32_e32 v14, 1, v11
	v_cndmask_b32_e64 v12, v12, v14, s[2:3]
	s_mov_b32 s30, s38
	s_mov_b32 s31, s39
	.loc	1 184 24                        ; rmsnorm.py:184:24
	v_and_b32_e32 v10, 63, v0
.Ltmp2:
	.file	2 "/sgl-workspace/triton-custom/python/triton/language" "standard.py"
	.loc	2 293 36                        ; standard.py:293:36 @[ rmsnorm.py:198:17 ]
	v_cmp_eq_u32_e32 vcc, 0, v10
.Ltmp3:
	.loc	1 188 9                         ; rmsnorm.py:188:9
	s_waitcnt vmcnt(1)
	v_and_b32_e32 v15, 0xffff0000, v2
	v_lshlrev_b32_e32 v14, 16, v2
	.loc	1 191 9                         ; rmsnorm.py:191:9
	s_waitcnt vmcnt(0)
	v_and_b32_e32 v17, 0xffff0000, v6
	v_lshlrev_b32_e32 v16, 16, v6
	.loc	1 188 9                         ; rmsnorm.py:188:9
	v_and_b32_e32 v19, 0xffff0000, v3
	v_lshlrev_b32_e32 v18, 16, v3
	.loc	1 191 9                         ; rmsnorm.py:191:9
	v_and_b32_e32 v21, 0xffff0000, v7
	v_lshlrev_b32_e32 v20, 16, v7
	.loc	1 188 9                         ; rmsnorm.py:188:9
	v_and_b32_e32 v7, 0xffff0000, v4
	v_lshlrev_b32_e32 v6, 16, v4
	.loc	1 191 9                         ; rmsnorm.py:191:9
	v_and_b32_e32 v23, 0xffff0000, v8
	v_lshlrev_b32_e32 v22, 16, v8
	.loc	1 188 9                         ; rmsnorm.py:188:9
	v_and_b32_e32 v25, 0xffff0000, v5
	v_lshlrev_b32_e32 v24, 16, v5
	.loc	1 191 9                         ; rmsnorm.py:191:9
	v_and_b32_e32 v27, 0xffff0000, v9
	v_lshlrev_b32_e32 v26, 16, v9
	.loc	1 192 12                        ; rmsnorm.py:192:12
	v_pk_add_f32 v[2:3], v[14:15], v[16:17]
	v_pk_add_f32 v[4:5], v[18:19], v[20:21]
	v_pk_add_f32 v[6:7], v[6:7], v[22:23]
	v_pk_add_f32 v[8:9], v[24:25], v[26:27]
	.loc	1 195 13                        ; rmsnorm.py:195:13
	v_cvt_pk_bf16_f32 v14, v2, v3
	v_cvt_pk_bf16_f32 v15, v4, v5
	v_cvt_pk_bf16_f32 v16, v6, v7
	v_cvt_pk_bf16_f32 v17, v8, v9
	.loc	1 198 21                        ; rmsnorm.py:198:21
	v_pk_mul_f32 v[18:19], v[2:3], v[2:3]
	v_pk_mul_f32 v[20:21], v[4:5], v[4:5]
	.loc	1 195 8                         ; rmsnorm.py:195:8
	buffer_store_dwordx4 v[14:17], v12, s[28:31], 0 offen
	.loc	1 198 21                        ; rmsnorm.py:198:21
	v_pk_mul_f32 v[22:23], v[6:7], v[6:7]
	v_pk_mul_f32 v[24:25], v[8:9], v[8:9]
.Ltmp4:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ rmsnorm.py:198:17 ] ]
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
	.loc	2 293 36                        ; standard.py:293:36 @[ rmsnorm.py:198:17 ]
	v_mov_b32_e32 v15, v14
	s_nop 1
	v_mov_b32_dpp v15, v15 row_bcast:15 row_mask:0xa bank_mask:0xf bound_ctrl:1
.Ltmp6:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ rmsnorm.py:198:17 ] ]
	v_add_f32_e32 v14, v15, v14
	s_nop 1
	v_add_f32_dpp v14, v14, v14 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
.Ltmp7:
	.loc	2 293 36                        ; standard.py:293:36 @[ rmsnorm.py:198:17 ]
	s_nop 0
	v_readlane_b32 s6, v14, 63
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_2
; %bb.1:
	.loc	2 0 36 is_stmt 0                ; standard.py:0:36
	s_lshr_b32 s7, s17, 4
	s_and_b32 s7, s7, 60
	s_add_i32 s7, s7, 0
	.loc	2 293 36                        ; standard.py:293:36 @[ rmsnorm.py:198:17 ]
	v_mov_b32_e32 v14, s7
	v_mov_b32_e32 v15, s6
	ds_write_b32 v14, v15
.LBB0_2:
	.loc	2 0 36                          ; standard.py:0:36
	s_or_b64 exec, exec, s[4:5]
	.loc	2 293 36                        ; standard.py:293:36 @[ rmsnorm.py:198:17 ]
	v_cmp_gt_u32_e32 vcc, 16, v0
	v_lshl_add_u32 v14, v0, 2, 0
.Ltmp8:
	.loc	1 198 17 is_stmt 1              ; rmsnorm.py:198:17
	v_mov_b32_e32 v15, 0
.Ltmp9:
	.loc	2 293 36                        ; standard.py:293:36 @[ rmsnorm.py:198:17 ]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[4:5], vcc
; %bb.3:
	ds_read_b32 v15, v14
; %bb.4:
	.loc	2 0 36 is_stmt 0                ; standard.py:0:36
	s_or_b64 exec, exec, s[4:5]
	.loc	2 293 36                        ; standard.py:293:36 @[ rmsnorm.py:198:17 ]
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v16, v15
	s_load_dword s6, s[0:1], 0x38
	s_load_dwordx2 s[4:5], s[0:1], 0x48
	v_mov_b32_dpp v16, v16 row_shr:8 row_mask:0xf bank_mask:0xc
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_nop 0
	v_mov_b32_dpp v16, v15 row_shl:8 row_mask:0xf bank_mask:0x3
.Ltmp10:
	.loc	2 263 15 is_stmt 1              ; standard.py:263:15 @[ standard.py:293:36 @[ rmsnorm.py:198:17 ] ]
	v_add_f32_e32 v15, v15, v16
.Ltmp11:
	.loc	2 293 36                        ; standard.py:293:36 @[ rmsnorm.py:198:17 ]
	v_mov_b32_e32 v16, v15
	s_nop 1
	v_mov_b32_dpp v16, v16 row_shr:4 row_mask:0xf bank_mask:0xa
	s_nop 1
	v_mov_b32_dpp v16, v15 row_shl:4 row_mask:0xf bank_mask:0x5
.Ltmp12:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ rmsnorm.py:198:17 ] ]
	v_add_f32_e32 v15, v15, v16
.Ltmp13:
	.loc	2 293 36                        ; standard.py:293:36 @[ rmsnorm.py:198:17 ]
	v_mov_b32_e32 v16, v15
	s_nop 1
	v_mov_b32_dpp v16, v16 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
.Ltmp14:
	.loc	2 263 15                        ; standard.py:263:15 @[ standard.py:293:36 @[ rmsnorm.py:198:17 ] ]
	v_add_f32_e32 v15, v15, v16
.Ltmp15:
	.loc	2 293 36                        ; standard.py:293:36 @[ rmsnorm.py:198:17 ]
	v_mov_b32_e32 v16, v15
	s_nop 1
	v_mov_b32_dpp v16, v16 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	s_and_saveexec_b64 s[0:1], vcc
; %bb.5:
	.loc	2 0 36 is_stmt 0                ; standard.py:0:36
	v_add_f32_e32 v0, v15, v16
	.loc	2 293 36                        ; standard.py:293:36 @[ rmsnorm.py:198:17 ]
	ds_write_b32 v14, v0
.Ltmp16:
; %bb.6:
	.loc	2 0 36                          ; standard.py:0:36
	s_or_b64 exec, exec, s[0:1]
	.loc	1 200 16 is_stmt 1              ; rmsnorm.py:200:16
	v_lshlrev_b32_e32 v0, 2, v13
	v_bfrev_b32_e32 v13, 1
	s_and_b32 s25, s25, 0xffff
	s_mov_b32 s27, 0x27000
	s_mov_b32 s26, 0x7ffffffe
	v_cndmask_b32_e64 v14, v13, v0, s[2:3]
	v_or_b32_e32 v0, 16, v0
.Ltmp17:
	.loc	2 293 36                        ; standard.py:293:36 @[ rmsnorm.py:198:17 ]
	s_waitcnt lgkmcnt(0)
	s_barrier
.Ltmp18:
	.loc	1 200 16                        ; rmsnorm.py:200:16
	buffer_load_dwordx4 v[14:17], v14, s[24:27], 0 offen
	v_cndmask_b32_e64 v0, v13, v0, s[2:3]
	buffer_load_dwordx4 v[18:21], v0, s[24:27], 0 offen
.Ltmp19:
	.loc	2 293 36                        ; standard.py:293:36 @[ rmsnorm.py:198:17 ]
	v_mov_b32_e32 v0, 0
	ds_read_b32 v0, v0
.Ltmp20:
	.loc	1 198 34                        ; rmsnorm.py:198:34
	v_cvt_f32_i32_e32 v22, s10
	.loc	1 203 44                        ; rmsnorm.py:203:44
	s_and_b32 s9, s9, 0xffff
	s_mov_b32 s10, s26
	s_mov_b32 s11, s27
	.loc	1 198 34                        ; rmsnorm.py:198:34
	s_waitcnt lgkmcnt(0)
	v_div_scale_f32 v23, s[0:1], v22, v22, v0
	v_rcp_f32_e32 v24, v23
	v_div_scale_f32 v25, vcc, v0, v22, v0
	.loc	1 215 44                        ; rmsnorm.py:215:44
	s_and_b32 s13, s13, 0xffff
	.loc	1 198 34                        ; rmsnorm.py:198:34
	v_fma_f32 v26, -v23, v24, 1.0
	v_fmac_f32_e32 v24, v26, v24
	v_mul_f32_e32 v26, v25, v24
	v_fma_f32 v27, -v23, v26, v25
	v_fmac_f32_e32 v26, v27, v24
	v_fma_f32 v23, -v23, v26, v25
	v_div_fmas_f32 v23, v23, v24, v26
	v_div_fixup_f32 v0, v23, v22, v0
	.loc	1 199 31                        ; rmsnorm.py:199:31
	v_add_f32_e32 v0, s4, v0
	.loc	1 199 25 is_stmt 0              ; rmsnorm.py:199:25
	v_sqrt_f32_e32 v0, v0
	s_mov_b32 s4, 0x2edbe6ff
	.loc	1 215 44 is_stmt 1              ; rmsnorm.py:215:44
	s_mov_b32 s14, s26
	s_mov_b32 s15, s27
	.loc	1 199 17                        ; rmsnorm.py:199:17
	v_div_scale_f32 v22, s[0:1], v0, v0, 1.0
	v_rcp_f32_e32 v23, v22
	v_div_scale_f32 v24, vcc, 1.0, v0, 1.0
	.loc	1 219 49                        ; rmsnorm.py:219:49
	s_and_b32 s21, s21, 0xffff
	.loc	1 199 17                        ; rmsnorm.py:199:17
	v_fma_f32 v25, -v22, v23, 1.0
	v_fmac_f32_e32 v23, v25, v23
	v_mul_f32_e32 v25, v24, v23
	v_fma_f32 v26, -v22, v25, v24
	v_fmac_f32_e32 v25, v26, v23
	v_fma_f32 v22, -v22, v25, v24
	v_div_fmas_f32 v22, v22, v23, v25
	v_div_fixup_f32 v0, v22, v0, 1.0
	.loc	1 201 14                        ; rmsnorm.py:201:14
	v_pk_mul_f32 v[2:3], v[2:3], v[0:1] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[4:5], v[0:1] op_sel_hi:[1,0]
	v_pk_mul_f32 v[6:7], v[6:7], v[0:1] op_sel_hi:[1,0]
	v_pk_mul_f32 v[8:9], v[8:9], v[0:1] op_sel_hi:[1,0]
	.loc	1 219 49                        ; rmsnorm.py:219:49
	v_lshrrev_b32_e32 v1, 2, v1
	v_and_b32_e32 v1, 0xfc, v1
	v_add_u32_e32 v1, 0, v1
	s_mov_b32 s22, s26
	s_mov_b32 s23, s27
	.loc	1 201 28                        ; rmsnorm.py:201:28
	s_waitcnt vmcnt(1)
	v_pk_add_f32 v[14:15], v[14:15], 1.0 op_sel_hi:[1,0]
	v_pk_add_f32 v[16:17], v[16:17], 1.0 op_sel_hi:[1,0]
	.loc	1 201 22 is_stmt 0              ; rmsnorm.py:201:22
	v_pk_mul_f32 v[2:3], v[14:15], v[2:3]
	.loc	1 201 28                        ; rmsnorm.py:201:28
	s_waitcnt vmcnt(0)
	v_pk_add_f32 v[14:15], v[18:19], 1.0 op_sel_hi:[1,0]
	.loc	1 201 22                        ; rmsnorm.py:201:22
	v_pk_mul_f32 v[4:5], v[16:17], v[4:5]
	v_pk_mul_f32 v[6:7], v[14:15], v[6:7]
	.loc	1 202 19 is_stmt 1              ; rmsnorm.py:202:19
	v_cvt_pk_bf16_f32 v2, v2, v3
	.loc	1 201 28                        ; rmsnorm.py:201:28
	v_pk_add_f32 v[16:17], v[20:21], 1.0 op_sel_hi:[1,0]
	.loc	1 202 19                        ; rmsnorm.py:202:19
	v_cvt_pk_bf16_f32 v3, v4, v5
	v_cvt_pk_bf16_f32 v4, v6, v7
	.loc	1 209 29                        ; rmsnorm.py:209:29
	v_lshlrev_b32_e32 v0, 16, v2
	v_and_b32_e32 v6, 0xffff0000, v2
	.loc	1 201 22                        ; rmsnorm.py:201:22
	v_pk_mul_f32 v[8:9], v[16:17], v[8:9]
.Ltmp21:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ rmsnorm.py:210:31 ] ]
	v_max_f32_e64 v17, |v6|, |v6|
	v_max_f32_e64 v18, |v0|, |v0|
.Ltmp22:
	.loc	1 202 19                        ; rmsnorm.py:202:19
	v_cvt_pk_bf16_f32 v5, v8, v9
	.loc	1 209 29                        ; rmsnorm.py:209:29
	v_lshlrev_b32_e32 v7, 16, v3
	v_and_b32_e32 v8, 0xffff0000, v3
.Ltmp23:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ rmsnorm.py:210:31 ] ]
	v_max_f32_e32 v17, v18, v17
.Ltmp24:
	.loc	1 209 29                        ; rmsnorm.py:209:29
	v_lshlrev_b32_e32 v9, 16, v4
	v_and_b32_e32 v14, 0xffff0000, v4
.Ltmp25:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ rmsnorm.py:210:31 ] ]
	v_max3_f32 v17, v17, |v7|, |v8|
.Ltmp26:
	.loc	1 209 29                        ; rmsnorm.py:209:29
	v_lshlrev_b32_e32 v15, 16, v5
	v_and_b32_e32 v16, 0xffff0000, v5
.Ltmp27:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ rmsnorm.py:210:31 ] ]
	v_max3_f32 v17, v17, |v9|, |v14|
	v_max3_f32 v17, v17, |v15|, |v16|
.Ltmp28:
	.loc	2 191 40                        ; standard.py:191:40 @[ rmsnorm.py:210:31 ]
	v_mov_b32_e32 v18, v17
.Ltmp29:
	.loc	1 203 44                        ; rmsnorm.py:203:44
	buffer_store_dwordx4 v[2:5], v12, s[8:11], 0 offen
.Ltmp30:
	.loc	2 191 40                        ; standard.py:191:40 @[ rmsnorm.py:210:31 ]
	s_nop 0
	v_mov_b32_dpp v18, v18 row_shr:8 row_mask:0xf bank_mask:0xc
	s_nop 1
	v_mov_b32_dpp v18, v17 row_shl:8 row_mask:0xf bank_mask:0x3
.Ltmp31:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ rmsnorm.py:210:31 ] ]
	v_max_f32_e32 v18, v18, v18
	v_max_f32_e32 v17, v17, v18
.Ltmp32:
	.loc	2 191 40                        ; standard.py:191:40 @[ rmsnorm.py:210:31 ]
	v_mov_b32_e32 v18, v17
	s_nop 1
	v_mov_b32_dpp v18, v18 row_shr:4 row_mask:0xf bank_mask:0xa
	s_nop 1
	v_mov_b32_dpp v18, v17 row_shl:4 row_mask:0xf bank_mask:0x5
.Ltmp33:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ rmsnorm.py:210:31 ] ]
	v_max_f32_e32 v18, v18, v18
	v_max_f32_e32 v17, v17, v18
.Ltmp34:
	.loc	2 191 40                        ; standard.py:191:40 @[ rmsnorm.py:210:31 ]
	v_mov_b32_e32 v18, v17
	s_nop 1
	v_mov_b32_dpp v18, v18 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
.Ltmp35:
	.loc	2 170 27                        ; standard.py:170:27 @[ standard.py:191:40 @[ rmsnorm.py:210:31 ] ]
	v_max_f32_e32 v18, v18, v18
	v_max_f32_e32 v17, v17, v18
.Ltmp36:
	.loc	2 191 40                        ; standard.py:191:40 @[ rmsnorm.py:210:31 ]
	v_mov_b32_e32 v18, v17
	s_nop 1
	v_mov_b32_dpp v18, v18 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
.Ltmp37:
	.loc	1 210 52                        ; rmsnorm.py:210:52
	v_max3_f32 v17, v17, v18, s4
	.loc	1 211 21                        ; rmsnorm.py:211:21
	v_mul_f32_e32 v17, s5, v17
	.loc	1 212 16                        ; rmsnorm.py:212:16
	v_div_scale_f32 v18, s[0:1], v17, v17, 1.0
	v_rcp_f32_e32 v19, v18
	v_div_scale_f32 v2, vcc, 1.0, v17, 1.0
	.loc	1 219 49                        ; rmsnorm.py:219:49
	s_and_b32 s0, s17, 0x3c0
	.loc	1 212 16                        ; rmsnorm.py:212:16
	v_fma_f32 v3, -v18, v19, 1.0
	v_fmac_f32_e32 v19, v3, v19
	v_mul_f32_e32 v3, v2, v19
	v_fma_f32 v4, -v18, v3, v2
	v_fmac_f32_e32 v3, v4, v19
	v_fma_f32 v2, -v18, v3, v2
	v_div_fmas_f32 v2, v2, v19, v3
	v_div_fixup_f32 v2, v2, v17, 1.0
	.loc	1 213 14                        ; rmsnorm.py:213:14
	v_mul_f32_e32 v0, v2, v0
	v_mul_f32_e32 v3, v2, v6
	v_mul_f32_e32 v4, v2, v7
	v_mul_f32_e32 v6, v2, v9
	v_mul_f32_e32 v7, v2, v14
	v_mul_f32_e32 v5, v2, v8
	v_mul_f32_e32 v8, v2, v15
	v_mul_f32_e32 v9, v2, v16
	.loc	1 213 31 is_stmt 0              ; rmsnorm.py:213:31
	v_cvt_scalef32_pk_fp8_f32 v2, v0, v3, 1.0
	v_cvt_scalef32_pk_fp8_f32 v3, v6, v7, 1.0
	v_cvt_scalef32_pk_fp8_f32 v2, v4, v5, 1.0 op_sel:[0,0,0,1]
	v_cvt_scalef32_pk_fp8_f32 v3, v8, v9, 1.0 op_sel:[0,0,0,1]
	.loc	1 215 44 is_stmt 1              ; rmsnorm.py:215:44
	v_cndmask_b32_e64 v0, v13, v11, s[2:3]
	buffer_store_dwordx2 v[2:3], v0, s[12:15], 0 offen
	.loc	1 219 49                        ; rmsnorm.py:219:49
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b32 v1, v17
	v_lshl_add_u32 v1, v10, 2, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b32 v1, v1
	s_cmp_eq_u32 s0, 0
	.loc	1 217 21                        ; rmsnorm.py:217:21
	v_cmp_gt_u32_e32 vcc, 40, v10
	.loc	1 219 44                        ; rmsnorm.py:219:44
	v_mul_lo_u32 v0, s6, v10
	.loc	1 219 49 is_stmt 0              ; rmsnorm.py:219:49
	s_cselect_b64 s[0:1], -1, 0
	v_add_lshl_u32 v0, v0, s16, 2
	s_and_b64 vcc, vcc, s[0:1]
	v_cndmask_b32_e32 v0, v13, v0, vcc
	s_waitcnt lgkmcnt(0)
	buffer_store_dword v1, v0, s[20:23], 0 offen
	.loc	1 218 4 is_stmt 1               ; rmsnorm.py:218:4
	s_endpgm
.Ltmp38:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _gemma_fused_add_rmsnorm_group_quant_kernel
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
	.size	_gemma_fused_add_rmsnorm_group_quant_kernel, .Lfunc_end0-_gemma_fused_add_rmsnorm_group_quant_kernel
	.cfi_endproc
                                        ; -- End function
	.set _gemma_fused_add_rmsnorm_group_quant_kernel.num_vgpr, 28
	.set _gemma_fused_add_rmsnorm_group_quant_kernel.num_agpr, 0
	.set _gemma_fused_add_rmsnorm_group_quant_kernel.numbered_sgpr, 40
	.set _gemma_fused_add_rmsnorm_group_quant_kernel.num_named_barrier, 0
	.set _gemma_fused_add_rmsnorm_group_quant_kernel.private_seg_size, 0
	.set _gemma_fused_add_rmsnorm_group_quant_kernel.uses_vcc, 1
	.set _gemma_fused_add_rmsnorm_group_quant_kernel.uses_flat_scratch, 0
	.set _gemma_fused_add_rmsnorm_group_quant_kernel.has_dyn_sized_stack, 0
	.set _gemma_fused_add_rmsnorm_group_quant_kernel.has_recursion, 0
	.set _gemma_fused_add_rmsnorm_group_quant_kernel.has_indirect_call, 0
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
	.section	.debug_abbrev,"",@progbits
	.byte	1                               ; Abbreviation Code
	.byte	17                              ; DW_TAG_compile_unit
	.byte	1                               ; DW_CHILDREN_yes
	.byte	37                              ; DW_AT_producer
	.byte	14                              ; DW_FORM_strp
	.byte	19                              ; DW_AT_language
	.byte	5                               ; DW_FORM_data2
	.byte	3                               ; DW_AT_name
	.byte	14                              ; DW_FORM_strp
	.byte	16                              ; DW_AT_stmt_list
	.byte	23                              ; DW_FORM_sec_offset
	.byte	27                              ; DW_AT_comp_dir
	.byte	14                              ; DW_FORM_strp
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	2                               ; Abbreviation Code
	.byte	46                              ; DW_TAG_subprogram
	.byte	0                               ; DW_CHILDREN_no
	.byte	3                               ; DW_AT_name
	.byte	14                              ; DW_FORM_strp
	.byte	32                              ; DW_AT_inline
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	3                               ; Abbreviation Code
	.byte	46                              ; DW_TAG_subprogram
	.byte	1                               ; DW_CHILDREN_yes
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	4                               ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	1                               ; DW_CHILDREN_yes
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	85                              ; DW_AT_ranges
	.byte	23                              ; DW_FORM_sec_offset
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	11                              ; DW_FORM_data1
	.byte	87                              ; DW_AT_call_column
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	5                               ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	0                               ; DW_CHILDREN_no
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	85                              ; DW_AT_ranges
	.byte	23                              ; DW_FORM_sec_offset
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	5                               ; DW_FORM_data2
	.byte	87                              ; DW_AT_call_column
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	6                               ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	0                               ; DW_CHILDREN_no
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	85                              ; DW_AT_ranges
	.byte	23                              ; DW_FORM_sec_offset
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	11                              ; DW_FORM_data1
	.byte	87                              ; DW_AT_call_column
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	0                               ; EOM(3)
	.section	.debug_info,"",@progbits
.Lcu_begin0:
	.long	.Ldebug_info_end0-.Ldebug_info_start0 ; Length of Unit
.Ldebug_info_start0:
	.short	4                               ; DWARF version number
	.long	.debug_abbrev                   ; Offset Into Abbrev. Section
	.byte	8                               ; Address Size (in bytes)
	.byte	1                               ; Abbrev [1] 0xb:0x6b DW_TAG_compile_unit
	.long	.Linfo_string0                  ; DW_AT_producer
	.short	2                               ; DW_AT_language
	.long	.Linfo_string1                  ; DW_AT_name
	.long	.Lline_table_start0             ; DW_AT_stmt_list
	.long	.Linfo_string2                  ; DW_AT_comp_dir
	.quad	.Lfunc_begin0                   ; DW_AT_low_pc
	.long	.Lfunc_end0-.Lfunc_begin0       ; DW_AT_high_pc
	.byte	2                               ; Abbrev [2] 0x2a:0x6 DW_TAG_subprogram
	.long	.Linfo_string3                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x30:0x45 DW_TAG_subprogram
	.quad	.Lfunc_begin0                   ; DW_AT_low_pc
	.long	.Lfunc_end0-.Lfunc_begin0       ; DW_AT_high_pc
	.long	42                              ; DW_AT_abstract_origin
	.byte	4                               ; Abbrev [4] 0x41:0x1a DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges0                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	198                             ; DW_AT_call_line
	.byte	17                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x4d:0xd DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges1                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.short	293                             ; DW_AT_call_line
	.byte	36                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0x5b:0x19 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges2                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	210                             ; DW_AT_call_line
	.byte	31                              ; DW_AT_call_column
	.byte	6                               ; Abbrev [6] 0x67:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges3                 ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	191                             ; DW_AT_call_line
	.byte	40                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
.Ldebug_info_end0:
	.section	.debug_ranges,"",@progbits
.Ldebug_ranges0:
	.quad	.Ltmp2-.Lfunc_begin0
	.quad	.Ltmp3-.Lfunc_begin0
	.quad	.Ltmp4-.Lfunc_begin0
	.quad	.Ltmp8-.Lfunc_begin0
	.quad	.Ltmp9-.Lfunc_begin0
	.quad	.Ltmp16-.Lfunc_begin0
	.quad	.Ltmp17-.Lfunc_begin0
	.quad	.Ltmp18-.Lfunc_begin0
	.quad	.Ltmp19-.Lfunc_begin0
	.quad	.Ltmp20-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges1:
	.quad	.Ltmp4-.Lfunc_begin0
	.quad	.Ltmp5-.Lfunc_begin0
	.quad	.Ltmp6-.Lfunc_begin0
	.quad	.Ltmp7-.Lfunc_begin0
	.quad	.Ltmp10-.Lfunc_begin0
	.quad	.Ltmp11-.Lfunc_begin0
	.quad	.Ltmp12-.Lfunc_begin0
	.quad	.Ltmp13-.Lfunc_begin0
	.quad	.Ltmp14-.Lfunc_begin0
	.quad	.Ltmp15-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges2:
	.quad	.Ltmp21-.Lfunc_begin0
	.quad	.Ltmp22-.Lfunc_begin0
	.quad	.Ltmp23-.Lfunc_begin0
	.quad	.Ltmp24-.Lfunc_begin0
	.quad	.Ltmp25-.Lfunc_begin0
	.quad	.Ltmp26-.Lfunc_begin0
	.quad	.Ltmp27-.Lfunc_begin0
	.quad	.Ltmp29-.Lfunc_begin0
	.quad	.Ltmp30-.Lfunc_begin0
	.quad	.Ltmp37-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges3:
	.quad	.Ltmp21-.Lfunc_begin0
	.quad	.Ltmp22-.Lfunc_begin0
	.quad	.Ltmp23-.Lfunc_begin0
	.quad	.Ltmp24-.Lfunc_begin0
	.quad	.Ltmp25-.Lfunc_begin0
	.quad	.Ltmp26-.Lfunc_begin0
	.quad	.Ltmp27-.Lfunc_begin0
	.quad	.Ltmp28-.Lfunc_begin0
	.quad	.Ltmp31-.Lfunc_begin0
	.quad	.Ltmp32-.Lfunc_begin0
	.quad	.Ltmp33-.Lfunc_begin0
	.quad	.Ltmp34-.Lfunc_begin0
	.quad	.Ltmp35-.Lfunc_begin0
	.quad	.Ltmp36-.Lfunc_begin0
	.quad	0
	.quad	0
	.section	.debug_str,"MS",@progbits,1
.Linfo_string0:
	.asciz	"triton"                        ; string offset=0
.Linfo_string1:
	.asciz	"rmsnorm.py"                    ; string offset=7
.Linfo_string2:
	.asciz	"/netra-server/python/sglang/jit_kernel/minimax_m3" ; string offset=18
.Linfo_string3:
	.asciz	"_gemma_fused_add_rmsnorm_group_quant_kernel" ; string offset=68
	.section	".note.GNU-stack","",@progbits
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
    .name:           _gemma_fused_add_rmsnorm_group_quant_kernel
    .private_segment_fixed_size: 0
    .sgpr_count:     46
    .sgpr_spill_count: 0
    .symbol:         _gemma_fused_add_rmsnorm_group_quant_kernel.kd
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
	.section	.debug_line,"",@progbits
.Lline_table_start0:
