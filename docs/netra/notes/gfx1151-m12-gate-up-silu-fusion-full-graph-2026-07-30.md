# gfx1151 M12 gate+up and SiLU fusion full-graph result (2026-07-30)

All performance values are measured on gfx1151 unless explicitly marked otherwise. This remains native ordered batch-12 decode, not speculative verification or dFlash.

## Trace-ranked target

After the first accepted M12 row specialization, separate raw gate and up launches still consumed 40.503% of correlated graph kernel time, and the padded SiLU launch consumed 3.973%. Each gate/up projection reread the same activation fragments. SiLU processed all 64 storage rows although an M12 routed expert group has at most twelve valid rows.

## Raw ASM changes

`mxfp4_m12_group_gate_up_wmma_gfx1151` computes gate and up in one wave. For every K fragment it loads activation once, loads both original row-major MXFP4 weight streams, and keeps two persistent WMMA accumulator sets. It writes only rows 0 through 11 into the unchanged `[group,64,512]` buffers. Its LLVM metadata is 87 VGPR, 33 SGPR, zero LDS and zero scratch; rocprofv3 reports the 88-VGPR allocation granule.

`silu_mul_m12_group_bf16_gfx1151` uses a two-dimensional `(24,group_count)` grid. It visits 12 rows times 512 columns per group while preserving the 64-row input/output stride. Metadata is 8 VGPR, 14 SGPR, zero LDS and zero scratch.

The HIP bridge loads both code objects before graph capture and launches them with stable graph-pool pointers. No final compute is hidden in HIP C++.

Complete before/after disassemblies are under `gfx1151-m12-gate-up-silu-fusion-disassembly-2026-07-30/`. The fused projection has four static WMMA sites, 15 waits, no barrier, 40 DS sites, two activation `global_load_b128` sites and 16 stores. Two invocations of the earlier single-projection kernel also have four WMMA sites but execute four activation `global_load_b128` instructions dynamically and require two graph nodes.

## Isolated HIP-event correctness and performance

Twenty-one alternating samples at the production 96-group geometry gave:

| Raw ASM comparison | Valid output | Baseline median | Candidate median | Speedup |
|---|---:|---:|---:|---:|
| two M12 gate/up launches vs fused launch | gate and up bit-exact, zero mismatches | 1.458701 ms | 1.178976 ms | 1.237261x |
| padded M64 SiLU vs M12 strided SiLU | bit-exact, zero mismatches | 0.048611 ms | 0.011983 ms | 4.056664x |

HIP kernels in the harness perform only deterministic setup and comparison. The projection and SiLU computations being timed are raw gfx1151 AMDGCN code objects.

## Real-checkpoint graph serving

The current fused result, the prior separate-M12 ASM result and the generic graph oracle used identical generated input IDs and deterministic greedy decoding. Cached tokens were zero and dFlash was disabled.

| Exact ordered scenario | Generic graph E2E | Prior M12 ASM E2E | Fused M12 E2E | Speedup vs generic | Speedup vs prior ASM | Fused output tok/s | Exact sequences |
|---|---:|---:|---:|---:|---:|---:|---:|
| batch 12, 210 input +32 output each | 8,083.525 ms | 5,952.809 ms | 5,564.446 ms | 1.452710x | 1.069794x | 69.0096 | 12/12 against both |
| batch 12, 210 input +128 output each | 26,192.816 ms | 18,436.354 ms | 16,676.696 ms | 1.570624x | 1.105516x | 92.1046 | 12/12 against both |

These are labeled host HTTP end-to-end measurements. For +128, fused aggregate input throughput is 151.1091 input tok/s, median server-reported E2E is 16,663.779 ms, and the unified-memory sysfs peak sample is 100,616,454,144 bytes. TTFT is not exposed separately by this ordered batch endpoint and is therefore not estimated.

## rocprofv3 graph replay

The profiler used process-start `/root/venv1151/bin/rocprofv3`, disabled signal handlers and counter collection, and correlated eight actual `hipGraphLaunch` calls. The terminal `Killed` line is intentional SIGTERM cleanup rather than signal 6.

| Replay metric | Prior M12 ASM | Fused M12 | Improvement |
|---|---:|---:|---:|
| kernels per replay | 3,063 | 3,023 | 40 fewer, 1.306% |
| mean GPU span | 129,865.403 us | 118,387.992 us | 1.096947x |
| median GPU span | 129,982.056 us | 118,562.429 us | 1.096x approximately |
| mean summed kernel time | 121,526.068 us | 110,582.694 us | 1.098961x |
| mean positive inter-kernel gap | 2.723 us | 2.583 us | 1.054x approximately |
| median positive inter-kernel gap | 2.084 us | 2.084 us | neutral |

The fused gate+up has 320 invocations across eight replays, mean 1,084.814 us and 39.240% of graph kernel time. The earlier pair implied 1,230.535 us from two 615.268-us launches, so graph-correlated projection time improves 1.134328x. M12 SiLU has 320 invocations, mean 10.090 us and 0.365%; the prior padded SiLU mean was 120.715 us, a 11.964137x traced reduction. Down remains 231.474 us mean and 8.373%.

## Decision

Accept both raw ASM kernels. They pass isolated bit equality, preserve 12/12 real-checkpoint greedy sequences at +32 and +128, reduce graph nodes, improve correlated GPU time and improve uncached host serving.

The fused gate+up kernel remains the top single family at 39.240%. Its next experiments should be internal K-block prefetch and weight/activation wait scheduling, measured against the current 88-VGPR allocation. Piecewise graphs remain unvalidated, and actual M2-M16 speculative verification/dFlash remains input-blocked by the absent compatible draft checkpoint and checkpoint `dflash_config`.

## Reproduction

Run inside the Netra LXC:

```bash
scripts/rocm/tools/build/build_netra_sglang_gfx1151.sh
build/sglang/benchmark_m12_fused_gate_up_pair build/sglang/mxfp4_m12_group_gate_wmma_gfx1151.hsaco build/sglang/mxfp4_m12_group_gate_up_wmma_gfx1151.hsaco 96 21
build/sglang/benchmark_m12_group_silu_pair build/sglang/silu_mul_bf16_gfx1151.hsaco build/sglang/silu_mul_m12_group_bf16_gfx1151.hsaco 96 21
```
