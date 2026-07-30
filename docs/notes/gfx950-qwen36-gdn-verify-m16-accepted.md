# Accepted gfx950 Qwen GDN M=16 verification pipeline

Target: AMD Instinct MI350X, CDNA4, `gfx950`, wave64

Checkpoint: Qwen3.6-35B-A3B FP8 E4M3, 128×128 blocks

## Raw implementation

The accepted fixed-shape target-verification pipeline is:

```text
kernels/gfx950/linear_attention/verify/
  qwen36_gdn_verify_m16_precompute_gfx950.s
  qwen36_gdn_verify_m16_precomputed_bv16_gfx950.s
runtime/gfx950/linear_attention/verify/
  qwen36_gdn_verify_m16_bridge.h
  qwen36_gdn_verify_m16_bridge.hip
```

The ABI is restricted to `B=1,T=16,H=16,HV=32,K=128,V=128`. The build script
selects precompute variant 7 (`triton-exact`) and core variant 13
(`fused-packed-exact`). HIP C++ loads modules, manages stable workspaces,
dispatches on the caller stream, and bridges graph capture; it does not hide a
targeted compute implementation.

## Correctness

A reusable real-checkpoint capture covers all 30 GDN layers. Normalized Q,
normalized K, decay, beta, BF16 output, BF16 recurrent state, graph replay, and
repeat execution are bit exact for every layer.

Aggregate checked elements:

| Boundary | Elements | Mismatches |
|---|---:|---:|
| normalized Q | 983,040 | 0 |
| normalized K | 983,040 | 0 |
| decay | 15,360 | 0 |
| beta | 15,360 | 0 |
| BF16 output | 1,966,080 | 0 |
| BF16 final state | 15,728,640 | 0 |

An eight-GPU sweep reproduced exact outputs on every MI350X. Concurrent
microkernel timing from that sweep is deliberately excluded from performance
claims.

## Arithmetic reconstruction

The precompute kernel reproduces the compiler’s adjacent-element lane layout,
Q/K row-pair order, split-ln2 logarithm conversion, and subnormal-preserving
exponential. A measured gfx950 dependency required `s_nop 0` between
`v_exp_f32` and `v_ldexp_f32`.

The recurrent core reproduces the deployed packed output reduction:

- V residues 0-3 and 8-11 use Q order `0,1,2,3,4,5,6,7`;
- V residues 4-7 and 12-15 use Q order `1,0,2,3,4,5,6,7`.

An earlier uniform reduction order was state-exact but left one to four BF16
output mismatches in 13 layers. An earlier layer-0-exact candidate also changed
dFlash verification behavior. Both remain rejected.

## HIP-event timing

One isolated MI350X, 2,000 iterations:

| Phase | Minimum | Median | Mean | p90 | Maximum |
|---|---:|---:|---:|---:|---:|
| precompute | 5.920 us | 6.120 us | 6.294 us | 6.360 us | 14.120 us |
| recurrent core | 18.080 us | 18.440 us | 18.630 us | 18.801 us | 30.040 us |
| combined | 24.040 us | 24.361 us | 24.538 us | 24.641 us | 33.160 us |

## Code-object contract

| Object | VGPR | SGPR | LDS | Private | Workgroups × threads |
|---|---:|---:|---:|---:|---:|
| precompute | 44 | 48 | 0 B | 0 B | 256 × 64 |
| recurrent core | 80 | 40 | 1,024 B | 0 B | 256 × 64 |

Both metadata records declare `amdgcn-amd-amdhsa--gfx950` and wavefront size
64.

```text
precompute hsaco ee599188d2d8562fc2a6b04b6048658a8abd1105c517e0e0da78c36ff02ed85c
core hsaco       2d787febfe8b305334d2aa6a9976b1c35e77598b6820ab10fe317fac7664bf41
bridge library   00a4f3b6654c406bc58c3e53ac8d41924f60eabe9a1020c675b471540393a732
```

## End-to-end acceptance

Paired full-graph dFlash runs retained identical hashes across 50 exact 16+2
requests and 20 exact 210+128 requests. Short-request median latency improved
2.32%. Matched 210+128 verification buckets improved latency 3.13-3.43% and
generation throughput 3.52-3.69%.

The kernel is accepted for counter profiling and broader serving gates. The
overall mission and piecewise-graph promotion remain incomplete.

## gfx950 counter evidence

The accepted pipeline was profiled in 18 separate `rocprofv3` counter passes.
Counter collection is intrusive, so the retained HIP-event and serving traces
remain the latency sources.

| Metric (median per dispatch) | Precompute | Recurrent core |
|---|---:|---:|
| Waves | 256 | 256 |
| Total instructions | 62,208 | 1,234,944 |
| VALU instructions | 40,192 | 1,092,608 |
| VMEM instructions | 3,072 | 58,368 |
| LDS instructions | 0 | 24,576 |
| MFMA instructions | 0 | 0 |
| L2 read sectors / bytes | 19,712 / 630,784 | 207,328 / 6,634,496 |
| L2 write sectors / bytes | 10,240 / 327,680 | 557,056 / 17,825,792 |
| Derived L2 hit fraction | 70.92% | 51.26% |
| VALU utilization | 56.13% | 97.54% |
| LDS bank-conflict metric | 0 | 0.3974 |
| Memory-unit stalled metric | 0.0020 | 0.0278 |

The profiler reports no AGPR or scratch allocation. It reports 24/40 VGPRs
for the two dispatches while the code-object metadata declares 44/80 VGPRs;
both representations are retained rather than conflated. The recurrent core,
not precompute, dominates instructions and traffic.

The reproducible driver is
`tools/benchmark/profile_gfx950_qwen36_gdn_verify_m16_counters.sh`. It asserts
both exact kernel names, the fixed shape, gfx950, and wave64.

## Piecewise-graph decision

Piecewise promotion is rejected for now. A matched candidate/control test
showed that the raw module launches themselves replay, and the raw pipeline
reduced diagnostic wall time, but both candidate and unmodified control
produced the same wrong cross-mode token sequences:

```text
16+2 piecewise     ab777d10ffa6693511a599f130f9a480b564093e7e231494afd17aa6eede6cba
16+2 accepted full 3eb632023967244c9991beff8a881c21ad15b4d0e48284e5f6ed14f4dfba2750

210+128 piecewise     8cf5682c0ab5307cb04b6d7292da155ddf14c7936f39fe10e849595e5967ea57
210+128 accepted full 6285266a2fb67a34940db360925b075d4f0c60efc8955bbf4a884558223025c3
```

The 210+128 piecewise output degenerates into repeated token 15 and reports an
implausible roughly 72% acceptance rate. Since the control has the same output
with `NETRA_GFX950_GDN_VERIFY_M16=0`, this is a pre-existing piecewise+dFlash
correctness failure rather than evidence against the raw GDN arithmetic.
Neither the candidate's 1,431.41 diagnostic generation tok/s nor its 110.03 ms
median wall time is valid throughput.

Primary evidence:

```text
/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z/
  kernel_experiments/qwen36_gdn_gfx950_accepted_bundle_20260730T210731Z/
  profiles/rocprof/isolated_gdn_verify_m16_20260731T234600Z/
  dflash/piecewise_specv1_block16_gdn_verify_raw_candidate_20260731T235000Z/
  dflash/piecewise_specv1_block16_gdn_verify_control_20260731T235500Z/
```
