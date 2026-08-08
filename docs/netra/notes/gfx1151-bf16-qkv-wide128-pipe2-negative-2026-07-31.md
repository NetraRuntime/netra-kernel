# gfx1151 BF16 QKV two-fragment pipeline — rejected

Date: 2026-07-31

Status: **rejected, measured on gfx1151**. Production remains the accepted bf16_qkv_decode_wave1_wide128_gfx1151 raw-ASM kernel. The Qwen3.6-35B-A3B checkpoint remains MXFP4 with its model-native BF16 QKV weights; no alternate quantization was tested and no estimated performance values are used.

## Ranked motivation

The latest exact eager 1-input/+32-output request trace ranks BF16 QKV second: 330 calls, 99.050357 ms total GPU duration, 300.153 us mean, and 11.717% of traced request wall, all measured on gfx1151. The accepted wide128 kernel executes eight K fragments, each with two 128-bit global loads followed by a full vmcnt(0) before four ordered BF16 dot2 instructions.

The experimental raw gfx1151 kernel primes fragment zero, issues fragment one while computing fragment zero, then issues the following fragment zero while computing fragment one. It preserves the exact four-dot order for all eight fragments, the 24-byte three-pointer kernarg, wave32 mode, grid 1152, workgroup 256, zero LDS/scratch, output layout, and caller stream. Static global-load sites rise from 2 to 6, dot2 sites from 4 to 12, and vmcnt wait sites from 1 to 3 because the two-fragment body is partially unrolled. Dynamic work and bytes are unchanged.

## Real-checkpoint correctness and HIP events

The reusable A/B harness loads the accepted and candidate modules before timing and uses the same ten real QKV weight tensors and deterministic BF16 activations. All 92,160 BF16 outputs are bit-exact: zero bit mismatches and maximum absolute difference 0 measured on gfx1151. Candidate eager output hashes also match HIP graph replay for every layer.

The 101-sample shared-process A/B/BA result is:

| gfx1151 measured ten-layer pass | Median | p90 |
|---|---:|---:|
| accepted wide128 | 2.647167 ms | 2.703311 ms |
| two-fragment pipeline | 2.647968 ms | 2.696579 ms |

The median speed ratio is 0.999697x, so the pipeline is 0.030% slower measured on gfx1151. Candidate graph replay measures 2.648931 ms median and remains bit-exact. An earlier 31-sample pass showed only 1.001150x; the larger interleaved run resolves that as noise.

Because the candidate failed the isolated real-checkpoint performance gate, no serving A/B was run and no end-to-end speedup is claimed.

## rocprofv3 evidence

Each counter was collected in a fresh process with rocprofv3 signal handlers disabled. Both kernels launch 9,216 waves, use 128 allocated SGPR, zero LDS, and zero scratch.

| gfx1151 measured counter | Accepted | Pipeline |
|---|---:|---:|
| allocated VGPR | 24 | 32 |
| fetched KiB | 18,438.781 | 18,439.969 |
| written KiB | 8.063 | 8.000 |
| L2 hit | 3.355% | 3.370% |
| mean occupancy / active CU | 59.578 | 58.291 |
| occupancy | 91.076% | 91.828% |
| memory-unit busy | 98.248% | 98.330% |
| waves | 9,216 | 9,216 |
| VALU instructions | 77 | 77 |
| mean sampled wave cycles | 1,349,637,550.5 | 1,274,117,765.5 |

Wave-cycle measurements have only two samples and wide dispersion, so their apparent reduction is not used as a speed claim. The stable observations are unchanged bytes, unchanged dynamic VALU work, already-saturated memory-unit busy, and an allocation-granule increase from 24 to 32 VGPR. The gfx1151 metric set exposes no direct dependency-stall percentage; none is estimated.

## Decision

The accepted kernel already has enough wave-level memory parallelism to hide this short loop. Added fragment ILP cannot improve the measured memory-bound dispatch and costs an extra VGPR allocation granule. The experimental source, disassembly, counters, and correctness/timing data are retained as a negative result; production source, HSACO, ABI, graph behavior, and launch geometry remain unchanged.

Production HSACO SHA-256 is aae22ff0fc0649273ab69a65c36fff2ad7157fd1a89571ebc1da82b6481bcf69. Experimental HSACO SHA-256 is 35502259b25364a333d2138f5ae236a7b9568c289e775173bddaa20e2ef78e06.

Evidence is under gfx1151-bf16-qkv-wide128-pipe2-negative-results-2026-07-31 and gfx1151-bf16-qkv-wide128-pipe2-negative-disassembly-2026-07-31.
