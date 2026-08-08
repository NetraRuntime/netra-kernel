# Qwen3.6 BF16 attention gate on gfx950

Status: rejected for production integration on 2026-08-03; retained as a
bitwise-exact assembly/fusion reference.

The Qwen3.6 full-attention output gate is `x * sigmoid(gate)` over BF16
`[T, 16, 256]` tensors. The deployed eager path materializes the BF16 sigmoid
result before the BF16 multiply. The raw kernel preserves that rounding
boundary, uses one wave64 per token/head, and has no LDS, barrier, or scratch.
The gate view uses a 512-element head stride and a runtime token stride.

The final code object declares `amdgcn-amd-amdhsa--gfx950` and wavefront size
64. HIP C++ is restricted to module loading and dispatch.

## Isolated HIP-event results

All rows used 500 timed iterations and were bitwise equal to the eager BF16
result.

| Tokens | Eager (us) | Raw gfx950 (us) | Speedup |
|---:|---:|---:|---:|
| 1 | 14.440 | 12.480 | 1.157x |
| 12 | 15.921 | 12.480 | 1.276x |
| 64 | 16.080 | 12.560 | 1.280x |
| 768 | 19.360 | 13.001 | 1.489x |
| 1024 | 22.240 | 13.480 | 1.650x |

The T=768 row is the exact c64 dFlash target-verification layout.

## Serving result

The matched workload was single-gfx950, FP8 E4M3 weights, FP8 E4M3 KV,
dFlash block 12, piecewise graphs, concurrency 64, 192 requests, and exact
1024 input/1024 forced output tokens. Raw draft GQA4 was disabled, matching the
accepted production configuration.

Controls were 6998.36 and 7117.29 output tok/s; candidates were 7078.23 and
6999.72 output tok/s. The medians are 7057.83 and 7038.97 tok/s, respectively,
a 0.27% regression. The integration is therefore rejected even though the
isolated kernel is faster. A deterministic real-checkpoint response had the
identical SHA-256 on control and candidate:
`273f42231e06430aa603044d44a698e50a450cc0d936ef86a4cc586f3acaabe8`.

An initial A/B mistakenly forced the already-rejected raw draft GQA4 kernel.
Its unchanged control collapsed from 7282.64 tok/s and acceptance 4.177 to
3099.80 tok/s and acceptance 2.727, reproducing the known request-lifetime
state-reuse failure. The runtime-capacity GDN fix remained byte-identical to
its validated snapshot; GQA4, not the capacity fix, caused this regression.

## Development incident

The first isolated launch exposed an ABI bug: the kernel loaded pointer
arguments before preserving the workgroup id in `s2`. This caused a GPU virtual
memory fault. The instruction order was corrected before all results above;
subsequent eager and graph tests were bitwise exact and GPU 6 remained healthy.
The failed run and kernel log were retained in the benchmark directory.

Raw artifacts are under
`/data/netra/benchmarks/gfx950_qwen36_optimization/20260803T141500Z-gdn-contig-reduction-gpu6/attention-gate-build/`.
The corrected serving A/B and invalidated GQA4-on runs are under
`/data/netra/benchmarks/gfx950_qwen36_optimization/20260803T153000Z-attention-gate-ab-gpu6/`.

## Adjacent rejected variant

A contiguous-reduction/VOP3P update to the raw M12 GDN verifier measured
111.1015 us control versus 110.841 us candidate (0.23%). It also produced 16
mismatches over 3,145,728 values, maximum absolute error 1.907e-6. It was
reverted and rejected.
