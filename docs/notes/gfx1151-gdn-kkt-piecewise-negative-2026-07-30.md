# Rejected gfx1151 GDN KKT FP32 piecewise split (2026-07-30)

## Decision

Reject the KKT-build / block-solve split. All values below are measured on gfx1151 with HIP events at the exact `B1,T8192,H32,Hg16,K128,BT64,BC16` model shape.

The split is mathematically viable: a Triton KKT builder that stores all ten lower 16x16 blocks as FP32, followed by the extracted block solve/merge, produces zero BF16 bit differences from the fused BK64/one-wave oracle. It is not performance viable: 9.545224 ms median versus 5.221479 ms fused, 1.827860x slower.

The experimental hand-written raw AMDGCN KKT builder measures 5.503513 ms alone versus 5.573285 ms for the compiler builder, a measured 1.012678x builder speedup on gfx1151. With the compiler solve/merge, the raw piecewise path measures 9.505779 ms, 1.820529x slower than fused, and produces 145 BF16 bit differences with maximum absolute error 0.00006103515625. It therefore fails both end-to-end kernel performance and strict correctness gates.

| gfx1151 measured path | Median HIP-event ms | Relative to fused | BF16 mismatches vs fused | Max abs |
|---|---:|---:|---:|---:|
| fused BK64/one-wave compiler oracle | 5.221479 | 1.000000x | 0 | 0 |
| compiler FP32 builder only | 5.573285 | n/a | n/a | n/a |
| raw ASM FP32 builder only | 5.503513 | n/a | n/a | n/a |
| compiler builder + compiler solve | 9.545224 | 0.547028x | 0 | 0 |
| raw ASM builder + compiler solve | 9.505779 | 0.549295x | 145 | 0.00006103515625 |

## Cause

The extra FP32 workspace is 64 MiB at T8192 and forces an HBM write/read round trip plus a second launch. That cost overwhelms the bounded-register benefit. Static raw code-object metadata is 212 VGPR, 32 SGPR, 8,192 B LDS, zero private segment, wave32, and a 32-thread workgroup.

The remaining raw correctness difference is in WMMA fragment accumulation order. Disabling gates and setting beta to one leaves the same tiny FP32 residual, ruling out address calculation and the gate epilogue. The split experiment proves that FP32 storage itself is exact when the builder accumulation matches production.

## Reproduction

```bash
source /root/sglvenv1151/bin/activate
cd /root/netra-mxfp4-gfx1151
bash tools/build/build_gdn_kkt_piecewise_experiment.sh
python tools/benchmark/benchmark_gdn_kkt_piecewise.py \
  > results/kernels/gfx1151/gdn-kkt-piecewise-experiment.json
```

The raw builder remains under `kernels/gfx1151/gdn/experiments/`; it is not linked into the production backend. Its HIP bridge is launch-only. The disassembly and code-object metadata are retained under `docs/notes/disassembly/gdn-kkt-piecewise-negative-gfx1151/`.

## Next design gate

Keep the fused one-wave workgroup. The next raw design must keep the ten KKT blocks and solve/merge within one dispatch, reproduce the compiler fragment order, and use explicit register/LDS placement instead of a global FP32 workspace. No performance or occupancy gain from that future design is estimated here.
