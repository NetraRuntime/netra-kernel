# Qwen3.6 gfx950 M8192 GDN causal-convolution serving negative

## Verdict

Rejected for production promotion. The raw gfx950 kernel is bit-exact against
the deployed Triton causal-convolution oracle and is 1.50x faster in isolation,
but the required 192-request c64 32K-input/16K-output serving gate was 5.60%
slower than the same-state control. The raw source, graph-safe physical-state
ABI, bridge, build script, and isolated harness are retained as an experiment;
the SGLang best launcher does not enable this kernel.

The long-run loss is correlated with different generated token streams and
lower weighted speculative acceptance, not an isolated numerical mismatch in
the convolution. That does not satisfy the end-to-end promotion rule.

## Exact kernel contract

- GPU: AMD Instinct MI350X, gfx950, wave64
- checkpoint: Qwen3.6-35B-A3B FP8 E4M3 with 128x128 weight blocks
- operation: model-native BF16 depthwise causal convolution plus SiLU
- shape: B=1, M=8192, D=8192, width=4
- input layout: shape (8192, 8192), strides (1, 8192)
- state ABI: physical BF16 state pool, device cache-index pointer, and device
  has-initial-state pointer
- output: BF16 shape (8192, 8192)
- workgroup: 256 threads, one workgroup per 256 features
- grid: 8192 workgroups
- timing: HIP events, 30 retained repeats
- isolated artifact root:
  `/data/netra/benchmarks/gfx950_qwen36_optimization/20260807T010500Z-gdn-causal-conv-m8192-gpu1`

## Design and code object

Each workgroup owns 256 adjacent features and 32 consecutive token rows. It
loads the three-token prefix and four BF16 weights once per feature, advances
the recurrence through 32 tokens, applies the same BF16-product/FP32-sum and
SiLU boundaries as Triton, writes contiguous BF16 output, and commits the final
three-token physical state.

The production-shaped ABI reads the cache slot and initial-state flag from
device memory. No host scalar extraction is required, so the launch can be
captured in the pinned SGLang piecewise graph.

- target: `amdgcn-amd-amdhsa--gfx950`
- wavefront: 64
- VGPR: 33
- SGPR: 34
- LDS: 0 bytes
- scratch: 0 bytes
- maximum workgroup: 256
- static disassembly: 39 global BF16 loads, 33 global BF16 stores, 32
  `v_exp_f32`, 32 `v_div_fmas_f32`, and zero barriers

## Isolated correctness and timing

Both fresh-state and initial-state modes were checked. The physical state pool
used four slots and a nonzero cache slot (slot 3), so a logical/physical slot
alias could not pass accidentally.

| implementation | median us | p90 us | result |
|---|---:|---:|---|
| deployed Triton | 135.161 | 139.401 | oracle |
| raw gfx950 BM32 | 90.321 | 93.441 | 1.496x |

All 67,108,864 output elements and all 98,304 physical-state elements were
bit-exact in both modes: zero mismatches and max absolute error 0.

## Real-checkpoint gates

The raw kernel was loaded before graph capture and its dispatch was proven at
the exact live M8192 shape. A 10-request, concurrency-1 32K-input/1-output
screen measured 57,374.63 input tok/s versus 57,034.80 control (+0.60%), but the
margin is too small to override the canonical long-serving gate.

The full 1,319-question GSM8K natural-EOS gate completed at 94.996% accuracy
(1,253 correct, 16 invalid). Full-stack quality was therefore healthy.

The canonical matched c64 stress used 192 requests, exact 32,768-token random
inputs and exact forced 16,384-token outputs:

| metric | raw candidate | control | candidate delta |
|---|---:|---:|---:|
| duration (s) | 818.165 | 772.379 | +5.93% |
| input throughput (tok/s) | 7,689.71 | 8,145.56 | -5.60% |
| output throughput (tok/s) | 3,844.86 | 4,072.78 | -5.60% |
| total throughput (tok/s) | 11,534.57 | 12,218.34 | -5.60% |
| mean TTFT (ms) | 11,560.71 | 11,419.80 | +1.23% |
| mean TPOT (ms) | 7.337 | 7.261 | +1.05% |
| weighted accept length | 8.968 | 9.489 | -5.49% |
| verification calls | 335,640 | 331,669 | +1.20% |

Both arms completed all 192 requests with exactly 6,291,456 input and
3,145,728 output tokens and no request errors. Generated-text hashes differed,
and the candidate spent longer in the content-dependent accept-length-1 forced
tail. Known AITER FMoE nondeterminism and the use of different physical GPUs
make the precise attribution noisy; regardless, the candidate did not pass the
declared end-to-end gate.

## Conclusion

The kernel proves that this isolated Triton operation has a clean raw-assembly
speedup, but it saves too little of a 32K/16K request to dominate speculative
path variance. Do not wire it into the best launcher. Revisit only as part of a
