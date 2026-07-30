# Post-group4-qpipe gfx1151 exact-32K ranked trace (2026-07-30)

This is a measured rocprofv3 process-start trace on gfx1151 for one uncached,
batch-1, exact 32,768-input/+1-output request. Graph and dFlash are disabled;
MXFP4 weights and model-native BF16 operations are unchanged. Host serving E2E
was 22,993.794 ms, cached tokens were zero, output token was 220, and measured
peak VRAM was 101,993,529,344 bytes. Input and output hashes match the qpipe8
baseline trace.

The trace contains 37,723 kernel launches and 137 unique kernels. GPU kernel
time totals 23,136.476 ms across 37,991.278 ms trace wall time. Positive launch
gaps total 14,869.768 ms (median 6.693 us, p90 13.344 us); kernel work occupies
60.899% of trace wall and gaps occupy 39.140%.

## Ranked GPU cost

| Rank | Kernel | Calls | Mean ms | Total ms | Kernel % | Wall % |
|---:|---|---:|---:|---:|---:|---:|
| 1 | `extend_attention_wmma_n64_gfx1151` | 40 | 137.205 | 5,488.215 | 23.721 | 14.446 |
| 2 | `mxfp4_prefill_gate_wmma_gfx1151` | 320 | 8.932 | 2,858.360 | 12.354 | 7.524 |
| 3 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` | 360 | 6.662 | 2,398.492 | 10.367 | 6.313 |
| 4 | `gdn_chunk_o_bv32_gfx1151` | 120 | 11.430 | 1,371.602 | 5.928 | 3.610 |
| 5 | `mxfp4_prefill_down_wmma_gfx1151` | 160 | 7.505 | 1,200.861 | 5.190 | 3.161 |
| 6 | `recompute_w_u_reuse_a_ordered_gfx1151` | 120 | 9.703 | 1,164.411 | 5.033 | 3.065 |
| 7 | `chunk_gated_delta_rule_fwd_kernel_h_blockdim64` | 180 | 5.837 | 1,050.583 | 4.541 | 2.765 |
| 8 | `chunk_gated_delta_rule_fwd_kkt_solve_kernel` | 180 | 5.390 | 970.170 | 4.193 | 2.554 |
| 9 | direct-copy elementwise kernel | 640 | 1.223 | 782.442 | 3.382 | 2.060 |
| 10 | rocBLAS long-prefill GEMM | 40 | 14.308 | 572.310 | 2.474 | 1.506 |
| 11 | BF16 conversion/copy kernel | 1,092 | 0.479 | 523.365 | 2.262 | 1.378 |
| 12 | `expert_weighted_reduce_top8_fp64_gfx1151` | 160 | 2.894 | 463.086 | 2.002 | 1.219 |

The accepted shared-KV attention change reduces rank-1 cost from 6,791.151 to
5,488.215 ms, a measured 1.2374x. Attention remains first by total request cost.
The next independent targets are MXFP4 gate/dense prefill, GDN output/state,
GDN KKT, and high-frequency copy/conversion paths.

## CPU/runtime observations

`hipLaunchKernel` accounts for 17,478 calls and 1,621.882 ms CPU API time;
`hipModuleLaunchKernel` accounts for 6,657 calls and 74.989 ms. The trace also
contains 686 `hipMalloc` calls (98.435 ms), 138 `hipFree` calls (727.510 ms),
and nine `hipEventSynchronize` calls (58.890 ms). These are measured process
totals.

The 11,989 `hipMemcpyWithStream` calls and their 22,395.040 ms CPU total include
server/model startup because rocprofv3 traces the process from launch. They are
not labeled request-only tensor-conversion cost. A request-window marker or a
warm-server attach mechanism is required before attributing that total to
serving orchestration.

Compared with the same-seed qpipe8 trace, total kernel time improves 1.0583x,
trace wall improves 1.0943x, and positive gaps fall 13.084%. Because process
startup is included, only the per-kernel GPU totals are cleanly isolated; host
serving comparisons are separately reported with fresh unprofiled servers.

The profiler wrapper deliberately terminates the traced server after the one
request; rocprofv3 therefore prints `Killed` while still finalizing valid CSVs.
This is not the signal-6 PMC failure. Machine-readable kernel/API rankings are
in `gfx1151-post-group4-qpipe-ranked-full-32k-2026-07-30.json`; raw trace CSVs
remain under `results/profiles/gfx1151/group4-qpipe-full-32k-20260730/`.
