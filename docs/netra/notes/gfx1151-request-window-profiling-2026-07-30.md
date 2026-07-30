# gfx1151 request-window profiling and synchronization inventory — 2026-07-30

All results below are **measured on gfx1151** (AMD Ryzen AI Max+ PRO 395 / Radeon 8060S). The serving case is exact 32,768 input +1 output, zero cached tokens, MXFP4 checkpoint weights, graph disabled, and dFlash disabled.

## Outcome

Two correctness-valid SGLang overlays are accepted:

- `sglang-gfx1151-mamba-track-host-flag.patch` carries authoritative CPU Mamba tracking/alignment metadata into `ForwardBatch` and removes batch-1 GPU truth conversions and dynamic indexing.
- `sglang-gfx1151-gdn-syncfree-chunk-metadata.patch` supplies the existing CPU sequence-length mirror to FLA, builds indices/offsets directly on gfx1151, and reuses the same chunk-index tensor in `chunk_o`.

Clean serving progressed from **21828.363 ms** to **21696.412 ms measured on gfx1151** (1510.3 derived input tok/s), a measured delta of **-131.951 ms** or **1.006082x**. The exact input hash, output token `82`, and output hash match. This small E2E delta is not statistically established; the overlays are retained for correctness, graph-safe host metadata, and the structural reductions proven below.

## Exact synchronization diagnosis

A temporary native interceptor recovered Python frames after long HIP calls. The measured chain was:

1. `prepare_chunk_indices`: `.tolist()` copied one `int32` length from gfx1151 to the host (4-byte D2H) and drained the preceding 8K chunk.
2. Reusing host lengths alone moved the fence to the CPU-built indices' `.to(cu_seqlens)` (1,024-byte H2D at the 8K tier).
3. Building indices on-device exposed `prepare_chunk_offsets` constructing `[0]` through a 4-byte H2D transfer.
4. Passing host lengths through the FLA call chain and reusing the parent chunk-index tensor removed all >100 ms `hipMemcpyWithStream` calls in the final 16K interceptor run.

The accepted rocprofv3 trace reduced `hipMemcpyWithStream` from **29 to 17 calls**, with the maximum falling from multi-second waits to **14.464 ms**. Kernel launches fell from **16,904 to 16,888**, positive launch gaps from **934.620 to 897.084 ms**, and gap occupancy from **4.148% to 3.977%**.

Five `hipEventSynchronize` calls remain. Native stacks place them at `BatchResultProcessor.process_batch_result_prefill -> result.copy_done.synchronize()`. Their CPU durations overlap the GPU critical chain rather than adding to it. Removing the pure-middle-chunk fence was tested separately: 16K/two chunks was correct, but 32K/four queued chunks triggered `HSA_STATUS_ERROR_EXCEPTION` and a HIP launch failure, consistent with unsafe in-flight state or workspace aliasing. That experiment was rejected and fully reverted.

## Complete request-window ranking

This is the latest accepted request-only trace: **22518.294 ms profiler-instrumented E2E**, 16,888 launches, **22556.800 ms** trace wall, **21692.602 ms** kernel time, and **96.169%** kernel occupancy, all measured on gfx1151. Percent is of trace wall time; resources come from rocprofv3 code-object metadata.

| Rank | Kernel | Calls | Mean ms | Total ms | Trace | VGPR | SGPR | LDS | Scratch |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | `extend_attention_wmma_n64_gfx1151` | 40 | 133.798 | 5351.939 | 23.726% | 248 | 128 | 64 KiB | 0 B |
| 2 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` | 360 | 6.761 | 2433.851 | 10.790% | 112 | 128 | 0 KiB | 0 B |
| 3 | `chunk_fwd_kernel_o` | 120 | 15.752 | 1890.291 | 8.380% | 256 | 128 | 0 KiB | 432 B |
| 4 | `mxfp4_prefill_gate_wmma_gfx1151` | 160 | 7.867 | 1258.690 | 5.580% | 112 | 128 | 4 KiB | 0 B |
| 5 | `mxfp4_prefill_down_wmma_gfx1151` | 160 | 7.591 | 1214.514 | 5.384% | 112 | 128 | 0 KiB | 0 B |
| 6 | `recompute_w_u_reuse_a_ordered_gfx1151` | 120 | 10.002 | 1200.212 | 5.321% | 136 | 128 | 16 KiB | 0 B |
| 7 | `mxfp4_prefill_up_silu_wmma_gfx1151` | 160 | 7.319 | 1171.041 | 5.192% | 112 | 128 | 4 KiB | 0 B |
| 8 | `chunk_gated_delta_rule_fwd_kernel_h_blockdim64` | 120 | 8.823 | 1058.776 | 4.694% | 256 | 128 | 0 KiB | 524 B |
| 9 | `chunk_gated_delta_rule_fwd_kkt_solve_kernel` | 120 | 8.093 | 971.136 | 4.305% | 256 | 128 | 0 KiB | 128 B |
| 10 | `rocBLAS/Tensile GEMM` | 40 | 14.281 | 571.258 | 2.533% | 256 | 128 | 50 KiB | 0 B |
| 11 | `ATen BF16 copy` | 765 | 0.683 | 522.808 | 2.318% | 24 | 128 | 0 KiB | 0 B |
| 12 | `expert_weighted_reduce_top8_fp64_gfx1151` | 160 | 2.897 | 463.469 | 2.055% | 40 | 128 | 0 KiB | 0 B |
| 13 | `expert_activation_pack_gfx1151` | 160 | 2.539 | 406.173 | 1.801% | 8 | 128 | 0 KiB | 0 B |
| 14 | `ATen elementwise multiply` | 729 | 0.494 | 359.939 | 1.596% | 24 | 128 | 0 KiB | 0 B |
| 15 | `rocBLAS/Tensile GEMM` | 200 | 1.439 | 287.883 | 1.276% | 256 | 128 | 50 KiB | 0 B |
| 16 | `rocBLAS/Tensile GEMM` | 40 | 6.159 | 246.343 | 1.092% | 256 | 128 | 50 KiB | 0 B |
| 17 | `qkvzba_split_copy_gfx1151` | 150 | 1.423 | 213.449 | 0.946% | 8 | 128 | 0 KiB | 0 B |
| 18 | `__amd_rocclr_copyBuffer` | 831 | 0.246 | 204.630 | 0.907% | 16 | 128 | 0 KiB | 0 B |
| 19 | `ATen pow` | 405 | 0.484 | 195.954 | 0.869% | 16 | 128 | 0 KiB | 0 B |
| 20 | `ATen mean reduction` | 405 | 0.466 | 188.569 | 0.836% | 32 | 128 | 0.5 KiB | 0 B |

The top remaining target is `extend_attention_wmma_n64_gfx1151`: **40 calls, 5351.939 ms total, 23.726% of trace wall, 248 VGPR, 128 SGPR, and 64 KiB LDS**, measured on gfx1151.

## Negative results

- Device-side boolean-index oracle: rejected; 17,244 launches and 85 blocking-copy calls, with no E2E improvement.
- Pinned host-known static-row oracle: rejected; it removed visible copies but not the FLA synchronization chain and did not improve clean E2E.
- Pure-middle-chunk output/fence skip: rejected and reverted; exact 16K passed, but exact 32K caused a gfx1151 hardware exception after four chunks were queued.

## Profiler behavior and signal 6

The repository reorganization had removed the frontend targeted by the ABI-matched wheel's `rocprof-attach` symlink. It is restored at `scripts/rocm/tools/profiling/rocprof_attach.py`, with single-shot signal detach handling.

Live attachment remains rejected: the ABI-matched attempt killed the scheduler with signal 11 and returned status 6; the `/opt/rocm-7.2.1` frontend reported success but emitted no usable trace. The repeated “rocprofv3 caught signal 6” loop is **consistent with** attach/teardown instability after unsafe live attach, but is not claimed as a uniquely proven root cause. The accepted method is process-start rocprofv3 with `--disable-signal-handlers true` and a timed collection window.

## Evidence paths

- Clean baseline: `results/serving/gfx1151/prefill-up-silu-fusion-triton-gdn-32768-plus1-seed20260730-a/request.json`
- Clean accepted result: `results/serving/gfx1151/chunk-metadata-syncfree-32768-plus1-seed20260730-a/request.json`
- Accepted request-only trace: `results/profiles/gfx1151/chunk-metadata-syncfree-windowed-32768-plus1-20260730`
- Native D2H stack: `results/debug/gfx1151/hipcopy-native-trace-16384-plus1-20260730/server.stderr`
- Python-frame copy stacks: `results/serving/gfx1151/hipcopy-python-stack2-16384-plus1-20260730/server.stderr`
- Final no-long-copy interceptor run: `results/serving/gfx1151/chunk-metadata-reuse-intercept-16384-plus1-20260730`
- Rejected four-chunk fence-skip failure: `results/serving/gfx1151/pure-middle-output-skip-32768-plus1-seed20260730-a/server.stderr`
- Machine-readable ledger: `docs/netra/notes/gfx1151-request-window-profiling-2026-07-30.json`
