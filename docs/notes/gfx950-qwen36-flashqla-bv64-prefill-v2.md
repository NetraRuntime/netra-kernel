# gfx950 Qwen3.6 FlashQLA-derived BV64 prefill v2

Date: 2026-08-03

Target: one MI350X, `gfx950`, wave64, Qwen3.6-35B-A3B FP8 E4M3
weights, BF16 GDN state, `N=16`, 1,024 tokens per sequence, `H=32`,
`Hg=16`, `K=V=128`, and chunk size 64.

QwenLM FlashQLA commit `821fd9d37ede18fdc2a4e707fefe3770bfc32e58`
was used as the algorithmic reference. Its CUDA/TileLang implementation was not
ported. The raw kernels here were re-derived for gfx950 wave64 and use
`v_mfma_f32_16x16x32_bf16`.

## Measured design progression

The rejected v1 assigned one `V16` tile to each workgroup and recomputed the
same 64x64 QK matrix eight times per head. The new kernels widen ownership while
sharing QK:

| raw kernel | grid | VGPR | SGPR | LDS | N16 fused median | raw-H + Triton-O | speedup |
|---|---:|---:|---:|---:|---:|---:|---:|
| `qwen36_gdn_fused_h_o_n16_t1024_bv32_gfx950` | `4x512` | 144 | 36 | 24 KiB | 811.8 us | 1082.7 us | 1.33x |
| `qwen36_gdn_fused_h_o_n16_t1024_bv64_gfx950` | `2x512` | 184 | 36 | 40 KiB | 599.8 us | 1080.3 us | 1.80x |

Both code objects are gfx950/wave64 with zero scratch and zero spills. BV64
shares each QK tile across four V16 quarters and leaves 1,024 workgroups for the
256-CU device at N16. The B1/T1024 BV64 result is intentionally not selected:
231.96 us versus 68.32 us for the narrow baseline, confirming that the wider
tile is a high-parallelism regime only.

## Correctness status

The BV32 one-chunk gate produced a bit-exact 524,288-element final state. Its
output differed in two BF16 subnormal elements, maximum absolute error
`1.9073486328125e-6`, with no tolerance failures.

The stable 20-iteration BV64 N16 run is not accepted for integration. Against
the real-checkpoint raw-H + Triton-O oracle:

- output: maximum absolute error `0.015625`, cosine `0.9999994636`, six
  predeclared relative-tolerance failures;
- final state: maximum absolute error `0.125`, cosine `0.9999979734`, 698
  predeclared relative-tolerance failures.

The speedup is retained as the scheduling anchor, but the kernel remains under
`experiments/` and must not be dispatched from SGLang. The next version widens
to the full `BV128` head tile and restores the deployed MFMA accumulation and
BF16 conversion order before any layer or serving gate.

Artifacts:

- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T235000Z-gdn-fused-bv32-onechunk-gpu5/`;
- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260803T001500Z-gdn-fused-bv32-n16-t1024-gpu5/`;
- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260803T020000Z-gdn-fused-bv64-n16-final-gpu5/`.
