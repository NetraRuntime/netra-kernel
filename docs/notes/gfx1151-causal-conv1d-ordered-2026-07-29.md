# gfx1151 ordered BF16 streaming causal convolution

Status: **accepted and enabled for the exact Qwen3.6 8K prefill shape**. Every number below is measured on gfx1151; no estimate is presented as measurement.

## Replacement and concrete compiler inefficiency

Shape: B=1, T=8192, D=8192, width=4, BF16 input/weight/output/state, SiLU, continuous-batch cache indexing. Triton's `_causal_conv1d_fwd_kernel` assigns an eight-token tile to each program, reloads the three-token overlap, and launches 32,768 workgroups per layer call. The raw kernel assigns one lane to one feature and streams 64 tokens while keeping the rolling three-token window in VGPRs. It launches 8,192 workgroups and uses a second stream-ordered raw kernel for state writeback.

The rejected prototype used FP32 `v_mul`/`v_fmac`, changing Triton's BF16 product-rounding tree by one BF16 ULP. Disassembly showed that gfx1151 Triton lowers each tap as a one-active-lane `v_dot2_bf16_bf16`, returns the rounded BF16 product in the low half, shifts it into FP32, and performs a left-associated four-product sum. `causal_conv1d_stream64_ordered_gfx1151.s` reproduces that exact tree. This is not a packed-two-tap dot product.

## Correctness — gfx1151 measured

The controlled B1/T8192/D8192 test compared 67,108,864 BF16 output elements and the complete updated state cache. Value mismatches: 0. Raw BF16 bit mismatches: 0. State bit mismatches: 0. A ROCm/PyTorch `torch.equal` call returned false despite zero value and bit mismatches; explicit `int16` comparison, NaN counts, and infinity counts were therefore recorded.

A real-checkpoint validation ran raw and Triton for all 30 GDN layers of an 8,192-token request. Each layer reported zero output-bit mismatches and zero state-bit mismatches, including nonzero cache index 6 and `has_initial_state=False`. Direct HIP graph capture/replay with stable pointers matched eager output and state bit-for-bit.

## HIP events and rocprofv3 — gfx1151 measured

| Implementation | Calls | Total GPU ms | Mean us | Median us |
|---|---:|---:|---:|---:|
| Triton long-prefill conv | 120 | 1303.633029 | 10863.609 | 10856.896 |
| ordered raw conv | 120 | 166.052669 | 1383.772 | 1383.339 |
| ordered raw state writeback | 120 | 0.178491 | 1.487 | 1.442 |
| ordered raw pair | 120 | 166.231160 | 1385.260 | — |

Measured request-shape GPU reduction: 1137.401869 ms, **7.84229x** for the replaced long-prefill pair. The controlled HIP-event pair measured 1.394898 ms raw versus 10.795752 ms Triton, **7.73946x**.

The raw conv has 32 profiler VGPRs, 128 profiler SGPRs, zero LDS, zero scratch, and 32,768 waves. Pure ROCm 7.2.1 HIP counter passes measured 96.089033% occupancy, 61.858593 mean occupancy per active CU, 69,353.375 KiB fetch, 65,103.750 KiB write, 33.472447% L2 hit, 99.145786% memory-unit busy, and zero LDS bank conflicts. Direct dependency-stall percentage is unavailable in the gfx1151 metric set and is not estimated.

## Exact serving — gfx1151 measured

Both pairs are exact 32,768 input +1 output, uncached, batch 1, graph disabled, dFlash disabled.

| State | Pair A ms / token | Pair B ms / token | Mean ms |
|---|---:|---:|---:|
| contemporaneous Triton baseline | 27279.751504 / 248045 | 26901.914056 / 220 | 27090.832780 |
| ordered raw convolution | 25802.060901 / 248045 | 25955.106171 / 220 | 25878.583536 |

Measured host reduction: 1212.249244 ms, **1.046844x**, or 4.474758%. Peak VRAM was 72,933,638,144 bytes baseline and 72,046,575,616 bytes raw in these sysfs-sampled runs.

One preliminary raw Pair B run returned token 0. The change was not accepted at that point. All-layer dual execution then proved bit-exactness; an accidental dead dispatch block in the separate update function was removed, and a clean raw process returned the baseline token 220. The clean paired results above are the accepted evidence.

## Integration and evidence

The HIP bridge preloads both HSACOs before capture and uses `hipModuleLaunchKernel` on the current stream. The custom op mutates only the preallocated output and state, has no `.item()` call, and falls back to Triton outside the exact shape. Production source, state-write ASM, SGLang patch, build integration, correctness harness, counter harness, graph test, process-start trace, serving JSON, and before/after disassembly ship together.

Evidence paths:

- `results/profiles/gfx1151/causal-conv1d-ordered-full-32k/`
- `results/profiles/gfx1151/causal-conv1d-ordered-counters-hip72-20260729/summary.json`
- `results/serving/gfx1151/causal-conv1d-ab-20260729/`
- `docs/notes/disassembly/causal-conv1d-ordered-gfx1151/`
