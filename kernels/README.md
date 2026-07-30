# Kernel source layout

Architecture and quantization format are explicit directory boundaries:

- `kernels/gfx1151/mxfp4/` contains the retained wave32/RDNA MXFP4 work;
- `kernels/gfx950/fp8/` contains wave64/CDNA4 FP8 E4M3 work for MI350X.

Nothing below `gfx1151/mxfp4` is a valid gfx950 implementation or MI350X
measurement. All targeted compute files below either architecture hierarchy
are raw AMDGCN assembly.

- `decode/`: shipping M=1 decode kernels.
- `verify/`: speculative-verification kernels, including the M=12 path.
- `prefill/`: WMMA prefill kernels and their shared include.
- `lm_head/`: checkpoint-repacked MXFP4 LM-head kernels.
- `serving/`: runtime-shape kernels implementing the SGLang bridge ABI.
- `epilogue/`: standalone raw-assembly epilogues.

The `experiments/` directories contain measured negative-result variants.
They remain buildable so disassembly and performance records stay
reproducible, but the production build does not dispatch to them.

The gfx950 Qwen3.6 work begins under
`gfx950/fp8/moe/decode/experiments/`. A kernel moves out of `experiments/`
only after real-checkpoint correctness, graph replay, identical-shape kernel
timing, and uncached end-to-end serving gates pass.
