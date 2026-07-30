# gfx1151 GDN recompute W/U RHS-fragment reuse — 2026-07-30

Status: **accepted**. All timings below are measured on gfx1151 (AMD Ryzen AI Max+ PRO 395). The checkpoint remains MXFP4; this model-native BF16 GDN operation is in scope. Graph and dFlash modes are stated explicitly.

## Ranked reason for work

The graph-disabled, uncached exact 32,768-input/+1-output baseline ranked `recompute_w_u_reuse_a_ordered_gfx1151` fifth: 120 invocations, 1,211.034 ms total GPU time, 10.092 ms mean, and 5.382% of request kernel time. This was selected from the measured request ranking, not from an assumed bottleneck.

## Raw AMDGCN change

The prior gfx1151 kernel loaded and swizzled the same four RHS B fragments independently for two A row fragments. The accepted kernel retains the RHS fragments in otherwise unused `v24:v55`, then reuses them for both row fragments. The WMMA multiplication order and 128 WMMA instructions are unchanged, so outputs remain bit-identical to the previous ordered raw ASM.

The shipping source is now canonical under `scripts/rocm/`:

- `scripts/rocm/kernels/gfx1151/gdn/recompute_w_u_ordered_gfx1151.s`
- retained baseline and differently named candidate in `scripts/rocm/kernels/gfx1151/gdn/experiments/`
- HIP launch/timing-only harnesses and build/profile/benchmark tools under `scripts/rocm/`

The existing SGLang build bridge now assembles the canonical source. Findings and evidence are under `docs/netra/notes/` as required by the current repository structure.

## Correctness gates

For exact Qwen3.6 shape B1/T8192/H32/Hg16/K128/V128/BT64 with nonuniform seeded inputs:

- previous ASM versus candidate: bit-exact W and U;
- candidate repeated execution: bit-exact;
- HIP graph replay versus eager: bit-exact;
- Triton/model-native oracle max absolute error: W 7.6293945e-6, U 1.5258789e-5, identical for baseline and candidate;
- all values finite.

Two fresh-server real-checkpoint exact 32,768/+1 requests were uncached and deterministic. Pair A produced token 5525 and pair B token 248045; input hashes, token IDs, and output hashes match their corresponding previous-ASM runs.

## HIP-event timing

Two repeated experiment-HSACO runs plus a production-HSACO run used the same `timed_w` and `timed_u`
device addresses for both variants:

| Run | Baseline median | Candidate median | Speedup | Status |
|---|---:|---:|---:|---|
| A | 10.715901 ms | 10.359514 ms | 1.034402x | measured |
| B | 10.721274 ms | 10.399712 ms | 1.030920x | measured |
| production HSACO | 10.680648 ms | 10.389462 ms | 1.028027x | measured |

An earlier harness timed baseline and candidate into separate 128 MiB W/U
allocations. On this unified-memory, memory-bound APU kernel, physical allocation
placement moved results by several percent and could invert the comparison. Those
unshared-output timings are explicitly discarded. Correctness still uses separate
outputs; only timing uses shared addresses so both kernels see identical memory.

## Disassembly and rocprofv3 evidence

Static gfx1151 disassembly changed as follows:

| Item | Baseline | Candidate | Change |
|---|---:|---:|---:|
| disassembly lines | 8,547 | 7,459 | -12.73% |
| `ds_load*` | 1,056 | 544 | -48.48% |
| `ds_swizzle*` | 640 | 384 | -40.00% |
| `s_waitcnt` | 366 | 238 | -34.97% |
| WMMA | 128 | 128 | unchanged |

rocprofv3 used `/opt/rocm-7.2.1/bin/rocprofv3`, one counter per fresh process and `--disable-signal-handlers true`. This deliberately avoids the known rocprofv3 signal-6 failure caused by looping many PMCs or attaching to the large Python/SGLang process.

| Metric | Baseline | Candidate | Change |
|---|---:|---:|---:|
| `SQ_INSTS_LDS` | 14,221,312 | 7,929,856 | -44.24% |
| `SQ_WAVE_CYCLES` | 9,864,484,730 | 9,656,678,747 | -2.11% |
| `VALUInsts` | 6,060 | 5,868 | -3.17% |
| fetch size | 123,153.188 KiB | 122,348.625 KiB | -0.65% |
| write size | 69,623.250 KiB | 68,901.812 KiB | -1.04% |
| L2 hit | 48.652% | 51.955% | +3.303 points |
| mean occupancy | 15.904 | 15.817 | no occupancy tier change |
| memory unit busy | 98.771% | 99.236% | +0.465 points |
| LDS conflict ratio | 41.905% | 43.077% | +1.172 points |

Resources are unchanged: 136 allocated VGPRs, 128 SGPRs, 16 KiB LDS, no scratch, and 8,192 waves. The LDS-conflict percentage rises slightly because the instruction mix/denominator changes, while the absolute dynamic LDS instruction count falls by 44.24%. The gfx1151 metric set does not expose a direct dependency-stall counter.

## Full request impact

The matched seeded rocprofv3 exact 32,768/+1 request used graph disabled, dFlash disabled, zero cached tokens:

- recompute family: 1,211.034 → 1,204.748 ms over 120 calls, 1.005218x measured;
- candidate mean: 10.039565 ms;
- candidate share: 5.369% of total kernel GPU time;
- whole trace: 22,437.158 ms kernel GPU time, 35,601.705 ms trace wall, and 13,171.479 ms positive launch gaps;
- real-checkpoint output token 5525 remained exact.

Fresh-server, profiler-free paired serving provides the acceptance gate:

| Seed | Baseline host E2E | Candidate host E2E | Improvement |
|---|---:|---:|---:|
| pair A | 21,572.145 ms | 21,513.832 ms | 58.313 ms |
| pair B | 21,619.550 ms | 21,561.194 ms | 58.356 ms |
| mean | 21,595.847 ms | 21,537.513 ms | 58.334 ms / 1.002708x |

These are measured host serving E2E results on gfx1151, not GPU kernel timing. Exact counts are 32,768 input and 1 output, cached tokens 0, graph disabled, dFlash disabled. Maximum candidate peak VRAM was 101,356,224,512 bytes. Non-streaming SGLang metadata did not provide a separate TTFT/input-throughput field, so those values are recorded as unavailable rather than estimated.

## Shard loading observation

The four fresh-server gates reached health in 23.145–24.152 seconds measured on gfx1151. The previous 10–20 minute shard-loading behavior did not recur. This confirms the existing fast-loader path remained active during the kernel work; it is not a new loading speedup attributed to this ASM change.

## Reproduction

Run only inside the Netra LXC:

```bash
cd /root/netra-mxfp4-gfx1151
scripts/rocm/tools/build/build_recompute_w_u_breuse_experiment.sh
/root/sglvenv1151/bin/python \
  scripts/rocm/tools/benchmark/benchmark_recompute_w_u_raw_variants.py \
  --launcher-so build/experiments/recompute-w-u-breuse/librecompute_w_u_dual.so \
  --baseline-hsaco build/experiments/recompute-w-u-breuse/recompute_w_u_ordered_baseline_gfx1151.hsaco \
  --candidate-hsaco build/experiments/recompute-w-u-breuse/recompute_w_u_ordered_breuse_gfx1151.hsaco \
  --samples 31
scripts/rocm/tools/profiling/profile_recompute_w_u_breuse_counters.sh
scripts/rocm/tools/benchmark/benchmark_sglang_fresh_request.sh \
  LABEL SEED 32768 1 49152
```

The before/after disassemblies and unified diff are in `docs/netra/notes/gfx1151-recompute-w-u-breuse-disassembly-2026-07-30/`. Machine-readable aggregate, HIP-event, and rocprofv3 records are adjacent to this note.
