# gfx1151 dense-prefill MXFP4 dword layout (2026-07-29)

Every runtime number below is measured on gfx1151. Static instruction counts
are labeled separately. The real checkpoint remains MXFP4; no alternate
quantization format is used.

## Ranked-path reason

The accepted gate/up layout trace moved the generic dense-prefill kernel to
rank 2: 360 calls, 2,943.308 ms total GPU duration, 8.176 ms mean, and 9.897%
of kernel time for an exact uncached 32,768-input/+1-output request. Its K32
step issued eight strided byte loads, seven dependent address additions, and
six pack operations before decoding the two WMMA fragments. rocprofv3 reported
112 allocated VGPRs, 128 SGPRs, zero LDS, and zero scratch.

The three real Qwen3.6 shapes are G128/M64 N12288/K2048, N2048/K4096, and
N64/K2048. Their request counts are 120 each across four 8,192-token chunks.

## Accepted raw AMDGCN design

The new raw gfx1151 repacker performs one load-time byte permutation:

`[K32][fragment][subgroup][N][four packed K bytes]`

Every E2M1 nibble is copied exactly. Decode retains the original MXFP4 view;
prefill receives a separate stable pointer. The production compute kernel now
issues two coalesced dword loads per K32 instead of eight strided byte loads.
It removes six load instructions, seven dependent vector address operations,
and six pack operations from the static loop body. The raw modules are loaded
before graph capture and the 90 persistent views are built before capture.

The persistent views contain 505,282,560 bytes (481.875 MiB). Their exact
breakdown is 30 x 12,582,912-byte QKVZ views, 30 x 4,194,304-byte GDN-output
views, and 30 x 65,536-byte BA views.

## Correctness and HIP events

The raw device repacker matched the host oracle byte-for-byte at all three real
shapes. Baseline and candidate FP32 output buffers were bit identical, with
zero mismatches and maximum absolute difference zero. Captured HIP graph replay
also matched eager output exactly.

| gfx1151 shape, G128/M64 | Previous median | Dword median | Speedup | Repack median | Graph replay | Correctness |
|---|---:|---:|---:|---:|---:|---|
| N12288/K2048 | 14.558731 ms | 12.935582 ms | 1.125479x | 0.113493 ms | 12.955162 ms | bit exact |
| N2048/K4096 | 7.308417 ms | 4.903353 ms | 1.490494x | 0.028894 ms | 4.880715 ms | bit exact |
| N64/K2048, 31 samples | 0.774129 ms | 0.796532 ms | 0.971874x | 0.005651 ms | 0.681678 ms | bit exact |

The first two rows use 11 alternating HIP-event samples. N64 was repeated for
31 samples because its sub-millisecond result was noisy; it is recorded as an
isolated negative even though the shared all-dword deployment won the serving
gate below.

## rocprofv3 hardware evidence

Each counter was collected in a separate process launch with ROCm 7.2.1 at the
identical shape. The gfx1151 metric set exposes no direct dependency-stall
counter, so none is estimated.

| gfx1151 counter/resource | N12288 before | N12288 dword | Change | N2048 before | N2048 dword | Change |
|---|---:|---:|---:|---:|---:|---:|
| Fetch size, KiB | 1,322,643.781 | 1,077,846.738 | -18.508% | 1,234,990.156 | 253,080.888 | -79.507% |
| SQ busy cycles | 831,759,545 | 741,985,037 | -10.793% | 410,263,553 | 275,802,639 | -32.774% |
| SQ VALU instructions | 726,859,776 | 651,362,304 | -10.387% | 240,680,960 | 215,515,136 | -10.456% |
| Flat instructions | 110,100,480 | 72,351,744 | -34.286% | 36,175,872 | 23,592,960 | -34.783% |
| Occupancy | 74.6528% | 74.7053% | +0.0524 pp | 71.3255% | 73.5938% | +2.2682 pp |
| Waves | 98,304 | 98,304 | unchanged | 16,384 | 16,384 | unchanged |
| VGPR/SGPR/LDS/scratch | 112/128/0/0 | 112/128/0/0 | unchanged | 112/128/0/0 | 112/128/0/0 | unchanged |

L2 hit rate is not interpreted alone: the new layout deliberately eliminates
traffic, so fewer cache hits accompany far fewer total fetches and misses.
There are no LDS conflicts because the kernel allocates no LDS.
For N64/K2048, the dword layout reduced static flat and VALU instructions but
increased measured fetch from 73,599.594 to 77,492.463 KiB (+5.289%) and SQ
busy cycles from 39,184,378 to 40,862,973 (+4.284%), confirming the isolated
negative. Wave count and 112/128/0/0 resources remained unchanged.

## Full-request rocprofv3 gate

The ABI-matched ROCm 7.13 profiler ran from process start with signal handlers
disabled and finalized CSV traces without the prior signal-6 recursion. The
exact request was 32,768 input/+1 output, uncached, batch 1, graph disabled,
and dFlash disabled.

| gfx1151 request cost | Previous | Dword | Change |
|---|---:|---:|---:|
| Calls | 360 | 360 | unchanged |
| Total GPU duration | 2,943.308 ms | 2,432.430 ms | -510.879 ms (-17.357%) |
| Mean GPU duration | 8.176 ms | 6.757 ms | -17.357% |
| Kernel-time share | 9.897% | 8.345% | -1.552 pp |
| Ranked position | 2 | 3 | gate/up becomes rank 2 |

The measured per-shape totals explain the aggregate:

| Shape | Calls | Previous total | Dword total | Change |
|---|---:|---:|---:|---:|
| N64/K2048 | 120 | 167.128 ms | 171.615 ms | +4.487 ms |
| N2048/K4096 | 120 | 801.957 ms | 592.668 ms | -209.289 ms |
| N12288/K2048 | 120 | 1,974.223 ms | 1,668.147 ms | -306.076 ms |

The one-time raw repacker appears 90 times during model initialization at only
4.772 ms total GPU time. It is not on the request replay path.

## Real-checkpoint serving gate

The control is commit `cbe25010018b1d91e59c585b6db9fbafade8a2fb`. Each row
uses identical deterministic IDs and greedy sampling.

| Pair | Previous host E2E | Dword host E2E | Greedy ID | Status |
|---|---:|---:|---:|---|
| A | 28,628.678 ms | 28,100.357 ms | 248045 | exact match, gfx1151 measured |
| B | 28,433.218 ms | 27,904.237 ms | 220 | exact match, gfx1151 measured |
| Mean | 28,530.948 ms | 28,002.297 ms | both | 1.018879x |

Mean host E2E falls by 528.651 ms. Requests are exact 32,768/+1, uncached,
batch 1, graph disabled, and dFlash disabled. Measured peak sysfs unified-VRAM
values are 72,044,933,120 and 72,047,030,272 bytes.

The exact 210/+1 correctness request also produced the unchanged greedy ID
95860. Its single 616.442 ms host sample was slower than the prior 567.600 ms,
so no short-prefill performance improvement is claimed.

## Loading result

The full shard-and-weight phase is 9.32 seconds measured on gfx1151 versus
9.01 seconds for the prior accepted build. This remains the optimized
multi-thread loader, not the former 10-20 minute path. The 0.31-second process
variation includes post-load view creation and is accepted for the 528.651 ms
per-32K-request saving. The old and new layouts remain MXFP4 throughout.

## Rejected N64 specialization

A second production trial retained the old strided raw ASM and skipped the N64
persistent view. It was motivated by the isolated 2.813% N64 regression and
would have recovered 4.487 ms in the trace. Real serving rejected it:

| gfx1151 paired mean | All-dword | N64 strided specialization | Result |
|---|---:|---:|---:|
| Exact 32,768/+1 host E2E | 28,002.297 ms | 28,181.301 ms | +179.005 ms, reject |

Both greedy pairs remained correct. The unused specialization and bridge branch
were removed from production; this is a measured negative result rather than
an assumption-based choice.

## Static disassembly

The compute kernel falls from 384 to 366 static instructions. Global loads fall
from 17 to 11 while 15 waits, eight WMMA instructions, 72 DS swizzles, 32
stores, and allocated resources remain unchanged. The generic raw repacker is
28 instructions: four byte loads, three pack operations, one dword store, no
LDS, and no scratch.

## Evidence

- Production compute: `kernels/gfx1151/mxfp4/serving/mxfp4_sgl_linear_prefill_wmma_gfx1151.s`
- Production repacker: `kernels/gfx1151/mxfp4/serving/mxfp4_sgl_linear_prefill_repack_dword_gfx1151.s`
- HIP launch/graph bridge: `integrations/sglang/netra_mxfp4_sgl_launcher.hip`
- SGLang load-time integration: `integrations/sglang/netra_gfx1151_sglang.py`
- Correctness/timing harness: `harness/gfx1151/mxfp4/serving/benchmark_linear_prefill_dword_layout.hip`
- Counter runner: `tools/profiling/profile_dense_prefill_dword_layout_counters.sh`
- Full JSON: `docs/notes/gfx1151-dense-prefill-dword-layout-2026-07-29.json`
- Counter data: `results/profiles/gfx1151/dense-prefill-dword-n{12288-k2048,2048-k4096}-g128-20260729/`
- Full trace: `results/profiles/gfx1151/dense-prefill-dword-layout-full-32k/`
- Serving data: `results/serving/gfx1151/dense-prefill-dword-layout-20260729/`
- Before/after/repacker disassembly: `docs/notes/disassembly/gfx1151-dense-prefill-dword-layout-2026-07-29/`
