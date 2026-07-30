# Kernel source layout

Architecture and quantization format are explicit directory boundaries:

- `kernels/gfx1151/mxfp4/` contains the retained wave32/RDNA MXFP4 work;
- `kernels/gfx1151/{attention,gdn,moe}/` contains the other retained gfx1151
  families;
- `kernels/gfx950/` contains wave64/CDNA4 Qwen work for MI350X, including FP8
  E4M3 projections and model-native BF16/FP32 operations.

Nothing below `gfx1151/` is a valid gfx950 implementation or MI350X
measurement. All targeted compute files below either architecture hierarchy
are raw AMDGCN assembly.

- `decode/`: shipping M=1 decode kernels.
- `verify/`: speculative-verification kernels, including the M=12 path.
- `prefill/`: WMMA prefill kernels and their shared include.
- `lm_head/`: checkpoint-repacked MXFP4 LM-head kernels.
- `serving/`: runtime-shape kernels implementing the SGLang bridge ABI.
- `epilogue/`: standalone raw-assembly epilogues.
- `routing/`: routing projections and bookkeeping fusions. The accepted
  Qwen3.6 M=1 shared-gate/route-append kernel is under
  `gfx950/routing/decode/`.
- `sampling/`: logits reductions and sampling-path kernels.
- `linear_attention/`: GDN projection and recurrent-state kernels.
- `norm/`: normalization and fused residual experiments.

Within `mxfp4/`, `decode/`, `verify/`, `prefill/`, `lm_head/`, `serving/`,
and `epilogue/` separate the model phases and runtime ABI.

Every `experiments/` directory contains measured negative-result variants.
They remain buildable so disassembly and performance records stay
reproducible, but the production build does not dispatch to them.

The gfx950 Qwen3.6 work begins under
`gfx950/fp8/moe/decode/experiments/`. A kernel moves out of `experiments/`
only after real-checkpoint correctness, graph replay, identical-shape kernel
timing, and uncached end-to-end serving gates pass.
