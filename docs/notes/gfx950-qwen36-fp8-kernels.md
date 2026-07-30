# gfx950 Qwen3.6 FP8 kernel development

Target: AMD Instinct MI350X, CDNA4, `gfx950`, wave64
Checkpoint: Qwen3.6-35B-A3B FP8 E4M3, 128×128 weight blocks

This hierarchy is independent of the retained gfx1151 wave32/MXFP4 work. No
gfx1151 instruction selection, wave organization, layout, or measurement is
carried over as MI350X evidence.

## First measured experiment

The first scheduler-attached decode trace ranked the AITER/CK two-stage MoE
pipeline as a critical region. Its per-layer sequence is:

1. 256-expert/top-9 sorting;
2. BF16→FP8 E4M3 per-128 activation quantization;
3. split-K FP8 stage-1 GEMM;
4. FP32→BF16 SiLU×up;
5. BF16→FP8 E4M3 per-128 quantization;
6. FP8 stage-2 GEMM.

The exact stage-1 launch has 72 workgroups/288 waves across 256 CUs and stage 2
has 144 workgroups/576 waves. Per-XCD wave counts are exactly balanced. The
first raw-assembly experiment therefore fuses steps 4 and 5 for the measured
fixed decode shape: nine rows, width 512, four 128-value groups per row.

Source:

```text
kernels/gfx950/fp8/moe/decode/experiments/
  qwen36_moe_silu_mul_quant_fp8_gfx950.s
```

It deliberately remains under `experiments/`. Promotion requires:

- real-checkpoint layer-output, routing, logit, and greedy-token gates;
- eager/full-graph/piecewise-graph replay parity;
- positive uncached end-to-end serving impact.

### Isolated result

The raw production-shaped code object now passes the isolated deployed-contract
gate:

- 0/4,608 FP8 E4M3 byte mismatches;
- 0/36 FP32 scale mismatches;
- a temporary diagnostic build also produced 0/4,608 BF16-rounded
  intermediate mismatches before the diagnostic ABI was removed.

It also passes the exact live AITER request boundary. An eager/auto SGLang
server kept capture disabled throughout warmup, then captured one M=1 decode
boundary inside an uncached exact 16-input/2-output request. The raw HIP bridge
replayed the captured FP32 `[9,1024]` stage-1 tensor and matched all 4,608
captured FP8 bytes and all 36 scales exactly. Captured and raw hashes were:

```text
FP8   41dcc16cbf14afdd14098c4b0447c4ffed0436ac7fb139dd17ecc5af5bb2128f
scale e1cd428337b6dc1ecb6b111601986ad2c46b75fbae81ea04868ed0fea75a7021
```

The reference deliberately matches the deployed gfx950 instruction stream:
the subgroup maximum is broadcast to all lanes and the scale uses
`v_mul_f32` with rounded `1/448` (`0x3b124925`). Early harness variants that
used lane-private partial maxima or generic IEEE division were invalid
oracles and are retained in the development record, not counted as kernel
failures.

Five 5,000-iteration HIP-event runs on GPU 0 measured:

| Run | Two HIP kernels (µs) | Raw fused (µs) | Speedup |
|---:|---:|---:|---:|
| 1 | 5.591 | 2.809 | 1.990× |
| 2 | 5.506 | 2.778 | 1.982× |
| 3 | 5.258 | 2.575 | 2.042× |
| 4 | 5.582 | 2.787 | 2.002× |
| 5 | 5.523 | 2.782 | 1.985× |

Median raw duration is 2.782 µs; median per-run speedup is 1.990×. These are
isolated harness measurements, not serving throughput.

An intrusive rocprofv3 trace recorded 251 raw dispatches at 2.742 µs mean.
Code-object metadata declares `gfx950`, wave64, 64-thread maximum workgroups,
35 VGPRs, 27 SGPRs, no AGPRs, no LDS, no private segment, and no declared
spills. The static object contains 133 instructions, four 128-bit global
loads, two global stores, and three wait-count instructions.

The reusable C ABI bridge is:

```text
runtime/gfx950/fp8/moe/
  qwen36_moe_silu_mul_quant_bridge.h
  qwen36_moe_silu_mul_quant_bridge.hip
```

It hard-gates gfx950 at module load, preloads the raw hsaco before capture, and
launches on the caller's HIP stream without allocation or synchronization.
Its current SHA-256 is
`6afa10d518cc76bd0594715a3ea7a4cf89440cea0a003a3a31b59dcdaa587baf`.

The XCD counter pass collected 71 raw dispatches. Every nine-wave dispatch
placed two waves on XCD0 and one wave on each other XCD: all eight XCDs are
used and the one-wave difference is the unavoidable 9÷8 remainder, not a
scheduler imbalance. Counter-instrumented durations are not wall-time
measurements.

Artifacts:

```text
/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z/
  kernel_experiments/
    qwen36_moe_silu_mul_quant_fp8_gfx950_20260729T225736Z/
```

## Fast edit-to-correctness loop

The exact uncached request-stage tensors are reused for assembly development:

```bash
tools/benchmark/iterate_gfx950_qwen36_moe_silu_mul_quant.sh
```

The build always reassembles, relinks, regenerates disassembly and metadata,
but rebuilds the HIP harness and bridge only when their sources are stale. A
named lightweight container stays alive as `sleep` between iterations, so it
does not retain a GPU allocation. Two consecutive measured invocations were:

| Invocation | Build (s) | Validation (s) | Total (s) |
|---:|---:|---:|---:|
| cold validator container | 0.197 | 1.417 | 1.847 |
| steady state | 0.184 | 1.345 | 1.560 |

Both passed with zero FP8-byte and scale mismatches. These timings describe
the development loop, not kernel or serving performance.

## SGLang runtime integration

The opt-in SGLang adapter preloads this repository's HIP bridge and raw hsaco
before graph capture, then replaces only the exact AITER M=1 inter-stage
activation/quant boundary. A real captured tensor passed through the SGLang
custom op, bridge, and raw object with zero mismatches. An isolated native HIP
graph capture/replay passed the same exact gate.

An intrusive same-forward real-checkpoint run compared deployed AITER and raw
outputs for every decoder layer before returning raw outputs to stage 2:

- 40/40 distinct decoder-layer records passed;
- 0/184,320 FP8-byte mismatches;
- 0/1,440 FP32-scale mismatches.

The cross-process greedy-token gate remains rejected. Baseline and raw runs
already diverged during 16-token prefill, where this M=1 kernel cannot execute,
confirming the previously measured auto/AITER nondeterminism. Five 210+128
diagnostic runs per path showed a 1.01149× median decode-throughput ratio, but
each path produced five unique token hashes. That timing is not eligible for
acceptance.

The exact 210+128 rocprofv3 request window confirmed 5,120 replaced boundaries:
5,120 AITER activation dispatches and 5,120 inter-stage quant dispatches were
replaced by 5,120 raw dispatches. This is a net reduction of 5,120 kernels and
HIP launches. The raw mean was 2.607 µs; merged request-window GPU-busy time
was 10.678 ms lower than the retained baseline. The profiler is intrusive and
the token gate failed, so these are structural/GPU-cost results only.

Artifacts:

```text
/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z/
  correctness/eager_aiter_raw_shadow_20260729T234552Z/
  performance/eager_aiter_raw_ab_candidate_20260730T000244Z/
  profiles/rocprof/eager_auto_raw_gfx950_attach_20260730T000958Z/
```

The experiment is still not accepted. It must next pass across complete real
Qwen layer outputs, then graph replay, logit/token, and uncached end-to-end
gates. The exact request-stage pass closes the isolated live-boundary gate but
does not by itself prove stage-2 or layer-output parity. A faster
microbenchmark alone does not promote it.

## Deterministic M=1 down projection and expert reduction

Same-process all-layer capture localized the first AITER mismatch to
`model.layers.0.mlp.experts`. Exact CK stage-2 capture then showed its FP8
activation/scales were correct, but the BF16 result was effectively
uncorrelated with the independent block-scale dequantize/matmul/reduce oracle.
Explicit destination zeroing and K-split removal restored repeatability, not
agreement with the retained Triton or high-precision oracle.

The correctness-first replacement is:

```text
kernels/gfx950/fp8/moe/decode/experiments/
  qwen36_moe_down_reduce_fp8_gfx950.s
harness/gfx950/fp8/moe/decode/
  qwen36_moe_down_reduce_fp8_gfx950.hip
```

It consumes the exact M=1 shape: nine FP8 E4M3 `[512]` routed activations,
128-wide activation scales, FP8 `[2048,512]` expert weights with 128x128
scales, routed IDs/weights, and emits one deterministic BF16 `[2048]` row.
One wave64 owns 64 output columns and the 32-wave grid covers the output.

gfx950 rejected the RDNA-style packed FP8 `dot4` instruction. The retained
seed therefore uses native OCP-FP8 conversion plus fixed-order FP32 FMAs; the
next variant must re-tile the same contract around CDNA4 MFMA.

Real-capture correctness:

| Check | Result |
|---|---:|
| cosine versus FP32 oracle | 0.999999 |
| maximum absolute error | 2.45431e-5 |
| mean absolute error | 2.62760e-6 |
| BF16 mismatches versus oracle | 1 / 2,048 |
| BF16 mismatches versus deployed CK | 2,044 / 2,048 |

The scalar seed measures 187.76 µs by HIP events. rocprofv3 recorded 30
dispatches at 185.647 µs mean and 185.12 µs median. It is correctness evidence,
not a performance candidate. The code object SHA-256 is
`cd7c5f1a56f230edcd7e3fb407e5107b0993c50abb526df719288ef06b3a6a09`;
metadata declares gfx950/wave64, 10 VGPRs, 41 SGPRs, no LDS/private segment,
and a 64-thread maximum workgroup.

The edit-to-result loop is:

```bash
tools/benchmark/iterate_gfx950_qwen36_moe_down_reduce.sh
```

It reassembles, links, regenerates disassembly/metadata, and runs 20
real-capture validations in 0.415 seconds total (0.189 seconds build, 0.226
seconds validation) without restarting SGLang.

Artifacts:

```text
/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z/
  correctness/eager_aiter_prezero_noksplit_stage2_capture_20260730T010056Z/
  kernel_experiments/qwen36_moe_down_reduce_fp8_gfx950_20260730T010200Z/
```

Status is **correctness seed, not accepted**. MFMA performance, full layer
integration, Triton-oracle parity, graph replay, and uncached request impact
remain open gates.

## Native CDNA4 MFMA decode projections

The scalar seed has now been re-tiled around the gfx950-native
`v_mfma_f32_16x16x128_f8f6f4` instruction:

```text
kernels/gfx950/fp8/moe/decode/experiments/
  qwen36_moe_down_reduce_fp8_mfma_gfx950.s
  qwen36_moe_gate_up_fp8_mfma_gfx950.s
```

Both kernels use wave64, map one wave to 16 output columns, consume the
checkpoint's FP8 E4M3 values without format conversion, and apply the original
FP32 128x128 scales after each K=128 MFMA. They use 30 VGPRs, 40–42 SGPRs, no
LDS, no scratch, and no private segment.

Real-capture results:

| Kernel | Shape | Oracle cosine | Max abs | Determinism | HIP median |
|---|---|---:|---:|---:|---:|
| gate/up stage 1 | 9×(1×2048 · 2048×1024) | 1.000000 | 1.12891e-4 | 100/100 exact | 8.96 µs |
| down + routed reduction | 9×(1×512 · 512×2048) | 0.999999 | 2.45431e-5 | 100/100 exact | 13.08 µs |

The MFMA down/reduce kernel is about 14.4× faster than the 187.76 µs scalar
seed. Its 30/2,048 BF16 differences from the independent oracle are confined
to FP32 accumulation order; the maximum and mean FP32 errors remain
2.45431e-5 and 2.62836e-6. The isolated harness now copies and compares every
output after each launch, so determinism is measured rather than inferred.

The new gate/up loop is:

```bash
tools/benchmark/iterate_gfx950_qwen36_moe_gate_up_mfma.sh
```

A warm edit-to-result iteration takes 0.429 seconds: 0.187 seconds to
assemble/link/inspect and 0.243 seconds for 100 deterministic real-capture
validations. The down/reduce loop takes 0.416 seconds for the corresponding
100-launch gate.

The stage-1 capture and exported oracle are retained at:

```text
/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z/
  correctness/eager_aiter_stage1_exact_capture_20260730T015902Z/
  kernel_experiments/qwen36_moe_stage1_fp8_gfx950_20260730T020100Z/
```

The deployed AITER stage-1 tensor has cosine `-0.010015` to the independent
block-scale oracle and is not a correctness reference. These MFMA kernels are
still experimental until the complete raw M=1 pipeline passes full-layer and
deterministic Triton token gates.

## Complete raw M=1 pipeline integration

The gate/up MFMA, exact SiLU/FP8 quantizer, and down/reduce MFMA kernels are
now integrated as one opt-in M=1 path. Raw compute and the HIP module bridge
remain in `netra-kernel`; the SGLang adapter only recognizes the exact Qwen
decode shapes, passes the original FP32 checkpoint scales, and dispatches on
the caller stream.

Real-checkpoint eager execution passed the deterministic Triton token oracle:

- 20/20 identical 16-input/2-output requests produced `[220,220]` and SHA-256
  `3eb632023967244c9991beff8a881c21ad15b4d0e48284e5f6ed14f4dfba2750`;
- 5/5 exact 210-input/128-output requests produced one stable SHA-256,
  `6285266a2fb67a34940db360925b075d4f0c60efc8955bbf4a884558223025c3`;
- the same hashes passed native full-graph capture/replay.

Eager integration is rejected for performance: median 210+128 wall time was
5.14697 seconds versus 4.85537 seconds for pure Triton, a 6.01% regression.
A one-decode Torch trace showed why. The three raw kernels totaled only about
1.64 ms over 40 layers, while the enclosing Python/AITER MoE dispatch consumed
11.71 ms of inclusive CPU operator time and the trace contained 2,792
`aten::empty` calls.

The raw kernels' real-weight durations in that trace were:

| Kernel | Calls | Mean |
|---|---:|---:|
| gate/up MFMA | 40 | 13.486 µs |
| SiLU + FP8 quant | 40 | 2.846 µs |
| down + routed reduction MFMA | 40 | 24.773 µs |

Preloading the code objects before capture and allowing already-installed
wrappers during capture removed that eager orchestration from replay. Matched
full-graph serving results were:

| Exact case | Full Triton median | Full raw median | Raw speedup |
|---|---:|---:|---:|
| 16 input + 2 output, wall | 59.062 ms | 58.214 ms | 1.0146× |
| 210 input + 128 output, wall | 909.655 ms | 854.718 ms | 1.0643× |
| 210 input + 128 output, decode throughput | 148.014 tok/s | 158.288 tok/s | 1.0694× |

The raw full-graph path produced one hash across all five long runs. The
matched full-Triton control produced two hashes, so its timing is retained as
the performance control but it did not pass its own repeatability gate.

The first piecewise runs exposed rare token drift in both raw and pure-Triton
controls. Exact-operand capture later proved that untuned AITER CK dense M=210
prefill GEMMs were independently nondeterministic, so those token drifts no
longer establish a graph-state or raw-kernel defect.

Experimental compiled M=210 CKTile and Triton integrations subsequently caused
AMDGPU `VM_L2_PROTECTION_FAULT` events. The faults reproduced with one-wave
raw, two-wave raw, and raw disabled. Restoring the pinned SGLang FP8 graph path
made both raw-off and two-wave controls memory-safe. The fault is therefore
attributed to the rejected compiled-M210 integration, not the raw gfx950
decode objects.

The accepted interim policy makes exact M=210 prefill an explicit eager graph
break, uses deterministic CKTile for its untuned block-FP8 GEMMs, retains
piecewise capture for other buckets, and keeps the two-wave raw M=1 decode
path. It produced one hash in 200/200 seeded 210+8 probes, 40/40 exact 210+1
requests, and 40/40 exact 210+128 requests. Median walls were 96.848 ms,
54.057 ms, and 815.616 ms respectively. The long-run hash was
`6285266a2fb67a34940db360925b075d4f0c60efc8955bbf4a884558223025c3`.
Capture evidence excludes bucket 210 and records its prefill as
`cuda graph: False`. Native M=210 piecewise capture remains rejected; this
explicit graph-break policy is accepted for continued validation.

ROCm 7.2 rocprofv3 dynamic-attach and process-start tracing both crashed the
scheduler in `at::cuda::CUDAGraph::replay()` after five output tokens. Their
partial outputs are negative profiler-compatibility artifacts, not timing
evidence. Full-graph wall measurements are unprofiled; raw-kernel timings above
come from the separate eager Torch trace and isolated HIP-event runs.

Code-object hashes used by the passing full-graph run:

```text
gate/up:       8b5640f7d4244effd0ea263d8c7b579aaf4650ebfcd28be94351d85e62390ba0
SiLU/quant:    6d87114b3bcc5028d9bad3e219c584be7e34bd79baa9010b76a1466c38fecd91
down/reduce:   4aea649a7ec6f03c400aa321dc5f9289c943bfd57a235909163d3aba73f86580
HIP bridge:    229da8b2e686f70c5b98aa9ca4f520febc302093469d2d31215f61a3a5e45230
```

Retained artifacts:

```text
/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z/
  correctness/eager_triton_prefill_raw_full_m1_20260730T021651Z/
  performance/eager_triton_raw_full_m1_ab_baseline_20260730T022125Z/
  performance/eager_triton_raw_full_m1_ab_candidate_20260730T022322Z/
  performance/full_triton_raw_full_m1_candidate_20260730T022931Z/
  performance/full_triton_raw_full_m1_baseline_20260730T023109Z/
  correctness/piecewise_triton_raw_full_m1_20260730T023309Z/
  correctness/piecewise_triton_control_20260730T024848Z/
  correctness/piecewise_raw_2wave_fp8cktile_all_m210_20260730T042900Z/
  correctness/piecewise_selective_two_m210_20260730T044202Z/
  correctness/piecewise_qkvz_only_m210_20260730T044511Z/
  correctness/piecewise_m210_graph_cktile_20260730T045227Z/
  correctness/piecewise_m210_graph_triton_20260730T045709Z/
  correctness/piecewise_raw_off_fp8utils_head_20260730T050953Z/
  correctness/piecewise_raw_two_wave_fp8utils_head_20260730T051214Z/
  correctness/piecewise_raw_two_wave_m210_eager_cktile_20260730T051615Z/
  kernel_experiments/qwen36_fp8_qkvz_m210_graph_20260730T044400Z/
  kernel_experiments/qwen36_fp8_qkvz_m210_compiled_custom_op_20260730T045100Z/
  kernel_experiments/qwen36_fp8_attn_qkv_m210_compiled_custom_op_20260730T045130Z/
  kernel_experiments/qwen36_fp8_qkvz_m210_compiled_custom_triton_20260730T045600Z/
  kernel_experiments/qwen36_fp8_attn_qkv_m210_compiled_custom_triton_20260730T045630Z/
  profiles/rocprof/full_raw_m1_attach_20260730T023811Z/
  profiles/rocprof/full_raw_m1_wrapped_20260730T024030Z/
```

Status: **accepted for continued full-graph and explicit-M210-break piecewise
validation**. Counter evidence, complete layer/state tolerances, longer
required cases, and native M=210 piecewise capture remain open before
production promotion.

## Rejected dense M=1 output-projection variants

The retained auto/AITER trace selected the exact
`M=1,N=2048,K=4096` FP8-E4M3/block-128 family: 5,120 calls and 64.886 ms in
one exact 210-input/128-output request. The real-checkpoint capture/export,
raw AMDGCN, reusable bridge, and fast loop live here:

```text
kernels/gfx950/fp8/dense/decode/experiments/
  qwen36_dense_m1_n2048_k4096_fp8_mfma_gfx950.s
  qwen36_dense_m1_n2048_k4096_fp8_mfma_4wave_lds_gfx950.s
harness/gfx950/fp8/dense/decode/
runtime/gfx950/fp8/dense/
tools/benchmark/iterate_gfx950_qwen36_dense_m1.sh
tools/benchmark/profile_gfx950_qwen36_dense_m1_counters.sh
```

The one-wave variant matched all 2,048 deployed BF16 values over 200 launches
and 20 native graph replays. Its five-run HIP-event median of medians was
10.00 microseconds versus 17.92 microseconds for the identical-operand AITER
harness. It was nevertheless rejected: matched full-graph 210+128 serving
regressed median wall/generation time by 4.51%/4.73%.

The four-wave variant stages each 128-byte activation block once in LDS for
four-wave reuse. It is also BF16-exact, deterministic, and graph-exact.
Five 200-launch runs measured 15.52–15.56 microsecond medians, with a complete
warm edit/build/validation loop of about 0.44 seconds. Its code object is
gfx950/wave64, declares 32 VGPRs, 32 SGPRs, 128 bytes LDS, no scratch/spills,
and has SHA-256
`99dc0247b7ebbcf2210a0b10ab028b848bfac1796d64e11e9d7b8797652e81d9`.

Intrusive rocprofv3 medians show the intended reuse but also its cost:

| Counter | One wave | Four-wave LDS |
|---|---:|---:|
| `SQ_WAVES` | 128 | 128 |
| `SQ_INSTS_MFMA` | 4,096 | 4,096 |
| `SQ_INSTS_VMEM` | 16,512 | 12,416 |
| `SQ_INSTS_LDS` | 0 | 12,288 |
| `TCC_READ_SECTORS_sum` | 283,072 | 267,968 |
| `TCC_MISS_sum` | 66,152 | 65,960 |
| `LDSBankConflict` | 0 | 0 |

The LDS design removes 24.8% of VMEM instructions but only 5.3% of TCC read
sectors because the 8 MiB weight dominates. In matched full-graph serving it
regressed wall/generation by 10.02%/10.63% and decode throughput by 9.61%.
The candidate and flag-off control both produced the same stable token hash in
40/40 uncached requests.

Both dense variants are retained as **rejected experiments**. The SGLang flag
defaults off. No isolated repeated-weight result can promote a later variant
without cold-weight full-graph evidence.

## Two-wave down/reduce promotion and deterministic prefill oracle

The one-wave down/reduce kernel launches only 128 waves on the 256-CU MI350X.
The promoted variant keeps 128 output tiles but uses two wave64s per
workgroup:

```text
kernels/gfx950/fp8/moe/decode/experiments/
  qwen36_moe_down_reduce_fp8_mfma_2wave_gfx950.s
```

Wave 0 computes routed slots 0–4. Wave 1 computes slots 5–8 into a 1,024-byte
LDS staging area; after one barrier, wave 0 consumes those contributions in
the original slot/K-block order. The two-wave output is therefore bit-exact
to the one-wave implementation while exposing 256 waves to the 256 CUs.

Two independent 200-iteration real-capture runs had zero nondeterministic
iterations and the same error as the one-wave kernel: cosine `0.999999`,
maximum FP32 error `2.45431e-5`, mean FP32 error `2.62836e-6`, and 30/2,048
BF16 differences from the independent accumulation-order oracle. HIP-event
medians were 10.28 and 10.32 µs versus 13.041 µs for one wave, a 1.266×
isolated speedup. The promoted code-object SHA-256 is
`c08f206d0d4395f111bf44d665a05ab90a58332ccb59314b8e3f1c21aac03f76`.

gfx950 counters confirmed 256 waves per dispatch, 128-thread workgroups,
1,024 bytes of LDS, no scratch, and zero LDS bank conflicts. Aggregate
`SQ_WAVES` and FP8 MFMA counts were exactly equal across all eight XCDs. The
countered object used 16 VGPRs, 48 SGPRs, and no AGPRs. Counter collection is
intrusive and is not used for wall-time claims.

The earlier long-request token gate was contaminated by nondeterministic
untuned AITER CK dense prefill GEMMs. A guarded correctness-only policy now
routes every untuned block-FP8 dense M=210 call to deterministic CKTile. It
does not change the checkpoint format: weights remain FP8 E4M3 with 128x128
scales. This policy is an oracle, not an accepted Netra compute kernel.

The reusable exact-operand harness lives in `netra-kernel`:

```text
harness/gfx950/fp8/dense/prefill/
  qwen36_qkvz_m210_aiter_variants.py
```

For both captured projections, activation bytes and scales had one hash in
20 iterations. AITER CK produced 20 distinct output hashes, whereas CKTile
and preshuffled Triton each produced one:

| Real checkpoint shape | Broken CK median | CKTile median | CKTile max error vs FP32-dequantized oracle |
|---|---:|---:|---:|
| GDN QKVZ, M210×N12288×K2048 | 64–76 µs | 85 µs | 0.0625 |
| attention QKV, M210×N9216×K2048 | 64.24 µs | 82.16 µs | 0.03125 |

With that oracle held identical for both variants:

| Full-graph exact 210+128 | One wave | Two waves | Two-wave result |
|---|---:|---:|---:|
| repetitions | 40 | 40 | all hashes identical |
| median wall latency | 0.853208 s | 0.810078 s | 1.05324× |
| median generation latency | 0.800514 s | 0.756619 s | 1.05801× |
| output hash | `6285266a...25c3` | `6285266a...25c3` | exact match |

The fast pre-promotion probe also passed 200/200 exact prompt-seeded
210-input/8-output requests in 20.5 seconds with one output hash. The
two-wave variant is now the default SGLang launch selection; the one-wave
object remains available as a retained control.

Artifacts:

```text
/data/netra/benchmarks/gfx950_qwen36_optimization/20260729T121623Z/
  kernel_experiments/qwen36_moe_down_reduce_2wave_gfx950_20260730T030300Z/
  profiles/rocprof/isolated_raw_down_2wave_20260730T030500Z/
  correctness/full_raw_1wave_fp8cktile_all_m210_20260730T041608Z/
  correctness/full_raw_2wave_fp8cktile_all_m210_20260730T041846Z/
```
