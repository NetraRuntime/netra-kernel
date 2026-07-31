// SPDX-License-Identifier: MIT
// Raw gfx1151 Qwen3.6 GDN chunk-output: two-wave fused gated qh + causal qk + Av.
// Fixed B=1,T=8192,H=32,Hg=16,K=V=128,BT=64,BV=32, BF16 q/h/o, FP32 g.
// Grid=(4,256,32), block=64 wave32. Each workgroup owns one 32-row half chunk.
// Experiment: persist the full-chunk gate vector at LDS 24576 across qh and qk.
// Production two-wave fixes the rejected prototype's missing Q rows 4..7 in every eight-row group.
// Raw full compute path; no compiler-generated compute or scratch.

.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
.amdhsa_code_object_version 6
.text

.macro GATE_TILE MT
  s_cmp_lt_u32 s43, \MT
  s_cbranch_scc1 .Lgate_tile_done_\@
  .set RR, 0
  .rept 8
    .set AREG, 24+\MT*8+RR
    v_sub_f32_e32 v92, v[84+RR], v[80+\MT]
    v_cmp_le_f32_e32 vcc_lo, v92, v98
    v_cndmask_b32_e32 v92, 0xff800000, v92, vcc_lo
    v_mul_f32_e32 v92, 0x3fb8aa3b, v92
    v_exp_f32_e32 v92, v92
    v_lshlrev_b32_e32 v93, 4, v2
    v_add_nc_u32_e32 v93, v4, v93
    v_add_nc_u32_e32 v93, (RR*2), v93
    v_add_nc_u32_e32 v93, s45, v93
    v_add_nc_u32_e32 v94, (\MT*16), v3
    v_cmp_le_u32_e32 vcc_lo, v94, v93
    v_cndmask_b32_e32 v92, 0, v92, vcc_lo
    v_mul_f32_e32 v[AREG], v[AREG], v92
    v_lshrrev_b32_e32 v95, 16, v[AREG]
    v_and_b32_e32 v95, 1, v95
    v_add_nc_u32_e32 v96, 0x7fff, v[AREG]
    v_add_nc_u32_e32 v96, v95, v96
    v_lshrrev_b32_e32 v96, 16, v96
    v_lshlrev_b32_e32 v97, 11, v2
    v_lshl_add_u32 v97, v4, 7, v97
    v_lshl_add_u32 v97, v3, 1, v97
    ds_write_b16 v97, v96 offset:(\MT*32+RR*256)
    .set RR, RR+1
  .endr
.Lgate_tile_done_\@:
.endm

.protected gdn_chunk_o_bv32_gskip_pipe8_gfx1151
.globl gdn_chunk_o_bv32_gskip_pipe8_gfx1151
.p2align 8
.type gdn_chunk_o_bv32_gskip_pipe8_gfx1151,@function
gdn_chunk_o_bv32_gskip_pipe8_gfx1151:
  // q,k,v,h,g,o,cu_seqlens,chunk_indices,scale,T
  // System SGPRs: s2=BV tile, s3=(chunk*2+row_half), s4=head.
  s_mov_b32 s26, s4
  s_clause 0x4
  s_load_b128 s[8:11], s[0:1], 0
  s_load_b128 s[12:15], s[0:1], 16
  s_load_b128 s[16:19], s[0:1], 32
  s_load_b128 s[20:23], s[0:1], 48
  s_load_b64 s[24:25], s[0:1], 64
  s_waitcnt lgkmcnt(0)

  // Scalar fixed-shape bases.
  s_lshr_b32 s27, s26, 1              // grouped q/h head
  s_and_b32 s43, s3, 1                // 32-row half within chunk
  s_lshr_b32 s44, s3, 1               // 64-row chunk
  s_lshl_b32 s45, s43, 5              // half row offset
  s_lshl_b32 s28, s44, 6              // first token in chunk
  s_add_u32 s28, s28, s45             // first query token in half
  s_lshl_b32 s29, s27, 8              // q head byte offset
  s_lshl_b32 s30, s44, 20             // h chunk byte offset
  s_lshl_b32 s31, s26, 15             // h head byte offset
  s_add_u32 s30, s30, s31
  s_lshl_b32 s31, s2, 13              // h BV32 byte offset
  s_add_u32 s30, s30, s31
  s_lshl_b32 s31, s44, 6              // first token in full chunk

  v_and_b32_e32 v1, 31, v0            // lane
  v_lshrrev_b32_e32 v2, 5, v0         // wave 0..1
  v_and_b32_e32 v3, 15, v0            // WMMA column lane
  v_lshrrev_b32_e32 v4, 4, v1         // WMMA row parity
  v_and_b32_e32 v200, 15, v0          // 16-byte vector index
  v_lshrrev_b32_e32 v201, 4, v0       // loader row 0..3

  // Stage this half's complete Q[32,128] row-major at LDS 0.
  .set LR, 208
  .set QR, 0
  .rept 8
    v_add_nc_u32_e32 v202, (QR*4), v201
    v_add_nc_u32_e32 v203, s28, v202
    v_lshlrev_b32_e32 v204, 12, v203
    v_add_nc_u32_e32 v204, s29, v204
    v_lshl_add_u32 v204, v200, 4, v204
    global_load_b128 v[LR:LR+3], v204, s[8:9]
    .set LR, LR+4
    .set QR, QR+1
  .endr
  s_waitcnt vmcnt(0)
  .set LR, 208
  .set QR, 0
  .rept 8
    v_add_nc_u32_e32 v202, (QR*4), v201
    v_lshlrev_b32_e32 v205, 8, v202
    v_lshl_add_u32 v205, v200, 4, v205
    ds_write_b128 v205, v[LR:LR+3]
    .set LR, LR+4
    .set QR, QR+1
  .endr

  // Stage H[BV32,128] row-major at LDS 8192.
  .set LR, 208
  .set HR, 0
  .rept 8
    v_add_nc_u32_e32 v202, (HR*4), v201
    v_lshlrev_b32_e32 v204, 8, v202
    v_add_nc_u32_e32 v204, s30, v204
    v_lshl_add_u32 v204, v200, 4, v204
    global_load_b128 v[LR:LR+3], v204, s[14:15]
    .set LR, LR+4
    .set HR, HR+1
  .endr
  s_waitcnt vmcnt(0)
  .set LR, 208
  .set HR, 0
  .rept 8
    v_add_nc_u32_e32 v202, (HR*4), v201
    v_lshlrev_b32_e32 v205, 8, v202
    v_lshl_add_u32 v205, v200, 4, v205
    v_add_nc_u32_e32 v205, 8192, v205
    ds_write_b128 v205, v[LR:LR+3]
    .set LR, LR+4
    .set HR, HR+1
  .endr

  // Stage the full chunk's g[64,head] once at persistent LDS 24576.
  v_add_nc_u32_e32 v202, s31, v0
  v_lshlrev_b32_e32 v204, 7, v202
  v_lshl_add_u32 v204, s26, 2, v204
  global_load_dword v208, v204, s[16:17]
  s_waitcnt vmcnt(0)
  v_lshlrev_b32_e32 v205, 2, v0
  v_add_nc_u32_e32 v205, 24576, v205
  ds_write_b32 v205, v208
  s_waitcnt lgkmcnt(0)
  s_barrier

  // C accumulators: two 16-column output fragments per wave.
  v_mov_b32_e32 v64, 0
  v_mov_b32_e32 v65, 0
  v_mov_b32_e32 v66, 0
  v_mov_b32_e32 v67, 0
  v_mov_b32_e32 v68, 0
  v_mov_b32_e32 v69, 0
  v_mov_b32_e32 v70, 0
  v_mov_b32_e32 v71, 0
  v_mov_b32_e32 v72, 0
  v_mov_b32_e32 v73, 0
  v_mov_b32_e32 v74, 0
  v_mov_b32_e32 v75, 0
  v_mov_b32_e32 v76, 0
  v_mov_b32_e32 v77, 0
  v_mov_b32_e32 v78, 0
  v_mov_b32_e32 v79, 0

  // Q A-layout base for this wave's 16 rows.
  v_lshlrev_b32_e32 v5, 12, v2
  v_lshl_add_u32 v5, v3, 8, v5
  v_lshl_add_u32 v5, v4, 4, v5

  // Eight K16 steps; H is already in N-major row-major form.
  .set DK, 0
  .rept 8
    ds_load_b128 v[8:11], v5 offset:(DK*32)
    s_waitcnt lgkmcnt(0)
    ds_swizzle_b32 v12, v8 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v13, v9 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v14, v10 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v15, v11 offset:swizzle(SWAP,16)
    s_waitcnt lgkmcnt(0)

    v_lshlrev_b32_e32 v206, 8, v3
    v_lshl_add_u32 v206, v4, 4, v206
    v_add_nc_u32_e32 v206, (8192+DK*32), v206
    ds_load_b128 v[16:19], v206
    s_waitcnt lgkmcnt(0)
    ds_swizzle_b32 v20, v16 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v21, v17 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v22, v18 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v23, v19 offset:swizzle(SWAP,16)
    s_waitcnt lgkmcnt(0)
    v_wmma_f32_16x16x16_bf16 v[64:71], v[8:15], v[16:23], v[64:71]

    v_add_nc_u32_e32 v206, 4096, v206
    ds_load_b128 v[16:19], v206
    s_waitcnt lgkmcnt(0)
    ds_swizzle_b32 v20, v16 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v21, v17 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v22, v18 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v23, v19 offset:swizzle(SWAP,16)
    s_waitcnt lgkmcnt(0)
    v_wmma_f32_16x16x16_bf16 v[72:79], v[8:15], v[16:23], v[72:79]
    .set DK, DK+1
  .endr

  // Apply exp(g_row) and model scale once per output row.
  .set MR, 0
  .rept 8
    v_lshlrev_b32_e32 v206, 4, v2
    v_add_nc_u32_e32 v206, v4, v206
    v_add_nc_u32_e32 v206, (MR*2), v206
    v_add_nc_u32_e32 v206, s45, v206
    v_lshlrev_b32_e32 v206, 2, v206
    v_add_nc_u32_e32 v206, 24576, v206
    ds_load_b32 v208, v206
    s_waitcnt lgkmcnt(0)
    v_mul_f32_e32 v208, 0x3fb8aa3b, v208
    v_exp_f32_e32 v208, v208
    v_mul_f32_e32 v[64+MR], v[64+MR], v208
    v_mul_f32_e32 v[72+MR], v[72+MR], v208
    .set MR, MR+1
  .endr

  // All waves finished reading H. Replace it with K[64,128].
  s_barrier
  .set KB, 0
  .rept 2
    .set LR, 208
    .set KR, 0
    .rept 8
      v_add_nc_u32_e32 v202, (KB*32+KR*4), v201
      v_add_nc_u32_e32 v203, s31, v202
      v_lshlrev_b32_e32 v204, 12, v203
      v_add_nc_u32_e32 v204, s29, v204
      v_lshl_add_u32 v204, v200, 4, v204
      global_load_b128 v[LR:LR+3], v204, s[10:11]
      .set LR, LR+4
      .set KR, KR+1
    .endr
    s_waitcnt vmcnt(0)
    .set LR, 208
    .set KR, 0
    .rept 8
      v_add_nc_u32_e32 v202, (KB*32+KR*4), v201
      v_lshlrev_b32_e32 v205, 8, v202
      v_lshl_add_u32 v205, v200, 4, v205
      v_add_nc_u32_e32 v205, 8192, v205
      ds_write_b128 v205, v[LR:LR+3]
      .set LR, LR+4
      .set KR, KR+1
    .endr
    .set KB, KB+1
  .endr
  s_waitcnt lgkmcnt(0)
  s_barrier

  // Four 16-column q @ k^T fragments. These become gated causal A.
  .set AR, 24
  .rept 32
    v_mov_b32_e32 v[AR], 0
    .set AR, AR+1
  .endr
  .set DK, 0
  .rept 8
    ds_load_b128 v[8:11], v5 offset:(DK*32)
    s_waitcnt lgkmcnt(0)
    ds_swizzle_b32 v12, v8 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v13, v9 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v14, v10 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v15, v11 offset:swizzle(SWAP,16)
    s_waitcnt lgkmcnt(0)
    .set KT, 0
    .rept 4
      v_lshlrev_b32_e32 v206, 8, v3
      v_lshl_add_u32 v206, v4, 4, v206
      v_add_nc_u32_e32 v206, (8192+KT*4096+DK*32), v206
      ds_load_b128 v[16:19], v206
      s_waitcnt lgkmcnt(0)
      ds_swizzle_b32 v20, v16 offset:swizzle(SWAP,16)
      ds_swizzle_b32 v21, v17 offset:swizzle(SWAP,16)
      ds_swizzle_b32 v22, v18 offset:swizzle(SWAP,16)
      ds_swizzle_b32 v23, v19 offset:swizzle(SWAP,16)
      s_waitcnt lgkmcnt(0)
      v_wmma_f32_16x16x16_bf16 v[24+KT*8:31+KT*8], v[8:15], v[16:23], v[24+KT*8:31+KT*8]
      .set KT, KT+1
    .endr
    .set DK, DK+1
  .endr

  // Clear the complete WMMA A workspace before skipping full-future tiles.
  v_mov_b32_e32 v208, 0
  v_mov_b32_e32 v209, 0
  v_mov_b32_e32 v210, 0
  v_mov_b32_e32 v211, 0
  v_lshlrev_b32_e32 v205, 6, v0
  ds_write_b128 v205, v[208:211] offset:0
  ds_write_b128 v205, v[208:211] offset:16
  ds_write_b128 v205, v[208:211] offset:32
  ds_write_b128 v205, v[208:211] offset:48
  s_waitcnt lgkmcnt(0)
  s_barrier
  v_readfirstlane_b32 s43, v2
  s_lshr_b32 s44, s45, 4
  s_add_u32 s43, s44, s43

  // Q is dead. Reuse the persistent gates without a reload or barrier.
  .set GC, 0
  .rept 4
    v_add_nc_u32_e32 v206, (GC*16), v3
    v_lshlrev_b32_e32 v206, 2, v206
    v_add_nc_u32_e32 v206, 24576, v206
    ds_load_b32 v[80+GC], v206
    .set GC, GC+1
  .endr
  .set GR, 0
  .rept 8
    v_lshlrev_b32_e32 v206, 4, v2
    v_add_nc_u32_e32 v206, v4, v206
    v_add_nc_u32_e32 v206, (GR*2), v206
    v_add_nc_u32_e32 v206, s45, v206
    v_lshlrev_b32_e32 v206, 2, v206
    v_add_nc_u32_e32 v206, 24576, v206
    ds_load_b32 v[84+GR], v206
    .set GR, GR+1
  .endr
  s_waitcnt lgkmcnt(0)

  // Apply safe_exp(g_row-g_col), causal mask, and store A as BF16.
  v_mov_b32_e32 v98, 0
  GATE_TILE 0
  GATE_TILE 1
  GATE_TILE 2
  GATE_TILE 3
  s_waitcnt lgkmcnt(0)
  s_barrier

  // Stage V[64,32] row-major at LDS 8192.
  v_and_b32_e32 v200, 3, v0
  v_lshrrev_b32_e32 v201, 2, v0
  .set LR, 208
  .set VR, 0
  .rept 4
    v_add_nc_u32_e32 v202, (VR*16), v201
    v_add_nc_u32_e32 v203, s31, v202
    v_lshlrev_b32_e32 v204, 13, v203
    v_lshl_add_u32 v204, s26, 8, v204
    v_lshl_add_u32 v204, s2, 6, v204
    v_lshl_add_u32 v204, v200, 4, v204
    global_load_b128 v[LR:LR+3], v204, s[12:13]
    .set LR, LR+4
    .set VR, VR+1
  .endr
  s_waitcnt vmcnt(0)
  .set LR, 208
  .set VR, 0
  .rept 4
    v_add_nc_u32_e32 v202, (VR*16), v201
    v_lshlrev_b32_e32 v205, 6, v202
    v_lshl_add_u32 v205, v200, 4, v205
    v_add_nc_u32_e32 v205, 8192, v205
    ds_write_b128 v205, v[LR:LR+3]
    .set LR, LR+4
    .set VR, VR+1
  .endr
  s_waitcnt lgkmcnt(0)
  s_barrier

  // A[32,64] @ V[64,32], accumulating directly into gated qh C registers.
  v_lshlrev_b32_e32 v7, 11, v2
  v_lshl_add_u32 v7, v3, 7, v7
  v_lshl_add_u32 v7, v4, 4, v7
  .set VT, 0
  .rept 4
    ds_load_b128 v[8:11], v7 offset:(VT*32)
    s_waitcnt lgkmcnt(0)
    ds_swizzle_b32 v12, v8 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v13, v9 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v14, v10 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v15, v11 offset:swizzle(SWAP,16)
    s_waitcnt lgkmcnt(0)
    .set OB, 0
    .rept 2
      v_lshlrev_b32_e32 v206, 9, v4
      v_lshl_add_u32 v206, v3, 1, v206
      v_add_nc_u32_e32 v206, (8192+VT*1024+OB*32), v206
      ds_load_u16 v16, v206 offset:0
      ds_load_u16_d16_hi v16, v206 offset:64
      ds_load_u16 v17, v206 offset:128
      ds_load_u16_d16_hi v17, v206 offset:192
      ds_load_u16 v18, v206 offset:256
      ds_load_u16_d16_hi v18, v206 offset:320
      ds_load_u16 v19, v206 offset:384
      ds_load_u16_d16_hi v19, v206 offset:448
      s_waitcnt lgkmcnt(0)
      ds_swizzle_b32 v20, v16 offset:swizzle(SWAP,16)
      ds_swizzle_b32 v21, v17 offset:swizzle(SWAP,16)
      ds_swizzle_b32 v22, v18 offset:swizzle(SWAP,16)
      ds_swizzle_b32 v23, v19 offset:swizzle(SWAP,16)
      s_waitcnt lgkmcnt(0)
      .if OB == 0
        v_wmma_f32_16x16x16_bf16 v[64:71], v[8:15], v[16:23], v[64:71]
      .else
        v_wmma_f32_16x16x16_bf16 v[72:79], v[8:15], v[16:23], v[72:79]
      .endif
      .set OB, OB+1
    .endr
    .set VT, VT+1
  .endr

  // Shared model scale applies to qh and Av after their FP32 sum.
  .set OR, 64
  .rept 16
    v_mul_f32_e32 v[OR], s24, v[OR]
    .set OR, OR+1
  .endr

  // C-layout row base and direct BF16 output stores.
  v_lshlrev_b32_e32 v6, 4, v2
  v_add_nc_u32_e32 v6, v6, v4
  .set OB, 0
  .rept 2
    .set WR, 0
    .rept 8
      .if OB == 0
        .set OREG, 64+WR
      .else
        .set OREG, 72+WR
      .endif
      v_lshrrev_b32_e32 v208, 16, v[OREG]
      v_and_b32_e32 v208, 1, v208
      v_add_nc_u32_e32 v209, 0x7fff, v[OREG]
      v_add_nc_u32_e32 v209, v208, v209
      v_lshrrev_b32_e32 v209, 16, v209
      v_add_nc_u32_e32 v202, (WR*2), v6
      v_add_nc_u32_e32 v202, s28, v202
      v_lshlrev_b32_e32 v204, 13, v202
      v_lshl_add_u32 v204, s26, 8, v204
      v_lshl_add_u32 v204, s2, 6, v204
      v_lshl_add_u32 v204, v3, 1, v204
      v_add_nc_u32_e32 v204, (OB*32), v204
      global_store_short v204, v209, s[18:19]
      .set WR, WR+1
    .endr
    .set OB, OB+1
  .endr
  s_endpgm

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel gdn_chunk_o_bv32_gskip_pipe8_gfx1151
.amdhsa_group_segment_fixed_size 25088
.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size 72
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_wavefront_size32 1
.amdhsa_enable_private_segment 0
.amdhsa_system_sgpr_workgroup_id_x 1
.amdhsa_system_sgpr_workgroup_id_y 1
.amdhsa_system_sgpr_workgroup_id_z 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_vgpr 240
.amdhsa_next_free_sgpr 46
.amdhsa_reserve_vcc 1
.amdhsa_float_denorm_mode_32 3
.amdhsa_float_denorm_mode_16_64 3
.amdhsa_dx10_clamp 1
.amdhsa_ieee_mode 1
.amdhsa_workgroup_processor_mode 0
.amdhsa_memory_ordered 1
.amdhsa_forward_progress 1
.end_amdhsa_kernel
.text
.Lfunc_end0:
.size gdn_chunk_o_bv32_gskip_pipe8_gfx1151, .Lfunc_end0-gdn_chunk_o_bv32_gskip_pipe8_gfx1151

.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: q, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: k, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: v, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: h, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: g, .offset: 32, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: o, .offset: 40, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: cu_seqlens, .offset: 48, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: chunk_indices, .offset: 56, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: scale, .offset: 64, .size: 4, .value_kind: by_value }
      - { .name: T, .offset: 68, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 25088
    .kernarg_segment_align: 8
    .kernarg_segment_size: 72
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 64
    .name: gdn_chunk_o_bv32_gskip_pipe8_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 46
    .sgpr_spill_count: 0
    .symbol: gdn_chunk_o_bv32_gskip_pipe8_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 240
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 0
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
