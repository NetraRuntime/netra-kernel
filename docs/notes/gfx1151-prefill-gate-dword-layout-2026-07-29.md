# gfx1151 MXFP4 prefill gate/up dword layout (2026-07-29)

Every runtime value below is measured on gfx1151. Instruction counts are
static disassembly results, not runtime estimates.

## Ranked-path reason

The prior exact 32,768-input/+1-output process-start trace ranked
`mxfp4_prefill_gate_wmma_gfx1151` second: 320 calls, 3,456.036 ms total,
10.800 ms mean, and 11.41% of kernel time. The old inner K32 step issued eight
strided byte loads and six pack operations before MXFP4 decode. It used 112
allocated VGPRs, 128 profiler-reported SGPRs, no LDS, and no scratch.

## Accepted raw AMDGCN design

The checkpoint and both resident weight views remain MXFP4. A 29-instruction
raw gfx1151 repacker performs a one-time byte permutation during model
initialization:

`[expert][K32][fragment][subgroup][N][four packed K bytes]`

The production raw compute kernel consumes two coalesced dword loads per K32
step instead of eight strided byte loads. It removes six global-load
instructions and the pack sequence without dequantizing or changing any E2M1
nibble. Decode keeps the original MXFP4 view; prefill uses stable pointers to
the permuted view. Both raw modules are loaded before graph capture.

## Correctness and HIP events

The device repacker matched the host layout oracle for all 134,217,728 bytes.
At the exact Qwen expert shape E256/G1276/M64/N512/K2048, the previous and new
compute outputs were bit identical: zero mismatches and maximum absolute error
zero.

| gfx1151 measurement | Previous | New | Result |
|---|---:|---:|---:|
| HIP-event median, 11 samples | 10.222587 ms | 8.507615 ms | 1.201581x |
| One-time repacker median | n/a | 1.138494 ms | measured |
| HIP graph replay median | n/a | 8.517274 ms | measured, bit exact |

Graph capture used a preloaded raw module, stable device pointers, and no
capture-time allocation. Eleven replay outputs matched eager byte-for-byte.

## rocprofv3 counters

Each counter was collected in its own process launch using the system ROCm
7.2.1 profiler against the HIP-7.2 harness.

| gfx1151 counter/resource | Previous | New | Change |
|---|---:|---:|---:|
| Fetch size | 587,746.547 KiB | 393,866.531 KiB | -32.987% |
| SQ busy cycles | 602,769,635 | 481,244,879 | -20.161% |
| SQ VALU instructions | 286,150,656 | 270,512,000 | -5.465% |
| Occupancy | 73.4734% | 74.0003% | +0.5269 pp |
| L2 hit | 92.4787% | 92.0131% | -0.4657 pp |
| Waves | 40,832 | 40,832 | unchanged |
| VGPR / SGPR / LDS / scratch | 112 / 128 / 0 / 0 | 112 / 128 / 0 / 0 | unchanged |

The gfx1151 metric set exposes no direct dependency-stall counter. Zero LDS
means the LDS-conflict counter is zero by construction. The reduced fetch and
SQ busy counts explain the measured improvement; the small L2-hit decrease is
not a regression in total traffic.

## Full-request rocprofv3 gate

The ABI-matched ROCm-7.13 wheel profiler ran from process start with signal
handlers disabled and CSV output. It finalized a 13 MB kernel trace and 29 MB
HIP trace with no `signal 6`, SIGABRT, profiler ABI, or configuration-period
error. The exact request was uncached 32,768 input/+1 output, batch 1, graph
disabled, and dFlash disabled.

| gfx1151 request cost | Previous | New |
|---|---:|---:|
| Calls | 320 | 320 |
| Total GPU duration | 3,456.036 ms | 2,906.637 ms |
| Mean GPU duration | 10.800 ms | 9.083 ms |
| Kernel-time share | 11.41% | 9.774% |
| Ranked position | 2 | 3 |

The measured total falls by 549.399 ms, or 15.897%. The one-time raw repacker
appears 80 times during model loading, at 1.132 ms mean and 90.525 ms total.
After this acceptance, dense prefill ranks second and gate/up ranks third.

The full process-start trace still includes weight-loading copies. The very
large aggregate `hipMemcpyWithStream` CPU time is therefore initialization,
not request dispatch; request-only GPU kernel ranks above use the known model
call counts and shapes.

## Real-checkpoint serving gate

The paired controls are the immediately preceding accepted K-LDS-swizzle
production build. Each pair uses identical deterministic input IDs.

| Pair | Previous host E2E | New host E2E | Greedy ID | Status |
|---|---:|---:|---:|---|
| A | 29,144.951 ms | 28,628.678 ms | 248045 | match, gfx1151 measured |
| B | 29,046.815 ms | 28,433.218 ms | 220 | match, gfx1151 measured |
| Mean | 29,095.883 ms | 28,530.948 ms | both | 1.019800x |

Mean host E2E falls by 564.935 ms. All requests were exact 32,768/+1,
uncached, batch 1, graph disabled, and dFlash disabled. Peak sysfs unified-VRAM
accounting rises from a 60.923 GB pair mean to 71.767 GB, an expected
10,844,516,352-byte increase for 80 persistent 128 MiB MXFP4 views.

Additional accepted measured results:

- Exact 8,192/+1 uncached: 5,867.450 ms, greedy ID 278 matching the prior
  deterministic control, peak VRAM 71,768,244,224 bytes.
- Exact 210/+1 uncached: 567.600 ms, peak VRAM 71,840,841,728 bytes.
- Exact 210/+128 uncached: 526.401 ms TTFT, 7,602.906 ms total, 17.947 output
  tok/s, peak VRAM 71,840,841,728 bytes.

## Loading and memory decision

Shard loading remains 9.01 seconds measured; the prefill permutation adds only
90.525 ms of GPU work across the complete model. Launch-to-health at the
49,152-token server tier is 22.143 seconds measured. The 96 GiB gfx1151 unified
VRAM pool retains more than enough capacity for the tested 49K context tier,
so the faster persistent layout is accepted. A shared 128 MiB workspace would
save memory but would repay the repack cost on every layer and request; it is
not selected for this deployment.

## Static disassembly

The compute kernel falls from 375 to 364 instructions. Global-load
instructions fall from 17 to 11; WMMA count, 16 waits, 72 DS operations, 32
stores, LDS, scratch, and allocated register counts remain unchanged. The raw
repacker is 29 instructions with four byte loads, three pack operations, one
dword store, no LDS, and no scratch.

## Profiler signal-6 fix

`tools/profiling/profile_sglang_request.sh` now uses the confirmed safe
process-start flow. It selects `/root/venv1151/bin/rocprofv3`, disables signal
handlers, and emits CSV. It refuses to attach to a live scheduler, eliminating
the inherited resource-tracker SIGABRT recursion that produced repeated
`rocprofv3 caught signal 6 PID 33358` messages.

## Evidence

- Raw compute: `kernels/gfx1151/mxfp4/prefill/mxfp4_prefill_gate_wmma_gfx1151.s`
- Raw repacker: `kernels/gfx1151/mxfp4/prefill/mxfp4_prefill_repack_dword_gfx1151.s`
- Harness: `harness/gfx1151/mxfp4/prefill/benchmark_prefill_gate_dword_layout.hip`
- Full measured JSON: `docs/notes/gfx1151-prefill-gate-dword-layout-2026-07-29.json`
- Counter detail: `results/profiles/gfx1151/prefill-gate-dword-layout-counters-20260729/`
- Full request trace: `results/profiles/gfx1151/prefill-gate-dword-layout-32k-start-20260729/`
- Serving detail: `results/serving/gfx1151/prefill-gate-dword-layout/`
- Before/after/repacker disassembly: `docs/notes/disassembly/gfx1151-prefill-gate-dword-layout-2026-07-29/`
