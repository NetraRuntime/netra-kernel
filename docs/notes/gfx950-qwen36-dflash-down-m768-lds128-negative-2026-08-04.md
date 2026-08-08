# Qwen3.6 gfx950 dFlash M768 BF16 down-projection LDS128 negative

## Verdict

Rejected. Cooperative LDS staging and operand pipelining reduced the raw
kernel from 191.96 us to 67.48 us, but the final candidate remained 40.8%
slower than the deployed rocBLAS/Tensile kernel and failed the predeclared
bitwise BF16 gate.

## Contract and method

- GPU: AMD Instinct MI350X, `gfx950`, wave64
- real checkpoint tensor: `layers.0.mlp.down_proj.weight`
- shape: M=768, N=2,048, K=6,144
- input, weight, and output: BF16
- timing: HIP events, 20 retained repeats after warm-up
- counters: `rocprofv3` supported gfx950 counters
- artifact root:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T060000Z-dflash-down-m768-gpu6`

## Iteration results

| implementation | median us | p90 us | result |
|---|---:|---:|---|
| deployed rocBLAS/Tensile 64x96x256 | 47.920 | 49.480 | baseline winner |
| raw direct-global M64xN64 | 191.964 | - | rejected |
| raw LDS M64xN64xK128, pitch 272 | 73.141 | 75.800 | rejected |
| raw LDS M64xN64xK128, pitch 320 | 70.141 | 72.440 | rejected |
| raw LDS pitch 320, pipelined operands | 67.480 | 71.919 | rejected |

Only 16-byte-aligned row pitches were viable. Pitches 260, 264, 268, 276,
and 280 bytes took approximately 289-291 us. Pitch 320 halved the measured LDS
bank-conflict rate relative to pitch 272. Double-buffering the LDS operand
registers then produced another 3.8% improvement without increasing the raw
80-VGPR allocation.

## Code object and counters

The final candidate uses a 256-thread/four-wave workgroup, 40,960 bytes of
LDS, 80 VGPRs, 23 SGPRs, wave64, and zero scratch. Static disassembly contains
16 BF16 MFMAs, 16 `ds_read_b128` instructions, eight `ds_write_b128`
instructions, and two barriers in the K128 loop body.

| gfx950 counter | final raw | deployed Tensile |
|---|---:|---:|
| LDS bank conflict | 12.49% | 0.00% |
| LDS utilization | 37.46% | 32.33% |
| MFMA utilization | 12.49% | 19.38% |
| mean occupancy per active CU | 1.50 | 1.00 |

The higher occupancy does not compensate for the M64xN64 tile's lower data
reuse and issue efficiency. The deployed M64xN96xK256 schedule launches fewer
workgroups, reuses each activation tile over more output columns, and sustains
substantially higher MFMA utilization.

## Correctness

The raw output is stable across direct-global, LDS-pitch, and pipelined
variants. Against the deployed result, 521 of 1,572,864 BF16 elements differ,
with maximum absolute error 0.015625 and mean absolute error 4.67e-7. HIP graph
capture/replay is exact. This is consistent with a different accumulation
order, but it still fails the declared bitwise isolated gate.

## Next decision

Do not continue tuning the M64xN64xK128 topology. A successor must use a wider
N tile and a deeper K stage comparable to M64xN96xK256, or target a genuinely
untuned live draft projection rather than duplicating this mature Tensile
shape.
