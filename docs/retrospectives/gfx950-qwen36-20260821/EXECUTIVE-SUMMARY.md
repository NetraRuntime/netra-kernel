# Qwen3.6 on MI350X: executive summary

Netra is fast on MI350X when four things line up: an exact numerical/layout
contract, a gfx950-specialized kernel, a graph-safe fixed ABI, and a serving
configuration that preserves the kernel gain. Kernel code alone is not the
answer. The strongest proof is the negative evidence: a 1.30x QKVZ/conv
microkernel, a 1.50x long-convolution microkernel, a faster dense M768 kernel,
and elimination of 48 long-prefill cats all failed or were flat at the matched
serving gate. AITER remains the right production implementation for several
dense and non-M768 MoE contracts.

The accepted wins have concrete causes. GQA attention shares native FP8 KV
traffic across query heads; K0 GDN avoids an approximately 805 MiB full-state
write; BF16 recurrent state halves the 27B state pool from 18.14 to 9.07 GB;
argmax expands 16 underfilled reductions into 2,048 stage-one waves; and the
M768 MoE producer/reducer pair shares a byte-locked split-K workspace. Fixed
bridges load and resolve symbols before graph capture and do no allocation,
lookup, or synchronization in the launch path.

The defensible novelty is engineering, not a new algorithm: model-neutral
operation manifests, byte-locked raw-kernel templates, paired workspace ABIs,
evidence-locked tactics, and systematic serving-gated promotion on gfx950.
Exact-shape specialization, graph replay, mixed-precision state, split-K,
IO-aware attention, tactic selection, and compiler lowering all have clear
prior art. No research-novel claim is made.

This audit reconstructed 472 relevant commits, 2,292 historical file changes,
290 tracked evidence files, 37 tactics, 46 manifest operations, and 347
external-artifact references. A read-only ignored-file pass also hashed 581
local artifacts, including 25 HSACOs and 17 present 35B checkpoint shards; all
17 shards match the pinned revision tree, which still lacks 26 LFS files. The
current host has no `/dev/kfd`, ROCm
toolchain, Docker daemon, or mounted `/data/netra` archive. Consequently, the
report faithfully curates historical tracked measurements but does not claim a
new 2026-08-21 benchmark run. Input-1K cases, current pinned-upstream reruns,
raw per-iteration samples, and a uniform TTFT/TPOT/p50/p95/memory matrix remain
open execution gaps.

Priority order: restore the immutable MI350X environment and raw archive;
rerun a matched AITER/SGLang/Triton matrix with ABBA process ordering; attack
27B long dense prefill (61.6% of profiled wall time); then 35B non-M768 MoE
(19.63%), attention (11.01%), and GDN initialization (9.45%). Do not promote
new kernels until correctness, warm/replay microbenchmarks, graph stability,
and natural-EOS serving all pass.
