# Qwen3.6 M=210/N=2048/K=4096 FP8 projection

Status: accepted for eager single-GPU integration on MI350X/gfx950.

## Exact workload

- Real checkpoint: `Qwen3.6-35B-A3B-FP8`, FP8 E4M3 weights with
  128x128 scales.
- Shape: `M=210, N=2048, K=4096`.
- Frequency: 40 calls in an uncached exact 210-token prefill.
- Captured ABI: FP8 input `[210,4096]`, transposed FP32 activation scales
  `[210,32]`, AITER-preshuffled FP8 weights `[2048,4096]`, FP32 weight scales
  `[16,32]`, and BF16 output `[210,2048]`.
- The captured deployed output and a fresh CKTile output have the identical
  SHA-256 `e5b68423d4fbcd75251bf9d28e17881a9d258a2e96c3c851a12bd010e3635ce5`.

## Raw gfx950 design

`qwen36_dense_m210_k4096_fp8_mfma_m32n32_gfx950.s` uses one wave64 per
32x32 output tile and four independent
`v_mfma_f32_16x16x128_f8f6f4` chains. Each activation and weight fragment is
reused across two MFMA chains. The 32 K blocks are reduced in fixed order.
There is no LDS, barrier, split-K, atomic, scratch, or intermediate workspace.

The K=2048 M32xN32 topology was retained only after re-deriving the K=4096
activation row stride, preshuffled weight N-tile stride, scale-row stride, and
loop trip count from the captured tensors. No gfx1151/wave32 assumptions are
used.

Code-object metadata declares gfx950, wave64, 106 VGPRs, 34 SGPRs, zero LDS,
and zero scratch. The launch is `grid=(64,7,1)`, `block=(64,1,1)`.

## Correctness

- 0/430,080 BF16 mismatches against CKTile.
- 200/200 eager launches produced one output hash.
- 200/200 HIP graph replays produced one output hash and matched eager.
- Output canary: 0/4,096 modified bytes.
- FP32 dequantized oracle: maximum absolute error `0.0019269`, mean absolute
  error `1.45103e-05`, cosine `0.999999`.
- Real SGLang shadow validation: 120/120 K=4096 layer calls passed bit-for-bit
  across three exact 210-input/1-output requests. The full 80-call raw path
  retained deterministic token hash
  `991a26ff4edaa7d5244848d1b20fa4c667589de6f83f6e38b45c763f8bee10eb`.

## Performance

HIP-event medians over 200 identical captured launches:

| implementation | median |
|---|---:|
| AITER CKTile | 58.841 us |
| raw gfx950 bridge | 21.480 us |

The isolated speedup is 2.739x. A same-GPU eager A-B-A serving bracket,
replacing this family and the previously accepted K=2048 M=210 families,
reduced warmed median 210-to-1 TTFT from 98.988 ms to a 97.687 ms bracket
mean: 1.301 ms, 1.315%, or 1.0133x. All 57 warmed raw samples and 19 warmed
control samples retained the same token hash.

## Counter evidence

For each 448-wave dispatch, rocprofv3 reports exactly 57,344 MFMA
instructions (`448 waves * 32 K blocks * 4 MFMA`). A representative dispatch
also records 656,512 VALU, 141,376 SALU, and 232,192 VMEM instructions.
The TCC pass records 121,552 read requests and 13,440 write requests; the
cache pass records 617,592 hits and 134,712 misses (82.09% hit fraction).

The counter passes are separate because the larger combined TCC counter set
previously failed to finalize reliably on this profiler build.

## Evidence

- Capture and isolated artifacts:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z/kernel_experiments/qwen36_m210_n2048_k4096_capture_20260731T0745Z`
- Real-layer shadow:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z/correctness/eager_dense_m210_all_shadow_gpu0_20260731T0810Z`
- Serving A-B-A:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z/performance/eager_m210_all_raw_gpu0_20260731T0830Z/m210-all-eager-aba-comparison.json`

Full-graph and piecewise-graph serving promotion remain separate gates.
