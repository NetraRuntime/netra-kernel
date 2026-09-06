// SPDX-License-Identifier: MIT
// Handwritten gfx950 DSV4 control operation: rope_flat.
// ABI: sixteen 64-bit pointers followed by sixteen uint32 scalars (192 bytes).
// Caller supplies valid, non-aliasing tensors on the owning device/stream.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.protected netra_dsv4_rope_flat
.globl netra_dsv4_rope_flat
.p2align 8
.type netra_dsv4_rope_flat,@function
netra_dsv4_rope_flat:
    s_load_dwordx16 s[4:19], s[0:1], 0
    s_load_dwordx16 s[20:35], s[0:1], 64
    s_load_dwordx16 s[36:51], s[0:1], 128
    s_waitcnt lgkmcnt(0)
    s_lshl_b32 s52, s2, 6
    v_add_u32 v1, s52, v0
    v_cmp_gt_u32 vcc, s36, v1
    s_and_b64 exec, exec, vcc
    v_lshrrev_b32 v2, s38, v1
    v_lshrrev_b32 v3, s37, v2
    s_lshl_b32 s52, 1, s37
    s_sub_u32 s52, s52, 1
    v_and_b32 v2, s52, v2
    s_lshl_b32 s53, 1, s38
    s_sub_u32 s53, s53, 1
    v_and_b32 v1, s53, v1
    v_mul_lo_u32 v10, s39, v3
    v_mul_hi_u32 v11, s39, v3
    v_mul_lo_u32 v12, s40, v2
    v_mul_hi_u32 v13, s40, v2
    v_add_co_u32 v10, vcc, v10, v12
    v_addc_co_u32 v11, vcc, v11, v13, vcc
    v_lshlrev_b32 v2, 2, v1
    v_add_co_u32 v10, vcc, v10, v2
    v_addc_co_u32 v11, vcc, v11, 0, vcc
    v_mov_b32 v12, s5
    v_add_co_u32 v10, vcc, s4, v10
    v_addc_co_u32 v11, vcc, v11, v12, vcc
    global_load_dword v4, v[10:11], off
    s_cmp_eq_u32 s42, 0
    s_cbranch_scc1 .Lposition
    v_mul_lo_u32 v2, s41, v3
    global_load_dword v3, v2, s[8:9]
    s_waitcnt vmcnt(0)
.Lposition:
    v_mul_lo_u32 v12, s44, v3
    v_mul_hi_u32 v13, s44, v3
    v_lshlrev_b32 v2, 3, v1
    v_add_co_u32 v12, vcc, v12, v2
    v_addc_co_u32 v13, vcc, v13, 0, vcc
    v_mov_b32 v14, s7
    v_add_co_u32 v12, vcc, s6, v12
    v_addc_co_u32 v13, vcc, v13, v14, vcc
    global_load_dwordx2 v[6:7], v[12:13], off
    s_waitcnt vmcnt(0)
    v_and_b32 v5, 0xffff0000, v4
    v_lshlrev_b32 v4, 16, v4
    v_mul_f32 v8, v5, v7
    v_mul_f32 v9, v4, v7
    s_cmp_eq_u32 s43, 0
    s_cbranch_scc1 .Lforward
    v_xor_b32 v9, 0x80000000, v9
    s_branch .Lfma
.Lforward:
    v_xor_b32 v8, 0x80000000, v8
.Lfma:
    v_fma_f32 v8, v4, v6, v8
    v_fma_f32 v9, v5, v6, v9
    v_cvt_pk_bf16_f32 v4, v8, v9
    global_store_dword v[10:11], v4, off

.Ldone:
    s_endpgm
.Lend:
.size netra_dsv4_rope_flat, .Lend-netra_dsv4_rope_flat
.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel netra_dsv4_rope_flat
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
    .name: netra_dsv4_rope_flat
    .private_segment_fixed_size: 0
    .sgpr_count: 64
    .sgpr_spill_count: 0
    .symbol: netra_dsv4_rope_flat.kd
    .vgpr_count: 24
    .vgpr_spill_count: 0
    .wavefront_size: 64
...
.end_amdgpu_metadata
