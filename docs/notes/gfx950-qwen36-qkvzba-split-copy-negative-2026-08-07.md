# Qwen3.6 gfx950 QKVZ/BA split-copy serving negative

## Verdict

Rejected for production promotion. The raw gfx950 copy is bit-exact and faster
than the deployed Triton kernel in isolation, but the matched single-GPU GSM8K
serving gate regressed output throughput by 1.47%. The SGLang opt-in path must
remain disabled.

## Measured target

- GPU: AMD Instinct MI350X
- ISA target: `amdgcn-amd-amdhsa--gfx950`
- wavefront: 64
- checkpoint: Qwen3.6-35B-A3B FP8 E4M3, 128x128 blocks
- input ABI:
  - `mixed_qkvz[M, 12288]` BF16
  - `mixed_ba[M, 64]` BF16
- output ABI:
  - `mixed_qkv[M, 8192]`
  - `z[M, 32, 128]`
  - `b[M, 32]`
  - `a[M, 32]`

The retained c64 trace attributed 19.018 ms across 836 calls, or 1.80% of GPU
time, to the Triton split/reshape/copy region.

## Raw CDNA4 design

The kernel uses two 256-thread workgroups per token and four wave64 waves per
workgroup. Each lane moves 64 bytes with four `global_load_dwordx4` and four
`global_store_dwordx4` instructions. Workgroup 0 copies QKV; workgroup 1
copies Z and the small B/A tails.

Code-object metadata:

- 20 VGPR
- 32 SGPR
- 0 bytes LDS
- 0 bytes scratch
- 16 static `global_load_dwordx4`
- 16 static `global_store_dwordx4`
- no barriers or LDS instructions

## Isolated HIP-event result

All four outputs had zero BF16 bit mismatches against the deployed SGLang
Triton implementation for every shape.

| M | raw median us | Triton median us | speedup |
|---:|---:|---:|---:|
| 1 | 11.360 | 19.440 | 1.711x |
| 12 | 10.720 | 18.681 | 1.743x |
| 64 | 11.001 | 19.040 | 1.731x |
| 210 | 11.240 | 19.240 | 1.712x |
| 768 | 18.960 | 22.120 | 1.167x |
| 1024 | 22.040 | 24.000 | 1.089x |
| 8192 | 110.721 | 113.662 | 1.027x |

Direct HIP graph replay was also bit-exact at M=12, M=64, and M=768.

## Matched GSM8K serving gate

Both arms used GPU 6, c64, gigatoken, DFLASH block 12, a 4096-token draft
window, FP8 E4M3 target and draft KV caches, identical source and launch
arguments, and all 1319 GSM8K test requests. Only the split-copy toggle changed.

| metric | control | raw gfx950 | delta |
|---|---:|---:|---:|
| accuracy | 95.072% (1254/1319) | 94.920% (1252/1319) | -0.152 pp |
| output tok/s | 11,595.91 | 11,425.03 | -1.474% |
| total tok/s | 14,400.53 | 14,200.13 | -1.392% |
| mean TTFT ms | 169.82 | 171.10 | +0.76% |
| mean TPOT ms | 4.745 | 4.744 | -0.02% |
| accept length | 6.865 | 6.892 | +0.028 |

Acceptance was effectively unchanged, so it does not explain this regression.
The result demonstrates why the isolated speedup is insufficient for
promotion. The replacement saves only a small traced share and its graph/custom
dispatch integration does not improve complete serving.

## Artifacts

- isolated build and timing:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260807T143000Z-qkvzba-split-copy-gpu6`
- same-GPU control:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260807T144915Z-qwen36-c64-gpu6`
- same-GPU candidate:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260807T145352Z-qwen36-c64-gpu6`

The raw source, bridge, reproducible build helper, and benchmark are retained
for future fusion work. A successor should fuse the copy into a consumer or
producer so it removes a graph node and a complete HBM round trip.
