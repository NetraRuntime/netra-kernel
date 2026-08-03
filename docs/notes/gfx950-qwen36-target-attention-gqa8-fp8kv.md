# gfx950 Qwen target GQA8 attention with native FP8 KV

The production source is
`kernels/gfx950/attention/verify/qwen36_extend_attention_m16_gqa8_fp8kv_gfx950.s`.
It is raw wave64 AMDGCN targeting gfx950 explicitly. The HIP bridge only loads
the module and launches it; no compute is hidden in HIP C++.

The measured dFlash verification ABI is BF16 Q/K/V extension and output,
native E4M3 prefix K/V, 16 query heads, two KV heads, D=256, block 12, and
batch at most 64. Piecewise/full graph execution uses int64 `qo_indptr`, int32
`kv_indptr`, and int64 `kv_indices`.

One 512-thread workgroup covers four query heads sharing a KV head. The launch
grid has two KV heads and two query-head groups per sequence. This reduces
repeated prefix K/V traffic by four relative to the deployed per-query-head
Triton layout while preserving its N64 online-softmax order. The code object
uses 32 KiB dynamic LDS, 148 VGPRs, 80 SGPRs, no AGPRs, and no scratch.

On the exact real-checkpoint M=756 capture, raw replay was deterministic with
28/3,096,576 BF16 mismatches, maximum absolute error 0.0009765625, cosine 1.0,
and no NaN/Inf. HIP-event median was 84.081 us versus 185.722 us for the
deployed target Triton kernel. The SGLang full-plus-piecewise serving A/B/A
measured an 8.406% mean output-throughput increase over the fresh control and
passed stable-token and full GSM8K gates.

The build emits the HSACO, gfx950 disassembly, code-object metadata, bridge,
and SHA-256 manifest under
`build/gfx950-qwen36-extend-attention-gqa8-fp8kv/`.

Rejected variants retained in the benchmark record include two-head grouping,
the initial shared-scale int64 prologue, and a broad M<=16 dispatch predicate
that incorrectly selected extension-only piecewise prefill.

## HiP-attention sparse-decode evaluation (2026-08-03)

The `qwen3_64k` HiP preset was evaluated on the same single-gfx950 Qwen3.6
FP8 E4M3 plus dFlash workload, with dense prefill and sparse delta decode. A
scoped 32,768-input/128-output Torch trace attributed 3,294.063 ms (58.52%) of
5,628.644 ms total GPU time to 516 `_attn_fwd` calls. The dominant decode
shape used grid `(16,1,1)`, 512 threads, and averaged 4,073.123 us across 438
calls.

The deployed Triton code objects use wave64 but allocate 256 VGPRs and 106
SGPRs, 90-131 KiB dynamic LDS, and 1,056-2,820 bytes of scratch per workitem.
The largest variant contains 1,929 scratch loads and 1,486 scratch stores. A
forced `BLOCK_M=32`, `BLOCK_N=64`, four-wave specialization removed the 21x
query padding for the 12-token verifier, but still used 256 VGPRs, 106 SGPRs,
78,080 bytes LDS, and 1,108-1,116 bytes scratch per workitem (about 435 scratch
loads and 156 stores). It preserved the established 210+128 output hash, but
warmed 32K+128 latency was 5.992-7.018 seconds versus 6.44-6.72 seconds for
the normal HiP autotuner and 4.20-4.52 seconds for dense target attention. The
long-context dFlash output hashes were non-repeatable in both HiP and dense
controls. The specialization and HiP serving integration are therefore rejected.

For comparison, the scratch-free raw gfx950 full-attention M16 stage1+stage2
path is bitwise identical to 16 deployed Triton decode calls at prefix length
32,768 and eight KV splits. HIP-event means were 0.212185 ms raw versus
2.980429 ms for the sequential oracle, a 14.046x isolated speedup. The existing
batched GQA8 FP8-KV production kernel remains the accepted serving path; its
full-plus-piecewise A/B/A result above is the relevant end-to-end evidence.

Raw traces and code objects are retained under
`20260803T125940Z-dflash-target-hip-qwen64k-torchprofile-gpu6` and
`20260803T134727Z-dflash-target-hip-qwen64k-bm32w4-gpu6` in the optimization
artifact root.
