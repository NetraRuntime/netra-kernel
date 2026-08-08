# gfx1151 BF16 shared-down batch-four scheduling — 2026-07-31

Status: **accepted, measured on gfx1151**. Model: Qwen3.6-35B-A3B with checkpoint-native MXFP4 weights; this model-native shared-expert down projection is BF16. No alternate checkpoint quantization was tested.

## Raw kernel change

`bf16_shared_down_decode_wave4_gfx1151` now issues four original coalesced `global_load_b32` K tiles before each full dependency wait. Lane-to-K ownership and per-accumulator dot order are unchanged, so the established wave reduction tree is preserved exactly. The exported symbol, 24-byte/8-byte-aligned kernarg ABI, grid `(64,1,1)`, workgroup `(256,1,1)`, wave32 mode, caller stream, output layout, zero LDS/scratch, preload order, and graph-pool pointers are unchanged.

Metadata-visible VGPRs rise from 18 to 34; rocprofv3 allocation rises from 24 to 40 VGPR. HSACO SHA-256 changes from `d62461d6...af0fe` to `81bf7498...bfcb4`.

## Correctness

- **Measured gfx1151 old/new raw:** all 40 real checkpoint layers, 81,920 BF16 values, zero bit mismatches and max absolute difference 0.
- **Measured gfx1151 model-native reference:** the production validator retains max absolute difference `0.001953125` and at most two BF16 differences per layer against rocBLAS, matching the accepted raw-kernel envelope.
- **Measured gfx1151 serving:** eager 1+128, full-graph 1+128, and eager 210+128 each produced exact old/new output-token hashes in all four paired cases.

## HIP events and counters

The rotating all-40-layer raw A/B measures `0.994820 -> 0.726230 ms`, **1.36984x**. The independent production validator measures the new raw kernel at `0.731208 ms` versus rocBLAS `1.291736 ms`, **1.76658x**.

rocprofv3 counters used one metric per fresh process with signal handlers disabled. Fetch remains `1025.656 KiB` and wave count remains 512. VALU instructions fall `168 -> 138` (-17.86%) and SQ wave cycles fall `38,869,152 -> 26,490,077.5` (-31.85%). The available gfx1151 metric set exposes no direct dependency-stall percentage, so none is estimated.

## Uncached serving A/B

Every row is **measured on gfx1151**, four paired cases, exact requested tokens, cached tokens 0, dFlash disabled.

| Scenario | Graph | Old median host E2E | New median host E2E | Delta | Old -> new output tok/s |
|---|---:|---:|---:|---:|---:|
| 1 input + 128 output | disabled | 3080.298 ms | 3040.717 ms | -1.285% | 42.088 -> 42.630 |
| 1 input + 128 output | full decode tiers | 3092.132 ms | 3061.029 ms | -1.006% | 41.743 -> 42.153 |
| 210 input + 128 output | disabled | 3474.626 ms | 3438.478 ms | -1.040% | 41.636 -> 42.197 |

For eager 1+128, median TTFT is `62.082 -> 61.926 ms` and decode wall is `3017.472 -> 2979.113 ms`. For eager 210+128, median TTFT is `424.541 -> 428.845 ms` and input throughput is `494.780 -> 489.963 tok/s`; this M1 replacement does not claim a prefill gain.

Full decode graph captured all tiers on both variants. Old capture was 2.94/2.82 s, new capture 2.80/2.80 s, and reported graph memory was 0.17 GB. Candidate graph remains slower than candidate eager at batch 1, but replay is correct and preserves the kernel gain.

## Complete trace and next rank

The exact 1 input + 32 output eager request window measures 31,662 launches, `729.617 ms` total GPU kernel time, `101.441 ms` positive launch gaps, and `824.270 ms` wall. Shared-down falls from `32.904 ms` total / `25.156 us` mean to `23.576 ms` / `18.191 us`.

The next measured totals are LM head `159.888 ms`, QKV `97.834 ms`, N12800 GDN projection `67.972 ms`, shared gate/up `67.003 ms`, routed gate/up `66.462 ms`, attention output `48.028 ms`, and routed down `37.308 ms`. The 50 tok/s goal remains incomplete.

## Negative ledger

- LM-head batch-two `b32` was bit-exact but 1.35% slower; its unrolled pipeline gained only 0.12%, inside noise.
- QKV batch-two was bit-exact but gained only 0.24%, inside noise; its unrolled pipeline was 0.79% slower.
- Routed gate chunk persistence factors two and four were bit-exact but 4.80% and 9.37% slower.
- Splitting shared gate/up weight streams reduced VGPRs and stayed bit-exact, but was 3.96% slower.
- Shared-down `b64` and `b128` measured 1.099x and 1.450x, but changed lane partitioning and produced 8 and 7 BF16 differences versus the established raw tree. Both are rejected; `b128` is faster than the accepted exact candidate but fails the stronger exactness gate.
- Exact shared-down batch-two measured 1.077x and is rejected because exact batch-four is faster at 1.370x.

## Evidence

Machine-readable results are in `gfx1151-bf16-shared-down-batch4-2026-07-31.json`. Before/after disassembly, metadata, hashes, and diff are in `gfx1151-bf16-shared-down-batch4-disassembly-2026-07-31/`. Raw counter, serving, and trace artifacts remain under `results/` inside Netra.
