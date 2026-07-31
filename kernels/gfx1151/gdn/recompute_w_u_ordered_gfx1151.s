// SPDX-License-Identifier: MIT
// Raw gfx1151 Qwen3.6 GDN recompute W/U with A and RHS-fragment reuse across four output tiles.
// Fixed B1,T8192,H32,Hg16,K=V128,BT64. Grid=(128,32), block=64 wave32.

.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
.amdhsa_code_object_version 6
.text

// Preserve Triton's left-associated W scale: (k * beta) * exp(g), then BF16.
.macro SCALE_BF16_PAIR_W src
  v_lshlrev_b32_e32 v114, 16, \src
  v_and_b32_e32 v115, 0xffff0000, \src
  v_mul_f32_e32 v114, v112, v114
  v_mul_f32_e32 v115, v112, v115
  v_mul_f32_e32 v114, v113, v114
  v_mul_f32_e32 v115, v113, v115
  v_lshrrev_b32_e32 v116, 16, v114
  v_and_b32_e32 v116, 1, v116
  v_add_nc_u32_e32 v114, 0x7fff, v114
  v_add_nc_u32_e32 v114, v116, v114
  v_lshrrev_b32_e32 v114, 16, v114
  v_lshrrev_b32_e32 v116, 16, v115
  v_and_b32_e32 v116, 1, v116
  v_add_nc_u32_e32 v115, 0x7fff, v115
  v_add_nc_u32_e32 v115, v116, v115
  v_and_b32_e32 v115, 0xffff0000, v115
  v_or_b32_e32 \src, v114, v115
.endm

.macro SCALE_BF16_PAIR src
  v_lshlrev_b32_e32 v114, 16, \src
  v_and_b32_e32 v115, 0xffff0000, \src
  v_mul_f32_e32 v114, v112, v114
  v_mul_f32_e32 v115, v112, v115
  v_lshrrev_b32_e32 v116, 16, v114
  v_and_b32_e32 v116, 1, v116
  v_add_nc_u32_e32 v114, 0x7fff, v114
  v_add_nc_u32_e32 v114, v116, v114
  v_lshrrev_b32_e32 v114, 16, v114
  v_lshrrev_b32_e32 v116, 16, v115
  v_and_b32_e32 v116, 1, v116
  v_add_nc_u32_e32 v115, 0x7fff, v115
  v_add_nc_u32_e32 v115, v116, v115
  v_and_b32_e32 v115, 0xffff0000, v115
  v_or_b32_e32 \src, v114, v115
.endm

.macro LOAD_B_FRAGMENT_TO base, reg
  ds_load_u16 v[\reg], \base offset:0
  ds_load_u16_d16_hi v[\reg], \base offset:128
  ds_load_u16 v[\reg+1], \base offset:256
  ds_load_u16_d16_hi v[\reg+1], \base offset:384
  ds_load_u16 v[\reg+2], \base offset:512
  ds_load_u16_d16_hi v[\reg+2], \base offset:640
  ds_load_u16 v[\reg+3], \base offset:768
  ds_load_u16_d16_hi v[\reg+3], \base offset:896
  s_waitcnt lgkmcnt(0)
  ds_swizzle_b32 v[\reg+4], v[\reg] offset:swizzle(SWAP,16)
  ds_swizzle_b32 v[\reg+5], v[\reg+1] offset:swizzle(SWAP,16)
  ds_swizzle_b32 v[\reg+6], v[\reg+2] offset:swizzle(SWAP,16)
  ds_swizzle_b32 v[\reg+7], v[\reg+3] offset:swizzle(SWAP,16)
  s_waitcnt lgkmcnt(0)
.endm

.macro COMPUTE_TILE tile, is_w
  // The prior tile's second accumulator block aliases v96:v127.
  v_and_b32_e32 v96, 7, v0
  v_lshrrev_b32_e32 v97, 3, v0
  // Stage one transformed RHS[64,64] tile at LDS 8192.
  .if \is_w
    s_lshr_b32 s35, s3, 1
    s_lshl_b32 s35, s35, 8
    s_add_u32 s35, s35, ((\tile)-2)*128
    s_lshl_b32 s37, s3, 8
    s_add_u32 s37, s37, ((\tile)-2)*128
  .else
    s_lshl_b32 s35, s3, 8
    s_add_u32 s35, s35, (\tile)*128
    s_mov_b32 s37, s35
  .endif

  .set BR, 0
  .rept 8
    v_add_nc_u32_e32 v100, (BR*8), v97
    v_add_nc_u32_e32 v101, s27, v100
    .if \is_w
      v_lshlrev_b32_e32 v102, 12, v101
    .else
      v_lshlrev_b32_e32 v102, 13, v101
    .endif
    v_add_nc_u32_e32 v102, s35, v102
    v_lshl_add_u32 v102, v96, 4, v102
    .if \is_w
      global_load_b128 v[108:111], v102, s[8:9]
    .else
      global_load_b128 v[108:111], v102, s[10:11]
    .endif
    v_lshlrev_b32_e32 v104, 7, v101
    v_lshl_add_u32 v104, s3, 2, v104
    global_load_dword v112, v104, s[12:13]
    .if \is_w
      global_load_dword v113, v104, s[20:21]
    .endif
    s_waitcnt vmcnt(0)
    .if \is_w
      v_mul_f32_e32 v113, 0x3fb8aa3b, v113
      v_exp_f32_e32 v113, v113
      SCALE_BF16_PAIR_W v108
      SCALE_BF16_PAIR_W v109
      SCALE_BF16_PAIR_W v110
      SCALE_BF16_PAIR_W v111
    .else
      SCALE_BF16_PAIR v108
      SCALE_BF16_PAIR v109
      SCALE_BF16_PAIR v110
      SCALE_BF16_PAIR v111
    .endif
    v_lshlrev_b32_e32 v103, 7, v100
    v_lshl_add_u32 v103, v96, 4, v103
    v_add_nc_u32_e32 v103, 8192, v103
    ds_write_b128 v103, v[108:111]
    .set BR, BR+1
  .endr
  s_waitcnt lgkmcnt(0)
  s_barrier

  // Two 16-row fragments per wave and four 16-column fragments each.
  .set CR, 64
  .rept 64
    v_mov_b32_e32 v[CR], 0
    .set CR, CR+1
  .endr
  .set KT, 0
  .rept 4
    ds_load_b128 v[8:11], v5 offset:(KT*32)
    s_waitcnt lgkmcnt(0)
    ds_swizzle_b32 v12, v8 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v13, v9 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v14, v10 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v15, v11 offset:swizzle(SWAP,16)
    s_waitcnt lgkmcnt(0)
    .set OB, 0
    .rept 4
      v_lshlrev_b32_e32 v129, 10, v4
      v_lshl_add_u32 v129, v3, 1, v129
      v_add_nc_u32_e32 v129, (8192+KT*2048+OB*32), v129
      LOAD_B_FRAGMENT_TO v129, (24+OB*8)
      v_wmma_f32_16x16x16_bf16 v[64+OB*8:71+OB*8], v[8:15], v[24+OB*8:31+OB*8], v[64+OB*8:71+OB*8]
      .set OB, OB+1
    .endr

    ds_load_b128 v[8:11], v7 offset:(KT*32)
    s_waitcnt lgkmcnt(0)
    ds_swizzle_b32 v12, v8 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v13, v9 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v14, v10 offset:swizzle(SWAP,16)
    ds_swizzle_b32 v15, v11 offset:swizzle(SWAP,16)
    s_waitcnt lgkmcnt(0)
    .set OB, 0
    .rept 4
      v_wmma_f32_16x16x16_bf16 v[96+OB*8:103+OB*8], v[8:15], v[24+OB*8:31+OB*8], v[96+OB*8:103+OB*8]
      .set OB, OB+1
    .endr
    .set KT, KT+1
  .endr

  // Round and store this 64-column tile.
  .set RB, 0
  .rept 2
    .set OB, 0
    .rept 4
      .set RR, 0
      .rept 8
        .set OREG, 64+RB*32+OB*8+RR
        v_lshrrev_b32_e32 v130, 16, v[OREG]
        v_and_b32_e32 v130, 1, v130
        v_add_nc_u32_e32 v131, 0x7fff, v[OREG]
        v_add_nc_u32_e32 v131, v130, v131
        v_lshrrev_b32_e32 v131, 16, v131
        v_add_nc_u32_e32 v132, (RB*32+RR*2), v6
        v_add_nc_u32_e32 v133, s27, v132
        v_lshlrev_b32_e32 v134, 13, v133
        v_add_nc_u32_e32 v134, s37, v134
        v_lshl_add_u32 v134, v3, 1, v134
        v_add_nc_u32_e32 v134, (OB*32), v134
        .if \is_w
          global_store_short v134, v131, s[14:15]
        .else
          global_store_short v134, v131, s[16:17]
        .endif
        .set RR, RR+1
      .endr
      .set OB, OB+1
    .endr
    .set RB, RB+1
  .endr
  // Every wave must finish reading RHS before the next tile overwrites it.
  s_barrier
.endm

.protected recompute_w_u_reuse_a_ordered_gfx1151
.globl recompute_w_u_reuse_a_ordered_gfx1151
.p2align 8
.type recompute_w_u_reuse_a_ordered_gfx1151,@function
recompute_w_u_reuse_a_ordered_gfx1151:
  // k,v,beta,w,u,A,g,cu_seqlens,chunk_indices,T; s2=chunk, s3=head.
  s_clause 0x5
  s_load_b128 s[8:11], s[0:1], 0
  s_load_b128 s[12:15], s[0:1], 16
  s_load_b128 s[16:19], s[0:1], 32
  s_load_b128 s[20:23], s[0:1], 48
  s_load_b64 s[24:25], s[0:1], 64
  s_load_b32 s26, s[0:1], 72
  s_waitcnt lgkmcnt(0)

  s_lshl_b32 s27, s2, 6
  s_lshl_b32 s36, s3, 7
  v_and_b32_e32 v1, 31, v0
  v_lshrrev_b32_e32 v2, 5, v0
  v_and_b32_e32 v3, 15, v0
  v_lshrrev_b32_e32 v4, 4, v1
  v_and_b32_e32 v96, 7, v0
  v_lshrrev_b32_e32 v97, 3, v0

  // Load A[64,64] exactly once.
  .set AR, 0
  .rept 8
    v_add_nc_u32_e32 v100, (AR*8), v97
    v_add_nc_u32_e32 v101, s27, v100
    v_lshlrev_b32_e32 v102, 12, v101
    v_add_nc_u32_e32 v102, s36, v102
    v_lshl_add_u32 v102, v96, 4, v102
    global_load_b128 v[108:111], v102, s[18:19]
    s_waitcnt vmcnt(0)
    v_lshlrev_b32_e32 v103, 7, v100
    v_lshl_add_u32 v103, v96, 4, v103
    ds_write_b128 v103, v[108:111]
    .set AR, AR+1
  .endr
  s_waitcnt lgkmcnt(0)
  s_barrier

  v_lshlrev_b32_e32 v5, 11, v2
  v_lshl_add_u32 v5, v3, 7, v5
  v_lshl_add_u32 v5, v4, 4, v5
  v_add_nc_u32_e32 v7, 4096, v5
  v_lshlrev_b32_e32 v6, 4, v2
  v_add_nc_u32_e32 v6, v4, v6

  COMPUTE_TILE 0, 0
  COMPUTE_TILE 1, 0
  COMPUTE_TILE 2, 1
  COMPUTE_TILE 3, 1
  s_endpgm

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel recompute_w_u_reuse_a_ordered_gfx1151
.amdhsa_group_segment_fixed_size 16384
.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size 80
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_wavefront_size32 1
.amdhsa_enable_private_segment 0
.amdhsa_system_sgpr_workgroup_id_x 1
.amdhsa_system_sgpr_workgroup_id_y 1
.amdhsa_system_sgpr_workgroup_id_z 0
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_vgpr 135
.amdhsa_next_free_sgpr 40
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
.size recompute_w_u_reuse_a_ordered_gfx1151, .Lfunc_end0-recompute_w_u_reuse_a_ordered_gfx1151

.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: k, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: v, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: beta, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: w, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: u, .offset: 32, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: A, .offset: 40, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: g, .offset: 48, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: cu_seqlens, .offset: 56, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: chunk_indices, .offset: 64, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: T, .offset: 72, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 16384
    .kernarg_segment_align: 8
    .kernarg_segment_size: 80
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 64
    .name: recompute_w_u_reuse_a_ordered_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 40
    .sgpr_spill_count: 0
    .symbol: recompute_w_u_reuse_a_ordered_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 135
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
