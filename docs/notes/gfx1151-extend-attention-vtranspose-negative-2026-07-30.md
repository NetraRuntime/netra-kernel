# Rejected gfx1151 attention V-transpose (2026-07-30)

Status: **rejected; production qpipe8 remains unchanged**. Runtime and counter
values below are measured on gfx1151. Static instruction/resource properties
are labeled static. The candidate remains raw AMDGCN ASM under `experiments/`.

## Design tested

The production PV phase reads row-major V from LDS with eight `ds_load_u16`
instructions and four lane swizzles for every output block. The candidate
transposes each 16-row V tile while staging it:

- every row-major global `b128` is scattered with eight `ds_write_b16` stores;
- each PV fragment is then loaded with two `ds_load_b128` operations;
- the direct wide-load form removes all V-side lane swizzles;
- QK arithmetic, K swizzle, P layout, mask, online-softmax order, ABI, 64 KiB
  LDS, 248 allocated VGPRs, and zero scratch remain unchanged.

The first diagnostic version treated `s39` as a row index although it is the
production `row * 512` LDS byte offset. Correcting the bit extraction made the
candidate byte-identical before performance was assessed.

## Correctness and HIP-event gate

At T64 with prefix 0/64/192 and exact T8192 with prefix
0/8192/16384/24576, every candidate output is byte-identical to qpipe8:
`max_abs=0`, `mean_abs=0`. The exact T8192 alternating AB/BA medians are:

| Prefix | qpipe8 ms | V-transpose ms | Relative | Status |
|---:|---:|---:|---:|---|
| 0 | 42.6147 | 73.0463 | 0.5834x | gfx1151 measured |
| 8,192 | 125.5306 | 214.9969 | 0.5839x | gfx1151 measured |
| 16,384 | 211.5556 | 358.2252 | 0.5906x | gfx1151 measured |
| 24,576 | 299.0124 | 502.5432 | 0.5950x | gfx1151 measured |
| Four tiers | 678.7133 | 1,148.8115 | 0.5908x | gfx1151 measured sum |

The real four-tier geometry is 69.3% slower. No serving or graph integration is
justified after this isolated-kernel rejection.

## Disassembly and rocprofv3 evidence

Static disassembly counts over the fully unrolled raw kernels show the trade:

| Instruction/resource | qpipe8 | V-transpose | Status |
|---|---:|---:|---|
| `ds_load_u16` | 512 | 0 | static gfx1151 |
| `ds_load_b128` | 84 | 212 | static gfx1151 |
| `ds_swizzle_b32` | 592 | 336 | static gfx1151 |
| `ds_store_b16` | 32 | 288 | static gfx1151 |
| `ds_store_b128` | 96 | 64 | static gfx1151 |
| LDS / VGPR / scratch | 65,536 B / 248 / 0 | same | static gfx1151 |

Standalone rocprofv3 passes at exact T8192/prefix24576 measured 8,192 waves
for both. Mean occupancy per active CU fell from 5.089918 to 2.995584, VRAM
fetch rose from 15,284,311.9 to 24,981,309.9 KiB, L2 hit fell from 28.237636%
to 17.942177%, LDS bank conflicts rose from 34.666258 to 74.699786, and VALU
instructions rose from 906,046 to 959,866. The candidate `OccupancyPercent`
sample was an invalid 282,968.73% and is explicitly not interpreted. This ROCm
metric set exposes no direct dependency-stall counter, so none is estimated.

## Decision

Reject checklist item 10 in this scatter-transpose form. Wider PV reads do not
pay for eight narrow stores per source row; the measured bank-conflict and
cache behavior is substantially worse. A future V layout should only be tested
if the producer can emit the wide-read layout directly without a scatter.

Full before/after gfx1151 disassemblies and their unified diff are retained in
`docs/notes/gfx1151-extend-attention-vtranspose-disassembly-2026-07-30/`.

Reproduce with `tools/build/build_extend_attention_vtranspose_experiment.sh`,
`tools/benchmark/benchmark_extend_attention_variants.py`, and
`tools/profiling/profile_extend_attention_vtranspose_counters.sh`. Adjacent JSON
files contain HIP-event and rocprofv3 results.
