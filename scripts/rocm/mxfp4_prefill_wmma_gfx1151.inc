// Shared raw-ISA macros for gfx1151 grouped MXFP4 prefill kernels.

	.macro PREFILL_DECODE_TO W O0 O1 O2 O3 U0 U1 U2 U3
	v_and_b32_e32 v88, 0x07070707, \W
	v_lshrrev_b32_e32 v89, 4, \W
	v_and_b32_e32 v89, 0x07070707, v89
	v_lshlrev_b32_e32 v90, 4, \W
	v_and_b32_e32 v91, 0x80808080, \W
	v_perm_b32 v92, v5, v4, v88
	v_perm_b32 v93, v5, v4, v89
	v_perm_b32 v94, v7, v6, v88
	v_perm_b32 v95, v7, v6, v89
	v_and_b32_e32 v90, 0x80808080, v90
	v_or_b32_e32 v94, v90, v94
	v_or_b32_e32 v95, v91, v95
	v_perm_b32 v96, v94, v92, 0x05010400
	v_perm_b32 v97, v94, v92, 0x07030602
	v_perm_b32 v98, v95, v93, 0x05010400
	v_perm_b32 v99, v95, v93, 0x07030602
	v_perm_b32 \O0, v98, v96, 0x05040100
	v_perm_b32 \O1, v98, v96, 0x07060302
	v_perm_b32 \O2, v99, v97, 0x05040100
	v_perm_b32 \O3, v99, v97, 0x07060302
	ds_swizzle_b32 \U0, \O0 offset:swizzle(SWAP,16)
	ds_swizzle_b32 \U1, \O1 offset:swizzle(SWAP,16)
	ds_swizzle_b32 \U2, \O2 offset:swizzle(SWAP,16)
	ds_swizzle_b32 \U3, \O3 offset:swizzle(SWAP,16)
	.endm

	.macro PREFILL_ACC_TILE AOFF C0 C1 C2 C3 C4 C5 C6 C7
	v_dual_mov_b32 v64, 0 :: v_dual_mov_b32 v65, 0
	v_dual_mov_b32 v66, 0 :: v_dual_mov_b32 v67, 0
	v_dual_mov_b32 v68, 0 :: v_dual_mov_b32 v69, 0
	v_dual_mov_b32 v70, 0 :: v_dual_mov_b32 v71, 0
	v_add_nc_u32_e32 v13, \AOFF, v8
	global_load_b128 v[72:75], v13, s[8:9]
	global_load_b128 v[80:83], v13, s[8:9] offset:32
	s_waitcnt vmcnt(0)
	ds_swizzle_b32 v76, v72 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v77, v73 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v78, v74 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v79, v75 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v84, v80 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v85, v81 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v86, v82 offset:swizzle(SWAP,16)
	ds_swizzle_b32 v87, v83 offset:swizzle(SWAP,16)
	s_waitcnt lgkmcnt(0)
	v_wmma_f32_16x16x16_bf16 v[64:71], v[72:79], v[16:23], v[64:71]
	v_wmma_f32_16x16x16_bf16 v[64:71], v[80:87], v[24:31], v[64:71]
	v_fmac_f32_e32 \C0, v64, v104
	v_fmac_f32_e32 \C1, v65, v104
	v_fmac_f32_e32 \C2, v66, v104
	v_fmac_f32_e32 \C3, v67, v104
	v_fmac_f32_e32 \C4, v68, v104
	v_fmac_f32_e32 \C5, v69, v104
	v_fmac_f32_e32 \C6, v70, v104
	v_fmac_f32_e32 \C7, v71, v104
	.endm

	.macro PREFILL_STORE_TILE ROWBYTES C0 C1 C2 C3 C4 C5 C6 C7
	ds_swizzle_b32 v72, \C4 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v76, \C0 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v73, \C5 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v77, \C1 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v74, \C6 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v78, \C2 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v75, \C7 offset:swizzle(ROTATE,1,16)
	ds_swizzle_b32 v79, \C3 offset:swizzle(ROTATE,1,16)
	s_waitcnt lgkmcnt(0)
	v_mov_b32_dpp v72, \C0 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp \C4, v76 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp v73, \C1 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp \C5, v77 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp v74, \C2 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp \C6, v78 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp v75, \C3 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	v_mov_b32_dpp \C7, v79 quad_perm:[0,1,2,3] row_mask:0x5 bank_mask:0xf
	global_store_b32 v11, v72, s[10:11]
	v_add_nc_u32_e32 v11, \ROWBYTES, v11
	global_store_b32 v11, \C4, s[10:11]
	v_add_nc_u32_e32 v11, \ROWBYTES, v11
	global_store_b32 v11, v73, s[10:11]
	v_add_nc_u32_e32 v11, \ROWBYTES, v11
	global_store_b32 v11, \C5, s[10:11]
	v_add_nc_u32_e32 v11, \ROWBYTES, v11
	global_store_b32 v11, v74, s[10:11]
	v_add_nc_u32_e32 v11, \ROWBYTES, v11
	global_store_b32 v11, \C6, s[10:11]
	v_add_nc_u32_e32 v11, \ROWBYTES, v11
	global_store_b32 v11, v75, s[10:11]
	v_add_nc_u32_e32 v11, \ROWBYTES, v11
	global_store_b32 v11, \C7, s[10:11]
	v_add_nc_u32_e32 v11, \ROWBYTES, v11
	.endm
