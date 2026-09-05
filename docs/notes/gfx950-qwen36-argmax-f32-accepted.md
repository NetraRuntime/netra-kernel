# Qwen3.6 dFlash FP32 argmax on gfx950

Date: 2026-07-30
Status: **accepted for the measured TP1/full-graph/block-16 path**

The real target-verification boundary is contiguous FP32 `[16,248320]`.
PyTorch's deployed reduction launches one 512-thread workgroup per row, only
16 workgroups/128 waves on the 256-CU MI350X. The exact specialization is
21,244 bytes of function text and uses the generic 992-byte reduction ABI plus
512 dynamic LDS bytes per workgroup.

The raw replacement is:

```text
kernels/gfx950/sampling/verify/qwen36_argmax_f32_gfx950.s
runtime/gfx950/sampling/verify/qwen36_argmax_f32_bridge.h
runtime/gfx950/sampling/verify/qwen36_argmax_f32_bridge.hip
harness/gfx950/sampling/verify/qwen36_argmax_f32_gfx950.hip
tools/build/build_gfx950_qwen36_argmax_f32.sh
tools/benchmark/validate_gfx950_qwen36_argmax_f32.py
tools/benchmark/profile_gfx950_qwen36_argmax_f32_counters.sh
```

Stage 1 assigns 128 one-wave chunks to each row, giving 2,048 waves at the
measured shape. Each chunk consumes exactly 1,940 FP32 values. Stage 2 uses
one wave per row to reduce the 128 partial keys. Both stages are raw gfx950
AMDGPU assembly and use wave64.

The ordering key reproduces PyTorch `GreaterOrNan<float>`:

- NaN sorts above every ordered value and the first NaN wins;
- `-0` and `+0` compare equal;
- ordered IEEE values, including infinities, preserve numeric order;
- bitwise-not of the index makes the lowest index win every tie.

Both code-object entries declare 52 VGPRs, 20 SGPRs, no AGPRs, no LDS, and no
scratch. Their function text totals 3,984 bytes, 81.25% less than the deployed
specialization. The HSACO SHA-256 is
`6dcf075b0ada1ff795af9bcd71e60359654096aabc0901479eef72aa0dc57643`.

## Validation

The PyTorch oracle passed 197/197 exact cases over row counts 1, 16, and 32,
including random values, cross-chunk ties, signed zero, infinities, NaNs, and
subnormals. A real-checkpoint full-graph shadow run compared raw output with
`torch.argmax` on every same-invocation verification logits tensor and found
no mismatch.

One thousand isolated HIP-event iterations measured:

| Path | Mean |
|---|---:|
| raw two-stage | 7.949 us |
| PyTorch | 56.304 us |
| speedup | 7.083x |

The actual serving trace measured 74.550 microseconds for PyTorch versus
7.878 + 4.428 = 12.306 microseconds for the raw stages, a 6.058x speedup.
Across 20 uncached 210+128 requests per variant, generation latency regressed
against actual dFlash verification calls improved from 9.456968 to 9.392771
milliseconds/call. That 64.197-microsecond end-to-end saving agrees with the
62.244-microsecond GPU saving.

Absolute request medians are not attributed to this kernel because existing
AITER/Triton nondeterminism changed dFlash acceptance and verification counts.
The same-invocation exact shadow and per-verification regression are the
acceptance gates.

## Counters and disassembly

Ten isolated rocprofv3 counter passes are retained under
`profiles/rocprof/isolated_argmax_f32_20260730T231500Z`. Selected stage-1
medians are 2,048 `SQ_WAVES`, 1,552,384 `SQ_INSTS_VALU`, 18,432
`SQ_INSTS_VMEM`, 526,532 `TCC_READ_SECTORS_sum`, and zero
`LDSBankConflict`. Counter collection is intrusive and not latency evidence.

The complete raw/deployed code objects, hashes, metadata, and disassembly are
under
`profiles/disassembly/argmax_deployed_vs_raw_20260730T231600Z`.
The deployed target resolves to rocprof kernel ID 46 and PyTorch fatbin record
122, with target metadata `amdgcn-amd-amdhsa--gfx950`.

Only the exact guarded boundary is promoted. Other vocab sizes, dtypes,
noncontiguous layouts, sampling verification, piecewise graphs, and multi-GPU
fall back to the caller's existing implementation.
