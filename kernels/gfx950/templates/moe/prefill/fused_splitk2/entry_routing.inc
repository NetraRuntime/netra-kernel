// SPDX-License-Identifier: MIT
// Fixed ABI, split selection, route validation, and W13 address setup.

	.macro NETRA_MOE_PREFILL_FUSED_SPLITK2_ENTRY_ROUTING symbol
	.text
	.protected \symbol
	.globl \symbol
	.p2align 8
	.type \symbol,@function
\symbol:
	s_load_dwordx2 s[4:5], s[0:1], 0x0
	s_load_dwordx2 s[6:7], s[0:1], 0x8
	s_load_dwordx2 s[8:9], s[0:1], 0x10
	s_load_dwordx2 s[10:11], s[0:1], 0x18
	s_load_dwordx2 s[12:13], s[0:1], 0x20
	s_load_dwordx2 s[14:15], s[0:1], 0x28
	s_load_dwordx2 s[16:17], s[0:1], 0x30
	s_load_dwordx2 s[18:19], s[0:1], 0x38
	s_load_dwordx2 s[20:21], s[0:1], 0x40
	s_load_dwordx2 s[22:23], s[0:1], 0x48
	s_load_dwordx2 s[24:25], s[0:1], 0x50
	s_load_dword s26, s[0:1], 0x58
	s_load_dwordx2 s[84:85], s[0:1], 0x60
	s_load_dword s86, s[0:1], 0x68
	s_waitcnt lgkmcnt(0)
	s_lshl_b32 s27, s3, 6
	s_load_dword s28, s[22:23], 0x0
	s_lshl_b32 s29, s3, 2
	s_load_dword s29, s[20:21], s29
	s_waitcnt lgkmcnt(0)
	s_cmp_lt_u32 s27, s28
	s_cbranch_scc0 .L_1844
	// Split-K half selector: workgroup x in {0,1} owns W13 N128 groups
	// {2x, 2x+1} and the matching W2 K128 slices, and writes its own half
	// of the partial workspace. The two-half reducer sums them.
	s_lshl_b32 s88, s2, 1
	s_add_u32 s89, s88, 2
	s_mul_i32 s30, s26, 9
	// The final scalar argument carries the launched block capacity in normal
	// operation (values 1 and 2 remain reserved for the old debug exits).
	// Using that fixed capacity makes the split-half stride graph-capturable;
	// the host need not copy num_valid_ids back from the device.
	s_add_u32 s30, s30, s86
	s_lshl_b32 s30, s30, 12
	s_mul_i32 s30, s30, s2
	s_add_u32 s24, s24, s30
	s_addc_u32 s25, s25, 0
	v_and_b32_e32 v1, 15, v0
	v_and_b32_e32 v2, 48, v0
	v_lshrrev_b32_e32 v3, 6, v0
	v_lshlrev_b32_e32 v5, 4, v3
	v_add_u32_e32 v5, s27, v5
	v_add_u32_e32 v3, v5, v1
	v_lshlrev_b32_e32 v3, 2, v3
	global_load_dword v4, v3, s[16:17]
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
	s_waitcnt vmcnt(0)
	v_lshrrev_b32_e32 v6, 24, v4
	v_and_b32_e32 v4, 0xffffff, v4
	v_cmp_gt_u32_e32 vcc, s26, v4
	v_cndmask_b32_e32 v4, 0, v4, vcc
	v_cmp_gt_u32_e32 vcc, 9, v6
	v_cndmask_b32_e32 v4, 0, v4, vcc
	v_lshrrev_b32_e32 v6, 24, v84
	v_and_b32_e32 v7, 0xffffff, v84
	v_mul_lo_u32 v120, 9, v7
	v_add_u32_e32 v120, v6, v120
	v_cmp_gt_u32_e64 s[56:57], 9, v6
	v_cmp_gt_u32_e64 s[82:83], s26, v7
	s_and_b64 s[56:57], s[56:57], s[82:83]
	v_cndmask_b32_e64 v84, 0, v7, s[56:57]
	v_lshrrev_b32_e32 v6, 24, v85
	v_and_b32_e32 v7, 0xffffff, v85
	v_mul_lo_u32 v121, 9, v7
	v_add_u32_e32 v121, v6, v121
	v_cmp_gt_u32_e64 s[58:59], 9, v6
	v_cmp_gt_u32_e64 s[82:83], s26, v7
	s_and_b64 s[58:59], s[58:59], s[82:83]
	v_cndmask_b32_e64 v85, 0, v7, s[58:59]
	v_lshrrev_b32_e32 v6, 24, v86
	v_and_b32_e32 v7, 0xffffff, v86
	v_mul_lo_u32 v122, 9, v7
	v_add_u32_e32 v122, v6, v122
	v_cmp_gt_u32_e64 s[60:61], 9, v6
	v_cmp_gt_u32_e64 s[82:83], s26, v7
	s_and_b64 s[60:61], s[60:61], s[82:83]
	v_cndmask_b32_e64 v86, 0, v7, s[60:61]
	v_lshrrev_b32_e32 v6, 24, v87
	v_and_b32_e32 v7, 0xffffff, v87
	v_mul_lo_u32 v123, 9, v7
	v_add_u32_e32 v123, v6, v123
	v_cmp_gt_u32_e64 s[62:63], 9, v6
	v_cmp_gt_u32_e64 s[82:83], s26, v7
	s_and_b64 s[62:63], s[62:63], s[82:83]
	v_cndmask_b32_e64 v87, 0, v7, s[62:63]
	s_mul_i32 s54, s26, 9
	s_add_u32 s54, s54, s3
	v_mov_b32_e32 v6, s54
	v_cndmask_b32_e64 v120, v6, v120, s[56:57]
	v_cndmask_b32_e64 v121, v6, v121, s[58:59]
	v_cndmask_b32_e64 v122, v6, v122, s[60:61]
	v_cndmask_b32_e64 v123, v6, v123, s[62:63]
	s_or_b64 s[66:67], s[56:57], s[58:59]
	s_or_b64 s[64:65], s[60:61], s[62:63]
	s_or_b64 s[66:67], s[66:67], s[64:65]
	v_lshlrev_b32_e32 v94, 11, v4
	v_add_u32_e32 v94, v2, v94
	v_lshlrev_b32_e32 v93, 4, v2
	v_lshlrev_b32_e32 v92, 4, v1
	v_add_u32_e32 v93, v93, v92
	v_add_u32_e32 v93, 0x8000, v93
	// Waves 0-1 cooperatively load 16 bytes per lane; waves 2-3 consume the
	// shared LDS tile but do not duplicate the global/LDS transfer work.
	v_lshlrev_b32_e32 v92, 4, v0
	v_readfirstlane_b32 s75, v0
	s_lshl_b32 s30, s29, 21
	s_add_u32 s68, s8, s30
	s_addc_u32 s69, s9, 0
	s_lshl_b32 s30, s29, 9
	s_add_u32 s70, s10, s30
	s_addc_u32 s71, s11, 0
	s_mov_b32 s80, s88
	.endm
