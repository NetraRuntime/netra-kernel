// SPDX-License-Identifier: MIT
// Experimental fused raw gfx1151 GDN KKT construction + blockwise triangular solve.
// Fixed B1,T8192,H32,Hg16,K128,BT64,BC16. Grid=(128,32), block=32.

.amdgcn_target "amdgcn-amd-amdhsa--gfx1151"
.amdhsa_code_object_version 6
.text

.macro RNE_BF16 dst, src, tmp
  v_lshrrev_b32_e32 \tmp, 16, \src
  v_and_b32_e32 \tmp, 1, \tmp
  v_add_nc_u32_e32 \dst, 0x7fff, \src
  v_add_nc_u32_e32 \dst, \tmp, \dst
  v_lshrrev_b32_e32 \dst, 16, \dst
.endm

.macro COMPUTE_BLOCK rb, cb
  s_add_u32 s22, s30, (\rb*16)
  s_add_u32 s23, s30, (\cb*16)
  .if \rb > \cb
    s_mov_b32 s26, 16
  .else
    s_mov_b32 s26, 0
  .endif

  v_dual_mov_b32 v64, 0 :: v_dual_mov_b32 v65, 0
  v_dual_mov_b32 v66, 0 :: v_dual_mov_b32 v67, 0
  v_dual_mov_b32 v68, 0 :: v_dual_mov_b32 v69, 0
  v_dual_mov_b32 v70, 0 :: v_dual_mov_b32 v71, 0

  .set DK, 0
  .rept 8
    v_add_nc_u32_e32 v202, s22, v200
    v_lshlrev_b32_e32 v204, 12, v202
    v_add_nc_u32_e32 v204, s25, v204
    v_lshl_add_u32 v204, v201, 4, v204
    v_add_nc_u32_e32 v204, (DK*32), v204
    global_load_b128 v[24:27], v204, s[8:9]
    v_add_nc_u32_e32 v203, s23, v200
    v_lshlrev_b32_e32 v205, 12, v203
    v_add_nc_u32_e32 v205, s25, v205
    v_lshl_add_u32 v205, v201, 4, v205
    v_add_nc_u32_e32 v205, (DK*32), v205
    global_load_b128 v[28:31], v205, s[8:9]
    s_waitcnt vmcnt(0)

    ds_bpermute_b32 v34, v32, v24
    ds_bpermute_b32 v35, v33, v24
    ds_bpermute_b32 v36, v32, v25
    ds_bpermute_b32 v37, v33, v25
    ds_bpermute_b32 v38, v32, v26
    ds_bpermute_b32 v39, v33, v26
    ds_bpermute_b32 v40, v32, v27
    ds_bpermute_b32 v41, v33, v27
    s_waitcnt lgkmcnt(0)
    v_cmp_gt_u32_e32 vcc_lo, 16, v1
    v_cndmask_b32_e32 v8, v35, v34, vcc_lo
    v_cndmask_b32_e32 v12, v34, v35, vcc_lo
    v_cndmask_b32_e32 v9, v37, v36, vcc_lo
    v_cndmask_b32_e32 v13, v36, v37, vcc_lo
    v_cndmask_b32_e32 v10, v39, v38, vcc_lo
    v_cndmask_b32_e32 v14, v38, v39, vcc_lo
    v_cndmask_b32_e32 v11, v41, v40, vcc_lo
    v_cndmask_b32_e32 v15, v40, v41, vcc_lo

    ds_bpermute_b32 v34, v32, v28
    ds_bpermute_b32 v35, v33, v28
    ds_bpermute_b32 v36, v32, v29
    ds_bpermute_b32 v37, v33, v29
    ds_bpermute_b32 v38, v32, v30
    ds_bpermute_b32 v39, v33, v30
    ds_bpermute_b32 v40, v32, v31
    ds_bpermute_b32 v41, v33, v31
    s_waitcnt lgkmcnt(0)
    v_cmp_gt_u32_e32 vcc_lo, 16, v1
    v_cndmask_b32_e32 v16, v35, v34, vcc_lo
    v_cndmask_b32_e32 v20, v34, v35, vcc_lo
    v_cndmask_b32_e32 v17, v37, v36, vcc_lo
    v_cndmask_b32_e32 v21, v36, v37, vcc_lo
    v_cndmask_b32_e32 v18, v39, v38, vcc_lo
    v_cndmask_b32_e32 v22, v38, v39, vcc_lo
    v_cndmask_b32_e32 v19, v41, v40, vcc_lo
    v_cndmask_b32_e32 v23, v40, v41, vcc_lo
    v_wmma_f32_16x16x16_bf16 v[64:71], v[8:15], v[16:23], v[64:71]
    .set DK, DK+1
  .endr

  v_add_nc_u32_e32 v80, s23, v3
  v_lshlrev_b32_e32 v80, 7, v80
  v_lshl_add_u32 v80, s3, 2, v80
  global_load_dword v80, v80, s[10:11]
  s_waitcnt vmcnt(0)

  .set RR, 0
  .rept 8
    v_add_nc_u32_e32 v81, (RR*2), v4
    v_add_nc_u32_e32 v82, s22, v81
    v_lshlrev_b32_e32 v83, 7, v82
    v_lshl_add_u32 v83, s3, 2, v83
    global_load_dword v84, v83, s[10:11]
    v_lshlrev_b32_e32 v85, 7, v82
    v_lshl_add_u32 v85, s3, 2, v85
    global_load_dword v86, v85, s[12:13]
    s_waitcnt vmcnt(0)
    v_sub_f32_e32 v87, v84, v80
    v_mov_b32_e32 v88, 0
    v_cmp_le_f32_e32 vcc_lo, v87, v88
    v_cndmask_b32_e32 v87, 0xff800000, v87, vcc_lo
    v_mul_f32_e32 v87, 0x3fb8aa3b, v87
    v_exp_f32_e32 v87, v87
    v_mul_f32_e32 v[64+RR], v[64+RR], v87
    v_mul_f32_e32 v[64+RR], v[64+RR], v86
    v_add_nc_u32_e32 v89, s26, v81
    v_cmp_gt_u32_e32 vcc_lo, v89, v3
    v_cndmask_b32_e32 v[64+RR], 0, v[64+RR], vcc_lo

    v_add_nc_u32_e32 v90, (\rb*16), v81
    v_lshlrev_b32_e32 v90, 8, v90
    v_lshl_add_u32 v90, v3, 2, v90
    v_add_nc_u32_e32 v90, (\cb*64), v90
    ds_write_b32 v90, v[64+RR]
    .set RR, RR+1
  .endr
.endm

// Solve two adjacent 16x16 diagonal blocks in parallel. Lanes 0-15 own the
// first block and lanes 16-31 own the second; each lane owns one column.
.macro SOLVE_DIAG_PAIR first_block
  v_lshrrev_b32_e32 v120, 4, v1
  v_lshlrev_b32_e32 v120, 4, v120
  v_add_nc_u32_e32 v120, (\first_block*16), v120
  s_mov_b32 s40, 0
.Ldiag_init_\@:
  v_add_nc_u32_e32 v121, s40, v120
  v_lshlrev_b32_e32 v122, 8, v121
  v_add_nc_u32_e32 v123, v120, v3
  v_lshl_add_u32 v122, v123, 2, v122
  ds_load_b32 v124, v122
  s_waitcnt lgkmcnt(0)
  v_xor_b32_e32 v124, 0x80000000, v124
  v_cmp_gt_u32_e32 vcc_lo, s40, v3
  v_cndmask_b32_e32 v124, 0, v124, vcc_lo
  ds_write_b32 v122, v124
  s_add_u32 s40, s40, 1
  s_cmp_lt_u32 s40, 16
  s_cbranch_scc1 .Ldiag_init_\@
  s_waitcnt lgkmcnt(0)
  s_mov_b32 s40, 2
.Ldiag_row_\@:
  v_add_nc_u32_e32 v121, s40, v120
  v_lshlrev_b32_e32 v122, 8, v121
  v_add_nc_u32_e32 v123, v120, v3
  v_lshl_add_u32 v122, v123, 2, v122
  ds_load_b32 v126, v122
  // Match the production Triton blocked1 axis-0 reduction exactly. For a
  // representative row lane it reduces k with xor distances 8,4,2,1; the
  // distance-8 pair is fma(row[k], inv[k,col], mul(row[k+8],inv[k+8,col])).
  .set KK, 0
  .rept 16
    v_lshlrev_b32_e32 v124, 8, v121
    v_lshl_add_u32 v124, v120, 2, v124
    v_add_nc_u32_e32 v124, (KK*4), v124
    v_add_nc_u32_e32 v127, KK, v120
    v_lshlrev_b32_e32 v127, 8, v127
    v_lshl_add_u32 v127, v123, 2, v127
    ds_load_b32 v[140+KK], v124
    ds_load_b32 v[156+KK], v127
    .set KK, KK+1
  .endr
  s_waitcnt lgkmcnt(0)
  s_bitcmp1_b32 s40, 3
  s_cbranch_scc1 .Ldiag_high_half_\@
  .set KK, 0
  .rept 8
    v_mul_f32_e32 v[172+KK], v[148+KK], v[164+KK]
    v_fma_f32 v[172+KK], v[140+KK], v[156+KK], v[172+KK]
    .set KK, KK+1
  .endr
  s_branch .Ldiag_tree_\@
.Ldiag_high_half_\@:
  .set KK, 0
  .rept 8
    v_mul_f32_e32 v[172+KK], v[140+KK], v[156+KK]
    v_fma_f32 v[172+KK], v[148+KK], v[164+KK], v[172+KK]
    .set KK, KK+1
  .endr
.Ldiag_tree_\@:
  v_add_f32_e32 v172, v172, v176
  v_add_f32_e32 v173, v173, v177
  v_add_f32_e32 v174, v174, v178
  v_add_f32_e32 v175, v175, v179
  v_add_f32_e32 v172, v172, v174
  v_add_f32_e32 v173, v173, v175
  v_add_f32_e32 v172, v172, v173
  v_add_f32_e32 v126, v126, v172
  v_cmp_gt_u32_e32 vcc_lo, s40, v3
  v_cndmask_b32_e32 v126, 0, v126, vcc_lo
  ds_write_b32 v122, v126
  s_waitcnt lgkmcnt(0)
  s_add_u32 s40, s40, 1
  s_cmp_lt_u32 s40, 16
  s_cbranch_scc1 .Ldiag_row_\@
  v_lshlrev_b32_e32 v122, 8, v123
  v_lshl_add_u32 v122, v123, 2, v122
  v_mov_b32_e32 v124, 0x3f800000
  ds_write_b32 v122, v124
  s_waitcnt lgkmcnt(0)
.endm

// Scalar IEEE 16x16 matrix multiply. Each lane owns one row and eight columns.
.macro MATMUL16 dr, dc, lr, lc, rr, rc, neg
  v_dual_mov_b32 v130, 0 :: v_dual_mov_b32 v131, 0
  v_dual_mov_b32 v132, 0 :: v_dual_mov_b32 v133, 0
  v_dual_mov_b32 v134, 0 :: v_dual_mov_b32 v135, 0
  v_dual_mov_b32 v136, 0 :: v_dual_mov_b32 v137, 0
  v_lshlrev_b32_e32 v120, 8, v200
  v_add_nc_u32_e32 v120, (\lr*4096 + \lc*64), v120
  v_lshlrev_b32_e32 v121, 5, v201
  v_add_nc_u32_e32 v121, (\rr*4096 + \rc*64), v121
  s_mov_b32 s41, 0
.Lmm_k_\@:
  v_mov_b32_e32 v122, s41
  v_lshlrev_b32_e32 v122, 2, v122
  v_add_nc_u32_e32 v122, v120, v122
  s_lshl_b32 s44, s41, 8
  v_add_nc_u32_e32 v123, s44, v121
  ds_load_b32 v138, v122
  ds_load_b128 v[140:143], v123
  ds_load_b128 v[144:147], v123 offset:16
  s_waitcnt lgkmcnt(0)
  v_fma_f32 v130, v138, v140, v130
  v_fma_f32 v131, v138, v141, v131
  v_fma_f32 v132, v138, v142, v132
  v_fma_f32 v133, v138, v143, v133
  v_fma_f32 v134, v138, v144, v134
  v_fma_f32 v135, v138, v145, v135
  v_fma_f32 v136, v138, v146, v136
  v_fma_f32 v137, v138, v147, v137
  s_add_u32 s41, s41, 1
  s_cmp_lt_u32 s41, 16
  s_cbranch_scc1 .Lmm_k_\@
  .if \neg
    v_xor_b32_e32 v130, 0x80000000, v130
    v_xor_b32_e32 v131, 0x80000000, v131
    v_xor_b32_e32 v132, 0x80000000, v132
    v_xor_b32_e32 v133, 0x80000000, v133
    v_xor_b32_e32 v134, 0x80000000, v134
    v_xor_b32_e32 v135, 0x80000000, v135
    v_xor_b32_e32 v136, 0x80000000, v136
    v_xor_b32_e32 v137, 0x80000000, v137
  .endif
  v_lshlrev_b32_e32 v124, 8, v200
  v_add_nc_u32_e32 v124, (\dr*4096 + \dc*64), v124
  v_lshl_add_u32 v124, v201, 5, v124
  ds_write_b128 v124, v[130:133]
  ds_write_b128 v124, v[134:137] offset:16
  s_waitcnt lgkmcnt(0)
.endm

// Continue a prior MATMUL16 destination with another 16 K terms. Triton
// folds adjacent tt.dot additions into one continuous FP32 FMA accumulator.
.macro MATMUL16_ACC dr, dc, lr, lc, rr, rc
  v_lshlrev_b32_e32 v120, 8, v200
  v_lshlrev_b32_e32 v121, 5, v201
  v_add_nc_u32_e32 v124, (\dr*4096 + \dc*64), v120
  v_add_nc_u32_e32 v124, v121, v124
  ds_load_b128 v[130:133], v124
  ds_load_b128 v[134:137], v124 offset:16
  v_add_nc_u32_e32 v120, (\lr*4096 + \lc*64), v120
  v_add_nc_u32_e32 v121, (\rr*4096 + \rc*64), v121
  s_waitcnt lgkmcnt(0)
  s_mov_b32 s41, 0
.Lmm_acc_k_\@:
  v_mov_b32_e32 v122, s41
  v_lshlrev_b32_e32 v122, 2, v122
  v_add_nc_u32_e32 v122, v120, v122
  s_lshl_b32 s44, s41, 8
  v_add_nc_u32_e32 v123, s44, v121
  ds_load_b32 v138, v122
  ds_load_b128 v[140:143], v123
  ds_load_b128 v[144:147], v123 offset:16
  s_waitcnt lgkmcnt(0)
  v_fma_f32 v130, v138, v140, v130
  v_fma_f32 v131, v138, v141, v131
  v_fma_f32 v132, v138, v142, v132
  v_fma_f32 v133, v138, v143, v133
  v_fma_f32 v134, v138, v144, v134
  v_fma_f32 v135, v138, v145, v135
  v_fma_f32 v136, v138, v146, v136
  v_fma_f32 v137, v138, v147, v137
  s_add_u32 s41, s41, 1
  s_cmp_lt_u32 s41, 16
  s_cbranch_scc1 .Lmm_acc_k_\@
  ds_write_b128 v124, v[130:133]
  ds_write_b128 v124, v[134:137] offset:16
  s_waitcnt lgkmcnt(0)
.endm

.macro ADD16 dr, dc, ar, ac, br, bc
  v_lshlrev_b32_e32 v120, 8, v200
  v_lshlrev_b32_e32 v121, 5, v201
  v_add_nc_u32_e32 v122, (\ar*4096 + \ac*64), v120
  v_add_nc_u32_e32 v122, v121, v122
  v_add_nc_u32_e32 v123, (\br*4096 + \bc*64), v120
  v_add_nc_u32_e32 v123, v121, v123
  ds_load_b128 v[130:133], v122
  ds_load_b128 v[134:137], v122 offset:16
  ds_load_b128 v[140:143], v123
  ds_load_b128 v[144:147], v123 offset:16
  s_waitcnt lgkmcnt(0)
  v_add_f32_e32 v130, v130, v140
  v_add_f32_e32 v131, v131, v141
  v_add_f32_e32 v132, v132, v142
  v_add_f32_e32 v133, v133, v143
  v_add_f32_e32 v134, v134, v144
  v_add_f32_e32 v135, v135, v145
  v_add_f32_e32 v136, v136, v146
  v_add_f32_e32 v137, v137, v147
  v_add_nc_u32_e32 v124, (\dr*4096 + \dc*64), v120
  v_add_nc_u32_e32 v124, v121, v124
  ds_write_b128 v124, v[130:133]
  ds_write_b128 v124, v[134:137] offset:16
  s_waitcnt lgkmcnt(0)
.endm
.protected gdn_kkt_solve_blockwise_gfx1151
.globl gdn_kkt_solve_blockwise_gfx1151
.p2align 8
.type gdn_kkt_solve_blockwise_gfx1151,@function
gdn_kkt_solve_blockwise_gfx1151:
  // k,g,beta,out_bf16. s2=chunk, s3=head.
  s_clause 0x1
  s_load_b128 s[8:11], s[0:1], 0
  s_load_b128 s[12:15], s[0:1], 16
  s_waitcnt lgkmcnt(0)

  s_lshl_b32 s30, s2, 6
  s_lshr_b32 s25, s3, 1
  s_lshl_b32 s25, s25, 8
  v_and_b32_e32 v1, 31, v0
  v_and_b32_e32 v3, 15, v0
  v_lshrrev_b32_e32 v4, 4, v1
  v_lshrrev_b32_e32 v200, 1, v1
  v_and_b32_e32 v201, 1, v1
  v_and_b32_e32 v30, 16, v1
  v_lshrrev_b32_e32 v31, 2, v30
  v_and_b32_e32 v32, 15, v1
  v_lshl_or_b32 v32, v32, 3, v31
  v_xor_b32_e32 v33, 4, v32

  COMPUTE_BLOCK 0, 0
  COMPUTE_BLOCK 1, 0
  COMPUTE_BLOCK 1, 1
  COMPUTE_BLOCK 2, 0
  COMPUTE_BLOCK 2, 1
  COMPUTE_BLOCK 2, 2
  COMPUTE_BLOCK 3, 0
  COMPUTE_BLOCK 3, 1
  COMPUTE_BLOCK 3, 2
  COMPUTE_BLOCK 3, 3
  s_waitcnt lgkmcnt(0)

  // Production block dependency order; upper LDS blocks are scratch.
  SOLVE_DIAG_PAIR 0
  SOLVE_DIAG_PAIR 2
  MATMUL16 0,1, 1,1, 1,0, 0
  MATMUL16 1,0, 0,1, 0,0, 1
  MATMUL16 0,1, 2,0, 0,0, 0
  MATMUL16_ACC 0,1, 2,1, 1,0
  MATMUL16 2,0, 2,2, 0,1, 1
  MATMUL16 0,1, 3,0, 0,0, 0
  MATMUL16_ACC 0,1, 3,1, 1,0
  MATMUL16_ACC 0,1, 3,2, 2,0
  MATMUL16 3,0, 3,3, 0,1, 1
  MATMUL16 0,1, 2,2, 2,1, 0
  MATMUL16 2,1, 0,1, 1,1, 1
  MATMUL16 0,1, 3,1, 1,1, 0
  MATMUL16_ACC 0,1, 3,2, 2,1
  MATMUL16 3,1, 3,3, 0,1, 1
  MATMUL16 0,1, 3,3, 3,2, 0
  MATMUL16 3,2, 0,1, 2,2, 1

  v_lshlrev_b32_e32 v104, 2, v1
  v_add_nc_u32_e32 v2, 32, v1
  s_mov_b32 s40, 0
.Lstore_row:
  s_lshl_b32 s42, s40, 8
  v_add_nc_u32_e32 v100, s42, v104
  v_add_nc_u32_e32 v101, 128, v100
  ds_load_b32 v106, v100
  ds_load_b32 v107, v101
  s_waitcnt lgkmcnt(0)
  v_cmp_ge_u32_e32 vcc_lo, s40, v1
  v_cndmask_b32_e32 v106, 0, v106, vcc_lo
  v_cmp_ge_u32_e32 vcc_lo, s40, v2
  v_cndmask_b32_e32 v107, 0, v107, vcc_lo
  RNE_BF16 v110, v106, v111
  RNE_BF16 v112, v107, v113
  v_cmp_neq_f32_e32 vcc_lo, 0, v106
  v_cndmask_b32_e32 v110, 0, v110, vcc_lo
  v_cmp_neq_f32_e32 vcc_lo, 0, v107
  v_cndmask_b32_e32 v112, 0, v112, vcc_lo
  s_add_u32 s45, s30, s40
  s_lshl_b32 s45, s45, 12
  s_lshl_b32 s46, s3, 7
  s_add_u32 s45, s45, s46
  v_lshlrev_b32_e32 v117, 1, v1
  v_add_nc_u32_e32 v117, s45, v117
  v_add_nc_u32_e32 v118, 64, v117
  global_store_short v117, v110, s[14:15]
  global_store_short v118, v112, s[14:15]
  s_add_u32 s40, s40, 1
  s_cmp_lt_u32 s40, 64
  s_cbranch_scc1 .Lstore_row
  s_waitcnt vmcnt(0)
  s_endpgm

.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel gdn_kkt_solve_blockwise_gfx1151
.amdhsa_group_segment_fixed_size 16384
.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size 32
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_wavefront_size32 1
.amdhsa_enable_private_segment 0
.amdhsa_system_sgpr_workgroup_id_x 1
.amdhsa_system_sgpr_workgroup_id_y 1
.amdhsa_system_sgpr_workgroup_id_z 0
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_vgpr 206
.amdhsa_next_free_sgpr 48
.amdhsa_reserve_vcc 1
.amdhsa_float_denorm_mode_32 3
.amdhsa_float_denorm_mode_16_64 3
.amdhsa_dx10_clamp 1
.amdhsa_ieee_mode 1
.amdhsa_workgroup_processor_mode 1
.amdhsa_memory_ordered 1
.amdhsa_forward_progress 1
.end_amdhsa_kernel
.text
.Lfunc_end0:
.size gdn_kkt_solve_blockwise_gfx1151, .Lfunc_end0-gdn_kkt_solve_blockwise_gfx1151

.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: k, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: g, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: beta, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: out_bf16, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
    .group_segment_fixed_size: 16384
    .kernarg_segment_align: 8
    .kernarg_segment_size: 32
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 32
    .name: gdn_kkt_solve_blockwise_gfx1151
    .private_segment_fixed_size: 0
    .sgpr_count: 48
    .sgpr_spill_count: 0
    .symbol: gdn_kkt_solve_blockwise_gfx1151.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 206
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target: amdgcn-amd-amdhsa--gfx1151
amdhsa.version: [1, 2]
...
.end_amdgpu_metadata
