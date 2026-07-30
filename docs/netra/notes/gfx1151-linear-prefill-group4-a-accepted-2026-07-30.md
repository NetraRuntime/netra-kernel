# gfx1151 dense-prefill group4-A acceptance (2026-07-30)

Status: **accepted for N64 and N2048 only**. Every runtime and speedup in this
note is measured on gfx1151; none is estimated. MXFP4 checkpoint weights and the
persistent dword weight layout are unchanged. N12288 remains on the original
raw-ASM kernel.

## What changed

The accepted raw AMDGCN kernel places four adjacent N16 output waves in one
128-thread workgroup. They share one 4 KiB M64xK32 BF16 activation tile in LDS
while retaining the original per-wave weight decode, WMMA order, accumulators,
and output stores. The compatibility launcher selects it only when N is 64 or
2048:

| Shape selection | Grid | Workgroup | Kernel |
|---|---:|---:|---|
| N64/N2048 | N/64 by G | 128 | `mxfp4_sgl_linear_prefill_group4_a_gfx1151` |
| N12288 | N/16 by G | 32 | `mxfp4_sgl_linear_prefill_wmma_gfx1151` |

The exported C ABI, packed `LinearArgs`, argument order, shared-memory launch
parameter, and caller-provided HIP stream are unchanged. The module is loaded
during the existing preload sequence, before graph capture.

## Strengthened correctness

The isolated harness uses deterministic finite nonuniform BF16 activations.
Twenty fresh processes per accepted shape passed before integration. The final
accepted source then passed eager and graph replay equality:

| Exact G128/M64 shape | Samples | Original median | Group4-A median | Result |
|---|---:|---:|---:|---|
| N64/K2048 | 31 | 0.782355 ms | 0.231249 ms | 3.383171x; bit-exact eager and graph |
| N2048/K4096 | 21 | 4.974259 ms | 4.824928 ms | 1.030950x; bit-exact eager and graph |
| N12288/K2048 | 11 | 13.740413 ms | 14.310320 ms | 0.960175x; bit-exact, not selected |

An instrumented real-checkpoint 32,768/+1 execution launched both kernels for
every accepted-shape projection and compared device results before continuing.
All 120 N64 calls and all 120 N2048 calls were bit-exact; the deterministic
output remained token 82. The comparison synchronization made its host time
diagnostic-only.

The exact prompt involved in the historical token-0 rejection was then run in
five fresh candidate servers. All five returned the production token 5525. A
second deterministic prompt returned token 248045, and the canonical prompt
returned token 82 after final no-environment integration. Input and output
hashes matched their production controls. The old rejection report is retained
as history and marked superseded rather than deleted.

The final HSACO is byte-identical to the isolated experiment:

`1a376353494b460fba13a86416a9141c07712bf3869f47aee51b32a57f3b50cb`

## Interleaved serving A/B

Exact 32,768 input +1 output, zero cached tokens, graph disabled, dFlash
disabled, identical pair-A input hash
`cec98edb9b9131417d34fefef2e2723124853af29cdbfa02be23428f4b6dd9b7`:

| Order | Original host E2E | Group4-A host E2E | Greedy result |
|---|---:|---:|---|
| A1/B1 | 21,704.270853 ms | 21,596.623229 ms | token 5525, matching hash |
| A2/B2 | 21,716.420955 ms | 21,574.944732 ms | token 5525, matching hash |
| Mean | 21,710.345904 ms | 21,585.783981 ms | **1.0057706x** |

This is a measured 124.561924 ms mean host-E2E reduction on gfx1151. The
unprofiled serving sample is used for the serving claim; profiler wall time is
reported separately below.

## Accepted rocprofv3 request trace

The final integrated library was traced over the exact canonical 32,768/+1
request, zero cached tokens, graph disabled, and dFlash disabled. Output token
82 and hashes match production.

| Metric | Prior accepted runtime | Group4-A runtime | Measured delta |
|---|---:|---:|---:|
| Dense linear GPU, 360 calls | 2,433.851 ms | 2,312.351 ms | 121.500 ms saved; 1.05255x |
| Total kernel GPU time | 21,692.602 ms | 21,526.866 ms | 165.736 ms saved |
| Trace wall | 22,556.800 ms | 22,384.160 ms | 172.640 ms saved |
| Kernel launches | 16,888 | 16,888 | no additional launches |

The selected-kernel split is 120 N12288 original calls at 1,659.005691 ms and
240 N64/N2048 group4-A calls at 653.345204 ms. Group4-A reports 112 VGPR, 128
SGPR, 4,096 bytes LDS, zero scratch, and a 128-thread workgroup. Overall kernel
occupancy of trace wall is 96.170087%; positive launch gaps sum to 894.009969
ms. `hipModuleLaunchKernel` appears 3,705 times and consumes 39.697581 ms total
CPU time (10.714597 us mean). The request host E2E under profiling is
22,336.012757 ms and is not mixed with the unprofiled serving mean.

Artifacts are under
`results/profiles/gfx1151/group4-a-accepted-windowed-32768p1-20260730/` and
`results/serving/gfx1151/group4-a-*`. The unchanged before/after disassembly is
retained under
`docs/notes/gfx1151-linear-prefill-group4-a-negative-disassembly-2026-07-30/`;
the identical HSACO hash proves the accepted raw instructions equal that
reviewed candidate.

## Decision

