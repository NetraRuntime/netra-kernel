# gfx1151 N32 persistent-Q extend-attention negative result (2026-07-30)

Status: **rejected**. Every runtime and counter value below is measured on
gfx1151. Static disassembly counts are labeled separately. The candidate is not
connected to production SGLang dispatch.

## Design tested

The existing rejected N32 kernel used 20 KiB LDS but reloaded Q from global
memory for every key tile. This experiment implements the missing persistent-Q
variant requested in the attention optimization checklist:

- M64 x N32, four wave32 waves, batch 1, Hq=16, Hkv=2, D=256;
- 32 KiB persistent Q LDS;
- 16 KiB reusable K/V LDS;
- 4 KiB separate P LDS, eliminating Q/P overlap and per-tile Q restoration;
- 52 KiB total LDS, 224 allocated VGPRs, and zero scratch;
- stable device `kv_indptr` pointer with no `.item()` or host synchronization.

The first diagnostic launch exposed that the older experimental N32/N16 files
still used the pre-graph value ABI for token and prefix counts. The current
launcher passes `kv_indptr` as a device pointer. Interpreting its low bits as a
token count caused HIP status 700. The new candidate implements the accepted
N64 graph-safe ABI and dereferences `kv_indptr[1]` on device.

## Correctness

At T=64 and prefixes 0/64/192, the candidate is byte-identical to the previously
validated N32 arithmetic. At the real T=8192 shape, maximum absolute differences
versus the accepted N64 kernel are `6.103515625e-05`, `3.814697265625e-06`,
`1.9073486328125e-06`, and `1.9073486328125e-06` for prefix tiers
0/8192/16384/24576. These match the known N32-versus-N64 arithmetic envelope.

## HIP-event performance gate

Each row has three warmups and eleven samples with identical inputs.

| Prefix | Accepted N64 ms | N32 persistent-Q ms | Relative result | Status |
|---:|---:|---:|---:|---|
| 0 | 44.0947 | 63.4510 | 0.6949x | gfx1151 measured |
| 8,192 | 128.1045 | 189.3082 | 0.6767x | gfx1151 measured |
| 16,384 | 217.2879 | 344.2445 | 0.6312x | gfx1151 measured |
| 24,576 | 306.4637 | 495.2213 | 0.6188x | gfx1151 measured |
| Four tiers | 695.9508 | 1,092.2250 | 0.6372x | gfx1151 measured sum |

The candidate is 56.94% slower over the actual four-tier request geometry. No
serving integration or full-request run is justified.

## rocprofv3 mechanism

At T=8192/prefix=24576, one-counter-per-process standalone harness passes show:

| Counter/resource | Accepted N64 | N32 persistent-Q | Result |
|---|---:|---:|---:|
| VGPR | 248 | 224 | lower, measured metadata |
| LDS | 65,536 B | 53,248 B | lower, measured metadata |
| OccupancyPercent | 7.377047% | 4.714472% | worse, gfx1151 measured |
| Mean occupancy/active CU | 4.786643 | 3.062978 | worse, gfx1151 measured |
| VRAM fetch | 18.276 GiB | 5.222 GiB | 71.4% lower, gfx1151 measured |
| L2 hit | 24.662958% | 52.697794% | higher, gfx1151 measured |
| LDS bank conflict | 49.789985 | 49.308568 | approximately unchanged |
| VALUInsts | 812,758 | 999,111 | 22.9% higher, gfx1151 measured |

`SQ_WAVE_CYCLES` returned exactly 85,899,345,900 for both kernels and is treated
as saturated/invalid. The gfx1151 metric set exposes no direct dependency-stall
counter.

Q persistence succeeds at its intended memory objective, but N32 doubles the
number of online-softmax updates and output rescale passes. Static code size per
loop body falls from 6,800 to 4,494 instructions and WMMA sites from 128 to 64,
but N32 executes the loop twice as often. The repeated nonlinear/reduction work
dominates the lower Q traffic.

## Decision and next design

Retain the source as a negative experiment; do not hook it into SGLang. The next
candidate should retain N64 QK and one online-softmax update, store P separately,
then consume V in two N32 phases. That layout is 32 KiB Q + 8 KiB P + 16 KiB V
= 56 KiB and directly removes Q restoration without doubling softmax/rescaling.

Reproduction uses `tools/build/build_extend_attention_n32_persistent_q_experiment.sh`,
`tools/benchmark/benchmark_extend_attention_variants.py`, and
`tools/profiling/profile_extend_attention_n32_persistent_q_counters.sh`.
Machine-readable HIP-event, counter, and disassembly reports accompany this note.
