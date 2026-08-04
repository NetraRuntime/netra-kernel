// SPDX-License-Identifier: MIT
//
// Qwen3.6 FP8 E4M3 one-stage routed expert prototype for gfx950/CDNA4.
//
// One 4-wave64 workgroup consumes an expert-sorted M64 route block.  It
// retains all four activation K128 slices in LDS, then owns N256 of the W2
// output at a time without inter-workgroup split-K.  It performs the
// complete expert path without a global activation payload or route partial:
// activation or route-partial workspace:
//
//   hidden FP8 x W13 FP8 -> BF16 gate/up boundary
//   BF16 SiLU(gate) * up -> BF16 activation boundary
//   per-route 1x128 E4M3 quantization in LDS
//   activation FP8 x W2 FP8 -> router-weighted packed-BF16 atomic output
//
// W13 and W2 use the deployed AITER 16x16 shuffled layouts.  Four waves own
// four M16 row tiles and cooperatively load every weight slab once.  The
// lower 32 KiB of LDS retains the complete M64x512 E4M3 activation; the upper
// LDS region is reused for W13/W2 weight slabs and the transient BF16 N128
// activation.  Output must be zeroed by the existing MoE sorting contract.
//
// Grid:      (1, ceil(num_valid_ids/64), 1)
// Workgroup: (256, 1, 1), four wave64s
// LDS:       64 KiB

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_fused_m64n256_atomic_fp8_gfx950
	.globl qwen36_moe_fused_m64n256_atomic_fp8_gfx950
	.p2align 8
	.type qwen36_moe_fused_m64n256_atomic_fp8_gfx950,@function
qwen36_moe_fused_m64n256_atomic_fp8_gfx950:
	// hidden, hidden scale, W13, W13 scale, W2, W2 scale, sorted IDs,
	// sorted route weights, compact experts, valid count, BF16 output, rows.
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
	s_load_dwordx2 s[24:25], s[0:1], 80
	s_load_dword s26, s[0:1], 88
	s_load_dwordx2 s[84:85], s[0:1], 96
	s_load_dword s86, s[0:1], 104
	s_waitcnt lgkmcnt(0)

	// Exact M64 block bounds and compact expert.
	s_lshl_b32 s27, s3, 6
	s_load_dword s28, s[22:23], 0
	s_lshl_b32 s29, s3, 2
	s_load_dword s29, s[20:21], s29
	s_waitcnt lgkmcnt(0)
	s_cmp_lt_u32 s27, s28
	s_cbranch_scc0 .Lend

	// Wave/lane coordinates.  Each wave owns one M16 row tile.
	v_and_b32_e32 v1, 15, v0
	v_and_b32_e32 v2, 48, v0
	v_lshrrev_b32_e32 v3, 6, v0
	v_lshlrev_b32_e32 v5, 4, v3
	v_add_u32_e32 v5, s27, v5

	// Low lane selects the hidden row used by the native MFMA A fragment.
	v_add_u32_e32 v3, v5, v1
	v_lshlrev_b32_e32 v3, 2, v3
	global_load_dword v4, v3, s[16:17]

	// Four result rows per lane and their route weights.
	v_lshrrev_b32_e32 v3, 2, v2
	v_add_u32_e32 v88, v5, v3
	v_add_u32_e32 v89, 1, v88
	v_add_u32_e32 v90, 2, v88
	v_add_u32_e32 v91, 3, v88
	v_lshlrev_b32_e32 v3, 2, v88
	global_load_dword v84, v3, s[16:17]
	global_load_dword v85, v3, s[16:17] offset:4
	global_load_dword v86, v3, s[16:17] offset:8
	global_load_dword v87, v3, s[16:17] offset:12
	global_load_dword v120, v3, s[18:19]
	global_load_dword v121, v3, s[18:19] offset:4
	global_load_dword v122, v3, s[18:19] offset:8
	global_load_dword v123, v3, s[18:19] offset:12
	s_waitcnt vmcnt(0)

	// Clamp the hidden row for padded routes.
	v_lshrrev_b32_e32 v6, 24, v4
	v_and_b32_e32 v4, 0x00ffffff, v4
	v_cmp_gt_u32_e32 vcc, s26, v4
	v_cndmask_b32_e32 v4, 0, v4, vcc
	v_cmp_gt_u32_e32 vcc, 9, v6
	v_cndmask_b32_e32 v4, 0, v4, vcc

	// Retain one exact validity mask and decoded token row per result.
	.macro DECODE_RESULT packed, masklo, maskhi
	v_lshrrev_b32_e32 v6, 24, v\packed
	v_and_b32_e32 v7, 0x00ffffff, v\packed
	v_cmp_gt_u32_e64 s[\masklo:\maskhi], 9, v6
	v_cmp_gt_u32_e64 s[82:83], s26, v7
	s_and_b64 s[\masklo:\maskhi], s[\masklo:\maskhi], s[82:83]
	v_cndmask_b32_e64 v\packed, 0, v7, s[\masklo:\maskhi]
	.endm
	DECODE_RESULT 84,56,57
	DECODE_RESULT 85,58,59
	DECODE_RESULT 86,60,61
	DECODE_RESULT 87,62,63
	s_or_b64 s[66:67], s[56:57], s[58:59]
	s_or_b64 s[64:65], s[60:61], s[62:63]
	s_or_b64 s[66:67], s[66:67], s[64:65]

	// Hidden and native LDS fragment coordinates retained across W13 groups.
	v_lshlrev_b32_e32 v94, 11, v4
	v_add_u32_e32 v94, v2, v94
	v_lshlrev_b32_e32 v93, 4, v2
	v_lshlrev_b32_e32 v92, 4, v1
	v_add_u32_e32 v93, v93, v92
	v_add_u32_e32 v93, 32768, v93
	v_lshlrev_b32_e32 v92, 3, v0

	// Compact-expert W13 and W13-scale bases.
	s_lshl_b32 s30, s29, 21
	s_add_u32 s68, s8, s30
	s_addc_u32 s69, s9, 0
	s_lshl_b32 s30, s29, 9
	s_add_u32 s70, s10, s30
	s_addc_u32 s71, s11, 0

	// One workgroup materializes all four N128 activation blocks.
	s_mov_b32 s80, 0
.Lw13_group:
	// Rebuild the N128 pair bases; each shuffled N16 tile is 32 KiB.
	s_lshl_b32 s30, s80, 18
	s_add_u32 s32, s68, s30
	s_addc_u32 s33, s69, 0
	s_lshl_b32 s31, s80, 6
	s_mov_b32 s34, s70
	s_mov_b32 s35, s71
	s_mov_b32 s79, 0

.Lw13_half:
	// One N64 half: four gate and four up N16 tile bases.
	s_lshl_b32 s30, s79, 17
	s_add_u32 s36, s32, s30
	s_addc_u32 s37, s33, 0
	s_add_u32 s40, s36, 32768
	s_addc_u32 s41, s37, 0
	s_add_u32 s42, s36, 65536
	s_addc_u32 s43, s37, 0
	s_add_u32 s44, s36, 98304
	s_addc_u32 s45, s37, 0
	s_add_u32 s46, s36, 1048576
	s_addc_u32 s47, s37, 0
	s_add_u32 s48, s40, 1048576
	s_addc_u32 s49, s41, 0
	s_add_u32 s50, s42, 1048576
	s_addc_u32 s51, s43, 0
	s_add_u32 s52, s44, 1048576
	s_addc_u32 s53, s45, 0

	.irp r,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79
	v_mov_b32_e32 v\r, 0
	.endr
	.irp r,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115
	v_mov_b32_e32 v\r, 0
	.endr
	s_mov_b32 s38, 0

.Lw13_k:
	// Cooperative paired 16 KiB gate/up slab at LDS [32K,48K).  The tiny
	// scale workspace is global, so both halves can share one VMEM wait and
	// one barrier exactly as in the accepted standalone M64 producer.
	s_lshl_b32 s39, s38, 11
	v_add_u32_e32 v95, s39, v92
	global_load_dwordx2 v[16:17], v95, s[36:37]
	global_load_dwordx2 v[24:25], v95, s[40:41]
	global_load_dwordx2 v[32:33], v95, s[42:43]
	global_load_dwordx2 v[40:41], v95, s[44:45]
	global_load_dwordx2 v[48:49], v95, s[46:47]
	global_load_dwordx2 v[50:51], v95, s[48:49]
	global_load_dwordx2 v[52:53], v95, s[50:51]
	global_load_dwordx2 v[54:55], v95, s[52:53]

	// Fully padded waves retain weight loads and every barrier.
	s_cmp_eq_u64 s[66:67], 0
	s_cbranch_scc1 .Lw13_skip_a
	s_lshl_b32 s54, s38, 7
	v_add_u32_e32 v96, s54, v94
	global_load_dwordx4 v[8:11], v96, s[4:5]
	global_load_dwordx4 v[12:15], v96, s[4:5] offset:64
	s_lshl_b32 s55, s38, 2
	v_lshlrev_b32_e32 v96, 6, v84
	v_add_u32_e32 v96, s55, v96
	global_load_dword v80, v96, s[6:7]
	v_lshlrev_b32_e32 v96, 6, v85
	v_add_u32_e32 v96, s55, v96
	global_load_dword v81, v96, s[6:7]
	v_lshlrev_b32_e32 v96, 6, v86
	v_add_u32_e32 v96, s55, v96
	global_load_dword v82, v96, s[6:7]
	v_lshlrev_b32_e32 v96, 6, v87
	v_add_u32_e32 v96, s55, v96
	global_load_dword v83, v96, s[6:7]
	s_add_u32 s54, s31, s55
	s_load_dword s72, s[34:35], s54
	s_add_u32 s54, s54, 256
	s_load_dword s73, s[34:35], s54
.Lw13_skip_a:

	s_waitcnt vmcnt(0) & lgkmcnt(0)
	v_add_u32_e32 v96, 32768, v92
	ds_write_b64 v96, v[16:17]
	ds_write_b64 v96, v[24:25] offset:2048
	ds_write_b64 v96, v[32:33] offset:4096
	ds_write_b64 v96, v[40:41] offset:6144
	ds_write_b64 v96, v[48:49] offset:8192
	ds_write_b64 v96, v[50:51] offset:10240
	ds_write_b64 v96, v[52:53] offset:12288
	ds_write_b64 v96, v[54:55] offset:14336
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cmp_eq_u64 s[66:67], 0
	s_cbranch_scc1 .Lw13_skip_compute

	ds_read_b128 v[16:19], v93
	ds_read_b128 v[20:23], v93 offset:1024
	ds_read_b128 v[24:27], v93 offset:2048
	ds_read_b128 v[28:31], v93 offset:3072
	ds_read_b128 v[32:35], v93 offset:4096
	ds_read_b128 v[36:39], v93 offset:5120
	ds_read_b128 v[40:43], v93 offset:6144
	ds_read_b128 v[44:47], v93 offset:7168
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	s_nop 12
	.macro W13_ACC tmp, acc, scale, wscale
	v_mul_f32_e32 v\tmp, s\wscale, v\tmp
	v_fmac_f32_e32 v[\acc], v\scale, v\tmp
	.endm
	W13_ACC 48,64,80,72
	W13_ACC 49,65,81,72
	W13_ACC 50,66,82,72
	W13_ACC 51,67,83,72
	W13_ACC 52,68,80,72
	W13_ACC 53,69,81,72
	W13_ACC 54,70,82,72
	W13_ACC 55,71,83,72
	W13_ACC 56,72,80,72
	W13_ACC 57,73,81,72
	W13_ACC 58,74,82,72
	W13_ACC 59,75,83,72
	W13_ACC 60,76,80,72
	W13_ACC 61,77,81,72
	W13_ACC 62,78,82,72
	W13_ACC 63,79,83,72

	ds_read_b128 v[16:19], v93 offset:8192
	ds_read_b128 v[20:23], v93 offset:9216
	ds_read_b128 v[24:27], v93 offset:10240
	ds_read_b128 v[28:31], v93 offset:11264
	ds_read_b128 v[32:35], v93 offset:12288
	ds_read_b128 v[36:39], v93 offset:13312
	ds_read_b128 v[40:43], v93 offset:14336
	ds_read_b128 v[44:47], v93 offset:15360
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	s_nop 12
	W13_ACC 48,100,80,73
	W13_ACC 49,101,81,73
	W13_ACC 50,102,82,73
	W13_ACC 51,103,83,73
	W13_ACC 52,104,80,73
	W13_ACC 53,105,81,73
	W13_ACC 54,106,82,73
	W13_ACC 55,107,83,73
	W13_ACC 56,108,80,73
	W13_ACC 57,109,81,73
	W13_ACC 58,110,82,73
	W13_ACC 59,111,83,73
	W13_ACC 60,112,80,73
	W13_ACC 61,113,81,73
	W13_ACC 62,114,82,73
	W13_ACC 63,115,83,73
.Lw13_skip_compute:
	s_barrier
	s_add_u32 s38, s38, 1
	s_cmp_lt_u32 s38, 16
	s_cbranch_scc1 .Lw13_k

	// BF16-rounded SiLU*up into transient LDS [48K,64K).
	s_cmp_eq_u64 s[66:67], 0
	s_cbranch_scc1 .Lw13_half_done
	v_lshrrev_b32_e32 v32, 6, v0
	v_lshlrev_b32_e32 v32, 11, v32
	v_and_b32_e32 v33, 63, v0
	v_lshlrev_b32_e32 v33, 5, v33
	v_add_u32_e32 v32, v33, v32
	v_add_u32_e32 v32, 49152, v32
	// The validated 32-lane quantizer maps lanes 0..15 to the upper N64
	// slab and lanes 16..31 to the lower slab.
	s_xor_b32 s74, s79, 1
	s_lshl_b32 s74, s74, 13
	v_add_u32_e32 v32, s74, v32
	s_mov_b32 s74, 0xbfb8aa3b
	s_mov_b32 s75, 0x3f800000
	.macro ACT_STORE g0,g1,g2,g3,u0,u1,u2,u3,tileoff
	v_cvt_pk_bf16_f32 v16, v\g0, v\g1
	v_cvt_pk_bf16_f32 v17, v\g2, v\g3
	v_cvt_pk_bf16_f32 v18, v\u0, v\u1
	v_cvt_pk_bf16_f32 v19, v\u2, v\u3
	v_lshlrev_b32_e32 v20, 16, v16
	v_and_b32_e32 v21, 0xffff0000, v16
	v_lshlrev_b32_e32 v22, 16, v17
	v_and_b32_e32 v23, 0xffff0000, v17
	v_lshlrev_b32_e32 v24, 16, v18
	v_and_b32_e32 v25, 0xffff0000, v18
	v_lshlrev_b32_e32 v26, 16, v19
	v_and_b32_e32 v27, 0xffff0000, v19
	v_mul_f32_e32 v28, s74, v20
	v_mul_f32_e32 v29, s74, v21
	v_mul_f32_e32 v30, s74, v22
	v_mul_f32_e32 v31, s74, v23
	v_exp_f32_e32 v28, v28
	v_exp_f32_e32 v29, v29
	v_exp_f32_e32 v30, v30
	v_exp_f32_e32 v31, v31
	v_add_f32_e32 v28, s75, v28
	v_add_f32_e32 v29, s75, v29
	v_add_f32_e32 v30, s75, v30
	v_add_f32_e32 v31, s75, v31
	v_rcp_f32_e32 v28, v28
	v_rcp_f32_e32 v29, v29
	v_rcp_f32_e32 v30, v30
	v_rcp_f32_e32 v31, v31
	v_mul_f32_e32 v20, v28, v20
	v_mul_f32_e32 v21, v29, v21
	v_mul_f32_e32 v22, v30, v22
	v_mul_f32_e32 v23, v31, v23
	v_mul_f32_e32 v20, v24, v20
	v_mul_f32_e32 v21, v25, v21
	v_mul_f32_e32 v22, v26, v22
	v_mul_f32_e32 v23, v27, v23
	v_cvt_pk_bf16_f32 v16, v20, v21
	v_cvt_pk_bf16_f32 v17, v22, v23
	v_add_u32_e32 v18, \tileoff, v32
	ds_write_b64 v18, v[16:17]
	.endm
	ACT_STORE 64,65,66,67,100,101,102,103,0
	ACT_STORE 68,69,70,71,104,105,106,107,8
	ACT_STORE 72,73,74,75,108,109,110,111,16
	ACT_STORE 76,77,78,79,112,113,114,115,24
.Lw13_half_done:
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_add_u32 s79, s79, 1
	s_cmp_lt_u32 s79, 2
	s_cbranch_scc1 .Lw13_half

	// Quantize this N128 group from transient BF16 LDS into the persistent
	// M64x512 E4M3 region [0,32K); scales live at [40K,41K).
	v_and_b32_e32 v1, 31, v0
	v_lshrrev_b32_e32 v2, 5, v0
	v_and_b32_e32 v25, 63, v0
	s_mov_b32 s76, 0
	s_mov_b32 s72, 0x3b124925
	s_mov_b32 s73, 0x2edbe6ff
	s_mov_b32 s74, 0x05040100
.Lquant_rows:
	s_lshl_b32 s77, s76, 3
	v_add_u32_e32 v3, s77, v2
	// Native transient-BF16 address for four adjacent columns.
	v_lshrrev_b32_e32 v6, 4, v3
	v_lshlrev_b32_e32 v6, 11, v6
	v_and_b32_e32 v7, 15, v3
	v_lshrrev_b32_e32 v8, 2, v7
	v_lshlrev_b32_e32 v8, 9, v8
	v_add_u32_e32 v6, v8, v6
	v_and_b32_e32 v8, 3, v7
	v_lshlrev_b32_e32 v8, 1, v8
	v_add_u32_e32 v6, v8, v6
	v_and_b32_e32 v8, 15, v1
	v_lshlrev_b32_e32 v8, 2, v8
	v_and_b32_e32 v9, 15, v8
	v_lshlrev_b32_e32 v9, 5, v9
	v_add_u32_e32 v6, v9, v6
	v_lshrrev_b32_e32 v9, 4, v8
	v_lshlrev_b32_e32 v9, 3, v9
	v_add_u32_e32 v6, v9, v6
	v_cmp_gt_u32_e32 vcc, 16, v1
	v_mov_b32_e32 v9, 8192
	v_cndmask_b32_e32 v9, 0, v9, vcc
	v_add_u32_e32 v6, v9, v6
	v_add_u32_e32 v6, 49152, v6
	ds_read_u16 v12, v6
	ds_read_u16 v13, v6 offset:32
	ds_read_u16 v14, v6 offset:64
	ds_read_u16 v15, v6 offset:96
	s_waitcnt lgkmcnt(0)
	v_lshlrev_b32_e32 v20, 16, v12
	v_lshlrev_b32_e32 v21, 16, v13
	v_lshlrev_b32_e32 v22, 16, v14
	v_lshlrev_b32_e32 v23, 16, v15
	v_max3_f32 v24, |v20|, |v21|, s73
	v_max3_f32 v24, v24, |v22|, |v23|
	.irp mask,1,2,4,8,16
	v_xor_b32_e32 v26, \mask, v25
	v_lshlrev_b32_e32 v26, 2, v26
	ds_bpermute_b32 v27, v26, v24
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v24, v24, v27
	.endr
	v_mul_f32_e32 v24, s72, v24
	// Tiny graph-stable scale workspace [sorted row, four K128 groups].
	// Keeping these 256 bytes per group outside LDS lets paired gate/up
	// weights share one 16 KiB load/barrier phase.
	v_add_u32_e32 v26, s27, v3
	v_lshlrev_b32_e32 v26, 4, v26
	s_lshl_b32 s77, s80, 2
	v_add_u32_e32 v26, s77, v26
	v_cmp_eq_u32_e64 s[78:79], 0, v1
	s_and_saveexec_b64 s[82:83], s[78:79]
	global_store_dword v26, v24, s[84:85]
	s_or_b64 exec, exec, s[82:83]
	// Refined reciprocal and packed four-byte E4M3 result.
	v_rcp_f32_e32 v26, v24
	s_nop 1
	v_fma_f32 v27, -v24, v26, 1.0
	s_nop 1
	v_fma_f32 v26, v27, v26, v26
	s_nop 1
	v_mul_f32_e32 v20, v26, v20
	v_mul_f32_e32 v21, v26, v21
	v_mul_f32_e32 v22, v26, v22
	v_mul_f32_e32 v23, v26, v23
	v_cvt_pk_fp8_f32 v28, v20, v21
	v_cvt_pk_fp8_f32 v29, v22, v23
	v_perm_b32 v28, v29, v28, s74
	v_lshlrev_b32_e32 v26, 9, v3
	s_lshl_b32 s77, s80, 7
	v_add_u32_e32 v26, s77, v26
	v_lshlrev_b32_e32 v27, 2, v1
	v_add_u32_e32 v26, v27, v26
	ds_write_b32 v26, v28
	s_add_u32 s76, s76, 1
	s_cmp_lt_u32 s76, 8
	s_cbranch_scc1 .Lquant_rows
	s_waitcnt vmcnt(0) & lgkmcnt(0)
	s_barrier
	s_add_u32 s80, s80, 1
	s_cmp_lt_u32 s80, 4
	s_cbranch_scc1 .Lw13_group

	// Restore native coordinates for the one-workgroup W2 phase.
	v_and_b32_e32 v1, 15, v0
	v_and_b32_e32 v2, 48, v0
	v_lshlrev_b32_e32 v93, 4, v2
	v_lshlrev_b32_e32 v92, 4, v1
	v_add_u32_e32 v93, v93, v92
	v_add_u32_e32 v93, 32768, v93
	v_lshlrev_b32_e32 v92, 3, v0
	s_cmp_eq_u32 s86, 2
	s_cbranch_scc1 .Lend

	// Debug stage 1 exports one or more complete sorted M64 activation tiles
	// in local row-major E4M3 order.  Use grid x=1 while diagnosing so output
	// workgroups do not race on the identical export destination.
	s_cmp_eq_u32 s86, 1
	s_cbranch_scc0 .Lactivation_debug_done
	v_lshlrev_b32_e32 v112, 2, v0
	s_lshl_b32 s54, s3, 15
	v_add_u32_e32 v113, s54, v112
	s_mov_b32 s55, 0
.Lactivation_debug_copy:
	ds_read_b32 v114, v112
	s_waitcnt lgkmcnt(0)
	global_store_dword v113, v114, s[24:25]
	v_add_u32_e32 v112, 1024, v112
	v_add_u32_e32 v113, 1024, v113
	s_add_u32 s55, s55, 1
	s_cmp_lt_u32 s55, 32
	s_cbranch_scc1 .Lactivation_debug_copy
	s_waitcnt vmcnt(0)
	s_endpgm
.Lactivation_debug_done:

	// Compact-expert W2 bases.  This workgroup owns all K128 slices and emits
	// complete N256 tiles; packed BF16 atomics combine routes only.
	s_lshl_b32 s30, s29, 20
	s_add_u32 s68, s12, s30
	s_addc_u32 s69, s13, 0
	s_lshl_b32 s30, s29, 8
	s_add_u32 s70, s14, s30
	s_addc_u32 s71, s15, 0
	s_mov_b32 s31, 0

	// Rebuild local row/native A coordinates.
	v_and_b32_e32 v1, 15, v0
	v_and_b32_e32 v2, 48, v0
	v_lshrrev_b32_e32 v3, 6, v0
	v_lshlrev_b32_e32 v5, 4, v3
	v_add_u32_e32 v104, v5, v1
	v_lshlrev_b32_e32 v98, 9, v104
	v_add_u32_e32 v98, v2, v98
	v_lshlrev_b32_e32 v97, 4, v2
	v_lshlrev_b32_e32 v96, 4, v1
	v_add_u32_e32 v97, v97, v96
	v_add_u32_e32 v97, 32768, v97
	v_lshlrev_b32_e32 v96, 3, v0
	s_mov_b32 s80, 0

.Ldown_n256:
	// Sixteen N16 output tiles (N256) per persistent output step.
	s_lshl_b32 s30, s80, 17
	s_add_u32 s32, s68, s30
	s_addc_u32 s33, s69, 0
	s_lshl_b32 s30, s80, 5
	s_add_u32 s37, s31, s30
	.irp r,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191
	v_mov_b32_e32 v\r, 0
	.endr
	s_mov_b32 s38, 0

.Ldown_k:
	// Cooperative W2 N256xK128 slab at LDS [32K,64K).
	s_lshl_b32 s39, s38, 11
	v_add_u32_e32 v99, s39, v96
	global_load_dwordx2 v[16:17], v99, s[32:33]
	v_add_u32_e32 v99, 8192, v99
	global_load_dwordx2 v[18:19], v99, s[32:33]
	v_add_u32_e32 v99, 8192, v99
	global_load_dwordx2 v[20:21], v99, s[32:33]
	v_add_u32_e32 v99, 8192, v99
	global_load_dwordx2 v[22:23], v99, s[32:33]
	v_add_u32_e32 v99, 8192, v99
	global_load_dwordx2 v[24:25], v99, s[32:33]
	v_add_u32_e32 v99, 8192, v99
	global_load_dwordx2 v[26:27], v99, s[32:33]
	v_add_u32_e32 v99, 8192, v99
	global_load_dwordx2 v[28:29], v99, s[32:33]
	v_add_u32_e32 v99, 8192, v99
	global_load_dwordx2 v[30:31], v99, s[32:33]
	v_add_u32_e32 v99, 8192, v99
	global_load_dwordx2 v[32:33], v99, s[32:33]
	v_add_u32_e32 v99, 8192, v99
	global_load_dwordx2 v[34:35], v99, s[32:33]
	v_add_u32_e32 v99, 8192, v99
	global_load_dwordx2 v[36:37], v99, s[32:33]
	v_add_u32_e32 v99, 8192, v99
	global_load_dwordx2 v[38:39], v99, s[32:33]
	v_add_u32_e32 v99, 8192, v99
	global_load_dwordx2 v[40:41], v99, s[32:33]
	v_add_u32_e32 v99, 8192, v99
	global_load_dwordx2 v[42:43], v99, s[32:33]
	v_add_u32_e32 v99, 8192, v99
	global_load_dwordx2 v[44:45], v99, s[32:33]
	v_add_u32_e32 v99, 8192, v99
	global_load_dwordx2 v[46:47], v99, s[32:33]
	s_cmp_eq_u64 s[66:67], 0
	s_cbranch_scc1 .Ldown_skip_a
	// Native activation fragment from persistent E4M3 LDS.
	s_lshl_b32 s54, s38, 7
	v_add_u32_e32 v100, s54, v98
	ds_read_b128 v[8:11], v100
	ds_read_b128 v[12:15], v100 offset:64
	// Four row scales for this K128 block from the tiny stable workspace.
	v_lshrrev_b32_e32 v100, 2, v2
	v_add_u32_e32 v100, v5, v100
	v_add_u32_e32 v100, s27, v100
	v_lshlrev_b32_e32 v100, 4, v100
	s_lshl_b32 s54, s38, 2
	v_add_u32_e32 v100, s54, v100
	global_load_dword v108, v100, s[84:85]
	global_load_dword v109, v100, s[84:85] offset:16
	global_load_dword v110, v100, s[84:85] offset:32
	global_load_dword v111, v100, s[84:85] offset:48
	s_add_u32 s54, s37, s54
	s_load_dword s72, s[70:71], s54
	s_add_u32 s54, s54, 16
	s_load_dword s73, s[70:71], s54
.Ldown_skip_a:

	s_waitcnt vmcnt(0) & lgkmcnt(0)
	v_add_u32_e32 v100, 32768, v96
	ds_write_b64 v100, v[16:17]
	ds_write_b64 v100, v[18:19] offset:2048
	ds_write_b64 v100, v[20:21] offset:4096
	ds_write_b64 v100, v[22:23] offset:6144
	ds_write_b64 v100, v[24:25] offset:8192
	ds_write_b64 v100, v[26:27] offset:10240
	ds_write_b64 v100, v[28:29] offset:12288
	ds_write_b64 v100, v[30:31] offset:14336
	ds_write_b64 v100, v[32:33] offset:16384
	ds_write_b64 v100, v[34:35] offset:18432
	ds_write_b64 v100, v[36:37] offset:20480
	ds_write_b64 v100, v[38:39] offset:22528
	ds_write_b64 v100, v[40:41] offset:24576
	ds_write_b64 v100, v[42:43] offset:26624
	ds_write_b64 v100, v[44:45] offset:28672
	ds_write_b64 v100, v[46:47] offset:30720
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cmp_eq_u64 s[66:67], 0
	s_cbranch_scc1 .Ldown_skip_compute

	.macro W2_ACC tmp, acc, scale, wscale
	v_mul_f32_e32 v\tmp, s\wscale, v\tmp
	v_fmac_f32_e32 v\acc, v\scale, v\tmp
	.endm
	.macro W2_QUAD ldsbase, wscale, a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15
	ds_read_b128 v[16:19], v97 offset:\ldsbase
	ds_read_b128 v[20:23], v97 offset:(\ldsbase+1024)
	ds_read_b128 v[24:27], v97 offset:(\ldsbase+2048)
	ds_read_b128 v[28:31], v97 offset:(\ldsbase+3072)
	ds_read_b128 v[32:35], v97 offset:(\ldsbase+4096)
	ds_read_b128 v[36:39], v97 offset:(\ldsbase+5120)
	ds_read_b128 v[40:43], v97 offset:(\ldsbase+6144)
	ds_read_b128 v[44:47], v97 offset:(\ldsbase+7168)
	s_waitcnt lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	s_nop 12
	W2_ACC 48,\a0,108,\wscale
	W2_ACC 49,\a1,109,\wscale
	W2_ACC 50,\a2,110,\wscale
	W2_ACC 51,\a3,111,\wscale
	W2_ACC 52,\a4,108,\wscale
	W2_ACC 53,\a5,109,\wscale
	W2_ACC 54,\a6,110,\wscale
	W2_ACC 55,\a7,111,\wscale
	W2_ACC 56,\a8,108,\wscale
	W2_ACC 57,\a9,109,\wscale
	W2_ACC 58,\a10,110,\wscale
	W2_ACC 59,\a11,111,\wscale
	W2_ACC 60,\a12,108,\wscale
	W2_ACC 61,\a13,109,\wscale
	W2_ACC 62,\a14,110,\wscale
	W2_ACC 63,\a15,111,\wscale
	.endm
	W2_QUAD 0,72,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143
	W2_QUAD 8192,72,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159
	W2_QUAD 16384,73,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175
	W2_QUAD 24576,73,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191
.Ldown_skip_compute:
	s_barrier
	s_add_u32 s38, s38, 1
	s_cmp_lt_u32 s38, 4
	s_cbranch_scc1 .Ldown_k

	// Apply route weights and atomically accumulate adjacent BF16 columns.
	// Neighbor exchange stays within each 16-lane MFMA column subgroup.
	s_cmp_eq_u64 s[66:67], 0
	s_cbranch_scc1 .Ldown_n256_done
	v_and_b32_e32 v112, 63, v0
	v_xor_b32_e32 v113, 1, v112
	v_lshlrev_b32_e32 v113, 2, v113
	v_and_b32_e32 v114, 1, v1
	v_cmp_eq_u32_e64 s[82:83], 0, v114
	s_lshl_b32 s54, s80, 8
	v_add_u32_e32 v115, s54, v1
	v_lshlrev_b32_e32 v115, 1, v115
	.macro ATOMIC_TILE a0,a1,a2,a3,coloff
	v_mul_f32_e32 v\a0, v120, v\a0
	v_mul_f32_e32 v\a1, v121, v\a1
	v_mul_f32_e32 v\a2, v122, v\a2
	v_mul_f32_e32 v\a3, v123, v\a3
	ds_bpermute_b32 v16, v113, v\a0
	ds_bpermute_b32 v17, v113, v\a1
	ds_bpermute_b32 v18, v113, v\a2
	ds_bpermute_b32 v19, v113, v\a3
	s_waitcnt lgkmcnt(0)
	v_cvt_pk_bf16_f32 v20, v\a0, v16
	v_cvt_pk_bf16_f32 v21, v\a1, v17
	v_cvt_pk_bf16_f32 v22, v\a2, v18
	v_cvt_pk_bf16_f32 v23, v\a3, v19
	v_add_u32_e32 v116, \coloff, v115
	v_lshlrev_b32_e32 v117, 12, v84
	v_add_u32_e32 v117, v116, v117
	v_lshlrev_b32_e32 v118, 12, v85
	v_add_u32_e32 v118, v116, v118
	v_lshlrev_b32_e32 v119, 12, v86
	v_add_u32_e32 v119, v116, v119
	v_lshlrev_b32_e32 v124, 12, v87
	v_add_u32_e32 v124, v116, v124
	s_and_b64 s[78:79], s[56:57], s[82:83]
	s_and_saveexec_b64 s[64:65], s[78:79]
	global_atomic_pk_add_bf16 v117, v20, s[24:25]
	s_or_b64 exec, exec, s[64:65]
	s_and_b64 s[78:79], s[58:59], s[82:83]
	s_and_saveexec_b64 s[64:65], s[78:79]
	global_atomic_pk_add_bf16 v118, v21, s[24:25]
	s_or_b64 exec, exec, s[64:65]
	s_and_b64 s[78:79], s[60:61], s[82:83]
	s_and_saveexec_b64 s[64:65], s[78:79]
	global_atomic_pk_add_bf16 v119, v22, s[24:25]
	s_or_b64 exec, exec, s[64:65]
	s_and_b64 s[78:79], s[62:63], s[82:83]
	s_and_saveexec_b64 s[64:65], s[78:79]
	global_atomic_pk_add_bf16 v124, v23, s[24:25]
	s_or_b64 exec, exec, s[64:65]
	.endm
	ATOMIC_TILE 128,129,130,131,0
	ATOMIC_TILE 132,133,134,135,32
	ATOMIC_TILE 136,137,138,139,64
	ATOMIC_TILE 140,141,142,143,96
	ATOMIC_TILE 144,145,146,147,128
	ATOMIC_TILE 148,149,150,151,160
	ATOMIC_TILE 152,153,154,155,192
	ATOMIC_TILE 156,157,158,159,224
	ATOMIC_TILE 160,161,162,163,256
	ATOMIC_TILE 164,165,166,167,288
	ATOMIC_TILE 168,169,170,171,320
	ATOMIC_TILE 172,173,174,175,352
	ATOMIC_TILE 176,177,178,179,384
	ATOMIC_TILE 180,181,182,183,416
	ATOMIC_TILE 184,185,186,187,448
	ATOMIC_TILE 188,189,190,191,480
.Ldown_n256_done:
	s_waitcnt vmcnt(0)
	s_add_u32 s80, s80, 1
	s_cmp_lt_u32 s80, 8
	s_cbranch_scc1 .Ldown_n256
.Lend:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_fused_m64n256_atomic_fp8_gfx950
		.amdhsa_group_segment_fixed_size 65536
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 112
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 192
		.amdhsa_accum_offset 192
		.amdhsa_next_free_sgpr 88
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_moe_fused_m64n256_atomic_fp8_gfx950, .Lfunc_end0-qwen36_moe_fused_m64n256_atomic_fp8_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: hidden_fp8, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: hidden_scale_f32, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: shuffled_w13_fp8, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: w13_scale_f32, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: shuffled_w2_fp8, .offset: 32, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: w2_scale_f32, .offset: 40, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: sorted_token_ids_i32, .offset: 48, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: sorted_weights_f32, .offset: 56, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: compact_sorted_expert_ids_i32, .offset: 64, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: num_valid_ids_i32, .offset: 72, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: output_bf16, .offset: 80, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_write }
      - { .name: rows, .offset: 88, .size: 4, .value_kind: by_value }
      - { .name: route_scale_workspace_f32, .offset: 96, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_write }
      - { .name: debug_stage, .offset: 104, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 65536
    .kernarg_segment_align: 8
    .kernarg_segment_size: 112
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_moe_fused_m64n256_atomic_fp8_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 90
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_fused_m64n256_atomic_fp8_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 192
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
