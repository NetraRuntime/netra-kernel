# gfx1151 fusion ledger (2026-07-29)

This ledger distinguishes gfx1151 measured results from untested candidates. MXFP4 weights remain MXFP4 throughout.

| Candidate | Status | gfx1151 evidence | Decision / next gate |
|---|---|---|---|
| GDN QKVZ + BA decode projection | Accepted — gfx1151 measured kernel and serving | Real-checkpoint raw-ASM HIP-event median fell from 0.199833 ms for two dispatches to 0.108543 ms for one padded dispatch, a measured 1.841x speedup. Output is bit-exact to separate raw ASM; staged-FP64 max BF16 absolute error 0.001953125 and normalized L2 2.53e-5. Uncached full-graph 1/+32 median improved 1,944.784 to 1,800.900 ms (1.0799x), and 210/+128 improved 8,033.376 to 7,455.958 ms (1.0774x). | Retained only for M=1. Fixed 1/+32 output hashes match the pre-fusion graph. Prefill keeps separate exact-shape kernels to avoid 448 padded outputs. |
| GDN QKVZ/BA split + reshape + copy | Accepted — gfx1151 measured kernel, serving, and graph | Hand-written raw ASM is bit-exact at M1/M64/M210/M8192 and improves M8192 HIP-event median from 12.437 to 1.772 ms (7.0195x). Uncached 8,192/+1 median improves 7,073.980 to 6,761.489 ms (1.0462x); matched 32,768/+1 improves 35,399.053 to 34,114.981 ms (1.0376x). | Retained for the fixed Qwen3.6 12288/64 layout. M210 serving is neutral. Native M64 `tc_piecewise` capture/replay passes after graph-safe M1 launch boundaries. |
| Decode gate + up + SiLU, N128 | Rejected — measured | Raw ASM fused 193.700 us versus 170.206 us standalone rocprofv3 kernel sum; HIP event 199.508 versus 185.722 us; bit-exact BF16 to standalone; 56 VGPR | 13.8% slower kernel sum and 7.4% slower pipeline. Occupancy loss and four exponential paths outweigh fewer launches/stores. |
| Decode gate + up + SiLU, N64 | Rejected — measured | Raw ASM HIP event 203.829 us; 40 VGPR | Duplicated decode work is slower than both N128 fused and standalone. |
| Prefill M128 reuse | Rejected — measured | Raw ASM 203.129 us versus 197.510 us for two selected M64 calls; 144 VGPR | Register pressure offsets reuse. |
| Prefill gate paired A-tile prefetch | Rejected — gfx1151 measured | Reused post-decode VGPRs with no allocation increase and matched the FP64 result exactly. G=8 measured 105.009 us versus 104.817 us baseline; real G=1,276 measured 11,085.683 us versus 10,658.226 us. | 4.01% slower at the real server shape; extra in-flight traffic reduced rather than hid latency. Standalone raw ASM retained in `scripts/rocm/`. |
| Prefill scale-folded BF16 tables | Rejected — measured | HIP event 107.815 us versus 104.992 us baseline; maximum synthetic error 0.001965 versus 0.000327 | Slower and less accurate. |
| Gate + up projection with shared activation loads | Covered by the rejected fused decode experiment | The fused kernel retained 384 `v_perm_b32` and 128 `v_dot2_f32_bf16`, while allocation rose to 56 VGPR | Do not reinstate without a materially different schedule. |
| SiLU x up feeding down projection | Pending | No full-request or matched rocprofv3 result yet | Must preserve BF16 staging semantics or validate a changed numerical contract against FP64 and layer outputs. |
| Residual + RMSNorm | Pending | Trace inventory captured the family, but it is below the top decode and long-prefill costs | Re-rank after graph launch removal. |
| Q/K norm + RoPE + KV store | Pending | Adjacent kernels are visible in the full-attention sequence; no fused gfx1151 ASM exists | Validate exact RoPE/KV-cache contents before timing. |
| Prefill online-softmax attention | Highest-priority pending | Extend-attention `_fwd_kernel` costs 8,824.300 ms across 40 calls in measured 32K prefill; current Triton dispatch uses 256 VGPR and 1,184 B scratch | First benchmark tile/schedule oracles, then implement accepted compute in raw gfx1151 ASM. |
| GDN state update + gate + normalization | High-priority pending | `chunk_fwd_kernel_o`, `recompute_w_u_fwd_kernel`, and chunk delta-rule are dominant in 8K/32K measured traces, with 256 VGPR and scratch in two kernels | Separate fusion must show reduced spills and full layer correctness. |
| Router projection + top-k + softmax | Pending | Routing is not yet isolated with counters | Capture expert IDs/weights and preserve exact top-k ties. |
| Expert permutation + activation gather | Pending | Gather/index families cost more than 2.2 s combined in measured 32K trace | Compare against a device-resident fixed-capacity grouped layout. |
| Router-weight application + expert reduction + residual | Pending | No isolated matched result | Check whether extra live accumulators reduce occupancy. |
| Final RMSNorm + LM head + sampling | Pending | LM-head and sampling are not the first long-prefill target; raw LM-head kernels already exist | Retest after graph capture removes launch overhead. |
| Speculative verify + accept/commit | Blocked by inputs | Supplied checkpoint has no `dflash_config` and no compatible DFlash draft checkpoint is installed | No performance value estimated. |

The accepted QKVZ+BA entry also has a finalized gfx1151 rocprofv3 CSV trace.
Across 221 calls per shape, separate QKVZ and BA raw-ASM kernel medians were
100.351 and 84.922 us, while the fused padded kernel median was 101.114 us: a
measured 1.8323x kernel-time speedup. All three dispatches use 40 VGPR, 128
SGPR, zero LDS, and zero scratch.

The detailed measured negative-result data is also retained in `docs/notes/gfx1151-mxfp4-results.json` and `docs/notes/gfx1151-mxfp4-kernels.md`.
