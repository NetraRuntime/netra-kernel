# gfx1151 MXFP4 dense-prefill pair-prefetch pipeline — 2026-07-31

Status: **accepted, measured on gfx1151**. Model: Qwen3.6-35B-A3B with checkpoint-native MXFP4 weights. No alternate quantization was tested.

## Ranked target

The accepted GDN trace ranked `mxfp4_sgl_linear_prefill_wmma_gfx1151` second by total request cost: 119 launches, 1,636.255 ms total, 13.750 ms mean, and 7.532% of exact uncached 32,768-input/+1-output host wall time, all measured on gfx1151. The production dispatcher uses this path for the real N=12,288, K=2,048, G=128 prefill shape.

## Raw AMDGCN change

The wave32 kernel still decodes one 16x32 MXFP4 B tile and reuses it across four 16-row WMMA activation tiles. The accepted raw gfx1151 scheduling change pairs adjacent activation tiles:

1. issue both 128-bit loads for tile A0;
2. issue both 128-bit loads for tile A1;
3. use `s_waitcnt vmcnt(2)` so only A0 must complete;
4. swizzle and compute A0 while A1 remains in flight;
5. use the final `s_waitcnt vmcnt(0)` immediately before consuming A1.

Dead decode temporaries hold the second tile. The operation order within every output accumulator is unchanged, so FP32 accumulation remains bit-exact.

The exported kernel symbol, 40-byte/8-byte-aligned kernarg, argument order, grid `(N/16,G,1)`, workgroup `(32,1,1)`, wave32 mode, zero dynamic shared memory, caller stream, module preload order, graph-pool pointers, and weight layout are unchanged. rocprofv3 reports the same 112 allocated VGPR, 128 SGPR, zero LDS, zero scratch, and 98,304 waves.

HSACO SHA-256 changes from `4b50f9587c0a51e5f3e452e46c33de3f95ca63d9f4527b125f4bdf5f3749cb17` to `78838e0bce77502c8e0971a5ece2f9a9ac1ab1e6aa6f3dbf141be66d2dcaad82`.

## Correctness and HIP events

The production-symbol before/after harness uses identical packed weights, scales, BF16 activations, launch geometry, stream behavior, and 31 interleaved samples.

| gfx1151 measured exact shape | Before | After | Result |
|---|---:|---:|---:|
| N=12,288, K=2,048, G=128 eager median | 13.823839 ms | 13.068698 ms | **1.057782x** |
| output comparison | — | — | bit-exact, zero mismatches, max abs 0 |
| dword repack | — | 0.109606 ms | bit-exact |
| candidate graph replay median | — | 13.374315 ms | eager/graph bit-exact |

The graph measurement includes graph replay overhead and is not presented as an eager-versus-graph speedup. It proves raw-module graph capture and replay correctness with stable pointers and no capture-time module load or allocation.

## rocprofv3 counters

Each counter was collected in a separate process with `--disable-signal-handlers true`; this avoids the previously observed rocprofv3 signal-6 handler loop. The metric set exposes no direct dependency-stall percentage, so none is estimated.

| gfx1151 measured counter | Before | After | Delta |
|---|---:|---:|---:|
| allocated VGPR / SGPR | 112 / 128 | 112 / 128 | unchanged |
| LDS / scratch bytes | 0 / 0 | 0 / 0 | unchanged |
| waves | 98,304 | 98,304 | unchanged |
| SQ wave cycles | 34,874,804,486.5 | 32,364,744,415.4 | **-7.197%** |
| SQ busy cycles | 728,873,827.0 | 676,212,614.6 | **-7.225%** |
| occupancy | 74.688% | 74.660% | -0.028 points |
| L2 hit | 77.420% | 79.212% | +1.792 points |
| fetched KiB | 1,082,471.563 | 1,150,444.475 | +6.279% |
| memory-unit busy | 96.725% | 99.204% | +2.479 points |
| VALU instructions | 6,626 | 6,626 | unchanged |
| LDS bank conflicts | 0 | 0 | unchanged |

The extra fetched bytes are a measured cost of increasing concurrent activation requests. Higher L2 hit rate and hidden dependency latency still reduce cycles and HIP-event duration.

## Real-checkpoint serving

Every serving row is uncached, dFlash-disabled, token-exact old/new, and **measured on gfx1151**. The kernel A/B extension pins the identical `200221fd...` runtime-library hash on both sides and records the actual HSACO hash per server.

| Scenario | Graph mode | Before host E2E | After host E2E | Delta |
|---|---|---:|---:|---:|
| exact 32,768 input +1 output | disabled | 20,891.538 ms | 20,833.936 ms | **-0.276%** |
| exact 8,192 input +2 output | full decode tiers 1/2/4/8/12/16 | 4,364.424 ms | 4,353.735 ms | **-0.245%** |

For the two 32K pairs, the median-of-two derived input throughput is 1,568.500 -> 1,572.829 tok/s on gfx1151. This is derived from measured TTFT, not an estimate. Peak whole-APU VRAM varies between server processes and is retained in the raw JSON rather than attributed to this zero-workspace kernel.

The first automated serving attempt used a stale runtime library and failed before model initialization because `netra_mxfp4_sgl_decode_block64` was absent. No request or target kernel ran, and that invalid attempt is excluded from all performance claims.

## Fresh full-request trace

The new exact 32,768-input/+1-output rocprofv3 window measures 15,078 launches, 21,679.121 ms wall, 20,644.042 ms summed GPU kernels, and 1,072.292 ms positive launch gaps on gfx1151. The accepted dense-prefill kernel measures 119 calls, 1,549.833 ms total, 13.024 ms mean, and 7.149% of trace wall. Relative to the immediately preceding trace it falls by 86.422 ms total, or 5.282% measured on gfx1151.

The next ranked costs are attention 5,184.231 ms, dense prefill 1,549.833 ms, GDN chunk output 1,438.899 ms, MoE gate 1,252.602 ms, MoE down 1,213.004 ms, GDN recompute 1,188.462 ms, and MoE up 1,169.275 ms, all measured on gfx1151.

## Experiment ledger

- `group2_a`: rejected. 13.647623 -> 17.563641 ms, 0.777038x measured on gfx1151. Sharing activation through LDS adds barriers and loses more than it saves.
- `pair2_a` with broad `vmcnt(0)`: positive but superseded. 13.700230 -> 13.109991 ms, 1.045022x measured on gfx1151.
- precise-wait pipeline versus broad-wait pair: 13.250736 -> 13.119409 ms, 1.010010x measured on gfx1151.
- precise-wait production candidate: accepted based on bit-exact raw and graph output, rocprofv3 cycle reduction, and positive eager and graph-enabled serving A/B.

## Evidence

- Production ASM: `kernels/gfx1151/mxfp4/serving/mxfp4_sgl_linear_prefill_wmma_gfx1151.s`
- Experimental ASM ledger: `kernels/gfx1151/mxfp4/serving/experiments/`
- HIP-event and graph harness: `harness/gfx1151/mxfp4/serving/benchmark_linear_prefill_pair2_pipe_a.hip`
- Single-kernel counter driver: `harness/gfx1151/mxfp4/serving/linear_prefill_counter_driver.hip`
- HSACO-capable serving A/B driver: `scripts/rocm/tools/benchmark/benchmark_runtime_serving_ab.sh`
- Reproducible rocprofv3 counter driver: `scripts/rocm/tools/profiling/profile_linear_prefill_pair2_pipe_counters.sh`
- Counter, serving, and full-trace JSON: `docs/netra/notes/gfx1151-linear-prefill-pair2-pipe-results-2026-07-31/`
- Before/after disassembly: `docs/netra/notes/gfx1151-linear-prefill-pair2-pipe-disassembly-2026-07-31/`
