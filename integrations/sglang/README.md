# SGLang integration

This directory is the complete serving overlay for SGLang commit
`1eee8fbdcc25b44e13bc097d5ff6ac24e8c24af4`.

- `sglang-gfx1151-integration.patch` is the single authoritative SGLang patch.
- `netra_gfx1151_sglang.py` is copied into SGLang's quantization package.
- `netra_mxfp4_sgl_launcher.hip` is launch-only host code for the raw HSACOs.
- `launch.sh` starts the validated gfx1151 deployment.

Build the native artifacts first:

```bash
bash tools/build/build_netra_sglang_gfx1151.sh
```

Then follow the patch, copy, and launch commands in the repository
`README.md`.
