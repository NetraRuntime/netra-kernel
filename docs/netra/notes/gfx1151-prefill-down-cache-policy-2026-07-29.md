# gfx1151 MXFP4 prefill-down cache-policy experiment (rejected)

Status: **not enabled in production**. All runtime values are measured on gfx1151 and no values are estimated. MXFP4 weights remain MXFP4.

The fresh exact 32,768-token trace measured `mxfp4_prefill_down_wmma_gfx1151` at 160 calls and 1,201.098 ms total. Its exact per-dispatch server shape is approximately 1,276 groups of 64 rows, N=2,048, K=512. Groups are sorted by expert, creating repeated use of a 512 KiB packed-weight block and 32 KiB scale block for adjacent groups.

`scripts/rocm/mxfp4_prefill_down_wmma_glc_gfx1151.s` is a raw AMDGCN negative variant that adds gfx11 `glc` only to immutable packed-weight and scale loads. Activation and output memory policies are unchanged.

A paired native harness used G=1,280, 128 experts, ten adjacent groups per expert, exact M64/N2048/K512 geometry, identical stable device pointers, and nine HIP-event samples per kernel.

| gfx1151 raw ASM | median | samples range | output |
|---|---:|---:|---|
| default load policy | 7.340948 ms | 7.311292–7.373489 ms | reference |
| immutable-weight `glc` | 7.401101 ms | 7.371404–7.438932 ms | byte-identical |

The variant is 0.812% slower (`0.99187x`), so it is rejected before SGLang integration or rocprofv3 promotion. The result indicates the default cache hierarchy already handles adjacent immutable expert reuse better than bypassing the near cache for this schedule.

Reproducible artifacts are `scripts/rocm/prefill_down_cache_policy_harness.hip`, the retained raw variant, and `results/kernels/gfx1151/down-glc-paired.txt`. Before/after disassemblies are under `docs/netra/notes/disassembly/prefill-down-glc-gfx1151/`.
