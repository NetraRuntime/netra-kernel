# Production composition profiles

A profile is a data-only composition of reusable operation contracts. It must
define:

```bash
NETRA_PROFILE_COMPONENT_REGISTRY=gfx950
NETRA_PROFILE_OUTPUT_NAMESPACE=gfx950-example-model
NETRA_PROFILE_COMPONENTS=(
  router-bf16-k2048-n256
  attention-verify-gqa8-d256-fp8kv-m16
)
```

To support another model:

1. Compare every required architecture, shape, dtype, layout, quantization,
   reduction, and ABI field with `components/README.md`.
2. Add one data-only profile and compose every matching existing contract.
3. For a genuinely new boundary, add one focused implementation builder and
   one self-registering file under `components/<architecture>/`. Do not edit a
   central switch or copy the runner or a complete model build script.
4. Run correctness, graph, and serving gates for the new model. Reusing a
   contract avoids code duplication; it does not transfer model accuracy
   evidence automatically.

List and build profiles with the model-neutral entrypoint:

```bash
tools/build/build_production.sh list-profiles
tools/build/build_production.sh gfx950-qwen36-dflash list
tools/build/build_production.sh gfx950-qwen36-dflash all
```
