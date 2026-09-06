// SPDX-License-Identifier: MIT
// Handwritten gfx950 DSV4 control operation: online_partial_1024.
// ABI: sixteen 64-bit pointers followed by sixteen uint32 scalars (192 bytes).
// Caller supplies valid, non-aliasing tensors on the owning device/stream.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.protected netra_dsv4_online_partial_1024
.globl netra_dsv4_online_partial_1024
.p2align 8
.type netra_dsv4_online_partial_1024,@function
netra_dsv4_online_partial_1024:
    s_load_dwordx16 s[4:19], s[0:1], 0
    s_load_dwordx16 s[20:35], s[0:1], 64
    s_load_dwordx16 s[36:51], s[0:1], 128
    s_waitcnt lgkmcnt(0)
    // Four waves per 1024-logit tile. Keep scores/noise in registers.
    s_mov_b32 s63, s2
    v_lshrrev_b32 v23, 6, v0
    s_nop 4
    v_readfirstlane_b32 s62, v23
    s_nop 4
    s_cmp_eq_u32 s38, 1
    s_cbranch_scc1 .Lone_tile
    s_mul_hi_u32 s52, s2, s39
    s_mul_i32 s53, s52, s38
    s_sub_u32 s53, s2, s53
    s_cmp_lt_u32 s53, s38
    s_cbranch_scc1 .Ldivided
    s_add_u32 s52, s52, 1
    s_sub_u32 s53, s53, s38
    s_branch .Ldivided
.Lone_tile:
    s_mov_b32 s52, s2
    s_mov_b32 s53, 0
.Ldivided:
    s_mov_b32 s2, s52
    s_lshl_b32 s60, s2, 2
    s_load_dword s54, s[6:7], s60
    s_load_dword s55, s[8:9], s60
    s_mul_i32 s60, s2, s37
    s_mul_hi_u32 s61, s2, s37
    s_add_u32 s4, s4, s60
    s_addc_u32 s5, s5, s61
    s_lshl_b32 s56, s36, 2
    s_mul_i32 s60, s2, s56
    s_mul_hi_u32 s61, s2, s56
    s_add_u32 s10, s10, s60
    s_addc_u32 s11, s11, s61
    s_waitcnt lgkmcnt(0)
    v_mov_b32 v16, s54
    v_rcp_f32 v16, v16
    v_nop
    s_nop 3
    s_lshl_b32 s53, s53, 10
    v_add_u32 v18, s53, v0
    v_mov_b32 v24, 0xff800000
    v_mov_b32 v28, 1.0
    v_add_u32 v1, 0, v18
    v_cmp_gt_u32 vcc, s36, v1
    s_and_saveexec_b64 s[58:59], vcc
    v_lshlrev_b32 v2, 2, v1
    global_load_dword v24, v2, s[4:5]
    s_cmp_lg_u32 s55, 0
    s_cbranch_scc1 .Lgreedy0
    global_load_dword v28, v2, s[10:11]
.Lgreedy0:
    s_mov_b64 exec, s[58:59]
    v_mov_b32 v25, 0xff800000
    v_mov_b32 v29, 1.0
    v_add_u32 v1, 256, v18
    v_cmp_gt_u32 vcc, s36, v1
    s_and_saveexec_b64 s[58:59], vcc
    v_lshlrev_b32 v2, 2, v1
    global_load_dword v25, v2, s[4:5]
    s_cmp_lg_u32 s55, 0
    s_cbranch_scc1 .Lgreedy1
    global_load_dword v29, v2, s[10:11]
.Lgreedy1:
    s_mov_b64 exec, s[58:59]
    v_mov_b32 v26, 0xff800000
    v_mov_b32 v30, 1.0
    v_add_u32 v1, 512, v18
    v_cmp_gt_u32 vcc, s36, v1
    s_and_saveexec_b64 s[58:59], vcc
    v_lshlrev_b32 v2, 2, v1
    global_load_dword v26, v2, s[4:5]
    s_cmp_lg_u32 s55, 0
    s_cbranch_scc1 .Lgreedy2
    global_load_dword v30, v2, s[10:11]
.Lgreedy2:
    s_mov_b64 exec, s[58:59]
    v_mov_b32 v27, 0xff800000
    v_mov_b32 v31, 1.0
    v_add_u32 v1, 768, v18
    v_cmp_gt_u32 vcc, s36, v1
    s_and_saveexec_b64 s[58:59], vcc
    v_lshlrev_b32 v2, 2, v1
    global_load_dword v27, v2, s[4:5]
    s_cmp_lg_u32 s55, 0
    s_cbranch_scc1 .Lgreedy3
    global_load_dword v31, v2, s[10:11]
.Lgreedy3:
    s_mov_b64 exec, s[58:59]
    s_waitcnt vmcnt(0)
    v_mul_f32 v24, v24, v16
    v_mul_f32 v25, v25, v16
    v_mul_f32 v26, v26, v16
    v_mul_f32 v27, v27, v16
    v_max_f32 v8, v24, v25
    v_max_f32 v9, v26, v27
    v_max_f32 v8, v8, v9
    s_nop 1
    v_max_f32_dpp v8, v8, v8 quad_perm:[1,0,3,2]
    s_nop 1
    v_max_f32_dpp v8, v8, v8 quad_perm:[2,3,0,1]
    s_nop 1
    v_max_f32_dpp v8, v8, v8 row_shl:4 bound_ctrl:1
    s_nop 1
    v_max_f32_dpp v8, v8, v8 row_shl:8 bound_ctrl:1
    s_nop 1
    v_mov_b32 v20, v8
    s_nop 1
    v_permlane16_swap_b32 v8, v20
    s_nop 1
    v_max_f32 v8, v8, v20
    s_nop 1
    v_mov_b32 v20, v8
    s_nop 1
    v_permlane32_swap_b32 v8, v20
    s_nop 1
    v_max_f32 v8, v8, v20
    s_nop 4
    v_readfirstlane_b32 s52, v8
    s_nop 4
    s_mov_b64 exec, 1
    s_lshl_b32 s60, s62, 2
    v_mov_b32 v2, s60
    v_mov_b32 v4, s52
    ds_write_b32 v2, v4 offset:0
    s_waitcnt lgkmcnt(0)
    s_mov_b64 exec, -1
    s_barrier
    s_mov_b64 exec, 1
    v_mov_b32 v2, 0
    ds_read_b128 v[4:7], v2 offset:0
    s_waitcnt lgkmcnt(0)
    v_max_f32 v4, v4, v5
    v_max_f32 v6, v6, v7
    v_max_f32 v4, v4, v6
    s_nop 4
    v_readfirstlane_b32 s52, v4
    s_nop 4
    s_mov_b64 exec, -1
    s_cmp_lg_u32 s62, 0
    s_cbranch_scc1 .Lskip_max
    s_mov_b64 exec, 1
    s_lshl_b32 s60, s63, 2
    v_mov_b32 v2, s60
    v_mov_b32 v4, s52
    global_store_dword v2, v4, s[12:13]
    s_mov_b64 exec, -1
.Lskip_max:
    v_sub_f32 v24, v24, s52
    v_mul_f32 v24, 1.4426950408889634, v24
    v_exp_f32 v24, v24
    v_nop
    s_nop 3
    v_rcp_f32 v28, v28
    v_nop
    s_nop 3
    v_mul_f32 v24, v24, v28
    v_add_u32 v1, 0, v18
    v_cmp_gt_u32 vcc, s36, v1
    v_cndmask_b32 v24, -1.0, v24, vcc
    v_sub_f32 v25, v25, s52
    v_mul_f32 v25, 1.4426950408889634, v25
    v_exp_f32 v25, v25
    v_nop
    s_nop 3
    v_rcp_f32 v29, v29
    v_nop
    s_nop 3
    v_mul_f32 v25, v25, v29
    v_add_u32 v1, 256, v18
    v_cmp_gt_u32 vcc, s36, v1
    v_cndmask_b32 v25, -1.0, v25, vcc
    v_sub_f32 v26, v26, s52
    v_mul_f32 v26, 1.4426950408889634, v26
    v_exp_f32 v26, v26
    v_nop
    s_nop 3
    v_rcp_f32 v30, v30
    v_nop
    s_nop 3
    v_mul_f32 v26, v26, v30
    v_add_u32 v1, 512, v18
    v_cmp_gt_u32 vcc, s36, v1
    v_cndmask_b32 v26, -1.0, v26, vcc
    v_sub_f32 v27, v27, s52
    v_mul_f32 v27, 1.4426950408889634, v27
    v_exp_f32 v27, v27
    v_nop
    s_nop 3
    v_rcp_f32 v31, v31
    v_nop
    s_nop 3
    v_mul_f32 v27, v27, v31
    v_add_u32 v1, 768, v18
    v_cmp_gt_u32 vcc, s36, v1
    v_cndmask_b32 v27, -1.0, v27, vcc
    v_max_f32 v8, v24, v25
    v_max_f32 v9, v26, v27
    v_max_f32 v8, v8, v9
    s_nop 1
    v_max_f32_dpp v8, v8, v8 quad_perm:[1,0,3,2]
    s_nop 1
    v_max_f32_dpp v8, v8, v8 quad_perm:[2,3,0,1]
    s_nop 1
    v_max_f32_dpp v8, v8, v8 row_shl:4 bound_ctrl:1
    s_nop 1
    v_max_f32_dpp v8, v8, v8 row_shl:8 bound_ctrl:1
    s_nop 1
    v_mov_b32 v20, v8
    s_nop 1
    v_permlane16_swap_b32 v8, v20
    s_nop 1
    v_max_f32 v8, v8, v20
    s_nop 1
    v_mov_b32 v20, v8
    s_nop 1
    v_permlane32_swap_b32 v8, v20
    s_nop 1
    v_max_f32 v8, v8, v20
    s_nop 4
    v_readfirstlane_b32 s52, v8
    s_nop 4
    s_mov_b64 exec, 1
    s_lshl_b32 s60, s62, 2
    v_mov_b32 v2, s60
    v_mov_b32 v4, s52
    ds_write_b32 v2, v4 offset:16
    s_waitcnt lgkmcnt(0)
    s_mov_b64 exec, -1
    s_barrier
    s_mov_b64 exec, 1
    v_mov_b32 v2, 0
    ds_read_b128 v[4:7], v2 offset:16
    s_waitcnt lgkmcnt(0)
    v_max_f32 v4, v4, v5
    v_max_f32 v6, v6, v7
    v_max_f32 v4, v4, v6
    s_nop 4
    v_readfirstlane_b32 s52, v4
    s_nop 4
    s_mov_b64 exec, -1
    s_cmp_lg_u32 s62, 0
    s_cbranch_scc1 .Lskip_key
    s_mov_b64 exec, 1
    s_lshl_b32 s60, s63, 2
    v_mov_b32 v2, s60
    v_mov_b32 v4, s52
    global_store_dword v2, v4, s[14:15]
    s_mov_b64 exec, -1
.Lskip_key:
    v_mov_b32 v8, 0x7fffffff
    v_mov_b32 v9, 0x7fffffff
    v_add_u32 v1, 0, v18
    v_cmp_eq_f32 vcc, s52, v24
    v_cndmask_b32 v1, v9, v1, vcc
    v_min_u32 v8, v8, v1
    v_add_u32 v1, 256, v18
    v_cmp_eq_f32 vcc, s52, v25
    v_cndmask_b32 v1, v9, v1, vcc
    v_min_u32 v8, v8, v1
    v_add_u32 v1, 512, v18
    v_cmp_eq_f32 vcc, s52, v26
    v_cndmask_b32 v1, v9, v1, vcc
    v_min_u32 v8, v8, v1
    v_add_u32 v1, 768, v18
    v_cmp_eq_f32 vcc, s52, v27
    v_cndmask_b32 v1, v9, v1, vcc
    v_min_u32 v8, v8, v1
    s_nop 1
    v_min_u32_dpp v8, v8, v8 quad_perm:[1,0,3,2]
    s_nop 1
    v_min_u32_dpp v8, v8, v8 quad_perm:[2,3,0,1]
    s_nop 1
    v_min_u32_dpp v8, v8, v8 row_shl:4 bound_ctrl:1
    s_nop 1
    v_min_u32_dpp v8, v8, v8 row_shl:8 bound_ctrl:1
    s_nop 1
    v_mov_b32 v20, v8
    s_nop 1
    v_permlane16_swap_b32 v8, v20
    s_nop 1
    v_min_u32 v8, v8, v20
    s_nop 1
    v_mov_b32 v20, v8
    s_nop 1
    v_permlane32_swap_b32 v8, v20
    s_nop 1
    v_min_u32 v8, v8, v20
    s_nop 4
    v_readfirstlane_b32 s52, v8
    s_nop 4
    s_mov_b64 exec, 1
    s_lshl_b32 s60, s62, 2
    v_mov_b32 v2, s60
    v_mov_b32 v4, s52
    ds_write_b32 v2, v4 offset:32
    s_waitcnt lgkmcnt(0)
    s_mov_b64 exec, -1
    s_barrier
    s_mov_b64 exec, 1
    v_mov_b32 v2, 0
    ds_read_b128 v[4:7], v2 offset:32
    s_waitcnt lgkmcnt(0)
    v_min_u32 v4, v4, v5
    v_min_u32 v6, v6, v7
    v_min_u32 v4, v4, v6
    s_nop 4
    v_readfirstlane_b32 s52, v4
    s_nop 4
    s_mov_b64 exec, -1
    s_cmp_lg_u32 s62, 0
    s_cbranch_scc1 .Lskip_index
    s_mov_b64 exec, 1
    s_lshl_b32 s60, s63, 2
    v_mov_b32 v2, s60
    v_mov_b32 v4, s52
    global_store_dword v2, v4, s[16:17]
    s_mov_b64 exec, -1
.Lskip_index:

.Ldone:
    s_endpgm
.Lend:
.size netra_dsv4_online_partial_1024, .Lend-netra_dsv4_online_partial_1024
.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel netra_dsv4_online_partial_1024
    .amdhsa_group_segment_fixed_size 48
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
    .group_segment_fixed_size: 48
    .kernarg_segment_align: 8
    .kernarg_segment_size: 192
    .max_flat_workgroup_size: 256
    .name: netra_dsv4_online_partial_1024
    .private_segment_fixed_size: 0
    .sgpr_count: 64
    .sgpr_spill_count: 0
    .symbol: netra_dsv4_online_partial_1024.kd
    .vgpr_count: 32
    .vgpr_spill_count: 0
    .wavefront_size: 64
...
.end_amdgpu_metadata
