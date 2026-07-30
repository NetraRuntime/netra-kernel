# gfx1151 attention 32 KiB LDS experiments (2026-07-30)

Status: **rejected; production unchanged**. All runtime, correctness, resource,
and counter claims below are measured on gfx1151 unless explicitly labeled
static disassembly. No value is estimated.

## Question tested

The accepted N64 group-4 attention kernel uses 64 KiB LDS, 248 VGPR, 128 SGPR,
and zero scratch. A VGPR-only experiment reached 224 VGPR but did not improve
occupancy. These experiments test whether combining 224 VGPR with a real 32 KiB
LDS footprint creates a residency step and enough latency benefit to compensate
for the required schedule changes.

Two raw gfx1151 AMDGCN candidates were built:

1. `extend_attention_wmma_n32_group4_qpipe_kvbatch8_lowlds_gfx1151`: M64xN32,
   four query heads share one 16 KiB K/V tile, four 4 KiB P workspaces occupy
   the other 16 KiB, and Q remains globally sourced with next-fragment overlap.
2. `extend_attention_wmma_n64_group4_qpipe_kvbatch4_overlay32k_gfx1151`: retain
   N64 QK, four-head K/V reuse, one 64-column online-softmax update, and exact
   arithmetic. K initially occupies all 32 KiB. Tile-major P overwrites dead K;
   each 16-row V fragment then overwrites its already-loaded P tile in place.

Both use grid `(M/64, 4, 1)`, a 512-thread workgroup, wave32, BF16 Q/K/V, Hq=16,
Hkv=2, D=256, page size 1, 224 VGPR, 128 SGPR, 32,768 bytes LDS, and zero scratch.

## Correctness gate

The N32 candidate was compared with the accepted N64 kernel at T=64 with
prefixes 0/64/192 and T=8192 with prefixes 0/8192/16384/24576. Its maximum
absolute differences were respectively at most `6.103515625e-05` and
`6.103515625e-05`, matching the already-established N32 arithmetic envelope.

The N64 P/V-overlay candidate is byte-identical to the accepted N64 kernel at
all those shapes: maximum and mean absolute error are both zero. The barrier
before overwriting K and each P-to-V handoff barrier are required for correctness.

## HIP-event acceptance gates

Identical allocations and inputs were used; both variants write the same timed
output allocation. Samples alternate A/B then B/A. Lower time is better.

### M64xN32 group-4 low-LDS candidate

Three warmups and eleven measured gfx1151 samples per tier:

| Prefix | N64 baseline ms | N32 candidate ms | Baseline/candidate | Result |
|---:|---:|---:|---:|---|
| 0 | 34.624286 | 38.194336 | 0.906529x | measured regression |
| 8,192 | 99.939476 | 108.577179 | 0.920446x | measured regression |
| 16,384 | 166.579071 | 183.462479 | 0.907974x | measured regression |
| 24,576 | 233.623337 | 257.576874 | 0.907004x | measured regression |
| Sum | 534.766171 | 587.810867 | 0.909759x | **9.919% slower, rejected** |

### N64 P/V-overlay candidate

Three warmups and thirty-one measured gfx1151 samples per tier:

| Prefix | N64 baseline ms | Overlay candidate ms | Baseline/candidate | Result |
|---:|---:|---:|---:|---|
| 0 | 34.803120 | 36.188095 | 0.961728x | measured regression |
| 8,192 | 99.908058 | 104.699677 | 0.954235x | measured regression |
| 16,384 | 166.838654 | 176.513718 | 0.945188x | measured regression |
| 24,576 | 233.877884 | 248.757141 | 0.940186x | measured regression |
| Sum | 535.427715 | 566.158630 | 0.945720x | **5.740% slower, rejected** |

The overlay result is the stronger isolation: arithmetic, WMMA count, global
load count, LDS instruction count, and output are unchanged. Its extra P/V
handoffs do not earn a residency benefit.

## rocprofv3 evidence

Each counter was collected in a fresh process with
`--disable-signal-handlers true`, avoiding the previously observed rocprofv3
signal-6 failure mode. Shape is T=8192, prefix=24576. The gfx1151 metric set has
no direct dependency-stall counter.

| Counter/resource | N64 baseline | N32 low-LDS | N64 overlay32k |
|---|---:|---:|---:|
| LDS bytes | 65,536 | 32,768 | 32,768 |
| VGPR / SGPR / scratch | 248 / 128 / 0 | 224 / 128 / 0 | 224 / 128 / 0 |
| OccupancyPercent | 10.033116% | 9.100424% | 9.452329% median |
| Mean occupancy/active CU | 6.517015 | 5.896687 | 6.147695 |
| SQ waves | 8,192 | 8,192 | 8,192 |
| VRAM fetch KiB | 19,176,317.625 | 32,471,217.438 | 17,491,366.250 |
| VRAM write KiB | 32,423 | 32,423 | 32,384 |
| L2 hit | 9.065595% | 7.292260% | 15.213691% |
| Memory-unit busy | 18.730445% | 27.065821% | 23.261292% |
| LDS bank-conflict metric | 29.133858 | 25.984252 | 26.229508 |
| VALUInsts | 878,687.5 | 988,442.0 | 902,009.5 |
| SQ_INSTS_LDS | 4,453,023,744 | 4,688,166,912 | 4,453,023,744 |
| SQ_INSTS_SALU | 263,948,288 | 285,200,384 | 284,804,096 |

Two valid fresh baseline occupancy reruns were 10.029379% and 10.005679%.
Three overlay reruns were 9.452329%, 9.412202%, and 9.464421%. One baseline
rocprofv3 sample returned an impossible value above 100%; it is explicitly
excluded and retained in the raw profile directory for auditability.

The result disproves the working assumption that 32 KiB LDS plus 224 VGPR is
sufficient for a residency step with this 512-thread workgroup. N32 additionally
doubles Q loads and online-softmax/output-rescale updates. The overlay avoids
that arithmetic penalty but adds eight static barriers rather than obtaining
more resident work.

## Static disassembly comparison

These are static gfx1151 `llvm-objdump` counts, not runtime measurements:

| Item | N64 baseline | N32 low-LDS | N64 overlay32k |
|---|---:|---:|---:|
| Instruction lines | 6,695 | 4,555 | 6,763 |
| WMMA sites | 128 | 64 | 128 |
| Global-load sites | 80 | 48 | 80 |
| LDS-load sites | 580 | 290 | 580 |
| LDS-store sites | 96 | 48 | 96 |
| LDS-swizzle sites | 592 | 328 | 592 |
| `s_waitcnt` sites | 307 | 175 | 319 |
| `s_barrier` sites | 4 | 4 | 12 |
| exponent sites | 40 | 24 | 40 |

N32 executes its shorter body twice per N64 key span. The overlay executes the
same number of arithmetic and memory operations as N64 but pays four P/V
handoffs per tile.

## Decision

Neither candidate is connected to SGLang production, and no serving benchmark
is claimed for a kernel that failed the isolated gate. Retain both raw assembly
files as reproducible negative experiments.

Do not continue LDS-only tuning at 224 VGPR. A viable next residency design must
also materially reduce the 128-register FP32 output accumulator footprint or
use a smaller workgroup. The most plausible attention directions are:

- register-to-register P layout conversion that removes P LDS without adding
  four handoff barriers;
- a smaller-workgroup design that preserves N64 softmax and useful K/V reuse;
- larger contiguous KV pages, measured with the accepted group-4 kernel;
- Q/K normalization + RoPE + KV-cache-store fusion outside this kernel.

No speedup is estimated for these untested directions.

## Reproduction and evidence

- `scripts/rocm/tools/build/build_extend_attention_n32_lowlds_experiment.sh`
- `scripts/rocm/tools/build/build_extend_attention_overlay32k_experiment.sh`
- `scripts/rocm/tools/benchmark/benchmark_extend_attention_variants_shared_output.py`
- `scripts/rocm/tools/profiling/profile_extend_attention_n32_lowlds_counters.sh`
- `scripts/rocm/tools/profiling/profile_extend_attention_overlay32k_counters.sh`
- `gfx1151-attention-n32-group4-lowlds-hip-events-2026-07-30.json`
- `gfx1151-attention-overlay32k-hip-events-2026-07-30.json`
- `gfx1151-attention-lowlds-rocprofv3-2026-07-30.json`
- `gfx1151-attention-lowlds-disassembly-counts-2026-07-30.json`
