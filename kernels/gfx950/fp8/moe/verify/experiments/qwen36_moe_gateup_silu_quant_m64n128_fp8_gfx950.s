// SPDX-License-Identifier: MIT
//
// Qwen3.6 expert-sorted paired FP8 gate/up projection, SiLU, and block-128
// FP8 activation quantization for gfx950. One workgroup computes two N64
// halves sequentially, retains the deployed BF16 boundaries in 16 KiB LDS,
// then quantizes each real route with one FP32 scale per 128 columns.
// Grid: (4 N128 pairs, num_valid_ids/64, 1), workgroup: 256, LDS: 16 KiB.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected qwen36_moe_gateup_silu_quant_m64n128_fp8_gfx950
	.globl qwen36_moe_gateup_silu_quant_m64n128_fp8_gfx950
	.p2align 8
	.type qwen36_moe_gateup_silu_quant_m64n128_fp8_gfx950,@function
qwen36_moe_gateup_silu_quant_m64n128_fp8_gfx950:
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dwordx2 s[10:11], s[0:1], 24
	s_load_dwordx2 s[12:13], s[0:1], 32
	s_load_dwordx2 s[14:15], s[0:1], 40
	s_load_dwordx2 s[16:17], s[0:1], 48
	s_load_dwordx2 s[18:19], s[0:1], 56
	s_load_dwordx2 s[56:57], s[0:1], 64
	s_load_dword s58, s[0:1], 72
	s_waitcnt lgkmcnt(0)
	s_mov_b32 s20, s58

	// M64 sorted-block bounds and compact expert.
	s_lshl_b32 s21, s3, 6
	s_load_dword s22, s[16:17], 0
	s_lshl_b32 s23, s3, 2
	s_load_dword s23, s[14:15], s23
	s_waitcnt lgkmcnt(0)
	s_cmp_lt_u32 s21, s22
	s_cbranch_scc0 .Lend

	// Vector-native wave/lane coordinates avoid a readfirstlane dependency.
	v_and_b32_e32 v1, 15, v0
	v_and_b32_e32 v2, 48, v0
	v_lshrrev_b32_e32 v3, 6, v0
	v_lshlrev_b32_e32 v5, 4, v3
	v_add_u32_e32 v5, s21, v5

	// Native A route for lane[3:0].
	v_add_u32_e32 v3, v5, v1
	v_lshlrev_b32_e32 v3, 2, v3
	global_load_dword v4, v3, s[12:13]
	// Four result routes for lane[5:4].
	v_lshrrev_b32_e32 v3, 2, v2
	v_add_u32_e32 v88, v5, v3
	v_add_u32_e32 v89, 1, v88
	v_add_u32_e32 v90, 2, v88
	v_add_u32_e32 v91, 3, v88
	v_lshlrev_b32_e32 v3, 2, v88
	global_load_dword v84, v3, s[12:13]
	global_load_dword v85, v3, s[12:13] offset:4
	global_load_dword v86, v3, s[12:13] offset:8
	global_load_dword v87, v3, s[12:13] offset:12
	s_waitcnt vmcnt(0)

	// Decode/clamp the A token. Slot 9 is padding.
	v_lshrrev_b32_e32 v6, 24, v4
	v_and_b32_e32 v4, 0x00ffffff, v4
	v_cmp_gt_u32_e32 vcc, s20, v4
	v_cndmask_b32_e32 v4, 0, v4, vcc
	v_cmp_gt_u32_e32 vcc, 9, v6
	v_cndmask_b32_e32 v4, 0, v4, vcc

	// Convert each packed sorted ID to a clamped scale row and a unique
	// route-major destination. Padded rows use rows*9+sorted_row sinks.
	s_lshl_b32 s39, s20, 3
	s_add_u32 s39, s39, s20
	.macro DECODE_ROUTE token, sortedrow, route
	v_lshrrev_b32_e32 v6, 24, v\token
	v_and_b32_e32 v\token, 0x00ffffff, v\token
	v_lshlrev_b32_e32 v3, 3, v\token
	v_add_u32_e32 v\route, v\token, v3
	v_add_u32_e32 v\route, v6, v\route
	v_add_u32_e32 v3, s39, v\sortedrow
	v_cmp_gt_u32_e32 vcc, s20, v\token
	v_cndmask_b32_e32 v\route, v3, v\route, vcc
	v_cndmask_b32_e32 v\token, 0, v\token, vcc
	v_cmp_gt_u32_e32 vcc, 9, v6
	v_cndmask_b32_e32 v\route, v3, v\route, vcc
	v_cndmask_b32_e32 v\token, 0, v\token, vcc
	.endm
	DECODE_ROUTE 84,88,116
	DECODE_ROUTE 85,89,117
	DECODE_ROUTE 86,90,118
	DECODE_ROUTE 87,91,119

	// Expert bases and four shuffled N16 gate/up weight-tile bases.
	s_lshl_b32 s24, s23, 21
	s_add_u32 s32, s8, s24
	s_addc_u32 s33, s9, 0
	s_lshl_b32 s24, s23, 9
	s_add_u32 s34, s10, s24
	s_addc_u32 s35, s11, 0
	s_lshl_b32 s24, s2, 18
	s_add_u32 s32, s32, s24
	s_addc_u32 s33, s33, 0
	s_add_u32 s40, s32, 32768
	s_addc_u32 s41, s33, 0
	s_add_u32 s42, s32, 65536
	s_addc_u32 s43, s33, 0
	s_add_u32 s44, s32, 98304
	s_addc_u32 s45, s33, 0
	s_add_u32 s46, s32, 1048576
	s_addc_u32 s47, s33, 0
	s_add_u32 s48, s40, 1048576
	s_addc_u32 s49, s41, 0
	s_add_u32 s50, s42, 1048576
	s_addc_u32 s51, s43, 0
	s_add_u32 s52, s44, 1048576
	s_addc_u32 s53, s45, 0

	// A and LDS fragment addresses, cooperative loader byte offset.
	v_lshlrev_b32_e32 v94, 11, v4
	v_add_u32_e32 v94, v2, v94
	v_lshlrev_b32_e32 v93, 4, v2
	v_lshlrev_b32_e32 v92, 4, v1
	v_add_u32_e32 v93, v93, v92
	v_lshlrev_b32_e32 v92, 3, v0

	// One W scale covers this N128 group; output starts at x*128.
	s_lshl_b32 s25, s2, 6
	s_lshl_b32 s26, s2, 7
	s_mov_b32 s59, 0


.Lhalf_loop:
	// Gate and up each retain sixteen FP32 accumulators.
	.macro ZERO_ACC reg
	v_mov_b32_e32 v\reg, 0
	.endm
	.irp r,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79
	ZERO_ACC \r
	.endr
	.irp r,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115
	ZERO_ACC \r
	.endr
	s_mov_b32 s27, 0

.Lk_loop:
	// Load the gate half and the shared A fragment/scales.
	s_lshl_b32 s28, s27, 11
	v_add_u32_e32 v95, s28, v92
	global_load_dwordx2 v[16:17], v95, s[32:33]
	global_load_dwordx2 v[24:25], v95, s[40:41]
	global_load_dwordx2 v[32:33], v95, s[42:43]
	global_load_dwordx2 v[40:41], v95, s[44:45]
	// During the first N64 half, the paired up slab can occupy the otherwise
	// unused upper 8 KiB of LDS.  During the second half that slab holds the
	// first half's activation results, so preserve it and use the lower-LDS
	// producer path after the gate MFMA instead.
	s_cmp_eq_u32 s59, 0
	s_cbranch_scc0 .Lskip_paired_up_preload
	global_load_dwordx2 v[48:49], v95, s[46:47]
	global_load_dwordx2 v[50:51], v95, s[48:49]
	global_load_dwordx2 v[52:53], v95, s[50:51]
	global_load_dwordx2 v[54:55], v95, s[52:53]
.Lskip_paired_up_preload:

	// Per-wave A fragment.
	s_lshl_b32 s29, s27, 7
	v_add_u32_e32 v96, s29, v94
	global_load_dwordx4 v[8:11], v96, s[4:5]
	global_load_dwordx4 v[12:15], v96, s[4:5] offset:64

	// Four activation scales and shared W scale.
	s_lshl_b32 s30, s27, 2
	v_lshlrev_b32_e32 v96, 6, v84
	v_add_u32_e32 v96, s30, v96
	global_load_dword v80, v96, s[6:7]
	v_lshlrev_b32_e32 v96, 6, v85
	v_add_u32_e32 v96, s30, v96
	global_load_dword v81, v96, s[6:7]
	v_lshlrev_b32_e32 v96, 6, v86
	v_add_u32_e32 v96, s30, v96
	global_load_dword v82, v96, s[6:7]
	v_lshlrev_b32_e32 v96, 6, v87
	v_add_u32_e32 v96, s30, v96
	global_load_dword v83, v96, s[6:7]
	s_add_u32 s31, s25, s30
	s_load_dword s36, s[34:35], s31
	s_add_u32 s38, s31, 256
	s_load_dword s37, s[34:35], s38

	s_waitcnt vmcnt(0) & lgkmcnt(0)
	ds_write_b64 v92, v[16:17]
	ds_write_b64 v92, v[24:25] offset:2048
	ds_write_b64 v92, v[32:33] offset:4096
	ds_write_b64 v92, v[40:41] offset:6144
	s_cmp_eq_u32 s59, 0
	s_cbranch_scc0 .Lskip_paired_up_store
	ds_write_b64 v92, v[48:49] offset:8192
	ds_write_b64 v92, v[50:51] offset:10240
	ds_write_b64 v92, v[52:53] offset:12288
	ds_write_b64 v92, v[54:55] offset:14336
.Lskip_paired_up_store:
	s_waitcnt lgkmcnt(0)
	s_barrier

	ds_read_b128 v[16:19], v93
	ds_read_b128 v[20:23], v93 offset:1024
	ds_read_b128 v[24:27], v93 offset:2048
	ds_read_b128 v[28:31], v93 offset:3072
	ds_read_b128 v[32:35], v93 offset:4096
	ds_read_b128 v[36:39], v93 offset:5120
	ds_read_b128 v[40:43], v93 offset:6144
	ds_read_b128 v[44:47], v93 offset:7168
	s_waitcnt lgkmcnt(0)

	// Four independent matrix instructions cover N64.
	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	s_nop 12

	.macro SCALE_ACC tmp, acc, scale
	v_mul_f32_e32 v\tmp, s36, v\tmp
	v_fmac_f32_e32 v\acc, v\scale, v\tmp
	.endm
	SCALE_ACC 48,64,80
	SCALE_ACC 49,65,81
	SCALE_ACC 50,66,82
	SCALE_ACC 51,67,83
	SCALE_ACC 52,68,80
	SCALE_ACC 53,69,81
	SCALE_ACC 54,70,82
	SCALE_ACC 55,71,83
	SCALE_ACC 56,72,80
	SCALE_ACC 57,73,81
	SCALE_ACC 58,74,82
	SCALE_ACC 59,75,83
	SCALE_ACC 60,76,80
	SCALE_ACC 61,77,81
	SCALE_ACC 62,78,82
	SCALE_ACC 63,79,83

	// The first half consumes its already-resident upper slab directly.
	// The second half must preserve that slab, so refill lower LDS only after
	// every wave has finished reading the gate fragment.
	s_cmp_eq_u32 s59, 0
	s_cbranch_scc0 .Lsecond_half_up_producer
	ds_read_b128 v[16:19], v93 offset:8192
	ds_read_b128 v[20:23], v93 offset:9216
	ds_read_b128 v[24:27], v93 offset:10240
	ds_read_b128 v[28:31], v93 offset:11264
	ds_read_b128 v[32:35], v93 offset:12288
	ds_read_b128 v[36:39], v93 offset:13312
	ds_read_b128 v[40:43], v93 offset:14336
	ds_read_b128 v[44:47], v93 offset:15360
	s_branch .Lup_fragment_wait

.Lsecond_half_up_producer:
	s_barrier
	global_load_dwordx2 v[16:17], v95, s[46:47]
	global_load_dwordx2 v[24:25], v95, s[48:49]
	global_load_dwordx2 v[32:33], v95, s[50:51]
	global_load_dwordx2 v[40:41], v95, s[52:53]
	s_waitcnt vmcnt(0)
	ds_write_b64 v92, v[16:17]
	ds_write_b64 v92, v[24:25] offset:2048
	ds_write_b64 v92, v[32:33] offset:4096
	ds_write_b64 v92, v[40:41] offset:6144
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[16:19], v93
	ds_read_b128 v[20:23], v93 offset:1024
	ds_read_b128 v[24:27], v93 offset:2048
	ds_read_b128 v[28:31], v93 offset:3072
	ds_read_b128 v[32:35], v93 offset:4096
	ds_read_b128 v[36:39], v93 offset:5120
	ds_read_b128 v[40:43], v93 offset:6144
	ds_read_b128 v[44:47], v93 offset:7168
.Lup_fragment_wait:
	s_waitcnt lgkmcnt(0)

	v_mfma_f32_16x16x128_f8f6f4 v[48:51], v[8:15], v[16:23], 0
	v_mfma_f32_16x16x128_f8f6f4 v[52:55], v[8:15], v[24:31], 0
	v_mfma_f32_16x16x128_f8f6f4 v[56:59], v[8:15], v[32:39], 0
	v_mfma_f32_16x16x128_f8f6f4 v[60:63], v[8:15], v[40:47], 0
	s_nop 12

	s_mov_b32 s36, s37
	SCALE_ACC 48,100,80
	SCALE_ACC 49,101,81
	SCALE_ACC 50,102,82
	SCALE_ACC 51,103,83
	SCALE_ACC 52,104,80
	SCALE_ACC 53,105,81
	SCALE_ACC 54,106,82
	SCALE_ACC 55,107,83
	SCALE_ACC 56,108,80
	SCALE_ACC 57,109,81
	SCALE_ACC 58,110,82
	SCALE_ACC 59,111,83
	SCALE_ACC 60,112,80
	SCALE_ACC 61,113,81
	SCALE_ACC 62,114,82
	SCALE_ACC 63,115,83

	s_barrier
	s_add_u32 s27, s27, 1
	s_cmp_lt_u32 s27, 16
	s_cbranch_scc1 .Lk_loop

	// Match the deployed BF16 gate/up and activation boundaries. The first
	// N64 half occupies upper LDS and the second occupies lower LDS, both in
	// the native MFMA lane layout: wave/lane/tile/two-row-pair.
	s_cmp_eq_u32 s59, 0
	s_cselect_b32 s60, 8192, 0
	v_lshrrev_b32_e32 v32, 6, v0
	v_lshlrev_b32_e32 v32, 11, v32
	v_and_b32_e32 v33, 63, v0
	v_lshlrev_b32_e32 v33, 5, v33
	v_add_u32_e32 v32, v33, v32
	v_add_u32_e32 v32, s60, v32
	s_mov_b32 s54, 0xbfb8aa3b
	s_mov_b32 s55, 0x3f800000

	.macro ACT_LDS_STORE g0,g1,g2,g3,u0,u1,u2,u3,tileoff
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
	v_mul_f32_e32 v28, s54, v20
	v_mul_f32_e32 v29, s54, v21
	v_mul_f32_e32 v30, s54, v22
	v_mul_f32_e32 v31, s54, v23
	v_exp_f32_e32 v28, v28
	v_exp_f32_e32 v29, v29
	v_exp_f32_e32 v30, v30
	v_exp_f32_e32 v31, v31
	v_add_f32_e32 v28, s55, v28
	v_add_f32_e32 v29, s55, v29
	v_add_f32_e32 v30, s55, v30
	v_add_f32_e32 v31, s55, v31
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
	ACT_LDS_STORE 64,65,66,67,100,101,102,103,0
	ACT_LDS_STORE 68,69,70,71,104,105,106,107,8
	ACT_LDS_STORE 72,73,74,75,108,109,110,111,16
	ACT_LDS_STORE 76,77,78,79,112,113,114,115,24
	s_waitcnt lgkmcnt(0)
	s_barrier

	// The second N64 half shares the same block-128 weight scale.
	s_cmp_eq_u32 s59, 0
	s_cbranch_scc0 .Lquant_phase
	s_add_u32 s32, s32, 131072
	s_addc_u32 s33, s33, 0
	s_add_u32 s40, s40, 131072
	s_addc_u32 s41, s41, 0
	s_add_u32 s42, s42, 131072
	s_addc_u32 s43, s43, 0
	s_add_u32 s44, s44, 131072
	s_addc_u32 s45, s45, 0
	s_add_u32 s46, s46, 131072
	s_addc_u32 s47, s47, 0
	s_add_u32 s48, s48, 131072
	s_addc_u32 s49, s49, 0
	s_add_u32 s50, s50, 131072
	s_addc_u32 s51, s51, 0
	s_add_u32 s52, s52, 131072
	s_addc_u32 s53, s53, 0
	s_mov_b32 s59, 1
	s_branch .Lhalf_loop

.Lquant_phase:
	// Eight vector-native 32-lane subgroups quantize eight routes at a time.
	// Each lane owns four adjacent columns, giving one dword FP8 store.
	v_and_b32_e32 v1, 31, v0
	v_lshrrev_b32_e32 v2, 5, v0
	v_and_b32_e32 v25, 63, v0
	s_mov_b32 s61, 0
	s_mov_b32 s71, 8192
	s_mov_b32 s72, 0x3b124925
	s_mov_b32 s73, 0x2edbe6ff
	s_lshl_b32 s68, s2, 7
	s_lshl_b32 s69, s2, 2
	s_mov_b32 s70, 0x05040100

.Lquant_batch_loop:
	s_lshl_b32 s62, s61, 3
	v_add_u32_e32 v3, s62, v2
	v_add_u32_e32 v4, s21, v3
	v_lshlrev_b32_e32 v4, 2, v4
	global_load_dword v5, v4, s[12:13]

	// Native-layout address for four adjacent columns of this route.
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
	v_mov_b32_e32 v9, s71
	v_cndmask_b32_e32 v9, 0, v9, vcc
	v_add_u32_e32 v6, v9, v6
	ds_read_u16 v12, v6
	ds_read_u16 v13, v6 offset:32
	ds_read_u16 v14, v6 offset:64
	ds_read_u16 v15, v6 offset:96
	s_waitcnt vmcnt(0) & lgkmcnt(0)

	// Packed ID and four BF16 values become vector-native route state.
	v_lshrrev_b32_e32 v16, 24, v5
	v_and_b32_e32 v17, 0x00ffffff, v5
	v_mul_lo_u32 v18, 9, v17
	v_add_u32_e32 v18, v16, v18
	v_lshlrev_b32_e32 v20, 16, v12
	v_lshlrev_b32_e32 v21, 16, v13
	v_lshlrev_b32_e32 v22, 16, v14
	v_lshlrev_b32_e32 v23, 16, v15
	v_max3_f32 v24, |v20|, |v21|, s73
	v_max3_f32 v24, v24, |v22|, |v23|

	// Exact max within each 32-lane subgroup (128 values).
	.irp mask,1,2,4,8,16
	v_xor_b32_e32 v26, \mask, v25
	v_lshlrev_b32_e32 v26, 2, v26
	ds_bpermute_b32 v27, v26, v24
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v24, v24, v27
	.endr
	v_mul_f32_e32 v24, s72, v24

	// Preserve a validity mask for both scale and FP8 stores.
	v_cmp_gt_u32_e64 s[74:75], 9, v16
	v_cmp_gt_u32_e64 s[76:77], s20, v17
	s_and_b64 s[74:75], s[74:75], s[76:77]
	v_cmp_eq_u32_e64 s[76:77], 0, v1
	s_and_b64 s[76:77], s[76:77], s[74:75]
	v_lshlrev_b32_e32 v26, 4, v18
	v_add_u32_e32 v26, s69, v26
	s_and_saveexec_b64 s[78:79], s[76:77]
	global_store_dword v26, v24, s[56:57]
	s_or_b64 exec, exec, s[78:79]

	// Match the deployed reciprocal refinement and FP8 E4M3 conversion.
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
	v_perm_b32 v28, v29, v28, s70
	v_lshlrev_b32_e32 v26, 9, v18
	v_add_u32_e32 v26, s68, v26
	v_lshlrev_b32_e32 v27, 2, v1
	v_add_u32_e32 v26, v27, v26
	s_and_saveexec_b64 s[78:79], s[74:75]
	global_store_dword v26, v28, s[18:19]
	s_or_b64 exec, exec, s[78:79]

	s_add_u32 s61, s61, 1
	s_cmp_lt_u32 s61, 8
	s_cbranch_scc1 .Lquant_batch_loop
	s_waitcnt vmcnt(0)
.Lend:
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.amdhsa_kernel qwen36_moe_gateup_silu_quant_m64n128_fp8_gfx950
		.amdhsa_group_segment_fixed_size 16384
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 80
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 120
		.amdhsa_accum_offset 120
		.amdhsa_next_free_sgpr 80
		.amdhsa_reserve_vcc 1
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size qwen36_moe_gateup_silu_quant_m64n128_fp8_gfx950, .Lfunc_end0-qwen36_moe_gateup_silu_quant_m64n128_fp8_gfx950

	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: hidden_fp8, .offset: 0, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: hidden_scale_f32, .offset: 8, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: shuffled_w13_fp8, .offset: 16, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: w13_scale_f32, .offset: 24, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: sorted_token_ids_i32, .offset: 32, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: compact_sorted_expert_ids_i32, .offset: 40, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: num_valid_ids_i32, .offset: 48, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: read_only }
      - { .name: route_activation_fp8, .offset: 56, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: route_scale_f32, .offset: 64, .size: 8, .value_kind: global_buffer, .address_space: global, .actual_access: write_only }
      - { .name: rows, .offset: 72, .size: 4, .value_kind: by_value }
    .group_segment_fixed_size: 16384
    .kernarg_segment_align: 8
    .kernarg_segment_size: 80
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 256
    .name: qwen36_moe_gateup_silu_quant_m64n128_fp8_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 82
    .sgpr_spill_count: 0
    .symbol: qwen36_moe_gateup_silu_quant_m64n128_fp8_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 120
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
