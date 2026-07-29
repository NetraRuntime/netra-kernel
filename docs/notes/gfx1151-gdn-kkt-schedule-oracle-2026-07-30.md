# gfx1151 GDN KKT scheduling oracle (2026-07-30)

## Outcome

The exact Qwen3.6 GDN KKT shape has a bit-exact one-wave scheduling oracle on gfx1151. The standard Triton kernel at `BK=64`, one wave (`num_warps=1`) measured 5.184967 ms median with HIP events, versus 5.955927 ms for the production four-wave schedule: a measured 1.148691x kernel speedup on gfx1151.

This compiler kernel is an oracle only. It is not enabled in production and is not an accepted final compute implementation. The targeted replacement must be hand-written gfx1151 AMDGCN assembly.

## Why this is next

The post-expert-reduction exact-32K rocprofv3 trace ranks `chunk_gated_delta_rule_fwd_kkt_solve_kernel` eighth by total request GPU cost: 150 invocations, 961.425615 ms total, and 6,409.504 us mean on gfx1151. Its measured median dispatch was 7,963.921 us. The production dispatch uses 256 VGPR, the profiler reports 128 SGPR, 128 bytes scratch, grid `128x32`, and workgroup `128x1` for the T8192 tier.

## Reproduction

```bash
source /root/sglvenv1151/bin/activate
cd /root/netra-mxfp4-gfx1151
python tools/benchmark/benchmark_gdn_kkt_schedules.py \
  > results/kernels/gfx1151/gdn-kkt-schedule-sweep.json
```

The benchmark uses the model-real shape `B=1, T=8192, H=32, Hg=16, K=128, BT=64, BC=16`, variable-length indexing, BF16 K/beta/output, and FP32 cumulative gates. All timings below are measured on gfx1151 with HIP events. Correctness compares every BF16 output bit to the production `BK64/w4` result after honoring the wrapper's zero-initialized upper-triangle contract.

| Implementation | BK | Waves/workgroup | Median ms | Speedup | BF16 bit mismatches | Max abs |
|---|---:|---:|---:|---:|---:|---:|
| production standard | 64 | 4 | 5.955927 | 1.000000x | 0 | 0 |
| standard scheduling oracle | 64 | 1 | 5.184967 | 1.148691x | 0 | 0 |
| standard scheduling oracle | 64 | 2 | 6.099676 | 0.976433x | 0 | 0 |
| standard scheduling oracle | 32 | 1 | 5.349185 | 1.113427x | 0 | 0 |
| standard scheduling oracle | 32 | 2 | 6.166210 | 0.965897x | 0 | 0 |
| standard scheduling oracle | 32 | 4 | 5.483027 | 1.086248x | 0 | 0 |
| XPU low-register variant | 64 | 4 | 20.237852 | 0.294296x | 66,258 | 0.0001220703125 |
| XPU low-register variant | 64 | 8 | 11.897243 | 0.500614x | 66,258 | 0.0001220703125 |
| XPU low-register variant | 32 | 4 | 18.121284 | 0.328670x | 66,258 | 0.0001220703125 |
| XPU low-register variant | 32 | 8 | 13.209471 | 0.450883x | 66,258 | 0.0001220703125 |

The low-register rewrite is rejected on measured gfx1151 correctness and performance. Its changed accumulation order produces the same 66,258 BF16 differences in every tested schedule and its best case is 1.9975x slower than production.

## Static gfx1151 disassembly comparison

The retained code-object disassembly and unified diff are under `docs/notes/disassembly/gdn-kkt-schedule-oracle-gfx1151/`.

| Static property | Production BK64/w4 | Oracle BK64/w1 |
|---|---:|---:|
| workgroup size | 128 | 32 |
| VGPR metadata | 256 | 256 |
| SGPR metadata | 38 | 42 |
| private segment | 172 B | 916 B |
| group segment | 0 B | 0 B |
| `v_wmma_f32_16x16x16_bf16` | 80 | 80 |
| `s_waitcnt` occurrences | 275 | 361 |
| scratch/flat-scratch references | 148 | 430 |
| barrier occurrences | 78 | 0 |

The one-wave schedule wins despite substantially more compiler spill traffic. The concrete opportunity is therefore not simply lower reported scratch: it is the one-wave mapping with no cross-wave barriers. A raw implementation should keep that mapping while manually controlling the recurrent rows so it does not inherit the oracle's 916-byte private segment.

The scheduling microbenchmark did not collect cache counters, bytes transferred, occupancy, or dependency-stall counters, so none are estimated here. The request trace and static code-object metadata are reported separately rather than mislabelled as counter measurements.

## Raw gfx1151 ASM design gate

The candidate raw kernel should use one wave per `(chunk, head)` workgroup, retain the 16x16 block recurrence and all 80 WMMA issue sites, preserve production accumulation order, and preserve the zero upper triangle expected by downstream solves. For T8192 this is a `128x32` grid of 4,096 independent workgroups. Manual VGPR/scratch placement must be validated rather than inferred.

Acceptance requires:

1. zero BF16 bit mismatches at the controlled exact shape;
2. real-checkpoint per-layer and greedy-token validation;
3. identical eager and graph replay outputs;
4. rocprofv3 counters plus HIP-event timing at identical shapes;
5. measured full-request improvement on gfx1151.

No production setting changes in this milestone.
