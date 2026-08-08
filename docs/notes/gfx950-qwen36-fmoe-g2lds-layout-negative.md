# gfx950 Qwen3.6 FMoE global-to-LDS layout negative

Date: 2026-08-08 UTC

Status: **rejected at the isolated correctness gate; never integrated.**

## Motivation and exact contract

Disassembly of deployed AITER showed that its weight path uses
`buffer_load_dwordx4 ... lds`, not the per-wave direct-global scheme tested in
the preceding negative. This experiment transplanted that gfx950 transfer
mechanism into the retained raw one-workgroup kernel while leaving its MFMA,
accumulation, quantization, W2, reducer, and ABI unchanged.

- GPU: AMD Instinct MI350X, `gfx950`, wave64
- weights: FP8 E4M3, 128x128 block scales
- exact real-checkpoint shape: M=1024, hidden=2048, intermediate=512, top-k=9
- sorted fixture: 18,624 valid IDs / 291 M64 blocks
- workgroup: four waves / 256 threads
- code object: 224 VGPRs, 94 SGPRs, 64 KiB LDS, zero scratch

The installed assembler rejects MUBUF-to-LDS `dwordx2`, so the compiled
variant uses two loader waves and `dwordx4`: each loader wave is intended to
own a 1 KiB half of each 2 KiB weight row. Static disassembly contains 16
`buffer_load_dwordx4 ... lds`, 52 `ds_read_b128`, 20 `ds_write_b64`, six
barriers, and 24 FP8 MFMAs. W2 remains unchanged.

## Result

The kernel launches, remains finite, and reports 301.022 us fused median, but
the timing is invalid because correctness fails catastrophically:

- structural BF16 mismatches: 2,095,323 / 2,097,152
- structural max absolute error: 0.139749
- structural cosine: 0.529619
- AITER cosine: 0.529605
- nondeterministic iterations: 99 / 100
- correctness gate: fail

The corruption proves that AITER's global-to-LDS opcode cannot be transplanted
independently. Its implicit LDS lane placement is coupled to AITER's custom LDS
read addresses and deep 512-VGPR MFMA fragment organization. The retained raw
kernel expects the row-major layout produced by `global_load_dwordx2` followed
by `ds_write_b64`; the nominal two-wave mapping violates that contract and
introduces overlapping or otherwise incompatible placement.

## Decision

Do not tune, integrate, or benchmark this source in serving. A correct AITER-
style successor requires co-designing the MUBUF transfer, LDS layout, MFMA
fragment mapping, and deep accumulator ownership as one kernel; it is not a
local staging substitution. Since deployed AITER is already 226 us and the
correct retained raw kernel is 282.8 us, stop this FMoE topology line and move
to the less mature measured GDN copy/replay hotspot.

Artifacts:
`/data/netra/benchmarks/gfx950_qwen36_optimization/20260808T205000Z-fmoe-g2lds-w13-gpu1`.
