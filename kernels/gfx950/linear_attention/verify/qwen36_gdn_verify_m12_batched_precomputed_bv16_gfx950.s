// SPDX-License-Identifier: MIT
//
// Shape-gated raw gfx950 recurrent core for the exact Qwen3.6 dFlash
// target-verification family:
//   B=1..64, T=12, H=16, HV=32, K=128, V=128, BV=16.
//
// Q/K normalization and the scalar decay/beta gates are precomputed in FP32.
// The paired precompute kernel supplies these inputs. Variant 15 is the
// full-cache selection: variant 13 arithmetic plus the deployed packed
// decoder's BF16 state commit between verification positions.  A K0 build
// sets NETRA_GDN_K0_NO_INTERMEDIATE=1 and uses variant 13: target verification
// produces BF16 outputs but neither rounds the live FP32 recurrence between
// positions nor writes the twelve rollback snapshots.
//
// Grid: B*256 one-wave workgroups.
// local_workgroup_x = workgroup_x % 256 = hv * 8 + v_tile.
// Each lane owns four V rows and eight consecutive K values (32 FP32 state
// registers).  K/Q vectors are cooperatively staged through 1 KiB LDS.

	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text

	// Variant 13 is the bit-exact packed reduction order recovered from the
	// deployed gfx950 Triton BV16 code object. Variant 15 adds the M=1 packed
	// state lifecycle. The other values are retained for arithmetic attribution:
	//   0: original forward FMA chain + one-direction scan
	//   1: Triton reverse add chain + XOR reduction
	//   2: forward add chain + XOR reduction
	//   3: Triton reverse add chain + one-direction scan
	//   4: balanced local add tree + XOR reduction
	//   5: forward K add chain + forward Q FMA chain + XOR reduction
	//   6: forward K add chain + reverse Q FMA chain + XOR reduction
	//   7: forward K add chain + reverse Q add chain + XOR reduction
	//   8: forward K add chain + balanced Q add tree + XOR reduction
	//   9: forward K add chain + Q FMA order 1,0,2,3,4,5,6,7
	//  10: forward K add chain + Q FMA order 1,0,3,2,5,4,7,6
	//  11: forward K add chain + Q FMA order 7,6,4,5,2,3,0,1
	//  12: forward K add chain + reverse Q FMA order 7..0
	//  13: deployed packed-Q order: forward for V rows 0-3/8-11 and
	//      1,0,2,3,4,5,6,7 for V rows 4-7/12-15
	//  14: rejected pre-output BF16 state round; changes the current output
	//  15: variant 13 output arithmetic, then a BF16 state commit before the
	//      next verification position (the actual packed-decode lifecycle)
	//  16: experimental packed even/odd dot-product chains. This reduces each
	//      eight-term local dot from eleven instructions to five, but changes
	//      the FP32 reduction order and therefore requires real-checkpoint gates.
	//  17: variant 16 arithmetic with four independent V-row chains interleaved
	//      to cover packed-VALU dependency latency on gfx950.
	.ifndef NETRA_GDN_CORE_VARIANT
	.set NETRA_GDN_CORE_VARIANT, 15
	.endif
	.ifndef NETRA_GDN_K0_NO_INTERMEDIATE
	.set NETRA_GDN_K0_NO_INTERMEDIATE, 0
	.endif
	// Experimental high-batch launch geometry.  Consecutive logical waves own
	// adjacent V tiles of the same value head, so a multi-wave workgroup can
	// stage the shared normalized Q/K vectors once.  Double-buffered LDS keeps
	// one barrier per recurrent step without allowing the loader wave to
	// overwrite vectors that a lagging peer has not consumed.  One wave remains
	// the production/default geometry and preserves the exact existing ISA.
	.ifndef NETRA_GDN_WAVES_PER_WORKGROUP
	.set NETRA_GDN_WAVES_PER_WORKGROUP, 1
	.endif
	.ifndef NETRA_GDN_SHARE_QK
	.set NETRA_GDN_SHARE_QK, 1
	.endif
	// State-only K0 replay reuses this proven recurrence body but skips Q loads,
	// output reduction, and rollback snapshots.  Kernarg 5 becomes the output
	// SSM pool, kernarg 7 carries per-request accepted lengths, and kernarg 9
	// carries output-state indices.  The default remains the verification ABI.
	.ifndef NETRA_GDN_STATE_REPLAY
	.set NETRA_GDN_STATE_REPLAY, 0
	.endif
	.if (NETRA_GDN_STATE_REPLAY != 0) && (NETRA_GDN_STATE_REPLAY != 1)
	.error "NETRA_GDN_STATE_REPLAY must be 0 or 1"
	.endif
// Dual state replay stores an earlier tracking-prefix snapshot and the final
// accepted-prefix state from one live FP32 recurrence. It is valid only for
// the state-only replay specialization.
.ifndef NETRA_GDN_STATE_REPLAY_DUAL
.set NETRA_GDN_STATE_REPLAY_DUAL, 0
.endif
.if (NETRA_GDN_STATE_REPLAY_DUAL != 0) && (NETRA_GDN_STATE_REPLAY != 1)
.error "NETRA_GDN_STATE_REPLAY_DUAL requires NETRA_GDN_STATE_REPLAY=1"
.endif
	.if (NETRA_GDN_WAVES_PER_WORKGROUP != 1) && (NETRA_GDN_WAVES_PER_WORKGROUP != 2) && (NETRA_GDN_WAVES_PER_WORKGROUP != 4) && (NETRA_GDN_WAVES_PER_WORKGROUP != 8)
	.error "NETRA_GDN_WAVES_PER_WORKGROUP must be 1, 2, 4, or 8"
	.endif

	.macro DOT8_K_LOCAL s0, s1, s2, s3, s4, s5, s6, s7, a0
	.if NETRA_GDN_CORE_VARIANT == 0
	v_mul_f32_e32 v\a0, v\s0, v8
	v_fma_f32 v\a0, v\s1, v9, v\a0
	v_fma_f32 v\a0, v\s2, v10, v\a0
	v_fma_f32 v\a0, v\s3, v11, v\a0
	v_fma_f32 v\a0, v\s4, v12, v\a0
	v_fma_f32 v\a0, v\s5, v13, v\a0
	v_fma_f32 v\a0, v\s6, v14, v\a0
	v_fma_f32 v\a0, v\s7, v15, v\a0
	.elseif (NETRA_GDN_CORE_VARIANT == 1) || (NETRA_GDN_CORE_VARIANT == 3)
	// LLVM lowers Triton's per-thread reduction in reverse pair order:
	//   ((((((p6+p7)+p4)+p5)+p2)+p3)+p0)+p1.
	v_pk_mul_f32 v[76:77], v[\s6:\s7], v[14:15]
	v_add_f32_e32 v\a0, v76, v77
	v_pk_mul_f32 v[76:77], v[\s4:\s5], v[12:13]
	v_add_f32_e32 v\a0, v76, v\a0
	v_add_f32_e32 v\a0, v77, v\a0
	v_pk_mul_f32 v[76:77], v[\s2:\s3], v[10:11]
	v_add_f32_e32 v\a0, v76, v\a0
	v_add_f32_e32 v\a0, v77, v\a0
	v_pk_mul_f32 v[76:77], v[\s0:\s1], v[8:9]
	v_add_f32_e32 v\a0, v76, v\a0
	v_add_f32_e32 v\a0, v77, v\a0
	.elseif (NETRA_GDN_CORE_VARIANT == 2) || (NETRA_GDN_CORE_VARIANT >= 5 && NETRA_GDN_CORE_VARIANT <= 15)
	v_pk_mul_f32 v[76:77], v[\s0:\s1], v[8:9]
	v_add_f32_e32 v\a0, v76, v77
	v_pk_mul_f32 v[76:77], v[\s2:\s3], v[10:11]
	v_add_f32_e32 v\a0, v76, v\a0
	v_add_f32_e32 v\a0, v77, v\a0
	v_pk_mul_f32 v[76:77], v[\s4:\s5], v[12:13]
	v_add_f32_e32 v\a0, v76, v\a0
	v_add_f32_e32 v\a0, v77, v\a0
	v_pk_mul_f32 v[76:77], v[\s6:\s7], v[14:15]
	v_add_f32_e32 v\a0, v76, v\a0
	v_add_f32_e32 v\a0, v77, v\a0
	.elseif NETRA_GDN_CORE_VARIANT == 16
	// Accumulate even and odd products independently in packed FP32, then
	// combine the chains. This variant is retained for attribution; variant 17
	// interleaves four rows to hide their packed-VALU dependency latency.
	v_pk_mul_f32 v[76:77], v[\s0:\s1], v[8:9]
	v_pk_fma_f32 v[76:77], v[\s2:\s3], v[10:11], v[76:77]
	v_pk_fma_f32 v[76:77], v[\s4:\s5], v[12:13], v[76:77]
	v_pk_fma_f32 v[76:77], v[\s6:\s7], v[14:15], v[76:77]
	v_add_f32_e32 v\a0, v76, v77
	.elseif NETRA_GDN_CORE_VARIANT == 4
	v_pk_mul_f32 v[76:77], v[\s0:\s1], v[8:9]
	v_add_f32_e32 v\a0, v76, v77
	v_pk_mul_f32 v[76:77], v[\s2:\s3], v[10:11]
	v_add_f32_e32 v76, v76, v77
	v_add_f32_e32 v\a0, v\a0, v76
	v_pk_mul_f32 v[76:77], v[\s4:\s5], v[12:13]
	v_add_f32_e32 v78, v76, v77
	v_pk_mul_f32 v[76:77], v[\s6:\s7], v[14:15]
	v_add_f32_e32 v76, v76, v77
	v_add_f32_e32 v76, v78, v76
	v_add_f32_e32 v\a0, v\a0, v76
	.else
	.error "unsupported NETRA_GDN_CORE_VARIANT"
	.endif
	.endm

	.macro DOT8_K_LOCAL4_INTERLEAVED
	v_pk_mul_f32 v[64:65], v[32:33], v[8:9]
	v_pk_mul_f32 v[66:67], v[40:41], v[8:9]
	v_pk_mul_f32 v[68:69], v[48:49], v[8:9]
	v_pk_mul_f32 v[70:71], v[56:57], v[8:9]
	v_pk_fma_f32 v[64:65], v[34:35], v[10:11], v[64:65]
	v_pk_fma_f32 v[66:67], v[42:43], v[10:11], v[66:67]
	v_pk_fma_f32 v[68:69], v[50:51], v[10:11], v[68:69]
	v_pk_fma_f32 v[70:71], v[58:59], v[10:11], v[70:71]
	v_pk_fma_f32 v[64:65], v[36:37], v[12:13], v[64:65]
	v_pk_fma_f32 v[66:67], v[44:45], v[12:13], v[66:67]
	v_pk_fma_f32 v[68:69], v[52:53], v[12:13], v[68:69]
	v_pk_fma_f32 v[70:71], v[60:61], v[12:13], v[70:71]
	v_pk_fma_f32 v[64:65], v[38:39], v[14:15], v[64:65]
	v_pk_fma_f32 v[66:67], v[46:47], v[14:15], v[66:67]
	v_pk_fma_f32 v[68:69], v[54:55], v[14:15], v[68:69]
	v_pk_fma_f32 v[70:71], v[62:63], v[14:15], v[70:71]
	v_add_f32_e32 v64, v64, v65
	v_add_f32_e32 v66, v66, v67
	v_add_f32_e32 v68, v68, v69
	v_add_f32_e32 v70, v70, v71
	.endm

	.macro DOT8_Q_LOCAL4_INTERLEAVED
	v_pk_mul_f32 v[64:65], v[32:33], v[16:17]
	v_pk_mul_f32 v[66:67], v[40:41], v[16:17]
	v_pk_mul_f32 v[68:69], v[48:49], v[16:17]
	v_pk_mul_f32 v[70:71], v[56:57], v[16:17]
	v_pk_fma_f32 v[64:65], v[34:35], v[18:19], v[64:65]
	v_pk_fma_f32 v[66:67], v[42:43], v[18:19], v[66:67]
	v_pk_fma_f32 v[68:69], v[50:51], v[18:19], v[68:69]
	v_pk_fma_f32 v[70:71], v[58:59], v[18:19], v[70:71]
	v_pk_fma_f32 v[64:65], v[36:37], v[20:21], v[64:65]
	v_pk_fma_f32 v[66:67], v[44:45], v[20:21], v[66:67]
	v_pk_fma_f32 v[68:69], v[52:53], v[20:21], v[68:69]
	v_pk_fma_f32 v[70:71], v[60:61], v[20:21], v[70:71]
	v_pk_fma_f32 v[64:65], v[38:39], v[22:23], v[64:65]
	v_pk_fma_f32 v[66:67], v[46:47], v[22:23], v[66:67]
	v_pk_fma_f32 v[68:69], v[54:55], v[22:23], v[68:69]
	v_pk_fma_f32 v[70:71], v[62:63], v[22:23], v[70:71]
	v_add_f32_e32 v64, v64, v65
	v_add_f32_e32 v66, v66, v67
	v_add_f32_e32 v68, v68, v69
	v_add_f32_e32 v70, v70, v71
	.endm

	.macro DOT8_Q_LOCAL s0, s1, s2, s3, s4, s5, s6, s7, a0
	.if (NETRA_GDN_CORE_VARIANT == 0) || (NETRA_GDN_CORE_VARIANT == 5)
	v_mul_f32_e32 v\a0, v\s0, v16
	v_fma_f32 v\a0, v\s1, v17, v\a0
	v_fma_f32 v\a0, v\s2, v18, v\a0
	v_fma_f32 v\a0, v\s3, v19, v\a0
	v_fma_f32 v\a0, v\s4, v20, v\a0
	v_fma_f32 v\a0, v\s5, v21, v\a0
	v_fma_f32 v\a0, v\s6, v22, v\a0
	v_fma_f32 v\a0, v\s7, v23, v\a0
	.elseif (NETRA_GDN_CORE_VARIANT == 1) || (NETRA_GDN_CORE_VARIANT == 3) || (NETRA_GDN_CORE_VARIANT == 7)
	v_pk_mul_f32 v[76:77], v[\s6:\s7], v[22:23]
	v_add_f32_e32 v\a0, v76, v77
	v_pk_mul_f32 v[76:77], v[\s4:\s5], v[20:21]
	v_add_f32_e32 v\a0, v76, v\a0
	v_add_f32_e32 v\a0, v77, v\a0
	v_pk_mul_f32 v[76:77], v[\s2:\s3], v[18:19]
	v_add_f32_e32 v\a0, v76, v\a0
	v_add_f32_e32 v\a0, v77, v\a0
	v_pk_mul_f32 v[76:77], v[\s0:\s1], v[16:17]
	v_add_f32_e32 v\a0, v76, v\a0
	v_add_f32_e32 v\a0, v77, v\a0
	.elseif NETRA_GDN_CORE_VARIANT == 2
	v_pk_mul_f32 v[76:77], v[\s0:\s1], v[16:17]
	v_add_f32_e32 v\a0, v76, v77
	v_pk_mul_f32 v[76:77], v[\s2:\s3], v[18:19]
	v_add_f32_e32 v\a0, v76, v\a0
	v_add_f32_e32 v\a0, v77, v\a0
	v_pk_mul_f32 v[76:77], v[\s4:\s5], v[20:21]
	v_add_f32_e32 v\a0, v76, v\a0
	v_add_f32_e32 v\a0, v77, v\a0
	v_pk_mul_f32 v[76:77], v[\s6:\s7], v[22:23]
	v_add_f32_e32 v\a0, v76, v\a0
	v_add_f32_e32 v\a0, v77, v\a0
	.elseif (NETRA_GDN_CORE_VARIANT == 4) || (NETRA_GDN_CORE_VARIANT == 8)
	v_pk_mul_f32 v[76:77], v[\s0:\s1], v[16:17]
	v_add_f32_e32 v\a0, v76, v77
	v_pk_mul_f32 v[76:77], v[\s2:\s3], v[18:19]
	v_add_f32_e32 v76, v76, v77
	v_add_f32_e32 v\a0, v\a0, v76
	v_pk_mul_f32 v[76:77], v[\s4:\s5], v[20:21]
	v_add_f32_e32 v78, v76, v77
	v_pk_mul_f32 v[76:77], v[\s6:\s7], v[22:23]
	v_add_f32_e32 v76, v76, v77
	v_add_f32_e32 v76, v78, v76
	v_add_f32_e32 v\a0, v\a0, v76
	.elseif NETRA_GDN_CORE_VARIANT == 6
	v_mul_f32_e32 v\a0, v\s6, v22
	v_fma_f32 v\a0, v\s7, v23, v\a0
	v_fma_f32 v\a0, v\s4, v20, v\a0
	v_fma_f32 v\a0, v\s5, v21, v\a0
	v_fma_f32 v\a0, v\s2, v18, v\a0
	v_fma_f32 v\a0, v\s3, v19, v\a0
	v_fma_f32 v\a0, v\s0, v16, v\a0
	v_fma_f32 v\a0, v\s1, v17, v\a0
	.elseif NETRA_GDN_CORE_VARIANT == 9
	v_mul_f32_e32 v\a0, v\s1, v17
	v_fma_f32 v\a0, v\s0, v16, v\a0
	v_fma_f32 v\a0, v\s2, v18, v\a0
	v_fma_f32 v\a0, v\s3, v19, v\a0
	v_fma_f32 v\a0, v\s4, v20, v\a0
	v_fma_f32 v\a0, v\s5, v21, v\a0
	v_fma_f32 v\a0, v\s6, v22, v\a0
	v_fma_f32 v\a0, v\s7, v23, v\a0
	.elseif NETRA_GDN_CORE_VARIANT == 10
	v_mul_f32_e32 v\a0, v\s1, v17
	v_fma_f32 v\a0, v\s0, v16, v\a0
	v_fma_f32 v\a0, v\s3, v19, v\a0
	v_fma_f32 v\a0, v\s2, v18, v\a0
	v_fma_f32 v\a0, v\s5, v21, v\a0
	v_fma_f32 v\a0, v\s4, v20, v\a0
	v_fma_f32 v\a0, v\s7, v23, v\a0
	v_fma_f32 v\a0, v\s6, v22, v\a0
	.elseif NETRA_GDN_CORE_VARIANT == 11
	v_mul_f32_e32 v\a0, v\s7, v23
	v_fma_f32 v\a0, v\s6, v22, v\a0
	v_fma_f32 v\a0, v\s4, v20, v\a0
	v_fma_f32 v\a0, v\s5, v21, v\a0
	v_fma_f32 v\a0, v\s2, v18, v\a0
	v_fma_f32 v\a0, v\s3, v19, v\a0
	v_fma_f32 v\a0, v\s0, v16, v\a0
	v_fma_f32 v\a0, v\s1, v17, v\a0
	.elseif NETRA_GDN_CORE_VARIANT == 12
	v_mul_f32_e32 v\a0, v\s7, v23
	v_fma_f32 v\a0, v\s6, v22, v\a0
	v_fma_f32 v\a0, v\s5, v21, v\a0
	v_fma_f32 v\a0, v\s4, v20, v\a0
	v_fma_f32 v\a0, v\s3, v19, v\a0
	v_fma_f32 v\a0, v\s2, v18, v\a0
	v_fma_f32 v\a0, v\s1, v17, v\a0
	v_fma_f32 v\a0, v\s0, v16, v\a0
	.elseif (NETRA_GDN_CORE_VARIANT == 13) || (NETRA_GDN_CORE_VARIANT == 14) || (NETRA_GDN_CORE_VARIANT == 15)
	// Triton's packed pair gives alternating V groups distinct first terms.
	.if (\a0 == 64) || (\a0 == 68)
	v_mul_f32_e32 v\a0, v\s0, v16
	v_fma_f32 v\a0, v\s1, v17, v\a0
	.else
	v_mul_f32_e32 v\a0, v\s1, v17
	v_fma_f32 v\a0, v\s0, v16, v\a0
	.endif
	v_fma_f32 v\a0, v\s2, v18, v\a0
	v_fma_f32 v\a0, v\s3, v19, v\a0
	v_fma_f32 v\a0, v\s4, v20, v\a0
	v_fma_f32 v\a0, v\s5, v21, v\a0
	v_fma_f32 v\a0, v\s6, v22, v\a0
	v_fma_f32 v\a0, v\s7, v23, v\a0
	.elseif NETRA_GDN_CORE_VARIANT == 16
	v_pk_mul_f32 v[76:77], v[\s0:\s1], v[16:17]
	v_pk_fma_f32 v[76:77], v[\s2:\s3], v[18:19], v[76:77]
	v_pk_fma_f32 v[76:77], v[\s4:\s5], v[20:21], v[76:77]
	v_pk_fma_f32 v[76:77], v[\s6:\s7], v[22:23], v[76:77]
	v_add_f32_e32 v\a0, v76, v77
	.else
	.error "unsupported NETRA_GDN_CORE_VARIANT"
	.endif
	.endm

	// The default XOR tree is instruction-for-instruction equivalent to the
	// reduction tree recovered from Triton.  Variants 0 and 3 retain the old
	// one-direction scan so its numerical effect can be measured independently.
	.macro REDUCE4_BROADCAST a0, a1, a2, a3, tmp
	.if (NETRA_GDN_CORE_VARIANT == 0) || (NETRA_GDN_CORE_VARIANT == 3)
	v_add_f32_dpp v\a0, v\a0, v\a0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v\a1, v\a1, v\a1 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v\a2, v\a2, v\a2 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v\a3, v\a3, v\a3 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v\a0, v\a0, v\a0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v\a1, v\a1, v\a1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v\a2, v\a2, v\a2 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v\a3, v\a3, v\a3 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v\a0, v\a0, v\a0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v\a1, v\a1, v\a1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v\a2, v\a2, v\a2 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v\a3, v\a3, v\a3 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v\a0, v\a0, v\a0 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v\a1, v\a1, v\a1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v\a2, v\a2, v\a2 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_add_f32_dpp v\a3, v\a3, v\a3 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_lshrrev_b32_e32 v\tmp, 4, v0
	v_lshlrev_b32_e32 v\tmp, 6, v\tmp
	v_add_u32_e32 v\tmp, 60, v\tmp
	ds_bpermute_b32 v\a0, v\tmp, v\a0
	ds_bpermute_b32 v\a1, v\tmp, v\a1
	ds_bpermute_b32 v\a2, v\tmp, v\a2
	ds_bpermute_b32 v\a3, v\tmp, v\a3
	s_waitcnt lgkmcnt(0)
	.else
	// XOR 8 within each 16-lane row.
	v_mov_b32_e32 v65, v\a0
	v_mov_b32_e32 v67, v\a1
	v_mov_b32_e32 v69, v\a2
	v_mov_b32_e32 v71, v\a3
	v_mov_b32_dpp v65, v65 row_shr:8 row_mask:0xf bank_mask:0xc
	v_mov_b32_dpp v67, v67 row_shr:8 row_mask:0xf bank_mask:0xc
	v_mov_b32_dpp v69, v69 row_shr:8 row_mask:0xf bank_mask:0xc
	v_mov_b32_dpp v71, v71 row_shr:8 row_mask:0xf bank_mask:0xc
	v_mov_b32_dpp v65, v\a0 row_shl:8 row_mask:0xf bank_mask:0x3
	v_mov_b32_dpp v67, v\a1 row_shl:8 row_mask:0xf bank_mask:0x3
	v_mov_b32_dpp v69, v\a2 row_shl:8 row_mask:0xf bank_mask:0x3
	v_mov_b32_dpp v71, v\a3 row_shl:8 row_mask:0xf bank_mask:0x3
	v_add_f32_e32 v\a0, v\a0, v65
	v_add_f32_e32 v\a1, v\a1, v67
	v_add_f32_e32 v\a2, v\a2, v69
	v_add_f32_e32 v\a3, v\a3, v71

	// XOR 4.
	v_mov_b32_e32 v65, v\a0
	v_mov_b32_e32 v67, v\a1
	v_mov_b32_e32 v69, v\a2
	v_mov_b32_e32 v71, v\a3
	v_mov_b32_dpp v65, v65 row_shr:4 row_mask:0xf bank_mask:0xa
	v_mov_b32_dpp v67, v67 row_shr:4 row_mask:0xf bank_mask:0xa
	v_mov_b32_dpp v69, v69 row_shr:4 row_mask:0xf bank_mask:0xa
	v_mov_b32_dpp v71, v71 row_shr:4 row_mask:0xf bank_mask:0xa
	v_mov_b32_dpp v65, v\a0 row_shl:4 row_mask:0xf bank_mask:0x5
	v_mov_b32_dpp v67, v\a1 row_shl:4 row_mask:0xf bank_mask:0x5
	v_mov_b32_dpp v69, v\a2 row_shl:4 row_mask:0xf bank_mask:0x5
	v_mov_b32_dpp v71, v\a3 row_shl:4 row_mask:0xf bank_mask:0x5
	v_add_f32_e32 v\a0, v\a0, v65
	v_add_f32_e32 v\a1, v\a1, v67
	v_add_f32_e32 v\a2, v\a2, v69
	v_add_f32_e32 v\a3, v\a3, v71

	// XOR 2 and XOR 1.
	v_mov_b32_dpp v65, v\a0 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_mov_b32_dpp v67, v\a1 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_mov_b32_dpp v69, v\a2 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_mov_b32_dpp v71, v\a3 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_e32 v\a0, v\a0, v65
	v_add_f32_e32 v\a1, v\a1, v67
	v_add_f32_e32 v\a2, v\a2, v69
	v_add_f32_e32 v\a3, v\a3, v71
	v_mov_b32_dpp v65, v\a0 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_mov_b32_dpp v67, v\a1 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_mov_b32_dpp v69, v\a2 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_mov_b32_dpp v71, v\a3 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_e32 v\a0, v\a0, v65
	v_add_f32_e32 v\a1, v\a1, v67
	v_add_f32_e32 v\a2, v\a2, v69
	v_add_f32_e32 v\a3, v\a3, v71
	.endif
	.endm

	.macro UPDATE8 r0, r1, s0, s1, s2, s3, s4, s5, s6, s7
	v_mov_b32_e32 v64, v\r0
	v_mov_b32_e32 v65, v\r0
	v_pk_fma_f32 v[\s0:\s1], v[8:9], v[64:65], v[\s0:\s1]
	v_pk_fma_f32 v[\s2:\s3], v[10:11], v[64:65], v[\s2:\s3]
	v_pk_fma_f32 v[\s4:\s5], v[12:13], v[64:65], v[\s4:\s5]
	v_pk_fma_f32 v[\s6:\s7], v[14:15], v[64:65], v[\s6:\s7]
	.endm

	.macro ROUND_STATE_BF16_PAIR lo, hi, tmp
	v_cvt_pk_bf16_f32 v\tmp, v\lo, v\hi
	v_lshlrev_b32_e32 v\lo, 16, v\tmp
	v_and_b32_e32 v\hi, 0xffff0000, v\tmp
	.endm
.macro PACK_STORE_STATE_BF16 base_lo, base_hi
v_cvt_pk_bf16_f32 v8, v32, v33
v_cvt_pk_bf16_f32 v9, v34, v35
v_cvt_pk_bf16_f32 v10, v36, v37
v_cvt_pk_bf16_f32 v11, v38, v39
v_cvt_pk_bf16_f32 v12, v40, v41
v_cvt_pk_bf16_f32 v13, v42, v43
v_cvt_pk_bf16_f32 v14, v44, v45
v_cvt_pk_bf16_f32 v15, v46, v47
v_cvt_pk_bf16_f32 v16, v48, v49
v_cvt_pk_bf16_f32 v17, v50, v51
v_cvt_pk_bf16_f32 v18, v52, v53
v_cvt_pk_bf16_f32 v19, v54, v55
v_cvt_pk_bf16_f32 v20, v56, v57
v_cvt_pk_bf16_f32 v21, v58, v59
v_cvt_pk_bf16_f32 v22, v60, v61
v_cvt_pk_bf16_f32 v23, v62, v63
global_store_dwordx4 v7, v[8:11], s[\base_lo:\base_hi]
v_add_u32_e32 v5, 1024, v7
global_store_dwordx4 v5, v[12:15], s[\base_lo:\base_hi]
v_add_u32_e32 v5, 2048, v7
global_store_dwordx4 v5, v[16:19], s[\base_lo:\base_hi]
v_add_u32_e32 v5, 3072, v7
global_store_dwordx4 v5, v[20:23], s[\base_lo:\base_hi]
.endm


	.if NETRA_GDN_STATE_REPLAY_DUAL == 1
	.protected qwen36_gdn_state_replay_m12_dual_precomputed_bv16_gfx950
	.globl qwen36_gdn_state_replay_m12_dual_precomputed_bv16_gfx950
	.p2align 8
	.type qwen36_gdn_state_replay_m12_dual_precomputed_bv16_gfx950,@function
qwen36_gdn_state_replay_m12_dual_precomputed_bv16_gfx950:
	.else
	.protected qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950
	.globl qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950
	.p2align 8
	.type qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950,@function
qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950:
	.endif
	// Preserve workgroup X, then load the eight data pointers and two
	// device-side pool-index pointers.
	.if NETRA_GDN_WAVES_PER_WORKGROUP == 1
	s_mov_b32 s18, s2
	s_mov_b32 s30, 0
	.else
	// Convert the physical multi-wave workgroup into the original logical
	// one-wave index.  Normalize v0 back to a wave-local lane ID so the body
	// below remains instruction-for-instruction identical after mapping.
	v_readfirstlane_b32 s30, v0
	s_lshr_b32 s30, s30, 6
	v_and_b32_e32 v0, 63, v0
	.if NETRA_GDN_WAVES_PER_WORKGROUP == 2
	s_lshl_b32 s18, s2, 1
	.elseif NETRA_GDN_WAVES_PER_WORKGROUP == 4
	s_lshl_b32 s18, s2, 2
	.else
	s_lshl_b32 s18, s2, 3
	.endif
	s_add_u32 s18, s18, s30
	.endif
	s_load_dwordx2 s[2:3], s[0:1], 0
	s_load_dwordx2 s[4:5], s[0:1], 8
	s_load_dwordx2 s[6:7], s[0:1], 16
	s_load_dwordx2 s[8:9], s[0:1], 24
	s_load_dwordx2 s[10:11], s[0:1], 32
	s_load_dwordx2 s[12:13], s[0:1], 40
	s_load_dwordx2 s[14:15], s[0:1], 48
	s_load_dwordx2 s[16:17], s[0:1], 56
	s_load_dwordx2 s[24:25], s[0:1], 64
	s_load_dwordx2 s[26:27], s[0:1], 72
	s_load_dword s29, s[0:1], 80
	// The serving pool is sized independently of the verification batch.  Its
	// runtime capacity occupies the ABI padding at byte 84 so recycled request
	// and tracking slots above 64 remain distinct.
	s_load_dword s31, s[0:1], 84
	.if NETRA_GDN_STATE_REPLAY_DUAL == 1
	s_load_dwordx2 s[32:33], s[0:1], 88
	s_load_dwordx2 s[34:35], s[0:1], 96
	.endif
	s_waitcnt lgkmcnt(0)

	// Decode the sequence and local workgroup. Resolve each sequence's selected
	// recurrent-state pool slot (1 MiB) and M=12 intermediate slot (12 MiB).
	s_lshr_b32 s19, s18, 8
	s_and_b32 s18, s18, 255
	s_lshl_b32 s20, s19, 2
	s_load_dword s24, s[24:25], s20
	s_load_dword s26, s[26:27], s20
	.if NETRA_GDN_STATE_REPLAY == 1
	s_load_dword s28, s[16:17], s20
	.endif
	.if NETRA_GDN_STATE_REPLAY_DUAL == 1
	s_load_dword s36, s[32:33], s20
	s_load_dword s37, s[34:35], s20
	.endif
	s_waitcnt lgkmcnt(0)
	// Graph capture initializes only the live prefix of its dummy state-index
	// tensors. Clamp capture-time sentinels to the actual runtime pool capacity.
	s_sub_u32 s31, s31, 1
	s_max_i32 s24, s24, 0
	s_min_u32 s24, s24, s31
	s_max_i32 s26, s26, 0
	s_min_u32 s26, s26, s31
	.if NETRA_GDN_STATE_REPLAY_DUAL == 1
	s_max_i32 s37, s37, 0
	s_min_i32 s37, s37, s31
	.endif
	s_mov_b32 s25, 0
	s_lshl_b64 s[24:25], s[24:25], 20
	s_add_u32 s14, s14, s24
	s_addc_u32 s15, s15, s25
	s_mov_b32 s27, 0
	.if NETRA_GDN_STATE_REPLAY == 1
	// Destination state uses the ordinary one-MiB pool-slot stride.  Clamp the
	// accepted length for graph-capture dummy inputs and preserve it in s30
	// after the immutable wave index has been copied to s18 below.
	.if NETRA_GDN_STATE_REPLAY_DUAL == 1
	// Preserve the tracking length and resolve its independent destination
	// while s12:s13 still holds the common state-pool base.
	s_max_i32 s36, s36, 0
	s_min_i32 s36, s36, 12
	s_mov_b32 s38, s36
	s_mov_b32 s36, s37
	s_mov_b32 s37, 0
	s_lshl_b64 s[36:37], s[36:37], 20
	s_add_u32 s34, s12, s36
	s_addc_u32 s35, s13, s37
	.endif
	s_lshl_b64 s[26:27], s[26:27], 20
	s_add_u32 s12, s12, s26
	s_addc_u32 s13, s13, s27
	s_max_i32 s28, s28, 0
	s_min_i32 s28, s28, 12
	.else
	s_mul_i32 s26, s26, 12
	s_lshl_b64 s[26:27], s[26:27], 20
	s_add_u32 s16, s16, s26
	s_addc_u32 s17, s17, s27
	.endif
	s_lshl_b32 s29, s29, 1

	// Advance compact precompute buffers and the original V/output views to
	// this sequence. Each sequence contains exactly 12 contiguous token rows.
	s_mul_i32 s20, s19, 0x18000
	s_add_u32 s2, s2, s20
	s_addc_u32 s3, s3, 0
	s_add_u32 s4, s4, s20
	s_addc_u32 s5, s5, 0
	s_mul_i32 s20, s19, 1536
	s_add_u32 s8, s8, s20
	s_addc_u32 s9, s9, 0
	s_add_u32 s10, s10, s20
	s_addc_u32 s11, s11, 0
	// V is a view into the packed Q/K/V projection and therefore uses the
	// caller-provided token stride (8192 elements in the captured graph).
	s_mul_i32 s20, s19, 12
	s_mul_i32 s20, s20, s29
	s_add_u32 s6, s6, s20
	s_addc_u32 s7, s7, 0
	// Output is always compact [B*12,32,128] BF16. It must not inherit V's
	// packed-projection stride; doing so left a 96 KiB hole per sequence and
	// crossed the graph allocation for B>1. State replay instead addresses its
	// destination through the pool index above.
	.if NETRA_GDN_STATE_REPLAY == 0
	s_mul_i32 s20, s19, 0x18000
	s_add_u32 s12, s12, s20
	s_addc_u32 s13, s13, 0
	.endif

	// hv = workgroup_x / 8, tile = workgroup_x % 8, head = hv / 2.
	s_lshr_b32 s19, s18, 3
	s_and_b32 s20, s18, 7
	s_lshr_b32 s21, s19, 1
	// s30:s31 is reused by the output-lane EXEC mask below.  Preserve the
	// immutable wave index in s18 now that the logical workgroup ID has been
	// fully decoded.
	s_mov_b32 s18, s30
	.if NETRA_GDN_STATE_REPLAY == 1
	s_mov_b32 s30, s28
	s_cmp_eq_u32 s30, 0
	s_cbranch_scc1 .Lexit
	.endif

	// Lane mapping: row-within-four = lane / 16, K chunk = lane % 16.
	v_lshrrev_b32_e32 v1, 4, v0
	v_and_b32_e32 v2, 15, v0

	// Initial/intermediate group-0 byte offset:
	//   hv*32768 + tile*4096 + row*256 + k_chunk*16.
	s_lshl_b32 s22, s19, 15
	s_lshl_b32 s23, s20, 12
	s_add_u32 s22, s22, s23
	v_lshlrev_b32_e32 v3, 8, v1
	v_lshlrev_b32_e32 v4, 4, v2
	v_add_u32_e32 v3, v3, v4
	v_add_u32_e32 v7, s22, v3

	// Load all 32 BF16 state elements owned by the lane.
	global_load_dwordx4 v[64:67], v7, s[14:15]
	v_add_u32_e32 v4, 1024, v7
	global_load_dwordx4 v[68:71], v4, s[14:15]
	v_add_u32_e32 v4, 2048, v7
	global_load_dwordx4 v[72:75], v4, s[14:15]
	v_add_u32_e32 v4, 3072, v7
	global_load_dwordx4 v[76:79], v4, s[14:15]
	s_waitcnt vmcnt(0)

	// BF16 -> FP32, four V rows by eight K values.
	v_lshlrev_b32_e32 v32, 16, v64
	v_and_b32_e32 v33, 0xffff0000, v64
	v_lshlrev_b32_e32 v34, 16, v65
	v_and_b32_e32 v35, 0xffff0000, v65
	v_lshlrev_b32_e32 v36, 16, v66
	v_and_b32_e32 v37, 0xffff0000, v66
	v_lshlrev_b32_e32 v38, 16, v67
	v_and_b32_e32 v39, 0xffff0000, v67

	v_lshlrev_b32_e32 v40, 16, v68
	v_and_b32_e32 v41, 0xffff0000, v68
	v_lshlrev_b32_e32 v42, 16, v69
	v_and_b32_e32 v43, 0xffff0000, v69
	v_lshlrev_b32_e32 v44, 16, v70
	v_and_b32_e32 v45, 0xffff0000, v70
	v_lshlrev_b32_e32 v46, 16, v71
	v_and_b32_e32 v47, 0xffff0000, v71

	v_lshlrev_b32_e32 v48, 16, v72
	v_and_b32_e32 v49, 0xffff0000, v72
	v_lshlrev_b32_e32 v50, 16, v73
	v_and_b32_e32 v51, 0xffff0000, v73
	v_lshlrev_b32_e32 v52, 16, v74
	v_and_b32_e32 v53, 0xffff0000, v74
	v_lshlrev_b32_e32 v54, 16, v75
	v_and_b32_e32 v55, 0xffff0000, v75

	v_lshlrev_b32_e32 v56, 16, v76
	v_and_b32_e32 v57, 0xffff0000, v76
	v_lshlrev_b32_e32 v58, 16, v77
	v_and_b32_e32 v59, 0xffff0000, v77
	v_lshlrev_b32_e32 v60, 16, v78
	v_and_b32_e32 v61, 0xffff0000, v78
	v_lshlrev_b32_e32 v62, 16, v79
	v_and_b32_e32 v63, 0xffff0000, v79

	// Optional assembler-time mapping probe.  A build with
	// -Wa,-defsym,NETRA_DEBUG_INITIAL_COPY=1 copies the decoded initial state
	// into intermediate step zero and exits before any recurrent arithmetic.
	.ifdef NETRA_DEBUG_INITIAL_COPY
	v_cvt_pk_bf16_f32 v8, v32, v33
	v_cvt_pk_bf16_f32 v9, v34, v35
	v_cvt_pk_bf16_f32 v10, v36, v37
	v_cvt_pk_bf16_f32 v11, v38, v39
	v_cvt_pk_bf16_f32 v12, v40, v41
	v_cvt_pk_bf16_f32 v13, v42, v43
	v_cvt_pk_bf16_f32 v14, v44, v45
	v_cvt_pk_bf16_f32 v15, v46, v47
	v_cvt_pk_bf16_f32 v16, v48, v49
	v_cvt_pk_bf16_f32 v17, v50, v51
	v_cvt_pk_bf16_f32 v18, v52, v53
	v_cvt_pk_bf16_f32 v19, v54, v55
	v_cvt_pk_bf16_f32 v20, v56, v57
	v_cvt_pk_bf16_f32 v21, v58, v59
	v_cvt_pk_bf16_f32 v22, v60, v61
	v_cvt_pk_bf16_f32 v23, v62, v63
	global_store_dwordx4 v7, v[8:11], s[16:17]
	v_add_u32_e32 v5, 1024, v7
	global_store_dwordx4 v5, v[12:15], s[16:17]
	v_add_u32_e32 v5, 2048, v7
	global_store_dwordx4 v5, v[16:19], s[16:17]
	v_add_u32_e32 v5, 3072, v7
	global_store_dwordx4 v5, v[20:23], s[16:17]
	s_waitcnt vmcnt(0)
	s_endpgm
	.endif

	// Per-step scalar/vector byte bases.
	s_lshl_b32 s22, s21, 9              // q/k FP32 head base
	s_lshl_b32 s23, s19, 2              // decay/beta FP32 index
	s_lshl_b32 s26, s19, 8              // v/output hv base
	s_lshl_b32 s27, s20, 5              // v/output tile base
	s_add_u32 s26, s26, s27
	v_lshlrev_b32_e32 v4, 1, v1         // row BF16 byte offset
	v_add_u32_e32 v4, s26, v4
	v_mov_b32_e32 v75, v4                // independent strided V input offset
	s_mov_b32 s28, 0

.Ltime_loop:
	// Stage two normalized K and Q FP32 values per lane to LDS.
	.if (NETRA_GDN_WAVES_PER_WORKGROUP == 1) || (NETRA_GDN_SHARE_QK == 0)
	v_lshlrev_b32_e32 v5, 3, v0
	v_add_u32_e32 v6, s22, v5
	global_load_dwordx2 v[64:65], v6, s[4:5]
	.if NETRA_GDN_STATE_REPLAY == 0
	global_load_dwordx2 v[66:67], v6, s[2:3]
	.endif
	.else
	// Only wave zero fetches Q/K.  Every peer maps to another V tile of the
	// same HV and therefore consumes the same vectors.
	s_cmp_eq_u32 s18, 0
	s_cbranch_scc0 .Lskip_shared_qk_global
	v_lshlrev_b32_e32 v5, 3, v0
	v_add_u32_e32 v6, s22, v5
	global_load_dwordx2 v[64:65], v6, s[4:5]
	.if NETRA_GDN_STATE_REPLAY == 0
	global_load_dwordx2 v[66:67], v6, s[2:3]
	.endif
.Lskip_shared_qk_global:
	.endif

	// Load the four BF16 V values and the two uniform FP32 gates.
	global_load_ushort v24, v75, s[6:7]
	v_add_u32_e32 v5, 8, v75
	global_load_ushort v25, v5, s[6:7]
	v_add_u32_e32 v5, 16, v75
	global_load_ushort v26, v5, s[6:7]
	v_add_u32_e32 v5, 24, v75
	global_load_ushort v27, v5, s[6:7]
	s_load_dword s24, s[8:9], s23
	s_load_dword s25, s[10:11], s23
	.if (NETRA_GDN_WAVES_PER_WORKGROUP == 1) || (NETRA_GDN_SHARE_QK == 0)
	s_waitcnt vmcnt(4)
	v_lshlrev_b32_e32 v5, 3, v0
	ds_write_b64 v5, v[64:65]
	.if NETRA_GDN_STATE_REPLAY == 0
	ds_write_b64 v5, v[66:67] offset:512
	.endif
	s_waitcnt vmcnt(0) lgkmcnt(0)

	// Read the lane's eight K and Q values.
	v_lshlrev_b32_e32 v5, 5, v2
	ds_read_b128 v[8:11], v5
	ds_read_b128 v[12:15], v5 offset:16
	.if NETRA_GDN_STATE_REPLAY == 0
	ds_read_b128 v[16:19], v5 offset:512
	ds_read_b128 v[20:23], v5 offset:528
	.endif
	.else
	// Alternate 1 KiB Q/K banks.  Reaching the next bank's barrier proves
	// every peer has consumed the prior bank, so an end-of-step barrier is not
	// needed.
	s_and_b32 s27, s28, 1
	s_lshl_b32 s27, s27, 10
	s_cmp_eq_u32 s18, 0
	s_cbranch_scc0 .Lskip_shared_qk_stage
	s_waitcnt vmcnt(4)
	v_lshlrev_b32_e32 v5, 3, v0
	v_add_u32_e32 v5, s27, v5
	ds_write_b64 v5, v[64:65]
	.if NETRA_GDN_STATE_REPLAY == 0
	ds_write_b64 v5, v[66:67] offset:512
	.endif
.Lskip_shared_qk_stage:
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier

	// Read the lane's eight K and Q values from the selected shared bank.
	v_lshlrev_b32_e32 v5, 5, v2
	v_add_u32_e32 v5, s27, v5
	ds_read_b128 v[8:11], v5
	ds_read_b128 v[12:15], v5 offset:16
	.if NETRA_GDN_STATE_REPLAY == 0
	ds_read_b128 v[16:19], v5 offset:512
	ds_read_b128 v[20:23], v5 offset:528
	.endif
	.endif
	s_waitcnt lgkmcnt(0)

	// Optional cooperative Q/K mapping probe.  Even HV workgroups on tile zero
	// write one copy per head into the start of the intermediate buffer:
	// K [16,16,128] followed by Q [16,16,128], both FP32.
	.ifdef NETRA_DEBUG_QK
	s_cmp_eq_u32 s20, 0
	s_cbranch_scc0 .Ladvance
	s_and_b32 s27, s19, 1
	s_cmp_eq_u32 s27, 0
	s_cbranch_scc0 .Ladvance
	v_cmp_gt_u32_e32 vcc, 16, v0
	s_and_saveexec_b64 s[30:31], vcc
	v_lshlrev_b32_e32 v64, 5, v2
	v_add_u32_e32 v64, s22, v64
	global_store_dwordx4 v64, v[8:11], s[16:17]
	v_add_u32_e32 v65, 16, v64
	global_store_dwordx4 v65, v[12:15], s[16:17]
	v_add_u32_e32 v64, 0x20000, v64
	global_store_dwordx4 v64, v[16:19], s[16:17]
	v_add_u32_e32 v65, 16, v64
	global_store_dwordx4 v65, v[20:23], s[16:17]
	s_or_b64 exec, exec, s[30:31]
	s_branch .Ladvance
	.endif

	// Optional scalar-address probe.  The first lane of tile zero writes the
	// loaded decay/beta pair as FP32 into the beginning of the output buffer.
	.ifdef NETRA_DEBUG_GATES
	s_cmp_eq_u32 s20, 0
	s_cbranch_scc0 .Ladvance
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_and_saveexec_b64 s[30:31], vcc
	v_mov_b32_e32 v64, s23
	v_lshlrev_b32_e32 v64, 1, v64
	v_mov_b32_e32 v65, s24
	global_store_dword v64, v65, s[12:13]
	v_add_u32_e32 v64, 4, v64
	v_mov_b32_e32 v65, s25
	global_store_dword v64, v65, s[12:13]
	s_or_b64 exec, exec, s[30:31]
	s_branch .Ladvance
	.endif

	// Optional V-address probe.  The K-chunk-zero lanes cover all 16 V rows
	// of every tile and write the loaded BF16 values in their logical layout.
	.ifdef NETRA_DEBUG_V
	v_cmp_eq_u32_e32 vcc, 0, v2
	s_and_saveexec_b64 s[30:31], vcc
	global_store_short v4, v24, s[16:17]
	v_add_u32_e32 v64, 8, v4
	global_store_short v64, v25, s[16:17]
	v_add_u32_e32 v64, 16, v4
	global_store_short v64, v26, s[16:17]
	v_add_u32_e32 v64, 24, v4
	global_store_short v64, v27, s[16:17]
	s_or_b64 exec, exec, s[30:31]
	s_branch .Ladvance
	.endif

	// BF16 V -> FP32.
	v_lshlrev_b32_e32 v24, 16, v24
	v_lshlrev_b32_e32 v25, 16, v25
	v_lshlrev_b32_e32 v26, 16, v26
	v_lshlrev_b32_e32 v27, 16, v27

	// h *= decay, using packed FP32 operations.
	v_mov_b32_e32 v64, s24
	v_mov_b32_e32 v65, s24
	v_pk_mul_f32 v[32:33], v[64:65], v[32:33]
	v_pk_mul_f32 v[34:35], v[64:65], v[34:35]
	v_pk_mul_f32 v[36:37], v[64:65], v[36:37]
	v_pk_mul_f32 v[38:39], v[64:65], v[38:39]
	v_pk_mul_f32 v[40:41], v[64:65], v[40:41]
	v_pk_mul_f32 v[42:43], v[64:65], v[42:43]
	v_pk_mul_f32 v[44:45], v[64:65], v[44:45]
	v_pk_mul_f32 v[46:47], v[64:65], v[46:47]
	v_pk_mul_f32 v[48:49], v[64:65], v[48:49]
	v_pk_mul_f32 v[50:51], v[64:65], v[50:51]
	v_pk_mul_f32 v[52:53], v[64:65], v[52:53]
	v_pk_mul_f32 v[54:55], v[64:65], v[54:55]
	v_pk_mul_f32 v[56:57], v[64:65], v[56:57]
	v_pk_mul_f32 v[58:59], v[64:65], v[58:59]
	v_pk_mul_f32 v[60:61], v[64:65], v[60:61]
	v_pk_mul_f32 v[62:63], v[64:65], v[62:63]

	.ifdef NETRA_DEBUG_DECAY_ONLY
	s_branch .Lstore_intermediate
	.endif

	// v -= sum_k(h*k); v *= beta.
	.if NETRA_GDN_CORE_VARIANT == 17
	DOT8_K_LOCAL4_INTERLEAVED
	.else
	DOT8_K_LOCAL 32,33,34,35,36,37,38,39,64
	DOT8_K_LOCAL 40,41,42,43,44,45,46,47,66
	DOT8_K_LOCAL 48,49,50,51,52,53,54,55,68
	DOT8_K_LOCAL 56,57,58,59,60,61,62,63,70
	.endif
	REDUCE4_BROADCAST 64,66,68,70,65
	v_sub_f32_e32 v24, v24, v64
	v_sub_f32_e32 v25, v25, v66
	v_sub_f32_e32 v26, v26, v68
	v_sub_f32_e32 v27, v27, v70
	v_mul_f32_e32 v24, s25, v24
	v_mul_f32_e32 v25, s25, v25
	v_mul_f32_e32 v26, s25, v26
	v_mul_f32_e32 v27, s25, v27

	// Optional delta-rule reduction probe.  K-chunk-zero lanes write the four
	// FP32 residual values in logical [T,HV,V] order.
	.ifdef NETRA_DEBUG_RESIDUAL
	v_cmp_eq_u32_e32 vcc, 0, v2
	s_and_saveexec_b64 s[30:31], vcc
	v_lshlrev_b32_e32 v64, 1, v4
	global_store_dword v64, v24, s[16:17]
	v_add_u32_e32 v64, 16, v64
	global_store_dword v64, v25, s[16:17]
	v_add_u32_e32 v64, 16, v64
	global_store_dword v64, v26, s[16:17]
	v_add_u32_e32 v64, 16, v64
	global_store_dword v64, v27, s[16:17]
	s_or_b64 exec, exec, s[30:31]
	s_branch .Ladvance
	.endif

	// Lane-resolved reduction probe: [T,HV,V,16 K-chunks] FP32.
	.ifdef NETRA_DEBUG_RESIDUAL_LANES
	v_lshlrev_b32_e32 v64, 5, v4
	v_lshlrev_b32_e32 v65, 2, v2
	v_add_u32_e32 v64, v64, v65
	global_store_dword v64, v24, s[16:17]
	v_add_u32_e32 v64, 256, v64
	global_store_dword v64, v25, s[16:17]
	v_add_u32_e32 v64, 256, v64
	global_store_dword v64, v26, s[16:17]
	v_add_u32_e32 v64, 256, v64
	global_store_dword v64, v27, s[16:17]
	s_branch .Ladvance
	.endif

	// h += k*v.
	UPDATE8 24,65,32,33,34,35,36,37,38,39
	UPDATE8 25,65,40,41,42,43,44,45,46,47
	UPDATE8 26,65,48,49,50,51,52,53,54,55
	UPDATE8 27,65,56,57,58,59,60,61,62,63

	// Sequential decode exposes BF16 recurrent state to the next token and
	// computes its output from that stored precision.  Variant 14 preserves
	// this boundary while retaining the M=16 fused launch.
	.if NETRA_GDN_CORE_VARIANT == 14
	ROUND_STATE_BF16_PAIR 32,33,76
	ROUND_STATE_BF16_PAIR 34,35,76
	ROUND_STATE_BF16_PAIR 36,37,76
	ROUND_STATE_BF16_PAIR 38,39,76
	ROUND_STATE_BF16_PAIR 40,41,76
	ROUND_STATE_BF16_PAIR 42,43,76
	ROUND_STATE_BF16_PAIR 44,45,76
	ROUND_STATE_BF16_PAIR 46,47,76
	ROUND_STATE_BF16_PAIR 48,49,76
	ROUND_STATE_BF16_PAIR 50,51,76
	ROUND_STATE_BF16_PAIR 52,53,76
	ROUND_STATE_BF16_PAIR 54,55,76
	ROUND_STATE_BF16_PAIR 56,57,76
	ROUND_STATE_BF16_PAIR 58,59,76
	ROUND_STATE_BF16_PAIR 60,61,76
	ROUND_STATE_BF16_PAIR 62,63,76
	.endif

	.if NETRA_GDN_STATE_REPLAY == 0
	// o = sum_k(h*q).
	.if NETRA_GDN_CORE_VARIANT == 17
	DOT8_Q_LOCAL4_INTERLEAVED
	.else
	DOT8_Q_LOCAL 32,33,34,35,36,37,38,39,64
	DOT8_Q_LOCAL 40,41,42,43,44,45,46,47,66
	DOT8_Q_LOCAL 48,49,50,51,52,53,54,55,68
	DOT8_Q_LOCAL 56,57,58,59,60,61,62,63,70
	.endif
	REDUCE4_BROADCAST 64,66,68,70,65

	// One lane per 16-lane row stores the four BF16 outputs.
	v_and_b32_e32 v74, 15, v0
	v_cmp_eq_u32_e32 vcc, 0, v74
	s_and_saveexec_b64 s[30:31], vcc
	v_cvt_pk_bf16_f32 v72, v64, v66
	v_cvt_pk_bf16_f32 v73, v68, v70
	global_store_short v4, v72, s[12:13]
	v_lshrrev_b32_e32 v74, 16, v72
	v_add_u32_e32 v5, 8, v4
	global_store_short v5, v74, s[12:13]
	v_add_u32_e32 v5, 16, v4
	global_store_short v5, v73, s[12:13]
	v_lshrrev_b32_e32 v74, 16, v73
	v_add_u32_e32 v5, 24, v4
	global_store_short v5, v74, s[12:13]
	s_or_b64 exec, exec, s[30:31]
	.endif

	// Packed decode writes BF16 state after producing the current output.  The
	// next token therefore reloads BF16-rounded state, not the live FP32 value.
	.if NETRA_GDN_CORE_VARIANT == 15
	ROUND_STATE_BF16_PAIR 32,33,76
	ROUND_STATE_BF16_PAIR 34,35,76
	ROUND_STATE_BF16_PAIR 36,37,76
	ROUND_STATE_BF16_PAIR 38,39,76
	ROUND_STATE_BF16_PAIR 40,41,76
	ROUND_STATE_BF16_PAIR 42,43,76
	ROUND_STATE_BF16_PAIR 44,45,76
	ROUND_STATE_BF16_PAIR 46,47,76
	ROUND_STATE_BF16_PAIR 48,49,76
	ROUND_STATE_BF16_PAIR 50,51,76
	ROUND_STATE_BF16_PAIR 52,53,76
	ROUND_STATE_BF16_PAIR 54,55,76
	ROUND_STATE_BF16_PAIR 56,57,76
	ROUND_STATE_BF16_PAIR 58,59,76
	ROUND_STATE_BF16_PAIR 60,61,76
	ROUND_STATE_BF16_PAIR 62,63,76
	.endif

	// Cache the complete BF16 intermediate state for this step.
.Lstore_intermediate:
	.if (NETRA_GDN_K0_NO_INTERMEDIATE == 0) && (NETRA_GDN_STATE_REPLAY == 0)
	v_cvt_pk_bf16_f32 v8, v32, v33
	v_cvt_pk_bf16_f32 v9, v34, v35
	v_cvt_pk_bf16_f32 v10, v36, v37
	v_cvt_pk_bf16_f32 v11, v38, v39
	v_cvt_pk_bf16_f32 v12, v40, v41
	v_cvt_pk_bf16_f32 v13, v42, v43
	v_cvt_pk_bf16_f32 v14, v44, v45
	v_cvt_pk_bf16_f32 v15, v46, v47
	v_cvt_pk_bf16_f32 v16, v48, v49
	v_cvt_pk_bf16_f32 v17, v50, v51
	v_cvt_pk_bf16_f32 v18, v52, v53
	v_cvt_pk_bf16_f32 v19, v54, v55
	v_cvt_pk_bf16_f32 v20, v56, v57
	v_cvt_pk_bf16_f32 v21, v58, v59
	v_cvt_pk_bf16_f32 v22, v60, v61
	v_cvt_pk_bf16_f32 v23, v62, v63
	global_store_dwordx4 v7, v[8:11], s[16:17]
	v_add_u32_e32 v5, 1024, v7
	global_store_dwordx4 v5, v[12:15], s[16:17]
	v_add_u32_e32 v5, 2048, v7
	global_store_dwordx4 v5, v[16:19], s[16:17]
	v_add_u32_e32 v5, 3072, v7
	global_store_dwordx4 v5, v[20:23], s[16:17]
	.endif

	// Advance to the next verification token.
.Ladvance:
	s_add_u32 s28, s28, 1
	.if NETRA_GDN_STATE_REPLAY_DUAL == 1
	// Snapshot the earlier prefix without rounding the live FP32 recurrence.
	s_cmp_eq_u32 s28, s38
	s_cbranch_scc0 .Lskip_tracking_state_store
	PACK_STORE_STATE_BF16 34, 35
.Lskip_tracking_state_store:
	.endif
	s_add_u32 s22, s22, 8192
	s_add_u32 s23, s23, 128
	v_add_u32_e32 v4, 8192, v4
	v_add_u32_e32 v75, s29, v75
	.if (NETRA_GDN_K0_NO_INTERMEDIATE == 0) && (NETRA_GDN_STATE_REPLAY == 0)
	v_add_u32_e32 v7, 0x100000, v7
	.endif
	.if NETRA_GDN_STATE_REPLAY == 1
	s_cmp_lt_u32 s28, s30
	.else
	s_cmp_lt_u32 s28, 12
	.endif
	s_cbranch_scc1 .Ltime_loop

	.if NETRA_GDN_STATE_REPLAY == 1
	// State-only replay exposes only the final BF16 state, matching Triton's
	// live FP32 recurrence followed by one terminal conversion.
	PACK_STORE_STATE_BF16 12, 13
	.endif

.Lexit:
	s_waitcnt vmcnt(0)
	s_endpgm

	.section .rodata,"a",@progbits
	.p2align 6, 0
	.if NETRA_GDN_STATE_REPLAY_DUAL == 1
	.amdhsa_kernel qwen36_gdn_state_replay_m12_dual_precomputed_bv16_gfx950
		.amdhsa_group_segment_fixed_size 2048
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 104
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 80
		.amdhsa_accum_offset 80
		.amdhsa_next_free_sgpr 39
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.else
	.amdhsa_kernel qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950
		.amdhsa_group_segment_fixed_size 2048
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 88
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 80
		.amdhsa_accum_offset 80
		.amdhsa_next_free_sgpr 32
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_tg_split 0
	.end_amdhsa_kernel
	.endif
	.text
.Lfunc_end0:
	.if NETRA_GDN_STATE_REPLAY_DUAL == 1
	.size qwen36_gdn_state_replay_m12_dual_precomputed_bv16_gfx950, .Lfunc_end0-qwen36_gdn_state_replay_m12_dual_precomputed_bv16_gfx950
	.else
	.size qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950, .Lfunc_end0-qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950
	.endif

	.if NETRA_GDN_STATE_REPLAY_DUAL == 1
	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: q_normalized_f32, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: k_normalized_f32, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: v_bf16, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: decay_f32, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: beta_f32, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: output_state_pool_bf16, .offset: 40, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: initial_state_pool_bf16, .offset: 48, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: main_lengths_i32, .offset: 56, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: initial_state_indices_i32, .offset: 64, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: main_output_state_indices_i32, .offset: 72, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: stride_v, .offset: 80, .size: 4,
          .value_kind: by_value }
      - { .name: state_capacity, .offset: 84, .size: 4,
          .value_kind: by_value }
      - { .name: tracking_lengths_i32, .offset: 88, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: tracking_output_state_indices_i32, .offset: 96, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
    .group_segment_fixed_size: 2048
    .kernarg_segment_align: 8
    .kernarg_segment_size: 104
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 512
    .name: qwen36_gdn_state_replay_m12_dual_precomputed_bv16_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 40
    .sgpr_spill_count: 0
    .symbol: qwen36_gdn_state_replay_m12_dual_precomputed_bv16_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 80
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
	.else
	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - { .name: q_normalized_f32, .offset: 0, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: k_normalized_f32, .offset: 8, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: v_bf16, .offset: 16, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: decay_f32, .offset: 24, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: beta_f32, .offset: 32, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: output_bf16, .offset: 40, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: initial_ssm_bf16, .offset: 48, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: intermediate_bf16, .offset: 56, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: write_only }
      - { .name: initial_state_indices_i32, .offset: 64, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: intermediate_state_indices_i32, .offset: 72, .size: 8,
          .value_kind: global_buffer, .address_space: global,
          .actual_access: read_only }
      - { .name: stride_v, .offset: 80, .size: 4,
          .value_kind: by_value }
      - { .name: state_capacity, .offset: 84, .size: 4,
          .value_kind: by_value }
    .group_segment_fixed_size: 2048
    .kernarg_segment_align: 8
    .kernarg_segment_size: 88
    .language: OpenCL C
    .language_version: [2, 0]
    .max_flat_workgroup_size: 512
    .name: qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950
    .private_segment_fixed_size: 0
    .sgpr_count: 40
    .sgpr_spill_count: 0
    .symbol: qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count: 80
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version: [1, 2]
...
	.end_amdgpu_metadata
	.endif
