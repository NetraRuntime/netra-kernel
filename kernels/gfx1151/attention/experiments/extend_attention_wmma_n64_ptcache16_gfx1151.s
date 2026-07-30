// SPDX-License-Identifier: MIT
// Raw gfx1151 online-softmax extend attention for Qwen3.6 standard attention.
// Fixed B=1, Hq=16, Hkv=2, Dq=Dv=256, BF16, causal, page size 1.
// Tile: M64 x N64 with K-only LDS-bank swizzle. Grid=(M/64,16,1), block=128.

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

// Physically permute 16-byte K chunks by the low three row bits.
// V writes and all V reads remain byte-for-byte identical to production.
.macro SWIZZLE_K_LDS_WRITE PTR
  .if \PTR == 6
    s_lshr_b32 s41, s39, 9
    s_and_b32 s41, s41, 7
    s_lshl_b32 s41, s41, 4
    v_xor_b32_e32 v230, s41, v230
  .elseif \PTR == 12
    s_lshr_b32 s41, s39, 9
    s_and_b32 s41, s41, 7
    s_lshl_b32 s41, s41, 4
    v_xor_b32_e32 v230, s41, v230
  .endif
.endm

.macro SWIZZLE_K_LDS_READ
  v_and_b32_e32 v235, 7, v3
  v_lshlrev_b32_e32 v235, 4, v235
  v_xor_b32_e32 v234, v235, v234
.endm

// One wave loads keys wave_id + {0,4,...,60}; every lane loads one 16-byte
// head-dimension vector. PTR is the low SGPR of the selected K or V buffer.
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
  global_load_b128 v[225:228], v229, s[32:33]
  s_waitcnt vmcnt(0)
  s_add_u32 s39, s29, \KOFF
  s_lshl_b32 s39, s39, 9
  v_add_nc_u32_e32 v230, s39, v229
  v_add_nc_u32_e32 v230, 32768, v230
  SWIZZLE_K_LDS_WRITE \PTR
  ds_write_b128 v230, v[225:228]
.endm

.macro LOAD_CURRENT_ONE KOFF PTR
  s_add_u32 s38, s28, s29
  s_add_u32 s38, s38, \KOFF
  s_sub_u32 s38, s38, s19
  s_lshl_b32 s38, s38, 10
  s_add_u32 s38, s38, s25
  s_add_u32 s32, s[\PTR], s38
  s_addc_u32 s33, s[\PTR+1], 0
  global_load_b128 v[225:228], v229, s[32:33]
  s_waitcnt vmcnt(0)
  s_add_u32 s39, s29, \KOFF
  s_lshl_b32 s39, s39, 9
  v_add_nc_u32_e32 v230, s39, v229
  v_add_nc_u32_e32 v230, 32768, v230
  SWIZZLE_K_LDS_WRITE \PTR
  ds_write_b128 v230, v[225:228]
.endm

.macro LOAD_PREFIX_BATCH8 KOFF PTR BASE
  s_add_u32 s30, s28, s29
  s_add_u32 s30, s30, \KOFF
  s_lshl_b32 s30, s30, 3
  s_load_b64 s[\BASE:\BASE+1], s[16:17], s30 offset:0
  s_load_b64 s[\BASE+2:\BASE+3], s[16:17], s30 offset:32
  s_load_b64 s[\BASE+4:\BASE+5], s[16:17], s30 offset:64
  s_load_b64 s[\BASE+6:\BASE+7], s[16:17], s30 offset:96
  s_load_b64 s[\BASE+8:\BASE+9], s[16:17], s30 offset:128
  s_load_b64 s[\BASE+10:\BASE+11], s[16:17], s30 offset:160
  s_load_b64 s[\BASE+12:\BASE+13], s[16:17], s30 offset:192
  s_load_b64 s[\BASE+14:\BASE+15], s[16:17], s30 offset:224
  s_waitcnt lgkmcnt(0)
  .set BI, 0
  .rept 8
    s_lshl_b32 s38, s[\BASE+BI*2], 10
    s_add_u32 s38, s38, s25
    s_add_u32 s32, s[\PTR], s38
    s_addc_u32 s33, s[\PTR+1], 0
    .if BI < 4
      global_load_b128 v[8+BI*4:11+BI*4], v229, s[32:33]
    .else
      global_load_b128 v[231+(BI-4)*4:234+(BI-4)*4], v229, s[32:33]
    .endif
    .set BI, BI+1
  .endr
  s_waitcnt vmcnt(0)
  .set BI, 0
  .rept 8
    s_add_u32 s39, s29, (\KOFF+BI*4)
    s_lshl_b32 s39, s39, 9
    v_add_nc_u32_e32 v230, s39, v229
    v_add_nc_u32_e32 v230, 32768, v230
    SWIZZLE_K_LDS_WRITE \PTR
    .if BI < 4
      ds_write_b128 v230, v[8+BI*4:11+BI*4]
    .else
      ds_write_b128 v230, v[231+(BI-4)*4:234+(BI-4)*4]
    .endif
    .set BI, BI+1
  .endr
.endm

// Reuse either retained prefix page-table batch from the K phase.
// The selected BASE SGPR range survives QK, masking, and online softmax.
.macro LOAD_PREFIX_BATCH8_REUSE KOFF PTR BASE
  .set BI, 0
  .rept 8
    s_lshl_b32 s38, s[\BASE+BI*2], 10
    s_add_u32 s38, s38, s25
    s_add_u32 s32, s[\PTR], s38
    s_addc_u32 s33, s[\PTR+1], 0
    .if BI < 4
      global_load_b128 v[8+BI*4:11+BI*4], v229, s[32:33]
    .else
      global_load_b128 v[231+(BI-4)*4:234+(BI-4)*4], v229, s[32:33]
    .endif
    .set BI, BI+1
  .endr
  s_waitcnt vmcnt(0)
  .set BI, 0
  .rept 8
    s_add_u32 s39, s29, (\KOFF+BI*4)
    s_lshl_b32 s39, s39, 9
    v_add_nc_u32_e32 v230, s39, v229
    v_add_nc_u32_e32 v230, 32768, v230
    SWIZZLE_K_LDS_WRITE \PTR
    .if BI < 4
      ds_write_b128 v230, v[8+BI*4:11+BI*4]
    .else
      ds_write_b128 v230, v[231+(BI-4)*4:234+(BI-4)*4]
    .endif
    .set BI, BI+1
  .endr
.endm

.macro LOAD_CURRENT_BATCH16 KOFF PTR
  .set BI, 0
  .rept 16
    s_add_u32 s38, s28, s29
    s_add_u32 s38, s38, (\KOFF+BI*4)
    s_sub_u32 s38, s38, s19
    s_lshl_b32 s38, s38, 10
    s_add_u32 s38, s38, s25
    s_add_u32 s32, s[\PTR], s38
    s_addc_u32 s33, s[\PTR+1], 0
    .if BI < 4
      global_load_b128 v[8+BI*4:11+BI*4], v229, s[32:33]
    .elseif BI < 8
      global_load_b128 v[192+(BI-4)*4:195+(BI-4)*4], v229, s[32:33]
    .elseif BI < 12
      global_load_b128 v[208+(BI-8)*4:211+(BI-8)*4], v229, s[32:33]
    .else
      global_load_b128 v[231+(BI-12)*4:234+(BI-12)*4], v229, s[32:33]
    .endif
    .set BI, BI+1
  .endr
  s_waitcnt vmcnt(0)
  .set BI, 0
  .rept 16
    s_add_u32 s39, s29, (\KOFF+BI*4)
    s_lshl_b32 s39, s39, 9
    v_add_nc_u32_e32 v230, s39, v229
    v_add_nc_u32_e32 v230, 32768, v230
    SWIZZLE_K_LDS_WRITE \PTR
    .if BI < 4
      ds_write_b128 v230, v[8+BI*4:11+BI*4]
    .elseif BI < 8
      ds_write_b128 v230, v[192+(BI-4)*4:195+(BI-4)*4]
    .elseif BI < 12
      ds_write_b128 v230, v[208+(BI-8)*4:211+(BI-8)*4]
    .else
      ds_write_b128 v230, v[231+(BI-12)*4:234+(BI-12)*4]
    .endif
    .set BI, BI+1
  .endr
.endm

.macro LOAD_PREFIX_64 PTR
  LOAD_PREFIX_BATCH8 0,  \PTR, 44
  LOAD_PREFIX_BATCH8 32, \PTR, 60
.endm

.macro LOAD_CURRENT_64 PTR
  LOAD_CURRENT_BATCH16 0, \PTR
.endm

.macro RESTORE_Q_P_ADDRS
  v_lshlrev_b32_e32 v231, 4, v2
  v_add_nc_u32_e32 v231, s21, v231
  v_add_nc_u32_e32 v231, v231, v3
  v_lshlrev_b32_e32 v240, 13, v231
  v_add_nc_u32_e32 v240, s24, v240
  v_lshl_add_u32 v240, v4, 4, v240
  v_lshlrev_b32_e32 v231, 13, v2
  v_lshl_add_u32 v232, v4, 7, v231
  v_lshl_add_u32 v232, v3, 1, v232
  v_add_nc_u32_e32 v232, 6144, v232
  v_lshl_add_u32 v233, v3, 7, v231
  v_lshlrev_b32_e32 v229, 4, v1
  v_lshl_add_u32 v233, v4, 4, v233
  v_add_nc_u32_e32 v233, 6144, v233
.endm

// Load or restore all 16 Q depth fragments in two batches. v192:v223 are
// dead at both call sites; retaining eight VMEM operations before vmcnt(0)
// exposes memory-level parallelism without changing the 248-VGPR allocation.
.macro LOAD_Q_PIPE8
  .set QP, 0
  .rept 2
    .set QI, 0
    .rept 8
      global_load_b128 v[192+QI*4:195+QI*4], v240, s[4:5] offset:((QP*8+QI)*32)
      .set QI, QI+1
    .endr
    s_waitcnt vmcnt(0)
    .set QI, 0
    .rept 8
      ds_write_b128 v5, v[192+QI*4:195+QI*4] offset:((QP*8+QI)*32)
      .set QI, QI+1
    .endr
    .set QP, QP+1
  .endr
.endm

.protected extend_attention_wmma_n64_ptcache16_gfx1151
.globl extend_attention_wmma_n64_ptcache16_gfx1151
.p2align 8
.type extend_attention_wmma_n64_ptcache16_gfx1151,@function
extend_attention_wmma_n64_ptcache16_gfx1151:
  // q, k_extend, v_extend, o, k_buffer, v_buffer, kv_indices,
  // tokens, prefix_tokens, sm_scale, reserved
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
  v_lshlrev_b32_e32 v229, 4, v1

  // Global Q address and persistent row-major Q LDS address.
  v_lshlrev_b32_e32 v231, 4, v2
  v_add_nc_u32_e32 v231, s21, v231
  v_add_nc_u32_e32 v231, v231, v3
  v_lshlrev_b32_e32 v240, 13, v231
  v_add_nc_u32_e32 v240, s24, v240
  v_lshl_add_u32 v240, v4, 4, v240
  v_lshlrev_b32_e32 v5, 13, v2
  v_lshl_add_u32 v5, v3, 9, v5
  v_lshl_add_u32 v5, v4, 4, v5
  LOAD_Q_PIPE8
  s_waitcnt lgkmcnt(0)
  s_barrier

  // C-layout row base: parity in lane[4], accumulator index enumerates row/2.
  v_lshlrev_b32_e32 v6, 4, v2
  v_add_nc_u32_e32 v6, s21, v6
  v_add_nc_u32_e32 v6, v6, v4

  // P overlays Q rows 12..15 after QK. Store is C->row-major; load is A layout.
  v_lshlrev_b32_e32 v231, 13, v2
  v_lshl_add_u32 v232, v4, 7, v231
  v_lshl_add_u32 v232, v3, 1, v232
  v_add_nc_u32_e32 v232, 6144, v232
  v_lshl_add_u32 v233, v3, 7, v231
  v_lshl_add_u32 v233, v4, 4, v233
  v_add_nc_u32_e32 v233, 6144, v233

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
  // Restore the four Q rows occupied by the preceding tile's P transpose.
  v_cmp_le_u32_e32 vcc_lo, 12, v3
  s_and_saveexec_b32 s42, vcc_lo
  LOAD_Q_PIPE8
  s_mov_b32 exec_lo, s42
  s_waitcnt lgkmcnt(0)
  s_barrier

  // K phase: the 32 KiB data half of LDS holds 64x256 BF16 K.
  s_cmp_lt_u32 s28, s19
  s_cbranch_scc0 .Lload_k_current
  LOAD_PREFIX_64 12
  s_branch .Lk_loaded
.Lload_k_current:
  LOAD_CURRENT_64 6
.Lk_loaded:
  RESTORE_Q_P_ADDRS
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
  v_dual_mov_b32 v200, 0 :: v_dual_mov_b32 v201, 0
  v_dual_mov_b32 v202, 0 :: v_dual_mov_b32 v203, 0
  v_dual_mov_b32 v204, 0 :: v_dual_mov_b32 v205, 0
  v_dual_mov_b32 v206, 0 :: v_dual_mov_b32 v207, 0
  v_dual_mov_b32 v208, 0 :: v_dual_mov_b32 v209, 0
  v_dual_mov_b32 v210, 0 :: v_dual_mov_b32 v211, 0
  v_dual_mov_b32 v212, 0 :: v_dual_mov_b32 v213, 0
  v_dual_mov_b32 v214, 0 :: v_dual_mov_b32 v215, 0

  .set DK, 0
  .rept 16
    ds_load_b128 v[8:11], v5 offset:(DK*32)
    s_waitcnt lgkmcnt(0)
    ds_swizzle_b32 v12, v8 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v13, v9 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v14, v10 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v15, v11 offset:swizzle(SWAP,16)
    s_waitcnt lgkmcnt(0)
    .set KT, 0
    v_lshlrev_b32_e32 v234, 9, v3
    v_lshl_add_u32 v234, v4, 4, v234
    v_add_nc_u32_e32 v234, (32768+DK*32), v234
    SWIZZLE_K_LDS_READ
    ds_load_b128 v[16:19], v234
    s_waitcnt lgkmcnt(0)
    ds_swizzle_b32 v20, v16 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v21, v17 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v22, v18 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v23, v19 offset:swizzle(SWAP,16)
    s_waitcnt lgkmcnt(0)
    .rept 4
      .if KT < 3
        v_lshlrev_b32_e32 v234, 9, v3
        v_lshl_add_u32 v234, v4, 4, v234
        v_add_nc_u32_e32 v234, (32768+(KT+1)*8192+DK*32), v234
        SWIZZLE_K_LDS_READ
        .if (KT % 2) == 0
          ds_load_b128 v[225:228], v234
        .else
          ds_load_b128 v[16:19], v234
        .endif
      .endif
      .if KT == 0
        v_wmma_f32_16x16x16_bf16 v[24:31], v[8:15], v[16:23], v[24:31]
      .elseif KT == 1
        v_wmma_f32_16x16x16_bf16 v[192:199], v[8:15], v[225:232], v[192:199]
      .elseif KT == 2
        v_wmma_f32_16x16x16_bf16 v[200:207], v[8:15], v[16:23], v[200:207]
      .else
        v_wmma_f32_16x16x16_bf16 v[208:215], v[8:15], v[225:232], v[208:215]
      .endif
      .if KT < 3
        s_waitcnt lgkmcnt(0)
        .if (KT % 2) == 0
          ds_swizzle_b32 v229, v225 offset:swizzle(SWAP,16)
          ds_swizzle_b32 v230, v226 offset:swizzle(SWAP,16)
          ds_swizzle_b32 v231, v227 offset:swizzle(SWAP,16)
          ds_swizzle_b32 v232, v228 offset:swizzle(SWAP,16)
        .else
          ds_swizzle_b32 v20, v16 offset:swizzle(SWAP,16)
          ds_swizzle_b32 v21, v17 offset:swizzle(SWAP,16)
          ds_swizzle_b32 v22, v18 offset:swizzle(SWAP,16)
          ds_swizzle_b32 v23, v19 offset:swizzle(SWAP,16)
        .endif
        s_waitcnt lgkmcnt(0)
      .endif
      .set KT, KT+1
    .endr
    .set DK, DK+1
  .endr
  RESTORE_Q_P_ADDRS
  // Only the diagonal current-chunk tile is partially causal. Every prefix
  // tile and every earlier current tile is fully valid and needs scaling only.
  s_add_u32 s40, s19, s21
  s_cmp_eq_u32 s28, s40
  s_cbranch_scc1 .Lcausal_mask
  .set FT, 0
  .rept 4
    .set FR, 0
    .rept 8
      .if FT == 0
        .set FREG, 24+FR
      .elseif FT == 1
        .set FREG, 192+FR
      .elseif FT == 2
        .set FREG, 200+FR
      .else
        .set FREG, 208+FR
      .endif
      v_mul_f32_e32 v[FREG], s20, v[FREG]
      .set FR, FR+1
    .endr
    .set FT, FT+1
  .endr
  s_branch .Lmask_done
.Lcausal_mask:

  // Apply causal mask to four 16-column score fragments.
  .set MT, 0
  .rept 4
    .set MR, 0
    .rept 8
      .if MT == 0
        .set SREG, 24+MR
      .elseif MT == 1
        .set SREG, 192+MR
      .elseif MT == 2
        .set SREG, 200+MR
      .else
        .set SREG, 208+MR
      .endif
      v_mul_f32_e32 v[SREG], s20, v[SREG]
      v_add_nc_u32_e32 v235, (MT*16), v3
      v_add_nc_u32_e32 v235, s28, v235
      v_add_nc_u32_e32 v236, (MR*2), v6
      v_add_nc_u32_e32 v237, s19, v236
      v_add_nc_u32_e32 v237, 1, v237
      v_cmp_lt_u32_e32 vcc_lo, v235, v237
      v_cndmask_b32_e32 v[SREG], 0xff800000, v[SREG], vcc_lo
      .set MR, MR+1
    .endr
    .set MT, MT+1
  .endr
.Lmask_done:

  // One online-softmax update for all 64 columns.
  .set SR, 0
  .rept 8
    v_mov_b32_e32 v[216+SR], v[24+SR]
    ALLREDUCE_MAX (216+SR), 224
    v_mov_b32_e32 v225, v[192+SR]
    ALLREDUCE_MAX 225, 224
    v_max_f32_e32 v[216+SR], v[216+SR], v225
    v_mov_b32_e32 v225, v[200+SR]
    ALLREDUCE_MAX 225, 224
    v_max_f32_e32 v[216+SR], v[216+SR], v225
    v_mov_b32_e32 v225, v[208+SR]
    ALLREDUCE_MAX 225, 224
    v_max_f32_e32 v[216+SR], v[216+SR], v225
    v_max_f32_e32 v[216+SR], v[32+SR], v[216+SR]
    v_sub_f32_e32 v[48+SR], v[32+SR], v[216+SR]
    v_mul_f32_e32 v[48+SR], 0x3fb8aa3b, v[48+SR]
    v_exp_f32_e32 v[48+SR], v[48+SR]
    v_sub_f32_e32 v[24+SR], v[24+SR], v[216+SR]
    v_mul_f32_e32 v[24+SR], 0x3fb8aa3b, v[24+SR]
    v_exp_f32_e32 v[24+SR], v[24+SR]
    v_sub_f32_e32 v[192+SR], v[192+SR], v[216+SR]
    v_mul_f32_e32 v[192+SR], 0x3fb8aa3b, v[192+SR]
    v_exp_f32_e32 v[192+SR], v[192+SR]
    v_sub_f32_e32 v[200+SR], v[200+SR], v[216+SR]
    v_mul_f32_e32 v[200+SR], 0x3fb8aa3b, v[200+SR]
    v_exp_f32_e32 v[200+SR], v[200+SR]
    v_sub_f32_e32 v[208+SR], v[208+SR], v[216+SR]
    v_mul_f32_e32 v[208+SR], 0x3fb8aa3b, v[208+SR]
    v_exp_f32_e32 v[208+SR], v[208+SR]
    v_mov_b32_e32 v[32+SR], v[216+SR]
    v_mov_b32_e32 v[216+SR], v[24+SR]
    ALLREDUCE_SUM (216+SR), 224
    v_mov_b32_e32 v225, v[192+SR]
    ALLREDUCE_SUM 225, 224
    v_add_f32_e32 v[216+SR], v[216+SR], v225
    v_mov_b32_e32 v225, v[200+SR]
    ALLREDUCE_SUM 225, 224
    v_add_f32_e32 v[216+SR], v[216+SR], v225
    v_mov_b32_e32 v225, v[208+SR]
    ALLREDUCE_SUM 225, 224
    v_add_f32_e32 v[216+SR], v[216+SR], v225
    v_mul_f32_e32 v[40+SR], v[40+SR], v[48+SR]
    v_add_f32_e32 v[40+SR], v[40+SR], v[216+SR]
    .set SR, SR+1
  .endr

  .set OT, 64
  .rept 16
    RESCALE_TILE OT
    .set OT, OT+8
  .endr

  // Transpose four P fragments into the Q-overlaid 16x64 BF16 workspace.
  .set PT, 0
  .rept 4
    .set PR, 0
    .rept 8
      .if PT == 0
        .set PREG, 24+PR
      .elseif PT == 1
        .set PREG, 192+PR
      .elseif PT == 2
        .set PREG, 200+PR
      .else
        .set PREG, 208+PR
      .endif
      v_lshrrev_b32_e32 v238, 16, v[PREG]
      v_and_b32_e32 v238, 1, v238
      v_add_nc_u32_e32 v239, 0x7fff, v[PREG]
      v_add_nc_u32_e32 v239, v238, v239
      v_lshrrev_b32_e32 v239, 16, v239
      ds_write_b16 v232, v239 offset:(PT*32+PR*256)
      .set PR, PR+1
    .endr
    .set PT, PT+1
  .endr
  s_waitcnt lgkmcnt(0)
  s_barrier

  // V phase overwrites the K data half after all QK consumers finish.
  s_cmp_lt_u32 s28, s19
  s_cbranch_scc0 .Lload_v_current
  LOAD_PREFIX_BATCH8_REUSE 0, 14, 44
  LOAD_PREFIX_BATCH8_REUSE 32, 14, 60
  s_branch .Lv_loaded
.Lload_v_current:
  LOAD_CURRENT_64 8
.Lv_loaded:
  RESTORE_Q_P_ADDRS
  s_waitcnt lgkmcnt(0)
  s_barrier

  // Four P[16x16] x V[16x256] fragments accumulate into 16 output tiles.
  .set VT, 0
  .rept 4
    ds_load_b128 v[8:11], v233 offset:(VT*32)
    s_waitcnt lgkmcnt(0)
    ds_swizzle_b32 v12, v8 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v13, v9 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v14, v10 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v15, v11 offset:swizzle(SWAP,16)
    s_waitcnt lgkmcnt(0)
    v_lshlrev_b32_e32 v234, 12, v4
    v_lshl_add_u32 v234, v3, 1, v234
    v_add_nc_u32_e32 v234, (32768+VT*8192), v234
    .set OB, 0
    ds_load_u16 v16, v234 offset:(OB*32+0)
    ds_load_u16_d16_hi v16, v234 offset:(OB*32+512)
    ds_load_u16 v17, v234 offset:(OB*32+1024)
    ds_load_u16_d16_hi v17, v234 offset:(OB*32+1536)
    ds_load_u16 v18, v234 offset:(OB*32+2048)
    ds_load_u16_d16_hi v18, v234 offset:(OB*32+2560)
    ds_load_u16 v19, v234 offset:(OB*32+3072)
    ds_load_u16_d16_hi v19, v234 offset:(OB*32+3584)
    s_waitcnt lgkmcnt(0)
    ds_swizzle_b32 v20, v16 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v21, v17 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v22, v18 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v23, v19 offset:swizzle(SWAP,16)
    s_waitcnt lgkmcnt(0)
    .rept 16
      .if (OB % 2) == 0
        .if OB < 15
          ds_load_u16 v225, v234 offset:((OB+1)*32+0)
          ds_load_u16_d16_hi v225, v234 offset:((OB+1)*32+512)
          ds_load_u16 v226, v234 offset:((OB+1)*32+1024)
          ds_load_u16_d16_hi v226, v234 offset:((OB+1)*32+1536)
          ds_load_u16 v227, v234 offset:((OB+1)*32+2048)
          ds_load_u16_d16_hi v227, v234 offset:((OB+1)*32+2560)
          ds_load_u16 v228, v234 offset:((OB+1)*32+3072)
          ds_load_u16_d16_hi v228, v234 offset:((OB+1)*32+3584)
        .endif
        v_wmma_f32_16x16x16_bf16 v[64+OB*8:71+OB*8], v[8:15], v[16:23], v[64+OB*8:71+OB*8]
        .if OB < 15
          s_waitcnt lgkmcnt(0)
          ds_swizzle_b32 v229, v225 offset:swizzle(SWAP,16)
          ds_swizzle_b32 v230, v226 offset:swizzle(SWAP,16)
          ds_swizzle_b32 v231, v227 offset:swizzle(SWAP,16)
          ds_swizzle_b32 v232, v228 offset:swizzle(SWAP,16)
          s_waitcnt lgkmcnt(0)
        .endif
      .else
        .if OB < 15
          ds_load_u16 v16, v234 offset:((OB+1)*32+0)
          ds_load_u16_d16_hi v16, v234 offset:((OB+1)*32+512)
          ds_load_u16 v17, v234 offset:((OB+1)*32+1024)
          ds_load_u16_d16_hi v17, v234 offset:((OB+1)*32+1536)
          ds_load_u16 v18, v234 offset:((OB+1)*32+2048)
          ds_load_u16_d16_hi v18, v234 offset:((OB+1)*32+2560)
          ds_load_u16 v19, v234 offset:((OB+1)*32+3072)
          ds_load_u16_d16_hi v19, v234 offset:((OB+1)*32+3584)
        .endif
        v_wmma_f32_16x16x16_bf16 v[64+OB*8:71+OB*8], v[8:15], v[225:232], v[64+OB*8:71+OB*8]
        .if OB < 15
          s_waitcnt lgkmcnt(0)
          ds_swizzle_b32 v20, v16 offset:swizzle(SWAP,16)
          ds_swizzle_b32 v21, v17 offset:swizzle(SWAP,16)
          ds_swizzle_b32 v22, v18 offset:swizzle(SWAP,16)
          ds_swizzle_b32 v23, v19 offset:swizzle(SWAP,16)
          s_waitcnt lgkmcnt(0)
        .endif
      .endif
      .set OB, OB+1
    .endr
    .set VT, VT+1
  .endr

  v_lshlrev_b32_e32 v229, 4, v1
  s_add_u32 s28, s28, 64
  s_cmp_lt_u32 s28, s27
  s_cbranch_scc1 .Ltile_loop

  // Normalize once per row, then write the 16 BF16 output-column tiles.
  .set IR, 0
  .rept 8
    v_rcp_f32_e32 v[56+IR], v[40+IR]
    .set IR, IR+1
  .endr
  .set WB, 0
  .rept 16
    .set WR, 0
    .rept 8
      v_mul_f32_e32 v238, v[64+WB*8+WR], v[56+WR]
      v_lshrrev_b32_e32 v239, 16, v238
      v_and_b32_e32 v239, 1, v239
      v_add_nc_u32_e32 v240, 0x7fff, v238
      v_add_nc_u32_e32 v240, v239, v240
      v_lshrrev_b32_e32 v240, 16, v240
      v_add_nc_u32_e32 v241, (WR*2), v6
      v_lshlrev_b32_e32 v242, 13, v241
      v_add_nc_u32_e32 v242, s24, v242
      v_lshl_add_u32 v242, v3, 1, v242
      v_add_nc_u32_e32 v242, (WB*32), v242
      v_cmp_gt_u32_e32 vcc_lo, s18, v241
      s_and_saveexec_b32 s42, vcc_lo
      global_store_short v242, v240, s[10:11]
      s_mov_b32 exec_lo, s42
      .set WR, WR+1
    .endr
    .set WB, WB+1
  .endr
.Lend:
  s_endpgm

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel extend_attention_wmma_n64_ptcache16_gfx1151
.amdhsa_group_segment_fixed_size 65536
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
.amdhsa_next_free_vgpr 247
.amdhsa_next_free_sgpr 76
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
.size extend_attention_wmma_n64_ptcache16_gfx1151, .Lfunc_end0-extend_attention_wmma_n64_ptcache16_gfx1151

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
      - { .name: tokens, .offset: 56, .size: 4, .value_kind: by_value }
      - { .name: prefix_tokens, .offset: 60, .size: 4, .value_kind: by_value }
      - { .name: sm_scale, .offset: 64, .size: 4, .value_kind: by_value }
      - { .name: reserved, .offset: 68, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 65536
    .kernarg_segment_align: 8
    .kernarg_segment_size: 72
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 128
    .name: extend_attention_wmma_n64_ptcache16_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 64
    .sgpr_spill_count: 0
    .symbol: extend_attention_wmma_n64_ptcache16_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 244
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
