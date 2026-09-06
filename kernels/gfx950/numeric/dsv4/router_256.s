// SPDX-License-Identifier: MIT
// Handwritten gfx950 DSV4 control operation: router_256.
// ABI: sixteen 64-bit pointers followed by sixteen uint32 scalars (192 bytes).
// Caller supplies valid, non-aliasing tensors on the owning device/stream.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.protected netra_dsv4_router_256
.globl netra_dsv4_router_256
.p2align 8
.type netra_dsv4_router_256,@function
netra_dsv4_router_256:
    s_load_dwordx8 s[4:11], s[0:1], 0
    s_load_dwordx8 s[36:43], s[0:1], 128
    s_load_dword s51, s[0:1], 188
    s_waitcnt lgkmcnt(0)
    s_mul_i32 s60, s2, 512
    s_mul_hi_u32 s61, s2, 512
    s_add_u32 s4, s4, s60
    s_addc_u32 s5, s5, s61
    s_lshl_b32 s52, s36, 2
    s_mul_i32 s60, s2, s52
    s_mul_hi_u32 s61, s2, s52
    s_add_u32 s8, s8, s60
    s_addc_u32 s9, s9, s61
    s_mul_i32 s60, s2, s52
    s_mul_hi_u32 s61, s2, s52
    s_add_u32 s10, s10, s60
    s_addc_u32 s11, s11, s61
    v_lshlrev_b32 v1, 3, v0
    global_load_dwordx2 v[24:25], v1, s[4:5]
    global_load_dwordx2 v[26:27], v1, s[6:7]
    s_waitcnt vmcnt(0)
    v_mov_b32 v22, -1.0e30
    v_lshlrev_b32 v4, 16, v24
    v_lshlrev_b32 v8, 16, v26
    v_and_b32 v5, 0xffff0000, v24
    v_and_b32 v9, 0xffff0000, v26
    v_lshlrev_b32 v6, 16, v25
    v_lshlrev_b32 v10, 16, v27
    v_and_b32 v7, 0xffff0000, v25
    v_and_b32 v11, 0xffff0000, v27
    // Interleave independent activation chains across the four experts.
    v_and_b32 v12, 0x7fffffff, v4
    v_mul_f32 v12, -1.4426950408889634, v12
    v_and_b32 v13, 0x7fffffff, v5
    v_mul_f32 v13, -1.4426950408889634, v13
    v_and_b32 v14, 0x7fffffff, v6
    v_mul_f32 v14, -1.4426950408889634, v14
    v_and_b32 v15, 0x7fffffff, v7
    v_mul_f32 v15, -1.4426950408889634, v15
    v_exp_f32 v12, v12
    v_exp_f32 v13, v13
    v_exp_f32 v14, v14
    v_exp_f32 v15, v15
    v_nop
    s_nop 3
    v_add_f32 v16, 1.0, v12
    v_add_f32 v17, 1.0, v13
    v_add_f32 v18, 1.0, v14
    v_add_f32 v19, 1.0, v15
    v_log_f32 v24, v16
    v_log_f32 v25, v17
    v_log_f32 v26, v18
    v_log_f32 v27, v19
    v_nop
    s_nop 3
    v_mul_f32 v24, 0.6931471805599453, v24
    v_sub_f32 v28, v16, 1.0
    v_cmp_eq_f32 vcc, 1.0, v16
    v_cndmask_b32 v28, v28, 1.0, vcc
    v_mul_f32 v25, 0.6931471805599453, v25
    v_sub_f32 v29, v17, 1.0
    v_cmp_eq_f32 vcc, 1.0, v17
    v_cndmask_b32 v29, v29, 1.0, vcc
    v_mul_f32 v26, 0.6931471805599453, v26
    v_sub_f32 v30, v18, 1.0
    v_cmp_eq_f32 vcc, 1.0, v18
    v_cndmask_b32 v30, v30, 1.0, vcc
    v_mul_f32 v27, 0.6931471805599453, v27
    v_sub_f32 v31, v19, 1.0
    v_cmp_eq_f32 vcc, 1.0, v19
    v_cndmask_b32 v31, v31, 1.0, vcc
    v_rcp_f32 v28, v28
    v_rcp_f32 v29, v29
    v_rcp_f32 v30, v30
    v_rcp_f32 v31, v31
    v_nop
    s_nop 3
    v_mul_f32 v24, v12, v24
    v_mul_f32 v24, v24, v28
    v_cmp_eq_f32 vcc, 1.0, v16
    v_cndmask_b32 v24, v24, v12, vcc
    v_max_f32 v4, 0, v4
    v_add_f32 v4, v4, v24
    v_mul_f32 v25, v13, v25
    v_mul_f32 v25, v25, v29
    v_cmp_eq_f32 vcc, 1.0, v17
    v_cndmask_b32 v25, v25, v13, vcc
    v_max_f32 v5, 0, v5
    v_add_f32 v5, v5, v25
    v_mul_f32 v26, v14, v26
    v_mul_f32 v26, v26, v30
    v_cmp_eq_f32 vcc, 1.0, v18
    v_cndmask_b32 v26, v26, v14, vcc
    v_max_f32 v6, 0, v6
    v_add_f32 v6, v6, v26
    v_mul_f32 v27, v15, v27
    v_mul_f32 v27, v27, v31
    v_cmp_eq_f32 vcc, 1.0, v19
    v_cndmask_b32 v27, v27, v15, vcc
    v_max_f32 v7, 0, v7
    v_add_f32 v7, v7, v27
    v_sqrt_f32 v4, v4
    v_sqrt_f32 v5, v5
    v_sqrt_f32 v6, v6
    v_sqrt_f32 v7, v7
    v_nop
    s_nop 3
    v_add_f32 v8, v4, v8
    v_cmp_eq_f32 vcc, v8, v8
    v_cndmask_b32 v8, v22, v8, vcc
    v_add_f32 v9, v5, v9
    v_cmp_eq_f32 vcc, v9, v9
    v_cndmask_b32 v9, v22, v9, vcc
    v_add_f32 v10, v6, v10
    v_cmp_eq_f32 vcc, v10, v10
    v_cndmask_b32 v10, v22, v10, vcc
    v_add_f32 v11, v7, v11
    v_cmp_eq_f32 vcc, v11, v11
    v_cndmask_b32 v11, v22, v11, vcc
    v_mov_b32 v21, 257
    v_mov_b32 v22, 0xff800000
    v_lshlrev_b32 v1, 2, v0
    // Keep selected weights in wave registers until the final normalized store.
    v_mov_b32 v24, 0
    v_mov_b32 v25, 0
    s_mov_b32 s56, 0
.Lselect:
    v_max_f32 v12, v8, v9
    v_max_f32 v13, v10, v11
    v_max_f32 v12, v12, v13
    s_nop 1
    v_max_f32_dpp v12, v12, v12 quad_perm:[1,0,3,2]
    s_nop 1
    v_max_f32_dpp v12, v12, v12 quad_perm:[2,3,0,1]
    s_nop 1
    v_max_f32_dpp v12, v12, v12 row_shl:4 bound_ctrl:1
    s_nop 1
    v_max_f32_dpp v12, v12, v12 row_shl:8 bound_ctrl:1
    s_nop 1
    v_mov_b32 v20, v12
    s_nop 1
    v_permlane16_swap_b32 v12, v20
    s_nop 1
    v_max_f32 v12, v12, v20
    s_nop 1
    v_mov_b32 v20, v12
    s_nop 1
    v_permlane32_swap_b32 v12, v20
    s_nop 1
    v_max_f32 v12, v12, v20
    s_nop 4
    v_readfirstlane_b32 s52, v12
    s_nop 4
    v_mov_b32 v13, 257
    v_add_u32 v14, 0, v1
    v_cmp_eq_f32 vcc, s52, v8
    v_cndmask_b32 v14, v21, v14, vcc
    v_min_u32 v13, v13, v14
    v_add_u32 v14, 1, v1
    v_cmp_eq_f32 vcc, s52, v9
    v_cndmask_b32 v14, v21, v14, vcc
    v_min_u32 v13, v13, v14
    v_add_u32 v14, 2, v1
    v_cmp_eq_f32 vcc, s52, v10
    v_cndmask_b32 v14, v21, v14, vcc
    v_min_u32 v13, v13, v14
    v_add_u32 v14, 3, v1
    v_cmp_eq_f32 vcc, s52, v11
    v_cndmask_b32 v14, v21, v14, vcc
    v_min_u32 v13, v13, v14
    // Resolve the local raw weight before the stable first-lane ballot.
    v_sub_u32 v27, v13, v1
    v_mov_b32 v26, v4
    v_cmp_eq_u32 vcc, v27, 1
    v_cndmask_b32 v26, v26, v5, vcc
    v_cmp_eq_u32 vcc, v27, 2
    v_cndmask_b32 v26, v26, v6, vcc
    v_cmp_eq_u32 vcc, v27, 3
    v_cndmask_b32 v26, v26, v7, vcc
    v_cmp_ne_u32 vcc, v13, v21
    s_nop 4
    s_ff1_i32_b64 s55, vcc
    v_readlane_b32 s53, v13, s55
    v_readlane_b32 s54, v26, s55
    s_nop 4
    // Hold IDs and weights until one coalesced final store per output.
    v_mov_b32 v14, s54
    v_mov_b32 v15, s53
    v_cmp_eq_u32 vcc, s56, v0
    v_cndmask_b32 v24, v24, v14, vcc
    v_cndmask_b32 v25, v25, v15, vcc
    v_add_u32 v14, 0, v1
    v_cmp_eq_u32 vcc, s53, v14
    v_cndmask_b32 v8, v8, v22, vcc
    v_add_u32 v14, 1, v1
    v_cmp_eq_u32 vcc, s53, v14
    v_cndmask_b32 v9, v9, v22, vcc
    v_add_u32 v14, 2, v1
    v_cmp_eq_u32 vcc, s53, v14
    v_cndmask_b32 v10, v10, v22, vcc
    v_add_u32 v14, 3, v1
    v_cmp_eq_u32 vcc, s53, v14
    v_cndmask_b32 v11, v11, v22, vcc
    s_add_u32 s56, s56, 1
    s_cmp_lt_u32 s56, s37
    s_cbranch_scc1 .Lselect
    v_mov_b32 v4, v24
    v_lshlrev_b32 v2, 2, v0
    v_mov_b32 v8, v4
    s_nop 1
    v_add_f32_dpp v8, v8, v8 quad_perm:[1,0,3,2]
    s_nop 1
    v_add_f32_dpp v8, v8, v8 quad_perm:[2,3,0,1]
    s_nop 1
    v_add_f32_dpp v8, v8, v8 row_shl:4 bound_ctrl:1
    s_nop 1
    v_add_f32_dpp v8, v8, v8 row_shl:8 bound_ctrl:1
    s_nop 1
    v_mov_b32 v20, v8
    s_nop 1
    v_permlane16_swap_b32 v8, v20
    s_nop 1
    v_add_f32 v8, v8, v20
    s_nop 1
    v_mov_b32 v20, v8
    s_nop 1
    v_permlane32_swap_b32 v8, v20
    s_nop 1
    v_add_f32 v8, v8, v20
    s_nop 4
    v_readfirstlane_b32 s52, v8
    s_nop 4
    v_mov_b32 v8, s52
    v_mov_b32 v9, s40
    v_rcp_f32 v9, v9
    v_nop
    s_nop 3
    v_mul_f32 v5, v8, v9
    v_cmp_gt_u32 vcc, s37, v0
    v_cndmask_b32 v4, v5, v4, vcc
    s_cmp_eq_u32 s38, 0
    s_cbranch_scc1 .Lskip_norm
    v_cmp_gt_f32 vcc, v8, 0
    v_cndmask_b32 v8, 1.0, v8, vcc
    v_rcp_f32 v8, v8
    v_nop
    s_nop 3
    v_mul_f32 v4, v4, v8
.Lskip_norm:
    s_cmp_eq_u32 s39, 0
    s_cbranch_scc1 .Lskip_scale
    v_mul_f32 v4, s40, v4
.Lskip_scale:
    v_cmp_gt_u32 vcc, s36, v0
    s_and_b64 exec, exec, vcc
    global_store_dword v2, v4, s[8:9]
    v_sub_u32 v4, v0, s37
    v_add_u32 v4, 256, v4
    v_cmp_lt_u32 vcc, v0, s37
    v_cndmask_b32 v4, v4, v25, vcc
    global_store_dword v2, v4, s[10:11]

.Ldone:
    s_endpgm
.Lend:
.size netra_dsv4_router_256, .Lend-netra_dsv4_router_256
.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel netra_dsv4_router_256
    .amdhsa_group_segment_fixed_size 0
    .amdhsa_private_segment_fixed_size 0
    .amdhsa_kernarg_size 192
    .amdhsa_user_sgpr_count 2
    .amdhsa_user_sgpr_kernarg_segment_ptr 1
    .amdhsa_enable_private_segment 0
    .amdhsa_system_sgpr_workgroup_id_x 1
    .amdhsa_system_sgpr_workgroup_id_y 1
    .amdhsa_system_vgpr_workitem_id 0
    .amdhsa_next_free_vgpr 32
    .amdhsa_accum_offset 32
    .amdhsa_next_free_sgpr 64
    .amdhsa_reserve_vcc 1
    .amdhsa_float_round_mode_32 0
    .amdhsa_float_denorm_mode_32 3
    .amdhsa_dx10_clamp 1
    .amdhsa_ieee_mode 1
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1, 2]
amdhsa.kernels:
  - .args:
      - {.name: p0, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global}
      - {.name: p1, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global}
      - {.name: p2, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global}
      - {.name: p3, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global}
      - {.name: p4, .offset: 32, .size: 8, .value_kind: global_buffer, .address_space: global}
      - {.name: p5, .offset: 40, .size: 8, .value_kind: global_buffer, .address_space: global}
      - {.name: p6, .offset: 48, .size: 8, .value_kind: global_buffer, .address_space: global}
      - {.name: p7, .offset: 56, .size: 8, .value_kind: global_buffer, .address_space: global}
      - {.name: p8, .offset: 64, .size: 8, .value_kind: global_buffer, .address_space: global}
      - {.name: p9, .offset: 72, .size: 8, .value_kind: global_buffer, .address_space: global}
      - {.name: p10, .offset: 80, .size: 8, .value_kind: global_buffer, .address_space: global}
      - {.name: p11, .offset: 88, .size: 8, .value_kind: global_buffer, .address_space: global}
      - {.name: p12, .offset: 96, .size: 8, .value_kind: global_buffer, .address_space: global}
      - {.name: p13, .offset: 104, .size: 8, .value_kind: global_buffer, .address_space: global}
      - {.name: p14, .offset: 112, .size: 8, .value_kind: global_buffer, .address_space: global}
      - {.name: p15, .offset: 120, .size: 8, .value_kind: global_buffer, .address_space: global}
      - {.name: a0, .offset: 128, .size: 4, .value_kind: by_value}
      - {.name: a1, .offset: 132, .size: 4, .value_kind: by_value}
      - {.name: a2, .offset: 136, .size: 4, .value_kind: by_value}
      - {.name: a3, .offset: 140, .size: 4, .value_kind: by_value}
      - {.name: a4, .offset: 144, .size: 4, .value_kind: by_value}
      - {.name: a5, .offset: 148, .size: 4, .value_kind: by_value}
      - {.name: a6, .offset: 152, .size: 4, .value_kind: by_value}
      - {.name: a7, .offset: 156, .size: 4, .value_kind: by_value}
      - {.name: a8, .offset: 160, .size: 4, .value_kind: by_value}
      - {.name: a9, .offset: 164, .size: 4, .value_kind: by_value}
      - {.name: a10, .offset: 168, .size: 4, .value_kind: by_value}
      - {.name: a11, .offset: 172, .size: 4, .value_kind: by_value}
      - {.name: a12, .offset: 176, .size: 4, .value_kind: by_value}
      - {.name: a13, .offset: 180, .size: 4, .value_kind: by_value}
      - {.name: a14, .offset: 184, .size: 4, .value_kind: by_value}
      - {.name: a15, .offset: 188, .size: 4, .value_kind: by_value}
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 192
    .max_flat_workgroup_size: 64
    .name: netra_dsv4_router_256
    .private_segment_fixed_size: 0
    .sgpr_count: 64
    .sgpr_spill_count: 0
    .symbol: netra_dsv4_router_256.kd
    .vgpr_count: 32
    .vgpr_spill_count: 0
    .wavefront_size: 64
...
.end_amdgpu_metadata
