# gfx1151 BF16 router batch-four scheduling — 2026-07-31

Status: **accepted, measured on gfx1151**. Model: Qwen3.6-35B-A3B with checkpoint-native MXFP4 weights; the model-native MoE router projection remains BF16 input/weights with FP32 output. No alternate checkpoint quantization was tested.

## Raw kernel change

`bf16_router_decode_wave2_fp32_gfx1151` now issues four original coalesced activation and two-row weight K tiles before each full dependency wait. The K loop changes from 32 single-tile wait groups to 8 four-tile groups. Lane-to-K ownership, per-accumulator dot order, FP32 reduction order, output layout, and top-k consumer are unchanged.

The shared library retains the exact prior 30-symbol `netra_*` export table. The exported kernel symbol, 24-byte/8-byte-aligned three-pointer kernarg ABI, module grid `(16,1,1)` (4,096 total workitems), workgroup `(256,1,1)`, wave32 mode, caller HIP stream, zero LDS/scratch, preload order, and stable graph-pool pointers are unchanged. Source metadata rises from 18 to 22 VGPR, but rocprofv3 reports the same 24-VGPR and 128-SGPR allocation granules. HSACO SHA-256 changes from `f1371c14dd50265ce7d2827a2a4c9e63e86f3b4d965b442b7dbd0051fcb8ccd8` to `29d4777f7493ca461df8b68b7303722cb2d0bbb0c0587155d0d2697d71c16332`.

## Correctness

- **Measured gfx1151 old/new raw:** all 40 real checkpoint router layers, 10,240 FP32 outputs, zero bit mismatches and maximum absolute difference 0.
- **Measured gfx1151 FP64 reference:** all 40 layer top-8 expert sets match FP64; maximum absolute FP32-vs-FP64 logit error is `5.386536940932274e-07`.
- **Measured gfx1151 serving:** eager 1+128, full-graph 1+128, and eager 210+128 produced exact old/new output-token hashes for every paired input. The generated Qwen output is unchanged by this optimization.

## HIP events and rocprofv3 counters

The rotating real-checkpoint all-40-layer HIP-event A/B measures `1.042637 -> 0.570822 ms`, **1.82654x measured on gfx1151**.

Every rocprofv3 counter was collected in a fresh process with signal handlers disabled. Both kernels launch 128 waves and fetch nearly identical bytes.

| gfx1151 measured counter | baseline | batch-four |
|---|---:|---:|
| fetched KiB | 514.563 | 514.719 |
| L2 hit | 7.323% | 7.505% |
| mean occupancy / active CU | 7.796 | 7.633 |
| occupancy | 6.085% | 4.221% |
| memory-unit busy | 58.283% | 36.728% |
| waves | 128 | 128 |
| wave cycles | 2,666,036.5 | 1,163,684 |
| VALU instructions | 202 | 130 |
| allocated VGPR / SGPR | 24 / 128 | 24 / 128 |

SQ wave cycles fall **56.351% measured on gfx1151** and VALU instructions fall 35.644%. The lower sampled occupancy and memory-unit busy do not reflect a larger allocation granule; the same waves finish sooner. The available gfx1151 metric set exposes no direct dependency-stall percentage, so none is estimated. `WRITE_SIZE` reported zero for both and is not used.

## Complete eager trace

The fresh exact 1 input + 32 output eager rocprofv3 request window is uncached with dFlash disabled. It measures 32,203 launches, `733.171 ms` summed GPU kernels, `128.504 ms` positive launch gaps, and `845.353 ms` host request wall. The raw router measures 1,320 calls, `17.655 ms` total, `13.375 us` mean, and `13.144 us` median. The preceding accepted trace measured the same 1,320 calls at approximately `30.483 ms` total; the derived request-level router-total reduction is **42.08% measured on gfx1151**. Because the full traces are independent profiler runs, their total request wall times are not treated as an A/B claim.

The router moves from rank 7 to rank 12 by total GPU time. Current higher totals are LM head `159.975 ms`, QKV `99.050 ms`, GDN N=12800 MXFP4 projection `68.995 ms`, shared gate/up `67.392 ms`, routed gate/up `66.532 ms`, attention output `48.896 ms`, routed down `39.029 ms`, GDN N=2048 MXFP4 projection `25.910 ms`, shared down `24.106 ms`, recurrent GDN `21.589 ms`, and MXFP4 N=2048 reduction `18.251 ms`, all measured on gfx1151.

## Uncached serving A/B

Every row is **measured on gfx1151**, four interleaved paired cases, exact requested token counts, cached tokens 0, dFlash disabled, and bit-exact old/new token hashes.

| Scenario | Graph | Old median host E2E | New median host E2E | Delta | Old -> new output tok/s |
|---|---:|---:|---:|---:|---:|
| 1 input + 128 output | disabled | 3048.108 ms | 2994.286 ms | -1.766% | 42.622 -> 43.286 |
| 1 input + 128 output | full decode tiers | 3054.592 ms | 2990.373 ms | -2.102% | 42.281 -> 43.187 |
| 210 input + 128 output | disabled | 3451.612 ms | 3387.415 ms | -1.860% | 42.013 -> 42.876 |

For eager 1+128, median TTFT is `66.545 -> 60.350 ms` and decode wall is `2979.678 -> 2934.004 ms`. For eager 210+128, median TTFT is `429.392 -> 424.799 ms`, input throughput is `489.395 -> 494.537 tok/s`, and decode wall is `3022.880 -> 2962.057 ms`. This M=1 replacement does not claim a prefill-kernel gain.

The newest measured non-speculative batch-1 rate is **43.286 tok/s eager on gfx1151**; full graph is **43.187 tok/s measured on gfx1151**. The 50 tok/s target remains incomplete.

## Full graph gate

Native SGLang full decode graphs captured tiers 1/2/4/8/12/16 before requests. Old capture measured 3.05/2.81 s with 0.18/0.17 GB reported graph memory; candidate capture measured 2.85/2.77 s with 0.17/0.17 GB. Capture-time launch paths made no new allocation, module load, tensor query, synchronization, or runtime registration mutation. Replay retained the caller stream and produced exact tokens. Whole-APU sysfs peak-VRAM readings varied materially between server processes and are retained in raw artifacts rather than attributed to this zero-workspace kernel.

## SGLang versus llama.cpp interpretation

The comparison target is llama.cpp, not vLLM. In the current eager trace, positive GPU launch gaps are 15.20% of the profiler request wall; this is material but cannot alone explain a much larger unmatched llama.cpp advantage. A fair attribution needs identical Qwen3.6 checkpoint semantics and must separate SGLang scheduling from llama.cpp kernel coverage, quantized-operation coverage, fusion, and fixed-shape execution. No matched llama.cpp/SGLang throughput ratio is claimed here.

## Evidence

- Raw kernel: `kernels/gfx1151/moe/bf16_router_decode_wave2_fp32_gfx1151.s`
- Production FP64 validator: `scripts/rocm/harness/gfx1151/dense/validate_bf16_router_decode.py`
- Counter driver: `scripts/rocm/harness/gfx1151/dense/bf16_router_decode_counter_driver.hip`
- Counter script: `scripts/rocm/tools/profiling/profile_bf16_router_counters.sh`
- Counters: `results/profiles/gfx1151/bf16-router-{prebatch4,batch4}-counters-20260731`
- Complete trace: `results/profiles/gfx1151/router-batch4-current-exact1-in-32-out-eager-20260731`
- Eager 1+128 A/B: `results/runtime/gfx1151/runtime-refactor-working-new/serving-ab/router-batch4-eager-1-plus128-20260731`
- Full-graph 1+128 A/B: `results/runtime/gfx1151/runtime-refactor-working-new/serving-ab/router-batch4-fullgraph-1-plus128-20260731`
- Eager 210+128 A/B: `results/runtime/gfx1151/runtime-refactor-working-new/serving-ab/router-batch4-eager-210-plus128-20260731`
- Before/after disassembly: `docs/netra/notes/gfx1151-bf16-router-batch4-disassembly-2026-07-31/`
