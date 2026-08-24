# gfx950 Qwen3.6 fused M64 row-wave and split-K4 result

Status: **validated negative experiment; not integrated into SGLang**.

This experiment is a hand-written wave64 gfx950 one-stage MoE kernel for the
real Qwen3.6-35B-A3B FP8 E4M3 M=1024 verification capture. It fuses FP8 W13,
BF16 SiLU, per-128 E4M3 activation quantization, FP8 W2, route weighting, and
packed-BF16 atomic output reduction. The checkpoint weights remain E4M3 with
128x128 block scales.

The first implementation assigned each wave an M16 row tile. A workgroup
visited all N256 output tiles serially. After fixing an LDS lifetime bug and
the two activation-layout errors described below, the persistent paired-load
variant produced finite, close complete-layer output, but took 417.844 us.
The deployed AITER oracle took 223.323 us for the same capture and timing
protocol, so this organization was 87.11% slower and failed the end-to-end
replacement gate.

The split-K4 variant launched four workgroups per M64 block. Each workgroup
owned one activation N128 / W2 K128 slice and atomically combined its result.
It reduced the measured W13+SiLU+quantization region from 251.262 us to
179.222 us, but the complete kernel regressed to 428.304 us. Its additional
partial-output atomic traffic also worsened agreement with both references.

| Variant | Complete median | Structural max abs | Structural cosine | AITER max abs | AITER cosine |
|---|---:|---:|---:|---:|---:|
| persistent row-wave, paired gate/up loads | 417.844 us | 0.000849761 | 0.999968 | 0.000976562 | 0.999961 |
| split-K4 | 428.304 us | 0.00125727 | 0.999948 | 0.0012207 | 0.999940 |
| packaged AITER oracle | 223.323 us | - | - | - | - |

The debugging sequence produced three reusable findings:

1. The original paired 16 KiB W13 staging region overlapped a persistent LDS
   scale table at 40 KiB. Sequential gate/up staging removed the corruption.
2. For each N128 activation group, the checkpoint quantization layout expects
   the first N64 half in the upper 8 KiB slab and the second N64 half in the
   lower slab. Correcting this and the W13 scale group offset reduced the
   sampled active-block mismatch to 393 of 27,136 FP8 bytes (1.45%).
3. Parallelizing W13 alone is insufficient. The row-wave implementation still
   serializes W2 across 32 N64 output steps, and split-K adds partial-output
   atomics without eliminating that serial output-N traversal.

The retained AITER disassembly is used only as an ISA and timing oracle. It
shows a materially different gfx950 occupancy point: wave64, workgroup size
256, 64 KiB LDS, 512 VGPRs, 102 SGPRs, no scratch, and extensive AGPR operands.
Its waves retain several M16 row tiles while owning output-N work. The next
Netra implementation therefore uses an independently derived wave-N contract:
four waves own distinct N tiles, retain four M16 row tiles in high register
state, write the M64x512 quantized activation once to LDS, and traverse far
fewer W2 output-N tiles. It must still pass the real-checkpoint layer and
serving gates before integration.

That wave-N follow-up has now been measured. Its retained results and raw
sources are described in
`gfx950-qwen36-fused-m64-waven-negative-2026-08-02.md`; it corrected the
row-wave W2 diagnosis but did not beat the deployed producer/oracle.

Raw artifacts are retained on the MI350X host at:

- `/data/netra/benchmarks/gfx950_qwen36_optimization/20260801T190500Z-fused-m64n256-atomic-r1-gpu6/`
- `/data/netra/repos/netra-kernel/build/gfx950-qwen36-fused-m64n2048-r7-paired/`
- `/data/netra/repos/netra-kernel/build/gfx950-qwen36-fused-m64-splitk4-r9/`

The build directories contain the gfx950 code objects, metadata, and
disassembly. The experimental raw source is kept under
`kernels/gfx950/fp8/moe/verify/experiments/`; no row-wave variant is exposed as
a production runtime kernel.
