# Qwen3.6 gfx950 M8192 segmented-M16 prefill-attention negative

## Verdict

Rejected. The raw gfx950 kernel is deterministic and numerically close to the
deployed FP8-KV/BF16-tail attention path, but it is slower at every exact
prefix length. The regression grows from 22.7% at prefix zero to 85.0% at a
three-chunk prefix. Do not integrate this topology into SGLang.

## Target and exact contract

- GPU: AMD Instinct MI350X, gfx950, wave64, 256 CUs.
- checkpoint contract: FP8 E4M3 block-quantized weights; FP8 E4M3 KV cache.
- query shape: M=8192, 16 query heads, 2 KV heads, head dimension 256.
- prefix lengths: 0, 8192, 16384, and 24576 tokens.
- candidate grid: 512 x 2 x 2 workgroups, 512 threads per workgroup.
- timing: HIP events, 3 warmups and 10 retained repeats per shape.
- artifact root: `/data/netra/benchmarks/gfx950_qwen36_optimization/20260806T173242Z-prefill-segment16-gpu3`.

## Design

The candidate reuses the accepted GQA8 verification MFMA core. Grid x maps to
one 16-token segment. A workgroup shares each FP8 prefix K/V tile across four
query heads, consumes the original prefix and all earlier extension tokens from
the FP8 cache, and evaluates its current 16-token causal tail from BF16 K/V.
The hand-written prologue changes sequence/segment mapping while retaining the
native online-softmax and FP8/BF16 MFMA body.

## Code object

- target: `amdgcn-amd-amdhsa--gfx950`
- wavefront: 64
- VGPR: 148; SGPR: 80; LDS: 32768 dynamic bytes; scratch: zero
- native instructions include FP8 16x16x128, FP8 16x16x32, and BF16 16x16x32 MFMA
- source: `kernels/gfx950/attention/prefill/experiments/qwen36_prefill_attention_m8192_segment16_gqa8_fp8kv_gfx950.s`

## HIP-event results

| original prefix | shipped M128 median us | raw M16-segment median us | regression | max abs | cosine |
|---:|---:|---:|---:|---:|---:|
| 0 | 1501.266 | 1842.347 | +22.72% | 0.00374603 | 0.999666 |
| 8192 | 3142.772 | 5171.041 | +64.54% | 0.000101089 | 0.999862 |
| 16384 | 4710.799 | 8386.834 | +78.03% | 0.0000610352 | 0.999912 |
| 24576 | 6353.385 | 11751.387 | +84.97% | 0.0000476837 | 0.999943 |

The raw output is deterministic over repeated launches. Differences from the
shipped oracle are expected because prior tokens inside the same 8K chunk are
read back from FP8 KV rather than retained as BF16 extension K/V. No serving
quality gate was run because the performance gate already failed decisively.

## Root cause and successor

Each M16 workgroup independently traverses nearly the same prefix. The schedule
therefore duplicates prefix-loop overhead across 512 x-workgroups and gives up
the query-row reuse and parallelism of the shipped M128 Triton geometry. The
failure worsens monotonically with prefix length, proving the topology is wrong.

The successor must own at least M128 query rows per cooperative tile, retain
GQA8 K/V sharing, and distribute prefix N64 tiles without serializing eight M16
segments. Further tuning of this segmented-M16 topology is not justified.
