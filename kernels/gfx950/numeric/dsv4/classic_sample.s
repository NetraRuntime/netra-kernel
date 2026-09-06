// SPDX-License-Identifier: MIT
// Handwritten gfx950 DSV4 control operation: classic_sample.
// ABI: sixteen 64-bit pointers followed by sixteen uint32 scalars (192 bytes).
// Caller supplies valid, non-aliasing tensors on the owning device/stream.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.protected netra_dsv4_classic_sample
.globl netra_dsv4_classic_sample
.p2align 8
.type netra_dsv4_classic_sample,@function
netra_dsv4_classic_sample:
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
    s_lshl_b32 s60, s2, 2
    s_load_dword s32, s[16:17], s60
    s_mul_i32 s60, s2, s46
    s_lshl_b32 s60, s60, 2
    v_and_b32 v1, 63, v0
    v_lshlrev_b32 v2, 2, v1
    v_add_u32 v2, s60, v2
    v_mov_b32 v4, 0
    v_cmp_gt_u32 vcc, s46, v1
    s_and_saveexec_b64 s[58:59], vcc
    global_load_dword v4, v2, s[24:25]
    s_waitcnt vmcnt(0)
    s_mov_b64 exec, s[58:59]
    s_waitcnt lgkmcnt(0)
    s_mov_b64 exec, 1
    v_mov_b32 v16, 0
    v_mov_b32 v17, 0
    s_mov_b32 s56, 0
.Lsum_tiles:
    s_cmp_lg_u32 s56, s29
    s_cbranch_scc1 .Lnot_current
    v_mov_b32 v17, v16
.Lnot_current:
    v_readlane_b32 s52, v4, s56
    s_nop 4
    v_add_f32 v16, v16, s52
    s_add_u32 s56, s56, 1
    s_cmp_lt_u32 s56, s46
    s_cbranch_scc1 .Lsum_tiles
    s_nop 4
    v_readfirstlane_b32 s30, v16
    v_readfirstlane_b32 s31, v17
    s_nop 4
    s_mov_b64 exec, -1
    v_add_f32 v25, v24, v25
    v_add_f32 v26, v25, v26
    v_add_f32 v27, v26, v27
    v_mov_b32 v40, v27
    v_sub_u32 v2, v1, 1
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v40
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v40, v9
    v_cmp_ge_u32 vcc, v1, 1
    v_cndmask_b32 v40, v40, v10, vcc
    v_sub_u32 v2, v1, 2
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v40
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v40, v9
    v_cmp_ge_u32 vcc, v1, 2
    v_cndmask_b32 v40, v40, v10, vcc
    v_sub_u32 v2, v1, 4
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v40
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v40, v9
    v_cmp_ge_u32 vcc, v1, 4
    v_cndmask_b32 v40, v40, v10, vcc
    v_sub_u32 v2, v1, 8
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v40
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v40, v9
    v_cmp_ge_u32 vcc, v1, 8
    v_cndmask_b32 v40, v40, v10, vcc
    v_sub_u32 v2, v1, 16
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v40
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v40, v9
    v_cmp_ge_u32 vcc, v1, 16
    v_cndmask_b32 v40, v40, v10, vcc
    v_sub_u32 v2, v1, 32
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v40
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v40, v9
    v_cmp_ge_u32 vcc, v1, 32
    v_cndmask_b32 v40, v40, v10, vcc
    s_nop 4
    v_readlane_b32 s52, v40, 63
    s_nop 4
    s_mov_b64 exec, 1
    s_lshl_b32 s60, s62, 2
    v_mov_b32 v2, s60
    v_mov_b32 v4, s52
    ds_write_b32 v2, v4 offset:0
    s_waitcnt lgkmcnt(0)
    s_mov_b64 exec, -1
    v_add_f32 v29, v28, v29
    v_add_f32 v30, v29, v30
    v_add_f32 v31, v30, v31
    v_mov_b32 v41, v31
    v_sub_u32 v2, v1, 1
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v41
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v41, v9
    v_cmp_ge_u32 vcc, v1, 1
    v_cndmask_b32 v41, v41, v10, vcc
    v_sub_u32 v2, v1, 2
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v41
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v41, v9
    v_cmp_ge_u32 vcc, v1, 2
    v_cndmask_b32 v41, v41, v10, vcc
    v_sub_u32 v2, v1, 4
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v41
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v41, v9
    v_cmp_ge_u32 vcc, v1, 4
    v_cndmask_b32 v41, v41, v10, vcc
    v_sub_u32 v2, v1, 8
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v41
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v41, v9
    v_cmp_ge_u32 vcc, v1, 8
    v_cndmask_b32 v41, v41, v10, vcc
    v_sub_u32 v2, v1, 16
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v41
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v41, v9
    v_cmp_ge_u32 vcc, v1, 16
    v_cndmask_b32 v41, v41, v10, vcc
    v_sub_u32 v2, v1, 32
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v41
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v41, v9
    v_cmp_ge_u32 vcc, v1, 32
    v_cndmask_b32 v41, v41, v10, vcc
    s_nop 4
    v_readlane_b32 s52, v41, 63
    s_nop 4
    s_mov_b64 exec, 1
    s_lshl_b32 s60, s62, 2
    v_mov_b32 v2, s60
    v_mov_b32 v4, s52
    ds_write_b32 v2, v4 offset:16
    s_waitcnt lgkmcnt(0)
    s_mov_b64 exec, -1
    v_add_f32 v33, v32, v33
    v_add_f32 v34, v33, v34
    v_add_f32 v35, v34, v35
    v_mov_b32 v42, v35
    v_sub_u32 v2, v1, 1
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v42
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v42, v9
    v_cmp_ge_u32 vcc, v1, 1
    v_cndmask_b32 v42, v42, v10, vcc
    v_sub_u32 v2, v1, 2
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v42
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v42, v9
    v_cmp_ge_u32 vcc, v1, 2
    v_cndmask_b32 v42, v42, v10, vcc
    v_sub_u32 v2, v1, 4
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v42
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v42, v9
    v_cmp_ge_u32 vcc, v1, 4
    v_cndmask_b32 v42, v42, v10, vcc
    v_sub_u32 v2, v1, 8
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v42
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v42, v9
    v_cmp_ge_u32 vcc, v1, 8
    v_cndmask_b32 v42, v42, v10, vcc
    v_sub_u32 v2, v1, 16
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v42
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v42, v9
    v_cmp_ge_u32 vcc, v1, 16
    v_cndmask_b32 v42, v42, v10, vcc
    v_sub_u32 v2, v1, 32
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v42
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v42, v9
    v_cmp_ge_u32 vcc, v1, 32
    v_cndmask_b32 v42, v42, v10, vcc
    s_nop 4
    v_readlane_b32 s52, v42, 63
    s_nop 4
    s_mov_b64 exec, 1
    s_lshl_b32 s60, s62, 2
    v_mov_b32 v2, s60
    v_mov_b32 v4, s52
    ds_write_b32 v2, v4 offset:32
    s_waitcnt lgkmcnt(0)
    s_mov_b64 exec, -1
    v_add_f32 v37, v36, v37
    v_add_f32 v38, v37, v38
    v_add_f32 v39, v38, v39
    v_mov_b32 v43, v39
    v_sub_u32 v2, v1, 1
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v43
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v43, v9
    v_cmp_ge_u32 vcc, v1, 1
    v_cndmask_b32 v43, v43, v10, vcc
    v_sub_u32 v2, v1, 2
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v43
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v43, v9
    v_cmp_ge_u32 vcc, v1, 2
    v_cndmask_b32 v43, v43, v10, vcc
    v_sub_u32 v2, v1, 4
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v43
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v43, v9
    v_cmp_ge_u32 vcc, v1, 4
    v_cndmask_b32 v43, v43, v10, vcc
    v_sub_u32 v2, v1, 8
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v43
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v43, v9
    v_cmp_ge_u32 vcc, v1, 8
    v_cndmask_b32 v43, v43, v10, vcc
    v_sub_u32 v2, v1, 16
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v43
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v43, v9
    v_cmp_ge_u32 vcc, v1, 16
    v_cndmask_b32 v43, v43, v10, vcc
    v_sub_u32 v2, v1, 32
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v43
    s_waitcnt lgkmcnt(0)
    v_add_f32 v10, v43, v9
    v_cmp_ge_u32 vcc, v1, 32
    v_cndmask_b32 v43, v43, v10, vcc
    s_nop 4
    v_readlane_b32 s52, v43, 63
    s_nop 4
    s_mov_b64 exec, 1
    s_lshl_b32 s60, s62, 2
    v_mov_b32 v2, s60
    v_mov_b32 v4, s52
    ds_write_b32 v2, v4 offset:48
    s_waitcnt lgkmcnt(0)
    s_mov_b64 exec, -1
    s_barrier
    v_mov_b32 v19, s30
    v_mov_b32 v16, s32
    v_mul_f32 v19, v19, v16
    v_mov_b32 v16, 0x7fffffff
    // Carry follows the reference's sequential chunk/wave order.
    s_mov_b64 exec, 1
    s_add_u32 s57, s62, 0
    s_mov_b32 s56, 0
    v_mov_b32 v4, 0
.Lcarry0:
    s_cmp_ge_u32 s56, s57
    s_cbranch_scc1 .Lcarry_done0
    s_lshl_b32 s60, s56, 2
    v_mov_b32 v2, s60
    ds_read_b32 v5, v2
    s_waitcnt lgkmcnt(0)
    v_add_f32 v4, v4, v5
    s_add_u32 s56, s56, 1
    s_branch .Lcarry0
.Lcarry_done0:
    s_nop 4
    v_readfirstlane_b32 s52, v4
    s_nop 4
    s_mov_b64 exec, -1
    v_add_f32 v8, v40, s52
    v_sub_u32 v2, v1, 1
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v8
    s_waitcnt lgkmcnt(0)
    v_cmp_eq_u32 vcc, v1, 0
    v_mov_b32 v12, s52
    v_cndmask_b32 v9, v9, v12, vcc
    v_add_f32 v10, v24, v9
    v_add_f32 v10, s31, v10
    v_add_u32 v11, 0, v18
    v_cmp_gt_f32 vcc, v10, v19
    s_mov_b64 s[58:59], vcc
    v_cmp_lt_u32 vcc, v11, s37
    s_and_b64 vcc, vcc, s[58:59]
    v_mov_b32 v13, 0x7fffffff
    v_cndmask_b32 v11, v13, v11, vcc
    v_min_u32 v16, v16, v11
    v_add_f32 v10, v25, v9
    v_add_f32 v10, s31, v10
    v_add_u32 v11, 1, v18
    v_cmp_gt_f32 vcc, v10, v19
    s_mov_b64 s[58:59], vcc
    v_cmp_lt_u32 vcc, v11, s37
    s_and_b64 vcc, vcc, s[58:59]
    v_mov_b32 v13, 0x7fffffff
    v_cndmask_b32 v11, v13, v11, vcc
    v_min_u32 v16, v16, v11
    v_add_f32 v10, v26, v9
    v_add_f32 v10, s31, v10
    v_add_u32 v11, 2, v18
    v_cmp_gt_f32 vcc, v10, v19
    s_mov_b64 s[58:59], vcc
    v_cmp_lt_u32 vcc, v11, s37
    s_and_b64 vcc, vcc, s[58:59]
    v_mov_b32 v13, 0x7fffffff
    v_cndmask_b32 v11, v13, v11, vcc
    v_min_u32 v16, v16, v11
    v_mov_b32 v10, v8
    v_add_f32 v10, s31, v10
    v_add_u32 v11, 3, v18
    v_cmp_gt_f32 vcc, v10, v19
    s_mov_b64 s[58:59], vcc
    v_cmp_lt_u32 vcc, v11, s37
    s_and_b64 vcc, vcc, s[58:59]
    v_mov_b32 v13, 0x7fffffff
    v_cndmask_b32 v11, v13, v11, vcc
    v_min_u32 v16, v16, v11
    // Carry follows the reference's sequential chunk/wave order.
    s_mov_b64 exec, 1
    s_add_u32 s57, s62, 4
    s_mov_b32 s56, 0
    v_mov_b32 v4, 0
.Lcarry1:
    s_cmp_ge_u32 s56, s57
    s_cbranch_scc1 .Lcarry_done1
    s_lshl_b32 s60, s56, 2
    v_mov_b32 v2, s60
    ds_read_b32 v5, v2
    s_waitcnt lgkmcnt(0)
    v_add_f32 v4, v4, v5
    s_add_u32 s56, s56, 1
    s_branch .Lcarry1
.Lcarry_done1:
    s_nop 4
    v_readfirstlane_b32 s52, v4
    s_nop 4
    s_mov_b64 exec, -1
    v_add_f32 v8, v41, s52
    v_sub_u32 v2, v1, 1
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v8
    s_waitcnt lgkmcnt(0)
    v_cmp_eq_u32 vcc, v1, 0
    v_mov_b32 v12, s52
    v_cndmask_b32 v9, v9, v12, vcc
    v_add_f32 v10, v28, v9
    v_add_f32 v10, s31, v10
    v_add_u32 v11, 1024, v18
    v_cmp_gt_f32 vcc, v10, v19
    s_mov_b64 s[58:59], vcc
    v_cmp_lt_u32 vcc, v11, s37
    s_and_b64 vcc, vcc, s[58:59]
    v_mov_b32 v13, 0x7fffffff
    v_cndmask_b32 v11, v13, v11, vcc
    v_min_u32 v16, v16, v11
    v_add_f32 v10, v29, v9
    v_add_f32 v10, s31, v10
    v_add_u32 v11, 1025, v18
    v_cmp_gt_f32 vcc, v10, v19
    s_mov_b64 s[58:59], vcc
    v_cmp_lt_u32 vcc, v11, s37
    s_and_b64 vcc, vcc, s[58:59]
    v_mov_b32 v13, 0x7fffffff
    v_cndmask_b32 v11, v13, v11, vcc
    v_min_u32 v16, v16, v11
    v_add_f32 v10, v30, v9
    v_add_f32 v10, s31, v10
    v_add_u32 v11, 1026, v18
    v_cmp_gt_f32 vcc, v10, v19
    s_mov_b64 s[58:59], vcc
    v_cmp_lt_u32 vcc, v11, s37
    s_and_b64 vcc, vcc, s[58:59]
    v_mov_b32 v13, 0x7fffffff
    v_cndmask_b32 v11, v13, v11, vcc
    v_min_u32 v16, v16, v11
    v_mov_b32 v10, v8
    v_add_f32 v10, s31, v10
    v_add_u32 v11, 1027, v18
    v_cmp_gt_f32 vcc, v10, v19
    s_mov_b64 s[58:59], vcc
    v_cmp_lt_u32 vcc, v11, s37
    s_and_b64 vcc, vcc, s[58:59]
    v_mov_b32 v13, 0x7fffffff
    v_cndmask_b32 v11, v13, v11, vcc
    v_min_u32 v16, v16, v11
    // Carry follows the reference's sequential chunk/wave order.
    s_mov_b64 exec, 1
    s_add_u32 s57, s62, 8
    s_mov_b32 s56, 0
    v_mov_b32 v4, 0
.Lcarry2:
    s_cmp_ge_u32 s56, s57
    s_cbranch_scc1 .Lcarry_done2
    s_lshl_b32 s60, s56, 2
    v_mov_b32 v2, s60
    ds_read_b32 v5, v2
    s_waitcnt lgkmcnt(0)
    v_add_f32 v4, v4, v5
    s_add_u32 s56, s56, 1
    s_branch .Lcarry2
.Lcarry_done2:
    s_nop 4
    v_readfirstlane_b32 s52, v4
    s_nop 4
    s_mov_b64 exec, -1
    v_add_f32 v8, v42, s52
    v_sub_u32 v2, v1, 1
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v8
    s_waitcnt lgkmcnt(0)
    v_cmp_eq_u32 vcc, v1, 0
    v_mov_b32 v12, s52
    v_cndmask_b32 v9, v9, v12, vcc
    v_add_f32 v10, v32, v9
    v_add_f32 v10, s31, v10
    v_add_u32 v11, 2048, v18
    v_cmp_gt_f32 vcc, v10, v19
    s_mov_b64 s[58:59], vcc
    v_cmp_lt_u32 vcc, v11, s37
    s_and_b64 vcc, vcc, s[58:59]
    v_mov_b32 v13, 0x7fffffff
    v_cndmask_b32 v11, v13, v11, vcc
    v_min_u32 v16, v16, v11
    v_add_f32 v10, v33, v9
    v_add_f32 v10, s31, v10
    v_add_u32 v11, 2049, v18
    v_cmp_gt_f32 vcc, v10, v19
    s_mov_b64 s[58:59], vcc
    v_cmp_lt_u32 vcc, v11, s37
    s_and_b64 vcc, vcc, s[58:59]
    v_mov_b32 v13, 0x7fffffff
    v_cndmask_b32 v11, v13, v11, vcc
    v_min_u32 v16, v16, v11
    v_add_f32 v10, v34, v9
    v_add_f32 v10, s31, v10
    v_add_u32 v11, 2050, v18
    v_cmp_gt_f32 vcc, v10, v19
    s_mov_b64 s[58:59], vcc
    v_cmp_lt_u32 vcc, v11, s37
    s_and_b64 vcc, vcc, s[58:59]
    v_mov_b32 v13, 0x7fffffff
    v_cndmask_b32 v11, v13, v11, vcc
    v_min_u32 v16, v16, v11
    v_mov_b32 v10, v8
    v_add_f32 v10, s31, v10
    v_add_u32 v11, 2051, v18
    v_cmp_gt_f32 vcc, v10, v19
    s_mov_b64 s[58:59], vcc
    v_cmp_lt_u32 vcc, v11, s37
    s_and_b64 vcc, vcc, s[58:59]
    v_mov_b32 v13, 0x7fffffff
    v_cndmask_b32 v11, v13, v11, vcc
    v_min_u32 v16, v16, v11
    // Carry follows the reference's sequential chunk/wave order.
    s_mov_b64 exec, 1
    s_add_u32 s57, s62, 12
    s_mov_b32 s56, 0
    v_mov_b32 v4, 0
.Lcarry3:
    s_cmp_ge_u32 s56, s57
    s_cbranch_scc1 .Lcarry_done3
    s_lshl_b32 s60, s56, 2
    v_mov_b32 v2, s60
    ds_read_b32 v5, v2
    s_waitcnt lgkmcnt(0)
    v_add_f32 v4, v4, v5
    s_add_u32 s56, s56, 1
    s_branch .Lcarry3
.Lcarry_done3:
    s_nop 4
    v_readfirstlane_b32 s52, v4
    s_nop 4
    s_mov_b64 exec, -1
    v_add_f32 v8, v43, s52
    v_sub_u32 v2, v1, 1
    v_lshlrev_b32 v2, 2, v2
    ds_bpermute_b32 v9, v2, v8
    s_waitcnt lgkmcnt(0)
    v_cmp_eq_u32 vcc, v1, 0
    v_mov_b32 v12, s52
    v_cndmask_b32 v9, v9, v12, vcc
    v_add_f32 v10, v36, v9
    v_add_f32 v10, s31, v10
    v_add_u32 v11, 3072, v18
    v_cmp_gt_f32 vcc, v10, v19
    s_mov_b64 s[58:59], vcc
    v_cmp_lt_u32 vcc, v11, s37
    s_and_b64 vcc, vcc, s[58:59]
    v_mov_b32 v13, 0x7fffffff
    v_cndmask_b32 v11, v13, v11, vcc
    v_min_u32 v16, v16, v11
    v_add_f32 v10, v37, v9
    v_add_f32 v10, s31, v10
    v_add_u32 v11, 3073, v18
    v_cmp_gt_f32 vcc, v10, v19
    s_mov_b64 s[58:59], vcc
    v_cmp_lt_u32 vcc, v11, s37
    s_and_b64 vcc, vcc, s[58:59]
    v_mov_b32 v13, 0x7fffffff
    v_cndmask_b32 v11, v13, v11, vcc
    v_min_u32 v16, v16, v11
    v_add_f32 v10, v38, v9
    v_add_f32 v10, s31, v10
    v_add_u32 v11, 3074, v18
    v_cmp_gt_f32 vcc, v10, v19
    s_mov_b64 s[58:59], vcc
    v_cmp_lt_u32 vcc, v11, s37
    s_and_b64 vcc, vcc, s[58:59]
    v_mov_b32 v13, 0x7fffffff
    v_cndmask_b32 v11, v13, v11, vcc
    v_min_u32 v16, v16, v11
    v_mov_b32 v10, v8
    v_add_f32 v10, s31, v10
    v_add_u32 v11, 3075, v18
    v_cmp_gt_f32 vcc, v10, v19
    s_mov_b64 s[58:59], vcc
    v_cmp_lt_u32 vcc, v11, s37
    s_and_b64 vcc, vcc, s[58:59]
    v_mov_b32 v13, 0x7fffffff
    v_cndmask_b32 v11, v13, v11, vcc
    v_min_u32 v16, v16, v11
    v_mov_b32 v8, v16
    s_nop 1
    v_min_u32_dpp v8, v8, v8 quad_perm:[1,0,3,2]
    s_nop 1
    v_min_u32_dpp v8, v8, v8 quad_perm:[2,3,0,1]
    s_nop 1
    v_min_u32_dpp v8, v8, v8 row_shl:4 bound_ctrl:1
    s_nop 1
    v_min_u32_dpp v8, v8, v8 row_shl:8 bound_ctrl:1
    s_nop 1
    v_mov_b32 v20, v8
    s_nop 1
    v_permlane16_swap_b32 v8, v20
    s_nop 1
    v_min_u32 v8, v8, v20
    s_nop 1
    v_mov_b32 v20, v8
    s_nop 1
    v_permlane32_swap_b32 v8, v20
    s_nop 1
    v_min_u32 v8, v8, v20
    s_nop 4
    v_readfirstlane_b32 s52, v8
    s_nop 4
    s_mov_b64 exec, 1
    s_lshl_b32 s60, s53, 2
    v_mov_b32 v2, s60
    v_mov_b32 v4, s52
    global_atomic_umin v2, v4, s[4:5]

.Ldone:
    s_endpgm
.Lend:
.size netra_dsv4_classic_sample, .Lend-netra_dsv4_classic_sample
.section .rodata,"a",@progbits
.p2align 6, 0
.amdhsa_kernel netra_dsv4_classic_sample
    .amdhsa_group_segment_fixed_size 64
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
    .group_segment_fixed_size: 64
    .kernarg_segment_align: 8
    .kernarg_segment_size: 192
    .max_flat_workgroup_size: 256
    .name: netra_dsv4_classic_sample
    .private_segment_fixed_size: 0
    .sgpr_count: 64
    .sgpr_spill_count: 0
    .symbol: netra_dsv4_classic_sample.kd
    .vgpr_count: 64
    .vgpr_spill_count: 0
    .wavefront_size: 64
...
.end_amdgpu_metadata
