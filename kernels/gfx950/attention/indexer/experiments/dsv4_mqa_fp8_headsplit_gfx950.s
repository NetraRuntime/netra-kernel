// SPDX-License-Identifier: MIT
// Four waves split H64 into H16 each, one workgroup per 64-key page run.
// Each wave stores 64 head-partial scores; wave 0 combines them through LDS.
// FP32 summation reassociates across head groups; qualification is required.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.protected netra_dsv4_mqa_fp8_headsplit_gfx950
.globl netra_dsv4_mqa_fp8_headsplit_gfx950
.p2align 8
.type netra_dsv4_mqa_fp8_headsplit_gfx950,@function
netra_dsv4_mqa_fp8_headsplit_gfx950:
    s_load_dwordx16 s[4:19], s[0:1], 0
    s_load_dwordx2 s[20:21], s[0:1], 64
    s_load_dword s36, s[0:1], 72
    s_waitcnt lgkmcnt(0)
    v_lshrrev_b32_e32 v1, 6, v0
    s_nop 4
    v_readfirstlane_b32 s40, v1
    s_nop 4
    v_and_b32_e32 v0, 63, v0

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
    s_lshl_b32 s34, s40, 11
    s_add_u32 s4, s4, s34
    s_addc_u32 s5, s5, 0
    s_lshl_b32 s34, s40, 6
    s_add_u32 s8, s8, s34
    s_addc_u32 s9, s9, 0
    v_and_b32_e32 v1, 15, v0
    v_and_b32_e32 v2, 48, v0
    v_lshlrev_b32_e32 v3, 7, v1
    v_add_u32_e32 v3, v3, v2
    v_lshlrev_b32_e32 v4, 4, v0
    global_load_dwordx4 v[8:11], v3, s[4:5]
    global_load_dwordx4 v[12:15], v3, s[4:5] offset:64
    global_load_dwordx4 v[16:19], v2, s[8:9]
    s_branch .Lpage_ready
.Lload_page:
    s_lshl_b32 s32, s2, 2
    s_load_dword s25, s[12:13], s32
.Lpage_ready:
    s_waitcnt lgkmcnt(0)
    s_mul_i32 s32, s25, s20
    s_mul_hi_u32 s33, s25, s20
    s_add_u32 s26, s6, s32
    s_addc_u32 s27, s7, s33
    s_add_u32 s28, s26, 8192
    s_addc_u32 s29, s27, 0
    v_add_u32_e32 v7, 0, v4
    global_load_dwordx4 v[20:23], v7, s[26:27]
    global_load_dwordx4 v[24:27], v7, s[26:27] offset:1024
    v_lshlrev_b32_e32 v7, 2, v1
    global_load_dword v52, v7, s[28:29] offset:0
    v_add_u32_e32 v7, 2048, v4
    global_load_dwordx4 v[28:31], v7, s[26:27]
    global_load_dwordx4 v[32:35], v7, s[26:27] offset:1024
    v_lshlrev_b32_e32 v7, 2, v1
    global_load_dword v53, v7, s[28:29] offset:64
    v_add_u32_e32 v7, 4096, v4
    global_load_dwordx4 v[36:39], v7, s[26:27]
    global_load_dwordx4 v[40:43], v7, s[26:27] offset:1024
    v_lshlrev_b32_e32 v7, 2, v1
    global_load_dword v54, v7, s[28:29] offset:128
    v_add_u32_e32 v7, 6144, v4
    global_load_dwordx4 v[44:47], v7, s[26:27]
    global_load_dwordx4 v[48:51], v7, s[26:27] offset:1024
    v_lshlrev_b32_e32 v7, 2, v1
    global_load_dword v55, v7, s[28:29] offset:192
    s_waitcnt vmcnt(0)
    v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[20:27], 0
    v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[28:35], 0
    v_mfma_f32_16x16x128_f8f6f4 v[64:67], v[8:15], v[36:43], 0
    v_mfma_f32_16x16x128_f8f6f4 v[68:71], v[8:15], v[44:51], 0
    v_pk_mul_f32 v[56:57], v[56:57], v[52:53] op_sel:[0,0] op_sel_hi:[1,0]
    v_max_f32_e32 v56, 0, v56
    v_max_f32_e32 v57, 0, v57
    v_pk_mul_f32 v[56:57], v[56:57], v[16:17]
    v_pk_mul_f32 v[58:59], v[58:59], v[52:53] op_sel:[0,0] op_sel_hi:[1,0]
    v_max_f32_e32 v58, 0, v58
    v_max_f32_e32 v59, 0, v59
    v_pk_mul_f32 v[58:59], v[58:59], v[18:19]
    v_pk_add_f32 v[56:57], v[56:57], v[58:59]
    v_add_f32_e32 v56, v56, v57
    v_mov_b32_e32 v72, v56
    s_nop 1
    v_permlane16_swap_b32_e32 v56, v72
    s_nop 1
    v_add_f32_e32 v56, v56, v72
    v_mov_b32_e32 v72, v56
    s_nop 1
    v_permlane32_swap_b32_e32 v56, v72
    s_nop 1
    v_add_f32_e32 v56, v56, v72
    s_lshl_b32 s34, s40, 2
    v_lshlrev_b32_e32 v7, 4, v1
    v_add_u32_e32 v7, s34, v7
    v_cmp_gt_u32_e32 vcc, 16, v0
    s_and_saveexec_b64 s[30:31], vcc
    ds_write_b32 v7, v56 offset:0
    s_mov_b64 exec, s[30:31]
    v_pk_mul_f32 v[60:61], v[60:61], v[52:53] op_sel:[0,1] op_sel_hi:[1,1]
    v_max_f32_e32 v60, 0, v60
    v_max_f32_e32 v61, 0, v61
    v_pk_mul_f32 v[60:61], v[60:61], v[16:17]
    v_pk_mul_f32 v[62:63], v[62:63], v[52:53] op_sel:[0,1] op_sel_hi:[1,1]
    v_max_f32_e32 v62, 0, v62
    v_max_f32_e32 v63, 0, v63
    v_pk_mul_f32 v[62:63], v[62:63], v[18:19]
    v_pk_add_f32 v[60:61], v[60:61], v[62:63]
    v_add_f32_e32 v60, v60, v61
    v_mov_b32_e32 v72, v60
    s_nop 1
    v_permlane16_swap_b32_e32 v60, v72
    s_nop 1
    v_add_f32_e32 v60, v60, v72
    v_mov_b32_e32 v72, v60
    s_nop 1
    v_permlane32_swap_b32_e32 v60, v72
    s_nop 1
    v_add_f32_e32 v60, v60, v72
    s_lshl_b32 s34, s40, 2
    v_lshlrev_b32_e32 v7, 4, v1
    v_add_u32_e32 v7, s34, v7
    v_cmp_gt_u32_e32 vcc, 16, v0
    s_and_saveexec_b64 s[30:31], vcc
    ds_write_b32 v7, v60 offset:256
    s_mov_b64 exec, s[30:31]
    v_pk_mul_f32 v[64:65], v[64:65], v[54:55] op_sel:[0,0] op_sel_hi:[1,0]
    v_max_f32_e32 v64, 0, v64
    v_max_f32_e32 v65, 0, v65
    v_pk_mul_f32 v[64:65], v[64:65], v[16:17]
    v_pk_mul_f32 v[66:67], v[66:67], v[54:55] op_sel:[0,0] op_sel_hi:[1,0]
    v_max_f32_e32 v66, 0, v66
    v_max_f32_e32 v67, 0, v67
    v_pk_mul_f32 v[66:67], v[66:67], v[18:19]
    v_pk_add_f32 v[64:65], v[64:65], v[66:67]
    v_add_f32_e32 v64, v64, v65
    v_mov_b32_e32 v72, v64
    s_nop 1
    v_permlane16_swap_b32_e32 v64, v72
    s_nop 1
    v_add_f32_e32 v64, v64, v72
    v_mov_b32_e32 v72, v64
    s_nop 1
    v_permlane32_swap_b32_e32 v64, v72
    s_nop 1
    v_add_f32_e32 v64, v64, v72
    s_lshl_b32 s34, s40, 2
    v_lshlrev_b32_e32 v7, 4, v1
    v_add_u32_e32 v7, s34, v7
    v_cmp_gt_u32_e32 vcc, 16, v0
    s_and_saveexec_b64 s[30:31], vcc
    ds_write_b32 v7, v64 offset:512
    s_mov_b64 exec, s[30:31]
    v_pk_mul_f32 v[68:69], v[68:69], v[54:55] op_sel:[0,1] op_sel_hi:[1,1]
    v_max_f32_e32 v68, 0, v68
    v_max_f32_e32 v69, 0, v69
    v_pk_mul_f32 v[68:69], v[68:69], v[16:17]
    v_pk_mul_f32 v[70:71], v[70:71], v[54:55] op_sel:[0,1] op_sel_hi:[1,1]
    v_max_f32_e32 v70, 0, v70
    v_max_f32_e32 v71, 0, v71
    v_pk_mul_f32 v[70:71], v[70:71], v[18:19]
    v_pk_add_f32 v[68:69], v[68:69], v[70:71]
    v_add_f32_e32 v68, v68, v69
    v_mov_b32_e32 v72, v68
    s_nop 1
    v_permlane16_swap_b32_e32 v68, v72
    s_nop 1
    v_add_f32_e32 v68, v68, v72
    v_mov_b32_e32 v72, v68
    s_nop 1
    v_permlane32_swap_b32_e32 v68, v72
    s_nop 1
    v_add_f32_e32 v68, v68, v72
    s_lshl_b32 s34, s40, 2
    v_lshlrev_b32_e32 v7, 4, v1
    v_add_u32_e32 v7, s34, v7
    v_cmp_gt_u32_e32 vcc, 16, v0
    s_and_saveexec_b64 s[30:31], vcc
    ds_write_b32 v7, v68 offset:768
    s_mov_b64 exec, s[30:31]
    s_waitcnt lgkmcnt(0)
    s_barrier
    s_cmp_lg_u32 s40, 0
    s_cbranch_scc1 .Lnext
    v_lshlrev_b32_e32 v7, 4, v0
    ds_read_b128 v[56:59], v7
    s_waitcnt lgkmcnt(0)
    v_pk_add_f32 v[56:57], v[56:57], v[58:59]
    v_add_f32_e32 v56, v56, v57
    v_add_u32_e32 v5, s22, v0
    v_cmp_gt_u32_e32 vcc, s24, v5
    v_mov_b32_e32 v6, 0xff800000
    v_cndmask_b32_e32 v56, v6, v56, vcc
    v_cmp_gt_u32_e32 vcc, s21, v5
    s_and_saveexec_b64 s[30:31], vcc
    v_lshlrev_b32_e32 v7, 2, v5
    global_store_dword v7, v56, s[14:15]
    s_mov_b64 exec, s[30:31]
.Lnext:
    s_add_u32 s2, s2, 1
    s_cmp_ge_u32 s2, s37
    s_cbranch_scc1 .Ldone
    // Prevent the next page from overwriting partials before wave 0 reads.
    s_barrier
    s_lshl_b32 s22, s2, 6
    s_cmp_ge_u32 s22, s24
    s_cbranch_scc1 .Linvalid_page
    s_branch .Lload_page
.Linvalid_page:
    s_cmp_lg_u32 s40, 0
    s_cbranch_scc1 .Ldone
.Lfill:
    v_add_u32_e32 v5, s22, v0
    v_cmp_gt_u32_e32 vcc, s21, v5
    s_and_saveexec_b64 s[30:31], vcc
    v_lshlrev_b32_e32 v7, 2, v5
    v_mov_b32_e32 v56, 0xff800000
    global_store_dword v7, v56, s[14:15]
    s_mov_b64 exec, s[30:31]
    s_add_u32 s2, s2, 1
    s_lshl_b32 s22, s2, 6
    s_cmp_lt_u32 s2, s37
    s_cbranch_scc1 .Lfill
.Ldone:
    s_endpgm
.Lend:
.size netra_dsv4_mqa_fp8_headsplit_gfx950, .Lend-netra_dsv4_mqa_fp8_headsplit_gfx950
.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel netra_dsv4_mqa_fp8_headsplit_gfx950
    .amdhsa_group_segment_fixed_size 1024
    .amdhsa_private_segment_fixed_size 0
    .amdhsa_kernarg_size 76
    .amdhsa_user_sgpr_count 2
    .amdhsa_user_sgpr_kernarg_segment_ptr 1
    .amdhsa_enable_private_segment 0
    .amdhsa_system_sgpr_workgroup_id_x 1
    .amdhsa_system_sgpr_workgroup_id_y 1
    .amdhsa_system_vgpr_workitem_id 0
    .amdhsa_next_free_vgpr 76
    .amdhsa_accum_offset 76
    .amdhsa_next_free_sgpr 44
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
    .group_segment_fixed_size: 1024
    .kernarg_segment_align: 8
    .kernarg_segment_size: 76
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: netra_dsv4_mqa_fp8_headsplit_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 44
    .sgpr_spill_count: 0
    .symbol: netra_dsv4_mqa_fp8_headsplit_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 76
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
