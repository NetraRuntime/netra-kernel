# Rejected gfx1151 GDN KKT FP32 piecewise split (2026-07-30)

## Decision

Reject the KKT-build / block-solve split. All values below are measured on gfx1151 with HIP events at the exact `B1,T8192,H32,Hg16,K128,BT64,BC16` model shape.

The split is mathematically viable: a compiler KKT builder that stores all ten lower 16x16 blocks as FP32, followed by the extracted block solve/merge, produces zero BF16 bit differences from the fused BK64/one-wave oracle. It is not performance viable: 9.509684 ms median versus 5.227223 ms fused, 1.819261x slower.

The first hand-written LDS-staged raw builder was slightly faster in isolation but changed WMMA accumulation order. Its complete piecewise path measures 9.534371 ms and produces 145 BF16 differences with maximum absolute error 0.00006103515625, so it is rejected.

A second hand-written raw AMDGCN builder reproduces Triton's direct-load cross-lane WMMA fragment packing. It is exact: zero FP32 and BF16 mismatches. The builder measures 5.308085 ms versus 5.533179 ms for the compiler builder, a measured 1.042406x speedup on gfx1151. The exact raw builder plus compiler solve still measures 9.582621 ms, 1.833214x slower than fused. Thus the builder is a valid component for the future fused kernel, while the global-workspace split remains rejected.

| gfx1151 measured path | Median HIP-event ms | Relative to fused | BF16 mismatches vs fused | Max abs |
|---|---:|---:|---:|---:|
| fused BK64/one-wave compiler oracle | 5.227223 | 1.000000x | 0 | 0 |
| compiler FP32 builder only | 5.533179 | n/a | n/a | n/a |
| raw LDS builder only | 5.497642 | n/a | n/a | n/a |
| exact raw direct-fragment builder only | 5.308085 | n/a | n/a | n/a |
| compiler builder + compiler solve | 9.509684 | 0.549674x | 0 | 0 |
| raw LDS builder + compiler solve | 9.534371 | 0.548250x | 145 | 0.00006103515625 |
| exact raw builder + compiler solve | 9.582621 | 0.545490x | 0 | 0 |

## Cause

The extra FP32 workspace is 64 MiB at T8192 and forces an HBM write/read round trip plus a second launch. That cost overwhelms the bounded-register benefit. Both raw builders use 212 VGPR, 32 SGPR, zero private segment, wave32, and a 32-thread workgroup; the rejected LDS builder reserves 8,192 B LDS while the exact direct-fragment builder reserves zero LDS.

The original correctness difference was WMMA fragment packing, not address calculation or the gate epilogue. Reproducing the compiler's `ds_bpermute_b32` fragment construction removes every FP32 difference. A 91-VGPR remap remained exact but regressed the builder to 6.521017 ms measured on gfx1151, so that register placement is also rejected.

## Reproduction

```bash
source /root/sglvenv1151/bin/activate
cd /root/netra-mxfp4-gfx1151
bash scripts/rocm/tools/build/build_gdn_kkt_piecewise_experiment.sh
python tools/benchmark/benchmark_gdn_kkt_piecewise.py \
  > results/kernels/gfx1151/gdn-kkt-piecewise-experiment-v2.json
```

Both raw builders remain under `kernels/gfx1151/gdn/experiments/`; it is not linked into the production backend. Its HIP bridge is launch-only. The disassembly and code-object metadata are retained under `docs/notes/disassembly/gdn-kkt-piecewise-negative-gfx1151/`.

## Next design gate

Keep the fused one-wave workgroup. The next raw design must keep the ten KKT blocks and solve/merge within one dispatch, reproduce the compiler fragment order, and use explicit register/LDS placement instead of a global FP32 workspace. No performance or occupancy gain from that future design is estimated here.
