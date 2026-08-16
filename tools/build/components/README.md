# Reusable operation contracts

Architecture directories expose model-neutral operation contracts. Each
contract lives in its own file and registers one build adapter, so adding an
implementation does not modify a central switch or another model's profile.
A contract is reusable only when architecture, tensor shapes, dtypes, layouts,
quantization, reduction order, and runtime ABI all match. The model that first
contributed a kernel is not part of the contract identity.

The current `gfx950` contracts are:

| Contract | Required implementation boundary |
|---|---|
| `moe-decode-fp8-e4m3-h2048-i512-top9-block128-aiter` | FP8 E4M3 MoE decode, hidden=2048, intermediate=512, top-k=9, 128-element scales, AITER weight layout |
| `router-bf16-k2048-n256` | BF16 row-wise router projection, K=2048 and N=256 |
| `attention-verify-gqa8-d256-fp8kv-m16` | verification M<=16, GQA8, D=256, native E4M3 paged prefix KV |
| `gdn-verify-b64-t12-h16-hv32-k128-v128-k0` | B<=64, T=12, H=16, HV=32, K=V=128, lossless K0 replay contract |
| `gdn-replay-b64-t12-h16-hv32-k128-v128` | accepted-tail state replay for the matching GDN contract |

List contracts through the generic runner:

```bash
tools/build/build_production.sh gfx950-qwen36-dflash contracts
```

An implementation may retain an older model-specific symbol internally while
the registry acts as its adapter. That symbol is not a promise of portability;
the operation contract above is.

To extend an architecture, add exactly one
`components/<architecture>/<contract>.sh`. Define its builder function, call
`netra_register_component`, and add the contract to whichever profiles need
it. No runner or registry switch needs editing.
