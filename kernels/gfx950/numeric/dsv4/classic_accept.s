// SPDX-License-Identifier: MIT
// Handwritten gfx950 DSV4 control operation: classic_accept.
// ABI: sixteen 64-bit pointers followed by sixteen uint32 scalars (192 bytes).
// Caller supplies valid, non-aliasing tensors on the owning device/stream.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.protected netra_dsv4_classic_accept
.globl netra_dsv4_classic_accept
.p2align 8
.type netra_dsv4_classic_accept,@function
netra_dsv4_classic_accept:
    s_load_dwordx16 s[4:19], s[0:1], 0
    s_load_dwordx16 s[20:35], s[0:1], 64
    s_load_dwordx16 s[36:51], s[0:1], 128
    s_waitcnt lgkmcnt(0)
    s_mul_i32 s60, s2, s45
    s_mul_hi_u32 s61, s2, s45
    s_add_u32 s6, s6, s60
    s_addc_u32 s7, s7, s61
    s_mul_i32 s60, s2, s38
    s_mul_hi_u32 s61, s2, s38
    s_add_u32 s10, s10, s60
    s_addc_u32 s11, s11, s61
    s_mul_i32 s60, s2, s39
    s_mul_hi_u32 s61, s2, s39
    s_add_u32 s12, s12, s60
    s_addc_u32 s13, s13, s61
    s_mul_i32 s60, s2, s40
    s_mul_hi_u32 s61, s2, s40
    s_add_u32 s14, s14, s60
    s_addc_u32 s15, s15, s61
    s_mul_i32 s60, s2, s41
    s_mul_hi_u32 s61, s2, s41
    s_add_u32 s18, s18, s60
    s_addc_u32 s19, s19, s61
    s_mul_i32 s60, s2, s43
    s_mul_hi_u32 s61, s2, s43
    s_add_u32 s20, s20, s60
    s_addc_u32 s21, s21, s61
    s_mul_i32 s60, s2, 16
    s_mul_hi_u32 s61, s2, 16
    s_add_u32 s22, s22, s60
    s_addc_u32 s23, s23, s61
    s_load_dword s53, s[12:13], 0
    s_waitcnt lgkmcnt(0)
    s_mov_b64 exec, 1
    v_mov_b32 v2, 0
    v_mov_b32 v4, s53
    global_store_dword v2, v4, s[6:7]
    s_mov_b32 s52, 0
    s_mov_b32 s54, 1
    s_mov_b32 s55, 1
.Lverify:
    s_cmp_ge_u32 s54, s36
    s_cbranch_scc1 .Lverified
    s_lshl_b32 s60, s54, 3
    s_load_dword s56, s[10:11], s60
    s_sub_u32 s60, s54, 1
    s_lshl_b32 s60, s60, 2
    s_load_dword s57, s[14:15], s60
    s_waitcnt lgkmcnt(0)
    s_lshl_b32 s61, s56, 2
    s_mul_i32 s60, s52, s42
    s_add_u32 s60, s60, s61
    s_load_dword s58, s[18:19], s60
    s_mul_i32 s60, s52, s44
    s_add_u32 s60, s60, s61
    s_load_dword s59, s[20:21], s60
    s_waitcnt lgkmcnt(0)
    v_mov_b32 v4, s58
    v_mov_b32 v5, s59
    v_mov_b32 v6, s57
    v_mul_f32 v5, v5, v6
    v_cmp_gt_f32 vcc, v4, v5
    s_cbranch_vccz .Lrejected
    s_lshl_b32 s60, s53, 2
    v_mov_b32 v2, s60
    v_mov_b32 v4, s56
    global_store_dword v2, v4, s[4:5]
    s_lshl_b32 s60, s54, 3
    s_load_dword s53, s[12:13], s60
    s_waitcnt lgkmcnt(0)
    s_lshl_b32 s60, s54, 2
    v_mov_b32 v2, s60
    v_mov_b32 v4, s53
    global_store_dword v2, v4, s[6:7]
    s_mov_b32 s52, s54
    s_add_u32 s54, s54, 1
    s_branch .Lverify
.Lrejected:
    s_mov_b32 s55, 0
.Lverified:
    s_sub_u32 s54, s54, 1
    s_lshl_b32 s60, s2, 2
    v_mov_b32 v2, s60
    v_mov_b32 v4, s54
    global_store_dword v2, v4, s[8:9]
    s_lshl_b32 s60, s53, 2
    v_mov_b32 v2, s60
    s_sub_u32 s60, s37, 1
    v_mov_b32 v4, s60
    global_store_dword v2, v4, s[4:5]
    v_mov_b32 v2, 0
    v_mov_b32 v4, s52
    v_mov_b32 v5, s53
    v_mov_b32 v6, s55
    v_mov_b32 v7, 0
    global_store_dwordx4 v2, v[4:7], s[22:23]

.Ldone:
    s_endpgm
.Lend:
.size netra_dsv4_classic_accept, .Lend-netra_dsv4_classic_accept
.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel netra_dsv4_classic_accept
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
    .name: netra_dsv4_classic_accept
    .private_segment_fixed_size: 0
    .sgpr_count: 64
    .sgpr_spill_count: 0
    .symbol: netra_dsv4_classic_accept.kd
    .vgpr_count: 24
    .vgpr_spill_count: 0
    .wavefront_size: 64
...
.end_amdgpu_metadata
