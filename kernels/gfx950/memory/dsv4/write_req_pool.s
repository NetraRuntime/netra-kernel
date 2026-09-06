// SPDX-License-Identifier: MIT
// Handwritten gfx950 DSV4 control operation: write_req_pool.
// ABI: sixteen 64-bit pointers followed by sixteen uint32 scalars (192 bytes).
// Caller supplies valid, non-aliasing tensors on the owning device/stream.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.protected netra_dsv4_write_req_pool
.globl netra_dsv4_write_req_pool
.p2align 8
.type netra_dsv4_write_req_pool,@function
netra_dsv4_write_req_pool:
    s_load_dwordx16 s[4:19], s[0:1], 0
    s_load_dwordx16 s[20:35], s[0:1], 64
    s_load_dwordx16 s[36:51], s[0:1], 128
    s_waitcnt lgkmcnt(0)
    // A14 is log2(tiles/request), A13 is token stride. Each tile owns
    // disjoint token offsets; metadata output belongs only to tile zero.
    s_lshl_b32 s63, 1, s50
    s_sub_u32 s63, s63, 1
    s_and_b32 s63, s63, s2
    s_lshr_b32 s2, s2, s50
    s_lshl_b32 s63, s63, 6
    v_mov_b32 v1, v0
    v_mov_b32 v3, 0
.Lsum:
    v_mov_b32 v4, 0
    v_cmp_gt_u32 vcc, s2, v1
    s_and_saveexec_b64 s[58:59], vcc
    v_mul_lo_u32 v2, s40, v1
    global_load_dword v4, v2, s[14:15]
    s_waitcnt vmcnt(0)
    s_mov_b64 exec, s[58:59]
    v_add_u32 v3, v3, v4
    v_add_u32 v1, 64, v1
    v_cmp_gt_u32 vcc, s2, v1
    s_cbranch_vccnz .Lsum
    s_nop 1
    v_add_u32_dpp v3, v3, v3 quad_perm:[1,0,3,2]
    s_nop 1
    v_add_u32_dpp v3, v3, v3 quad_perm:[2,3,0,1]
    s_nop 1
    v_add_u32_dpp v3, v3, v3 row_shl:4 bound_ctrl:1
    s_nop 1
    v_add_u32_dpp v3, v3, v3 row_shl:8 bound_ctrl:1
    s_nop 1
    v_mov_b32 v20, v3
    s_nop 1
    v_permlane16_swap_b32 v3, v20
    s_nop 1
    v_add_u32 v3, v3, v20
    v_mov_b32 v20, v3
    s_nop 1
    v_permlane32_swap_b32 v3, v20
    s_nop 1
    v_add_u32 v3, v3, v20
    s_nop 4
    v_readfirstlane_b32 s52, v3
    s_nop 4
    s_mul_i32 s60, s2, s37
    s_load_dword s57, s[6:7], s60
    s_mul_i32 s60, s2, s38
    s_load_dword s53, s[10:11], s60
    s_mul_i32 s60, s2, s39
    s_load_dword s56, s[12:13], s60
    s_lshl_b32 s60, s2, 3
    s_load_dwordx2 s[54:55], s[8:9], s60
    s_waitcnt lgkmcnt(0)
    s_mul_i32 s60, s57, s36
    s_mul_hi_u32 s61, s57, s36
    s_lshl_b64 s[60:61], s[60:61], 2
    s_add_u32 s4, s4, s60
    s_addc_u32 s5, s5, s61
    s_mul_i32 s60, s52, 8
    s_mul_hi_u32 s61, s52, 8
    s_add_u32 s16, s16, s60
    s_addc_u32 s17, s17, s61
    v_add_u32 v1, s63, v0
.Lprefix_copy:
    v_cmp_gt_u32 vcc, s53, v1
    s_and_saveexec_b64 s[58:59], vcc
    v_lshlrev_b32 v2, 3, v1
    global_load_dword v4, v2, s[54:55]
    s_waitcnt vmcnt(0)
    v_lshlrev_b32 v2, 2, v1
    global_store_dword v2, v4, s[4:5]
    s_mov_b64 exec, s[58:59]
    v_add_u32 v1, s49, v1
    v_cmp_gt_u32 vcc, s53, v1
    s_cbranch_vccnz .Lprefix_copy
    s_sub_u32 s56, s56, s53
    s_mul_i32 s60, s53, 4
    s_mul_hi_u32 s61, s53, 4
    s_add_u32 s4, s4, s60
    s_addc_u32 s5, s5, s61
    v_add_u32 v1, s63, v0
.Lextend_copy:
    v_cmp_gt_u32 vcc, s56, v1
    s_and_saveexec_b64 s[58:59], vcc
    v_lshlrev_b32 v2, 3, v1
    global_load_dword v4, v2, s[16:17]
    s_waitcnt vmcnt(0)
    v_lshlrev_b32 v2, 2, v1
    global_store_dword v2, v4, s[4:5]
    s_mov_b64 exec, s[58:59]
    v_add_u32 v1, s49, v1
    v_cmp_gt_u32 vcc, s56, v1
    s_cbranch_vccnz .Lextend_copy

.Ldone:
    s_endpgm
.Lend:
.size netra_dsv4_write_req_pool, .Lend-netra_dsv4_write_req_pool
.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel netra_dsv4_write_req_pool
    .amdhsa_group_segment_fixed_size 0
    .amdhsa_private_segment_fixed_size 0
    .amdhsa_kernarg_size 192
    .amdhsa_user_sgpr_count 2
    .amdhsa_user_sgpr_kernarg_segment_ptr 1
    .amdhsa_enable_private_segment 0
    .amdhsa_system_sgpr_workgroup_id_x 1
    .amdhsa_system_sgpr_workgroup_id_y 1
    .amdhsa_system_vgpr_workitem_id 0
    .amdhsa_next_free_vgpr 24
    .amdhsa_accum_offset 24
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
    .name: netra_dsv4_write_req_pool
    .private_segment_fixed_size: 0
    .sgpr_count: 64
    .sgpr_spill_count: 0
    .symbol: netra_dsv4_write_req_pool.kd
    .vgpr_count: 24
    .vgpr_spill_count: 0
    .wavefront_size: 64
...
.end_amdgpu_metadata
