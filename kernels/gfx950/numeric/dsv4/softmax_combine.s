// SPDX-License-Identifier: MIT
// Handwritten gfx950 DSV4 control operation: softmax_combine.
// ABI: sixteen 64-bit pointers followed by sixteen uint32 scalars (192 bytes).
// Caller supplies valid, non-aliasing tensors on the owning device/stream.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.protected netra_dsv4_softmax_combine
.globl netra_dsv4_softmax_combine
.p2align 8
.type netra_dsv4_softmax_combine,@function
netra_dsv4_softmax_combine:
    s_load_dwordx16 s[4:19], s[0:1], 0
    s_load_dwordx16 s[20:35], s[0:1], 64
    s_load_dwordx16 s[36:51], s[0:1], 128
    s_waitcnt lgkmcnt(0)
    s_mul_i32 s52, s2, s36
    s_lshl_b32 s52, s52, 2
    v_lshlrev_b32 v2, 2, v0
    v_add_u32 v2, s52, v2
    v_mov_b32 v4, 0xff800000
    v_mov_b32 v5, 0
    v_mov_b32 v12, 0xff800000
    v_mov_b32 v13, 0
    v_cmp_gt_u32 vcc, s36, v0
    s_and_saveexec_b64 s[58:59], vcc
    global_load_dword v4, v2, s[4:5]
    global_load_dword v5, v2, s[6:7]
    s_mov_b64 exec, s[58:59]
    v_add_u32 v3, 64, v0
    v_cmp_gt_u32 vcc, s36, v3
    s_and_saveexec_b64 s[58:59], vcc
    global_load_dword v12, v2, s[4:5] offset:256
    global_load_dword v13, v2, s[6:7] offset:256
    s_waitcnt vmcnt(0)
    s_mov_b64 exec, s[58:59]
    v_max_f32 v8, v4, v12
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
    s_lshl_b32 s60, s2, 2
    v_mov_b32 v2, s60
    v_mov_b32 v8, s52
    global_store_dword v2, v8, s[8:9]
    s_mov_b64 exec, -1
    v_sub_f32 v4, v4, s52
    v_sub_f32 v12, v12, s52
    v_mul_f32 v4, 1.4426950408889634, v4
    v_mul_f32 v12, 1.4426950408889634, v12
    v_exp_f32 v4, v4
    v_nop
    s_nop 3
    v_exp_f32 v12, v12
    v_nop
    s_nop 3
    v_mul_f32 v5, v5, v4
    v_mul_f32 v13, v13, v12
    v_add_f32 v8, v5, v13
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
    s_mov_b64 exec, 1
    v_mov_b32 v4, s52
    v_rcp_f32 v4, v4
    v_nop
    s_nop 3
    global_store_dword v2, v4, s[10:11]

.Ldone:
    s_endpgm
.Lend:
.size netra_dsv4_softmax_combine, .Lend-netra_dsv4_softmax_combine
.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel netra_dsv4_softmax_combine
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
    .name: netra_dsv4_softmax_combine
    .private_segment_fixed_size: 0
    .sgpr_count: 64
    .sgpr_spill_count: 0
    .symbol: netra_dsv4_softmax_combine.kd
    .vgpr_count: 24
    .vgpr_spill_count: 0
    .wavefront_size: 64
...
.end_amdgpu_metadata
