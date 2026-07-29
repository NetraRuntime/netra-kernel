# gfx1151 MXFP4 prefill-down paired-group reuse (rejected)

Status: **not enabled in production**. All numbers are measured on gfx1151; none are estimated. MXFP4 weights remain MXFP4.

The exact 32,768-token trace measured the existing raw down kernel at 160 calls and 1,201.098 ms total. Sorted routing creates approximately ten adjacent M64 groups per expert at the real ~1,276-group shape, suggesting that two groups could share packed-weight loads, scale loads, MXFP4 unpacking, and decoded BF16 weight fragments.

`scripts/rocm/mxfp4_prefill_down_pair_wmma_gfx1151.s` is a hand-written raw AMDGCN ceiling prototype. Each wave computes two adjacent M64 groups for one expert. It loads and decodes each N16xK32 weight fragment once, then applies it to two activation groups with independent FP32 accumulator sets. The prototype contract deliberately assumes an even group count and equal expert IDs within every pair; it is not wired into SGLang.

| gfx1151 resource | single group | paired group |
|---|---:|---:|
| VGPR | 105 | 137 |
| SGPR | 22 | 28 |
| LDS | 0 B | 0 B |
| Scratch | 0 B | 0 B |

The exact-shape ceiling harness used G=1,280, M=64, N=2,048, K=512, 128 experts with ten adjacent groups per expert, deterministic nonzero MXFP4/scales/BF16 activations, alternating launch order, and nine HIP-event samples.

| raw gfx1151 ASM | median | sample range | output |
|---|---:|---:|---|
| existing single-group | 7.341971 ms | 7.279892–7.384693 ms | reference |
| paired-group reuse | 7.502595 ms | 7.450776–7.563187 ms | byte-identical |

Paired reuse is 2.188% slower (`0.97859x`). The extra 32 live FP32 accumulators raise register allocation by 30.5%; reduced occupancy and the longer dependency chain outweigh shared weight decode/load work. Because the optimistic equal-pair ceiling already loses, boundary/tail handling and SGLang integration would only add work and are rejected.

Artifacts: `scripts/rocm/benchmark_prefill_down_pair.hip`, `results/kernels/gfx1151/prefill-down-pair-prototype.txt`, and `docs/netra/notes/disassembly/prefill-down-pair-gfx1151/`.
