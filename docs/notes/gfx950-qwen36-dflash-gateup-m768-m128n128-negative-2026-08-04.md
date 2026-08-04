# Qwen3.6 gfx950 dFlash M768 gate/up M128N128 negative

## Verdict

Rejected. The raw `gfx950` kernel is bit-exact and graph-exact on the real
Qwen3.6 dFlash checkpoint, but its 88.058 us median is 61.9% slower than the
same-run deployed Torch/Tensile BF16 linear at 54.380 us. It was not integrated
into SGLang and no serving restart was performed.

## Contract and method

- GPU: AMD Instinct MI350X, `gfx950`, wave64
- checkpoint: `Qwen3.6-35B-A3B-DFlash`
- operation: concatenated BF16 gate/up projection
- shape: M=768, N=12,288, K=2,048
- input and output: BF16
- timing: HIP events, 20 warmups, 100 retained repeats
- graph gate: one captured launch replayed and compared to eager output
- artifact root:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T081400Z-dflash-gateup-m128n128-gpu3`

The experiment ran on otherwise-idle GPU 3. The live Qwen server on GPU 6 and
the production training allocation on GPUs 1,2,5,7 were not modified.

## Raw schedule

One 256-thread workgroup computes a 128x128 macro tile. Four wave64s own 64x64
quadrants, with sixteen native 16x16x32 BF16 MFMA accumulator tiles per wave.
A and B use padded 272-byte LDS rows and K128 staging. Two VGPR operand banks
alternate the four K32 MFMA steps in each slab.

The emitted code object reports:

- 160 VGPRs, 24 SGPRs
- 81,920 bytes LDS
- zero scratch and zero register spills
- 64 static `v_mfma_f32_16x16x32_bf16` instructions
- 16 global 128-bit loads, 16 LDS 128-bit writes, 32 LDS 128-bit reads
- two barriers
- HSACO SHA-256:
  `88659bb84633b68bbfb9e73694ab5f1257f3d909fd66bf40e37ebd455f4104fa`

## Results

| implementation | minimum us | median us | p90 us |
|---|---:|---:|---:|
| deployed Torch/Tensile BF16 linear | 49.119 | 54.380 | 64.719 |
| raw gfx950 M128N128 | 85.799 | 88.058 | 98.278 |

All 9,437,184 BF16 outputs matched bit-for-bit. Both paths produced SHA-256
`d58213406b3d9ed69478bc63030bfba3b1697a52e454c84bb3c00ec09e5e32ba`, and
captured graph replay was exact.

The larger tile reduces the absolute time of the earlier raw prototypes, but
its 80 KiB LDS and 160-VGPR static footprint materially constrain scheduling,
while the grid contains only 576 workgroups for the full GEMM. The retained
timing shows that this schedule does not hide the 16 serial K128 stages as well
as the mature library kernel. Because the isolated performance gate failed
decisively, occupancy counters and end-to-end integration were intentionally
skipped; no unmeasured occupancy number is claimed here.

## Decision

Do not continue increasing monolithic gate/up tile ownership. Preserve this
source as a structural negative. The next work should target a measured draft
or verification kernel whose deployed implementation is less mature than this
BF16 GEMM baseline.
