# DeepSeek-V4 DSpARK FP32 argmax on gfx950

Date: 2026-08-28
Status: **accepted for target verification; broader draft-graph dispatch rejected**

The profiled DeepSeek-V4-Flash DSpARK target-verification boundary is a
contiguous FP32 tensor with 129,280 columns. At decode batch 64 it has 384
rows (six verification tokens per request). The generic PyTorch reduction was
the largest replaceable non-MoE boundary in the decode trace: 24,891 us over
564 calls, or 44.133 us/call and 4.89% of GPU kernel time.

The Netra-kernel implementation follows the repository's raw gfx950 layout:

```text
kernels/gfx950/sampling/verify/dsv4_dspark_argmax_f32_gfx950.s
runtime/gfx950/sampling/verify/dsv4_dspark_argmax_f32_bridge.h
runtime/gfx950/sampling/verify/dsv4_dspark_argmax_f32_bridge.hip
harness/gfx950/sampling/verify/dsv4_dspark_argmax_f32_gfx950.hip
tools/build/build_gfx950_dsv4_dspark_argmax_f32.sh
tools/benchmark/validate_gfx950_dsv4_dspark_argmax_f32.py
```

Stage 1 assigns 16 one-wave chunks to each row. Each wave covers 8,080
columns as four 2,020-value subchunks. Stage 2 uses one wave per row to reduce
the 16 partial `(value,index)` keys. Both entries are wave64 raw AMDGPU
assembly, use 52 VGPRs, no LDS, and no scratch. Stage 1 uses 21 SGPRs and
3,432 bytes of function text; stage 2 uses 20 SGPRs and 556 bytes. The
maximum selected-server workspace is 196,608 bytes for 1,536 rows.

The ordering key reproduces PyTorch `GreaterOrNan<float>`:

- NaN sorts above every ordered value and the first NaN wins;
- `-0` and `+0` compare equal;
- infinities and finite IEEE values preserve numeric order;
- the lowest index wins every tie.

The assembly SHA-256 is
`7d200b0041172906633b4f7e06c9dfa8a5aefc70dbe3b87419bc90601b4e8cf5`.
The selected HSACO SHA-256 is
`734a315ea1da89ee910b477160098fd304650ca4d9ffdfd3510a37c47d9f1f06`.

## Search and validation

The chunk search retained every result:

| Candidate | Result at 384 rows | Disposition |
|---|---:|---|
| 64 chunks | 42.909 us | exact, superseded |
| 8 chunks, first loop | 41.200 us | rejected, 38/384 mismatches |
| 8 chunks, fixed | 41.025 us | exact, superseded |
| 16 chunks | 40.272 us | exact winner |
| 32 chunks | 41.893 us | exact, slower |

The final 16-chunk validator passed 69/69 cases over row counts 1, 6, 64,
and 384. Coverage includes 16 random seeds per row shape plus cross-chunk
ties, signed zero, infinities, first-NaN behavior, and subnormals. Two thousand
same-process HIP-event iterations measured 39.611 us for raw versus 47.485 us
for `torch.argmax`, a 1.199x speedup.

## Serving result and promotion boundary

The selected server dispatches only the target-verification argmax. Its final
decode-b64 trace measured 26.373 + 4.321 = 30.694 us/call for the two raw
stages versus 42.749 us/call for the remaining same-shape PyTorch reduction,
a 1.393x speedup and 12.055 us saved per target verification. The final
semantic qualification passed with aggregate DSpARK acceptance 3.022, and
the exact 18-cell 1K/8K matrix completed with zero request failures.

An experiment that also replaced the five argmax operations folded into the
draft CUDA graph was rejected. Although its profile contained 606 raw pairs
and zero PyTorch argmax launches, three unprofiled decode-b64 repeats averaged
1,765.996 output token/s versus the prior selected R3 result of 1,881.98
token/s (-6.16%). The draft integration remains in history and artifacts but
is not in the selected overlay.

Only the guarded FP32, contiguous, 129,280-column gfx950 boundary is promoted.
Other dtypes, widths, layouts, sampling modes, architectures, and devices fall
back to the caller's existing implementation.
