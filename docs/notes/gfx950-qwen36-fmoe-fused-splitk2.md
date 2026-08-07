# gfx950 fused FMoE: split-K x2, deep-K, masked stores, and the real wall

Date: 2026-08-08 UTC

Status: **three validated-correct variants, all within noise of the 320 us
pipelined baseline; the binding constraint is now identified empirically**.

## Variants measured (exact M=1024 capture, GPU1)

| Variant | Fused median | Reduce median | Gate |
|---|---:|---:|---|
| v3 pipelined baseline | 308.7 us | 15.0 us | pass, bit-identical |
| deep-K (8 MFMAs/wait via dead W2 regs v[128:175]) | 320.1 total | - | pass, bit-identical |
| masked partial stores (exec-predicated, skips padding rows) | 309.0 us | 14.9 us | pass, bit-identical |
| split-K x2 (grid 2x291, per-half partials, two-half reducer) | 293.9 us | 26.9 us | pass, deterministic, tolerance-identical |

Split-K x2 is numerically reassociated (two-half FP32 sum), shifts exactly
two BF16 outputs, and passes every preregistered tolerance; it is the first
grid-level decomposition of this kernel that preserves determinism with no
atomics. The two-half reducer `qwen36_moe_route_reduce_f32_2h_gfx950` sums
split-K halves before the fixed-order route weighting.

## Diagnosis

Three orthogonal levers (2x occupancy, 2x MFMA depth per wait, -78 MB of
partial-store traffic) all measured flat, and a co-run of two complete
harness instances on one GPU ran each at full solo speed. The kernel is
therefore neither bandwidth- nor compute- nor wave-slot-bound: the GPU has
about 2x idle capacity while it runs. The wall is the per-workgroup serial
latency chain times round quantization of the grid: 291 uniform workgroups
on 256 CUs is one full round plus a 35-workgroup tail that costs an entire
second round (2 x ~160 us = the observed 320); split-K x2 gives 582
workgroups of ~98 us = 3 rounds = the observed 294. The masked sink-row
stores were already L2-absorbed (all lanes hit one 8 KiB row per block),
which is why removing them changed nothing.

## Next steps

1. rocprofv3 occupancy/counter pass to confirm per-CU workgroup residency
   (the co-run proves 2x64 KiB LDS coexists on a CU, so solo grids should
   co-schedule their tail; measured walls say they do not).
2. A balanced persistent schedule or true 2-per-CU co-residency so the tail
   round disappears: ideal wall at the current chain length is
   291x160/256 = 182 us for the unsplit kernel and ~115 us for split-K x2,
   both below the AITER 226 us reference.
3. If co-residency needs LDS below a threshold, shrink the split-K variant
   to its natural 48 KiB (each half only needs its own activation region).

Artifacts: `20260808T172016Z-fmoe-fused-pipeline-gpu1` plus in-tree sources;
harnesses now report fused and reduce medians separately.
