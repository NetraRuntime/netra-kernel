// SPDX-License-Identifier: MIT
// Handwritten gfx950 DSV4 control operation: compressed_metadata.
// ABI: sixteen 64-bit pointers followed by sixteen uint32 scalars (192 bytes).
// Caller supplies valid, non-aliasing tensors on the owning device/stream.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.protected netra_dsv4_compressed_metadata
.globl netra_dsv4_compressed_metadata
.p2align 8
.type netra_dsv4_compressed_metadata,@function
netra_dsv4_compressed_metadata:
    s_load_dwordx16 s[4:19], s[0:1], 0
    s_load_dwordx16 s[20:35], s[0:1], 64
    s_load_dwordx16 s[36:51], s[0:1], 128
    s_waitcnt lgkmcnt(0)
    s_mul_i32 s60, s2, s36
    s_load_dword s52, s[4:5], s60
    s_mul_i32 s60, s2, s37
    s_load_dword s53, s[6:7], s60
    s_lshl_b32 s60, s2, 3
    s_load_dwordx2 s[54:55], s[8:9], s60
    s_waitcnt lgkmcnt(0)
    s_lshr_b64 s[56:57], s[54:55], 2
    s_and_b32 s58, s52, 3
    s_cmp_eq_u32 s58, 0
    s_cselect_b32 s56, s56, 0
    s_cselect_b32 s57, s57, 0
    v_mov_b32 v4, s56
    v_mov_b32 v5, s57
    s_and_b32 s58, s53, -4
    v_mov_b32 v6, s58
    s_lshr_b32 s58, s52, 2
    v_mov_b32 v7, s58
    s_max_u32 s58, s58, 1
    v_mov_b32 v8, s58
    s_lshr_b64 s[56:57], s[54:55], 7
    s_and_b32 s58, s52, 127
    s_cmp_eq_u32 s58, 0
    s_cselect_b32 s56, s56, 0
    s_cselect_b32 s57, s57, 0
    v_mov_b32 v10, s56
    v_mov_b32 v11, s57
    s_and_b32 s58, s53, -128
    v_mov_b32 v12, s58
    s_lshr_b32 s59, s52, 7
    v_mov_b32 v13, s59
    s_max_u32 s58, s59, 1
    v_mov_b32 v14, s58
    v_mov_b32 v1, s2
    v_lshlrev_b32 v2, 3, v1
    v_lshlrev_b32 v1, 2, v1
    s_mov_b64 exec, 1
    global_store_dwordx2 v2, v[4:5], s[12:13]
    global_store_dword v1, v6, s[14:15]
    global_store_dword v1, v7, s[16:17]
    global_store_dword v1, v8, s[18:19]
    global_store_dwordx2 v2, v[10:11], s[20:21]
    global_store_dword v1, v12, s[22:23]
    global_store_dword v1, v13, s[24:25]
    global_store_dword v1, v14, s[26:27]
    s_mov_b64 exec, -1
    s_cmp_eq_u32 s39, 0
    s_cbranch_scc1 .Ldone
    s_lshl_b32 s52, s38, 2
    s_mul_i32 s60, s2, s52
    s_mul_hi_u32 s61, s2, s52
    s_add_u32 s10, s10, s60
    s_addc_u32 s11, s11, s61
    s_lshl_b32 s52, s39, 2
    s_mul_i32 s60, s2, s52
    s_mul_hi_u32 s61, s2, s52
    s_add_u32 s28, s28, s60
    s_addc_u32 s29, s29, s61
    s_mov_b32 s52, 1
    s_lshl_b32 s52, s52, s40
    s_sub_u32 s52, s52, 1
    s_cmp_lt_u32 s39, 256
    s_cbranch_scc1 .Lscalar_pages
    s_and_b32 s53, s39, -4
    v_lshlrev_b32 v1, 2, v0
.Lquad_pages:
    v_cmp_gt_u32 vcc, s53, v1
    s_and_saveexec_b64 s[56:57], vcc
    v_lshrrev_b32 v2, s40, v1
    v_lshlrev_b32 v2, 2, v2
    s_cmp_eq_u32 s40, 0
    s_cbranch_scc1 .Lquad_page1
    s_cmp_eq_u32 s40, 1
    s_cbranch_scc1 .Lquad_page2
    global_load_dword v4, v2, s[10:11]
    s_waitcnt vmcnt(0)
    v_lshlrev_b32 v4, s40, v4
    v_and_b32 v3, s52, v1
    v_add_u32 v4, v4, v3
    v_add_u32 v5, 1, v4
    v_add_u32 v6, 2, v4
    v_add_u32 v7, 3, v4
    s_branch .Lquad_valid
.Lquad_page1:
    global_load_dwordx4 v[4:7], v2, s[10:11]
    s_waitcnt vmcnt(0)
    s_branch .Lquad_valid
.Lquad_page2:
    global_load_dwordx2 v[4:5], v2, s[10:11]
    s_waitcnt vmcnt(0)
    v_lshlrev_b32 v6, 1, v5
    v_add_u32 v7, 1, v6
    v_lshlrev_b32 v4, 1, v4
    v_add_u32 v5, 1, v4
.Lquad_valid:
    v_add_u32 v8, 0, v1
    v_cmp_gt_u32 vcc, s59, v8
    v_cndmask_b32 v4, -1, v4, vcc
    v_add_u32 v8, 1, v1
    v_cmp_gt_u32 vcc, s59, v8
    v_cndmask_b32 v5, -1, v5, vcc
    v_add_u32 v8, 2, v1
    v_cmp_gt_u32 vcc, s59, v8
    v_cndmask_b32 v6, -1, v6, vcc
    v_add_u32 v8, 3, v1
    v_cmp_gt_u32 vcc, s59, v8
    v_cndmask_b32 v7, -1, v7, vcc
    v_lshlrev_b32 v2, 2, v1
    global_store_dwordx4 v2, v[4:7], s[28:29]
    s_mov_b64 exec, s[56:57]
    v_add_u32 v1, 256, v1
    v_cmp_gt_u32 vcc, s53, v1
    s_cbranch_vccnz .Lquad_pages
    v_add_u32 v1, s53, v0
    s_branch .Lpages
.Lscalar_pages:
    v_mov_b32 v1, v0
.Lpages:
    v_lshrrev_b32 v2, s40, v1
    v_and_b32 v3, s52, v1
    v_mov_b32 v4, 0
    v_cmp_gt_u32 vcc, s39, v1
    s_and_saveexec_b64 s[56:57], vcc
    v_cmp_gt_u32 vcc, s38, v2
    s_and_saveexec_b64 s[54:55], vcc
    v_lshlrev_b32 v2, 2, v2
    global_load_dword v4, v2, s[10:11]
    s_waitcnt vmcnt(0)
    s_mov_b64 exec, s[54:55]
    v_lshlrev_b32 v4, s40, v4
    v_add_u32 v4, v4, v3
    v_cmp_gt_u32 vcc, s59, v1
    v_cndmask_b32 v4, -1, v4, vcc
    v_lshlrev_b32 v2, 2, v1
    global_store_dword v2, v4, s[28:29]
    s_mov_b64 exec, s[56:57]
    v_add_u32 v1, 64, v1
    v_cmp_gt_u32 vcc, s39, v1
    s_cbranch_vccnz .Lpages
.Ldone:
    s_endpgm
.Lend:
.size netra_dsv4_compressed_metadata, .Lend-netra_dsv4_compressed_metadata
.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel netra_dsv4_compressed_metadata
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
    .name: netra_dsv4_compressed_metadata
    .private_segment_fixed_size: 0
    .sgpr_count: 64
    .sgpr_spill_count: 0
    .symbol: netra_dsv4_compressed_metadata.kd
    .vgpr_count: 24
    .vgpr_spill_count: 0
    .wavefront_size: 64
...
.end_amdgpu_metadata
