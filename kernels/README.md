# Kernel source layout

All files below `kernels/gfx1151/mxfp4/` are hand-written AMDGCN assembly
targeting `gfx1151`.

- `decode/`: shipping M=1 decode kernels.
- `verify/`: speculative-verification kernels, including the M=12 path.
- `prefill/`: WMMA prefill kernels and their shared include.
- `lm_head/`: checkpoint-repacked MXFP4 LM-head kernels.
- `serving/`: runtime-shape kernels implementing the SGLang bridge ABI.
- `epilogue/`: standalone raw-assembly epilogues.

The `experiments/` directories contain measured negative-result variants.
They remain buildable so disassembly and performance records stay
reproducible, but the production build does not dispatch to them.
