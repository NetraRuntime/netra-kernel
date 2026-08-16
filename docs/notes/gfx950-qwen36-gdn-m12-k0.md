# Qwen3.6 dFlash M=12 K0 GDN verification on gfx950

## Accepted scope

This implementation replaces the lossless K0 (`cache_steps=0`) half of the
Qwen3.6 dFlash M=12 GDN verification path. It supports batches 1 through 64,
uses wave64 gfx950 code objects, and leaves accepted-prefix state replay on the
existing Triton state-update kernel. Qwen weights remain FP8 E4M3 with 128x128
blocks; this kernel consumes the model-native BF16 recurrent operands.

The production code consists of:

- `qwen36_gdn_verify_m12_batched_precompute_gfx950.s`, which prepares normalized
  Q/K, decay, and beta workspaces;
- `qwen36_gdn_verify_m12_batched_precomputed_bv16_gfx950.s`, which performs the
  recurrent computation and writes only BF16 outputs in K0 mode;
- a HIP module-loading and launch bridge. HIP does not implement the compute.

Build with `NETRA_GDN_K0_NO_INTERMEDIATE=1`. The production serving default is
variant 17 (`packed-pair-interleaved`); variant 13 (`fused-packed-exact`) is the
explicit bit-exact rollback via
`NETRA_GDN_CORE_VARIANT=fused-packed-exact`. Both disassemblies contain no
`global_store_dwordx4` and four `global_store_short` instructions, eliminating
the rejected full-state intermediate writes.

## Correctness and timing

Real-checkpoint layer-0 capture at B=64, M=12 compared 3,145,728 output elements:

- raw K0 versus Triton K0: bit exact, zero mismatches, max absolute error 0;
- Triton K0 versus the retained full-cache capture: bit exact;
- raw precompute plus core median: 119.1815 us over 100 HIP-event samples;
- Triton median: 186.6225 us;
- isolated median speedup: 1.56587x.

Artifact:
`/data/netra/benchmarks/gfx950_qwen36_optimization/20260801T100000Z-gdn-k0-raw-layer0-gpu5/result.json`.

## gfx950 evidence

The built code objects declare `amdgcn-amd-amdhsa--gfx950` and wavefront size
64. Metadata reports 1,024 bytes group segment, zero private segment, 40 SGPRs,
and 80 VGPRs. rocprofv3 reports workgroup 64, LDS 1,024 bytes, scratch 0,
VGPR count 40, and SGPR count 48; the apparent register-count difference is
retained as reported by each tool rather than normalized across allocation
units.

For 11 counter-instrumented core dispatches, medians were:

- duration: 105.001 us;
- `SQ_WAVES`: 16,384;
- `SQ_INSTS_VALU`: 48,693,248;
- `SQ_INSTS_LDS`: 1,179,648;
- `SQ_INSTS_VMEM`: 2,031,616;
- `SQ_WAIT_ANY`: 47,401,862;
- `GRBM_GUI_ACTIVE`: 1,722,782;
- `TCC_READ_SECTORS_sum`: 9,744,516;
- `TCC_WRITE_SECTORS_sum`: 1,572,864.

These are raw supported gfx950 counter values. No sector-to-byte conversion is
claimed here. Counter artifacts are under
`/data/netra/benchmarks/gfx950_qwen36_optimization/20260801T104500Z-gdn-k0-raw-counters-gpu5/`.

`rocprof-compute` was present but could not run in the profiling environment
because its exact Python dependencies (including pandas) were absent. The host
environment was not modified; rocprofv3 PMC collection was used instead.

## End-to-end acceptance

The SGLang integration reached 4,445.627 output tok/s at concurrency 64 for
1,024-input/256-output requests, compared with 4,107.910 tok/s for a reverse-order
same-GPU control (+8.221%). Fixed small-request hashes were stable. A clean full
GSM8K run scored 0.9558599696, exactly matching the strongest retained control.

The earlier full-state raw variant was rejected: it wrote roughly 805 MiB of
intermediate snapshots per B=64/M=12 invocation and slowed serving despite a
microbenchmark win. K0 is accepted because it removes those stores and improves
the complete request path without a correctness loss.

## 2026-08-16 serving-default promotion

A matched five-run single-MI350X A/B used 384 random requests, exactly 1,024
input and 1,024 forced output tokens per request, concurrency 128, DFlash block
12, temperature zero, and seed 20260809. Variant 17 averaged 9,083.34 output
tok/s versus 8,830.10 for variant 13: +2.868%. Medians were 9,095.11 and
8,874.47 tok/s respectively (+2.486%).

Variant 17 changes FP32 association and raises mean acceptance on this greedy
workload from 4.413 to 6.506, so the end-to-end gain is not claimed as raw
kernel latency alone. Its established tolerance remains 163 of 3,145,728 BF16
outputs differing from Triton, with maximum absolute error 0.0009765625. The
previous GSM8K-200 gate scored 94.5% versus a retained exact-control range of
95.5--96.0%; this tradeoff is explicitly accepted for the serving default.

Artifact:
`/data/netra/benchmarks/gfx950_qwen36_optimization/best-single-gpu-1k1k-gdn-v17-20260816/`.
