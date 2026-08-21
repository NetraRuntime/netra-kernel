// Netra model-independent fixed-contract tactic template.
	.include "kernels/gfx950/templates/common/primitives.inc"
	.include "kernels/gfx950/templates/attention/common/kernel_descriptor.inc"
	.include "kernels/gfx950/templates/attention/verify/gqa_fp8kv_metadata.inc"
	.include "kernels/gfx950/templates/attention/verify/gqa4/entry_addressing.inc"
	.include "kernels/gfx950/templates/attention/verify/gqa4/prefix_fp8kv_attention.inc"
	.include "kernels/gfx950/templates/attention/verify/gqa4/causal_tail_output.inc"
	NETRA_GFX950_MODULE_HEADER 5
	.macro NETRA_ATTENTION_GQA4_FP8KV symbol
	NETRA_ATTENTION_GQA4_ENTRY_ADDRESSING \symbol
	NETRA_ATTENTION_GQA4_PREFIX_FP8KV_ATTENTION \symbol
	NETRA_ATTENTION_GQA4_CAUSAL_TAIL_OUTPUT \symbol
	NETRA_ATTENTION_KERNEL_DESCRIPTOR \symbol, 0, 96, 1, 0, 257, 96, 136
	.text
.Lfunc_end0:
	.size	\symbol, .Lfunc_end0-\symbol
                                        ; -- End function
	.set \symbol\().num_vgpr, 136
	.set \symbol\().num_agpr, 0
	.set \symbol\().numbered_sgpr, 76
	.set \symbol\().num_named_barrier, 0
	.set \symbol\().private_seg_size, 0
	.set \symbol\().uses_vcc, 1
	.set \symbol\().uses_flat_scratch, 0
	.set \symbol\().has_dyn_sized_stack, 0
	.set \symbol\().has_recursion, 0
	.set \symbol\().has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 9780
; TotalNumSgprs: 82
; NumVgprs: 136
; NumAgprs: 0
; TotalNumVgprs: 136
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 12
; VGPRBlocks: 32
; NumSGPRsForWavesPerEU: 102
; NumVGPRsForWavesPerEU: 257
; AccumOffset: 136
; Occupancy: 1
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 33
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.set amdgpu.max_num_named_barrier, 0
	.text
	.section	".note.GNU-stack","",@progbits
	NETRA_ATTENTION_GQA4_GQA6_METADATA \symbol, 0, 256, 136, 82, 0
	.endm
