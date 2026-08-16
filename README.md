# Netra Kernel

Netra Kernel is a collection of hand-written AMDGCN kernels for accelerating
specific inference paths on AMD GPUs. The compute implementations are raw
assembly code objects; HIP and Python are used only for module management,
dispatch, graph/workspace integration, correctness validation, benchmarking,
and serving integration.

This is a target-specific kernel laboratory, not a portable tensor library.
Every kernel has an explicit contract covering GPU architecture, wave size,
tensor shape, dtype, memory layout, quantization format, and reduction order.
Unsupported contracts remain on the caller's existing implementation.

## Supported targets

| Target | Hardware | Wave size | Checkpoint format | Current focus |
|---|---|---:|---|---|
| `gfx1151` | Ryzen AI Max+ / RDNA | 32 | MXFP4 plus model-native BF16/FP32 | Decode, prefill, attention, GDN, MoE, normalization, and SGLang serving |
| `gfx950` | AMD Instinct MI350X / CDNA4 | 64 | Qwen3.6 FP8 E4M3 with 128x128 block scales | FP8 projections and MoE, verification, routing, sampling, attention, GDN, and normalization |

Kernels and measurements are not portable across the two targets. Nothing
under `gfx1151/` is a valid `gfx950` implementation or MI350X result, and vice
versa.

## Design

The serving path is deliberately thin:

```text
SGLang / PyTorch
      |
      v
Python shape, dtype, and layout guard
      |
      v
C ABI and HIP module bridge
      |
      v
Preloaded target-specific HSACO
      |
      v
Raw AMDGCN kernel
```

Before graph capture, the runtime loads code objects and resolves their kernel
symbols. Repeated launches use cached `hipFunction_t` handles, packed kernargs,
and the caller's HIP stream. The dispatch path is designed to avoid allocation,
synchronization, filesystem access, environment parsing, symbol lookup, and
mutable registration state.

The project follows these rules:

- Raw `.s` files contain targeted compute.
- Runtime bridges manage modules and dispatch; they do not hide alternate HIP
  compute implementations.
- Exact-shape guards select Netra kernels. Other shapes fall back to the
  existing framework path.
- Correctness is evaluated on real checkpoint tensors whenever possible.
- Kernel timing alone is not sufficient for promotion; graph and serving gates
  also matter.
- Measured negative results are retained under `experiments/` so rejected ideas
  remain reproducible.
- Performance reports identify whether a number came from HIP events,
  `rocprofv3`, or host end-to-end measurement.

The consolidated gfx1151 runtime contract is described in
[`runtime/gfx1151/README.md`](runtime/gfx1151/README.md). Kernel directory
conventions are described in [`kernels/README.md`](kernels/README.md).

## Repository layout

```text
kernels/
  gfx1151/
    mxfp4/
      decode/       M=1 decode kernels
      verify/       Speculative-verification kernels, including M=12
      prefill/      WMMA prefill kernels and shared includes
      lm_head/      MXFP4 LM-head kernels
      serving/      Runtime-shape kernels for the SGLang ABI
      epilogue/     Standalone raw-assembly epilogues
    attention/      Standard-attention and Q/K/mRoPE/KV-cache kernels
    dense/          Model-native BF16 projections
    gdn/            Gated-delta-network kernels
    moe/            Routing, activation packing, and expert reduction
    norm/           Normalization kernels
  gfx950/
    fp8/            FP8 dense and MoE kernels
    attention/      Target-verification attention kernels
    linear_attention/
                    GDN verification and recurrent-state kernels
    norm/           Normalization and quantization fusions
    routing/        Decode and verification routing kernels
    sampling/       Verification argmax and sampling-path kernels

runtime/
  gfx1151/          Consolidated C ABI, module registry, kernargs, and launches
  gfx950/           Focused load/launch/unload bridges by kernel family

harness/
  gfx1151/          HIP correctness, timing, and counter drivers
  gfx950/           Real-capture and synthetic kernel validators

scripts/rocm/
  integrations/    SGLang overlay and launcher
  kernels/         Canonical raw gfx1151 sources for reorganized mission work
  harness/         Focused HIP/Python validation tools
  tools/           Build, benchmark, correctness, and profiling entry points

tools/
  build/            Reproducible target-specific builds and production bundles
  benchmark/        Kernel, graph, and serving benchmarks
  checkpoint/       One-time checkpoint extraction and repacking
  profiling/        rocprofv3 request, trace, and counter analysis
  triton/           Reference-baseline preparation

tests/gfx1151/      Retained real-checkpoint SGL ABI checks
docs/notes/         gfx950 and retained kernel-development records
docs/netra/notes/   Current gfx1151 findings and machine-readable evidence
results/            Selected kernel, profiler, runtime, and serving evidence
```

The gfx1151 reorganization is incremental. New mission work under
`scripts/rocm/` and `docs/netra/notes/` is canonical; the top-level architecture
trees remain canonical for current gfx950 work and retained gfx1151 artifacts.
Sources must not be duplicated across the two layouts.

## Kernel lifecycle

Repository location communicates maturity:

1. A new idea starts as an isolated kernel and harness.
2. Correctness is checked against a framework, high-precision, or captured
   real-checkpoint reference.
3. Determinism and native HIP graph capture/replay are checked.
4. The exact framework boundary is shadowed or compared in the same process.
5. Matched serving A/B and token or output gates determine promotion.
6. Accepted kernels move out of `experiments/`; rejected variants remain there
   with their measurements.

Some accepted kernels are intentionally limited to eager or full-graph mode
when an independent piecewise-graph control path is not yet correct. Consult the
corresponding note before changing a dispatch predicate.

## Prerequisites

The project does not provide a CPU fallback or cross-compilation-only
validation environment.

For gfx1151 work, use the Netra LXC with:

- a visible `gfx1151` device;
- ROCm 7.2.1 at `/opt/rocm-7.2.1`;
- the validated SGLang checkout and Python environment;
- the transformed Qwen3.6 MXFP4 checkpoint for real-checkpoint gates.

For gfx950 work, use the MI350X server with:

- a visible `gfx950` device;
- ROCm tools, including Clang, `hipcc`, `llvm-objdump`, and `llvm-readobj`;
- the Qwen3.6 FP8 checkpoint and retained tensor captures required by the
  selected validator.

Most scripts accept output-directory or ROCm-path overrides. Older gfx1151
scripts intentionally retain the validated LXC paths.

The gfx950 build conventions and canonical MI350X production bundle are
documented in [`tools/build/README.md`](tools/build/README.md).

## Build gfx1151

Run inside the Netra LXC:

```bash
cd /root/netra-mxfp4-gfx1151

# Standalone raw code objects and harnesses.
bash tools/build/build_gfx1151_mxfp4_raw.sh

# Complete SGLang backend and consolidated runtime library.
bash scripts/rocm/tools/build/build_netra_sglang_gfx1151.sh
```

The raw build writes to `build/raw` by default. The serving build writes to
`build/sglang` and produces target HSACOs, disassemblies, validation binaries,
and `libnetra_mxfp4_sgl.so`.

## Validate gfx1151

The retained real-checkpoint ABI checks compare raw output with staged FP64
dequantized-MXFP4 references:

```bash
cd /root/netra-mxfp4-gfx1151

NETRA_TEST_M=65 NETRA_TEST_N=64 \
  /root/sglvenv1151/bin/python \
  tests/gfx1151/test_netra_mxfp4_sgl_linear.py

/root/sglvenv1151/bin/python \
  tests/gfx1151/test_netra_mxfp4_sgl_decode.py
```

Focused correctness, graph, profiler, and A/B entry points live under
`scripts/rocm/tools/` and `tools/`. Read the note for a kernel family before
running a profiler command; counter collection is intrusive and is not used as
latency evidence.

## SGLang integration

The validated gfx1151 integration base is SGLang commit
`1eee8fbdcc25b44e13bc097d5ff6ac24e8c24af4`.

The overlay consists of a base integration patch followed by focused patches
for accepted attention, GDN, dense, routing, MoE, and normalization paths. The
required order and purpose of each patch are documented in
[`scripts/rocm/integrations/sglang/README.md`](scripts/rocm/integrations/sglang/README.md).

Apply the validated overlay in this order:

```bash
cd /root/work/sglang-main

netra_integration=/root/netra-mxfp4-gfx1151/scripts/rocm/integrations/sglang
patches=(
  sglang-gfx1151-integration.patch
  sglang-gfx1151-qkvz-ba-fusion.patch
  sglang-gfx1151-extend-attention.patch
  sglang-gfx1151-gdn-chunk-o.patch
  sglang-gfx1151-gdn-recompute-w-u.patch
  sglang-gfx1151-causal-conv1d.patch
  sglang-gfx1151-qk-mrope-kv-fusion.patch
  sglang-gfx1151-mamba-track-host-flag.patch
  sglang-gfx1151-gdn-syncfree-chunk-metadata.patch
  sglang-gfx1151-bf16-lm-head.patch
  sglang-gfx1151-bf16-qkv.patch
  sglang-gfx1151-bf16-shared-gate-up-silu.patch
  sglang-gfx1151-bf16-attention-output.patch
  sglang-gfx1151-bf16-router.patch
  sglang-gfx1151-qwen36-rmsnorm.patch
)

for patch in "${patches[@]}"; do
  git apply "${netra_integration}/${patch}"
done

cp "${netra_integration}/netra_gfx1151_sglang.py" \
  python/sglang/srt/layers/quantization/netra_gfx1151.py
```

Then start the validated deployment:

```bash
cd /root/netra-mxfp4-gfx1151
bash scripts/rocm/integrations/sglang/launch.sh
```

The launcher defaults to:

- SGLang: `/root/work/sglang-main`
- virtual environment: `/root/sglvenv1151`
- model: `/root/models/qwen36-sgl-mxfp4`

`SGLANG_DIR`, `SGLANG_VENV`, `MODEL_DIR`, and the other variables in
`launch.sh` can override those paths and serving parameters. Each optional
Netra replacement also has an explicit environment switch that restores the
existing SGLang path.

The integration enables the measured bounded two-thread checkpoint loader by
default. Do not increase `SGLANG_WEIGHT_LOADER_THREADS` on the 16 GiB Netra
system without checking peak host memory. The persistent prefill layout also
has a substantial unified-VRAM cost; see the linked loading and prefill notes
before changing it.

## Build and validate gfx950

All gfx950 builds and measurements must run on a visible MI350X:

```bash
cd /path/to/netra-kernel
bash tools/build/build_gfx950_qwen36_fp8_raw.sh

cd build/gfx950-qwen36-fp8
./qwen36_moe_silu_mul_quant_fp8_gfx950_harness \
  5000 ./qwen36_moe_silu_mul_quant_fp8_gfx950.hsaco
```

The build refuses to create a target-specific object if `gfx950` is not
visible. It also emits disassembly and metadata, checks the architecture and
wave64 declarations, and records SHA-256 hashes.

Each promoted or experimental gfx950 family has a focused build script under
`tools/build/` and, where needed, an edit-to-result loop under
`tools/benchmark/`. For example:

```bash
tools/benchmark/iterate_gfx950_qwen36_moe_silu_mul_quant.sh
tools/build/build_gfx950_qwen36_gdn_fused_h_o_t1024_bv128.sh
```

These loops reuse controlled real-request captures to avoid restarting the
full model for every assembly edit. Full SGLang launches remain necessary for
layer, graph, token, and end-to-end acceptance gates.

## Results and status

Start with these records:

### gfx1151

- [Current decode optimization status](docs/netra/notes/gfx1151-decode-optimization-2026-07-31.md)
- [Kernel development and negative results](docs/notes/gfx1151-mxfp4-kernels.md)
- [Machine-readable kernel results](docs/notes/gfx1151-mxfp4-results.json)
- [SGLang integration and serving results](docs/notes/gfx1151-mxfp4-sglang-integration-2026-07-29.md)
- [Machine-readable SGLang results](docs/notes/gfx1151-mxfp4-sglang-results.json)
- [Raw ASM versus Triton MXFP4](docs/notes/gfx1151-mxfp4-triton-comparison.md)
- [Checkpoint loading report](docs/notes/gfx1151-loading-report-2026-07-29.md)
- [Accepted extend-attention K LDS swizzle](docs/notes/gfx1151-extend-attention-k-lds-swizzle-2026-07-29.md)

### gfx950

- [Qwen3.6 FP8 kernel development](docs/notes/gfx950-qwen36-fp8-kernels.md)
- [Machine-readable FP8 results](docs/notes/gfx950-qwen36-fp8-results.json)
- [Accepted M=16 GDN verification pipeline](docs/notes/gfx950-qwen36-gdn-verify-m16-accepted.md)
- [Accepted packed T1024 BV128 GDN prefill fusion](docs/notes/gfx950-qwen36-flashqla-bv128-prefill-accepted.md)
- [Accepted FP32 verification argmax](docs/notes/gfx950-qwen36-argmax-f32-accepted.md)

Every reported performance number is architecture- and workload-specific.
Microkernel speedups do not imply serving speedups, and profiler counter runs
are not used as wall-time measurements.

## Development expectations

When adding or changing a kernel:

- Keep the architecture, wave size, shape, dtype, and layout contract explicit.
- Keep targeted compute in raw assembly.
- Preserve the caller's stream and graph-capture behavior.
- Add or update a focused build and correctness entry point.
- Inspect code-object metadata and disassembly after every material change.
- Compare against an independent reference, not only a previous candidate.
- Run repeated determinism checks.
- Record both positive and negative measurements.
- Do not promote an isolated speedup without matched integration and serving
  evidence.

## License

Netra Kernel is released under the [MIT License](LICENSE).
