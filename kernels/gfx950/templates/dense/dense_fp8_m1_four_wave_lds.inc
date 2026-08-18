// SPDX-License-Identifier: MIT
// Four-wave LDS gfx950 schedule for the exact specialized dense FP8 M=1 contract.

	.include "common/abi.inc"
	.include "common/metadata.inc"
	.include "dense/fp8_block128.inc"
	.include "dense/mfma_tiles.inc"
	.include "dense/weight_layouts.inc"
	.include "dense/epilogues.inc"

	.macro NETRA_DENSE_FP8_M1_FOUR_WAVE_LDS symbol
	NETRA_REQUIRE_FP8_BLOCK128_M1
	NETRA_REQUIRE_MFMA_TILE_N
	NETRA_REQUIRE_AITER_SHUFFLE_16X16
	.if NETRA_WAVES_PER_WG != 4
	.error "four-wave schedule requires NETRA_WAVES_PER_WG=4"
	.endif

	NETRA_GFX950_KERNEL_BEGIN \symbol
	// Kernargs: activation FP8, activation scales FP32, shuffled weight FP8,
	//           weight scales FP32, output BF16.
	s_load_dwordx2 s[4:5], s[0:1], 0
	s_load_dwordx2 s[6:7], s[0:1], 8
	s_load_dwordx2 s[8:9], s[0:1], 16
	s_load_dwordx2 s[10:11], s[0:1], 24
	s_load_dwordx2 s[12:13], s[0:1], 32
	s_waitcnt lgkmcnt(0)

	// tile = workgroup_id*4 + wave_id.
	v_lshrrev_b32_e32 v31, 6, v0
	v_and_b32_e32 v1, 15, v0
	v_and_b32_e32 v2, 48, v0
	s_lshl_b32 s17, s2, 6
	v_lshlrev_b32_e32 v3, 4, v31
	v_add_u32_e32 v3, s17, v3
	v_add_u32_e32 v3, v3, v1
	v_mov_b32_e32 v6, 0

	// Physical shuffled-weight offset for K-block zero.
	s_lshl_b32 s19, s2, 18
	v_lshlrev_b32_e32 v4, 16, v31
	v_add_u32_e32 v4, s19, v4
	v_lshlrev_b32_e32 v5, 4, v2
	v_add_u32_e32 v4, v4, v5
	v_lshlrev_b32_e32 v5, 4, v1
	v_add_u32_e32 v4, v4, v5

	// One 128x128 scale covers two adjacent four-tile workgroups.
	s_lshr_b32 s20, s2, 1
	s_lshl_b32 s20, s20, 7
	s_add_u32 s22, s10, s20
	s_addc_u32 s23, s11, 0

	s_mov_b32 s24, 0
.Lkblock:
	s_lshl_b32 s25, s24, 7
	s_lshl_b32 s26, s24, 2
	s_load_dword s27, s[6:7], s26
	s_load_dword s28, s[22:23], s26

	// Workitems 0..31 cooperatively stage this activation block.
	v_cmp_gt_u32_e32 vcc, 32, v0
	s_and_saveexec_b64 s[30:31], vcc
	v_lshlrev_b32_e32 v31, 2, v0
	v_add_u32_e32 v7, s25, v31
	global_load_dword v30, v7, s[4:5]
	s_waitcnt vmcnt(0)
	ds_write_b32 v31, v30
	s_waitcnt lgkmcnt(0)
	s_or_b64 exec, exec, s[30:31]
	s_barrier

	ds_read_b128 v[10:13], v2
	ds_read_b128 v[14:17], v2 offset:64

	// One K=128 block occupies 2,048 bytes in the AITER preshuffle.
	s_lshl_b32 s29, s24, 11
	v_add_u32_e32 v8, s29, v4
	global_load_dwordx4 v[18:21], v8, s[8:9]
	global_load_dwordx4 v[22:25], v8, s[8:9] offset:1024
	v_mov_b32_e32 v26, 0
	v_mov_b32_e32 v27, 0
	v_mov_b32_e32 v28, 0
	v_mov_b32_e32 v29, 0

	s_waitcnt lgkmcnt(0)
	s_barrier
	s_waitcnt vmcnt(0) & lgkmcnt(0)
	v_mfma_f32_16x16x128_f8f6f4 v[26:29], v[10:17], v[18:25], 0
	s_nop 15
	v_mul_f32_e32 v9, s27, v26
	v_mul_f32_e32 v9, s28, v9
	v_add_f32_e32 v6, v6, v9

	s_add_u32 s24, s24, 1
	s_cmp_lt_u32 s24, NETRA_MFMA_KBLOCKS
	s_cbranch_scc1 .Lkblock

	NETRA_STORE_IDENTITY_LANE_GROUP_ZERO
	s_endpgm
	NETRA_DENSE_FIVE_POINTER_METADATA \symbol, 128, 256, 32, 32
	.endm
