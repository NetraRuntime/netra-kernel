# Netra MXFP4 kernels for gfx1151

Hand-written AMDGCN kernels for Qwen3.6-35B-A3B on the AMD Ryzen AI Max+
PRO 395 (`gfx1151`). The repository is MXFP4-only. HIP and Python code is
limited to launching, correctness checking, checkpoint conversion, profiling,
and serving integration.

All build, validation, profiling, and benchmark commands must run inside the
`Netra` LXC.

## Repository layout

```text
scripts/rocm/
  kernels/        Canonical raw gfx1151 ASM for newly reorganized work
  harness/        HIP launch, graph, correctness, and timing bridges
  tools/          Reproducible build, benchmark, and profiling entry points
docs/netra/notes/ Current findings, disassemblies, and machine-readable evidence
kernels/gfx1151/mxfp4/
  decode/        M=1 decode kernels and retained experiments
  verify/        M=12 speculative-verification kernels
  prefill/       WMMA prefill kernels, shared include, and experiments
  lm_head/       MXFP4 LM-head kernels
  serving/       SGLang ABI kernels
  epilogue/      Raw assembly epilogues
kernels/gfx1151/attention/
  ...            Standard-attention kernels and rejected experiments
kernels/gfx1151/gdn/
  ...            Gated-delta-network kernels and rejected experiments
kernels/gfx1151/moe/
  ...            MoE routing/packing kernels and rejected experiments
harness/gfx1151/mxfp4/
  ...            HIP launch, timing, and correctness harnesses
harness/gfx1151/{attention,gdn,moe}/
  ...            Non-MXFP4 launch, timing, and correctness harnesses
scripts/rocm/integrations/sglang/
  ...            SGLang bridge, launch script, and consolidated patch
tools/
  build/         Reproducible gfx1151 builds
  benchmark/     Kernel and serving benchmarks
  checkpoint/    One-time real-checkpoint extraction and repacking
  profiling/     rocprofv3 request and trace analysis tools
  triton/        MXFP4 reference-baseline preparation
tests/gfx1151/   Real-checkpoint integration correctness gates
docs/notes/      Measurements, negative results, and machine-readable data
results/         Selected compact kernel, profiler, and serving evidence
```

New mission work is canonical under `scripts/rocm/` and `docs/netra/notes/`.
The older top-level kernel/tool and `docs/notes/` paths remain in place for
reproducibility while they are migrated incrementally; new sources must not be
duplicated into those legacy trees.

Files under an `experiments/` directory are retained measured negative results;
they are built for reproducibility but are not selected as shipping kernels.

## Build

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
