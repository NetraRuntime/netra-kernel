# gfx1151 extend-attention counters and cache-policy experiment

Production status: **default global-load policy retained**. All runtime values are measured on gfx1151; no values are estimated.

## Native rocprofv3 counters

The native harness dispatches the accepted raw AMDGCN kernel at exact Qwen3.6 shape T=8,192, prefix=24,576, Hq=16, Hkv=2, D=256, causal, with sequential page indices. It uses synthetic zero data so values do not represent model correctness, but addresses and dispatch geometry match the serving specialization. Each metric was collected in a separate process with `/opt/rocm-7.2.1/bin/rocprofv3 --disable-signal-handlers true`.

| gfx1151 metric | measured value |
|---|---:|
| Workgroups / waves | 2,048 / 8,192 |
| OccupancyPercent | 7.377047% |
| MeanOccupancyPerActiveCU | 4.786643 waves |
| VRAM fetch | 19,163,593.938 KiB (18.276 GiB) |
| VRAM write | 32,439.875 KiB |
| L2CacheHit | 24.662958% |
| LDSBankConflict | 49.789985% |
| SQ_INSTS_LDS | 4,658,905,088 |
| SQ_INSTS_VALU | 6,658,113,536 |
| SQ_INSTS_FLAT | 177,537,024 |
| VGPR / LDS / scratch | 248 / 65,536 B / 0 B |
| WriteUnitStalled | 0.000931% |

`MemUnitBusy` returned 860,299.543081 for a metric described as a percentage, so that counter is invalid on this gfx1151/rocprofv3 combination and is not interpreted. Direct dependency-stall counters are not exposed. The raw CSVs and complete summary are under `results/profiles/gfx1151/extend-attention-counters-20260729/`.

The low L2 hit rate and 18.276 GiB fetch volume confirm that repeated K/V consumption across query heads and M tiles is a primary optimization boundary. Full 64 KiB LDS allocation and 248 VGPRs constrain residency; LDS bank conflicts are also material.

## K/V `glc` raw-ASM variant

`scripts/rocm/extend_attention_wmma_n64_glc_gfx1151.s` differs only by adding gfx11 `glc` to K/V `global_load_b128` instructions. Q loads retain the default policy. The intent was to bypass the per-workgroup near cache for single-use K/V loads and improve sharing through the device-level cache.

Paired HIP-event timing loaded default and `glc` HSACOs into one process and used identical tensors. Outputs were byte-identical at every tier.

| Prefix | default | K/V `glc` | speedup | byte equal |
|---:|---:|---:|---:|---|
| 0 | 45.991566 ms | 44.772144 ms | 1.0272x | yes |
| 8,192 | 130.906784 ms | 128.538315 ms | 1.0184x | yes |
| 16,384 | 223.318192 ms | 216.965714 ms | 1.0293x | yes |
| 24,576 | 317.822510 ms | 306.958435 ms | 1.0354x | yes |

## Real-checkpoint rejection

Temporary production integration used exact uncached 32,768 input/+1 output, graph disabled and dFlash disabled.

| gfx1151 build | seed | host E2E | greedy token |
|---|---|---:|---:|
| default baseline | pair-a | 29,930.237 ms | 220 |
| K/V `glc` | pair-a | 29,799.171 ms | 220 |
| default baseline | pair-b | 29,806.921 ms | 96043 |
| K/V `glc` | pair-b | 29,620.627 ms | 0 |
| restored default | pair-b | 30,275.225 ms | 96043 |

The live KV path failed even though static isolated inputs were byte-identical. The result proves this cache policy is unsafe for the serving write/read sequence; a specific stale-cache mechanism is plausible but not claimed without a dedicated producer/consumer trace. The default policy was restored and rebuilt. No serving speedup is accepted.

Before/after gfx1151 disassemblies and their minimal diff are under `docs/netra/notes/disassembly/extend-attention-glc-gfx1151/`. Reproducible harnesses are `scripts/rocm/extend_attention_counter_harness.hip`, `scripts/rocm/profile_extend_attention_counters.sh`, and `scripts/rocm/benchmark_extend_attention_cache_policy.py`.
