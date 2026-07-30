# Post-qpipe8 gfx1151 exact-32K ranked trace (2026-07-30)

This is a measured rocprofv3 process-start trace on gfx1151 for one uncached,
batch-1, exact 32,768-input/+1-output request. Graph and dFlash are disabled;
MXFP4 weights and model-native BF16 operations are unchanged. Host serving E2E
was 24,324.723 ms, cached tokens were zero, output token was 220, and measured
peak VRAM was 101,487,054,848 bytes.

The trace contains 37,723 kernel launches and 137 unique kernels. GPU kernel
time totals 24,486.024 ms across 41,574.278 ms trace wall time. Positive launch
gaps total 17,108.147 ms (median 6.693 us, p90 13.587 us); kernel work occupies
58.897% of trace wall and gaps occupy 41.151%.

## Ranked GPU cost

| Rank | Kernel | Calls | Mean ms | Total ms | Kernel % | Wall % |
|---:|---|---:|---:|---:|---:|---:|
| 1 | `extend_attention_wmma_n64_gfx1151` | 40 | 169.779 | 6,791.151 | 27.735 | 16.335 |
| 2 | `mxfp4_prefill_gate_wmma_gfx1151` | 320 | 8.931 | 2,858.054 | 11.672 | 6.875 |
| 3 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` | 360 | 6.671 | 2,401.654 | 9.808 | 5.777 |
| 4 | `gdn_chunk_o_bv32_gfx1151` | 120 | 11.428 | 1,371.415 | 5.601 | 3.299 |
| 5 | `recompute_w_u_reuse_a_ordered_gfx1151` | 120 | 10.119 | 1,214.305 | 4.959 | 2.921 |
| 6 | `mxfp4_prefill_down_wmma_gfx1151` | 160 | 7.507 | 1,201.188 | 4.906 | 2.889 |
| 7 | `chunk_gated_delta_rule_fwd_kernel_h_blockdim64` | 180 | 5.835 | 1,050.379 | 4.290 | 2.527 |
| 8 | `chunk_gated_delta_rule_fwd_kkt_solve_kernel` | 180 | 5.387 | 969.626 | 3.960 | 2.332 |
| 9 | direct-copy elementwise kernel | 640 | 1.236 | 791.282 | 3.232 | 1.903 |

The raw attention kernel remains the first optimization target by total request
cost, not merely by individual latency. The next independent targets are MXFP4
MoE/dense prefill, GDN output/state paths, and high-frequency copy/conversion
kernels.

## CPU/runtime observations

`hipLaunchKernel` accounts for 17,478 calls and 1,618.909 ms CPU API time;
`hipModuleLaunchKernel` accounts for 6,657 calls and 74.471 ms. The trace also
contains 686 `hipMalloc` calls (60.513 ms), 138 `hipFree` calls (728.939 ms),
and nine `hipEventSynchronize` calls (59.652 ms). These are measured process
totals.

The 11,989 `hipMemcpyWithStream` calls and their 25,701.866 ms CPU total include
server/model startup because rocprofv3 traces the process from launch. They are
not labeled request-only tensor-conversion cost. A request-window marker or a
warm-server attach mechanism is required before attributing that total to
serving orchestration.

The profiler wrapper deliberately terminates the traced server after the one
request; rocprofv3 therefore prints `Killed` while still finalizing valid CSVs.
This is not the signal-6 PMC failure. Machine-readable kernel/API rankings are
in `gfx1151-post-qpipe8-ranked-full-32k-2026-07-30.json`; raw trace CSVs remain
under `results/profiles/gfx1151/post-qpipe8-ranked-full-32k-20260730/`.
