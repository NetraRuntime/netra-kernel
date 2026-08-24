# gfx950 Qwen M64 wave-skip result

The hand-written M64 gate/up and down wave-skip kernels are retained because
they are bit-identical to their non-wave-skip raw controls and improve the
isolated four-stage pipeline at the real M=768 and M=1024 checkpoint shapes.

They are not accepted as a serving replacement. SGLang c64 throughput fell
from the fresh 4,610.878 tok/s control to 4,432.211 tok/s. Consolidating the
gate/up and quantization handoff produced 4,393.331 tok/s, confirming that the
dominant loss is four GPU nodes plus materialized BF16/FP8 intermediates rather
than Python dispatch.

The next kernel is a true one-stage M64xN256 gfx950 MoE design. It will combine
gate/up, SiLU, down projection, routing weight, and packed-BF16 accumulation in
one wave64 workgroup contract while skipping fully padded M16 waves. The
deployed AITER code object is retained only as a timing, correctness, and ISA
oracle; the replacement remains raw Netra AMDGCN assembly.
