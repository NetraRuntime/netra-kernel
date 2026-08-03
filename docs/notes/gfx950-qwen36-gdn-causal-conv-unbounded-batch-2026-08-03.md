# Qwen3.6 gfx950 GDN causal convolution: unbounded-batch bridge

## Decision

Accept the capacity correction for the already-shipped raw gfx950 M=12 causal
convolution.  Do not claim a new end-to-end speedup: the paired current-stack
serving result was performance-neutral (+0.12%).  The change is required because
the previous bridge rejected batch 256 during graph capture even though the raw
assembly grid and address arithmetic are batch-generic.

The Qwen checkpoint remained FP8 E4M3 with 128x128 weight blocks and FP8 E4M3
KV cache.  The convolution inputs, state, weights, output, and speculative
window remained model-native BF16.

## Changes

- Remove the artificial B64 ceiling from the HIP dispatch bridge.
- Export `netra_qwen36_gdn_causal_conv_m12_batch_capacity`; `UINT32_MAX`
  explicitly denotes an unbounded bridge contract.
- Keep batch bounds in the raw assembly through its scalar `batch` kernarg and
  exact `batch * 32` workgroup grid.
- Mark the build as `shape=B1+,M12,D8192,W4` and verify the capacity symbol.
- Extend the real-checkpoint harness with graph batch size, live batch, and
  high cache-slot offsets.

## Real-checkpoint correctness and HIP-event timing

All runs were on one MI350X (`gfx950:sramecc+:xnack-`) using layer-0 weights
from the pinned Qwen FP8 checkpoint.

| Case | Raw median | Triton median | Result |
|---|---:|---:|---|
| B256, 256 live | 76.261 us | 110.162 us | output/state/window bit-exact |
| B256 graph, 64 live, slots 961-1024 | 22.060 us | n/a | live tensors bit-exact; 192 padded outputs untouched |

The B256 all-live comparisons covered 25,165,824 output values, 6,291,456
final-state values, and 75,497,472 intermediate-window values with zero
mismatches.  The padded case also exercises the widened state/window address
math at the last valid slot of the 1025-slot serving cache.

Artifacts:

- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260803T171000Z-gdn-conv-b256-capacity-gpu6/all-live-b256.json`
- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260803T171000Z-gdn-conv-b256-capacity-gpu6/padded-b256-live64-offset961.json`

## Current-stack serving A/B

Piecewise graphs, dFlash M12, FP8 KV, 69,632 context, concurrency 64, exactly
1,024 input and 1,024 forced output tokens, 192 requests per seed:

| Seed | Triton control | Raw gfx950 | Delta | Acceptance control/raw |
|---|---:|---:|---:|---:|
| 20260803 | 5,857.58 tok/s | 5,839.02 tok/s | -0.32% | 4.234 / 4.192 |
| 20260804 | 6,191.89 tok/s | 6,224.87 tok/s | +0.53% | 4.246 / 4.236 |
| Mean | 6,024.73 tok/s | 6,031.94 tok/s | +0.12% | 4.240 / 4.214 |

Every run completed 192/192 requests and generated exactly 196,608 output
tokens.  The isolated kernel is bit-exact, while the complete stack retains
known nondeterministic routed-MoE accumulation, so small cross-process token and
acceptance variation is not attributed to this convolution.

Control:
`/data/netra/benchmarks/gfx950_qwen36_optimization/20260803T164500Z-currentstack-gdn-conv-control-gpu6`

Candidate:
`/data/netra/benchmarks/gfx950_qwen36_optimization/20260803T175000Z-currentstack-gdn-conv-raw-capacity-wired-gpu6`

## Next target

The corrected torch trace attributes 1.918% of kernel time to the standalone
Triton causal update and 1.797% to the adjacent QKVZ/BA split/reshape/copy.
The standalone replacement is now below serving noise.  The next implementation
target is a raw gfx950 fusion of that producer with the M12 convolution so the
launch, intermediate tensor traffic, and layout materialization are removed.
