// SPDX-License-Identifier: MIT
// Raw gfx1151 Qwen3.6 extend attention: M64 x N32, persistent Q, separate Q/P, 52 KiB LDS.
// B=1, Hq=16, Hkv=2, Dq=Dv=256, BF16, causal, page size 1.
// Grid=(tokens/64,16,1), block=(128,1,1); token/prefix counts are multiples 64.

.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
.amdhsa_code_object_version 6
.text

.macro ALLREDUCE_MAX REG TMP
  v_mov_b32_e32 v[\TMP], v[\REG]
  v_mov_b32_dpp v[\TMP], v[\TMP] row_shr:8 row_mask:0xf bank_mask:0xc
  v_mov_b32_dpp v[\TMP], v[\REG] row_shl:8 row_mask:0xf bank_mask:0x3
  v_max_f32_e32 v[\REG], v[\REG], v[\TMP]
  v_mov_b32_e32 v[\TMP], v[\REG]
  v_mov_b32_dpp v[\TMP], v[\TMP] row_shr:4 row_mask:0xf bank_mask:0xa
  v_mov_b32_dpp v[\TMP], v[\REG] row_shl:4 row_mask:0xf bank_mask:0x5
  v_max_f32_e32 v[\REG], v[\REG], v[\TMP]
  v_mov_b32_dpp v[\TMP], v[\REG] quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
  v_max_f32_e32 v[\REG], v[\REG], v[\TMP]
  v_mov_b32_dpp v[\TMP], v[\REG] quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
  v_max_f32_e32 v[\REG], v[\REG], v[\TMP]
.endm

.macro ALLREDUCE_SUM REG TMP
  v_mov_b32_e32 v[\TMP], v[\REG]
  v_mov_b32_dpp v[\TMP], v[\TMP] row_shr:8 row_mask:0xf bank_mask:0xc
  v_mov_b32_dpp v[\TMP], v[\REG] row_shl:8 row_mask:0xf bank_mask:0x3
  v_add_f32_e32 v[\REG], v[\REG], v[\TMP]
  v_mov_b32_e32 v[\TMP], v[\REG]
  v_mov_b32_dpp v[\TMP], v[\TMP] row_shr:4 row_mask:0xf bank_mask:0xa
  v_mov_b32_dpp v[\TMP], v[\REG] row_shl:4 row_mask:0xf bank_mask:0x5
  v_add_f32_e32 v[\REG], v[\REG], v[\TMP]
  v_mov_b32_dpp v[\TMP], v[\REG] quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
  v_add_f32_e32 v[\REG], v[\REG], v[\TMP]
  v_mov_b32_dpp v[\TMP], v[\REG] quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
  v_add_f32_e32 v[\REG], v[\REG], v[\TMP]
.endm

.macro RESCALE_TILE BASE
  v_mul_f32_e32 v[\BASE+0], v[\BASE+0], v48
  v_mul_f32_e32 v[\BASE+1], v[\BASE+1], v49
  v_mul_f32_e32 v[\BASE+2], v[\BASE+2], v50
  v_mul_f32_e32 v[\BASE+3], v[\BASE+3], v51
  v_mul_f32_e32 v[\BASE+4], v[\BASE+4], v52
  v_mul_f32_e32 v[\BASE+5], v[\BASE+5], v53
  v_mul_f32_e32 v[\BASE+6], v[\BASE+6], v54
  v_mul_f32_e32 v[\BASE+7], v[\BASE+7], v55
.endm

.macro LOAD_PREFIX_ONE KOFF PTR
  s_add_u32 s30, s28, s29
  s_add_u32 s30, s30, \KOFF
  s_lshl_b32 s30, s30, 3
  s_load_b64 s[36:37], s[16:17], s30
  s_waitcnt lgkmcnt(0)
  s_lshl_b32 s38, s36, 10
  s_add_u32 s38, s38, s25
  s_add_u32 s32, s[\PTR], s38
  s_addc_u32 s33, s[\PTR+1], 0
  global_load_b128 v[209:212], v213, s[32:33]
  s_waitcnt vmcnt(0)
  s_add_u32 s39, s29, \KOFF
  s_lshl_b32 s39, s39, 9
  v_add_nc_u32_e32 v222, s39, v213
  v_add_nc_u32_e32 v222, 32768, v222
  ds_write_b128 v222, v[209:212]
.endm

.macro LOAD_CURRENT_ONE KOFF PTR
  s_add_u32 s38, s28, s29
  s_add_u32 s38, s38, \KOFF
  s_sub_u32 s38, s38, s19
  s_lshl_b32 s38, s38, 10
  s_add_u32 s38, s38, s25
  s_add_u32 s32, s[\PTR], s38
  s_addc_u32 s33, s[\PTR+1], 0
  global_load_b128 v[209:212], v213, s[32:33]
  s_waitcnt vmcnt(0)
  s_add_u32 s39, s29, \KOFF
  s_lshl_b32 s39, s39, 9
  v_add_nc_u32_e32 v222, s39, v213
  v_add_nc_u32_e32 v222, 32768, v222
  ds_write_b128 v222, v[209:212]
.endm

.macro LOAD_PREFIX_32 PTR
  LOAD_PREFIX_ONE 0,  \PTR
  LOAD_PREFIX_ONE 4,  \PTR
  LOAD_PREFIX_ONE 8,  \PTR
  LOAD_PREFIX_ONE 12, \PTR
  LOAD_PREFIX_ONE 16, \PTR
  LOAD_PREFIX_ONE 20, \PTR
  LOAD_PREFIX_ONE 24, \PTR
  LOAD_PREFIX_ONE 28, \PTR
.endm

.macro LOAD_CURRENT_32 PTR
  LOAD_CURRENT_ONE 0,  \PTR
  LOAD_CURRENT_ONE 4,  \PTR
  LOAD_CURRENT_ONE 8,  \PTR
  LOAD_CURRENT_ONE 12, \PTR
  LOAD_CURRENT_ONE 16, \PTR
  LOAD_CURRENT_ONE 20, \PTR
  LOAD_CURRENT_ONE 24, \PTR
  LOAD_CURRENT_ONE 28, \PTR
.endm

.protected extend_attention_wmma_n32_persistent_q_gfx1151
.globl extend_attention_wmma_n32_persistent_q_gfx1151
.p2align 8
.type extend_attention_wmma_n32_persistent_q_gfx1151,@function
extend_attention_wmma_n32_persistent_q_gfx1151:
  s_clause 0x3
  s_load_b128 s[4:7], s[0:1], 0
  s_load_b128 s[8:11], s[0:1], 16
  s_load_b128 s[12:15], s[0:1], 32
  s_load_b128 s[16:19], s[0:1], 48
  s_load_b64 s[20:21], s[0:1], 64
  s_waitcnt lgkmcnt(0)
  s_load_b32 s22, s[18:19], 4
  s_waitcnt lgkmcnt(0)
  s_mov_b32 s18, s20
  s_mov_b32 s19, s22
  s_mov_b32 s20, s21

  s_lshl_b32 s21, s2, 6
  s_cmp_ge_u32 s21, s18
  s_cbranch_scc1 .Lend
  s_lshr_b32 s23, s3, 3
  s_lshl_b32 s24, s3, 9
  s_lshl_b32 s25, s23, 9
  s_add_u32 s26, s21, 64
  s_min_u32 s26, s26, s18
  s_add_u32 s27, s19, s26
  s_mov_b32 s28, 0

  v_and_b32_e32 v1, 31, v0
  v_lshrrev_b32_e32 v2, 5, v0
  v_and_b32_e32 v3, 15, v0
  v_lshrrev_b32_e32 v4, 4, v0
  v_and_b32_e32 v4, 1, v4
  v_readfirstlane_b32 s29, v2
  v_lshlrev_b32_e32 v213, 4, v1

  // Load Q once into its own 32 KiB LDS region. Q remains persistent while
  // the 16 KiB K/V region is reused and P occupies a separate 4 KiB region.
  v_lshlrev_b32_e32 v215, 4, v2
  v_add_nc_u32_e32 v215, s21, v215
  v_add_nc_u32_e32 v215, v215, v3
  v_lshlrev_b32_e32 v221, 13, v215
  v_add_nc_u32_e32 v221, s24, v221
  v_lshl_add_u32 v221, v4, 4, v221
  v_lshlrev_b32_e32 v223, 13, v2
  v_lshl_add_u32 v223, v3, 9, v223
  v_lshl_add_u32 v223, v4, 4, v223
  .set QD, 0
  .rept 16
    global_load_b128 v[209:212], v221, s[4:5] offset:(QD*32)
    s_waitcnt vmcnt(0)
    ds_write_b128 v223, v[209:212] offset:(QD*32)
    .set QD, QD+1
  .endr
  s_waitcnt lgkmcnt(0)
  s_barrier

  // C-layout row base and 4 KiB P workspace after 32 KiB Q + 16 KiB reusable data LDS.
  v_lshlrev_b32_e32 v6, 4, v2
  v_add_nc_u32_e32 v6, s21, v6
  v_add_nc_u32_e32 v6, v6, v4
  v_lshlrev_b32_e32 v214, 10, v2
  v_lshl_add_u32 v214, v4, 6, v214
  v_lshl_add_u32 v214, v3, 1, v214
  v_add_nc_u32_e32 v214, 49152, v214
  v_lshlrev_b32_e32 v215, 10, v2
  v_lshl_add_u32 v215, v3, 6, v215
  v_lshl_add_u32 v215, v4, 4, v215
  v_add_nc_u32_e32 v215, 49152, v215

  v_mov_b32_e32 v32, 0xff800000
  v_mov_b32_e32 v33, v32
  v_mov_b32_e32 v34, v32
  v_mov_b32_e32 v35, v32
  v_mov_b32_e32 v36, v32
  v_mov_b32_e32 v37, v32
  v_mov_b32_e32 v38, v32
  v_mov_b32_e32 v39, v32
  v_dual_mov_b32 v40, 0 :: v_dual_mov_b32 v41, 0
  v_dual_mov_b32 v42, 0 :: v_dual_mov_b32 v43, 0
  v_dual_mov_b32 v44, 0 :: v_dual_mov_b32 v45, 0
  v_dual_mov_b32 v46, 0 :: v_dual_mov_b32 v47, 0
  .set ZR, 64
  .rept 64
    v_dual_mov_b32 v[ZR], 0 :: v_dual_mov_b32 v[ZR+1], 0
    .set ZR, ZR+2
  .endr

.Ltile_loop:
  s_barrier
  s_cmp_lt_u32 s28, s19
  s_cbranch_scc0 .Lload_k_current
  LOAD_PREFIX_32 12
  s_branch .Lk_loaded
.Lload_k_current:
  LOAD_CURRENT_32 6
.Lk_loaded:
  s_waitcnt lgkmcnt(0)
  s_barrier

  v_dual_mov_b32 v24, 0 :: v_dual_mov_b32 v25, 0
  v_dual_mov_b32 v26, 0 :: v_dual_mov_b32 v27, 0
  v_dual_mov_b32 v28, 0 :: v_dual_mov_b32 v29, 0
  v_dual_mov_b32 v30, 0 :: v_dual_mov_b32 v31, 0
  v_dual_mov_b32 v192, 0 :: v_dual_mov_b32 v193, 0
  v_dual_mov_b32 v194, 0 :: v_dual_mov_b32 v195, 0
  v_dual_mov_b32 v196, 0 :: v_dual_mov_b32 v197, 0
  v_dual_mov_b32 v198, 0 :: v_dual_mov_b32 v199, 0
  .set DK, 0
  .rept 16
    ds_load_b128 v[8:11], v223 offset:(DK*32)
    s_waitcnt lgkmcnt(0)
    ds_swizzle_b32 v12, v8 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v13, v9 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v14, v10 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v15, v11 offset:swizzle(SWAP,16)
    s_waitcnt lgkmcnt(0)
    .set KT, 0
    .rept 2
      v_lshlrev_b32_e32 v209, 9, v3
      v_lshl_add_u32 v209, v4, 4, v209
      v_add_nc_u32_e32 v209, (KT*8192+DK*32), v209
      v_add_nc_u32_e32 v209, 32768, v209
      ds_load_b128 v[16:19], v209
      s_waitcnt lgkmcnt(0)
      ds_swizzle_b32 v20, v16 offset:swizzle(SWAP,16)
      ds_swizzle_b32 v21, v17 offset:swizzle(SWAP,16)
      ds_swizzle_b32 v22, v18 offset:swizzle(SWAP,16)
      ds_swizzle_b32 v23, v19 offset:swizzle(SWAP,16)
      s_waitcnt lgkmcnt(0)
      .if KT == 0
        v_wmma_f32_16x16x16_bf16 v[24:31], v[8:15], v[16:23], v[24:31]
      .else
        v_wmma_f32_16x16x16_bf16 v[192:199], v[8:15], v[16:23], v[192:199]
      .endif
      .set KT, KT+1
    .endr
    .set DK, DK+1
  .endr

  .set MT, 0
  .rept 2
    .set MR, 0
    .rept 8
      .if MT == 0
        .set SREG, 24+MR
      .else
        .set SREG, 192+MR
      .endif
      v_mul_f32_e32 v[SREG], s20, v[SREG]
      v_add_nc_u32_e32 v216, (MT*16), v3
      v_add_nc_u32_e32 v216, s28, v216
      v_add_nc_u32_e32 v217, (MR*2), v6
      v_add_nc_u32_e32 v218, s19, v217
      v_add_nc_u32_e32 v218, 1, v218
      v_cmp_lt_u32_e32 vcc_lo, v216, v218
      v_cndmask_b32_e32 v[SREG], 0xff800000, v[SREG], vcc_lo
      .set MR, MR+1
    .endr
    .set MT, MT+1
  .endr

  .set SR, 0
  .rept 8
    v_mov_b32_e32 v[200+SR], v[24+SR]
    ALLREDUCE_MAX (200+SR), 208
    v_mov_b32_e32 v209, v[192+SR]
    ALLREDUCE_MAX 209, 208
    v_max_f32_e32 v[200+SR], v[200+SR], v209
    v_max_f32_e32 v[200+SR], v[32+SR], v[200+SR]
    v_sub_f32_e32 v[48+SR], v[32+SR], v[200+SR]
    v_mul_f32_e32 v[48+SR], 0x3fb8aa3b, v[48+SR]
    v_exp_f32_e32 v[48+SR], v[48+SR]
    v_sub_f32_e32 v[24+SR], v[24+SR], v[200+SR]
    v_mul_f32_e32 v[24+SR], 0x3fb8aa3b, v[24+SR]
    v_exp_f32_e32 v[24+SR], v[24+SR]
    v_sub_f32_e32 v[192+SR], v[192+SR], v[200+SR]
    v_mul_f32_e32 v[192+SR], 0x3fb8aa3b, v[192+SR]
    v_exp_f32_e32 v[192+SR], v[192+SR]
    v_mov_b32_e32 v[32+SR], v[200+SR]
    v_mov_b32_e32 v[200+SR], v[24+SR]
    ALLREDUCE_SUM (200+SR), 208
    v_mov_b32_e32 v209, v[192+SR]
    ALLREDUCE_SUM 209, 208
    v_add_f32_e32 v[200+SR], v[200+SR], v209
    v_mul_f32_e32 v[40+SR], v[40+SR], v[48+SR]
    v_add_f32_e32 v[40+SR], v[40+SR], v[200+SR]
    .set SR, SR+1
  .endr

  .set OT, 64
  .rept 16
    RESCALE_TILE OT
    .set OT, OT+8
  .endr

  .set PT, 0
  .rept 2
    .set PR, 0
    .rept 8
      .if PT == 0
        .set PREG, 24+PR
      .else
        .set PREG, 192+PR
      .endif
      v_lshrrev_b32_e32 v219, 16, v[PREG]
      v_and_b32_e32 v219, 1, v219
      v_add_nc_u32_e32 v220, 0x7fff, v[PREG]
      v_add_nc_u32_e32 v220, v219, v220
      v_lshrrev_b32_e32 v220, 16, v220
      ds_write_b16 v214, v220 offset:(PT*32+PR*128)
      .set PR, PR+1
    .endr
    .set PT, PT+1
  .endr
  s_waitcnt lgkmcnt(0)
  s_barrier

  s_cmp_lt_u32 s28, s19
  s_cbranch_scc0 .Lload_v_current
  LOAD_PREFIX_32 14
  s_branch .Lv_loaded
.Lload_v_current:
  LOAD_CURRENT_32 8
.Lv_loaded:
  s_waitcnt lgkmcnt(0)
  s_barrier

  .set VT, 0
  .rept 2
    ds_load_b128 v[8:11], v215 offset:(VT*32)
    s_waitcnt lgkmcnt(0)
    ds_swizzle_b32 v12, v8 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v13, v9 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v14, v10 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v15, v11 offset:swizzle(SWAP,16)
    s_waitcnt lgkmcnt(0)
    v_lshlrev_b32_e32 v209, 12, v4
    v_lshl_add_u32 v209, v3, 1, v209
    v_add_nc_u32_e32 v209, (VT*8192), v209
    v_add_nc_u32_e32 v209, 32768, v209
    .set OB, 0
    .rept 16
      ds_load_u16 v16, v209 offset:(OB*32+0)
      ds_load_u16_d16_hi v16, v209 offset:(OB*32+512)
      ds_load_u16 v17, v209 offset:(OB*32+1024)
      ds_load_u16_d16_hi v17, v209 offset:(OB*32+1536)
      ds_load_u16 v18, v209 offset:(OB*32+2048)
      ds_load_u16_d16_hi v18, v209 offset:(OB*32+2560)
      ds_load_u16 v19, v209 offset:(OB*32+3072)
      ds_load_u16_d16_hi v19, v209 offset:(OB*32+3584)
      s_waitcnt lgkmcnt(0)
      ds_swizzle_b32 v20, v16 offset:swizzle(SWAP,16)
      ds_swizzle_b32 v21, v17 offset:swizzle(SWAP,16)
      ds_swizzle_b32 v22, v18 offset:swizzle(SWAP,16)
      ds_swizzle_b32 v23, v19 offset:swizzle(SWAP,16)
      s_waitcnt lgkmcnt(0)
      v_wmma_f32_16x16x16_bf16 v[64+OB*8:71+OB*8], v[8:15], v[16:23], v[64+OB*8:71+OB*8]
      .set OB, OB+1
    .endr
    .set VT, VT+1
  .endr

  s_add_u32 s28, s28, 32
  s_cmp_lt_u32 s28, s27
  s_cbranch_scc1 .Ltile_loop

  .set IR, 0
  .rept 8
    v_rcp_f32_e32 v[56+IR], v[40+IR]
    .set IR, IR+1
  .endr
  .set WB, 0
  .rept 16
    .set WR, 0
    .rept 8
      v_mul_f32_e32 v219, v[64+WB*8+WR], v[56+WR]
      v_lshrrev_b32_e32 v220, 16, v219
      v_and_b32_e32 v220, 1, v220
      v_add_nc_u32_e32 v223, 0x7fff, v219
      v_add_nc_u32_e32 v223, v220, v223
      v_lshrrev_b32_e32 v223, 16, v223
      v_add_nc_u32_e32 v222, (WR*2), v6
      v_lshlrev_b32_e32 v220, 13, v222
      v_add_nc_u32_e32 v220, s24, v220
      v_lshl_add_u32 v220, v3, 1, v220
      v_add_nc_u32_e32 v220, (WB*32), v220
      v_cmp_gt_u32_e32 vcc_lo, s18, v222
      s_and_saveexec_b32 s42, vcc_lo
      global_store_short v220, v223, s[10:11]
      s_mov_b32 exec_lo, s42
      .set WR, WR+1
    .endr
    .set WB, WB+1
  .endr
.Lend:
  s_endpgm

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel extend_attention_wmma_n32_persistent_q_gfx1151
.amdhsa_group_segment_fixed_size 53248
.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size 72
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_wavefront_size32 1
.amdhsa_enable_private_segment 0
.amdhsa_system_sgpr_workgroup_id_x 1
.amdhsa_system_sgpr_workgroup_id_y 1
.amdhsa_system_sgpr_workgroup_id_z 0
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_vgpr 224
.amdhsa_next_free_sgpr 43
.amdhsa_reserve_vcc 1
.amdhsa_float_denorm_mode_32 3
.amdhsa_float_denorm_mode_16_64 3
.amdhsa_dx10_clamp 1
.amdhsa_ieee_mode 1
.amdhsa_workgroup_processor_mode 1
.amdhsa_memory_ordered 1
.amdhsa_forward_progress 1
.end_amdhsa_kernel
.text
.Lfunc_end0:
.size extend_attention_wmma_n32_persistent_q_gfx1151, .Lfunc_end0-extend_attention_wmma_n32_persistent_q_gfx1151

.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: q, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: k_extend, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: v_extend, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: o, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: k_buffer, .offset: 32, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: v_buffer, .offset: 40, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: kv_indices, .offset: 48, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: kv_indptr, .offset: 56, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: tokens, .offset: 64, .size: 4, .value_kind: by_value }
      - { .name: sm_scale, .offset: 68, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 53248
    .kernarg_segment_align: 8
    .kernarg_segment_size: 72
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 128
    .name: extend_attention_wmma_n32_persistent_q_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 48
    .sgpr_spill_count: 0
    .symbol: extend_attention_wmma_n32_persistent_q_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 224
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
