# Qwen3.6 on MI350X: executive summary

Netra is fast on MI350X when four things line up: an exact numerical/layout
contract, a gfx950-specialized kernel, a graph-safe fixed ABI, and a serving
configuration that preserves the kernel gain. Kernel code alone is not the
answer. Historical negative evidence includes a 1.30x QKVZ/conv microkernel, a
1.50x long-convolution microkernel, a faster dense M768 kernel, and elimination
of 48 long-prefill cats that all failed or were flat at the matched serving
gate. AITER remains the correct production implementation for several dense
and non-M768 MoE contracts.

The current isolated MI350X campaign provides two narrow correctness-qualified
comparisons. At 27B input-16/output-1, Netra's steady median wall latency was
59.086 ms versus 74.501 ms for the SGLang/AITER control: 20.65% lower, or
1.261x. At input-8192/output-1 it was 409.187 versus 421.226 ms: 2.86% lower,
or 1.029x. Both arms produced identical output hashes in all 20 repeats. At
35B input-16/output-1, the control won: 23.828 versus 24.951 ms, so Netra was
4.71% slower. That negative is retained.

The concurrent results are diagnostics, not production claims. Apparent Netra
output-throughput deltas were +14.58% at 27B C128, +10.27% at C192, and +1.06%
at 35B C64, but concurrent dFlash output hashes diverged across arms. The 35B
1K Netra case generated three distinct hashes in three repeats, and the 35B
8K control returned a second hash in 3/20 repeats. Those timings are
correctness-ineligible. Likewise, 1,800 timings from a six-process legacy GDN
harness are retained but cannot establish a win because its current exactness
gate failed after the modular ABI refactor.

The accepted gains have concrete causes. GQA attention shares native FP8 KV
traffic across query heads; K0 GDN avoids an approximately 805 MiB full-state
write; BF16 recurrent state halves the 27B state pool from 18.14 to 9.07 GB;
argmax expands 16 underfilled reductions into 2,048 stage-one waves; and the
M768 MoE producer/reducer pair shares a byte-locked split-K workspace. Current
rocprofv3 passes corroborate the accepted M1 pair: zero LDS bank conflicts and
no scratch, 99.11% VALU utilization for gate/up, and 92.44% for down/reduce.
Fixed bridges load and resolve symbols before graph capture and do no
allocation, lookup, or synchronization in the launch path.

The defensible novelty is engineering, not a new algorithm: model-neutral
operation manifests, byte-locked raw-kernel templates, paired workspace ABIs,
evidence-locked tactics, and systematic serving-gated promotion on gfx950.
Exact-shape specialization, graph replay, mixed-precision state, split-K,
IO-aware attention, tactic selection, and compiler lowering all have clear
prior art. No research-novel claim is made.

The audit reconstructed 472 relevant commits, 2,292 historical file changes,
290 tracked evidence files, 37 tactics, and 46 manifest operations. It also
inventoried 581 ignored artifacts, recovered the 1.025 GB prefill archive, and
captured a new 126 MB campaign. The combined external evidence has 1,038
hashed files, while four checkpoint manifests hash 349 files across roughly
73 GB. The derived ledger contains 5,544,631 numeric leaves, 10,100 serving
metric rows, 1,800 GDN timing rows, and 56 profiler-counter rows.

Priority order is now correctness first: explain the 35B and concurrency hash
divergence; add independent-process serving intervals and current exact
M8/M12/M16/M768/C256 coverage; then attack 27B long dense prefill (61.60% of
profiled wall time), 35B non-M768 MoE (19.63%), attention (11.01%), and GDN
initialization (9.45%). Do not promote a new kernel until correctness,
warm/replay microbenchmarks, graph stability, matched serving, and natural-EOS
quality all pass.
