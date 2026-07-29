# gfx1151 extend-attention V LDS swizzle negative result (2026-07-29)

Every runtime value below is measured on gfx1151. No value is estimated.

## Variant

Starting from the accepted K-swizzled raw AMDGCN kernel, the experimental
source also XOR-permutes V's 64-byte column group by logical row bit 3. This
separates the two eight-row V halves that otherwise alias the same LDS banks.
Reads calculate and XOR the complete per-output-block address before issuing
`ds_load_u16`; applying the XOR before the immediate output-block offset is
incorrect because addition can carry through the selected address bit.

The final experimental source is
`kernels/gfx1151/attention/experiments/extend_attention_wmma_n64_kv_lds_swizzle_gfx1151.s`.
It retains 248 profiler-reported VGPR, 64 KiB LDS, and zero scratch.

## Correctness

Unscaled random BF16 comparisons against the accepted production kernel are
bit exact for T/prefix pairs 64/0, 64/64, 128/64, and 128/192. Thus the
rejection is solely performance-based.

## HIP-event timing

| T | Prefix | Accepted K-only ms | K+V ms | Relative result | Status |
|---:|---:|---:|---:|---:|---|
| 8,192 | 0 | 44.0123 | 45.1815 | -2.588% | gfx1151 measured |
| 8,192 | 8,192 | 127.7189 | 132.8223 | -3.996% | gfx1151 measured |
| 8,192 | 16,384 | 216.7899 | 223.0668 | -2.896% | gfx1151 measured |
| 8,192 | 24,576 | 305.4296 | 312.3178 | -2.255% | gfx1151 measured |

Each row uses three warmups and eleven HIP-event samples with identical data.
The candidate is slower at every real Qwen3.6 chunk tier, so no serving run is
justified: forty calls would only amplify an already measured regression.

## rocprofv3 mechanism

At T=8,192/prefix=24,576, LDS bank conflict falls from the accepted K-only
34.634323% to 18.160880%, a measured 47.564% relative reduction. However, SQ
busy cycles rise from 17,400,779,332 to 17,795,529,782 (+2.269%). VALU
instructions rise from 906,046 to 970,630 and SALU instructions from 122,296
to 143,824. The address/XOR work costs more than the removed conflicts.

The candidate profiler's occupancy value is invalid (269,762.69%) and is
excluded. Resources are instead taken from valid code-object metadata and the
stable profiler fields. The gfx1151 metric set exposes no direct dependency-
stall counter.

Evidence is retained in the adjacent `negative-hip-events` and
