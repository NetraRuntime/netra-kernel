# Raw GDN chunk-output integration on gfx1151

All numbers in this note are **measured on gfx1151** (AMD Ryzen AI Max+ PRO
395 / Radeon 8060S). Nothing below is an estimate.

## Accepted integration

`gdn_chunk_o_bv32_gfx1151.s` is now loaded with the other raw code objects by
the SGLang HIP bridge. The graph-safe custom op launches a fixed
`512x128x32` thread grid (reported by rocprofv3; 4x128x32 workgroups of 128
threads), uses 32 KiB LDS, 216 VGPR, 128 SGPR, and zero scratch. Dispatch is
limited to Qwen3.6 B1/T8192/H32/Hg16/K128/V128/BT64 BF16 inputs, FP32 gates,
contiguous storage, and int32 varlen metadata. All other shapes remain on the
Triton implementation.

The live model has an extra batch dimension in the recurrent state:
`[1,128,32,128,128]`. An initial guard expected the flattened
`[128,32,128,128]` shape, so the first real trace correctly fell back to
Triton. This negative integration result is retained at
`results/profiles/gfx1151/raw-gdn-chunk-o-32k-start` and was not used for the
accepted performance claim.

## Correctness and graph replay

The reproducible synthetic exact-shape test measured max absolute error
`1.9073486328125e-6`, mean absolute error `2.0215873246243188e-12`, and finite
output against the tuned Triton oracle. Ten HIP-event samples measured 11.575
ms median for raw assembly versus 15.026 ms for tuned Triton, a 1.2982x kernel
speedup. HIP graph replay measured 11.618 ms and the same 1.907e-6 maximum
error.

A temporary real-checkpoint, layer-by-layer oracle gate returned the Triton
result after comparing each of the 30 GDN layers. Across the real B1/T8192
activations, the maximum of per-layer max errors was 0.00048828125, the median
per-layer max was 0.00006103515625, both implementations were finite, and the
largest per-layer mean error was 6.3868e-11. The validation synchronization and
fallback were removed after this check.

The paired non-profiled, uncached, exact 32,768-input/+1-output serving run used
identical input IDs (`b8e34a...3fecc`). Tuned Triton produced one space token in
30,484.975 ms; raw assembly produced the identical greedy token in 30,262.817
ms. TTFT was 30,484.848 ms versus 30,262.664 ms, input throughput was 1,074.895
versus 1,082.786 token/s, and peak sysfs VRAM was 61,573,218,304 versus
61,129,388,032 bytes. Graph and dFlash were disabled. This is a measured
1.00734x end-to-end speedup and 222.157 ms saving on gfx1151.

## rocprofv3 evidence

Process-start rocprofv3 was used with `--disable-signal-handlers true`; attach
mode remains rejected because it previously killed the scheduler. For the
identical exact 32K request, the raw symbol appeared 120 times and consumed
1,419.825 ms total, 11.832 ms mean, and 11.816 ms median. It accounted for
4.548% of measured kernel time and 2.562% of trace wall time.

The tuned compiler oracle consumed 1,881.299 ms over 120 calls, so raw assembly
saved 461.474 ms of GPU time and was 1.3250x faster in the real trace. The
original untuned kernel consumed 3,978.250 ms with 1,632 bytes of scratch, so
the accepted raw kernel is 2.8020x faster and saves 2,558.425 ms versus that
starting point. The process-start host E2E values were 32,466.847 ms for tuned
Triton and 31,293.848 ms for raw, but the paired non-profiled result above is
the serving claim.

The accepted trace is
`results/profiles/gfx1151/raw-gdn-chunk-o-live-shape-32k-start`. The exact
benchmark is `tools/benchmark/benchmark_gdn_chunk_o.py`; the SGLang source patch is
`scripts/rocm/integrations/sglang/sglang-gfx1151-gdn-chunk-o.patch`.
