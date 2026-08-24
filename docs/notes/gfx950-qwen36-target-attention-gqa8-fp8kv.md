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
