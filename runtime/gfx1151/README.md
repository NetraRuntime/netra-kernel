# gfx1151 runtime boundary

`runtime/gfx1151/` owns the host-side launch contract for Netra's raw gfx1151
AMDGCN kernels. Raw compute remains under `kernels/gfx1151/`; SGLang-specific
Python and patching remain under `scripts/rocm/integrations/sglang/`.

## Design

The runtime is deliberately a single shared library and a single compatibility
translation unit. `compatibility.h` declares the existing public C ABI, while
`netra_mxfp4_sgl_launcher.hip` forwards each public symbol to a focused subsystem
header:

- `common/`: immutable kernel descriptors, the module registry, kernarg layouts,
  error handling, gfx1151 validation, and thin launch helpers;
- `mxfp4/decode/`: M=1 dense and MoE launches;
- `mxfp4/verify/`: the accepted M=12 grouped expert launches;
- `mxfp4/prefill/`: weight repacking and M64-or-larger dense/MoE launches;
- `mxfp4/attention/`: extend attention and fused Q/K normalization, mRoPE, and
  KV-cache storage;
- `mxfp4/gdn/`: projection splitting, chunk output, W/U recomputation, and
  causal-convolution state update;
- `mxfp4/moe/`: expert activation packing and deterministic expert reduction.

Each raw kernel has a static descriptor containing its HSACO filename, symbol,
and immutable launch metadata. Initialization loads functions into named
`hipFunction_t` fields in the same order and with the same failure semantics as
the original launcher. Device and HIP-context ownership are recorded once after
preload. The current implementation still preloads the established set because
changing preload policy is outside this performance-neutral extraction.

## Hot-path and graph invariants

SGLang calls `netra_mxfp4_sgl_init` before graph capture. After that point, every
subsystem resolves a named cached function field and constructs the same packed
kernarg on the stack. Launches pass the caller's `hipStream_t` unchanged to
`hipModuleLaunchKernel`.

The dispatch path performs no map lookup, filesystem access, environment
parsing, symbol lookup, device query, allocation, logging, or registration
mutation. It preserves the original `std::call_once` fast check because every
old public launcher performed that check. Capture and replay therefore use
already-loaded modules and stable SGLang-owned device pointers.

Kernarg sizes and alignments are guarded by `static_assert` in
`common/kernargs.h`. Grid, workgroup, shared-memory, argument order, return-code
mapping, and launch-parameter-buffer mechanics remain local and explicit so a
future generic abstraction cannot silently add a branch or indirect lookup.

## Build and focused A/B validation

Run only inside the Netra LXC:

```bash
scripts/rocm/tools/build/build_netra_sglang_gfx1151.sh
scripts/rocm/tools/build/build_runtime_dispatch_ab_gfx1151.sh
build/runtime-refactor/benchmark_runtime_dispatch_ab \
  results/runtime/gfx1151/runtime-refactor-c421a85-old/libnetra_mxfp4_sgl.old.so \
  build/sglang/libnetra_mxfp4_sgl.so 50000
```

The dispatch harness uses a non-default stream, compares output bits, measures
host launch p50/p90, uses HIP events for GPU duration, captures one raw launch,
checks graph node count, and measures graph replay p50/p90. Fresh-process preload
and real-checkpoint serving A/B tools are in
`scripts/rocm/tools/benchmark/`. `compare_runtime_traces.py` compares rocprofv3
kernel signatures and graph replay intervals.

The accepted measured results and exact reproduction commands are recorded in
`docs/netra/notes/gfx1151-runtime-refactor-2026-07-30.md`.
