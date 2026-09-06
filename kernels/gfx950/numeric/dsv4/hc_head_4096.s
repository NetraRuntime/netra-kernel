// SPDX-License-Identifier: MIT
// Handwritten gfx950 DSV4 control operation: hc_head_4096.
// ABI: sixteen 64-bit pointers followed by sixteen uint32 scalars (192 bytes).
// Caller supplies valid, non-aliasing tensors on the owning device/stream.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.protected netra_dsv4_hc_head_4096
.globl netra_dsv4_hc_head_4096
.p2align 8
.type netra_dsv4_hc_head_4096,@function
netra_dsv4_hc_head_4096:
    s_load_dwordx16 s[4:19], s[0:1], 0
    s_load_dwordx16 s[20:35], s[0:1], 64
    s_load_dwordx16 s[36:51], s[0:1], 128
    s_waitcnt lgkmcnt(0)
    v_lshrrev_b32 v23, 6, v0
    s_nop 4
    v_readfirstlane_b32 s62, v23
    s_nop 4
    s_load_dword s54, s[8:9], 0
    s_load_dwordx4 s[24:27], s[10:11], 0
    s_mul_i32 s60, s2, 32768
    s_mul_hi_u32 s61, s2, 32768
    s_add_u32 s4, s4, s60
    s_addc_u32 s5, s5, s61
    s_mul_i32 s60, s2, 8192
    s_mul_hi_u32 s61, s2, 8192
    s_add_u32 s12, s12, s60
    s_addc_u32 s13, s13, s61
    s_add_u32 s14, s6, 65536
    s_addc_u32 s15, s7, 0
    s_add_u32 s16, s6, 131072
    s_addc_u32 s17, s7, 0
    s_add_u32 s18, s6, 196608
    s_addc_u32 s19, s7, 0
    s_waitcnt lgkmcnt(0)
    v_mov_b32 v24, 0
    v_mov_b32 v25, 0
    v_mov_b32 v26, 0
    v_mov_b32 v27, 0
    v_mov_b32 v28, 0
    v_lshlrev_b32 v1, 1, v0
.Ldot_loop:
    v_lshlrev_b32 v2, 1, v1
    global_load_dword v4, v2, s[4:5]
    v_lshlrev_b32 v2, 2, v1
    global_load_dwordx2 v[8:9], v2, s[6:7]
    global_load_dwordx2 v[10:11], v2, s[14:15]
    global_load_dwordx2 v[12:13], v2, s[16:17]
    global_load_dwordx2 v[14:15], v2, s[18:19]
    s_waitcnt vmcnt(0)
    v_lshlrev_b32 v5, 16, v4
    v_and_b32 v6, 0xffff0000, v4
    v_mul_f32 v7, v5, v5
    v_add_f32 v24, v24, v7
    v_mul_f32 v7, v6, v6
    v_add_f32 v24, v24, v7
    v_mul_f32 v7, v5, v8
    v_add_f32 v25, v25, v7
    v_mul_f32 v7, v6, v9
    v_add_f32 v25, v25, v7
    v_mul_f32 v7, v5, v10
    v_add_f32 v26, v26, v7
    v_mul_f32 v7, v6, v11
    v_add_f32 v26, v26, v7
    v_mul_f32 v7, v5, v12
    v_add_f32 v27, v27, v7
    v_mul_f32 v7, v6, v13
    v_add_f32 v27, v27, v7
    v_mul_f32 v7, v5, v14
    v_add_f32 v28, v28, v7
    v_mul_f32 v7, v6, v15
    v_add_f32 v28, v28, v7
    v_add_u32 v1, 512, v1
    v_cmp_gt_u32 vcc, 16384, v1
    s_cbranch_vccnz .Ldot_loop
    v_mov_b32 v8, v24
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
    s_mul_i32 s60, s62, 20
    v_mov_b32 v2, s60
    v_mov_b32 v4, s52
    ds_write_b32 v2, v4 offset:0
    s_mov_b64 exec, -1
    v_mov_b32 v8, v25
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
    s_mul_i32 s60, s62, 20
    v_mov_b32 v2, s60
    v_mov_b32 v4, s52
    ds_write_b32 v2, v4 offset:4
    s_mov_b64 exec, -1
    v_mov_b32 v8, v26
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
    s_mul_i32 s60, s62, 20
    v_mov_b32 v2, s60
    v_mov_b32 v4, s52
    ds_write_b32 v2, v4 offset:8
    s_mov_b64 exec, -1
    v_mov_b32 v8, v27
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
    s_mul_i32 s60, s62, 20
    v_mov_b32 v2, s60
    v_mov_b32 v4, s52
    ds_write_b32 v2, v4 offset:12
    s_mov_b64 exec, -1
    v_mov_b32 v8, v28
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
    s_mul_i32 s60, s62, 20
    v_mov_b32 v2, s60
    v_mov_b32 v4, s52
    ds_write_b32 v2, v4 offset:16
    s_mov_b64 exec, -1
    s_waitcnt lgkmcnt(0)
    s_barrier
    s_mov_b64 exec, 1
    v_mov_b32 v2, 0
    ds_read_b32 v4, v2 offset:0
    ds_read_b32 v5, v2 offset:20
    ds_read_b32 v6, v2 offset:40
    ds_read_b32 v7, v2 offset:60
    s_waitcnt lgkmcnt(0)
    v_add_f32 v4, v4, v5
    v_add_f32 v6, v6, v7
    v_add_f32 v24, v4, v6
    ds_read_b32 v4, v2 offset:4
    ds_read_b32 v5, v2 offset:24
    ds_read_b32 v6, v2 offset:44
    ds_read_b32 v7, v2 offset:64
    s_waitcnt lgkmcnt(0)
    v_add_f32 v4, v4, v5
    v_add_f32 v6, v6, v7
    v_add_f32 v25, v4, v6
    ds_read_b32 v4, v2 offset:8
    ds_read_b32 v5, v2 offset:28
    ds_read_b32 v6, v2 offset:48
    ds_read_b32 v7, v2 offset:68
    s_waitcnt lgkmcnt(0)
    v_add_f32 v4, v4, v5
    v_add_f32 v6, v6, v7
    v_add_f32 v26, v4, v6
    ds_read_b32 v4, v2 offset:12
    ds_read_b32 v5, v2 offset:32
    ds_read_b32 v6, v2 offset:52
    ds_read_b32 v7, v2 offset:72
    s_waitcnt lgkmcnt(0)
    v_add_f32 v4, v4, v5
    v_add_f32 v6, v6, v7
    v_add_f32 v27, v4, v6
    ds_read_b32 v4, v2 offset:16
    ds_read_b32 v5, v2 offset:36
    ds_read_b32 v6, v2 offset:56
    ds_read_b32 v7, v2 offset:76
    s_waitcnt lgkmcnt(0)
    v_add_f32 v4, v4, v5
    v_add_f32 v6, v6, v7
    v_add_f32 v28, v4, v6
    v_mul_f32 v24, 0.00006103515625, v24
    v_add_f32 v24, s36, v24
    v_rsq_f32 v24, v24
    v_nop
    s_nop 3
    v_mul_f32 v4, v25, v24
    v_mov_b32 v5, s54
    v_mov_b32 v6, s24
    v_fma_f32 v4, v4, v5, v6
    v_mul_f32 v4, -1.4426950408889634, v4
    v_exp_f32 v4, v4
    v_nop
    s_nop 3
    v_add_f32 v4, 1.0, v4
    v_rcp_f32 v4, v4
    v_nop
    s_nop 3
    v_add_f32 v4, s37, v4
    s_nop 4
    v_readfirstlane_b32 s24, v4
    s_nop 4
    v_mul_f32 v4, v26, v24
    v_mov_b32 v5, s54
    v_mov_b32 v6, s25
    v_fma_f32 v4, v4, v5, v6
    v_mul_f32 v4, -1.4426950408889634, v4
    v_exp_f32 v4, v4
    v_nop
    s_nop 3
    v_add_f32 v4, 1.0, v4
    v_rcp_f32 v4, v4
    v_nop
    s_nop 3
    v_add_f32 v4, s37, v4
    s_nop 4
    v_readfirstlane_b32 s25, v4
    s_nop 4
    v_mul_f32 v4, v27, v24
    v_mov_b32 v5, s54
    v_mov_b32 v6, s26
    v_fma_f32 v4, v4, v5, v6
    v_mul_f32 v4, -1.4426950408889634, v4
    v_exp_f32 v4, v4
    v_nop
    s_nop 3
    v_add_f32 v4, 1.0, v4
    v_rcp_f32 v4, v4
    v_nop
    s_nop 3
    v_add_f32 v4, s37, v4
    s_nop 4
    v_readfirstlane_b32 s26, v4
    s_nop 4
    v_mul_f32 v4, v28, v24
    v_mov_b32 v5, s54
    v_mov_b32 v6, s27
    v_fma_f32 v4, v4, v5, v6
    v_mul_f32 v4, -1.4426950408889634, v4
    v_exp_f32 v4, v4
    v_nop
    s_nop 3
    v_add_f32 v4, 1.0, v4
    v_rcp_f32 v4, v4
    v_nop
    s_nop 3
    v_add_f32 v4, s37, v4
    s_nop 4
    v_readfirstlane_b32 s27, v4
    s_nop 4
    s_mov_b64 exec, -1
    s_add_u32 s14, s4, 8192
    s_addc_u32 s15, s5, 0
    s_add_u32 s16, s4, 16384
    s_addc_u32 s17, s5, 0
    s_add_u32 s18, s4, 24576
    s_addc_u32 s19, s5, 0
    v_lshlrev_b32 v1, 1, v0
.Loutput:
    v_lshlrev_b32 v2, 1, v1
    global_load_dword v4, v2, s[4:5]
    global_load_dword v5, v2, s[14:15]
    global_load_dword v6, v2, s[16:17]
    global_load_dword v7, v2, s[18:19]
    s_waitcnt vmcnt(0)
    v_lshlrev_b32 v8, 16, v4
    v_and_b32 v9, 0xffff0000, v4
    v_mul_f32 v8, s24, v8
    v_mul_f32 v9, s24, v9
    v_lshlrev_b32 v10, 16, v5
    v_and_b32 v11, 0xffff0000, v5
    v_mul_f32 v10, s25, v10
    v_mul_f32 v11, s25, v11
    v_lshlrev_b32 v12, 16, v6
    v_and_b32 v13, 0xffff0000, v6
    v_mul_f32 v12, s26, v12
    v_mul_f32 v13, s26, v13
    v_lshlrev_b32 v14, 16, v7
    v_and_b32 v15, 0xffff0000, v7
    v_mul_f32 v14, s27, v14
    v_mul_f32 v15, s27, v15
    v_add_f32 v8, v8, v10
    v_add_f32 v9, v9, v11
    v_add_f32 v12, v12, v14
    v_add_f32 v13, v13, v15
    v_add_f32 v8, v8, v12
    v_add_f32 v9, v9, v13
    v_cvt_pk_bf16_f32 v4, v8, v9
    global_store_dword v2, v4, s[12:13]
    v_add_u32 v1, 512, v1
    v_cmp_gt_u32 vcc, 4096, v1
    s_cbranch_vccnz .Loutput

.Ldone:
    s_endpgm
.Lend:
.size netra_dsv4_hc_head_4096, .Lend-netra_dsv4_hc_head_4096
.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel netra_dsv4_hc_head_4096
    .amdhsa_group_segment_fixed_size 80
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
    .group_segment_fixed_size: 80
    .kernarg_segment_align: 8
    .kernarg_segment_size: 192
    .max_flat_workgroup_size: 256
    .name: netra_dsv4_hc_head_4096
    .private_segment_fixed_size: 0
    .sgpr_count: 64
    .sgpr_spill_count: 0
    .symbol: netra_dsv4_hc_head_4096.kd
    .vgpr_count: 32
    .vgpr_spill_count: 0
    .wavefront_size: 64
...
.end_amdgpu_metadata
