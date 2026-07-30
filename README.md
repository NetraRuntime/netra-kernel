# Netra target-specific AMDGCN kernels

Hand-written AMDGCN kernels organized by GPU architecture and checkpoint
format. The retained `gfx1151/mxfp4` implementation targets Ryzen AI Max+
wave32/RDNA. The new `gfx950/fp8` implementation targets AMD Instinct MI350X
CDNA4 wave64 and the native Qwen3.6 FP8 E4M3 128×128-block checkpoint.

HIP and Python code is limited to module loading, dispatch, graph/workspace
management, correctness checking, profiling, and serving integration. Targeted
compute replacements are raw `.s` files.

The gfx1151 work runs inside its `Netra` LXC. All gfx950 builds, validation,
profiles, and benchmarks run on the MI350X server.

## Repository layout

```text
scripts/rocm/
  kernels/        Canonical raw gfx1151 ASM for newly reorganized work
  harness/        HIP launch, graph, correctness, and timing bridges
  tools/          Reproducible build, benchmark, and profiling entry points
docs/netra/notes/ Current findings, disassemblies, and machine-readable evidence
kernels/
  gfx1151/mxfp4/
    decode/      M=1 decode kernels and retained experiments
    verify/      M=12 speculative-verification kernels
    prefill/     WMMA prefill kernels, shared include, and experiments
    lm_head/     MXFP4 LM-head kernels
    serving/     SGLang ABI kernels
    epilogue/    Raw assembly epilogues
  gfx1151/{attention,gdn,moe}/
    ...          Non-MXFP4 kernels and retained experiments
  gfx950/
    fp8/         MI350X Qwen FP8 projection and MoE kernels
    linear_attention/
    norm/
    routing/
    sampling/    Model-native BF16/FP32 Qwen kernels
harness/
  gfx1151/{mxfp4,attention,gdn,moe}/
  gfx950/
  ...            HIP launch, timing, and correctness harnesses
runtime/
  gfx1151/        gfx1151 runtime support
  gfx950/         HIP module/dispatch bridges with allocation-free launches
scripts/rocm/integrations/sglang/
  ...            SGLang bridge, launch script, and consolidated patch
tools/
  build/         Reproducible architecture-specific builds
  benchmark/     Kernel and serving benchmarks
  checkpoint/    One-time real-checkpoint extraction and repacking
  profiling/     rocprofv3 request and trace analysis tools
  triton/        MXFP4 reference-baseline preparation
tests/gfx1151/   Retained gfx1151 real-checkpoint correctness gates
docs/notes/      Measurements, negative results, and machine-readable data
results/         Selected compact kernel, profiler, and serving evidence
```

Reorganized gfx1151 mission work is canonical under `scripts/rocm/` and
`docs/netra/notes/`. The top-level architecture trees remain the canonical
home of the current gfx950 work and of retained gfx1151 artifacts while the
older layout is migrated incrementally. Sources must not be duplicated across
the two layouts.

Files under an `experiments/` directory are retained measured negative results;
they are built for reproducibility but are not selected as shipping kernels.

## Retained gfx1151 build

Run inside Netra:

```bash
cd /root/netra-mxfp4-gfx1151
bash tools/build/build_gfx1151_mxfp4_raw.sh
bash scripts/rocm/tools/build/build_netra_sglang_gfx1151.sh
```

The raw build writes to `build/raw` by default. The serving build writes to
`build/sglang` and produces the raw-ASM HSACOs plus the HIP launch-only shared
library.

## SGLang integration

The validated integration base is SGLang commit
`1eee8fbdcc25b44e13bc097d5ff6ac24e8c24af4`.

```bash
cd /root/work/sglang-main
git apply \
  /root/netra-mxfp4-gfx1151/scripts/rocm/integrations/sglang/sglang-gfx1151-integration.patch
git apply \
  /root/netra-mxfp4-gfx1151/scripts/rocm/integrations/sglang/sglang-gfx1151-qkvz-ba-fusion.patch
git apply \
  /root/netra-mxfp4-gfx1151/scripts/rocm/integrations/sglang/sglang-gfx1151-extend-attention.patch
git apply \
  /root/netra-mxfp4-gfx1151/scripts/rocm/integrations/sglang/sglang-gfx1151-gdn-chunk-o.patch
git apply \
  /root/netra-mxfp4-gfx1151/scripts/rocm/integrations/sglang/sglang-gfx1151-gdn-recompute-w-u.patch
git apply \
  /root/netra-mxfp4-gfx1151/scripts/rocm/integrations/sglang/sglang-gfx1151-causal-conv1d.patch
git apply \
  /root/netra-mxfp4-gfx1151/scripts/rocm/integrations/sglang/sglang-gfx1151-qk-mrope-kv-fusion.patch
git apply \
  /root/netra-mxfp4-gfx1151/scripts/rocm/integrations/sglang/sglang-gfx1151-mamba-track-host-flag.patch
git apply \
  /root/netra-mxfp4-gfx1151/scripts/rocm/integrations/sglang/sglang-gfx1151-gdn-syncfree-chunk-metadata.patch
git apply \
  /root/netra-mxfp4-gfx1151/scripts/rocm/integrations/sglang/sglang-gfx1151-bf16-lm-head.patch
cp /root/netra-mxfp4-gfx1151/scripts/rocm/integrations/sglang/netra_gfx1151_sglang.py \
  python/sglang/srt/layers/quantization/netra_gfx1151.py

cd /root/netra-mxfp4-gfx1151
bash scripts/rocm/integrations/sglang/launch.sh
```

The launch script defaults to the real transformed checkpoint at
`/root/models/qwen36-sgl-mxfp4`. Environment variables in the script allow
overriding the SGLang tree, virtual environment, model, host, port, memory
fraction, context length, and visible device.

## Correctness

Run the real-checkpoint SGL ABI gates inside Netra:

```bash
cd /root/netra-mxfp4-gfx1151
NETRA_TEST_M=65 NETRA_TEST_N=64 \
  /root/sglvenv1151/bin/python tests/gfx1151/test_netra_mxfp4_sgl_linear.py
/root/sglvenv1151/bin/python \
  tests/gfx1151/test_netra_mxfp4_sgl_decode.py
```

Both tests compare gfx1151 outputs with staged fp64 dequantized-MXFP4
references using real checkpoint weights.

## Results and implementation notes

- [Kernel development and negative results](docs/notes/gfx1151-mxfp4-kernels.md)
- [Machine-readable kernel results](docs/notes/gfx1151-mxfp4-results.json)
- [SGLang integration and serving results](docs/notes/gfx1151-mxfp4-sglang-integration-2026-07-29.md)
- [Machine-readable SGLang results](docs/notes/gfx1151-mxfp4-sglang-results.json)
- [Raw ASM versus Triton MXFP4 comparison](docs/notes/gfx1151-mxfp4-triton-comparison.md)
- [Fast real-checkpoint shard loading](docs/notes/gfx1151-loading-report-2026-07-29.md)
- [Accepted extend-attention K LDS swizzle](docs/notes/gfx1151-extend-attention-k-lds-swizzle-2026-07-29.md)

Every reported performance number in those records is labeled measured or
estimated and is specific to gfx1151.

## MI350X / gfx950 Qwen FP8 work

Builds, profiles, and benchmarks run only on the MI350X server:

```bash
bash tools/build/build_gfx950_qwen36_fp8_raw.sh
(
  cd build/gfx950-qwen36-fp8
  ./qwen36_moe_silu_mul_quant_fp8_gfx950_harness \
    5000 ./qwen36_moe_silu_mul_quant_fp8_gfx950.hsaco
)
```

The first implementation is intentionally retained as an experiment until
real-checkpoint layer/state, graph replay, and end-to-end gates pass. See
[gfx950 Qwen FP8 kernel development](docs/notes/gfx950-qwen36-fp8-kernels.md)
and its
[machine-readable isolated results](docs/notes/gfx950-qwen36-fp8-results.json).

After one controlled live-request tensor capture exists, use the fast
assembly/correctness loop without reloading Qwen:

```bash
tools/benchmark/iterate_gfx950_qwen36_moe_silu_mul_quant.sh
```

It incrementally rebuilds only stale components and reuses a lightweight,
persistent gfx950 validator container. Full SGLang launches are reserved for
layer, graph, and end-to-end integration gates.
