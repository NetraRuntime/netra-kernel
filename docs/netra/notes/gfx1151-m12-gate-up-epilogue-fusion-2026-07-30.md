# gfx1151 M12 register-resident gate + SiLU x up fusion (2026-07-30)

All performance values are measured on gfx1151 unless explicitly marked otherwise. This is native ordered batch-12 decode, not speculative verification or dFlash.

## Trace-ranked target

After the accepted shared-load gate+up kernel and M12-only SiLU, correlated graph replay still attributed 39.240% of summed kernel time to gate+up and 0.365% to SiLU. Gate and up were written as FP32 to two `[group,64,512]` workspaces, immediately read by SiLU, converted to BF16, and written to the down-projection input.

## Raw ASM replacement

`mxfp4_m12_group_gate_up_silu_wmma_gfx1151` keeps the transformed gate and up values in VGPRs, executes the exact existing `exp2(-x*log2(e))` SiLU and round-to-nearest-even BF16 conversion, and writes the BF16 intermediate directly. It removes sixteen FP32 store sites and the following two input streams, replacing them with eight BF16 store sites. Static sites are four WMMA, fifteen waits, zero barriers, twenty global loads, eight global stores, and eight exponentials.

Metadata remains 87 VGPR, 33 SGPR, zero LDS, and zero scratch; rocprofv3 reports the 88-VGPR allocation granule. The HIP bridge loads the code object before graph capture and supplies stable graph-pool pointers. No compute is implemented in HIP C++.

Complete before, after, and rejected-schedule disassemblies are in `gfx1151-m12-gate-up-epilogue-fusion-disassembly-2026-07-30/`.

## Correctness and isolated HIP events

At 96 routed groups and twelve valid rows, the fused epilogue is bit-exact against the accepted raw gate+up kernel followed by the accepted raw M12 SiLU kernel. It produced zero BF16 mismatches.

| Measurement | Baseline median | Fused median | Speedup |
|---|---:|---:|---:|
| 21 samples, eight launches per event | 1.188969 ms | 1.166456 ms | 1.019300x |
| 61 samples A, eight launches per event | 1.189168 ms | 1.168060 ms | 1.018072x |
| 61 samples B, eight launches per event | 1.187511 ms | 1.163245 ms | 1.020860x |

## Negative scheduling ledger

Two less structural candidates were rejected before the epilogue fusion:

- `mxfp4_m12_group_gate_up_wait4_wmma_gfx1151` changes the broad load wait into `vmcnt(4)` for gate computation and `vmcnt(0)` before up. It is bit-exact, but separate-process normalization against the same two-launch oracle showed about a 1.27% regression. Static waits increase from fifteen to sixteen.
- `mxfp4_m12_group_gate_up_kprefetch_wmma_gfx1151` prefetches the next block's scales, activation, gate weights, and up weights without increasing the 87-VGPR metadata count. Batched direct comparison measured 0.0796% slower in one module order and 0.277% faster in the reverse order. The direction reversal is classified as neutral; it is not shipped in production.

Both raw ASM experiments remain under `scripts/rocm/kernels/gfx1151/mxfp4/experiments/` as reproducible negative results.

## Real-checkpoint full graph

The current fusion, the prior separate epilogue, and the generic graph oracle used identical generated input IDs for each comparison, deterministic greedy decoding, zero cached tokens, and dFlash disabled. All sequences were exact 12/12 against both oracles.

| Exact ordered scenario | Generic graph E2E | Prior M12 graph E2E | Fused epilogue E2E | Fused versus prior | Fused versus generic | Output tok/s |
|---|---:|---:|---:|---:|---:|---:|
| batch 12, 210 input +32 output each | 8,083.525 ms | 5,564.446 ms | 5,647.168 ms | 0.985352x | 1.431430x | 67.9987 |
| batch 12, 210 input +128 output each | 26,192.816 ms | 16,676.696 ms | 16,594.796 ms | 1.004935x | 1.578375x | 92.5591 |

These are measured host HTTP E2E values. The exact-seed short sample regressed 1.487%, while the longer sample improved 0.494%. A different-seed warm +32 run measured 5,154.317 ms but is not used for an A/B speedup claim because router/expert work changes with the input. TTFT is not exposed separately and is not estimated. Peak unified-memory sampling for the fused server was 101,702,283,264 bytes and showed no stable allocation reduction because the graph pool still owns the now-unused intermediate buffers.

## rocprofv3 graph replay

Eight actual `hipGraphLaunch` calls were correlated with signal handlers and counter collection disabled. The terminal `Killed` line is intentional SIGTERM cleanup, not signal 6.

| Replay metric | Prior separate epilogue | Register-resident fusion | Improvement |
|---|---:|---:|---:|
| kernels per replay | 3,023 | 2,983 | 40 fewer, 1.323% |
| mean GPU span | 118,387.992 us | 116,121.747 us | 1.019516x |
| median GPU span | 118,562.429 us | 116,401.478 us | 1.018564x |
| mean summed kernel time | 110,582.694 us | 108,402.801 us | 1.020109x |
| mean graph-launch CPU time | 1,668.606 us | 1,653.542 us | 1.009110x |
| mean positive launch gap | 2.583 us | 2.589 us | neutral/slightly worse |

The prior gate+up and M12 SiLU means sum to 1,094.904 us. The new single kernel measures 1,053.377 us, a correlated 1.039422x improvement. It has 320 invocations across eight replays and consumes 38.869% of summed graph kernel time. Down is now 228.972 us mean and 8.449%.

## Decision

Accept the raw ASM epilogue fusion. It passes bit equality, complete real-checkpoint sequence equality, isolated HIP-event timing, node-count reduction, and correlated rocprofv3 GPU-span reduction. The +32 host sample is retained as a negative serving result rather than hidden; +128 and GPU evidence establish positive end-to-end value.

The next trace-ranked raw target remains this fused kernel at 38.869%, but wait-only and zero-register K-block prefetch schedules are now measured negative/neutral. A materially different weight transaction or accumulator schedule is required. Piecewise graphs remain unvalidated, and actual verify/dFlash remains input-blocked by the absent compatible draft checkpoint and `dflash_config`.
