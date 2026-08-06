# Qwen3.6 gfx950 BF16 GDN fused projection split

## Verdict

Retained as a validated opt-in gfx950 implementation. The raw AMDGCN kernel is
bit-exact and faster than the widened Triton baseline at every measured
long-prefill shape. In a matched 8-request 32K-input/1-output serving A/B it
improved input throughput by 3.22%.

It is not enabled by default yet. The exact 192-request c64
32K-input/16K-output candidate encountered the existing low-batch DFlash
acceptance collapse and finished below its reverse-order control. The raw
projection no longer runs after prefill and its complete outputs are bit-exact,
so that tail is not attributed to the copy kernel; nevertheless the required
long-serving gate did not pass.

## Target and ABI

- GPU: AMD Instinct MI350X
- target: amdgcn-amd-amdhsa--gfx950
- wavefront: 64
- workgroup: 256 threads / four waves
- input: BF16 mixed_qkvz [M,12288] and mixed_ba [M,64]
- output: BF16 qkv [M,8192], z [M,4096], b [M,32], a [M,32]
- Qwen checkpoint: FP8 E4M3 weights with 128x128 blocks
- minimum integrated row count: 32,768

The kernel assigns one workgroup to one row. Four waves issue aligned
16-byte global loads and stores. Explicit s_mul_i32 plus s_mul_hi_u32 row
addressing avoids the signed 32-bit indexing failure that affected the prior
Triton implementation above approximately M=174,762.

## Code object

- VGPR: 36
- SGPR: 20
- LDS: 0 bytes
- scratch/private segment: 0 bytes
- VGPR/SGPR spills: 0
- static instructions: 7 global_load_dwordx4, 8 global_store_dwordx4,
  5 s_mul_hi_u32
- code object target: gfx950
- wavefront size: 64

## Correctness

The standalone harness checked raw BF16 bits at rows 0, 174761, 174762,
174763, and M-1 for M=32,768, 98,304, and 229,376. Every qkv, z, b, and a
sample was exact.

The SGLang integration then compared every output element for M=32,768:
all 404,750,336 input BF16 elements were split into the four outputs with
torch.equal=true. The real Qwen checkpoint completed an 8-request 32K/1
serving run and the exact 192-request 32K/16K run without faults or fallback.
Every long-run request produced exactly 16,384 tokens.

## HIP-event results

| rows | widened Triton median us | raw mean us | raw reduction |
|---:|---:|---:|---:|
| 32,768 | 492.244 | 299.834 | 39.09% |
| 98,304 | 1,444.113 | 915.205 | 36.62% |
| 229,376 | 3,237.149 | 2,158.336 | 33.33% |

At M=229,376 the kernel moves 11,333,009,408 bytes, corresponding to
approximately 5.25 TB/s from the measured raw duration. rocprofv3 recorded
11 calls with 2,157.179 us average, 2,138.400 us minimum, and 2,172.466 us
maximum.

## Serving evidence

Matched c8 32K-input/1-output, same GPU and whole-prompt profile:

| arm | input tok/s | mean TTFT ms |
|---|---:|---:|
| Triton control | 53,240.86 | 4,444.58 |
| raw gfx950 | 54,955.03 | 4,293.52 |

The raw arm is +3.22% in input throughput and -3.40% in mean TTFT.

The exact 192-request c64 32K/16K runs were not a valid promotion win:

| arm | output tok/s | total tok/s | accept length | duration s |
|---|---:|---:|---:|---:|
| raw candidate | 3,485.85 | 10,457.55 | 8.98 | 902.43 |
| reverse control | 6,740.06 | 20,220.19 | 10.28 | 466.72 |

The candidate collapsed to acceptance length 1.0 for its final low-batch
survivors; the reverse control retained about 9-10 in the same phase. This
large nondeterministic DFlash/MoE tail overwhelms the prefill-only gain.
Production-default promotion remains blocked on fixing that defect and
repeating the long A/B.

## Artifacts

- isolated build and rocprofv3:
  /data/netra/benchmarks/gfx950_qwen36_optimization/20260806T150140Z-gdn-fused-proj-raw-gpu3
- raw serving candidate:
  /data/netra/benchmarks/gfx950_qwen36_optimization/20260806T151801Z-qwen36-c64-gpu5
- reverse-order control:
  /data/netra/benchmarks/gfx950_qwen36_optimization/20260806T153816Z-qwen36-c64-gpu5
