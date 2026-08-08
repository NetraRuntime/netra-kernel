# Qwen3.6 dFlash M768 BF16 down-projection global-load negative

## Verdict

Rejected as a compute schedule. The four-wave raw gfx950 kernel is safe,
deterministic, and graph-capturable, but it is 3.94x slower than the deployed
rocBLAS/Tensile kernel and misses the exact-BF16 correctness gate.

## Measured contract

- GPU: AMD Instinct MI350X, `gfx950`, wave64
- draft checkpoint weight: `layers.0.mlp.down_proj.weight`
- operation: BF16 `[768,6144]` times BF16 `[2048,6144]^T`
- output: BF16 `[768,2048]`
- workgroups: 32x12, four waves / 256 threads
- code object: 80 VGPR, 20 SGPR, zero LDS, zero scratch
- raw source:
  `kernels/gfx950/dflash/draft/qwen36_dflash_mlp_down_bf16_m768_m64n64_global_gfx950.s`

The deployed control selected the Tensile
`MT64x96x256_MI16x16x1` gfx950 kernel. Rocprofv3 reports 256 threads, 86,016
bytes LDS, 140 VGPR, 96 SGPR, and steady dispatches around 36-44 us. This is the
architecture to beat, not the untuned-warning string alone.

## Result

HIP-event timings on the real layer-0 checkpoint weight:

| implementation | median us | p90 us |
|---|---:|---:|
| Torch/rocBLAS control, 200 repeats | 49.080 | 54.081 |
| raw direct-global, 20 repeats | 185.586 | 186.846 |
| raw direct-global graph-fixed repeat | 191.964 | 192.283 |

The raw schedule is 3.78x slower in the primary run and 3.94x slower in the
graph-fixed repeat. It differs in 521 of 1,572,864 BF16 elements, with max
absolute error 0.015625 and mean absolute error 4.67e-7. Replay after capture is
bit-exact to the eager raw output. No AMDGPU fault or reset occurred, and the
control Qwen server remained healthy.

Artifacts:
`/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T060000Z-dflash-down-m768-gpu6`

## Cause and successor

Each 32x32 wave quadrant reloads both A and B directly from HBM. Across the
64x64 workgroup tile that duplicates operand traffic and provides no K-stage
prefetch. The deployed kernel instead uses a 64x96 macro tile, K=256 staging,
and 86 KiB LDS.

Do not tune the direct-global topology. The successor should use a padded,
bank-aware LDS layout, at least K=128 staging, four-wave 64x64 or 64x96 output
ownership, and overlapped global prefetch/MFMA issue. Correctness comparison
must include the deployed M=768 accumulation order before serving integration.
