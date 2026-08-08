# gfx1151 BF16 shared gate/up wide-load decode — 2026-07-31

All results in this note are for AMD Ryzen AI Max+ PRO 395, `gfx1151`.
GPU claims are measured with HIP events or rocprofv3. Serving claims are measured
with streaming host wall time. Values explicitly called derived are not direct
measurements.

## Decision

Accept `bf16_shared_gate_up_silu_decode_wide128_gfx1151.s` for the exact
Qwen3.6 shared-expert M=1 BF16 gate/up plus SiLU shape, N=1024 and K=2048.
It replaces the accepted raw wave2 implementation without changing the 24-byte,
8-byte-aligned three-pointer kernarg ABI, grid `(32,1,1)`, workgroup 256, caller
HIP stream, graph-pool pointers, or model weights.

The candidate replaces scalar `global_load_b32` operand traffic with
`global_load_b128`. Each lane consumes eight 16-byte activation/weight fragments
instead of thirty-two 4-byte fragments. Final compute remains hand-written raw
AMDGCN assembly for gfx1151. HIP C++ is used only for launch, timing, and the
counter harness.

| gfx1151 code object | SHA-256 | status |
|---|---|---|
| baseline wave2 | `13424b1036af90fe8cfe991f030c244363ee2ce33e19652054f47d00987fb859` | measured |
| candidate wide128 | `b31630c522404a21db024d2784833ee1b90bbe1933dec738e7c027e00ddebfd6` | measured |

Both code objects report no LDS and no scratch. rocprofv3 reports allocation
granules of 40 VGPRs and 128 SGPRs for the candidate.

## Correctness

The production validator covered all 40 real checkpoint layers at exact
M1/N1024/K2048 and used the real layer weights. Against the model-native
rocBLAS plus SGLang SiLU path, the candidate remains inside the already accepted
raw-kernel envelope: maximum absolute BF16 difference is 0.0078125 and the
maximum differing BF16 elements in any layer is 156.

The existing FP64 spot check on real layers 0, 20, and 39 remains favorable to
the raw candidate relative to rocBLAS. Candidate mean absolute error was
0.000211626, 0.000129090, and 0.000185321 respectively, versus rocBLAS
0.000235129, 0.000149440, and 0.000220686.

The wide-load candidate is not universally bit-exact to the accepted raw wave2
kernel. A fixed real-weight activation fixture found four numerical BF16
differences across all 40 layers, with maximum absolute difference 6.1035e-5,
plus four signed-zero bit differences. The accepted wave2 result was slightly
closer to FP64 at all four numerical positions. This is recorded rather than
relaxing the established comparison.

Five random one-token matched serving inputs produced one equal output hash and
four later greedy-sequence divergences. The candidate was deterministic, and
candidate eager versus full graph was 5/5 output-hash exact. A natural Rayleigh
scattering prompt produced coherent output and its first 128 greedy tokens were
identical to wave2 and identical across three candidate repeats, hash
`be4a789bd20721c8573aded6af1de30c0a118b3ec4e73427f3be4a66300838e2`.

## HIP-event timing

The matched synthetic HIP-event sweep measured the 40-layer pass:

| gfx1151 measured configuration | Median / 40 layers | relative |
|---|---:|---:|
| accepted raw wave2 | 3.086074 ms | 1.000x |
| wide64 experiment | 2.385779 ms | 1.29353x |
| accepted wide128 candidate | 2.052549 ms | 1.50353x |

The production validator independently measured wide128 at 1.859712 ms median
for 40 layers versus 4.364053 ms for model-native rocBLAS plus SiLU, 2.34663x.
That comparison is not substituted for the matched raw-wave2 A/B above.

A workgroup-only sweep was negative: WG256/grid32 3.068102 ms,
WG128/grid64 3.077519 ms, WG64/grid128 3.066580 ms, and WG32/grid256
3.139756 ms. The instruction stream, not work partitioning, was the useful lever.
Wide64 is correct within the same numerical envelope but rejected because
wide128 is faster.

## rocprofv3 counters

Counters were collected one metric per fresh process with profiler signal
handlers disabled. All eighteen raw/rocBLAS passes completed without signal 6.
The table below compares the old raw wave2 counter artifact with wide128.

| gfx1151 measured counter | wave2 | wide128 |
|---|---:|---:|
| fetched KiB | 2050.59 | 2050.66 |
| L2 hit | 2.209% | 2.232% |
| mean occupancy / active CU | 12.764 | 12.494 |
| occupancy | 12.720% | 11.496% |
| memory-unit busy | 66.190% | 58.708% |
| waves | 256 | 256 |
| wave cycles | 9,119,944.5 | 6,353,654.0 |
| VALU instructions | 411 | 291 |

The profiler's `WRITE_SIZE` metric reported zero despite the required output
stores and is not used for byte accounting. The available gfx1151 metric set
does not expose a direct dependency-stall percentage, so none is estimated.
The structural result is 29.20% fewer reported VALU instructions and 30.33%
fewer wave cycles with unchanged fetched bytes and wave count.

## Matched serving A/B

Five matched seeds used exact 1 input + 128 output, cached tokens 0, eager graph
disabled, dFlash disabled. Decode wall covers 127 timed output intervals.

| gfx1151 measured median | wave2 | wide128 | change |
|---|---:|---:|---:|
| decode wall | 3390.195 ms | 3253.504 ms | -4.032% |
| output throughput | 37.461 tok/s | 39.035 tok/s | +4.201% |
| E2E wall | 3453.772 ms | 3314.631 ms | -4.029% |

The derived saving is 1.076 ms per decoded interval. The measured wide128 result
is the newest non-speculative batch-1 eager decode result, but the 50 tok/s target
is not yet achieved.

## Full graph gate

A native SGLang full decode graph captured batch 1 in 1.37 s and reported
3.05 GB graph memory. Five matched seeds produced identical candidate eager and
graph output hashes.

| gfx1151 measured median | wide128 eager | wide128 full graph |
|---|---:|---:|
| decode wall | 3253.504 ms | 3283.573 ms |
| output throughput | 39.035 tok/s | 38.677 tok/s |
| E2E wall | 3314.631 ms | 3331.209 ms |

Full graph is 0.924% slower in decode wall and 0.916% lower in output throughput,
so eager remains the performance choice for batch 1. The graph path remains a
correctness-safe option.

## SGLang versus llama.cpp interpretation

No matched llama.cpp run exists in this repository, so no framework speed ratio
is claimed. The newest complete eager request window measured 922.962 ms host
wall, 826.261 ms summed GPU kernels (89.523%), 101.371 ms positive launch gaps
(10.983%), and 31,421 kernel launches for exact 1 input + 32 output.

This evidence says the Python scheduler is not the dominant current bottleneck.
SGLang's very fragmented model path and CPU/GPU dispatch contribute materially,
but even eliminating all measured positive gaps would not by itself reach
50 tok/s. llama.cpp can plausibly benefit from a more static, coarser batch-1
execution path; that remains an inference until a same-checkpoint, same-token,
same-gfx1151 A/B is captured.

## Evidence

- Production correctness/graph JSON:
  `/tmp/bf16-shared-gate-up-wide128-production-validation.json`
- Matched serving artifacts:
  `results/serving/gfx1151/shared-gate-wave2-control-eager-1-plus128-20260731`
  and `results/serving/gfx1151/shared-gate-wide128-eager-1-plus128-20260731`
- Full graph artifacts:
  `results/serving/gfx1151/shared-gate-wide128-fullgraph-1-plus128-20260731`
- rocprofv3 counters:
  `results/profiles/gfx1151/bf16-shared-gate-up-wide128-counters-20260731`
- Before/after disassembly:
  `gfx1151-bf16-shared-gate-up-wide128-disassembly-2026-07-31/`
