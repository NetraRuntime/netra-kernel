# gfx1151 expert activation pack

Production status: **accepted and enabled**. All timings below are measured on gfx1151; no estimates are reported. MXFP4 weights remain unchanged.

## Target and implementation

The exact 32,768-input trace showed 160 repeated MoE activation-preparation sequences at each 8,192-token chunk shape: allocate/clear the fixed-capacity BF16 grouped buffer, gather 65,536 routed source rows, then indexed-copy them into 81,664 padded group rows. `scripts/rocm/expert_activation_pack_gfx1151.s` replaces those three GPU kernels with one raw gfx1151 AMDGCN dispatch.

Each workgroup handles one routed token pair. Its 256 threads copy one 4 KiB BF16 hidden row with 16-byte loads/stores. The last pair before each group gap clears only padding rows. The final pair clears the unused tail. The code object uses 8 VGPR, 26 SGPR, wave32, zero LDS, and zero scratch. The launch-only HIP bridge loads the module before graph capture.

## Correctness

- The exact T=8,192/top-k=8/expert=256 microbenchmark is bit-equal to Torch `zeros + index_select + index_copy`.
- A 65,536-word prefix and suffix guard detected zero out-of-bounds writes.
- Instrumented real-checkpoint validation compared all 160 pack calls in an exact uncached 32,768-input request. Every output was bit-equal; all inputs were contiguous with stride `(2048, 1)`.
- Exact M64 native `tc_piecewise` replay returned token 198 and the same output SHA-256 as eager. SGLang logged `cuda graph: True`.

The long-prompt pair-B greedy choice is not a single-valued full-stack oracle: an unused extra module load changed the committed atomic baseline from token 96043 to 3709 without calling the new kernel, and later fresh servers reproduced both outcomes. The accepted pack itself is bit-equal at all 160 layer boundaries. A separate fixed pairwise expert reduction did not remove this fresh-server variation and remains rejected.

## HIP events and rocprofv3

At T=8,192, raw pack median is 2.559765100479126 ms versus 6.754312992095947 ms for the three-Torch-kernel pipeline, a measured 2.6386456283944586x speedup.

A valid ABI-matched rocprofv3 process-start CSV trace covered exact 32,768-input/+1-output, graph disabled and dFlash disabled. Graceful SIGTERM allowed the GPU scheduler to finalize 13.43 MB of kernel trace and 30.03 MB of HIP trace.

| gfx1151 exact 32K activation-preparation component | Calls | Total GPU ms |
|---|---:|---:|
| BF16 fixed-capacity fill, before | 160 | 209.902 |
| pre-activation gather, before | 160 | 361.350 |
| indexed copy, before | 160 | 516.872 |
| raw activation pack, after | 160 | 404.818 |

The matched segment falls from 1,088.123 to 404.818 ms: 683.305 ms GPU time saved and 320 launches removed. Durations are rocprofv3 GPU timestamps, not host timing.

## Serving and graphs

Exact uncached 32,768/+1 host E2E on gfx1151:

| Pair | Baseline ms | Raw pack ms | Speedup | Output |
|---|---:|---:|---:|---|
| A | 29,930.237 | 29,389.212 | 1.01841x | token 220 in both |
| B, same module layout | 30,037.008 | 29,320.495 | 1.02444x | token 3709 in both |

These are host-monotonic serving results, not GPU-duration claims. Both runs report exactly 32,768 input tokens, one output token, zero cached tokens, graph disabled, and dFlash disabled.

Native M64 `tc_piecewise` captured in 12.44 s using 0.28 GB. One replay measured 511.701 ms versus 575.082 ms eager and matched the eager output hash. This is a graph-compatibility result only; a one-sample graph speedup is not claimed.

Artifacts include the raw `.s`, HIP launcher, reproducible HIP-event benchmark, SGLang bridge, build registration, code-object metadata/disassembly, compact JSON result, paired serving JSONs, and the full rocprofv3 CSV directory.

## Profiler handling

Attach-mode ABI-matched rocprofv3 killed the scheduler with SIGSEGV during `rocattach`; that attempt is invalid. Process-start profiling with `--disable-signal-handlers true`, CSV output, and graceful SIGTERM finalized correctly. This also confirms the earlier repeated `caught signal 6` output was profiler signal-handler recursion, not an inference loop.
