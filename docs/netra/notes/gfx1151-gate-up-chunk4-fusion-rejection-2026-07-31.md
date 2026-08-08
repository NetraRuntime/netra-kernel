# gfx1151 routed gate/up chunk4 fusion rejection — 2026-07-31

All results are for AMD Ryzen AI Max+ PRO 395, `gfx1151`. GPU claims use HIP
events or rocprofv3. Serving claims use streaming host wall time. Derived values
are labeled explicitly.

## Decision

Reject the experimental routed-expert gate/up chunk4 fusion from production.
Keep its raw AMDGCN sources and harness as a negative fusion result, but do not
build, preload, register, or launch them in the accepted runtime.

The experiment tests selected-experts=8, N=512, K=2048. One raw wave32 kernel
computes gate and up partials from shared activations. A second raw kernel keeps
the accepted chunk4 reduction order and applies SiLU and gate-times-up. It
reduces the stage from five launches to two without changing MXFP4 weights.

| gfx1151 code object | SHA-256 | status |
|---|---|---|
| baseline gate/up compute | `7ebefa5aa26bc14d8148fe7661ecb13a90b164c8792a1d58ef70018baeabad14` | measured |
| fused gate/up compute | `8fd6a67f86202befdaf08462da5605b9d15e0a4cd1e4830f95901fd6589fc850` | rejected |
| baseline chunk4 reducer | `7a4478e57d2a7d0dafc10c08c032947be4db0075475055b8957600802dc62622` | measured |
| fused reducer + SiLU | `4d19232971bfe54555416f2f4b4f9d6753663c479ca55e1c98f03e17e2224a03` | rejected |
| baseline SiLU | `4baaace32626351388370c30336dddd44429b9cd8106446c502ef834c5a8d007` | measured |

The fused compute uses grid `(1,128,1)`, workgroup 128, a 56-byte seven-pointer
kernarg, 48 allocated VGPRs, 128 allocated SGPRs, zero LDS, and zero scratch.
The fused reducer uses grid `(2,8,1)`, workgroup 128, a 16-byte kernarg, 24
allocated VGPRs, 128 allocated SGPRs, zero LDS, and zero scratch. These
experimental ABIs were never added to the accepted public C ABI.

## Correctness and cache-hot HIP events

Synthetic inputs and real checkpoint weights from layers 0, 10, 20, and 30,
experts 0 through 7, produced byte-identical gate and up partials and zero BF16
output mismatches.

| gfx1151 measured weights | baseline five launches | candidate two launches | speedup |
|---|---:|---:|---:|
| synthetic | 29.520 us | 19.852 us | 1.4870x |
| real layer 0 | 29.485 us | 19.780 us | 1.4906x |
| real layer 10 | 29.385 us | 19.649 us | 1.4955x |
| real layer 20 | 29.392 us | 19.700 us | 1.4920x |
| real layer 30 | 29.443 us | 19.754 us | 1.4904x |

These cache-hot results prove correctness and best-case launch reduction, not
production acceptance.

## Complete-request trace

Matched traces used exact 1 input + 32 output, cached tokens 0, eager execution,
and dFlash disabled. rocprofv3 signal handlers were disabled; no signal-6 loop
occurred.

| gfx1151 measured routed gate/up stage | accepted separate | fused candidate | change |
|---|---:|---:|---:|
| compute invocations | 2,574 | 1,285 | -50.08% |
| compute GPU total | 83.774 ms | 94.795 ms | +13.15% |
| reducer GPU total | 4.239 ms | 2.776 ms | -34.52% |
| standalone SiLU GPU total | 1.599 ms | 0 ms | -100% |
| complete stage GPU total | 89.613 ms | 97.571 ms | +8.88% |

The fused compute carries both weight streams in a 48-VGPR wave versus separate
40-VGPR waves. Under the cold, rotating 35B working set, the extra live state and
two-stream memory demand reduce memory-level parallelism. The 11.021 ms compute
regression exceeds the reducer and SiLU savings.

| gfx1151 measured complete trace | accepted separate | fused candidate | change |
|---|---:|---:|---:|
| host request wall | 860.873 ms | 866.111 ms | +0.608% |
| summed kernel GPU time | 767.885 ms | 782.024 ms | +1.841% |
| positive launch gaps | 95.742 ms | 87.770 ms | -8.327% |
| GPU launches | 31,444 | 27,551 | -12.381% |
| kernel/wall occupancy | 89.198% | 90.291% | +1.093 points |
| gap/wall occupancy | 11.121% | 10.134% | -0.988 points |

The candidate removes 3,893 measured launches and 7.972 ms of positive gaps,
but added GPU work cancels the savings. This is a concrete negative result for
launch-count-only fusion on gfx1151.

## End-to-end serving gate

Five production samples used exact 1 input + 128 output, cached tokens 0, batch
1, eager execution, and dFlash disabled. All five output hashes matched.

| gfx1151 measured median | accepted separate | fused candidate | change |
|---|---:|---:|---:|
| TTFT | 59.269 ms | 59.402 ms | +0.225% |
| decode wall | 3169.604 ms | 3177.392 ms | +0.246% |
| output throughput | 40.068 tok/s | 39.970 tok/s | -0.245% |
| E2E wall | 3227.876 ms | 3236.174 ms | +0.257% |

The candidate fails the end-to-end value gate. The accepted launcher, runtime
descriptors, workspace, Python bridge, and SGLang integration were restored and
rebuilt. The candidate is absent from production preload and capture paths.

## Evidence

- Raw experiments: `kernels/gfx1151/mxfp4/decode/experiments/mxfp4_decode_gate_up_chunk4_fused_gfx1151.s` and `mxfp4_decode_gate_up_chunk4_reduce_silu_gfx1151.s`
- Harness: `scripts/rocm/harness/gfx1151/mxfp4/benchmark_decode_gate_up_chunk4_fused.hip`
- Accepted trace: `results/profiles/gfx1151/attn-oproj-wide128-qkv-wide128-shared-wide128-complete-eager-b1-1-plus32-20260731`
- Candidate trace: `results/profiles/gfx1151/gate-up-chunk4-fused-attn-oproj-qkv-shared-wide128-complete-eager-b1-1-plus32-20260731`
- Serving A/B: the corresponding `results/serving/gfx1151/*eager-1-plus128-20260731` directories
- Disassembly and metadata: `docs/netra/notes/gfx1151-gate-up-chunk4-fusion-rejection-disassembly-2026-07-31/`
