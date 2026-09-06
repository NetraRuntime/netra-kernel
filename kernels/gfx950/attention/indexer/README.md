# DeepSeek V4 C4 indexer assembly experiment

This is a handwritten AMDGCN replacement candidate for AITER's
`_gluon_deepgemm_fp8_paged_mqa_logits_preshuffle`, specialized to the deployed
DeepSeek V4 Flash indexer: 64 replicated heads, dimension 128, one query per row,
64 keys per packed page, gfx950 E4M3FN. It does not replace other Triton kernels.
It is experimental and is not selected automatically by SGLang.

`experiments/dsv4_mqa_fp8_h64_d128_gfx950.s` implements the entire score
calculation. The HIP bridge only loads the module, checks the launch contract,
and launches it on the caller's stream. There is no HIP C++ compute kernel or
Triton dependency in the candidate runtime.

## Contract

For every valid key, the operation is
`sum_heads(weight[h] * relu(fp32_dot(q_fp8[h], k_fp8[key]) * key_scale[key]))`.
Scale/ReLU/weight ordering is preserved, including signed head weights.
Invalid output positions are written as negative infinity.

Inputs must be finite. Lengths must be nonnegative and must not exceed the
output width. Active page IDs must refer to allocated pages in the same KV
pool. Zero-length rows never read their page table or KV. Pages can be shared
between requests; each row uses its own page table and length. Callers own
tensor lifetime, non-aliasing output, and stream dependencies. The launcher
does not read GPU scalars to check semantic contracts.

Q is E4M3FN `[rows,1,64,128]`, contiguous within each head and across heads.
Weights are FP32 `[rows,64]`; lengths and page table are int32. KV is a byte
view `[physical_pages,64,1,132]`. Within each physical page, the first 8192
bytes are shuffled FP8 keys and the next 256 bytes are 64 FP32 scales:

```
key_byte_offset = (key % 16)*16 + (dim % 16)
                + (dim // 16)*256 + (key // 16)*2048
scale_byte_offset = 8192 + key*4
```

Q, weight, page-table and output rows may have padding. Physical KV pages may
have padding. Row/page base address arithmetic is 64-bit, preserving the
production fix for logits allocations beyond 4 GiB. Maximum output width is
262144 compressed C4 keys (the capacity corresponding to a 1,048,576-token
input); this is not itself a validation of model accuracy at 1M context.

The module is explicitly preloaded per device before graph capture. Launches
allocate no GPU buffers, copy no tensors, synchronize no streams, and perform
no file access. A module must outlive all captured graphs that reference it.
Unsupported layouts must use the existing serving backend.

## Schedule and ABI

One 64-thread wave computes one query by a run of 64-key pages. It retains 64x128 query
elements and head weights in registers while processing four 16-key tiles per page.
Each tile uses four `v_mfma_f32_16x16x128_f8f6f4` instructions, vector
scale/ReLU/weight operations, register reduction, then two `ds_bpermute`
reductions. It uses 84 VGPRs, 40 SGPRs and no LDS or scratch spills.

The 76-byte kernarg block contains six pointers (Q, KV, weights, lengths,
page table, output), then seven uint32 values: output row stride in elements,
Q row stride in bytes, weight row stride in bytes, page-table row stride in
bytes, KV page stride in bytes, output width, and pages per wave. Grid X is ceil(width/(64*pages_per_wave)),
grid Y is rows, block X is 64. See the bridge for bounds and alignment checks.

Instruction reference: [AMD CDNA4 ISA](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf).

## Reproduce

From the repository root in a ROCm 7.2 gfx950 environment:

```sh
bash tools/benchmark/indexer/build.sh /tmp/netra-mqa-build
python tools/benchmark/indexer/validate.py \
  --build /tmp/netra-mqa-build --output /tmp/netra-mqa-results.json
```

The validator requires the deployment's AITER scorer for comparison, including
its 64-bit output-address fix, plus SGLang's exact top-K R2 patch. Use
`--skip-native-topk` only for scorer-only validation. Run it on isolated GPUs. It checks one-hot and
random FP8 inputs, signed/positive weights, ragged lengths, page permutations,
invalid rows, output canaries, top-512 set agreement, changing graph inputs,
1M-equivalent compressed width, and output/KV addresses beyond 4 GiB.
Reported graph timings are kernel microbenchmarks, not serving TPS.

Before production selection, require real captured-input and exact-topK
qualification, concurrent stream/device ownership checks, and the existing
TP4xDP2 correctness and C256 a/b/c serving gates. Preserve outer query tiling,
exact top-K, long-position arithmetic, HiCache/Mooncake ownership fixes, and
request isolation. Assembly alone is not evidence of a performance gain.

Recorded results and limitations: [validation report](../../../../benchmark_results/dsv4_indexer_asm_20260906/README.md).
