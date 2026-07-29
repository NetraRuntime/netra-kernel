# Raw gfx1151 extend-attention result (2026-07-29)

All runtime durations in this note are measured on gfx1151 with HIP events.
No runtime value is estimated. Static instruction counts are explicitly labeled.

## Ranked-path context

SGLang's Triton `_fwd_kernel` for batch 1, Hq=16, Hkv=2, D=256,
BF16 causal extend attention was rank 1 in the measured exact 32,768/+1 trace:
40 invocations, 8,824.300 ms total, and 25.32% of host end-to-end time.
The real chunk shape is M=8,192 with prefix tiers 0/8,192/16,384/24,576.

## Accepted raw kernel

`scripts/rocm/extend_attention_wmma_n64_gfx1151.s` is hand-written AMDGCN
for gfx1151. It uses M64xN64 tiles, four wave32 waves, 64 KiB LDS, raw BF16
WMMA, causal masking, online softmax, paged prefix loads, and direct BF16 output.
K/V global loads are staged 8 or 16 at a time. QK and PV LDS operands are
double buffered across WMMA issue. Prefix length is loaded from device
`kv_indptr[1]`, so graph replay performs no `.item()` or host synchronization.

| Prefix | Raw median ms | Triton median ms | Speedup | Status |
|---:|---:|---:|---:|---|
| 0 | 46.988 | 47.858 | 1.0185x | gfx1151 measured, 20 samples |
| 8,192 | 134.587 | 165.071 | 1.2265x | gfx1151 measured |
| 16,384 | 229.024 | 278.695 | 1.2169x | gfx1151 measured |
| 24,576 | 323.871 | 391.470 | 1.2087x | gfx1151 measured |
| Four chunks | 734.469 | 883.090 | 1.2024x | gfx1151 measured sum |

At prefix 0, raw max absolute error versus FP32 is 1.2598e-4 and normalized
L2 is 1.8740e-3. At prefixes 8K/16K/24K, raw max difference versus Triton is
3.8147e-6/1.9073e-6/1.9073e-6 respectively.

## Real-checkpoint full-request validation

The graph-disabled, dFlash-disabled real checkpoint passed exact 32,768 input
+1 output with zero cached tokens on gfx1151. Host serving end-to-end time was
32,709.365 ms measured, completion count was exactly one, and the request had
zero retractions. Peak process-visible VRAM from the container sysfs sampler was
61,195,784,192 bytes; this is unified-memory accounting, not dedicated VRAM.

A separate process-start rocprofv3 run of the same exact token counts measured
34,232.846 ms host end-to-end. The trace contains 40 invocations of the raw
`extend_attention_wmma_n64_gfx1151` symbol, proving that the narrow SGLang
dispatch did not silently fall back to Triton. Those 40 calls cost 7,336.823 ms
total GPU time, or 21.985% of total traced kernel time. The raw kernel remained
rank 1; `chunk_fwd_kernel_o` became rank 2 at 3,978.250 ms.

The paired full-request A/B used identical input IDs (matching SHA-256) and
produced identical output text (matching SHA-256). Triton attention measured
34,761.266 ms and raw ASM measured 32,709.365 ms. Raw is 2,051.901 ms faster:
1.0627x end-to-end, or 5.90% lower latency, gfx1151 measured. Both runs were
uncached, graph disabled, dFlash disabled, exact 32,768 input +1 output, and had
zero retractions.

The compact full-request trace summary is
`docs/netra/notes/gfx1151-extend-attention-full-request-2026-07-29.json`.
Raw process-start trace CSV files remain under
`results/profiles/gfx1151/raw-attention-32k-start/`.

## Graph validation

The actual SGLang custom-op boundary was captured and replayed with stable
pointers. Prefix-0 replay is bit exact to eager raw output and has a measured
46.478 ms median. A graph captured with prefix 0 was replayed after only the
device value `kv_indptr[1]` changed to 8,192; replay measured 134.194 ms and
matched Triton within 3.8147e-6. Module loading occurs in model initialization.

## Concrete disassembly changes

These are static gfx1151 disassembly counts, not runtime measurements:

| Metric | Triton 64x64/4-wave | Raw ASM | Change |
|---|---:|---:|---:|
| Instructions | 13,651 | 6,444 | -52.8% |
| Scratch loads/stores | 377 / 467 | 0 / 0 | eliminated |
| `s_waitcnt` | 1,227 | 345 | -71.9% |
| `s_delay_alu` | 933 | 0 | eliminated |
| Barriers | 11 | 5 | -54.5% |
| LDS operations | 2,481 | 1,316 | -47.0% |

Before/after disassemblies and machine-readable counts are under
`docs/netra/notes/disassembly/gfx1151-extend-attention-2026-07-29/` and
`docs/netra/notes/gfx1151-extend-attention-final-disassembly-2026-07-29.json`.

## Negative variants retained

- N16, 50 KiB LDS: correct, but M8192 prefix 0 measured 62.470 ms versus
  47.892 ms Triton (0.7666x). Rejected because LDS residency and serialized
  staging dominate despite strong M64 timing.
- Initial N64, 64 KiB LDS: correct, but measured 62.599 ms versus 47.880 ms
  (0.7649x). Batched loads and QK/PV double buffering converted this design
  into the accepted kernel.
- N32, 20 KiB LDS with direct Q reload: correct after fixing a P-workspace
  register collision, but measured 114.565 ms versus 47.837 ms (0.4176x).
  Repeated Q traffic overwhelmed the occupancy benefit; rejected.
- Compiler-generated 64x32/eight-wave Triton remains a design oracle only.
  It is not an accepted compute implementation.

## Integration scope

The SGLang dispatch is deliberately narrow: batch 1, exact 8,192-token BF16
chunk, Hq=16, Hkv=2, D=256, causal, page size 1, contiguous tensors, unit K/V
scales, and no custom masks, sinks, LSE, score modification, or skip stage.
Every other case falls back to Triton. `scripts/rocm/sglang_extend_attention_gfx1151.patch`
contains the SGLang source patch; the launch/custom-op bridge is in
`integrations/sglang/` and the reproducible build is
`tools/build/build_netra_sglang_gfx1151.sh`.

## Profiler attach negative result

Attaching wheel rocprofv3 7.13.0 to the already-running scheduler is unsafe on
this stack. Registration through rocattach failed with status 6 after ptrace
killed the scheduler with signal 11. The earlier repeated `rocprofv3 caught
signal 6` output was the profiler's installed SIGABRT handler recursively
handling an abort from a Python multiprocessing resource-tracker process, not a
GPU-kernel assertion. Process-start profiling is the retained path, and the
attach script disables rocprofv3 signal handlers to prevent recursive logging.
