# gfx1151 extend-attention optimization record (2026-07-29)

Every duration below is measured on gfx1151. Serving attribution is from
rocprofv3; isolated tile-oracle durations use HIP events. Static instruction
counts are labeled separately and are not runtime measurements.

## Trace rank and actual specialization

The trace name `_fwd_kernel` resolves to SGLang's Triton
`kernels/ops/attention/extend_attention.py` kernel, not an unidentified helper.
For Qwen3.6 it runs batch 1, 16 query heads, 2 KV heads, head dimension 256,
BF16, causal masking, and 8,192-token chunks. It is rank 1 for the exact
32,768/+1 request: 40 calls total 8,824.300 ms, or 25.32% of host E2E,
measured by rocprofv3 on gfx1151.

The cached 64x64/four-wave code object is specialized for gfx1151. Its metadata
reports 256 VGPR, 105 SGPR, 1,184 bytes private scratch per work-item, and 32 KiB
dynamic shared memory. Static disassembly contains 13,770 instructions,
377 scratch loads, 467 scratch stores, 1,227 `s_waitcnt`, 933 `s_delay_alu`,
11 barriers, and 256 WMMA instructions. This makes register spilling and the
online-softmax dependency chain the concrete raw-ASM targets.

## Temporary tile oracle

Compiler-generated Triton variants are temporary design oracles only; none is
an accepted final compute kernel. Each row is the median of five HIP-event
samples at the actual 8,192-token extend shape. Output is compared with the
64x64/four-wave BF16 baseline.

| Prefix tokens | 64x64 / 4 waves ms | 64x32 / 8 waves ms | Speedup | Normalized L2 | Status |
|---:|---:|---:|---:|---:|---|
| 0 | 47.670 | 44.916 | 1.0613x | 4.29e-4 | gfx1151 measured |
| 8,192 | 163.867 | 143.950 | 1.1384x | 4.24e-4 | gfx1151 measured |
| 16,384 | 276.080 | 250.437 | 1.1024x | 3.83e-4 | gfx1151 measured |
| 24,576 | 390.126 | 359.904 | 1.0840x | 3.63e-4 | gfx1151 measured |
| Four chunks | 877.744 | 799.208 | 1.0983x | n/a | gfx1151 measured |

A 128x64/eight-wave variant is 1.217x faster with zero prefix but regresses the
four-chunk sum by 6.8%, so it is rejected as a uniform kernel. A 64x64/eight-wave
variant also regresses the four-chunk sum. The 64x32/eight-wave decomposition
reduces the corresponding compiler code object's private scratch to 492 bytes
and static scratch instructions from 844 to 147. The final replacement must be
hand-written AMDGCN `.s`; this oracle is not integrated into serving.
