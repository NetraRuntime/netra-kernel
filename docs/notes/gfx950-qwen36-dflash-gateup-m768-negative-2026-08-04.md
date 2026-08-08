# Qwen3.6 gfx950 dFlash M768 BF16 gate/up negative

## Verdict

Rejected. Both raw gfx950 gate/up projections are bit-exact against the real
dFlash checkpoint and replay exactly under HIP graphs, but neither beats the
deployed BF16 linear path. Doubling N ownership to 128 columns does not improve
the uncontended latency floor and increases wave/LDS pressure.

## Exact live shape

- GPU: AMD Instinct MI350X, `gfx950`, wave64
- draft checkpoint: Qwen3.6-35B-A3B-DFlash
- input: M=768, K=2,048, BF16
- concatenated gate/up weight: N=12,288, K=2,048, BF16
- output: M=768, N=12,288, BF16
- graph shape: c64 dFlash verification (12 draft tokens per sequence)

The live SGLang log reports this shape as missing from AITER's BF16 tuned CSV
and selecting the default Torch solution. An exhaustive installed-assembly
screen selected AITER's 256x256 kernel at 100.8022 us. Its code object uses a
256-thread workgroup, 163,840 bytes LDS, 512 reported vector/accumulator
registers, 112 SGPRs, and zero scratch.

## Raw designs

The first handwritten kernel uses four waves per workgroup. Each wave computes
a 32x32 quadrant while the workgroup stages a 64x64 K128 slab in padded LDS.
The second uses eight waves for a 64x128 macro tile. It halves repeated A loads
but increases the workgroup to 512 threads and LDS to 61,440 bytes.

| implementation | workgroup | LDS | median us | minimum us | result |
|---|---:|---:|---:|---:|---|
| deployed Torch linear, M64N64 run | library | library | 95.582 | 68.081 | control |
| raw M64N64 | 256 | 40,960 B | 137.622 | 106.402 | reject |
| deployed Torch linear, M64N128 run | library | library | 95.241 | 67.201 | control |
| raw M64N128 | 512 | 61,440 B | 162.123 | 106.522 | reject |

Both raw variants produced zero BF16 mismatches across 9,437,184 outputs,
max absolute error 0, identical SHA-256
`d58213406b3d9ed69478bc63030bfba3b1697a52e454c84bb3c00ec09e5e32ba`,
and exact graph replay.

The M64N128 result shows that reducing workgroup count without increasing
per-wave output ownership is not useful on this shape. A viable successor must
increase MFMA accumulator ownership per wave (M128/N128 or larger), approach
the installed 256x256 kernel's operand reuse, and avoid the 512-thread
workgroup's scheduling penalty. Do not integrate either candidate into SGLang.

## Artifacts

- AITER screen:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T090000Z-dflash-bf16-m768-aiter-tune-gpu5`
- raw M64N64:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T091500Z-dflash-gateup-m64n64-gpu5`
- raw M64N128:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T093000Z-dflash-gateup-m64n128-gpu5`
