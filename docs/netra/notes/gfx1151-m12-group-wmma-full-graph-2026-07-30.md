# gfx1151 M12 routed-group WMMA and full-graph result (2026-07-30)

> Superseded later on 2026-07-30 by the accepted fused gate+up and M12-strided SiLU result in `gfx1151-m12-gate-up-silu-fusion-full-graph-2026-07-30.md`. This note remains the measured intermediate baseline.

All performance numbers in this note are measured on gfx1151 unless explicitly marked otherwise. This is native batch-12 decode, not speculative verification or dFlash.

## Trace-ranked cause

The accepted M12 full-decode trace showed the generic routed expert path at the top of request GPU cost. For 12 tokens and top-k 8, the graph keeps a stable 96-group geometry. Each group can contain at most twelve valid rows, but the M64 prefill kernels computed all 64 rows: 6,144 rows for at most 96 routed pairs. The earlier graph replay attributed 49.726% of summed kernel time to gate/up and 12.475% to down. Attention plus the accepted Q/K-normalization, MRoPE and KV-store fusion was about 0.598%, so attention work was not the next top-down target.

## Raw ASM replacement

Two raw AMDGCN code objects specialize the production group strides while computing and storing only rows 0 through 11:

- `mxfp4_m12_group_gate_wmma_gfx1151`: N=512, K=2048, grid `(32, group_count, 1)`, wave32.
- `mxfp4_m12_group_down_wmma_gfx1151`: N=2048, K=512, grid `(128, group_count, 1)`, wave32.

Both retain the model's original row-major MXFP4 weights and per-group expert IDs. The HIP bridge only loads modules, launches raw ASM, captures/replays graphs and manages existing buffers. `SGLANG_NETRA_DISABLE_M12_GROUP_WMMA=1` restores the generic A/B oracle. Modules are loaded during backend initialization before graph capture, and replay uses stable pointers already owned by the SGLang graph pools.

LLVM metadata for both replacements is 65 VGPR, 23 SGPR, zero LDS and zero scratch. rocprofv3 reports the allocation granules as 72 VGPR and 128 SGPR. Static disassembly changes are:

| Projection | Kernel | WMMA sites | waits | barriers | DS sites |
|---|---|---:|---:|---:|---:|
| gate/up | generic M64 | 8 | 20 | 2 | 82 |
| gate/up | M12 ASM | 2 | 12 | 0 | 24 |
| down | generic M64 | 8 | 20 | 0 | 72 |
| down | M12 ASM | 2 | 12 | 0 | 24 |

Complete before/after disassemblies are under `gfx1151-m12-group-wmma-disassembly-2026-07-30/`.

## Isolated correctness and HIP-event timing

The reproducible pair harness compares the production raw-ASM kernel with the M12 raw-ASM candidate for 96 groups and only the twelve valid rows. Packed MXFP4 data, scales, activations and expert IDs are identical. Twenty-one alternating samples produced:

| Projection | Bit equality | Generic median | M12 median | Speedup |
|---|---:|---:|---:|---:|
| gate/up projection | true, 0 mismatches | 1.113899 ms | 0.769209 ms | 1.448110x |
| down projection | true, 0 mismatches | 0.830524 ms | 0.430331 ms | 1.929966x |

These are isolated HIP-event measurements. Sample dispersion is retained in the companion JSON and no cold-cache estimate is assigned.

## Real-checkpoint full-graph correctness and serving

The SGL-compatible real checkpoint was launched twice with identical graph tiers `[1,2,4,8,12,16]`, once with the environment switch disabling this specialization and once with it enabled. Ordered requests used identical input IDs and greedy decoding. Cached tokens were zero.

| Exact scenario | Generic graph host E2E | M12 ASM graph host E2E | Speedup | Generic output tok/s | M12 output tok/s | Exact sequences |
|---|---:|---:|---:|---:|---:|---:|
| batch 12, 210 input +32 output each | 8,083.525 ms | 5,952.809 ms | 1.357935x | 47.5040 | 64.5074 | 12/12 |
| batch 12, 210 input +128 output each | 26,192.816 ms | 18,436.354 ms | 1.420716x | 58.6420 | 83.3137 | 12/12 |

Timing is labeled host end-to-end serving time. It is not substituted for GPU claims. The +128 run emitted exactly 1,536 output tokens and accepted no prefix-cache hits. dFlash was disabled.

## rocprofv3 graph replay

The process-start profiler used `/root/venv1151/bin/rocprofv3`, disabled profiler signal handlers and did not collect counters. This avoids the previously reproduced Python/counter AQL ABI signal-6 failure. The server was intentionally terminated after the request, so the shell's final `Killed` line is SIGTERM cleanup, not signal 6.

Eight actual hipGraphLaunch replays were correlated, each containing 3,063 kernels:

| Replay metric | Generic graph | M12 ASM graph | Improvement |
|---|---:|---:|---:|
| mean GPU span | 194,532.240 us | 129,865.403 us | 1.497953x |
| median GPU span | 194,746.144 us | 129,982.056 us | 1.498x approximately |
| mean summed kernel time | 185,945.245 us | 121,526.068 us | 1.530085x |
| mean positive launch gap | 2.804 us | 2.723 us | 1.030x approximately |
| median positive launch gap | 2.084 us | 2.084 us | neutral |

The accepted raw gate/up kernel has 640 invocations across eight replays, mean 615.268 us, and 40.503% of graph kernel time. The raw down kernel has 320 invocations, mean 236.815 us, and 7.795%. Relative to the prior identical-shape trace, gate/up kernel mean improves 1.878519x and down improves 2.448741x.

## Loading and memory observations

Two loader threads loaded all 26 shards and staged 61,440 MXFP4 expert tensors in 10.02 to 13.48 seconds in these measured warm/mixed-cache launches. Eight loader threads was previously rejected after SIGKILL from memory pressure. No controlled cold-cache number is claimed, but the current path does not reproduce the reported 10 to 20 minute startup.

Graph construction was measured between 3.00 and 4.07 seconds in these A/B launches. Reported graph memory varied from 0.16 to 0.80 GB between processes and is not treated as a stable candidate delta without a tighter memory-controlled experiment.

## Reproduction

Run inside the Netra LXC:

```bash
scripts/rocm/tools/build/build_netra_sglang_gfx1151.sh
build/sglang/benchmark_m12_group_wmma_pair gate build/sglang/mxfp4_prefill_gate_wmma_gfx1151.hsaco build/sglang/mxfp4_m12_group_gate_wmma_gfx1151.hsaco 96 21
build/sglang/benchmark_m12_group_wmma_pair down build/sglang/mxfp4_prefill_down_wmma_gfx1151.hsaco build/sglang/mxfp4_m12_group_down_wmma_gfx1151.hsaco 96 21
```

Use `SGLANG_NETRA_DISABLE_M12_GROUP_WMMA=1` for the generic real-checkpoint A/B server. The accepted candidate is the default.

## Decision and next work

Retain the M12 raw-ASM specialization: isolated outputs are bit-exact, real-checkpoint greedy sequences are 12/12 exact at +32 and +128, and both rocprofv3 GPU time and serving E2E improve materially.

The new trace still ranks gate/up first at 40.503%. The next experiment should share activation traffic across gate and up or fuse their epilogue without increasing VGPR allocation, then reduce the padded SiLU launch, which remains 3.973% of replay kernel time. Actual M2-M16 speculative verification and dFlash remain input-blocked because no compatible draft checkpoint or checkpoint `dflash_config` is installed.
