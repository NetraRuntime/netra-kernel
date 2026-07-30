# gfx1151 Q/K norm + MRoPE + KV-store fusion (2026-07-30)

Status: **accepted for eager SGLang and native full M1 decode graph; M2-M16 and piecewise graph gates remain**.

Every runtime and counter value below is measured on gfx1151. No speedup is estimated.

## Scope

The accepted raw AMDGCN kernel is specialized for the real Qwen3.6 standard-attention ABI:

- BF16 Qwen row `[M,9216]`, Hq=16, Hkv=2, D=256, rotary dimension 64;
- interleaved Q/gate extraction and gate copy;
- Gemma Q/K RMSNorm with model-native BF16 rounding;
- three-axis MRoPE sections `[11,11,10]`;
- page-size-1 K/V cache storage using int64 slot mappings.

## Correctness and the rejected intermediate

| M | Position mode | Q/K/gate/cache result on gfx1151 |
|---:|---|---|
| 1 | multimodal 3-axis | bit-exact |
| 12 | multimodal 3-axis | bit-exact |
| 210 | text 3-axis | bit-exact |
| 8,192 | text 3-axis | bit-exact over 79,691,776 checked elements |
| 32,768 | text 3-axis | bit-exact over 318,767,104 checked elements |

The model-native SGLang Triton/HIP path is the arithmetic oracle because downstream greedy behavior depends on its BF16 rounding order. A first raw wave-local butterfly reduction differed in only 103 of about 37.7 million normalized Q/K values at M=8192, but a real-checkpoint 210/+128 greedy run diverged at output index 60. It was rejected.

The accepted kernel reconstructs Triton's exact four-wave reduction association inside each owning wave: adjacent BF16 pairs form four 64-element partials, then fold as `(p0+p2)+(p1+p3)`. The full 128-token deterministic real-checkpoint sequence is now identical to two baseline runs.

## HIP-event result

| M | Baseline mean ms | Raw mean ms | Mean speedup | Baseline median ms | Raw median ms | Median speedup |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 0.046138 | 0.010961 | 4.2094x | 0.044253 | 0.009618 | 4.6011x |
| 12 | 0.047386 | 0.010891 | 4.3511x | 0.045706 | 0.009778 | 4.6744x |
| 210 | 0.046528 | 0.021822 | 2.1322x | 0.045350 | 0.021700 | 2.0898x |
| 8,192 | 2.055323 | 1.669744 | 1.2309x | 2.058459 | 1.666071 | 1.2355x |
| 32,768 | 7.827205 | 6.432603 | 1.2168x | 7.830539 | 6.424549 | 1.2188x |

These are identical-shape HIP-event measurements of the complete baseline preparation path versus one raw kernel, not host serving times.

## rocprofv3 and disassembly evidence

A process-start kernel trace measured eight M8192 raw dispatches at 1.676159 ms mean. The pure ROCm 7.2 counter driver measured:

- dispatch grid 1,048,576 threads, workgroup 128;
- 40 VGPR and 128 SGPR allocation granules, zero scratch, 512-byte LDS allocation granule;
- 32,768 wavefronts;
- 59.022965% OccupancyPercent and 35.391669 mean occupancy per active CU;
- 73,950.3125 KiB fetched and 69,230.8125 KiB written per dispatch;
- 41.7585345% L2 hit;
- 758 VALU and 88 SALU instructions per wave;
- 0% measured LDS bank conflict;
- 32.5874525% write-unit stall.

The source metadata uses 34 VGPR, 48 SGPR, 128 bytes fixed LDS, and zero scratch; rocprofv3 reports hardware allocation granules. Direct dependency/wait-state stall counters are not exposed by this gfx1151 metric set.

Running hardware counters through the PyTorch ROCm environment reproduced `aqlprofile API table load failed`, SIGABRT, and `rocprofv3 caught signal 6`. Counter collection is therefore one counter per fresh process through the pure `/opt/rocm-7.2.1` HIP driver. Combining incompatible derived counters also exceeds hardware collection capability and can enter the same signal-finalization loop.

## Exact serving result

Three paired fresh-server 210/+1 runs used zero cached tokens, seed 7702, graph disabled, and dFlash disabled. All six requests had the same input hash and greedy token `[248045]`.

| Pair | Baseline host E2E ms | Raw host E2E ms | Raw minus baseline ms |
|---:|---:|---:|---:|
| 1 | 705.168781 | 554.865842 | -150.302939 |
| 2 | 563.165699 | 561.419327 | -1.746372 |
| 3 | 560.136376 | 555.965971 | -4.170405 |

The baseline/raw medians are 563.165699/555.965971 ms, a measured nominal 1.012950x ratio. Pair 1 is a baseline outlier, so the mean ratio is excluded and the serving gain remains modest.

The longer sequence gate used exact 210 input tokens and 128 forced output tokens with the same eager modes:

| Run | Host E2E ms | Peak unified VRAM bytes | Output sequence |
|---|---:|---:|---|
| baseline 1 | 7,746.015950 | 99,880,947,712 | reference |
| baseline 2 | 7,598.096069 | 99,774,193,664 | identical to baseline 1 |
| accepted raw | 7,767.909637 | 100,029,636,608 | identical to both baselines |

Candidate output SHA256 is `a05e55f27281f5dd3edb28e6a686280718ffc8d4a06048317c5389f74309a91b`. Host timing is neutral/noisy and is not an end-to-end speedup claim.

## Decision

Accept the raw gfx1151 kernel and eager SGLang dispatch because it removes the separate Q/K norm, MRoPE, and KV-store critical-path launches while preserving exact model-native results and providing a measured isolated GPU-path win at every tested M.

Native full M1 decode graph replay is now accepted with distinct per-layer stable output workspaces and no fusion allocation during capture. A shared cross-layer workspace was rejected because repeated replay throughput degraded despite exact outputs. Treat the measured 1.295% 210/+1 eager median improvement and 0.5415% paired 210/+128 full-graph host-E2E improvement as modest; M2-M16 verify and piecewise prefill remain separate gates.

## Reproduction

- `kernels/gfx1151/attention/qk_norm_mrope_gate_kv_store_gfx1151.s`
- `scripts/rocm/tools/build/build_qk_norm_mrope_kv_fusion_experiment.sh`
- `scripts/rocm/tools/benchmark/benchmark_qk_norm_mrope_kv_fusion.py`
- `scripts/rocm/tools/profiling/profile_qk_norm_mrope_kv_fusion_counters.sh`
- `scripts/rocm/harness/gfx1151/attention/qk_norm_mrope_gate_kv_store_counter_driver.hip`
