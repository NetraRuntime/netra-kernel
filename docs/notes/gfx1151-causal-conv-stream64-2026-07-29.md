# gfx1151 streaming causal-convolution prototype (rejected pending bit-exact lowering)

Status: **not enabled in production**. All numbers are measured on gfx1151 unless explicitly marked estimated.

## Why it was targeted

The exact 32,768-token process-start trace contains 120 large `_causal_conv1d_fwd_kernel` calls (four 8,192-token chunks across 30 GDN layers) totaling 1,313.526 ms, with 10.946 ms mean. The 30 decode-size calls total only 0.101 ms. The large Triton launch uses 32,768 workgroups per layer call (`grid=128x1024x32`, `workgroup=128`) and 72 VGPRs.

Triton's 8-token tile reloads a three-token overlap. The raw prototype assigns one lane to one feature and streams 64 tokens while retaining the width-4 rolling window in VGPRs. Its grid has 8,192 workgroups (`64x128`, workgroup 128), 25 VGPRs, 25 SGPRs, no LDS, and no scratch. A second raw kernel performs stream-ordered, exact state-cache writeback.

## Exact-shape result

Shape: B=1, T=8192, D=8192, W=4; BF16 input/weight/output/state; SiLU; initial-state and cache-index handling enabled.

| gfx1151 implementation | HIP-event median | output max abs vs Triton | state max abs |
|---|---:|---:|---:|
| Triton oracle | 10.776091 ms | reference | reference |
| raw stream64 + raw state writeback | 1.400832 ms | 0.0009765625 | 0.0 |

Measured kernel-pair speedup: **7.6926x**. Mean output absolute error was `4.4520e-05`; the state cache was bit-exact. A faster reciprocal-only epilogue measured 1.373580 ms, but the retained source uses the IEEE division refinement lowered by Triton.

## Dispatch finding and real checkpoint

The first attempted SGLang hook produced zero raw calls because ROCm followed the direct Triton import: the wrapper import was guarded by `is_cuda()` rather than `is_cuda() or is_hip()`. That negative trace is `results/profiles/gfx1151/causal-conv-stream64-32k-start`; its 1,321.106 ms of compiler conv time is not a raw-kernel result.

After correcting the temporary HIP dispatch, exact uncached 32,768-input/+1-output serving, graph disabled and dFlash disabled, measured:

| build | prompt | host E2E | greedy token |
|---|---|---:|---:|
| established generic | pair-a | 29,930.237 ms | 220 |
| raw conv | pair-a | 28,868.209 ms | 220 |
| established generic | pair-b | 29,806.921 ms | 96043 |
| raw conv | pair-b | 28,728.771 ms | 3709 |

The raw path delivered the expected ~1.07 s host benefit, but pair-b changed its deterministic greedy token. A one-BF16-ULP layer error is therefore not acceptable for this model's sensitive logit boundary. Production build files, the HIP bridge, and SGLang dispatch were restored to Triton. No serving speedup is accepted or claimed.

The retained raw ASM and harness are:

- `kernels/gfx1151/gdn/experiments/causal_conv1d_stream64_gfx1151.s`
- `kernels/gfx1151/gdn/experiments/causal_conv1d_state_update_gfx1151.s`
- `harness/gfx1151/gdn/causal_conv1d_stream64_launcher.hip`
- `tools/benchmark/benchmark_causal_conv1d_stream64.py`

Disassemblies are in `docs/notes/disassembly/causal-conv-gfx1151/`. Future work should reproduce Triton's packed BF16 dot/rounding order exactly before repeating the real-checkpoint gate.

## Superseded by accepted ordered revision

The rejected FP32-FMA prototype remains as negative evidence. The later `causal_conv1d_stream64_ordered_gfx1151` revision reproduces Triton's per-tap BF16 dot rounding, passes controlled and real-checkpoint bit-exact gates, and is enabled in production. See `gfx1151-causal-conv1d-ordered-2026-07-29.md`.
