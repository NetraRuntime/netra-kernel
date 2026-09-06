// SPDX-License-Identifier: MIT
// gfx950 C4 paged-MQA scorer. One wave scores a run of pages, overlapping next-key loads with compute.
// FP32 scale/ReLU/weight postprocessing and the original head reduction tree.
// Preshuffle: ((key%16)*16 + (dim%16) + (dim/16)*256 + (key/16)*2048).
// All tensor/page/row bases use 64-bit address arithmetic. Invalid scores
// are written as -infinity; no masked row reads another request's pages.
// Finite E4M3FN inputs; FP32 key scales/weights/output; next_n=1; D=128,H=64.

.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.macro NETRA_MQA_SCORE kb, ke, scale, tile
    v_mfma_f32_16x16x128_f8f6f4 v[64:67], v[8:15], v[\kb:\ke], 0
    v_mfma_f32_16x16x128_f8f6f4 v[68:71], v[16:23], v[\kb:\ke], 0
    v_mfma_f32_16x16x128_f8f6f4 v[72:75], v[24:31], v[\kb:\ke], 0
    v_mfma_f32_16x16x128_f8f6f4 v[76:79], v[32:39], v[\kb:\ke], 0
    // Independent MFMAs cover the early accumulators; preceding head
    // postprocessing covers the final accumulator latency.
    v_pk_mul_f32 v[64:65], v[64:65], v[\scale:(\scale+1)] op_sel_hi:[1,0]
    v_max_f32_e32 v64, 0, v64
    v_max_f32_e32 v65, 0, v65
    v_pk_mul_f32 v[64:65], v[64:65], v[40:41]
    v_pk_mul_f32 v[66:67], v[66:67], v[\scale:(\scale+1)] op_sel_hi:[1,0]
    v_max_f32_e32 v66, 0, v66
    v_max_f32_e32 v67, 0, v67
    v_pk_mul_f32 v[66:67], v[66:67], v[42:43]
    v_pk_mul_f32 v[68:69], v[68:69], v[\scale:(\scale+1)] op_sel_hi:[1,0]
    v_max_f32_e32 v68, 0, v68
    v_max_f32_e32 v69, 0, v69
    v_pk_mul_f32 v[68:69], v[68:69], v[44:45]
    v_pk_mul_f32 v[70:71], v[70:71], v[\scale:(\scale+1)] op_sel_hi:[1,0]
    v_max_f32_e32 v70, 0, v70
    v_max_f32_e32 v71, 0, v71
    v_pk_mul_f32 v[70:71], v[70:71], v[46:47]
    v_pk_mul_f32 v[72:73], v[72:73], v[\scale:(\scale+1)] op_sel_hi:[1,0]
    v_max_f32_e32 v72, 0, v72
    v_max_f32_e32 v73, 0, v73
    v_pk_mul_f32 v[72:73], v[72:73], v[48:49]
    v_pk_mul_f32 v[74:75], v[74:75], v[\scale:(\scale+1)] op_sel_hi:[1,0]
    v_max_f32_e32 v74, 0, v74
    v_max_f32_e32 v75, 0, v75
    v_pk_mul_f32 v[74:75], v[74:75], v[50:51]
    v_pk_mul_f32 v[76:77], v[76:77], v[\scale:(\scale+1)] op_sel_hi:[1,0]
    v_max_f32_e32 v76, 0, v76
    v_max_f32_e32 v77, 0, v77
    v_pk_mul_f32 v[76:77], v[76:77], v[52:53]
    v_pk_mul_f32 v[78:79], v[78:79], v[\scale:(\scale+1)] op_sel_hi:[1,0]
    v_max_f32_e32 v78, 0, v78
    v_max_f32_e32 v79, 0, v79
    v_pk_mul_f32 v[78:79], v[78:79], v[54:55]
    // Same reduction tree, paired FP32 additions.
    v_pk_add_f32 v[64:65], v[64:65], v[72:73]
    v_pk_add_f32 v[66:67], v[66:67], v[74:75]
    v_pk_add_f32 v[68:69], v[68:69], v[76:77]
    v_pk_add_f32 v[70:71], v[70:71], v[78:79]
    v_pk_add_f32 v[64:65], v[64:65], v[68:69]
    v_pk_add_f32 v[66:67], v[66:67], v[70:71]
    v_pk_add_f32 v[64:65], v[64:65], v[66:67]
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
    v_add_u32_e32 v5, s22, v1
    v_add_u32_e32 v5, (\tile * 16), v5
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
.endm

.protected netra_dsv4_mqa_fp8_pipeline_gfx950
.globl netra_dsv4_mqa_fp8_pipeline_gfx950
.p2align 8
.type netra_dsv4_mqa_fp8_pipeline_gfx950,@function
netra_dsv4_mqa_fp8_pipeline_gfx950:
    s_load_dwordx16 s[4:19], s[0:1], 0
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
    // Issue the first page-table read before query/weight loads.
    s_lshl_b32 s32, s2, 2
    s_load_dword s25, s[12:13], s32
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
    s_branch .Lpage_ready
.Lload_page:
    s_lshl_b32 s32, s2, 2
    s_load_dword s25, s[12:13], s32
.Lpage_ready:
    s_waitcnt lgkmcnt(0)
    // Active page IDs must satisfy the existing KV-pool contract.
    // Padding rows never reach this read.
    s_mul_i32 s32, s25, s20
    s_mul_hi_u32 s33, s25, s20
    s_add_u32 s26, s6, s32
    s_addc_u32 s27, s7, s33
    s_add_u32 s28, s26, 8192
    s_addc_u32 s29, s27, 0
    v_add_u32_e32 v7, 0, v4
    global_load_dwordx4 v[56:59], v7, s[26:27]
    global_load_dwordx4 v[60:63], v7, s[26:27] offset:1024
    v_add_u32_e32 v5, 0, v1
    v_lshlrev_b32_e32 v7, 2, v5
    global_load_dword v80, v7, s[28:29]
    s_waitcnt vmcnt(0)
    v_add_u32_e32 v7, 2048, v4
    global_load_dwordx4 v[84:87], v7, s[26:27]
    global_load_dwordx4 v[88:91], v7, s[26:27] offset:1024
    v_add_u32_e32 v5, 16, v1
    v_lshlrev_b32_e32 v7, 2, v5
    global_load_dword v92, v7, s[28:29]
    NETRA_MQA_SCORE 56, 63, 80, 0
    s_waitcnt vmcnt(0)
    v_add_u32_e32 v7, 4096, v4
    global_load_dwordx4 v[56:59], v7, s[26:27]
    global_load_dwordx4 v[60:63], v7, s[26:27] offset:1024
    v_add_u32_e32 v5, 32, v1
    v_lshlrev_b32_e32 v7, 2, v5
    global_load_dword v80, v7, s[28:29]
    NETRA_MQA_SCORE 84, 91, 92, 1
    s_waitcnt vmcnt(0)
    v_add_u32_e32 v7, 6144, v4
    global_load_dwordx4 v[84:87], v7, s[26:27]
    global_load_dwordx4 v[88:91], v7, s[26:27] offset:1024
    v_add_u32_e32 v5, 48, v1
    v_lshlrev_b32_e32 v7, 2, v5
    global_load_dword v92, v7, s[28:29]
    NETRA_MQA_SCORE 56, 63, 80, 2
    s_waitcnt vmcnt(0)
    NETRA_MQA_SCORE 84, 91, 92, 3
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
.size netra_dsv4_mqa_fp8_pipeline_gfx950, .Lend-netra_dsv4_mqa_fp8_pipeline_gfx950

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel netra_dsv4_mqa_fp8_pipeline_gfx950
    .amdhsa_group_segment_fixed_size 0
    .amdhsa_private_segment_fixed_size 0
    .amdhsa_kernarg_size 76
    .amdhsa_user_sgpr_count 2
    .amdhsa_user_sgpr_kernarg_segment_ptr 1
    .amdhsa_enable_private_segment 0
    .amdhsa_system_sgpr_workgroup_id_x 1
    .amdhsa_system_sgpr_workgroup_id_y 1
    .amdhsa_system_vgpr_workitem_id 0
    .amdhsa_next_free_vgpr 96
    .amdhsa_accum_offset 96
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
    .name: netra_dsv4_mqa_fp8_pipeline_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 40
    .sgpr_spill_count: 0
    .symbol: netra_dsv4_mqa_fp8_pipeline_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 96
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
