# gfx1151 routed gate/up batch-eight load scheduling — 2026-07-31

Status: **accepted, measured on gfx1151**. Model: Qwen3.6-35B-A3B with checkpoint-native MXFP4 weights. No alternative quantization was tested.

## Change

The raw AMDGCN `mxfp4_decode_gate_chunk4_gfx1151` kernel now issues eight packed-weight and BF16-activation load pairs before each full dependency wait. Arithmetic order and the existing reduction tree are unchanged. The exported symbol, 40-byte/8-byte-aligned kernarg ABI, grid `(1,128,1)`, workgroup `(128,1,1)`, wave32 mode, zero LDS, zero scratch, workspace, stream, and graph integration remain unchanged.

The metadata-visible live register counts rise from 34 VGPR/26 SGPR to 40 VGPR/32 SGPR, but both code objects occupy the same gfx1151 allocation granules reported by rocprofv3 (40 VGPR/128 SGPR). The candidate shortens the function from 3988 to 3964 bytes. HSACO SHA-256 changes from `7ebefa5a...abad14` to `b712e54a...0e451`.

## Correctness gates

- **Measured gfx1151:** all 40 real checkpoint layers, gate and up projections, 327,680 FP32 values: zero bit mismatches and max absolute difference 0.
- **Measured gfx1151 FP64 oracle:** both old and new have max absolute error `9.596347809e-6` and mean absolute error `1.458880433e-6`; old/new output is bit-exact.
- **Measured gfx1151 serving:** all four paired eager cases, all four paired full-graph cases, and all four paired 210+128 cases have identical deterministic output-token hashes.

## Isolated performance

HIP events, 20 interleaved samples over the 40-layer real-checkpoint path (80 gate/up compute+reduce pairs): `2.848267 -> 2.313804 ms`, **1.23099x**, saving `0.534463 ms` per decode-token-equivalent. The synthetic FP64-oracle fixture measures `13.69554 -> 12.45053 us` per pair, **1.10000x**.

rocprofv3 used one counter per fresh process with signal handlers disabled. Fetch remains `2180.5625 KiB`, waves remain `512`, and VALU instructions remain `1600`; SQ wave cycles fall `18,143,345 -> 16,452,879` (**-9.32%**). No direct gfx1151 dependency-stall counter is exposed by the available metric set.

## Uncached serving A/B

All rows are **measured on gfx1151**, dFlash disabled, four paired cases, exact requested lengths, zero cached tokens.

| Scenario | Graph | Old median host E2E | New median host E2E | Delta | Old -> new output tok/s |
|---|---:|---:|---:|---:|---:|
| 1 input + 128 output | disabled | 3151.109 ms | 3074.640 ms | -2.427% | 41.129 -> 42.186 |
| 1 input + 128 output | full decode tiers | 3170.706 ms | 3093.747 ms | -2.427% | 40.735 -> 41.721 |
| 210 input + 128 output | disabled | 3543.412 ms | 3479.594 ms | -1.801% | 40.755 -> 41.673 |

For 210+128 eager, median TTFT is `426.888 -> 428.190 ms` and median input throughput is `492.147 -> 490.776 tok/s`; the change targets decode and does not claim a prefill gain. Candidate full graph remains slower than candidate eager for 1+128 (`3093.747` versus `3074.640 ms`).

## Complete request trace and remaining rank

The valid process-start rocprofv3 trace for exact 1 input + 32 output, eager, measures 31,926 kernel launches, `739.522 ms` total kernel GPU time, `103.676 ms` positive launch gaps, and `837.557 ms` request-window wall time. Gate compute is now `69.287 ms` total at `26.486 us` mean over 2,616 calls. Previous production trace measured `83.912 ms` and `32.003 us` mean.

The next measured kernel totals are LM head `159.786 ms`, QKV `96.415 ms`, routed gate/up `69.287 ms`, N12800 GDN projection `68.696 ms`, and shared-expert gate/up `67.322 ms`. Dispatch gaps are material, but kernel GPU time remains the dominant budget; full graph not improving serving confirms that scheduler-only work cannot close the remaining decode gap.

## Negative ledger

- N12800/K2048 load batching at WG128/64/32 was bit-exact across 30 real GDN layers; best total-path result was only 1.01427x and overlapped noise. Rejected.
- N12800 persistence factors 2/4/8/16, including batch2/batch4, were bit-exact but neutral to 6.8% slower. Rejected.
- LM-head WG256 with 4 KiB LDS activation reuse was bit-exact across ten activations and argmax, but regressed `5.010920 -> 5.246644 ms` (+4.70%). Rejected.
- Router wave1 was FP32/top8 bit-exact across all 40 layers, but regressed `1.049010 -> 1.081189 ms` per 40 layers (+3.07%). Rejected.
- A windowed rocprofv3 request completed but the profiler exited 137 without a kernel CSV. It is explicitly rejected. The process-start trace emitted valid kernel/HIP CSV and is the trace used above.

## Artifacts

Before/after disassembly, metadata, hashes, and diff are in `gfx1151-gate-chunk4-batch8-disassembly-2026-07-31/`. Machine-readable results are in `gfx1151-gate-chunk4-batch8-2026-07-31.json`. Raw profiler and serving artifacts remain under `results/profiles/gfx1151/` and `results/runtime/gfx1151/` in Netra.
