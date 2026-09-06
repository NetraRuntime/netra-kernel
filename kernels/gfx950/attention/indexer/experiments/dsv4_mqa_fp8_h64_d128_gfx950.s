// SPDX-License-Identifier: MIT
// Hand-written gfx950 C4 paged-MQA scorer. One wave computes one query x
// a small run of 64-key pages, retaining all 64x128 FP8 query values in registers across four
// 16-key tiles. Each tile uses four 16x16x128 FP8 MFMAs and reduces the
// scaled/ReLU/weighted results across the 64 indexer heads.
// Preshuffle: ((key%16)*16 + (dim%16) + (dim/16)*256 + (key/16)*2048).
// All tensor/page/row bases use 64-bit address arithmetic. Invalid scores
// are written as -infinity; no masked row reads another request's pages.
// Finite E4M3FN inputs; FP32 key scales/weights/output; next_n=1; D=128,H=64.

.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.protected netra_dsv4_mqa_fp8_h64_d128_gfx950
.globl netra_dsv4_mqa_fp8_h64_d128_gfx950
.p2align 8
.type netra_dsv4_mqa_fp8_h64_d128_gfx950,@function
netra_dsv4_mqa_fp8_h64_d128_gfx950:
    s_load_dwordx2 s[4:5], s[0:1], 0
    s_load_dwordx2 s[6:7], s[0:1], 8
    s_load_dwordx2 s[8:9], s[0:1], 16
    s_load_dwordx2 s[10:11], s[0:1], 24
    s_load_dwordx2 s[12:13], s[0:1], 32
    s_load_dwordx2 s[14:15], s[0:1], 40
    s_load_dwordx4 s[16:19], s[0:1], 48
    s_load_dwordx2 s[20:21], s[0:1], 64
    s_load_dword s36, s[0:1], 72
    s_waitcnt lgkmcnt(0)

    // Kernargs at 48: output row stride (elements), query/weight/page-table
    // row strides (bytes), KV page stride (bytes), output width (elements),
    // and pages per wave.
    // Query row = workgroup Y; first logical page = workgroup X * pages/wave.
    s_mul_i32 s2, s2, s36
    s_add_u32 s37, s2, s36
    s_lshl_b32 s22, s2, 6
    s_lshl_b32 s32, s3, 2
    s_load_dword s24, s[10:11], s32
    s_lshl_b32 s34, s16, 2
    s_mul_i32 s32, s3, s34
    s_mul_hi_u32 s33, s3, s34
    s_add_u32 s14, s14, s32
    s_addc_u32 s15, s15, s33
    s_waitcnt lgkmcnt(0)
    s_cmp_ge_u32 s22, s24
    s_cbranch_scc1 .Linvalid_page
    s_mul_i32 s32, s3, s17
    s_mul_hi_u32 s33, s3, s17
    s_add_u32 s4, s4, s32
    s_addc_u32 s5, s5, s33
    s_mul_i32 s32, s3, s18
    s_mul_hi_u32 s33, s3, s18
    s_add_u32 s8, s8, s32
    s_addc_u32 s9, s9, s33
    s_mul_i32 s32, s3, s19
    s_mul_hi_u32 s33, s3, s19
    s_add_u32 s12, s12, s32
    s_addc_u32 s13, s13, s33
    v_and_b32_e32 v1, 15, v0
    v_and_b32_e32 v2, 48, v0
    v_lshlrev_b32_e32 v3, 7, v1
    v_add_u32_e32 v3, v3, v2
    v_lshlrev_b32_e32 v4, 4, v0
    // Q lane: head=lane%16, dims=(lane/16)*16 + [0:16,64:80].
    v_add_u32_e32 v7, 0, v3
    global_load_dwordx4 v[8:11], v7, s[4:5]
    global_load_dwordx4 v[12:15], v7, s[4:5] offset:64
    global_load_dwordx4 v[40:43], v2, s[8:9] offset:0
    v_add_u32_e32 v7, 2048, v3
    global_load_dwordx4 v[16:19], v7, s[4:5]
    global_load_dwordx4 v[20:23], v7, s[4:5] offset:64
    global_load_dwordx4 v[44:47], v2, s[8:9] offset:64
    v_add_u32_e32 v7, 4096, v3
    global_load_dwordx4 v[24:27], v7, s[4:5]
    global_load_dwordx4 v[28:31], v7, s[4:5] offset:64
    global_load_dwordx4 v[48:51], v2, s[8:9] offset:128
    v_add_u32_e32 v7, 6144, v3
    global_load_dwordx4 v[32:35], v7, s[4:5]
    global_load_dwordx4 v[36:39], v7, s[4:5] offset:64
    global_load_dwordx4 v[52:55], v2, s[8:9] offset:192
    s_waitcnt vmcnt(0)
.Lload_page:
    s_lshl_b32 s32, s2, 2
    s_load_dword s25, s[12:13], s32
    s_waitcnt lgkmcnt(0)
    // Active page IDs must satisfy the existing KV-pool contract.
    // Padding rows never reach this read.
    s_mul_i32 s32, s25, s20
    s_mul_hi_u32 s33, s25, s20
    s_add_u32 s26, s6, s32
    s_addc_u32 s27, s7, s33
    s_add_u32 s28, s26, 8192
    s_addc_u32 s29, s27, 0
    s_mov_b32 s23, 0
    s_waitcnt vmcnt(0)
.Lkey_tile:
    s_lshl_b32 s34, s23, 11
    v_add_u32_e32 v7, s34, v4
    global_load_dwordx4 v[56:59], v7, s[26:27]
    global_load_dwordx4 v[60:63], v7, s[26:27] offset:1024
    s_lshl_b32 s34, s23, 4
    v_add_u32_e32 v5, s34, v1
    v_lshlrev_b32_e32 v7, 2, v5
    global_load_dword v80, v7, s[28:29]
    s_waitcnt vmcnt(0)
    v_mfma_f32_16x16x128_f8f6f4 v[64:67], v[8:15], v[56:63], 0
    v_mfma_f32_16x16x128_f8f6f4 v[68:71], v[16:23], v[56:63], 0
    v_mfma_f32_16x16x128_f8f6f4 v[72:75], v[24:31], v[56:63], 0
    v_mfma_f32_16x16x128_f8f6f4 v[76:79], v[32:39], v[56:63], 0
    s_nop 15
    v_mul_f32_e32 v64, v80, v64
    v_max_f32_e32 v64, 0, v64
    v_mul_f32_e32 v64, v40, v64
    v_mul_f32_e32 v65, v80, v65
    v_max_f32_e32 v65, 0, v65
    v_mul_f32_e32 v65, v41, v65
    v_mul_f32_e32 v66, v80, v66
    v_max_f32_e32 v66, 0, v66
    v_mul_f32_e32 v66, v42, v66
    v_mul_f32_e32 v67, v80, v67
    v_max_f32_e32 v67, 0, v67
    v_mul_f32_e32 v67, v43, v67
    v_mul_f32_e32 v68, v80, v68
    v_max_f32_e32 v68, 0, v68
    v_mul_f32_e32 v68, v44, v68
    v_mul_f32_e32 v69, v80, v69
    v_max_f32_e32 v69, 0, v69
    v_mul_f32_e32 v69, v45, v69
    v_mul_f32_e32 v70, v80, v70
    v_max_f32_e32 v70, 0, v70
    v_mul_f32_e32 v70, v46, v70
    v_mul_f32_e32 v71, v80, v71
    v_max_f32_e32 v71, 0, v71
    v_mul_f32_e32 v71, v47, v71
    v_mul_f32_e32 v72, v80, v72
    v_max_f32_e32 v72, 0, v72
    v_mul_f32_e32 v72, v48, v72
    v_mul_f32_e32 v73, v80, v73
    v_max_f32_e32 v73, 0, v73
    v_mul_f32_e32 v73, v49, v73
    v_mul_f32_e32 v74, v80, v74
    v_max_f32_e32 v74, 0, v74
    v_mul_f32_e32 v74, v50, v74
    v_mul_f32_e32 v75, v80, v75
    v_max_f32_e32 v75, 0, v75
    v_mul_f32_e32 v75, v51, v75
    v_mul_f32_e32 v76, v80, v76
    v_max_f32_e32 v76, 0, v76
    v_mul_f32_e32 v76, v52, v76
    v_mul_f32_e32 v77, v80, v77
    v_max_f32_e32 v77, 0, v77
    v_mul_f32_e32 v77, v53, v77
    v_mul_f32_e32 v78, v80, v78
    v_max_f32_e32 v78, 0, v78
    v_mul_f32_e32 v78, v54, v78
    v_mul_f32_e32 v79, v80, v79
    v_max_f32_e32 v79, 0, v79
    v_mul_f32_e32 v79, v55, v79
    // Balanced reduction of the 16 head values owned by this lane.
    v_add_f32_e32 v64, v64, v72
    v_add_f32_e32 v65, v65, v73
    v_add_f32_e32 v66, v66, v74
    v_add_f32_e32 v67, v67, v75
    v_add_f32_e32 v68, v68, v76
    v_add_f32_e32 v69, v69, v77
    v_add_f32_e32 v70, v70, v78
    v_add_f32_e32 v71, v71, v79
    v_add_f32_e32 v64, v64, v68
    v_add_f32_e32 v65, v65, v69
    v_add_f32_e32 v66, v66, v70
    v_add_f32_e32 v67, v67, v71
    v_add_f32_e32 v64, v64, v66
    v_add_f32_e32 v65, v65, v67
    v_add_f32_e32 v64, v64, v65
    v_xor_b32_e32 v83, 16, v0
    v_lshlrev_b32_e32 v83, 2, v83
    ds_bpermute_b32 v82, v83, v64
    s_waitcnt lgkmcnt(0)
    v_add_f32_e32 v64, v64, v82
    v_xor_b32_e32 v83, 32, v0
    v_lshlrev_b32_e32 v83, 2, v83
    ds_bpermute_b32 v82, v83, v64
    s_waitcnt lgkmcnt(0)
    v_add_f32_e32 v64, v64, v82
    v_add_u32_e32 v5, s22, v5
    v_cmp_gt_u32_e32 vcc, s24, v5
    v_mov_b32_e32 v81, 0xff800000
    v_cndmask_b32_e32 v64, v81, v64, vcc
    v_cmp_gt_u32_e32 vcc, s21, v5
    s_and_saveexec_b64 s[30:31], vcc
    v_cmp_gt_u32_e32 vcc, 16, v0
    s_and_b64 exec, exec, vcc
    v_lshlrev_b32_e32 v7, 2, v5
    global_store_dword v7, v64, s[14:15]
    s_mov_b64 exec, s[30:31]
    s_add_u32 s23, s23, 1
    s_cmp_lt_u32 s23, 4
    s_cbranch_scc1 .Lkey_tile
    s_add_u32 s2, s2, 1
    s_cmp_ge_u32 s2, s37
    s_cbranch_scc1 .Ldone
    s_lshl_b32 s22, s2, 6
    s_cmp_ge_u32 s22, s24
    s_cbranch_scc1 .Linvalid_page
    s_branch .Lload_page
.Linvalid_page:
    v_add_u32_e32 v5, s22, v0
    v_cmp_gt_u32_e32 vcc, s21, v5
    s_and_saveexec_b64 s[30:31], vcc
    v_lshlrev_b32_e32 v7, 2, v5
    v_mov_b32_e32 v64, 0xff800000
    global_store_dword v7, v64, s[14:15]
    s_mov_b64 exec, s[30:31]
    s_add_u32 s2, s2, 1
    s_lshl_b32 s22, s2, 6
    s_cmp_lt_u32 s2, s37
    s_cbranch_scc1 .Linvalid_page
.Ldone:
    s_endpgm
.Lend:
.size netra_dsv4_mqa_fp8_h64_d128_gfx950, .Lend-netra_dsv4_mqa_fp8_h64_d128_gfx950

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel netra_dsv4_mqa_fp8_h64_d128_gfx950
    .amdhsa_group_segment_fixed_size 0
    .amdhsa_private_segment_fixed_size 0
    .amdhsa_kernarg_size 76
    .amdhsa_user_sgpr_count 2
    .amdhsa_user_sgpr_kernarg_segment_ptr 1
    .amdhsa_enable_private_segment 0
    .amdhsa_system_sgpr_workgroup_id_x 1
    .amdhsa_system_sgpr_workgroup_id_y 1
    .amdhsa_system_vgpr_workitem_id 0
    .amdhsa_next_free_vgpr 84
    .amdhsa_accum_offset 84
    .amdhsa_next_free_sgpr 40
    .amdhsa_reserve_vcc 1
    .amdhsa_float_denorm_mode_32 3
    .amdhsa_float_denorm_mode_16_64 3
    .amdhsa_dx10_clamp 1
    .amdhsa_ieee_mode 1
    .amdhsa_tg_split 0
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: query_fp8, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global }
      - { .name: paged_kv, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global }
      - { .name: head_weights, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global }
      - { .name: sequence_lengths, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global }
      - { .name: page_table, .offset: 32, .size: 8, .value_kind: global_buffer, .address_space: global }
      - { .name: output_logits, .offset: 40, .size: 8, .value_kind: global_buffer, .address_space: global }
      - { .name: output_row_stride, .offset: 48, .size: 4, .value_kind: by_value }
      - { .name: query_row_bytes, .offset: 52, .size: 4, .value_kind: by_value }
      - { .name: weight_row_bytes, .offset: 56, .size: 4, .value_kind: by_value }
      - { .name: page_table_row_bytes, .offset: 60, .size: 4, .value_kind: by_value }
      - { .name: kv_page_bytes, .offset: 64, .size: 4, .value_kind: by_value }
      - { .name: output_width, .offset: 68, .size: 4, .value_kind: by_value }
      - { .name: pages_per_wave, .offset: 72, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 76
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 64
    .name: netra_dsv4_mqa_fp8_h64_d128_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 40
    .sgpr_spill_count: 0
    .symbol: netra_dsv4_mqa_fp8_h64_d128_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 84
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
