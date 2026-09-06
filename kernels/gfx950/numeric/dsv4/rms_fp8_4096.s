// SPDX-License-Identifier: MIT
// Handwritten gfx950 DSV4 control operation: rms_fp8_4096.
// ABI: sixteen 64-bit pointers followed by sixteen uint32 scalars (192 bytes).
// Caller supplies valid, non-aliasing tensors on the owning device/stream.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.protected netra_dsv4_rms_fp8_4096
.globl netra_dsv4_rms_fp8_4096
.p2align 8
.type netra_dsv4_rms_fp8_4096,@function
netra_dsv4_rms_fp8_4096:
    s_load_dwordx8 s[4:11], s[0:1], 0
    s_load_dwordx2 s[12:13], s[0:1], 32
    s_load_dwordx8 s[36:43], s[0:1], 128
    s_waitcnt lgkmcnt(0)
    // Four waves cooperate on one 4096-wide row. Four pairs of 128-element
    // quantization groups per wave; inputs stay in registers between passes.
    v_lshrrev_b32 v23, 6, v0
    s_nop 4
    v_readfirstlane_b32 s62, v23
    s_nop 4
    v_and_b32 v0, 63, v0
    s_mul_i32 s60, s2, s41
    s_mul_hi_u32 s61, s2, s41
    s_add_u32 s4, s4, s60
    s_addc_u32 s5, s5, s61
    s_mul_i32 s60, s2, s37
    s_mul_hi_u32 s61, s2, s37
    s_add_u32 s8, s8, s60
    s_addc_u32 s9, s9, s61
    s_mul_i32 s60, s2, s38
    s_mul_hi_u32 s61, s2, s38
    s_add_u32 s10, s10, s60
    s_addc_u32 s11, s11, s61
    s_mul_i32 s60, s2, s40
    s_mul_hi_u32 s61, s2, s40
    s_add_u32 s12, s12, s60
    s_addc_u32 s13, s13, s61
    s_lshl_b32 s63, s62, 9
    v_lshlrev_b32 v18, 3, v0
    v_add_u32 v18, s63, v18
    v_add_u32 v19, 4096, v18
    global_load_dwordx2 v[24:25], v18, s[4:5] offset:0
    global_load_dwordx2 v[32:33], v18, s[6:7] offset:0
    global_load_dwordx2 v[26:27], v18, s[4:5] offset:2048
    global_load_dwordx2 v[34:35], v18, s[6:7] offset:2048
    global_load_dwordx2 v[28:29], v19, s[4:5] offset:0
    global_load_dwordx2 v[36:37], v19, s[6:7] offset:0
    global_load_dwordx2 v[30:31], v19, s[4:5] offset:2048
    global_load_dwordx2 v[38:39], v19, s[6:7] offset:2048
    s_waitcnt vmcnt(0)
    v_mov_b32 v3, 0
    v_lshlrev_b32 v4, 16, v24
    v_and_b32 v5, 0xffff0000, v24
    v_fma_f32 v3, v4, v4, v3
    v_fma_f32 v3, v5, v5, v3
    v_lshlrev_b32 v4, 16, v25
    v_and_b32 v5, 0xffff0000, v25
    v_fma_f32 v3, v4, v4, v3
    v_fma_f32 v3, v5, v5, v3
    v_lshlrev_b32 v4, 16, v26
    v_and_b32 v5, 0xffff0000, v26
    v_fma_f32 v3, v4, v4, v3
    v_fma_f32 v3, v5, v5, v3
    v_lshlrev_b32 v4, 16, v27
    v_and_b32 v5, 0xffff0000, v27
    v_fma_f32 v3, v4, v4, v3
    v_fma_f32 v3, v5, v5, v3
    v_lshlrev_b32 v4, 16, v28
    v_and_b32 v5, 0xffff0000, v28
    v_fma_f32 v3, v4, v4, v3
    v_fma_f32 v3, v5, v5, v3
    v_lshlrev_b32 v4, 16, v29
    v_and_b32 v5, 0xffff0000, v29
    v_fma_f32 v3, v4, v4, v3
    v_fma_f32 v3, v5, v5, v3
    v_lshlrev_b32 v4, 16, v30
    v_and_b32 v5, 0xffff0000, v30
    v_fma_f32 v3, v4, v4, v3
    v_fma_f32 v3, v5, v5, v3
    v_lshlrev_b32 v4, 16, v31
    v_and_b32 v5, 0xffff0000, v31
    v_fma_f32 v3, v4, v4, v3
    v_fma_f32 v3, v5, v5, v3
    s_nop 1
    v_add_f32_dpp v3, v3, v3 quad_perm:[1,0,3,2]
    s_nop 1
    v_add_f32_dpp v3, v3, v3 quad_perm:[2,3,0,1]
    s_nop 1
    v_add_f32_dpp v3, v3, v3 row_shl:4 bound_ctrl:1
    s_nop 1
    v_add_f32_dpp v3, v3, v3 row_shl:8 bound_ctrl:1
    s_nop 1
    v_mov_b32 v20, v3
    s_nop 1
    v_permlane16_swap_b32 v3, v20
    s_nop 1
    v_add_f32 v3, v3, v20
    s_nop 1
    v_mov_b32 v20, v3
    s_nop 1
    v_permlane32_swap_b32 v3, v20
    s_nop 1
    v_add_f32 v3, v3, v20
    s_nop 4
    v_readfirstlane_b32 s52, v3
    s_nop 4
    s_mov_b64 exec, 1
    s_lshl_b32 s60, s62, 2
    v_mov_b32 v2, s60
    v_mov_b32 v4, s52
    ds_write_b32 v2, v4
    s_waitcnt lgkmcnt(0)
    s_mov_b64 exec, -1
    s_barrier
    s_mov_b64 exec, 1
    v_mov_b32 v2, 0
    ds_read_b128 v[4:7], v2
    s_waitcnt lgkmcnt(0)
    v_add_f32 v4, v4, v5
    v_add_f32 v6, v6, v7
    v_add_f32 v4, v4, v6
    v_mul_f32 v4, 0.000244140625, v4
    v_add_f32 v4, s36, v4
    v_rsq_f32 v4, v4
    v_nop
    s_nop 3
    s_nop 4
    v_readfirstlane_b32 s53, v4
    s_nop 4
    s_mov_b64 exec, -1
    // Four contiguous elements per lane reduce global loads/stores.
    v_lshlrev_b32 v4, 16, v24
    v_and_b32 v5, 0xffff0000, v24
    v_lshlrev_b32 v6, 16, v32
    v_and_b32 v7, 0xffff0000, v32
    v_mul_f32 v4, s53, v4
    v_mul_f32 v5, s53, v5
    v_mul_f32 v40, v4, v6
    v_mul_f32 v41, v5, v7
    v_lshlrev_b32 v4, 16, v25
    v_and_b32 v5, 0xffff0000, v25
    v_lshlrev_b32 v6, 16, v33
    v_and_b32 v7, 0xffff0000, v33
    v_mul_f32 v4, s53, v4
    v_mul_f32 v5, s53, v5
    v_mul_f32 v42, v4, v6
    v_mul_f32 v43, v5, v7
    v_lshlrev_b32 v4, 16, v26
    v_and_b32 v5, 0xffff0000, v26
    v_lshlrev_b32 v6, 16, v34
    v_and_b32 v7, 0xffff0000, v34
    v_mul_f32 v4, s53, v4
    v_mul_f32 v5, s53, v5
    v_mul_f32 v44, v4, v6
    v_mul_f32 v45, v5, v7
    v_lshlrev_b32 v4, 16, v27
    v_and_b32 v5, 0xffff0000, v27
    v_lshlrev_b32 v6, 16, v35
    v_and_b32 v7, 0xffff0000, v35
    v_mul_f32 v4, s53, v4
    v_mul_f32 v5, s53, v5
    v_mul_f32 v46, v4, v6
    v_mul_f32 v47, v5, v7
    v_lshlrev_b32 v4, 16, v28
    v_and_b32 v5, 0xffff0000, v28
    v_lshlrev_b32 v6, 16, v36
    v_and_b32 v7, 0xffff0000, v36
    v_mul_f32 v4, s53, v4
    v_mul_f32 v5, s53, v5
    v_mul_f32 v48, v4, v6
    v_mul_f32 v49, v5, v7
    v_lshlrev_b32 v4, 16, v29
    v_and_b32 v5, 0xffff0000, v29
    v_lshlrev_b32 v6, 16, v37
    v_and_b32 v7, 0xffff0000, v37
    v_mul_f32 v4, s53, v4
    v_mul_f32 v5, s53, v5
    v_mul_f32 v50, v4, v6
    v_mul_f32 v51, v5, v7
    v_lshlrev_b32 v4, 16, v30
    v_and_b32 v5, 0xffff0000, v30
    v_lshlrev_b32 v6, 16, v38
    v_and_b32 v7, 0xffff0000, v38
    v_mul_f32 v4, s53, v4
    v_mul_f32 v5, s53, v5
    v_mul_f32 v52, v4, v6
    v_mul_f32 v53, v5, v7
    v_lshlrev_b32 v4, 16, v31
    v_and_b32 v5, 0xffff0000, v31
    v_lshlrev_b32 v6, 16, v39
    v_and_b32 v7, 0xffff0000, v39
    v_mul_f32 v4, s53, v4
    v_mul_f32 v5, s53, v5
    v_mul_f32 v54, v4, v6
    v_mul_f32 v55, v5, v7
    s_cmp_eq_u32 s42, 0
    s_cbranch_scc1 .Lnormalized_stored
    v_cvt_pk_bf16_f32 v4, v40, v41
    v_cvt_pk_bf16_f32 v5, v42, v43
    v_cvt_pk_bf16_f32 v6, v44, v45
    v_cvt_pk_bf16_f32 v7, v46, v47
    v_cvt_pk_bf16_f32 v8, v48, v49
    v_cvt_pk_bf16_f32 v9, v50, v51
    v_cvt_pk_bf16_f32 v10, v52, v53
    v_cvt_pk_bf16_f32 v11, v54, v55
    global_store_dwordx2 v18, v[4:5], s[12:13] offset:0
    global_store_dwordx2 v18, v[6:7], s[12:13] offset:2048
    global_store_dwordx2 v19, v[8:9], s[12:13] offset:0
    global_store_dwordx2 v19, v[10:11], s[12:13] offset:2048
.Lnormalized_stored:
    v_and_b32 v4, 0x7fffffff, v40
    v_and_b32 v5, 0x7fffffff, v41
    v_and_b32 v6, 0x7fffffff, v42
    v_and_b32 v7, 0x7fffffff, v43
    v_max_f32 v4, v4, v5
    v_max_f32 v6, v6, v7
    v_max_f32 v24, v4, v6
    v_and_b32 v4, 0x7fffffff, v44
    v_and_b32 v5, 0x7fffffff, v45
    v_and_b32 v6, 0x7fffffff, v46
    v_and_b32 v7, 0x7fffffff, v47
    v_max_f32 v4, v4, v5
    v_max_f32 v6, v6, v7
    v_max_f32 v25, v4, v6
    v_and_b32 v4, 0x7fffffff, v48
    v_and_b32 v5, 0x7fffffff, v49
    v_and_b32 v6, 0x7fffffff, v50
    v_and_b32 v7, 0x7fffffff, v51
    v_max_f32 v4, v4, v5
    v_max_f32 v6, v6, v7
    v_max_f32 v26, v4, v6
    v_and_b32 v4, 0x7fffffff, v52
    v_and_b32 v5, 0x7fffffff, v53
    v_and_b32 v6, 0x7fffffff, v54
    v_and_b32 v7, 0x7fffffff, v55
    v_max_f32 v4, v4, v5
    v_max_f32 v6, v6, v7
    v_max_f32 v27, v4, v6
    v_max_f32_dpp v24, v24, v24 quad_perm:[1,0,3,2]
    v_max_f32_dpp v25, v25, v25 quad_perm:[1,0,3,2]
    v_max_f32_dpp v26, v26, v26 quad_perm:[1,0,3,2]
    v_max_f32_dpp v27, v27, v27 quad_perm:[1,0,3,2]
    v_max_f32_dpp v24, v24, v24 quad_perm:[2,3,0,1]
    v_max_f32_dpp v25, v25, v25 quad_perm:[2,3,0,1]
    v_max_f32_dpp v26, v26, v26 quad_perm:[2,3,0,1]
    v_max_f32_dpp v27, v27, v27 quad_perm:[2,3,0,1]
    v_max_f32_dpp v24, v24, v24 row_shl:4 bound_ctrl:1
    v_max_f32_dpp v25, v25, v25 row_shl:4 bound_ctrl:1
    v_max_f32_dpp v26, v26, v26 row_shl:4 bound_ctrl:1
    v_max_f32_dpp v27, v27, v27 row_shl:4 bound_ctrl:1
    v_max_f32_dpp v24, v24, v24 row_shl:8 bound_ctrl:1
    v_max_f32_dpp v25, v25, v25 row_shl:8 bound_ctrl:1
    v_max_f32_dpp v26, v26, v26 row_shl:8 bound_ctrl:1
    v_max_f32_dpp v27, v27, v27 row_shl:8 bound_ctrl:1
    v_mov_b32 v32, v24
    v_mov_b32 v33, v25
    v_mov_b32 v34, v26
    v_mov_b32 v35, v27
    v_permlane16_swap_b32 v24, v32
    v_permlane16_swap_b32 v25, v33
    v_permlane16_swap_b32 v26, v34
    v_permlane16_swap_b32 v27, v35
    v_max_f32 v24, v24, v32
    v_max_f32 v25, v25, v33
    v_max_f32 v26, v26, v34
    v_max_f32 v27, v27, v35
    v_max_f32_dpp v24, v24, v24 row_shr:4 bound_ctrl:1
    v_max_f32_dpp v25, v25, v25 row_shr:4 bound_ctrl:1
    v_max_f32_dpp v26, v26, v26 row_shr:4 bound_ctrl:1
    v_max_f32_dpp v27, v27, v27 row_shr:4 bound_ctrl:1
    v_max_f32_dpp v24, v24, v24 row_shr:8 bound_ctrl:1
    v_max_f32_dpp v25, v25, v25 row_shr:8 bound_ctrl:1
    v_max_f32_dpp v26, v26, v26 row_shr:8 bound_ctrl:1
    v_max_f32_dpp v27, v27, v27 row_shr:8 bound_ctrl:1
    v_max_f32 v24, 1.0e-10, v24
    v_mul_f32 v24, 0.002232142857142857, v24
    v_max_f32 v25, 1.0e-10, v25
    v_mul_f32 v25, 0.002232142857142857, v25
    v_max_f32 v26, 1.0e-10, v26
    v_mul_f32 v26, 0.002232142857142857, v26
    v_max_f32 v27, 1.0e-10, v27
    v_mul_f32 v27, 0.002232142857142857, v27
    // Each half-wave owns one quantization group and one scale store.
    s_lshl_b32 s60, s62, 1
    v_lshrrev_b32 v1, 5, v0
    v_add_u32 v1, s60, v1
    v_and_b32 v3, 31, v0
    v_cmp_eq_u32 vcc, v3, 0
    s_and_saveexec_b64 s[58:59], vcc
    v_add_u32 v2, 0, v1
    v_mul_lo_u32 v2, s39, v2
    global_store_dword v2, v24, s[10:11]
    v_add_u32 v2, 8, v1
    v_mul_lo_u32 v2, s39, v2
    global_store_dword v2, v25, s[10:11]
    v_add_u32 v2, 16, v1
    v_mul_lo_u32 v2, s39, v2
    global_store_dword v2, v26, s[10:11]
    v_add_u32 v2, 24, v1
    v_mul_lo_u32 v2, s39, v2
    global_store_dword v2, v27, s[10:11]
    s_mov_b64 exec, s[58:59]
    v_rcp_f32 v24, v24
    v_rcp_f32 v25, v25
    v_rcp_f32 v26, v26
    v_rcp_f32 v27, v27
    v_nop
    s_nop 3
    v_mul_f32 v40, v40, v24
    v_max_f32 v40, -448.0, v40
    v_min_f32 v40, 448.0, v40
    v_mul_f32 v41, v41, v24
    v_max_f32 v41, -448.0, v41
    v_min_f32 v41, 448.0, v41
    v_mul_f32 v42, v42, v24
    v_max_f32 v42, -448.0, v42
    v_min_f32 v42, 448.0, v42
    v_mul_f32 v43, v43, v24
    v_max_f32 v43, -448.0, v43
    v_min_f32 v43, 448.0, v43
    v_mul_f32 v44, v44, v25
    v_max_f32 v44, -448.0, v44
    v_min_f32 v44, 448.0, v44
    v_mul_f32 v45, v45, v25
    v_max_f32 v45, -448.0, v45
    v_min_f32 v45, 448.0, v45
    v_mul_f32 v46, v46, v25
    v_max_f32 v46, -448.0, v46
    v_min_f32 v46, 448.0, v46
    v_mul_f32 v47, v47, v25
    v_max_f32 v47, -448.0, v47
    v_min_f32 v47, 448.0, v47
    v_mul_f32 v48, v48, v26
    v_max_f32 v48, -448.0, v48
    v_min_f32 v48, 448.0, v48
    v_mul_f32 v49, v49, v26
    v_max_f32 v49, -448.0, v49
    v_min_f32 v49, 448.0, v49
    v_mul_f32 v50, v50, v26
    v_max_f32 v50, -448.0, v50
    v_min_f32 v50, 448.0, v50
    v_mul_f32 v51, v51, v26
    v_max_f32 v51, -448.0, v51
    v_min_f32 v51, 448.0, v51
    v_mul_f32 v52, v52, v27
    v_max_f32 v52, -448.0, v52
    v_min_f32 v52, 448.0, v52
    v_mul_f32 v53, v53, v27
    v_max_f32 v53, -448.0, v53
    v_min_f32 v53, 448.0, v53
    v_mul_f32 v54, v54, v27
    v_max_f32 v54, -448.0, v54
    v_min_f32 v54, 448.0, v54
    v_mul_f32 v55, v55, v27
    v_max_f32 v55, -448.0, v55
    v_min_f32 v55, 448.0, v55
    v_lshrrev_b32 v2, 1, v18
    v_cvt_scalef32_pk_fp8_f32 v4, v40, v41, 1.0
    v_cvt_scalef32_pk_fp8_f32 v5, v42, v43, 1.0
    v_and_b32 v4, 0xffff, v4
    v_lshlrev_b32 v5, 16, v5
    v_or_b32 v4, v4, v5
    global_store_dword v2, v4, s[8:9] offset:0
    v_cvt_scalef32_pk_fp8_f32 v4, v44, v45, 1.0
    v_cvt_scalef32_pk_fp8_f32 v5, v46, v47, 1.0
    v_and_b32 v4, 0xffff, v4
    v_lshlrev_b32 v5, 16, v5
    v_or_b32 v4, v4, v5
    global_store_dword v2, v4, s[8:9] offset:1024
    v_cvt_scalef32_pk_fp8_f32 v4, v48, v49, 1.0
    v_cvt_scalef32_pk_fp8_f32 v5, v50, v51, 1.0
    v_and_b32 v4, 0xffff, v4
    v_lshlrev_b32 v5, 16, v5
    v_or_b32 v4, v4, v5
    global_store_dword v2, v4, s[8:9] offset:2048
    v_cvt_scalef32_pk_fp8_f32 v4, v52, v53, 1.0
    v_cvt_scalef32_pk_fp8_f32 v5, v54, v55, 1.0
    v_and_b32 v4, 0xffff, v4
    v_lshlrev_b32 v5, 16, v5
    v_or_b32 v4, v4, v5
    global_store_dword v2, v4, s[8:9] offset:3072
.Ldone:
    s_endpgm
.Lend:
.size netra_dsv4_rms_fp8_4096, .Lend-netra_dsv4_rms_fp8_4096
.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel netra_dsv4_rms_fp8_4096
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
    .name: netra_dsv4_rms_fp8_4096
    .private_segment_fixed_size: 0
    .sgpr_count: 64
    .sgpr_spill_count: 0
    .symbol: netra_dsv4_rms_fp8_4096.kd
    .vgpr_count: 64
    .vgpr_spill_count: 0
    .wavefront_size: 64
...
.end_amdgpu_metadata
