// SPDX-License-Identifier: MIT
// Handwritten gfx950 DSV4 control operation: prefill_indices_wide.
// ABI: sixteen 64-bit pointers followed by sixteen uint32 scalars (192 bytes).
// Caller supplies valid, non-aliasing tensors on the owning device/stream.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.protected netra_dsv4_prefill_indices_wide
.globl netra_dsv4_prefill_indices_wide
.p2align 8
.type netra_dsv4_prefill_indices_wide,@function
netra_dsv4_prefill_indices_wide:
    s_load_dwordx16 s[4:19], s[0:1], 0
    s_load_dwordx16 s[20:35], s[0:1], 64
    s_load_dwordx16 s[36:51], s[0:1], 128
    s_waitcnt lgkmcnt(0)
    // Four waves cooperate on one wide row; v0 retains the full thread index.
    v_lshrrev_b32 v23, 6, v0
    s_nop 4
    v_readfirstlane_b32 s62, v23
    s_nop 4
    s_mul_i32 s60, s2, s36
    s_load_dword s22, s[4:5], s60
    s_mul_i32 s60, s2, s37
    s_load_dword s23, s[6:7], s60
    s_mul_i32 s60, s2, s38
    s_load_dword s24, s[8:9], s60
    s_mul_i32 s60, s2, s39
    s_load_dword s25, s[10:11], s60
    s_lshl_b32 s60, s2, 2
    s_load_dwordx2 s[26:27], s[14:15], s60
    s_load_dword s28, s[16:17], s60
    s_waitcnt lgkmcnt(0)
    s_sub_i32 s32, s22, s23
    s_add_i32 s30, s32, 1
    s_min_i32 s30, s30, s41
    s_sub_i32 s31, s22, s41
    s_add_i32 s31, s31, 1
    s_max_i32 s31, s31, 0
    s_sub_i32 s29, s23, s31
    s_max_i32 s29, s29, 0
    s_min_i32 s29, s29, s41
    s_add_i32 s24, s24, s32
    s_sub_i32 s24, s24, s30
    s_add_i32 s24, s24, 1
    s_mul_i32 s60, s28, 4
    s_mul_hi_u32 s61, s28, 4
    s_add_u32 s20, s20, s60
    s_addc_u32 s21, s21, s61
    s_mul_i32 s60, s26, 4
    s_mul_hi_u32 s61, s26, 4
    s_add_u32 s18, s18, s60
    s_addc_u32 s19, s19, s61
    // Extend and previous-chunk SWA streams are disjoint and ragged.
    s_and_b32 s53, s30, -4
    v_lshlrev_b32 v1, 2, v0
.Lextend_quad:
    v_cmp_gt_u32 vcc, s53, v1
    s_and_saveexec_b64 s[58:59], vcc
    v_add_u32 v4, s24, v1
    v_add_u32 v5, 1, v4
    v_add_u32 v6, 2, v4
    v_add_u32 v7, 3, v4
    v_lshlrev_b32 v3, 2, v1
    global_store_dwordx4 v3, v[4:7], s[20:21]
    s_mov_b64 exec, s[58:59]
    v_add_u32 v1, 1024, v1
    v_cmp_gt_u32 vcc, s53, v1
    s_cbranch_vccnz .Lextend_quad
    v_add_u32 v1, s53, v0
    v_cmp_gt_u32 vcc, s30, v1
    s_and_saveexec_b64 s[58:59], vcc
    v_add_u32 v4, s24, v1
    v_lshlrev_b32 v3, 2, v1
    global_store_dword v3, v4, s[20:21]
    s_mov_b64 exec, s[58:59]
    s_mul_i32 s25, s25, s43
    v_mov_b32 v1, v0
.Lprefix:
    v_cmp_gt_u32 vcc, s29, v1
    s_and_saveexec_b64 s[58:59], vcc
    v_add_u32 v2, s31, v1
    v_mul_hi_u32 v3, s44, v2
    v_mul_lo_u32 v3, s43, v3
    v_sub_u32 v2, v2, v3
    v_sub_u32 v3, v2, s43
    v_cmp_ge_u32 vcc, v2, s43
    v_cndmask_b32 v2, v2, v3, vcc
    v_add_u32 v2, s25, v2
    v_lshlrev_b32 v3, 2, v1
    global_store_dword v3, v2, s[18:19]
    s_mov_b64 exec, s[58:59]
    v_add_u32 v1, 256, v1
    v_cmp_gt_u32 vcc, s29, v1
    s_cbranch_vccnz .Lprefix
    s_cmp_eq_u32 s40, 0
    s_cbranch_scc1 .Ldone
    s_sub_i32 s27, s27, s26
    s_sub_i32 s27, s27, s29
    s_lshl_b32 s52, s40, 2
    s_mul_i32 s60, s2, s52
    s_mul_hi_u32 s61, s2, s52
    s_add_u32 s12, s12, s60
    s_addc_u32 s13, s13, s61
    s_mul_i32 s60, s29, 4
    s_mul_hi_u32 s61, s29, 4
    s_add_u32 s18, s18, s60
    s_addc_u32 s19, s19, s61
    s_cmp_le_u32 s27, 64
    s_cbranch_scc1 .Lshort_compressed
    s_and_b32 s53, s27, -4
    v_lshlrev_b32 v1, 2, v0
.Lcompressed_quad:
    v_cmp_gt_u32 vcc, s53, v1
    s_and_saveexec_b64 s[58:59], vcc
    v_lshlrev_b32 v2, 2, v1
    global_load_dwordx4 v[4:7], v2, s[12:13]
    s_waitcnt vmcnt(0)
    v_add_u32 v4, s42, v4
    v_add_u32 v5, s42, v5
    v_add_u32 v6, s42, v6
    v_add_u32 v7, s42, v7
    global_store_dwordx4 v2, v[4:7], s[18:19]
    s_mov_b64 exec, s[58:59]
    v_add_u32 v1, 1024, v1
    v_cmp_gt_u32 vcc, s53, v1
    s_cbranch_vccnz .Lcompressed_quad
    v_add_u32 v1, s53, v0
    v_cmp_gt_u32 vcc, s27, v1
    s_and_saveexec_b64 s[58:59], vcc
    v_lshlrev_b32 v2, 2, v1
    global_load_dword v4, v2, s[12:13]
    s_waitcnt vmcnt(0)
    v_add_u32 v4, s42, v4
    global_store_dword v2, v4, s[18:19]
    s_mov_b64 exec, s[58:59]
    s_branch .Ldone
.Lshort_compressed:
    v_mov_b32 v1, v0
.Lcompressed:
    v_cmp_gt_u32 vcc, s27, v1
    s_and_saveexec_b64 s[58:59], vcc
    v_lshlrev_b32 v3, 2, v1
    global_load_dword v2, v3, s[12:13]
    s_waitcnt vmcnt(0)
    v_add_u32 v2, s42, v2
    global_store_dword v3, v2, s[18:19]
    s_mov_b64 exec, s[58:59]
    v_add_u32 v1, 256, v1
    v_cmp_gt_u32 vcc, s27, v1
    s_cbranch_vccnz .Lcompressed

.Ldone:
    s_endpgm
.Lend:
.size netra_dsv4_prefill_indices_wide, .Lend-netra_dsv4_prefill_indices_wide
.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel netra_dsv4_prefill_indices_wide
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
    .max_flat_workgroup_size: 256
    .name: netra_dsv4_prefill_indices_wide
    .private_segment_fixed_size: 0
    .sgpr_count: 64
    .sgpr_spill_count: 0
    .symbol: netra_dsv4_prefill_indices_wide.kd
    .vgpr_count: 24
    .vgpr_spill_count: 0
    .wavefront_size: 64
...
.end_amdgpu_metadata
