# gfx1151 expert reduction determinism follow-up

Production status: **not enabled**. All numeric values are measured on gfx1151.

A second raw top-8 expert reduction replaced the earlier FMA chain with eight separate FP32 multiplies and a fixed balanced pairwise add tree. It is bit-exact to that pairwise FP32 reference at T=128 and T=8,192. At T=8,192 it differs from an FP64-accumulated/rounded-BF16 reference in 885 of 16,777,216 elements (0.00528%), with max absolute error 0.0078125 and mean absolute error 1.4431e-8. The code object uses 34 VGPR, 44 SGPR, zero LDS, and zero scratch.

Temporarily combining it with the accepted activation pack reduced exact 32,768/+1 host E2E to 27,125.973 ms for pair A and 26,991.833 ms for pair B. Pair A returned token 220. Pair B returned token 3709 on the first server and token 96043 after a fresh-server restart with identical code and input. Therefore the fixed MoE reduction does not eliminate the remaining full-stack nondeterminism, and the large apparent serving speedup is not accepted.

An unused module-load control also changed pair B from 96043 to 3709 while the committed Torch gather/multiply/atomic-index-add path remained active. This proves the historical pair-B token alone is schedule/layout-sensitive and cannot determine whether an otherwise bit-exact replacement is correct. Future determinism work must capture layer/logit deltas across fresh server epochs and rank remaining atomic or unordered reductions before promoting a numerically non-bit-exact kernel.

The raw pairwise `.s`, disassembly, metadata, and compact JSON measurements are retained as a negative-result oracle.
