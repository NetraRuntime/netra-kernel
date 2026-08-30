# gfx950 DeepSeek V4 DSpARK Triton-to-assembly opportunities

## Scope

This ranking uses the concurrency-64 Kineto decode capture from the MI350X
DeepSeek V4 DSpARK campaign. It ranks only work for which assembly can remove a
launch, an intermediate tensor, or a multi-kernel dependency chain. A
one-for-one rewrite of a 4--5 us Triton kernel is not considered sufficient.

## 1. Unified-KV prefill index pipeline

The source path is
`python/sglang/kernels/ops/attention/dsv4/unified_kv_kernels/runtime.py`.
Each `build_prefill_indices` invocation currently dispatches:

1. `_prefill_lengths_kernel`;
2. rocPRIM scan, pad elementwise, and device copy for prefix lengths;
3. rocPRIM scan, pad elementwise, and device copy for extend lengths;
4. `_build_prefill_indices_kernel`.

The trace contains 2,380 complete chains: 19,040 GPU kernel/copy operations,
81.61 ms aggregate GPU time, and 35.07 us median summed GPU duration per chain.
The observed Triton grids are 1, 31, and 32 token programs.

Implement a gfx950 one-workgroup kernel for the bounded graph shapes. It should
compute both length vectors, scan them in registers/LDS, emit both `[T+1]`
indptrs, and fill both ragged index streams. Keep the current Triton/rocPRIM
pipeline as the fallback for unsupported `T`, `win`, compression width, or
layout. The two Triton kernels cannot be fused without also absorbing both
scans because the second kernel consumes the completed indptrs.

Required gate: exact parity for both compression modes and no-compression,
including empty compressed tails, followed by the standard DSpARK serving
throughput and latency gate.

## 2. Step-local add into DSpARK argmax stage 1

`_build_step_local_kernel` is immediately followed by
`dsv4_dspark_argmax_f32_stage1_gfx950` and stage 2 in all 455 observed
occurrences. The Triton add accounts for 3.18 ms; the exact three-operation
chains account for 10.76 ms.

Add dtype-specialized stage-1 assembly entry points that load `base_local` and
`bias`, convert as required, perform the FP32 add, and feed the existing ordered
argmax reduction without materializing `step_local`. This removes one launch
and changes the add-plus-stage-1 traffic from two input reads, one temporary
write, and one temporary read to two input reads.

Required gate: reproduce PyTorch FP32 addition, NaN handling, lowest-index tie
breaking, bias tail padding, and every supported vocabulary/shard width. Retain
the current materialized path when TP all-gather or an unsupported dtype/layout
separates the producer from argmax.

## 3. Router plus shared-expert append

`_router_triton_kernel` is immediately followed by
`_fused_append_shared_experts_kernel` in all 2,233 trace occurrences. Router
time is 10.86 ms and append time is 9.44 ms. Producing the final routed-plus-
shared layout in the router would remove 2,233 launches and the routed-only
intermediate output.

First test the existing unified Triton router's shared-slot epilogue because it
already implements the necessary output form. If its gfx950 code or numerics do
not qualify, implement the combined epilogue in assembly using the accepted
Qwen `qwen36_shared_gate_append_m1_gfx950` layout as the design reference, but
preserve DeepSeek's grouped-routing, scaling, renormalization, and shared-weight
semantics.

## Lower-priority work

- Two adjacent `_scatter_loc_kernel` calls occur only 198 times. Their maximum
  direct launch saving is small compared with the three candidates above.
- `_swa_scatter_kernel` is launch-bound, but the prior greedy/SWA fusion failed
  the serving gate and was reverted. Do not retry it without a different data
  flow.
- `_fused_rms_fp8_group_quant_kernel` is followed by scale materialization in
  the older capture, but the retained FP8 producer/view changes target those
  copies. Reprofile the current qualified build before attributing any remaining
  copy to the quant kernel.
- Standalone `_fused_append_shared_experts_kernel`, `_router_triton_kernel`, and
  scatter kernels are already near the launch floor. Assembly work is justified
  only when it performs one of the cross-kernel fusions above.
