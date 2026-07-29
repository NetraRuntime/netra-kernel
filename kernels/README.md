# Kernel source layout

All shipping compute files below `kernels/gfx1151/` are hand-written AMDGCN
assembly targeting `gfx1151`.

- `attention/`: standard extend-attention kernels.
- `gdn/`: gated-delta-network and QKVZ/BA data-path kernels.
- `moe/`: routed-expert packing and reduction kernels.
- `mxfp4/`: MXFP4 projection and epilogue kernels.

Within `mxfp4/`, `decode/`, `verify/`, `prefill/`, `lm_head/`, `serving/`,
and `epilogue/` separate the model phases and runtime ABI.

Every `experiments/` directory contains measured negative-result variants.
They remain buildable so disassembly and performance records stay
reproducible, but production builds do not dispatch to them.
