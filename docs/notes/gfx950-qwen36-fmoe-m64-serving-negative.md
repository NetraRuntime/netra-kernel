# gfx950 Qwen3.6 M64 grouped FMoE serving rejection

Status: **validated negative; not enabled in SGLang production**.

This experiment replaces the complete AITER grouped FMoE path with raw
wave64 gfx950 assembly for gate/up + SiLU, the existing AITER FP8 activation
quantizer, an M64xN128 down projection, and deterministic nine-route
reduction. Qwen weights remain FP8 E4M3 with 128x128 scales and the target KV
cache remains FP8 E4M3.

The original M=1024 capture was insufficient for acceptance. A real c64
dFlash run exercises a distribution of verification rows, including M=768,
M=1008, and other partially occupied batches. A new exact M=768 capture
retains 191 active experts and all stage inputs, weights, scales, sorting
metadata, activation, and AITER outputs.

On that same M=768 capture, 100 HIP-event repetitions measured:

| Complete FMoE implementation | Median |
|---|---:|
| AITER `64x256` one-stage | 182.602 us |
| raw M64 gate/up + quant + M64xN128 down + reduction | 187.482 us |

The raw pipeline is 2.67% slower at the deployed verification shape. Its
structural output remains finite with cosine 0.999973 and maximum absolute
error 0.000844210, but 1,191,581 of 1,572,864 BF16 elements differ from the
structural oracle. Those aggregate gates were therefore too weak to predict
end-to-end greedy behavior.

The isolated candidate was then integrated without fallback into an otherwise
identical piecewise-graph, dFlash block-12, K0, single-MI350X server. Exact
16+2 and 210+128 requests each passed 3/3 with the retained production hashes.
The decisive c64 1024-input/256-output A/B rejected it:

| Server | Output throughput | Delta |
|---|---:|---:|
| current production control | 4380.449 tok/s | -- |
| raw grouped-M64 candidate | 4059.439 tok/s | -7.33% |

Only 31 of 512 deterministic greedy output hashes matched the control. The
first candidate hash was
`5dd67f745671caaacfed6a12a8f81560f95f80cd1dcbffb6dab78656c7df5efe`;
the identical control prompt produced
`1d1c4778a78e5a246f979f6b74ed9387b7a47bd8612356cdd1862e9173a7fc42`.
Speculative acceptance also declined from 0.166087 to 0.163931.

Artifacts:

- serving A/B:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260801T094500Z-fmoe-m64-raw-serving-gpu4/`
- exact M=768 capture, export, raw log, and AITER variants:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260801T100600Z-fmoe-m768-capture-gpu4/`
- raw serving bridge build:
  `/data/netra/repos/netra-kernel/build/gfx950-qwen36-moe-m64-verify-r1/`

The production GPU0 container was never stopped or modified. This path must
not be shipped until it beats AITER across the real row distribution and
passes concurrent deterministic output and GSM8K gates.
