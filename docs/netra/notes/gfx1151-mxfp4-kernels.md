# gfx1151 raw-ASM MXFP4 kernels

All numbers below are measured on the Radeon 8060S in the Ryzen AI Max+ PRO
395 (`gfx1151`, 40 CUs/20 WGPs). Times use HIP events or `rocprofv3`; host
wall-clock timing is not used. Weight buffers rotate over more than the 32 MiB
Infinity Cache unless explicitly noted.

This repository contains hand-written AMDGCN `.s` kernels, launch/check/timing
HIP harnesses, one-time Qwen3.6 checkpoint repackers, measured result data and
the complete optimization log. HIP sources do not implement matrix kernels.
Checkpoint tensors and generated code objects are intentionally not committed.

## Established ceilings

Measured on 2026-07-28 in the Netra LXC with ROCm 7.2.1:

| gfx1151 measurement | Result |
|---|---:|
| Back-to-back f16 WMMA issue rate | 55.3 TFLOP/s |
| Back-to-back BF16 WMMA issue rate | 55.2 TFLOP/s |
| FP32 VALU FMA issue rate | 13.7 TFLOP/s |
| `v_perm_b32` issue rate | 6.5 TOP/s |
| 2 GiB streaming reads | 222.4 GB/s |

The streaming probe is 64 times larger than the 32 MiB Infinity Cache. Its
best result was 9,657.0 us for 2 GiB, or 222.4 GB/s on gfx1151.

## Reproduced compiler decode baseline

The existing `mxfp4_gemv_gfx1151.hip` kernel reproduced at N=K=16,384:

- HIP event, measured on gfx1151: 762.3 us, 176.1 GB/s.
- Correctness, measured against an fp64 host reference: worst relative error
  1.401e-6.
- `rocprofv3` run: the event result was 769.0 us and 174.5 GB/s.

The benchmark rotates three 136 MiB MXFP4 weight-plus-scale sets, so this is a
memory result rather than an Infinity Cache result.

## Compiler disassembly diagnosis

The compiler-generated MXFP4 kernel has 2,378 static instructions in its
fully-unrolled MX-block loop body and surrounding control path:

| gfx1151 compiler output | Static count |
|---|---:|
| Explicit `s_delay_alu` | 472 |
| Unpack-class shifts, bitfields, masks and selects | 723 |
| `s_waitcnt` | 32 |
| Vector/global loads | 25 |
| FP32 compare instructions used by decode | 244 |
| VGPRs | 26 |

Concrete problems found in the disassembly:

1. E2M1 is reconstructed independently for every scalar weight. This produces
   hundreds of shifts, bitfields, compares, conditional selects and explicit
   dependency delays per MX block.
2. BF16 activation values are fetched through identical per-lane vector
   loads instead of uniform scalar loads.
3. Every packed-weight load reaches `vmcnt(0)` before its decode begins.
4. Four output atomics compile into four load/CAS retry loops instead of the
   native non-returning gfx1151 global FP32 atomic instruction.

These observations determine the raw-assembly changes below.

## Raw-ASM decode gate/up specialization

Files:

- `scripts/rocm/mxfp4_decode_gate_gfx1151.s`
- `scripts/rocm/mxfp4_decode_gate_gfx1151.hip`
- `scripts/rocm/extract_qwen36_gate_mxfp4.py`

The kernel is raw AMDGCN assembly. The HIP file only loads the code object,
launches it, checks it and times it.

The fixed shape is the actual Qwen3.6-35B-A3B decode gate/up operation:
8 selected experts, N=512 and K=2048. The loader transposes the checkpoint's
packed bytes and E8M0 scales once, without dequantizing them.

### Assembly changes and disassembly diff

The raw inner path uses byte lookup tables with `v_perm_b32` to construct exact
packed BF16 E2M1 pairs, followed by `v_dot2_f32_bf16`. Activations use uniform
scalar loads. Two weight/activation rows are software-pipelined at a time.
The split-K epilogue uses four native non-returning
`global_atomic_add_f32` instructions.

| Static disassembly count | Compiler | Raw ASM |
|---|---:|---:|
| Instructions | 2,378 | 496 |
| Permutes | 0 | 192 |
| Packed BF16 dot2 | 0 | 64 |
| Wait-class instructions | 32 | 19 |
| Loads | 30 | 35 |
| Atomics | 4 CAS loops | 4 native atomic instructions |
| VGPRs | 26 | 34 |

The static raw counts include one unrolled 32-value MX block; its scalar loop
executes 32 times per K split.

### Measurements

Matched real-shape compiler baseline: eight sequential compiler-kernel calls,
rotating 144 expert buffers. `rocprofv3` measured 50.682 us per expert over
the final 80 calls, or 405.456 us per eight-expert operation on gfx1151.
The matching HIP-event result was 416.7 us.

The first correct raw schedule deliberately used full dependency drains:

- `rocprofv3`, measured on gfx1151: 163.521 us average.
- HIP event, measured on gfx1151: 169.542 us.
- Effective traffic rate: 26.4 GB/s.

This was a useful negative result: raw assembly alone was not sufficient.
The full dependency drains and serialized row loads made the raw kernel slow.

After removing unnecessary ALU drains and pipelining two rows:

- `rocprofv3`, final 30 timed calls on gfx1151: 77.978 us mean, 83.998 us
  median, 48.531 us minimum and 86.122 us maximum.
- Effective traffic rate from the rocprof mean: 57.4 GB/s.
- Improvement over the matched eight-expert compiler baseline:
  **5.20x measured on gfx1151**.
- HIP event, separate 100-iteration run on gfx1151: 90.721 us and
  49.3 GB/s.

The raw result includes one grouped launch while the previous compiler kernel
requires eight launches. The speedup therefore includes both the ISA changes
and removal of seven launches; it is not presented as a pure instruction-only
speedup.

### Correctness gates

Synthetic MXFP4 with varying E8M0 scales, measured against fp64 at the complete
8×512×2048 shape:

- maximum absolute error: 1.900196e-4
- maximum relative error: 4.214233e-4

Real layer-0 checkpoint gate weights for experts 0–7, extracted directly from
the 26-shard model and measured against fp64:

- scale range: 103 through 121
- maximum absolute error: 6.332994e-8
- maximum relative error: 4.365097e-5
- `rocprofv3`, final 30 real-weight calls on gfx1151: 78.133 us mean,
  83.817 us median, 48.491 us minimum and 85.601 us maximum
- HIP-event performance on real weights: 85.860 us and 52.1 GB/s on gfx1151

## Remaining work

## Raw-ASM decode down-projection specialization

Files:

- `scripts/rocm/mxfp4_decode_down_gfx1151.s`
- `scripts/rocm/mxfp4_decode_down_gfx1151.hip`

This is the complementary real expert shape: 8 selected experts, N=2048 and
K=512. Sixteen workgroups cover the output without split K. That removes the
output clear and all atomics; the epilogue is four coalesced direct stores per
lane.

The same exact packed-BF16 E2M1 construction is used, but packed-weight rows
are 2,048 bytes apart. Loads issue in pairs and the scalar packed-weight base
advances while those loads are outstanding.

Raw down-projection disassembly on gfx1151:

| Static item | Count |
|---|---:|
| Instructions | 498 |
| `v_perm_b32` | 192 |
| `v_dot2_f32_bf16` | 64 |
| Wait-class instructions | 14 |
| Loads | 35 |
| Direct stores | 4 |
| Atomics | 0 |
| VGPRs | 34 |

Synthetic full-shape correctness against fp64:

- maximum absolute error: 6.437302e-5
- maximum relative error: 1.762983e-4

Real layer-0 down weights for experts 0–7:

- E8M0 scale range: 116 through 122
- maximum absolute error: 2.421439e-8
- maximum relative error: 1.142645e-3; this occurs on a near-zero fp64
  reference, while the absolute error is 2.42e-8
- `rocprofv3`, final 30 real-weight calls on gfx1151: 43.167 us mean,
  46.086 us median, 25.327 us minimum and 47.850 us maximum
- HIP event on real weights: 45.854 us and 98.6 GB/s

The matched compiler baseline rotates 144 expert buffers and launches eight
expert kernels per operation. Its final 80 profiled expert calls average
14.990 us each, or 119.916 us for eight experts. The raw grouped kernel is
therefore **2.78x faster, measured with rocprofv3 on gfx1151**.

## Remaining work

Both decode expert matrix orientations now have passing raw-ASM kernels.
Still required: M=12 speculative verification, grouped prefill, the MXFP4
LM-head case, standalone versus fused measurements for each, and matched
`rocprofv3` runs on real checkpoint data.

## M=12 verify work in progress

`scripts/rocm/mxfp4_verify_gate_gfx1151.s` is the first raw-ASM correctness
reference for E=8, M=12, N=512, K=2048. Unlike twelve decode calls, it decodes
each packed weight once and reuses it across all twelve BF16 activation rows.

Real layer-0 gate weights pass the fp64 gate:

- maximum absolute error: 1.266599e-7
- maximum relative error: 1.792436e-4
- normalized L2 error: 4.803296e-8

The current VALU implementation uses 122 VGPRs and has 1,519 static
instructions, including 192 `v_perm_b32`, 768 `v_dot2_f32_bf16` and 23
wait-class instructions. `rocprofv3` measures 286.312 us mean over the final
20 real-weight calls on gfx1151, or 0.703 TFLOP/s from that profiler mean.

This is not yet a shipping performance result. Retiling from eight four-wave
workgroups to 32 one-wave workgroups changed the HIP-event result from
300.970 us to 302.543 us. That occupancy hypothesis was a measured dead end.
The next performance version must replace the 768 VALU dot2 instructions with
gfx1151 WMMA rather than continuing to tune this accumulator-heavy path.

## Raw-ASM M=12 WMMA verification

Files:

- `scripts/rocm/mxfp4_verify_gate_wmma_gfx1151.s`
- `scripts/rocm/mxfp4_verify_gate_wmma_gfx1151.hip`
- `scripts/rocm/mxfp4_verify_down_wmma_gfx1151.s`
- `scripts/rocm/mxfp4_verify_down_wmma_gfx1151.hip`

The exact gfx1151 WMMA fragment mapping was established empirically with the
installed rocWMMA headers and a BF16 identity probe before writing these
kernels. A lane loads row/column `lane&15`, the two 16-lane subgroups supply
opposite K halves, and `ds_swizzle_b32 ... SWAP,16` constructs the upper input
fragment. The output transform uses rocWMMA's verified `ROTATE,1,16` swizzles
and DPP row selection.

Both kernels use one wave per 16-by-16 output tile. Two WMMA instructions
consume each K=32 MX block, and eight FP32 FMAs apply its E8M0 scale to the
persistent accumulators.

| Static disassembly item | gfx1151 gate/up | gfx1151 down |
|---|---:|---:|
| Instructions | 174 | 176 |
| `v_wmma_f32_16x16x16_bf16` | 2 | 2 |
| `v_perm_b32` | 24 | 24 |
| Wait instructions | 7 | 7 |
| Global loads | 11 | 11 |
| `ds_swizzle_b32` | 24 | 24 |
| Global stores | 8 | 8 |
| Allocated VGPRs reported by `rocprofv3` | 72 | 72 |

The counts are static; the gate/up K loop executes 64 times and the down K
loop executes 16 times.

The first correct WMMA schedule waited for A before issuing B. It measured
74.052 us mean over the final 30 `rocprofv3` calls on gfx1151. Issuing A and B
together removed one complete VMEM drain per K half and measured 51.405 us
mean over the final 96 calls on gfx1151. This is a measured 1.44x schedule
improvement with no numerical change.

Final real-checkpoint results with 32 rotating packed/scales copies:

| Real checkpoint operation | Correctness vs fp64 on gfx1151 | `rocprofv3` mean on gfx1151 |
|---|---|---:|
| Gate, E=8 M=12 N=512 K=2048 | max abs 1.266599e-7, max rel 1.792436e-4, normalized L2 4.807820e-8 | 51.405 us, 3.916 TFLOP/s |
| Up, E=8 M=12 N=512 K=2048 | max abs 9.825453e-8, max rel 2.011668e-4, normalized L2 4.819773e-8 | same gate/up kernel; separate HIP event 52.748 us |
| Down, E=8 M=12 N=2048 K=512 | max abs 2.980232e-8, max rel 3.906250e-3, normalized L2 2.288736e-8 | 26.631 us, 7.560 TFLOP/s |

The gate/up WMMA result is 5.57x faster on gfx1151 than the measured
286.312-us raw VALU predecessor at the identical shape. The large relative
errors occur at near-zero references; normalized L2 is the useful aggregate
error.

## Raw grouped-expert prefill

Files:

- `scripts/rocm/mxfp4_prefill_gate_wmma_gfx1151.s`
- `scripts/rocm/mxfp4_prefill_down_wmma_gfx1151.s`
- `scripts/rocm/mxfp4_prefill_wmma_gfx1151.inc`
- the matching `.hip` launch/correctness harnesses

The grouped interface stores activations and outputs as padded 64-row chunks.
`expert_ids[group]` selects the checkpoint expert, so arbitrary routed expert
sizes are represented by one or more chunks without pointer chasing in the K
loop. One wave holds four 16-row accumulator tiles and reuses each decoded
MXFP4 B fragment four times.

| Static disassembly item | gfx1151 gate/up | gfx1151 down |
|---|---:|---:|
| Instructions | 375 | 377 |
| WMMA instructions per MX block | 8 | 8 |
| Permutes per MX block | 24 | 24 |
| Scale FMAs per MX block | 32 | 32 |
| Wait instructions | 16 | 16 |
| Global loads | 17 | 17 |
| Swizzles | 72 | 72 |
| Stores | 32 | 32 |
| Allocated VGPRs reported by `rocprofv3` | 112 | 112 |

Real layer-0 weights, G=8 groups and M=64 rows per group:

| Grouped prefill operation | Correctness vs fp64 on gfx1151 | Final 96-call `rocprofv3` result on gfx1151 |
|---|---|---:|
| Gate, N=512 K=2048 | max abs 1.271255e-7, max rel 2.364865e-2, normalized L2 4.632562e-8 | 98.755 us, 10.873 TFLOP/s |
| Up, N=512 K=2048 | max abs 1.303852e-7, max rel 2.706217e-3, normalized L2 4.610021e-8 | same raw gate/up kernel |
| Down, N=2048 K=512 | max abs 3.864989e-8, max rel 5.681818e-3, normalized L2 2.325625e-8 | 84.581 us, 12.695 TFLOP/s |

All figures in the table are measured on gfx1151. The gate/up traffic rate is
76.98 GB/s and down is 108.48 GB/s from the exact packed, scale, activation
and output byte counts.

The grouped expert-ID address path was also checked against a full 256-expert
layer-0 extraction, using real experts 0, 37, 74, 111, 148, 185, 222 and 3.
Measured on gfx1151, maximum absolute error was 1.192093e-7 and normalized L2
was 4.634558e-8. An initial harness print incorrectly counted all 256 resident
expert tensors as traffic although the dispatch touched eight, producing an
invalid 1,399.6-GB/s figure. The harness now counts only dispatched matrices;
the invalid figure is retained here solely as the caught accounting bug.
The same scattered IDs on the full 256-expert down projection measured
3.958121e-8 maximum absolute error and 2.245399e-8 normalized L2 on gfx1151.
Its large 3.725290e3 maximum relative error is an exact near-zero denominator,
not a large absolute discrepancy.

An end-of-network layer-39 check crosses the other end of the 26-shard
checkpoint. On gfx1151, real gate/up/down maximum absolute errors were
1.862645e-7, 2.179295e-7 and 7.450581e-8; normalized L2 errors were
4.603612e-8, 4.642733e-8 and 2.540457e-8 respectively. Layer-39 scale bytes
ranged from 118 through 123. These are correctness runs, not the final
performance samples reported above.

### Negative scale-folding result

A variant generated scale-adjusted BF16 decode lookup tables and accumulated
WMMA directly into C, removing the temporary eight-register accumulator and
32 FP32 scale FMAs per MX block. It regressed on gfx1151:

- real gate HIP-event time changed from 104.992 us to 107.815 us;
- synthetic max absolute error changed from 3.266335e-4 to 1.964569e-3;
- synthetic normalized L2 changed from 1.072704e-7 to 6.534740e-7.

The dynamic table construction cost more than the removed FMAs, and changing
the FP32 summation order amplified absolute error. The variant was reverted.

A second reuse experiment kept eight 16-row tiles live in
`mxfp4_prefill_gate_m128_wmma_gfx1151.s`. It passed the real-weight fp64 gate
(max absolute error 1.341105e-7, normalized L2 4.699788e-8), but allocated 144
VGPRs. `rocprofv3` measured 203.129 us on gfx1151 for 128 rows, versus 197.510
us for two measured 64-row calls. Extra reuse therefore regressed 2.85% from
reduced occupancy.

The opposite experiment, `mxfp4_prefill_gate_m32_wmma_gfx1151.s`, remapped
the register file to 96 allocated VGPRs and kept only two tiles live. It
passed real-weight fp64 validation (max absolute error 1.192093e-7,
normalized L2 4.672731e-8), but `rocprofv3` measured 62.943 us on gfx1151 for
32 rows. Two such calls take 125.886 us, 27.5% slower than the 98.755-us
64-row kernel because weights are decoded twice. Four live tiles are the
measured reuse/occupancy sweet spot among 32, 64 and 128 rows on gfx1151.
Thus the selected M64 gate/up kernel is a measured 1.275x improvement over
its shape-normalized M32 raw-ASM predecessor on gfx1151.

### External MXFP4 prefill baseline audit

ROCm 7.2.1 installs CK 1.2.0 headers for an A16/W4 MXFP4 MoE FlatMM kernel.
The matching upstream source is AMD Composable Kernel commit
`a7ed94f71cb412178ad034c98c05724c37083efa` (tag `rocm-7.2.1`). It was audited
as the strongest installed external candidate rather than substituting a
different numeric format.

This implementation cannot provide a gfx1151 measurement. Its CMake target
list is gfx908, gfx90a, gfx942 and gfx950. A direct build of
`example/ck_tile/18_flatmm/mixed_prec/a16w4_moe_flatmm.cpp` with ROCm 7.2.1
for gfx1151 fails at compile time in
`static_encoding_pattern.hpp:157`: the generated distribution evaluates
`X0 * Y1` to zero while requiring the 32-lane gfx1151 wave size. This is a
measured build failure, not a performance estimate. No CK number from another
GPU is used as a gfx1151 comparison. The M32 raw predecessor above is
therefore the only architecture-, format- and shape-matched prefill baseline
available in this environment.

## MXFP4 LM-head specialization

Files:

- `scripts/rocm/quantize_qwen36_lm_head_mxfp4.py`
- `scripts/rocm/mxfp4_lm_head_decode_gfx1151.s`
- `scripts/rocm/mxfp4_lm_head_verify_wmma_gfx1151.s`
- the matching `.hip` launch/correctness harnesses

The checkpoint LM head is BF16 `[248320,2048]`, so the one-time repacker
quantizes it to packed `[1024,248320]` plus E8M0 scales `[64,248320]`.
Measured on the real checkpoint, the scale-byte range is 118 through 123 and
the MXFP4 quantization normalized L2 error versus the original BF16 tensor is
0.119638. Kernel arithmetic below is compared against an fp64 reference of
those quantized MXFP4 values, not against the pre-quantization BF16 tensor.

The decode kernel assigns four adjacent logits per lane and streams each
packed row exactly once. Its gfx1151 disassembly has 485 static instructions,
192 permutes, 64 packed BF16 dot2 instructions, ten waits, 35 loads, one
128-bit store and 40 allocated VGPRs.

The M=12 kernel uses the verified WMMA fragment mapping. Its gfx1151
disassembly has 172 static instructions, two WMMAs, 24 permutes, seven waits,
13 loads, eight stores and 72 allocated VGPRs.

| Real MXFP4 LM-head case | Correctness vs fp64 on gfx1151 | Final 20-call `rocprofv3` result on gfx1151 |
|---|---|---:|
| Decode M=1 N=248320 K=2048 | max abs 3.725290e-7, max rel 4.599567e-3, normalized L2 4.944872e-8 | 1,201.571 us, 225.68 GB/s effective, 0.847 TFLOP/s |
| Verify M=12 N=248320 K=2048 | max abs 4.023314e-7, max rel 2.985075e-2, normalized L2 4.298918e-8 | 1,441.562 us, 195.73 GB/s effective, 8.467 TFLOP/s |

The decode effective rate is 1.5% above the separately measured 222.4-GB/s
gfx1151 stream probe. Four rotating LM-head copies occupy about 1.08 GB, so
this is not a 32-MiB cache artifact; the small excess is reported as
measurement/traffic-model variance rather than a new physical bandwidth
claim.

A matched launch-only harness reuses the previously reproduced compiler code
object at this exact LM-head shape and on the same real MXFP4 buffers.
`rocprofv3` measured 1,337.093 us for the compiler kernel and 1,196.558 us for
the raw kernel in the same process on gfx1151: a measured 1.117x kernel-only
speedup. The compiler output differs from the fp64-validated raw output by
4.768372e-7 maximum absolute error.

## Decode gate/up fusion: measured negative result

Files:

- `scripts/rocm/mxfp4_decode_gate_up_fused_gfx1151.s`
- `scripts/rocm/mxfp4_decode_gate_up_fused_n64_gfx1151.s`
- `scripts/rocm/silu_mul_bf16_gfx1151.s`
- the fused and standalone-pipeline HIP launch/check harnesses

The N128 fused experiment decodes gate and up MXFP4 weights in one wave,
applies SiLU and multiplication, and writes BF16 output. Because gfx1151 does
not accept `v_cvt_pk_bf16_f32`, the raw epilogue implements IEEE
round-to-nearest-even explicitly before packing BF16.

The fused output is bit-exact to the standalone raw gate + raw up + raw SiLU
pipeline: zero of 4,096 BF16 values differ on the real checkpoint. Against
the fp64 dequantized-MXFP4 reference, measured gfx1151 error is 7.191333e-4
maximum absolute, 3.813265e-3 maximum relative and 1.710884e-3 normalized L2.
The larger error than the FP32-output GEMV gates is the expected final BF16
rounding and is shared exactly by both compared pipelines.

The disassembly explains why eliminating intermediate traffic did not win:

| Static gfx1151 disassembly item | Two gate/up decoders + SiLU | Fused N128 |
|---|---:|---:|
| Instructions | 1,017 | 968 |
| `v_perm_b32` | 384 | 384 |
| `v_dot2_f32_bf16` | 128 | 128 |
| Wait-class instructions | 40 | 13 |
| Exponentials | 1 | 4 |
| Declared VGPRs in ASM | 34 + 34 + 8 | 54 |
| Allocated VGPRs reported by `rocprofv3` | 40 per decoder, 8 epilogue | 56 |

The fused wave retains four gate and four up output columns, then executes
four independent SiLU paths. Its 56-VGPR allocation and four exponentials
reduce residency/throughput enough to outweigh fewer instructions, waits,
launches and intermediate stores.

Matched final samples on gfx1151:

- `rocprofv3`, final 128 decoder calls plus final 64 epilogues:
  170.205875 us standalone kernel sum;
- `rocprofv3`, final 64 fused calls in the same process: 193.700109 us;
- HIP event, complete standalone pipeline including its two output clears:
  185.722 us;
- HIP event, fused pipeline: 199.508 us.

The fused N128 kernel is therefore 13.8% slower by the matched profiler kernel
sum and 7.4% slower end-to-end by HIP event, both measured on gfx1151. A
lower-pressure N64 fused variant allocated 40 VGPRs but duplicated more decode
work and measured 203.829 us by HIP event on gfx1151. Fusion remains a
reproducible negative experiment; the selected path is the three standalone
raw-ASM kernels.

## Completion status

Raw ASM now covers both expert decode orientations, both M=12 verify
orientations, grouped 64-row prefill for both orientations, and LM-head decode
and verify. The real-checkpoint correctness gates, gfx1151 profiler samples,
prefill predecessor comparison, external MXFP4 baseline audit and decode
fusion comparison are recorded above.

## Reproducible build

`scripts/rocm/build_gfx1151_mxfp4_raw.sh` was executed inside Netra with ROCm
7.2.1. It assembled all nine matrix kernels plus the standalone raw SiLU
epilogue and four retained negative-result variants, emitted gfx1151
disassemblies, compiled the HIP launch/check harnesses, and wrote SHA-256
hashes. The verified invocation was:

```bash
repo=/root/netra-mxfp4-gfx1151
bash "$repo/scripts/rocm/build_gfx1151_mxfp4_raw.sh" \
  "$repo/scripts/rocm" /root/netra-mxfp4-gfx1151-build
```

Machine-readable final results are in
`docs/netra/notes/gfx1151-mxfp4-results.json`.
