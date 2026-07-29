# gfx1151 QKVZ/BA split-copy replacement (2026-07-29)

## Decision

Accepted for the Qwen3.6 GDN prefill path on gfx1151. Final compute is
`qkvzba_split_copy_gfx1151` in hand-written AMDGCN `.s`; HIP is launch-only.
It preserves MXFP4 weights and copies model-native BF16. The opt-out
`SGLANG_NETRA_DISABLE_QKVZBA_SPLIT_COPY=1` retains the Triton baseline.

## Trace-driven target

The complete trace ranked the existing contiguous split sixth by total GPU
cost in both long-prefill scenarios. On measured gfx1151 it consumed 372.615
ms across 60 calls for 8,192/+1 (4.75% of GPU time), and 1,490.657 ms across
150 calls for 32,768/+1 (4.28%). The operation is a fixed BF16 layout copy:
`[M,12288] -> [M,8192] + [M,32,128]` and `[M,64] -> [M,32] + [M,32]`.

## Design and correctness

The raw kernel launches `(7,M,1)` workgroups of 256 work-items. Each active
work-item moves one aligned 16-byte vector. Four groups copy QKV, two copy Z,
and eight lanes of the final group copy B/A. It has no LDS, barrier,
conversion, allocation, or scratch path.

At M=1, 64, 210, and 8,192, every QKV, Z, B, and A output bit matched the
SGLang Triton oracle. BF16 bit-pattern comparison was used so NaN payloads
cannot hide a mismatch. All four mismatch counts were zero at every shape.
The real checkpoint produced the same output hash for matched 32,768/+1 eager
runs and for matched M64 eager/piecewise replay.

One-token greedy serving is not globally deterministic for every input on this
baseline. One of five matched pairs at M210 and M8192 differed, while repeating
the unchanged Triton baseline for the same M8192 input also changed from `in`
to a space. Four of five pairs matched at each tier. This is recorded as a
model/runtime reduction-order property; direct kernel correctness is bit-exact.

## HIP-event and rocprofv3 evidence

All rows are gfx1151 measured with HIP events, 50 repetitions after 20 warmups.
Bytes are total input plus output traffic.

| M | Bytes | Triton median ms | Raw ASM median ms | Speedup | Correctness |
|---:|---:|---:|---:|---:|---|
| 1 | 49,408 | 0.012433 | 0.007735 | 1.6074x | bit-exact |
| 64 | 3,162,112 | 0.013661 | 0.009658 | 1.4144x | bit-exact |
| 210 | 10,375,680 | 0.027947 | 0.018395 | 1.5193x | bit-exact |
| 8,192 | 404,750,336 | 12.437214 | 1.771805 | 7.0195x | bit-exact |

An ABI-matched rocprofv3 CSV trace independently measured 16 M8192 calls per
implementation: Triton totaled 198.046 ms at 12.378 ms mean; raw ASM totaled
28.196 ms at 1.762 ms mean. This is measured, not estimated.

The `/opt/rocm-7.2.1/bin/rocprofv3` counter harness measured 8 VGPR, 128
reported SGPR allocation, zero LDS, zero scratch, 458,752 waves, 77.400%
occupancy, 86.684% memory-unit busy, 33.335% L2 hit, zero LDS conflicts, and
41.605% write-unit stalled. `FETCH_SIZE` and `WRITE_SIZE` were 98,817.625 KiB
and 98,350 KiB. Direct dependency-stall is not exposed on gfx1151 by this set.

Static gfx1151 disassembly has 117 executable instructions, 12 waits, eight
global loads/stores, and eight delay instructions for Triton, versus 58
instructions, five waits, four 128-bit loads/stores, and no delays for raw ASM.
Neither spills or uses LDS. Full before/after disassemblies are checked in.

## Uncached serving impact

These are gfx1151 measured host end-to-end HTTP timings with graph and dFlash
disabled. M210/M8192 use five unique-prefix repetitions; M32768 is a matched
single run after an M8192 warmup. Every request observed zero cached tokens.

| Input/output | Triton baseline | Raw ASM | Speedup | Status |
|---:|---:|---:|---:|---|
| 210/+1 | 536.056 ms median | 535.832 ms median | 1.0004x | neutral |
| 8,192/+1 | 7,073.980 ms median | 6,761.489 ms median | 1.0462x | accepted |
| 32,768/+1 | 35,399.053 ms | 34,114.981 ms | 1.0376x | accepted |


Matched streamed +1 runs explicitly measured TTFT. Output throughput is N/A
for a single output token; total latency and TTFT differ only by response
bookkeeping. Graph and dFlash were disabled.

| Input/output | Mode | TTFT ms | Input tok/s | Total ms | Peak VRAM bytes | Cached |
|---:|---|---:|---:|---:|---:|---:|
| 8,192/+1 | Triton | 7,103.483 | 1,153.237 | 7,103.554 | 61,531,357,184 | 0 |
| 8,192/+1 | raw ASM | 6,803.236 | 1,204.133 | 6,803.290 | 61,530,914,816 | 0 |
| 32,768/+1 | Triton | 35,226.947 | 930.197 | 35,227.054 | 61,533,458,432 | 0 |
| 32,768/+1 | raw ASM | 33,941.126 | 965.436 | 33,941.271 | 61,533,011,968 | 0 |
The measured M32768 output hash matched. Peak sysfs VRAM was 61,789,110,272
bytes baseline and 61,705,265,152 bytes raw. This includes unified-memory
accounting and is reported exactly as observed.

## Graph integration

Initial native `tc_piecewise` capture exposed direct-ctypes graph breaks in the
existing M=1 QKVZ+BA fusion and general M=1 linear path. Both now cross a
registered custom-op boundary while retaining raw AMDGCN compute. Final gfx1151
M64 capture completed in 12.06 s with 0.28 GB graph memory. Uncached M64/+1
replay completed in 510.610 ms and matched eager input and output hashes.
Modules load before capture and the raw launch uses the current graph stream.

## Reproduction artifacts

- `tools/benchmark/benchmark_qkvzba_split_copy.py`
- `tools/profiling/profile_qkvzba_split_copy_counters.sh`
- `docs/notes/gfx1151-qkvzba-split-copy-hip-events-2026-07-29.json`
- `docs/notes/gfx1151-qkvzba-split-copy-counters-2026-07-29.json`
- `docs/notes/gfx1151-qkvzba-split-copy-disassembly-2026-07-29.json`
- `docs/notes/disassembly/gfx1151-qkvzba-split-copy-2026-07-29/`
- `docs/notes/gfx1151-qkvzba-split-copy-serving-2026-07-29.json`
