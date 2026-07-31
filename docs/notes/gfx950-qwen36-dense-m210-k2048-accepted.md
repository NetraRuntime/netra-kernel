# gfx950 Qwen3.6 dense M=210 K=2048 block-FP8 kernel

Status: accepted for real-layer shadow validation and SGLang integration.

The deployed operands are Qwen FP8 E4M3 weights with 128x128 weight scales,
per-row 1x128 dynamically quantized FP8 E4M3 activations, and BF16 output.
No checkpoint conversion or fallback is present.

## Real request inventory

An uncached exact 210-token prefill contains:

| Shape | Calls/request | Projection family |
|---|---:|---|
| M=210, N=12288, K=2048 | 30 | GDN QKVZ |
| M=210, N=9216, K=2048 | 10 | full-attention QKV |
| M=210, N=2048, K=4096 | 40 | output projections; separate unfinished kernel |

The accepted raw source is:

`kernels/gfx950/fp8/dense/prefill/qwen36_dense_m210_k2048_fp8_mfma_m32n32_gfx950.s`

It targets `amdgcn-amd-amdhsa--gfx950`, wave64, and uses
`v_mfma_f32_16x16x128_f8f6f4`. One wave computes an M32xN32 tile as four
independent 16x16 MFMA chains. A and B fragments are each reused twice. The
K=2048 reduction is fixed at 16 ordered K blocks with no split-K, atomics,
LDS, or scratch. A by-value output-stride kernarg allows the same code object
to cover N=9216 and N=12288.

## Correctness and timing

All measurements used real-checkpoint operands captured from the pinned Qwen
checkpoint and HIP events on MI350X/gfx950.

| N | BF16 mismatch vs CKTile | Repeats | Graph replay | Raw bridge median | CKTile replay median | Speedup |
|---:|---:|---:|---|---:|---:|---:|
| 12288 | 0 / 2,580,480 | 200/200 identical | exact | 37.081 us | 46.207 us | 1.246x |
| 9216 | 0 / 1,935,360 | 200/200 identical | exact | 28.761 us | 45.760 us | 1.591x |

Both validators also passed a 4 KiB post-output canary. The N=12288 maximum
absolute difference from the separately dequantized FP32 matmul oracle was
0.0893173 with cosine similarity 0.999999. The N=9216 values were 0.0310678
and 0.999999. Acceptance requires the stronger bit-exact CKTile comparison.

## Code-object and counter evidence

The production code object metadata records gfx950, wave64, 106 VGPRs,
34 SGPRs, zero LDS, and zero scratch. The retained disassembly contains the
raw MFMA instructions and no compiler-generated compute kernel.

A selected rocprofv3 N=12288 dispatch reported:

| Counter | Value |
|---|---:|
| `SQ_INSTS_MFMA` | 172,032 |
| `SQ_INSTS_VALU` | 2,052,864 |
| `SQ_INSTS_SALU` | 436,608 |
| `SQ_INSTS_VMEM` | 717,312 |
| `SQ_WAVE_CYCLES` | 37,523,578 |
| `SQ_BUSY_CU_CYCLES` | 15,763,728 |

The exact MFMA count is 2,688 waves x 16 K blocks x 4 MFMAs. A combined
eight-counter TCC pass hung in profiler finalization after GPU work had
completed and was terminated after five minutes. It is not used for an HBM
claim; smaller TCC passes remain pending.

## Variant ledger

| Variant | Median | Decision |
|---|---:|---|
| one wave, M16xN16 | 66.239 us | rejected: redundant A/B traffic |
| four waves, B shared through 2 KiB LDS | 63.275 us | rejected: barrier/LDS overhead |
| one wave, M32xN16 | 56.920 us | rejected: insufficient column reuse |
| M32xN16 software prefetch | 56.921 us | rejected: no measurable gain |
| one wave, M32xN32 | 36.861 us direct | accepted topology |

The raw rejected sources remain under
`kernels/gfx950/fp8/dense/prefill/experiments/`.

## Reproduction artifacts

Root:

`/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z/kernel_experiments/qwen36_m210_k2048_raw_capture_20260731T063611Z`

Important subdirectories include `capture-gdn-qkvz`, `capture-attn-qkv`,
`production-build`, `rocprofv3-raw-n12288`, and
`rocprofv3-counters-raw-n12288`.

The next gates are all-layer real-checkpoint shadow validation, stable greedy
tokens/KV/GDN/router state, eager and graph serving impact, and replacement
of the remaining M=210,N=2048,K=4096 CKTile path.
