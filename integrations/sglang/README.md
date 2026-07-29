# SGLang integration

This directory is the complete serving overlay for SGLang commit
`1eee8fbdcc25b44e13bc097d5ff6ac24e8c24af4`.

- `sglang-gfx1151-integration.patch` is the base SGLang patch.
- `sglang-gfx1151-qkvz-ba-fusion.patch` applies after it and adds the measured
  Qwen3.6 GDN M=1 QKVZ+BA raw-ASM fusion, batched MXFP4 expert loading, and the
  native `tc_piecewise` model-loop boundary, plus the accepted raw-ASM GDN
  QKVZ/BA split-copy path.
- `sglang-gfx1151-extend-attention.patch` adds the accepted exact-shape raw
  gfx1151 standard-attention dispatch.
- `sglang-gfx1151-gdn-chunk-o.patch` adds the exact-shape raw gfx1151 GDN
  chunk-output dispatch after the base integration patches.
- `experiments/` retains integration patches for rejected design oracles.
- The raw GDN bridge is graph-safe and retains Triton for all other shapes.
- `netra_gfx1151_sglang.py` is copied into SGLang's quantization package.
- `netra_mxfp4_sgl_launcher.hip` is launch-only host code for the raw HSACOs.
- `launch.sh` starts the validated gfx1151 deployment.

The launcher enables the measured fast-load path by default: safetensors are
read without mmap by two bounded loader threads, then the Qwen integration
stages each 256-expert MXFP4 group into a small number of device copies. On the
16 GiB Netra system, do not raise `SGLANG_WEIGHT_LOADER_THREADS` without first
checking peak host memory. The cold-cache gfx1151 result is documented in
`docs/notes/gfx1151-loading-report-2026-07-29.md`.

Build the native artifacts first:

```bash
bash tools/build/build_netra_sglang_gfx1151.sh
```

Then follow the patch, copy, and launch commands in the repository
`README.md`.
