# Qwen3.6 gfx950 M64 atomic MoE-down negative

## Verdict

Rejected. Replacing the FP32 route-partial workspace and fixed-order reducer
with packed-BF16 atomics did not improve the matched M=768 pipeline and missed
the predeclared complete-output cosine gate.

## Shape and implementation

- GPU: AMD Instinct MI350X, `gfx950`, wave64
- checkpoint: Qwen3.6-35B-A3B FP8 E4M3, 128x128 block scales
- verification rows: 768
- hidden / expert intermediate: 2,048 / 512
- top-k: 9
- valid sorted IDs / M64 blocks: 15,872 / 248
- grid: 16 N128 tiles x 248 expert blocks
- workgroup: 256 threads / four waves
- LDS: 32 KiB
- VGPR / SGPR / scratch: 140 / 58 / zero

The raw kernel applies the sorted route weights, converts adjacent FP32
outputs to packed BF16, and executes `global_atomic_pk_add_bf16` directly into
the final token-major output. The harness includes the required zeroing in the
timed path. Static disassembly contains eight MFMA instructions, 32 packed
BF16 atomics, and one barrier; the K loop executes four times.

## Debugging result

The first build used `v124` both as the first accumulator of the second N64
slab and as a temporary output address. That destroyed columns 64-79 of every
N128 tile and produced structural cosine 0.987168. Commit `d8d9f42` reuses a
dead lane-index register for the address instead, preserving all accumulators
without increasing register count.

## Matched result

One hundred HIP-event repetitions on the same retained real-checkpoint M=768
capture produced:

| complete raw pipeline | median us | p90 us | correctness |
|---|---:|---:|---|
| FP32 partials + fixed-order reducer | 185.198 | 188.606 | pass |
| packed-BF16 atomic down | 187.817 | 194.149 | fail |
| packaged AITER 64x256 one-stage oracle | 182.602 | 187.774 | pass |

The atomic candidate is 1.41% slower than the matched fixed-order raw pipeline
and 2.86% slower than AITER. Its complete output has structural max absolute
error 0.00084421 and cosine 0.999966, and AITER max absolute error 0.000976562
and cosine 0.999963. The unchanged predeclared cosine thresholds are 0.9999725
and 0.9999645 respectively, so the candidate fails even though both maximum
error limits pass.

The old reducer remains the correct raw baseline. A viable successor needs to
reduce W2 compute or weight traffic, not merely replace its deterministic
reduction with atomics. The next useful W2 topology is N256 ownership with
activation reuse, provided it preserves the accepted fixed-order output gate.

Artifacts are retained under:

`/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T043000Z-moe-down-atomic-gpu6/`

