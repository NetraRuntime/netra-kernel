# Qwen3.6 gfx950 M64 N256 one-workgroup FMoE negative

## Verdict

Rejected. The raw gfx950 kernel is substantially faster than the earlier
four-workgroup row-wave/split-K prototype, but it remains much slower than the
deployed AITER `64x256` one-stage kernel and fails the predeclared isolated
correctness gate.

## Real-checkpoint shape and method

- GPU: AMD Instinct MI350X, `gfx950`, wave64
- weights: FP8 E4M3, 128x128 block scales
- rows: 768
- hidden: 2,048
- expert intermediate: 512
- top-k: 9
- active experts: 191 in the retained AITER capture
- raw sorted M64 fixture: 15,872 valid IDs / 248 M64 blocks
- timing: HIP events in the retained fused-M64 harness
- artifact root:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T041500Z-moe-1wg-n256-gpu6`

The candidate ran on GPU 6 while the Qwen server was healthy but idle. The
production training and verifier containers were not modified or interrupted.

## Design

The previous prototype launched four workgroups per sorted M64 block. Each
workgroup produced one K128 activation slice and one W2 split-K contribution.
This candidate instead launches one four-wave workgroup per M64 block:

1. Compute and quantize all four M64x128 activation slices into the lower
   32 KiB of LDS.
2. Stage W2 as N256xK128 slabs in the upper 32 KiB.
3. Retain 64 FP32 W2 accumulators per lane across all four K128 slices.
4. Emit eight complete N256 output steps. Packed-BF16 atomics combine routed
   experts only; they no longer combine four split-K workgroups.

The raw source intentionally retains the historical atomic kernel symbol so
the existing real-checkpoint harness can load the alternate code object.

## Code object

- target: `amdgcn-amd-amdhsa--gfx950`
- wavefront: 64
- workgroup: 256 threads / four waves
- LDS: 65,536 bytes
- VGPR: 192
- SGPR: 90
- scratch: zero
- static disassembly: 24 FP8 MFMA instructions, 64 packed-BF16 atomics,
  6 barriers

## Results

| implementation | median us | p90 us | result |
|---|---:|---:|---|
| deployed AITER 64x256, same M=768 capture | 182.602 | 187.774 | baseline winner |
| earlier raw four-workgroup row-wave | 417.844 | 420.456 | rejected |
| raw one-workgroup N256, 20 repeats | 333.150 | 337.418 | rejected |

The N256 candidate is 20.3% faster than the earlier raw design, but 82.4%
slower than AITER. Its complete-output comparison reports max absolute error
0.00102954 and cosine 0.999966 against the structural oracle; comparison to
the retained AITER result reports max absolute error 0.000976562 and cosine
0.999960. The harness nevertheless reports `full_correctness_gate=fail`, so
the candidate cannot be promoted even apart from performance.

## Conclusion

Increasing W2 ownership to N256 fixes a real inefficiency, but serializing all
four W13 activation groups in one workgroup gives away too much parallelism.
Do not continue tuning this one-workgroup topology. A viable successor needs
parallel W13 production plus a graph-safe persistent/multi-phase W2 schedule,
or should target a different measured hotspot where the deployed baseline is
not already as mature as AITER FMoE.
