# gfx950 Qwen3.6 GDN M8192 chunk output

Date: 2026-08-02

## Scope and implementation

This accepted raw AMDGCN module replaces only the exact Qwen3.6 GDN chunk
output shape `B=1,T=8192,H=32,Hg=16,K=V=128,BT=64` on `gfx950` wave64. The
checkpoint remains FP8 E4M3 with 128x128 weight blocks and the serving KV cache
remains FP8 E4M3. Unsupported shapes stay on the existing SGLang path.

The production source is
`kernels/gfx950/linear_attention/prefill/qwen36_gdn_chunk_o_m8192_bv128_fixed_t8192_gfx950.s`.
The HIP runtime bridge only loads the code object and launches it on the
caller's stream; it contains no replacement compute.

The deployed BV64 Triton geometry launched two workgroups per V dimension and
reloaded common Q/K inputs for both halves. The selected CDNA4 layout gives one
four-wave workgroup all 128 V elements, uses a 32 KiB LDS tile, and launches
`grid=(1,128,32)` with 256 threads. It uses native
`v_mfma_f32_32x32x16_bf16`, 138 VGPRs, 56 SGPRs, zero scratch, and zero spills.
The retained source is a standalone, fixed-T gfx950 module with compiler debug
and source-map sections removed. Its compute disassembly is instruction-for-
instruction identical to the quarantined BV128 oracle; the manually selected
BV128 geometry, fixed ABI, launch contract, runtime gate, and retained source
are maintained in this repository.

## Correctness

The real layer-0 capture contains 33,554,432 BF16 output elements. The raw
module is bit-exact to the matching BV128 Triton oracle. Relative to the
deployed captured output, 172 elements differ, maximum absolute error is
`0.00390625`, cosine similarity is `0.99999994`, and there are zero failures
under the preregistered `atol=0.03125`, `rtol=0.01`, `cosine>=0.9995` gate.
The SGLang custom-op wrapper produces the same result and graph replay matches
eager execution.

The cleaned production server retained only the two pre-existing near-tie
one-token hashes (`220` and `5525`) seen in the same-GPU control. Full
GSM8K-nonthinking evaluation scored `0.95527` accuracy and `0.01365` invalid
over 1,319 questions, versus `0.94845` and `0.01213` for the current-best
control. The earlier 200-question stochastic runs ranged from 0.940 to 0.960
for instruction-identical candidates, so the full-set comparison is the
quality gate.

An isolated GPU2 control replica failed before producing a comparable full-set
result. At `2026-08-02 03:02:53 UTC`, with this chunk kernel disabled and before
any exact-T8192 dispatch, the kernel log recorded an AMDGPU VM permission fault
for server PID 2973196/PASID 32858 at `0x00007dc2a83f8000`; the container then
exited. That run's 99.92% invalid responses are excluded. The valid control is
the still-live GPU1 current-best server above. The fault is a separate existing
batch-32/control-stack correctness issue and is not attributed to this module.

## Performance

The cleaned production build measured 87.561 us eager and 95.961 us graph
replay over 100 HIP-event iterations. The matching fixed-T BV128 Triton oracle
measured 100.761 us eager and 102.541 us graph replay. Relative to the original
deployed variable/BV64 path, the retained graph measurements were 121.58 us
for Triton and 97.38 us for the raw module, a 19.9% reduction.

The same-GPU serving A/B used 30 exact uncached 8192-input/1-output requests per
arm, discarding each arm's first warmup request. Median latency fell from
127.967 ms to 127.563 ms (`0.316%`), and mean latency fell from 128.097 ms to
127.638 ms (`0.360%`). Both arms used piecewise graphs, dFlash block 12, FP8
E4M3 KV, one MI350X, and the same server snapshot.

## Counter evidence and rejected variants

The deployed BV64 path issued 32,768 waves, 917,504 MFMA instructions, and
measured about 40.5% occupancy. Its counter run recorded 18.553 million TCC
read sectors, 4.194 million write sectors, 66.45 million `SQ_WAIT_ANY`, and
110.5 us profiler duration. BV32 was 185-201 us; eight-wave workgroups were
about 270 us; one, three, and four stages did not improve the selected
four-wave/two-stage oracle. BK64/BV128 was close but did not beat BK128/BV128.

The first hand-written recurrence+output fusion attempt was rejected at the
first chunk because its MFMA lane/state mapping produced output cosine 0.227
and state error up to 8,960. QwenLM FlashQLA commit
`821fd9d37ede18fdc2a4e707fefe3770bfc32e58` remains the design reference for a
fresh fused wave64 mapping: recurrence and output fusion can avoid materializing
all chunk states, but Hopper/TileLang warp specialization will not be ported
mechanically to CDNA4.

## Artifacts

- isolated production-clean result:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T025100Z-gdn-chunk-o-bv128-production-clean-gpu2/result.json`
- final artifact with explicit BV128/grid/LDS metadata:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T031100Z-gdn-chunk-o-bv128-production-final-gpu2/result.json`
- same-GPU candidate serving:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T025646Z-gdn-chunk-o-bv128-production-clean-gpu2/`
- same-GPU control serving:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T024716Z-gdn-chunk-o-control-gpu2/`
- original raw counters:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260802T034000Z-gdn-chunk-o-raw-source-counters-gpu2/`

Production source SHA-256 is
`1646495cd1ac8862debb80c99e036a35caee7500bf19881e8f71de3ff6bcde9b`;
the validated code object is
`75299ddad1d39da42ea4f7b337987a83e1b36a1a928b5f5c1e5b83d4f3954305`.
