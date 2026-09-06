// SPDX-License-Identifier: MIT
// Handwritten gfx950 DSV4 control operation: classic_tile_sum.
// ABI: sixteen 64-bit pointers followed by sixteen uint32 scalars (192 bytes).
// Caller supplies valid, non-aliasing tensors on the owning device/stream.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.protected netra_dsv4_classic_tile_sum
.globl netra_dsv4_classic_tile_sum
.p2align 8
.type netra_dsv4_classic_tile_sum,@function
netra_dsv4_classic_tile_sum:
    s_load_dwordx16 s[4:19], s[0:1], 0
    s_load_dwordx16 s[20:35], s[0:1], 64
    s_load_dwordx16 s[36:51], s[0:1], 128
    s_waitcnt lgkmcnt(0)
    s_mov_b32 s28, s2
    v_lshrrev_b32 v23, 6, v0
    s_nop 4
    v_readfirstlane_b32 s62, v23
    s_nop 4
    s_cmp_eq_u32 s46, 1
    s_cbranch_scc1 .Lone_tile
    s_mul_hi_u32 s52, s2, s47
    s_mul_i32 s29, s52, s46
    s_sub_u32 s29, s2, s29
    s_cmp_lt_u32 s29, s46
    s_cbranch_scc1 .Ldivided
    s_add_u32 s52, s52, 1
    s_sub_u32 s29, s29, s46
    s_branch .Ldivided
.Lone_tile:
    s_mov_b32 s52, s2
    s_mov_b32 s29, 0
.Ldivided:
    s_mov_b32 s2, s52
    s_lshl_b32 s60, s2, 4
    s_load_dwordx4 s[52:55], s[22:23], s60
    s_mul_i32 s60, s2, s41
    s_mul_hi_u32 s61, s2, s41
    s_add_u32 s18, s18, s60
    s_addc_u32 s19, s19, s61
    s_mul_i32 s60, s2, s43
    s_mul_hi_u32 s61, s2, s43
    s_add_u32 s20, s20, s60
    s_addc_u32 s21, s21, s61
    s_waitcnt lgkmcnt(0)
    s_mul_i32 s60, s52, s42
    s_mul_hi_u32 s61, s52, s42
    s_add_u32 s18, s18, s60
    s_addc_u32 s19, s19, s61
    s_mul_i32 s60, s52, s44
    s_mul_hi_u32 s61, s52, s44
    s_add_u32 s20, s20, s60
    s_addc_u32 s21, s21, s61
    s_lshl_b32 s60, s29, 12
    v_lshlrev_b32 v18, 2, v0
    v_add_u32 v18, s60, v18
    v_mov_b32 v24, 0
    v_mov_b32 v25, 0
    v_mov_b32 v26, 0
    v_mov_b32 v27, 0
    v_mov_b32 v28, 0
    v_mov_b32 v29, 0
    v_mov_b32 v30, 0
    v_mov_b32 v31, 0
    v_mov_b32 v32, 0
    v_mov_b32 v33, 0
    v_mov_b32 v34, 0
    v_mov_b32 v35, 0
    v_mov_b32 v36, 0
    v_mov_b32 v37, 0
    v_mov_b32 v38, 0
    v_mov_b32 v39, 0
    v_add_u32 v2, 0, v18
    v_cmp_gt_u32 vcc, s37, v2
    s_and_saveexec_b64 s[58:59], vcc
    v_lshlrev_b32 v2, 2, v2
    global_load_dwordx4 v[24:27], v2, s[18:19]
    s_cmp_lg_u32 s54, 0
    s_cbranch_scc1 .Lloaded0
    global_load_dwordx4 v[40:43], v2, s[20:21]
    s_waitcnt vmcnt(0)
    v_sub_f32 v24, v24, v40
    v_max_f32 v24, 0, v24
    v_sub_f32 v25, v25, v41
    v_max_f32 v25, 0, v25
    v_sub_f32 v26, v26, v42
    v_max_f32 v26, 0, v26
    v_sub_f32 v27, v27, v43
    v_max_f32 v27, 0, v27
.Lloaded0:
    s_waitcnt vmcnt(0)
    s_mov_b64 exec, s[58:59]
    v_add_u32 v2, 1024, v18
    v_cmp_gt_u32 vcc, s37, v2
    s_and_saveexec_b64 s[58:59], vcc
    v_lshlrev_b32 v2, 2, v2
    global_load_dwordx4 v[28:31], v2, s[18:19]
    s_cmp_lg_u32 s54, 0
    s_cbranch_scc1 .Lloaded1
    global_load_dwordx4 v[44:47], v2, s[20:21]
    s_waitcnt vmcnt(0)
    v_sub_f32 v28, v28, v44
    v_max_f32 v28, 0, v28
    v_sub_f32 v29, v29, v45
    v_max_f32 v29, 0, v29
    v_sub_f32 v30, v30, v46
    v_max_f32 v30, 0, v30
    v_sub_f32 v31, v31, v47
    v_max_f32 v31, 0, v31
.Lloaded1:
    s_waitcnt vmcnt(0)
    s_mov_b64 exec, s[58:59]
    v_add_u32 v2, 2048, v18
    v_cmp_gt_u32 vcc, s37, v2
    s_and_saveexec_b64 s[58:59], vcc
    v_lshlrev_b32 v2, 2, v2
    global_load_dwordx4 v[32:35], v2, s[18:19]
    s_cmp_lg_u32 s54, 0
    s_cbranch_scc1 .Lloaded2
    global_load_dwordx4 v[48:51], v2, s[20:21]
    s_waitcnt vmcnt(0)
    v_sub_f32 v32, v32, v48
    v_max_f32 v32, 0, v32
    v_sub_f32 v33, v33, v49
    v_max_f32 v33, 0, v33
    v_sub_f32 v34, v34, v50
    v_max_f32 v34, 0, v34
    v_sub_f32 v35, v35, v51
    v_max_f32 v35, 0, v35
.Lloaded2:
    s_waitcnt vmcnt(0)
    s_mov_b64 exec, s[58:59]
    v_add_u32 v2, 3072, v18
    v_cmp_gt_u32 vcc, s37, v2
    s_and_saveexec_b64 s[58:59], vcc
    v_lshlrev_b32 v2, 2, v2
    global_load_dwordx4 v[36:39], v2, s[18:19]
    s_cmp_lg_u32 s54, 0
    s_cbranch_scc1 .Lloaded3
    global_load_dwordx4 v[52:55], v2, s[20:21]
    s_waitcnt vmcnt(0)
    v_sub_f32 v36, v36, v52
    v_max_f32 v36, 0, v36
    v_sub_f32 v37, v37, v53
    v_max_f32 v37, 0, v37
    v_sub_f32 v38, v38, v54
    v_max_f32 v38, 0, v38
    v_sub_f32 v39, v39, v55
    v_max_f32 v39, 0, v39
.Lloaded3:
    s_waitcnt vmcnt(0)
    s_mov_b64 exec, s[58:59]
    v_mov_b32 v8, v24
    v_add_f32 v8, v8, v25
    v_add_f32 v8, v8, v26
    v_add_f32 v8, v8, v27
    v_add_f32 v8, v8, v28
    v_add_f32 v8, v8, v29
    v_add_f32 v8, v8, v30
    v_add_f32 v8, v8, v31
    v_add_f32 v8, v8, v32
    v_add_f32 v8, v8, v33
    v_add_f32 v8, v8, v34
    v_add_f32 v8, v8, v35
    v_add_f32 v8, v8, v36
    v_add_f32 v8, v8, v37
    v_add_f32 v8, v8, v38
    v_add_f32 v8, v8, v39
    s_nop 1
    v_add_f32_dpp v8, v8, v8 row_shr:8 bound_ctrl:1
    s_nop 1
    v_add_f32_dpp v8, v8, v8 row_shr:4 bound_ctrl:1
    s_nop 1
    v_add_f32_dpp v8, v8, v8 row_shr:2 bound_ctrl:1
    s_nop 1
    v_add_f32_dpp v8, v8, v8 row_shr:1 bound_ctrl:1
    s_nop 1
    v_add_f32_dpp v8, v8, v8 row_bcast:15 row_mask:0xa
    s_nop 1
    v_add_f32_dpp v8, v8, v8 row_bcast:31 row_mask:0xc
    s_nop 4
    v_readlane_b32 s52, v8, 63
    s_nop 4
    s_mov_b64 exec, 1
    s_lshl_b32 s60, s62, 2
    v_mov_b32 v2, s60
    v_mov_b32 v4, s52
    ds_write_b32 v2, v4
    s_waitcnt lgkmcnt(0)
    s_mov_b64 exec, -1
    s_barrier
    s_cmp_lg_u32 s62, 0
    s_cbranch_scc1 .Ldone
    s_mov_b64 exec, 1
    v_mov_b32 v2, 0
    ds_read_b128 v[4:7], v2
    s_waitcnt lgkmcnt(0)
    v_add_f32 v4, v4, v6
    v_add_f32 v5, v5, v7
    v_add_f32 v4, v4, v5
    s_lshl_b32 s60, s28, 2
    v_mov_b32 v2, s60
    global_store_dword v2, v4, s[24:25]
.Ldone:
    s_endpgm
.Lend:
.size netra_dsv4_classic_tile_sum, .Lend-netra_dsv4_classic_tile_sum
.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel netra_dsv4_classic_tile_sum
    .amdhsa_group_segment_fixed_size 16
    .amdhsa_private_segment_fixed_size 0
    .amdhsa_kernarg_size 192
    .amdhsa_user_sgpr_count 2
    .amdhsa_user_sgpr_kernarg_segment_ptr 1
    .amdhsa_enable_private_segment 0
    .amdhsa_system_sgpr_workgroup_id_x 1
    .amdhsa_system_sgpr_workgroup_id_y 1
    .amdhsa_system_vgpr_workitem_id 0
    .amdhsa_next_free_vgpr 64
    .amdhsa_accum_offset 64
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
    .group_segment_fixed_size: 16
    .kernarg_segment_align: 8
    .kernarg_segment_size: 192
    .max_flat_workgroup_size: 256
    .name: netra_dsv4_classic_tile_sum
    .private_segment_fixed_size: 0
    .sgpr_count: 64
    .sgpr_spill_count: 0
    .symbol: netra_dsv4_classic_tile_sum.kd
    .vgpr_count: 64
    .vgpr_spill_count: 0
    .wavefront_size: 64
...
.end_amdgpu_metadata
