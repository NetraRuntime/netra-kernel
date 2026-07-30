# gfx1151 bounded-anchor attention: measured negative (2026-07-30)

## Decision

Reject the raw `anchor1` kernel for production on gfx1151. It reduces dynamic
VALU work and is slightly faster in isolated long-prefix HIP-event tests, but
it is not bit-identical, increases error against an FP64 reference at
model-like Q/K amplitudes, and improves paired exact 32K/+1 serving by only
0.0905%. The accepted bit-stable N64 kernel was restored after testing.

All numbers below are measured on gfx1151. No estimated speedups are reported.

## Experiment

The candidate retains each row's online-softmax anchor until a later tile
maximum exceeds it by 1.0. Between re-anchors, `alpha` is exactly one and the
kernel skips all 128 output-accumulator rescale multiplies. Re-anchoring keeps
probabilities bounded by approximately `exp(1)` rather than allowing an
unbounded fixed-anchor sum.

The final compute candidate is raw AMDGCN assembly:

- `scripts/rocm/kernels/gfx1151/attention/experiments/extend_attention_wmma_n64_group4_qpipe_kvbatch16_anchor1_gfx1151.s`

The baseline is the accepted raw gfx1151 kernel:

- `kernels/gfx1151/attention/extend_attention_wmma_n64_gfx1151.s`

Both use grid `(M/64, 4, 1)`, block 512, 64 KiB LDS, 248 allocated VGPRs,
128 allocated SGPRs, and no scratch.

## Isolated HIP-event result

Shape: `M=8192`, `Hq=16`, `Hkv=2`, `D=256`, BF16, page size 1. Each row is the
median of 21 alternating A/B measurements with a shared output allocation.

| Prefix | Baseline (ms) | anchor1 (ms) | Speedup |
|---:|---:|---:|---:|
| 0 | 34.5761 | 34.5092 | 1.00194x |
| 8,192 | 100.0725 | 99.5267 | 1.00548x |
| 16,384 | 166.8456 | 165.8522 | 1.00599x |
| 24,576 | 234.0766 | 232.5898 | 1.00639x |
| Four-tier sum | 535.5709 | 532.4779 | 1.00581x |

Outputs were not bit-identical. With the low-amplitude benchmark distribution,
the maximum baseline/candidate delta was `6.1035e-05`.

## rocprofv3 evidence

One counter was collected per fresh process with
`--disable-signal-handlers true` at `M=8192`, prefix 24,576:

| Counter | Baseline | anchor1 | Change |
|---|---:|---:|---:|
| `VALUInsts` | 878,687.5 | 832,171.5 | -5.2938% |
| `FETCH_SIZE` (KiB) | 19,059,261.25 | 19,063,315.125 | +0.0213% |

The sampled `OccupancyPercent` values were invalid (>100%) and
`SQ_WAVE_CYCLES` saturated to the same value, so neither is used for a claim.
The direct dependency-stall counter is not exposed for gfx1151 by this
rocprofv3 metric set.

The result indicates that output rescaling is not the primary limiter: removing
5.29% of dynamic VALU instructions produces only a 0.58% four-tier reduction.
K/V movement, LDS traffic, WMMA issue, or their dependency schedule remains the
dominant constraint.

## FP64 correctness

The reference uses the exact BF16 Q/K/V inputs converted to FP64, FP64 QK,
causal mask, FP64 softmax, and FP64 PV. At `M=256`, prefix 128:

| Q/K amplitude | Baseline RMSE | anchor1 RMSE | Relative change |
|---:|---:|---:|---:|
| 0.02 | 1.31447e-4 | 1.28451e-4 | -2.28% |
| 1.0 | 2.28825e-4 | 2.37507e-4 | +3.79% |
| 2.0 | 1.04139e-3 | 1.07881e-3 | +3.59% |

Amplitude 1.0 is the more relevant normalized-Q/K stress than the legacy 0.02
microbenchmark distribution. The candidate's absolute error remains small, but
the regression is consistent and the end-to-end gain is too small to justify
changing softmax rounding behavior.

## Real-checkpoint serving

Exact 210 input +128 output, seed 7702, uncached, graph disabled, dFlash
disabled: all 128 greedy output IDs matched the accepted baseline.

Exact 32,768 input +1 output, seed 20260730, uncached, graph disabled, dFlash
disabled:

| Pair | Baseline host E2E (ms) | anchor1 host E2E (ms) | Delta (ms) |
|---:|---:|---:|---:|
| 1 | 21,705.2527 | 21,679.2622 | -25.9905 |
| 2 | 21,704.9311 | 21,691.6791 | -13.2520 |
| Mean | 21,705.0919 | 21,685.4706 | -19.6213 |

Both candidate runs returned the same token `82` as their paired baseline.
The measured mean serving speedup is only 1.000905x and is not treated as a
statistically established production improvement.

Machine-readable evidence is in
`docs/netra/notes/gfx1151-attention-anchor1-negative-2026-07-30.json`; complete
before/after disassembly and its diff are in
`docs/netra/notes/gfx1151-attention-anchor1-negative-disassembly-2026-07-30/`.

## Reproduction

Run inside the Netra LXC:

```bash
bash scripts/rocm/tools/build/build_extend_attention_anchor1_experiment.sh
python scripts/rocm/tools/benchmark/validate_extend_attention_fp64.py \
  --baseline-library build/experiments/attention-anchor1/libextend_attention_baseline.so \
  --baseline-hsaco build/experiments/attention-anchor1/extend_attention_wmma_n64_gfx1151.hsaco \
  --candidate-library build/experiments/attention-anchor1/libextend_attention_candidate.so \
  --candidate-hsaco build/experiments/attention-anchor1/extend_attention_wmma_n64_group4_qpipe_kvbatch16_anchor1_gfx1151.hsaco \
  --candidate-label anchor1 --tokens 256 --prefix 128
bash scripts/rocm/tools/profiling/profile_extend_attention_anchor1_counters.sh
python scripts/rocm/tools/benchmark/benchmark_extend_attention_variants_shared_output.py \
  --baseline-library build/experiments/attention-anchor1/libextend_attention_baseline.so \
  --baseline-hsaco build/experiments/attention-anchor1/extend_attention_wmma_n64_gfx1151.hsaco \
  --candidate-library build/experiments/attention-anchor1/libextend_attention_candidate.so \
  --candidate-hsaco build/experiments/attention-anchor1/extend_attention_wmma_n64_group4_qpipe_kvbatch16_anchor1_gfx1151.hsaco \
  --candidate-label anchor1 --tokens 8192 \
  --prefix 0 8192 16384 24576 --warmup 5 --repetitions 21 --interleaved
```
