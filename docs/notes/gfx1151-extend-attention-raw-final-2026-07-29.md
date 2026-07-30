# Raw gfx1151 extend-attention result (2026-07-29)

All runtime durations in this note are measured on gfx1151 with HIP events.
No runtime value is estimated. Static instruction counts are explicitly labeled.

## Ranked-path context

SGLang's Triton `_fwd_kernel` for batch 1, Hq=16, Hkv=2, D=256,
BF16 causal extend attention was rank 1 in the measured exact 32,768/+1 trace:
40 invocations, 8,824.300 ms total, and 25.32% of host end-to-end time.
The real chunk shape is M=8,192 with prefix tiers 0/8,192/16,384/24,576.

## Accepted raw kernel

`kernels/gfx1151/attention/extend_attention_wmma_n64_gfx1151.s` is hand-written AMDGCN
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
`docs/notes/gfx1151-extend-attention-full-request-2026-07-29.json`.
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
`docs/notes/disassembly/gfx1151-extend-attention-2026-07-29/` and
`docs/notes/gfx1151-extend-attention-final-disassembly-2026-07-29.json`.

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
Every other case falls back to Triton. `scripts/rocm/integrations/sglang/sglang-gfx1151-extend-attention.patch`
contains the SGLang source patch; the launch/custom-op bridge is in
`scripts/rocm/integrations/sglang/` and the reproducible build is
`scripts/rocm/tools/build/build_netra_sglang_gfx1151.sh`.

## Profiler attach negative result

Attaching wheel rocprofv3 7.13.0 to the already-running scheduler is unsafe on
this stack. Registration through rocattach failed with status 6 after ptrace
killed the scheduler with signal 11. The earlier repeated `rocprofv3 caught
signal 6` output was the profiler's installed SIGABRT handler recursively
handling an abort from a Python multiprocessing resource-tracker process, not a
GPU-kernel assertion. Process-start profiling is the retained path, and the
attach script disables rocprofv3 signal handlers to prevent recursive logging.

## Accepted scalar causal-mask fast path

All durations below are measured on gfx1151; none are estimated. The original
raw kernel performed per-score causal address arithmetic, comparison, and
`v_cndmask` for every 64-key tile. With the exact 8192-token chunk geometry,
only the single diagonal current-chunk tile in each query block can be
partially causal. Prefix tiles and earlier current tiles are fully valid.

The accepted revision compares the key-tile scalar index against
`prefix + query_block_start`. Full tiles execute only score scaling; the
existing elementwise causal path remains unchanged for the diagonal tile.
Static source expansion removes seven vector instructions per score from the
executed full-tile path (224 vector instructions per full tile), at the cost
of one scalar add, compare, and branch. This instruction delta is static
analysis; all timing claims are measured.

| Prefix | Previous raw median ms | Mask-fast median ms | Improvement | Status |
|---:|---:|---:|---:|---|
| 0 | 46.988 | 45.483 | 1.0331x | gfx1151 measured, HIP events |
| 8,192 | 134.587 | 130.316 | 1.0328x | gfx1151 measured, HIP events |
| 16,384 | 229.024 | 224.024 | 1.0223x | gfx1151 measured, HIP events |
| 24,576 | 323.871 | 315.926 | 1.0251x | gfx1151 measured, HIP events |
| Four chunks | 734.469 | 715.748 | 1.0262x | gfx1151 measured sum |

All four exact-shape output byte hashes were bit-identical to the previously
accepted raw kernel. The max differences versus Triton were 1.2207e-4 at
prefix zero and 3.8147e-6/3.8147e-6/1.9073e-6 at prefixes 8K/16K/24K.
The larger prefix-zero difference is the existing accepted BF16-vs-FP32
behavior, not introduced by this change.

A normally finalized process-start rocprofv3 trace measured 40 calls at
7,156.497 ms total, down from 7,324.711 ms for the same symbol and exact input
in the immediately preceding trace. This removes 168.214 ms of GPU work and
is a measured 1.0235x kernel-family improvement on gfx1151.

Two paired non-profiled exact 32768/+1 uncached requests measured old/new TTFT
of 30,094.222/29,930.157 ms and 29,959.600/29,806.836 ms. Greedy output token
IDs matched in both pairs. Mean TTFT improved from 30,026.911 to 29,868.496 ms:
158.415 ms, 1.00530x, or 0.5276% lower end-to-end latency. Graph mode and
dFlash were disabled for these serving pairs.

The stable-pointer custom-op launch also passed graph capture/replay. Prefix-0
and prefix-8192 replay were bit-identical to eager output after changing only
the device `kv_indptr` value. Prefix-8192 graph replay measured 130.799 ms
median over seven HIP-event samples. No allocation, `.item()`, or host
synchronization was added to the captured path.

## Accepted qpipe8 follow-up (2026-07-30)

The production raw N64 kernel now batches the prologue and per-tile Q restore
loads eight at a time. Exact T8192 four-tier HIP-event cost improves 696.698 to
679.227 ms (1.0257x), and two exact 32K/+1 matched real-checkpoint pairs improve
mean host E2E 24,227.707 to 23,304.863 ms with identical greedy outputs. Graph
replay remains byte-identical. All runtime values are measured on gfx1151; see
`docs/notes/gfx1151-extend-attention-qpipe8-2026-07-30.md` for full evidence.
