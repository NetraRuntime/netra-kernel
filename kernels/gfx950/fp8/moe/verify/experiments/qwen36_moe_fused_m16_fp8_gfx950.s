// SPDX-License-Identifier: MIT
//
// Complete expert-compute prototype for the exact Qwen3.6 M=1024 routed-MoE
// call on gfx950.  One wave64 workgroup consumes one expert-sorted M16 route
// block and performs, without a global intermediate:
//
//   FP8 hidden x FP8 W13 -> BF16 gate/up in LDS
//   BF16-rounded SiLU(gate) * up -> FP8 E4M3 in LDS, 1x128 scales
//   FP8 activation x FP8 W2 -> FP32 route partials
//
// A separate raw fixed-order reducer applies the nine router weights.  HIP is
// used only to load, dispatch, allocate the stable route workspace, and time.
// This first complete candidate deliberately uses an M16 tile so the entire
// gate/up and quantized activation remain resident in 40.25 KiB LDS.
//
// Grid:      (sorted_expert_ids.size(), 1, 1)
// Workgroup: (512, 1, 1), eight wave64s

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_fused_m16_fp8_gfx950
	.globl qwen36_moe_fused_m16_fp8_gfx950
	.p2align 8
	.type qwen36_moe_fused_m16_fp8_gfx950,@function
qwen36_moe_fused_m16_fp8_gfx950:
	// hidden FP8, hidden scale FP32, W13 FP8, W13 scale FP32,
	// W2 FP8, W2 scale FP32, sorted token IDs, compact sorted experts,
	// valid sorted count, FP32 route partials, rows.
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dwordx2 s[10:11], s[0:1], 24
	s_load_dwordx2 s[12:13], s[0:1], 32
	s_load_dwordx2 s[14:15], s[0:1], 40
	s_load_dwordx2 s[16:17], s[0:1], 48
	s_load_dwordx2 s[18:19], s[0:1], 56
	s_load_dwordx2 s[20:21], s[0:1], 64
	s_load_dwordx2 s[22:23], s[0:1], 72
	s_load_dword s24, s[0:1], 80
	s_load_dword s52, s[0:1], 84
	s_load_dwordx2 s[56:57], s[0:1], 88
	s_load_dwordx2 s[58:59], s[0:1], 96
	s_load_dwordx2 s[60:61], s[0:1], 104
	s_waitcnt lgkmcnt(0)

	// Reject unused graph-stable sorting capacity.
	s_lshl_b32 s25, s2, 4
	s_lshl_b32 s31, s2, 2
	v_mov_b32_e32 v50, 0
	global_load_dword v51, v50, s[20:21]
	v_mov_b32_e32 v52, s31
	global_load_dword v53, v52, s[18:19]
	s_waitcnt vmcnt(0)
	s_nop 3
	v_readfirstlane_b32 s26, v51
	v_readfirstlane_b32 s27, v53
	s_nop 3
	s_cmp_lt_u32 s25, s26
	s_cbranch_scc0 .Lend

	// Wave/lane organization and route count.
	v_lshrrev_b32_e32 v8, 6, v0
	s_nop 3
	v_readfirstlane_b32 s28, v8
	s_nop 3
	v_and_b32_e32 v9, 63, v0
	v_and_b32_e32 v1, 15, v9
	v_and_b32_e32 v2, 48, v9
	s_mul_i32 s47, s24, 9
	v_mov_b32_e32 v46, s47

	// The AITER sorted-token ABI is (topk_slot << 24) | token_row.  Low
	// lanes select the M dimension for MFMA A loads.
	v_add_u32_e32 v3, s25, v1
	v_lshlrev_b32_e32 v3, 2, v3
	global_load_dword v4, v3, s[16:17]

	// Each lane owns four result rows.  Load their packed route IDs once and
	// retain decoded route indices through both GEMMs.
	v_lshrrev_b32_e32 v5, 2, v2
	v_add_u32_e32 v5, s25, v5
	v_lshlrev_b32_e32 v5, 2, v5
	global_load_dword v38, v5, s[16:17]
	global_load_dword v39, v5, s[16:17] offset:4
	global_load_dword v40, v5, s[16:17] offset:8
	global_load_dword v41, v5, s[16:17] offset:12
	s_waitcnt vmcnt(0)

	// Clamp the low-lane token used by MFMA A loads.
	v_lshrrev_b32_e32 v5, 24, v4
	v_and_b32_e32 v4, 0x00ffffff, v4
	v_cmp_gt_u32_e32 vcc, s24, v4
	v_cndmask_b32_e32 v4, 0, v4, vcc
	v_cmp_gt_u32_e32 vcc, 9, v5
	v_cndmask_b32_e32 v4, 0, v4, vcc

	// Decode four token rows for per-row input scales and four flattened
	// token/top-k route indices for final partial stores.
	v_lshrrev_b32_e32 v5, 24, v38
	v_and_b32_e32 v38, 0x00ffffff, v38
	v_mul_lo_u32 v42, 9, v38
	v_add_u32_e32 v42, v5, v42
	v_cmp_gt_u32_e32 vcc, s24, v38
	v_cndmask_b32_e32 v38, 0, v38, vcc
	v_cmp_gt_u32_e32 vcc, 9, v5
	v_cndmask_b32_e32 v38, 0, v38, vcc
	v_cmp_gt_u32_e32 vcc, s47, v42
	v_cndmask_b32_e32 v42, v46, v42, vcc
	v_cmp_gt_u32_e32 vcc, 9, v5
	v_cndmask_b32_e32 v42, v46, v42, vcc

	v_lshrrev_b32_e32 v5, 24, v39
	v_and_b32_e32 v39, 0x00ffffff, v39
	v_mul_lo_u32 v43, 9, v39
	v_add_u32_e32 v43, v5, v43
	v_cmp_gt_u32_e32 vcc, s24, v39
	v_cndmask_b32_e32 v39, 0, v39, vcc
	v_cmp_gt_u32_e32 vcc, 9, v5
	v_cndmask_b32_e32 v39, 0, v39, vcc
	v_cmp_gt_u32_e32 vcc, s47, v43
	v_cndmask_b32_e32 v43, v46, v43, vcc
	v_cmp_gt_u32_e32 vcc, 9, v5
	v_cndmask_b32_e32 v43, v46, v43, vcc

	v_lshrrev_b32_e32 v5, 24, v40
	v_and_b32_e32 v40, 0x00ffffff, v40
	v_mul_lo_u32 v44, 9, v40
	v_add_u32_e32 v44, v5, v44
	v_cmp_gt_u32_e32 vcc, s24, v40
	v_cndmask_b32_e32 v40, 0, v40, vcc
	v_cmp_gt_u32_e32 vcc, 9, v5
	v_cndmask_b32_e32 v40, 0, v40, vcc
	v_cmp_gt_u32_e32 vcc, s47, v44
	v_cndmask_b32_e32 v44, v46, v44, vcc
	v_cmp_gt_u32_e32 vcc, 9, v5
	v_cndmask_b32_e32 v44, v46, v44, vcc

	v_lshrrev_b32_e32 v5, 24, v41
	v_and_b32_e32 v41, 0x00ffffff, v41
	v_mul_lo_u32 v45, 9, v41
	v_add_u32_e32 v45, v5, v45
	v_cmp_gt_u32_e32 vcc, s24, v41
	v_cndmask_b32_e32 v41, 0, v41, vcc
	v_cmp_gt_u32_e32 vcc, 9, v5
	v_cndmask_b32_e32 v41, 0, v41, vcc
	v_cmp_gt_u32_e32 vcc, s47, v45
	v_cndmask_b32_e32 v45, v46, v45, vcc
	v_cmp_gt_u32_e32 vcc, 9, v5
	v_cndmask_b32_e32 v45, v46, v45, vcc

	// Give each workgroup a distinct bounded padding sink to avoid races
	// between the final padded block of every expert.
	s_add_u32 s48, s47, s2
	v_mov_b32_e32 v5, s48
	v_cmp_eq_u32_e32 vcc, s47, v42
	v_cndmask_b32_e32 v42, v42, v5, vcc
	v_cmp_eq_u32_e32 vcc, s47, v43
	v_cndmask_b32_e32 v43, v43, v5, vcc
	v_cmp_eq_u32_e32 vcc, s47, v44
	v_cndmask_b32_e32 v44, v44, v5, vcc
	v_cmp_eq_u32_e32 vcc, s47, v45
	v_cndmask_b32_e32 v45, v45, v5, vcc

	// Diagnostic stage 4 writes the sixteen decoded route IDs for each
	// workgroup to a bounded prefix of the existing partial workspace.
	s_cmp_eq_u32 s52, 4
	s_cbranch_scc0 .Lroutes_ready
.Lwrite_debug_routes:
	v_cmp_eq_u32_e32 vcc, 0, v1
	s_and_saveexec_b64 s[50:51], vcc
	s_lshl_b32 s31, s2, 9
	s_lshl_b32 s48, s28, 6
	s_add_u32 s31, s31, s48
	v_lshrrev_b32_e32 v47, 2, v2
	v_lshlrev_b32_e32 v47, 2, v47
	v_add_u32_e32 v47, s31, v47
	global_store_dwordx4 v47, v[42:45], s[22:23]
	s_waitcnt vmcnt(0)
	s_or_b64 exec, exec, s[50:51]
	s_endpgm
.Lroutes_ready:

	// Compact-expert W13 and scale bases.
	s_lshl_b32 s31, s27, 21
	s_add_u32 s32, s8, s31
	s_addc_u32 s33, s9, 0
	s_lshl_b32 s31, s27, 9
	s_add_u32 s34, s10, s31
	s_addc_u32 s35, s11, 0

	// Hidden byte base selected by low lane; lane[5:4] selects the native
	// 16-byte K subgroup.
	v_lshlrev_b32_e32 v47, 11, v4
	v_add_u32_e32 v47, v2, v47
	// The packaged M1024 path presents W13 in AITER's 16x16 shuffle:
	// [N/16,K/32,2,16,16].  Within a tile, lane[3:0] selects N and
	// lane[5:4]*16 selects the two K32 halves consumed by this lane.
	v_lshlrev_b32_e32 v48, 4, v1
	v_lshlrev_b32_e32 v51, 4, v2
	v_add_u32_e32 v48, v51, v48

	// Eight waves cover 64 W13 N16 tiles in eight rounds.
	s_mov_b32 s29, s28
.Lgate_tile:
	// tile*32768 + lane_low*2048 + K subgroup.
	s_lshl_b32 s36, s29, 15
	v_add_u32_e32 v49, s36, v48
	// W13 scale is [expert, N/128=8, K/128=16].
	s_lshr_b32 s37, s29, 3
	s_lshl_b32 s37, s37, 6
	v_mov_b32_e32 v30, 0
	v_mov_b32_e32 v31, 0
	v_mov_b32_e32 v32, 0
	v_mov_b32_e32 v33, 0
	s_mov_b32 s30, 0
.Lgate_k:
	// Four per-row activation scales correspond to the four MFMA results.
	s_lshl_b32 s31, s30, 2
	v_lshlrev_b32_e32 v50, 6, v38
	v_add_u32_e32 v50, s31, v50
	global_load_dword v34, v50, s[6:7]
	v_lshlrev_b32_e32 v50, 6, v39
	v_add_u32_e32 v50, s31, v50
	global_load_dword v35, v50, s[6:7]
	v_lshlrev_b32_e32 v50, 6, v40
	v_add_u32_e32 v50, s31, v50
	global_load_dword v36, v50, s[6:7]
	v_lshlrev_b32_e32 v50, 6, v41
	v_add_u32_e32 v50, s31, v50
	global_load_dword v37, v50, s[6:7]
	s_add_u32 s48, s37, s31
	v_mov_b32_e32 v52, s48
	global_load_dword v53, v52, s[34:35]

	s_lshl_b32 s48, s30, 7
	v_add_u32_e32 v50, s48, v47
	global_load_dwordx4 v[10:13], v50, s[4:5]
	global_load_dwordx4 v[14:17], v50, s[4:5] offset:64
	// Four shuffled K32 tiles occupy 2,048 bytes per K=128 block.
	s_lshl_b32 s48, s30, 11
	v_add_u32_e32 v50, s48, v49
	global_load_dwordx4 v[18:21], v50, s[32:33]
	global_load_dwordx4 v[22:25], v50, s[32:33] offset:1024
	v_mov_b32_e32 v26, 0
	v_mov_b32_e32 v27, 0
	v_mov_b32_e32 v28, 0
	v_mov_b32_e32 v29, 0
	s_waitcnt vmcnt(0) & lgkmcnt(0)
	s_nop 3
	v_readfirstlane_b32 s44, v53
	s_nop 3
	v_mfma_f32_16x16x128_f8f6f4 v[26:29], v[10:17], v[18:25], 0
	s_nop 15
	v_mul_f32_e32 v26, v34, v26
	v_mul_f32_e32 v26, s44, v26
	v_add_f32_e32 v30, v30, v26
	v_mul_f32_e32 v27, v35, v27
	v_mul_f32_e32 v27, s44, v27
	v_add_f32_e32 v31, v31, v27
	v_mul_f32_e32 v28, v36, v28
	v_mul_f32_e32 v28, s44, v28
	v_add_f32_e32 v32, v32, v28
	v_mul_f32_e32 v29, v37, v29
	v_mul_f32_e32 v29, s44, v29
	v_add_f32_e32 v33, v33, v29
	s_add_u32 s30, s30, 1
	s_cmp_lt_u32 s30, 16
	s_cbranch_scc1 .Lgate_k

	// LDS [16,1024] BF16 gate/up, row-major.  v2*512 is the byte base
	// for rows 0/4/8/12 owned by this lane subgroup.
	v_lshlrev_b32_e32 v50, 9, v2
	s_lshl_b32 s31, s29, 5
	v_add_u32_e32 v50, s31, v50
	v_lshlrev_b32_e32 v51, 1, v1
	v_add_u32_e32 v50, v51, v50
	v_cvt_pk_bf16_f32 v34, v30, v30
	v_cvt_pk_bf16_f32 v35, v31, v31
	v_cvt_pk_bf16_f32 v36, v32, v32
	v_cvt_pk_bf16_f32 v37, v33, v33
	ds_write_b16 v50, v34
	ds_write_b16 v50, v35 offset:2048
	ds_write_b16 v50, v36 offset:4096
	ds_write_b16 v50, v37 offset:6144
	s_add_u32 s29, s29, 8
	s_cmp_lt_u32 s29, 64
	s_cbranch_scc1 .Lgate_tile
	s_waitcnt lgkmcnt(0)
	s_barrier

	// Diagnostic stage 7 exports the complete BF16 W13 boundary in sorted
	// route order. Each of 512 threads copies sixteen LDS dwords, covering
	// [16,1024] without changing the production arithmetic path.
	s_cmp_eq_u32 s52, 7
	s_cbranch_scc0 .Lstage1_debug_done
	v_lshlrev_b32_e32 v50, 2, v0
	s_lshl_b32 s31, s2, 15
	v_add_u32_e32 v51, s31, v50
	s_mov_b32 s30, 0
.Lstage1_debug_copy:
	ds_read_b32 v10, v50
	s_waitcnt lgkmcnt(0)
	global_store_dword v51, v10, s[56:57]
	v_add_u32_e32 v50, 2048, v50
	v_add_u32_e32 v51, 2048, v51
	s_add_u32 s30, s30, 1
	s_cmp_lt_u32 s30, 16
	s_cbranch_scc1 .Lstage1_debug_copy
	s_waitcnt vmcnt(0)
	s_endpgm
.Lstage1_debug_done:
	s_cmp_eq_u32 s52, 1
	s_cbranch_scc1 .Lend

	// Constants for BF16-rounded SiLU and E4M3 quantization.
	s_mov_b32 s40, 0x3f800000       // 1.0f
	s_mov_b32 s41, 0xbfb8aa3b       // -log2(e)
	s_mov_b32 s42, 0x3b124925       // 1.0f / 448.0f
	s_mov_b32 s43, 0x2edbe6ff       // 1.0e-10f

	// Sixty-four (row,128-column-block) groups are divided over eight
	// waves. Each lane owns one adjacent BF16 pair.
	s_mov_b32 s45, s28
.Lquant_group:
	s_lshr_b32 s46, s45, 2
	s_and_b32 s49, s45, 3
	// Debug stage 6 writes intermediates in sorted-route order.  This avoids
	// another packed-route load in the kernel; the harness maps each retained
	// sorted row back to its (token, top-k slot) reference row.
	s_add_u32 s53, s25, s46
	s_lshl_b32 s48, s46, 11
	s_lshl_b32 s49, s49, 8
	s_add_u32 s48, s48, s49
	v_lshlrev_b32_e32 v50, 2, v9
	v_add_u32_e32 v50, s48, v50
	ds_read_b32 v10, v50
	ds_read_b32 v11, v50 offset:1024
	s_waitcnt lgkmcnt(0)

	// Unpack two gate and up BF16 values to FP32.
	v_lshlrev_b32_e32 v12, 16, v10
	v_and_b32_e32 v13, 0xffff0000, v10
	v_lshlrev_b32_e32 v14, 16, v11
	v_and_b32_e32 v15, 0xffff0000, v11
	v_mul_f32_e32 v16, s41, v12
	v_mul_f32_e32 v17, s41, v13
	v_exp_f32_e32 v16, v16
	v_exp_f32_e32 v17, v17
	v_add_f32_e32 v16, s40, v16
	v_add_f32_e32 v17, s40, v17
	v_rcp_f32_e32 v16, v16
	v_rcp_f32_e32 v17, v17
	v_mul_f32_e32 v12, v16, v12
	v_mul_f32_e32 v13, v17, v13
	v_mul_f32_e32 v12, v14, v12
	v_mul_f32_e32 v13, v15, v13

	// Match the deployed BF16 activation boundary before scale selection.
	v_cvt_pk_bf16_f32 v18, v12, v13
	v_lshlrev_b32_e32 v12, 16, v18
	v_and_b32_e32 v13, 0xffff0000, v18
	v_max3_f32 v19, |v12|, |v13|, s43

	// Retain the deployed BF16 activation boundary for exact stage-local
	// comparison.  Address is [sorted_row, 512] BF16.
	s_cmp_eq_u32 s52, 6
	s_cbranch_scc0 .Ldebug_bf16_done
	s_lshl_b32 s31, s53, 10
	s_add_u32 s31, s31, s49
	v_lshlrev_b32_e32 v54, 2, v9
	v_add_u32_e32 v54, s31, v54
	global_store_dword v54, v18, s[56:57]
.Ldebug_bf16_done:

	// Reduce 64 lanes: four 16-lane DPP rows followed by four broadcasts.
	s_nop 1
	v_mov_b32_dpp v20, v19 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 v19, v19, v20
	s_nop 1
	v_mov_b32_dpp v20, v19 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 v19, v19, v20
	s_nop 1
	v_mov_b32_dpp v20, v19 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 v19, v19, v20
	s_nop 1
	v_mov_b32_dpp v20, v19 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:0
	v_max_f32_e32 v19, v19, v20
	s_nop 1
	v_mov_b32_e32 v24, 60
	v_mov_b32_e32 v25, 124
	v_mov_b32_e32 v26, 188
	v_mov_b32_e32 v27, 252
	ds_bpermute_b32 v20, v24, v19
	ds_bpermute_b32 v21, v25, v19
	ds_bpermute_b32 v22, v26, v19
	ds_bpermute_b32 v23, v27, v19
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v19, v20, v21, v22
	v_max_f32_e32 v19, v19, v23
	v_mul_f32_e32 v19, s42, v19

	// One scale per group at LDS byte 40960.
	v_cmp_eq_u32_e32 vcc, 0, v9
	s_and_saveexec_b64 s[50:51], vcc
	s_lshl_b32 s48, s45, 2
	s_add_u32 s48, s48, 40960
	v_mov_b32_e32 v20, s48
	ds_write_b32 v20, v19
	s_cmp_eq_u32 s52, 6
	s_cbranch_scc0 .Ldebug_scale_done
	s_lshl_b32 s31, s53, 4
	s_and_b32 s48, s45, 3
	s_lshl_b32 s48, s48, 2
	s_add_u32 s31, s31, s48
	v_mov_b32_e32 v54, s31
	global_store_dword v54, v19, s[60:61]
.Ldebug_scale_done:
	s_or_b64 exec, exec, s[50:51]

	// Reciprocal refinement and packed two-byte E4M3 store at LDS 32768.
	v_rcp_f32_e32 v20, v19
	s_nop 1
	v_fma_f32 v21, -v19, v20, 1.0
	s_nop 1
	v_fma_f32 v20, v21, v20, v20
	s_nop 1
	v_mul_f32_e32 v12, v20, v12
	v_mul_f32_e32 v13, v20, v13
	v_cvt_pk_fp8_f32 v18, v12, v13
	s_lshl_b32 s48, s46, 9
	s_lshl_b32 s49, s49, 0
	// Recreate block*128 after s49 was reused above.
	s_and_b32 s49, s45, 3
	s_lshl_b32 s49, s49, 7
	s_add_u32 s48, s48, s49
	s_add_u32 s48, s48, 32768
	v_lshlrev_b32_e32 v20, 1, v9
	v_add_u32_e32 v20, s48, v20
	ds_write_b16 v20, v18

	// Retain the packed E4M3 activation after quantization. Address is
	// [sorted_row, 512] bytes.
	s_cmp_eq_u32 s52, 6
	s_cbranch_scc0 .Ldebug_fp8_done
	s_lshl_b32 s31, s53, 9
	s_add_u32 s31, s31, s49
	v_lshlrev_b32_e32 v54, 1, v9
	v_add_u32_e32 v54, s31, v54
	global_store_short v54, v18, s[58:59]
.Ldebug_fp8_done:

	s_add_u32 s45, s45, 8
	s_cmp_lt_u32 s45, 64
	s_cbranch_scc1 .Lquant_group
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cmp_eq_u32 s52, 2
	s_cbranch_scc1 .Lend
	s_cmp_eq_u32 s52, 6
	s_cbranch_scc0 .Lquant_debug_done
	s_waitcnt vmcnt(0)
	s_endpgm
.Lquant_debug_done:

	// Compact-expert W2 and scale bases.
	s_lshl_b32 s31, s27, 20
	s_add_u32 s32, s12, s31
	s_addc_u32 s33, s13, 0
	s_lshl_b32 s31, s27, 8
	s_add_u32 s34, s14, s31
	s_addc_u32 s35, s15, 0

	// Eight waves cover 128 output N16 tiles in sixteen rounds.
	s_mov_b32 s29, s28
.Ldown_tile:
	s_lshl_b32 s36, s29, 13
	v_lshlrev_b32_e32 v47, 4, v1
	v_add_u32_e32 v47, s36, v47
	v_lshlrev_b32_e32 v48, 4, v2
	v_add_u32_e32 v47, v48, v47
	s_lshr_b32 s37, s29, 3
	s_lshl_b32 s37, s37, 4

	v_mov_b32_e32 v30, 0
	v_mov_b32_e32 v31, 0
	v_mov_b32_e32 v32, 0
	v_mov_b32_e32 v33, 0
	s_mov_b32 s30, 0
.Ldown_k:
	// Native A fragment from quantized LDS [16,512].
	v_lshlrev_b32_e32 v48, 9, v1
	v_add_u32_e32 v48, 32768, v48
	v_add_u32_e32 v48, v2, v48
	s_lshl_b32 s48, s30, 7
	v_add_u32_e32 v48, s48, v48
	ds_read_b128 v[10:13], v48
	ds_read_b128 v[14:17], v48 offset:64

	// Four row scales selected by the MFMA result-row subgroup.
	v_lshrrev_b32_e32 v49, 2, v2
	v_lshlrev_b32_e32 v49, 4, v49
	v_add_u32_e32 v49, 40960, v49
	s_lshl_b32 s31, s30, 2
	v_add_u32_e32 v49, s31, v49
	ds_read_b32 v34, v49
	ds_read_b32 v35, v49 offset:16
	ds_read_b32 v36, v49 offset:32
	ds_read_b32 v37, v49 offset:48
	s_add_u32 s48, s37, s31
	v_mov_b32_e32 v52, s48
	global_load_dword v53, v52, s[34:35]

	// Native shuffled W2 fragment.
	s_lshl_b32 s48, s30, 11
	v_add_u32_e32 v50, s48, v47
	global_load_dwordx4 v[18:21], v50, s[32:33]
	global_load_dwordx4 v[22:25], v50, s[32:33] offset:1024
	v_mov_b32_e32 v26, 0
	v_mov_b32_e32 v27, 0
	v_mov_b32_e32 v28, 0
	v_mov_b32_e32 v29, 0
	s_waitcnt vmcnt(0) & lgkmcnt(0)
	s_nop 3
	v_readfirstlane_b32 s44, v53
	s_nop 3
	v_mfma_f32_16x16x128_f8f6f4 v[26:29], v[10:17], v[18:25], 0
	s_nop 15
	v_mul_f32_e32 v26, v34, v26
	v_mul_f32_e32 v26, s44, v26
	v_add_f32_e32 v30, v30, v26
	v_mul_f32_e32 v27, v35, v27
	v_mul_f32_e32 v27, s44, v27
	v_add_f32_e32 v31, v31, v27
	v_mul_f32_e32 v28, v36, v28
	v_mul_f32_e32 v28, s44, v28
	v_add_f32_e32 v32, v32, v28
	v_mul_f32_e32 v29, v37, v29
	v_mul_f32_e32 v29, s44, v29
	v_add_f32_e32 v33, v33, v29
	s_add_u32 s30, s30, 1
	s_cmp_lt_u32 s30, 4
	s_cbranch_scc1 .Ldown_k

	// FP32 route workspace [(rows*9)+sorted_blocks,2048]. Padding sentinels
	// map to per-workgroup sink rows that the fixed-order reducer never reads.
	// Unconditional stores avoid divergent EXEC manipulation around VMEM.
	s_cmp_eq_u32 s52, 3
	s_cbranch_scc1 .Ldown_next
	s_cmp_eq_u32 s52, 5
	s_cbranch_scc1 .Ldown_next
	s_lshl_b32 s31, s29, 4
	v_add_u32_e32 v47, s31, v1
	v_lshlrev_b32_e32 v47, 2, v47
	v_lshlrev_b32_e32 v48, 13, v42
	v_add_u32_e32 v48, v47, v48
	global_store_dword v48, v30, s[22:23]
	v_lshlrev_b32_e32 v48, 13, v43
	v_add_u32_e32 v48, v47, v48
	global_store_dword v48, v31, s[22:23]
	v_lshlrev_b32_e32 v48, 13, v44
	v_add_u32_e32 v48, v47, v48
	global_store_dword v48, v32, s[22:23]
	v_lshlrev_b32_e32 v48, 13, v45
	v_add_u32_e32 v48, v47, v48
	global_store_dword v48, v33, s[22:23]
	s_waitcnt vmcnt(0)

.Ldown_next:
	s_add_u32 s29, s29, 8
	s_cmp_lt_u32 s29, 128
	s_cbranch_scc1 .Ldown_tile
	s_cmp_eq_u32 s52, 5
	s_cbranch_scc1 .Lwrite_debug_routes
.Lend:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_fused_m16_fp8_gfx950
		.amdhsa_group_segment_fixed_size 41216
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 112
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 55
		.amdhsa_accum_offset 56
		.amdhsa_next_free_sgpr 62
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_moe_fused_m16_fp8_gfx950, .Lfunc_end0-qwen36_moe_fused_m16_fp8_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: hidden_fp8, .offset: 0, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: hidden_scale_f32, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: w13_fp8, .offset: 16, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: w13_scale_f32, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: w2_fp8, .offset: 32, .size: 8, .value_kind: global_buffer,
          .address_space: global, .actual_access: read_only }
      - { .name: w2_scale_f32, .offset: 40, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: sorted_token_ids_i32, .offset: 48, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: sorted_expert_ids_i32, .offset: 56, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: num_valid_ids_i32, .offset: 64, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: partial_f32, .offset: 72, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: rows, .offset: 80, .size: 4, .value_kind: by_value }
      - { .name: debug_stage, .offset: 84, .size: 4, .value_kind: by_value }
      - { .name: debug_activation_bf16, .offset: 88, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: debug_activation_fp8, .offset: 96, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: debug_activation_scale_f32, .offset: 104, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
    .group_segment_fixed_size: 41216
    .kernarg_segment_align: 8
    .kernarg_segment_size: 112
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 512
    .name: qwen36_moe_fused_m16_fp8_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 64
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_fused_m16_fp8_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 56
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
