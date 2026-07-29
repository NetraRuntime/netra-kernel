# gfx1151 GDN chunk-output optimization (2026-07-29)

All runtime values are measured on gfx1151. No value is estimated.

The post-attention full-request trace ranked `chunk_fwd_kernel_o` second among
non-attention opportunities: 120 calls, 3,978.250 ms total GPU time, 33.186 ms
median, 256 VGPR, and 1,632 bytes scratch per work item. The exact model shape
is B=1, T=8192, H=32, Hg=16, K=V=128, BT=64, variable-length indexing.

## Temporary compiler oracle

BK64/BV32/eight waves measured 15.076 ms isolated versus 32.973 ms for the
original BK128/BV64/four-wave kernel, with max BF16 difference 3.8147e-6.
In the real 32K rocprofv3 request it reduced the 120-call total from 3,978.250
to 1,881.299 ms (2.1146x) and scratch from 1,632 to 432 bytes. Profiled host
E2E fell from 34,232.846 to 32,466.847 ms. This remains a fallback/oracle,
not the final targeted compute implementation.

## Raw AMDGCN result

`kernels/gfx1151/gdn/gdn_chunk_o_bv32_gfx1151.s` is a hand-written four-wave gfx1151
kernel. It stages Q/H, Q/K, causal gated A, and V through 32 KiB LDS; retains
the gated qh accumulators across the qk phase; converts A to BF16 in LDS; and
accumulates Av directly into the qh registers. It uses zero scratch.

At the exact model shape, ten HIP-event samples have a 10.920 ms median versus
15.205 ms for the tuned Triton oracle: 1.3924x. Versus the original live
33.186 ms median, raw is 3.039x. Max/mean BF16 differences from tuned Triton
are 3.8147e-6 and 1.1203e-11, and all outputs are finite.

The gated qh sub-path was separately validated by zeroing K and V. It measured
5.429 ms and matched the model-native/Triton result within 1.9073e-6.

Machine-readable measurements are in
`docs/notes/gfx1151-gdn-chunk-o-raw-2026-07-29.json`. Before/oracle
disassemblies and static counts are under
`docs/notes/disassembly/gfx1151-gdn-chunk-o-2026-07-29/` and
`docs/notes/gfx1151-gdn-chunk-o-oracle-disassembly-2026-07-29.json`.

## Integration status

Raw isolated correctness and HIP-event performance are accepted. SGLang
custom-op/graph wiring, real-checkpoint layer comparison, rocprofv3 symbol
attribution, and paired uncached serving A/B remain required before declaring
the full-request replacement accepted.
