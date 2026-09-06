# DeepSeek V4 C4 indexer assembly experiment

This is a handwritten AMDGCN replacement candidate for AITER's
`_gluon_deepgemm_fp8_paged_mqa_logits_preshuffle`, specialized to the deployed
DeepSeek V4 Flash indexer: 64 replicated heads, dimension 128, one query per row,
64 keys per packed page, gfx950 E4M3FN. It does not replace other Triton kernels.
It is experimental and is not selected automatically by SGLang.

The AMDGCN files in `experiments/` implement the entire score calculation.
The original `dsv4_mqa_fp8_h64_d128_gfx950.s` is retained for large workloads. The HIP bridge only loads the module, checks the launch contract,
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

`Scorer(build_dir)` selects a schedule from CPU shape metadata before launch.
Query rows include speculative tokens; they are not concurrent-user counts.
The small-batch policy uses shorter key tiles when there is little work, and
increases per-wave query reuse only when enough query-page work is available.
No GPU lengths are read on the host and no mutable execution buffers are shared.

All variants use FP8 `v_mfma_f32_16x16x128_f8f6f4`, FP32 scale/ReLU/weight
operations, the original reduction tree and two `ds_bpermute` head reductions.
The small variants use packed FP32 arithmetic, with loads and independent
MFMAs scheduled ahead of their consumers. No variant uses LDS or scratch spills.

| Mode | Assembly file suffix | Keys per wave | VGPRs | Threads/workgroup |
|---:|---|---|---:|---:|
| 0 | `h64_d128` | 64 x pages | 84 | 64 |
| 1 | `tile16_w1` | 16 | 84 | 64 |
| 2 | `tile16_w4` | 16 | 84 | 256 |
| 3 | `pipeline` | 64 x pages | 96 | 64 |
| 4 | `tile32` | 32 | 96 | 64 |
| 5 | `pair32` | 64 x pages | 112 | 64 |
| 6 | `pair32_w4` | 64 x pages | 112 | 256 |

Modes 2 and 6 partition work across independent waves. Mode 2 shares a page;
mode 6 assigns separate page runs to each wave. Explicit `mode=N` and
`pages_per_wave=N` arguments support isolated comparisons. An explicit page
count with no mode retains the original mode-0 override behavior.

The 76-byte GPU kernarg block remains six pointers (Q, KV, weights, lengths,
page table, output), then seven uint32 values: output row stride in elements,
Q row stride in bytes, weight row stride in bytes, page-table row stride in
bytes, KV page stride in bytes, output width, and pages per wave. The **host**
launch ABI is now `netra_mqa_launch_v2`; it adds a mode argument that chooses
the entry point and launch dimensions, without changing the GPU kernarg ABI.
Load the matching Python runtime, HIP bridge and code object together.
Grid Y is rows. Grid X is the ceiling of width divided by the keys owned by
a workgroup (including all its waves). The bridge checks bounds and alignment.

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

Recorded results and limitations: [small-batch follow-up](../../../../benchmark_results/dsv4_indexer_small_batch_20260906/README.md) and [original validation report](../../../../benchmark_results/dsv4_indexer_asm_20260906/README.md).
